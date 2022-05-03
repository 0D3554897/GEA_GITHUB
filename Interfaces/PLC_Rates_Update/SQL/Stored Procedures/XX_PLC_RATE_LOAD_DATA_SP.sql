USE [IMAPSStg]
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PLC_RATE_LOAD_DATA_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   DROP PROCEDURE [dbo].[XX_PLC_RATE_LOAD_DATA_SP]
GO

CREATE PROCEDURE [dbo].[XX_PLC_RATE_LOAD_DATA_SP]
(
@in_STATUS_RECORD_NUM   integer,
@out_STATUS_DESCRIPTION varchar(255) = NULL OUTPUT
)
AS

/***********************************************************************************************************
Name:    XX_PLC_RATE_LOAD_DATA_SP
Author:  HVT
Created: 02/05/2018
Purpose: Load customer's DDOU PLC rates data into SQL Server database using the bcp utility.
         Called by XX_PLC_RATE_RUN_INTERFACE_SP.

Notes:   Reference CR-10162 (IMAPS Help Request 20180108122548) Automate the process of updating
         the DDOU PLC rates data in Costpoint.
************************************************************************************************************/

BEGIN

DECLARE @SP_NAME                  sysname,
        @PLC_RATES_INTERFACE_NAME varchar(50),
        @PLC_RATES_TEXT_FILE      sysname,
        @PLC_RATES_FORMAT_FILE    sysname,
        @SERVER_NAME              sysname,
        @DATABASE_NAME            sysname,
        @SCHEMA_OWNER             sysname,
        @DEST_TABLE               sysname,
        @DOUBLE_QUOTE             char(1),
        @PERIOD                   char(1),
        @SPACE                    char(1),
        @cmd_str                  varchar(255),
        @PLC_rates_file           sysname,
        @ret_code                 integer,
        @row_count                integer,
        @exec_stat                integer,
        @DOS_error_msg            varchar(70),
        @user_error_msg           varchar(500),
        @SS_Error_Number          integer,
        @SS_Error_Message         sysname,
        @SS_Error_Procedure       sysname,
        @SS_Error_Line            smallint,
        @SS_Error_Severity        tinyint,
        @SS_Error_State           smallint

SET NOCOUNT ON

-- Set constants
SET @SP_NAME = 'XX_PLC_RATE_LOAD_DATA_SP'
SET @PLC_RATES_INTERFACE_NAME = 'PLC_RATES'
SET @SERVER_NAME = @@servername
SET @DATABASE_NAME = db_name()
SET @SCHEMA_OWNER = 'dbo'
SET @DEST_TABLE = 'XX_PLC_RATE_UPDATE_STG'
SET @DOUBLE_QUOTE = '"'
SET @SPACE = ' '
SET @PERIOD = '.'
SET @DOS_error_msg = 'Execution of DOS command failed: xp_cmdshell() returned error status'

BEGIN TRY

/*
 * IMPORTANT: Do not use TRUNCATE TABLE to empty table XX_PLC_RATE_UPDATE_STG. TRUNCATE TABLE causes the execution to be suspended such that
 * The statement EXEC @ret_code = master.dbo.xp_cmdshell @cmd_str is never reached; and table XX_PLC_RATE_UPDATE_STG is put in "WAIT" status.
 * Note that BEGIN TRANSACTION, COMMIT TRANSACTION and ROLLBACK TRANSACTION are all issued in the calling SP, XX_PLC_RATE_RUN_INTERFACE_SP.
 * Ultimately and manually, the system process ID (spid) with status = suspended must be identified using SP_WHO and SP_LOCK and
 * KILL to release the lock on the table. Once free, the table is returned to its original state before TRUNCATE TABLE event.
 */

DELETE dbo.XX_PLC_RATE_UPDATE_STG
SET @row_count = @@ROWCOUNT

IF @row_count IS NOT NULL AND @row_count > 0
   PRINT 'Number of dbo.XX_PLC_RATE_UPDATE_STG rows deleted: ' + CAST(@row_count as varchar(10))
ELSE
   PRINT 'Staging table XX_PLC_RATE_UPDATE_STG was empty before the delete attempt.'

PRINT 'Retrieve processing parameter data to build bcp command line ...'

SELECT @PLC_RATES_TEXT_FILE = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = @PLC_RATES_INTERFACE_NAME
   AND PARAMETER_NAME = 'PLC_RATES_TEXT_FILE' -- D:\IMAPS_DATA\inbox\PLC_RATES\

SELECT @PLC_RATES_FORMAT_FILE = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = @PLC_RATES_INTERFACE_NAME
   AND PARAMETER_NAME = 'PLC_RATES_FORMAT_FILE' -- D:\IMAPS_DATA\Interfaces\FORMAT\PLCRatesUpdate.fmt

-- Staging table XX_PLC_RATE_UPDATE_STG is populated using bcp. The format file used by bcp does not include columns CREATE_DT and CREATE_USER which are defined with default system values.

PRINT 'Construct DOS command string for bcp execution ...'

-- E.g., D:\IMAPS_DATA\inbox\PLC_RATES\PLC_Rates_12345.txt
SET @PLC_rates_file = @PLC_RATES_TEXT_FILE + 'PLC_Rates_' + CAST(@in_STATUS_RECORD_NUM as varchar(15)) + '.txt'

/*
 * Example of @cmd_str's value:
 * BCP "IMAPSStg.dbo.XX_PLC_RATE_UPDATE_STG" IN "D:\IMAPS_DATA\inbox\PLC_RATES\PLC_Rates_17342.txt" -S "HOU28FSDD01" -f "D:\IMAPS_DATA\Interfaces\FORMAT\PLCRatesUpdate.fmt" -T
 */

-- Construct the shell command line
SET @cmd_str = 'BCP' + @SPACE
SET @cmd_str = @cmd_str + @DOUBLE_QUOTE + @DATABASE_NAME + @PERIOD + @SCHEMA_OWNER + @PERIOD + @DEST_TABLE
SET @cmd_str = @cmd_str + @DOUBLE_QUOTE + @SPACE
SET @cmd_str = @cmd_str + 'IN' + @SPACE + @DOUBLE_QUOTE + @PLC_rates_file + @DOUBLE_QUOTE + @SPACE
SET @cmd_str = @cmd_str + '-S' + @SPACE + @DOUBLE_QUOTE + @SERVER_NAME + @DOUBLE_QUOTE + @SPACE
SET @cmd_str = @cmd_str + '-f' + @SPACE + @DOUBLE_QUOTE + @PLC_RATES_FORMAT_FILE + @DOUBLE_QUOTE + @SPACE
SET @cmd_str = @cmd_str + '-T'
PRINT 'DOS command: ' + @cmd_str

PRINT 'Execute DOS command ...'

EXEC @ret_code = master.dbo.xp_cmdshell @cmd_str

IF @ret_code <> 0
   BEGIN
      SET @out_STATUS_DESCRIPTION = 'NOTICE: Attempt to execute bcp utility via DOS command failed.'
      PRINT @out_STATUS_DESCRIPTION 
      RAISERROR(@DOS_error_msg, 16, 1)
   END

-- Even when bcp is executed successfully, the target table XX_PLC_RATE_UPDATE_STG isn't populated. Check this condition.

SELECT @row_count = COUNT(1) FROM dbo.XX_PLC_RATE_UPDATE_STG

IF @row_count = 0
   BEGIN
      SET @out_STATUS_DESCRIPTION = 'NOTICE: Attempt to populate table XX_PLC_RATE_UPDATE_STG via bcp failed. Table XX_PLC_RATE_UPDATE is empty.'
      PRINT @out_STATUS_DESCRIPTION
      GOTO BL_ERROR_HANDLER
   END
ELSE
   BEGIN
      SET @out_STATUS_DESCRIPTION = 'Table XX_PLC_RATE_UPDATE_STG is successfully populated via bcp.'
      PRINT @out_STATUS_DESCRIPTION
      PRINT 'Number of XX_PLC_RATE_UPDATE_STG records inserted: ' + CAST(@row_count as varchar(15))
   END

PRINT 'Update XX_PLC_RATE_UPDATE_STG data into usable condition ...'

PRINT 'Remove the dollar sign character at the leftmost position of column BILL_RT_AMT''s value ...'

SELECT @row_count = COUNT(1)
  FROM dbo.XX_PLC_RATE_UPDATE_STG
 WHERE LEFT(LTRIM(BILL_RT_AMT), 1) = CHAR(36) -- '$'

IF @row_count > 0
   BEGIN
      PRINT 'Number of XX_PLC_RATE_UPDATE_STG records with BILL_RT_AMT values having CHAR(36), the dollar sign, in the leftmost position: ' + CAST(@row_count as VARCHAR(10))

      UPDATE dbo.XX_PLC_RATE_UPDATE_STG
         SET BILL_RT_AMT = RIGHT(BILL_RT_AMT, LEN(BILL_RT_AMT) - 1)
       WHERE LEFT(LTRIM(BILL_RT_AMT), 1) = CHAR(36) -- '$'

      SET @row_count = @@ROWCOUNT
      PRINT 'Number of XX_PLC_RATE_UPDATE_STG records with the dollar sign in column BILL_RT_AMT removed: ' + CAST(@row_count as VARCHAR(10))
   END
ELSE
   PRINT 'Number of XX_PLC_RATE_UPDATE_STG records with BILL_RT_AMT values having CHAR(36), the dollar sign, in the leftmost position found: 0'

BL_ERROR_HANDLER:

-- Return success execution status to the calling (caller) SP
SET @exec_stat = 0

END TRY

BEGIN CATCH
   -- Retrieve error information
   SELECT @SS_Error_Number = ERROR_NUMBER(), @SS_Error_Severity = ERROR_SEVERITY(), @SS_Error_State = ERROR_STATE(),
          @SS_Error_Procedure = ERROR_PROCEDURE(), @SS_Error_Line = ERROR_LINE(), @SS_Error_Message = ERROR_MESSAGE()

   -- Build customized error message
   SET @user_error_msg = 'ERROR ' + CAST(@SS_Error_Number as VARCHAR(15)) + ': ' + @SS_Error_Message + ' [' +
                         @SS_Error_Procedure + ', Line ' + CAST(@SS_Error_Line as VARCHAR(10)) + ']'

   -- Display the customized error message to the console
   PRINT @user_error_msg

   -- Return output parameter value containing the customized error message to the calling (caller) SP
   SET @out_STATUS_DESCRIPTION = SUBSTRING(@user_error_msg, 1, 240)

   -- Return failure execution status to the calling (caller) SP
   SET @exec_stat = 1
END CATCH

SET NOCOUNT OFF
RETURN(@exec_stat)

END

GO

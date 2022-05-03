USE [IMAPSStg]
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PLC_RATE_UPDATE_CP_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   DROP PROCEDURE [dbo].[XX_PLC_RATE_UPDATE_CP_SP]
GO

CREATE PROCEDURE [dbo].[XX_PLC_RATE_UPDATE_CP_SP]
(
@in_STATUS_RECORD_NUM   integer,
@out_STATUS_DESCRIPTION varchar(255) = NULL OUTPUT
)
AS

/***********************************************************************************************************
Name:    XX_PLC_RATE_UPDATE_CP_SP
Author:  HVT
Created: 02/05/2018
Purpose: Update Costpoint tables Deltek.BILL_LAB_CAT and Deltek.PROJ_LAB_CAT_RT_SC directly.
         Archive PLC rates update files.
         Called by XX_PLC_RATE_RUN_INTERFACE_SP.

Notes:   Reference CR-10162 (IMAPS Help Request 20180108122548) Automate the process of updating
         the DDOU PLC rates data in Costpoint.
************************************************************************************************************/

BEGIN

DECLARE @SP_NAME                  sysname,
        @PLC_RATES_INTERFACE_NAME varchar(50),
        @PLC_RATES_TEXT_FILE      sysname,
        @ARCHIVE_DIR              sysname,
        @PLC_rates_file           sysname,
        @UPDATE_user              varchar(20),
        @PROJ_ID                  varchar(30),
        @BILL_LAB_CAT_CD          varchar(6),
        @BILL_RT_AMT              decimal(10, 4),
        @S_BILL_RT_TYPE_CD        varchar(1),
        @START_DT                 datetime,
        @END_DT                   datetime,
        @lcv                      integer,
        @record_key               integer,
        @cmd_str                  varchar(300),
        @ret_code                 integer,
        @row_count                integer,
        @source_data_row_count    integer,
        @cursor_row_count         integer,
        @cursor_error_flag        varchar(1),
        @hit_count                decimal,
        @hit_rate                 decimal(10,6),
        @exec_stat                integer,
        @DOS_error_msg            varchar(70),
        @error_desc               varchar(240),
        @user_error_msg           varchar(500),
        @SS_Error_Number          integer,
        @SS_Error_Message         sysname,
        @SS_Error_Procedure       sysname,
        @SS_Error_Line            smallint,
        @SS_Error_Severity        tinyint,
        @SS_Error_State           smallint

SET NOCOUNT ON

-- Set constants
SET @SP_NAME = 'XX_PLC_RATE_UPDATE_CP_SP'
SET @PLC_RATES_INTERFACE_NAME = 'PLC_RATES'
SET @S_BILL_RT_TYPE_CD = 'B'
SET @DOS_error_msg = 'Execution of DOS command failed: xp_cmdshell() returned error status'

-- Initialize local variables
SET @UPDATE_user = 'SRN-' + CAST(@in_STATUS_RECORD_NUM as varchar(15))
SELECT @source_data_row_count = COUNT(1) FROM dbo.XX_PLC_RATE_UPDATE_STG

BEGIN TRY

-- Step 1
PRINT 'Insert new Deltek.BILL_LAB_CAT parent records ...'

INSERT INTO IMAPS.Deltek.BILL_LAB_CAT
   (BILL_LAB_CAT_CD, BILL_LAB_CAT_DESC, MODIFIED_BY, TIME_STAMP, COMPANY_ID, BILL_AVG_RT_AMT, ROWVERSION)
   SELECT DISTINCT t1.GENL_LAB_CAT_CD, t1.GENL_LAB_CAT_CD, @UPDATE_user, GETDATE(), '1', 0.0000, 1
     FROM dbo.XX_PLC_RATE_UPDATE_STG t1
    WHERE 0 = (select count(1) from IMAPS.Deltek.BILL_LAB_CAT t3 where t3.BILL_LAB_CAT_CD = t1.GENL_LAB_CAT_CD) -- parent record doesn't already exist

SET @row_count = @@ROWCOUNT
PRINT 'Number of Deltek.BILL_LAB_CAT parent records inserted: ' + CAST(@row_count as varchar(15))

-- Step 2
PRINT 'Insert new Deltek.PROJ_LAB_CAT_RT_SC child records ...'

-- Initialize sequential value variables
SELECT @record_key = MAX(PROJ_LC_RT_KEY) FROM IMAPS.Deltek.PROJ_LAB_CAT_RT_SC
SET @record_key = @record_key + 1
SET @lcv = 0
SET @cursor_error_flag = 'N'

-- Get the total number of rows projected to be fetched by the cursor to aid error handling when cursor processing fails.
SELECT @row_count = COUNT(1)
  FROM dbo.XX_PLC_RATE_UPDATE_STG t1
 WHERE 0 = (select COUNT(1)
              from IMAPS.Deltek.PROJ_LAB_CAT_RT_SC t2
             where (t2.PROJ_ID + t2.BILL_LAB_CAT_CD) = (t1.PROJ_ID + t1.GENL_LAB_CAT_CD)
               and (t2.START_DT = t1.START_DT and t2.END_DT = t1.END_DT)
           )

DECLARE PLC_cursor CURSOR FAST_FORWARD FOR
   SELECT t1.PROJ_ID, t1.GENL_LAB_CAT_CD, t1.BILL_RT_AMT, t1.START_DT, t1.END_DT
     FROM dbo.XX_PLC_RATE_UPDATE_STG t1
    WHERE 0 = (select COUNT(1)
                 from IMAPS.Deltek.PROJ_LAB_CAT_RT_SC t2
                where (t2.PROJ_ID + t2.BILL_LAB_CAT_CD) = (t1.PROJ_ID + t1.GENL_LAB_CAT_CD)
                  and (t2.START_DT = t1.START_DT and t2.END_DT = t1.END_DT)
              )

OPEN PLC_cursor
FETCH PLC_cursor INTO @PROJ_ID, @BILL_LAB_CAT_CD, @BILL_RT_AMT, @START_DT, @END_DT

-- Determine the total number of rows in the cursor to aid error handling when cursor processing fails.
SET @cursor_row_count = @@CURSOR_ROWS

IF @cursor_row_count = -1
   BEGIN
      PRINT 'The cursor is dynamic: Not all qualified rows are retrieved at once.'
      SET @cursor_row_count = @row_count
      PRINT 'Total number of cursor rows: ' + CAST(@row_count as varchar(15))
   END

WHILE (@@FETCH_STATUS = 0)
   BEGIN
      SET @lcv = @lcv + 1

      INSERT INTO IMAPS.Deltek.PROJ_LAB_CAT_RT_SC
         VALUES(@record_key, @PROJ_ID, @BILL_LAB_CAT_CD, @BILL_RT_AMT, @S_BILL_RT_TYPE_CD, @START_DT, @END_DT, @UPDATE_user, GETDATE(), 1, '1', 0.0000)

      SET @record_key = @record_key + 1

      FETCH PLC_cursor INTO @PROJ_ID, @BILL_LAB_CAT_CD, @BILL_RT_AMT, @START_DT, @END_DT
   END

CLOSE PLC_cursor
DEALLOCATE PLC_cursor

PRINT 'Total number of Deltek.PROJ_LAB_CAT_RT_SC child records inserted via cursor: ' + CAST(@lcv as varchar(5))

-- Step 3
PRINT 'Update Deltek.PROJ_LAB_CAT_RT_SC child records ...'

UPDATE IMAPS.Deltek.PROJ_LAB_CAT_RT_SC
   SET BILL_RT_AMT = t2.BILL_RT_AMT,
       ROWVERSION  = ROWVERSION + 1,
       MODIFIED_BY = @UPDATE_user,
       TIME_STAMP  = GETDATE()
  FROM IMAPS.Deltek.PROJ_LAB_CAT_RT_SC t1,
       dbo.XX_PLC_RATE_UPDATE_STG t2
 WHERE t1.PROJ_ID         = t2.PROJ_ID
   AND t1.BILL_LAB_CAT_CD = t2.GENL_LAB_CAT_CD
   AND t1.START_DT        = t2.START_DT
   AND t1.END_DT          = t2.END_DT
   AND t1.BILL_RT_AMT    != t2.BILL_RT_AMT

SET @row_count = @@ROWCOUNT
PRINT 'Number of Deltek.PROJ_LAB_CAT_RT_SC child records updated: ' + CAST(@row_count as varchar(15))

PRINT 'Update interface run status record with update results ...'

SELECT @row_count = COUNT(1) FROM dbo.XX_PLC_RATE_UPDATE_STG

-- Use Deltek.PROJ_LAB_CAT_RT_SC child records created by Step 2 for a measure of success
UPDATE dbo.XX_IMAPS_INT_STATUS
   SET RECORD_COUNT_INITIAL = @source_data_row_count,
       RECORD_COUNT_SUCCESS = @lcv,
       MODIFIED_BY = SUSER_SNAME(),
       MODIFIED_DATE = GETDATE()
 WHERE INTERFACE_NAME = @PLC_RATES_INTERFACE_NAME
   AND STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

PRINT 'Move user-supplied PLC rates update files to the archive folder ...'

-- Get source directory
SELECT @PLC_RATES_TEXT_FILE = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = @PLC_RATES_INTERFACE_NAME
   AND PARAMETER_NAME = 'PLC_RATES_TEXT_FILE' -- D:\IMAPS_DATA\inbox\PLC_RATES\

-- Get destination directory
SELECT @ARCHIVE_DIR = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = @PLC_RATES_INTERFACE_NAME
   AND PARAMETER_NAME = 'ARCHIVE_DIR' -- D:\IMAPS_DATA\Interfaces\ARCHIVE\PLC_RATES\

SET @PLC_rates_file = @PLC_RATES_TEXT_FILE + 'PLC_Rates_' + CAST(@in_STATUS_RECORD_NUM as varchar(15)) + '.*'

SET @cmd_str = 'MOVE ' + @PLC_rates_file + ' ' + @ARCHIVE_DIR
PRINT 'DOS command: ' + @cmd_str

EXEC @ret_code = master.dbo.xp_cmdshell @cmd_str

IF @ret_code <> 0
   BEGIN
      SET @out_STATUS_DESCRIPTION = 'NOTICE: Attempt to archive PLC rates update files via DOS command failed.'
      PRINT @out_STATUS_DESCRIPTION 
      RAISERROR(@DOS_error_msg, 16, 1)
   END
ELSE
   BEGIN
      SET @out_STATUS_DESCRIPTION = 'PLC rates update files are archived successfully.'
      PRINT @out_STATUS_DESCRIPTION
   END

PRINT 'Return success execution status to the calling (caller) SP'
SET @exec_stat = 0

END TRY

BEGIN CATCH
   IF @lcv < @cursor_row_count
      BEGIN
         PRINT 'Cursor loop processing failed. Clean up cursor. [Post-error]'
         CLOSE PLC_cursor
         DEALLOCATE PLC_cursor

         SET @error_desc = 'NOTICE: CURSOR loop processing failed. Number of Deltek.PROJ_LAB_CAT_RT_SC child records inserted: ' + CAST(@lcv - 1 as varchar(10))

         SET @cursor_error_flag = 'Y'
         RAISERROR(@error_desc, 16, 1)
      END

   -- Retrieve error information
   SELECT @SS_Error_Number = ERROR_NUMBER(), @SS_Error_Severity = ERROR_SEVERITY(), @SS_Error_State = ERROR_STATE(),
          @SS_Error_Procedure = ERROR_PROCEDURE(), @SS_Error_Line = ERROR_LINE(), @SS_Error_Message = ERROR_MESSAGE()

   -- Build customized error message
   SET @user_error_msg = 'ERROR ' + CAST(@SS_Error_Number as varchar(15)) + ': ' + @SS_Error_Message + ' [' +
                         @SS_Error_Procedure + ', Line ' + CAST(@SS_Error_Line as VARCHAR(10)) + ']'

   -- Display the customized error message to the console
   PRINT @user_error_msg

   -- Return output parameter value containing the customized error message to the calling (caller) SP
   SET @OUT_STATUS_DESCRIPTION = SUBSTRING(@user_error_msg, 1, 240)

   -- Return failure execution status to the calling (caller) SP
   SET @exec_stat = 1
END CATCH

SET NOCOUNT OFF
RETURN(@exec_stat)

END

GO

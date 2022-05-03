USE [IMAPSStg]
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PLC_RATE_CHECK_RESOURCE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   DROP PROCEDURE [dbo].[XX_PLC_RATE_CHECK_RESOURCE_SP]
GO

CREATE PROCEDURE [dbo].[XX_PLC_RATE_CHECK_RESOURCE_SP]
(
@in_STATUS_RECORD_NUM   integer,
@out_STATUS_DESCRIPTION varchar(255) = NULL OUTPUT
)
AS

/***********************************************************************************************************
Name:    XX_PLC_RATE_CHECK_RESOURCE_SP
Author:  HVT
Created: 02/05/2018
Purpose: Verify that the customer-supplied PLC rates update files exists in their expected file storage
         location.
         Determine the existence of the files by attempting to rename the files to more uniformed names.
         Called by XX_PLC_RATE_RUN_INTERFACE_SP.

Notes:   Reference CR-10162 (IMAPS Help Request 20180108122548) Automate the process of updating
         the DDOU PLC rates data in Costpoint.

         Input data preparation:

         The user places two files in the designated file folder:
         (1) The original customer-supplied Excel PLC file. If there are more than one Excel files (e.g.,
             one for project DDOU.ICAB and one for project DDOU.NPUB), then the user must merge the two
             files into a single Excel file and rename the file using the format:
                DDOU MMM YYYY Rate Updates.xlsx
         (2) The original customer-supplied Excel PLC file saved as a Text (MS-DOS) (*.txt) file. The use
             must rename the text file using the format:
                DDOU MMM YYYY Rate Updates.txt
************************************************************************************************************/

BEGIN

DECLARE @SP_NAME                  sysname,
        @PLC_RATES_FILES          sysname,
        @PLC_rates_txt_file       sysname,
        @PLC_rates_Excel_file     sysname,
        @cmd_str                  varchar(300),
        @search_str               varchar(30),
        @DOS_error_msg            varchar(70),
        @ret_code                 integer,
        @exec_stat                integer,
        @user_error_msg           varchar(500),
        @SS_Error_Number          integer,
        @SS_Error_Message         sysname,
        @SS_Error_Procedure       sysname,
        @SS_Error_Line            smallint,
        @SS_Error_Severity        tinyint,
        @SS_Error_State           smallint

SET NOCOUNT ON

-- Set constants
SET @SP_NAME = 'XX_PLC_RATE_CHECK_RESOURCE_SP'
SET @DOS_error_msg = 'Execution of DOS command failed: xp_cmdshell() returned error status'

SET @PLC_rates_txt_file = 'PLC_Rates_' + CAST(@in_STATUS_RECORD_NUM as varchar(15)) + '.txt'    -- E.g., PLC_Rates_12345.txt
SET @PLC_rates_Excel_file = 'PLC_Rates_' + CAST(@in_STATUS_RECORD_NUM as varchar(15)) + '.xlsx' -- E.g., PLC_Rates_12345.xlsx

BEGIN TRY

-- Ensure that the user-supplied Excel file saved as PLC rates update text file exists in the INBOX folder by renaming this file to PLC_Rates_nnnnn.txt.
-- where nnnnn is STATUS_RECORD_NUM's value. When RENAME-ing a file, specifying a new drive or path for your destination file is not allowed.

PRINT 'Verify that the user-supplied Excel file saved as PLC rates update text file exists in the target input data folder ...'

SELECT @PLC_RATES_FILES = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'PLC_RATES'
   AND PARAMETER_NAME = 'PLC_RATES_TEXT_FILE' -- D:\IMAPS_DATA\inbox\PLC_RATES\

SET @search_str = '*' + 'DDOU' + '*' + CONVERT(varchar, DATEPART(yyyy, GETDATE())) + '*' + '.txt' -- E.g., *DDOU*2019*.txt
PRINT '@search_str = ' + @search_str

SET @cmd_str = 'DIR ' + @PLC_RATES_FILES + @search_str
PRINT 'DOS command: ' + @cmd_str

EXEC @ret_code = master.dbo.xp_cmdshell @cmd_str

IF @ret_code <> 0
   BEGIN
      -- @ret_code = 1
      PRINT 'NOTICE: Attempt to locate the user-supplied PLC rates update text file failed. The required user-supplied PLC rates update text file does not exist.'
      RAISERROR(@DOS_error_msg, 16, 1)
   END
ELSE
   PRINT 'The user-supplied PLC rates update text file was successfully located.'


PRINT 'Rename user-supplied PLC rates update text file ...'

SELECT @PLC_RATES_FILES = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'PLC_RATES'
   AND PARAMETER_NAME = 'EXCEL_PLC_RATE_FILE' -- D:\IMAPS_DATA\inbox\PLC_RATES\

SET @search_str = '*' + 'DDOU' + '*' + CONVERT(varchar, DATEPART(yyyy, GETDATE())) + '*' + '.txt' -- E.g., *DDOU*2019*.txt
PRINT '@search_str = ' + @search_str

SET @cmd_str = 'RENAME ' + @PLC_RATES_FILES + @search_str + ' ' + @PLC_rates_txt_file
PRINT 'DOS command: ' + @cmd_str

EXEC @ret_code = master.dbo.xp_cmdshell @cmd_str

IF @ret_code <> 0
   BEGIN
      -- @ret_code = 1
      SET @out_STATUS_DESCRIPTION = 'NOTICE: Attempt to rename the PLC rates update text file to ' + @PLC_rates_txt_file + ' failed. ' +
                                    'The required user-supplied PLC rates update text file does not exist.'
      PRINT @out_STATUS_DESCRIPTION
      RAISERROR(@DOS_error_msg, 16, 1)
   END
ELSE
   BEGIN
      SET @out_STATUS_DESCRIPTION = 'The user-supplied PLC rates update text file is renamed successfully.'
      PRINT @out_STATUS_DESCRIPTION
   END

-- Ensure that the customer-supplied Excel PLC file (e.g., DDOU_ICAB 2019 Rate Updates.xlsx) exists in the INBOX folder by renaming
-- this file to PLC_Rates_nnnnn.xlsx. When RENAME-ing a file, specifying a new drive or path for your destination file is not allowed.

PRINT 'Rename user-supplied PLC rates update Excel file ...'

SET @search_str = '*' + 'DDOU' + '*' + CONVERT(varchar, DATEPART(yyyy, GETDATE())) + '*' + '.xlsx' -- Example: *DDOU*2019*.xlsx
PRINT '@search_str = ' + @search_str

SET @cmd_str = 'RENAME ' + @PLC_RATES_FILES + @search_str + ' ' + @PLC_rates_Excel_file
PRINT 'DOS command: ' + @cmd_str

EXEC @ret_code = master.dbo.xp_cmdshell @cmd_str

IF @ret_code <> 0
   BEGIN
      SET @out_STATUS_DESCRIPTION = 'NOTICE: Attempt to rename the PLC rates update Excel file to ' + @PLC_rates_Excel_file + ' failed. ' +
                                    'The required user-supplied PLC rates update Excel file does not exist.'
      PRINT @out_STATUS_DESCRIPTION
      RAISERROR(@DOS_error_msg, 16, 1)
   END
ELSE
   BEGIN
      SET @out_STATUS_DESCRIPTION = 'The user-supplied Excel PLC rates update file was renamed successfully.'
      PRINT @out_STATUS_DESCRIPTION
   END

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

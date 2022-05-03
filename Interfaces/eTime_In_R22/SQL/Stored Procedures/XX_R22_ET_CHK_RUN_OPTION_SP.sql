IF OBJECT_ID('dbo.XX_R22_ET_CHK_RUN_OPTION_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_ET_CHK_RUN_OPTION_SP
    IF OBJECT_ID('dbo.XX_R22_ET_CHK_RUN_OPTION_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_ET_CHK_RUN_OPTION_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_ET_CHK_RUN_OPTION_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER ON
go


CREATE PROCEDURE [dbo].[XX_R22_ET_CHK_RUN_OPTION_SP]
(
@in_IMAPS_db_name        sysname,
@in_IMAPS_table_owner    sysname,
@in_user_password        sysname,
@in_Data_FName           varchar(100),
@in_Dtl_Fmt_FName        varchar(100),
@in_Ftr_Fmt_FName        varchar(100), 
@out_STATUS_DESCRIPTION  varchar(255) OUTPUT
)
AS

/************************************************************************************************  
Name:       XX_ET_CHK_RUN_OPTION_SP
Author:     HVT
Created:    04/25/2006  
Purpose:    Since the user is now given the option to run the eTime interface to post timesheet
            data belonging to the previous month to the current month, verify that all conditions
            required to run eTime interface in the current month are met.

            Called by XX_RUN_ETIME_INTERFACE.

Result Set: None

Notes:      This program is part of the solution for Defect 782.
            Modified for CR-1863 , changed from ETIME to ETIME_R22

Modified: 05/05/2011 for CR-3749 IMAPS shared issue

**************************************************************************************************/  
  
DECLARE @SP_NAME                    sysname,
        @ETIME_INTERFACE            varchar(50),
        @INTERFACE_STATUS_COMPLETED varchar(20),
        @last_STATUS_RECORD_NUM     integer,
        @last_issued_STATUS_CODE    varchar(20),
        @IMAPS_error_code           integer,
        @SQLServer_error_code       integer,
        @error_msg_placeholder1     sysname,
        @ts_period_end_date         datetime,
        @SERVER_NAME                sysname,
        @DOUBLE_QUOTE               char(1),
        @PERIOD                     char(1),
        @SPACE                      char(1),
        @cmd                        varchar(255),
        @login_name                 varchar(16),
        @password                   varchar(16),
        @row_count	            integer,
        @ret_code	            integer,
        @current_date               datetime

-- set local constants
SET @SP_NAME = 'XX_R22_ET_CHK_RUN_OPTION_SP'
SET @ETIME_INTERFACE = 'ETIME_R22' -- Modified for CR-1863
SET @INTERFACE_STATUS_COMPLETED = 'COMPLETED'
SET @SERVER_NAME = @@servername
SET @DOUBLE_QUOTE = '"'
SET @SPACE = ' '
SET @PERIOD = '.'

-- initialize local variables
SET @login_name = '' --Modified for CR-3749
SET @current_date = GETDATE()

PRINT 'Verify that all conditions required to run eTime interface in the current month are met ...'

/*
 * Make sure the interface run is not repeated with the same input file name.
 * Input file name must not be of a file that has already been successfully processed.
 *
 * The value of @in_Data_FName could come from XX_PROCESSING_PARAMETERS.PARAMETER_VALUE
 * of a previously completed run which includes a carriage return character at the
 * rightmost position.
 */

IF SUBSTRING(@in_Data_FName, LEN(@in_Data_FName), 1) = CHAR(13)
   OR SUBSTRING(@in_Data_FName, LEN(@in_Data_FName), 1) = CHAR(10)
   SET @in_Data_FName = SUBSTRING(@in_Data_FName, 1, LEN(@in_Data_FName) - 1)

SELECT @row_count = COUNT(1)
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE INTERFACE_FILE_NAME = @in_Data_FName
   AND INTERFACE_NAME = @ETIME_INTERFACE

IF @row_count = 1
   BEGIN
      SELECT @last_STATUS_RECORD_NUM = STATUS_RECORD_NUM, @last_issued_STATUS_CODE = STATUS_CODE
        FROM dbo.XX_IMAPS_INT_STATUS
       WHERE INTERFACE_FILE_NAME = @in_Data_FName
         AND INTERFACE_NAME = @ETIME_INTERFACE

      IF @last_issued_STATUS_CODE = @INTERFACE_STATUS_COMPLETED
         BEGIN
            SET @IMAPS_error_code = 501 -- The input file has been processed successfully at least once before.
            GOTO BL_ERROR_HANDLER
         END
   END

/*
 * The current interface execution date's month must be different from that of the timesheet period ending date.
 */

PRINT 'Validate user''s interface run option to post timesheets from another month to the current month ...'

-- construct the shell command line
SET @cmd = 'bcp' + @SPACE
SET @cmd = @cmd + @DOUBLE_QUOTE + @in_IMAPS_db_name + @PERIOD + @in_IMAPS_table_owner + @PERIOD + 'XX_R22_IMAPS_ET_IN_UTIL' + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + 'IN' + @SPACE + @DOUBLE_QUOTE + @in_Data_FName + @DOUBLE_QUOTE + @SPACE

--SET @cmd = @cmd + 'IN' + @SPACE + @DOUBLE_QUOTE + '\\Ffx2kdap11\inbox\etime\EV02UAT_4_7_062.txt' + @DOUBLE_QUOTE + @SPACE

SET @cmd = @cmd + '-S' + @SPACE + @DOUBLE_QUOTE + @SERVER_NAME + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-f' + @SPACE + @DOUBLE_QUOTE + @in_Dtl_Fmt_FName + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-T' + @SPACE + @DOUBLE_QUOTE /* + @login_name + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-P' + @SPACE + @DOUBLE_QUOTE + @in_user_password + @DOUBLE_QUOTE */ -- Modified for CR-3749 

PRINT 'Populate utility table XX_R22_IMAPS_ET_IN_UTIL with timesheet data using bcp ...'
PRINT @cmd


-- guarantee that the target table is empty
TRUNCATE TABLE dbo.XX_R22_IMAPS_ET_IN_UTIL

EXEC @ret_code = master.dbo.xp_cmdshell @cmd

IF @ret_code <> 0
   BEGIN
      SET @IMAPS_error_code = 400 -- Attempt to BULK INSERT into table %1 failed.
      SET @error_msg_placeholder1 = 'table XX_R22_IMAPS_ET_IN_UTIL'
      GOTO BL_ERROR_HANDLER
   END

-- get rid of the footer record (see XX_IMAPS_ET_FTR_IN_TMP which provides the date and time the eT&E input file is created)
DELETE FROM dbo.XX_R22_IMAPS_ET_IN_UTIL where EMP_SERIAL_NUM = '999999'

select @ts_period_end_date = MAX(CAST((TS_YEAR + '-' + TS_MONTH + '-' + TS_DAY) AS datetime))
  from dbo.XX_R22_IMAPS_ET_IN_UTIL

-- this scenario: the timesheet period end date is a future date
IF @ts_period_end_date >= @current_date
   GOTO BL_ERROR_HANDLER

-- this scenario: when the timesheet period end date's month is December, make sure the current date is January of the new year
IF (DATEPART(MONTH, @ts_period_end_date) = 12) AND
   (DATEPART(MONTH, @current_date) != 1 OR (DATEPART(YEAR, @current_date) - DATEPART(YEAR, @ts_period_end_date)) != 1)
   GOTO BL_ERROR_HANDLER

-- clean up
TRUNCATE TABLE dbo.XX_R22_IMAPS_ET_IN_UTIL

RETURN(0)

BL_ERROR_HANDLER:

-- clean up
TRUNCATE TABLE dbo.XX_R22_IMAPS_ET_IN_UTIL

IF @IMAPS_error_code IS NOT NULL
   EXEC dbo.XX_ERROR_MSG_DETAIL
      @in_error_code          = @IMAPS_error_code,
      @in_display_requested   = 1,
      @in_placeholder_value1  = @error_msg_placeholder1,
      @in_calling_object_name = @SP_NAME,
      @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT
ELSE
   PRINT 'USER ERROR: The eTime interface may not be run for the current month.' + ' [' + @SP_NAME + ']'

RETURN(1)


go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_R22_ET_CHK_RUN_OPTION_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_ET_CHK_RUN_OPTION_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_ET_CHK_RUN_OPTION_SP >>>'
go

USE [IMAPSStg]
GO
/****** Object:  StoredProcedure [dbo].[XX_RETRORATE_PROCESS_CP_ERROR_LOG_SP]    Script Date: 05/05/2011 13:27:38 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS (SELECT * FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[DBO].[XX_RETRORATE_PROCESS_CP_ERROR_LOG_SP]') AND OBJECTPROPERTY(ID, N'ISPROCEDURE') = 1)
DROP PROCEDURE [DBO].[XX_RETRORATE_PROCESS_CP_ERROR_LOG_SP]
GO


CREATE PROCEDURE [dbo].[XX_RETRORATE_PROCESS_CP_ERROR_LOG_SP]
(
-- Defect_592_Begin
@in_STATUS_RECORD_NUM      integer,
-- Defect_592_End
@out_SQLServer_error_code  integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION    varchar(255) = NULL OUTPUT
)
AS
BEGIN
/****************************************************************************************************
Name:       XX_RETRORATE_PROCESS_CP_ERROR_LOG_SP
Author:     HVT
Created:    12/20/2005
Purpose:    Run this stored procedure for the Retro Cost Rate Change application.
            After the Costpoint timesheet preprocessor was run and an error log file was produced in
            the process, process this file to insert error records in the error table.
            Called by XX_RETRORATE_RUN_INTERFACE_SP.
Parameters: 
Result Set: None
Notes:

Defect 592  Update the XX_IMAPS_INT_STATUS record with processing statistics.
Defect 612  Fix the display of the count values. Add ISNULL().
****************************************************************************************************/

DECLARE @SP_NAME                        sysname,
        @IMAPS_DB_NAME                  sysname,
        @IMAPS_SCHEMA_OWNER             sysname,
        --@IN_USER_PASSWORD               sysname, --CR3728
        @IN_TS_PREP_ERRORS_TABLENAME    sysname,
        @IN_TS_PREP_ERR_FORMAT_FILENAME sysname,
        @OUT_CP_ERROR_FILENAME          sysname,
		@OUT_QUERYOUT_SQL				sysname,
        @shell_cmd                      varchar(255),
        @ret_code                       integer,
-- Defect_592_Begin
        @row_count                      integer,
        @total_RECORD_COUNT_ERROR       integer,
        @total_LAB_CST_AMT_ERROR        decimal(14, 2)
-- Defect_592_End


--begin change KM 4/13/06
declare @TS_PREP sysname,
	@ARCH_DIR sysname,
	@DISTINCT_FILENAME sysname,
	@CMD varchar(500),
	@error_msg_placeholder1 sysname,
	@error_msg_placeholder2 sysname

SELECT 	@ARCH_DIR = PARAMETER_VALUE
FROM 	DBO.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'RETRORATE'
AND 	PARAMETER_NAME = 'ARCH_DIR'

SELECT 	@TS_PREP = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	INTERFACE_NAME_CD = 'RETRORATE'
AND	PARAMETER_NAME = 'OUT_TS_PREP_FILENAME'

--ARCHIVE TS_PREP
SET @CMD = 'MOVE ' + REPLACE(@TS_PREP, '.TXT', '.ZZZ') + ' ' + @ARCH_DIR + CAST(@in_STATUS_RECORD_NUM as varchar(10)) + '_RATE_RETRO_TS_PREP.TXT'
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
  BEGIN
      SET @error_msg_placeholder1 = 'archive file'
      SET @error_msg_placeholder2 = 'RATE_RETRO_TS_PREP.TXT'
      GOTO BL_ERROR_HANDLER
  END
--end change KM 4/13/06...continued below


-- set local constants
SET @SP_NAME = 'XX_RETRORATE_PROCESS_CP_ERROR_LOG_SP'
SET @IMAPS_DB_NAME = db_name()

-- Defect_592_Begin
-- initialize local variables
SET @total_RECORD_COUNT_ERROR = 0
SET @total_LAB_CST_AMT_ERROR = 0
-- Defect_592_End

-- retrieve input parameter data necessary to run this stored procedure
EXEC dbo.XX_RETRORATE_GET_PROCESSING_PARAMS_SP
   @out_IMAPS_SCHEMA_OWNER               = @IMAPS_SCHEMA_OWNER             OUTPUT,
   --@out_IN_USER_PASSWORD                 = @IN_USER_PASSWORD               OUTPUT, --CR3728
   @out_QUERYOUT_SQL					 = @OUT_QUERYOUT_SQL				OUTPUT, --CR 3728
   @out_IN_TS_PREP_ERRORS_TABLENAME      = @IN_TS_PREP_ERRORS_TABLENAME    OUTPUT,
   @out_IN_TS_PREP_ERROR_FORMAT_FILENAME = @IN_TS_PREP_ERR_FORMAT_FILENAME OUTPUT,
   @out_OUT_CP_TS_PREP_ERROR_FILENAME    = @OUT_CP_ERROR_FILENAME          OUTPUT

IF @ret_code <> 0 -- the called sp returned an error status
   RETURN(1)

IF @OUT_CP_ERROR_FILENAME IS NULL
   BEGIN
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = 209, -- No %1 exist to %2.
         @in_display_requested    = 1,
         @in_SQLServer_error_code = NULL,
         @in_placeholder_value1   = 'Costpoint timesheet preprocessor error file name parameter value',
         @in_placeholder_value2   = 'construct shell command line',
         @in_calling_object_name  = @SP_NAME,
         @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
      RETURN(1)
   END

/*
 * After the Costpoint timesheet preprocessor finished its run, if it rejected any records due to validation errors,
 * it wrote those records to a file, RATE_RETRO_TS_PREP.err, which this interface had specified.
 * Check for the existence of this error log file.
 */

SET @shell_cmd = 'DIR ' + @OUT_CP_ERROR_FILENAME
EXEC @ret_code = master.dbo.xp_cmdshell @shell_cmd

/*
 * Error file does not exist: no error processing needed, exit
 */
IF @ret_code = 1
   BEGIN
      PRINT 'No error log file produced by Costpoint timesheet preprocessor to consider ...'
      RETURN(0)
   END

PRINT 'Process error log file (if any) produced by the Costpoint timesheet preprocessor using bcp ...'

-- Table XX_RATE_RETRO_TS_PREP_ERRORS, used below, is emptied in XX_RETRORATE_PREPARE_DATA_SP

/*
 * Costpoint-generated error file exists. Insert records into table XX_RATE_RETRO_TS_PREP_ERRORS
 * via the bulk copy utility (bcp) which uses the Costpoint error file RATE_RETRO_TS_PREP.err as source input.
 */

EXEC @ret_code = dbo.XX_EXEC_SHELL_CMD_INSERT_OSUSER
   @in_IMAPS_db_name       = @IMAPS_DB_NAME,
   @in_IMAPS_table_owner   = @IMAPS_SCHEMA_OWNER,
   @in_dest_table          = @IN_TS_PREP_ERRORS_TABLENAME,
   @in_format_file         = @IN_TS_PREP_ERR_FORMAT_FILENAME,
   @in_input_file          = @OUT_CP_ERROR_FILENAME,
   --@in_usr_password        = @IN_USER_PASSWORD, --CR3728
   @out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION OUTPUT

IF @ret_code <> 0
   RETURN(1)

--begin change KM 4/13/06
-- Get Rid of Non Distinct Records If Needed
IF (
	(SELECT COUNT(1) FROM dbo.XX_RATE_RETRO_TS_PREP_ERRORS)
	<>
	(SELECT COUNT(DISTINCT NOTES) FROM dbo.XX_RATE_RETRO_TS_PREP_ERRORS)
)
BEGIN
	PRINT 'Costpoint Error file contains duplicate records...'
	
	--CREATE DISTINCT ERROR FILE
	SET @DISTINCT_FILENAME = REPLACE(@OUT_CP_ERROR_FILENAME, '.ERR' , '_DISTINCT.ERR')


	-- CR 3728 begin
	--Replace BCP queryout with call to XX_EXEC_SHELL_CMD_QUERYOUT_OSUSER 
	EXEC @ret_code = dbo.XX_EXEC_SHELL_CMD_QUERYOUT_OSUSER
		@in_query_sql			= @OUT_QUERYOUT_SQL,
		@in_format_file			= @IN_TS_PREP_ERR_FORMAT_FILENAME,
		@in_output_file          = @DISTINCT_FILENAME,
		@out_STATUS_DESCRIPTION	= @out_STATUS_DESCRIPTION OUTPUT


	--SET @CMD = 'BCP "SELECT DISTINCT * FROM IMAPSStg.dbo.XX_RATE_RETRO_TS_PREP_ERRORS" queryout ' + @DISTINCT_FILENAME + ' -f' + @IN_TS_PREP_ERR_FORMAT_FILENAME + ' -S' + @@servername + ' -Uimapsstg ' + '-P' + @IN_USER_PASSWORD
	--EXEC @ret_code = master.dbo.xp_cmdshell @CMD

	--CR3728 end



	IF @ret_code <> 0
	   BEGIN
	      SET @error_msg_placeholder1 = 'BCP DISTINCT error file FROM'
	      SET @error_msg_placeholder2 = 'XX_RATE_RETRO_TS_PREP_ERRORS'
	      GOTO BL_ERROR_HANDLER
	   END
	
	--ARCHIVE DISTINCT ERROR FILE
	SET @CMD = 'MOVE ' + @DISTINCT_FILENAME + ' ' + @ARCH_DIR + CAST(@in_STATUS_RECORD_NUM as varchar(10)) + '_RATE_RETRO_TS_PREP_DISTINCT.ERR'
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD
	IF @ret_code <> 0
	  BEGIN
	      SET @error_msg_placeholder1 = 'archive file'
	      SET @error_msg_placeholder2 = 'RATE_RETRO_TS_PREP_DISTINCT.ERR'
	      GOTO BL_ERROR_HANDLER
	  END
END
--end change KM 4/13/06



-- Defect_592_Begin
-- Report the total records and labor cost amount that did not get processed by the Costpoint timesheet preprocessor

-- verify that table XX_RATE_RETRO_TS_PREP_ERRORS does have records
SELECT @total_RECORD_COUNT_ERROR = COUNT(distinct notes) FROM dbo.XX_RATE_RETRO_TS_PREP_ERRORS

IF @total_RECORD_COUNT_ERROR > 0
   BEGIN
      -- the total labor cost amount from all error input timesheet records represents the total cost that failed processing
      SELECT @total_LAB_CST_AMT_ERROR = SUM(CONVERT(decimal(14, 2), LAB_CST_AMT))
        FROM dbo.XX_RATE_RETRO_TS_PREP_TEMP
	WHERE NOTES IN (SELECT DISTINCT NOTES FROM dbo.XX_RATE_RETRO_TS_PREP_ERRORS)

      UPDATE dbo.XX_IMAPS_INT_STATUS
         SET RECORD_COUNT_ERROR = @total_RECORD_COUNT_ERROR,
             AMOUNT_FAILED      = ISNULL(@total_LAB_CST_AMT_ERROR, 0),
             MODIFIED_BY        = SUSER_SNAME(),
             MODIFIED_DATE      = GETDATE()
       WHERE STATUS_RECORD_NUM  = @in_STATUS_RECORD_NUM

      SET @row_count = @@ROWCOUNT

      IF @row_count = 0
         BEGIN
            -- Attempt to update a XX_IMAPS_INT_STATUS record with processing error totals failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code          = 204,
               @in_display_requested   = 1,
               @in_placeholder_value1  = 'update',
               @in_placeholder_value2  = 'a XX_IMAPS_INT_STATUS record with processing error totals',
               @in_calling_object_name = @SP_NAME,
               @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END
   END

-- Defect_592_End


--change KM 4/13/06
--ARCHIVE EVERYTHING
--NO DELETION
--NO SITTING IN PROCESS FOLDER

/*
 * Clean up: The flat file produced by this interface and used by the Costpoint timesheet preprocessor
 * can be overwritten and hence need not be removed. Only the error log file produced by the Costpoint
 * timesheet preprocessor needs removal because this file is not necessarily created every time the
 * Costpoint timesheet preprocessor is invoked.

EXEC @ret_code = dbo.XX_MANAGE_FILE_SP
   @in_shell_cmd = 'DEL',
   @in_arg_1 = @OUT_CP_ERROR_FILENAME

IF @ret_code <> 0
   BEGIN
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = 204, -- Attempt to %1 %2 failed.
         @in_display_requested    = 1,
         @in_SQLServer_error_code = NULL,
         @in_placeholder_value1   = 'delete a file',
         @in_placeholder_value2   = 'via shell command',
         @in_calling_object_name  = @SP_NAME,
         @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
      RETURN(1)
   END
*/

--ARCHIVE REGULAR ERROR FILE
SET @CMD = 'MOVE ' + @OUT_CP_ERROR_FILENAME + ' ' + @ARCH_DIR + CAST(@in_STATUS_RECORD_NUM as varchar(10)) + '_RATE_RETRO_TS_PREP.ERR'
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
  BEGIN
      SET @error_msg_placeholder1 = 'archive file'
      SET @error_msg_placeholder2 = 'RATE_RETRO_TS_PREP.ERR'
      GOTO BL_ERROR_HANDLER
  END


RETURN(0)


BL_ERROR_HANDLER:

 EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code          = 204,
               @in_display_requested   = 1,
               @in_placeholder_value1  = @error_msg_placeholder1,
               @in_placeholder_value2  = @error_msg_placeholder2,
	       @in_calling_object_name = @SP_NAME,
               @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
END







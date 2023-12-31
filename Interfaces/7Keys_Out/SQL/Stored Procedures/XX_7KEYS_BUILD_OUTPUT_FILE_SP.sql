SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_7KEYS_BUILD_OUTPUT_FILE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   drop procedure [dbo].[XX_7KEYS_BUILD_OUTPUT_FILE_SP]
GO



CREATE PROCEDURE dbo.XX_7KEYS_BUILD_OUTPUT_FILE_SP
(
@in_STATUS_RECORD_NUM      integer,
@out_SQLServer_error_code  integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION    varchar(255) = NULL OUTPUT
)
AS
/****************************************************************************************************
Name:       XX_7KEYS_BUILD_OUTPUT_FILE_SP
Author:     HVT
Created:    11/07/2005
Purpose:    Use bcp to create output files for detail and header. The output files are stored in the
            designated FTP directory pending further actions from the next control point.
            Called by XX_7KEYS_RUN_INTERFACE_SP.
Parameters: 
Result Set: None
Notes:

Feature 478 Clean up disabled code.
from CP600001172 to CP600001246
****************************************************************************************************/

DECLARE @SP_NAME                 sysname,
        @SERVER_NAME             sysname,
        @DOUBLE_QUOTE            char(1),
        @PERIOD                  char(1),
        @SPACE                   char(1),
        @cmd                     varchar(255),
        @IMAPS_db_name           sysname,
        @IMAPS_schema_owner      sysname,
        @source_dtl_table        sysname,
        @source_hdr_table        sysname,
        @out_dtl_format_file     sysname,  -- including the file's full directory path
        @out_hdr_format_file     sysname,  -- including the file's full directory path
        @dtl_output_filename     sysname,
        @hdr_output_filename     sysname,
 /*     @login_name              sysname,
        @usr_password            sysname,      CR-3548 03/29/2011 */
        @SQLServer_error_code    integer,
        @IMAPS_error_code        integer,
        @row_count               integer,
        @ret_code                integer

-- set local constants
SET @SP_NAME = 'XX_7KEYS_BUILD_OUTPUT_FILE_SP'
SET @SERVER_NAME = @@servername
SET @DOUBLE_QUOTE = '"'
SET @SPACE = ' '
SET @PERIOD = '.'

-- initialize local variables
SET @IMAPS_error_code = 204

PRINT 'Process Stage 7KEYS2 - Create output files ...'

PRINT 'Retrieve necessary parameter data to run bcp ...'

-- retrieve necessary parameter data to produce output files
EXEC @ret_code = dbo.XX_7KEYS_GET_PROCESSING_PARAMS_SP
   @out_IMAPS_SCHEMA_OWNER         = @IMAPS_schema_owner  OUTPUT,
   @out_IMAPS_DATABASE_NAME        = @IMAPS_db_name       OUTPUT,
/* @out_IN_USER_NAME               = @login_name          OUTPUT,
   @out_IN_USER_PASSWORD           = @usr_password        OUTPUT,   CR-3548 03/29/2011*/
   @out_OUT_DETAIL_TABLE_NAME      = @source_dtl_table    OUTPUT,
   @out_OUT_HEADER_TABLE_NAME      = @source_hdr_table    OUTPUT,
   @out_OUT_DETAIL_FORMAT_FILENAME = @out_dtl_format_file OUTPUT,
   @out_OUT_HEADER_FORMAT_FILENAME = @out_hdr_format_file OUTPUT,
   @out_OUT_DETAIL_FILENAME        = @dtl_output_filename OUTPUT,
   @out_OUT_HEADER_FILENAME        = @hdr_output_filename OUTPUT

IF @ret_code <> 0 -- SP call results in error
   BEGIN
      SET @out_STATUS_DESCRIPTION = 'Execution of XX_7KEYS_GET_PROCESSING_PARAMS_SP resulted in error.'
      PRINT @out_STATUS_DESCRIPTION
      RETURN(1)
   END

PRINT 'Create detail output file  ...'
/* code was replaced by XX_EXEC_SHELL_CMD_OSUSER call CR-3548 03/29/2011
PRINT 'Create detail output file via bcp ...'

-- Note: xp_cmdshell supplies the opening and closing single quotes for the shell command

-- construct the shell command line string
SET @cmd = 'BCP' + @SPACE
SET @cmd = @cmd + @DOUBLE_QUOTE + @IMAPS_db_name + @PERIOD + @IMAPS_schema_owner + @PERIOD + @source_dtl_table
SET @cmd = @cmd + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + 'OUT' + @SPACE + @DOUBLE_QUOTE + @dtl_output_filename + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-S' + @SPACE + @DOUBLE_QUOTE + @SERVER_NAME + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-f' + @SPACE + @DOUBLE_QUOTE + @out_dtl_format_file + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-U' + @SPACE + @DOUBLE_QUOTE + @login_name + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-P' + @SPACE + @DOUBLE_QUOTE + @usr_password + @DOUBLE_QUOTE

PRINT '@cmd = ' + @cmd

EXEC @ret_code = master.dbo.xp_cmdshell @cmd */

EXECUTE @ret_code = [IMAPSStg].[dbo].[XX_EXEC_SHELL_CMD_OSUSER] 
   @in_IMAPS_db_name = @IMAPS_db_name
  ,@in_IMAPS_table_owner = @IMAPS_schema_owner 
  ,@in_source_table =  @source_dtl_table
  ,@in_format_file = @out_dtl_format_file 
  ,@in_output_file = @dtl_output_filename
  ,@out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION OUTPUT


IF @ret_code <> 0
   BEGIN
      -- Attempt to %1 %2 failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = @IMAPS_error_code,
         @in_display_requested    = 1,
         @in_SQLServer_error_code = @SQLServer_error_code,
         @in_placeholder_value1   = 'create detail output file ',
         @in_placeholder_value2   = 'for 7KEYS/PSP',
         @in_calling_object_name  = @SP_NAME,
         @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
      RETURN(1)
   END






PRINT 'Create header output file ...'
/* code was replaced by XX_EXEC_SHELL_CMD_OSUSER call  CR-3548 03/29/2011
PRINT 'Create header output file via bcp ...'

-- construct the shell command line string
SET @cmd = 'BCP' + @SPACE
SET @cmd = @cmd + @DOUBLE_QUOTE + @IMAPS_db_name + @PERIOD + @IMAPS_schema_owner + @PERIOD + @source_hdr_table
SET @cmd = @cmd + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + 'OUT' + @SPACE + @DOUBLE_QUOTE + @hdr_output_filename + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-S' + @SPACE + @DOUBLE_QUOTE + @SERVER_NAME + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-f' + @SPACE + @DOUBLE_QUOTE + @out_hdr_format_file + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-U' + @SPACE + @DOUBLE_QUOTE + @login_name + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-P' + @SPACE + @DOUBLE_QUOTE + @usr_password + @DOUBLE_QUOTE

PRINT '@cmd = ' + @cmd

EXEC @ret_code = master.dbo.xp_cmdshell @cmd */


EXECUTE @ret_code = [IMAPSStg].[dbo].[XX_EXEC_SHELL_CMD_OSUSER] 
   @in_IMAPS_db_name = @IMAPS_db_name
  ,@in_IMAPS_table_owner = @IMAPS_schema_owner 
  ,@in_source_table =  @source_hdr_table
  ,@in_format_file = @out_hdr_format_file  
  ,@in_output_file = @hdr_output_filename
  ,@out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION OUTPUT

IF @ret_code <> 0
   BEGIN
      -- Attempt to %1 %2 failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = @IMAPS_error_code,
         @in_display_requested    = 1,
         @in_SQLServer_error_code = @SQLServer_error_code,
         @in_placeholder_value1   = 'create header output file ',
         @in_placeholder_value2   = 'for 7KEYS/PSP',
         @in_calling_object_name  = @SP_NAME,
         @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
      RETURN(1)
   END




PRINT 'Assemble output file ...'


EXEC @ret_code = dbo.XX_MANAGE_FILE_SP
   @in_shell_cmd = 'TYPE',
   @in_arg_1 = @dtl_output_filename,
   @in_arg_2 = @hdr_output_filename

IF @ret_code <> 0
   BEGIN
      -- Attempt to %1 %2 failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = @IMAPS_error_code,
         @in_display_requested    = 1,
         @in_SQLServer_error_code = @SQLServer_error_code,
         @in_placeholder_value1   = 'assemble final output file',
         @in_placeholder_value2   = 'for 7KEYS/PSP',
         @in_calling_object_name  = @SP_NAME,
         @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
      RETURN(1)
   END

RETURN(0)


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


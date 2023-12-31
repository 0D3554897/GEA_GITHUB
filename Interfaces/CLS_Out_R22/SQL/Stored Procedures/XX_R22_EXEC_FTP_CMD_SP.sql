use imapsstg

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_EXEC_FTP_CMD_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_R22_EXEC_FTP_CMD_SP]
GO


CREATE PROCEDURE dbo.XX_R22_EXEC_FTP_CMD_SP
(
@in_command_file      sysname,  -- including the file's full directory path
@in_log_file          sysname,   -- including the file's full directory path

@out_SystemError        integer      = NULL OUTPUT, 
@out_STATUS_DESCRIPTION varchar(275) = NULL OUTPUT
)
AS
/************************************************************************************************
Name:       XX_R22_EXEC_FTP_CMD_SP
Author:     KM
Created:    2011-03-14
Purpose:    Execute FTP command file and store results
Parameters: FTP input file and output file
Result Set: None
************************************************************************************************/
BEGIN

DECLARE @SP_NAME             sysname,
        @SERVER_NAME         sysname,
        @DOUBLE_QUOTE        char(1),
        @PERIOD              char(1),
        @SPACE               char(1),
        @cmd                 varchar(255),
        @IMAPS_error_number        integer,
        @SQLServer_error_code      integer,
        @error_msg_placeholder1    sysname,
        @error_msg_placeholder2    sysname,
        @ret_code                  integer

-- set local constants
SET @SP_NAME = 'XX_R22_EXEC_FTP_CMD_SP'
SET @SERVER_NAME = @@servername
SET @DOUBLE_QUOTE = '"'
SET @SPACE = ' '
SET @PERIOD = '.'



SET @CMD = 'echo BEGIN run at ' + convert(char(20), getdate(),121) + ' >>' + @DOUBLE_QUOTE + @in_log_file + @DOUBLE_QUOTE

EXEC @ret_code = master.dbo.xp_cmdshell @cmd

IF @ret_code <> 0
   BEGIN

	EXEC dbo.XX_ERROR_MSG_DETAIL
	   @in_error_code           = 204,
	   @in_display_requested    = 1,
	   @in_SQLServer_error_code = @SQLServer_error_code,
	   @in_placeholder_value1   = 'append date to log file failed.  review',
	   @in_placeholder_value2   = @in_log_file,
	   @in_calling_object_name  = @SP_NAME,
	   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

	PRINT @out_STATUS_DESCRIPTION

      RETURN(1)
   END


-- Note: xp_cmdshell supplies the opening and closing single quotes for the shell command
-- construct the shell command line
SET @CMD = 'ftp -s:' + @DOUBLE_QUOTE + @in_command_file + @DOUBLE_QUOTE + ' >>' + @DOUBLE_QUOTE + @in_log_file + @DOUBLE_QUOTE

EXEC @ret_code = master.dbo.xp_cmdshell @cmd

IF @ret_code <> 0
   BEGIN

	EXEC dbo.XX_ERROR_MSG_DETAIL
	   @in_error_code           = 204,
	   @in_display_requested    = 1,
	   @in_SQLServer_error_code = @SQLServer_error_code,
	   @in_placeholder_value1   = 'FTP failed. review',
	   @in_placeholder_value2   = @in_log_file,
	   @in_calling_object_name  = @SP_NAME,
	   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

	PRINT @out_STATUS_DESCRIPTION

      RETURN(1)
   END


SET @CMD = 'echo END run at ' + convert(char(20), getdate(),121) + ' >>' + @DOUBLE_QUOTE + @in_log_file + @DOUBLE_QUOTE

EXEC @ret_code = master.dbo.xp_cmdshell @cmd

IF @ret_code <> 0
   BEGIN

	EXEC dbo.XX_ERROR_MSG_DETAIL
	   @in_error_code           = 204,
	   @in_display_requested    = 1,
	   @in_SQLServer_error_code = @SQLServer_error_code,
	   @in_placeholder_value1   = 'append date to log file failed.  review',
	   @in_placeholder_value2   = @in_log_file,
	   @in_calling_object_name  = @SP_NAME,
	   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

	PRINT @out_STATUS_DESCRIPTION

      RETURN(1)
   END


SET @CMD = 'echo -- >>' + @DOUBLE_QUOTE + @in_log_file + @DOUBLE_QUOTE
EXEC @ret_code = master.dbo.xp_cmdshell @cmd
EXEC @ret_code = master.dbo.xp_cmdshell @cmd
EXEC @ret_code = master.dbo.xp_cmdshell @cmd
EXEC @ret_code = master.dbo.xp_cmdshell @cmd
EXEC @ret_code = master.dbo.xp_cmdshell @cmd

IF @ret_code <> 0
   BEGIN

	EXEC dbo.XX_ERROR_MSG_DETAIL
	   @in_error_code           = 204,
	   @in_display_requested    = 1,
	   @in_SQLServer_error_code = @SQLServer_error_code,
	   @in_placeholder_value1   = 'append date to log file failed.  review',
	   @in_placeholder_value2   = @in_log_file,
	   @in_calling_object_name  = @SP_NAME,
	   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

	PRINT @out_STATUS_DESCRIPTION

      RETURN(1)
   END



RETURN(0)

END

GRANT EXECUTE ON dbo.XX_R22_EXEC_FTP_CMD_SP TO PUBLIC


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

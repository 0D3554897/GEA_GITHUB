USE [IMAPSStg]
GO
/****** Object:  StoredProcedure [dbo].[XX_EXEC_SHELL_CMD_QUERYOUT_OSUSER]    Script Date: 05/05/2011 14:18:02 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS (SELECT * FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[DBO].[XX_EXEC_SHELL_CMD_QUERYOUT_OSUSER]') AND OBJECTPROPERTY(ID, N'ISPROCEDURE') = 1)
DROP PROCEDURE [DBO].[XX_EXEC_SHELL_CMD_QUERYOUT_OSUSER]
GO

CREATE PROCEDURE [dbo].[XX_EXEC_SHELL_CMD_QUERYOUT_OSUSER]
(
@in_query_sql			 sysname,
@in_format_file          sysname,  -- including the file's full directory path
@in_output_file          sysname,

@out_STATUS_DESCRIPTION  varchar(255) = NULL OUTPUT
)
AS
BEGIN
/************************************************************************************************
Name:       XX_EXEC_SHELL_CMD_QUERYOUT
Author:     HVT/LA
Created:    03/16/2011
Purpose:    Execute one or more DOS commands.
Parameters: None
Result Set: None
Notes:      Stored procedures created in master DB always take the default user dbo.
************************************************************************************************/

DECLARE @SP_NAME             sysname,
        @SERVER_NAME         sysname,
        @DOUBLE_QUOTE        char(1),
        @PERIOD              char(1),
        @SPACE               char(1),
        @cmd                 varchar(255),
        @ret_code            integer

-- set local constants
SET @SP_NAME = 'XX_EXEC_SHELL_CMD_QUERYOUT_OSUSER'
SET @SERVER_NAME = @@servername
SET @DOUBLE_QUOTE = '"'
SET @SPACE = ' '
SET @PERIOD = '.'


-- Note: xp_cmdshell supplies the opening and closing single quotes for the shell command

-- construct the shell command line
SET @cmd = 'BCP' + @SPACE
SET @cmd = @cmd + @DOUBLE_QUOTE + @in_query_sql
SET @cmd = @cmd + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + 'QUERYOUT' + @SPACE + @DOUBLE_QUOTE + @in_output_file + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-S' + @SPACE + @DOUBLE_QUOTE + @SERVER_NAME + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-f' + @SPACE + @DOUBLE_QUOTE + @in_format_file + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-T' + @SPACE 
PRINT '@cmd = ' + @cmd
EXEC @ret_code = master.dbo.xp_cmdshell @cmd

IF @ret_code <> 0
   BEGIN
      -- Attempt to create input file for Costpoint timesheet preprocessor via bcp failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL -- database name must be explicitly provided
         @in_error_code          = 402,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME,
         @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT
      RETURN(1)
   END

RETURN(0)

END

GO


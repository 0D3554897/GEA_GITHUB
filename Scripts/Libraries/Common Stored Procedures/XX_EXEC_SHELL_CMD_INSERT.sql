SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_EXEC_SHELL_CMD_INSERT]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_EXEC_SHELL_CMD_INSERT]
GO

CREATE  PROCEDURE dbo.XX_EXEC_SHELL_CMD_INSERT
(
@in_IMAPS_db_name        sysname,
@in_IMAPS_table_owner    sysname,
@in_Dest_table           sysname,
@in_format_file          sysname,  -- including the file's full directory path
@in_input_file           sysname,
@in_usr_password         varchar(16),
@out_STATUS_DESCRIPTION  varchar(255) = NULL OUTPUT
)
AS

/************************************************************************************************
Name:       XX_EXEC_SHELL_CMD_INSERT
Author:     JG
Created:    08/04/2005
Purpose:    Execute one or more DOS commands.
            Load a table from a fixed-length, space-delimited file.
            To be used to capture the preprocessor errors 
            Called by XX_UPDATE_TS_PREP_STATUS_SP  which resides in the Staging database.
Parameters: 	@in_IMAPS_db_name        
		@in_IMAPS_table_owner    
		@in_Dest_table         
		@in_format_file         -- including the file's full directory path
		@in_input_file         
		@in_usr_password       
		@out_STATUS_DESCRIPTION -- OUTPUT parm

Result Set: None
Notes:      Stored procedures created in master DB always take the default user dbo.
************************************************************************************************/

DECLARE @SP_NAME             sysname,
        @SERVER_NAME         sysname,
        @DOUBLE_QUOTE        char(1),
        @PERIOD              char(1),
        @SPACE               char(1),
        @cmd                 varchar(255),
        @login_name          varchar(16),
        @password            varchar(16),
        @SQLServer_msg_text  varchar(275),
        @replace_str         char(5),
        @ret_code            integer

-- set local constants
SET @SP_NAME = 'dbo.XX_EXEC_SHELL_CMD_INSERT'
SET @SERVER_NAME = @@servername
SET @DOUBLE_QUOTE = '"'
SET @SPACE = ' '
SET @PERIOD = '.'

-- initialize local variables
SET @login_name = 'IMAPSSTG' --SUSER_SNAME()

-- Note: xp_cmdshell supplies the opening and closing single quotes for the shell command

-- construct the shell command line
SET @cmd = 'BCP' + @SPACE
SET @cmd = @cmd + @DOUBLE_QUOTE + @in_IMAPS_db_name + @PERIOD + @in_IMAPS_table_owner + @PERIOD + @in_Dest_table
SET @cmd = @cmd + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + 'IN' + @SPACE + @DOUBLE_QUOTE + @in_input_file + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-S' + @SPACE + @DOUBLE_QUOTE + @SERVER_NAME + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-f' + @SPACE + @DOUBLE_QUOTE + @in_format_file + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-U' + @SPACE + @DOUBLE_QUOTE + @login_name + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-P' + @SPACE + @DOUBLE_QUOTE + @in_usr_password + @DOUBLE_QUOTE

EXEC @ret_code = master.dbo.xp_cmdshell @cmd

IF @ret_code <> 0
   BEGIN
      -- Attempt to load file via bcp failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL -- database name must be explicitly provided
         @in_error_code          = 402,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME,
         @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT
      RETURN(1)
   END

RETURN(0)

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


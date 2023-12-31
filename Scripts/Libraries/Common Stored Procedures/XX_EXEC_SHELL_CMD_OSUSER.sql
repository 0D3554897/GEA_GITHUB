SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[XX_EXEC_SHELL_CMD_OSUSER]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
BEGIN
    DROP PROCEDURE dbo.XX_EXEC_SHELL_CMD_OSUSER
    IF OBJECT_ID('dbo.XX_EXEC_SHELL_CMD_OSUSER') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_EXEC_SHELL_CMD_OSUSER >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_EXEC_SHELL_CMD_OSUSER >>>'
END

GO

CREATE PROCEDURE [dbo].[XX_EXEC_SHELL_CMD_OSUSER]
(
@in_IMAPS_db_name        sysname,
@in_IMAPS_table_owner    sysname,
@in_source_table         sysname,
@in_format_file          sysname,  -- including the file's full directory path
@in_output_file          sysname,
--@in_usr_password         sysname,
@out_STATUS_DESCRIPTION  varchar(255) = NULL OUTPUT
)
AS

/************************************************************************************************
Name:       XX_EXEC_SHELL_CMD_OSUSER
Author:     HVT
Created:    07/01/2005
Purpose:    Execute one or more DOS commands.
            Build a fixed-length, space-delimited file using records from table XX_IMAPS_ET_IN_TMP.
            This file is used by the Costpoint timesheet preprocessor.
            Called by XX_RUN_ETIME_INTERFACE.
Parameters: None
Result Set: None
Modified    : 03/16/2011
Purpose     : Eliminate the use of Shared ID / CR-3548
Notes:      Stored procedures created in master DB always take the default user dbo.
************************************************************************************************/

DECLARE @SP_NAME             sysname,
        @SERVER_NAME         sysname,
        @DOUBLE_QUOTE        char(1),
        @PERIOD              char(1),
        @SPACE               char(1),
        @cmd                 varchar(255),
        @login_name          varchar(16),
        @ret_code            integer

-- set local constants
SET @SP_NAME = 'XX_EXEC_SHELL_CMD_OSUSER' -- Modified for CR-3548 03/16/2011
SET @SERVER_NAME = @@servername
SET @DOUBLE_QUOTE = '"'
SET @SPACE = ' '
SET @PERIOD = '.'

-- initialize local variables
--SET @login_name = 'imapsstg' -- SUSER_SNAME() is dependent on the logged-in DB

-- Note: xp_cmdshell supplies the opening and closing single quotes for the shell command

-- construct the shell command line
SET @cmd = 'BCP' + @SPACE
SET @cmd = @cmd + @DOUBLE_QUOTE + @in_IMAPS_db_name + @PERIOD + @in_IMAPS_table_owner + @PERIOD + @in_source_table
SET @cmd = @cmd + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + 'OUT' + @SPACE + @DOUBLE_QUOTE + @in_output_file + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-S' + @SPACE + @DOUBLE_QUOTE + @SERVER_NAME + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-f' + @SPACE + @DOUBLE_QUOTE + @in_format_file + @DOUBLE_QUOTE + @SPACE
--SET @cmd = @cmd + '-U' + @SPACE + @DOUBLE_QUOTE + @login_name + @DOUBLE_QUOTE + @SPACE
--SET @cmd = @cmd + '-P' + @SPACE + @DOUBLE_QUOTE + @in_usr_password + @DOUBLE_QUOTE
SET @cmd = @cmd + '-T' + @SPACE -- Modified for CR-3548 03/16/2011
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



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

IF OBJECT_ID('dbo.XX_EXEC_SHELL_CMD_OSUSER') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_EXEC_SHELL_CMD_OSUSER >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_EXEC_SHELL_CMD_OSUSER >>>'
go
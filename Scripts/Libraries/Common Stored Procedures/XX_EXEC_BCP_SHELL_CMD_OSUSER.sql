USE [IMAPSStg]
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_EXEC_BCP_SHELL_CMD_OSUSER]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   DROP PROCEDURE [dbo].[XX_EXEC_BCP_SHELL_CMD_OSUSER]
GO

CREATE PROCEDURE dbo.XX_EXEC_BCP_SHELL_CMD_OSUSER
(
@in_IMAPS_db_name        sysname,
@in_IMAPS_table_owner    sysname,
@in_Dest_table           sysname,
@in_format_file          sysname,
@in_input_file           sysname,
@in_error_log_file       sysname,
@out_STATUS_DESCRIPTION  varchar(255) = NULL OUTPUT
)
AS

/************************************************************************************************
Name:       XX_EXEC_BCP_SHELL_CMD_OSUSER
Author:     HVT
Created:    04-23-2020
Purpose:    Build and execute bcp (bulk copy) shell command line.
            Load a table from a fixed-length, space-delimited file.
            See call example in XX_AR_CCIS_LOAD_SP.
Notes:      CR-11452 04/23/2020 New bcp command line to work with Microsoft ODBC Driver 13.
************************************************************************************************/

DECLARE @SP_NAME             sysname,
        @SERVER_NAME         sysname,
        @DOUBLE_QUOTE        char(1),
        @PERIOD              char(1),
        @SPACE               char(1),
        @cmd                 varchar(300),
        @password            varchar(16),
        @SQLServer_msg_text  varchar(275),
        @replace_str         char(5),
        @ret_code            integer

-- Set local constants
SET @SP_NAME = 'dbo.XX_EXEC_BCP_SHELL_CMD_OSUSER'
SET @SERVER_NAME = @@servername
SET @DOUBLE_QUOTE = '"'
SET @SPACE = ' '
SET @PERIOD = '.'

-- Note: xp_cmdshell supplies the opening and closing single quotes for the shell command

-- Construct the shell command line
SET @cmd = 'BCP' + @SPACE
SET @cmd = @cmd + @DOUBLE_QUOTE + @in_IMAPS_db_name + @PERIOD + @in_IMAPS_table_owner + @PERIOD + @in_Dest_table
SET @cmd = @cmd + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + 'IN' + @SPACE + @DOUBLE_QUOTE + @in_input_file + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-S' + @SPACE + @DOUBLE_QUOTE + @SERVER_NAME + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-f' + @SPACE + @DOUBLE_QUOTE + @in_format_file + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-e' + @SPACE + @DOUBLE_QUOTE + @in_error_log_file + @DOUBLE_QUOTE + @SPACE
SET @cmd = @cmd + '-T -m 1 -r \n'

/*
Example of bcp command line:

BCP "IMAPSSTG.dbo.XX_AR_CCIS_ACTIVITY" IN "T:\IMAPS_DATA\Interfaces\PROCESS\7Keys\CCIS_ACTIVITY_2.TXT"
    -f "T:\IMAPS_DATA\Interfaces\FORMAT\XX_AR_CCIS_ACTIVITY.fmt"
    -S "DSWWINDAP49"
    -e "T:\IMAPS_DATA\INTERFACES\LOGS\CCIS\BCP_ERR_ACTIVITY.TXT" -- error log file is specified
    -T    -- trusted connection, no user id and password required
    -m 1  -- maximum number of errors before bcp is aborted (target input file line not copied by bcp)
    -r \n -- row terminator is specified: CRLF (carriage return + line feed)
*/

PRINT @cmd

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

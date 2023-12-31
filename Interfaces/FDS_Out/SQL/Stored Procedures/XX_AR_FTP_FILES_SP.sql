SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_FTP_FILES_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_AR_FTP_FILES_SP]
GO








CREATE PROCEDURE dbo.XX_AR_FTP_FILES_SP
AS
/************************************************************************************************  
Name:       	XX_AR_FTP_FILES_SP  
Author:     	CR, KM
Created:    	08/2005  
Purpose:    	FTP AR FILES TO FDS/CCS

Prerequisites: 	none 

Parameters: 
	Input: 	none
	Output: none   

Version: 	1.0
Notes:      	
************************************************************************************************/  
BEGIN

DECLARE @CMD		varchar(300),
	@CCS_FTP_SERVER	sysname,
	@CCS_FTP_USER sysname,
	@CCS_FTP_PASS sysname,
	@CCS_FTP_DEST_FILE sysname,
	@FDS_FTP_SERVER	sysname,
	@FDS_FTP_USER sysname,
	@FDS_FTP_PASS sysname,
	@FDS_FTP_DEST_FILE sysname,
	@FTP_DIR sysname,
	@FTP_CMD_FILE sysname,
	@ARCHIVE_DIR sysname,
	@ERROR_DIR sysname,
	@ret_code	int

-- Load Parameters From Table
SELECT @CCS_FTP_SERVER = PARAMETER_VALUE FROM dbo.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = 'FDS/CCS' AND PARAMETER_NAME = 'CCS_FTP_SERVER'

SELECT @CCS_FTP_USER = PARAMETER_VALUE FROM dbo.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = 'FDS/CCS' AND PARAMETER_NAME = 'CCS_FTP_USER'

SELECT @CCS_FTP_PASS = PARAMETER_VALUE FROM dbo.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = 'FDS/CCS' AND PARAMETER_NAME = 'CCS_FTP_PASS'

SELECT @CCS_FTP_DEST_FILE = PARAMETER_VALUE FROM dbo.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = 'FDS/CCS' AND PARAMETER_NAME = 'CCS_FTP_DEST_FILE'

SELECT @FDS_FTP_SERVER = PARAMETER_VALUE FROM dbo.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = 'FDS/CCS' AND PARAMETER_NAME = 'FDS_FTP_SERVER'

SELECT @FDS_FTP_USER = PARAMETER_VALUE FROM dbo.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = 'FDS/CCS' AND PARAMETER_NAME = 'FDS_FTP_USER'

SELECT @FDS_FTP_PASS = PARAMETER_VALUE FROM dbo.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = 'FDS/CCS' AND PARAMETER_NAME = 'FDS_FTP_PASS'

SELECT @FDS_FTP_DEST_FILE = PARAMETER_VALUE FROM dbo.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = 'FDS/CCS' AND PARAMETER_NAME = 'FDS_FTP_DEST_FILE'

SELECT @FTP_DIR = PARAMETER_VALUE FROM dbo.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = 'FDS/CCS' AND PARAMETER_NAME = 'FTP_DIR'

SELECT @ARCHIVE_DIR = PARAMETER_VALUE FROM dbo.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = 'FDS/CCS' AND PARAMETER_NAME = 'ARCHIVE_DIR'

SELECT @ERROR_DIR = PARAMETER_VALUE FROM dbo.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = 'FDS/CCS' AND PARAMETER_NAME = 'ERROR_DIR'

SET @FTP_CMD_FILE = 'temp_ftp_commands.txt'

-- FTP the CCS File

-- write FTP commands to temporary text file
SET @CMD = 'echo ' + @CCS_FTP_USER + ' > ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END

SET @CMD = 'echo ' + @CCS_FTP_PASS + ' >> ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END

SET @CMD = 'echo PUT IMAPS_TO_CCS_* ' + @CCS_FTP_DEST_FILE + ' >> ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END

SET @CMD = 'echo QUIT >> ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END

SET @CMD = 'MOVE ' + @FTP_DIR + 'IMAPS_TO_CCS_* .'
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END

SET @CMD = 'ftp -s:' + @FTP_CMD_FILE + ' ' + @CCS_FTP_SERVER
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END



-- FTP the FDS File
-- write FTP commands to temporary text file
SET @CMD = 'echo ' + @FDS_FTP_USER + ' > ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END

SET @CMD = 'echo ' + @FDS_FTP_PASS + ' >> ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END

SET @CMD = 'echo BINARY >> ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END

SET @CMD = 'echo QUOTE SITE LRECL=286 BLKSIZE=8008 RECFM=FB >> ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END


SET @CMD = 'echo PUT IMAPS_TO_FDS_* ' + @FDS_FTP_DEST_FILE + ' >> ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END

SET @CMD = 'echo QUIT >> ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END

SET @CMD = 'MOVE ' + @FTP_DIR + 'IMAPS_TO_FDS_* .'
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END

SET @CMD = 'ftp -s:' + @FTP_CMD_FILE + ' ' + @FDS_FTP_SERVER
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END

-- erase temp file
SET @CMD = 'ERASE ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END

-- Archive Files
SET @CMD = 'MOVE IMAPS_TO_CCS_* ' + @ARCHIVE_DIR
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END

SET @CMD = 'MOVE IMAPS_TO_FDS_* ' + @ARCHIVE_DIR
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END

SET @CMD = 'MOVE ' + @FTP_DIR + 'Transaction_Report_* ' + @ARCHIVE_DIR
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END

SET @CMD = 'MOVE ' + @ERROR_DIR + 'FDS_CCS_ERROR_LOG_* ' + @ARCHIVE_DIR
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	RETURN (1)
END

RETURN(0)
END






GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


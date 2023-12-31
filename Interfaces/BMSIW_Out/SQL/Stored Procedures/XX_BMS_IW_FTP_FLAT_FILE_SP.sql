use imapsstg

go


IF OBJECT_ID('dbo.XX_BMS_IW_FTP_FLAT_FILE_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_BMS_IW_FTP_FLAT_FILE_SP
    IF OBJECT_ID('dbo.XX_BMS_IW_FTP_FLAT_FILE_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_BMS_IW_FTP_FLAT_FILE_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_BMS_IW_FTP_FLAT_FILE_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER ON
go



CREATE PROCEDURE [dbo].[XX_BMS_IW_FTP_FLAT_FILE_SP]
(
@in_STATUS_RECORD_NUM     integer,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS
/****************************************************************************************************
Name:       XX_BMS_IW_FTP_FLAT_FILE_SP
Author:     KM
Created:    11/01/2005
Purpose:    This stored procedure FTP's the Flat File to BMS-IW
	    And then archives the file
Modified: 09/25/2007

Modified: 11/28/2011 standardize FTP calls (CR3890)
Modified: 07/01/2019 FTPES conversion CR-10982
Parameters: 
Result Set: None
Notes:
****************************************************************************************************/
BEGIN

-- declare standard constants
DECLARE	@SP_NAME                 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @row_count               integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
	@BMS_IW_INTERFACE_NAME	 sysname,
	@CMD			 varchar(500),
	@ret_code		 int,
	@ARCH_FILE_NAME		 sysname

-- set local const
SET @BMS_IW_INTERFACE_NAME = 'BMS_IW'
SET @SP_NAME = 'XX_BMS_IW_FTP_FLAT_FILE_SP'
SET @ARCH_FILE_NAME = CAST(@in_STATUS_RECORD_NUM as sysname) + '_BMS_IW.txt'

-- 1.	obtain ftp parameters
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'Obtain BMS_IW FTP'
SET @error_msg_placeholder2 = 'Paramaters'

DECLARE @FTP_FILE	sysname,
	@FTP_DEST_FILE	sysname,
	@FTP_DEST_FOLDER sysname,
	@ARCH_DIR	sysname
/* CR3890 ,
	@FTP_USER	sysname,
	@FTP_PASS	sysname,
	@FTP_SERVER	sysname*/

SELECT 	@FTP_FILE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @BMS_IW_INTERFACE_NAME
AND	PARAMETER_NAME = 'FTP_FILE'

SELECT 	@FTP_DEST_FILE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @BMS_IW_INTERFACE_NAME
AND	PARAMETER_NAME = 'FTP_DEST_FILE'

SELECT 	@FTP_DEST_FOLDER = substring(PARAMETER_VALUE,1,6)
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @BMS_IW_INTERFACE_NAME
AND	PARAMETER_NAME = 'FTP_DEST_FILE'


SELECT 	@ARCH_DIR = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @BMS_IW_INTERFACE_NAME
AND	PARAMETER_NAME = 'ARCH_DIR'

/* CR3890
SELECT 	@FTP_USER = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @BMS_IW_INTERFACE_NAME
AND	PARAMETER_NAME = 'FTP_USER'

SELECT 	@FTP_PASS = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @BMS_IW_INTERFACE_NAME
AND	PARAMETER_NAME = 'FTP_PASS'

SELECT 	@FTP_SERVER = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @BMS_IW_INTERFACE_NAME
AND	PARAMETER_NAME = 'FTP_SERVER'
*/

SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER




/*
CR3890

-- 2. write FTP commands to temporary text file
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'Create Temporary File'
SET @error_msg_placeholder2 = 'For FTP Commands'

DECLARE @FTP_CMD_FILE sysname
SET @FTP_CMD_FILE = 'temp_bms_iw_ftp_commands.txt'


SET @CMD = 'echo ' + @FTP_USER + ' > ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	GOTO BL_ERROR_HANDLER
END

SET @CMD = 'echo ' + @FTP_PASS + ' >> ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	GOTO BL_ERROR_HANDLER
END

-- TO DO
-- FIND OUT HOW TO USE MS XP COMMAND SHELL FTP
-- TO CONVERT ASCII to EBCDIC
-- I think FTProtocol converts ASCII to native charset codepage automatically
-- so long as mode is ASCII (default)
/*SET @CMD = 'echo QUOTE SITE TYPE C 037 >> ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	GOTO BL_ERROR_HANDLER
END*/

SET @CMD = 'echo QUOTE SITE LRECL=80 BLKSIZE=27920 RECFM=FB CYL PRI=10 SEC=10 RET  >> ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	GOTO BL_ERROR_HANDLER
END

SET @CMD = 'echo CD '+CHAR(39)+@FTP_DEST_FOLDER+CHAR(39)+' >> ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	GOTO BL_ERROR_HANDLER
END

SET @CMD = 'echo PUT ' + @ARCH_FILE_NAME + ' ' + substring(@FTP_DEST_FILE,8,len(@FTP_DEST_FILE)) + ' >> ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	GOTO BL_ERROR_HANDLER
END

SET @CMD = 'echo QUIT >> ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	GOTO BL_ERROR_HANDLER
END

SET @CMD = 'MOVE ' + @FTP_FILE + ' ' + @ARCH_FILE_NAME
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	GOTO BL_ERROR_HANDLER
END


-- 3.	FTP the File
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'FTP The'
SET @error_msg_placeholder2 = 'Flat File'
--SET @CMD = 'ftp -s:' + @ARCH_FILE_NAME + ' ' + @FTP_SERVER
SET @CMD = 'ftp -s:' + @FTP_CMD_FILE + ' ' + @FTP_SERVER
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	SET @CMD = 'MOVE ' + @ARCH_FILE_NAME + ' ' + @FTP_FILE
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD
	GOTO BL_ERROR_HANDLER
END


--4. 	erase temp file
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'Erase the temporary'
SET @error_msg_placeholder2 = 'FTP Command File'

SET @CMD = 'ERASE ' + @FTP_CMD_FILE
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	GOTO BL_ERROR_HANDLER
END

*/


--begin CR3890 new logic

	-- erase temp file, if it exists
	SET @CMD = 'ERASE BMS_IW.txt'
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD
	SET @ret_code = 0

	--move file to current working directory with arhive name
	SET @CMD = 'MOVE ' + @FTP_FILE + ' ' + @ARCH_FILE_NAME
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD
	IF @ret_code <> 0
	BEGIN
		PRINT 'FAILURE at '+@CMD
		GOTO BL_ERROR_HANDLER
	END

	--copy file to temp file (temp file created for static FTP command)
	SET @CMD = 'COPY ' + @ARCH_FILE_NAME + ' BMS_IW.txt'
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD
	IF @ret_code <> 0
	BEGIN
		PRINT 'FAILURE at '+@CMD
		GOTO BL_ERROR_HANDLER
	END


	-- 3.	FTP the File
	--BEGIN FTP
	DECLARE @FTP_command_file sysname,
			@FTP_log_file sysname,			
			@unique_name_part sysname,
			@FTP_EXE sysname		 -- Added for FTPES CR-10982

	SELECT @FTP_command_file = PARAMETER_VALUE
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='BMS_IW'
	AND PARAMETER_NAME='FTP_COMMAND_FILE'

	SELECT @FTP_log_file = PARAMETER_VALUE
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='BMS_IW'
	AND PARAMETER_NAME='FTP_LOG_FILE'

	-- Added for FTPES CR-10982
	SELECT @FTP_EXE = PARAMETER_VALUE
	FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='BMS_IW'
	AND PARAMETER_NAME='FTP_COMMAND_EXE'

	SELECT @unique_name_part = replace(replace(replace(replace(convert(char(20), getdate(),121),'-',''),':',''),'.',''),' ', '')

	--make log file unique for each run
	SET @FTP_log_file = REPLACE(@FTP_log_file, '.TXT', '_'+cast(@in_STATUS_RECORD_NUM as varchar)+'_'+@unique_name_part+'.TXT')

	-- Begin Change CR-10982
	-- NEw code for FTPES
    SET @CMD = @FTP_EXE + ' ' + @FTP_log_file + ' ' + @FTP_command_file
    PRINT 'DOS COMMAND IS : ' + @CMD
    
 	EXEC @ret_code = master.dbo.xp_cmdshell @CMD

	-- End Change CR-10982

	-- Comment old FTP section CR-10982
	/*
	EXEC @ret_code = XX_EXEC_FTP_CMD_SP
		@in_command_file=@FTP_command_file,
		@in_log_file=@FTP_log_file
	*/
	IF @ret_code <> 0 OR @@ERROR <> 0
	BEGIN
		--move file back to process folder
		SET @CMD = 'MOVE ' + @ARCH_FILE_NAME + ' ' + @FTP_FILE
		EXEC @ret_code = master.dbo.xp_cmdshell @CMD
		GOTO BL_ERROR_HANDLER
	END
	--END FTP

	
	--erase temp file now that we're done with it
	SET @CMD = 'ERASE BMS_IW.txt'
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD
	SET @ret_code = 0
--end CR3890 new logic




-- 5.	Archive Files
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'Archive the'
SET @error_msg_placeholder2 = 'BMS-IW File'

SET @CMD = 'MOVE ' + @ARCH_FILE_NAME + ' ' + @ARCH_DIR
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0
BEGIN
	GOTO BL_ERROR_HANDLER
END

-- 5.	UPDATE STATUS RECORD DETAILS
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'UPDATE STATUS RECORD'
SET @error_msg_placeholder2 = 'COUNT DETAILS'

UPDATE 	dbo.XX_IMAPS_INT_STATUS
SET	RECORD_COUNT_SUCCESS = RECORD_COUNT_INITIAL,
	AMOUNT_PROCESSED = AMOUNT_INPUT
WHERE  	STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

RETURN(0)

BL_ERROR_HANDLER:

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_number,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)

END











go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_BMS_IW_FTP_FLAT_FILE_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_BMS_IW_FTP_FLAT_FILE_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_BMS_IW_FTP_FLAT_FILE_SP >>>'
go
GRANT EXECUTE ON dbo.XX_BMS_IW_FTP_FLAT_FILE_SP TO imapsstg
go



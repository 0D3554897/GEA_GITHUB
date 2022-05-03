USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_AR_SFTP_INBOUND_SP]    Script Date: 4/27/2020 6:11:27 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO



IF EXISTS (SELECT * FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[DBO].[XX_AR_SFTP_INBOUND_SP]') AND OBJECTPROPERTY(ID, N'ISPROCEDURE') = 1)
   DROP PROCEDURE [DBO].[XX_AR_SFTP_INBOUND_SP]
GO



CREATE PROCEDURE [dbo].[XX_AR_SFTP_INBOUND_SP] 
(
@in_STATUS_RECORD_NUM     integer
) 
AS

/****************************************************************************************************
Name:       XX_AR_SFTP_INBOUND_SP
Author:     GEA
Created:    04/21/2020
Purpose:    This stored procedure serves as a script to run and drive all necessary tasks to
            to get the CCIS files from the sftp server to the local SFTP inbox

Parameters: STATUS RECORD NUMBER
Result Set: None
Notes:

****************************************************************************************************/

BEGIN

DECLARE @SP_NAME                        sysname,
		@INT							VARCHAR(20),
		@ENV							VARCHAR(4),
		@SFTP_SERVER					VARCHAR(100),
		@PROCESS_FOLDER					VARCHAR(100),
		@KEYFILE						VARCHAR(100),
		@SFTP_CMD						VARCHAR(100),
		@INBOX							VARCHAR(100),
		@LOG_FOLDER						VARCHAR(100),
		@LOG_FILE						VARCHAR(100),
		@SFTP_EXE						VARCHAR(100),
		@MAX							INT,
		@CMD							VARCHAR(400), 
		@MYCMD							VARCHAR(400), 
		@SRC							VARCHAR(300),
		@TGT							VARCHAR(300),
		@SUBJECT						VARCHAR(50),
		@MAIL_MESSAGE					VARCHAR(300),
		@MAIL_TEXT						VARCHAR(300),
        @ret_cod						integer,
		@IN_OPS_OWNER					varchar(300),

		@SQLServer_error_code			integer,
        @IMAPS_error_code				integer,
        @error_msg_placeholder1			sysname,
        @error_msg_placeholder2			sysname,
        @row_count						integer,
		@current_STATUS_DESCRIPTION		VARCHAR(100),
		@SQLServer_error_msg_text		VARCHAR(500)


 

-- set local constants
SET @SP_NAME = 'XX_AR_SFTP_INBOUND_SP'

PRINT ' '
PRINT '*~^**************************************************************************************************************' 
PRINT '*~^                        HERE IN ' + @SP_NAME
PRINT '*~^**************************************************************************************************************'
PRINT ' '

SET @INT = 'CCIS'
SET @MAIL_MESSAGE = ''
SET @MAIL_TEXT = ''

-- Retrieve necessary parameter data to run the SFTP interface
SELECT 	@ENV = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	PARAMETER_NAME	= 'SERVER_ENVIRONMENT'
PRINT '1. ENVIRONMENT : ' + @ENV

SELECT 	@SFTP_SERVER = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'UTIL'
AND	PARAMETER_NAME	= @ENV + '_SFTP_SERVER'
PRINT '2. SFTP SERVER : ' + @SFTP_SERVER

SELECT 	@PROCESS_FOLDER = PARAMETER_VALUE + @INT
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @INT
AND	PARAMETER_NAME	= 'PROCESS_FOLDER'
PRINT '3. PROCESS FOLDER : ' + @PROCESS_FOLDER

SELECT 	@KEYFILE = REPLACE(REPLACE(PARAMETER_VALUE, 'INTERFACE', @INT),'ENV',@ENV)
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'UTIL'
AND	PARAMETER_NAME	= 'KEYFILE'
PRINT '4. KEYFILE : ' + @KEYFILE

SELECT 	@INBOX = PARAMETER_VALUE + @INT
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'UTIL'
AND	PARAMETER_NAME	= 'INBOX_FOLDER'
PRINT '5. INBOX : ' + @INBOX

SELECT 	@SFTP_CMD = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @INT
AND	PARAMETER_NAME	= 'SFTP_CMD_FILE'
PRINT '6. SFTP COMMAND FILE : ' + @SFTP_CMD

SELECT 	@LOG_FOLDER = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @INT
AND	PARAMETER_NAME	= 'LOG_FOLDER'
PRINT '7. LOG FOLDER : ' + @LOG_FOLDER

SELECT 	@LOG_FILE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @INT
AND	PARAMETER_NAME	= 'SFTP_LOG_FILE'
PRINT '8. LOG FILE : ' + @LOG_FILE

SELECT 	@SFTP_EXE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'UTIL'
AND	PARAMETER_NAME	= 'SFTP_EXE'
PRINT '9. SFTP EXECUTABLE : ' + @SFTP_EXE

SELECT 	@IN_OPS_OWNER = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @INT
AND	PARAMETER_NAME	= 'IN_OPS_OWNER'
PRINT '10. OPS OWNER : ' + @IN_OPS_OWNER

PRINT 'PARAMETERS RETRIEVED'

SET @CMD = 'DEL /F /Q ' + @PROCESS_FOLDER + '\*.*'
PRINT 'Command is :' + @CMD
EXEC @ret_cod = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_cod <> 0 GOTO BL_ERROR_HANDLER
PRINT 'PROCESS FOLDER EMPTIED'

SET @CMD = @SFTP_EXE + ' ' + @PROCESS_FOLDER + ' ' + CHAR(34) + @SFTP_SERVER + CHAR(34) + ' ' + CHAR(34) + @KEYFILE + CHAR(34) + ' ' + @SFTP_CMD  + ' ' + CHAR(34) + @LOG_FOLDER + @LOG_FILE + CHAR(34)
PRINT 'Command is :' + @CMD
EXEC @ret_cod = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_cod <> 0 GOTO BL_ERROR_HANDLER
PRINT 'INBOUND SFTP EXECUTED.'

PRINT 'NOW RENAMING AND CHECKING FOR EXISTENCE'

DECLARE @ERR_CTR INT = 0
DECLARE @COUNTER INT = 0
DECLARE @MyList TABLE (SOURCE NVARCHAR(100), TARGET NVARCHAR(100))
-- INTERFACE FILES

INSERT INTO @MyList SELECT 
	CONCAT(PARSENAME(REPLACE(PARAMETER_VALUE,';','.'), 4), '.', PARSENAME(REPLACE(PARAMETER_VALUE,';','.'), 3)),
	CONCAT(PARSENAME(REPLACE(PARAMETER_VALUE,';','.'), 2), '.', PARSENAME(REPLACE(PARAMETER_VALUE,';','.'), 1))
  FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
  WHERE PARAMETER_NAME LIKE 'TARGET_FILE_%' AND INTERFACE_NAME_CD = @INT

SELECT @MAX=COUNT(*) FROM @MyList
PRINT 'NUMBER OF FILE PAIRS FROM QUERY: ' + CAST(@MAX AS VARCHAR(5))

WHILE @COUNTER < @MAX
BEGIN

    SELECT TOP 1 @SRC=SOURCE, @TGT=TARGET FROM @MyList

    SET @CMD = 'T:\IMAPS_DATA\Interfaces\PROGRAMS\BATCH\LF2CRLF.BAT ' + @PROCESS_FOLDER + '\' + @SRC + ' ' + @PROCESS_FOLDER + '\CRLF_' + @TGT 
    PRINT 'LF2CRLF COMMAND IS: ' + @CMD
	EXEC @ret_cod = master.dbo.xp_cmdshell @CMD
	PRINT 'RETURN CODE IS ' + CAST(COALESCE(@ret_cod,0) AS VARCHAR)

    SET @CMD = 'DEL /F /Q ' + @PROCESS_FOLDER + '\' + @SRC 
    PRINT 'DELETE COMMAND IS: ' + @CMD
	EXEC @ret_cod = master.dbo.xp_cmdshell @CMD
	PRINT 'RETURN CODE IS ' + CAST(COALESCE(@ret_cod,0) AS VARCHAR)

    SET @CMD = 'REN ' + @PROCESS_FOLDER + '\CRLF_' + @SRC + ' ' + @TGT
    PRINT 'RENAME COMMAND IS: ' + @CMD
	EXEC @ret_cod = master.dbo.xp_cmdshell @CMD
	PRINT 'RETURN CODE IS ' + CAST(COALESCE(@ret_cod,0) AS VARCHAR)

	SET @MYCMD = 'T:\IMAPS_DATA\Interfaces\PROGRAMS\BATCH\DOIT_XST.BAT ' + @PROCESS_FOLDER + '\' + @TGT
	PRINT 'CHECK COMMAND IS: ' + @MYCMD
	EXEC @ret_cod = master.dbo.xp_cmdshell @MYCMD
	PRINT 'RETURN CODE FOR ' + @TGT + ' = '  + CAST(COALESCE(@ret_cod,0) AS VARCHAR)
	IF COALESCE(@ret_cod,0)<>0 
	  BEGIN
	      SET @MAIL_MESSAGE = @MAIL_MESSAGE + CHAR(10) + @TGT 
	      SET @ERR_CTR = @ERR_CTR + 1 
	  END

	DELETE FROM @MyList WHERE TARGET = @TGT
	
	SET @COUNTER = @COUNTER + 1

END

PRINT 'ERROR COUNTER IS ' + CAST(@ERR_CTR AS VARCHAR(10))

IF @ERR_CTR > 0
  BEGIN
    SET @MAIL_TEXT = 'The ' + @INT + ' interface has run and the following files are missing from SFTP: ' + CHAR(10) + @MAIL_MESSAGE
						+ CHAR(10) + CHAR(10) + 'Message ID = '

	SET @SUBJECT = @INT + ' FILES NOT RECEIVED IN SFTP'

	INSERT INTO dbo.XX_IMAPS_MAIL_OUT
    (MESSAGE_TEXT, MESSAGE_SUBJECT, MAIL_TO_ADDRESS, STATUS_RECORD_NUM, CREATE_DT)
    SELECT @MAIL_TEXT, @SUBJECT, @IN_OPS_OWNER, @in_STATUS_RECORD_NUM, CURRENT_TIMESTAMP
	
	PRINT 'MAIL MESSAGE INCLUDES ' + @MAIL_MESSAGE

	RETURN(562)

  END

PRINT 'CONTENTS OF PROCESS FOLDER: '
SET @CMD= 'DIR ' + @PROCESS_FOLDER + '\*.*'
PRINT 'Command is :' + @CMD
EXEC @ret_cod = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_cod <> 0 GOTO BL_ERROR_HANDLER


PRINT ' '
PRINT '*~^**************************************************************************************************************' 
PRINT '*~^                        END OF ' + @SP_NAME
PRINT '*~^**************************************************************************************************************'
PRINT ' '

SET NOCOUNT OFF
RETURN(0)

BL_ERROR_HANDLER:


SET NOCOUNT OFF
RETURN(562)
END

GO


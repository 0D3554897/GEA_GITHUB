USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CLS_DOWN_FTP_FILE_SP]    Script Date: 3/27/2020 5:45:54 PM ******/
DROP PROCEDURE [dbo].[XX_R22_CLS_DOWN_FTP_FILE_SP]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CLS_DOWN_FTP_FILE_SP]    Script Date: 3/27/2020 5:45:54 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[XX_R22_CLS_DOWN_FTP_FILE_SP]
(
@in_STATUS_RECORD_NUM     integer
)
AS
/************************************************************************************************  
Name:       	XX_R22_CLS_DOWN_FTP_FILE_SP  
Author:     	KM
Created:    	12/2008  
Purpose:    	FTP file

Prerequisites: 	none 

Parameters: 
	Input: 	none
	Output: none   

Version: 	1.0
Notes:      	
************************************************************************************************/  
BEGIN

DECLARE @SP_NAME    sysname,
		@CMD		varchar(500),
		@FTP_SERVER	sysname,
		@FTP_USER sysname,
		@FTP_PASS sysname,
		@FTP_DEST_999FILE sysname,
		@FTP_DEST_PARMFILE sysname,
		@FTP_DEST_FILE sysname,
		@FTP_CMD_FILE sysname,
		@PROCESS_DIR sysname,
		@ret_code	int,
		@JAVA_LOG_FILE			sysname,
        @FTP_LOG_DIR           varchar(200),
        @FILE_CHECK            varchar(200),
		@FTP_ADJUST				int,
		@SEARCH_PHRASE			varchar(100),
		@FTP_CHECK_EXE			sysname,
		@FTP_INI_FILE		    VARCHAR(100),
		@rtn_code	int



--SET LOCAL CONSTANTS
SET @SP_NAME = 'XX_R22_CLS_DOWN_FTP_FILE_SP'	

PRINT '***********************************************************************************************************************'
PRINT @SP_NAME
PRINT '***********************************************************************************************************************'

PRINT 'DETERMINING WHICH DRIVES WE ARE WORKING WITH'

DECLARE @DATA_DRIVE nvarchar(255), @PROG_DRIVE nvarchar(255)

DECLARE @MyTbl TABLE(EnvVar NVARCHAR(255))

INSERT INTO @MyTbl exec xp_cmdshell 'echo %DATA_DRIVE%'
SET @DATA_DRIVE = (SELECT TOP 1 EnvVar from @MyTbl)
DELETE FROM @MyTbl

INSERT INTO @MyTbl exec xp_cmdshell 'echo %PROG_DRIVE%'
SET @PROG_DRIVE = (SELECT TOP 1 EnvVar from @MyTbl)


	--BEGIN FTP
	DECLARE @FTP_command_file sysname,
	        @FTP_EXE sysname,
			@FTP_log_file sysname,			
			@FTP_log_file_2 sysname,			
			@unique_name_part sysname
			
	SELECT @FTP_EXE = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE) 
	FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='UTIL'
	AND PARAMETER_NAME='FTP_EXE'
	
	SELECT @FTP_command_file = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE) 
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='CLS_R22'
	AND PARAMETER_NAME='FTP_COMMAND_FILE'

	SELECT @FTP_log_file = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE) 
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='CLS_R22'
	AND PARAMETER_NAME='FTP_LOG_FILE'

	SET @JAVA_LOG_FILE = @FTP_LOG_FILE
	SET @FTP_LOG_FILE = REPLACE(@FTP_LOG_FILE,'/','\')
	PRINT 'CLS_FTP_LOG_FILE IS ' + @FTP_LOG_FILE    

   -- get ftp log dir  
   SET @FTP_LOG_DIR = LEFT(@FTP_LOG_FILE,LEN(@FTP_LOG_FILE) - charindex('\',reverse(@FTP_LOG_FILE),1) + 1) 
   PRINT 'FTP LOG DIR IS ' + @FTP_LOG_DIR

	SELECT @PROCESS_DIR = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE) 
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='CLS_R22'
	AND PARAMETER_NAME='PROCESS_DIR'

	SET @CMD = 'del /f /q ' + @FTP_LOG_FILE
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD

/*******
	IF @ret_code <> 0 OR @@ERROR <> 0
	BEGIN
	    PRINT 'PROBLEM ERASING ORIGINAL FTP LOG USING: ' + @CMD
		RETURN (1)
	END
*******/

    PRINT 'ORIGINAL LOG FILE DELETED'

	PRINT 'ASSEMBLING FTP COMMAND'
    SET @CMD = @FTP_EXE + ' ' + @FTP_log_file + ' ' + @FTP_command_file
    PRINT 'DOS COMMAND IS : ' + @CMD
	PRINT 'AND CONSISTS OF THE 3 FOLLOWING COMPONENTS, IN ORDER:'
	PRINT '1. FTP_EXE: ' + @FTP_EXE
	PRINT '2. FTP_LOG_FILE: ' + @FTP_LOG_FILE
	PRINT '3. FTP_COMMAND_FILE: ' + @FTP_COMMAND_FILE

    
 	EXEC @ret_code = master.dbo.xp_cmdshell @CMD
	IF @ret_code <> 0 OR @@ERROR <> 0
	BEGIN
	    PRINT 'FTP PROGRAM FAILED TO EXECUTE PROPERLY'
		RETURN (1)
        GOTO BL_ERROR_HANDLER
	END   

/***
	EXEC @ret_code = XX_EXEC_FTP_CMD_SP
		@in_command_file=@FTP_command_file,
		@in_log_file=@FTP_log_file
**/

	IF @ret_code <> 0 OR @@ERROR <> 0
	BEGIN
		RETURN (1)
	END
	--END FTP
	

	
	PRINT 'R22_CLS INTERFACE FILE SENT'

PRINT '***********************************************************************************************************************'
PRINT '                      EVALUATE SUCCESS OF FTP'
PRINT '***********************************************************************************************************************'

   -- LOG CHECK UTILITY
   SELECT @FTP_CHECK_EXE = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE) 
     FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'UTIL'
      AND PARAMETER_NAME = 'FTP_CHECK_EXE'

 SELECT @FILE_CHECK = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE) 
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'UTIL'
   AND PARAMETER_NAME = 'DOES_FILE_EXIST_BAT'

   -- ADJUST FILE COUNT FOR FTP CHECK 
   SELECT @FTP_ADJUST = CAST(PARAMETER_VALUE AS INT)
     FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'CLS_R22'
      AND PARAMETER_NAME = 'CLS_FTP_ADJUST'

   -- SEARCH PHRASE
   SELECT @SEARCH_PHRASE = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE) 
     FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'CLS_R22'
      AND PARAMETER_NAME = 'CLS_SEARCH_PHRASE'  
	  
	SET @FTP_INI_FILE = 'DOES NOT MATTER'
 

  /***************************************************************************************************************
 -- NEW WAY, USING JAVA
-- This is a typical command:
-- D:\GHHS_Data\Interfaces\Programs\Java\ftp_chk\ftp_chk.bat CLS D:\GHHS_Data\Interfaces\Logs\CLS/CLS_FTP_LOG_330_20190521132648.TXT 2 "250 Transfer completed successfully." [SQLSTATE 01000]
--  batch_file + interface + log_file + #_of_search_phrases + search_phrase
-- @FTP_CHECK_EXE + 'CLS' + @FTP_LOG_FILE + @FTP_ADJUST + @SEARCH_PHRASE

*******************************************************************************************************************/

   
-- DELETE THE FTP SUCCESS OR FAILURE FILE FROM THE FTP FOLDER
   PRINT 'NEXT COMMAND DELETES FTP SUCCESS/FAILURE FILE IN FTP FOLDER.'
   SET @CMD = 'ERASE /Q /F ' + @FTP_LOG_DIR + '*.FTP'
   PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD  

   PRINT 'EVALUATING LOG FILES FOR FTP SUCCESS'
   SET @CMD = @FTP_CHECK_EXE + ' CLS_R22 ' + @JAVA_LOG_FILE + ' ' + CAST(@FTP_ADJUST AS VARCHAR) + ' "' + @SEARCH_PHRASE +'"'
   PRINT 'COMMAND IS : ' + @CMD
   PRINT 'CONSISTS OF THE FOLLOWING 5 COMPONENTS, IN ORDER:'
   PRINT '1. FTP_CHECK_EXE: ' + @FTP_CHECK_EXE
   PRINT '2. INTERFACE: CLS_R22'
   PRINT '3. FTP_LOG_FILE: ' + @FTP_LOG_FILE
   PRINT '4. PHRASE COUNT: ' + CAST(@FTP_ADJUST AS VARCHAR)
   PRINT '5. PHRASE: ' + @SEARCH_PHRASE
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code <> 0 OR @@ERROR <> 0
      BEGIN
        PRINT 'CLS FTP EVALUATION ERROR! FTP_CHK FAILED. CODE RETURNED = '  + cast(@rtn_code as varchar)

		GOTO BL_ERROR_HANDLER
        -- RETURN(557)
      END
   PRINT 'CLS FTP LOG FILE CONTENT EVALUATED'
-- END FTP TASK


  -- FILE CHECK SCRIPT LOOKS FOR FILES WITH ERROR CODE PREFIXES
  --   IF FOUND, ERROR IS RAISED THAT CORRESPONDS WITH ERROR CODE
    -- 0 is success, 5 types of ftp failure
         
  -- FTP CHECK SCRIPT NEEDS AN INI FILE TO KNOW WHAT TO DO           
  SET @CMD = @FILE_CHECK + ' ' + @FTP_LOG_DIR + '558.FTP'
  PRINT '558 COMMAND:' + @CMD
  PRINT 'CONSISTS OF:'
  PRINT 'FILE_CHECK_VAR: '+ @FILE_CHECK
  PRINT 'FTP_LOG_DIR:' +  @FTP_LOG_DIR
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
    -- PRINT 'rtn_code=' + cast(coalesce(@rtn_code,99)  as varchar(10))
   IF @rtn_code = 0 AND @@ERROR = 0
     BEGIN
       PRINT 'CLS REQUIRED FTP CHECK INI FILE NOT SPECIFIED.'
       RETURN (558)  
     END
-- END IF   

  -- FTP CHECK SCRIPT NEEDS TO KNOW WHAT WHICH FTP LOG TO EVALUATE
  SET @CMD = @FILE_CHECK + ' ' + @FTP_LOG_DIR + '559.FTP'
  PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   PRINT 'rtn_code=' + cast(@rtn_code as varchar(10))
   IF @rtn_code = 0 AND @@ERROR = 0
     BEGIN
       PRINT 'CLS REQUIRED FTP CHECK SEARCH FILE NOT SPECIFIED.'
       RETURN (559)  
     END
-- END IF   

  -- FTP CHECK SCRIPT NEEDS TO KNOW WHICH FTP COMMAND TO SEARCH FOR (SPECIFIED IN INI FILE)
  SET @CMD = @FILE_CHECK + ' ' + @FTP_LOG_DIR + '560.FTP'
  PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code = 0 AND @@ERROR = 0
     BEGIN
       PRINT 'CLS REQUIRED FTP CHECK SEARCH STRING NOT SPECIFIED.'
       RETURN (560)  
     END
-- END IF 

  -- FTP CHECK SCRIPT NEEDS TO KNOW HOW MANY COMMANDS IT SHOULD FIND (SPECIFIED IN INI FILE)
  SET @CMD = @FILE_CHECK + ' ' + @FTP_LOG_DIR + '561.FTP'
  PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code = 0 AND @@ERROR = 0
     BEGIN
       PRINT 'CLS REQUIRED FTP CHECK SEARCH COUNT NOT SPECIFIED.'
       RETURN (561)  
     END
-- END IF 

  -- FTP CHECK SCRIPT MISMATCH. COMMANDS FOUND IN FTP LOG <> COMMAND COUNT SPECIFIED
  -- E.G., NOT ENOUGH FILES TRANSFERRED; OR TOO MANY; OR NONE
  SET @CMD = @FILE_CHECK + ' ' + @FTP_LOG_DIR + '562.FTP'
  PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code = 0 AND @@ERROR = 0
     BEGIN
       PRINT 'CLS FTP LOG SHOWS WRONG NUMBER OF FILES TRANSFERRED'
       RETURN (562)  
     END
-- END IF 
      
 -- FTP CHECK SCRIPT FOUND NOTHING WRONG
  SET @CMD = @FILE_CHECK + ' ' + @FTP_LOG_DIR + '0.FTP'
  PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
 
   IF @rtn_code <> 0 OR @@ERROR <> 0
     BEGIN
       PRINT '0.FTP not found.  FTP WAS UNSUCCESSFUL. IF NO PROBLEM REPORTED ABOVE, LOOK AT FTP_CHK LOG'
       RETURN (1)
       GOTO BL_ERROR_HANDLER
     END
-- END IF 

 -- IF IT GETS THIS FAR, EVERYTHING WAS OK.
 
   	PRINT 'FTP WAS SUCCESSFUL'

	PRINT '  COMMANDS SHOULD APPEAR AND BE EXECUTED BELOW'

	SELECT @unique_name_part = replace(replace(replace(replace(convert(char(20), getdate(),121),'-',''),':',''),'.',''),' ', '')
	PRINT 'UNIQUE NAME PART IS: ' + @unique_name_part

	--make log file unique for each run
	SET @FTP_LOG_FILE_2 = REPLACE(@FTP_LOG_FILE, 'R22_CLS_FTP', cast(@in_STATUS_RECORD_NUM as varchar) + '_' + 'R22_CLS_FTP')
	PRINT 'FTP_LOG_FILE_2 a: ' + @FTP_LOG_FILE_2
	SET @FTP_log_file_2 = REPLACE(@FTP_log_file_2, '.TXT', '_' + @unique_name_part + '.TXT')
	PRINT 'FTP_LOG_FILE_2 b: ' + @FTP_LOG_FILE_2
	SET @FTP_LOG_FILE_2 = REPLACE(@FTP_LOG_FILE_2, 'LOGS', 'ARCHIVE')
	PRINT 'DESTINATION FTP LOG FILE IS: ' + @FTP_LOG_FILE_2

	SET @CMD = 'COPY /Y ' + @FTP_LOG_FILE + ' ' + @FTP_LOG_FILE_2
	PRINT '1. ' + @CMD
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD
	IF @ret_code <> 0 OR @@ERROR <> 0
	BEGIN
	    PRINT 'PROBLEM COPYING FTP LOG USING: ' + @CMD
		RETURN (1)
	END

	PRINT 'LOG FILE COPIED'


	-- erase temp files LAST
	SET @CMD = 'DEL /F /Q ' + @PROCESS_DIR + '*.*'
	PRINT '2. ' + @CMD
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD
	IF @ret_code <> 0 OR @@ERROR <> 0
	BEGIN
	    PRINT 'PROBLEM DELETING DATA FILES USING: ' + @CMD
		RETURN (1)
	END
	PRINT 'CLS FILES DELETED FROM PROCESS FOLDER'

RETURN(0)

	BL_ERROR_HANDLER:

	PRINT 'FTP HALTED'
	RETURN(1)

END



GO



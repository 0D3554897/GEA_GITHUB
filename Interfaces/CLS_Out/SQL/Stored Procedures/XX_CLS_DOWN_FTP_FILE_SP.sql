USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_CLS_DOWN_FTP_FILE_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 

 




CREATE PROCEDURE [dbo].[XX_CLS_DOWN_FTP_FILE_SP]
(
@in_STATUS_RECORD_NUM     integer
)
AS
/************************************************************************************************  
Name:       	XX_CLS_DOWN_FTP_FILE_SP  
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
SET @SP_NAME = 'XX_CLS_DOWN_FTP_FILE_SP'	

PRINT '***********************************************************************************************************************'
PRINT @SP_NAME
PRINT '***********************************************************************************************************************'


	--BEGIN FTP
	DECLARE @FTP_command_file sysname,
	        @FTP_EXE sysname,
			@FTP_log_file sysname,			
			@FTP_log_file_2 sysname,			
			@unique_name_part sysname
			
	SELECT @FTP_EXE = PARAMETER_VALUE
	FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='CLS'
	AND PARAMETER_NAME='FTP_COMMAND_EXE'
	
	SELECT @FTP_command_file = PARAMETER_VALUE
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='CLS'
	AND PARAMETER_NAME='FTP_COMMAND_FILE'

	SELECT @FTP_log_file = PARAMETER_VALUE
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='CLS'
	AND PARAMETER_NAME='FTP_LOG_FILE'

	SET @JAVA_LOG_FILE = @FTP_LOG_FILE
	SET @FTP_LOG_FILE = REPLACE(@FTP_LOG_FILE,'/','\')
	PRINT 'CLS_FTP_LOG_FILE IS ' + @FTP_LOG_FILE    

   -- get ftp log dir  
   SET @FTP_LOG_DIR = LEFT(@FTP_LOG_FILE,LEN(@FTP_LOG_FILE) - charindex('\',reverse(@FTP_LOG_FILE),1) + 1) 
   PRINT 'FTP LOG DIR IS ' + @FTP_LOG_DIR

	SELECT @PROCESS_DIR = PARAMETER_VALUE
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='CLS'
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


    SET @CMD = @FTP_EXE + ' ' + @FTP_log_file + ' ' + @FTP_command_file
    PRINT 'DOS COMMAND IS : ' + @CMD
    
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
	

	
	PRINT 'CLS INTERFACE FILE SENT'

PRINT '***********************************************************************************************************************'
PRINT '                      EVALUATE SUCCESS OF FTP'
PRINT '***********************************************************************************************************************'

   -- LOG CHECK UTILITY
   SELECT @FTP_CHECK_EXE = PARAMETER_VALUE
     FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'UTIL'
      AND PARAMETER_NAME = 'FTP_CHECK_EXE'

 SELECT @FILE_CHECK = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'UTIL'
   AND PARAMETER_NAME = 'DOES_FILE_EXIST_BAT'

   -- ADJUST FILE COUNT FOR FTP CHECK 
   SELECT @FTP_ADJUST = CAST(PARAMETER_VALUE AS INT)
     FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'CLS'
      AND PARAMETER_NAME = 'CLS_FTP_ADJUST'

   -- SEARCH PHRASE
   SELECT @SEARCH_PHRASE = PARAMETER_VALUE
     FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'CLS'
      AND PARAMETER_NAME = 'CLS_SEARCH_PHRASE'  
	  
	SET @FTP_INI_FILE = 'DOES NOT MATTER'
 

  /***************************************************************************************************************
 -- NEW WAY, USING JAVA
-- This is a typical command:
-- D:\GHHS_Data\Interfaces\Programs\Java\ftp_chk\ftp_chk.bat CLS D:\GHHS_Data\Interfaces\Logs\CLS/CLS_FTP_LOG_330_20190521132648.TXT 2 250 Transfer completed successfully. [SQLSTATE 01000]
--  batch_file + interface + log_file + #_of_search_phrases + search_phrase
-- @FTP_CHECK_EXE + 'CLS' + @FTP_LOG_FILE + @FTP_ADJUST + @SEARCH_PHRASE

*******************************************************************************************************************/

   
-- DELETE THE FTP SUCCESS OR FAILURE FILE FROM THE FTP FOLDER
   PRINT 'NEXT COMMAND DELETES FTP SUCCESS/FAILURE FILE IN FTP FOLDER.'
   SET @CMD = 'ERASE /Q /F ' + @FTP_LOG_DIR + '*.FTP'
   PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD  

   PRINT 'EVALUATING LOG FILES FOR FTP SUCCESS'
   SET @CMD = @FTP_CHECK_EXE + ' CLS ' + @JAVA_LOG_FILE + ' ' + CAST(@FTP_ADJUST AS VARCHAR) + ' ' + @SEARCH_PHRASE + ''
   PRINT 'COMMAND IS : ' + @CMD
   PRINT 'CONSISTS OF THE FOLLOWING, IN ORDER:'
   PRINT 'FTP_CHECK_EXE: ' + @FTP_CHECK_EXE
   PRINT 'INTERFACE: CLS'
   PRINT 'FTP_LOG_FILE: ' + @FTP_LOG_FILE
   PRINT 'PHRASE COUNT: ' + CAST(@FTP_ADJUST AS VARCHAR)
   PRINT 'PHRASE: ' + @SEARCH_PHRASE
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
       
PRINT 'CLSREQUIRED FTP CHECK SEARCH COUNT NOT SPECIFIED.'
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

	SELECT @unique_name_part = replace(replace(replace(replace(convert(char(20), getdate(),121),'-',''),':',''),'.',''),' ', '')

	--make log file unique for each run
	SET @FTP_log_file_2 = REPLACE(@FTP_log_file, '.TXT', '_'+cast(@in_STATUS_RECORD_NUM as varchar)+'_'+@unique_name_part+'.TXT')

	SET @CMD = 'COPY /Y ' + @FTP_LOG_FILE + ' ' + @FTP_log_file_2
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD
	IF @ret_code <> 0 OR @@ERROR <> 0
	BEGIN
	    PRINT 'PROBLEM COPYING FTP LOG USING: ' + @CMD
		RETURN (1)
	END

	PRINT 'LOG FILE COPIED'

	SET @CMD = 'DEL /F /Q ' + @FTP_LOG_FILE
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD
	IF @ret_code <> 0 OR @@ERROR <> 0
	BEGIN
	    PRINT 'PROBLEM ERASING ORIGINAL FTP LOG USING: ' + @CMD
		RETURN (1)
	END

    PRINT 'ORIGINAL LOG FILE DELETED'

	SET @CMD = 'DEL /F /Q ' + @FTP_LOG_DIR + 'CLS_FTP_BAT*.*'
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD
	IF @ret_code <> 0 OR @@ERROR <> 0
	BEGIN
	    PRINT 'PROBLEM ERASING ORIGINAL FTP BATCH LOG USING: ' + @CMD
		RETURN (1)
	END

    PRINT 'ORIGINAL LOG FILE DELETED'

	SET @CMD = 'DEL /F /Q ' + @FTP_LOG_DIR + 'FTP_CHK.TXT'
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD
	IF @ret_code <> 0 OR @@ERROR <> 0
	BEGIN
	    PRINT 'PROBLEM DELETING FTP LOG CHECK LOG USING: ' + @CMD
		RETURN (1)
	END

	SET @CMD = 'DEL /F /Q ' + @FTP_LOG_DIR + 'CFF*.*'
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD
	IF @ret_code <> 0 OR @@ERROR <> 0
	BEGIN
	    PRINT 'PROBLEM DELETING CFF LOGS USING: ' + @CMD
		RETURN (1)
	END
	-- erase temp files LAST
	SET @CMD = 'DEL /F /Q ' + @PROCESS_DIR + 'IMAPS_TO_CLS.BIN'
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD
	IF @ret_code <> 0 OR @@ERROR <> 0
	BEGIN
	    PRINT 'PROBLEM DELETING BIN FILE USING: ' + @CMD
		RETURN (1)
	END

	SET @CMD = 'DEL /F /Q ' + @PROCESS_DIR + 'F155PARM.TXT'
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD
	IF @ret_code <> 0 OR @@ERROR <> 0
	BEGIN
	    PRINT 'PROBLEM DELETING PARM FILE USING: ' + @CMD
		RETURN (1)
	END

	SET @CMD = 'DEL /F /Q ' + @PROCESS_DIR + 'IMAPS_TO_CLS_ERROR*.*'
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD
	IF @ret_code <> 0 OR @@ERROR <> 0
	BEGIN
	    PRINT 'PROBLEM DELETING ERROR FILE USING: ' + @CMD
		RETURN (1)
	END


	PRINT 'CLS FILES DELETED FROM PROCESS FOLDER'

RETURN(0)

	BL_ERROR_HANDLER:

	PRINT 'FTP HALTED'
	RETURN(1)

END



 

 

GO
 


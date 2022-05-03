USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_SABRIX_FTP_FILE_SP]    Script Date: 3/3/2022 11:40:36 AM ******/
DROP PROCEDURE [dbo].[XX_SABRIX_FTP_FILE_SP]
GO

/****** Object:  StoredProcedure [dbo].[XX_SABRIX_FTP_FILE_SP]    Script Date: 3/3/2022 11:40:36 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


 


CREATE PROCEDURE [dbo].[XX_SABRIX_FTP_FILE_SP]
(
@in_STATUS_RECORD_NUM integer,
@in_exec_mode         char(1) -- A = Archive files, F = FTP files
)
AS
/************************************************************************************************  
Name:       	XX_SABRIX_FTP_FILE_SP  
Author:     	CR, KM
Created:    	08/2018  
Purpose:    	FTP TAX FILE TO SABRIX
                Called by XX_SABRIX_CREATE_FILES_SP to process the case TRANSFER_FILES = NO.
                Called by XX_SABRIX_FDSCCS_RUN_INTERFACE_SP to process the case TRANSFER_FILES = YES.

Prerequisites: 	none 

Parameters: 
	Input: 	none
	Output: none   

Version: 	1.0
Notes:      	

************************************************************************************************/  


BEGIN

DECLARE @CMD                   varchar(800),


        @FTP_DIR               varchar(100),
        @myTYPE                sql_variant,
        @FTP_COMMAND_FILE      sysname,
		@FTP_ADJUST				int,
		@FTP_EXE                varchar(100),
		@SEARCH_PHRASE			varchar(100),
		@FTP_CHECK_EXE			sysname,
        @FTP_CMD				sysname,
        @FTP_LOG_FILE          sysname,
		@JAVA_LOG_FILE			sysname,
		@LOG_DIR 			   sysname,
        @FTP_LOG_DIR           varchar(200),
        @FILE_CHECK            varchar(200),
        @DATA_FILE			   varchar(100),	    
        @TEXT_FILE			   varchar(100),	    
        @TRX_FILE			   varchar(100),	    
        @FTP_FILE			   varchar(100),
        @CFF_LOG			   varchar(100),	    
	    @FTP_ini_file		   varchar(100),
	    @DB_CONN               sysname,
        @ARCHIVE_DIR           varchar(100),
        @TRANSFER_FILES        sysname,	
        @unique_name_part	   sysname,        
        @rtn_code              int,
        @SP_NAME               sysname

PRINT '' --CR9449 *~^
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_SABRIX_FTP_FILE_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^
-- *~^
SET @SP_NAME = 'XX_SABRIX_FTP_FILE_SP'

SELECT @in_Status_Record_Num = MAX(STATUS_RECORD_NUM) FROM imapsstg.dbo.XX_IMAPS_INT_STATUS 
  WHERE INTERFACE_NAME = 'SABRIX'

PRINT 'STATUS RECORD NUMBER IS ' + cast(@in_Status_Record_Num as varchar(10))

-- Load Parameters From Table

 SELECT @FILE_CHECK = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'UTIL'
   AND PARAMETER_NAME = 'DOES_FILE_EXIST_BAT'
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 79 : XX_SABRIX_FTP_FILE_SP.sql '  --CR9449
 
-- YES OR NO
SELECT @TRANSFER_FILES = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'SABRIX'
   AND PARAMETER_NAME = 'TRANSFER_FILES'

 IF ISNULL(@TRANSFER_FILES, 'NUL') = 'NUL'
    PRINT 'TRANSFER_FILES IS NULL'
 ELSE
    PRINT 'TRANSFER FILE VALUE IS : ' + @TRANSFER_FILES

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 138 : XX_SABRIX_FTP_FILE_SP.sql '  --CR9449
 
SELECT @FTP_DIR = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'SABRIX'
   AND PARAMETER_NAME = 'FTP_DIR'

 IF ISNULL(@FTP_DIR, 'NUL') = 'NUL'
    PRINT 'FTP_DIR IS NULL' 
    
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 148 : XX_SABRIX_FTP_FILE_SP.sql '  --CR9449
 
SELECT @ARCHIVE_DIR = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'SABRIX'
   AND PARAMETER_NAME = 'ARCHIVE_DIR'

 IF ISNULL(@ARCHIVE_DIR, 'NUL') = 'NUL'
    PRINT 'ARCHIVE_DIR IS NULL'

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 158 : XX_SABRIX_FTP_FILE_SP.sql '  --CR9449
 
SELECT @CFF_LOG = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'SABRIX'
   AND PARAMETER_NAME = 'SABRIX_CFF_LOG_FILE'
 
  IF ISNULL(@CFF_LOG, 'NUL') = 'NUL'
    PRINT 'CFF_LOG IS NULL'
      
SELECT @DATA_FILE = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'SABRIX'
   AND PARAMETER_NAME = 'SABRIX_JAVA_DATA_FILE'
   
 
  IF ISNULL(@DATA_FILE, 'NUL') = 'NUL'
    PRINT 'DATA_FILE IS NULL'
        
   
SELECT @TRX_FILE = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'SABRIX'
   AND PARAMETER_NAME = 'SABRIX_TRX_FILE'

  IF ISNULL(@TRX_FILE, 'NUL') = 'NUL'
    PRINT 'TRX_FILE IS NULL'
      
SELECT @TEXT_FILE = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'SABRIX'
   AND PARAMETER_NAME = 'SABRIX_JAVA_TEXT_FILE'

  IF ISNULL(@TEXT_FILE, 'NUL') = 'NUL'
    PRINT 'TEXT_FILE IS NULL'
      
SELECT @FTP_FILE = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'SABRIX'
   AND PARAMETER_NAME = 'SABRIX_FTP_FILE'

  IF ISNULL(@FTP_FILE, 'NUL') = 'NUL'
    PRINT 'FTP_FILE IS NULL'

SELECT @LOG_DIR = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'SABRIX'
   AND PARAMETER_NAME = 'JAVA_LOG_DIR'

  IF ISNULL(@LOG_DIR, 'NUL') = 'NUL'
    PRINT 'LOG_DIR IS NULL'

      
-- DO NOT TRANSFER THE FILES UNTIL THEY HAVE BEEN REVIEWED
IF (@TRANSFER_FILES = 'NO' OR @TRANSFER_FILES IS NULL) AND @in_exec_mode = 'A'

	BEGIN

		PRINT '*~^**************************************************************************************************************'
		PRINT '*~^                                                                                                             *'
		PRINT '*~^                        ARCHIVING PROCESS BEGINS'
		PRINT '*~^                                                                                                             *'
		PRINT '*~^**************************************************************************************************************'
		   -- Archive Files (DATA FILE, TEXT VERSION, DATA FILE FOR FTP, CFF LOG)
		   PRINT 'NOW ARCHIVING FILES'

		   PRINT 'COPY SABRIX DATA FILE'
		   SET @CMD = 'COPY /Y ' + @FTP_DIR + @DATA_FILE + ' ' + @ARCHIVE_DIR + CAST(@in_STATUS_RECORD_NUM as varchar(10)) + '_' + @FTP_FILE 
		   PRINT @CMD
		   /*
		   SELECT @myType = SQL_VARIANT_PROPERTY(@CMD,'BaseType')
		   PRINT @CMD
		   PRINT cast(@myType as varchar(100))
		   */
		   EXEC master.dbo.xp_cmdshell @CMD
		   IF @rtn_code <> 0 OR @@ERROR <> 0
			  RETURN (557)
   
		   PRINT 'COPY SABRIX TEXT DATA FILE' 
		   SET @CMD = 'COPY /Y ' + @FTP_DIR + @TEXT_FILE + ' ' + @ARCHIVE_DIR + CAST(@in_STATUS_RECORD_NUM as varchar(10)) + '_' + @TEXT_FILE  
		   PRINT @CMD
		   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
		   IF @rtn_code <> 0 OR @@ERROR <> 0
			  RETURN (557)
	
		   PRINT 'COPY SABRIX TRX FILE'
		   SET @CMD = 'COPY /Y ' + @FTP_DIR + @TRX_FILE + ' ' + @ARCHIVE_DIR + CAST(@in_STATUS_RECORD_NUM as varchar(10)) + '_' + @TRX_FILE
		   PRINT @CMD  
		   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
		   IF @rtn_code <> 0 OR @@ERROR <> 0
			  RETURN (557)

		   PRINT 'COPY SABRIX JAVA LOG' 
		   SET @CMD = 'COPY '+ @CFF_LOG + ' '  + @ARCHIVE_DIR + CAST(@in_STATUS_RECORD_NUM as varchar(10)) + '_' + substring(@CFF_LOG,CHARINDEX('CFF_SABRIX.TXT',@CFF_LOG),99)
		   PRINT @CMD
		   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
		   IF @rtn_code <> 0 OR @@ERROR <> 0
			BEGIN
			  PRINT 'SABRIX JAVA LOGS NOT ARCHIVED'
			  RETURN (557)
			END

		   SET @CMD = 'DEL /F /Q '+ @LOG_DIR + 'SABRIX_CFF_LOG.TXT'
		   PRINT @CMD
		   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
		   IF @rtn_code <> 0 OR @@ERROR <> 0
			BEGIN
			  PRINT 'SABRIX JAVA LOGS NOT DELETED'
			END

		   PRINT 'SABRIX INTERFACE FILES ARCHIVED BUT NOT FTPd'
		PRINT '*~^**************************************************************************************************************'
		PRINT '*~^                                                                                                             *'
		PRINT '*~^                        ARCHIVING PROCESS ENDS'
		PRINT '*~^                                                                                                             *'
		PRINT '*~^**************************************************************************************************************'

	END

ELSE IF @TRANSFER_FILES = 'YES' AND @in_exec_mode = 'F'

BEGIN

	PRINT '*~^**************************************************************************************************************'
	PRINT '*~^                                                                                                             *'
	PRINT '*~^                        FTP PROCESS BEGINS'
	PRINT '*~^                                                                                                             *'
	PRINT '*~^**************************************************************************************************************'

-- CR-9449 Begin
   PRINT ' '
   PRINT ' FILE IS ALREADY ARCHIVED, THIS IS THE FTP PROCEDURE, IN ORDER'
   PRINT ' FTP THE FILE'
   PRINT ' FTP_CHECK THE FILE TO MAKE SURE NUMBER OF FILES SENT IS AS EXPECTED'
   PRINT ' USE BATCH FILE TO RECORD RESULTS OF FTP_CHECK'
   PRINT ' ERASE THE FILE THAT WAS JUST FTPed'
   PRINT ' THE END'
   PRINT ' '

-- BEGIN FTP TASK
 
PRINT 'PREP FOR FTP'

   PRINT 'NEXT COMMAND REVEALS STATE OF PROCESS FOLDER.'
   SET @CMD = 'DIR ' + @FTP_DIR + '*.*'
   PRINT 'COMMAND IS: ' + @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD  
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 261 : XX_SABRIX_FTP_FILE_SP.sql '  --CR9449
 
 	SELECT @FTP_EXE = PARAMETER_VALUE
	FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='SABRIX'
	AND PARAMETER_NAME='FTP_COMMAND_EXE'


 
   SELECT @FTP_command_file = PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'SABRIX'
      AND PARAMETER_NAME = 'SABRIX_FTP_COMMAND_FILE'

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 271 : XX_SABRIX_FTP_FILE_SP.sql '  --CR9449
 
   SELECT @FTP_log_file = PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'SABRIX'
      AND PARAMETER_NAME = 'SABRIX_FTP_LOG_FILE'

    SELECT @FTP_ini_file = PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'SABRIX'
      AND PARAMETER_NAME = 'SABRIX_FTP_INI_FILE'
      
SELECT @DB_CONN = PARAMETER_VALUE
  FROM IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'UTIL'
   AND PARAMETER_NAME = 'DB_CONN_INI'  
   
     -- LOG CHECK UTILITY
   SELECT @FTP_CHECK_EXE = PARAMETER_VALUE
     FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'UTIL'
      AND PARAMETER_NAME = 'FTP_CHECK_EXE'

   -- ADJUST FILE COUNT FOR FTP CHECK 
   SELECT @FTP_ADJUST = CAST(PARAMETER_VALUE AS INT)
     FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'SABRIX'
      AND PARAMETER_NAME = 'SABRIX_FTP_ADJUST'

   -- SEARCH PHRASE
   SELECT @SEARCH_PHRASE = PARAMETER_VALUE
     FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'SABRIX'
      AND PARAMETER_NAME = 'SABRIX_SEARCH_PHRASE'    
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 281 : XX_SABRIX_FTP_FILE_SP.sql '  --CR9449

PRINT 'FTP COMMANDS BEGIN HERE. REFER TO LOGS FOR DETAIL'

	SELECT @unique_name_part = replace(replace(replace(replace(convert(char(20), getdate(),121),'-',''),':',''),'.',''),' ', '')

	--make log file unique for each run
	SET @FTP_log_file = REPLACE(@FTP_log_file, '.TXT', '_' + cast(@in_STATUS_RECORD_NUM as varchar) + '_' + @unique_name_part+'.TXT')
	PRINT 'FTP EXE IS: ' + @FTP_EXE
	PRINT 'FTP LOG IS: ' + @FTP_log_file
	PRINT 'FTP CMD IS: ' + @FTP_command_file

    SET @CMD = @FTP_EXE + ' ' + @FTP_log_file + ' ' + @FTP_command_file
    PRINT 'DOS COMMAND IS : ' + @CMD
    
    EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
	IF @rtn_code <> 0 OR @@ERROR <> 0
	BEGIN
		RETURN (1)
	END   

   PRINT 'FTP COMMAND EXECUTED. FTP LOG FILE IS ' + @FTP_log_file
-- END FTP TASK

   -- check for success
   -- get ftp log dir  
   SET @FTP_LOG_DIR = LEFT(@FTP_LOG_FILE,LEN(@FTP_LOG_FILE) - charindex('\',reverse(@FTP_LOG_FILE),1) + 1) 
   SET @FTP_LOG_DIR = @FTP_LOG_DIR + 'SABRIX\'
   PRINT 'THE FTP_LOG_DIR VARIABLE IS: ' +  @FTP_LOG_DIR 
   
   
-- DELETE THE FTP SUCCESS OR FAILURE FILE FROM THE FTP FOLDER
   PRINT 'NEXT COMMAND DELETES FTP SUCCESS/FAILURE FILE IN FTP FOLDER.'
   SET @CMD = 'ERASE /Q /F ' + @FTP_LOG_DIR + '*.FTP'
   PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD  

 /***************************************************************************************************************
 -- OLD WAY, USING MACRO SCHEDULER 
   PRINT 'EVALUATING LOG FILES FOR FTP SUCCESS'
   SET @CMD = @FTP_CHECK_EXE + ' /ini=' + @FTP_ini_file + ' /FILENAME=' + @FTP_log_file  + ' ' + @DB_CONN
   PRINT @FTP_CHECK_EXE
   PRINT @FTP_ini_file
   PRINT @FTP_log_file
   PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code <> 0 OR @@ERROR <> 0
      BEGIN
        PRINT 'FTP EVALUATION ERROR! CODE RETURNED = '  + cast(@rtn_code as varchar)
        RETURN (@rtn_code)
        -- RETURN(557)
      END
*******************************************************************************************************************/

 /***************************************************************************************************************
 -- NEW WAY, USING JAVA
-- This is a typical command:
-- D:\GHHS_Data\Interfaces\Programs\Java\ftp_chk\ftp_chk.bat SABRIX D:/GHHS_Data/Interfaces/Logs/SABRIX/SABRIX_FTP_LOG_330_20190521132648.TXT 2 250 Transfer completed successfully. [SQLSTATE 01000]
--  batch_file + interface + log_file + #_of_search_phrases + search_phrase
-- @FTP_CHECK_EXE + @FTP_LOG_FILE + @FTP_ADJUST + @SEARCH_PHRASE

*******************************************************************************************************************/

   PRINT 'EVALUATING LOG FILES FOR FTP SUCCESS'
   SET @CMD = @FTP_CHECK_EXE + ' SABRIX ' + @FTP_LOG_FILE + ' ' + CAST(@FTP_ADJUST AS VARCHAR) + ' ' + @SEARCH_PHRASE +''
   PRINT @CMD
   PRINT 'CONSISTS OF THE FOLLOWING 5 COMPONENTS, IN ORDER:'
   PRINT '1. FTP_CHECK_EXE: '+  @FTP_CHECK_EXE
   PRINT '2. INTERFACE: SABRIX'
   PRINT '3. FTP LOG FILE: ' + @FTP_LOG_FILE
   PRINT '4. FTP ADJUST: ' + CAST(@FTP_ADJUST AS VARCHAR)
   PRINT '5. FTP SEARCH PHRASE: ' + @SEARCH_PHRASE
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code <> 0 OR @@ERROR <> 0
      BEGIN
        PRINT 'SABRIX FTP EVALUATION ERROR! CODE RETURNED = '  + cast(@rtn_code as varchar)
        RETURN (@rtn_code)
        -- RETURN(557)
      END
   PRINT 'SABRIX FTP LOG FILE CONTENT EVALUATED'
-- END FTP TASK


  -- FILE CHECK SCRIPT LOOKS FOR FILES WITH ERROR CODE PREFIXES
  --   IF FOUND, ERROR IS RAISED THAT CORRESPONDS WITH ERROR CODE
    -- 0 is success, 5 types of ftp failure

         
  -- FTP CHECK SCRIPT NEEDS AN INI FILE TO KNOW WHAT TO DO           
  SET @CMD = @FILE_CHECK + ' ' + @FTP_LOG_DIR + '558.FTP'
  PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
    -- PRINT 'rtn_code=' + cast(coalesce(@rtn_code,99)  as varchar(10))
   IF @rtn_code = 0 AND @@ERROR = 0
     BEGIN
       PRINT 'SABRIX REQUIRED FTP CHECK INI FILE NOT SPECIFIED.'
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
       PRINT 'SABRIX REQUIRED FTP CHECK SEARCH FILE NOT SPECIFIED.'
       RETURN (559)  
     END
-- END IF   

  -- FTP CHECK SCRIPT NEEDS TO KNOW WHICH FTP COMMAND TO SEARCH FOR (SPECIFIED IN INI FILE)
  SET @CMD = @FILE_CHECK + ' ' + @FTP_LOG_DIR + '560.FTP'
  PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code = 0 AND @@ERROR = 0
     BEGIN
       PRINT 'SABRIX REQUIRED FTP CHECK SEARCH STRING NOT SPECIFIED.'
       RETURN (560)  
     END
-- END IF 

  -- FTP CHECK SCRIPT NEEDS TO KNOW HOW MANY COMMANDS IT SHOULD FIND (SPECIFIED IN INI FILE)
  SET @CMD = @FILE_CHECK + ' ' + @FTP_LOG_DIR + '561.FTP'
  PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code = 0 AND @@ERROR = 0
     BEGIN
       PRINT 'SABRIX REQUIRED FTP CHECK SEARCH COUNT NOT SPECIFIED.'
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
       PRINT 'SABRIX FTP LOG SHOWS WRONG NUMBER OF FILES TRANSFERRED'
       RETURN (562)  
     END
-- END IF 

  -- archive ftp log no matter what happened
  SET @CMD = 'COPY /Y ' + replace(@FTP_LOG_FILE,'/','\') + ' ' +  @ARCHIVE_DIR + cast(@in_Status_Record_Num as varchar(10)) + '_SABRIX_FTP_LOG_'  + @unique_name_part+'.TXT' 
  PRINT 'ARCHIVE COMMAND: ' + @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMd
      
 -- FTP CHECK SCRIPT FOUND NOTHING WRONG
  SET @CMD = @FILE_CHECK + ' ' + @FTP_LOG_DIR + '0.FTP'
  PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code = 0 AND @@ERROR = 0
     BEGIN
       PRINT 'SABRIX FTP CHECK TESTS PASSED. FTP WAS SUCCESSFUL.'
       RETURN (@rtn_code)  
     END
--   IF @rtn_code <> 0 OR @@ERROR <> 0
   ELSE
     BEGIN
       PRINT 'SABRIX FTP CHECK FAILED.  SEE THE FTP CHECK LOG (?.FTP) FOR DETAILS'
       RETURN (1)  
     END
-- END IF 


   -- Erase temporary files (Post-FTP)
   SET @CMD = 'DEL /F /Q ' + @FTP_FILE
   PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code <> 0 OR @@ERROR <> 0
      RETURN (557)

   -- Erase temporary files (Post-FTP)
   SET @CMD = 'DEL /F /Q SABRIX_FTP_LOG*'
   PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code <> 0 OR @@ERROR <> 0
      RETURN (557)

   PRINT 'SABRIX FILE JUST FTPed IS ERASED, AS WELL AS THE LOG'

   PRINT 'SABRIX INTERFACE FILE SENT'
	PRINT '*~^**************************************************************************************************************'
	PRINT '*~^                                                                                                             *'
	PRINT '*~^                        FTP PROCESS ENDS'
	PRINT '*~^                                                                                                             *'
	PRINT '*~^**************************************************************************************************************'
END

 
 
PRINT '' --CR9449 *~^
PRINT '*~^*************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF  XX_SABRIX_FTP_FILE_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^
RETURN(0)

END

 

 

 

 

 

 

 

GO



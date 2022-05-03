USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_FDS_FTP_CCS_FILE_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 


 

 





CREATE PROCEDURE [dbo].[XX_FDS_FTP_CCS_FILE_SP]
(
@in_STATUS_RECORD_NUM integer,
@in_exec_mode         char(1) -- A = Archive files, F = FTP files
)
AS
/************************************************************************************************  
Name:       	XX_FDS_FTP_CCS_FILE_SP  
Author:     	CR, KM
Created:    	08/2018  
Purpose:    	FTP INVOICE FILE TO CCS
                Called by XX_FDS_CREATE_FLAT_FILES_SP to process the case TRANSFER_FILES = NO.
                Called by XX_FDS_FDSCCS_RUN_INTERFACE_SP to process the case TRANSFER_FILES = YES.

Prerequisites: 	none 

Parameters: 
	Input: 	none
	Output: none   

Version: 	1.0
Notes:      	

CR10364 - ADDED NEW CONTROL POINT FOR FTP OF CCS FILE
************************************************************************************************/  


BEGIN

DECLARE @CMD                   varchar(800),


        @FTP_DIR               varchar(100),
        @myTYPE                sql_variant,
        @FTP_COMMAND_FILE      sysname,
        @FTP_CMD				sysname,
	@FTP_CHECK_EXE         sysname,
	@FTP_EXE         sysname,
		@FTP_ADJUST				varchar(2),
		@SEARCH_PHRASE			varchar(100),
        @FTP_LOG_FILE          sysname,
       @FTP_LOG_FILE2          sysname,
		@JAVA_LOG_FILE			sysname,                
        @JAVA_LOG_DIR           varchar(200),
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
PRINT '*~^                        HERE IN XX_FDS_FTP_CCS_FILE_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^
-- *~^
SET @SP_NAME = 'XX_FDS_FTP_CCS_FILE_SP'

SELECT @in_Status_Record_Num = MAX(STATUS_RECORD_NUM) FROM imapsstg.dbo.XX_IMAPS_INT_STATUS 
  WHERE INTERFACE_NAME = 'FDS'

PRINT 'STATUS RECORD NUMBER IS ' + cast(@in_Status_Record_Num as varchar(10))

-- Load Parameters From Table

 SELECT @FILE_CHECK = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'UTIL'
   AND PARAMETER_NAME = 'DOES_FILE_EXIST_BAT'
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 79 : XX_FDS_FTP_CCS_FILE_SP.sql '  --CR9449
 
-- YES OR NO
SELECT @TRANSFER_FILES = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'TRANSFER_FILES'

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 138 : XX_FDS_FTP_CCS_FILE_SP.sql '  --CR9449
 
SELECT @FTP_DIR = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'FTP_DIR'
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 148 : XX_FDS_FTP_CCS_FILE_SP.sql '  --CR9449
 
SELECT @ARCHIVE_DIR = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'ARCHIVE_DIR'

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 158 : XX_FDS_FTP_CCS_FILE_SP.sql '  --CR9449
 
   
SELECT @DATA_FILE = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'CCS_JAVA_DATA_FILE'
PRINT 'DATA FILE IS ' + @DATA_FILE

SELECT @TRX_FILE = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'CCS_TRX_FILE'

SELECT @TEXT_FILE = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'CCS_JAVA_TEXT_FILE'

SELECT @FTP_FILE = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'CCS_JAVA_DATA_FILE'

-- DO NOT TRANSFER THE FILES UNTIL THEY HAVE BEEN REVIEWED
IF (@TRANSFER_FILES = 'NO' OR @TRANSFER_FILES IS NULL) AND @in_exec_mode = 'A'
BEGIN
   -- Archive Files (DATA FILE, TEXT VERSION, DATA FILE FOR FTP, CFF LOG)
   PRINT 'NOW COPYING FILES'

   PRINT 'COPY CCS DATA FILE'
   SET @CMD = 'COPY /Y ' + @FTP_DIR + @DATA_FILE + ' ' + @ARCHIVE_DIR + CAST(@in_STATUS_RECORD_NUM as varchar(10)) + '_' + @FTP_FILE 
   PRINT @CMD
   /*
   SELECT @myType = SQL_VARIANT_PROPERTY(@CMD,'BaseType')
   PRINT @CMD
   PRINT cast(@myType as varchar(100))
   */
   EXEC master.dbo.xp_cmdshell @CMD
   IF @rtn_code <> 0 OR @@ERROR <> 0
      BEGIN
        PRINT 'FAILURE: CCS DATA FILE NOT FOUND'
        RETURN (557)
      END
   
   PRINT 'CCS INTERFACE FILE ARCHIVED BUT NOT SENT'
END


ELSE IF @TRANSFER_FILES = 'YES' AND @in_exec_mode = 'F'
BEGIN


PRINT 'PREP FOR FTP'
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 261 : XX_FDS_FTP_CCS_FILE_SP.sql '  --CR9449

   SELECT @FTP_CMD = PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'FDS'
      AND PARAMETER_NAME = 'CCS_FTP_CMD'
 
   SELECT @FTP_command_file = PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'FDS'
      AND PARAMETER_NAME = 'FTP_CCS_COMMAND_FILE'
	  
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 271 : XX_FDS_FTP_CCS_FILE_SP.sql '  --CR9449

   SELECT @FTP_log_file = PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'FDS'
      AND PARAMETER_NAME = 'FTP_CCS_LOG_FILE'

    SET @JAVA_LOG_FILE = @FTP_LOG_FILE
	SET @FTP_LOG_DIR = REPLACE(SUBSTRING(@JAVA_LOG_FILE, 0, CHARINDEX('/',@JAVA_LOG_FILE)+1),'/','\')
	SET @JAVA_LOG_DIR = SUBSTRING(@JAVA_LOG_FILE, 0, CHARINDEX('/',@JAVA_LOG_FILE)+1)
	SET @FTP_LOG_FILE = SUBSTRING(@JAVA_LOG_FILE, CHARINDEX('/',@JAVA_LOG_FILE)+1, 100)
	PRINT 'CCS_FTP_LOG_DIR IS ' + @FTP_LOG_DIR
	PRINT 'CCS_FTP_LOG_FILE IS ' + @FTP_LOG_FILE
	PRINT 'JAVA_LOG_DIR IS ' + @JAVA_LOG_DIR

    SELECT @FTP_ini_file = PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'FDS'
      AND PARAMETER_NAME = 'FTP_CCS_INI_FILE'
 
     SELECT @FTP_CHECK_EXE = PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'UTIL'
      AND PARAMETER_NAME = 'FTP_CHECK_EXE'
    

   -- ADJUST FILE COUNT FOR FTP CHECK 
   SELECT @FTP_ADJUST = CAST(PARAMETER_VALUE AS INT)
     FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'FDS'
      AND PARAMETER_NAME = 'CCS_FTP_ADJUST'

   -- SEARCH PHRASE
   SELECT @SEARCH_PHRASE = PARAMETER_VALUE
     FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'FDS'
      AND PARAMETER_NAME = 'CCS_SEARCH_PHRASE'  

  SELECT @FTP_EXE = PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'FDS'
      AND PARAMETER_NAME = 'CCS_FTP_CMD'
 
 
PRINT 'FTP COMMANDS BEGIN HERE. REFER TO LOGS FOR DETAIL'

	SELECT @unique_name_part = replace(replace(replace(replace(convert(char(20), getdate(),121),'-',''),':',''),'.',''),' ', '')

	--make log file unique for each run
	SET @FTP_log_file = cast(@in_STATUS_RECORD_NUM as varchar) + '_' + REPLACE(@FTP_log_file, '.TXT', '_' +  @unique_name_part+'.TXT')
	PRINT 'FTP EXE IS: ' + @FTP_EXE
	PRINT 'FTP LOG DIR IS: ' + @FTP_LOG_DIR
	PRINT 'FTP LOG IS: ' + @FTP_log_file
	PRINT 'FTP CMD IS: ' + @FTP_command_file

    SET @CMD = @FTP_EXE + ' ' + @FTP_LOG_DIR + @FTP_log_file + ' ' + @FTP_command_file
    PRINT 'DOS COMMAND IS : ' + @CMD
    
    EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
	IF @rtn_code <> 0 OR @@ERROR <> 0
	BEGIN
		RETURN (1)
	END   

   PRINT 'FTP COMMAND EXECUTED. FTP LOG FILE IS ' + @FTP_log_file

-- END FTP TASK

   -- ARCHIVE FTP FILE SUCCESS OR NO
   SET @CMD = 'COPY /Y ' + @FTP_LOG_DIR + @FTP_LOG_FILE + ' ' + @ARCHIVE_DIR + @FTP_LOG_FILE
   PRINT 'ARCHIVE COMMAND IS : ' + @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code <> 0 OR @@ERROR <> 0
     BEGIN
       PRINT 'CCS FTP LOG NOT ARCHIVED.'
       -- RETURN (@rtn_code)  
     END
   PRINT 'CCS FTP LOG ARCHIVED'

   PRINT '**********************************************************************************************************'
   PRINT '                                    CHECKING FOR SUCCESS     '
   PRINT '**********************************************************************************************************'
   -- check for success
   -- get ftp log dir  

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
        PRINT 'CCS FTP EVALUATION ERROR! CODE RETURNED = '  + cast(@rtn_code as varchar)
        RETURN (@rtn_code)
        -- RETURN(557)
      END
*******************************************************************************************************************/

 /***************************************************************************************************************
 -- NEW WAY, USING JAVA
-- This is a typical command:
-- D:\GHHS_Data\Interfaces\Programs\Java\ftp_chk\ftp_chk.bat SABRIX D:/GHHS_Data/Interfaces/Logs/SABRIX/SABRIX_FTP_LOG_330_20190521132648.TXT 2 250 Transfer completed successfully. [SQLSTATE 01000]
--  batch_file + log_file + #_of_search_phrases + search_phrase
-- @FTP_CHECK_EXE + @FTP_LOG_FILE + @FTP_ADJUST + @SEARCH_PHRASE

*******************************************************************************************************************/

   PRINT 'EVALUATING LOG FILES FOR FTP SUCCESS'
   SET @CMD = @FTP_CHECK_EXE + ' FDS ' + @JAVA_LOG_DIR + @FTP_LOG_FILE + ' ' + @FTP_ADJUST + ' ' + @SEARCH_PHRASE +''
   PRINT @CMD
   PRINT 'CONSISTS OF THE FOLLOWING, IN ORDER:'
   PRINT 'EXECUTABLE: ' + @FTP_CHECK_EXE
   PRINT 'INTERFACE: ' + 'FDS'
   PRINT 'LOG FILE: ' +  @JAVA_LOG_DIR + @FTP_LOG_FILE 
   PRINT 'ADJUST: ' +@FTP_ADJUST
   PRINT 'PHRASE:' + @SEARCH_PHRASE
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code <> 0 OR @@ERROR <> 0
      BEGIN
        PRINT 'CCS FTP EVALUATION ERROR! CODE RETURNED = '  + cast(@rtn_code as varchar)
        RETURN (@rtn_code)
        -- RETURN(557)
      END
   PRINT 'FTP LOG FILE CONTENT EVALUATED'
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
       PRINT 'CCS REQUIRED FTP CHECK INI FILE NOT SPECIFIED.'
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
       PRINT 'CCS REQUIRED FTP CHECK SEARCH FILE NOT SPECIFIED.'
       RETURN (559)  
     END
-- END IF   

  -- FTP CHECK SCRIPT NEEDS TO KNOW WHICH FTP COMMAND TO SEARCH FOR (SPECIFIED IN INI FILE)
  SET @CMD = @FILE_CHECK + ' ' + @FTP_LOG_DIR + '560.FTP'
  PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code = 0 AND @@ERROR = 0
     BEGIN
       PRINT 'CCS REQUIRED FTP CHECK SEARCH STRING NOT SPECIFIED.'
       RETURN (560)  
     END
-- END IF 

  -- FTP CHECK SCRIPT NEEDS TO KNOW HOW MANY COMMANDS IT SHOULD FIND (SPECIFIED IN INI FILE)
  SET @CMD = @FILE_CHECK + ' ' + @FTP_LOG_DIR + '561.FTP'
  PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code = 0 AND @@ERROR = 0
     BEGIN
       PRINT 'CCS REQUIRED FTP CHECK SEARCH COUNT NOT SPECIFIED.'
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
       PRINT 'CCS FTP LOG SHOWS WRONG NUMBER OF FILES TRANSFERRED'
       RETURN (562)  
     END
-- END IF 
      
 -- FTP CHECK SCRIPT FOUND NOTHING WRONG
  SET @CMD = @FILE_CHECK + ' ' + @FTP_LOG_DIR + '0.FTP'
  PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
     IF @rtn_code <> 0 OR @@ERROR <> 0
     BEGIN
       PRINT '0.FTP not found.  FTP WAS UNSUCCESSFUL.  LOOK FOR PROBLEMS WITH FTP CHECK OR LOG'
       RETURN (1)  
     END
-- END IF 

    -- IF IT GETS THIS FAR, EVERYTHING WAS OK.  
   	PRINT 'FTP WAS SUCCESSFUL'




   PRINT 'CCS INTERFACE FILE SENT'
END

 
 
PRINT '' --CR9449 *~^
PRINT '*~^*************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF  XX_FDS_FTP_CCS_FILE_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^
RETURN(0)

END








 

 

 

GO
 


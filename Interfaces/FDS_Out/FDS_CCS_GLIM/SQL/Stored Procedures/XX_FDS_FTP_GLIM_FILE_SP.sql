USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_FDS_FTP_GLIM_FILE_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 


 

 



CREATE PROCEDURE [dbo].[XX_FDS_FTP_GLIM_FILE_SP]
(
@in_STATUS_RECORD_NUM integer,
@in_exec_mode         char(1) -- A = Archive files, F = FTP files
)
AS
/************************************************************************************************  
Name:       	XX_FDS_FTP_GLIM_FILE_SP  
Author:     	GEA
Created:    	01/2018  
Purpose:    	FTP AR FILE TO GLIM OR COPY TO ARCHIVE
                Called by XX_FDS_CREATE_FLAT_FILES_SP to process the case TRANSFER_FILES = NO.
                Called by XX_FDS_FDSCCS_RUN_INTERFACE_SP to process the case TRANSFER_FILES = YES.

Prerequisites: 	none 

Parameters: 
	Input: 	none
	Output: none   

Version: 	1.0
Notes:      	

CR-9449         HVT Add new control point for GLIM file FTP process.
                12/14/2017 GEA Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
CR9449 - gea - 1/24/2018 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
************************************************************************************************/  


BEGIN

DECLARE @CMD                   varchar(500),
        @SP_NAME		       sysname,
        @FTP_DIR               sysname,
        @FTP_CMD_FILE          sysname,
        @FTP_CMD				sysname,
	    @FTP_CHECK_EXE         sysname,
		@FTP_EXE				sysname,
		@FTP_ADJUST				varchar(2),
		@SEARCH_PHRASE			varchar(100),
	    @FTP_GLIM_ini_file     sysname, 
	    @DB_CONN               sysname,       
        @ARCHIVE_DIR           sysname,
        @ERROR_DIR             sysname,
        @TRANSFER_FILES        sysname,
        @GLIM_OUT_FILE_1       sysname,
        @GLIM_OUT_FILE_2       sysname,
        @GLIM_FTP_DEST_FILE_1  sysname,
        @GLIM_FTP_DEST_FILE_2  sysname,
        @FTP_COMMAND_FILE      sysname,
        @FTP_LOG_FILE          sysname,
        @FTP_LOG_FILE2          sysname,
		@JAVA_LOG_FILE			sysname,
        @JAVA_LOG_DIR           varchar(200),
		@FTP_LOG_DIR           varchar(200),
        @FILE_CHECK            varchar(200),
        @unique_name_part      sysname,
        @rtn_code              int
        

PRINT '' --CR9449 *~^
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_FDS_FTP_GLIM_FILE_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^
-- *~^
SET @SP_NAME = 'XX_FDS_FTP_GLIM_FILE_SP'

-- Load Parameters From Table
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 79 : XX_FDS_FTP_GLIM_FILE_SP.sql '  --CR9449
 
SELECT @TRANSFER_FILES = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'TRANSFER_FILES'


SELECT @FILE_CHECK = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'UTIL'
   AND PARAMETER_NAME = 'DOES_FILE_EXIST_BAT'
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 89 : XX_FDS_FTP_GLIM_FILE_SP.sql '  --CR9449
 
SELECT @FTP_DIR = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'FTP_DIR'

PRINT 'FTP DIR IS ' + @FTP_DIR
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 99 : XX_FDS_FTP_GLIM_FILE_SP.sql '  --CR9449
 
SELECT @ARCHIVE_DIR = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'ARCHIVE_DIR'

PRINT 'ARCHIVE DIR IS ' + @ARCHIVE_DIR
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 109 : XX_FDS_FTP_GLIM_FILE_SP.sql '  --CR9449
 
SELECT @ERROR_DIR = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'ERROR_DIR'

PRINT 'ERROR DIR IS ' + @ERROR_DIR

SELECT @GLIM_OUT_FILE_1 = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'GLIM_FTP_DEST_FILE_1'

PRINT 'GLIM FTP FILE1 IS ' + @GLIM_OUT_FILE_1

SELECT @GLIM_OUT_FILE_2 = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'GLIM_FTP_DEST_FILE_2'

PRINT 'GLIM FTP FILE2 IS ' + @GLIM_OUT_FILE_2

-- CR 10176

    SELECT @FILE_CHECK = PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'UTIL'
      AND PARAMETER_NAME = 'DOES_FILE_EXIST_BAT'
      
PRINT 'FILE CHECK BATCH FILE IS ' + @FILE_CHECK


-- DO NOT TRANSFER THE FILES UNTIL THEY HAVE BEEN REVIEWED
IF (@TRANSFER_FILES = 'NO' OR @TRANSFER_FILES IS NULL) AND @in_exec_mode = 'A'
BEGIN
   -- Archive Files
-- does an out of balance file exist?  if so, stop process
   SET @CMD = @FILE_CHECK + ' ' + @FTP_DIR + @GLIM_OUT_FILE_1  + 'OOB' 
   PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code = 0 OR @@ERROR <> 0
   BEGIN
      PRINT @FTP_DIR  + @GLIM_OUT_FILE_1 + 'OOB FOUND! GLIM FILE IS OUT OF BALANCE.'
      RETURN (556)  -- 556 = OUT OF BALANCE
   END

-- first, make sure it exists. if not, stop the process; duplicate check, but no harm
   SET @CMD = @FILE_CHECK + ' ' + @FTP_DIR + @GLIM_OUT_FILE_1 
   PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code <> 0 OR @@ERROR <> 0
   BEGIN
      PRINT @FTP_DIR  + @GLIM_OUT_FILE_1 + ' NOT FOUND! '
      RETURN (557)  -- 557 = file not found
   END

-- END 10176

-- if so, move it
   SET @CMD = 'COPY /Y ' + @FTP_DIR + @GLIM_OUT_FILE_1 + ' ' + @ARCHIVE_DIR + CAST(@in_STATUS_RECORD_NUM as varchar(10)) + '_' + @GLIM_OUT_FILE_1
   PRINT @CMD 
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code <> 0 OR @@ERROR <> 0
      RETURN (557)

   PRINT @GLIM_OUT_FILE_1 + ' ARCHIVED TO ' + @ARCHIVE_DIR

-- first, make sure it exists.  if not, stop the process

   SET @CMD =  @FILE_CHECK + ' ' + @FTP_DIR + @GLIM_OUT_FILE_2 
   PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code <> 0 OR @@ERROR <> 0
   BEGIN
      PRINT @FTP_DIR + @GLIM_OUT_FILE_2 + ' NOT FOUND! '
      RETURN (557)  -- 557 = file not found
   END

-- if so, move it	
   SET @CMD = 'COPY /Y ' + @FTP_DIR + @GLIM_OUT_FILE_2 + ' ' + @ARCHIVE_DIR  + CAST(@in_STATUS_RECORD_NUM as varchar(10)) + '_' + @GLIM_OUT_FILE_2
   PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code <> 0 OR @@ERROR <> 0
      RETURN (557)

   PRINT @GLIM_OUT_FILE_2 + ' ARCHIVED TO ' + @ARCHIVE_DIR    

   PRINT 'GLIM INTERFACE FILE ARCHIVED BUT NOT SENT'
END
ELSE IF @TRANSFER_FILES = 'YES' AND @in_exec_mode = 'F'
BEGIN
-- CR-9449 Begin
   PRINT '_ '

   -- BEGIN FTP TASK
 SELECT @FTP_DIR = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'FTP_DIR'

PRINT 'FTP DIR IS ' + @FTP_DIR
 
   SELECT @FTP_CMD = PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'FDS'
      AND PARAMETER_NAME = 'GLIM_FTP_CMD'
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 210 : XX_FDS_FTP_GLIM_FILE_SP.sql '  --CR9449
 
   SELECT @FTP_COMMAND_FILE = PARAMETER_VALUE
     FROM dbo.XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'FDS'
      AND PARAMETER_NAME = 'GLIM_FTP_COMMAND_FILE'
      
    PRINT 'GLIM_FTP_COMMAND_FILE IS ' + @FTP_COMMAND_FILE


PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 222 : XX_FDS_FTP_GLIM_FILE_SP.sql '  --CR9449
 
   SELECT @FTP_LOG_FILE = PARAMETER_VALUE
     FROM dbo.XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'FDS'
      AND PARAMETER_NAME = 'GLIM_FTP_LOG_FILE'

    SET @JAVA_LOG_FILE = @FTP_LOG_FILE
	SET @FTP_LOG_DIR = REPLACE(SUBSTRING(@JAVA_LOG_FILE, 0, CHARINDEX('/',@JAVA_LOG_FILE)+1),'/','\')
	SET @JAVA_LOG_DIR = SUBSTRING(@JAVA_LOG_FILE, 0, CHARINDEX('/',@JAVA_LOG_FILE)+1)
	SET @FTP_LOG_FILE = SUBSTRING(@JAVA_LOG_FILE, CHARINDEX('/',@JAVA_LOG_FILE)+1, 100)
	PRINT 'GLIM_FTP_LOG_DIR IS ' + @FTP_LOG_DIR
	PRINT 'GLIM_FTP_LOG_FILE IS ' + @FTP_LOG_FILE
	PRINT 'JAVA_LOG_DIR IS ' + @JAVA_LOG_DIR

SELECT @DB_CONN = PARAMETER_VALUE
  FROM IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'UTIL'
   AND PARAMETER_NAME = 'DB_CONN_INI'

   SELECT @FTP_GLIM_ini_file = PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'FDS'
      AND PARAMETER_NAME = 'FTP_GLIM_INI_FILE'
 
     SELECT @FTP_CHECK_EXE = PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'UTIL'
      AND PARAMETER_NAME = 'FTP_CHECK_EXE'

    SELECT @FILE_CHECK = PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'UTIL'
      AND PARAMETER_NAME = 'DOES_FILE_EXIST_BAT'


   -- ADJUST FILE COUNT FOR FTP CHECK 
   SELECT @FTP_ADJUST = CAST(PARAMETER_VALUE AS INT)
     FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'FDS'
      AND PARAMETER_NAME = 'GLIM_FTP_ADJUST'

   -- SEARCH PHRASE
   SELECT @SEARCH_PHRASE = PARAMETER_VALUE
     FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'FDS'
      AND PARAMETER_NAME = 'GLIM_SEARCH_PHRASE'  

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
       PRINT 'GLIM FTP LOG NOT ARCHIVED.'
       -- RETURN (@rtn_code)  
     END
   PRINT 'GLIM FTP LOG ARCHIVED'


 -- DELETE THE FTP SUCCESS OR FAILURE FILE FROM THE FTP FOLDER
   PRINT 'NEXT COMMAND DELETES FTP SUCCESS/FAILURE FILE IN FTP FOLDER.'
   SET @CMD = 'ERASE /Q /F ' + @FTP_LOG_DIR + '*.FTP'
   PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD  
  
   /***************************************************************************************************************
 -- OLD WAY, USING MACRO SCHEDULER  
   PRINT 'EVALUATING LOG FILES FOR FTP SUCCESS'
   SET @CMD = @FTP_CHECK_EXE + ' /ini=' + @FTP_glim_ini_file + ' /FILENAME=' + @FTP_log_file+ ' ' + @DB_CONN
   PRINT @FTP_CHECK_EXE
   PRINT @FTP_glim_ini_file
   PRINT @FTP_log_file
   PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code <> 0 OR @@ERROR <> 0
      BEGIN
        PRINT 'FTP EVALUATION ERROR! CODE RETURNED = '  + cast(@rtn_code as varchar)
        RETURN (@rtn_code)
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
   SET @CMD = @FTP_CHECK_EXE + ' GLIM ' + @JAVA_LOG_DIR + @FTP_LOG_FILE + ' ' + @FTP_ADJUST + ' ' + @SEARCH_PHRASE +''
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
        PRINT 'GLIM FTP EVALUATION ERROR! CODE RETURNED = '  + cast(@rtn_code as varchar)
        RETURN (@rtn_code)
        -- RETURN(557)
      END
   PRINT 'GLIM FTP LOG FILE CONTENT EVALUATED'
-- END FTP TASK

  -- 0 is success, 5 types of failure
   
    
  -- FTP CHECK SCRIPT NEEDS AN INI FILE TO KNOW WHAT TO DO           
  SET @CMD = @FILE_CHECK + ' ' + @FTP_LOG_DIR  + '558.FTP'
  PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
    -- PRINT 'rtn_code=' + cast(coalesce(@rtn_code,99)  as varchar(10))
   IF @rtn_code = 0 AND @@ERROR = 0
     BEGIN
       PRINT 'GLIM REQUIRED FTP CHECK INI FILE NOT SPECIFIED.'
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
       PRINT 'GLIM REQUIRED FTP CHECK SEARCH FILE NOT SPECIFIED.'
       RETURN (559)  
     END
-- END IF   

  -- FTP CHECK SCRIPT NEEDS TO KNOW WHICH FTP COMMAND TO SEARCH FOR (SPECIFIED IN INI FILE)
  SET @CMD = @FILE_CHECK + ' ' + @FTP_LOG_DIR + '560.FTP'
  PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code = 0 AND @@ERROR = 0
     BEGIN
       PRINT 'GLIM REQUIRED FTP CHECK SEARCH STRING NOT SPECIFIED.'
       RETURN (560)  
     END
-- END IF 

  -- FTP CHECK SCRIPT NEEDS TO KNOW HOW MANY COMMANDS IT SHOULD FIND (SPECIFIED IN INI FILE)
  SET @CMD = @FILE_CHECK + ' ' + @FTP_LOG_DIR + '561.FTP'
  PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code = 0 AND @@ERROR = 0
     BEGIN
       PRINT 'GLIM REQUIRED FTP CHECK SEARCH COUNT NOT SPECIFIED.'
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
       PRINT 'GLIM FTP LOG SHOWS WRONG NUMBER OF FILES TRANSFERRED'
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
   
-- END CR 10176




   PRINT 'GLIM INTERFACE FILE SENT'
END

 
 
PRINT '' --CR9449 *~^
PRINT '*~^*************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF  XX_FDS_FTP_GLIM_FILE_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^
RETURN(0)

END





 

 

 

GO
 


USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_FDS_CREATE_FLAT_FILES_SP]    Script Date: 9/22/2022 2:20:32 PM ******/
DROP PROCEDURE [dbo].[XX_FDS_CREATE_FLAT_FILES_SP]
GO

/****** Object:  StoredProcedure [dbo].[XX_FDS_CREATE_FLAT_FILES_SP]    Script Date: 9/22/2022 2:20:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[XX_FDS_CREATE_FLAT_FILES_SP]
(
@in_STATUS_REC_NUM integer
)
AS
/****************************************************************************************************************
Name:          XX_FDS_CREATE_FLAT_FILES_SP
Author:        CR, KM
Created:       08/2005  
Purpose:       Call the Java programs to create the flat files. Move those flat files to the appropriate file
               folders. Call XX_FDS_FTP_CCS_FILE_SP, XX_FDS_FTP_FDS_FILE_SP and XX_FDS_FTP_GLIM_FILE_SP to archive
               all flat files.
               Called by XX_FDS_FDSCCS_RUN_INTERFACE_SP to process the case TRANSFER_FILES = NO.

Prerequisites: none 

Parameters: 
	Input: 	none
	Output: none   

Version: 	1.0

Notes:        -- REM FINGERPRINT TEST

CR-9449        HVT Add code to call new Java program to produce the GLIM-format flat file.
               12/14/2017 GEA Insert/Renumber multiple PRINT statements for logging purposes - marked by: *~^
               01/09/2018 HVT Add input parameter @in_STATUS_REC_NUM to allow SP calls.
*****************************************************************************************************************/  

BEGIN

DECLARE @CMD             varchar(600),
        @SERVER          sysname,
        @SP_NAME	 sysname,
		@QUOTE       varchar(1),
-- CR-9449 Begin
/*
        @DBNAME          sysname, -- Not used
        @USER            sysname, -- Not used
        @PWD             sysname, -- Not used
*/
-- CR-9449 END
        @FTP_DIR         sysname,
        @LOG_DIR         sysname,
        @ARCHIVE_DIR     sysname,
        @LOG_FILE        sysname,
        @JAVA_EXE        sysname,
		@JAVA_CMD		 varchar(500),
		@FDS_OUTPUT_PATH sysname,
		@CCS_OUTPUT_PATH sysname,
-- CR-9449 Begin
        @TRANSFER_FILES  sysname,
        @GLIM_EXE        sysname,
        @GLIM_CFF_FILES  sysname,
        @CCS_02_EXE      sysname,
		@CCS_02_CFF_FILES  sysname,
        @NUM_INVCS       integer,
		@CUR			 varchar(100),
		@CURFIL			 varchar(100),
		@ELAPSED		 varchar(2),
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @row_count               integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@out_STATUS_DESCRIPTION varchar(275),
-- CR-9449 End
        @JAVA_CLASS      sysname,
        @ret_code        integer,
        @return_cd		 varchar(25),
        @FILE_CHECK      sysname, 
		@GLIM_OUT_FILE_1 sysname,
        @GLIM_OUT_FILE_2 sysname,
        @DATA_FILE		 varchar(50),
		@INT_PATH		 VARCHAR(50),
        @CCS2_FILE		 varchar(50),
		@INTERFACE		 varchar(10)
        
        
PRINT '' --CR9449 *~^
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_FDS_CREATE_FLAT_FILES_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^
-- *~^
SET @INTERFACE = 'FDS'
SET @SP_NAME = 'XX_FDS_CREATE_FLAT_FILES_SP'
SET @QUOTE = CHAR(34)


-- Retrieve processing parameter values
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDS : Line 68 : XX_FDS_CREATE_FLAT_FILES_SP.sql '  --CR9449PRINT '' --   *~^
PRINT '*~^*************************************************************************'
PRINT '*~^          XX_FDS_CREATE_FLAT_FILES_SP - GET PARAMETERS'
PRINT '*~^*************************************************************************'
PRINT '' -- *~^   

PRINT 'NOW GETTING VARIOUS PARAMETERS. IMAPS_DATA_PATH IS FIRST'

SELECT 	@INT_PATH = PARAMETER_VALUE 
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'UTIL' 
AND	PARAMETER_NAME = 'IMAPS_DATA_PATH'

PRINT 'NOW GETTING VARIOUS PARAMETERS. INT_BAT IS NEXT'

SELECT 	@JAVA_CMD = REPLACE(PARAMETER_VALUE, '%INT_PATH%',@INT_PATH) 
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'UTIL'
AND	PARAMETER_NAME = 'INT_BAT'


SELECT @SERVER = REPLACE(PARAMETER_VALUE, '%INT_PATH%',@INT_PATH)
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'SERVER_PARAM'

    SELECT @FILE_CHECK = REPLACE(PARAMETER_VALUE, '%INT_PATH%',@INT_PATH)
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'UTIL'
      AND PARAMETER_NAME = 'DOES_FILE_EXIST_BAT'
   
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDS : Line 120 : XX_FDS_CREATE_FLAT_FILES_SP.sql '  --CR9449

-- CR-9449 BEGIN - Delete old FDS/GLIM output files from working folder
PRINT '' --   *~^
PRINT '*~^*************************************************************************'
PRINT '*~^          XX_FDS_CREATE_FLAT_FILES_SP - CLEANUP FILES'
PRINT '*~^*************************************************************************'
PRINT '' -- *~^   

SELECT @FDS_OUTPUT_PATH = REPLACE(PARAMETER_VALUE, '%INT_PATH%',@INT_PATH)
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'FDS_OUTPUT_PATH' 

SELECT @CCS_OUTPUT_PATH = REPLACE(PARAMETER_VALUE, '%INT_PATH%',@INT_PATH)
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'CCS_OUTPUT_PATH' 

SELECT @FTP_DIR = REPLACE(PARAMETER_VALUE, '%INT_PATH%',@INT_PATH)
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'FTP_DIR'

SELECT @LOG_DIR = REPLACE(PARAMETER_VALUE, '%INT_PATH%',@INT_PATH)
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'LOG_DIR'

SELECT @LOG_FILE = REPLACE(PARAMETER_VALUE, '%INT_PATH%',@INT_PATH)
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'FDS_LOG_FILE'

PRINT 'DELETE FDS OUTPUT FILES FROM WORKING DIR'
SET @CMD = 'DEL /F /Q ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'FDS\FDS\*.*'
PRINT @CMD
EXEC @ret_code = master.dbo.xp_cmdshell @CMD

IF @ret_code <> 0
   RETURN(1);

PRINT 'FDS FILES ARE DELETED'

PRINT 'DELETE CCS_02 OUTPUT FILES FROM WORKING DIR'
SET @CMD = 'DEL /F /Q ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'CCS_02\*.*'
PRINT @CMD
EXEC @ret_code = master.dbo.xp_cmdshell @CMD

IF @ret_code <> 0
   RETURN(1);

PRINT 'CCS_02 FILES ARE DELETED'

PRINT 'DELETE GLIM OUTPUT FILES FROM WORKING DIR'
SET @CMD = 'DEL /F /Q ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'GLIM\*.*'
PRINT @CMD
EXEC @ret_code = master.dbo.xp_cmdshell @CMD

IF @ret_code <> 0
   RETURN(1);

PRINT 'GLIM FILES ARE DELETED'

PRINT 'DELETE CCS_02 LOG FILES'
SET @CMD = 'DEL /F /Q ' + @LOG_DIR + 'CCS_02\*.*'
PRINT @CMD
EXEC @ret_code = master.dbo.xp_cmdshell @CMD

IF @ret_code <> 0
   RETURN(1);

PRINT 'CCS_02 LOGS ARE DELETED'

PRINT 'DELETE GLIM LOG FILES'
SET @CMD = 'DEL /F /Q ' + @LOG_DIR + 'GLIM\*.*'
PRINT @CMD
EXEC @ret_code = master.dbo.xp_cmdshell @CMD

IF @ret_code <> 0
   RETURN(1);

PRINT 'GLIM LOGS ARE DELETED'

PRINT 'DELETE SUBMISSION FILES FROM FTP DIR'
SET @CMD = 'DEL /F /Q ' + @FTP_DIR + '*.*'
PRINT @CMD
EXEC @ret_code = master.dbo.xp_cmdshell @CMD

IF @ret_code <> 0
   RETURN(1)

PRINT 'ALL SUBMISSION FILES ARE DELETED'

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDS : Line 138 : XX_FDS_CREATE_FLAT_FILES_SP.sql '  --CR9449
 
PRINT '' --   *~^
PRINT '*~^*************************************************************************'
PRINT '*~^          XX_FDS_CREATE_FLAT_FILES_SP - FDS'                             
PRINT '*~^*************************************************************************'
PRINT '' -- *~^   

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'CREATE FDS'
SET @error_msg_placeholder2 = 'AND CCS FILES'

--ALREADY HAVE @JAVA_CMD FROM ABOVE

SELECT @JAVA_EXE = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'JAVA_EXE'
   
SELECT @JAVA_CLASS = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'JAVA_CLASS'  


-- HERE'S WHAT WE WANT TO CREATE
--@JAVA_CMD  = T:\IMAPS_DATA\INTERFACES\PROGRAMS\BATCH\INTERFACE.BAT  
--@INT_PATH  = T:\IMAPS_DATA\ 
--@INTERFACE = FDS 
--BATCH 
--PROP 
--@JAVA_EXE  = "%JAVA_HOME%\JAVA.EXE -Dcom.ibm.jsse2.overrideDefaultTLS=true -jar" 
--@JAVA_CLASS = T:\IMAPS_DATA\interfaces\PROGRAMS\java\FDS\exe\CreateFlatFiles.jar 
--@SERVER_PARAM  = "T:\IMAPS_DATA\Props\FDS\jdbc_connection.properties" 
--no 
--"T:\IMAPS_DATA\INTERFACES\PROCESS\FDS\FDS\

PRINT 'EXECUTE CCS AND FDS JAVA PROGRAM'
SET @CMD = @JAVA_CMD + ' ' + @INT_PATH + ' ' + @INTERFACE + ' BATCH PROP ' + @JAVA_EXE + ' ' + @JAVA_CLASS + ' ' + @SERVER + ' ' + @FDS_OUTPUT_PATH + 'FDS\FDS\'
-- CR-9449 End
PRINT 'FDS COMMAND: ' + @CMD
EXEC @ret_code = master.dbo.xp_cmdshell @CMD

IF @ret_code <> 0
   RETURN(1);

PRINT 'NOW MOVING FDS LOG TO LOGS FOLDER'
SET @CMD = 'MOVE /Y ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'FDS\FDS\' + @LOG_FILE + ' ' +  @LOG_DIR + 'FDS\'
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing


PRINT 'JAVA FINISHED.  NOW CHECKING TO SEE IF EBC FILE IS CREATED'
PRINT 'NOW GETTING VARIOUS PARAMETERS.'

SELECT 	@CUR = REPLACE(REPLACE(PARAMETER_VALUE, '%INT_PATH%',@INT_PATH),'%INTERFACE%', @INTERFACE)
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'UTIL' 
AND	PARAMETER_NAME = 'ISIT_CURRENT'

SELECT 	@ELAPSED = PARAMETER_VALUE 
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'FDS' 
AND	PARAMETER_NAME = 'ELAPSED'

SELECT 	@CURFIL = PARAMETER_VALUE 
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'FDS' 
AND	PARAMETER_NAME = 'CCS_JAVA_DATA_FILE'


PRINT 'NOW BUILDING ISIT_CURRENT COMMAND'

SET @CMD = @CUR + ' ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'FDS\FDS\' + @CURFIL + ' ' + @ELAPSED
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

PRINT 'CCS BILLING FILE FOUND. NOW CHECKING FDS FILE'

SELECT 	@CURFIL = PARAMETER_VALUE 
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'FDS' 
AND	PARAMETER_NAME = 'FDS_JAVA_DATA_FILE'

SET @CMD = @CUR + ' ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'FDS\FDS\' + @CURFIL + ' ' + @ELAPSED
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

PRINT 'OBSOLETE FDS BILLING FILE FOUND. NOW CHECKING TRX FILE'

SELECT 	@CURFIL = PARAMETER_VALUE 
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'FDS' 
AND	PARAMETER_NAME = 'TRX_JAVA_DATA_FILE'

SET @CMD = @CUR + ' ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'FDS\FDS\' + @CURFIL + ' ' + @ELAPSED
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

PRINT 'TRX BILLING FILE FOUND. FDS WAS SUCCESSFUL'

PRINT 'NOW COPYING FILES TO PROCESS FOLDER'
SET @CMD = 'COPY /Y ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'FDS\FDS\*.* ' +  @FTP_DIR + '*.*'
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

PRINT 'FDS IS COMPLETE'

PRINT '' --   *~^
PRINT '*~^*************************************************************************'
PRINT '*~^          XX_FDS_CREATE_FLAT_FILES_SP - CCS_02'
PRINT '*~^*************************************************************************'
PRINT '' -- *~^   
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'CREATE '
SET @error_msg_placeholder2 = 'CCS_02 FILES'

SELECT @CCS_02_EXE = REPLACE(REPLACE(PARAMETER_VALUE, '%INT_PATH%',@INT_PATH),'%INTERFACE%', @INTERFACE)
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'CCS_02_EXE'

SELECT @CCS_02_CFF_FILES = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'CCS_02_CFF_FILES'

PRINT 'NOW BUILDING CFF COMMAND'

-- HERE'S WHAT WE WANT TO CREATE
--@JAVA_CMD  = T:\IMAPS_DATA\INTERFACES\PROGRAMS\BATCH\INTERFACE.BAT  
--@INT_PATH  = T:\IMAPS_DATA\ 
--@INTERFACE = FDS sbut interface, CCS_02
--CFF 
--@CCS_02_CFF_FILES = "CCS_0216_det,CCS_0216_div,CCS_0216_fil"

SET @CMD = @JAVA_CMD + ' ' + @INT_PATH + ' CCS_02' + ' CFF ' + @CCS_02_CFF_FILES 
PRINT 'CFF COMMAND IS : ' + @CMD
EXEC @ret_code = master.dbo.xp_cmdshell @CMD  

PRINT 'NOW COPYING CFF LOG TO LOGS FOLDER'
-- T:/IMAPS_DATA/Interfaces/Logs/CCS_02/CFF_CCS_02.LOG 
SET @CMD = 'COPY /Y ' + @LOG_DIR + 'CCS_02\CFF_CCS_02.LOG  ' 
SET @CMD = @CMD + @LOG_DIR + 'FDS\CFF_CCS_02.TXT' 
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing


SELECT @CURFIL = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'CCS_02_JAVA_DATA_FILE'
-- @FTP_DIR + @DATA_FILE IS THE FULL PATH LOCATION  

PRINT 'NOW BUILDING OUTPUT FILE'
SET @CMD = 'COPY /Y /B ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'CCS_02\CCS_0216_det.ebc + ' 
SET @CMD = @CMD +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'CCS_02\CCS_0216_div.ebc + ' 
SET @CMD = @CMD +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'CCS_02\CCS_0216_fil.ebc ' 
SET @CMD = @CMD +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'CCS_02\' + @CURFIL
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

-- DOES OUTPUT FILE EXIST?

PRINT 'NOW BUILDING ISIT_CURRENT COMMAND'
SET @CMD = @CUR + ' ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'CCS_02\' + @CURFIL + ' ' + @ELAPSED
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

PRINT 'CCS_02 BILLING FILE FOUND.'

PRINT 'NOW BUILDING OUTPUT TEXT FILE'
SET @CMD = 'COPY /Y ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'CCS_02\CCS_0216_det.txt + ' 
SET @CMD = @CMD +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'CCS_02\CCS_0216_div.txt + ' 
SET @CMD = @CMD +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'CCS_02\CCS_0216_det.txt ' 
SET @CMD = @CMD +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'CCS_02\' + REPLACE(@CURFIL,'.FIL','_FIL.TXT')
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

-- DOES OUTPUT TEXT FILE EXIST?
PRINT 'NOW CHECKING CCS_02 TEXT FILE'
SET @CMD = @CUR + ' ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'CCS_02\' + REPLACE(@CURFIL,'.FIL','_FIL.TXT') + ' ' + @ELAPSED
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

PRINT 'CCS_02 TEXT BILLING FILE FOUND.'

PRINT 'NOW COPYING FILES TO PROCESS FOLDER'
SET @CMD = 'COPY /Y ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'CCS_02\' + REPLACE(@CURFIL,'.FIL','*.* ')  +  @FTP_DIR + '*.*'
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

PRINT 'CCS_02 IS COMPLETE'
  
PRINT '' --   *~^
PRINT '*~^*************************************************************************'
PRINT '*~^          XX_FDS_CREATE_FLAT_FILES_SP - GLIM'
PRINT '*~^*************************************************************************'
PRINT '' -- *~^   

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'CREATE '
SET @error_msg_placeholder2 = 'GLIM FILES'

SELECT @GLIM_OUT_FILE_1 = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'GLIM_FTP_DEST_FILE_1'

SELECT @GLIM_OUT_FILE_2 = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'GLIM_FTP_DEST_FILE_2'

SELECT @GLIM_EXE = REPLACE(REPLACE(PARAMETER_VALUE, '%INT_PATH%',@INT_PATH),'%INTERFACE%', @INTERFACE)
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'GLIM_EXE'
-- CR-9449 End

SELECT @GLIM_CFF_FILES = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'GLIM_CFF_FILES'

PRINT 'NOW BUILDING CFF COMMAND'

-- HERE'S WHAT WE WANT TO CREATE
--@JAVA_CMD  = T:\IMAPS_DATA\INTERFACES\PROGRAMS\BATCH\INTERFACE.BAT  
--@INT_PATH  = T:\IMAPS_DATA\ 
--@INTERFACE = FDS sub interface, GLIM
--CFF 
--@GLIM_CFF_FILES

SET @CMD = @JAVA_CMD + ' ' + @INT_PATH + ' GLIM' + ' CFF ' + @GLIM_CFF_FILES
PRINT 'CFF COMMAND IS : ' + @CMD
EXEC @ret_code = master.dbo.xp_cmdshell @CMD  

PRINT 'NOW COPYING CFF LOG TO LOGS FOLDER'
SET @CMD = 'COPY /Y ' + @LOG_DIR + 'GLIM\CFF_GLIM.LOG  ' 
SET @CMD = @CMD + @LOG_DIR + 'FDS\CFF_GLIM.TXT' 

PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

PRINT 'NOW RENAMING CFF PARM OUTPUT'
SET @CMD = 'REN ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'GLIM\GLIMPARM.TXT ' + @GLIM_OUT_FILE_2
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

PRINT 'NOW RENAMING CFF OTHER OUTPUT'
SET @CMD = 'REN ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'GLIM\GLIM.EBC ' + @GLIM_OUT_FILE_1
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

-- glimparm script creates a code file that tells us if everything
--    went right, or exactly what went wrong, described below

-- END CR-9449
-- check for success 10247

-- first, check for OOB fle

SET @CMD = @FILE_CHECK + ' ' + @FTP_DIR + @GLIM_OUT_FILE_2 + 'OOB'
PRINT @CMD
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code = 0 AND @@ERROR = 0
  BEGIN
     PRINT @FTP_DIR  + @GLIM_OUT_FILE_2 + 'OOB - FILE FOUND! GLIM QUERY IS PROBABLY WRONG. SUPPLY OOB FILE TO DEVELOPER, THEN RE-RUN WITH VERBOSE GLIM LOGGING, AND SUPPLY THAT GLIM LOG TO DEVELOPER.'
     RETURN(557) -- FILE NOT FOUND
  END
ELSE
  PRINT   @FTP_DIR  + @GLIM_OUT_FILE_2 + 'OOB - FILE NOT FOUND! THIS IS A GOOD THING!'
-- END IF 


-- DOES OUTPUT FILE EXIST?
PRINT 'NOW BUILDING ISIT_CURRENT COMMAND'

PRINT 'CHECK GLIM EBCDIC FILE FIRST'

SELECT @CURFIL = @GLIM_OUT_FILE_1  

SET @CMD = @CUR + ' ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'GLIM\' + @CURFIL + ' ' + @ELAPSED
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

PRINT 'GLIM EBCDIC FILE FOUND.  CHECK PARM FILE NEXT'

SELECT @CURFIL = @GLIM_OUT_FILE_2

SET @CMD = @CUR + ' ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'GLIM\' + @CURFIL + ' ' + @ELAPSED
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

PRINT 'GLIM PARM FOUND. '

PRINT 'NOW COPYING FILES TO PROCESS FOLDER'
SET @CMD = 'COPY /Y ' +REPLACE(@FDS_OUTPUT_PATH,@QUOTE,'') + 'GLIM\IMAPFIW*.* ' +  @FTP_DIR + '*.*'
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

PRINT 'GLIM IS COMPLETE'



PRINT '' --   *~^
PRINT '*~^*************************************************************************'
PRINT '*~^          XX_FDS_CREATE_FLAT_FILES_SP - ARCHIVE'
PRINT '*~^*************************************************************************'
PRINT '' -- *~^      
-- CR-9449 Begin
-- Archive all interface output files

SELECT @TRANSFER_FILES = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'TRANSFER_FILES'

IF @TRANSFER_FILES <> 'YES' OR @TRANSFER_FILES IS NULL
   BEGIN
      PRINT 'TRANSFER_FILES = NO -- DETERMINE IF STAGING INVOICE DATA EXISTS TO ARCHIVE INTERFACE OUTPUT FILES.'
      SELECT @NUM_INVCS = COUNT(1) FROM dbo.XX_IMAPS_INV_OUT_SUM WHERE STATUS_FL = 'U' -- Unprocessed

      IF @NUM_INVCS = 0
         BEGIN      
            PRINT 'NO STAGING INVOICE DATA EXIST. NO ARCHIVING OF INTERFACE OUTPUT FILES.'
            SET @ret_code = 0
         END
      ELSE
         BEGIN
            PRINT 'CALL XX_FDS_FTP_CCS_FILE_SP TO ARCHIVE OUTPUT CCS FILE.'
            
            EXEC @ret_code = dbo.XX_FDS_FTP_CCS_FILE_SP
               @in_STATUS_RECORD_NUM = @in_STATUS_REC_NUM,
               @in_exec_mode = 'A'
            
            IF @ret_code <> 0
              BEGIN
                 PRINT 'XX_FDS_FTP_CCS_FILE_SP FAILED WITH CODE ' + CAST(@ret_code as VARCHAR(5))
                 RETURN (@ret_code)
              END
--CR10363               
/**************************************************************************/
            PRINT 'CALL XX_FDS_FTP_FDS_FILE_SP TO ARCHIVE OUTPUT FDS FILE.'
            
            EXEC @ret_code = dbo.XX_FDS_FTP_FDS_FILE_SP
               @in_STATUS_RECORD_NUM = @in_STATUS_REC_NUM,
               @in_exec_mode = 'A'
            
            IF @ret_code <> 0
                BEGIN
                 PRINT 'XX_FDS_FTP_FTP_FILE_SP FAILED WITH CODE ' + CAST(@ret_code as VARCHAR(5))
                 RETURN (@ret_code)
              END
/***************************************************************************/
            PRINT 'CALL XX_FDS_FTP_CCS_02_FILE_SP TO ARCHIVE OUTPUT FDS FILE.'
            
            EXEC @ret_code = dbo.XX_FDS_FTP_CCS_02_FILE_SP
               @in_STATUS_RECORD_NUM = @in_STATUS_REC_NUM,
               @in_exec_mode = 'A'
            
            IF @ret_code <> 0
               BEGIN
                 PRINT 'XX_FDS_FTP_CCS_02_FILE_SP FAILED WITH CODE ' + CAST(@ret_code as VARCHAR(5))
                 RETURN (@ret_code)
              END
--CR10363 END

            PRINT 'CALL XX_FDS_FTP_GLIM_FILE_SP TO ARCHIVE OUTPUT GLIM FILES.'
            
            EXEC @ret_code = dbo.XX_FDS_FTP_GLIM_FILE_SP
               @in_STATUS_RECORD_NUM = @in_STATUS_REC_NUM,
               @in_exec_mode = 'A'
            
            IF @ret_code <> 0
               BEGIN
                 PRINT 'XX_FDS_FTP_GLIM_FILE_SP FAILED WITH CODE ' + CAST(@ret_code as VARCHAR(5))
                 RETURN (@ret_code)
              END

         END  --@NUM_INVCS
END  --@TRANSFER_FILES
-- CR-9449 End

PRINT '' --CR9449 *~^
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                                     END OF XX_FDS_CREATE_FLAT_FILES_SP                                       *'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^

RETURN(0)


ErrorProcessing:
-- SELECT @ret_code
EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_number,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN 1

END



 

 

 

 

 

 

 

GO



USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_SABRIX_CREATE_FILES_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 



CREATE PROCEDURE [dbo].[XX_SABRIX_CREATE_FILES_SP]
(
@in_STATUS_REC_NUM integer
)
AS
/****************************************************************************************************************
Name:          XX_SABRIX_CREATE_FILES_SP
Author:        GEA
Created:       08/2018  
Purpose:       Call the Java programs to create the flat files. Move those flat files to the appropriate file
               folders. Call XX_AR_FTP_CCS_FILE_SP, XX_AR_FTP_FDS_FILE_SP and XX_AR_FTP_GLIM_FILE_SP to archive
               all flat files.
               Called by XX_AR_FDSCCS_RUN_INTERFACE_SP to process the case TRANSFER_FILES = NO.

Prerequisites: none 

Parameters: 
	Input: 	none
	Output: none   

Version: 	1.0

Notes:

*****************************************************************************************************************/  

BEGIN

DECLARE @CMD             varchar(600),
        @SERVER          sysname,
        @SP_NAME	 sysname,
        @PROCESS_DIR         sysname,
        @ARCHIVE_DIR     sysname,
        @ERROR_DIR       sysname,
        @JAVA_EXE        sysname,
        @TRANSFER_FILES  sysname,
        @GLIM_EXE        sysname,
        @SABRIX_EXE      sysname,
        @CCS_02_EXE      sysname,
        @NUM_INVCS       integer,
		@CUR			varchar(100),
		@CURFIL		varchar(100),
		@ELAPSED		varchar(2),
        @JAVA_CLASS      sysname,
        @ret_code        integer,
        @return_cd		 varchar(25),
        @FILE_CHECK      sysname, 
        @GLIM_OUT_FILE_2 sysname,
		@CFF_FILES       VARCHAR(100),
        @DATA_FILE		 varchar(50),
        @CCS2_FILE		 varchar(50)
        
        
PRINT ' *~^'
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_SABRIX_CREATE_FILES_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '  *~^'
-- *~^
SET @SP_NAME = 'XX_SABRIX_CREATE_FILES_SP'

-- Retrieve processing parameter values
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDS/CCS : Line 68 : XX_SABRIX_CREATE_FILES_SP.sql '  PRINT ' --   *~^'
PRINT '*~^*************************************************************************'
PRINT '*~^                                                                        *'
PRINT '*~^          XX_SABRIX_CREATE_FILES_SP - GET PARAMETERS'
PRINT '*~^                                                                        *'
PRINT '*~^*************************************************************************'
PRINT ' -- *~^'    

SELECT @SABRIX_EXE = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'SABRIX'
   AND PARAMETER_NAME = 'SABRIX_EXE'

SELECT @DATA_FILE = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'SABRIX'
   AND PARAMETER_NAME = 'SABRIX_JAVA_DATA_FILE'
-- @PROCESS_DIR + @DATA_FILE IS THE FULL PATH LOCATION   
-- CR 10364 END

    SELECT @FILE_CHECK = PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'UTIL'
      AND PARAMETER_NAME = 'DOES_FILE_EXIST_BAT'

    SELECT @CFF_FILES = PARAMETER_VALUE
     FROM XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'SABRIX'
      AND PARAMETER_NAME = 'CFF_FILES'


      
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDS/CCS : Line 105 : XX_SABRIX_CREATE_FILES_SP.sql '  
 
SELECT @PROCESS_DIR = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'SABRIX'
   AND PARAMETER_NAME = 'FTP_DIR'

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDS/CCS : Line 112 : XX_SABRIX_CREATE_FILES_SP.sql '  
 

PRINT ' --   *~^'
PRINT '*~^*************************************************************************'
PRINT '*~^                                                                        *'
PRINT '*~^          XX_SABRIX_CREATE_FILES_SP - CLEANUP FILES'
PRINT '*~^                                                                        *'
PRINT '*~^*************************************************************************'
PRINT ' -- *~^ '  


PRINT 'DELETE CCS OUTPUT FILES FROM WORKING DIR'
SET @CMD = 'ERASE ' + 'SABRIX* '
PRINT 'COMMAND IS: ' + @CMD
EXEC @ret_code = master.dbo.xp_cmdshell @CMD

IF @ret_code <> 0
   RETURN(1);

PRINT 'SABRIX FILES ARE DELETED'

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDS/CCS : Line 138 : XX_SABRIX_CREATE_FILES_SP.sql '  
 
-- CR10364 Begin
-- EXECUTE SABRIX JAVA PROGRAM
 
PRINT ' --   *~^'
PRINT '*~^*************************************************************************'
PRINT '*~^                                                                        *'
PRINT '*~^          XX_SABRIX_CREATE_FILES_SP - SABRIX'
PRINT '*~^                                                                        *'
PRINT '*~^*************************************************************************'
PRINT ' -- *~^  ' 
   
SET @CMD = @SABRIX_EXE +' ' + @CFF_FILES  + ''
PRINT 'EXECUTE SABRIX JAVA PROGRAM ' + @CMD
EXEC @ret_code = master.dbo.xp_cmdshell @CMD


-- CLEAN UP THE FOLDER AND MAKE REQUIRED COPIES
/*****
del /f /q %PROCESS%\sabrix_trx.ebc
copy /b %PROCESS%\sabrix_hdr.ebc + %PROCESS%\sabrix_dtl.ebc %PROCESS%\sabrix_out.fil >>%CFF_LOG_DIR%\%LOG_FILE%
copy %PROCESS%\sabrix_hdr.txt + %PROCESS%\sabrix_dtl.txt %PROCESS%\sabrix_out_fil.txt >>%CFF_LOG_DIR%\%LOG_FILE%
****/
   PRINT 'NEXT COMMAND REVEALS STATE OF PROCESS FOLDER.'
   SET @CMD = 'DIR ' + @PROCESS_DIR + '*.*'
   PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD   

   PRINT 'NEXT COMMAND DELETES SABRIX.TRX EBC FILE IN PROCESS FOLDER.'
   SET @CMD = 'DEL /F /Q  ' + @PROCESS_DIR + 'sabrix16_trx.ebc'
   PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD   

   PRINT 'NEXT COMMAND COPIES EBC FILES INTO A SINGLE SUBMISSION FILE.'
   SET @CMD = 'COPY /B ' + @PROCESS_DIR + 'sabrix16_hdr.ebc' + ' + ' +  @PROCESS_DIR + 'sabrix16_lin.ebc' + ' ' +  @PROCESS_DIR + 'sabrix_out.fil'
   PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD  

   PRINT 'NEXT COMMAND COPIES TXT FILES INTO A TEXT VERSION OF THE SINGLE SUBMISSION FILE.'
   SET @CMD = 'COPY ' + @PROCESS_DIR + 'sabrix16_hdr.txt' + ' + ' +  @PROCESS_DIR + 'sabrix16_lin.txt' + ' ' +  @PROCESS_DIR + 'sabrix_out_fil.txt'
   PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD  

   PRINT 'NEXT COMMAND RENAMES TRX FILE'
   SET @CMD = 'COPY ' + @PROCESS_DIR + 'sabrix16_trx.txt ' + @PROCESS_DIR + 'sabrix_trx.txt'
   PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD 


PRINT 'FILE CREATION FINISHED.  NOW CHECKING TO SEE IF SUBMISSION FILE IS CREATED'
PRINT 'NOW GETTING VARIOUS PARAMETERS.'

SELECT 	@CUR = PARAMETER_VALUE 
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'UTIL' 
AND	PARAMETER_NAME = 'ISIT_CURRENT'

SELECT 	@CURFIL = PARAMETER_VALUE 
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'SABRIX' 
AND	PARAMETER_NAME = 'CURRENT_FILE'

SELECT 	@ELAPSED = PARAMETER_VALUE 
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'SABRIX' 
AND	PARAMETER_NAME = 'ELAPSED'

SET @CMD = @CUR + ' ' + @CURFIL + ' ' + @ELAPSED
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0
  BEGIN
    PRINT 'TO GET THIS ERROR, EITHER JAVA PROGRAM CFF MUST HAVE FAILED OR PERMISSIONS ARE WRONG.'
	GOTO SIMPLE_ERROR_HANDLER
  END

-- DELETE THE SABRIX SUCCESS OR FAILURE FILE FROM THE FTP FOLDER
   PRINT 'NEXT COMMAND DELETES SABRIX SUCCESS/FAILURE FILE IN FTP FOLDER.'
   SET @CMD = 'ERASE /Q /F ' + @PROCESS_DIR + '*.SBR'
   PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD  


-- DOES SUBMISSION FILE EXIST?
  SET @CMD = @FILE_CHECK + ' ' + @PROCESS_DIR + @DATA_FILE
  PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD
   IF @ret_code = 0 AND @@ERROR = 0
     PRINT @PROCESS_DIR  + @DATA_FILE + ' FOUND! SABRIX PROPERLY EXECUTED.'
   ELSE
     BEGIN
        PRINT @PROCESS_DIR  + @DATA_FILE + ' NOT FOUND! SABRIX DID NOT PROPERLY EXECUTE.'
        RETURN (556)  
     END    
-- END IF 
-- CR10364 end

-- DOES TEXT VERSION OF SUBMISSION FILE EXIST?
  SET @CMD = @FILE_CHECK + ' ' + @PROCESS_DIR + 'sabrix_out_fil.txt'
  PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD
   IF @ret_code = 0 AND @@ERROR = 0
     PRINT @PROCESS_DIR  + 'sabrix_out_fil.txt' + ' FOUND! SABRIX PROPERLY EXECUTED.'
   ELSE
     BEGIN
        PRINT @PROCESS_DIR  + 'sabrix_out_fil.txt' + ' NOT FOUND! SABRIX DID NOT PROPERLY EXECUTE.'
        RETURN (556)  
     END    
-- END IF 
-- CR10364 end

-- DOES TRX FILE EXIST?
  SET @CMD = @FILE_CHECK + ' ' + @PROCESS_DIR + 'sabrix_trx.txt'
  PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD
   IF @ret_code = 0 AND @@ERROR = 0
     PRINT @PROCESS_DIR  +  'sabrix_trx.txt' + ' FOUND! SABRIX PROPERLY EXECUTED.'
   ELSE
     BEGIN
        PRINT @PROCESS_DIR  + 'sabrix_trx.txt' + ' NOT FOUND! SABRIX DID NOT PROPERLY EXECUTE.'
        RETURN (556)  
     END    
-- END IF 
-- CR10364 end

   PRINT 'NEXT COMMAND REVEALS STATE OF PROCESS FOLDER AT END OF CREATE FILES'
   SET @CMD = 'DIR ' + @PROCESS_DIR + '*.*'
   PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD   


PRINT ' --   *~^'
PRINT '*~^*************************************************************************'
PRINT '*~^                                                                        *'
PRINT '*~^          XX_SABRIX_CREATE_FILES_SP - ARCHIVE'
PRINT '*~^                                                                        *'
PRINT '*~^*************************************************************************'
PRINT '' -- *~^      
-- CR-9449 Begin
-- Archive all interface output files

PRINT 'CALL XX_SABRIX_FTP_FILE_SP TO ARCHIVE OUTPUT GLIM FILES.'
            
EXEC @ret_code = dbo.XX_SABRIX_FTP_FILE_SP
     @in_STATUS_RECORD_NUM = @in_STATUS_REC_NUM,
     @in_exec_mode = 'A'
            
IF @ret_code <> 0
      RETURN(1);

PRINT '  *~^'
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                                     END OF XX_SABRIX_CREATE_FILES_SP                                       *'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '  *~^'

RETURN(0)

END

SIMPLE_ERROR_HANDLER:

RETURN(@ret_code)

 

GO
 


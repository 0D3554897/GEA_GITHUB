USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CLS_DOWN_CREATE_FLAT_FILE_SP]    Script Date: 5/6/2020 5:02:58 PM ******/
DROP PROCEDURE [dbo].[XX_R22_CLS_DOWN_CREATE_FLAT_FILE_SP]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CLS_DOWN_CREATE_FLAT_FILE_SP]    Script Date: 5/6/2020 5:02:58 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 


CREATE PROCEDURE [dbo].[XX_R22_CLS_DOWN_CREATE_FLAT_FILE_SP] ( 
@in_STATUS_RECORD_NUM    integer, 
@out_SystemError int = NULL OUTPUT, 
@out_STATUS_DESCRIPTION varchar(275) = NULL OUTPUT) 
AS
/************************************************************************************************  
Name:       	XX_R22_CLS_DOWN_CREATE_FLAT_FILE_SP
Author:     	KM
Created:    	11/2005  
Purpose:    	Calls the Java Program that creates the Flat files
		Moves those flat files to the appropriate folders

Prerequisites: 	none 
 

Version: 	1.0
Notes:      	
		exec XX_R22_CLS_DOWN_CREATE_FLAT_FILE_SP
			@in_STATUS_RECORD_NUM = 86

 01/06/2017 - Added more detailed logging     
 01/16/2017 - Added new parameter, CMD_PARAM, to parameters table.  Contains the folder into which CMDSHELL errors are saved for OS execution commands.

************************************************************************************************/  
BEGIN

DECLARE	@SP_NAME                 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @row_count               integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@PROCESS_DIR			 varchar(500),
		@JAVA_CMD				 varchar(500),
		@CUR					 varchar(100),
		@CURFIL					 varchar(100),
		@ELAPSED				 varchar(2),
		@CFF_FILES				 varchar(100),
		@CMD 					 varchar(500),
		@999FILE				 varchar(100),
		@PARMFILE				 varchar(100),
		@SUMFILE				 varchar(100),
		@TEXTFILE				 varchar(100),
		@ret_code				 int
declare @SERVER sysname
declare @DBNAME sysname
declare @USER sysname
declare @PWD sysname

--SET LOCAL CONSTANTS
SET @SP_NAME = 'XX_R22_CLS_DOWN_CREATE_FLAT_FILE_SP'

PRINT '***********************************************************************************************************************'
PRINT '     START OF ' + @SP_NAME
PRINT '***********************************************************************************************************************'

PRINT 'DETERMINING WHICH DRIVES WE ARE WORKING WITH'

DECLARE @DATA_DRIVE nvarchar(255), @PROG_DRIVE nvarchar(255)

DECLARE @MyTbl TABLE(EnvVar NVARCHAR(255))

INSERT INTO @MyTbl exec xp_cmdshell 'echo %DATA_DRIVE%'
SET @DATA_DRIVE = (SELECT TOP 1 EnvVar from @MyTbl)
DELETE FROM @MyTbl

INSERT INTO @MyTbl exec xp_cmdshell 'echo %PROG_DRIVE%'
SET @PROG_DRIVE = (SELECT TOP 1 EnvVar from @MyTbl)

PRINT 'Two drives are:  ' + @PROG_DRIVE + ' AND ' + @DATA_DRIVE

--1.	CREATE OUTPUT FILES
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'CREATE R22_CLS'
SET @error_msg_placeholder2 = '999 FILE'

PRINT 'NOW GETTING VARIOUS PARAMETERS. JAVA_CMD IS FIRST'

SELECT 	@JAVA_CMD = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE) 
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'CLS_R22'
AND	PARAMETER_NAME = 'JAVA_CMD'

PRINT 'NOW GETTING VARIOUS PARAMETERS. CFF_FILES IS NEXT'

SELECT 	@CFF_FILES = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE)  
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'CLS_R22' 
AND	PARAMETER_NAME = 'CFF_FILES'

PRINT 'NOW GETTING VARIOUS PARAMETERS. PROCESS_DIR IS NEXT'

SELECT  @PROCESS_DIR = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE)  
FROM  dbo.XX_PROCESSING_PARAMETERS
WHERE   INTERFACE_NAME_CD = 'CLS_R22' 
AND PARAMETER_NAME = 'PROCESS_DIR'

PRINT 'NOW GETTING VARIOUS PARAMETERS. 999_FILE IS NEXT'

SELECT  @999FILE = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE)  
FROM  dbo.XX_PROCESSING_PARAMETERS
WHERE   INTERFACE_NAME_CD = 'CLS_R22' 
AND PARAMETER_NAME = 'FTP_DEST_999FILE'

PRINT 'NOW GETTING VARIOUS PARAMETERS. PARM_FILE IS NEXT'

SELECT  @PARMFILE = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE)  
FROM  dbo.XX_PROCESSING_PARAMETERS
WHERE   INTERFACE_NAME_CD = 'CLS_R22' 
AND PARAMETER_NAME = 'FTP_DEST_PARMFILE'

PRINT 'NOW GETTING VARIOUS PARAMETERS. SUM_FILE IS NEXT'

SELECT  @SUMFILE = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE)  
FROM  dbo.XX_PROCESSING_PARAMETERS
WHERE   INTERFACE_NAME_CD = 'CLS_R22' 
AND PARAMETER_NAME = 'FTP_DEST_SUMFILE'

PRINT 'NOW GETTING VARIOUS PARAMETERS. SUM_FILE IS NEXT'

SELECT  @TEXTFILE = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE)  
FROM  dbo.XX_PROCESSING_PARAMETERS
WHERE   INTERFACE_NAME_CD = 'CLS_R22' 
AND PARAMETER_NAME = 'TEXTFILE'

PRINT '7 PARAMETER LISTING: '
PRINT '1. JAVA_CMD: ' + @JAVA_CMD
PRINT '2. CFF_FILES: ' + @CFF_FILES
PRINT '3. PROCESS_DIR: ' + @PROCESS_DIR
PRINT '4. 999FILE: ' + @999FILE
PRINT '5. PARMFILE: ' + @PARMFILE
PRINT '6. SUMFILE: ' + @SUMFILE
PRINT '7. TEXTFILE: ' + @TEXTFILE

PRINT 'NOW CLEANING UP PROCESS FOLDER'

SET @CMD = 'DEL /F /Q ' + @PROCESS_DIR + '*.*'
PRINT 'COMMAND IS: ' + @CMD
EXEC @ret_code = master.dbo.xp_cmdshell @CMD  

PRINT 'NOW BUILDING CFF COMMAND'

SELECT @out_SystemError = @@ERROR
IF @out_SystemError <> 0 GOTO ErrorProcessing

SET @CMD = @JAVA_CMD +' ' + @CFF_FILES  + ''


PRINT 'EXECUTE CLS JAVA PROGRAM ' + @CMD
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

PRINT 'JAVA FINISHED.  NOW CHECKING TO SEE IF EBC FILE IS CREATED'
PRINT 'NOW GETTING VARIOUS PARAMETERS.'

SELECT 	@CUR = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE)  
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'UTIL' 
AND	PARAMETER_NAME = 'ISIT_CURRENT'

SELECT 	@CURFIL = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE)  
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'CLS_R22' 
AND	PARAMETER_NAME = 'CURRENT_FILE'

SELECT 	@ELAPSED = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE)  
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'CLS_R22' 
AND	PARAMETER_NAME = 'ELAPSED'

PRINT '3 PARAMETERS LISTED: '
PRINT '1. CUR: ' + @CUR
PRINT '2. CURFIL: ' + @CURFIL
PRINT '3. ELAPSED: ' + @ELAPSED

PRINT 'ASSEMBLING COMMAND'
SET @CMD = @CUR + ' ' +@CURFIL + ' ' + @ELAPSED
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

PRINT 'EBCIDIC FILE FOUND. NOW CHECKING PARMFILE'

PRINT 'ASSEMBLING 2ND COMMAND'
SELECT 	@CURFIL = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE)  
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'CLS_R22' 
AND	PARAMETER_NAME = 'PARMFILE'

SET @CMD = @CUR + ' ' +@CURFIL + ' ' + @ELAPSED
PRINT 'Command is :' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0 GOTO ErrorProcessing

PRINT 'PARM FILE FOUND.'
PRINT 'JAVA COMMAND SUCCESSFULLY EXECUTED '

PRINT 'NOW CLEANING UP AND RENAMING FILES'

  PRINT 'NEXT COMMAND REVEALS STATE OF PROCESS FOLDER.'
   SET @CMD = 'DIR ' + @PROCESS_DIR + '*.*'
   PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD   

   PRINT 'NEXT COMMAND DELETES UNWANTED FILES IN PROCESS FOLDER.'
   SET @CMD = 'DEL /F /Q  ' + @PROCESS_DIR + 'r22_clsdownparm.ebc'
   PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD   

   PRINT 'NEXT COMMAND DELETES UNWANTED FILE IN PROCESS FOLDER.'
   SET @CMD = 'DEL /F /Q  ' + @PROCESS_DIR + 'r22_clsdownsummary.ebc'
   PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD   

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'RENAME R22_CLS'
SET @error_msg_placeholder2 = 'TARGET FILES'

   PRINT 'NEXT COMMAND RENAMES EBC FILE'
   SET @CMD = 'COPY ' + @PROCESS_DIR + 'r22_clsdown.ebc ' +  @PROCESS_DIR + @999FILE
   PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD  
   IF @ret_code <> 0 GOTO ErrorProcessing

   PRINT 'NEXT COMMAND RENAMES PARM FILE'
   SET @CMD = 'COPY ' + @PROCESS_DIR + 'r22_clsdownparm.txt ' +   @PROCESS_DIR + @PARMFILE
   PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD  
   IF @ret_code <> 0 GOTO ErrorProcessing

   PRINT 'NEXT COMMAND RENAMES SUM FILE'
   SET @CMD = 'COPY ' + @PROCESS_DIR + 'r22_clsdownsummary.txt ' +  @PROCESS_DIR + @SUMFILE
   PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD 
   IF @ret_code <> 0 GOTO ErrorProcessing

   PRINT 'NEXT COMMAND RENAMES ASCII SUBMISSION FILE'
   SET @CMD = 'COPY ' + @PROCESS_DIR + 'r22_clsdown.txt ' +  @TEXTFILE
   PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD 
   IF @ret_code <> 0 GOTO ErrorProcessing


  PRINT 'NEXT COMMAND REVEALS ENDING STATE OF PROCESS FOLDER.'
   SET @CMD = 'DIR ' + @PROCESS_DIR + '*.*'
   PRINT 'COMMAND IS: ' + @CMD
   EXEC @ret_code = master.dbo.xp_cmdshell @CMD  


PRINT '***********************************************************************************************************************'
PRINT '     END OF ' + @SP_NAME
PRINT '***********************************************************************************************************************'


RETURN 0

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



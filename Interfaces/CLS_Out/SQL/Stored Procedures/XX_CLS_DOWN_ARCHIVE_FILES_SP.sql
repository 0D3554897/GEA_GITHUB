USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_CLS_DOWN_ARCHIVE_FILES_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 

 




CREATE PROCEDURE [dbo].[XX_CLS_DOWN_ARCHIVE_FILES_SP] ( 
@in_STATUS_RECORD_NUM    integer, 
@out_SystemError int = NULL OUTPUT, 
@out_STATUS_DESCRIPTION varchar(275) = NULL OUTPUT) 
AS
/************************************************************************************************  
Name:       	XX_ARCHIVE_FILES_SP
Author:     	KM
Created:    	11/2005  
Purpose:    	ARCHIVES the files

Prerequisites: 	none 
 

Version: 	1.0
Notes:      	
		exec xx_cls_down_archive_files_sp
			@in_STATUS_RECORD_NUM = 86

select * from xx_processing_parameters
************************************************************************************************/  
BEGIN

DECLARE	@SP_NAME                 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @row_count               integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
	@JAVA_CMD		 varchar(500),
	@SERVER_PARAM		 sysname,
	@CMD 			 varchar(500)
declare @SERVER sysname
declare @DBNAME sysname
declare @USER sysname
declare @PWD sysname

--SET LOCAL CONSTANTS
SET @SP_NAME = 'XX_CLS_DOWN_ARCHIVE_FILES_SP'


PRINT '***********************************************************************************************************************'
PRINT '        START OF ' + @SP_NAME
PRINT '***********************************************************************************************************************'




--2.	MOVE OUTPUT FILES
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'ARCHIVE CLS'
SET @error_msg_placeholder2 = 'OUTPUT FILES'

DECLARE @ERROR_DIR sysname,
	@PROCESS_DIR sysname,
	@ARCH_DIR sysname,
	@FILE_ID sysname

SELECT 	@ERROR_DIR = PARAMETER_VALUE 
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'CLS' 
AND	PARAMETER_NAME = 'ERROR_DIR'

SELECT 	@PROCESS_DIR = PARAMETER_VALUE 
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'CLS' 
AND	PARAMETER_NAME = 'PROCESS_DIR'

SELECT 	@ARCH_DIR = PARAMETER_VALUE 
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'CLS' 
AND	PARAMETER_NAME = 'ARCH_DIR'


SET @CMD = 'MOVE ' + @PROCESS_DIR + 'IMAPS_TO_CLS_ASCII* ' + @ARCH_DIR + Cast(@in_STATUS_RECORD_NUM as sysname) + '_IMAPS_TO_CLS_ASCII.TXT'
EXEC MASTER.DBO.XP_CMDSHELL @CMD
SET @CMD = 'MOVE ' + @PROCESS_DIR + 'IMAPS_TO_CLS_DOWN* ' + @ARCH_DIR + Cast(@in_STATUS_RECORD_NUM as sysname) + '_IMAPS_TO_CLS_DOWN_SUMMARY.TXT'
EXEC MASTER.DBO.XP_CMDSHELL @CMD
SET @CMD = 'COPY ' + @PROCESS_DIR + 'IMAPS_TO_CLS.BIN ' + @ARCH_DIR + Cast(@in_STATUS_RECORD_NUM as sysname) + '_IMAPS_TO_CLS.BIN'
EXEC MASTER.DBO.XP_CMDSHELL @CMD
SET @CMD = 'COPY ' + @PROCESS_DIR + 'F155PARM* ' + @ARCH_DIR + Cast(@in_STATUS_RECORD_NUM as sysname) + '_F155PARM.TXT'
EXEC MASTER.DBO.XP_CMDSHELL @CMD

SELECT @out_SystemError = @@ERROR
IF @out_SystemError <> 0 GOTO ErrorProcessing

PRINT '***********************************************************************************************************************'
PRINT '        END OF ' + @SP_NAME
PRINT '***********************************************************************************************************************'




RETURN 0

ErrorProcessing:
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
 


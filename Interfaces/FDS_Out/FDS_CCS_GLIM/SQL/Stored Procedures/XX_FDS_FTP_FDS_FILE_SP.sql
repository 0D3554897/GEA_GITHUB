USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_FDS_FTP_FDS_FILE_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 


 

 





CREATE PROCEDURE [dbo].[XX_FDS_FTP_FDS_FILE_SP]
(
@in_STATUS_RECORD_NUM integer,
@in_exec_mode         char(1) -- A = Archive files, F = FTP files
)
AS
/************************************************************************************************  
Name:       	XX_FDS_FTP_FDS_FILE_SP  
Author:     	CR, KM
Created:    	08/2005  
Purpose:    	FTP AR FILE TO FDS
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
-- CR-9449 Begin
/*
        @FDS_FTP_SERVER        sysname, -- Not used
        @FDS_FTP_USER          sysname, -- Not used
        @FDS_FTP_PASS          sysname, -- Not used
        @FDS_FTP_DEST_FILE     sysname, -- Not used
*/

-- CR-9449 End
        @FTP_DIR               varchar(100),
        @myTYPE                sql_variant,
        @FTP_COMMAND_FILE      sysname,
	    @FTP_CHECK_EXE         sysname,
        @FTP_LOG_FILE          sysname,
        @FTP_LOG_DIR           varchar(200),
        @FILE_CHECK            varchar(200),	    
	    @FTP_fds_ini_file      sysname,
	    @DB_CONN               sysname,
        @ARCHIVE_DIR           varchar(100),
        @ERROR_DIR             sysname,
        @TRANSFER_FILES        sysname,	
        @unique_name_part	   sysname,        
        @rtn_code              int,
        @SP_NAME               sysname

PRINT '' --CR9449 *~^
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_FDS_FTP_FDS_FILE_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^
-- *~^
SET @SP_NAME = 'XX_FDS_FTP_FDS_FILE_SP'


-- Load Parameters From Table

 SELECT @FILE_CHECK = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'UTIL'
   AND PARAMETER_NAME = 'DOES_FILE_EXIST_BAT'
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 79 : XX_FDS_FTP_FDS_FILE_SP.sql '  --CR9449
 
SELECT @TRANSFER_FILES = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'TRANSFER_FILES'

 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 138 : XX_FDS_FTP_FDS_FILE_SP.sql '  --CR9449
 
SELECT @FTP_DIR = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'FTP_DIR'


 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 148 : XX_FDS_FTP_FDS_FILE_SP.sql '  --CR9449
 
SELECT @ARCHIVE_DIR = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'ARCHIVE_DIR'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 158 : XX_FDS_FTP_FDS_FILE_SP.sql '  --CR9449
 
SELECT @ERROR_DIR = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
   AND PARAMETER_NAME = 'ERROR_DIR'

-- DO NOT TRANSFER THE FILES UNTIL THEY HAVE BEEN REVIEWED
IF (@TRANSFER_FILES = 'NO' OR @TRANSFER_FILES IS NULL) AND @in_exec_mode = 'A'
BEGIN
   -- Archive Files

   SET @CMD = 'MOVE ' + @FTP_DIR + 'IMAPS_TO_FDS* ' + @ARCHIVE_DIR + CAST(@in_STATUS_RECORD_NUM as varchar(10)) + '_IMAPS_TO_FDS.BIN' 
   PRINT @CMD
   
   -- EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   EXEC master.dbo.xp_cmdshell @CMD
   IF @rtn_code <> 0 OR @@ERROR <> 0
      RETURN (557)
	
   SET @CMD = 'MOVE ' + @FTP_DIR + 'Transaction_Report* ' + @ARCHIVE_DIR + CAST(@in_STATUS_RECORD_NUM as varchar(10)) + '_TRANSACTION_REPORT.TXT'
   PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD
   IF @rtn_code <> 0 OR @@ERROR <> 0
      RETURN (557)
	
   PRINT 'FDS INTERFACE FILE ARCHIVED BUT NOT SENT '
END
ELSE IF @TRANSFER_FILES = 'YES' AND @in_exec_mode = 'F'
BEGIN
-- CR-9449 Begin
   PRINT ' '
   PRINT 'FDS INTERFACE FILE IS NOT LONGER SENT'
END

 
 
PRINT '' --CR9449 *~^
PRINT '*~^*************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF  XX_FDS_FTP_FDS_FILE_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^
RETURN(0)

END






 

 

 

GO
 


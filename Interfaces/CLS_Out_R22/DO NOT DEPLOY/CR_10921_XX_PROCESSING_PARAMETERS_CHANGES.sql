     
INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
	values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS_R22'),'CLS_R22','FTP_CMD','D:\IMAPS_Data\Interfaces\PROGRAMS\CLS_R22\CLS_R22_ftp.bat',SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)
   
UPDATE  IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
SET PARAMETER_VALUE = 'D:\IMAPS_DATA\PROPS\CLS_R22\CLS_R22_WINSCP.TXT'
WHERE PARAMETER_NAME = 'FTP_COMMAND_FILE'
AND INTERFACE_NAME_CD = 'CLS_R22'

UPDATE  IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
SET PARAMETER_VALUE = 'D:\IMAPS_DATA\Interfaces\logs\CLS_R22_FTP_log.txt'
WHERE PARAMETER_NAME = 'FTP_LOG_FILE'
AND INTERFACE_NAME_CD = 'CLS_R22'
 
   
   SELECT PARAMETER_NAME, PARAMETER_VALUE
     FROM dbo.XX_PROCESSING_PARAMETERS
    WHERE INTERFACE_NAME_CD = 'CLS_R22'

      
      
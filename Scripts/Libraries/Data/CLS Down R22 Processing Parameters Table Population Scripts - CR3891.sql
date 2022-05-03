use imapsstg


--new parameters for
--CLS_R22  - ftp commands and log files
DECLARE @INTERFACE_NAME_ID integer

SELECT @INTERFACE_NAME_ID = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t2.APPLICATION_CODE = 'CLS_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@INTERFACE_NAME_ID, 'CLS_R22', 'FTP_COMMAND_FILE', 'D:\IMAPS_Data\NotShared\CLS_R22_FTP_commands.txt', SUSER_SNAME(), GETDATE())
INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@INTERFACE_NAME_ID, 'CLS_R22', 'FTP_LOG_FILE', 'D:\IMAPS_Data\NotShared\CLS_R22_FTP_log.txt', SUSER_SNAME(), GETDATE())



--update parameters and file path for FDS/CCS and CLS/CLS_R22 java properties file
update xx_processing_parameters
set parameter_value='"D:\IMAPS_Data\NotShared\jdbc_connection.properties"'
where interface_name_cd in ('CLS_R22')
and parameter_name='SERVER_PARAM'



--blank out old parameters
update xx_processing_parameters
set parameter_value = ''
where 
interface_name_cd='CLS_R22'
and 
parameter_name in ('DB_PARAM', 'PWD_PARAM', 'USER_PARAM')

update xx_processing_parameters
set parameter_value=''
where
interface_name_cd in ('CLS_R22')
and 
parameter_name in ('CCS_FTP_SERVER', 'CCS_FTP_USER', 'CCS_FTP_PASS', 'CCS_FTP_DEST_FILE', 'FDS_FTP_SERVER', 'FDS_FTP_USER', 'FDS_FTP_PASS', 'FDS_FTP_DEST_FILE', 'FTP_SERVER', 'FTP_USER', 'FTP_PASS', 'FTP_DEST_999FILE', 'FTP_DEST_PARMFILE')


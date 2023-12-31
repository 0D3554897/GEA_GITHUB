-- CR-11452 System Data Update

USE [IMAPSStg]
GO

UPDATE IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS
   SET PARAMETER_VALUE = 'fsst@dswax04.div16.ibm.com',
       MODIFIED_BY = SUSER_SNAME(),
       MODIFIED_DATE =  GETDATE()
 WHERE INTERFACE_NAME_CD = 'UTIL'
   AND PARAMETER_NAME = 'TEST_SFTP_SERVER'
GO

-- 04/29/2020 Begin
UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS SET PARAMETER_VALUE = '%PUTTY_HOME%KEYS\ENV_RSA_INTERFACE.PPK' WHERE PARAMETER_NAME = 'KEYFILE' AND INTERFACE_NAME_CD = 'UTIL'

UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS SET PARAMETER_VALUE = 'CCIS_OPEN_BALANCES.TXT;CCIS_OPEN_BALANCES.TXT' WHERE PARAMETER_NAME = 'TARGET_FILE_1' AND INTERFACE_NAME_CD = 'CCIS'
UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS SET PARAMETER_VALUE = 'CCIS_ACTIVITY.TXT;CCIS_ACTIVITY.TXT' WHERE PARAMETER_NAME = 'TARGET_FILE_2' AND INTERFACE_NAME_CD = 'CCIS'
UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS SET PARAMETER_VALUE = 'CCIS_OPEN_REMARKS.TXT;CCIS_OPEN_REMARKS.TXT' WHERE PARAMETER_NAME = 'TARGET_FILE_3' AND INTERFACE_NAME_CD = 'CCIS'

UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS SET PARAMETER_VALUE = 'vargal@us.ibm.com' WHERE PARAMETER_NAME = 'IN_OPS_OWNER' AND INTERFACE_NAME_CD = 'CCIS'
-- 04/29/2020 End

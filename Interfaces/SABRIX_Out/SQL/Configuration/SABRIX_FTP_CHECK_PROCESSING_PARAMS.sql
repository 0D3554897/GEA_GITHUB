
-- make sure the processing parameters are there, or not
-- only one of each

SELECT * FROM  IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = 'SABRIX'
and parameter_name in ('SABRIX_SEARCH_PHRASE','SABRIX_FTP_ADJUST','FTP_CHECK_EXE')

-- insert statements are below.  


DECLARE @SABRIX INT, @UTIL INT

SELECT @UTIL=INTERFACE_NAME_ID FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = 'UTIL'

INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
(INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
VALUES (@UTIL,'UTIL','FTP_CHECK_EXE','D:\IMAPS_Data\Interfaces\Programs\Java\ftp_chk\ftp_chk.bat', SUSER_SNAME(),GETDATE())


SELECT @SABRIX=INTERFACE_NAME_ID FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = 'SABRIX'

INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
(INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
VALUES (@SABRIX,'SABRIX','SABRIX_SEARCH_PHRASE','250 Transfer Completed', SUSER_SNAME(),GETDATE())

INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
(INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
VALUES (@SABRIX,'SABRIX','SABRIX_FTP_ADJUST','2', SUSER_SNAME(),GETDATE())

SELECT TOP 20 * FROM  IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
WHERE LEFT(CREATED_DATE,12) = LEFT(GETDATE(),12)


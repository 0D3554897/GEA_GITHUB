USE IMAPSSTG
INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS VALUES (
	(SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS'), LTRIM(RTRIM(' CLS' )), LTRIM(RTRIM(' XX_CLS_DOWN_ARCHIVE_FILES_SP' )),' 0' , SUSER_SNAME(),GETDATE(),NULL,NULL,NULL); 
INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS VALUES (
	(SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS'), LTRIM(RTRIM(' CLS' )), LTRIM(RTRIM(' XX_CLS_DOWN_CHECK_JOB_SP' )),' 0' , SUSER_SNAME(),GETDATE(),NULL,NULL,NULL); 
INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS VALUES (
	(SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS'), LTRIM(RTRIM(' CLS' )), LTRIM(RTRIM(' XX_CLS_DOWN_CREATE_FLAT_FILE_SP' )),' 0' , SUSER_SNAME(),GETDATE(),NULL,NULL,NULL); 
INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS VALUES (
	(SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS'), LTRIM(RTRIM(' CLS' )), LTRIM(RTRIM(' XX_CLS_DOWN_CREATE_LOG_RECORD_SP' )),' 0' , SUSER_SNAME(),GETDATE(),NULL,NULL,NULL); 
INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS VALUES (
	(SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS'), LTRIM(RTRIM(' CLS' )), LTRIM(RTRIM(' XX_CLS_DOWN_FTP_FILE_SP' )),' 0' , SUSER_SNAME(),GETDATE(),NULL,NULL,NULL); 
INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS VALUES (
	(SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS'), LTRIM(RTRIM(' CLS' )), LTRIM(RTRIM(' XX_CLS_DOWN_GET_TOTALS_SP' )),' 0' , SUSER_SNAME(),GETDATE(),NULL,NULL,NULL); 
INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS VALUES (
	(SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS'), LTRIM(RTRIM(' CLS' )), LTRIM(RTRIM(' XX_CLS_DOWN_LOAD_STAGE_SP' )),' 0' , SUSER_SNAME(),GETDATE(),NULL,NULL,NULL); 
INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS VALUES (
	(SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS'), LTRIM(RTRIM(' CLS' )), LTRIM(RTRIM(' XX_CLS_DOWN_RUN_INTERFACE_SP' )),' 0' , SUSER_SNAME(),GETDATE(),NULL,NULL,NULL); 
INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS VALUES (
	(SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS'), LTRIM(RTRIM(' CLS' )), LTRIM(RTRIM(' XX_CLS_DOWN_VALIDATE_ACCT_MAP_SP' )),' 0' , SUSER_SNAME(),GETDATE(),NULL,NULL,NULL); 
INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS VALUES (
	(SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS'), LTRIM(RTRIM(' CLS' )), LTRIM(RTRIM(' XX_CLS_DOWN_VALIDATE_CMR_SP' )),' 0' , SUSER_SNAME(),GETDATE(),NULL,NULL,NULL); 
INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS VALUES (
	(SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS'), LTRIM(RTRIM(' CLS' )), LTRIM(RTRIM(' XX_CLS_DOWN_VALIDATE_FIN_SP' )),' 0' , SUSER_SNAME(),GETDATE(),NULL,NULL,NULL); 

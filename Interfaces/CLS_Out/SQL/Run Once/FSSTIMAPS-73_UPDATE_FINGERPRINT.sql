UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
SET PARAMETER_VALUE = '15433'
WHERE PARAMETER_NAME = 'XX_CLS_DOWN_LOAD_STAGE_SP'


UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS SET PARAMETER_VALUE = 19847, MODIFIED_DATE = GETDATE() , MODIFIED_BY = SUSER_SNAME()
	 WHERE PARAMETER_NAME = 'XX_CLS_999_FILE_VW' ; 
UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS SET PARAMETER_VALUE = 14357, MODIFIED_DATE = GETDATE() , MODIFIED_BY = SUSER_SNAME()
	 WHERE PARAMETER_NAME = 'XX_CLS_999_FILE_TEXT_VW' ; 

USE IMAPSSTG

UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS SET PARAMETER_VALUE = 16889, MODIFIED_DATE = GETDATE() , MODIFIED_BY = SUSER_SNAME()
	 WHERE PARAMETER_NAME = 'XX_CLS_DOWN_LOAD_STAGE_SP' ; 

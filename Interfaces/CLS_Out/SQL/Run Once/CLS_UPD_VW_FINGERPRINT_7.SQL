USE IMAPSSTG
UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS SET PARAMETER_VALUE = 16881, MODIFIED_DATE = GETDATE() , MODIFIED_BY = SUSER_SNAME()
	 WHERE PARAMETER_NAME = 'XX_CLS_PARM_FILE_VW' ; 
UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS SET PARAMETER_VALUE = 17795, MODIFIED_DATE = GETDATE() , MODIFIED_BY = SUSER_SNAME()
	 WHERE PARAMETER_NAME = 'XX_CLS_DOWN_VW' ; 
UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS SET PARAMETER_VALUE = 18018, MODIFIED_DATE = GETDATE() , MODIFIED_BY = SUSER_SNAME()
	 WHERE PARAMETER_NAME = 'XX_CLS_DOWN_FDS_RECONCILE_VW' ; 
UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS SET PARAMETER_VALUE = 18282, MODIFIED_DATE = GETDATE() , MODIFIED_BY = SUSER_SNAME()
	 WHERE PARAMETER_NAME = 'XX_CLS_DOWN_GL_RECONCILE_VW' ; 
UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS SET PARAMETER_VALUE = 18697, MODIFIED_DATE = GETDATE() , MODIFIED_BY = SUSER_SNAME()
	 WHERE PARAMETER_NAME = 'XX_CLS_DOWN_BURDEN_RECONCILE_VW' ; 
UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS SET PARAMETER_VALUE = 19501, MODIFIED_DATE = GETDATE() , MODIFIED_BY = SUSER_SNAME()
	 WHERE PARAMETER_NAME = 'XX_CLS_999_FILE_TEXT_VW' ; 
UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS SET PARAMETER_VALUE = 20779, MODIFIED_DATE = GETDATE() , MODIFIED_BY = SUSER_SNAME()
	 WHERE PARAMETER_NAME = 'XX_CLS_999_FILE_VW' ; 

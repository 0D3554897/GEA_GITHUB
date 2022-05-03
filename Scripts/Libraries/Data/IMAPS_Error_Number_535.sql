-- DEV00000401_begin
INSERT INTO [dbo].[XX_INT_ERROR_MESSAGE]
([ERROR_CODE], [ERROR_TYPE], [ERROR_SEVERITY], 
[ERROR_MESSAGE], [ERROR_SOURCE], [CREATED_BY], 
[CREATED_DATE])
VALUES(535, 42, NULL, 
'The log record for the current interface run is missing. Please check XX_UTIL_OUT_LOG table.',
'IMAPS execution environment', 'imapsstg', GetDate())
GO

-- DEV00000401_end
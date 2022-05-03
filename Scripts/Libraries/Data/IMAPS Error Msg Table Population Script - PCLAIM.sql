-- begin TP 03/08/2006

INSERT INTO [dbo].[XX_INT_ERROR_MESSAGE]
([ERROR_CODE], [ERROR_TYPE], [ERROR_SEVERITY], 
[ERROR_MESSAGE], [ERROR_SOURCE], [CREATED_BY], 
[CREATED_DATE])
VALUES(528, 42, NULL, 
' PCLAIM input data has more than one VENDOR specified for VENDOR EMPLOYEE %1',
'IMAPS execution environment', 'imapsstg', GetDate())
GO


INSERT INTO [dbo].[XX_INT_ERROR_MESSAGE]
([ERROR_CODE], [ERROR_TYPE], [ERROR_SEVERITY], 
[ERROR_MESSAGE], [ERROR_SOURCE], [CREATED_BY], 
[CREATED_DATE])
VALUES(529, 42, NULL, 
' VENDOR specified in PCLAIM input data for VENDOR EMPLOYEE %1 does not match IMAPS VEND_EMPL table data',
'IMAPS execution environment', 'imapsstg', GetDate())
GO

-- end TP 03/08/2006
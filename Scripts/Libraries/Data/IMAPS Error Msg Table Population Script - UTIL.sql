INSERT INTO [dbo].[XX_INT_ERROR_MESSAGE]
([ERROR_CODE], [ERROR_TYPE], [ERROR_SEVERITY], 
[ERROR_MESSAGE], [ERROR_SOURCE], [CREATED_BY], 
[CREATED_DATE])
VALUES(530, 42, NULL, 
'Total %1 transfered to et&T is not in sync with the %1 in the staging table %2.',
'IMAPS execution environment', 'imapsstg', GetDate())
GO

INSERT INTO [dbo].[XX_INT_ERROR_MESSAGE]
([ERROR_CODE], [ERROR_TYPE], [ERROR_SEVERITY], 
[ERROR_MESSAGE], [ERROR_SOURCE], [CREATED_BY], 
[CREATED_DATE])
VALUES(531, 42, NULL, 
'Utilization Interface data gathered for the current interface run was already archived.',
'IMAPS execution environment', 'imapsstg', GetDate())
GO

INSERT INTO [dbo].[XX_INT_ERROR_MESSAGE]
([ERROR_CODE], [ERROR_TYPE], [ERROR_SEVERITY], 
[ERROR_MESSAGE], [ERROR_SOURCE], [CREATED_BY], 
[CREATED_DATE])
VALUES(532, 42, NULL, 
'Total count of record archived is not in sync with the number of records in the staging tables.',
'IMAPS execution environment', 'imapsstg', GetDate())
GO

INSERT INTO [dbo].[XX_INT_ERROR_MESSAGE]
([ERROR_CODE], [ERROR_TYPE], [ERROR_SEVERITY], 
[ERROR_MESSAGE], [ERROR_SOURCE], [CREATED_BY], 
[CREATED_DATE])
VALUES(533, 42, NULL, 
'Invalid last standard request record in XX_UTIL_OUT_LOG table',
'IMAPS execution environment', 'imapsstg', GetDate())
GO


-- for PCLAIM changes
INSERT INTO [dbo].[XX_INT_ERROR_MESSAGE]
([ERROR_CODE], [ERROR_TYPE], [ERROR_SEVERITY], 
[ERROR_MESSAGE], [ERROR_SOURCE], [CREATED_BY], 
[CREATED_DATE])
VALUES(525, 42, NULL, 
'Input data was not supplied by PCLAIM system to the XX_PCLAIM_IN table.',
'IMAPS execution environment', 'imapsstg', GetDate())
GO

INSERT INTO [dbo].[XX_INT_ERROR_MESSAGE]
([ERROR_CODE], [ERROR_TYPE], [ERROR_SEVERITY], 
[ERROR_MESSAGE], [ERROR_SOURCE], [CREATED_BY], 
[CREATED_DATE])
VALUES(526, 42, NULL, 
'Please validate PCLAIM input data and leave only one record with Null STATUS_RECORD_NUM in XX_PCLAIM_IN_LOG table.',
'IMAPS execution environment', 'imapsstg', GetDate())
GO

INSERT INTO [dbo].[XX_INT_ERROR_MESSAGE]
([ERROR_CODE], [ERROR_TYPE], [ERROR_SEVERITY], 
[ERROR_MESSAGE], [ERROR_SOURCE], [CREATED_BY], 
[CREATED_DATE])
VALUES(527, 42, NULL, 
'Log table %1 does not match the actuall %1.',
'IMAPS execution environment', 'imapsstg', GetDate())
GO
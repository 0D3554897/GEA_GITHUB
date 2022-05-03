INSERT INTO [dbo].[XX_INT_ERROR_MESSAGE]
([ERROR_CODE], [ERROR_TYPE], [ERROR_SEVERITY], 
[ERROR_MESSAGE], [ERROR_SOURCE], [CREATED_BY], 
[CREATED_DATE])
VALUES(550, 42, NULL, 
'Accounting FY and Month should be correctly entered for CLS run on demand',
'IMAPS execution environment', 'imapsstg', GetDate())
GO

INSERT INTO [dbo].[XX_INT_ERROR_MESSAGE]
([ERROR_CODE], [ERROR_TYPE], [ERROR_SEVERITY], 
[ERROR_MESSAGE], [ERROR_SOURCE], [CREATED_BY], 
[CREATED_DATE])
VALUES(551, 42, NULL, 
' CLS Down out put  in XX_CLS_DOWN  table is not balanced (CREDIT <> DEBIT)',
'IMAPS execution environment', 'imapsstg', GetDate())
GO

INSERT INTO [dbo].[XX_INT_ERROR_MESSAGE]
([ERROR_CODE], [ERROR_TYPE], [ERROR_SEVERITY], 
[ERROR_MESSAGE], [ERROR_SOURCE], [CREATED_BY], 
[CREATED_DATE])
VALUES(552, 42, NULL, 
'In %1 table %2. This could result in misrepresentation of IMAPS GL data',
'IMAPS execution environment', 'imapsstg', GetDate())
GO


INSERT INTO [dbo].[XX_INT_ERROR_MESSAGE]
([ERROR_CODE], [ERROR_TYPE], [ERROR_SEVERITY], 
[ERROR_MESSAGE], [ERROR_SOURCE], [CREATED_BY], 
[CREATED_DATE])
VALUES(553, 42, NULL, 
'Total value of burden applied to contract cost in CLS DOWN does not match the same value 
from PROJ_SUM table.',
'IMAPS execution environment', 'imapsstg', GetDate())
GO

INSERT INTO [dbo].[XX_INT_ERROR_MESSAGE]
([ERROR_CODE], [ERROR_TYPE], [ERROR_SEVERITY], 
[ERROR_MESSAGE], [ERROR_SOURCE], [CREATED_BY], 
[CREATED_DATE])
VALUES(554, 42, NULL, 
'FDS reversal is %1',
'IMAPS execution environment', 'imapsstg', GetDate())
GO


INSERT INTO [dbo].[XX_INT_ERROR_MESSAGE]
([ERROR_CODE], [ERROR_TYPE], [ERROR_SEVERITY], 
[ERROR_MESSAGE], [ERROR_SOURCE], [CREATED_BY], 
[CREATED_DATE])
VALUES(555, 42, NULL, 
'Burden found for customer/contract/service offering was assigned to multiple rows in XX_CLS_DOWN or 
 was not assigned at all.',
'IMAPS execution environment', 'imapsstg', GetDate())
GO
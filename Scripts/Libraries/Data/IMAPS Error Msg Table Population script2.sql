UPDATE [IMAPSStg].[dbo].[XX_INT_ERROR_MESSAGE]
SET [ERROR_MESSAGE]='Log table %1 does not match the actual %2.'
WHERE ERROR_CODE = 527

UPDATE [IMAPSStg].[dbo].[XX_INT_ERROR_MESSAGE]
SET [ERROR_MESSAGE]='Total %1 transferred to et&T is not in sync with the %2 in the staging table %3.'
WHERE ERROR_CODE = 530

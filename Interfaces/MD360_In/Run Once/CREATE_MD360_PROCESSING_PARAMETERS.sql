

insert into imapsstg.dbo.XX_PROCESSING_PARAMETERS values ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'UTIL'),'UTIL',
'C360 ERROR MAIL','vargal@us.ibm.com',
SUSER_SNAME(),GETDATE(),NULL,NULL,NULL)
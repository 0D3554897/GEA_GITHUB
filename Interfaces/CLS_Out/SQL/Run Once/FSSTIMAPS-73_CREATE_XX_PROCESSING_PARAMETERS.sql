INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
VALUES ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS')
, 'CLS', '703','35603000000',SUSER_SNAME(), GETDATE(),NULL,NULL,NULL)

INSERT INTO IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
VALUES ((SELECT CAST(LOOKUP_ID AS VARCHAR(10)) FROM IMAPSSTG.DBO.XX_LOOKUP_DETAIL WHERE APPLICATION_CODE = 'CLS')
, 'CLS', '704','45601000000',SUSER_SNAME(), GETDATE(),NULL,NULL,NULL)

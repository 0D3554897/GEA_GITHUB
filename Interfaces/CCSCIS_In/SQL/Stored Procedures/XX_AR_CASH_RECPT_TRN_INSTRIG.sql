USE [IMAPSStg]
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CASH_RECPT_TRN_INSTRIG]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
   DROP TRIGGER [dbo].[XX_AR_CASH_RECPT_TRN_INSTRIG]
GO



CREATE TRIGGER [dbo].[XX_AR_CASH_RECPT_TRN_INSTRIG]
ON
[dbo].[XX_AR_CASH_RECPT_TRN] FOR INSERT
AS

DECLARE @num_rows INTEGER

SELECT @num_rows = @@ROWCOUNT

IF @num_rows = 0
   RETURN

/* F08178 insert restrict */
IF (SELECT COUNT(*)
      FROM dbo.XX_AR_CASH_RECPT_HDR,
           inserted
     WHERE dbo.XX_AR_CASH_RECPT_HDR.CASH_RECPT_HDR_KEY = inserted.CASH_RECPT_HDR_KEY
   ) != @num_rows
   BEGIN
      RAISERROR('ERROR: NOT FOUND IN dbo.CASH_RECPT_HDR for child CASH_RECPT_TRN [XX_AR_CASH_RECPT_TRN_INSTRIG]', 40002, 1)
      ROLLBACK TRAN
      RETURN
   END

/* F08179 insert restrict */
IF (SELECT COUNT(*)
      FROM IMAPS.DELTEK.ORG_ACCT,
           inserted
     WHERE IMAPS.DELTEK.ORG_ACCT.ORG_ID = inserted.ORG_ID
       AND IMAPS.DELTEK.ORG_ACCT.ACCT_ID = inserted.ACCT_ID
   ) != @num_rows
   BEGIN
      RAISERROR('ERROR: NOT FOUND IN DELTEK.ORG_ACCT for child CASH_RECPT_TRN [XX_AR_CASH_RECPT_TRN_INSTRIG]', 40002, 1)
      ROLLBACK TRAN
      RETURN
   END

/* F08180 insert restrict */
IF (SELECT COUNT(*)
      FROM IMAPS.DELTEK.PROJ,
           inserted
     WHERE IMAPS.DELTEK.PROJ.PROJ_ID = inserted.PROJ_ID
   ) != (@num_rows - (select count(*) from inserted where inserted.PROJ_ID is NULL))
   BEGIN
      RAISERROR('ERROR: NOT FOUND IN DELTEK.PROJ for child CASH_RECPT_TRN [XX_AR_CASH_RECPT_TRN_INSTRIG]', 40002, 1)
      ROLLBACK TRAN
      RETURN 
   END 
GO

ALTER TABLE [dbo].[XX_AR_CASH_RECPT_TRN] ENABLE TRIGGER [XX_AR_CASH_RECPT_TRN_INSTRIG]
GO

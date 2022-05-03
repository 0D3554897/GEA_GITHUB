USE [IMAPSStg]
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CASH_RECPT_HDR_INSTRIG]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
   DROP TRIGGER [dbo].[XX_AR_CASH_RECPT_HDR_INSTRIG]
GO

CREATE TRIGGER [dbo].[XX_AR_CASH_RECPT_HDR_INSTRIG]
ON
[dbo].[XX_AR_CASH_RECPT_HDR] FOR INSERT
AS

DECLARE @num_rows INTEGER

SELECT @num_rows = @@ROWCOUNT

IF @num_rows = 0
   RETURN

/* F08176 insert restrict */
IF (SELECT COUNT(*)
      FROM IMAPS.DELTEK.POSTING,
           inserted
     WHERE IMAPS.DELTEK.POSTING.FY_CD = inserted.FY_CD
       AND IMAPS.DELTEK.POSTING.PD_NO = inserted.PD_NO
       AND IMAPS.DELTEK.POSTING.S_JNL_CD = inserted.S_JNL_CD
       AND IMAPS.DELTEK.POSTING.POST_SEQ_NO = inserted.POST_SEQ_NO
   ) != (@num_rows - (select count(*) from inserted where inserted.POST_SEQ_NO is NULL))
   BEGIN
      RAISERROR('ERROR: NOT FOUND IN DELTEK.POSTING for child CASH_RECPT_HDR [XX_AR_CASH_RECPT_HDR_INSTRIG]', 40002, 1)
      ROLLBACK TRAN
      RETURN
   END

/* F08175 insert restrict */
IF (SELECT COUNT(*)
      FROM IMAPS.DELTEK.SUB_PD,
           inserted
     WHERE IMAPS.DELTEK.SUB_PD.FY_CD = inserted.FY_CD
       AND IMAPS.DELTEK.SUB_PD.PD_NO = inserted.PD_NO
       AND IMAPS.DELTEK.SUB_PD.SUB_PD_NO = inserted.SUB_PD_NO
   ) != @num_rows
   BEGIN
      RAISERROR('ERROR: NOT FOUND IN DELTEK.SUB_PD for child CASH_RECPT_HDR [XX_AR_CASH_RECPT_HDR_INSTRIG]', 40002, 1)
      ROLLBACK TRAN
      RETURN
   END 
GO

ALTER TABLE [dbo].[XX_AR_CASH_RECPT_HDR] ENABLE TRIGGER [XX_AR_CASH_RECPT_HDR_INSTRIG]
GO

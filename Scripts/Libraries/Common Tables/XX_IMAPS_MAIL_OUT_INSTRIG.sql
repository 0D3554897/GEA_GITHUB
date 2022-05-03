USE [IMAPSStg]
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_IMAPS_MAIL_OUT_INSTRIG]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
   DROP TRIGGER [dbo].[XX_IMAPS_MAIL_OUT_INSTRIG]
GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE TRIGGER [dbo].[XX_IMAPS_MAIL_OUT_INSTRIG]
   ON [IMAPSStg].[dbo].[XX_IMAPS_MAIL_OUT]
   AFTER INSERT
AS 

/*************************************************************************************
Name:    XX_IMAPS_MAIL_OUT_INSTRIG
Author:  MT
Created: 04/01/2020
Purpose: Upon successful insert of XX_IMAPS_MAIL_OUT record, notify user via email.
         DR-11928 04/01/2020 Add MESSAGE_ID's value to MESSAGE_TEXT's value.
         The benefit of the IDENTITY constraint for column MESSAGE_ID is kept intact.
         See XX_SEND_STATUS_MAIL_SP.
**************************************************************************************/

DECLARE @MessageSubject  char(100),
        @MessageText     varchar(3000),
        @MailToAddress   varchar(300),
        @Attachments     varchar(300),
        @StatusRecordNum integer,
        @MessageID       integer

SET @MessageSubject = (SELECT MESSAGE_SUBJECT FROM inserted)
SET @MessageText = (SELECT MESSAGE_TEXT FROM inserted)
SET @MailToAddress = (SELECT MAIL_TO_ADDRESS FROM inserted)
SET @Attachments = (SELECT ATTACHMENTS FROM inserted)
SET @StatusRecordNum = (SELECT STATUS_RECORD_NUM FROM inserted)
SET @MessageID = (SELECT MESSAGE_ID FROM inserted)

-- Finalize or complete the value of MESSAGE_TEXT so that the email body text is displayed correctly.
SET @MessageText = @MessageText + CAST(@MessageID as varchar(15))

EXEC msdb.dbo.sp_send_dbmail
   @profile_name     = FSST_Dev,
   @recipients       = @MailToAddress,
   @subject          = @MessageSubject,
   @body             = @MessageText,
   @file_attachments = @Attachments

UPDATE [dbo].[XX_IMAPS_MAIL_OUT]
   SET MESSAGE_TEXT = @MessageText,
       SEND_DT = GETDATE()
 WHERE STATUS_RECORD_NUM = @StatusRecordNum
   AND MESSAGE_ID = @MessageID
GO

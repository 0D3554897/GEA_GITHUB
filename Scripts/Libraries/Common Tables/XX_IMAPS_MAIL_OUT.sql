if exists (select * from dbo.sysobjects where id = object_id(N'[XX_IMAPS_MAIL_OUT]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_IMAPS_MAIL_OUT]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_IMAPS_MAIL_OUT]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [XX_IMAPS_MAIL_OUT] (
	[MESSAGE_TEXT] [varchar] (3000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MESSAGE_SUBJECT] [char] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MAIL_TO_ADDRESS] [char] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ATTACMENTS] [varchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[CREATE_DT] [datetime] NOT NULL CONSTRAINT [DF_XX_IMAPS_MAIL_OUT_CREATED] DEFAULT (getdate()),
	[SEND_DT] [datetime] NULL ,
	[MESSAGE_ID] [int] IDENTITY (1, 1) NOT NULL ,
	CONSTRAINT [FK_XX_IMAPS_MAIL_OUT_XX_IMAPS_INT_STATUS] FOREIGN KEY 
	(
		[STATUS_RECORD_NUM]
	) REFERENCES [XX_IMAPS_INT_STATUS] (
		[STATUS_RECORD_NUM]
	) ON DELETE CASCADE  NOT FOR REPLICATION 
) ON [PRIMARY]
END

GO



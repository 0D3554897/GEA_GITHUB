if exists (select * from dbo.sysobjects where id = object_id(N'[XX_CERIS_VALIDAT_ERRORS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_CERIS_VALIDAT_ERRORS]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_VALIDAT_ERRORS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_VALIDAT_ERRORS] (
	[EMPL_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[ERROR_DESC] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TIME_STAMP] [datetime] NOT NULL CONSTRAINT [DF__XX_CERIS___TIME___391958F9] DEFAULT (getdate()),
	CONSTRAINT [FK_XX_CERIS_VALIDAT_ERRORS] FOREIGN KEY 
	(
		[STATUS_RECORD_NUM]
	) REFERENCES [XX_IMAPS_INT_STATUS] (
		[STATUS_RECORD_NUM]
	)
) ON [PRIMARY]
END

GO



if exists (select * from dbo.sysobjects where id = object_id(N'[XX_7KEYS_RUN_LOG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_7KEYS_RUN_LOG]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_7KEYS_RUN_LOG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_7KEYS_RUN_LOG] (
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[FY_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PD_NO] [smallint] NOT NULL ,
	[RUN_TYPE_ID] [int] NOT NULL ,
	[CREATED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TIME_STAMP] [datetime] NOT NULL CONSTRAINT [DF__XX_7KEYS___TIME___1B5ED8E0] DEFAULT (getdate()),
	CONSTRAINT [FK_XX_7KEYS_RUN_LOG_LOOKUP] FOREIGN KEY 
	(
		[RUN_TYPE_ID]
	) REFERENCES [XX_LOOKUP_DETAIL] (
		[LOOKUP_ID]
	),
	CONSTRAINT [FK_XX_7KEYS_RUN_LOG_STATUS] FOREIGN KEY 
	(
		[STATUS_RECORD_NUM]
	) REFERENCES [XX_IMAPS_INT_STATUS] (
		[STATUS_RECORD_NUM]
	)
) ON [PRIMARY]
END

GO



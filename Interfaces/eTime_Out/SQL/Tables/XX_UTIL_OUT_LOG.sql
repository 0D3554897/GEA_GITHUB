if exists (select * from dbo.sysobjects where id = object_id(N'[XX_UTIL_OUT_LOG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_UTIL_OUT_LOG]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_UTIL_OUT_LOG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_UTIL_OUT_LOG] (
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[START_DT] [smalldatetime] NULL ,
	[END_DT] [smalldatetime] NULL ,
	[LAST_TS_LN_KEY] [int] NULL ,
	[LAB_RECORD_COUNT] [int] NULL ,
	[ORG_RECORD_COUNT] [int] NULL ,
	[TOTAL_LABOR_HOURS] [decimal](14, 2) NULL ,
	CONSTRAINT [IX_XX_UTIL_OUT_LOG] UNIQUE  NONCLUSTERED 
	(
		[STATUS_RECORD_NUM]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [FK_XX_UTIL_OUT_LOG_XX_IMAPS_INT_STATUS] FOREIGN KEY 
	(
		[STATUS_RECORD_NUM]
	) REFERENCES [XX_IMAPS_INT_STATUS] (
		[STATUS_RECORD_NUM]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
) ON [PRIMARY]
END

GO



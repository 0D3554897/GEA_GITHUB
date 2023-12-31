if exists (select * from dbo.sysobjects where id = object_id(N'[XX_UTIL_ORG_OUT]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_UTIL_ORG_OUT]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_UTIL_ORG_OUT]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_UTIL_ORG_OUT] (
	[UTIL_ORG_RECORD_NUM] [int] IDENTITY (1, 1) NOT NULL ,
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[DIVISION] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PRACTICE_AREA] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ORG_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ORG_ABBRV_CD] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ORG_NAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[SERVICE_AREA] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SERVICE_AREA_DESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_XX_UTIL_ORG_OUT] PRIMARY KEY  CLUSTERED 
	(
		[UTIL_ORG_RECORD_NUM]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [FK_XX_UTIL_ORG_OUT_XX_IMAPS_INT_STATUS] FOREIGN KEY 
	(
		[STATUS_RECORD_NUM]
	) REFERENCES [XX_IMAPS_INT_STATUS] (
		[STATUS_RECORD_NUM]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
) ON [PRIMARY]
END

GO



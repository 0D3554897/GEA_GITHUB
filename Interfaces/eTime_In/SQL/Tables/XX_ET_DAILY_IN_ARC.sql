if exists (select * from dbo.sysobjects where id = object_id(N'[XX_ET_DAILY_IN_ARC]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_ET_DAILY_IN_ARC]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_ET_DAILY_IN_ARC]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [XX_ET_DAILY_IN_ARC] (
	[ET_DAILY_IN_ARC_NUM] [int] IDENTITY (1, 1) NOT NULL ,
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[EMP_SERIAL_NUM] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TS_YEAR] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TS_MONTH] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TS_DAY] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TS_DATE] [datetime] NOT NULL ,
	[TS_WEEK_END_DATE] [datetime] NOT NULL ,
	[PROJ_ABBR] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[REG_TIME] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OVERTIME] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PLC] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[RECORD_TYPE] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CREATED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CREATED_DATE] [datetime] NOT NULL ,
	[MODIFIED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MODIFIED_DATE] [datetime] NULL ,
	CONSTRAINT [PK_XX_ET_DAILY_IN_ARC] PRIMARY KEY  CLUSTERED 
	(
		[ET_DAILY_IN_ARC_NUM]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [FK_XX_ET_DAILY_IN_ARC] FOREIGN KEY 
	(
		[STATUS_RECORD_NUM]
	) REFERENCES [XX_IMAPS_INT_STATUS] (
		[STATUS_RECORD_NUM]
	)
) ON [PRIMARY]
END

GO



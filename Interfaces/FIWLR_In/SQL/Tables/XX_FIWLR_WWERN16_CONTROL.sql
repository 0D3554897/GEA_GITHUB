if exists (select * from dbo.sysobjects where id = object_id(N'[XX_FIWLR_WWERN16_CONTROL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_FIWLR_WWERN16_CONTROL]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_WWERN16_CONTROL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_FIWLR_WWERN16_CONTROL] (
	[CONTROL_RECORD_NUM] [int] IDENTITY (1, 1) NOT NULL ,
	[PROCESS_NAME] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[RECORD_COUNT] [numeric](9, 0) NULL ,
	[RECORD_COUNT_INITIAL] [numeric](9, 0) NULL ,
	[TOTAL_AMOUNT] [decimal](14, 2) NULL ,
	[CREATED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CREATED_DATE] [datetime] NOT NULL ,
	[MODIFIED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MODIFIED_DATE] [datetime] NULL ,
	CONSTRAINT [PK_XX_FIWLR_WWERN16_CONTROL] PRIMARY KEY  CLUSTERED 
	(
		[CONTROL_RECORD_NUM]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
END

GO



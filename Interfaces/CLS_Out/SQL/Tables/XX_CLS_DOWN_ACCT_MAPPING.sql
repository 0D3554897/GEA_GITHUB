if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CLS_DOWN_ACCT_MAPPING]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CLS_DOWN_ACCT_MAPPING]
GO

CREATE TABLE [dbo].[XX_CLS_DOWN_ACCT_MAPPING] (
	[ROW_NUM] [int] IDENTITY (1, 1) NOT NULL ,
	[IMAPS_ACCT_START] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[IMAPS_ACCT_END] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CLS_MAJOR] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CLS_MINOR] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CLS_SUB_MINOR] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CONTRACT] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CUSTOMER] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJECT] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MACHINE_TYPE] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PRODUCT_ID] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[APPLY_BURDEN] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REVERSE_FDS] [smallint] NULL ,
	[MULTIPLIER] [smallint] NULL ,
	[STUB] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[XX_CLS_DOWN_ACCT_MAPPING] ADD 
	CONSTRAINT [PK_XX_CLS_DOWN_ACCT_MAPPING] PRIMARY KEY  CLUSTERED 
	(
		[ROW_NUM]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
GO




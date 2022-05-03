use imapsstg

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CLS_DOWN_SUMMARY]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CLS_DOWN_SUMMARY]
GO

CREATE TABLE [dbo].[XX_CLS_DOWN_SUMMARY] (
	[DIVISION] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CLS_MAJOR] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CLS_MINOR] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CLS_SUB_MINOR] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DOLLAR_AMT] [decimal](14, 2) NULL ,
	[RECORD_CNT] [int] NULL 
) ON [PRIMARY]
GO


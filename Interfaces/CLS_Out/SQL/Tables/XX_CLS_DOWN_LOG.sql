if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CLS_DOWN_LOG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CLS_DOWN_LOG]
GO

CREATE TABLE [dbo].[XX_CLS_DOWN_LOG] (
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[FILE_SEQ_NUM] [int] NULL ,
	[VOUCHER_NUM] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FY_SENT] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MONTH_SENT] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[LEDGER_ENTRY_DATE] [datetime] NULL ,
	[MODIFIED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ON_DEMAND] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO


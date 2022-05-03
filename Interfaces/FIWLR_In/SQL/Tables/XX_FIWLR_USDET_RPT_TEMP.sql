SET ANSI_PADDING ON
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_USDET_RPT_TEMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_FIWLR_USDET_RPT_TEMP]
GO

CREATE TABLE [dbo].[XX_FIWLR_USDET_RPT_TEMP] (
	[STATUS_REC_NO] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[IDENT_REC_NO] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SOURCE_GROUP] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CP_LN_NOTES] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CP_LN_DESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CP_HDR_KEY] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CP_HDR_NO] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CP_LN_NO] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FY_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PD_NO] [smallint] NULL ,
	[SUB_PD_NO] [smallint] NULL 
) ON [PRIMARY]
GO



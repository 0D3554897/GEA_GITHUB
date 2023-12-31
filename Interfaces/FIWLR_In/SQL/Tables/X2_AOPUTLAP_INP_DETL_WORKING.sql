SET ANSI_PADDING ON
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[X2_AOPUTLAP_INP_DETL_WORKING]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[X2_AOPUTLAP_INP_DETL_WORKING]
GO

CREATE TABLE [dbo].[X2_AOPUTLAP_INP_DETL_WORKING] (
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[UNIQUE_RECORD_NUM] [int] NOT NULL ,
	[GROUPING_CLAUSE] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MAJOR] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SOURCE] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DOC_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REC_NO] [int] IDENTITY (1, 1) NOT NULL ,
	[S_STATUS_CD] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VCHR_NO] [int] NULL ,
	[FY_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VCHR_LN_NO] [smallint] NULL ,
	[ACCT_ID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ORG_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REF1_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REF2_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CST_AMT] [decimal](14, 2) NULL ,
	[TAXABLE_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[S_TAXABLE_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SALES_TAX_AMT] [decimal](14, 2) NULL ,
	[DISC_AMT] [decimal](14, 2) NULL ,
	[USE_TAX_AMT] [decimal](14, 2) NULL ,
	[AP_1099_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[S_AP_1099_TYPE_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VCHR_LN_DESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ORG_ABBRV_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ABBRV_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ACCT_ABBRV_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[NOTES] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TIME_STAMP] [datetime] NULL 
) ON [PRIMARY]
GO



/****** Object:  Table [dbo].[AOPUTLAP_INP_DETL_ERRORS]    Script Date: 06/20/2006 3:26:54 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AOPUTLAP_INP_DETL_ERRORS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[AOPUTLAP_INP_DETL_ERRORS]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AOPUTLAP_INP_DETL_ERRORS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[AOPUTLAP_INP_DETL_ERRORS] (
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[ERROR_SEQUENCE_NO] [int] NOT NULL ,
	[FEEDBACK] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REC_NO] [int] NOT NULL ,
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
END

GO



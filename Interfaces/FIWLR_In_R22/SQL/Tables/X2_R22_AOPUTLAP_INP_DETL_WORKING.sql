USE [IMAPSStg]
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[X2_R22_AOPUTLAP_INP_DETL_WORKING]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[X2_R22_AOPUTLAP_INP_DETL_WORKING]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[X2_R22_AOPUTLAP_INP_DETL_WORKING]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[X2_R22_AOPUTLAP_INP_DETL_WORKING](
	[STATUS_RECORD_NUM] [int] NOT NULL,
	[UNIQUE_RECORD_NUM] [int] NOT NULL,
	[GROUPING_CLAUSE] [varchar](254) NULL,
	[MAJOR] [char](3) NULL,
	[SOURCE] [char](3) NULL,
	[DOC_NO] [varchar](20) NULL,
	[REC_NO] [int] IDENTITY(1,1) NOT NULL,
	[S_STATUS_CD] [varchar](1) NULL,
	[VCHR_NO] [int] NULL,
	[FY_CD] [varchar](6) NOT NULL,
	[VCHR_LN_NO] [smallint] NULL,
	[ACCT_ID] [varchar](15) NULL,
	[ORG_ID] [varchar](20) NULL,
	[PROJ_ID] [varchar](30) NULL,
	[REF1_ID] [varchar](20) NULL,
	[REF2_ID] [varchar](20) NULL,
	[CST_AMT] [decimal](14, 2) NULL,
	[TAXABLE_FL] [varchar](1) NULL,
	[S_TAXABLE_CD] [varchar](6) NULL,
	[SALES_TAX_AMT] [decimal](14, 2) NULL,
	[DISC_AMT] [decimal](14, 2) NULL,
	[USE_TAX_AMT] [decimal](14, 2) NULL,
	[AP_1099_FL] [varchar](1) NULL,
	[S_AP_1099_TYPE_CD] [varchar](6) NULL,
	[VCHR_LN_DESC] [varchar](30) NULL,
	[ORG_ABBRV_CD] [varchar](6) NULL,
	[PROJ_ABBRV_CD] [varchar](6) NULL,
	[PROJ_ACCT_ABBRV_CD] [varchar](6) NULL,
	[NOTES] [varchar](254) NULL,
	[TIME_STAMP] [datetime] NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
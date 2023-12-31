USE [IMAPSStg]
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[X2_R22_AOPUTLAP_INP_HDR_WORKING]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[X2_R22_AOPUTLAP_INP_HDR_WORKING]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[X2_R22_AOPUTLAP_INP_HDR_WORKING]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[X2_R22_AOPUTLAP_INP_HDR_WORKING](
	[STATUS_RECORD_NUM] [int] NOT NULL,
	[GROUPING_CLAUSE] [varchar](254) NULL,
	[REC_NO] [int] IDENTITY(1,1) NOT NULL,
	[S_STATUS_CD] [varchar](1) NULL,
	[VCHR_NO] [int] NULL,
	[FY_CD] [varchar](6) NOT NULL,
	[PD_NO] [smallint] NULL,
	[SUB_PD_NO] [smallint] NULL,
	[VEND_ID] [varchar](12) NULL,
	[TERMS_DC] [varchar](15) NULL,
	[INVC_ID] [varchar](15) NULL,
	[INVC_DT] [varchar](10) NULL,
	[INVC_AMT] [decimal](14, 2) NULL,
	[DISC_DT] [varchar](10) NULL,
	[DISC_PCT_RT] [decimal](5, 2) NULL,
	[DISC_AMT] [decimal](14, 2) NULL,
	[DUE_DT] [varchar](10) NULL,
	[HOLD_VCHR_FL] [varchar](1) NULL,
	[PAY_WHEN_PAID_FL] [varchar](1) NULL,
	[PAY_VEND_ID] [varchar](12) NULL,
	[PAY_ADDR_DC] [varchar](10) NULL,
	[PO_ID] [varchar](10) NULL,
	[PO_RLSE_NO] [smallint] NULL,
	[RTN_RATE] [decimal](5, 2) NULL,
	[AP_ACCT_DESC] [varchar](30) NULL,
	[CASH_ACCT_DESC] [varchar](30) NULL,
	[S_INVC_TYPE] [varchar](1) NULL,
	[SHIP_AMT] [decimal](14, 2) NULL,
	[CHK_FY_CD] [varchar](6) NULL,
	[CHK_PD_NO] [smallint] NULL,
	[CHK_SUB_PD_NO] [smallint] NULL,
	[CHK_NO] [int] NULL,
	[CHK_DT] [varchar](10) NULL,
	[CHK_AMT] [decimal](14, 2) NULL,
	[DISC_TAKEN_AMT] [decimal](14, 2) NULL,
	[INVC_POP_DT] [varchar](10) NULL,
	[PRINT_NOTE_FL] [varchar](1) NULL,
	[JNT_PAY_VEND_NAME] [varchar](40) NULL,
	[NOTES] [varchar](254) NULL,
	[TIME_STAMP] [datetime] NULL,
	[SEP_CHK_FL] [varchar](1) NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF



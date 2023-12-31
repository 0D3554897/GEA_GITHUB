USE [IMAPSStg]
GO
/****** Object:  Table [DELTEK].[OPEN_BILLING_DETL]    Script Date: 02/11/2008 11:58:03 ******/



IF EXISTS (SELECT name FROM sysobjects WHERE name = 'XX_OPEN_BILLING_DETL' AND type = 'U')
DROP TABLE XX_OPEN_BILLING_DETL

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[XX_OPEN_BILLING_DETL](
	[CREATED_DATE] [datetime] NOT NULL,
	[XX_TOBE_RESTORED_FL] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,	
	[XX_RESTORED_FL] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[RESTORED_DATE] [datetime] NULL,
	[SRCE_KEY] [smallint] NOT NULL,
	[LVL1_KEY] [int] NOT NULL,
	[LVL2_KEY] [int] NOT NULL,
	[LVL3_KEY] [int] NOT NULL,
	[TRN_PROJ_ID] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ACCT_ID] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ORG_ID] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[FY_CD] [varchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[PD_NO] [smallint] NOT NULL,
	[SUB_PD_NO] [smallint] NOT NULL,
	[S_TRN_TYPE] [varchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TRN_AMT] [decimal](14, 2) NOT NULL,
	[TRN_HRS] [decimal](14, 2) NOT NULL,
	[TRN_QTY] [decimal](14, 4) NOT NULL,
	[BILL_AMT] [decimal](14, 2) NOT NULL,
	[BILL_HRS] [decimal](14, 2) NOT NULL,
	[BILL_QTY] [decimal](14, 4) NOT NULL,
	[WRITE_OFF_AMT] [decimal](14, 2) NOT NULL,
	[WRITE_OFF_HRS] [decimal](14, 2) NOT NULL,
	[WRITE_OFF_QTY] [decimal](14, 4) NOT NULL,
	[HOLD_AMT] [decimal](14, 2) NOT NULL,
	[HOLD_HRS] [decimal](14, 2) NOT NULL,
	[HOLD_QTY] [decimal](14, 4) NOT NULL,
	[PREV_BILLED_AMT] [decimal](14, 2) NOT NULL,
	[PREV_BILLED_HRS] [decimal](14, 2) NOT NULL,
	[PREV_BILLED_QTY] [decimal](14, 4) NOT NULL,
	[S_ID_TYPE] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ID] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[NAME] [varchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BILL_LAB_CAT_CD] [varchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[BILL_LAB_CAT_DESC] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ITEM_ID] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ITEM_RVSN_ID] [varchar](3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ITEM_DESC] [varchar](60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ITEM_NT] [varchar](254) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TRN_DESC] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[VCHR_NO] [int] NULL,
	[VCHR_KEY] [int] NULL,
	[JE_NO] [int] NULL,
	[REF1_ID] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[REF2_ID] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AP_INVC_ID] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[COMMENTS] [varchar](254) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TS_DT] [smalldatetime] NULL,
	[S_JNL_CD] [varchar](3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[POST_SEQ_NO] [int] NULL,
	[CASH_BASIS_DOL_AMT] [decimal](14, 2) NOT NULL,
	[S_SOURCE_CD] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[WRITE_OFF_DESC] [varchar](60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[HOLD_REASON_DESC] [varchar](60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[GENL_LAB_CAT_CD] [varchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[GENL_LAB_CAT_DESC] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[MODIFIED_BY] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TIME_STAMP] [datetime] NOT NULL,
	[CLIN_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CASH_RECPT_NO] [int] NULL,
	[UNITS_USAGE_DT] [smalldatetime] NULL,
	[SALES_TAX_CD] [varchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[S_PRICE_SRCE_CD] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SRCE_PROJ_ID] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PRICE_CATLG_CD] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ITEM_KEY] [int] NULL,
	[BILL_RT_AMT] [decimal](10, 4) NULL,
	[S_BILL_RT_TYPE_CD] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MU_BILL_RT_AMT] [decimal](10, 4) NULL,
	[ROWVERSION] [int] NULL,
	[COMPANY_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ORIG_BILL_RT_AMT] [decimal](14, 4) NOT NULL CONSTRAINT [OPEN_BILLING_DETL_ORIG_BILL_RT_AMT]  DEFAULT ((0)),
	[CASH_BASIS_HRS] [decimal](14, 2) NOT NULL CONSTRAINT [OPEN_BILLING_DETL_CASH_BASIS_HRS]  DEFAULT ((0))
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
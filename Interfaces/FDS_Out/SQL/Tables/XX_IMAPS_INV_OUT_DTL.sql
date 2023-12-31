/****** Object:  Table [dbo].[XX_IMAPS_INV_OUT_DTL]    Script Date: 10/04/2006 9:32:14 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_IMAPS_INV_OUT_DTL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_IMAPS_INV_OUT_DTL]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_IMAPS_INV_OUT_DTL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_IMAPS_INV_OUT_DTL] (
	[CUST_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PROJ_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PROJ_ABBRV_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[INVC_ID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[INVC_DT] [smalldatetime] NOT NULL ,
	[INVC_LN] [int] IDENTITY (1, 1) NOT NULL ,
	[CLIN_ID] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ACCT_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TRN_DESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TS_DT] [smalldatetime] NULL ,
	[BILL_RT_AMT] [decimal](10, 4) NULL ,
	[BILLED_HRS] [decimal](14, 2) NULL ,
	[RI_BILLABLE_CHG_CD] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[I_MACH_TYPE] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[M_PRODUCT_CODE] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[BILLED_AMT] [decimal](14, 2) NOT NULL ,
	[RTNGE_AMT] [decimal](14, 2) NOT NULL CONSTRAINT [DF__XX_IMAPS___RTNGE__382F5661] DEFAULT (0),
	[ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[NAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[BILL_LAB_CAT_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[BILL_LAB_CAT_DESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[BILL_FM_GRP_NO] [smallint] NOT NULL ,
	[BILL_FM_GRP_LBL] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[BILL_FM_LN_NO] [smallint] NOT NULL ,
	[BILL_FM_LN_LBL] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CUM_BILLED_HRS] [decimal](14, 2) NULL ,
	[CUM_BILLED_AMT] [decimal](14, 2) NULL ,
	[TC_AGRMNT] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TC_PROD_CATGRY] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TC_TAX] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TA_BASIC] [decimal](14, 2) NOT NULL ,
	[RF_GSA_INDICATOR] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SALES_TAX_AMT] [decimal](14, 2) NOT NULL ,
	[STATE_SALES_TAX_AMT] [decimal](14, 2) NOT NULL ,
	[COUNTY_SALES_TAX_AMT] [decimal](14, 2) NOT NULL ,
	[CITY_SALES_TAX_AMT] [decimal](14, 2) NOT NULL ,
	[SALES_TAX_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	 PRIMARY KEY  CLUSTERED 
	(
		[INVC_LN]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [FK_XX_IMAPS_INV_OUT_DTL] FOREIGN KEY 
	(
		[INVC_ID]
	) REFERENCES [dbo].[XX_IMAPS_INV_OUT_SUM] (
		[INVC_ID]
	)
) ON [PRIMARY]
END

GO



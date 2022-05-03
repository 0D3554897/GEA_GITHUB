USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_CLS_DOWN_THIS_MONTH_YTD]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_R22_CLS_DOWN_THIS_MONTH_YTD]
GO

CREATE TABLE [dbo].[XX_R22_CLS_DOWN_THIS_MONTH_YTD](
	[CLS_MAJOR]         [varchar](3) NULL,
	[CLS_MINOR]         [varchar](4) NULL,
	[CLS_SUB_MINOR]     [varchar](4) NULL,
	[IMAPS_ACCT]        [varchar](10) NULL,
	[IMAPS_PROJ_ID]     [varchar](30) NULL,
	[L1_PROJ_SEG_ID]    [varchar](30) NULL,
	[IMAPS_ORG_ID]      [varchar](20) NULL,
	[DIVISION]          [varchar](15) NULL,
	[LERU_NUM]          [varchar](6) NULL,
	[DOLLAR_AMT]        [decimal](14, 2) NULL,
	[GA_AMT]            [decimal](14, 2) NULL,
	[OVERHEAD_AMT]      [decimal](14, 2) NULL,
	[CONTRACT_NUM]      [varchar](30) NULL,
	[IGS_PROJ]          [varchar](7) NULL,
	[SERVICE_OFFERING]  [varchar](5) NULL,
	[CUSTOMER_NUM]      [varchar](10) NULL,
	[MACHINE_TYPE_CD]   [varchar](4) NULL,
	[PRODUCT_ID]        [varchar](12) NULL,
	[DESCRIPTION2]      [varchar](30) NULL,
	[BUSINESS_AREA]     [varchar](2) NULL,
	[MARKETING_AREA]    [varchar](2) NULL,
	[MARKETING_OFFICE]  [char](3) NULL,
	[CONSOLIDATED_REV_BRANCH_OFFICE] [char](3) NULL,
	[INDUSTRY]          [char](4) NULL,
	[ENTERPRISE_NUM_CD] [varchar](7) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

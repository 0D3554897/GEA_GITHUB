USE [IMAPSStg]
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[XX_R22_FIWLR_USDET_TEMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_R22_FIWLR_USDET_TEMP]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_USDET_TEMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_R22_FIWLR_USDET_TEMP](
	[IDENT_REC_NO] [int] NULL,
	[STATUS_REC_NO] [int] NOT NULL,
	[STREAM_ID] [varchar](2) NOT NULL,
	[LEDGER_TYPE] [varchar](1) NOT NULL,
	[MAJOR] [varchar](3) NOT NULL,
	[MINOR] [varchar](4) NOT NULL,
	[SUBMINOR] [varchar](4) NOT NULL,
	[ANALYSIS_CODE] [varchar](6) NULL,
	[DIVISION] [varchar](2) NULL,
	[EXTRACT_DATE] [varchar](50) NULL,
	[FIWLR_INV_DATE] [varchar](50) NULL,
	[VOUCHER_NO] [varchar](13) NULL,
	[VOUCHER_GRP_NO] [varchar](7) NULL,
	[WWER_EXP_KEY] [varchar](5) NULL,
	[WWER_EXP_DT] [varchar](10) NULL,
	[SOURCE] [varchar](3) NOT NULL,
	[ACCT_MONTH] [varchar](2) NULL,
	[ACCT_YEAR] [varchar](4) NULL,
	[AP_IDX] [varchar](10) NULL,
	[PROJECT_NO] [varchar](7) NULL,
	[DESCRIPTION1] [varchar](30) NULL,
	[DESCRIPTION2] [varchar](30) NULL,
	[DEPARTMENT] [varchar](3) NULL,
	[ACCOUNTANT_ID] [varchar](8) NULL,
	[PO_NO] [varchar](10) NULL,
	[INV_NO] [varchar](12) NULL,
	[ETV_CODE] [varchar](6) NULL,
	[COUNTRY_CODE] [varchar](3) NULL,
	[VENDOR_ID] [varchar](11) NULL,
	[EMPLOYEE_NO] [varchar](6) NULL,
	[AMOUNT] [decimal](15, 2) NULL,
	[INPUT_TYPE] [varchar](1) NULL,
	[AP_DOC_TYPE] [varchar](2) NULL,
	[REF_CREATION_DATE] [varchar](8) NULL,
	[REF_CREATION_TIME] [varchar](9) NULL,
	[CREATION_DATE] [datetime] NOT NULL CONSTRAINT [NN_XX_R22_FIWLR_USDET_TEMP_CDATE]  DEFAULT (getdate()),
	[SOURCE_GROUP] [varchar](10) NULL,
	[VEND_NAME] [varchar](30) NULL,
	[EMP_LASTNAME] [varchar](30) NULL,
	[EMP_FIRSTNAME] [varchar](30) NULL,
	[PROJ_ID] [varchar](30) NULL,
	[PROJ_ABBR_CD] [varchar](10) NULL,
	[ORG_ID] [varchar](30) NULL,
	[ORG_ABBR_CD] [varchar](10) NULL,
	[PAG_CD] [varchar](10) NULL,
	[VAL_NVAL_CD] [varchar](10) NULL,
	[ACCT_ID] [varchar](15) NULL,
	[ORDER_REF] [varchar](8) NULL,
	[PROJ] [varchar](3) NULL,
	[HOURS] [decimal](15, 2) NULL,
	[CP_HDR_NO] [int] NULL,
	[CP_LN_NO] [int] NULL,
	[FY_CD] [varchar](6) NULL,
	[PD_NO] [smallint] NULL,
	[SUB_PD_NO] [smallint] NULL,
	[REFERENCE1] [varchar](125) NULL,
	[REFERENCE2] [varchar](125) NULL,
	[REFERENCE3] [varchar](125) NULL,
	[REFERENCE4] [varchar](125) NULL,
	[REFERENCE5] [varchar](125) NULL
) ON [PRIMARY]

END
GO
SET ANSI_PADDING OFF

CREATE  INDEX [IX_FIWLR_R22_USDET_TEMP_STATUS] 
ON [dbo].[XX_R22_FIWLR_USDET_TEMP]([STATUS_REC_NO], [SOURCE_GROUP]) 
WITH  FILLFACTOR = 90 ON [PRIMARY]
GO


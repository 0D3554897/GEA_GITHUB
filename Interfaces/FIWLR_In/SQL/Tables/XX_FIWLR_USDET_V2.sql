if exists (select * from dbo.sysobjects where id = object_id(N'[XX_FIWLR_USDET_V2]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_FIWLR_USDET_V2]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_USDET_V2]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_FIWLR_USDET_V2] (
	[STATUS_REC_NO] [int] NOT NULL ,
	[STREAM_ID] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LEDGER_TYPE] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MAJOR] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MINOR] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[SUBMINOR] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ANALYSIS_CODE] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DIVISION] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXTRACT_DATE] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FIWLR_INV_DATE] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VOUCHER_NO] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VOUCHER_GRP_NO] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[WWER_EXP_KEY] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[WWER_EXP_DT] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SOURCE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ACCT_MONTH] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ACCT_YEAR] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AP_IDX] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJECT_NO] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DESCRIPTION1] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DESCRIPTION2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DEPARTMENT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ACCOUNTANT_ID] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PO_NO] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[INV_NO] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ETV_CODE] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[COUNTRY_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VENDOR_ID] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EMPLOYEE_NO] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AMOUNT] [decimal](15, 2) NULL ,
	[INPUT_TYPE] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AP_DOC_TYPE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REF_CREATION_DATE] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REF_CREATION_TIME] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CREATION_DATE] [datetime] NOT NULL CONSTRAINT [NN_XX_FIWLR_USDETV2_CDATE] DEFAULT (getdate()),
	[SOURCE_GROUP] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VEND_NAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EMP_LASTNAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EMP_FIRSTNAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ABBR_CD] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ORG_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ORG_ABBR_CD] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PAG_CD] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VAL_NVAL_CD] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ACCT_ID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[REFERENCE1] [varchar] (125) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REFERENCE2] [varchar] (125) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REFERENCE3] [varchar] (125) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REFERENCE4] [varchar] (125) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REFERENCE5] [varchar] (125) COLLATE SQL_Latin1_General_CP1_CI_AS NULL  
) ON [PRIMARY]
END

GO


CREATE  INDEX [fiwlr_v2_srecno_ix] 
ON [dbo].[XX_FIWLR_USDET_V2]([STATUS_REC_NO]) 
WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

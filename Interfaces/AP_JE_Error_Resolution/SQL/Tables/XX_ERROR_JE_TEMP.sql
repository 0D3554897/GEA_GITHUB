/****** Object:  Table [dbo].[XX_ERROR_JE_TEMP]    Script Date: 08/23/2006 11:33:39 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_ERROR_JE_TEMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_ERROR_JE_TEMP]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_ERROR_JE_TEMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_ERROR_JE_TEMP] (
	[INP_JE_NO] [int] NOT NULL ,
	[JE_LN_NO] [int] NOT NULL ,
	[TRN_AMT] [decimal](14, 2) NULL ,
	[ACCT_ID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ORG_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ABBRV_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJECT_NO] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PAG] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MAJOR] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MINOR] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SUB_MINOR] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SOURCE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ANALYSIS_CODE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DEPT] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VCHR_NO] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ACCOUNTANT_ID] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AP_IDX] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FEEDBACK] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[ERROR_SEQUENCE_NO] [int] NOT NULL ,
	[REC_NO] [int] NOT NULL 
) ON [PRIMARY]
END

GO



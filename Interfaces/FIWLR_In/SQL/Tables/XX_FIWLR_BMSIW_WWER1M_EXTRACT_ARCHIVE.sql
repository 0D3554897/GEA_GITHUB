USE [IMAPSStg]
GO
/****** Object:  Table [dbo].[XX_FIWLR_BMSIW_WWER1M_EXTRACT_ARCHIVE]    Script Date: 07/11/2009 07:50:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_BMSIW_WWER1M_EXTRACT_ARCHIVE]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_FIWLR_BMSIW_WWER1M_EXTRACT_ARCHIVE]
GO



CREATE TABLE [dbo].[XX_FIWLR_BMSIW_WWER1M_EXTRACT_ARCHIVE](
	[RPT_KEY] [nvarchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EXP_KEY] [decimal](5, 0) NOT NULL,
	[ACCOUNT_ID] [nvarchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CHRG_AMT] [decimal](15, 2) NOT NULL,
	[CHRG_CRNCY_CD] [nvarchar](3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CHRG_MIN_NUM] [nvarchar](4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CHRG_SUBMIN_NUM] [nvarchar](4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CONTROL_COUNTRY_CD] [nvarchar](3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CONTROL_GROUP_CD] [nvarchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EXP_CD] [nvarchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EXP_CHRG_DT] [datetime] NOT NULL,
	[EXP_CHRG_NM] [nvarchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EXP_BEGIN_DT] [datetime] NULL,
	[EXP_EFFECTIVE_DT] [datetime] NOT NULL,
	[EXP_END_DT] [datetime] NULL,
	[CREATED_TMS] [nvarchar](26) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CHRG_COUNTRY_CD] [nvarchar](3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CHRG_DIV_CD] [nvarchar](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CHRG_FINDPT_ID] [nvarchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CHRG_LEDGER_CD] [nvarchar](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CHRG_MAJ_NUM] [nvarchar](3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CNUM_ID] [nvarchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EMP_LAST_NM] [nvarchar](40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EMP_INITS_NM] [nvarchar](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EMP_SER_NUM] [nvarchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EXP_WEEK_END_DT] [datetime] NOT NULL,
	[INVOICE_TXT] [nvarchar](200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[PROCESSED_DT] [datetime] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF



/****** Object:  Index Status_record_line_number on Table [dbo].[XX_FIWLR_BMSIW_WWER1M_EXTRACT_ARCHIVE]    Script Date: 6/22/2007 12:27:44 PM ******/
if exists (select * from dbo.sysindexes where name = N'WWER_keys' and id = object_id(N'[dbo].[XX_FIWLR_BMSIW_WWER1M_EXTRACT_ARCHIVE]'))
drop index [dbo].[XX_FIWLR_BMSIW_WWER1M_EXTRACT_ARCHIVE].[WWER_keys]
GO

 CREATE  UNIQUE  CLUSTERED  INDEX [WWER_keys] ON [dbo].[XX_FIWLR_BMSIW_WWER1M_EXTRACT_ARCHIVE]([RPT_KEY], [EXP_KEY]) WITH  FILLFACTOR = 80 ON [PRIMARY]
GO

/****** Object:  Table [dbo].[XX_UTIL_LAB_OUT_ARCH]    Script Date: 07/24/2006 11:13:56 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_UTIL_LAB_OUT_ARCH]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_UTIL_LAB_OUT_ARCH]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_UTIL_LAB_OUT_ARCH]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_UTIL_LAB_OUT_ARCH] (
	[UTIL_LAB_RECORD_NUM] [int] IDENTITY (1, 1) NOT NULL ,
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[TS_LN_KEY] [int] NOT NULL ,
	[EMPL_ID] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LAST_FIRST_NAME] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EMPL_HOME_ORG_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[EMPL_HOME_ORG_NAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CONTRACT_ID] [char] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CONTRACT_NAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ABBRV_CD] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PROJ_NAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[INDUSTRY] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[KEY_ACCOUNT] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[HR_TYPE] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TS_DT] [datetime] NOT NULL ,
	[POSTING_DT] [datetime] NULL ,
	[ENTERED_HRS] [decimal](14, 2) NOT NULL ,
	[PERIOD_END_DT] [datetime] NOT NULL ,
	[ACCT_STATUS] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CONTACT_NAME] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PRIME_CONTR_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CUSTOMER_NO] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SOW_TYP_CD] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OWNING_DIV_CD] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OWNING_COUNTRY_CD] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OWNING_COMPANY_CD] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ACCT_TYP_CD] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OWNING_LOB_CD] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CTRY_CD] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CMPNY_CD] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ACCOUNT_ID] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PM_EMPL_ID] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ACCTGRP_ID] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_XX_UTIL_LAB_OUT_ARCH] PRIMARY KEY  CLUSTERED 
	(
		[UTIL_LAB_RECORD_NUM],
		[STATUS_RECORD_NUM]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [FK_XX_UTIL_LAB_OUT_ARCH_XX_IMAPS_INT_STATUS] FOREIGN KEY 
	(
		[STATUS_RECORD_NUM]
	) REFERENCES [dbo].[XX_IMAPS_INT_STATUS] (
		[STATUS_RECORD_NUM]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
) ON [PRIMARY]
END

GO



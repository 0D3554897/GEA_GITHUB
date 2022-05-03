USE [IMAPSStg]
GO
/****** Object:  Table [dbo].[XX_PAY_TYPE_ACCT_MAP]    Script Date: 05/20/2008 10:47:35 ******/

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PAY_TYPE_ACCT_MAP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_PAY_TYPE_ACCT_MAP]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[XX_PAY_TYPE_ACCT_MAP](
	[PAY_TYPE] [varchar](3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ACCT_GRP_CD] [varchar](3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[LAB_GRP_TYPE] [varchar](3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[REG_ACCT_ID] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[STB_ACCT_ID] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[REG_ACCT_NAME] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[STB_ACCT_NAME] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[COMPANY_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CREATED_BY] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TIME_STAMP] [datetime] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF


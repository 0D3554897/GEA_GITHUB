-- Reference ClearQuest Record No. CP600000413
-- Reference BP&S Service Request No. CR1639

USE [IMAPSStg]
GO
/****** Object:  Table [dbo].[XX_PCLAIM_PAY_TYPE_ACCT_MAP]    Script Date: 08/05/2008 13:06:52 ******/

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PCLAIM_PAY_TYPE_ACCT_MAP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   drop table [dbo].[XX_PCLAIM_PAY_TYPE_ACCT_MAP]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[XX_PCLAIM_PAY_TYPE_ACCT_MAP](
	[PAY_TYPE]      [varchar](3) NOT NULL,
	[REG_ACCT_ID]   [varchar](15) NULL,
	[REG_ACCT_NAME] [varchar](25) NULL,
	[STB_ACCT_ID]   [varchar](15) NULL,
	[STB_ACCT_NAME] [varchar](25) NULL,
	[COMPANY_ID]    [varchar](10) NOT NULL,
	[CREATED_BY]    [varchar](20) NOT NULL DEFAULT (suser_sname()),
	[TIME_STAMP]    [datetime] NOT NULL DEFAULT (getdate())
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF

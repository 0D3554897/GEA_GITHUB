USE [IMAPSStg]
GO
/****** Object:  Table [dbo].[XX_FIWLR_WWERN16_DOU]    Script Date: 07/11/2009 15:55:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_WWERN16_DOU]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_FIWLR_WWERN16_DOU]
GO


CREATE TABLE [dbo].[XX_FIWLR_WWERN16_DOU](
	[ACCOUNT_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CONTROL_GROUP_CD] [varchar](5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[JDE_PROJ_CODE] [varchar](4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
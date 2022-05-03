USE [IMAPSStg]
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_VEND_V]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_R22_FIWLR_VEND_V]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_VEND_V]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_R22_FIWLR_VEND_V](
	[VENDOR_ID] [varchar](10) NULL,
	[VEND_NAME] [varchar](30) NULL,
	[CREATION_DATE] [datetime] NOT NULL CONSTRAINT [NN_XX_R22_FIWLR_VENDV_CDATE]  DEFAULT (getdate())
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
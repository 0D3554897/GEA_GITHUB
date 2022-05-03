USE [IMAPSStg]
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_APSRC_GRP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_R22_FIWLR_APSRC_GRP]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_APSRC_GRP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_R22_FIWLR_APSRC_GRP](
	[SRCCODE_ID] [int] IDENTITY(1,1) NOT NULL,
	[SOURCE] [varchar](3) NOT NULL,
	[DESCRIPTION] [varchar](50) NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
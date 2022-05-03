USE [IMAPSStg]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[XX_R22_FIWLR_LERU_MAP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_R22_FIWLR_LERU_MAP]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_LERU_MAP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN

CREATE TABLE [dbo].[XX_R22_FIWLR_LERU_MAP](
	[LERU] [varchar](10) NULL,
	[PROJ_ABBRV_CD] [varchar](15) NULL
) ON [PRIMARY]

END
GO
SET ANSI_PADDING OFF
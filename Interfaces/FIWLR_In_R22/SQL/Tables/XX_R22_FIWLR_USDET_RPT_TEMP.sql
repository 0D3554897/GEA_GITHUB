USE [IMAPSStg]
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[XX_R22_FIWLR_USDET_RPT_TEMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_R22_FIWLR_USDET_RPT_TEMP]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_USDET_RPT_TEMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_R22_FIWLR_USDET_RPT_TEMP](
	[STATUS_REC_NO] [varchar](10) NULL,
	[IDENT_REC_NO] [varchar](10) NULL,
	[SOURCE_GROUP] [char](2) NULL,
	[CP_LN_NOTES] [varchar](254) NULL,
	[CP_LN_DESC] [varchar](30) NULL,
	[CP_HDR_KEY] [varchar](10) NULL,
	[CP_HDR_NO] [varchar](10) NULL,
	[CP_LN_NO] [varchar](10) NULL,
	[FY_CD] [varchar](6) NULL,
	[PD_NO] [smallint] NULL,
	[SUB_PD_NO] [smallint] NULL
) ON [PRIMARY]

END
GO
SET ANSI_PADDING OFF
USE [IMAPSStg]
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_RUNDATE_ACCTCAL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_R22_FIWLR_RUNDATE_ACCTCAL]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_RUNDATE_ACCTCAL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_R22_FIWLR_RUNDATE_ACCTCAL](
	[fiscal_year] [int] NOT NULL,
	[period] [int] NOT NULL,
	[sub_pd_no] [int] NOT NULL,
	[run_start_date] [varchar](10) NOT NULL,
	[run_end_date] [varchar](10) NOT NULL,
	[reference1] [varchar](125) NULL,
	[reference2] [varchar](125) NULL,
	[reference3] [varchar](125) NULL,
	[reference4] [varchar](125) NULL,
	[reference5] [varchar](125) NULL,
	[creation_date] [datetime] NULL,
	[created_by] [varchar](30) NULL
) ON [PRIMARY]

END
GO
SET ANSI_PADDING OFF
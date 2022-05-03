USE [IMAPSStg]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[XX_R22_FIWLR_VCHR_ACCT_MAP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_R22_FIWLR_VCHR_ACCT_MAP]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_VCHR_ACCT_MAP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN

CREATE TABLE [dbo].[XX_R22_FIWLR_VCHR_ACCT_MAP](
	[VCHR_START] [varchar](15) NULL,
	[MAJOR_1] [varchar](7) NULL,
	[MAJOR_2] [varchar](7) NULL,
	[MINOR_1] [varchar](15) NULL,
	[MINOR_2] [varchar](15) NULL,
	[SUB_MINOR_1] [varchar](4) NULL,
	[SUB_MINOR_2] [varchar](4) NULL,
	[ACCT_ID] [varchar](15) NULL,
	[creation_date] [smalldatetime] NULL,
	[created_by] [varchar](50) NULL
) ON [PRIMARY]

END
GO
SET ANSI_PADDING OFF
USE [IMAPSStg]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[XX_R22_CLS_IMAPS_ACCT_MAP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_R22_CLS_IMAPS_ACCT_MAP]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_CLS_IMAPS_ACCT_MAP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN

CREATE TABLE [dbo].[XX_R22_CLS_IMAPS_ACCT_MAP](
	[ACCT_ID] [varchar](15) NULL,
	[MAJOR_1] [varchar](7) NULL,
	[MAJOR_2] [varchar](7) NULL,
	[MINOR_1] [varchar](15) NULL,
	[MINOR_2] [varchar](15) NULL,
	[SUB_MINOR_1] [varchar](4) NULL,
	[SUB_MINOR_2] [varchar](4) NULL,
	[ANALYSIS_CD] [varchar](9) NULL,
	[ETV_CODE] [varchar](6) NULL,
	[PAG] [varchar](3) NULL,
	[VAL_NON_VAL_FL] [varchar](1) NULL,
	[INC_EXC_FL] [varchar](1) NULL,
	[ACCT_DESC] [varchar](30) NULL,
	[ANALYSIS_CD_DESC] [varchar](30) NULL,
	[REFERENCE_1] [varchar](20) NULL,
	[REFERENCE_2] [varchar](20) NULL,
	[DIVISION] [varchar](2) NULL,
	[creation_date] [smalldatetime] NULL,
	[created_by] [varchar](50) NULL
) ON [PRIMARY]

END
GO
SET ANSI_PADDING OFF
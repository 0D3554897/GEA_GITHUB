USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[XX_R22_CERIS_RETRO_TS](
	[EMPL_ID]           [varchar](6)     NOT NULL,
	[NEW_ORG_ID]        [varchar](20)    NULL,
	[NEW_EMPL_CLASS_CD] [varchar](6)     NULL,
	[NEW_HRLY_AMT]      [decimal](10, 4) NULL,
-- CR2350_Begin
	[NEW_EXMPT_FL]      [char] (1)       NULL,
-- CR2350_End
	[EFFECT_DT]         [smalldatetime]  NOT NULL,
	[END_DT]            [smalldatetime]  NOT NULL,
	[RETRO_TS_DT]       [smalldatetime]  NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
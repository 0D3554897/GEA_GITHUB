USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[XX_R22_CERIS_CP_EMPL_STG](
	[EMPL_ID] [varchar](6) NOT NULL,
	[ORIG_HIRE_DT] [datetime] NOT NULL,
	[ADJ_HIRE_DT] [datetime] NOT NULL,
	[TERM_DT] [datetime] NULL,
	[SPVSR_NAME] [varchar](25) NOT NULL,
	[LAST_NAME] [varchar](25) NOT NULL,
	[FIRST_NAME] [varchar](20) NOT NULL,
	[MID_NAME] [varchar](10) NOT NULL,
	[LAST_FIRST_NAME] [varchar](25) NOT NULL,
	[EMAIL_ID] [varchar](60) NOT NULL,
	[REFERENCE1] [varchar](125) NULL,
	[REFERENCE2] [varchar](125) NULL,
	[REFERENCE3] [varchar](125) NULL,
	[REFERENCE4] [varchar](125) NULL,
	[REFERENCE5] [varchar](125) NULL,
	[CREATION_DATE] [datetime] NOT NULL CONSTRAINT [DF__XX_R22_CE__CREAT__61516785]  DEFAULT (getdate()),
	[CREATED_BY] [varchar](35) NULL,
	[UPDATE_DATE] [datetime] NULL,
	[UPDATED_BY] [varchar](35) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
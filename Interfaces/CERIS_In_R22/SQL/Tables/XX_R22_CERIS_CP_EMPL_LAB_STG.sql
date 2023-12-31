USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[XX_R22_CERIS_CP_EMPL_LAB_STG](
	[EMPL_ID] [varchar](6) NOT NULL,
	[EFFECT_DT] [datetime] NOT NULL,
	[HRLY_AMT] [decimal](10, 4) NULL,
	[S_HRLY_SAL_CD] [varchar](1) NULL,
	[SAL_AMT] [decimal](10, 2) NULL,
	[ANNL_AMT] [decimal](10, 2) NULL,
	[EXMPT_FL] [char](1) NULL,
	[S_EMPL_TYPE_CD] [char](1) NULL,
	[EMPL_CLASS_CD] [varchar](12) NULL,
	[ORG_ID] [varchar](20) NULL,
	[SEC_ORG_ID] [varchar](20) NULL,
	[TITLE_DESC] [varchar](30) NULL,
	[LAB_GRP_TYPE] [varchar](3) NULL,
	[GENL_LAB_CAT_CD] [varchar](6) NULL,
	[REASON_DESC] [varchar](30) NULL,
	[WORK_YR_HRS_NO] [smallint] NULL,
	[REFERENCE1] [varchar](125) NULL,
	[REFERENCE2] [varchar](125) NULL,
	[REFERENCE3] [varchar](125) NULL,
	[REFERENCE4] [varchar](125) NULL,
	[REFERENCE5] [varchar](125) NULL,
	[CREATION_DATE] [datetime] NOT NULL CONSTRAINT [DF__XX_R22_CE__CREAT__6F357288]  DEFAULT (getdate()),
	[CREATED_BY] [varchar](35) NULL,
	[UPDATE_DATE] [datetime] NULL,
	[UPDATED_BY] [varchar](35) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
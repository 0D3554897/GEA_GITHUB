USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[XX_R22_CERIS_CP_STG](
	[EMPL_ID] [varchar](6) NOT NULL,
	[ORIG_HIRE_DT] [datetime] NOT NULL,
	[ADJ_HIRE_DT] [datetime] NOT NULL,
	[TERM_DT] [datetime] NULL,
	[SPVSR_NAME] [varchar](25) NOT NULL,
	[LAST_NAME] [varchar](25) NOT NULL,
	[FIRST_NAME] [varchar](20) NOT NULL,
	[MID_NAME] [varchar](10) NOT NULL,
	[EMAIL_ID] [varchar](60) NOT NULL,
	[JF_DT] [datetime] NOT NULL,
	[POS_DT] [datetime] NOT NULL,
	[DIVISION_START_DT] [datetime] NOT NULL,
	[DEPT_ST_DT] [datetime] NOT NULL,
	[EMPL_STAT_DT] [datetime] NOT NULL,
	[EMPL_STAT3_DT] [datetime] NULL,
	[LVL_DT_1] [datetime] NOT NULL,
	[DEPT_DT] [datetime] NOT NULL,
	[DEPT_SUF_DT] [datetime] NOT NULL,
	[EXEMPT_DT] [datetime] NOT NULL,
	[WORK_SCHD_DT] [datetime] NULL,
	[SALARY_DT] [datetime] NULL,
	[S_HRLY_SAL_CD] [varchar](1) NULL,
	[HRLY_AMT] [decimal](10, 4) NOT NULL,
	[SAL_AMT] [decimal](10, 2) NOT NULL,
	[ANNL_AMT] [decimal](10, 2) NOT NULL,
	[EXMPT_FL] [char](1) NOT NULL,
	[S_EMPL_TYPE_CD] [char](1) NOT NULL,
	[EMPL_CLASS_CD] [varchar](12) NOT NULL,
	[ORG_ID] [varchar](20) NOT NULL,
	[TITLE_DESC] [varchar](30) NOT NULL,
	[LAB_GRP_TYPE] [varchar](3) NOT NULL,
	[GENL_LAB_CAT_CD] [varchar](6) NOT NULL,
	[REASON_DESC] [varchar](30) NULL,
	[WORK_YR_HRS_NO] [smallint] NOT NULL,
	[REFERENCE1] [varchar](125) NULL,
	[REFERENCE2] [varchar](125) NULL,
	[REFERENCE3] [varchar](125) NULL,
	[REFERENCE4] [varchar](125) NULL,
	[REFERENCE5] [varchar](125) NULL,
	[CREATION_DATE] [datetime] NOT NULL CONSTRAINT [DF__XX_R22_CE__CREAT__6A70BD6B]  DEFAULT (getdate()),
	[CREATED_BY] [varchar](35) NULL,
	[UPDATE_DATE] [datetime] NULL,
	[UPDATED_BY] [varchar](35) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
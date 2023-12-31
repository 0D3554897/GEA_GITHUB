USE [IMAPSStg]
GO
IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_EMPL_LAB_INFO_PREVIOUS_VALUES]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_CERIS_EMPL_LAB_INFO_PREVIOUS_VALUES]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[XX_CERIS_EMPL_LAB_INFO_PREVIOUS_VALUES](

	[STATUS_RECORD_NUM] [int] NOT NULL,

	[EMPL_ID] [varchar](12) NOT NULL,
	[EFFECT_DT] [smalldatetime] NOT NULL,
	[S_HRLY_SAL_CD] [varchar](1) NOT NULL,
	[HRLY_AMT] [decimal](10, 4) NOT NULL,
	[SAL_AMT] [decimal](10, 2) NOT NULL,
	[ANNL_AMT] [decimal](10, 2) NOT NULL,
	[EXMPT_FL] [varchar](1) NOT NULL,
	[S_EMPL_TYPE_CD] [varchar](1) NOT NULL,
	[ORG_ID] [varchar](20) NOT NULL,
	[TITLE_DESC] [varchar](30) NOT NULL,
	[WORK_STATE_CD] [varchar](2) NULL,
	[STD_EST_HRS] [decimal](14, 2) NOT NULL,
	[STD_EFFECT_AMT] [decimal](10, 4) NOT NULL,
	[LAB_GRP_TYPE] [varchar](3) NULL,
	[GENL_LAB_CAT_CD] [varchar](6) NOT NULL,
	[MODIFIED_BY] [varchar](20) NOT NULL,
	[TIME_STAMP] [datetime] NOT NULL,
	[PCT_INCR_RT] [decimal](5, 4) NOT NULL,
	[HOME_REF1_ID] [varchar](20) NULL,
	[HOME_REF2_ID] [varchar](20) NULL,
	[REASON_DESC] [varchar](30) NOT NULL,
	[DETL_JOB_CD] [varchar](10) NULL,
	[PERS_ACT_RSN_CD] [varchar](10) NULL,
	[LAB_LOC_CD] [varchar](6) NULL,
	[MERIT_PCT_RT] [decimal](5, 4) NOT NULL,
	[PROMO_PCT_RT] [decimal](5, 4) NOT NULL,
	[COMP_PLAN_CD] [varchar](12) NULL,
	[SAL_GRADE_CD] [varchar](10) NULL,
	[S_STEP_NO] [smallint] NOT NULL,
	[REVIEW_FORM_ID] [varchar](12) NULL,
	[OVERALL_RT] [decimal](4, 2) NULL,
	[MGR_EMPL_ID] [varchar](12) NULL,
	[END_DT] [smalldatetime] NOT NULL,
	[SEC_ORG_ID] [varchar](20) NOT NULL,
	[COMMENTS] [varchar](254) NOT NULL,
	[EMPL_CLASS_CD] [varchar](12) NULL,
	[WORK_YR_HRS_NO] [smallint] NOT NULL,
	[BILL_LAB_CAT_CD] [varchar](6) NULL,
	[PERS_ACT_RSN_CD_2] [varchar](10) NULL,
	[PERS_ACT_RSN_CD_3] [varchar](10) NULL,
	[REASON_DESC_2] [varchar](30) NULL,
	[REASON_DESC_3] [varchar](30) NULL,
	[CORP_OFCR_FL] [varchar](1) NOT NULL,
	[SEASON_EMPL_FL] [varchar](1) NOT NULL,
	[HIRE_DT_FL] [varchar](1) NOT NULL,
	[TERM_DT_FL] [varchar](1) NOT NULL,
	[AFF_PLAN_CD] [varchar](12) NULL,
	[JOB_GROUP_CD] [varchar](10) NULL,
	[AA_COMMENTS] [varchar](254) NULL,
	[TC_TS_SCHED_CD] [varchar](10) NULL,
	[TC_WORK_SCHED_CD] [varchar](10) NULL,
	[ROWVERSION] [int] NULL,
	[HR_ORG_ID] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF


if exists (select * from dbo.sysobjects where id = object_id(N'[XX_CERIS_CP_STG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_CERIS_CP_STG]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_CP_STG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_CP_STG] (
	[EMPL_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ORIG_HIRE_DT] [datetime] NOT NULL ,
	[ADJ_HIRE_DT] [datetime] NOT NULL ,
	[TERM_DT] [datetime] NULL ,
	[SPVSR_NAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LAST_NAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FIRST_NAME] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MID_NAME] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[EMAIL_ID] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[JF_DT] [datetime] NOT NULL ,
	[POS_DT] [datetime] NOT NULL ,
	[DIVISION_START_DT] [datetime] NOT NULL ,
	[DEPT_ST_DT] [datetime] NOT NULL ,
	[EMPL_STAT_DT] [datetime] NOT NULL ,
	[EMPL_STAT3_DT] [datetime] NULL ,
	[LVL_DT_1] [datetime] NOT NULL ,
	[DEPT_DT] [datetime] NOT NULL ,
	[DEPT_SUF_DT] [datetime] NOT NULL ,
	[EXEMPT_DT] [datetime] NOT NULL ,
	[WORK_SCHD_DT] [datetime] NULL ,   -- change KM 12/22
	[HRLY_AMT] [decimal](10, 4) NOT NULL ,
	[SAL_AMT] [decimal](10, 2) NOT NULL ,
	[ANNL_AMT] [decimal](10, 2) NOT NULL ,
	[EXMPT_FL] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[S_EMPL_TYPE_CD] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ORG_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TITLE_DESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LAB_GRP_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[GENL_LAB_CAT_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[REASON_DESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[WORK_YR_HRS_NO] [smallint] NOT NULL 
) ON [PRIMARY]
END

GO



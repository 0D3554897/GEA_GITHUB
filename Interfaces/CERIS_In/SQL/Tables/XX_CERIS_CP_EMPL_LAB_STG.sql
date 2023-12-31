if exists (select * from dbo.sysobjects where id = object_id(N'[XX_CERIS_CP_EMPL_LAB_STG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_CERIS_CP_EMPL_LAB_STG]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_CP_EMPL_LAB_STG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_CP_EMPL_LAB_STG] (
	[EMPL_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[EFFECT_DT] [datetime] NOT NULL ,
	[HRLY_AMT] [decimal](10, 4) NULL ,
	[SAL_AMT] [decimal](10, 2) NULL ,
	[ANNL_AMT] [decimal](10, 2) NULL ,
	[EXMPT_FL] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[S_EMPL_TYPE_CD] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ORG_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SEC_ORG_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TITLE_DESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[LAB_GRP_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[GENL_LAB_CAT_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REASON_DESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[WORK_YR_HRS_NO] [smallint] NULL 
) ON [PRIMARY]
END

GO



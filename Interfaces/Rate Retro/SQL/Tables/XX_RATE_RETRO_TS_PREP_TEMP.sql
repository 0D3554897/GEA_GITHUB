/****** Object:  Table [dbo].[XX_RATE_RETRO_TS_PREP_TEMP]    Script Date: 1/3/2006 4:16:36 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_RATE_RETRO_TS_PREP_TEMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_RATE_RETRO_TS_PREP_TEMP]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_RATE_RETRO_TS_PREP_TEMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_RATE_RETRO_TS_PREP_TEMP] (
	[TS_DT] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EMPL_ID] [char] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[S_TS_TYPE_CD] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[WORK_STATE_CD] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FY_CD] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PD_NO] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SUB_PD_NO] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CORRECTING_REF_DT] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PAY_TYPE ] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[GENL_LAB_CAT_CD] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[S_TS_LN_TYPE_CD] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[LAB_CST_AMT] [char] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CHG_HRS] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[WORK_COMP_CD] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[LAB_LOC_CD] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ORG_ID] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ACCT_ID] [char] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ID] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[BILL_LAB_CAT_CD] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REF_STRUC_1_ID] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REF_STRUC_2_ID] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ORG_ABBRV_CD] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ABBRV_CD] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TS_HDR_SEQ_NO] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EFFECT_BILL_DT] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ACCT_ABBRV_CD] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[NOTES] [char] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
END

GO



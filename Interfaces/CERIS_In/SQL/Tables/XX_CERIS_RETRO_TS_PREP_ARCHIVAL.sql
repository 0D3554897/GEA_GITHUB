/****** Object:  Table [dbo].[XX_CERIS_RETRO_TS_PREP_ARCHIVAL]    Script Date: 03/08/2006 11:29:19 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_RETRO_TS_PREP_ARCHIVAL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CERIS_RETRO_TS_PREP_ARCHIVAL]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_RETRO_TS_PREP_ARCHIVAL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_RETRO_TS_PREP_ARCHIVAL] (
	[CERIS_RETRO_TS_PREP_REC_ARCH_NUM] [int] IDENTITY (1, 1) NOT NULL ,
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[TS_DT] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[EMPL_ID] [char] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[S_TS_TYPE_CD] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[WORK_STATE_CD] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FY_CD] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PD_NO] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[SUB_PD_NO] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
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
	[TS_HDR_SEQ_NO] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EFFECT_BILL_DT] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ACCT_ABBRV_CD] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[NOTES] [char] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TIME_STAMP] [datetime] NOT NULL ,
	CONSTRAINT [PK_XX_CERIS_RETRO_TS_PREP_ARCHIVAL] PRIMARY KEY  CLUSTERED 
	(
		[CERIS_RETRO_TS_PREP_REC_ARCH_NUM]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [FK_XX_CERIS_RETRO_TS_PREP_ARCHIVAL] FOREIGN KEY 
	(
		[STATUS_RECORD_NUM]
	) REFERENCES [dbo].[XX_IMAPS_INT_STATUS] (
		[STATUS_RECORD_NUM]
	)
) ON [PRIMARY]
END

GO



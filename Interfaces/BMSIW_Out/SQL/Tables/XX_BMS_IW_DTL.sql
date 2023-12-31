if exists (select * from dbo.sysobjects where id = object_id(N'[XX_BMS_IW_DTL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_BMS_IW_DTL]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_BMS_IW_DTL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_BMS_IW_DTL] (
	[RECORD_TYPE] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[EMP_SER_NUM] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CTRY_CD] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CMPNY_CD] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TOT_CLMED_HRS] [char] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ACCT_TYP_CD] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TRVL_INDICATOR] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CLM_WK_ENDING_DT] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[OVRTM_HRS_IND] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[OWNG_LOB_CD] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[OWNG_CNTRY_CD] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[OWNG_CMPNY_CD] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LBR_SYS_CD] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CHRG_ACCT_ID] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CHRG_ACTV_CD] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FILLER] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
END

GO



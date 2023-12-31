/****** Object:  Table [dbo].[AOPUTLJE_INP_TR_ERRORS]    Script Date: 06/20/2006 3:27:46 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AOPUTLJE_INP_TR_ERRORS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[AOPUTLJE_INP_TR_ERRORS]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AOPUTLJE_INP_TR_ERRORS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[AOPUTLJE_INP_TR_ERRORS] (
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[ERROR_SEQUENCE_NO] [int] NOT NULL ,
	[FEEDBACK] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REC_NO] [int] NOT NULL ,
	[S_STATUS_CD] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[JE_LN_NO] [smallint] NULL ,
	[INP_JE_NO] [int] NULL ,
	[S_JNL_CD] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FY_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PD_NO] [smallint] NOT NULL ,
	[SUB_PD_NO] [smallint] NULL ,
	[RVRS_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[JE_DESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TRN_AMT] [decimal](14, 2) NULL ,
	[ACCT_ID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ORG_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[JE_TRN_DESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REF_STRUC_1_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REF_STRUC_2_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CYCLE_DC] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ORG_ABBRV_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ABBRV_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ACCT_ABBRV_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UPDATE_OBD_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[NOTES] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TIME_STAMP] [datetime] NULL 
) ON [PRIMARY]
END

GO



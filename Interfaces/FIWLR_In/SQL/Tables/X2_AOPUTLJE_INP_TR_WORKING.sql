SET ANSI_PADDING ON
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[X2_AOPUTLJE_INP_TR_WORKING]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[X2_AOPUTLJE_INP_TR_WORKING]
GO

CREATE TABLE [dbo].[X2_AOPUTLJE_INP_TR_WORKING] (
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[UNIQUE_RECORD_NUM] [int] NOT NULL ,
	[GROUPING_CLAUSE] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MAJOR] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SOURCE] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DOC_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REC_NO] [int] IDENTITY (1, 1) NOT NULL ,
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
GO



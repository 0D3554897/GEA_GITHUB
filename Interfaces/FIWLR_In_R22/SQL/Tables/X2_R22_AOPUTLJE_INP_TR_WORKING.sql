USE [IMAPSStg]
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[X2_R22_AOPUTLJE_INP_TR_WORKING]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[X2_R22_AOPUTLJE_INP_TR_WORKING]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[X2_R22_AOPUTLJE_INP_TR_WORKING]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[X2_R22_AOPUTLJE_INP_TR_WORKING](
	[STATUS_RECORD_NUM] [int] NOT NULL,
	[UNIQUE_RECORD_NUM] [int] NOT NULL,
	[GROUPING_CLAUSE] [varchar](254) NULL,
	[MAJOR] [char](3) NULL,
	[SOURCE] [char](3) NULL,
	[DOC_NO] [varchar](20) NULL,
	[REC_NO] [int] IDENTITY(1,1) NOT NULL,
	[S_STATUS_CD] [varchar](1) NULL,
	[JE_LN_NO] [smallint] NULL,
	[INP_JE_NO] [int] NULL,
	[S_JNL_CD] [varchar](3) NOT NULL,
	[FY_CD] [varchar](6) NOT NULL,
	[PD_NO] [smallint] NOT NULL,
	[SUB_PD_NO] [smallint] NULL,
	[RVRS_FL] [varchar](1) NULL,
	[JE_DESC] [varchar](30) NULL,
	[TRN_AMT] [decimal](14, 2) NULL,
	[ACCT_ID] [varchar](15) NULL,
	[ORG_ID] [varchar](20) NULL,
	[JE_TRN_DESC] [varchar](30) NULL,
	[PROJ_ID] [varchar](30) NULL,
	[REF_STRUC_1_ID] [varchar](20) NULL,
	[REF_STRUC_2_ID] [varchar](20) NULL,
	[CYCLE_DC] [varchar](15) NULL,
	[ORG_ABBRV_CD] [varchar](6) NULL,
	[PROJ_ABBRV_CD] [varchar](6) NULL,
	[PROJ_ACCT_ABBRV_CD] [varchar](6) NULL,
	[UPDATE_OBD_FL] [varchar](1) NULL,
	[NOTES] [varchar](254) NULL,
	[TIME_STAMP] [datetime] NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
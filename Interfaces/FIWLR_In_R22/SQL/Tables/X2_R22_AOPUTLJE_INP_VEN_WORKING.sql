USE [IMAPSStg]
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[X2_R22_AOPUTLJE_INP_VEN_WORKING]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[X2_R22_AOPUTLJE_INP_VEN_WORKING]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[X2_R22_AOPUTLJE_INP_VEN_WORKING]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[X2_R22_AOPUTLJE_INP_VEN_WORKING](
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
	[VEND_SUBLN_NO] [smallint] NULL,
	[VEND_ID] [varchar](12) NULL,
	[GENL_LAB_CAT_CD] [varchar](6) NULL,
	[BILL_LAB_CAT_CD] [varchar](6) NULL,
	[LAB_HRS] [decimal](14, 2) NULL,
	[LAB_AMT] [decimal](14, 2) NULL,
	[VEND_EMPL_ID] [varchar](12) NULL,
	[EFFECT_BILL_DT_FLD] [varchar](10) NULL,
	[TIME_STAMP] [datetime] NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
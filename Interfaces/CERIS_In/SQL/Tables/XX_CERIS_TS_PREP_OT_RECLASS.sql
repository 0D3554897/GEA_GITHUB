USE [IMAPSStg]
GO

/****** Object:  Table [dbo].[XX_CERIS_TS_PREP_OT_RECLASS]    Script Date: 10/10/2012 10:56:51 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_TS_PREP_OT_RECLASS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_CERIS_TS_PREP_OT_RECLASS]
GO

CREATE TABLE [dbo].[XX_CERIS_TS_PREP_OT_RECLASS](
	[TS_DT] [char](10) NOT NULL,
	[EMPL_ID] [char](12) NOT NULL,
	[S_TS_TYPE_CD] [char](2) NOT NULL,
	[WORK_STATE_CD] [char](2) NOT NULL,
	[FY_CD] [char](6) NOT NULL,
	[PD_NO] [char](2) NOT NULL,
	[SUB_PD_NO] [char](2) NOT NULL,
	[CORRECTING_REF_DT] [char](10) NULL,
	[PAY_TYPE ] [char](3) NULL,
	[GENL_LAB_CAT_CD] [char](6) NULL,
	[S_TS_LN_TYPE_CD] [char](1) NULL,
	[LAB_CST_AMT] [char](15) NULL,
	[CHG_HRS] [char](10) NULL,
	[WORK_COMP_CD] [char](6) NULL,
	[LAB_LOC_CD] [char](6) NULL,
	[ORG_ID] [char](20) NULL,
	[ACCT_ID] [char](15) NULL,
	[PROJ_ID] [char](30) NULL,
	[BILL_LAB_CAT_CD] [char](6) NULL,
	[REF_STRUC_1_ID] [char](20) NULL,
	[REF_STRUC_2_ID] [char](20) NULL,
	[ORG_ABBRV_CD] [char](6) NULL,
	[PROJ_ABBRV_CD] [char](6) NULL,
	[TS_HDR_SEQ_NO] [char](3) NULL,
	[EFFECT_BILL_DT] [char](10) NULL,
	[PROJ_ACCT_ABBRV_CD] [char](6) NULL,
	[NOTES] [char](254) NULL,
	[REG_HRS] [decimal](14, 2) NULL,
	[OT_HRS] [decimal](14, 2) NULL,
	[REG_NOTES] [char](254) NULL,
	[OT_NOTES] [char](254) NULL,
	[STATE_CD] [varchar](2) NOT NULL,
	[S_OT_BASIS_CD] [varchar](1) NOT NULL,
	[EXMPT_HRS] [decimal](14, 2) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
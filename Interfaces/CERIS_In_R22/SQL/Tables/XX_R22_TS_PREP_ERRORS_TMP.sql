USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[XX_R22_TS_PREP_ERRORS_TMP](
	[TS_DT] [char](10) NOT NULL,
	[EMPL_ID] [char](6) NOT NULL,
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
	[NOTES] [char](254) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
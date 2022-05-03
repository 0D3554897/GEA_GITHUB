USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_CERIS_RPT_STG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_R22_CERIS_RPT_STG]
GO

CREATE TABLE [dbo].[XX_R22_CERIS_RPT_STG](
	[STATUS_RECORD_NUM] [int] NULL,
	[EMPL_ID] [varchar](6) NULL,
	[LNAME] [varchar](25) NOT NULL,
	[FNAME] [varchar](20) NOT NULL,
	[NAME_INITIALS] [varchar](5) NULL,
	[HIRE_EFF_DT] [varchar](8) NULL,
	[IBM_START_DT] [varchar](8) NULL,
	[TERM_DT] [varchar](8) NULL,
	[MGR_SERIAL_NUM] [varchar](8) NULL,
	[MGR_LNAME] [varchar](25) NOT NULL,
	[MGR_INITIALS] [varchar](5) NOT NULL,
	[JOB_FAM] [varchar](12) NULL,
	[JOB_FAM_DT] [varchar](8) NULL,
	[SAL_BAND] [varchar](2) NULL,
	[LVL_DT_1] [varchar](8) NULL,
	[DIVISION] [varchar](2) NULL,
	[DIVISION_START_DT] [varchar](8) NULL,
	[DEPT] [varchar](12) NULL,
	[DEPT_START_DT] [varchar](8) NULL,
	[DEPT_SUF_DT] [varchar](8) NULL,
	[FLSA_STAT] [varchar](3) NULL,
	[EXEMPT_DT] [varchar](8) NULL,
	[POS_CODE] [varchar](8) NULL,
	[POS_DESC] [varchar](30) NULL,
	[POS_DT] [varchar](8) NULL,
	[REG_TEMP] [char](1) NOT NULL,
	[STAT3] [varchar](1) NULL,
	[EMPL_STAT3_DT] [varchar](8) NULL,
	[STATUS] [varchar](8) NOT NULL,
	[EMPL_STAT_DT] [varchar](8) NULL,
	[STD_HRS] [int] NOT NULL,
	[WORK_SCHD_DT] [varchar](8) NULL,
	[LOA_BEG_DT] [varchar](8) NULL,
	[LOA_END_DT] [varchar](8) NULL,
	[LOA_TYPE] [varchar](3) NULL,
	[LVL_SUFFIX] [varchar](1) NULL,
	[DIVISION_FROM] [varchar](2) NULL,
	[WORK_OFF] [varchar](15) NULL,
	[CURR_DIV_FUNC_CODE] [varchar](2) NULL,
	[CURR_REP_LVL_CODE] [varchar](2) NULL,
	[PREV_DIV_FUNC_CODE] [varchar](2) NULL,
	[PREV_REP_LVL_CODE] [varchar](2) NULL,
	[MGR2_LNAME] [varchar](25) NULL,
	[MGR2_INITIALS] [varchar](5) NULL,
	[MGR3_LNAME] [varchar](25) NULL,
	[MGR3_INITIALS] [varchar](5) NULL,
	[HIRE_TYPE] [char](1) NULL,
	[HIRE_PRGM] [varchar](2) NULL,
	[SEPRSN] [varchar](2) NULL,
	[DEPT_FROM] [varchar](8) NULL,
	[VACELGD] [varchar](8) NULL,
	[CMPLN] [varchar](8) NULL,
	[BLDG_ID] [varchar](8) NULL,
	[DEPT_SHIFT_DT] [varchar](8) NULL,
	[DEPT_SHIFT_1] [char](1) NULL,
	[MGR_FLAG] [char](1) NULL,
	[SALARY_DT] [varchar](8) NULL,
	[ASTYP] [varchar](5) NULL,
	[ASNTYP] [varchar](5) NULL,
	[REFERENCE1] [varchar](125) NULL,
	[REFERENCE2] [varchar](125) NULL,
	[REFERENCE3] [varchar](125) NULL,
	[REFERENCE4] [varchar](125) NULL,
	[REFERENCE5] [varchar](125) NULL,
	[CREATION_DATE] [datetime] NOT NULL DEFAULT (getdate()),
	[CREATED_BY] [varchar](35) NULL,
	[UPDATE_DATE] [datetime] NULL,
	[UPDATED_BY] [varchar](35) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF

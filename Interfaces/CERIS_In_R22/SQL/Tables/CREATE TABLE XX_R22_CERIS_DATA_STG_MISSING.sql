USE [IMAPSStg]
GO

/****** Object:  Table [dbo].[XX_R22_CERIS_DATA_STG_MISSING]    Script Date: 04/07/2017 12:43:35 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_R22_CERIS_DATA_STG_MISSING]') AND type in (N'U'))
DROP TABLE [dbo].[XX_R22_CERIS_DATA_STG_MISSING]
GO

USE [IMAPSStg]
GO

/****** Object:  Table [dbo].[XX_R22_CERIS_DATA_STG_MISSING]    Script Date: 04/07/2017 12:43:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[XX_R22_CERIS_DATA_STG_MISSING](
	[R_EMPL_ID] [varbinary](256),
	[LNAME] [varchar](25),
	[FNAME] [varchar](20),
	[NAME_INITIALS] [varchar](8),
	[HIRE_EFF_DT] [varchar](8),
	[IBM_START_DT] [varchar](8),
	[TERM_DT] [varchar](8),
	[MGR_SERIAL_NUM] [varbinary](256),
	[MGR_LNAME] [varchar](25),
	[MGR_INITIALS] [varchar](8),
	[JOB_FAM] [varchar](12),
	[JOB_FAM_DT] [varchar](8),
	[SAL_BAND] [varchar](8),
	[LVL_DT_1] [varchar](8),
	[DIVISION] [varchar](8),
	[DIVISION_START_DT] [varchar](8),
	[DEPT] [varchar](12),
	[DEPT_START_DT] [varchar](8),
	[DEPT_SUF_DT] [varchar](8),
	[FLSA_STAT] [varchar](8),
	[EXEMPT_DT] [varchar](8),
	[POS_CODE] [varchar](8),
	[POS_DESC] [varchar](35),
	[POS_DT] [varchar](8),
	[REG_TEMP] [char](8),
	[STAT3] [varchar](8),
	[EMPL_STAT3_DT] [varchar](8),
	[STATUS] [varchar](8),
	[EMPL_STAT_DT] [varchar](8),
	[STD_HRS] [varchar](16),
	[WORK_SCHD_DT] [varchar](8),
	[LOA_BEG_DT] [varchar](8),
	[LOA_END_DT] [varchar](8),
	[LOA_TYPE] [varchar](8),
	[LVL_SUFFIX] [varchar](8),
	[DIVISION_FROM] [varchar](8),
	[WORK_OFF] [varchar](15),
	[CURR_DIV_FUNC_CODE] [varchar](8),
	[CURR_REP_LVL_CODE] [varchar](8),
	[PREV_DIV_FUNC_CODE] [varchar](8),
	[PREV_REP_LVL_CODE] [varchar](8),
	[MGR2_LNAME] [varchar](25),
	[MGR2_INITIALS] [varchar](8),
	[MGR3_LNAME] [varchar](25),
	[MGR3_INITIALS] [varchar](8),
	[HIRE_TYPE] [char](8),
	[HIRE_PRGM] [varchar](8),
	[SEPRSN] [varchar](8),
	[DEPT_FROM] [varchar](8),
	[VACELGD] [varchar](8),
	[CMPLN] [varchar](8),
	[BLDG_ID] [varchar](8),
	[DEPT_SHIFT_DT] [varchar](8),
	[DEPT_SHIFT_1] [char](8),
	[MGR_FLAG] [char](8),
	[SALARY] [varbinary](256),
	[SALARY_DT] [varchar](8),
	[CREATION_DATE] [datetime],
	[CREATED_BY] [varchar](35),
	[ASTYP] [varchar](8),
	[ASNTYP] [varchar](5)
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO



USE [IMAPSStg]
GO

/****** Object:  Table [dbo].[XX_CERIS_DATA_STG_MISSING]    Script Date: 03/09/2017 13:25:38 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_CERIS_DATA_STG_MISSING]') AND type in (N'U'))
DROP TABLE [dbo].[XX_CERIS_DATA_STG_MISSING]
GO

USE [IMAPSStg]
GO

/****** Object:  Table [dbo].[XX_CERIS_DATA_STG_MISSING]    Script Date: 03/09/2017 13:25:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[XX_CERIS_DATA_STG_MISSING](
	[REC_TYPE] [char](10),
	[SERIAL] [char](10),
	[HIRE_DATE_EFF] [char](8),
	[HIRE_DATE_SRD] [char](8),
	[SEP_DATE] [char](8),
	[DEPT_MGR_SER_1] [char](10),
	[DEPT_MGR_NAME_LAST] [char](30),
	[DEPT_MGR_NAME_INIT] [char](10),
	[JOB_FAMILY_1] [char](10),
	[JOB_FAMILY_DATE_1] [char](8),
	[LEVEL_PREFIX_1] [char](10),
	[LEVEL_SUFFIX_1] [char](10),
	[LVL_DATE_1] [char](8),
	[DIVISION_1] [char](10),
	[DIVISION_2] [char](10),
	[DIV_DATE] [char](8),
	[DEPT_PLUS_SFX] [char](10),
	[DEPT_DATE] [char](8),
	[DEPT_SUF_DATE] [char](8),
	[EX_NE_OUT] [char](10),
	[EXEMPT_DATE] [char](8),
	[POS_CODE_1] [char](10),
	[JOB_TITLE] [char](30),
	[POS_DATE_1] [char](8),
	[EMPL_STAT_1ST] [char](10),
	[EMPL_STAT_3RD] [char](10),
	[EMPL_STAT3_DATE] [char](8),
	[EMPL_STAT_2ND] [char](10),
	[EMPL_STAT_DATE] [char](8),
	[WORK_SCHD] [char](10),
	[WORK_SCHD_DATE] [char](8),
	[SET_ID] [char](10),
	[LOC_WORK_1] [char](10),
	[LOC_WORK_ST] [char](10),
	[LOC_WORK_DTE_1] [char](8),
	[TBWKL_CITY] [char](24),
	[SALARY] [char](10),
	[SAL_CHG_DTE_1] [char](8),
	[SAL_RTE_CDE] [char](10),
	[SAL_BASE] [char](10),
	[SAL_MO_OUT] [char](10),
	[NAME_LAST_MIXED] [char](50),
	[NAME_FIRST_MIXED] [char](50),
	[NAME_INIT] [char](10),
	[CREATION_DATE] [datetime],
	[CREATED_BY] [varchar](35)
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


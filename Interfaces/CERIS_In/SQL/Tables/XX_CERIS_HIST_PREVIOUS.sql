USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_HIST_PREVIOUS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_CERIS_HIST_PREVIOUS]
GO
CREATE TABLE [dbo].[XX_CERIS_HIST_PREVIOUS](
	[EMPL_ID] [varchar](12) NOT NULL,
	[LNAME] [varchar](25) NOT NULL,
	[FNAME] [varchar](20) NOT NULL,
	[NAME_INITIALS] [varchar](5) NULL,
	[HIRE_EFF_DT] [datetime] NOT NULL,
	[IBM_START_DT] [datetime] NOT NULL,
	[TERM_DT] [datetime] NULL,
	[MGR_SERIAL_NUM] [varchar](8) NOT NULL,
	[MGR_LNAME] [varchar](25) NOT NULL,
	[MGR_INITIALS] [varchar](5) NOT NULL,
	[JOB_FAM] [varchar](12) NOT NULL,
	[JOB_FAM_DT] [datetime] NOT NULL,
	[SAL_BAND] [varchar](2) NOT NULL,
	[LVL_DT_1] [datetime] NOT NULL,
	[DIVISION] [varchar](2) NOT NULL,
	[DIVISION_START_DT] [datetime] NOT NULL,
	[DEPT] [varchar](12) NOT NULL,
	[DEPT_START_DT] [datetime] NULL,
	[DEPT_SUF_DT] [datetime] NULL,
	[FLSA_STAT] [varchar](3) NULL,
	[EXEMPT_DT] [datetime] NULL,
	[POS_CODE] [varchar](8) NULL,
	[POS_DESC] [varchar](30) NULL,
	[POS_DT] [datetime] NOT NULL,
	[REG_TEMP] [char](1) NOT NULL,
	[STAT3] [varchar](1) NULL,
	[EMPL_STAT3_DT] [datetime] NULL,
	[STATUS] [varchar](8) NOT NULL,
	[EMPL_STAT_DT] [datetime] NOT NULL,
	[STD_HRS] [int] NOT NULL,
	[WORK_SCHD_DT] [datetime] NULL,
	[SALSETID] [varchar](2) NULL,
	[WKLNEW] [varchar](3) NULL,
	[WKLCITY] [varchar](24) NULL,
	[WKLST] [varchar](2) NULL,
	[PAY_DIFFERENTIAL] [char](1) NULL,
	[PAY_DIFFERENTIAL_DT] [smalldatetime] NULL,
	[LVL_SUFFIX] [varchar](2) NULL,
	[DIVISION_FROM] [varchar](2) NULL,
	[SALARY] [decimal](15, 2) NULL,
	[SALARY_RTE_CD] [varchar](3) NULL,
	[SALARY_DT] [smalldatetime] NULL,
	[WKL_DT] [smalldatetime] NULL
) ON [PRIMARY]


GO
SET ANSI_PADDING OFF


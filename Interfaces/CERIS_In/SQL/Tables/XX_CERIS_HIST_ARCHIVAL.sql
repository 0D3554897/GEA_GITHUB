if exists (select * from dbo.sysobjects where id = object_id(N'[XX_CERIS_HIST_ARCHIVAL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_CERIS_HIST_ARCHIVAL]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_HIST_ARCHIVAL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_HIST_ARCHIVAL] (
	[CERIS_HIST_ARCH_REC_NUM] [int] IDENTITY (1, 1) NOT NULL ,
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[EMPL_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LNAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FNAME] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[NAME_INIT] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[HIRE_EFF_DT] [datetime] NOT NULL ,
	[IBM_START_DT] [datetime] NOT NULL ,
	[TERM_DT] [datetime] NULL ,
	[MGR_SERIAL_NUM] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MGR_LNAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MGR_INIT] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[JOB_FAM] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[JOB_FAM_DT] [datetime] NOT NULL ,
	[SAL_BAND] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LVL_DT_1] [datetime] NOT NULL ,
	[DIVISION] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DIVISION_START_DT] [datetime] NOT NULL ,
	[DEPT] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DEPT_START_DT] [datetime] NULL ,
	[DEPT_SUF_DT] [datetime] NULL ,
	[FLSA_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXEMPT_DT] [datetime] NULL ,
	[POS_CODE] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[POS_DESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[POS_DT] [datetime] NOT NULL ,
	[REG_TEMP] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[STAT3] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EMPL_STAT3_DT] [datetime] NULL ,
	[STATUS] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[EMPL_STAT_DT] [datetime] NOT NULL ,
	[STD_HRS] [int] NOT NULL ,
	[WORK_SCHD_DT] [datetime] NULL , --change KM 12/22/05
	[CREATED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CREATED_DT] [datetime] NOT NULL ,
	[MODIFIED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MODIFIED_DT] [datetime] NULL ,
	CONSTRAINT [PK_XX_CERIS_HIST_ARCHIVAL] PRIMARY KEY  CLUSTERED 
	(
		[CERIS_HIST_ARCH_REC_NUM]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [FK_XX_CERIS_HIST_ARCHIVAL] FOREIGN KEY 
	(
		[STATUS_RECORD_NUM]
	) REFERENCES [XX_IMAPS_INT_STATUS] (
		[STATUS_RECORD_NUM]
	)
) ON [PRIMARY]
END

GO



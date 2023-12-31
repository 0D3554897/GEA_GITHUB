if exists (select * from dbo.sysobjects where id = object_id(N'[XX_CERIS_CP_EMPL_STG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_CERIS_CP_EMPL_STG]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_CP_EMPL_STG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_CP_EMPL_STG] (
	[EMPL_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ORIG_HIRE_DT] [datetime] NOT NULL ,
	[ADJ_HIRE_DT] [datetime] NOT NULL ,
	[TERM_DT] [datetime] NULL ,
	[SPVSR_NAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LAST_NAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FIRST_NAME] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MID_NAME] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LAST_FIRST_NAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[EMAIL_ID] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
END

GO



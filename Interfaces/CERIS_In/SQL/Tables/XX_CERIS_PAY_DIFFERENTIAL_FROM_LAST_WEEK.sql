use imapsstg

/****** Object:  Table [dbo].[XX_CERIS_PAY_DIFFERENTIAL_FROM_LAST_WEEK]    Script Date: 07/21/2006 12:56:24 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_PAY_DIFFERENTIAL_FROM_LAST_WEEK]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CERIS_PAY_DIFFERENTIAL_FROM_LAST_WEEK]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_PAY_DIFFERENTIAL_FROM_LAST_WEEK]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_PAY_DIFFERENTIAL_FROM_LAST_WEEK] (

	[EMPL_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,

	[JOB_FAM] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[JOB_FAM_DT] [datetime] NOT NULL ,
	[SAL_BAND] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LVL_DT_1] [datetime] NOT NULL ,
	[DIVISION] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DIVISION_START_DT] [datetime] NOT NULL ,
	[DEPT] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DEPT_START_DT] [datetime] NULL ,
	[FLSA_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXEMPT_DT] [datetime] NULL ,

	[PAY_DIFFERENTIAL] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PAY_DIFFERENTIAL_DT] smalldatetime NOT NULL ,

	[CREATED_DATE] [datetime] NOT NULL 

) ON [PRIMARY]
END

--default values
--N, 2011-01-01


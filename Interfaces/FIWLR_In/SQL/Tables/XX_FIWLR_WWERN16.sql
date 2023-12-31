if exists (select * from dbo.sysobjects where id = object_id(N'[XX_FIWLR_WWERN16]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_FIWLR_WWERN16]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_WWERN16]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_FIWLR_WWERN16] (
	[SOURCE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[REGION] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DIVISION] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MAJOR] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MINOR] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[SUBMINOR] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AMOUNT] [decimal](15, 2) NULL ,
	[DEPARTMENT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROCESSED_DT] [datetime] NULL ,
	[INVOICE_TXT] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXPENSE_CODE] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FROM_DIV] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EMPLOYEE_SER] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[IGS_PROJECT_NO] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXPENSE_DT] [datetime] NULL ,
	[RPTKEY] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXPKEY] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ACCOUNT_ID] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EMP_INITS_NM] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EMP_LAST_NM] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXP_BEGIN_DT] [datetime] NULL ,
	[EXP_CHRG_DT] [datetime] NULL ,
	[EXP_EFFECTIVE_DT] [datetime] NULL ,
	[EXP_END_DT] [datetime] NULL ,
	[EXP_WEEK_END_DT] [datetime] NULL ,
	[CREATION_DATE] [datetime] NOT NULL ,
	[CREATED_BY] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SOURCE_GROUP] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
END

GO



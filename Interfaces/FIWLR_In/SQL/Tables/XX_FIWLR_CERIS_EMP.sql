if exists (select * from dbo.sysobjects where id = object_id(N'[XX_FIWLR_CERIS_EMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_FIWLR_CERIS_EMP]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_CERIS_EMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_FIWLR_CERIS_EMP] (
	[STATUS_REC_NO] [int] NOT NULL ,
	[EMP_NO] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[EMP_LNAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EMP_FNAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[STATUS] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DEPT] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DIVISION] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DIV_FROM] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DIV_STRT_DATE] [datetime] NULL ,
	[IBM_STRT_DATE] [datetime] NULL ,
	[TERM_DATE] [datetime] NULL ,
	[CREATE_DATE] [datetime] NULL ,
	[TIME_STAMP] [datetime] NULL 
) ON [PRIMARY]
END

GO

CREATE  INDEX [fiwlr_ceris_emp_emp_ix] 
ON [dbo].[XX_FIWLR_CERIS_EMP]([EMP_NO]) 
WITH  FILLFACTOR = 90 ON [PRIMARY]
GO




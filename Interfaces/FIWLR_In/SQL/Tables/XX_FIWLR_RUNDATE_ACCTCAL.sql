/****** Object:  Table [dbo].[XX_FIWLR_RUNDATE_ACCTCAL]    Script Date: 10/04/2006 11:52:49 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_RUNDATE_ACCTCAL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_FIWLR_RUNDATE_ACCTCAL]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_RUNDATE_ACCTCAL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_FIWLR_RUNDATE_ACCTCAL] (
	[fiscal_year] [int] NOT NULL ,
	[period] [int] NOT NULL ,
	[sub_pd_no] [int] NOT NULL ,
	[run_start_date] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[run_end_date] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[reference1] [varchar] (125) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[reference2] [varchar] (125) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[reference3] [varchar] (125) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[reference4] [varchar] (125) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[reference5] [varchar] (125) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[creation_date] [datetime] NULL ,
	[created_by] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
END

GO



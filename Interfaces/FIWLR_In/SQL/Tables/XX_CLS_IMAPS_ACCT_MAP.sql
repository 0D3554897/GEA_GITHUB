if exists (select * from dbo.sysobjects where id = object_id(N'[XX_CLS_IMAPS_ACCT_MAP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CLS_IMAPS_ACCT_MAP]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CLS_IMAPS_ACCT_MAP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CLS_IMAPS_ACCT_MAP] (
	[ACCT_ID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MAJOR_1] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MAJOR_2] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MINOR_1] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MINOR_2] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SUB_MINOR_1] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SUB_MINOR_2] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ANALYSIS_CD] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PAG] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VAL_NON_VAL_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[INC_EXC_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ACCT_DESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ANALYSIS_CD_DESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REFERENCE_1] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REFERENCE_2] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DIVISION] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[creation_date]	SMALLDATETIME , -- Added by Veera on 12/0/2005
	[created_by]	VARCHAR(50)

) ON [PRIMARY]
END

GO



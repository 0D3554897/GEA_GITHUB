/****** Object:  Table [dbo].[XX_AR_CASH_RECPT_TRN]    Script Date: 12/21/2005 4:20:16 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CASH_RECPT_TRN]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_AR_CASH_RECPT_TRN]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CASH_RECPT_TRN]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_AR_CASH_RECPT_TRN] (
	[CASH_RECPT_HDR_KEY] [int] NOT NULL ,
	[CASH_RECPT_TRN_KEY] [int] IDENTITY (1, 1) NOT NULL ,
	[LN_NO] [smallint] NOT NULL ,
	[ACCT_ID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ORG_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ORG_ABBRV_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PROJ_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ABBRV_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[REF1_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[REF2_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[INVC_ID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CUST_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CHK_NO] [int] NOT NULL ,
	[TRN_DESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DISC_TAKEN_AMT] [decimal](14, 2) NOT NULL ,
	[TRN_AMT] [decimal](14, 2) NOT NULL ,
	[MODIFIED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TIME_STAMP] [datetime] NOT NULL ,
	[BANK_ACCT_ABBRV] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VEND_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TVL_ADV_ID] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TVL_ADV_HDR_KEY] [int] NULL ,
	[TVL_ADV_LN_KEY] [int] NULL ,
	[CASH_ACCT_LINE_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[S_LINE_SOURCE_CD] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PAY_TRN_AMT] [decimal](14, 2) NOT NULL ,
	[PAY_DISC_TAKEN_AMT] [decimal](14, 2) NOT NULL ,
	[TRN_TRN_AMT] [decimal](14, 2) NOT NULL ,
	[TRN_DISC_TAKEN_AMT] [decimal](14, 2) NOT NULL ,
	[MU_REAL_GAIN_AMT] [decimal](14, 2) NOT NULL ,
	[MU_REAL_LOSS_AMT] [decimal](14, 2) NOT NULL ,
	[PROJ_ACCT_ABBRV_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TRN_FINCHG_RCV_AMT] [decimal](14, 2) NOT NULL ,
	[PAY_FINCHG_RCV_AMT] [decimal](14, 2) NOT NULL ,
	[FINCHG_RCV_AMT] [decimal](14, 2) NOT NULL ,
	[ROWVERSION] [int] NULL ,
	[EXP_RPT_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_XX_AR_CASH_RECPT_TRN] PRIMARY KEY  CLUSTERED 
	(
		[CASH_RECPT_TRN_KEY]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
END

GO


/****** Object:  Index PI_0448 on Table [dbo].[XX_AR_CASH_RECPT_TRN]    Script Date: 12/21/2005 4:20:38 PM ******/
if exists (select * from dbo.sysindexes where name = N'PI_0448' and id = object_id(N'[dbo].[XX_AR_CASH_RECPT_TRN]'))
drop index [dbo].[XX_AR_CASH_RECPT_TRN].[PI_0448]
GO

 CREATE  UNIQUE  INDEX [PI_0448] ON [dbo].[XX_AR_CASH_RECPT_TRN]([CASH_RECPT_HDR_KEY], [CASH_RECPT_TRN_KEY]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO


/****** Object:  Trigger dbo.XX_AR_CASH_RECPT_TRN_INSTRIG    Script Date: 12/21/2005 4:21:02 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CASH_RECPT_TRN_INSTRIG]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[XX_AR_CASH_RECPT_TRN_INSTRIG]
GO

CREATE TRIGGER XX_AR_CASH_RECPT_TRN_INSTRIG    ON  XX_AR_CASH_RECPT_TRN FOR INSERT    AS    declare @num_rows int    select @num_rows = @@rowcount If @num_rows = 0    return       /* F08178 insert restrict */  IF (SELECT COUNT(*) FROM  XX_AR_CASH_RECPT_HDR, inserted    WHERE    XX_AR_CASH_RECPT_HDR.CASH_RECPT_HDR_KEY = inserted.CASH_RECPT_HDR_KEY) != @num_rows  BEGIN    RAISERROR 40002 'NOT IN CASH_RECPT_HDR for child CASH_RECPT_TRN'    ROLLBACK TRAN RETURN  END       /* F08179 insert restrict */  IF (SELECT COUNT(*) FROM  IMAPS.DELTEK.ORG_ACCT, inserted    WHERE    IMAPS.DELTEK.ORG_ACCT.ORG_ID = inserted.ORG_ID AND    IMAPS.DELTEK.ORG_ACCT.ACCT_ID = inserted.ACCT_ID) != @num_rows  BEGIN    RAISERROR 40002 'NOT IN ORG_ACCT for child CASH_RECPT_TRN'    ROLLBACK TRAN RETURN  END       /* F08180 insert restrict */  IF (SELECT COUNT(*) FROM  IMAPS.DELTEK.PROJ, inserted    WHERE    IMAPS.DELTEK.PROJ.PROJ_ID = inserted.PROJ_ID) !=       (@num_rows - (select count(*) from inserted where      inserted.PROJ_ID is null ))  BEGIN    RAISERROR 40002 'NOT IN PROJ for child CASH_RECPT_TRN'    ROLLBACK TRAN RETURN  END 

GO


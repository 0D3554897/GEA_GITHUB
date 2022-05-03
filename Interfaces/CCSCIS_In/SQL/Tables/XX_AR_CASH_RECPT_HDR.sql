/****** Object:  Table [dbo].[XX_AR_CASH_RECPT_HDR]    Script Date: 12/21/2005 4:18:18 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CASH_RECPT_HDR]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_AR_CASH_RECPT_HDR]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CASH_RECPT_HDR]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_AR_CASH_RECPT_HDR] (
	[CASH_RECPT_HDR_KEY] [int] NOT NULL ,
	[FY_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PD_NO] [smallint] NOT NULL ,
	[CASH_RECPT_NO] [int] NOT NULL ,
	[SUB_PD_NO] [smallint] NOT NULL ,
	[ENTR_USER_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ENTR_DTT] [datetime] NOT NULL ,
	[S_JNL_CD] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[POST_SEQ_NO] [int] NULL ,
	[RECPT_DT] [smalldatetime] NOT NULL ,
	[MODIFIED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TIME_STAMP] [datetime] NOT NULL ,
	[COMPANY_ID] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ADVANCE_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PAY_CRNCY_CD] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PAY_CRNCY_DT] [datetime] NULL ,
	[RATE_GRP_ID] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TRN_TO_EUR_RT] [decimal](14, 7) NOT NULL ,
	[EUR_TO_FUNC_RT] [decimal](14, 7) NOT NULL ,
	[TRN_TO_EUR_RT_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TRN_FREEZE_RT_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[BANK_DEPOSIT_NO] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OVR_BUD_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DOC_LOCATION] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ROWVERSION] [int] NULL 
) ON [PRIMARY]
END

GO

/****** Object:  Index PI_0447 on Table [dbo].[XX_AR_CASH_RECPT_HDR]    Script Date: 12/21/2005 4:18:30 PM ******/
if exists (select * from dbo.sysindexes where name = N'PI_0447' and id = object_id(N'[dbo].[XX_AR_CASH_RECPT_HDR]'))
drop index [dbo].[XX_AR_CASH_RECPT_HDR].[PI_0447]
GO

 CREATE  UNIQUE  INDEX [PI_0447] ON [dbo].[XX_AR_CASH_RECPT_HDR]([CASH_RECPT_HDR_KEY]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO


/****** Object:  Trigger dbo.XX_AR_CASH_RECPT_HDR_INSTRIG    Script Date: 12/21/2005 4:18:50 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CASH_RECPT_HDR_INSTRIG]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[XX_AR_CASH_RECPT_HDR_INSTRIG]
GO

CREATE TRIGGER XX_AR_CASH_RECPT_HDR_INSTRIG    ON  XX_AR_CASH_RECPT_HDR FOR INSERT    AS    declare @num_rows int    select @num_rows = @@rowcount If @num_rows = 0    return       /* F08176 insert restrict */  IF (SELECT COUNT(*) FROM  IMAPS.DELTEK.POSTING, inserted    WHERE    IMAPS.DELTEK.POSTING.FY_CD = inserted.FY_CD AND    IMAPS.DELTEK.POSTING.PD_NO = inserted.PD_NO AND   IMAPS.DELTEK.POSTING.S_JNL_CD = inserted.S_JNL_CD AND   IMAPS.DELTEK.POSTING.POST_SEQ_NO = inserted.POST_SEQ_NO) !=       (@num_rows - (select count(*) from inserted where      inserted.POST_SEQ_NO is null ))  BEGIN    RAISERROR 40002 'NOT IN POSTING for child CASH_RECPT_HDR'    ROLLBACK TRAN RETURN  END       /* F08175 insert restrict */  IF (SELECT COUNT(*) FROM  IMAPS.DELTEK.SUB_PD, inserted    WHERE    IMAPS.DELTEK.SUB_PD.FY_CD = inserted.FY_CD AND    IMAPS.DELTEK.SUB_PD.PD_NO = inserted.PD_NO AND    IMAPS.DELTEK.SUB_PD.SUB_PD_NO = inserted.SUB_PD_NO) != @num_rows  BEGIN    RAISERROR 40002 'NOT IN SUB_PD for child CASH_RECPT_HDR'    ROLLBACK TRAN RETURN  END 

GO

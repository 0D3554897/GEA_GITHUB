if exists (select * from dbo.sysobjects where id = object_id(N'[XX_AOPUTLAP_INP_HDR_ERR]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_AOPUTLAP_INP_HDR_ERR]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AOPUTLAP_INP_HDR_ERR]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_AOPUTLAP_INP_HDR_ERR] (
	[REC_NO] [int] NOT NULL ,
	[S_STATUS_CD] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VCHR_NO] [int] NULL ,
	[FY_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PD_NO] [smallint] NULL ,
	[SUB_PD_NO] [smallint] NULL ,
	[VEND_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TERMS_DC] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[INVC_ID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[INVC_DT] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[INVC_AMT] [decimal](14, 2) NULL ,
	[DISC_DT] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DISC_PCT_RT] [decimal](5, 2) NULL ,
	[DISC_AMT] [decimal](14, 2) NULL ,
	[DUE_DT] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[HOLD_VCHR_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PAY_WHEN_PAID_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PAY_VEND_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PAY_ADDR_DC] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PO_ID] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PO_RLSE_NO] [smallint] NULL ,
	[RTN_RATE] [decimal](5, 2) NULL ,
	[AP_ACCT_DESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CASH_ACCT_DESC] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[S_INVC_TYPE] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SHIP_AMT] [decimal](14, 2) NULL ,
	[CHK_FY_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CHK_PD_NO] [smallint] NULL ,
	[CHK_SUB_PD_NO] [smallint] NULL ,
	[CHK_NO] [int] NULL ,
	[CHK_DT] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CHK_AMT] [decimal](14, 2) NULL ,
	[DISC_TAKEN_AMT] [decimal](14, 2) NULL ,
	[INVC_POP_DT] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PRINT_NOTE_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[JNT_PAY_VEND_NAME] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[NOTES] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TIME_STAMP] [datetime] NULL ,
	[SEP_CHK_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
END

GO



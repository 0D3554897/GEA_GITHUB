/****** Object:  Table [dbo].[XX_IMAPS_INV_OUT_SUM]    Script Date: 1/13/2006 11:39:01 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_IMAPS_INV_OUT_SUM]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_IMAPS_INV_OUT_SUM]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_IMAPS_INV_OUT_SUM]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_IMAPS_INV_OUT_SUM] (
	[CUST_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PROJ_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[INVC_ID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[INVC_DT] [smalldatetime] NOT NULL ,
	[STATUS_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[BILL_TYPE] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FY_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PD_NO] [smallint] NOT NULL ,
	[CUR_JUL_DT] [int] NOT NULL ,
	[I_BO] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CUST_ADDR_DC] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PRIME_CONTR_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CUST_PO_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CUST_TERMS_DC] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[I_ENTERPRISE] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CUST_NAME] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[I_NAPCODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[C_STD_IND_CLASS] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[C_INDUS] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[C_STATE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[C_CNTY] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[C_CITY] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TI_CMR_CUST_TYPE] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[C_FDS_CUST_TYPE] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[I_MKG_DIV] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[I_COLL_OFF] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[C_COLL_DIV] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[T_CUST_REF_1] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[INVC_AMT] [decimal](14, 2) NOT NULL ,
	[SALES_TAX_AMT] [decimal](14, 2) NULL ,
	[CSP_AMT] [decimal](14, 2) NULL ,
	[CSP_TAX_AMT] [decimal](14, 2) NULL ,
	[FDS_INV_AMT] [decimal](14, 2) NOT NULL ,
	[FDS_SALES_TAX_AMT] [decimal](14, 2) NULL ,
	[TI_SVC_BO] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[HR_BILL_RT_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__XX_IMAPS___HR_BI__395884C4] DEFAULT ('N'),
	[HR_CUM_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__XX_IMAPS___HR_CU__3A4CA8FD] DEFAULT ('N'),
	[HR_CUR_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__XX_IMAPS___HR_CU__3B40CD36] DEFAULT ('N'),
	[HR_EMPL_NAME_FL] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__XX_IMAPS___HR_EM__3C34F16F] DEFAULT ('N'),
	[TC_CERTIFC_STATUS] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TC_TAX_CLASS] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[F_OCL] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_IMAPS_INV_OUT_SUM] UNIQUE  NONCLUSTERED 
	(
		[INVC_ID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
END

GO



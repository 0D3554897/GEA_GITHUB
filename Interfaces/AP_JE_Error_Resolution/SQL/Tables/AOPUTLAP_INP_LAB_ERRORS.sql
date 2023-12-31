/****** Object:  Table [dbo].[AOPUTLAP_INP_LAB_ERRORS]    Script Date: 06/20/2006 3:27:27 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AOPUTLAP_INP_LAB_ERRORS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[AOPUTLAP_INP_LAB_ERRORS]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AOPUTLAP_INP_LAB_ERRORS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[AOPUTLAP_INP_LAB_ERRORS] (
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[ERROR_SEQUENCE_NO] [int] NOT NULL ,
	[REC_NO] [int] NOT NULL ,
	[S_STATUS_CD] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VCHR_NO] [int] NULL ,
	[FY_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VCHR_LN_NO] [smallint] NULL ,
	[SUB_LN_NO] [smallint] NULL ,
	[VEND_EMPL_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[GENL_LAB_CAT_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[BILL_LAB_CAT_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VEND_HRS] [decimal](14, 2) NULL ,
	[VEND_AMT] [decimal](14, 2) NULL ,
	[EFFECT_BILL_DT] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TIME_STAMP] [datetime] NULL 
) ON [PRIMARY]
END

GO



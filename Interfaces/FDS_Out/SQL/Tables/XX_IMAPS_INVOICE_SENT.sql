/****** Object:  Table [dbo].[XX_IMAPS_INVOICE_SENT]    Script Date: 10/04/2006 9:32:41 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_IMAPS_INVOICE_SENT]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_IMAPS_INVOICE_SENT]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_IMAPS_INVOICE_SENT]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_IMAPS_INVOICE_SENT] (
	[CUST_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PROJ_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[INVC_ID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[INVC_AMT] [decimal](14, 2) NOT NULL ,
	[INVC_DT] [smalldatetime] NOT NULL ,
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[MODIFIED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__XX_IMAPS___MODIF__1CC8C9BC] DEFAULT (user_name()),
	[TIME_STAMP] [datetime] NOT NULL CONSTRAINT [DF__XX_IMAPS___TIME___1DBCEDF5] DEFAULT (getdate())
) ON [PRIMARY]
END

GO



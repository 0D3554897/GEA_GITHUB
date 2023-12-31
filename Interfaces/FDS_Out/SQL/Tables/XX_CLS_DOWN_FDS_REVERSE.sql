/****** Object:  Table [dbo].[XX_CLS_DOWN_FDS_REVERSE]    Script Date: 10/04/2006 9:33:05 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CLS_DOWN_FDS_REVERSE]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CLS_DOWN_FDS_REVERSE]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CLS_DOWN_FDS_REVERSE]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CLS_DOWN_FDS_REVERSE] (
	[SERVICE_OFFERED] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CUSTOMER_NUM] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CONTRACT_NUM] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ABBRV_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MACHINE_TYPE] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PRODUCT_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DOLLAR_AMT] [decimal](14, 2) NULL ,
	[RUN_DT] [datetime] NULL 
) ON [PRIMARY]
END

GO



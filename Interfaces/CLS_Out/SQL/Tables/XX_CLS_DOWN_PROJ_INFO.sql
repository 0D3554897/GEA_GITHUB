
use imapsstg
GO

/****** Object:  Table [dbo].[XX_CLS_DOWN_PROJ_INFO]    Script Date: 9/13/2007 2:02:15 PM ******/
SET ANSI_PADDING ON
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CLS_DOWN_PROJ_INFO]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CLS_DOWN_PROJ_INFO]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CLS_DOWN_PROJ_INFO]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CLS_DOWN_PROJ_INFO] (
	[PROJ_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SERVICE_OFFERING] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MACHINE_TYPE_CD] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PRODUCT_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CONTRACT_NUM] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CUSTOMER_NUM] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OVERHEAD_AMT] [decimal](14, 2) NULL ,
	[GA_AMT] [decimal](14, 2) NULL ,
	[REV_AMT] [decimal](14, 2) NULL ,
	[S_PROJ_RPT_DC] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ABBRV_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
END

GO



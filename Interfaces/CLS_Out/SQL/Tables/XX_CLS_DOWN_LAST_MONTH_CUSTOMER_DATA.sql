
USE [IMAPSSTG]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CLS_DOWN_LAST_MONTH_CUSTOMER_DATA]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CLS_DOWN_LAST_MONTH_CUSTOMER_DATA]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CLS_DOWN_LAST_MONTH_CUSTOMER_DATA]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN

CREATE TABLE [dbo].[XX_CLS_DOWN_LAST_MONTH_CUSTOMER_DATA](
	[CUSTOMER_NUM] [varchar](10) NULL,
	[MARKETING_OFFICE] [char](3) NULL,
	[CONSOLIDATED_REV_BRANCH_OFFICE] [char](3) NULL,
	[INDUSTRY] [char](4) NULL,
	[ENTERPRISE_NUM_CD] [varchar](7) NULL,
	[BUSINESS_AREA] [varchar](2) NULL,
	[MARKETING_AREA] [varchar](2) NULL
) ON [PRIMARY]

END
GO
SET ANSI_PADDING OFF
GO






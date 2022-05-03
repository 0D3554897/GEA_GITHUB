

USE [IMAPSSTG]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

/****** Object:  Table [dbo].[XX_CLS_DOWN_PROJ_CUST_ABOVE_BILLING_LEVEL]    Script Date: 1/3/2006 4:16:36 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CLS_DOWN_PROJ_CUST_ABOVE_BILLING_LEVEL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CLS_DOWN_PROJ_CUST_ABOVE_BILLING_LEVEL]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CLS_DOWN_PROJ_CUST_ABOVE_BILLING_LEVEL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CLS_DOWN_PROJ_CUST_ABOVE_BILLING_LEVEL] (

 CREATE_DATE								datetime DEFAULT(getdate()) NOT NULL,
 CREATE_USER								varchar (30) NOT NULL,
 UPDATE_DATE								datetime DEFAULT(getdate()) NOT NULL,
 UPDATE_USER								varchar (30) NOT NULL,

 PROJ_ID									varchar(30) NOT NULL,
 ADDR_DC									varchar(10) NOT NULL,

 ACTIVE_FL									char (1) NOT NULL,
 ACTIVE_DATE								datetime DEFAULT(getdate()) NOT NULL

) ON [PRIMARY]
END
GO


GO
SET ANSI_PADDING OFF







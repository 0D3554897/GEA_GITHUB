USE [IMAPSStg]
GO

/****** Object:  Table [dbo].[XX_IMAPS_CUSTOMER_FAILURES]    Script Date: 5/17/2022 1:25:00 PM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_IMAPS_CUSTOMER_FAILURES]') AND type in (N'U'))
DROP TABLE [dbo].[XX_IMAPS_CUSTOMER_FAILURES]
GO

/****** Object:  Table [dbo].[XX_IMAPS_CUSTOMER_FAILURES]    Script Date: 5/17/2022 1:25:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[XX_IMAPS_CUSTOMER_FAILURES](

	[I_CUST_ENTITY] [char](10)  NOT NULL
) ON [PRIMARY]
GO



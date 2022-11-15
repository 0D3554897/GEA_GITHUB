USE [IMAPSStg]
GO

/****** Object:  Table [dbo].[XX_CLS_DOWN_HW_SW_MAP]    Script Date: 9/9/2022 10:22:08 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_CLS_DOWN_HW_SW_MAP]') AND type in (N'U'))
DROP TABLE [dbo].[XX_CLS_DOWN_HW_SW_MAP]
GO

/****** Object:  Table [dbo].[XX_CLS_DOWN_HW_SW_MAP]    Script Date: 9/9/2022 10:22:08 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* created for FSSTIMAPS-73
BY: GEORGE ALVAREZ, 9/9/2022
This table holds the mapping required to assign 
  HW/SW revenue and expense to correct division

*/

CREATE TABLE [dbo].[XX_CLS_DOWN_HW_SW_MAP](
	[IMAPS_ACCT] [varchar](10) NOT NULL,
	[CLS_MAJOR] [varchar](3) NOT NULL,
	[CLS_MINOR] [varchar](4) NOT NULL,
	[CLS_SUB_MINOR] [varchar](4) NULL,
	[PRODUCT_ID] [varchar](12) NOT NULL,
	[DIVISION] [char](2) NOT NULL,
	[CLASS] [varchar](3) NOT NULL,
	[HWSW] [varchar](2) NOT NULL,
) ON [PRIMARY]
GO



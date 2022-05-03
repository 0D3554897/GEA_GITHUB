USE [IMAPSStg]
GO

/****** Object:  Table [dbo].[XX_FIWLR_WWER_EMPL]    Script Date: 04/25/2017 13:40:46 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_FIWLR_WWER_EMPL]') AND type in (N'U'))
DROP TABLE [dbo].[XX_FIWLR_WWER_EMPL]
GO

USE [IMAPSStg]
GO

/****** Object:  Table [dbo].[XX_FIWLR_WWER_EMPL]    Script Date: 04/25/2017 13:40:49 ******/
/** Table is used as temporary storage of the vendor(employee that created claim) , voucher (WWER claim) pairs  extracted  from WWER source.
The table is used in SSIS package.**/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[XX_FIWLR_WWER_EMPL](
	[VOUCHER_NO] [char](12) NOT NULL,
	[EMPLOYEE_NO] [char](6) NULL,
	[EMPLOYEE_NAME] [varchar](35) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO



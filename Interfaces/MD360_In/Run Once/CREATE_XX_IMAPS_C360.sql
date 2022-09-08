USE [IMAPSStg]
GO

/****** Object:  Table [dbo].[XX_IMAPS_C360]    Script Date: 5/17/2022 1:25:00 PM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_IMAPS_C360]') AND type in (N'U'))
DROP TABLE [dbo].[XX_IMAPS_C360]
GO

/****** Object:  Table [dbo].[XX_IMAPS_C360]    Script Date: 5/17/2022 1:25:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[XX_IMAPS_C360](

	[I_CUST_ENTITY] [varchar](10)  NOT NULL,
	[I_CO] [varchar](15) NULL,
	[I_ENT] [varchar](15) NULL,
	[N_ABBREV] [varchar](60) NOT NULL,
	[I_CUST_ADDR_TYPE] [varchar](4) NULL,
	[ADDR_LINE_1] [varchar](24) NULL,
	[ADDR_LINE_2] [varchar](24) NULL,
	[ADDR_LINE_3] [varchar](24) NULL,
	[ADDR_LINE_4] [varchar](24) NULL,
	[N_CITY] [varchar](70) NULL,
	[N_ST] [varchar](3) NULL,
	[C_ZIP] [varchar](10) NULL,
	[C_SCC_ST] [varchar](2) NOT NULL,
	[C_SCC_CNTY] [varchar](3) NOT NULL,
	[C_SCC_CITY] [varchar](4) NOT NULL,
	[I_MKTG_OFF] [varchar](35) NULL,
	[A_LEVEL_1_VALUE] [varchar](2) NULL,
	[I_PRIMRY_SVC_OFF] [varchar](30) NULL,
	[C_ICC_TE] [varchar](1) NULL,
	[C_ICC_TAX_CLASS] [varchar](3) NULL,
	[C_ESTAB_SIC] [varchar](8) NULL,
	[I_INDUS_DEPT] [varchar](10) NULL,
	[I_INDUS_CLASS] [varchar](10) NULL,
	[C_NAP] [varchar](3) NULL,
	[I_TYPE_CUST_1] [varchar](11) NULL,
	[F_GENRL_SVC_ADMIN] [varchar](1) NULL,
	[F_OCL] [char](1) NULL,
	[XMIT_DATE]  [varchar](8) NULL DEFAULT REPLACE(CONVERT (CHAR(10), getdate(), 101),'/','')
) ON [PRIMARY]
GO



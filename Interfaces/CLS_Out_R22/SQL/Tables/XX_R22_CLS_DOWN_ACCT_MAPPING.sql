USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_CLS_DOWN_ACCT_MAPPING]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_R22_CLS_DOWN_ACCT_MAPPING]
GO

CREATE TABLE [dbo].[XX_R22_CLS_DOWN_ACCT_MAPPING](
	[ROW_NUM]             [int] IDENTITY(1,1) NOT NULL,
	[NOTES]               [varchar](30) NULL,
	[IMAPS_ACCT_START]    [char](8) NOT NULL,
	[IMAPS_ACCT_END]      [char](8) NOT NULL,
	[POOL_NO]             [varchar](10) NULL,
	[S_PROJ_RPT_DC]       [varchar](50) NULL,
	[PROJ_ID]             [varchar](50) NULL,
	[CLS_MAJOR]           [char](3) NOT NULL,
	[CLS_MINOR]           [char](4) NOT NULL,
	[CLS_SUB_MINOR]       [char](4) NOT NULL,
	[CONTRACT]            [char](1) NULL,
	[CUSTOMER]            [char](1) NULL,
	[PROJECT]             [char](1) NULL,
	[MACHINE_TYPE]        [char](1) NULL,
	[PRODUCT_ID]          [char](1) NULL,
	[APPLY_BURDEN]        [char](1) NULL,
	[REVERSE_FDS]         [smallint] NULL,
	[MULTIPLIER]          [smallint] NULL,
 CONSTRAINT [PK_XX_R22_CLS_DOWN_ACCT_MAPPING] PRIMARY KEY CLUSTERED 
(
	[ROW_NUM] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

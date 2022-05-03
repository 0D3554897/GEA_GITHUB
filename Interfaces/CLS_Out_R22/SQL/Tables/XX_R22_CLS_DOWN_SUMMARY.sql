USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_CLS_DOWN_SUMMARY]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_R22_CLS_DOWN_SUMMARY]
GO

CREATE TABLE [dbo].[XX_R22_CLS_DOWN_SUMMARY](
	[CLS_MAJOR]     [varchar](3) NOT NULL,
	[CLS_MINOR]     [varchar](4) NOT NULL,
	[CLS_SUB_MINOR] [varchar](4) NOT NULL,
	[DOLLAR_AMT]    [decimal](14, 2) NULL,
	[RECORD_CNT]    [int] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

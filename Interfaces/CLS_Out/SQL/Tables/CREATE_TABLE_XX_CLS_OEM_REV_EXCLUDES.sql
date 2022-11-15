USE [IMAPSStg]
GO

/****** Object:  Table [dbo].[XX_CLS_DOWN_THIS_MONTH_YTD]    Script Date: 11/9/2022 2:37:31 PM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_CLS_OEM_REV_EXCLUDES]') AND type in (N'U'))
DROP TABLE [dbo].[XX_CLS_OEM_REV_EXCLUDES]
GO

/****** Object:  Table [dbo].[XX_CLS_OEM_REV_EXCLUDES]    Script Date: 11/9/2022 2:37:31 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[XX_CLS_OEM_REV_EXCLUDES](
	[IMAPS_LEVEL_1] [varchar](4) NOT NULL,
) ON [PRIMARY]
GO



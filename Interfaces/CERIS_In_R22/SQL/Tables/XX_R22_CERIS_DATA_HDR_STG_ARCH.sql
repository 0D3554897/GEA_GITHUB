USE [IMAPSStg]
GO

/****** Object:  Table [dbo].[XX_R22_CERIS_DATA_HDR_STG_ARCH]    Script Date: 09/29/2016 09:30:37 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_R22_CERIS_DATA_HDR_STG_ARCH]') AND type in (N'U'))
DROP TABLE [dbo].[XX_R22_CERIS_DATA_HDR_STG_ARCH]
GO

USE [IMAPSStg]
GO

/****** Object:  Table [dbo].[XX_R22_CERIS_DATA_HDR_STG_ARCH]    Script Date: 09/29/2016 09:30:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING OFF
GO

CREATE TABLE [dbo].[XX_R22_CERIS_DATA_HDR_STG_ARCH](
	[STATUS_RECORD_NUM] [int] NOT NULL,
	[REC_TYPE] [char](1) NOT NULL,
	[LAB1] [char](6) NOT NULL,
	[RUN_DATE] [char](8) NOT NULL,
	[FIL2] [char](6) NOT NULL,
	[RUN_TIME] [char](8) NOT NULL,
	[LAB3] [char](6) NOT NULL,
	[RECS_OUT] [char](6) NOT NULL,
	[LAB4] [char](6) NOT NULL,
	[SEQ_OUT] [char](4) NOT NULL,
	[LAB5] [char](6) NOT NULL,
	[HASH] [char](6) NOT NULL,
	[LAB6] [char](21) NOT NULL,
	[IBM_CLASSIFICATION] [char](20) NOT NULL,
	[DMEM_AS_OF_DATE] [char](8) NOT NULL,
	[LAB7] [char](16) NOT NULL,
	[EMP_FILENAME] [char](45) NOT NULL,
	[LAB8] [char](16) NOT NULL,
	[WKL_FILENAME] [char](45) NOT NULL,
	[CREATION_DATE] [datetime] NOT NULL,
	[CREATED_BY] [varchar](35) NOT NULL,
	[ARCHIVE_DATE] [datetime] NOT NULL,
	[ARCHIVED_BY] [varchar](35) NOT NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


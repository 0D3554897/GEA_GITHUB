USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_CERIS_ASSIGNMENT_LOG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_R22_CERIS_ASSIGNMENT_LOG]
GO

CREATE TABLE [dbo].[XX_R22_CERIS_ASSIGNMENT_LOG](
   [EMPL_ID]           [varchar](6)   NULL,
   [DIVISION]          [varchar](2)   NULL,
   [DIVISION_START_DT] [varchar](8)   NULL,
   [DIVISION_FROM]     [varchar](2)   NULL,
   [STATUS]            [varchar](8)   NULL,
   [TERM_DT]           [varchar](8)   NULL,
   [ASTYP]             [varchar](5)   NULL,
   [ASNTYP]            [varchar](5)   NULL,
   [CREATE_DT]         [datetime] NOT NULL DEFAULT (getdate()),
   [PROCESS_OMITTED]   [varchar](1)   NULL DEFAULT ('N'),
   [PROCESS_DT]        [datetime]     NULL,
   [STATUS_RECORD_NUM] [int]          NULL,
   [PROCESS_TYPE]      [varchar](1)   NULL,
   [PROCESS_DESC]      [varchar](150) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

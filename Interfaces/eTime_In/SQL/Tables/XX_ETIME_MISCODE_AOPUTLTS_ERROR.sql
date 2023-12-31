USE [IMAPSStg]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'XX_ETIME_MISCODE_AOPUTLTS_ERROR') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table XX_ETIME_MISCODE_AOPUTLTS_ERROR
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[XX_ETIME_MISCODE_AOPUTLTS_ERROR](
	[X_RECORD_NO] [int] NULL,
	[EMPL_ID] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[TS_DT] [smalldatetime] NULL,
	[TS_HDR_SEQ_NO] [smallint] NULL,
	[S_TS_TYPE_CD] [varchar](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[X_FIELD_NAME_S] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[X_CONTENTS_S] [varchar](70) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[X_ERROR_MSG_S] [varchar](150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MODIFIED_BY] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[TIME_STAMP] [datetime] NULL,
	[ERR_SUSP_WARN_NO] [smallint] NULL,
	[ROWVERSION] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
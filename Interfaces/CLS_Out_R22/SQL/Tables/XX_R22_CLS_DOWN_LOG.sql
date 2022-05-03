USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_CLS_DOWN_LOG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_R22_CLS_DOWN_LOG]
GO

CREATE TABLE [dbo].[XX_R22_CLS_DOWN_LOG](
	[STATUS_RECORD_NUM] [int] NOT NULL,
	[FILE_SEQ_NUM]      [int] NULL,
	[VOUCHER_NUM]       [varchar](7) NULL,
	[FY_SENT]           [char](4) NULL,
	[MONTH_SENT]        [char](2) NULL,
	[LEDGER_ENTRY_DATE] [datetime] NULL,
	[MODIFIED_BY]       [varchar](20) NULL,
	[ON_DEMAND]         [char](1) NULL,
	CONSTRAINT [FK_XX_R22_CLS_DOWN_LOG] FOREIGN KEY 
	(
		[STATUS_RECORD_NUM]
	) REFERENCES [XX_IMAPS_INT_STATUS] (
		[STATUS_RECORD_NUM]
	)
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

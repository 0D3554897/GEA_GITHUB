USE [IMAPSStg]
GO
/****** Object:  Index [PK_XX_PCLAIM_IN_ARCH]    Script Date: 03/10/2010 08:51:40 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[XX_PCLAIM_IN_ARCH]') AND name = N'PK_XX_PCLAIM_IN_ARCH')
ALTER TABLE [dbo].[XX_PCLAIM_IN_ARCH] DROP CONSTRAINT [PK_XX_PCLAIM_IN_ARCH]


USE [IMAPSStg]
GO
CREATE CLUSTERED INDEX [pclaim_STATUS_RECORD_NUM] ON [dbo].[XX_PCLAIM_IN_ARCH] 
(
	[STATUS_RECORD_NUM] ASC

)WITH (PAD_INDEX  = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, FILLFACTOR = 80, ONLINE = OFF) ON [PRIMARY]


GO


dbcc dbreindex ('XX_PCLAIM_IN_ARCH', '', 80)


GO


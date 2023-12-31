if exists (select * from dbo.sysobjects where id = object_id(N'[XX_FIWLR_VEND_V]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_FIWLR_VEND_V]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_VEND_V]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_FIWLR_VEND_V] (
	[VENDOR_ID] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VEND_NAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CREATION_DATE] [datetime] NOT NULL CONSTRAINT [NN_XX_FIWLR_VENDV_CDATE] DEFAULT (getdate())
) ON [PRIMARY]
END

GO



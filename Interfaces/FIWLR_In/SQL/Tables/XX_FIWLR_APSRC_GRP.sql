if exists (select * from dbo.sysobjects where id = object_id(N'[XX_FIWLR_APSRC_GRP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_FIWLR_APSRC_GRP]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_APSRC_GRP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_FIWLR_APSRC_GRP] (
	[SRCCODE_ID] [int] IDENTITY (1, 1) NOT NULL ,
	[SOURCE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DESCRIPTION] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CONTACT] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
END

GO



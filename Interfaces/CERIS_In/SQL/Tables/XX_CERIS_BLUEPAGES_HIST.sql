if exists (select * from dbo.sysobjects where id = object_id(N'[XX_CERIS_BLUEPAGES_HIST]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_CERIS_BLUEPAGES_HIST]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_BLUEPAGES_HIST]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_BLUEPAGES_HIST] (
	[EMPL_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[INTERNET_ID] [sysname] NOT NULL ,
	[TIME_STAMP] [datetime] NOT NULL CONSTRAINT [DF__XX_CERIS___TIME___0C90CB45] DEFAULT (getdate()),
	CONSTRAINT [PK_CERIS_BLUEPAGES_HIST] PRIMARY KEY  CLUSTERED 
	(
		[EMPL_ID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
END

GO



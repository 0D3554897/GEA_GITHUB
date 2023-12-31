if exists (select * from dbo.sysobjects where id = object_id(N'[XX_CERIS_PORT_NEW_ORGS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_CERIS_PORT_NEW_ORGS]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_PORT_NEW_ORGS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_PORT_NEW_ORGS] (
	[DEPT] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TIME_STAMP] [datetime] NOT NULL CONSTRAINT [DF__XX_CERIS___TIME___1249A49B] DEFAULT (getdate()),
	CONSTRAINT [PK_XX_CERIS_PORT_NEW_ORGS] PRIMARY KEY  CLUSTERED 
	(
		[DEPT]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
END

GO



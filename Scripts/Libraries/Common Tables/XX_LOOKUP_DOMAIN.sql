if exists (select * from dbo.sysobjects where id = object_id(N'[XX_LOOKUP_DOMAIN]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_LOOKUP_DOMAIN]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_LOOKUP_DOMAIN]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [XX_LOOKUP_DOMAIN] (
	[LOOKUP_DOMAIN_ID] [int] IDENTITY (1, 1) NOT NULL ,
	[LOOKUP_DOMAIN_DESC] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DOMAIN_CONSTANT] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CREATED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CREATED_DATE] [datetime] NOT NULL ,
	[MODIFIED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MODIFIED_DATE] [datetime] NULL ,
	CONSTRAINT [PK_LOOKUP_DOMAIN] PRIMARY KEY  CLUSTERED 
	(
		[LOOKUP_DOMAIN_ID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
END

GO



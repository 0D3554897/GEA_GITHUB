if exists (select * from dbo.sysobjects where id = object_id(N'[XX_LOOKUP_DETAIL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_LOOKUP_DETAIL]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_LOOKUP_DETAIL]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [XX_LOOKUP_DETAIL] (
	[LOOKUP_ID] [int] IDENTITY (1, 1) NOT NULL ,
	[LOOKUP_DOMAIN_ID] [int] NOT NULL ,
	[APPLICATION_CODE] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LOOKUP_DESCRIPTION] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PRESENTATION_ORDER] [int] NOT NULL ,
	[CREATED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CREATED_DATE] [datetime] NOT NULL ,
	[MODIFIED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MODIFIED_DATE] [datetime] NULL ,
	CONSTRAINT [PK_LOOKUP_DETAIL] PRIMARY KEY  CLUSTERED 
	(
		[LOOKUP_ID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [FK_LOOKUP_DETAIL] FOREIGN KEY 
	(
		[LOOKUP_DOMAIN_ID]
	) REFERENCES [XX_LOOKUP_DOMAIN] (
		[LOOKUP_DOMAIN_ID]
	)
) ON [PRIMARY]
END

GO


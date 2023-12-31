if exists (select * from dbo.sysobjects where id = object_id(N'[XX_INT_ERROR_MESSAGE]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_INT_ERROR_MESSAGE]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_INT_ERROR_MESSAGE]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [XX_INT_ERROR_MESSAGE] (
	[ERROR_CODE] [int] NOT NULL ,
	[ERROR_TYPE] [int] NOT NULL ,
	[ERROR_SEVERITY] [int] NULL ,
	[ERROR_MESSAGE] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ERROR_SOURCE] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CREATED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CREATED_DATE] [datetime] NOT NULL ,
	[MODIFIED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MODIFIED_DATE] [datetime] NULL ,
	CONSTRAINT [PK_XX_INT_ERROR_MESSAGE] PRIMARY KEY  CLUSTERED 
	(
		[ERROR_CODE]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [FK_XX_INT_ERROR_MSG1] FOREIGN KEY 
	(
		[ERROR_TYPE]
	) REFERENCES [XX_LOOKUP_DETAIL] (
		[LOOKUP_ID]
	)
) ON [PRIMARY]
END

GO



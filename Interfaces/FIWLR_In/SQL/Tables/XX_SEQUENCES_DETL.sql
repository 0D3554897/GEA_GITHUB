if exists (select * from dbo.sysobjects where id = object_id(N'[xx_sequences_detl]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[xx_sequences_detl]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[xx_sequences_detl]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[xx_sequences_detl] (
	[seq] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[sequence_id] [int] NULL ,
	 PRIMARY KEY  CLUSTERED 
	(
		[seq]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
END

GO



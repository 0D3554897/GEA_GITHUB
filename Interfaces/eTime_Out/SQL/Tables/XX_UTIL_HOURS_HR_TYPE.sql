if exists (select * from dbo.sysobjects where id = object_id(N'[XX_UTIL_HOURS_HR_TYPE]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_UTIL_HOURS_HR_TYPE]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_UTIL_HOURS_HR_TYPE]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_UTIL_HOURS_HR_TYPE] (
	[PROJ_ID] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[HR_TYPE] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[HR_TYPE_DESC] [nvarchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_XX_UTIL_HOURS_HR_TYPE] PRIMARY KEY  CLUSTERED 
	(
		[PROJ_ID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
END

GO



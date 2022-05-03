/****** Object:  Table [dbo].[XX_UTIL_ALT_PROJ_INDU]    Script Date: 07/24/2006 11:10:57 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_UTIL_ALT_PROJ_INDU]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_UTIL_ALT_PROJ_INDU]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_UTIL_ALT_PROJ_INDU]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_UTIL_ALT_PROJ_INDU] (
	[PROJ_RPT_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[INDUSTRY] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[KEY_ACCOUNT] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
END

GO



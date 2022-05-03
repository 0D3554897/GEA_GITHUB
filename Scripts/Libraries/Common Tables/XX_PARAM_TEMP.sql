if exists (select * from dbo.sysobjects where id = object_id(N'[XX_PARAM_TEMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_PARAM_TEMP]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PARAM_TEMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [XX_PARAM_TEMP] (
	[THE_FILE_NAME] [sysname] NOT NULL 
) ON [PRIMARY]
END

GO



/****** Object:  Table [dbo].[XX_CERIS_DIV16_STATUS]    Script Date: 03/07/2007 2:46:59 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_DIV16_STATUS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CERIS_DIV16_STATUS]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_DIV16_STATUS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_DIV16_STATUS] (
	[EMPL_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DIVISION] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DIVISION_START_DT] [datetime] NOT NULL ,
	[DIVISION_FROM] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CREATED_BY] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CREATION_DT] [datetime] NULL 
) ON [PRIMARY]
END

GO



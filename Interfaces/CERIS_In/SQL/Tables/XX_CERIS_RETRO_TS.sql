/****** Object:  Table [dbo].[XX_CERIS_RETRO_TS]    Script Date: 03/21/2007 5:43:00 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_RETRO_TS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CERIS_RETRO_TS]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_RETRO_TS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_RETRO_TS] (
	[EMPL_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[NEW_ORG_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[NEW_GLC] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EFFECT_DT] [smalldatetime] NOT NULL ,
	[END_DT] [smalldatetime] NOT NULL 
) ON [PRIMARY]
END

GO



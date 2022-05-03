/****** Object:  Table [dbo].[XX_CERIS_CLEARED_DEPARTMENTS]    Script Date: 07/21/2006 12:56:24 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_CLEARED_DEPARTMENTS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CERIS_CLEARED_DEPARTMENTS]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_CLEARED_DEPARTMENTS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_CLEARED_DEPARTMENTS] (
	[CERIS_GLC_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CERIS_DEPT] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[IMAPS_GLC_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CREATED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CREATED_DATE] [datetime] NOT NULL ,
	[MODIFIED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MODIFIED_DATE] [datetime] NULL 
) ON [PRIMARY]
END

GO



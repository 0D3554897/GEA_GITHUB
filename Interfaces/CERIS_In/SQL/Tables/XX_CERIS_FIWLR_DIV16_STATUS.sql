if exists (select * from dbo.sysobjects where id = object_id(N'[XX_CERIS_FIWLR_DIV16_STATUS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_CERIS_FIWLR_DIV16_STATUS]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_FIWLR_DIV16_STATUS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_FIWLR_DIV16_STATUS] (
	[EMPL_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LNAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FNAME] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[STATUS] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DEPT] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DIVISION] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DIVISION_FROM] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DIVISION_START_DT] [datetime] NOT NULL ,
	[SERVICE_DT] [datetime] NULL ,
	[CREATED_BY] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CREATION_DT] [datetime] NOT NULL 
) ON [PRIMARY]
END

GO



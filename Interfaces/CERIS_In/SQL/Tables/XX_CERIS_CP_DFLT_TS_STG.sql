if exists (select * from dbo.sysobjects where id = object_id(N'[XX_CERIS_CP_DFLT_TS_STG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_CERIS_CP_DFLT_TS_STG]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_CP_DFLT_TS_STG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_CP_DFLT_TS_STG] (
	[EMPL_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[GENL_LAB_CAT_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CHG_ORG_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
END

GO



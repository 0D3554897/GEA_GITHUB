if exists (select * from dbo.sysobjects where id = object_id(N'[XX_IMAPS_ET_FTR_IN_TMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_IMAPS_ET_FTR_IN_TMP]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_IMAPS_ET_FTR_IN_TMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [XX_IMAPS_ET_FTR_IN_TMP] (
	[FOOTER_IND] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FOOTER_DATE] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FOOTER_TIME] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TOTAL_REG_TIME] [char] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TOTAL_OVERTIME] [char] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TOTAL_RECORDS] [char] (66) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
END

GO



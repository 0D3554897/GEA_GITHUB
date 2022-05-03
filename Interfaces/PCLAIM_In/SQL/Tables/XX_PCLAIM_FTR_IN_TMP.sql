if exists (select * from dbo.sysobjects where id = object_id(N'[XX_PCLAIM_FTR_IN_TMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_PCLAIM_FTR_IN_TMP]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PCLAIM_FTR_IN_TMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [XX_PCLAIM_FTR_IN_TMP] (
	[FOOTER_IND] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TOTAL_RECORDS] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TOTAL_HOURS] [char] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TOTAL_COST] [char] (207) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
END

GO



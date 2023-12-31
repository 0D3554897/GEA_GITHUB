if exists (select * from dbo.sysobjects where id = object_id(N'[XX_BMS_IW_HDR]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_BMS_IW_HDR]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_BMS_IW_HDR]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_BMS_IW_HDR] (
	[RECORD_TYPE] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[REGISTRATION_ID] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CYCLE_NUMBER] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[THE_DATE] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DETAIL_RECORD_COUNT] [char] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TOTAL_HOURS] [char] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FILLER] [char] (41) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
END

GO



if exists (select * from dbo.sysobjects where id = object_id(N'[XX_IMAPS_ET_IN_TMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_IMAPS_ET_IN_TMP]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_IMAPS_ET_IN_TMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [XX_IMAPS_ET_IN_TMP] (
	[EMP_SERIAL_NUM] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TS_YEAR] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TS_MONTH] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TS_DAY] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PROJ_ABBR] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[SAT_REG_TIME] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SAT_OVERTIME] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SUN_REG_TIME] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SUN_OVERTIME] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MON_REG_TIME] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MON_OVERTIME] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TUE_REG_TIME] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TUE_OVERTIME] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[WED_REG_TIME] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[WED_OVERTIME] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[THU_REG_TIME] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[THU_OVERTIME] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FRI_REG_TIME] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FRI_OVERTIME] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PLC] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[RECORD_TYPE] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
END

GO



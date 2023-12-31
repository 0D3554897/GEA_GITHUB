if exists (select * from dbo.sysobjects where id = object_id(N'[XX_PCLAIM_IN_TMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_PCLAIM_IN_TMP]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PCLAIM_IN_TMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [XX_PCLAIM_IN_TMP] (
	[WORK_DATE] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VEND_EMPL_NAME] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PO_NUMBER] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VEND_EMPL_SERIAL_NUM] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PROJ_CODE] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VENDOR_ID] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DEPT_CODE] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[HOURS_CHARGED] [char] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[COST] [char] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PLC] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[BILL_RATE] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[RECORD_TYPE] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VEND_NAME] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VEND_ST_ADDRESS] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VEND_CITY] [char] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VEND_STATE] [char] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VEND_COUNTRY] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
END

GO



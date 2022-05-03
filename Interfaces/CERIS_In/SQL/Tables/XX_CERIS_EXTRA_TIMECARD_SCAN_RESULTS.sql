use imapsstg


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_EXTRA_TIMECARD_SCAN_RESULTS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CERIS_EXTRA_TIMECARD_SCAN_RESULTS]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_EXTRA_TIMECARD_SCAN_RESULTS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_EXTRA_TIMECARD_SCAN_RESULTS] (

	[EMPL_ID] [varchar] (12) NOT NULL ,

	[MIN_TS_DT] [datetime] NULL ,
	[MAX_TS_DT] [datetime] NULL ,

	[EXTRA_HRS] [decimal] (14,2) NOT NULL ,

	[DIVISION] [char] (2) NOT NULL ,
	[DIVISION_START_DT] [datetime] NOT NULL ,
	[DIVISION_FROM] [char] (2) NULL ,

	[CERIS_CHANGE_RUN_DT] [datetime] NULL,

	[CREATED_BY] [varchar] (50) NOT NULL ,
	[CREATED_DT] [datetime] NOT NULL 
) ON [PRIMARY]
END


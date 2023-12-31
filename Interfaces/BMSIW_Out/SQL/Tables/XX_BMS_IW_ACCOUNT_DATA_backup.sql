if exists (select * from dbo.sysobjects where id = object_id(N'[XX_BMS_IW_ACCOUNT_DATA_backup]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_BMS_IW_ACCOUNT_DATA_backup]
GO

CREATE TABLE [XX_BMS_IW_ACCOUNT_DATA_backup] (
	[ACCOUNT_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CONTROL_GROUP_CD] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OWNING_DIV_CD] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OWNING_COUNTRY_CD] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OWNING_COMPANY_CD] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ACCT_TYP_CD] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OWNING_LOB_CD] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SOW_TYP_CD] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO



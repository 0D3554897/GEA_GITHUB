/****** Object:  Table [dbo].[XX_BMS_IW_ACCOUNT_DATA]    Script Date: 07/24/2006 11:10:30 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_BMS_IW_ACCOUNT_DATA]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_BMS_IW_ACCOUNT_DATA]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_BMS_IW_ACCOUNT_DATA]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_BMS_IW_ACCOUNT_DATA] (
	[ACCOUNT_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ACCT_DESCRIPT] [varchar] (28) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[STATUS] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CONTACT_NAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CONTACT_EMP_NUM] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CONTROL_GROUP_CD] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OWNING_DIV_CD] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OWNING_COUNTRY_CD] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OWNING_COMPANY_CD] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ACCT_TYP_CD] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OWNING_LOB_CD] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SOW_TYP_CD] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
END

GO



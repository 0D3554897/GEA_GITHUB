if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_BMS_IW_DOU_DATA]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_BMS_IW_DOU_DATA]
GO

CREATE TABLE [dbo].[XX_BMS_IW_DOU_DATA] (
	[ACCOUNT_ID] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[JDE_PROJ_CODE] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CONTROL_GROUP_CD] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO



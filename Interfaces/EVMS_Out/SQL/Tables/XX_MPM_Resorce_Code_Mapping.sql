/****** Object:  Table [dbo].[XX_MPM_RESORCE_CODE_MAPPING]    Script Date: 8/1/2006 3:51:33 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_MPM_RESORCE_CODE_MAPPING]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_MPM_RESORCE_CODE_MAPPING]
GO

/****** Object:  Table [dbo].[XX_MPM_RESORCE_CODE_MAPPING]  
  This table is used by XX_MPM_INTERFACE_SETUP_SP 
and is populated by XX_MPM_RESORCE_MAPPING_UPDATE DTS package  Script Date: 8/1/2006 3:51:35 PM ******/
CREATE TABLE [dbo].[XX_MPM_RESORCE_CODE_MAPPING] (
	[IMAPS_GLC] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[IMAPS_LABOR_GROUP] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MPM_RESOURCE_CD] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
GO


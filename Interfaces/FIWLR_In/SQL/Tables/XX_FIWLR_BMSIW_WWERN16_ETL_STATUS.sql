USE [IMAPSStg]
GO
/****** Object:  Table [dbo].[XX_FIWLR_BMSIW_WWERN16_ETL_STATUS]    Script Date: 07/11/2009 07:50:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_BMSIW_WWERN16_ETL_STATUS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_FIWLR_BMSIW_WWERN16_ETL_STATUS]
GO

CREATE TABLE [dbo].[XX_FIWLR_BMSIW_WWERN16_ETL_STATUS](
 ROW_ID										int IDENTITY(1,1) NOT NULL,
 CREATED_USER								varchar(30) NOT NULL,
 CREATED_DATE								datetime DEFAULT(getdate()) NOT NULL,
 STATUS_CODE								varchar(30) NOT NULL,

 RECORD_COUNT								int NULL,
 CHRG_AMT									decimal(19, 2) NULL,
 MIN_CREATED_TMS							nvarchar(26) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 MAX_CREATED_TMS							nvarchar(26) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	
 MODIFIED_USER								varchar(30) NOT NULL,
 MODIFIED_DATE								datetime DEFAULT(getdate()) NOT NULL,


) ON [PRIMARY]

GO
SET ANSI_PADDING OFF




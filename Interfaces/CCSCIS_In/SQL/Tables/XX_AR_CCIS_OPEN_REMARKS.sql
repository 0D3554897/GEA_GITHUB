/****** Object:  Table [dbo].[XX_AR_CCIS_OPEN_REMARKS]    Script Date: 10/04/2006 9:50:20 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CCIS_OPEN_REMARKS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_AR_CCIS_OPEN_REMARKS]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CCIS_OPEN_REMARKS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_AR_CCIS_OPEN_REMARKS] (
	[CUSTNO] [char] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[INVNO] [char] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TIME_STAMP] [char] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AMTOPEN] [char] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ACTIONDATE] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[REMARK] [char] (43) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
END

GO



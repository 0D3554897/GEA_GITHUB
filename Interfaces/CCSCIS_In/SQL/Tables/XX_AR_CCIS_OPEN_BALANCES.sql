/****** Object:  Table [dbo].[XX_AR_CCIS_OPEN_BALANCES]    Script Date: 1/11/2006 3:35:15 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CCIS_OPEN_BALANCES]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_AR_CCIS_OPEN_BALANCES]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CCIS_OPEN_BALANCES]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_AR_CCIS_OPEN_BALANCES] (
	[INVNO] [char] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[INVC_DT] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CUSTNAME] [char] (28) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CUSTNO] [char] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ENTRYDATE] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[GROSSINV] [char] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[BALANCE] [char] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TAXAMT] [char] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LPFAMT] [char] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ACTIVIN] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ACTINMIN] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VALIDATED] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
END

GO



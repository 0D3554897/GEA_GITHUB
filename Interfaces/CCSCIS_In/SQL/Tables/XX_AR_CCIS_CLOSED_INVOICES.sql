/****** Object:  Table [dbo].[XX_AR_CCIS_CLOSED_INVOICES]    Script Date: 12/21/2005 4:29:58 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CCIS_CLOSED_INVOICES]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_AR_CCIS_CLOSED_INVOICES]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CCIS_CLOSED_INVOICES]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_AR_CCIS_CLOSED_INVOICES] (
	[ACTIV_KEY] [int] NOT NULL ,
	[VALIDATED] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
END

GO



/****** Object:  Table [dbo].[XX_AR_CCIS_ACTIV_ARCH]    Script Date: 1/11/2006 3:34:35 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CCIS_ACTIV_ARCH]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_AR_CCIS_ACTIV_ARCH]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CCIS_ACTIV_ARCH]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_AR_CCIS_ACTIV_ARCH] (
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[INVNO] [char] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[INVC_DT] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[COMPANY] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CUSTNO] [char] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CUSTNAME] [char] (28) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CHECKDATE] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CLEARDATE] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ENTRYDATE] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[GROSSINV] [char] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TAXAMT] [char] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LPFAMT] [char] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ACTIVIN] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ACTINMIN] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ACTIVOUT] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ACTOUTMIN] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CHECKNO] [char] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DIRDEBIT] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PPFLAG] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PPD] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[REINSTATED] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TIME_STAMP] [char] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PROCESSOR] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[SUBBATCH] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
END

GO



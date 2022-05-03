/****** Object:  Table [dbo].[XX_AR_CCIS_OPEN_BALANCES_ARCH]    Script Date: 1/11/2006 3:35:51 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CCIS_OPEN_BALANCES_ARCH]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_AR_CCIS_OPEN_BALANCES_ARCH]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CCIS_OPEN_BALANCES_ARCH]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_AR_CCIS_OPEN_BALANCES_ARCH] (
	[INVNO] [char] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[INVC_DT] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CUSTNO] [char] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[BALANCE] [char] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VALIDATED] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[IMAPS_INVC_ID] [char] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[IMAPS_BALANCE] [decimal](14, 2) NULL ,
	[TRN_AMT] [decimal](14, 2) NULL ,
	[STATUS_RECORD_NUM] [int] NULL 
) ON [PRIMARY]
END

GO



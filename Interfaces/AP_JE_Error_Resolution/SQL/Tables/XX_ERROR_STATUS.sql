/****** Object:  Table [dbo].[XX_ERROR_STATUS]    Script Date: 06/20/2006 3:28:45 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_ERROR_STATUS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_ERROR_STATUS]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_ERROR_STATUS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_ERROR_STATUS] (
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[ERROR_SEQUENCE_NO] [int] NOT NULL ,
	[INTERFACE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PREPROCESSOR] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[STATUS] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CONTROL_PT] [int] NOT NULL ,
	[TOTAL_COUNT] [int] NULL ,
	[SUCCESS_COUNT] [int] NULL ,
	[ERROR_COUNT] [int] NULL ,
	[TOTAL_AMOUNT] [decimal](14, 2) NULL ,
	[SUCCESS_AMOUNT] [decimal](14, 2) NULL ,
	[ERROR_AMOUNT] [decimal](14, 2) NULL ,
	[TIME_STAMP] [datetime] NOT NULL 
) ON [PRIMARY]
END

GO



if exists (select * from dbo.sysobjects where id = object_id(N'[XX_IMAPS_INT_STATUS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_IMAPS_INT_STATUS]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_IMAPS_INT_STATUS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [XX_IMAPS_INT_STATUS] (
	[STATUS_RECORD_NUM] [int] IDENTITY (1, 1) NOT NULL ,
	[INTERFACE_NAME] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[INTERFACE_TYPE] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[INTERFACE_SOURCE_SYSTEM] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[INTERFACE_DEST_SYSTEM] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[INTERFACE_FILE_NAME] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[INTERFACE_SOURCE_OWNER] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[INTERFACE_DEST_OWNER] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[STATUS_CODE] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[STATUS_DESCRIPTION] [varchar] (240) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[RECORD_COUNT_TRAILER] [numeric](9, 0) NULL ,
	[RECORD_COUNT_INITIAL] [numeric](9, 0) NULL ,
	[RECORD_COUNT_SUCCESS] [numeric](9, 0) NULL ,
	[RECORD_COUNT_ERROR] [numeric](9, 0) NULL ,
	[CREATED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CREATED_DATE] [datetime] NOT NULL ,
	[MODIFIED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MODIFIED_DATE] [datetime] NULL ,
	[AMOUNT_INPUT] [decimal](14, 2) NULL ,
	[AMOUNT_PROCESSED] [decimal](14, 2) NULL ,
	[AMOUNT_FAILED] [decimal](14, 2) NULL ,
	CONSTRAINT [PK_XX_IMAPS_INT_STATUS] PRIMARY KEY  CLUSTERED 
	(
		[STATUS_RECORD_NUM]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
END

GO



if exists (select * from dbo.sysobjects where id = object_id(N'[XX_PCLAIM_IN]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_PCLAIM_IN]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PCLAIM_IN]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [XX_PCLAIM_IN] (
	[PCLAIM_IN_RECORD_NUM] [int] IDENTITY (1, 1) NOT NULL ,
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[WORK_DATE] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VEND_EMPL_NAME] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PO_NUMBER] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VEND_EMPL_SERIAL_NUM] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_CODE] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VENDOR_ID] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DEPT_CODE] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[HOURS_CHARGED] [decimal](9, 2) NULL ,
	[COST] [decimal](9, 2) NULL ,
	[PLC] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[BILL_RATE] [decimal](9, 2) NULL ,
	[RECORD_TYPE] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VEND_NAME] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VEND_ST_ADDRESS] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VEND_CITY] [char] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VEND_STATE] [char] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VEND_COUNTRY] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CREATED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CREATED_DATE] [datetime] NOT NULL ,
	[MODIFIED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MODIFIED_DATE] [datetime] NULL ,
	[FY_CD] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PD_NO] [smallint] NULL ,
	[SUB_PD_NO] [smallint] NULL ,
	[VCHR_NO] [int] NULL ,
	[SUB_LN_NO] [smallint] NULL ,
	[VCHR_LN_NO] [smallint] NULL ,
	[VENDOR_ERROR] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_XX_PCLAIM_IN_VENDOR_ERROR] DEFAULT ('N'),
	CONSTRAINT [PK_XX_PCLAIM_IN] PRIMARY KEY  CLUSTERED 
	(
		[PCLAIM_IN_RECORD_NUM]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [FK_XX_PCLAIM_IN] FOREIGN KEY 
	(
		[STATUS_RECORD_NUM]
	) REFERENCES [XX_IMAPS_INT_STATUS] (
		[STATUS_RECORD_NUM]
	)
) ON [PRIMARY]
END

GO



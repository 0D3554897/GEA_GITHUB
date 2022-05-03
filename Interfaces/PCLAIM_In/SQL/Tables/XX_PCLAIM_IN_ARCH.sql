if exists (select * from dbo.sysobjects where id = object_id(N'[XX_PCLAIM_IN_ARCH]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_PCLAIM_IN_ARCH]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PCLAIM_IN_ARCH]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [XX_PCLAIM_IN_ARCH] (
	[PCLAIM_IN_RECORD_NUM] [bigint] NOT NULL ,
	[STATUS_RECORD_NUM] [int] NOT NULL ,
	[WORK_DATE] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VEND_EMPL_NAME] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PO_NUMBER] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VEND_EMPL_SERIAL_NUM] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PROJ_CODE] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[VENDOR_ID] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DEPT_CODE] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[HOURS_CHARGED] [char] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[COST] [char] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PLC] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[BILL_RATE] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
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
	[VCHR_NO] [int] NULL ,
	[SUB_LN_NO] [smallint] NULL ,
	[S_STATUS_CD] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VCHR_LN_NO] [smallint] NULL,
	[PAY_TYPE] [varchar](3) NULL,
	[UNID] [char](32) NULL,
	[REVISION_NUM] [char](5) NULL
	CONSTRAINT [PK_XX_PCLAIM_IN_ARCH] PRIMARY KEY  CLUSTERED 
	(
		[PCLAIM_IN_RECORD_NUM]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
END

GO



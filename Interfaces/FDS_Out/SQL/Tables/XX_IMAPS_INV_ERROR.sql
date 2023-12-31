if exists (select * from dbo.sysobjects where id = object_id(N'[XX_IMAPS_INV_ERROR]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_IMAPS_INV_ERROR]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_IMAPS_INV_ERROR]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_IMAPS_INV_ERROR] (
	[STATUS_RECORD_NUM] [int] NULL ,
	[ERROR_NUM] [int] IDENTITY (1, 1) NOT NULL ,
	[CUST_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[INVC_ID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[INVC_DT] [smalldatetime] NULL ,
	[ERROR_DESC] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MODIFIED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__XX_IMAPS___MODIF__7B7B4DDC] DEFAULT (user_name()),
	[TIME_STAMP] [datetime] NOT NULL CONSTRAINT [DF__XX_IMAPS___TIME___7C6F7215] DEFAULT (getdate())
) ON [PRIMARY]
END

GO



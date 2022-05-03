DROP TABLE [dbo].[XX_TEST_GENL_UDEF]

CREATE TABLE [dbo].[XX_TEST_GENL_UDEF] (
	[GENL_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[GENL1_ID] [int] NOT NULL ,
	[S_TABLE_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[UDEF_LBL_KEY] [int] NOT NULL ,
	[UDEF_TXT] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UDEF_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UDEF_DT] [smalldatetime] NULL ,
	[UDEF_AMT] [decimal](14, 4) NULL ,
	[MODIFIED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TIME_STAMP] [datetime] NOT NULL DEFAULT getdate(),
	[COMPANY_ID] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ROWVERSION] [int] NULL 
) ON [PRIMARY]
GO

GRANT SELECT, UPDATE, DELETE, INSERT on IMAPS.deltek.genl_udef TO IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT on dbo.xx_test_genl_udef TO IMAPSPRD,IMAPSSTG



USE [IMAPSStg]
GO

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'XX_RETRORATE_PAY_TYPES' AND type = 'U')
DROP TABLE XX_RETRORATE_PAY_TYPES

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[XX_RETRORATE_PAY_TYPES](
	[ROW_ID] [int] IDENTITY(1,1) NOT NULL, 
	[NON_ZERO_PAY_TYPE] [varchar] (3)  COLLATE SQL_Latin1_General_CP1_CI_AS,
	[RETRO_PAY_TYPE] [varchar] (3)  COLLATE SQL_Latin1_General_CP1_CI_AS,
	[CREATED_BY] [varchar] (50)  COLLATE SQL_Latin1_General_CP1_CI_AS,
	[CREATED_DATE] [datetime] NOT NULL,
	[MODIFIED_BY] [varchar] (50)  COLLATE SQL_Latin1_General_CP1_CI_AS,
	[MODIFIED_DATE] [datetime] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF


INSERT INTO XX_RETRORATE_PAY_TYPES
(non_zero_pay_type, retro_pay_type, created_by, created_date, modified_by, modified_date)
SELECT 'R', 'RO', 'imapsprd', getdate(), 'imapsprd', getdate()

INSERT INTO XX_RETRORATE_PAY_TYPES
(non_zero_pay_type, retro_pay_type, created_by, created_date, modified_by, modified_date)
SELECT 'STB', 'STO', 'imapsprd', getdate(), 'imapsprd', getdate()

INSERT INTO XX_RETRORATE_PAY_TYPES
(non_zero_pay_type, retro_pay_type, created_by, created_date, modified_by, modified_date)
SELECT 'STW', 'SWO', 'imapsprd', getdate(), 'imapsprd', getdate()


USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_LCDB_CODES_STG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_CERIS_LCDB_CODES_STG]
GO

CREATE TABLE [dbo].[XX_CERIS_LCDB_CODES_STG](

	[GLC_RecNo] int,
	[GLC_Code] nvarchar(6) NOT NULL,
	[GLC_Title] nvarchar(255) NOT NULL,

	[GLC_Short_Title] nvarchar(30) NOT NULL,

	[TYPE_DESC] nvarchar(20) NULL,
	[LOCA_DESC] nvarchar(20) NULL,
	[GRAD_DESC] nvarchar(20) NULL,
	[CATE_DESC] nvarchar(100) NULL,

	[CREATION_DATE] [datetime] NOT NULL DEFAULT getdate(),
	[CREATED_BY] [varchar](35) NOT NULL DEFAULT suser_sname()

) ON [PRIMARY]

GO
SET ANSI_PADDING OFF


/*
insert into XX_CERIS_LCDB_CODES_STG
(GLC_RecNo, GLC_Code, GLC_Title)
select 0, 'TTTT00', 'DEV TEST ONLY' --, current_timestamp, suser_sname()
*/


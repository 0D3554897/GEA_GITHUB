use imapsstg

/****** Object:  Table [dbo].[XX_CERIS_NON_EXEMPT_WKL_MAPPING]    Script Date: 07/21/2006 12:56:24 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_NON_EXEMPT_WKL_MAPPING]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CERIS_NON_EXEMPT_WKL_MAPPING]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_NON_EXEMPT_WKL_MAPPING]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_NON_EXEMPT_WKL_MAPPING] (


	[ROW_NUM] [int] IDENTITY(1,1) NOT NULL,

	[WKLCITY] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[WKLST] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[SALSETID] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,


	[CREATED_BY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CREATED_DATE] [datetime] NOT NULL ,

) ON [PRIMARY]
END

GO



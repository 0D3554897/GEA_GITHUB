if exists (select * from dbo.sysobjects where id = object_id(N'[XX_FIWLR_INC_EXC]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_FIWLR_INC_EXC]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_INC_EXC]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_FIWLR_INC_EXC] (
	[INC_EXC_ID] [int] IDENTITY (1, 1) NOT NULL ,
	[MAJOR] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MINOR] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SUBMINOR] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXTRACT_TYPE] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
END

GO



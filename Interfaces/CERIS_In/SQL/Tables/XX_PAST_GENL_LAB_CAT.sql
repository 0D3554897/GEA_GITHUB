
/****** Object:  Table [dbo].[XX_PAST_GENL_LAB_CAT]    Script Date: 04/03/2007 9:45:13 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PAST_GENL_LAB_CAT]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_PAST_GENL_LAB_CAT]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PAST_GENL_LAB_CAT]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_PAST_GENL_LAB_CAT] (
	[GENL_LAB_CAT_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[GENL_AVG_RT_AMT] [decimal](10, 4) NULL ,
	[FY_CD] [int] NULL 
) ON [PRIMARY]
END

GO
                                                                                                                   
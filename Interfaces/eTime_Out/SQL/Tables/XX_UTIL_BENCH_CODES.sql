/****** Object:  Table [dbo].[XX_UTIL_BENCH_CODES]    Script Date: 07/24/2006 11:11:35 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_UTIL_BENCH_CODES]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_UTIL_BENCH_CODES]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_UTIL_BENCH_CODES]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_UTIL_BENCH_CODES] (
	[PROJ_ABBRV_CD] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
END

GO



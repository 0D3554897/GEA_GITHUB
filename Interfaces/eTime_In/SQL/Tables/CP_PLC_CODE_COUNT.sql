if exists (select * from dbo.sysobjects where id = object_id(N'[CP_PLC_CODE_COUNT]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [CP_PLC_CODE_COUNT]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CP_PLC_CODE_COUNT]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [CP_PLC_CODE_COUNT] (
	[PLC_COUNT] [int] NULL ,
	[CREATE_DATE] [datetime] NULL CONSTRAINT [DF__CP_PLC_CO__CREAT__25B31578] DEFAULT (getdate())
) ON [PRIMARY]
END

GO



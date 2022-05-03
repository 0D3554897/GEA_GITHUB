USE [IMAPSStg]
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_EMP_V]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_R22_FIWLR_EMP_V]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

/* EMPLOYEE table was removed on ledger side and IMAPS changed to pulling names from Costpoint tables CR9841 

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_EMP_V]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_R22_FIWLR_EMP_V](
	[EMPLOYEE_NO] [varchar](6) NULL,
	[EMP_LASTNAME] [varchar](30) NULL,
	[EMP_FIRSTNAME] [varchar](30) NULL,
	[CREATION_DATE] [datetime] NOT NULL CONSTRAINT [NN_XX_R22_FIWLR_EMPV_CDATE]  DEFAULT (getdate())
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF

*/
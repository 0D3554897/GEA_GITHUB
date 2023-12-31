if exists (select * from dbo.sysobjects where id = object_id(N'[XX_FIWLR_EMP_V]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_FIWLR_EMP_V]
GO

/* EMPLOYEE table was removed on ledger side and IMAPS changed to pulling names from Costpoint tables CR9840 


if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_EMP_V]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_FIWLR_EMP_V] (
	[EMPLOYEE_NO] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EMP_LASTNAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EMP_FIRSTNAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CREATION_DATE] [datetime] NOT NULL CONSTRAINT [NN_XX_FIWLR_EMPV_CDATE] DEFAULT (getdate())
) ON [PRIMARY]
END

GO
*/


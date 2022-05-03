USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_LCDB_EMPL_ASSIGNMENTS_DEFALTS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_CERIS_LCDB_EMPL_ASSIGNMENTS_DEFALTS]
GO

CREATE TABLE [dbo].[XX_CERIS_LCDB_EMPL_ASSIGNMENTS_DEFALTS](


[Emp_RecNo] int NOT NULL,
[SerialNo] nvarchar(6),
[StatusCode] nvarchar(8),
[Emp_StartDate] datetime,
[Emp_EndDate] datetime,
[GLC_RecNo] int,
[GLC_Code] nvarchar(6) NOT NULL,
[EmpGLC_StartDate] datetime,
[EmpGLC_EndDate] datetime,

[CREATION_DATE] [datetime] NOT NULL DEFAULT getdate(),
[CREATED_BY] [varchar](35) NOT NULL DEFAULT suser_sname()

) ON [PRIMARY]

GO
SET ANSI_PADDING OFF


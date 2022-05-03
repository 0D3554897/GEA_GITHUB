USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_LCDB_EMPL_ASSIGNMENTS_STG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_CERIS_LCDB_EMPL_ASSIGNMENTS_STG]
GO

CREATE TABLE [dbo].[XX_CERIS_LCDB_EMPL_ASSIGNMENTS_STG](


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


/*
insert into XX_CERIS_LCDB_EMPL_ASSIGNMENTS_STG
(Emp_RecNo, SerialNo, StatusCode, Emp_StartDate, Emp_EndDate, GLC_RecNo, GLC_Code, EmpGLC_StartDate, EmpGLC_EndDate)
select 0, EMPL_ID,  '?', null, null, 0, 'TTTT00', '2012-01-01', null --, current_timestamp, suser_sname()
from XX_CERIS_DATA_STG
where division in ('16','1M')

*/


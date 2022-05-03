
USE [IMAPSStg]
GO
use imapsstg

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_T2R_EMPLOYEES]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_CERIS_T2R_EMPLOYEES]
GO

CREATE TABLE [dbo].[XX_CERIS_T2R_EMPLOYEES](

	[EMPL_ID] [varchar](6) NOT NULL,
	[HRLY_AMT] [decimal](14,4) NOT NULL,
	[EFFECT_DT] smalldatetime NOT NULL,

	[MODIFIED_BY] [varchar](35) NOT NULL DEFAULT suser_sname(),
	[TIME_STAMP] [datetime] NOT NULL DEFAULT getdate()

) ON [PRIMARY]

GO
SET ANSI_PADDING OFF

/*
TODO, get list of employees and hourly amounts

test employee

insert into xx_ceris_t2r_employees
(empl_id, hrly_amt, effect_dt)
select '3D0647',51.2345,'2012-12-29'

*/





USE [IMAPSStg]
GO
use imapsstg

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_T2R_EMPLOYEES_SALARY_FACTOR]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_CERIS_T2R_EMPLOYEES_SALARY_FACTOR]
GO

CREATE TABLE [dbo].[XX_CERIS_T2R_EMPLOYEES_SALARY_FACTOR](

	[EMPL_ID] [varchar](6) NOT NULL,
	[SALARY_FACTOR] [decimal](14,10) NOT NULL,
	[EFFECT_DT] smalldatetime NOT NULL,

	[MODIFIED_BY] [varchar](35) NOT NULL DEFAULT suser_sname(),
	[TIME_STAMP] [datetime] NOT NULL DEFAULT getdate()

) ON [PRIMARY]

GO
SET ANSI_PADDING OFF

/*
TODO, get list of employees and factor
*/




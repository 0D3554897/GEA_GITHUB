/*
 * Defect 1425 10/11/2006 - Get rid of the constraint of having the same PLC setup for the same project more than once.
 * (Although nothing is setup like this right now, Costpoint does allow this to happen.)
 */

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CP_PLC_CODE]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   drop table [dbo].[CP_PLC_CODE]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CP_PLC_CODE]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)

BEGIN

CREATE TABLE [dbo].[CP_PLC_CODE] (
	[PROJECT_ID] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PLC] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PLC_DESC] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PLC_STATUS] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PLC_DATE_OPN] [datetime] NULL ,
	[PLC_DATE_CLSD] [datetime] NULL ,
	[CREATE_DT] [datetime] NULL CONSTRAINT [DF__CP_PLC_CO__CREAT__23CACD06] DEFAULT (getdate()),
	[UPDATE_FLG] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PLC_UPDATE_DT] [datetime] NULL 
) ON [PRIMARY]

END

GO
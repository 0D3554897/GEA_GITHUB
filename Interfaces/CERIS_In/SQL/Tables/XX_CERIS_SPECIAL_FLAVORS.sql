USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_SPECIAL_FLAVORS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_CERIS_SPECIAL_FLAVORS]
GO

CREATE TABLE [dbo].[XX_CERIS_SPECIAL_FLAVORS](

		
		[DATACOL_NAME]	varchar(10) NOT NULL,
		[FLAVOR] varchar(10) NOT NULL,
		[REG_TEMP] char(1) NOT NULL,
		[FLSA_STAT] varchar(3) NOT NULL,
		[NOT_STAT3] varchar(1) NOT NULL,


		[STAT3] varchar(1) NOT NULL,

		[DAYS_PER_WEEK] decimal(4,2) NOT NULL,
                                             
	[CREATION_DATE] [datetime] NOT NULL DEFAULT getdate(),
	[CREATED_BY] [varchar](35) NOT NULL DEFAULT suser_sname()

) ON [PRIMARY]

GO
SET ANSI_PADDING OFF


/*
Special types of Supplementals

--weekly hours, montly salary (standard, not special)
   2         Long Term Supplemental 
*/


/*
--daily hours, daily salary, full time (5 days per week)
   A         Full Time Supplemental - Other Student
            (US Use Only)

   D         Full Time Supplemental - Non-student

   E         Full Time Supplemental - Pre-professional/Co-Op/Faculty
*/
--config rows to transform hours to weekly
insert into XX_CERIS_SPECIAL_FLAVORS
(DATACOL_NAME, FLAVOR, REG_TEMP, FLSA_STAT, NOT_STAT3, STAT3, DAYS_PER_WEEK)
select 'STD_HRS', 'DAILY_FULL', '3', 'E', '2', 'A', 5.0
go
insert into XX_CERIS_SPECIAL_FLAVORS
(DATACOL_NAME, FLAVOR, REG_TEMP, FLSA_STAT, NOT_STAT3, STAT3, DAYS_PER_WEEK)
select 'STD_HRS', 'DAILY_FULL', '3', 'E', '2', 'D', 5.0
go
insert into XX_CERIS_SPECIAL_FLAVORS
(DATACOL_NAME, FLAVOR, REG_TEMP, FLSA_STAT, NOT_STAT3, STAT3, DAYS_PER_WEEK)
select 'STD_HRS', 'DAILY_FULL', '3', 'E', '2', 'E', 5.0
go
--config row to identify special salary calculation (because of updated hours factor)
insert into XX_CERIS_SPECIAL_FLAVORS
(DATACOL_NAME, FLAVOR, REG_TEMP, FLSA_STAT, NOT_STAT3, STAT3, DAYS_PER_WEEK)
select 'SALARY', 'DAILY_FULL', '3', 'E', '2', 'A', 0
go
insert into XX_CERIS_SPECIAL_FLAVORS
(DATACOL_NAME, FLAVOR, REG_TEMP, FLSA_STAT, NOT_STAT3, STAT3, DAYS_PER_WEEK)
select 'SALARY', 'DAILY_FULL', '3', 'E', '2', 'D', 0
go
insert into XX_CERIS_SPECIAL_FLAVORS
(DATACOL_NAME, FLAVOR, REG_TEMP, FLSA_STAT, NOT_STAT3, STAT3, DAYS_PER_WEEK)
select 'SALARY', 'DAILY_FULL', '3', 'E', '2', 'E', 0
go


/*
--daily hours, daily salary, part time (? days per week)
--we are going to leave their standard hours as 1 day per week
--special case, we are going to treat these people as hourly
*/
--config row to identify special salary calculation
insert into XX_CERIS_SPECIAL_FLAVORS
(DATACOL_NAME, FLAVOR, REG_TEMP, FLSA_STAT, NOT_STAT3, STAT3, DAYS_PER_WEEK)
select 'SALARY', 'DAILY_PART', '3', 'E', '2', '*', 0
go


/*
NonExempt salary is always hourly, except for when
   2         Long Term Supplemental 
*/
--config row to identify special salary calculation
insert into XX_CERIS_SPECIAL_FLAVORS
(DATACOL_NAME, FLAVOR, REG_TEMP, FLSA_STAT, NOT_STAT3, STAT3, DAYS_PER_WEEK)
select 'SALARY', 'HOURLY', '3', 'N', '2', '*', 0
go


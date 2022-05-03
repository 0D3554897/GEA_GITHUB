use imapsstg

--backup XX_CERIS_DIV16_STATUS just in case there is a mess up in the order of operations of this build
select *
into xx_ceris_div16_status_CR6534_bkp
from xx_ceris_div16_status

go

--drop and recreate table
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_DIV16_STATUS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CERIS_DIV16_STATUS]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_DIV16_STATUS]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_DIV16_STATUS] (
	[EMPL_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,

	[DIVISION] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DIVISION_START_DT] [datetime] NOT NULL ,
	[DIVISION_FROM] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CREATED_BY] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CREATION_DT] [datetime] NULL ,


	[PREV_DIVISION] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PREV_DIVISION_START_DT] [datetime] NULL ,
	[PREV_DIVISION_FROM] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PREV_CREATION_DT] [datetime] NULL 

) ON [PRIMARY]
END

GO


--populate table

--this is the logic in the update SP
--putting it here too for table initialization purposes

insert into XX_CERIS_DIV16_STATUS
(empl_id, division, division_start_dt, division_from, creation_dt, created_by, prev_division, prev_division_start_dt, prev_division_from, prev_creation_dt)
select 
	cur.empl_id, 
	cur.division, 
	cur.division_start_dt, 
	cur.division_from, 
	cur.creation_dt,
	cur.created_by,
	prev.division as prev_division,
	prev.division_start_dt as prev_division_start_dt,
	prev.division_from as prev_division_from,
	prev.creation_dt as prev_creation_dt

from
xx_ceris_div16_status_orig cur
left join
xx_ceris_div16_status_orig prev
on
(cur.empl_id=prev.empl_id
and
 prev.creation_dt=(select max(creation_dt)
					from xx_ceris_div16_status_orig
					where empl_id=prev.empl_id
					and creation_dt<cur.creation_dt)
)


go




declare @max_swivel as int

select @max_swivel=cast(parameter_value as int)
from xx_processing_parameters
where interface_name_cd='CERIS'
and parameter_name='DIVISION_START_DATE_max_swivel'

delete t1
from xx_ceris_div16_status t1
where
0<> --not these records (these records are old, the division start date value has been retro-actively overwritten with a new value)
 (select count(1) 
  from xx_ceris_div16_status
  where  empl_id=t1.empl_id
  and	 isnull(prev_creation_dt,'1900-01-01')=t1.creation_dt
  and	 division=isnull(prev_division,'')
  and    isnull(division_from,'')=isnull(prev_division_from,'')
  --not deleting old record if the division_start_date value is being changed by more than X days
  --that's way too long and most likely some sort of user error
  and    abs(datediff(dd, t1.division_start_dt, division_start_dt)) <= @max_swivel --180
)



delete t1 --select *
from xx_ceris_div16_status t1
where
0<> --not these records (these records are old, the division value has been retro-actively overwritten with a new value)
 (select count(1) 
  from xx_ceris_div16_status
  where  empl_id=t1.empl_id
  and	 isnull(prev_creation_dt,'1900-01-01')=t1.creation_dt
  and	 division_start_dt=isnull(prev_division_start_dt,'')
  and    isnull(division_from,'')=isnull(prev_division_from,''))



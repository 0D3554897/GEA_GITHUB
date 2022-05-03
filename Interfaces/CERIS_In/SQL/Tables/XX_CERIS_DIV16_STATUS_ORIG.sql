use imapsstg


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_DIV16_STATUS_ORIG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_CERIS_DIV16_STATUS_ORIG]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_DIV16_STATUS_ORIG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_CERIS_DIV16_STATUS_ORIG] (
	[EMPL_ID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DIVISION] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DIVISION_START_DT] [datetime] NOT NULL ,
	[DIVISION_FROM] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CREATED_BY] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CREATION_DT] [datetime] NULL 
) ON [PRIMARY]
END

GO



--rebuild table using ETIME CERIS data
insert into XX_CERIS_DIV16_STATUS_ORIG
select 
	   EMP_NO as EMPL_ID,
	   DIVISION as DIVISION,
	   DIV_STRT_DATE as DIVISION_START_DT,
	   isnull(DIV_FROM,'') as DIVISION_FROM,	   
	   suser_sname() as created_by,
	   CREATE_DATE as CREATION_DT
from XX_FIWLR_CERIS_EMP et
where 
DIV_STRT_DATE is not null
and
TERM_DATE is null
group by emp_no, division, div_strt_date, DIV_FROM, CREATE_DATE


--insert new rows for treating terminations as a division
insert into XX_CERIS_DIV16_STATUS_ORIG
select EMP_NO as EMPL_ID,
	   '##' as DIVISION,
	   TERM_DATE+1 as DIVISION_START_DT,
	   DIVISION as DIVISION_FROM,
	   suser_sname() as created_by,
	   min(CREATE_DATE)  as CREATION_DT  
from XX_FIWLR_CERIS_EMP et
where TERM_DATE is not null
group by emp_no, TERM_DATE, DIVISION


--delete extra records
delete cur
from
xx_ceris_div16_status_orig cur
inner join --needs to be inner join
xx_ceris_div16_status_orig prev
on
(cur.empl_id=prev.empl_id
and
 prev.creation_dt=isnull((select max(creation_dt)
					from xx_ceris_div16_status_orig
					where empl_id=prev.empl_id
					and creation_dt<cur.creation_dt),'1900-01-01')
)
where
cur.division=prev.division
and
cur.division_start_dt=prev.division_start_dt
and
cur.division_from=prev.division_from
--we only want the original record (not the extra dates associated with dept changes in this table)


--insert new rows for treating newhire/transfer in as division before it happens
insert into XX_CERIS_DIV16_STATUS_ORIG
select EMP_NO as EMPL_ID,
	   '--' as DIVISION,
	   '1900-01-01' as DIVISION_START_DT,
	   '--' as DIVISION_FROM,
	   suser_sname() as created_by,	
	   min(CREATE_DATE)-13 as CREATION_DT  --need to manipulate this date
from XX_FIWLR_CERIS_EMP et
group by emp_no

--insert new rows for when employee drops off file (we are already capturing this in existing table)
insert into XX_CERIS_DIV16_STATUS_ORIG
select * from XX_CERIS_DIV16_STATUS where division='??'
--select * from XX_CERIS_DIV16_STATUS_prd_20130910 where division='??' --DEV only


use imapsstg

--backup staging table
select *
into DR6119_XX_CERIS_PAY_DIFFERENTIAL_FROM_LAST_WEEK_bkp
from XX_CERIS_PAY_DIFFERENTIAL_FROM_LAST_WEEK

--update staging table with fix
update XX_CERIS_PAY_DIFFERENTIAL_FROM_LAST_WEEK
set PAY_DIFFERENTIAL_DT=convert(char(10),PAY_DIFFERENTIAL_DT,120)
where PAY_DIFFERENTIAL_DT<>convert(char(10),PAY_DIFFERENTIAL_DT,120)


--backup ELI
select *
into DR6119_EMPL_LAB_INFO_bkp
from imaps.deltek.empl_lab_info

--create working table for employees with problem records
select *
into DR6119_EMPL_LAB_INFO_working
from imaps.deltek.empl_lab_info
where
empl_id in
(select empl_id
 from imaps.deltek.empl_lab_info
 where effect_dt<>convert(char(10),effect_dt,120)
 or end_dt<>convert(char(10),end_dt,120))

--fix start dates that have hours/mins/seconds
update DR6119_EMPL_LAB_INFO_working
set effect_dt=convert(char(10),effect_dt,120)
where effect_dt<>convert(char(10),effect_dt,120)

--fix end dates that have hours/mins/seconds
update DR6119_EMPL_LAB_INFO_working
set end_dt=convert(char(10),end_dt,120)
where end_dt<>convert(char(10),end_dt,120)


--delete from ELI for employees with problem records
delete from imaps.deltek.empl_lab_info
where empl_id in
(select empl_id
 from DR6119_EMPL_LAB_INFO_working)

--insert into ELI for employees with problem records fixed
insert into imaps.deltek.empl_lab_info
select *
from DR6119_EMPL_LAB_INFO_working


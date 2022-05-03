-- change from smallint to decimal

alter table XX_CERIS_CP_STG	
alter column WORK_YR_HRS_NO decimal(10,2)
go

alter table XX_CERIS_CP_EMPL_LAB_STG	
alter column WORK_YR_HRS_NO decimal(10,2)
go

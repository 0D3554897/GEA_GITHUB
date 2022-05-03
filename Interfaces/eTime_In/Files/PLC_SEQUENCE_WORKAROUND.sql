update imaps.deltek.proj_cntl
set PLC_TM_RT_SEQ_CD = 'A'

GO


insert into imaps.deltek.proj_lab_cat
(PROJ_ID, BILL_LAB_CAT_CD, BILL_LAB_CAT_DESC, 
 MODIFIED_BY, TIME_STAMP, ROWVERSION, COMPANY_ID)
select distinct tm_rt_seq_1.srce_proj_id, plc.bill_lab_cat_cd, plc.bill_lab_cat_desc,
'DATACONV', CURRENT_TIMESTAMP, 4000, 1
from
imaps.deltek.proj_lab_cat plc
inner join
imaps.deltek.tm_rt_order tm_rt_seq_2
on
(
tm_rt_seq_2.srce_proj_id = plc.proj_id
and
tm_rt_seq_2.seq_no > 1
)
inner join
imaps.deltek.tm_rt_order tm_rt_seq_1
on
(
tm_rt_seq_1.proj_id = tm_rt_seq_2.proj_id
and 
tm_rt_seq_1.seq_no = 1
)
where 
plc.bill_lab_cat_cd not in
(select bill_lab_cat_cd from imaps.deltek.proj_lab_cat where proj_id = tm_rt_seq_1.srce_proj_id)
group by tm_rt_seq_1.srce_proj_id, plc.bill_lab_cat_cd, plc.bill_lab_cat_desc

GO

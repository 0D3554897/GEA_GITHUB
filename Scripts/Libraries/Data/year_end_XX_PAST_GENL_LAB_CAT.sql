--store current year GLC rates in XX_PAST_GENL_LAB_CAT
use imapsstg
insert into xx_past_genl_lab_cat
(genl_lab_cat_cd, genl_avg_rt_amt, fy_cd)
select genl_lab_cat_cd, genl_avg_rt_amt, datepart(year, getdate()) /*'2007'*/
from imaps.deltek.genl_lab_cat

--this query should return 0 rows, otherwise there is a problem
use imapsstg
select fy_cd, genl_lab_cat_cd
from xx_past_genl_lab_cat
group by  fy_cd, genl_lab_cat_cd
having count(1)>1

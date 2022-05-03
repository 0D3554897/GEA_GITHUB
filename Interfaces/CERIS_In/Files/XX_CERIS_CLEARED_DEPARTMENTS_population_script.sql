--script for adding a department with security clearance

declare @DEPT varchar(8)

set @DEPT = 'F9AA'  --this is the ORG_ABBRV_CD

delete from imapsstg.dbo.xx_ceris_cleared_departments
where CERIS_DEPT = @DEPT

insert into imapsstg.dbo.xx_ceris_cleared_departments
select ceris.genl_lab_cat_cd, @DEPT, imaps.genl_lab_cat_cd, 
'imapsstg', getdate(), 'imapsstg', getdate()
from 
imaps.deltek.genl_lab_cat ceris
inner join
imaps.deltek.genl_lab_cat imaps
on
(
substring(ceris.genl_lab_cat_cd, 3, 1) not in ('Z', 'M')
and 
substring(imaps.genl_lab_cat_cd, 3, 1) in ('Z')
and
substring(ceris.genl_lab_cat_cd, 1, 2) = substring(imaps.genl_lab_cat_cd, 1, 2)
and
substring(ceris.genl_lab_cat_cd, 4, 2) = substring(imaps.genl_lab_cat_cd, 4, 2)
)
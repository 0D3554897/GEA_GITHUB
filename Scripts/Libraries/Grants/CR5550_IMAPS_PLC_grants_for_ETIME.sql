use imaps
create synonym dbo.cp_plc_code for imapsstg.dbo.cp_plc_code
create synonym dbo.cp_plc_code_count for imapsstg.dbo.cp_plc_code_count
grant select on dbo.cp_plc_code to eteuser
grant select on dbo.cp_plc_code_count to eteuser

use imapsstg
grant select on imapsstg.dbo.cp_plc_code to eteuser
grant select on imapsstg.dbo.cp_plc_code_count to eteuser

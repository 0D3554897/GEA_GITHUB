/*
Test Query
select SUB_PD_BEGIN_DT,	SUB_PD_END_DT,
 datepart(dw,SUB_PD_BEGIN_DT), datepart(dw,SUB_PD_END_DT),
case WHEN datepart(dw,SUB_PD_BEGIN_DT)=7
    THEN datepart(dw,SUB_PD_END_DT)-1
ELSE  datepart(dw,SUB_PD_END_DT)-datepart(dw,SUB_PD_BEGIN_DT)+1
END SPLIT_VAL,
(case WHEN datepart(dw,SUB_PD_BEGIN_DT)=7
    THEN datepart(dw,SUB_PD_END_DT)-1
ELSE  datepart(dw,SUB_PD_END_DT)-datepart(dw,SUB_PD_BEGIN_DT)+1
END) * 20 SPLIT_PER
from XX_r22_sub_pd where ts_dt>='12-25-2009'
order by ts_dt, sub_pd_begin_dt

*/
---- Added DR-2809/ 08/03/10
-- Update Script, only once
update  XX_r22_sub_pd 
set SPLIT_VAL= case WHEN datepart(dw,SUB_PD_BEGIN_DT)=7
                    THEN datepart(dw,SUB_PD_END_DT)-1
                ELSE  datepart(dw,SUB_PD_END_DT)-datepart(dw,SUB_PD_BEGIN_DT)+1
                END,
    SPLIT_PER=(case WHEN datepart(dw,SUB_PD_BEGIN_DT)=7
                    THEN datepart(dw,SUB_PD_END_DT)-1
                ELSE  datepart(dw,SUB_PD_END_DT)-datepart(dw,SUB_PD_BEGIN_DT)+1
                END) * 20

where ts_dt>='01-01-2010'
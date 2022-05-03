use imapsstg
/*
--alter staging tables to include division on transactions 
*/
ALTER TABLE xx_cls_down ADD DIVISION CHAR(2)
GO
ALTER TABLE xx_cls_down_this_month_ytd ADD DIVISION CHAR(2)
GO
update xx_cls_down_this_month_ytd set DIVISION='16'
go
ALTER TABLE xx_cls_down_last_month_ytd ADD DIVISION CHAR(2)
GO
update xx_cls_down_last_month_ytd set DIVISION='16'
go
ALTER TABLE xx_cls_down_ytd_archive ADD DIVISION CHAR(2)
GO
update xx_cls_down_ytd_archive set DIVISION='16'
go

/*
--alter account mappings to include division
--initialize account mapping as identical to 16
*/
ALTER TABLE xx_cls_down_acct_mapping ADD DIVISION CHAR(2)
GO
update xx_cls_down_acct_mapping set DIVISION='16'
go
insert into xx_cls_down_acct_mapping
(IMAPS_ACCT_START,
IMAPS_ACCT_END,
CLS_MAJOR,
CLS_MINOR,
CLS_SUB_MINOR,
CONTRACT,
CUSTOMER,
PROJECT,
MACHINE_TYPE,
PRODUCT_ID,
APPLY_BURDEN,
REVERSE_FDS,
MULTIPLIER,
STUB,
CREATED_BY,
CREATED_DATE,
MODIFIED_BY,
MODIFIED_DATE, 
DIVISION)
select
IMAPS_ACCT_START,
IMAPS_ACCT_END,
CLS_MAJOR,
CLS_MINOR,
CLS_SUB_MINOR,
CONTRACT,
CUSTOMER,
PROJECT,
MACHINE_TYPE,
PRODUCT_ID,
APPLY_BURDEN,
REVERSE_FDS,
MULTIPLIER,
STUB,
suser_name() as CREATED_BY,
current_timestamp as CREATED_DATE,
suser_name() as MODIFIED_BY,
current_timestamp as MODIFIED_DATE,
'1M' as DIVISION
from xx_cls_down_acct_mapping


ALTER TABLE xx_cls_down_acct_serv_mapping ADD DIVISION CHAR(2)
GO
update xx_cls_down_acct_serv_mapping set DIVISION='16'
go
insert into xx_cls_down_acct_serv_mapping
(IMAPS_ACCT_START,
IMAPS_ACCT_END,
SERVICE_OFFERING,
CLS_MAJOR,
CLS_MINOR,
CLS_SUB_MINOR,
CONTRACT,
CUSTOMER,
PROJECT,
MACHINE_TYPE,
PRODUCT_ID,
APPLY_BURDEN,
REVERSE_FDS,
MULTIPLIER,
CREATED_BY,
CREATED_DATE,
MODIFIED_BY,
MODIFIED_DATE,
DIVISION)
select
IMAPS_ACCT_START,
IMAPS_ACCT_END,
SERVICE_OFFERING,
CLS_MAJOR,
CLS_MINOR,
CLS_SUB_MINOR,
CONTRACT,
CUSTOMER,
PROJECT,
MACHINE_TYPE,
PRODUCT_ID,
APPLY_BURDEN,
REVERSE_FDS,
MULTIPLIER,
suser_name() as CREATED_BY,
current_timestamp as CREATED_DATE,
suser_name() as MODIFIED_BY,
current_timestamp as MODIFIED_DATE,
'1M' as DIVISION
from xx_cls_down_acct_serv_mapping




ALTER TABLE xx_cls_down_acct_memo_mapping ADD DIVISION CHAR(2)
GO
update xx_cls_down_acct_memo_mapping set DIVISION='16'
go
insert into xx_cls_down_acct_memo_mapping
(
IMAPS_ACCT,
CLS_MAJOR,
CLS_MINOR,
CLS_SUB_MINOR,
CONTRACT,
CUSTOMER,
PROJECT,
MACHINE_TYPE,
PRODUCT_ID,
APPLY_BURDEN,
MULTIPLIER,
CREATED_BY,
CREATED_DATE,
MODIFIED_BY,
MODIFIED_DATE,
DIVISION
)
SELECT
IMAPS_ACCT,
CLS_MAJOR,
CLS_MINOR,
CLS_SUB_MINOR,
CONTRACT,
CUSTOMER,
PROJECT,
MACHINE_TYPE,
PRODUCT_ID,
APPLY_BURDEN,
MULTIPLIER,
suser_name() as CREATED_BY,
current_timestamp as CREATED_DATE,
suser_name() as MODIFIED_BY,
current_timestamp as MODIFIED_DATE,
'1M' as DIVISION
from xx_cls_down_acct_memo_mapping

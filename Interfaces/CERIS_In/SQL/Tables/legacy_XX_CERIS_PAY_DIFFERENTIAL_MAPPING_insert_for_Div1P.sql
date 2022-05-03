
insert into xx_ceris_pay_differential_mapping
(
SALSETID,
DIVISION,
DEPT,
PAY_DIFFERENTIAL,
CREATED_BY,
CREATED_DATE
)
SELECT 
'55' as SALSETID,
'1P' as DIVISION,
'*' as DEPT,
'R' as PAY_DIFFERENTIAL,
suser_name() as CREATED_BY,
current_timestamp as CREATED_DATE

insert into xx_ceris_pay_differential_mapping
(
SALSETID,
DIVISION,
DEPT,
PAY_DIFFERENTIAL,
CREATED_BY,
CREATED_DATE
)
SELECT 
'66' as SALSETID,
'1P' as DIVISION,
'*' as DEPT,
'N' as PAY_DIFFERENTIAL,
suser_name() as CREATED_BY,
current_timestamp as CREATED_DATE

insert into xx_ceris_pay_differential_mapping
(
SALSETID,
DIVISION,
DEPT,
PAY_DIFFERENTIAL,
CREATED_BY,
CREATED_DATE
)
SELECT 
'77' as SALSETID,
'1P' as DIVISION,
'*' as DEPT,
'P' as PAY_DIFFERENTIAL,
suser_name() as CREATED_BY,
current_timestamp as CREATED_DATE
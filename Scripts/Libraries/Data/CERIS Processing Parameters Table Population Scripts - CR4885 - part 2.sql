use imapsstg
go

-- this intended to run AFTER the first part
declare @interface_name_id integer

select @interface_name_id = LOOKUP_ID 
  from dbo.XX_LOOKUP_DETAIL 
 where APPLICATION_CODE = 'CERIS' 

--just to make things easier on SIT/DEV
declare @param_value sysname
select @param_value= PARAMETER_VALUE
from xx_processing_parameters
where interface_name_cd='CERIS'
and parameter_name='Actuals_EFFECT_DT'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
   VALUES(@interface_name_id, 'CERIS', 'min_SAL_HRS_CHANGE_EFFECT_DT', @param_value, SUSER_SNAME(), GETDATE())
go

declare @interface_name_id integer

select @interface_name_id = LOOKUP_ID 
  from dbo.XX_LOOKUP_DETAIL 
 where APPLICATION_CODE = 'CERIS' 

INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
   VALUES(@interface_name_id, 'CERIS', 'week_days_in_current_year', '261', SUSER_SNAME(), GETDATE())
go


--review
/*
select parameter_name, parameter_value
from xx_processing_parameters
where interface_name_cd='CERIS'
and parameter_name in ('min_SAL_HRS_CHANGE_EFFECT_DT','week_days_in_current_year')
*/

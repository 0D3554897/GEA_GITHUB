declare @int_name_id int 
select @int_name_id = PRESENTATION_ORDER 
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'FDS/CCS' 
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'FDS/CCS', 'COLL_OFF', '28W', SUSER_SNAME(), GETDATE()) 
go 
declare @int_name_id int 
select @int_name_id = PRESENTATION_ORDER 
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'FDS/CCS' 
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'FDS/CCS', 'COLL_DIV', '12', SUSER_SNAME(), GETDATE()) 
go 


declare @int_name_id int 
select @int_name_id = PRESENTATION_ORDER 
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'FDS/CCS' 
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'FDS/CCS', 'DFLT_TC_TAX', '38', SUSER_SNAME(), GETDATE()) 
go 
declare @int_name_id int 
select @int_name_id = PRESENTATION_ORDER 
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'FDS/CCS' 
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'FDS/CCS', 'DFLT_TC_PROD_CATGRY', '16', SUSER_SNAME(), GETDATE()) 
go 
declare @int_name_id int 
select @int_name_id = PRESENTATION_ORDER 
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'FDS/CCS' 
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'FDS/CCS', 'DFLT_TC_AGRMNT', 'G', SUSER_SNAME(), GETDATE()) 
go 


declare @int_name_id int 
select @int_name_id = PRESENTATION_ORDER 
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'FDS/CCS' 
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'FDS/CCS', 'OHW_TC_TAX', '01', SUSER_SNAME(), GETDATE()) 
go 
declare @int_name_id int 
select @int_name_id = PRESENTATION_ORDER 
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'FDS/CCS' 
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'FDS/CCS', 'OHW_TC_PROD_CATGRY', '16', SUSER_SNAME(), GETDATE()) 
go 
declare @int_name_id int 
select @int_name_id = PRESENTATION_ORDER 
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'FDS/CCS' 
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'FDS/CCS', 'OHW_TC_AGRMNT', 'A', SUSER_SNAME(), GETDATE()) 
go 




declare @int_name_id int 
select @int_name_id = PRESENTATION_ORDER 
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'FDS/CCS' 
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'FDS/CCS', 'OSW_TC_TAX', '23', SUSER_SNAME(), GETDATE()) 
go 
declare @int_name_id int 
select @int_name_id = PRESENTATION_ORDER 
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'FDS/CCS' 
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'FDS/CCS', 'OSW_TC_PROD_CATGRY', '08', SUSER_SNAME(), GETDATE()) 
go 
declare @int_name_id int 
select @int_name_id = PRESENTATION_ORDER 
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'FDS/CCS' 
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'FDS/CCS', 'OSW_TC_AGRMNT', 'F', SUSER_SNAME(), GETDATE()) 
go 



declare @int_name_id int 
select @int_name_id = PRESENTATION_ORDER 
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'FDS/CCS' 
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'FDS/CCS', 'WEB_TC_TAX', '86', SUSER_SNAME(), GETDATE()) 
go 
declare @int_name_id int 
select @int_name_id = PRESENTATION_ORDER 
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'FDS/CCS' 
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'FDS/CCS', 'WEB_TC_PROD_CATGRY', '16', SUSER_SNAME(), GETDATE()) 
go 
declare @int_name_id int 
select @int_name_id = PRESENTATION_ORDER 
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'FDS/CCS' 
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'FDS/CCS', 'WEB_TC_AGRMNT', 'G', SUSER_SNAME(), GETDATE()) 
go 






delete from dbo.xx_processing_parameters
where parameter_name = 'CSP_ACCT_ID'
go
INSERT INTO dbo.XX_PROCESSING_PARAMETERS
  (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
  VALUES(12, 'FDS/CCS', 'CSP_ACCT_ID', '48-79-08', SUSER_SNAME(), GETDATE())
go
INSERT INTO dbo.XX_PROCESSING_PARAMETERS
  (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
  VALUES(12, 'FDS/CCS', 'CSP_ACCT_ID', '49-79-08', SUSER_SNAME(), GETDATE())
go
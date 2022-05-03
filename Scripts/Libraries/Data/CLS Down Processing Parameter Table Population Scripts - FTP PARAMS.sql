use imapsstg

declare @int_name_id int 
select @int_name_id = LOOKUP_ID
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'CLS'
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'CLS', 'FTP_SERVER', 'stfmvs1.pok.ibm.com', system_user, GETDATE()) 
go 


declare @int_name_id int 
select @int_name_id = LOOKUP_ID
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'CLS'
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'CLS', 'FTP_USER', 'imaptso', system_user, GETDATE()) 
go 

declare @int_name_id int 
select @int_name_id = LOOKUP_ID
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'CLS'
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'CLS', 'FTP_PASS', 'walk5you', system_user, GETDATE()) 
go 

declare @int_name_id int 
select @int_name_id = LOOKUP_ID
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'CLS'
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'CLS', 'FTP_DEST_999FILE', 'imaptso.control.ledgrin', system_user, GETDATE()) 
go 

declare @int_name_id int 
select @int_name_id = LOOKUP_ID
from dbo.XX_LOOKUP_DETAIL 
where APPLICATION_CODE = 'CLS'
INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
  VALUES(@int_name_id,  'CLS', 'FTP_DEST_PARMFILE', 'imaptso.f155.parm', system_user, GETDATE()) 
go 


use imapsstg
go


-- Add required XX_PROCESSING_PARAMETERS records that serve as the application's global constants

declare @interface_name_id integer

select @interface_name_id = LOOKUP_ID 
  from dbo.XX_LOOKUP_DETAIL 
 where APPLICATION_CODE = 'CERIS_LOAD' 

INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
   VALUES(@interface_name_id, 'CERIS_LOAD', 'IN_SOURCE_SYSOWNER', 'egf@us.ibm.com', SUSER_SNAME(), GETDATE())
go


declare @interface_name_id integer

select @interface_name_id = LOOKUP_ID 
  from dbo.XX_LOOKUP_DETAIL 
 where APPLICATION_CODE = 'CERIS_LOAD' 

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
   VALUES(@interface_name_id, 'CERIS_LOAD', 'OUT_DESTINATION_SYSOWNER', 'egf@us.ibm.com', SUSER_SNAME(), GETDATE()) 
go


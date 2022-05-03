use imapsstg
go


-- Add required XX_PROCESSING_PARAMETERS records that serve as the application's global constants

declare @interface_name_id integer

select @interface_name_id = LOOKUP_ID 
  from dbo.XX_LOOKUP_DETAIL 
 where APPLICATION_CODE = 'CERIS' 

INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
   VALUES(@interface_name_id, 'CERIS', 'Actuals_EFFECT_DT', '2012-12-29', SUSER_SNAME(), GETDATE())
go



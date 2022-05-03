-- Add required XX_PROCESSING_PARAMETERS records that serve as the application's global constants

declare @interface_name_id integer

select @interface_name_id = PRESENTATION_ORDER 
  from dbo.XX_LOOKUP_DETAIL 
 where APPLICATION_CODE = 'PROJEMPL' 

INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
   VALUES(@interface_name_id, 'PROJEMPL', 'IMAPS_SCHEMA_OWNER', 'dbo', SUSER_SNAME(), GETDATE()) 
go


declare @interface_name_id integer

select @interface_name_id = PRESENTATION_ORDER 
  from dbo.XX_LOOKUP_DETAIL 
 where APPLICATION_CODE = 'PROJEMPL' 

INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
   VALUES(@interface_name_id, 'PROJEMPL', 'IN_SOURCE_SYSOWNER', 'veerabhadra.chowdary@us.ibm.com', SUSER_SNAME(), GETDATE())
go


declare @interface_name_id integer

select @interface_name_id = PRESENTATION_ORDER 
  from dbo.XX_LOOKUP_DETAIL 
 where APPLICATION_CODE = 'PROJEMPL' 

INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
   VALUES(@interface_name_id,  'PROJEMPL', 'IN_USER_NAME', 'imapsstg', SUSER_SNAME(), GETDATE()) 
go 


declare @interface_name_id integer

select @interface_name_id = PRESENTATION_ORDER 
  from dbo.XX_LOOKUP_DETAIL 
 where APPLICATION_CODE = 'PROJEMPL' 

INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
   VALUES(@interface_name_id, 'PROJEMPL', 'IN_USER_PASSWORD', 'sta1ging', SUSER_SNAME(), GETDATE()) 
go 


declare @interface_name_id integer

select @interface_name_id = PRESENTATION_ORDER 
  from dbo.XX_LOOKUP_DETAIL 
 where APPLICATION_CODE = 'PROJEMPL' 

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
   VALUES(@interface_name_id, 'PROJEMPL', 'OUT_DESTINATION_SYSOWNER', 'veerabhadra.chowdary@us.ibm.com', SUSER_SNAME(), GETDATE()) 
go


declare @interface_name_id integer

select @interface_name_id = PRESENTATION_ORDER 
  from dbo.XX_LOOKUP_DETAIL 
 where APPLICATION_CODE = 'PROJEMPL' 

INSERT INTO dbo.XX_PROCESSING_PARAMETERS 
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
   VALUES(@interface_name_id, 'PROJEMPL', 'TOTAL_NUMBER_OF_CTRL_PTS', '2', SUSER_SNAME(), GETDATE()) 
go


declare @interface_name_id integer

select @interface_name_id = PRESENTATION_ORDER 
  from dbo.XX_LOOKUP_DETAIL 
 where APPLICATION_CODE = 'PROJEMPL' 

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE) 
   VALUES(@interface_name_id, 'PROJEMPL', 'COMPANY_ID','2',  SUSER_SNAME(), GETDATE()) 
go

 
 

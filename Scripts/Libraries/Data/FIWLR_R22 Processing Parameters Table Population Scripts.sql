-- Add required XX_PROCESSING_PARAMETERS records that serve as the application's global constants

declare @int_name_id int
select @int_name_id= PRESENTATION_ORDER
from dbo.XX_LOOKUP_DETAIL
where APPLICATION_CODE = 'FIWLR_R22'
INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@int_name_id, 'FIWLR_R22', 'IN_SOURCE_SYSOWNER', 'main.user@org_name.org', SUSER_SNAME(), GETDATE())
go


declare @int_name_id int
select @int_name_id= PRESENTATION_ORDER
from dbo.XX_LOOKUP_DETAIL
where APPLICATION_CODE = 'FIWLR_R22'
INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@int_name_id, 'FIWLR_R22', 'IN_DESTINATION_SYSOWNER', 'first.last@org_name.org', SUSER_SNAME(), GETDATE())
go

declare @int_name_id int
select @int_name_id= PRESENTATION_ORDER
from dbo.XX_LOOKUP_DETAIL
where APPLICATION_CODE = 'FIWLR_R22'
INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@int_name_id, 'FIWLR_R22', 'IMAPS_DATABASE_NAME', 'IMAPSStg', SUSER_SNAME(), GETDATE())
go

declare @int_name_id int
select @int_name_id= PRESENTATION_ORDER
from dbo.XX_LOOKUP_DETAIL
where APPLICATION_CODE = 'FIWLR_R22'
INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@int_name_id, 'FIWLR_R22', 'IMAPS_SCHEMA_OWNER', 'dbo', SUSER_SNAME(), GETDATE())
go

declare @int_name_id int
select @int_name_id= PRESENTATION_ORDER
from dbo.XX_LOOKUP_DETAIL
where APPLICATION_CODE = 'FIWLR_R22'
INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@int_name_id, 'FIWLR_R22', 'FIWLR_R22_PROC_QUE_ID', 'SCH_ETIME_IN', SUSER_SNAME(), GETDATE())
go

declare @int_name_id int
select @int_name_id= PRESENTATION_ORDER
from dbo.XX_LOOKUP_DETAIL
where APPLICATION_CODE = 'FIWLR_R22'
INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@int_name_id, 'FIWLR_R22', 'FIWLR_R22_PROC_ID', 'FIWLR_R22', SUSER_SNAME(), GETDATE())
go

declare @int_name_id int
select @int_name_id= PRESENTATION_ORDER
from dbo.XX_LOOKUP_DETAIL
where APPLICATION_CODE = 'FIWLR_R22'
INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@int_name_id, 'FIWLR_R22', 'FIWLR_R22_PROC_SERVER_ID', ' ', SUSER_SNAME(), GETDATE())
go


declare @int_name_id int
select @int_name_id= LOOKUP_ID
from dbo.XX_LOOKUP_DETAIL
where APPLICATION_CODE = 'FIWLR_R22'
insert into dbo.xx_processing_parameters
values(@int_name_id,'FIWLR_R22','EXTRACT_START_DATE','2008-01-01',SUSER_SNAME(),GETDATE(),SUSER_SNAME(),GETDATE(), NULL)

go



update xx_processing_parameters
set parameter_value = 
	(select  substring(max(ref_creation_date), 1, 4) + '-' +
	substring(max(ref_creation_date), 5, 2)+ '-' +
	substring(max(ref_creation_date), 7, 2)
	from xx_r22_fiwlr_usdet_archive)
where interface_name_cd = 'FIWLR_R22'
and parameter_name = 'EXTRACT_START_DATE'

go


declare @int_name_id int
select @int_name_id= LOOKUP_ID
from dbo.XX_LOOKUP_DETAIL
where APPLICATION_CODE = 'FIWLR_R22'
insert into dbo.xx_processing_parameters
values(@int_name_id,'FIWLR_R22','BALANCING_ORG_ID','22',SUSER_SNAME(),GETDATE(),SUSER_SNAME(),GETDATE(), NULL)

go


declare @int_name_id int

SELECT @int_name_id = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t2.APPLICATION_CODE = 'FIWLR_R22'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@int_name_id, 'FIWLR_R22', 'COMPANY_ID', '2', SUSER_SNAME(), GETDATE())
go


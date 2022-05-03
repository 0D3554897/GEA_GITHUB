declare @int_name_id int
select @int_name_id= PRESENTATION_ORDER
from dbo.XX_LOOKUP_DETAIL
where APPLICATION_CODE = 'FIWLR'
insert into dbo.xx_processing_parameters
values(@int_name_id,'FIWLR','N16_DR_ACCT_ID','42-02-99',SUSER_SNAME(),GETDATE(),SUSER_SNAME(),GETDATE())
go


declare @int_name_id int
select @int_name_id= PRESENTATION_ORDER
from dbo.XX_LOOKUP_DETAIL
where APPLICATION_CODE = 'FIWLR'
insert into dbo.xx_processing_parameters
values(@int_name_id,'FIWLR','N16_CR_ACCT_ID','42-12-99',SUSER_SNAME(),GETDATE(),SUSER_SNAME(),GETDATE())

go



declare @int_name_id int
select @int_name_id= LOOKUP_ID
from dbo.XX_LOOKUP_DETAIL
where APPLICATION_CODE = 'FIWLR'
insert into dbo.xx_processing_parameters
values(@int_name_id,'FIWLR','EXTRACT_START_DATE','2007-02-06',SUSER_SNAME(),GETDATE(),SUSER_SNAME(),GETDATE())

go



update xx_processing_parameters
set parameter_value = 
	(select  substring(max(ref_creation_date), 1, 4) + '-' +
	substring(max(ref_creation_date), 5, 2)+ '-' +
	substring(max(ref_creation_date), 7, 2)
	from xx_fiwlr_usdet_archive)
where interface_name_cd = 'FIWLR'
and parameter_name = 'EXTRACT_START_DATE'

go



declare @int_name_id int
select @int_name_id= LOOKUP_ID
from dbo.XX_LOOKUP_DETAIL
where APPLICATION_CODE = 'FIWLR'
insert into dbo.xx_processing_parameters
values(@int_name_id,'FIWLR','BALANCING_ORG_ID','16',SUSER_SNAME(),GETDATE(),SUSER_SNAME(),GETDATE())

go

-- CP600000284_Begin
-- Costpoint multi-company fix

DECLARE @INTERFACE_NAME_ID integer

SELECT @INTERFACE_NAME_ID = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t2.APPLICATION_CODE = 'FIWLR'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@INTERFACE_NAME_ID, 'FIWLR', 'COMPANY_ID', '1', SUSER_SNAME(), GETDATE())
go
-- CP600000284_End

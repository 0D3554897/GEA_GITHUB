-- LOOK_DOMAIN 
insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE) 
 values('AR_CCIS Interface Control Points', 'LD_AR_CCIS_INTERFACE_CTRL_PT', SUSER_SNAME(), GETDATE()) 
go 
-- LOOKUP_DETAIL control points 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_AR_CCIS_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CCIS-001', 'Received New AR Inbound file', 1, SUSER_SNAME(), GETDATE(), null, null) 
go 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_AR_CCIS_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CCIS-002', 'Loaded IMAPS CCIS Staging Tables', 2, SUSER_SNAME(), GETDATE(), null, null) 
go 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_AR_CCIS_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CCIS-003', 'Performed Data Validations', 3, SUSER_SNAME(), GETDATE(), null, null) 
go 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_AR_CCIS_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CCIS-004', 'Inserted AR Data to Costpoint AR Tables', 4, SUSER_SNAME(), GETDATE(), null, null) 
go 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_AR_CCIS_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CCIS-005', 'Feedback Provided to Source System', 5, SUSER_SNAME(), GETDATE(), null, null) 
go 

--change KM 4/12/06
UPDATE 	dbo.XX_LOOKUP_DETAIL
SET	LOOKUP_DESCRIPTION = 'CCIS System'
WHERE	APPLICATION_CODE = 'AR_COLLECTION'
go
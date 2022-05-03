-- LOOK_DOMAIN 
insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE) 
 values('BMS_IW Interface Control Points', 'LD_BMS_IW_INTERFACE_CTRL_PT', SUSER_SNAME(), GETDATE()) 
go 

-- LOOKUP_DETAIL control points 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_BMS_IW_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'BMS_IW-001', 'Successful finish of Utilization Interface', 1, SUSER_SNAME(), GETDATE(), null, null) 
go 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_BMS_IW_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'BMS_IW-002', 'Create File', 2, SUSER_SNAME(), GETDATE(), null, null) 
go 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_BMS_IW_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'BMS_IW-003', 'Transferred data via FTP/Archived data', 3, SUSER_SNAME(), GETDATE(), null, null) 
go 

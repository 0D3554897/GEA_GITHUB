-- Defect 739 11/14/2006 HVT
-- Correct typographical error: 'LD_INTERFACE_RUN_TYPE' (singular) instead of 'LD_INTERFACE_RUN_TYPES' (plural).

-- LOOK_DOMAIN
insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
   values('7 Keys & PSP DB Interface Control Point', 'LD_7KEYS_INTERFACE_CTRL_PT', SUSER_SNAME(), GETDATE())
go

insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
   values('Interface Run Types', 'LD_INTERFACE_RUN_TYPE', SUSER_SNAME(), GETDATE())
go


-- LOOKUP_DETAIL interface name
declare @order int
select @order = (MAX(PRESENTATION_ORDER) + 1) 
from dbo.XX_LOOKUP_DETAIL
where lookup_domain_id = 1
insert into dbo.XX_LOOKUP_DETAIL values(1, '7KEYS/PSP', '7 Keys and PSP Database', @order, SUSER_SNAME(), GETDATE(), null, null)
go


-- LOOKUP_DETAIL interface run type
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_INTERFACE_RUN_TYPE' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'SCHEDULED', 'Scheduled', 1, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_INTERFACE_RUN_TYPE' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'MANUAL', 'Manually', 2, SUSER_SNAME(), GETDATE(), null, null)
go


-- LOOKUP_DETAIL control points 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_7KEYS_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, '7KEYS1', 'Load Costpoint data into staging tables', 1, SUSER_SNAME(), GETDATE(), null, null) 
go 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_7KEYS_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, '7KEYS2', 'Create output files', 2, SUSER_SNAME(), GETDATE(), null, null) 
go 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_7KEYS_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, '7KEYS3', 'Process output file for storage in the FTP directory and archive output data', 3, SUSER_SNAME(), GETDATE(), null, null) 
go 

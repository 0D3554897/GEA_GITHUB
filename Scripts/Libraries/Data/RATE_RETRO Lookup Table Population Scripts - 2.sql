


-- LOOKUP_DETAIL control points change
update 	dbo.XX_LOOKUP_DETAIL
set 	LOOKUP_DESCRIPTION = 'Archive previous run data and populate preprocessor staging table'
where	application_code = 'RETRORATE-001'
go

declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_RETRORATE_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'RETRORATE-002', 'Create Costpoint timesheet preprocessor flat file via bcp', 2, SUSER_SNAME(), GETDATE(), null, null) 
go 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_RETRORATE_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'RETRORATE-003', 'Run Costpoint timesheet preprocessor', 3, SUSER_SNAME(), GETDATE(), null, null) 
go 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_RETRORATE_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'RETRORATE-004', 'Process Costpoint timesheet preprocessor error log, if any', 4, SUSER_SNAME(), GETDATE(), null, null) 
go 

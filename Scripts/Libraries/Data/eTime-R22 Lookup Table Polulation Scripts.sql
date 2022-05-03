IF NOT EXISTS (select domain_constant from dbo.xx_lookup_domain where domain_constant='LD_ETIME_R_INTERFACE_CTRL_PT')
BEGIN
insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE) 
 values('eTime Research Interface Control Points', 'LD_ETIME_R_INTERFACE_CTRL_PT', SUSER_SNAME(), GETDATE()) 
    PRINT 'ROW Created' 
END
go

--Added 08/22/08
-- LOOKUP_DETAIL interface name
declare @order int
select @order = (MAX(PRESENTATION_ORDER) + 1) 
from dbo.XX_LOOKUP_DETAIL
where lookup_domain_id = 1
insert into dbo.XX_LOOKUP_DETAIL values(1, 'ETIME_R22', 'Research eTime System', @order, SUSER_SNAME(), GETDATE(), null, null)
go


-- LOOKUP_DETAIL control points 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_ETIME_R_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'ETIME_R1', 'Retrieve labor file from FTP directory', 1, SUSER_SNAME(), GETDATE(), null, null) 
go 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_ETIME_R_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'ETIME_R2', 'Load labor files into staging tables and validate input data', 2, SUSER_SNAME(), GETDATE(), null, null) 
go 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_ETIME_R_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'ETIME_R3', 'Create file for IMAPS preprocessor and notify Costpoint via database update', 3, SUSER_SNAME(), GETDATE(), null, null) 
go 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_ETIME_R_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'ETIME_R4', 'Execution of Costpoint timesheet preprocessor', 4, SUSER_SNAME(), GETDATE(), null, null) 
go 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_ETIME_R_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'ETIME_R5', 'Update Control and Error tables', 5, SUSER_SNAME(), GETDATE(), null, null) 
go 
declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_ETIME_R_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'ETIME_R6', 'Provide feedback to source systems', 6, SUSER_SNAME(), GETDATE(), null, null) 
go 

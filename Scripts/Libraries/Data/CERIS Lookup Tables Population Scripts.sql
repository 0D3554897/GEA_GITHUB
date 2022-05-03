
--LOOKUP_DOMAIN 

insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
  values('CERIS Interface Control Points', 'LD_CERIS_INTERFACE_CTRL_PT', SUSER_SNAME(), GETDATE())
go


--LOOKUP_DETAIL

-- update CERIS interface name to CERIS/BluePages
update dbo.XX_LOOKUP_DETAIL
set APPLICATION_CODE = 'CERIS/BluePages',
    LOOKUP_DESCRIPTION = 'CERIS/BluePages'
where
    LOOKUP_DOMAIN_ID = 1 AND APPLICATION_CODE = 'CERIS'
go



-- control point data
declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_CERIS_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS1', 'Retrieve CERIS and BluePages data from eT&E system', 1, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_CERIS_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS2', 'Validate and load CERIS into staging tables', 2, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_CERIS_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS3', 'Perform direct INSERTs against Costpoint tables', 3, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_CERIS_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS4', 'Perform direct UPDATEs against Costpoint tables', 4, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_CERIS_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS5', 'Prepare retroactive timesheet data (conditional)', 5, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_CERIS_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS6', 'Archive source and error data', 6, SUSER_SNAME(), GETDATE(), null, null)
go

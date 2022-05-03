--LOOKUP_DETAIL

insert into dbo.XX_LOOKUP_DETAIL (LOOKUP_DOMAIN_ID,APPLICATION_CODE, LOOKUP_DESCRIPTION, PRESENTATION_ORDER, CREATED_BY, CREATED_DATE)
  values(1,'CERIS_R22', 'CERIS_R22', 26, SUSER_SNAME(), GETDATE())

--LOOKUP_DOMAIN 

insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
  values('CERIS Research Interface Control Points', 'LD_CERIS_R_INTERFACE_CTRL_PT', SUSER_SNAME(), GETDATE())
go


-- control point data
declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_CERIS_R_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS_R1', 'Retrieve CERIS Research data from staging table', 1, SUSER_SNAME(), GETDATE(), null, null)
go


declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_CERIS_R_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS_R2', 'Validate and load CERIS Research into staging tables', 2, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_CERIS_R_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS_R3', 'Perform direct INSERTs against Costpoint tables', 3, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_CERIS_R_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS_R4', 'Perform direct UPDATEs against Costpoint tables', 4, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_CERIS_R_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS_R5', 'Prepare retroactive timesheet data (conditional)', 5, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_CERIS_R_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS_R6', 'Archive source and error data', 6, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_CERIS_R_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS_R7', 'Wait for Completion of Costpoint Process Server (conditional)', 7, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_CERIS_R_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS_R8', 'Archive source, error and retroactive timesheet data', 8, SUSER_SNAME(), GETDATE(), null, null)
go

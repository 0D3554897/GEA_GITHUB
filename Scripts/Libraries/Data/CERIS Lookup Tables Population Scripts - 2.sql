

-- CERIS lookup_detail populations script 2
update dbo.xx_lookup_detail
set    application_code = 'CERIS'
where  application_code = 'CERIS/BluePages'

update dbo.xx_lookup_detail
set    lookup_description = 'Prepare and Kickoff Costpoint Process Server (conditional)'
where  application_code = 'CERIS6'

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_CERIS_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS7', 'Wait for Completion of Costpoint Process Server (conditional)', 7, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_CERIS_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS8', 'Archive source, error and retroactive timesheet data', 8, SUSER_SNAME(), GETDATE(), null, null)
go

--LOOKUP_DOMAIN 

insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
  values('Utilization Interface Control Points', 'LD_UTIL_INTERFACE_CTRL_PT', SUSER_SNAME(), GETDATE())
go


--LOOKUP_DETAIL

insert into dbo.XX_LOOKUP_DETAIL 
 values(1, 'UTIL', 'Utilization report for eT&E', 23, SUSER_SNAME(), GETDATE(), null, null)
go



-- control point data
declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_UTIL_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'UTIL1', 'Load IMAPS data into staging tables', 1, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_UTIL_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'UTIL2', 'Transfer data to eT&T', 2, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_UTIL_INTERFACE_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'UTIL3', 'Archive transfered data', 3, SUSER_SNAME(), GETDATE(), null, null)
go
-- LOOK_DOMAIN for control points

insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE) 
 values('RETRORATE Interface Control Points', 'LD_RETRORATE_INTERFACE_CTRL_PT', SUSER_SNAME(), GETDATE()) 
go 

-- LOOKUP_DETAIL for interface name and control points 

insert into dbo.XX_LOOKUP_DETAIL values(1, 'RETRORATE', 'RETRO RATE INTERFACE', 25, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int 
select @domain_id = LOOKUP_DOMAIN_ID 
from dbo.XX_LOOKUP_DOMAIN  
where DOMAIN_CONSTANT = 'LD_RETRORATE_INTERFACE_CTRL_PT' 
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'RETRORATE-001', 'RETRO RATE SUCCESSFULLY PROCESSED', 1, SUSER_SNAME(), GETDATE(), null, null) 
go 

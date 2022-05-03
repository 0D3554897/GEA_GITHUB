-- Add a XX_LOOKUP_DETAIL record for interface name under the Interface Names domain in table XX_LOOKUP_DOMAIN
declare @presentation_order integer

select @presentation_order = (MAX(PRESENTATION_ORDER) + 1) 
  from dbo.XX_LOOKUP_DETAIL
 where LOOKUP_DOMAIN_ID = 1

insert into dbo.XX_LOOKUP_DETAIL values(1, 'PROJEMPL', 'Project Workforce Employee interface', @presentation_order, SUSER_SNAME(), GETDATE(), null, null)
go

-- Add a XX_LOOKUP_DOMAIN record for interface control point set name
insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
   values('Proj Empl Interface Control Point', 'LD_PROJ_EMPL_INTERFACE_CTRL_PT', SUSER_SNAME(), GETDATE())
go

-- Add a XX_LOOKUP_DETAIL record for the first interface control point
declare @domain_id integer

select @domain_id = LOOKUP_DOMAIN_ID
  from dbo.XX_LOOKUP_DOMAIN
 where DOMAIN_CONSTANT = 'LD_PROJ_EMPL_INTERFACE_CTRL_PT'

insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'PROJEMPL_R1', 'Insert Proj Empl records into Oracle', 1, SUSER_SNAME(), GETDATE(), null, null) 
go

-- Add a XX_LOOKUP_DETAIL record for the second interface control point
declare @domain_id integer

select @domain_id = LOOKUP_DOMAIN_ID
  from dbo.XX_LOOKUP_DOMAIN
 where DOMAIN_CONSTANT = 'LD_PROJ_EMPL_INTERFACE_CTRL_PT'

insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'PROJEMPL_R2', 'Archive Proj Empl records', 2, SUSER_SNAME(), GETDATE(), null, null) 
go

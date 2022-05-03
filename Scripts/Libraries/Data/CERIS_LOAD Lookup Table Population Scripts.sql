use imapsstg
go

--change description of interface and control point
update xx_lookup_detail
set lookup_description='CERIS/LCDB'
where application_code='CERIS'
go
update xx_lookup_detail
set lookup_description='Retrieve CERIS and LCDB data from input tables'
where application_code='CERIS1'
go



-- Add a XX_LOOKUP_DETAIL record for interface name under the Interface Names domain in table XX_LOOKUP_DOMAIN
declare @presentation_order integer

select @presentation_order = (MAX(PRESENTATION_ORDER) + 1) 
  from dbo.XX_LOOKUP_DETAIL
 where LOOKUP_DOMAIN_ID = 1

insert into dbo.XX_LOOKUP_DETAIL values(1, 'CERIS_LOAD', 'CERIS SOURCE DATA', @presentation_order, SUSER_SNAME(), GETDATE(), null, null)
go

-- Add a XX_LOOKUP_DOMAIN record for interface control point set name
insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
   values('CERIS_LOAD Control Point', 'LD_CERIS_LOAD_CTRL_PT', SUSER_SNAME(), GETDATE())
go

-- Add a XX_LOOKUP_DETAIL record for the first interface control point
declare @domain_id integer

select @domain_id = LOOKUP_DOMAIN_ID
  from dbo.XX_LOOKUP_DOMAIN
 where DOMAIN_CONSTANT = 'LD_CERIS_LOAD_CTRL_PT'

insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS_LOAD_1', 'Perform initialization checks, data archive, table truncation', 1, SUSER_SNAME(), GETDATE(), null, null) 
go

-- Add a XX_LOOKUP_DETAIL record for the second interface control point
declare @domain_id integer

select @domain_id = LOOKUP_DOMAIN_ID
  from dbo.XX_LOOKUP_DOMAIN
 where DOMAIN_CONSTANT = 'LD_CERIS_LOAD_CTRL_PT'

insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CERIS_LOAD_2', 'Perform extract checks, update control totals', 2, SUSER_SNAME(), GETDATE(), null, null) 
go


--select * from xx_lookup_detail where application_code like '%ceris_load%'
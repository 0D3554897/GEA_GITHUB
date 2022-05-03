

--DEFALT value
insert into imaps.deltek.genl_lab_cat
(genl_lab_cat_cd, genl_lab_cat_desc, modified_by, time_stamp, company_id, genl_avg_rt_amt, rowversion)
select 'DEFALT', 'Default - No GLC in LCDB', suser_sname(), current_timestamp, '1', 0, 0
go



use imapsstg
go

-- Add a XX_LOOKUP_DETAIL record for interface name under the Interface Names domain in table XX_LOOKUP_DOMAIN
declare @presentation_order integer

select @presentation_order = (MAX(PRESENTATION_ORDER) + 1) 
  from dbo.XX_LOOKUP_DETAIL
 where LOOKUP_DOMAIN_ID = 1

insert into dbo.XX_LOOKUP_DETAIL values(1, 'LCDB_EXTRACT', 'Labor Category Database extract', @presentation_order, SUSER_SNAME(), GETDATE(), null, null)
go

-- Add a XX_LOOKUP_DOMAIN record for interface control point set name
insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
   values('LCDB_EXTRACT Control Point', 'LD_LCDB_EXTRACT_CTRL_PT', SUSER_SNAME(), GETDATE())
go

-- Add a XX_LOOKUP_DETAIL record for the first interface control point
declare @domain_id integer

select @domain_id = LOOKUP_DOMAIN_ID
  from dbo.XX_LOOKUP_DOMAIN
 where DOMAIN_CONSTANT = 'LD_LCDB_EXTRACT_CTRL_PT'

insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'LCDB_EXTRACT_1', 'Perform initialization checks, data archive, table truncation', 1, SUSER_SNAME(), GETDATE(), null, null) 
go

-- Add a XX_LOOKUP_DETAIL record for the second interface control point
declare @domain_id integer

select @domain_id = LOOKUP_DOMAIN_ID
  from dbo.XX_LOOKUP_DOMAIN
 where DOMAIN_CONSTANT = 'LD_LCDB_EXTRACT_CTRL_PT'

insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'LCDB_EXTRACT_2', 'Perform extract checks, update control totals', 2, SUSER_SNAME(), GETDATE(), null, null) 
go


--select * from xx_lookup_detail where application_code like '%lcdb%'
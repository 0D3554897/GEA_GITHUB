-- Add a XX_LOOKUP_DETAIL record for interface name under the Interface Names domain in table XX_LOOKUP_DOMAIN
declare @presentation_order integer

select @presentation_order = (MAX(PRESENTATION_ORDER) + 1) 
  from dbo.XX_LOOKUP_DETAIL
 where LOOKUP_DOMAIN_ID = 1

insert into dbo.XX_LOOKUP_DETAIL values(1, 'FIWLR_R22', 'FIW-LR Research System', @presentation_order, SUSER_SNAME(), GETDATE(), null, null)
go



--LOOKUP_DOMAIN 

insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
  values('FIWLR_R22 Interface Control Point', 'LD_FIWLR_R22_INTER_CTRL_PT', SUSER_SNAME(), GETDATE())
go


-- control point data
declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_FIWLR_R22_INTER_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'FIWLR_R1', 'FIW-LR Extract Data', 1, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_FIWLR_R22_INTER_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'FIWLR_R2', 'FIW-LR Data Validation', 2, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_FIWLR_R22_INTER_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'FIWLR_R3', 'FIW-LR AP Preprocessor Data', 3, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_FIWLR_R22_INTER_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'FIWLR_R4', 'FIW-LR Initiate AP  Preprocessor Success', 4, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_FIWLR_R22_INTER_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'FIWLR_R5', 'FIW-LR Initiate JE  Preprocessor Success', 5, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_FIWLR_R22_INTER_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'FIWLR_R6', 'Preprocessor Successfull', 6, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_FIWLR_R22_INTER_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'FIWLR_R7', 'FIW-LR Archive', 7, SUSER_SNAME(), GETDATE(), null, null)
go

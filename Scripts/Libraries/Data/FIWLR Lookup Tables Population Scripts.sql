
--LOOKUP_DOMAIN 

insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
  values('FIWLR Interface Control Point', 'LD_FIWLR_INTER_CTRL_PT', SUSER_SNAME(), GETDATE())
go


--LOOKUP_DETAIL

-- update FIW_LR interface name to FIWLR
update dbo.XX_LOOKUP_DETAIL
set APPLICATION_CODE = 'FIWLR'
where
    LOOKUP_DOMAIN_ID = 1 AND APPLICATION_CODE = 'FIW_LR'
go



-- control point data
declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_FIWLR_INTER_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'FIWLR1', 'FIW-LR Extract Data', 1, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_FIWLR_INTER_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'FIWLR2', 'FIW-LR Data Validation', 2, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_FIWLR_INTER_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'FIWLR3', 'FIW-LR AP Preprocessor Data', 3, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_FIWLR_INTER_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'FIWLR4', 'FIW-LR Initiate AP  Preprocessor Success', 4, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_FIWLR_INTER_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'FIWLR5', 'FIW-LR Initiate JE  Preprocessor Success', 5, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_FIWLR_INTER_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'FIWLR6', 'Preprocessor Successfull', 6, SUSER_SNAME(), GETDATE(), null, null)
go

declare @domain_id int
select @domain_id = LOOKUP_DOMAIN_ID
from dbo.XX_LOOKUP_DOMAIN 
where DOMAIN_CONSTANT = 'LD_FIWLR_INTER_CTRL_PT'
insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'FIWLR7', 'FIW-LR Archive', 7, SUSER_SNAME(), GETDATE(), null, null)
go

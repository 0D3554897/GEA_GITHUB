-- BP&S Reference No.: CR1656
-- ClearQuest Reference No.: CP600000465

-- Add XX_LOOKUP_DOMAIN record for control point domain

insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE) 
   values('CLS Down Research Interface Ctrl Pts', 'LD_CLS_DOWN_R22_CTRL_PT', SUSER_SNAME(), GETDATE()) 
GO

-- Add XX_LOOKUP_DETAIL record for interface name

declare @domain_id integer

select @domain_id = LOOKUP_DOMAIN_ID
  from dbo.XX_LOOKUP_DOMAIN  
 where DOMAIN_CONSTANT = 'LD_INTERFACE_NAME' 
 
declare @presentation_order integer

select @presentation_order = MAX(PRESENTATION_ORDER) + 1
  from dbo.XX_LOOKUP_DETAIL
 where LOOKUP_DOMAIN_ID = @domain_id

insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CLS_R22', 'CLS Down System - Research', @presentation_order, SUSER_SNAME(), GETDATE(), NULL, NULL)
GO

-- Add XX_LOOKUP_DETAIL records for control points

declare @domain_id integer

select @domain_id = LOOKUP_DOMAIN_ID
  from dbo.XX_LOOKUP_DOMAIN
 where DOMAIN_CONSTANT = 'LD_CLS_DOWN_R22_CTRL_PT' 

insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CLS_R1', 'Populate staging tables and archive staging data', 1, SUSER_SNAME(), GETDATE(), NULL, NULL) 
GO

declare @domain_id integer

select @domain_id = LOOKUP_DOMAIN_ID
  from dbo.XX_LOOKUP_DOMAIN
 where DOMAIN_CONSTANT = 'LD_CLS_DOWN_R22_CTRL_PT' 

insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CLS_R2', 'Populate summary table and update interface status', 2, SUSER_SNAME(), GETDATE(), NULL, NULL) 
GO 

declare @domain_id integer

select @domain_id = LOOKUP_DOMAIN_ID
  from dbo.XX_LOOKUP_DOMAIN
 where DOMAIN_CONSTANT = 'LD_CLS_DOWN_R22_CTRL_PT' 

insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CLS_R3', 'Create output files and move them to predetermined storage locations', 3, SUSER_SNAME(), GETDATE(), NULL, NULL) 
GO 

declare @domain_id integer

select @domain_id = LOOKUP_DOMAIN_ID
  from dbo.XX_LOOKUP_DOMAIN
 where DOMAIN_CONSTANT = 'LD_CLS_DOWN_R22_CTRL_PT' 

insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'CLS_R4', 'Archive output files', 4, SUSER_SNAME(), GETDATE(), NULL, NULL) 
GO 

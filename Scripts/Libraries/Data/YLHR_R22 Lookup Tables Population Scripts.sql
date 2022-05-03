-- BP&S Reference No.: CR1905
-- ClearQuest Reference No.: CP600000696

-- Add XX_LOOKUP_DOMAIN record for control point domain

insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE) 
   values('YTD Labor Hours Reconciliation Ctrl Pts', 'LD_YLHR_R22_CTRL_PT', SUSER_SNAME(), GETDATE()) 
GO

-- Add XX_LOOKUP_DETAIL record for application name

declare @domain_id integer

select @domain_id = LOOKUP_DOMAIN_ID
  from dbo.XX_LOOKUP_DOMAIN  
 where DOMAIN_CONSTANT = 'LD_INTERFACE_NAME' 
 
declare @presentation_order integer

select @presentation_order = MAX(PRESENTATION_ORDER) + 1
  from dbo.XX_LOOKUP_DETAIL
 where LOOKUP_DOMAIN_ID = @domain_id

insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'YLHR_R22', 'YTD eTimecard-Costpoint Hours Reconciliation', @presentation_order, SUSER_SNAME(), GETDATE(), NULL, NULL)
GO

-- Add XX_LOOKUP_DETAIL records for control points

declare @domain_id integer

select @domain_id = LOOKUP_DOMAIN_ID
  from dbo.XX_LOOKUP_DOMAIN
 where DOMAIN_CONSTANT = 'LD_YLHR_R22_CTRL_PT' 

insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'YLHR_R1', 'Retrieve and sum up eTimecard submitted daily hours', 1, SUSER_SNAME(), GETDATE(), NULL, NULL) 
GO

declare @domain_id integer

select @domain_id = LOOKUP_DOMAIN_ID
  from dbo.XX_LOOKUP_DOMAIN
 where DOMAIN_CONSTANT = 'LD_YLHR_R22_CTRL_PT' 

insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'YLHR_R2', 'Retrieve and sum up Costpoint posted and miscode daily hours', 2, SUSER_SNAME(), GETDATE(), NULL, NULL) 
GO 

declare @domain_id integer

select @domain_id = LOOKUP_DOMAIN_ID
  from dbo.XX_LOOKUP_DOMAIN
 where DOMAIN_CONSTANT = 'LD_YLHR_R22_CTRL_PT' 

insert into dbo.XX_LOOKUP_DETAIL values(@domain_id, 'YLHR_R3', 'Combine data sets and calculate hour difference totals', 3, SUSER_SNAME(), GETDATE(), NULL, NULL) 
GO 

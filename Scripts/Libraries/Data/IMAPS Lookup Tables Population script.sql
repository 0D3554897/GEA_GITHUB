/*
 * This script populates the lookup or reference tables.
 * The parent table XX_LOOKUP_DOMAIN provides the subject matters, topics or domains for grouping purpose.
 * The child table XX_LOOKUP_DETAIL provides the detail-level lookup values.  
 * PK column XX_LOOKUP_DOMAIN.LOOKUP_DOMAIN_ID is an IDENTITY column.
 * PK column XX_LOOKUP_DETAIL.LOOKUP_ID is an IDENTITY column.
 */

-- XX_LOOKUP_DETAIL (parent)

insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
   values('Interface Names', 'LD_INTERFACE_NAME', SUSER_SNAME(), GETDATE())
go

insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
   values('Interface Types', 'LD_INTERFACE_TYPE', SUSER_SNAME(), GETDATE())
go

insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
   values('eTime Interface Control Points', 'LD_ETIME_INTERFACE_CTRL_PT', SUSER_SNAME(), GETDATE())
go

insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
   values('Error Types', 'LD_ERROR_TYPE', SUSER_SNAME(), GETDATE())
go

insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
   values('Execution Result Status', 'LD_EXECUTION_STATUS', SUSER_SNAME(), GETDATE())
go

insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
   values('PCLAIM Interface Control Points', 'LD_PCLAIM_INTERFACE_CTRL_PT', SUSER_SNAME(), GETDATE())
go

insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
   values('FDS/CCS Interface Control POints', 'LD_FDS_CCS_INTFC_CTRL_PT', SUSER_SNAME(), GETDATE())
go

-- XX_LOOKUP_DETAIL (child)

-- Interface Names
insert into dbo.XX_LOOKUP_DETAIL values(1, 'AR_COLLECTION', 'Account Receivable Collection System', 1, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'BMS_IW', 'BMS_IW System', 2, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'CCS', 'CCS System', 3, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'CERIS', 'CERIS', 4, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'CITRUS', 'CITRUS System', 5, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'CLAIM', 'CLAIM System', 6, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'CLS', 'CLS System', 7, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'CMR', 'CMR System', 8, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'DOU', 'DOU System', 9, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'EMF', 'EMF System', 10, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'ETIME', 'e-Time&Expense System', 11, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'FDS/CCS', 'FDS and CCS System', 12, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'FIW_LR', 'FIW-LR System', 13, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'JDE', 'JDE System', 14, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'MPM', 'MPM System', 15, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'PACT', 'PACT System', 16, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'PCLAIM', 'PClaim System', 17, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'PS_FED_RPT', 'PS Federal Reporting System', 18, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'SAP_GL', 'SAP_GL System', 19, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'SIGNING_BAKLOG', 'Signings and Backlogs System', 20, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'TOTALS', 'TOTALS System', 21, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(1, 'WWER', 'WWER System', 22, SUSER_SNAME(), GETDATE(), null, null)
go

-- Interface Types
insert into dbo.XX_LOOKUP_DETAIL values(2, 'INBOUND', 'Inbound to IMAPS', 1, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(2, 'OUTBOUND', 'Outbound from IMAPS', 2, SUSER_SNAME(), GETDATE(), null, null)
go

-- eTime Interface Control Points
insert into dbo.XX_LOOKUP_DETAIL values(3, 'ETIME1', 'Retrieve labor file from FTP directory', 1, SUSER_SNAME(), GETDATE(), null, null)
go
-- MODIFIED message on control point etime2
-- by JG on 09/23
insert into dbo.XX_LOOKUP_DETAIL values(3, 'ETIME2', 'Load labor files into staging tables and validate input data', 2, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(3, 'ETIME3', 'Create file for IMAPS preprocessor and notify Costpoint via database update', 3, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(3, 'ETIME4', 'Execution of Costpoint timesheet preprocessor', 4, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(3, 'ETIME5', 'Update Control and Error tables', 5, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(3, 'ETIME6', 'Provide feedback to source systems', 6, SUSER_SNAME(), GETDATE(), null, null)
go

-- Error Types
insert into dbo.XX_LOOKUP_DETAIL values(4, 'INFORMATION', 'Information', 1, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(4, 'WARNING', 'Warning', 2, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(4, 'USER_ERROR', 'User Error', 3, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(4, 'SYSTEM_ERROR', 'System Error', 4, SUSER_SNAME(), GETDATE(), null, null)
go

-- Execution Result Status
insert into dbo.XX_LOOKUP_DETAIL values(5, 'BAD_FILE', 'Bad source input file', 1, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(5, 'COMPLETED', 'Interface processing completed', 2, SUSER_SNAME(), GETDATE(), null, null)
go
-- Modified by JG on 09/22/05
-- replaced CP_COMPLETED by CP_COMPLETE
insert into dbo.XX_LOOKUP_DETAIL values(5, 'CP_COMPLETE', 'Costpoint preprocessor completed', 3, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(5, 'CPIN_PROGRESS', 'Costpoint preprocessor in progress', 4, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(5, 'DUPLICATE', 'Duplicate source input file', 5, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(5, 'FAILED', 'Failure', 6, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(5, 'INITIATED', 'Interface processing initiated', 7, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(5, 'SUCCESS', 'Success', 8, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(5, 'SUCCESS_WITH_ERROR', 'Success with error(s) reported', 9, SUSER_SNAME(), GETDATE(), null, null)
go

-- PCLAIM Interface Control Points
insert into dbo.XX_LOOKUP_DETAIL values(6, 'PCLAIM1', 'Populate staging table using input source file', 1, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(6, 'PCLAIM2', 'Populate AP preprocessor staging tables', 2, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(6, 'PCLAIM3', 'Start AP preprocessor', 3, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(6, 'PCLAIM4', 'AP preprocessor run completed', 4, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(6, 'PCLAIM5', 'PCLAIM feed is archived', 5, SUSER_SNAME(), GETDATE(), null, null)
go

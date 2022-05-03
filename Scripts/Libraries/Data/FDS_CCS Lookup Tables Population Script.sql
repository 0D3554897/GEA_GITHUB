
--LOOKUP_DOMAIN 

--LOOKS LIKE IT IS ALREADY IN
--insert into dbo.XX_LOOKUP_DOMAIN (LOOKUP_DOMAIN_DESC, DOMAIN_CONSTANT, CREATED_BY, CREATED_DATE)
--  values('FDS/CCS Interface Control POints', 'LD_FDS_CCS_INTFC_CTRL_PT', SUSER_SNAME(), GETDATE())
--go


insert into dbo.XX_LOOKUP_DETAIL values(7, 'FDS/CCS-001', 'Load invoice data into summary staging table', 1, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(7, 'FDS/CCS-002', 'Validate and update CMR data', 2, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(7, 'FDS/CCS-003', 'Load invoice line data to detail staging table', 3, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(7, 'FDS/CCS-004', 'Create interface flat files', 4, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(7, 'FDS/CCS-005', 'Update sent table', 5, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(7, 'FDS/CCS-006', 'FTP interface flat files', 6, SUSER_SNAME(), GETDATE(), null, null)
go
insert into dbo.XX_LOOKUP_DETAIL values(7, 'FDS/CCS-007', 'Email control file and error file', 7, SUSER_SNAME(), GETDATE(), null, null)
go
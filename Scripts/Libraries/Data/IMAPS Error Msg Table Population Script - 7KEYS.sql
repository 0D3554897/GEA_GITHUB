insert into dbo.XX_INT_ERROR_MESSAGE values(211, 33, NULL, '%1 is currently not supported.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go

-- Example: %1 = 'The requested FY', %2 = 'FY'
insert into dbo.XX_INT_ERROR_MESSAGE values(212, 33, NULL, '%1 indicates a future %2.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go

-- Example: %1 = 'interface run type ID', %2 = 'system lookup table. Please contact system administrator'
insert into dbo.XX_INT_ERROR_MESSAGE values(213, 33, NULL, 'Missing %1 from %2.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
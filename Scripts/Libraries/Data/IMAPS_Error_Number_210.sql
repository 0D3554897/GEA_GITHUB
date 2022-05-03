-- DEV00000625_begin
-- 03/22/2005 - Missing Error No. 209 from system data
insert into dbo.XX_INT_ERROR_MESSAGE values(209, 32, NULL, 'No %1 exist to %2.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
-- DEV00000625_end

-- DEV00000244_begin
-- 11/10/2005 - Add info msg for interfaces that don't load data from input files
insert into dbo.XX_INT_ERROR_MESSAGE values(210, 31, NULL, '%1 failed validation due to %2.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
-- DEV00000244_end


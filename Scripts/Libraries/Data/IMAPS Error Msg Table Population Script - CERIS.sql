-- 10/07/2005 Add info msg for interfaces that don't load data from input files
insert into dbo.XX_INT_ERROR_MESSAGE 
	values(504, 31, NULL, 'Processing for %1 interface is initiated.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go

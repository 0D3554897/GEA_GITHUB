/********************************************
this is duplicate code also checked in from CR8887.
please check table definition first
if both default and nulls allowed are already set
this code will fail
*********************************************/
USE IMAPSStg
go
ALTER TABLE dbo.XX_CERIS_DATA_STG
ALTER COLUMN DEPT_SUF_DATE char(8) NULL
go
ALTER TABLE dbo.XX_CERIS_DATA_STG ADD DEFAULT 20160101 FOR DEPT_SUF_DATE
go
--Added for CR-1333/CR-1335
USE IMAPSStg
go
ALTER TABLE dbo.XX_IMAPS_ET_IN_TMP ADD ILC_ACTIVITY_CD char(6) NULL
go

ALTER TABLE dbo.XX_IMAPS_ET_FTR_IN_TMP
ALTER COLUMN TOTAL_RECORDS char(74) NOT NULL
go

--ALTER TABLE dbo.XX_ET_DAILY_IN_ERRORS ADD ILC_ACTIVITY_CD varchar(6) NULL
--go

ALTER TABLE dbo.XX_ET_DAILY_IN_ARC ADD ILC_ACTIVITY_CD varchar(6) NULL
go

ALTER TABLE dbo.XX_ET_DAILY_IN ADD ILC_ACTIVITY_CD varchar(6) NULL
go

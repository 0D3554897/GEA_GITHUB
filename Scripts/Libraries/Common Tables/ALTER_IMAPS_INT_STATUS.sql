ALTER TABLE dbo.XX_IMAPS_INT_STATUS
ALTER COLUMN INTERFACE_SOURCE_OWNER [varchar] (100) NOT NULL
GO

-- CP600000199 (DR1427) 02/08/2008 HVT Begin
-- Increase column size from 100 to 300.

ALTER TABLE dbo.XX_IMAPS_INT_STATUS
ALTER COLUMN INTERFACE_DEST_OWNER [varchar] (300) NOT NULL
GO

-- CP600000199 (DR1427) 02/08/2008 HVT End


alter table xx_imaps_int_status
alter column RECORD_COUNT_INITIAL decimal(17,2) NULL
go

alter table xx_imaps_int_status
alter column RECORD_COUNT_SUCCESS decimal(17,2) NULL
go

alter table xx_imaps_int_status
alter column RECORD_COUNT_ERROR	  decimal(17,2) NULL
go

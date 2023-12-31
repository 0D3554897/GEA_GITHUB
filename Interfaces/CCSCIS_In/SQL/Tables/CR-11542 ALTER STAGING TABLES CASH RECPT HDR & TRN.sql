USE [IMAPSStg]
GO

ALTER TABLE dbo.XX_AR_CASH_RECPT_HDR ALTER COLUMN TRN_TO_EUR_RT decimal(28, 15) NOT NULL
GO
ALTER TABLE dbo.XX_AR_CASH_RECPT_HDR ALTER COLUMN EUR_TO_FUNC_RT decimal(28, 15) NOT NULL
GO

USE [IMAPSStg]
GO

ALTER TABLE dbo.XX_AR_CASH_RECPT_TRN ALTER COLUMN DISC_TAKEN_AMT decimal(17, 2) NOT NULL
GO
ALTER TABLE dbo.XX_AR_CASH_RECPT_TRN ALTER COLUMN TRN_AMT decimal(17, 2) NOT NULL
GO
ALTER TABLE dbo.XX_AR_CASH_RECPT_TRN ALTER COLUMN PAY_TRN_AMT decimal(17, 2) NOT NULL
GO
ALTER TABLE dbo.XX_AR_CASH_RECPT_TRN ALTER COLUMN PAY_DISC_TAKEN_AMT decimal(17, 2) NOT NULL
GO
ALTER TABLE dbo.XX_AR_CASH_RECPT_TRN ALTER COLUMN TRN_TRN_AMT decimal(17, 2) NOT NULL
GO
ALTER TABLE dbo.XX_AR_CASH_RECPT_TRN ALTER COLUMN TRN_DISC_TAKEN_AMT decimal(17, 2) NOT NULL
GO
ALTER TABLE dbo.XX_AR_CASH_RECPT_TRN ALTER COLUMN MU_REAL_GAIN_AMT decimal(17, 2) NOT NULL
GO
ALTER TABLE dbo.XX_AR_CASH_RECPT_TRN ALTER COLUMN MU_REAL_LOSS_AMT decimal(17, 2) NOT NULL
GO
ALTER TABLE dbo.XX_AR_CASH_RECPT_TRN ALTER COLUMN TRN_FINCHG_RCV_AMT decimal(17, 2) NOT NULL
GO
ALTER TABLE dbo.XX_AR_CASH_RECPT_TRN ALTER COLUMN PAY_FINCHG_RCV_AMT decimal(17, 2) NOT NULL
GO
ALTER TABLE dbo.XX_AR_CASH_RECPT_TRN ALTER COLUMN FINCHG_RCV_AMT decimal(17, 2) NOT NULL
GO
ALTER TABLE dbo.XX_AR_CASH_RECPT_TRN ADD BANK_AMT decimal(17, 2) NULL
GO

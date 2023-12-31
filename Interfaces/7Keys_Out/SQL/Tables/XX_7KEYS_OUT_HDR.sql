if exists (select * from dbo.sysobjects where id = object_id(N'[XX_7KEYS_OUT_HDR]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_7KEYS_OUT_HDR]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_7KEYS_OUT_HDR]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)

BEGIN

CREATE TABLE [XX_7KEYS_OUT_HDR] (
	[STATUS_RECORD_NUM] [int] NULL ,
	[ROW_NUM_TOTAL] [int] NULL ,
	[PERIOD_REVENUE_TOTAL] [decimal](14, 2) NULL ,
	[PERIOD_COST_TOTAL] [decimal](14, 2) NULL ,
	[QTD_REVENUE_TOTAL] [decimal](14, 2) NULL ,
	[QTD_COST_TOTAL] [decimal](14, 2) NULL ,
	[YTD_REVENUE_TOTAL] [decimal](14, 2) NULL ,
	[YTD_COST_TOTAL] [decimal](14, 2) NULL ,
	[ITD_REVENUE_TOTAL] [decimal](14, 2) NULL ,
	[ITD_COST_TOTAL] [decimal](14, 2) NULL ,
	[ITD_FUNDING_TOTAL] [decimal](14, 2) NULL ,
	[UNBILLED_REVENUE_TOTAL] [decimal](14, 2) NULL ,
	[UNBILLED_REVENUE_31TO60DAYS_TOTAL] [decimal](14, 2) NULL ,
	[UNBILLED_REVENUE_61TO90DAYS_TOTAL] [decimal](14, 2) NULL ,
	[UNBILLED_REVENUE_OVER90DAYS_TOTAL] [decimal](14, 2) NULL ,
	[AGED_BILL_AMT_TOTAL] [decimal](14, 2) NULL ,
	[AGED_RECEIVABLE_31TO60DAYS_TOTAL] [decimal](14, 2) NULL ,
	[AGED_RECEIVABLE_61TO90DAYS_TOTAL] [decimal](14, 2) NULL ,
	[AGED_RECEIVABLE_OVER90DAYS_TOTAL] [decimal](14, 2) NULL ,
	[BILLED_AMT_TOTAL] [decimal](14, 2) NULL ,
	CONSTRAINT [FK_XX_7KEYS_OUT_HDR] FOREIGN KEY 
	(
		[STATUS_RECORD_NUM]
	) REFERENCES [XX_IMAPS_INT_STATUS] (
		[STATUS_RECORD_NUM]
	)
) ON [PRIMARY]

END

GO



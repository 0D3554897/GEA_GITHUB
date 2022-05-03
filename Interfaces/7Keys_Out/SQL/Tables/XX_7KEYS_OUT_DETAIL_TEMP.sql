if exists (select * from dbo.sysobjects where id = object_id(N'[XX_7KEYS_OUT_DETAIL_TEMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_7KEYS_OUT_DETAIL_TEMP]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_7KEYS_OUT_DETAIL_TEMP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)

BEGIN

CREATE TABLE [dbo].[XX_7KEYS_OUT_DETAIL_TEMP](
	[PROJ_ID] [char](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DATA_CATEGORY] [char](3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CONTRACT_NAME] [char](25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PROJ_NAME] [char](25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PRIME_CONTR_ID] [char](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PROJ_MGR_ID] [char](12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PROJ_MGR_NAME] [char](25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PROJ_MGR_EMAIL] [char](60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PROJ_EXECUTIVE_ID] [char](12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PROJ_EXECUTIVE] [char](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PROJ_EXECUTIVE_EMAIL] [char](60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FINANCIAL_MANAGER] [char](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IBM_OPP_NUM_SIEBEL] [char](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CONTRACT_TYPE] [char](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SERVICE_OFFERING] [char](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SERVICE_AREA] [char](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SERVICE_AREA_DESC] [char](55) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FEDERAL_SERVICE_AREA_DESC] [char](25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PRACTICE_AREA] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ULTIMATE_CLIENT] [char](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CORE_ACCOUNT] [char](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MI0405_INDICATOR] [char](8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DIVISION] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[INDUSTRY] [char](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[INDUSTRY_NAME] [char](80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[KEY_ACCOUNT] [char](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[KEY_ACCOUNT_NAME] [char](25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[GROSS_PROFIT_MARGIN] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CUST_LONG_NAME] [char](40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PERIOD_REVENUE] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PERIOD_COST] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PERIOD_PROFIT] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[QTD_REVENUE] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[QTD_COST] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[QTD_PROFIT] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[YTD_REVENUE] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[YTD_COST] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[YTD_PROFIT] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ITD_REVENUE] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ITD_COST] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ITD_PROFIT] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ITD_VALUE] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ITD_FUNDING] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[UNBILLED_REVENUE] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[UNBILLED_REVENUE_31TO60DAYS] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[UNBILLED_REVENUE_61TO90DAYS] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[UNBILLED_REVENUE_OVER90DAYS] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AGED_BILL_AMT] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AGED_RECEIVABLE_31TO60DAYS] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AGED_RECEIVABLE_61TO90DAYS] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AGED_RECEIVABLE_OVER90DAYS] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[BILLED_AMT] [char](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MOD_NUM] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PERIOD_OF_PERFORMANCE_START_DT] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PERIOD_OF_PERFORMANCE_END_DT] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]

END

GO



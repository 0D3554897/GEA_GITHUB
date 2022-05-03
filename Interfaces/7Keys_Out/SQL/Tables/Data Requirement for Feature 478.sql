/*
 * Data Requirements for Feature No. 478
 * Add 5 columns: LVL_NO, L1_PROJ_SEG_ID, L2_PROJ_SEG_ID, L3_PROJ_SEG_ID
 * Add 4 house-keeeping columns: CREATED_BY, CREATED_DT, MODIFIED_BY, MODIFIED_DT
 * Add DEFAULT 0 property to all dollar amount columns
 */

DROP TABLE [XX_7KEYS_OUT_DETAIL]
GO


CREATE TABLE [XX_7KEYS_OUT_DETAIL] (
	[ROW_NUM] [int] IDENTITY (1, 1) NOT NULL ,
	[STATUS_RECORD_NUM] [int] NULL ,
	[PROJ_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_NAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
-- Feature 478 begin
	[LVL_NO] [smallint] NULL ,
	[L1_PROJ_SEG_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[L2_PROJ_SEG_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[L3_PROJ_SEG_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
-- Feature 478 end
	[PROJ_MGR_NAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PROJ_EXECUTIVE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FINANCIAL_MANAGER] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[IBM_OPP_NUM_SIEBEL] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CONTRACT_TYPE] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SERVICE_AREA] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PRACTICE_AREA] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MI0405_INDICATOR] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[INDUSTRY] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[INDUSTRY_NAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[KEY_ACCOUNT] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[KEY_ACCOUNT_NAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[GROSS_PROFIT_MARGIN] [decimal](14, 4) NULL ,
	[CUST_LONG_NAME] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[S_REV_FORMULA_CD] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
-- Feature 478 begin
	[PERIOD_REVENUE] [decimal](14, 2) NULL DEFAULT 0 ,
	[PERIOD_COST] [decimal](14, 2) NULL DEFAULT 0 ,
	[PERIOD_PROFIT] [decimal](14, 2) NULL DEFAULT 0 ,
	[YTD_REVENUE] [decimal](14, 2) NULL DEFAULT 0 ,
	[YTD_COST] [decimal](14, 2) NULL DEFAULT 0 ,
	[YTD_PROFIT] [decimal](14, 2) NULL DEFAULT 0 ,
	[ITD_REVENUE] [decimal](14, 2) NULL DEFAULT 0 ,
	[ITD_COST] [decimal](14, 2) NULL DEFAULT 0 ,
	[ITD_PROFIT] [decimal](14, 2) NULL DEFAULT 0 ,
	[ITD_VALUE] [decimal](14, 2) NULL DEFAULT 0 ,
	[ITD_FUNDING] [decimal](14, 2) NULL DEFAULT 0 ,
	[RETAINAGE_AMT] [decimal](14, 2) NULL DEFAULT 0 ,
	[UNBILLED_REVENUE] [decimal](14, 2) NULL DEFAULT 0 ,
	[AGED_BILL_AMT] [decimal](14, 2) NULL DEFAULT 0 ,
	[BILLED_AMT] [decimal](14, 2) NULL DEFAULT 0 ,
-- Feature 478 end
	[MOD_NUM] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PERIOD_OF_PERFORMANCE_START_DT] [datetime] NULL ,
	[PERIOD_OF_PERFORMANCE_END_DT] [datetime] NULL ,
-- Feature 478 begin
	[CREATED_BY] [varchar] (20)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CREATED_DT] [datetime] NOT NULL,
	[MODIFIED_BY] [varchar] (20)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MODIFIED_DT] [datetime] NULL
-- Feature 478 end
	CONSTRAINT [FK_XX_7KEYS_OUT_DETAIL] FOREIGN KEY 
	(
		[STATUS_RECORD_NUM]
	) REFERENCES [XX_IMAPS_INT_STATUS] (
		[STATUS_RECORD_NUM]
	)
) ON [PRIMARY]
GO

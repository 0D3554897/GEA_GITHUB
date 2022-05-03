SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO


IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_7KEYS_GET_OUTPUT_DATA_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   DROP PROCEDURE [dbo].[XX_7KEYS_GET_OUTPUT_DATA_SP]
GO

CREATE PROCEDURE [dbo].[XX_7KEYS_GET_OUTPUT_DATA_SP]
(
@in_STATUS_RECORD_NUM      integer,
@in_FY_CD                  varchar(6),
@in_period_num             smallint,
@out_SQLServer_error_code  integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION    varchar(255) = NULL OUTPUT
)
AS
/***********************************************************************************************************
Name:       XX_7KEYS_GET_OUTPUT_DATA_SP
Author:     HVT
Created:    11/04/2005
Purpose:    Retrieve required data from the Costpoint DB and store in the staging tables to be used
            to build an output file.
            Called by XX_7KEYS_RUN_INTERFACE_SP.
Parameters: 
Result Set: None
Notes:

Feature 478 The record for level 3 should contain level 3 data and rolled up (summarized) data from
            all lower levels.
            Table XX_7KEYS_OUT_DETAIL is changed by the addition of 5 columns LVL_NO, L1_PROJ_SEG_ID,
            L2_PROJ_SEG_ID, L3_PROJ_SEG_ID, and 4 house-keeeping columns CREATED_BY, CREATED_DT,
            MODIFIED_BY, MODIFIED_DT.
            Add ISNULL() to all dollar amount columns to display their undefined values as .00
            by default.

            03/06/2006 Add column aliases to SELECT statements used by the INSERT INTO statements.
            Clean up unused code.

            03/13/2006 Data retrieved from Deltek tables RPT_REV_SUM, RPT_PROJ_UNBILLED and PROJ_BILL_HS
            may look "repeating" in the output file because all three tables have PROJ_ID, FY_CD, PD_NO
            and SUB_PD_NO that together make the record unique. All three tables are "trending" tables.
            E.g., for RPT_PROJ_UNBILLED, if for each period that there is an unbilled amount, a record
            is inserted. Hence, with the passing of periods, a project may incur multiple records.

            Add non-nullable column Deltek.PROJ.PRIME_CONTR_ID varchar(20) to the output detail record.

Defect 976  05/15/2006 Provide aged receivable and unbilled revenue data for 31-60 days, 61-90 days and
            more than 90 days. Also, change the source of (1) PRACTICE_AREA and SERVICE_AREA from Costpoint
            tables PROJ and GENL_UDEF, respectively, to PROJ_RPT_ID (via PROJ_RPT_PROJ) for both,
            and (2) UNBILLED_REVENUE from Costpoint table RPT_PROJ_UNBILLED to Z_BLPUBILL_RPT.

            06/22/2006 Correct code to realize more data mapping changes for SERVICE_AREA, PRACTICE_AREA,
            INDUSTRY, INDUSTRY_NAME, KEY_ACCOUNT, KEY_ACCOUNT_NAME, GROSS_PROFIT_MARGIN. Also exclude
            projects whose ORG.L2_ORG_SEG_ID = 'S' (Shop Orders).

            07/14/2006 Do not include S_REV_FORMULA_CD and RETAINAGE_AMT in the final report.
            Add SERVICE_AREA_DESC. Limit the value of INDUSTRY to the first 3 segments.

            07/18/2006 Add column CONTRACT_NAME for level 1 contract name. Add column DATA_CATEGORY and
            assign the hardcoded value 'FED.' Apply rollup only to those project levels that are set up
            to recognize revenue. Only those revenue-recognizing level records appear in the final report.

Defect 1321 09/06/2006 Change the display format of columns PERIOD_OF_PERFORMANCE_START_DT and
            PERIOD_OF_PERFORMANCE_END_DT from yyyy-mm-dd to yyyymmdd.

Defect 1609 11/16/2006 Fix this problem: IMAPS.Deltek.GENL_UDEF.UDEF_TXT which is defined as varchar(30),
            is incompatible with IMAPS.dbo.XX_7KEYS_OUT_DETAIL.GROSS_PROFIT_MARGIN which is defined as 
            decimal(14,4).

Defect 1618 11/20/2006 Fix the problem of two PROJ_RPT_PROJ records with the same PROJ_ID (at LVL_NO = 2)
            values but different PROJ_RPT_ID values (one for service area ID, one for industry ID).
            For processing key account and calculating aged receivable and unbilled revenue, replace use
            of cursors to improve processing speed.

Defect 1764 02/22/2007 Fix the problem of columns UNBILLED_REVENUE_31TO60DAYS, UNBILLED_REVENUE_61TO90DAYS
            and UNBILLED_REVENUE_OVER90DAYS from staging table XX_7KEYS_OUT_DETAIL not getting any values.

CP600000074 10/08/2007 Reference BP&S Service Requests: DR1264, DR948, CR998, CR1170, DR1291

            DR1264: Modified Code to extract revenue from lower levels and roll it up to level 2.

            DR948: PRACTICE_AREA now comes from SUBSTRING(Deltek.PROJ_RPT_ID.PROJ_RPT_ID, 6, 3) instead of
            Deltek.PROJ.PROJ_TYPE_DC.

            CR998: PERIOD_REVENUE, PERIOD_COST and PERIOD_PROFIT now come from Deltek.PSR_FINAL_DATA
            (PSR = Project Status Report) instead of Deltek.REPT_REV_SUM.

            CR1170: Unbilled revenue data now come from table XX_REVENUE_UNBILLED_SUMMARY which is
            populated by the Calculated Unbilled Process. This renders the manual calculation of
            unbilled revenue values obsolete.

            DR1291: Duplicate lines for a specific project ID in the final report are caused by the
            multiple entries or records in table IMAPS.Deltek.RPT_REV_SUM at project level 2 with the
            same PROJ_ID, FY_CD, PD_NO and SUB_PD_NO. This fix partially overcomes the fix for DR1264.

CP600000163 01/16/2008 Reference BP&S Service Request DR1388
            The values of SERVICE_AREA field (and hence PRACTICE_AREA field) are not retrieved or populated
            completely causing some staging XX_7KEYS_OUT_DETAIL records to have values and some do not.
            Only records at reporting project level 2 need SERVICE_AREA and PRACTCE_AREA information since
            Service Area is assigned at the 2nd level of the project and inherited down the project tree.
            Remove obsolete code resulting from the fix.

CP600000288 04/01/2008 Reference BP&S Service Request CR1543
            Costpoint multi-company fix (18 instances). Also fix the problem of the output's
            GROSS_PROFIT_MARGIN value (Deltek.GENL_UDEF.UDEF_TXT) being null when it should not.

CP600000582 03/02/2009 Reference BP&S Service Request CR1888
            Add QTD_REVENUE, QTD_COST and QTD_PROFIT to output data.

DR7490      09/08/2014, CP600002091 (Costpoint 6), CP600002092 (Costpoint 7)
            Correct output data: All XX_7KEYS_OUT_DETAIL_TEMP records should have values in aged account
            receivable columns.

************************************************************************************************************/

DECLARE @SP_NAME                 sysname,
        @DIV_16_COMPANY_ID       varchar(10),
        @S_TABLE_ID              varchar(20),
        @SQLServer_error_code    integer,
        @IMAPS_error_code        integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
        @row_count               integer,
        @ret_code                integer,
        @PROJ_ID                 varchar(30),
        @LVL_NO                  smallint,
        @L1_PROJ_SEG_ID          varchar(30),
        @L2_PROJ_SEG_ID          varchar(30),
        @L3_PROJ_SEG_ID          varchar(30),
        @SERVICE_AREA            varchar(20),
        @SERVICE_AREA_DESC       varchar(55),
        @PRACTICE_AREA           varchar(20),
        @PREV_PROJ_ID            varchar(30),
        @PREV_L2_PROJ_SEG_ID     varchar(30),
        @usr_dt                  smalldatetime,  -- the first day of the user-specified report accounting month and FY combo
        @DATA_CATEGORY_DIV16     char(3)

-- set local constants
SET @SP_NAME = 'XX_7KEYS_GET_OUTPUT_DATA_SP'
SET @DATA_CATEGORY_DIV16 = 'FED'
SET @S_TABLE_ID = 'PJ'
SET @usr_dt = CAST((@in_FY_CD + '-' + CAST(@in_period_num as varchar(2)) + '-' + '01') as smalldatetime)

-- set local variables
SET @IMAPS_error_code = 204

IF @in_STATUS_RECORD_NUM IS NULL OR @in_FY_CD IS NULL OR @in_period_num IS NULL
   BEGIN
      -- Missing required input parameter(s)
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 100,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
      RETURN(1)
   END

-- CP600000582_Begin

DECLARE @starting_PD_NO smallint,
        @ending_PD_NO   smallint

SET @starting_PD_NO = 
   CASE 
      WHEN @in_period_num in (1, 2, 3) THEN 1
      WHEN @in_period_num in (4, 5, 6) THEN 4
      WHEN @in_period_num in (7, 8, 9) THEN 7
      WHEN @in_period_num in (10, 11, 12) THEN 10
   END

SET @ending_PD_NO = @in_period_num

-- CP600000582_End

-- CP600000288_Begin

EXEC @ret_code = dbo.XX_7KEYS_GET_PROCESSING_PARAMS_SP
   @out_COMPANY_ID = @DIV_16_COMPANY_ID OUTPUT

IF @ret_code <> 0
   BEGIN
      -- An error has occured. Please contact system administrator.
      SET @IMAPS_error_code = 301
      GOTO BL_ERROR_HANDLER
   END

IF LEN(RTRIM(LTRIM(@DIV_16_COMPANY_ID))) = 0
   BEGIN
      -- Missing required %1 for %2.
      SET @IMAPS_error_code = 203
      SET @error_msg_placeholder1 = 'processing parameter COMPANY_ID'
      SET @error_msg_placeholder2 = '7 Keys/PSP Interface'
      GOTO BL_ERROR_HANDLER
   END

-- CP600000288_End

PRINT 'Process Stage 7KEYS1 - Load Costpoint data into staging tables ...'

PRINT 'Clear staging tables ...'
TRUNCATE TABLE dbo.XX_7KEYS_OUT_DETAIL
TRUNCATE TABLE dbo.XX_7KEYS_OUT_HDR
TRUNCATE TABLE dbo.XX_7KEYS_OUT_DETAIL_TEMP
TRUNCATE TABLE dbo.XX_7KEYS_OUT_HDR_TEMP

PRINT 'Populate staging table XX_7KEYS_OUT_DETAIL ...'

-- XX_7KEYS_OUT_DETAIL.ROW_NUM is an IDENTITY column
INSERT INTO dbo.XX_7KEYS_OUT_DETAIL
   (STATUS_RECORD_NUM,
    PROJ_ID, DATA_CATEGORY, CONTRACT_NAME, PROJ_NAME, PRIME_CONTR_ID,
    LVL_NO, L1_PROJ_SEG_ID, L2_PROJ_SEG_ID, L3_PROJ_SEG_ID,
    PROJ_MGR_NAME,
    PROJ_EXECUTIVE,
    FINANCIAL_MANAGER,
    IBM_OPP_NUM_SIEBEL,
    CONTRACT_TYPE,
    SERVICE_AREA,
    SERVICE_AREA_DESC,
    PRACTICE_AREA,
    GROSS_PROFIT_MARGIN,
    MI0405_INDICATOR,
    CUST_LONG_NAME,
    S_REV_FORMULA_CD,
    PERIOD_REVENUE, PERIOD_COST, PERIOD_PROFIT,
-- CP600000582_Begin
    QTD_REVENUE, QTD_COST, QTD_PROFIT,
-- CP600000582_End
    YTD_REVENUE, YTD_COST, YTD_PROFIT,
    ITD_REVENUE, ITD_COST, ITD_PROFIT,
    ITD_VALUE, ITD_FUNDING,
-- Defect CP600000074 (CR1170) Veera 10/08/07 Begin
--  UNBILLED_REVENUE,
-- Defect CP600000074 (CR1170) Veera 10/08/07 End
    INDUSTRY,
    INDUSTRY_NAME,
    KEY_ACCOUNT,
    KEY_ACCOUNT_NAME,
    AGED_BILL_AMT,
    BILLED_AMT,
    MOD_NUM,
    PERIOD_OF_PERFORMANCE_START_DT,
    PERIOD_OF_PERFORMANCE_END_DT,
    CREATED_BY, CREATED_DT,
-- Defect CP600000980 begin
    PROJ_MGR_ID,
    PROJ_MGR_EMAIL,
    PROJ_EXECUTIVE_ID,
    PROJ_EXECUTIVE_EMAIL,
    SERVICE_OFFERING,
    FEDERAL_SERVICE_AREA_DESC,
    ULTIMATE_CLIENT, 
    CORE_ACCOUNT,
    DIVISION
-- Defect CP600000980 end
)
   SELECT @in_STATUS_RECORD_NUM,
          t1.PROJ_ID, @DATA_CATEGORY_DIV16, t1.L1_PROJ_NAME, t1.PROJ_NAME, t1.PRIME_CONTR_ID,
          t1.LVL_NO, t1.L1_PROJ_SEG_ID, t1.L2_PROJ_SEG_ID, t1.L3_PROJ_SEG_ID,
          t1.PROJ_MGR_NAME,
          (select UDEF_TXT
             from IMAPS.Deltek.GENL_UDEF
            where GENL_ID      = t1.PROJ_ID
              and S_TABLE_ID   = @S_TABLE_ID
              and UDEF_LBL_KEY = 21 -- UDEF_LBL.UDEF_LBL = PROJECT EXECUTIVE
-- CP600000288_Begin
              and COMPANY_ID   = @DIV_16_COMPANY_ID
-- CP600000288_End
          ) as PROJ_EXECUTIVE,
          (select UDEF_TXT
             from IMAPS.Deltek.GENL_UDEF
            where GENL_ID      = t1.PROJ_ID
              and S_TABLE_ID   = @S_TABLE_ID
              and UDEF_LBL_KEY = 8 -- UDEF_LBL.UDEF_LBL = FINANCIAL ANALYST
-- CP600000288_Begin
              and COMPANY_ID   = @DIV_16_COMPANY_ID
-- CP600000288_End
          ) as FINANCIAL_MANAGER,
          (select UDEF_TXT
             from IMAPS.Deltek.GENL_UDEF
            where GENL_ID      = t1.PROJ_ID
              and S_TABLE_ID   = @S_TABLE_ID
              and UDEF_LBL_KEY = 10 -- UDEF_LBL.UDEF_LBL = IBM OPP. # (SIEBEL)
-- CP600000288_Begin
              and COMPANY_ID   = @DIV_16_COMPANY_ID
-- CP600000288_End
          ) as IBM_OPP_NUM_SIEBEL,
          (select UDEF_ID
             from IMAPS.Deltek.GENL_UDEF
            where GENL_ID      = t1.PROJ_ID
              and S_TABLE_ID   = @S_TABLE_ID
              and UDEF_LBL_KEY = 5 -- UDEF_LBL.UDEF_LBL = CONTRACT TYPE
-- CP600000288_Begin
              and COMPANY_ID   = @DIV_16_COMPANY_ID
-- CP600000288_End
          ) as CONTRACT_TYPE,
          t11.PROJ_RPT_ID as SERVICE_AREA,
          t11.SERVICE_AREA_DESCRIPTION as SERVICE_AREA_DESC,
-- Defect CP600000074 (DR948) Veera 5/29/07 Begin
--        t1.PROJ_TYPE_DC as PRACTICE_AREA,
          SUBSTRING(t11.PROJ_RPT_ID, 6, 3) as PRACTICE_AREA,		
-- Defect CP600000074 (DR948) Veera 5/29/07 End
-- Defect 1609 begin
           (select CASE
                     WHEN UDEF_TXT is NULL THEN ISNULL(UDEF_AMT, 0)
                     WHEN UDEF_TXT is not NULL AND (LEN(RTRIM(LTRIM(UDEF_TXT))) = 0 OR ISNUMERIC(UDEF_TXT) != 1) THEN ISNULL(UDEF_AMT, 0)
                     WHEN UDEF_TXT is not NULL AND (LEN(RTRIM(LTRIM(UDEF_TXT))) > 0 AND ISNUMERIC(UDEF_TXT) = 1  and UDEF_LBL_KEY = 22 ) THEN CAST(ISNULL(UDEF_TXT, '0') as decimal(14, 4))
-- Defect CP600000980 UDEF_LBL_KEY = 22  added to CASE statement
-- CP600000288_Begin
                     ELSE NULL
-- CP600000288_End
                  END
             from IMAPS.Deltek.GENL_UDEF
            where GENL_ID      = t1.PROJ_ID
              and S_TABLE_ID   =  @S_TABLE_ID
              and UDEF_LBL_KEY = 22 -- UDEF_LBL.UDEF_LBL = GROSS PROFIT MARGIN
-- CP600000288_Begin
              and COMPANY_ID   = @DIV_16_COMPANY_ID
-- CP600000288_End
          ) as GROSS_PROFIT_MARGIN,  
/*
          (select CASE LEN(UDEF_TXT)
                     WHEN 0 THEN ISNULL(UDEF_AMT, 0)
                     ELSE CAST(UDEF_TXT as decimal(14, 4))
                  END
             from IMAPS.Deltek.GENL_UDEF
            where GENL_ID      = t1.PROJ_ID
              and S_TABLE_ID   = @S_TABLE_ID
              and UDEF_LBL_KEY = 22 -- UDEF_LBL.UDEF_LBL = GROSS PROFIT MARGIN
          ) as GROSS_PROFIT_MARGIN,
*/
-- Defect 1609 end
          (select UDEF_TXT from IMAPS.Deltek.GENL_UDEF
            where GENL_ID      = t1.PROJ_ID
              and S_TABLE_ID   = @S_TABLE_ID
              and UDEF_LBL_KEY = 26 -- UDEF_LBL.UDEF_LBL = MI0405 TYPE
-- CP600000288_Begin
              and COMPANY_ID   = @DIV_16_COMPANY_ID
-- CP600000288_End
          ) as MI0405_INDICATOR,
          t2.CUST_LONG_NAME,
          t9.S_REV_FORMULA_CD,
-- Defect CP600000074 (CR998) Veera 10/08/07 begin
--        ISNULL(t3.PERIOD_REVENUE, 0) as PERIOD_REVENUE, ISNULL(t3.PERIOD_COST, 0) as PERIOD_COST, ISNULL(t3.PERIOD_PROFIT, 0) as PERIOD_PROFIT,

          ISNULL(t3addition.PERIOD_REVENUE, 0) as PERIOD_REVENUE, 
          ISNULL(t3addition.PERIOD_COST, 0)    as PERIOD_COST, 
          ISNULL(t3addition.PERIOD_PROFIT, 0)  as PERIOD_PROFIT,

-- CP600000582_Begin
          ISNULL(t3encore.QTD_REVENUE, 0) as QTD_REVENUE, 
          ISNULL(t3encore.QTD_COST, 0)    as QTD_COST, 
          ISNULL(t3encore.QTD_PROFIT, 0)  as QTD_PROFIT,
-- CP600000582_End

-- Defect CP600000074 (CR998) Veera 10/08/07 end
          ISNULL(t3.YTD_REVENUE, 0) as YTD_REVENUE, ISNULL(t3.YTD_COST, 0) as YTD_COST, ISNULL(t3.YTD_PROFIT, 0) as YTD_PROFIT,
          ISNULL(t3.ITD_REVENUE, 0) as ITD_REVENUE, ISNULL(t3.ITD_COST, 0) as ITD_COST, ISNULL(t3.ITD_PROFIT, 0) as ITD_PROFIT,
          ISNULL(t3.ITD_VALUE, 0)   as ITD_VALUE,   ISNULL(t3.ITD_FUNDING, 0) as ITD_FUNDING,
-- Defect CP600000074 (CR1170) Veera 10/08/07 Begin
--        ISNULL(t4.UNBILLED_REVENUE, 0) as UNBILLED_REVENUE,
-- Defect CP600000074 (CR1170) Veera 10/08/07 End
          (t5.L1_PROJ_RPT_SG_ID + '.' + t5.L2_PROJ_RPT_SG_ID + '.' + t5.L3_PROJ_RPT_SG_ID) as INDUSTRY,
          CAST((t5.L3_PROJ_RPT_NAME + ' - ' + t5.L4_PROJ_RPT_NAME + ' - ' + t5.L5_PROJ_RPT_NAME) AS varchar(80)) as INDUSTRY_NAME,
          CASE t1.LVL_NO
             WHEN 2 THEN CAST((t5.L1_PROJ_RPT_SG_ID + '.' + t5.L2_PROJ_RPT_SG_ID + '.' + t5.L3_PROJ_RPT_SG_ID + '.' + t5.L4_PROJ_RPT_SG_ID) AS varchar(20))
             ELSE NULL
          END as KEY_ACCOUNT,
          CASE t1.LVL_NO
             WHEN 2 THEN t5.L4_PROJ_RPT_NAME
             ELSE NULL
          END as KEY_ACCOUNT_NAME,
          ISNULL(t7.AGED_BILL_AMT, 0) as AGED_BILL_AMT,
          ISNULL(t10.BILLED_AMT, 0) as BILLED_AMT,
          (select TOP 1
                  t8.PROJ_MOD_ID
             from IMAPS.Deltek.PROJ_MOD t8
            where t8.PROJ_ID = t1.PROJ_ID
            order by t8.PROJ_ID, t8.PROJ_MOD_ID desc
          ) as MOD_NUM,
          CONVERT(char, t1.PROJ_START_DT, 101) as PERIOD_OF_PERFORMANCE_START_DT, -- style 101: mm/dd/ccyy
          CONVERT(char, t1.PROJ_END_DT, 101) as PERIOD_OF_PERFORMANCE_END_DT,
          SUSER_SNAME() as IMAPS_USER, CURRENT_TIMESTAMP as RUN_DATETIME,
-- Defect CP600000980 begin
    t1.EMPL_ID + '897' as PROJ_MGR_ID,
   (select EMAIL_ID from IMAPS.Deltek.EMPL
            where EMPL_ID      = t1.EMPL_ID
              and COMPANY_ID   = @DIV_16_COMPANY_ID
          ) as   PROJ_MGR_EMAIL,
    (select case when rtrim(isnull(UDEF_ID,'')) = '' then UDEF_TXT + '897'
                  else UDEF_ID + '897' end from IMAPS.Deltek.GENL_UDEF
            where GENL_ID      = t1.PROJ_ID
              and S_TABLE_ID   = @S_TABLE_ID
              and UDEF_LBL_KEY = 38 
              and COMPANY_ID   = @DIV_16_COMPANY_ID
          ) as PROJ_EXECUTIVE_ID,
      (select EMAIL_ID from IMAPS.Deltek.EMPL
            where EMPL_ID      =  (select case when rtrim(isnull(UDEF_ID,'')) = '' then UDEF_TXT 
                  else UDEF_ID end from IMAPS.Deltek.GENL_UDEF
					where GENL_ID      = t1.PROJ_ID
						and S_TABLE_ID   = @S_TABLE_ID
						and UDEF_LBL_KEY = 38 
					    and COMPANY_ID   = @DIV_16_COMPANY_ID) 
					and COMPANY_ID   = @DIV_16_COMPANY_ID
          ) as   PROJ_EXECUTIVE_EMAIL,
      (select case when rtrim(isnull(UDEF_ID,'')) = '' then UDEF_TXT 
                  else UDEF_ID end from IMAPS.Deltek.GENL_UDEF
            where GENL_ID      = t1.PROJ_ID
              and S_TABLE_ID   = @S_TABLE_ID
              and UDEF_LBL_KEY = 19 
              and COMPANY_ID   = @DIV_16_COMPANY_ID
          ) as SERVICE_OFFERING,
    t11.FEDERAL_SERVICE_AREA_DESC,
     (select case when rtrim(isnull(UDEF_ID,'')) = '' then UDEF_TXT 
                  else UDEF_ID end from IMAPS.Deltek.GENL_UDEF
            where GENL_ID      = t1.PROJ_ID
              and S_TABLE_ID   = @S_TABLE_ID
              and UDEF_LBL_KEY = 6 
              and COMPANY_ID   = @DIV_16_COMPANY_ID
          ) as ULTIMATE_CLIENT, 
    t13.CORE_ACCOUNT AS CORE_ACCOUNT,
    LEFT (t12.ORG_ID,2) as  DIVISION
-- Defect CP600000980 end
     FROM IMAPS.Deltek.PROJ t1
     LEFT JOIN
          IMAPS.Deltek.CUST t2
          ON
          (t1.CUST_ID = t2.CUST_ID
-- CP600000288_Begin
           AND
           t2.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000288_End
          )
     LEFT JOIN
          (select t3a.PROJ_ID,
-- Defect CP600000074 (CR998) Veera 10/08/07 begin
                  SUM(CASE WHEN t3a.SUB_TOT_TYPE_NO = 1 THEN t3a.PTD_INCUR_AMT ELSE 0 END) AS PERIOD_REVENUE, 
                  SUM(CASE WHEN t3a.SUB_TOT_TYPE_NO > 1 THEN t3a.PTD_INCUR_AMT ELSE 0 END) AS PERIOD_COST,
                  SUM(CASE WHEN t3a.SUB_TOT_TYPE_NO = 1 THEN t3a.PTD_INCUR_AMT ELSE 0 END) - 
                     SUM(CASE WHEN t3a.SUB_TOT_TYPE_NO > 1 THEN t3a.PTD_INCUR_AMT ELSE 0 END) AS PERIOD_PROFIT
             from dbo.XX_PSR_PTD_FINAL_DATA t3a
            where t3a.FY_CD = @in_FY_CD
              and t3a.PD_NO = @in_period_num
              and t3a.SUB_PD_NO = 3
-- CP600000288_Begin
              and t3a.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000288_End
	    group by t3a.PROJ_ID
          ) t3addition ON t1.PROJ_ID = t3addition.PROJ_ID

-- CP600000582_Begin
     LEFT JOIN
          (select t3b.PROJ_ID,
                  SUM(CASE WHEN t3b.SUB_TOT_TYPE_NO = 1 THEN t3b.PTD_INCUR_AMT ELSE 0 END) AS QTD_REVENUE, 
                  SUM(CASE WHEN t3b.SUB_TOT_TYPE_NO > 1 THEN t3b.PTD_INCUR_AMT ELSE 0 END) AS QTD_COST,
                  SUM(CASE WHEN t3b.SUB_TOT_TYPE_NO = 1 THEN t3b.PTD_INCUR_AMT ELSE 0 END) - 
                  SUM(CASE WHEN t3b.SUB_TOT_TYPE_NO > 1 THEN t3b.PTD_INCUR_AMT ELSE 0 END) AS QTD_PROFIT
             from dbo.XX_PSR_PTD_FINAL_DATA t3b
            where t3b.FY_CD = @in_FY_CD
              and (t3b.PD_NO >= @starting_PD_NO AND t3b.PD_NO <= @ending_PD_NO)
              and t3b.SUB_PD_NO = 3
              and t3b.COMPANY_ID = @DIV_16_COMPANY_ID
            group by t3b.PROJ_ID
           ) t3encore ON t1.PROJ_ID = t3encore.PROJ_ID
-- CP600000582_End

-- Defect CP600000074 (DR1291) HVT 10/30/2007 begin
-- Roll up to project level 2 via LEFT(RPT_REV_SUM.PROJ_ID, 9) to avoid inserting records
-- with identical project level 2 IDs into XX_7KEYS_OUT_DETAIL.

     LEFT JOIN
          (select LEFT(t3b.PROJ_ID, 9)                     as PROJ_ID,
                  SUM(t3b.TGT_YTD_REV)                     as YTD_REVENUE,
                  SUM(t3b.TGT_YTD_COSTS)                   as YTD_COST,
                  SUM(t3b.TGT_YTD_REV - t3b.TGT_YTD_COSTS) as YTD_PROFIT,
                  SUM(t3b.TGT_ITD_REV)                     as ITD_REVENUE,
                  SUM(t3b.TGT_ITD_COSTS)                   as ITD_COST,
                  SUM(t3b.TGT_ITD_REV - t3b.TGT_ITD_COSTS) as ITD_PROFIT,
                  SUM(t3b.ITD_VALUE)                       as ITD_VALUE,
                  SUM(t3b.ITD_FUNDING)                     as ITD_FUNDING
             from IMAPS.Deltek.RPT_REV_SUM t3b
            where t3b.FY_CD      = @in_FY_CD
              and t3b.PD_NO      = @in_period_num
-- CP600000288_Begin
              and t3b.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000288_End
              and t3b.SUB_PD_NO  = (select MAX(t3c.SUB_PD_NO)
                                      from IMAPS.Deltek.RPT_REV_SUM t3c
                                     where t3c.FY_CD      = t3b.FY_CD
                                       and t3c.PD_NO      = t3b.PD_NO
                                       and t3c.PROJ_ID    = t3b.PROJ_ID
-- CP600000288_Begin
                                       and t3c.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000288_End
                                  )
            group by LEFT(t3b.PROJ_ID, 9)
          ) t3 ON t1.PROJ_ID = t3.PROJ_ID
-- Defect CP600000074 (DR1291) HVT 10/30/2007 end
-- Defect CP600000074 (CR998) Veera 10/08/07 end

-- Defect CP600000074 (CR1170) Veera 10/08/07 Begin
/*
     LEFT JOIN
          (select TRN_PROJ_ID, FY_CD, PD_NO, SUM(BILL_AMT) as UNBILLED_REVENUE
             from IMAPS.Deltek.Z_BLPUBILL_RPT
            where FY_CD = @in_FY_CD
              and PD_NO = @in_period_num
            group by TRN_PROJ_ID, FY_CD, PD_NO
          ) t4 ON t1.PROJ_ID = t4.TRN_PROJ_ID
*/
-- Defect CP600000074 (CR1170) Veera 10/08/07 End

     LEFT JOIN
          (select t5a.PROJ_ID,
                  t5a.PROJ_RPT_ID, t5b.L3_PROJ_RPT_NAME, t5b.L4_PROJ_RPT_NAME, t5b.L5_PROJ_RPT_NAME,
                  L1_PROJ_RPT_SG_ID, t5b.L2_PROJ_RPT_SG_ID, t5b.L3_PROJ_RPT_SG_ID, t5b.L4_PROJ_RPT_SG_ID
             from IMAPS.Deltek.PROJ_RPT_PROJ t5a,
                  IMAPS.Deltek.PROJ_RPT_ID t5b
            where t5a.PROJ_RPT_ID = t5b.PROJ_RPT_ID
              and t5a.COMPANY_ID = t5b.COMPANY_ID
-- CP600000288_Begin
              and t5b.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000288_End
-- Defect 1618 begin
              and LEFT(t5a.PROJ_RPT_ID, 4) = 'INDU'
-- Defect 1618 end
          ) t5 ON t1.PROJ_ID = t5.PROJ_ID AND t1.LVL_NO = 2
     LEFT JOIN
          (select PROJ_ID,
                  SUM(BAL_DUE_AMT) as AGED_BILL_AMT
             from IMAPS.Deltek.AR_HDR_HS
            where DUE_DT < GETDATE()
-- CP600000288_Begin
              and COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000288_End
            group by PROJ_ID
          ) t7 ON t1.PROJ_ID = t7.PROJ_ID
     LEFT JOIN
          IMAPS.Deltek.PROJ_REV_SETUP t9
          ON
          (t1.PROJ_ID = t9.PROJ_ID
-- CP600000288_Begin
           AND
           t9.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000288_End
          )
     LEFT JOIN
          (select t10a.PROJ_ID, t10a.BILLED_AMT
             from IMAPS.Deltek.PROJ_BILL_HS t10a
            where t10a.FY_CD = @in_FY_CD
              and t10a.PD_NO = @in_period_num
              and t10a.SUB_PD_NO = (select MAX(t10b.SUB_PD_NO)
                                     from IMAPS.Deltek.PROJ_BILL_HS t10b
                                    where t10b.FY_CD   = t10a.FY_CD
                                      and t10b.PD_NO   = t10a.PD_NO
                                      and t10b.PROJ_ID = t10a.PROJ_ID
                                   )
          ) t10 ON t1.PROJ_ID = t10.PROJ_ID
     LEFT JOIN
          (select t11a.PROJ_ID, t11b.PROJ_RPT_ID,
                  (t11b.L2_PROJ_RPT_NAME + ' - ' + t11b.L3_PROJ_RPT_NAME) as SERVICE_AREA_DESCRIPTION,
                   t11b.L4_PROJ_RPT_NAME as FEDERAL_SERVICE_AREA_DESC
             from IMAPS.Deltek.PROJ_RPT_PROJ t11a,
                  IMAPS.Deltek.PROJ_RPT_ID t11b
            where t11a.PROJ_RPT_ID = t11b.PROJ_RPT_ID
              and t11a.COMPANY_ID = t11b.COMPANY_ID
-- CP600000288_Begin
              and t11b.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000288_End
-- Defect CP600000163 (DR1388) begin
              and UPPER(t11b.L1_PROJ_RPT_NAME) = 'SERVICE AREA'
              and LEN(t11a.PROJ_ID) = 9
          ) t11 ON t1.PROJ_ID = t11.PROJ_ID
-- Defect CP600000163 (DR1388) end
-- Defect CP600000980 begin 
LEFT JOIN
     IMAPSstg.dbo.XX_INDUSTRY_CORE_INVEST_MAPPING t13
        on
        t11.PROJ_RPT_ID = t13.PROJ_RPT_ID
-- Defect CP600000980 end
-- CP600000288_Begin
/*
          IMAPS.Deltek.ORG t12
    WHERE t1.ORG_ID = t12.ORG_ID
      AND t1.COMPANY_ID = t12.COMPANY_ID
      AND t1.COMPANY_ID = @DIV_16_COMPANY_ID
      AND t12.L2_ORG_SEG_ID != 'S' -- exclude projects whose org is "Shop Orders"
*/
     LEFT JOIN
          IMAPS.Deltek.ORG t12
          ON
          (t1.ORG_ID = t12.ORG_ID
           AND
           t12.L2_ORG_SEG_ID != 'S' -- exclude projects whose org is "Shop Orders"
          )
    WHERE t1.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000288_End
    ORDER BY t1.PROJ_ID

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to insert records into staging table XX_7KEYS_OUT_DETAIL failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into staging table XX_7KEYS_OUT_DETAIL'
      GOTO BL_ERROR_HANDLER
   END

IF @row_count = 0
   BEGIN
      SET @out_STATUS_DESCRIPTION = 'No Costpoint data exist that meet the user-supplied selection criteria (input parameter values).'
      RETURN(0)
   END




PRINT 'Update staging table XX_7KEYS_OUT_DETAIL with rolled up key account data for revenue-recognizing levels ...'

/*
 * Key account data happen only at project level 2 records
 * (PROJ_RPT_ID.L1_PROJ_RPT_SG_ID + '.' + PROJ_RPT_ID.L2_PROJ_RPT_SG_ID + '.' + PROJ_RPT_ID.L3_PROJ_RPT_SG_ID + '.' + PROJ_RPT_ID.L4_PROJ_RPT_SG_ID) is used as KEY_ACCOUNT
 * PROJ_RPT_ID.L4_PROJ_RPT_NAME is used as KEY_ACCOUNT_NAME
 *
 * Set KEY_ACCOUNT and KEY_ACCOUNT_NAME of records at revenue-recognizing levels to that of level 2.
 */

-- Defect 1618 Begin

SELECT PROJ_ID, L1_PROJ_SEG_ID, L2_PROJ_SEG_ID, KEY_ACCOUNT, KEY_ACCOUNT_NAME
  INTO #tmp_KEY_ACCOUNT
  FROM dbo.XX_7KEYS_OUT_DETAIL
 WHERE KEY_ACCOUNT is not null
   AND LVL_NO = 2

UPDATE dbo.XX_7KEYS_OUT_DETAIL
   SET KEY_ACCOUNT = tmp.KEY_ACCOUNT,
       KEY_ACCOUNT_NAME = tmp.KEY_ACCOUNT_NAME
  FROM dbo.XX_7KEYS_OUT_DETAIL dtl
       INNER JOIN
       #tmp_KEY_ACCOUNT tmp
       ON
       (dtl.PROJ_ID like (tmp.L1_PROJ_SEG_ID + '%')
       AND 
       dtl.L1_PROJ_SEG_ID in (SELECT L1_PROJ_SEG_ID
                                FROM dbo.XX_7KEYS_OUT_DETAIL
                               WHERE L1_PROJ_SEG_ID LIKE (tmp.L1_PROJ_SEG_ID + '%')
                                 AND LVL_NO = 2
                               GROUP BY L1_PROJ_SEG_ID
                              HAVING COUNT(1) = 1)
	)
  WHERE dtl.S_REV_FORMULA_CD is not null
    AND dtl.KEY_ACCOUNT is null
    AND dtl.LVL_NO >= 1 -- the contract has only one level 2 record

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to update key account data (LVL_NO >= 1) in staging table XX_7KEYS_OUT_DETAIL failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'key account data (LVL_NO >= 1) in staging table XX_7KEYS_OUT_DETAIL'
      DROP TABLE #tmp_KEY_ACCOUNT
      GOTO BL_ERROR_HANDLER
   END

UPDATE dbo.XX_7KEYS_OUT_DETAIL
   SET KEY_ACCOUNT = tmp.KEY_ACCOUNT,
       KEY_ACCOUNT_NAME = tmp.KEY_ACCOUNT_NAME
  FROM dbo.XX_7KEYS_OUT_DETAIL dtl
       INNER JOIN
       #tmp_KEY_ACCOUNT tmp
       ON
       (dtl.PROJ_ID like (tmp.L1_PROJ_SEG_ID + '.' + tmp.L2_PROJ_SEG_ID + '%')
       AND 
       dtl.L1_PROJ_SEG_ID in (SELECT L1_PROJ_SEG_ID
                                FROM dbo.XX_7KEYS_OUT_DETAIL
                               WHERE L1_PROJ_SEG_ID LIKE (tmp.L1_PROJ_SEG_ID + '%')
                                 AND LVL_NO = 2
                               GROUP BY L1_PROJ_SEG_ID
                              HAVING COUNT(1) > 1)
       )
 WHERE dtl.S_REV_FORMULA_CD is not null
   AND dtl.LVL_NO > 2 -- the contract has multiple level 2 records

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to update key account data (LVL_NO > 2) in staging table XX_7KEYS_OUT_DETAIL failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'key account data (LVL_NO > 2) in staging table XX_7KEYS_OUT_DETAIL'
      DROP TABLE #tmp_KEY_ACCOUNT
      GOTO BL_ERROR_HANDLER
   END

DROP TABLE #tmp_KEY_ACCOUNT

-- Defect 1618 End

PRINT 'Calculate aged receivable ...'

SELECT dtl.PROJ_ID, SUM(ar.BAL_DUE_AMT) as AGED_RECEIVABLE_31TO60DAYS
  INTO #tmp_AGED_RECEIVABLE_31TO60DAYS
  FROM dbo.XX_7KEYS_OUT_DETAIL dtl
       INNER JOIN
       IMAPS.Deltek.AR_HDR_HS ar
       ON
       (dtl.PROJ_ID = ar.PROJ_ID
        AND
        ar.INVC_DT IS NOT NULL
        AND
        DATEDIFF(DAY, ar.INVC_DT, GETDATE()) >= 31 AND DATEDIFF(DAY, ar.INVC_DT, GETDATE()) <= 60
-- CP600000288_Begin
        AND
        ar.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000288_End
       )
 GROUP BY dtl.PROJ_ID


UPDATE dbo.XX_7KEYS_OUT_DETAIL
   SET AGED_RECEIVABLE_31TO60DAYS = tmp.AGED_RECEIVABLE_31TO60DAYS
  FROM dbo.XX_7KEYS_OUT_DETAIL dtl
       INNER JOIN
       #tmp_AGED_RECEIVABLE_31TO60DAYS tmp
       ON
       (dtl.PROJ_ID = tmp.PROJ_ID)

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to update aged receivable data (31 to 60 days) in staging table XX_7KEYS_OUT_DETAIL failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'aged receivable data (31 to 60 days) in staging table XX_7KEYS_OUT_DETAIL'
      DROP TABLE dbo.#tmp_AGED_RECEIVABLE_61TO90DAYS
      GOTO BL_ERROR_HANDLER
   END

DROP TABLE #tmp_AGED_RECEIVABLE_31TO60DAYS

SELECT dtl.PROJ_ID, SUM(ar.BAL_DUE_AMT) as AGED_RECEIVABLE_61TO90DAYS
  INTO #tmp_AGED_RECEIVABLE_61TO90DAYS
  FROM dbo.XX_7KEYS_OUT_DETAIL dtl
       INNER JOIN
       IMAPS.Deltek.AR_HDR_HS ar
       ON
       (dtl.PROJ_ID = ar.PROJ_ID
        AND
        ar.INVC_DT IS NOT NULL
        AND
        DATEDIFF(DAY, ar.INVC_DT, GETDATE()) >= 61 AND DATEDIFF(DAY, ar.INVC_DT, GETDATE()) <= 90
-- CP600000288_Begin
        AND
        ar.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000288_End
       )
 GROUP BY dtl.PROJ_ID

UPDATE dbo.XX_7KEYS_OUT_DETAIL
   SET AGED_RECEIVABLE_61TO90DAYS = tmp.AGED_RECEIVABLE_61TO90DAYS
  FROM dbo.XX_7KEYS_OUT_DETAIL dtl
       INNER JOIN
       #tmp_AGED_RECEIVABLE_61TO90DAYS tmp
       ON
       (dtl.PROJ_ID = tmp.PROJ_ID)

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to update aged receivable data (61 to 90 days) in staging table XX_7KEYS_OUT_DETAIL failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'aged receivable data (61 to 90 days) in staging table XX_7KEYS_OUT_DETAIL'
      DROP TABLE dbo.#tmp_AGED_RECEIVABLE_61TO90DAYS
      GOTO BL_ERROR_HANDLER
   END

DROP TABLE #tmp_AGED_RECEIVABLE_61TO90DAYS

SELECT dtl.PROJ_ID, SUM(ar.BAL_DUE_AMT) as AGED_RECEIVABLE_OVER90DAYS
  INTO #tmp_AGED_RECEIVABLE_OVER90DAYS
  FROM dbo.XX_7KEYS_OUT_DETAIL dtl
       INNER JOIN
       IMAPS.Deltek.AR_HDR_HS ar
       ON
       (dtl.PROJ_ID = ar.PROJ_ID
        AND
        ar.INVC_DT IS NOT NULL
        AND
        DATEDIFF(DAY, ar.INVC_DT, GETDATE()) >= 91
-- CP600000288_Begin
        AND
        ar.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000288_End
       )
 GROUP BY dtl.PROJ_ID

UPDATE dbo.XX_7KEYS_OUT_DETAIL
   SET AGED_RECEIVABLE_OVER90DAYS = tmp.AGED_RECEIVABLE_OVER90DAYS
  FROM dbo.XX_7KEYS_OUT_DETAIL dtl
       INNER JOIN
       #tmp_AGED_RECEIVABLE_OVER90DAYS tmp
       ON
       (dtl.PROJ_ID = tmp.PROJ_ID)

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to update aged receivable data (over 90 days) in staging table XX_7KEYS_OUT_DETAIL failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'aged receivable data (over 90 days) in staging table XX_7KEYS_OUT_DETAIL'
      DROP TABLE dbo.#tmp_AGED_RECEIVABLE_OVER90DAYS
      GOTO BL_ERROR_HANDLER
   END

DROP TABLE #tmp_AGED_RECEIVABLE_OVER90DAYS

-- Defect CP600000074 (CR1170) Veera 10/08/07 Begin
-- Fix for Defect CP600000074 (CR1170) renders the unbilled revenue calculation code below obsolete
/*
PRINT 'Calculate unbilled revenue ...'

SELECT dtl.PROJ_ID, SUM(unbill.BILL_AMT) as UNBILLED_REVENUE_31TO60DAYS
  INTO #tmp_UNBILLED_REVENUE_31TO60DAYS
  FROM dbo.XX_7KEYS_OUT_DETAIL dtl
       INNER JOIN IMAPS.Deltek.Z_BLPUBILL_RPT unbill
       ON (dtl.PROJ_ID = unbill.INVC_PROJ_ID)
-- Defect 1764 begin
 WHERE DATEDIFF(DAY, CAST(unbill.FY_CD + '-' + CAST(unbill.PD_NO AS varchar(2)) + '-' + '01' AS smalldatetime), @usr_dt) >= 31
   AND DATEDIFF(DAY, CAST(unbill.FY_CD + '-' + CAST(unbill.PD_NO AS varchar(2)) + '-' + '01' AS smalldatetime), @usr_dt) <= 60
-- Defect 1764 end
 GROUP BY dtl.PROJ_ID

UPDATE dbo.XX_7KEYS_OUT_DETAIL
   SET UNBILLED_REVENUE_31TO60DAYS = tmp.UNBILLED_REVENUE_31TO60DAYS
  FROM dbo.XX_7KEYS_OUT_DETAIL dtl
       INNER JOIN
       #tmp_UNBILLED_REVENUE_31TO60DAYS tmp
       ON
       (dtl.PROJ_ID = tmp.PROJ_ID)

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to update unbilled revenue data (31 to 60 days) in staging table XX_7KEYS_OUT_DETAIL failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'unbilled revenue data (31 to 60 days) in staging table XX_7KEYS_OUT_DETAIL'
      DROP TABLE dbo.#tmp_UNBILLED_REVENUE_31TO60DAYS
      GOTO BL_ERROR_HANDLER
   END

DROP TABLE #tmp_UNBILLED_REVENUE_31TO60DAYS

select dtl.PROJ_ID, SUM(unbill.BILL_AMT) as UNBILLED_REVENUE_61TO90DAYS
  into #tmp_UNBILLED_REVENUE_61TO90DAYS
  FROM dbo.XX_7KEYS_OUT_DETAIL dtl
       INNER JOIN IMAPS.Deltek.Z_BLPUBILL_RPT unbill
       ON (dtl.PROJ_ID = unbill.INVC_PROJ_ID)
-- Defect 1764 begin
 WHERE DATEDIFF(DAY, CAST(unbill.FY_CD + '-' + CAST(unbill.PD_NO AS varchar(2)) + '-' + '01' AS smalldatetime), @usr_dt) >= 61
   AND DATEDIFF(DAY, CAST(unbill.FY_CD + '-' + CAST(unbill.PD_NO AS varchar(2)) + '-' + '01' AS smalldatetime), @usr_dt) <= 90
-- Defect 1764 end
 GROUP BY dtl.PROJ_ID

UPDATE dbo.XX_7KEYS_OUT_DETAIL
   SET UNBILLED_REVENUE_61TO90DAYS = tmp.UNBILLED_REVENUE_61TO90DAYS
  FROM dbo.XX_7KEYS_OUT_DETAIL dtl
       INNER JOIN
       #tmp_UNBILLED_REVENUE_61TO90DAYS tmp
       ON
       (dtl.PROJ_ID = tmp.PROJ_ID)

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to update unbilled revenue data (61 to 90 days) in staging table XX_7KEYS_OUT_DETAIL failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'unbilled revenue data (61 to 90 days) in staging table XX_7KEYS_OUT_DETAIL'
      DROP TABLE dbo.#tmp_UNBILLED_REVENUE_61TO90DAYS
      GOTO BL_ERROR_HANDLER
   END

DROP TABLE #tmp_UNBILLED_REVENUE_61TO90DAYS

select dtl.PROJ_ID, SUM(unbill.BILL_AMT) as UNBILLED_REVENUE_OVER90DAYS
  into #tmp_UNBILLED_REVENUE_OVER90DAYS
  FROM dbo.XX_7KEYS_OUT_DETAIL dtl
       INNER JOIN IMAPS.Deltek.Z_BLPUBILL_RPT unbill
       ON (dtl.PROJ_ID = unbill.INVC_PROJ_ID)
-- Defect 1764 Fix begin
 WHERE DATEDIFF(DAY, CAST(unbill.FY_CD + '-' + CAST(unbill.PD_NO AS varchar(2)) + '-' + '01' AS smalldatetime), @usr_dt) >= 91
-- Defect 1764 Fix end
 GROUP BY dtl.PROJ_ID
	
UPDATE dbo.XX_7KEYS_OUT_DETAIL
   SET UNBILLED_REVENUE_OVER90DAYS = tmp.UNBILLED_REVENUE_OVER90DAYS
  FROM dbo.XX_7KEYS_OUT_DETAIL dtl
       INNER JOIN
       #tmp_UNBILLED_REVENUE_OVER90DAYS tmp
       ON
       (dtl.PROJ_ID = tmp.PROJ_ID)

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to update unbilled revenue data (over 90 days) in staging table XX_7KEYS_OUT_DETAIL failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'unbilled revenue data (over 90 days) in staging table XX_7KEYS_OUT_DETAIL'
      DROP TABLE dbo.#tmp_UNBILLED_REVENUE_OVER90DAYS
      GOTO BL_ERROR_HANDLER
   END

DROP TABLE #tmp_UNBILLED_REVENUE_OVER90DAYS
*/
-- Defect CP600000074 (CR1170) Veera 10/08/07 End

-- Defect 1618 end

/*
 * Process the data in XX_7KEYS_OUT_DETAIL to limit reporting to only the first 3 levels (1, 2, 3)
 * of PROJ_ID with level 3 holding the total value of levels 3, 4, 5 and 6.
 */

EXEC @ret_code = dbo.XX_7KEYS_PROCESS_OUTPUT_DATA_SP
   @out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION OUTPUT

IF @ret_code <> 0
   GOTO BL_ERROR_HANDLER



PRINT 'Populate header table XX_7KEYS_OUT_HDR ...'

-- Get the total number of records from staging table XX_7KEYS_OUT_DETAIL that will ultimately appear on the final output file
SELECT @row_count = COUNT(1) 
  FROM dbo.XX_7KEYS_OUT_DETAIL
 WHERE S_REV_FORMULA_CD IS NOT NULL

INSERT INTO dbo.XX_7KEYS_OUT_HDR
   SELECT @in_STATUS_RECORD_NUM,
          @row_count,
          SUM(PERIOD_REVENUE) as PERIOD_REVENUE_TOTAL,
          SUM(PERIOD_COST) as PERIOD_COST_TOTAL, 
-- CP600000582_Begin
          SUM(QTD_REVENUE) as QTD_REVENUE_TOTAL,
          SUM(QTD_COST) as QTD_COST_TOTAL,
-- CP600000582_End
          SUM(YTD_REVENUE) as YTD_REVENUE_TOTAL,
          SUM(YTD_COST) as YTD_COST_TOTAL,
          SUM(ITD_REVENUE) as ITD_REVENUE_TOTAL,
          SUM(ITD_COST) as ITD_COST_TOTAL,
          SUM(ITD_FUNDING) as ITD_FUNDING_TOTAL, 
          SUM(UNBILLED_REVENUE) as UNBILLED_REVENUE_TOTAL,
          SUM(UNBILLED_REVENUE_31TO60DAYS) as UNBILLED_REVENUE_31TO60DAYS_TOTAL,
          SUM(UNBILLED_REVENUE_61TO90DAYS) as UNBILLED_REVENUE_61TO90DAYS_TOTAL,
          SUM(UNBILLED_REVENUE_OVER90DAYS) as UNBILLED_REVENUE_OVER90DAYS_TOTAL,
          SUM(AGED_BILL_AMT) as AGED_BILL_AMT_TOTAL,
          SUM(AGED_RECEIVABLE_31TO60DAYS) as AGED_RECEIVABLE_31TO60DAYS_TOTAL,
          SUM(AGED_RECEIVABLE_61TO90DAYS) as AGED_RECEIVABLE_61TO90DAYS_TOTAL,
          SUM(AGED_RECEIVABLE_OVER90DAYS) as AGED_RECEIVABLE_OVER90DAYS_TOTAL,
          SUM(BILLED_AMT) as BILLED_AMT_TOTAL
     FROM dbo.XX_7KEYS_OUT_DETAIL

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to insert records into table XX_7KEYS_OUT_HDR failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_7KEYS_OUT_HDR'
      GOTO BL_ERROR_HANDLER
   END

PRINT 'Populate detail output template table XX_7KEYS_OUT_DETAIL_TEMP ...'

/*
 * 03/06/2006 Add column aliases and limit the source records to project revenue-recognizing levels
 * XX_7KEYS_OUT_DETAIL_TEMP is the table used by bcp to prepare the Costpoint timesheet preprocessor flat file
 */
INSERT INTO dbo.XX_7KEYS_OUT_DETAIL_TEMP
   select CAST(isnull(PROJ_ID, '') as char(30)) as PROJ_ID,
          CAST(isnull(DATA_CATEGORY, '') as char(3)) as DATA_CATEGORY,
          CAST(isnull(CONTRACT_NAME, '') as char(25)) as CONTRACT_NAME,
          CAST(isnull(PROJ_NAME, '') as char(25)) PROJ_NAME,
          CAST(isnull(PRIME_CONTR_ID, '') as char(25)) as PRIME_CONTR_ID,
          CAST(isnull(PROJ_MGR_ID,'') as char(12)) as PROJ_MGR_ID,
          CAST(isnull(PROJ_MGR_NAME, '') as char(25)) as PROJ_MGR_NAME,
          CAST(isnull(PROJ_MGR_EMAIL,'') as char(60)) as PROJ_MGR_EMAIL,
          CAST(isnull(PROJ_EXECUTIVE_ID,'') as char(12)) as PROJ_EXECUTIVE_ID,
          CAST(isnull(PROJ_EXECUTIVE, '') as char(30)) as PROJ_EXECUTIVE,
          CAST(isnull(PROJ_EXECUTIVE_EMAIL,'') as char(60)) as PROJ_EXECUTIVE_EMAIL,
          CAST(isnull(FINANCIAL_MANAGER, '') as char(30)) as FINANCIAL_MANAGER,
          CAST(isnull(IBM_OPP_NUM_SIEBEL, '') as char(30)) as IBM_OPP_NUM_SIEBEL,
          CAST(isnull(CONTRACT_TYPE, '') as char(20)) CONTRACT_TYPE, 
          CAST(isnull(SERVICE_OFFERING,'') as char(30)) as SERVICE_OFFERING,
          CAST(isnull(SERVICE_AREA, '') as char(20)) as SERVICE_AREA,
          CAST(isnull(SERVICE_AREA_DESC, '') as char(55)) as SERVICE_AREA_DESC,
          CAST(isnull(FEDERAL_SERVICE_AREA_DESC,'') as char(25)) as FEDERAL_SERVICE_AREA_DESC,
          CAST(isnull(PRACTICE_AREA, '') as char(15)) as PRACTICE_AREA,
          CAST(isnull(ULTIMATE_CLIENT,'') as char(30)) as ULTIMATE_CLIENT,
          CAST(isnull(CORE_ACCOUNT, '') as char(30)) as CORE_ACCOUNT,
          CAST(isnull(MI0405_INDICATOR, '') as char(8)) as MI0405_INDICATOR,
          CAST(isnull(DIVISION, '') as char(2)) as DIVISION,
          CAST(isnull(INDUSTRY, '') as char(20)) as INDUSTRY,
          CAST(isnull(INDUSTRY_NAME, '') as char(80)) as INDUSTRY_NAME,
          CAST(isnull(KEY_ACCOUNT, '') as char(20)) as KEY_ACCOUNT,
          CAST(isnull(KEY_ACCOUNT_NAME, '') as char(25)) as KEY_ACCOUNT_NAME,
          isnull(CAST(GROSS_PROFIT_MARGIN as char(15)), '') as GROSS_PROFIT_MARGIN,
          CAST(isnull(CUST_LONG_NAME, '') as char(40)) as CUST_LONG_NAME,
          isnull(CAST(PERIOD_REVENUE as char(15)), '') as PERIOD_REVENUE,
          isnull(CAST(PERIOD_COST as char(15)), '') as PERIOD_COST,
          isnull(CAST(PERIOD_PROFIT as char(15)), '') as PERIOD_PROFIT,
-- CP600000582_Begin
          isnull(CAST(QTD_REVENUE as char(15)), '') as QTD_REVENUE, 
          isnull(CAST(QTD_COST as char(15)), '')    as QTD_COST, 
          isnull(CAST(QTD_PROFIT as char(15)), '')  as QTD_PROFIT,
-- CP600000582_End
          isnull(CAST(YTD_REVENUE as char(15)), '') as YTD_REVENUE,
          isnull(CAST(YTD_COST as char(15)), '') as YTD_COST,
          isnull(CAST(YTD_PROFIT as char(15)), '') as YTD_PROFIT,
          isnull(CAST(ITD_REVENUE as char(15)), '') as ITD_REVENUE,
          isnull(CAST(ITD_COST as char(15)), '') as ITD_COST,
          isnull(CAST(ITD_PROFIT as char(15)), '') asITD_PROFIT,
          isnull(CAST(ITD_VALUE as char(15)), '') as ITD_VALUE,
          isnull(CAST(ITD_FUNDING as char(15)), '') as ITD_FUNDING,
          isnull(CAST(UNBILLED_REVENUE as char(15)), '') as UNBILLED_REVENUE,
          isnull(CAST(UNBILLED_REVENUE_31TO60DAYS as char(15)), '') as UNBILLED_REVENUE_31TO60DAYS,
          isnull(CAST(UNBILLED_REVENUE_61TO90DAYS as char(15)), '') as UNBILLED_REVENUE_61TO90DAYS,
          isnull(CAST(UNBILLED_REVENUE_OVER90DAYS as char(15)), '') as UNBILLED_REVENUE_OVER90DAYS,
          isnull(CAST(AGED_BILL_AMT as char(15)), '') as AGED_BILL_AMT,
          isnull(CAST(AGED_RECEIVABLE_31TO60DAYS as char(15)), '') as AGED_RECEIVABLE_31TO60DAYS,
          isnull(CAST(AGED_RECEIVABLE_61TO90DAYS as char(15)), '') as AGED_RECEIVABLE_61TO90DAYS,
          isnull(CAST(AGED_RECEIVABLE_OVER90DAYS as char(15)), '') as AGED_RECEIVABLE_OVER90DAYS,
          isnull(CAST(BILLED_AMT as char(15)), '') as BILLED_AMT,
          CAST(isnull(MOD_NUM, '') as char(10)) as MOD_NUM,
-- Defect 1321 Begin
--        CONVERT(char(10), isnull(PERIOD_OF_PERFORMANCE_START_DT, ''), 120) as PERIOD_OF_PERFORMANCE_START_DT, -- date style yyyy-mm-dd
--        CONVERT(char(10), isnull(PERIOD_OF_PERFORMANCE_END_DT, ''), 120) as PERIOD_OF_PERFORMANCE_END_DT

          isnull((CAST(DATEPART(year, PERIOD_OF_PERFORMANCE_START_DT) as char(4)) +
                  CASE
                     WHEN DATEPART(month, PERIOD_OF_PERFORMANCE_START_DT) < 10
                        THEN '0' + CAST(DATEPART(month, PERIOD_OF_PERFORMANCE_START_DT) as varchar(2))
                        ELSE CAST(DATEPART(month, PERIOD_OF_PERFORMANCE_START_DT) as varchar(2))
                     END +
                  CASE 
                     WHEN DATEPART(day, PERIOD_OF_PERFORMANCE_START_DT) < 10
                        THEN '0' + CAST(DATEPART(day, PERIOD_OF_PERFORMANCE_START_DT) as varchar(2))
                        ELSE CAST(DATEPART(day, PERIOD_OF_PERFORMANCE_START_DT) as varchar(2))
                  END
                 ),
                 SPACE(10)
                ) as PERIOD_OF_PERFORMANCE_START_DT, -- date style yyyymmdd

          isnull((CAST(DATEPART(year, PERIOD_OF_PERFORMANCE_END_DT) as char(4)) +
                  CASE
                     WHEN DATEPART(month, PERIOD_OF_PERFORMANCE_END_DT) < 10
                        THEN '0' + CAST(DATEPART(month, PERIOD_OF_PERFORMANCE_END_DT) as varchar(2))
                        ELSE CAST(DATEPART(month, PERIOD_OF_PERFORMANCE_END_DT) as varchar(2))
                     END +
                  CASE 
                     WHEN DATEPART(day, PERIOD_OF_PERFORMANCE_END_DT) < 10
                        THEN '0' + CAST(DATEPART(day, PERIOD_OF_PERFORMANCE_END_DT) as varchar(2))
                        ELSE CAST(DATEPART(day, PERIOD_OF_PERFORMANCE_END_DT) as varchar(2))
                  END
                 ),
                 SPACE(10)
                ) as PERIOD_OF_PERFORMANCE_END_DT
-- Defect 1321 End
     from dbo.XX_7KEYS_OUT_DETAIL
    where STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM
      and LVL_NO = 2
    order by PROJ_ID

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to insert records into table XX_7KEYS_OUT_DETAIL_TEMP failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_7KEYS_OUT_DETAIL_TEMP'
      GOTO BL_ERROR_HANDLER
   END

-- DR7490_begin
PRINT 'Update XX_7KEYS_OUT_DETAIL_TEMP with rolled up project level 2 aged account receivable amounts ...'

UPDATE dbo.XX_7KEYS_OUT_DETAIL_TEMP
   SET AGED_BILL_AMT = b.AGED_BILL_AMT,
       AGED_RECEIVABLE_31TO60DAYS = b.AGED_RECEIVABLE_31TO60DAYS,
       AGED_RECEIVABLE_61TO90DAYS = b.AGED_RECEIVABLE_61TO90DAYS,
       AGED_RECEIVABLE_OVER90DAYS = b.AGED_RECEIVABLE_OVER90DAYS
  FROM (SELECT LEFT(a.PROJ_ID, 9) as LVL2_PROJ_ID,
               SUM(a.AGED_BILL_AMT) as AGED_BILL_AMT,
               SUM(a.AGED_RECEIVABLE_31TO60DAYS) as AGED_RECEIVABLE_31TO60DAYS,
               SUM(a.AGED_RECEIVABLE_61TO90DAYS) as AGED_RECEIVABLE_61TO90DAYS,
               SUM(a.AGED_RECEIVABLE_OVER90DAYS) as AGED_RECEIVABLE_OVER90DAYS
          FROM dbo.XX_7KEYS_OUT_DETAIL a
         WHERE a.S_REV_FORMULA_CD is not NULL
         GROUP BY LEFT(a.PROJ_ID, 9)
       ) b
 WHERE PROJ_ID = b.LVL2_PROJ_ID

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to update table XX_7KEYS_OUT_DETAIL_TEMP with rolled up project level 2 aged account receivable amounts failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'table XX_7KEYS_OUT_DETAIL_TEMP with rolled up project level 2 aged account receivable amounts'
      GOTO BL_ERROR_HANDLER
   END
-- DR7490_end

-- Defect CP600000074 (CR1170) Veera 10/08/07 Begin
PRINT 'Build FY- and period-specific unbilled revenue data ...'

DECLARE @ReturnValue integer
SET @ReturnValue = 0

EXEC @ret_code = dbo.XX_CALCULATE_UNBILLED_REVENUE_SP
   @FY_CD       = @in_FY_CD,
   @PD_NO       = @in_period_num,
   @ReturnValue = @ReturnValue OUTPUT

IF @ret_code <> 0
   BEGIN
      -- Attempt to refresh table XX_REVENUE_UNBILLED_SUMMARY via XX_CALCULATE_UNBILLED_REVENUE_SP failed.
      SET @error_msg_placeholder1 = 'refresh'
      SET @error_msg_placeholder2 = 'table XX_REVENUE_UNBILLED_SUMMARY via XX_CALCULATE_UNBILLED_REVENUE_SP'
      GOTO BL_ERROR_HANDLER
   END

PRINT 'Update XX_7KEYS_OUT_DETAIL_TEMP with rolled up project level 2 unbilled revenue data from XX_REVENUE_UNBILLED_SUMMARY ...'

UPDATE dbo.XX_7KEYS_OUT_DETAIL_TEMP
   SET UNBILLED_REVENUE	= a.UNBILL_0_TO_30 + a.UNBILL_30_TO_60 + a.UNBILL_60_TO_90 + a.UNBILL_90_TO_120 + a.UNBILL_120_PLUS,
       UNBILLED_REVENUE_31TO60DAYS = a.UNBILL_30_TO_60,
       UNBILLED_REVENUE_61TO90DAYS = a.UNBILL_60_TO_90,
       UNBILLED_REVENUE_OVER90DAYS = a.UNBILL_90_TO_120 + a.UNBILL_120_PLUS
  FROM (SELECT LEFT(PROJ_ID, 9)      as L2_PROJ,
               SUM(UNBILL_0_TO_30)   as UNBILL_0_TO_30,
               SUM(UNBILL_30_TO_60)  as UNBILL_30_TO_60,
               SUM(UNBILL_60_TO_90 ) as UNBILL_60_TO_90,
               SUM(UNBILL_90_TO_120) as UNBILL_90_TO_120,
               SUM(UNBILL_120_PLUS)  as UNBILL_120_PLUS
          FROM dbo.XX_REVENUE_UNBILLED_SUMMARY
         GROUP BY LEFT(PROJ_ID, 9)
       ) a
 WHERE PROJ_ID = a.L2_PROJ

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to update table XX_7KEYS_OUT_DETAIL_TEMP with rolled up project level 2 data from table XX_REVENUE_UNBILLED_SUMMARY failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'table XX_7KEYS_OUT_DETAIL_TEMP with rolled up project level 2 data from table XX_REVENUE_UNBILLED_SUMMARY'
      GOTO BL_ERROR_HANDLER
   END

-- Rollup for those projects with revenue recognition set up at levels 3 and lower
UPDATE dbo.XX_7KEYS_OUT_DETAIL_TEMP
   SET UNBILLED_REVENUE	= a.UNBILL_0_TO_30 + a.UNBILL_30_TO_60 + a.UNBILL_60_TO_90 + a.UNBILL_90_TO_120 + a.UNBILL_120_PLUS,
       UNBILLED_REVENUE_31TO60DAYS = a.UNBILL_30_TO_60,
       UNBILLED_REVENUE_61TO90DAYS = a.UNBILL_60_TO_90,
       UNBILLED_REVENUE_OVER90DAYS = a.UNBILL_90_TO_120 + a.UNBILL_120_PLUS
  FROM (SELECT LEFT(t1.PROJ_ID, 9)      as L2_PROJ,
               SUM(t1.UNBILL_0_TO_30)   as UNBILL_0_TO_30,
               SUM(t1.UNBILL_30_TO_60)  as UNBILL_30_TO_60,
               SUM(t1.UNBILL_60_TO_90 ) as UNBILL_60_TO_90,
               SUM(t1.UNBILL_90_TO_120) as UNBILL_90_TO_120,
               SUM(t1.UNBILL_120_PLUS)  as UNBILL_120_PLUS
          FROM dbo.XX_REVENUE_UNBILLED_SUMMARY t1,
               dbo.XX_7KEYS_OUT_DETAIL t2
         WHERE t1.PROJ_ID = t2.PROJ_ID
           AND t2.S_REV_FORMULA_CD IS NOT NULL
           AND t2.LVL_NO > 2
         GROUP BY LEFT(t1.PROJ_ID, 9)
       ) a
 WHERE PROJ_ID = a.L2_PROJ

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to update table XX_7KEYS_OUT_DETAIL_TEMP with rolled up project levels >= 3 data from table XX_REVENUE_UNBILLED_SUMMARY failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'table XX_7KEYS_OUT_DETAIL_TEMP with rolled up project levels >= 3 data from table XX_REVENUE_UNBILLED_SUMMARY failed'
      GOTO BL_ERROR_HANDLER
   END

-- Defect CP600000074 (CR1170) Veera 10/08/07 End

-- Defect CP600000074 (DR1264) Veera 10/08/07 begin
-- Extract revenue from lower levels and roll it up to level 2.
UPDATE dbo.XX_7KEYS_OUT_DETAIL_TEMP
   SET PERIOD_REVENUE = a.PERIOD_REVENUE,
       PERIOD_COST    = a.PERIOD_COST,
       PERIOD_PROFIT  = a.PERIOD_PROFIT,
-- CP600000582_Begin
       QTD_REVENUE    = a.QTD_REVENUE,
       QTD_COST       = a.QTD_COST,
       QTD_PROFIT     = a.QTD_PROFIT
-- CP600000582_End
-- Defect CP600000074 (DR1291) HVT 10/30/2007 begin
-- Fix for DR1291 overcomes fix for DR1264
--     YTD_REVENUE    = a.YTD_REVENUE,
--     YTD_COST       = a.YTD_COST,
--     YTD_PROFIT     = a.YTD_PROFIT,
--     ITD_REVENUE    = a.ITD_REVENUE,
--     ITD_COST       = a.ITD_COST,
--     ITD_PROFIT     = a.ITD_PROFIT,
--     ITD_VALUE      = a.ITD_VALUE,
--     ITD_FUNDING    = a.ITD_FUNDING
-- Defect CP600000074 (DR1291) HVT 10/30/2007 end
  FROM (SELECT LEFT(PROJ_ID, 9)    as L2_PROJ,
               SUM(PERIOD_REVENUE) as PERIOD_REVENUE,
               SUM(PERIOD_COST)    as PERIOD_COST,
               SUM(PERIOD_PROFIT)  as PERIOD_PROFIT,
-- CP600000582_Begin
               SUM(QTD_REVENUE)    as QTD_REVENUE,
               SUM(QTD_COST)       as QTD_COST,
               SUM(QTD_PROFIT)     as QTD_PROFIT
-- CP600000582_End
-- Defect CP600000074 (DR1291) HVT 10/30/2007 begin
--             SUM(YTD_REVENUE)    as YTD_REVENUE,
--             SUM(YTD_COST)       as YTD_COST,
--             SUM(YTD_PROFIT)     as YTD_PROFIT,
--             SUM(ITD_REVENUE)    as ITD_REVENUE,
--             SUM(ITD_COST )      as ITD_COST,
--             SUM(ITD_PROFIT)     as ITD_PROFIT,
--             SUM(ITD_VALUE)      as ITD_VALUE,
--             SUM(ITD_FUNDING)    as ITD_FUNDING
-- Defect CP600000074 (DR1291) HVT 10/30/2007 end
          FROM dbo.XX_7KEYS_OUT_DETAIL
         WHERE S_REV_FORMULA_CD IS NOT NULL
           AND LVL_NO > 2
	 GROUP BY LEFT(PROJ_ID, 9)
       ) a
 WHERE PROJ_ID = a.L2_PROJ

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to extract lower level revenue records and roll up to level 2 in table XX_7KEYS_OUT_DETAIL_TEMP failed.
      SET @error_msg_placeholder1 = 'extract'
      SET @error_msg_placeholder2 = 'lower level revenue records and roll up to level 2 in table XX_7KEYS_OUT_DETAIL_TEMP'
      GOTO BL_ERROR_HANDLER
   END

-- Defect CP600000074 (DR1264) Veera 10/08/07 end

PRINT 'Populate header output template table XX_7KEYS_OUT_HDR_TEMP ...'

INSERT INTO dbo.XX_7KEYS_OUT_HDR_TEMP
   select isnull(CAST(ROW_NUM_TOTAL as char(10)), '') as ROW_NUM_TOTAL,
          isnull(CAST(PERIOD_REVENUE_TOTAL as char(15)), '') as PERIOD_REVENUE_TOTAL,
          isnull(CAST(PERIOD_COST_TOTAL as char(15)), '') as PERIOD_COST_TOTAL,
-- CP600000582_Begin
          isnull(CAST(QTD_REVENUE_TOTAL as char(15)), '') as QTD_REVENUE_TOTAL,
          isnull(CAST(QTD_COST_TOTAL as char(15)), '') as QTD_COST_TOTAL,
-- CP600000582_End
          isnull(CAST(YTD_REVENUE_TOTAL as char(15)), '') as YTD_REVENUE_TOTAL,
          isnull(CAST(YTD_COST_TOTAL as char(15)), '') as YTD_COST_TOTAL,
          isnull(CAST(ITD_REVENUE_TOTAL as char(15)), '') as ITD_REVENUE_TOTAL,
          isnull(CAST(ITD_COST_TOTAL as char(15)), '') as ITD_COST_TOTAL,
          isnull(CAST(ITD_FUNDING_TOTAL as char(15)), '') as ITD_FUNDING_TOTAL,
          isnull(CAST(UNBILLED_REVENUE_TOTAL as char(15)), '') as UNBILLED_REVENUE_TOTAL,
          isnull(CAST(UNBILLED_REVENUE_31TO60DAYS_TOTAL as char(15)), '') as UNBILLED_REVENUE_31TO60DAYS_TOTAL,
          isnull(CAST(UNBILLED_REVENUE_61TO90DAYS_TOTAL as char(15)), '') as UNBILLED_REVENUE_61TO90DAYS_TOTAL,
          isnull(CAST(UNBILLED_REVENUE_OVER90DAYS_TOTAL as char(15)), '') as UNBILLED_REVENUE_OVER90DAYS_TOTAL,
          isnull(CAST(AGED_BILL_AMT_TOTAL as char(15)), '') as AGED_BILL_AMT_TOTAL,
          isnull(CAST(AGED_RECEIVABLE_31TO60DAYS_TOTAL as char(15)), '') as AGED_RECEIVABLE_31TO60DAYS_TOTAL,
          isnull(CAST(AGED_RECEIVABLE_61TO90DAYS_TOTAL as char(15)), '') as AGED_RECEIVABLE_61TO90DAYS_TOTAL,
          isnull(CAST(AGED_RECEIVABLE_OVER90DAYS_TOTAL as char(15)), '') as AGED_RECEIVABLE_OVER90DAYS_TOTAL,
          isnull(CAST(BILLED_AMT_TOTAL as char(15)), '') as BILLED_AMT_TOTAL
     from dbo.XX_7KEYS_OUT_HDR
    where STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to insert records into table XX_7KEYS_OUT_HDR_TEMP failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_7KEYS_OUT_HDR_TEMP'
      GOTO BL_ERROR_HANDLER
   END

RETURN(0)

BL_ERROR_HANDLER:

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_code,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)


GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON 
GO


SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_7KEYS_PROCESS_OUTPUT_DATA_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   DROP PROCEDURE [dbo].[XX_7KEYS_PROCESS_OUTPUT_DATA_SP]
GO

CREATE PROCEDURE [dbo].[XX_7KEYS_PROCESS_OUTPUT_DATA_SP]
(
@out_STATUS_DESCRIPTION varchar(255) = NULL OUTPUT
)
AS
/*******************************************************************************************************
Name:       XX_7KEYS_PROCESS_OUTPUT_DATA_SP
Author:     HVT
Created:    02/07/2006
Purpose:    The output record for level 3 should contain level 3 data and rolled up (summarized) data
            from all lower levels.
            Called by XX_7KEYS_GET_OUTPUT_DATA_SP.
Parameters: 
Result Set: None
Notes:      This program satisfies the requirements of Feature No. 478

Defect 611  Bob Russo has requested that rollup also occurs at level 2 and 1.

            The rolling up process implemented here is not an absolute one in that the amount of the
            parent level is not strictly equal to the sum of the amounts of the children levels.
            That is, whatever non-zero amount currently found at the parent level is used in the 
            summing; the parent level amount is not simply replaced by the result of the summing up of
            the children level amounts.

Defect 976  05/15/2006 Provide aged receivable and unbilled revenue data for 31-60 days, 61-90 days and
            more than 90 days. Also, change the source of (1) PRACTICE_AREA and SERVICE_AREA from Costpoint
            tables PROJ and GENL_UDEF, respectively, to PROJ_RPT_ID (via PROJ_RPT_PROJ) for both,
            and (2) UNBILLED_REVENUE from Costpoint table RPT_PROJ_UNBILLED to Z_BLPUBILL_RPT.

            07/14/2006 Discard S_REV_FORMULA_CD, RETAINAGE_AMT.

            07/18/2006 Apply rollup only to those project levels that are set up to recognize revenue.

CP600000074 10/08/2007 (BP&S No. CR1170) HVT
            Unbilled revenue data now come from table XX_REVENUE_UNBILLED_SUMMARY which is populated by
            the Calculated Unbilled Process. This renders the manual calculation of unbilled revenue
            values in the calling program XX_7KEYS_GET_OUTPUT_DATA_SP obsolete.

CP600000582 03/02/2009 Reference BP&S Service Request CR1888
            Add QTD_REVENUE, QTD_COST and QTD_PROFIT to output data.

********************************************************************************************************/

DECLARE @SP_NAME                     sysname,
        @PROJ_ID                     varchar(30),
        @LVL_NO                      smallint,
        @SQLServer_error_code        integer,
        @IMAPS_error_code            integer,
        @error_msg_placeholder1      sysname,
        @error_msg_placeholder2      sysname,
        @PERIOD_REVENUE              decimal(14, 2),
        @PERIOD_COST                 decimal(14, 2),
        @PERIOD_PROFIT               decimal(14, 2),
-- CP600000582_Begin
        @QTD_REVENUE                 decimal(14, 2),
        @QTD_COST                    decimal(14, 2),
        @QTD_PROFIT                  decimal(14, 2),
-- CP600000582_End
        @YTD_REVENUE                 decimal(14, 2),
        @YTD_COST                    decimal(14, 2),
        @YTD_PROFIT                  decimal(14, 2),
        @ITD_REVENUE                 decimal(14, 2),
        @ITD_COST                    decimal(14, 2),
        @ITD_PROFIT                  decimal(14, 2),
        @ITD_VALUE                   decimal(14, 2),
        @ITD_FUNDING                 decimal(14, 2),
-- Defect CP600000074 (CR1170) Begin
--      @UNBILLED_REVENUE            decimal(14, 2),
--      @UNBILLED_REVENUE_31TO60DAYS decimal(14, 2),
--      @UNBILLED_REVENUE_61TO90DAYS decimal(14, 2),
--      @UNBILLED_REVENUE_OVER90DAYS decimal(14, 2),
-- Defect CP600000074 (CR1170) End
        @AGED_RECEIVABLE_31TO60DAYS  decimal(14, 2),
        @AGED_RECEIVABLE_61TO90DAYS  decimal(14, 2),
        @AGED_RECEIVABLE_OVER90DAYS  decimal(14, 2),
        @AGED_BILL_AMT               decimal(14, 2),
        @BILLED_AMT                  decimal(14, 2)

-- set local constants
SET @SP_NAME = 'XX_7KEYS_PROCESS_OUTPUT_DATA_SP'

-- set local variables
SET @IMAPS_error_code = 204

-- initialize local variables
SET @PERIOD_REVENUE   = 0
SET @PERIOD_COST      = 0
SET @PERIOD_PROFIT    = 0
-- CP600000582_Begin
SET @QTD_REVENUE      = 0
SET @QTD_COST         = 0
SET @QTD_PROFIT       = 0
-- CP600000582_End
SET @YTD_REVENUE      = 0
SET @YTD_COST         = 0
SET @YTD_PROFIT       = 0
SET @ITD_REVENUE      = 0
SET @ITD_COST         = 0
SET @ITD_PROFIT       = 0
SET @ITD_VALUE        = 0
SET @ITD_FUNDING      = 0

-- Defect CP600000074 (CR1170) Begin
--SET @UNBILLED_REVENUE = 0
--SET @UNBILLED_REVENUE_31TO60DAYS = 0
--SET @UNBILLED_REVENUE_61TO90DAYS = 0
--SET @UNBILLED_REVENUE_OVER90DAYS = 0
-- Defect CP600000074 (CR1170) End

SET @AGED_RECEIVABLE_31TO60DAYS  = 0
SET @AGED_RECEIVABLE_61TO90DAYS  = 0
SET @AGED_RECEIVABLE_OVER90DAYS  = 0
SET @AGED_BILL_AMT = 0
SET @BILLED_AMT    = 0

PRINT 'Limit reporting to XX_7KEYS_OUT_DETAIL records with project ID at levels 1-3 ...'

/*
 * Because the UPDATE command does not allow the use of aggregate function SUM(), use a temporary table and a cursor to perform SUM().
 * Extract from table XX_7KEYS_OUT_DETAIL only those records whose project levels are set up to recognize revenue. 
 */

CREATE TABLE dbo.#7KEYSTempTable_2 (
   PROJ_ID                     varchar(30)    NULL,
   LVL_NO                      smallint       NULL,
   PERIOD_REVENUE              decimal(14, 2) NULL DEFAULT 0,
   PERIOD_COST                 decimal(14, 2) NULL DEFAULT 0,
   PERIOD_PROFIT               decimal(14, 2) NULL DEFAULT 0,
-- CP600000582_Begin
   QTD_REVENUE                 decimal(14, 2) NULL DEFAULT 0,
   QTD_COST                    decimal(14, 2) NULL DEFAULT 0,
   QTD_PROFIT                  decimal(14, 2) NULL DEFAULT 0,
-- CP600000582_End
   YTD_REVENUE                 decimal(14, 2) NULL DEFAULT 0,
   YTD_COST                    decimal(14, 2) NULL DEFAULT 0,
   YTD_PROFIT                  decimal(14, 2) NULL DEFAULT 0,
   ITD_REVENUE                 decimal(14, 2) NULL DEFAULT 0,
   ITD_COST                    decimal(14, 2) NULL DEFAULT 0,
   ITD_PROFIT                  decimal(14, 2) NULL DEFAULT 0,
   ITD_VALUE                   decimal(14, 2) NULL DEFAULT 0,
   ITD_FUNDING                 decimal(14, 2) NULL DEFAULT 0,
-- Defect CP600000074 (CR1170) Begin
-- UNBILLED_REVENUE            decimal(14, 2) NULL DEFAULT 0,
-- UNBILLED_REVENUE_31TO60DAYS decimal(14, 2) NULL DEFAULT 0,
-- UNBILLED_REVENUE_61TO90DAYS decimal(14, 2) NULL DEFAULT 0,
-- UNBILLED_REVENUE_OVER90DAYS decimal(14, 2) NULL DEFAULT 0,
-- Defect CP600000074 (CR1170) End
   AGED_RECEIVABLE_31TO60DAYS  decimal(14, 2) NULL DEFAULT 0,
   AGED_RECEIVABLE_61TO90DAYS  decimal(14, 2) NULL DEFAULT 0,
   AGED_RECEIVABLE_OVER90DAYS  decimal(14, 2) NULL DEFAULT 0,
   AGED_BILL_AMT               decimal(14, 2) NULL DEFAULT 0,
   BILLED_AMT                  decimal(14, 2) NULL DEFAULT 0)

PRINT 'Populate temporary table #7KEYSTempTable_2 with only levels 1-3 data ...'

INSERT INTO dbo.#7KEYSTempTable_2
   SELECT PROJ_ID, LVL_NO,
          PERIOD_REVENUE, PERIOD_COST, PERIOD_PROFIT,
-- CP600000582_Begin
          QTD_REVENUE, QTD_COST, QTD_PROFIT,
-- CP600000582_End
          YTD_REVENUE, YTD_COST, YTD_PROFIT,
          ITD_REVENUE, ITD_COST, ITD_PROFIT, ITD_VALUE, ITD_FUNDING,
-- Defect CP600000074 (CR1170) Begin
--        UNBILLED_REVENUE, UNBILLED_REVENUE_31TO60DAYS, UNBILLED_REVENUE_61TO90DAYS, UNBILLED_REVENUE_OVER90DAYS,
-- Defect CP600000074 (CR1170) End
          AGED_RECEIVABLE_31TO60DAYS, AGED_RECEIVABLE_61TO90DAYS, AGED_RECEIVABLE_OVER90DAYS,
          AGED_BILL_AMT, BILLED_AMT
     FROM dbo.XX_7KEYS_OUT_DETAIL
    WHERE S_REV_FORMULA_CD IS NOT NULL
    ORDER BY PROJ_ID

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to insert records into temporary table #7KEYSTempTable_2 failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into temporary table #7KEYSTempTable_2'
      DROP TABLE dbo.#7KEYSTempTable_2
      GOTO BL_ERROR_HANDLER
   END

PRINT 'Update staging table XX_7KEYS_OUT_DETAIL with rolled up data for revenue-recognizing levels ...'

DECLARE cursor_one CURSOR FOR
   SELECT PROJ_ID, LVL_NO
     FROM dbo.#7KEYSTempTable_2

OPEN cursor_one
FETCH cursor_one INTO @PROJ_ID, @LVL_NO

WHILE (@@FETCH_STATUS = 0)
   BEGIN
      /*
       * In a tree-like structure, if the root level (level 1 or contract level) is set up as the revenue-recognizing level,
       * then no levels below this level can be set up to recognize revenue; if a branch level (level 2, 3, 4, etc.) is set up
       * as the revenue-recognizing level, then no levels below this level can be set up to recognize revenue. In general,
       * for a given branch level, there can only be one revenue-recognizing level.
       */
      SELECT @PERIOD_REVENUE              = SUM(PERIOD_REVENUE),
             @PERIOD_COST                 = SUM(PERIOD_COST),
             @PERIOD_PROFIT               = SUM(PERIOD_PROFIT),
-- CP600000582_Begin
             @QTD_REVENUE                 = SUM(QTD_REVENUE),
             @QTD_COST                    = SUM(QTD_COST),
             @QTD_PROFIT                  = SUM(QTD_PROFIT),
-- CP600000582_End
             @YTD_REVENUE                 = SUM(YTD_REVENUE),
             @YTD_COST                    = SUM(YTD_COST),
             @YTD_PROFIT                  = SUM(YTD_PROFIT),
             @ITD_REVENUE                 = SUM(ITD_REVENUE),
             @ITD_COST                    = SUM(ITD_COST),
             @ITD_PROFIT                  = SUM(ITD_PROFIT),
             @ITD_VALUE                   = SUM(ITD_VALUE),
             @ITD_FUNDING                 = SUM(ITD_FUNDING),
-- Defect CP600000074 (CR1170) Begin
--           @UNBILLED_REVENUE            = SUM(UNBILLED_REVENUE),
--           @UNBILLED_REVENUE_31TO60DAYS = SUM(UNBILLED_REVENUE_31TO60DAYS),
--           @UNBILLED_REVENUE_61TO90DAYS = SUM(UNBILLED_REVENUE_61TO90DAYS),
--           @UNBILLED_REVENUE_OVER90DAYS = SUM(UNBILLED_REVENUE_OVER90DAYS),
-- Defect CP600000074 (CR1170) End
             @AGED_RECEIVABLE_31TO60DAYS  = SUM(AGED_RECEIVABLE_31TO60DAYS),
             @AGED_RECEIVABLE_61TO90DAYS  = SUM(AGED_RECEIVABLE_61TO90DAYS),
             @AGED_RECEIVABLE_OVER90DAYS  = SUM(AGED_RECEIVABLE_OVER90DAYS),
             @AGED_BILL_AMT               = SUM(AGED_BILL_AMT),
             @BILLED_AMT                  = SUM(BILLED_AMT)
        FROM dbo.XX_7KEYS_OUT_DETAIL
       WHERE SUBSTRING(PROJ_ID, 1, LEN(@PROJ_ID)) = @PROJ_ID
         AND LVL_NO >= @LVL_NO
       GROUP BY SUBSTRING(PROJ_ID, 1, LEN(@PROJ_ID))

      UPDATE dbo.XX_7KEYS_OUT_DETAIL
         SET PERIOD_REVENUE              = ISNULL(@PERIOD_REVENUE, 0),
             PERIOD_COST                 = ISNULL(@PERIOD_COST, 0),
             PERIOD_PROFIT               = ISNULL(@PERIOD_PROFIT, 0),
-- CP600000582_Begin
             QTD_REVENUE                 = ISNULL(@QTD_REVENUE, 0),
             QTD_COST                    = ISNULL(@QTD_COST, 0),
             QTD_PROFIT                  = ISNULL(@QTD_PROFIT, 0),
-- CP600000582_End
             YTD_REVENUE                 = ISNULL(@YTD_REVENUE, 0),
             YTD_COST                    = ISNULL(@YTD_COST, 0),
             YTD_PROFIT                  = ISNULL(@YTD_PROFIT, 0),
             ITD_REVENUE                 = ISNULL(@ITD_REVENUE, 0),
             ITD_COST                    = ISNULL(@ITD_COST, 0),
             ITD_PROFIT                  = ISNULL(@ITD_PROFIT, 0),
             ITD_VALUE                   = ISNULL(@ITD_VALUE, 0),
             ITD_FUNDING                 = ISNULL(@ITD_FUNDING, 0),
-- Defect CP600000074 (CR1170) Begin
--           UNBILLED_REVENUE            = ISNULL(@UNBILLED_REVENUE, 0),
--           UNBILLED_REVENUE_31TO60DAYS = ISNULL(@UNBILLED_REVENUE_31TO60DAYS, 0),
--           UNBILLED_REVENUE_61TO90DAYS = ISNULL(@UNBILLED_REVENUE_61TO90DAYS, 0),
--           UNBILLED_REVENUE_OVER90DAYS = ISNULL(@UNBILLED_REVENUE_OVER90DAYS, 0),
-- Defect CP600000074 (CR1170) End
             AGED_RECEIVABLE_31TO60DAYS  = ISNULL(@AGED_RECEIVABLE_31TO60DAYS, 0),
             AGED_RECEIVABLE_61TO90DAYS  = ISNULL(@AGED_RECEIVABLE_61TO90DAYS, 0),
             AGED_RECEIVABLE_OVER90DAYS  = ISNULL(@AGED_RECEIVABLE_OVER90DAYS, 0),
             AGED_BILL_AMT               = ISNULL(@AGED_BILL_AMT, 0),
             BILLED_AMT                  = ISNULL(@BILLED_AMT, 0),
             MODIFIED_BY                 = SUSER_SNAME(),
             MODIFIED_DT                 = CURRENT_TIMESTAMP
        FROM dbo.XX_7KEYS_OUT_DETAIL
       WHERE PROJ_ID = @PROJ_ID
         AND LVL_NO = @LVL_NO

      SELECT @SQLServer_error_code = @@ERROR

      IF @SQLServer_error_code <> 0
         BEGIN
            -- Attempt to update records in table XX_7KEYS_OUT_DETAIL failed.
            SET @error_msg_placeholder1 = 'update'
            SET @error_msg_placeholder2 = 'records in table XX_7KEYS_OUT_DETAIL'
            DROP TABLE dbo.#7KEYSTempTable_2
            GOTO BL_ERROR_HANDLER
         END

      -- reset variables
      SET @PERIOD_REVENUE = 0
      SET @PERIOD_COST    = 0
      SET @PERIOD_PROFIT  = 0
-- CP600000582_Begin
      SET @QTD_REVENUE    = 0
      SET @QTD_COST       = 0
      SET @QTD_PROFIT     = 0
-- CP600000582_End
      SET @YTD_REVENUE    = 0
      SET @YTD_COST       = 0
      SET @YTD_PROFIT     = 0
      SET @ITD_REVENUE    = 0
      SET @ITD_COST       = 0
      SET @ITD_PROFIT     = 0
      SET @ITD_VALUE      = 0
      SET @ITD_FUNDING    = 0
-- Defect CP600000074 (CR1170) Begin
--    SET @UNBILLED_REVENUE = 0
--    SET @UNBILLED_REVENUE_31TO60DAYS = 0
--    SET @UNBILLED_REVENUE_61TO90DAYS = 0
--    SET @UNBILLED_REVENUE_OVER90DAYS = 0
--    SET @AGED_RECEIVABLE_31TO60DAYS  = 0
-- Defect CP600000074 (CR1170) End
      SET @AGED_RECEIVABLE_61TO90DAYS  = 0
      SET @AGED_RECEIVABLE_OVER90DAYS  = 0
      SET @AGED_BILL_AMT    = 0
      SET @BILLED_AMT       = 0

      FETCH cursor_one INTO @PROJ_ID, @LVL_NO

   END /* WHILE (@@FETCH_STATUS = 0) */

-- clean up
CLOSE cursor_one
DEALLOCATE cursor_one
DROP TABLE dbo.#7KEYSTempTable_2

RETURN(0)

BL_ERROR_HANDLER:

-- Clean up opened cursor
IF CURSOR_STATUS('local', 'cursor_one') > 0
   BEGIN
      CLOSE cursor_one
      DEALLOCATE cursor_one
   END

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

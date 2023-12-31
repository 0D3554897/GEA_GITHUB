SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_GET_PERIOD_N_SUBPERIOD_DATA]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_GET_PERIOD_N_SUBPERIOD_DATA]
GO


CREATE PROCEDURE dbo.XX_GET_PERIOD_N_SUBPERIOD_DATA
(
@in_ts_end_date         datetime,
@out_period_number      smallint OUTPUT,
@out_subperiod_number   smallint OUTPUT,
@out_subperiod_end_date datetime OUTPUT,
@out_ts_date_1          datetime OUTPUT,
@out_ts_date_2          datetime = NULL OUTPUT
)
AS

/**************************************************************************************************
Name:       XX_GET_PERIOD_N_SUBPERIOD_DATA
Author:     HVT
Created:    06/21/2005
Purpose:    Given the timesheet end date, determine the period number, the subperiod number and one
            or more time sheet end dates depending on the value of the input timesheet end date.
            Called by XX_INSERT_TS_PREPROC_RECORDS.
Parameters: 
Result Set: None
Notes:
***************************************************************************************************/

DECLARE @ts_start_date        datetime,
        @period_number        smallint,
        @subperiod_number     smallint,
        @subperiod_end_dt     datetime,
        @selected_subperiod   tinyint

/*
 * The timesheet period end date may indicate that the start of the timesheet period belongs to one month
 * and the end of the timesheet period belongs to another month. This presents the following scenario.
 * If the timesheet end date is one that belongs to the "next" accounting month/period, then determine
 * the "previous" accounting month/period. E.g., if the timesheet end date is 2000-09-02, the "next"
 * accounting month/period is September, and the "previous" accounting month/period is August.
 */

SET @ts_start_date = @in_ts_end_date - 6

IF datepart(month, @ts_start_date) < datepart(month, @in_ts_end_date)
   SET @out_period_number = datepart(month, @ts_start_date)
ELSE
   SET @out_period_number = datepart(month, @in_ts_end_date)

DECLARE cursor_test CURSOR FOR
   SELECT SUB_PD_NO, CONVERT(char(10), SUB_PD_END_DT, 120) SUB_PD_END_DT
     FROM IMAPS.deltek.SUB_PD
    WHERE FY_CD = CAST(datepart(year, @in_ts_end_date) AS CHAR(4))
      AND PD_NO = @out_period_number
 ORDER BY PD_NO, SUB_PD_NO

OPEN cursor_test
FETCH cursor_test INTO @subperiod_number, @subperiod_end_dt

WHILE (@@fetch_status = 0)
   BEGIN
      IF @subperiod_number = 1
         IF @in_ts_end_date = @subperiod_end_dt
            BEGIN
               SET @out_subperiod_number = @subperiod_number
               SET @out_subperiod_end_date = @subperiod_end_dt
            END
      IF @subperiod_number = 2
         IF @in_ts_end_date <= @subperiod_end_dt
            BEGIN
               SET @out_subperiod_number = @subperiod_number
               SET @out_subperiod_end_date = @subperiod_end_dt
            END
      IF @subperiod_number = 3
         BEGIN
            SET @out_subperiod_number = @subperiod_number
            SET @out_subperiod_end_date = @subperiod_end_dt
            IF @in_ts_end_date >= @subperiod_end_dt
               BEGIN
                  SET @out_ts_date_1 = @subperiod_end_dt
                  SET @out_ts_date_2 = @in_ts_end_date
               END
         END

      FETCH cursor_test INTO @subperiod_number, @subperiod_end_dt
   END /* WHILE (@@fetch_status = 0) */

CLOSE cursor_test
DEALLOCATE cursor_test


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


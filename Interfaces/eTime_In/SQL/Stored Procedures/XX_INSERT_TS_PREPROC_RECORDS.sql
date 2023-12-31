IF OBJECT_ID('dbo.XX_INSERT_TS_PREPROC_RECORDS') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_INSERT_TS_PREPROC_RECORDS
    IF OBJECT_ID('dbo.XX_INSERT_TS_PREPROC_RECORDS') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_INSERT_TS_PREPROC_RECORDS >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_INSERT_TS_PREPROC_RECORDS >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go





CREATE PROCEDURE [dbo].[XX_INSERT_TS_PREPROC_RECORDS]
(
@in_STATUS_RECORD_NUM      integer,
-- Defect 782 Begin
@current_month_posting_ind char(1) = NULL,
-- Defect 782 End
@in_COMPANY_ID char(1)= NULL, -- Added CR-1543
@out_STATUS_DESCRIPTION    varchar(255) = NULL OUTPUT
)
AS

/****************************************************************************************************
Name:       XX_INSERT_TS_PREPROC_RECORDS
Author:     HVT
Created:    06/21/2005
Purpose:    Using source data from temporary table XX_IMAPS_ET_IN_TMP, validate and format source
            data and insert records into temporary table XX_IMAPS_TS_PREP_TEMP to be used by bcp 
            to build a space-delimited file for the Costpoint timesheet preprocessor.
            For a given employee ID and for each input eTime timesheet record, produce a record for
            Costpoint timesheet preprocessor for each day of the timesheet period that the employee
            did work.
            If the processing encounters erroneous source input data records, insert new records
            into tables XX_IMAPS_ET_IN_ERRORS and XX_ET_DAILY_IN_ERRORS.
            See Costpoint tables deltek.TS_HDR and deltek.LN.

            Called by XX_RUN_ETIME_INTERFACE.

Parameters: 
Result Set: None

Notes:      08/18/2005: Validate only the source input file, especially its data for correct format
            as specified by Costpoint preprocessors. No re-processing of data that Costpoint 
            preprocessor rejects.

            Modified by KM on 10/21/05

            01/26/2006: Feature 415 - Add code to process new data element amendment number from the
            eT&E input source.

Defect 782  04/25/2006 Provide option to post the timesheets from another month to the current month.
            07/24/2006 Use a different local variable, @CURRENT_PD_NO, that truely holds the current
            accounting period based on the calendar.

CR-1333        ILC_ACTIVITY_CD added 12/07

Changed logic for January subperiod - January now has 3 subperiods

CR-1414     Modified for CR-1414 related changes

CR-1539     PAY_TYPE added 04/29/08
CR-1543        COMPANY_ID Logic Added 04/29/08
DR-2717        Util Miscode Logic modified 4/21/10, 5/4/10
CR-4886		Modified for Actuals Changes
CR-4886		Actuals Changes - TS_HDR_SEQ fix, SUB_PD_NO logic 10/31/2012
CR-4886     Modified for Defalt logic
****************************************************************************************************/

DECLARE @in_EMP_SERIAL_NUM      char(6),
        @in_TS_YEAR             char(4),
        @in_TS_MONTH            char(2),
        @in_TS_DAY              char(2),
        @in_PROJ_ABBR           char(6),
        @in_SAT_REG_TIME        varchar(6),
        @in_SAT_OVERTIME        varchar(6),
        @in_SUN_REG_TIME        varchar(6),
        @in_SUN_OVERTIME        varchar(6),
        @in_MON_REG_TIME        varchar(6),
        @in_MON_OVERTIME        varchar(6),
        @in_TUE_REG_TIME        varchar(6),
        @in_TUE_OVERTIME        varchar(6),
        @in_WED_REG_TIME        varchar(6),
        @in_WED_OVERTIME        varchar(6),
        @in_THU_REG_TIME        varchar(6),
        @in_THU_OVERTIME        varchar(6),
        @in_FRI_REG_TIME        varchar(6),
        @in_FRI_OVERTIME        varchar(6),
        @in_PLC                 varchar(6),
        @in_RECORD_TYPE         varchar(1),
        @in_AMENDMENT_NUM       varchar(2),
        @in_ILC_ACTIVITY_CD     varchar(6), -- Added CR-1333
        @in_PAY_TYPE            varchar(3), -- Added CR-1539
        @out_TS_DT              char(10),
        @out_EMPL_ID            char(12),
        @out_S_TS_TYPE_CD       char(2),
        @out_WORK_STATE_CD      char(2),
        @out_FY_CD              char(6),
        @out_PD_NO              char(2),
        @out_SUB_PD_NO          char(2),
        @out_CORRECTING_REF_DT  varchar(10),
        @out_PAY_TYPE           varchar(3),
        @out_LAB_CST_AMT    varchar(15),
        @out_CHG_HRS       varchar(10),
        @out_LAB_LOC_CD         varchar(6),
        @out_PROJ_ID            varchar(30),
        @out_BILL_LAB_CAT_CD    varchar(6),
        @out_PROJ_ABBRV_CD      varchar(6),
        @out_TS_HDR_SEQ_NO      varchar(3),
        @out_EFFECT_BILL_DT     varchar(10),
        @out_NOTES       varchar(254),
        @SP_NAME                sysname,
        @DAYS_IN_A_WEEK         tinyint,
        @CHAR_VALUE_NONE        char(4),
        @total_hours            decimal(14, 2),
        @str_TS_DT              char(10),
        @ts_period_start_date   datetime,
        @ts_period_end_date     datetime,
        @ts_date_for_output_1   datetime,
        @ts_date_for_output_2   datetime,
        @ts_period_day_date     datetime,
        @accounting_period      smallint,
        @subperiod_number       smallint,
        @subperiod_end_date     datetime,
        @reg_time               varchar(6),
        @overtime               varchar(6),
        @lcv                    tinyint,
        @lv_row_count           integer,
        @lv_error_code          integer,
        @lv_param_ERROR_CODE    varchar(6),
        @lv_error_msg_text      varchar(300),
        @lv_identity_val        integer,
        @ret_code               integer,
        @out_TS_HDR_SEQ_NO_int  integer,

        @LAB_GRP_TYPE varchar(3),
        @ACCT_ID varchar(15)

-- set local constants
SET @SP_NAME = 'XX_INSERT_TS_PREPROC_RECORDS'
SET @DAYS_IN_A_WEEK = 7
SET @CHAR_VALUE_NONE = 'NONE'


-- initialize local variables
SET @lv_error_msg_text = ''

IF @in_STATUS_RECORD_NUM IS NULL
   BEGIN
      SET @lv_error_code = 100 -- Missing required input parameter(s)
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = @lv_error_code,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
      RETURN(1) -- terminate execution and exit
   END

-- Added CR-1543
IF @in_COMPANY_ID IS NULL
   BEGIN
      SET @lv_error_code = 100 -- Missing required input parameter(s)
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = @lv_error_code,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
      RETURN(1) -- terminate execution and exit
   END



--CHANGE 1
--FY/Period/SubPeriod Values
--Derived from max weekending date in file for R values
DECLARE @MAX_WEEK_ENDING_DT datetime,
    @MAX_WEEK_ENDING_DT_SubPeriod int


SELECT @MAX_WEEK_ENDING_DT = MAX(CAST((TS_YEAR + '-' + TS_MONTH + '-' + TS_DAY) AS datetime))
FROM dbo.XX_IMAPS_ET_IN_TMP WHERE RECORD_TYPE = 'R'

--change KM 11/14/05
IF @MAX_WEEK_ENDING_DT IS NULL
BEGIN
-- THERE SHOULD BE AT LEAST 1 Regular Record in each batch
    EXEC dbo.XX_ERROR_MSG_DETAIL
             @in_error_code           = 204,
             @in_display_requested    = 1,
             @in_SQLServer_error_code = @lv_error_code,
             @in_placeholder_value1   = 'verify existence of at least',
             @in_placeholder_value2   = '1 regular timesheet',
             @in_calling_object_name  = @SP_NAME,
             @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
    RETURN 1
END
--end change KM 11/14/05




--CHANGE KM 
--JANUARY NOW IS LIKE ALL OTHER MONTHS
SELECT @MAX_WEEK_ENDING_DT_SubPeriod = a.SUB_PD_NO 
    FROM IMAPS.DELTEK.SUB_PD a
    WHERE a.SUB_PD_END_DT =
    (SELECT MIN(b.SUB_PD_END_DT)
     FROM  IMAPS.DELTEK.SUB_PD b
           WHERE (b.SUB_PD_NO = 2 OR
              b.SUB_PD_NO = 3) AND
           DATEDIFF(day, @MAX_WEEK_ENDING_DT, b.SUB_PD_END_DT) >= 0)
--END CHAGE KM

    

DECLARE @CurrentFY int,
    @CurrentPeriod int,
    @CurrentSubPeriod int,

    @EndDateOfSubPeriod_1 datetime,
    @EndDateOf_TS_SubPeriod datetime,

    @CORRECTING_EndDateOfSubPeriod_1 datetime,
    @CORRECTING_SubPeriod int,
    @EndDateOf_CORRECTING_TS_Subperiod datetime

SET @CurrentFY = DATEPART(year, @MAX_WEEK_ENDING_DT)
SET @CurrentPeriod = DATEPART(month, @MAX_WEEK_ENDING_DT)

SELECT @EndDateOfSubPeriod_1 = SUB_PD_END_DT
FROM IMAPS.Deltek.SUB_PD 
WHERE PD_NO=@CurrentPeriod AND
	FY_CD = @CurrentFY AND
	SUB_PD_NO = 1





--CHANGE 2 sub period values derived inside loop
--ie for each day of timesheet week
TRUNCATE TABLE dbo.XX_IMAPS_TS_PREP_TEMP
TRUNCATE TABLE dbo.XX_IMAPS_TS_PREP_ZEROS
TRUNCATE TABLE dbo.XX_ET_DAILY_IN

DECLARE cursor_one CURSOR FAST_FORWARD FOR
   SELECT * FROM dbo.XX_IMAPS_ET_IN_TMP
   --where EMP_SERIAL_NUM in ('2D7258','005459','021531','7D7218','7D7507','001918','2D1339','020563','830796')

OPEN cursor_one
FETCH cursor_one
INTO @in_EMP_SERIAL_NUM, @in_TS_YEAR, @in_TS_MONTH, @in_TS_DAY, @in_PROJ_ABBR, @in_SAT_REG_TIME, @in_SAT_OVERTIME,
@in_SUN_REG_TIME, @in_SUN_OVERTIME, @in_MON_REG_TIME, @in_MON_OVERTIME, @in_TUE_REG_TIME, @in_TUE_OVERTIME,
@in_WED_REG_TIME, @in_WED_OVERTIME, @in_THU_REG_TIME, @in_THU_OVERTIME, @in_FRI_REG_TIME, @in_FRI_OVERTIME,
@in_PLC, @in_RECORD_TYPE, @in_AMENDMENT_NUM, @in_ILC_ACTIVITY_CD, -- Added CR-1333
@in_PAY_TYPE -- Added CR-1539

WHILE (@@fetch_status = 0)
BEGIN

	--Added CR-4886 
	-- To make sure CurrentFY value is not overwritten
	 SET @CurrentFY = DATEPART(year, @MAX_WEEK_ENDING_DT)
	 SET @CurrentPeriod = DATEPART(month, @MAX_WEEK_ENDING_DT)


      SET @out_EMPL_ID = @in_EMP_SERIAL_NUM
      SET @out_FY_CD = @CurrentFY
      SET @out_PD_NO = @CurrentPeriod
      SET @out_PROJ_ABBRV_CD = substring(@in_PROJ_ABBR, 1, 4)
      SET @out_PAY_TYPE=@in_PAY_TYPE -- Added CR-1539 
     
      -- 08/26/2005: project labor category is defaulted to 'NONE' if @in_PLC does not have a value
      IF @in_PLC IS NULL
         SET @out_BILL_LAB_CAT_CD = @CHAR_VALUE_NONE
      ELSE
         IF DATALENGTH(RTRIM(@in_PLC)) = 0
            SET @out_BILL_LAB_CAT_CD = @CHAR_VALUE_NONE
         ELSE
            SET @out_BILL_LAB_CAT_CD = @in_PLC

      -- timesheet type code
      IF @in_RECORD_TYPE IS NOT NULL
         SET @out_S_TS_TYPE_CD = @in_RECORD_TYPE
      ELSE
         SET @out_S_TS_TYPE_CD = 'R' -- Regular

      -- labor cost amount
      SET @out_LAB_CST_AMT = '0'



      SET @out_WORK_STATE_CD = '' -- zero-length string


    SET @ts_period_end_date = CAST((@in_TS_YEAR + '-' + @in_TS_MONTH + '-' + @in_TS_DAY) AS datetime)
    SET @ts_period_start_date = @ts_period_end_date - 6
    
    --for correcting ref dt calculation
    SELECT @CORRECTING_EndDateOfSubPeriod_1 = SUB_PD_END_DT
        FROM IMAPS.Deltek.SUB_PD 
        WHERE PD_NO =  DATEPART(month, @ts_period_end_date) AND
        FY_CD = DATEPART(year, @ts_period_end_date) AND
        SUB_PD_NO = 1
    
    --CHANGE KM 
    --JANUARY NOW IS LIKE ALL OTHER MONTHS
    SELECT @CORRECTING_SubPeriod = a.SUB_PD_NO 
            FROM IMAPS.DELTEK.SUB_PD a
            WHERE a.SUB_PD_END_DT =
            (SELECT MIN(b.SUB_PD_END_DT)
            FROM  IMAPS.DELTEK.SUB_PD b
            WHERE (b.SUB_PD_NO = 2 OR
            b.SUB_PD_NO = 3) AND
            DATEDIFF(day,@ts_period_end_date,b.SUB_PD_END_DT) >= 0)
    --END CHANGE

    --loop for each day
    -- traverse thru the course of a timesheet period, from the first to the last day of the period
    SET @lcv = 0

    WHILE @lcv < 7
    BEGIN
        
            SET @ts_period_day_date = @ts_period_start_date + @lcv
            SET @out_ts_dt=NULL     --Added CR-4886 Tejas
            SET @out_EFFECT_BILL_DT = CONVERT(char(10), @ts_period_day_date, 120) --Added CR-4886 Tejas
            
        --CHANGE KM 
        --JANUARY NOW IS LIKE ALL OTHER MONTHS
        SELECT @CurrentSubPeriod = a.SUB_PD_NO 
        FROM IMAPS.DELTEK.SUB_PD a
        WHERE a.SUB_PD_END_DT =
        (SELECT MIN(b.SUB_PD_END_DT)
        FROM  IMAPS.DELTEK.SUB_PD b
        WHERE (b.SUB_PD_NO = 2 OR
        b.SUB_PD_NO = 3) AND
        DATEDIFF(day,@ts_period_day_date,b.SUB_PD_END_DT) >= 0)
        --END CHANGE
        
        SELECT @EndDateOf_TS_SubPeriod = SUB_PD_END_DT
        FROM IMAPS.Deltek.SUB_PD 
        -- begin change KM 12/6/05
        WHERE PD_NO =  DATEPART(month, @ts_period_day_date) AND
            FY_CD = DATEPART(year, @ts_period_day_date) AND
                SUB_PD_NO = @CurrentSubPeriod
        -- end change KM 12/6/05

        SELECT @EndDateOf_CORRECTING_TS_SubPeriod = SUB_PD_END_DT
        FROM IMAPS.Deltek.SUB_PD 
        WHERE     PD_NO =  DATEPART(month, @ts_period_day_date) AND
            FY_CD = DATEPART(year, @ts_period_day_date) AND
                SUB_PD_NO = @CurrentSubPeriod


	--Begin CR-4886 Change
		--Records after actuals date will use xx_sub_pd to figure out TS_DT, Correcting_Ref_dt
		IF @out_EFFECT_BILL_DT>=
						(SELECT  distinct parameter_value
							FROM xx_processing_parameters
							WHERE interface_name_cd='CERIS'
							AND UPPER(parameter_name)='ACTUALS_EFFECT_DT' )
		  BEGIN
			  IF @out_S_TS_TYPE_CD in ('C','N','D') -- Modified CR-1649

				BEGIN
					SELECT DISTINCT
						  -- For C, N, D pd/sub pd will be based on max wkends and not on effect_bill_dt
						  --@CurrentPeriod = a.PD_NO,	Commented 10/22/2012
						  --@CurrentSubPeriod = a.SUB_PD_NO, Commented 10/22/2012
						   @out_CORRECTING_REF_DT = CONVERT(char(10),a.sub_pd_end_dt,120),
						   @out_TS_DT = CONVERT(char(10), @MAX_WEEK_ENDING_DT, 120)
					FROM XX_SUB_PD a
					WHERE @out_EFFECT_BILL_DT>=a.SUB_PD_BEGIN_DT
						and @out_EFFECT_BILL_DT<=a.SUB_PD_END_DT

					--Added CR-4886 10/22/2012
 				    -- For C, N, D pd/sub pd will be based on max wkends and not on effect_bill_dt
					SELECT DISTINCT
						  @CurrentPeriod = a.PD_NO,
						   @CurrentSubPeriod = a.SUB_PD_NO
					FROM XX_SUB_PD a
					WHERE @MAX_WEEK_ENDING_DT>=a.SUB_PD_BEGIN_DT
						and @MAX_WEEK_ENDING_DT<=a.SUB_PD_END_DT
			   END
			  --Modified CR-4886 10/30/2012
			  -- If Friday(Work_Day)<>Max(Wkend_Friday) then derive pd/sub pd from xx_sub_pd for max wkend date
			  ELSE IF  @out_S_TS_TYPE_CD in ('R') and DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(@out_EFFECT_BILL_DT)<>@MAX_WEEK_ENDING_DT
			   BEGIN
					SELECT DISTINCT
						  @CurrentPeriod = a.PD_NO,
						   @CurrentSubPeriod = a.SUB_PD_NO
						   --@out_CORRECTING_REF_DT = NULL,
						   --@out_TS_DT = CONVERT(char(10), a.SUB_PD_END_DT, 120) 
					FROM XX_SUB_PD a
					WHERE @MAX_WEEK_ENDING_DT>=a.SUB_PD_BEGIN_DT
						and @MAX_WEEK_ENDING_DT<=a.SUB_PD_END_DT

					SELECT DISTINCT
						   @out_CORRECTING_REF_DT = NULL,
						   @out_TS_DT = CONVERT(char(10), a.SUB_PD_END_DT, 120) 
					FROM XX_SUB_PD a
					WHERE @out_EFFECT_BILL_DT>=a.SUB_PD_BEGIN_DT
						and @out_EFFECT_BILL_DT<=a.SUB_PD_END_DT

			   END
			  --Modified CR-4886 10/30/2012
			  -- If Friday(Work_Day)=Max(Wkend_Friday) then derive pd/sub pd from xx_sub_pd
			  ELSE IF  @out_S_TS_TYPE_CD in ('R') and DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(@out_EFFECT_BILL_DT)=@MAX_WEEK_ENDING_DT
			   BEGIN
					SELECT DISTINCT
						  @CurrentPeriod = a.PD_NO,
						  @CurrentSubPeriod = a.SUB_PD_NO,
						   @out_CORRECTING_REF_DT = NULL,
						   @out_TS_DT = CONVERT(char(10), a.SUB_PD_END_DT, 120) 
					FROM XX_SUB_PD a
					WHERE @out_EFFECT_BILL_DT>=a.SUB_PD_BEGIN_DT
						and @out_EFFECT_BILL_DT<=a.SUB_PD_END_DT
			   END
			   SET @out_SUB_PD_NO = @CurrentSubPeriod
		  END

	--END CR-4886 Change

	--Use Old Logic for prior TS
		--IF Added, CR-4886
		IF @out_EFFECT_BILL_DT<
						(SELECT  parameter_value
							FROM xx_processing_parameters
							WHERE interface_name_cd='CERIS'
							AND UPPER(parameter_name)='ACTUALS_EFFECT_DT')
		  BEGIN
				--TS_DT/SubPeriod/Correcting Reference Date calculation
				--If correcting timesheet
			IF @out_S_TS_TYPE_CD = 'C'
	 			BEGIN
					SET @out_SUB_PD_NO = @MAX_WEEK_ENDING_DT_SubPeriod
					SET @out_TS_DT = CONVERT(char(10), @MAX_WEEK_ENDING_DT, 120)
					
					IF(DATEDIFF(month, @ts_period_end_date, @ts_period_day_date) < 0)
						BEGIN
							SET @out_CORRECTING_REF_DT = CONVERT(char(10), @CORRECTING_EndDateOfSubPeriod_1 - 1, 120)
						END
					ELSE IF(@CORRECTING_SubPeriod <> @CurrentSubPeriod)
						BEGIN   --CHANGE KM 11/11/05
							SET @out_CORRECTING_REF_DT = CONVERT(char(10), @EndDateOf_CORRECTING_TS_SubPeriod, 120)
						END
					ELSE
						BEGIN
							SET @out_CORRECTING_REF_DT = CONVERT(char(10), @ts_period_end_date, 120)
						END
					
				END

			ELSE IF (DATEDIFF(month,@MAX_WEEK_ENDING_DT,@EndDateOf_TS_SubPeriod) < 0)
				BEGIN
					SET @out_SUB_PD_NO = '1'
					--SET @out_TS_DT = CONVERT(char(10), @ts_period_end_date, 120)
					SET @out_TS_DT = CONVERT(char(10), @EndDateOfSubPeriod_1 - 1, 120)
					SET @out_CORRECTING_REF_DT = NULL			
				END
				-- else if SubPeriod should be Previous
			ELSE IF @CurrentSubPeriod <> @MAX_WEEK_ENDING_DT_SubPeriod
				BEGIN
					SET @out_SUB_PD_NO = @CurrentSubPeriod
					SET @out_TS_DT = CONVERT(char(10), @EndDateOf_TS_SubPeriod, 120)
					SET @out_CORRECTING_REF_DT = NULL
					
				END
				-- else everything is based off MAX_WEEK_ENDING_DT
				ELSE
				BEGIN
					SET @out_SUB_PD_NO = @MAX_WEEK_ENDING_DT_SubPeriod
					SET @out_TS_DT = CONVERT(char(10), @MAX_WEEK_ENDING_DT, 120)
					SET @out_CORRECTING_REF_DT = NULL
					
				END
		  END

-- BEGIN CONTINUED CHANGE TS_HDR_SEQ_NO 01/01/06
    
        -- HDR_SEQ_NO CALCULATION
        -- for correcting timesheets 
        -- distinct headers are not automatically created by preprocessor
        -- to ensure 1 header for each correcting reference date
        -- we must make use of the TS_HDR_SEQ_NO field

        -- 09/07/2006
        -- NEED TO GROUP TIMESHEETS BY PROJECT IN ORDER TO
        -- ISOLATE CROSS-CHARGING ERRORS
        IF @out_S_TS_TYPE_CD  in ('C' , 'N' ,'D') --Modified CR-4886
        BEGIN
            -- CHANGE KM 1/5/06
            -- needed in order to make NULL comparisons
            set @out_TS_HDR_SEQ_NO_int = NULL
            
            -- find out if header will already be created
            -- by previous line item
            select     @out_TS_HDR_SEQ_NO_int = CAST(TS_HDR_SEQ_NO AS int)
            from     dbo.XX_IMAPS_TS_PREP_TEMP
            where     EMPL_ID = @out_EMPL_ID AND
                TS_DT    = @out_TS_DT   AND
                S_TS_TYPE_CD = @out_S_TS_TYPE_CD AND
                --PROJ_ABBRV_CD = @out_PROJ_ABBRV_CD AND    --Modified CR-4886
                CORRECTING_REF_DT = @out_CORRECTING_REF_DT
            
            -- if not, find previous HDR_SEQ_NO
            -- and increment
            if @out_TS_HDR_SEQ_NO_int IS NULL
            BEGIN
                select     @out_TS_HDR_SEQ_NO_int = MAX(CAST(TS_HDR_SEQ_NO AS int)) 
                from     dbo.XX_IMAPS_TS_PREP_TEMP
                where     EMPL_ID = @out_EMPL_ID AND
                    TS_DT    = @out_TS_DT   AND
                    S_TS_TYPE_CD = @out_S_TS_TYPE_CD AND
                    (
                    CORRECTING_REF_DT <> @out_CORRECTING_REF_DT
                    OR PROJ_ABBRV_CD <> @out_PROJ_ABBRV_CD
                    )
                
                -- if HDR_SEQ_NO not found, assign 1
                -- else, increment HDR_SEQ_NO
                if @out_TS_HDR_SEQ_NO_int IS NULL
                    set @out_TS_HDR_SEQ_NO_int = 1
                else
                    set @out_TS_HDR_SEQ_NO_int = @out_TS_HDR_SEQ_NO_int + 1
            END
        END
        
        -- BEGIN CHANGE KM 09/07/2006
        -- NEED TO GROUP TIMESHEETS BY PROJECT IN ORDER TO
        -- ISOLATE CROSS-CHARGING ERRORS
        -- MAX TS_HDR_SEQ_NO for R type timesheets is still 9!!!!!
        ELSE IF @out_S_TS_TYPE_CD = 'R'
        BEGIN
            set @out_TS_HDR_SEQ_NO_int = 1
        END
        
        SET @out_TS_HDR_SEQ_NO = CAST(@out_TS_HDR_SEQ_NO_int as varchar(3))
-- END CHANGE KM TS_HDR_SEQ_NO




            IF @lcv = 0 -- Saturday
               BEGIN
                  SET @reg_time = @in_SAT_REG_TIME
                  SET @overtime = @in_SAT_OVERTIME
               END
            ELSE IF @lcv = 1 -- Sunday
   BEGIN
         SET @reg_time = @in_SUN_REG_TIME
                  SET @overtime = @in_SUN_OVERTIME
               END
        ELSE IF @lcv = 2 -- Monday
               BEGIN
                  SET @reg_time = @in_MON_REG_TIME
                  SET @overtime = @in_MON_OVERTIME
               END
          ELSE IF @lcv = 3 -- Tuesday
               BEGIN
                  SET @reg_time = @in_TUE_REG_TIME
                  SET @overtime = @in_TUE_OVERTIME
               END
  ELSE IF @lcv = 4 -- Wednesday
               BEGIN
                  SET @reg_time = @in_WED_REG_TIME
                  SET @overtime = @in_WED_OVERTIME
               END
            ELSE IF @lcv = 5 -- Thursday
               BEGIN
                  SET @reg_time = @in_THU_REG_TIME
      SET @overtime = @in_THU_OVERTIME
   END
       ELSE IF @lcv = 6 -- Friday
               BEGIN
                  SET @reg_time = @in_FRI_REG_TIME
                  SET @overtime = @in_FRI_OVERTIME
               END

            -- get total hours charged for a given timesheet day
            SET @total_hours = CONVERT(decimal(14, 2), @reg_time)
            SET @total_hours = @total_hours + CONVERT(decimal(14, 2), @overtime)
            SET @out_CHG_HRS = CONVERT(varchar(10), @total_hours)

            SET @out_LAB_LOC_CD = @CHAR_VALUE_NONE -- 08/26/2005

            -- effective billing date takes the date value of the timesheet day
            SET @out_EFFECT_BILL_DT = CONVERT(char(10), @ts_period_day_date, 120)

            /*
             * Add one new XX_ET_DAILY_IN record for each day of the timesheet period.
             * PK column ET_DAILY_IN_RECORD_NUM is an IDENTITY column.
         * 
             */
            INSERT INTO dbo.XX_ET_DAILY_IN
               (STATUS_RECORD_NUM, EMP_SERIAL_NUM, TS_YEAR, TS_MONTH, TS_DAY,
                TS_DATE, TS_WEEK_END_DATE, PROJ_ABBR, REG_TIME, OVERTIME,
                PLC, RECORD_TYPE, AMENDMENT_NUM, ILC_ACTIVITY_CD, PAY_TYPE, -- Added CR-1539
                CREATED_BY, CREATED_DATE)
               VALUES(@in_STATUS_RECORD_NUM, @in_EMP_SERIAL_NUM, @in_TS_YEAR, @in_TS_MONTH, @in_TS_DAY,
                      @ts_period_day_date, @ts_period_end_date, @out_PROJ_ABBRV_CD, @reg_time, @overtime,
                      @out_BILL_LAB_CAT_CD, @out_S_TS_TYPE_CD, @in_AMENDMENT_NUM,@in_ILC_ACTIVITY_CD, @in_PAY_TYPE, -- Added CR-1539
                      SUSER_SNAME(), GETDATE())

            SET @lv_error_code = @@ERROR

            IF @lv_error_code <> 0
               BEGIN
                  -- Attempt to insert a XX_ET_DAILY_IN record failed.
                  EXEC dbo.XX_ERROR_MSG_DETAIL
                     @in_error_code           = 204,
                     @in_display_requested    = 1,
                     @in_SQLServer_error_code = @lv_error_code,
                     @in_placeholder_value1   = 'insert',
                     @in_placeholder_value2   = 'a XX_ET_DAILY_IN record',
                     @in_calling_object_name  = @SP_NAME,
                     @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

                  CLOSE cursor_one
                  DEALLOCATE cursor_one
                  RETURN(1) -- exit this sp
               END

            /*
             * 08/17/2005: To aid error investigation, set @out_NOTES to a value that is composed of two other values
             * using the format M-N where M is the "Batch Number" (XX_IMAPS_INT_STATUS.STATUS_RECORD_NUM) and N is
             * the value of the PK column XX_ET_DAILY_IN.ET_DAILY_IN_RECORD_NUM just inserted above.
         */

            -- retrieve the last-generated identity value assigned to the IDENTITY column for the INSERT above
            SET @lv_identity_val = IDENT_CURRENT('dbo.XX_ET_DAILY_IN')

            SET @out_NOTES = CONVERT(varchar(10), @in_STATUS_RECORD_NUM) + '-' + CONVERT(varchar(10), @lv_identity_val)+ '-' +'ACTVT_CD'+COALESCE(@in_ILC_ACTIVITY_CD,NULL,SPACE(6))+'-'+rtrim(@out_S_TS_TYPE_CD)
            -- ACTVT_CD Added CR-1333
            -- S_TS_TYPE_CD Added CR-4886
      -- add one new XX_IMAPS_TS_PREP_TEMP record for each day of the timesheet period
        IF (CAST(@out_CHG_HRS as decimal(14,2)) <> .00)
        BEGIN

           INSERT INTO dbo.XX_IMAPS_TS_PREP_TEMP
                       (TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
                        SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, LAB_CST_AMT, CHG_HRS,
                        LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
                        EFFECT_BILL_DT, NOTES)
                       VALUES(@out_TS_DT, @out_EMPL_ID, @out_S_TS_TYPE_CD, @out_WORK_STATE_CD, @out_FY_CD, @out_PD_NO,
  @out_SUB_PD_NO, @out_CORRECTING_REF_DT, @out_PAY_TYPE, @out_LAB_CST_AMT, @out_CHG_HRS,
                              @out_LAB_LOC_CD, @out_PROJ_ID, @out_BILL_LAB_CAT_CD, @out_PROJ_ABBRV_CD, @out_TS_HDR_SEQ_NO,
                              @out_EFFECT_BILL_DT, @out_NOTES)                    
        END
        ELSE
        BEGIN
            INSERT INTO dbo.XX_IMAPS_TS_PREP_ZEROS
              (TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
                    SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, LAB_CST_AMT, CHG_HRS,
                    LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
                    EFFECT_BILL_DT, NOTES)
                   VALUES(@out_TS_DT, @out_EMPL_ID, @out_S_TS_TYPE_CD, @out_WORK_STATE_CD, @out_FY_CD, @out_PD_NO,
                          @out_SUB_PD_NO, @out_CORRECTING_REF_DT, @out_PAY_TYPE, @out_LAB_CST_AMT, @out_CHG_HRS,
                          @out_LAB_LOC_CD, @out_PROJ_ID, @out_BILL_LAB_CAT_CD, @out_PROJ_ABBRV_CD, @out_TS_HDR_SEQ_NO,
                          @out_EFFECT_BILL_DT, @out_NOTES)
        END

            SET @lv_error_code = @@ERROR

            IF @lv_error_code <> 0
               BEGIN
          -- Attempt to insert a XX_IMAPS_TS_PREP_TEMP record failed.
                  EXEC dbo.XX_ERROR_MSG_DETAIL
                     @in_error_code           = 204,
                     @in_display_requested    = 1,
                     @in_SQLServer_error_code = @lv_error_code,
                     @in_placeholder_value1   = 'insert',
                     @in_placeholder_value2   = 'a XX_IMAPS_TS_PREP_TEMP record',
                     @in_calling_object_name  = @SP_NAME,
                     @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

                  CLOSE cursor_one
                  DEALLOCATE cursor_one
                  RETURN(1) -- exit this sp
               END

            SET @lcv = @lcv + 1
    END -- end while loop




FETCH cursor_one
INTO @in_EMP_SERIAL_NUM, @in_TS_YEAR, @in_TS_MONTH, @in_TS_DAY, @in_PROJ_ABBR, @in_SAT_REG_TIME, @in_SAT_OVERTIME,
@in_SUN_REG_TIME, @in_SUN_OVERTIME, @in_MON_REG_TIME, @in_MON_OVERTIME, @in_TUE_REG_TIME, @in_TUE_OVERTIME,
@in_WED_REG_TIME, @in_WED_OVERTIME, @in_THU_REG_TIME, @in_THU_OVERTIME, @in_FRI_REG_TIME, @in_FRI_OVERTIME,
@in_PLC, @in_RECORD_TYPE, @in_AMENDMENT_NUM, @in_ILC_ACTIVITY_CD, -- Added CR-1333
@in_PAY_TYPE -- Added CR-1539

END -- end while loop

CLOSE cursor_one
DEALLOCATE cursor_one


SET @lv_error_code = @@ERROR

IF @lv_error_code <> 0
BEGIN
  -- Attempt to insert a XX_IMAPS_TS_PREP_TEMP record failed.
  EXEC dbo.XX_ERROR_MSG_DETAIL
     @in_error_code           = 204,
     @in_display_requested    = 1,
     @in_SQLServer_error_code = @lv_error_code,
     @in_placeholder_value1   = 'update',
     @in_placeholder_value2   = 'IMAPS.DELTEK.DFLT_REG_TS',
     @in_calling_object_name  = @SP_NAME,
     @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
  RETURN(1) -- exit this sp
END


/* Temporary Comment begin -- 07/25/2012 DR-4886
--begin change KM 02/27/05
UPDATE     IMAPS.DELTEK.DFLT_REG_TS
SET     GENL_LAB_CAT_CD = empl_lab.GENL_LAB_CAT_CD,
         CHG_ORG_ID = empl_lab.ORG_ID
FROM     IMAPS.DELTEK.DFLT_REG_TS as dflt_reg
INNER JOIN 
    IMAPS.DELTEK.EMPL_LAB_INFO AS empl_lab
ON     (
    dflt_reg.EMPL_ID = empl_lab.EMPL_ID
AND    empl_lab.EFFECT_DT <= @MAX_WEEK_ENDING_DT
AND    empl_lab.END_DT >= @MAX_WEEK_ENDING_DT
AND    (empl_lab.GENL_LAB_CAT_CD <> dflt_reg.GENL_LAB_CAT_CD
    OR empl_lab.ORG_ID <> dflt_reg.CHG_ORG_ID)
)
--end change KM 02/27/05
Temporary comments end*/

-- Defect 782 Begin

IF @current_month_posting_ind IS NOT NULL AND @current_month_posting_ind = 'Y'
   BEGIN
 DECLARE @CURRENT_PD_NO integer
      SET @CURRENT_PD_NO = DATEPART(month, GETDATE())

  --BEGIN SUB_PD CHANGE KM
      UPDATE dbo.XX_IMAPS_TS_PREP_TEMP
         SET PD_NO = @CURRENT_PD_NO,
            SUB_PD_NO = 1
      WHERE  S_TS_TYPE_CD = 'R'

      UPDATE dbo.XX_IMAPS_TS_PREP_TEMP
         SET PD_NO = @CURRENT_PD_NO,
             SUB_PD_NO = 2
      WHERE  S_TS_TYPE_CD in ( 'C','N','D') --Modified CR-4886
      --END SUB_PD CHANGE KM

      SET @lv_error_code = @@ERROR

      IF @lv_error_code <> 0
         BEGIN
            -- Attempt to insert a XX_IMAPS_TS_PREP_TEMP record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
               @in_SQLServer_error_code = @lv_error_code,
               @in_placeholder_value1   = 'update',
      @in_placeholder_value2   = 'IMAPS.DELTEK.DFLT_REG_TS',
               @in_calling_object_name  = @SP_NAME,
               @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END
   END

-- Defect 782 End


--CHANGE KM 09/08/06
--DO NOT TRY TO PROCESS CROSS-CHARGING TIMESHEETS
--SAVE THEM IN A SEPARATE TABLE FOR FUTURE PROCESSING
--CHANGE KM 09/08/06

--IDENTIFY
UPDATE dbo.XX_IMAPS_TS_PREP_TEMP
SET ACCT_ID = lab_acct.ACCT_ID,
GENL_LAB_CAT_CD = empl_lab.GENL_LAB_CAT_CD
FROM dbo.XX_IMAPS_TS_PREP_TEMP ts
INNER JOIN IMAPS.DELTEK.EMPL_LAB_INFO empl_lab
on
(ts.empl_id = empl_lab.empl_id
 and 
   (
        (ts.S_TS_TYPE_CD = 'R' AND cast(ts.TS_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
        OR
        (ts.S_TS_TYPE_CD in ('C','N','D') AND cast(ts.CORRECTING_REF_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
        --Modified CR-4886
    )
)
INNER JOIN IMAPS.DELTEK.PROJ proj
on
(ts.PROJ_ABBRV_CD = proj.PROJ_ABBRV_CD
AND proj.COMPANY_ID=@in_COMPANY_ID)     --Added CR-1543
INNER JOIN IMAPS.DELTEK.LAB_ACCT_GRP_DFLT lab_acct
ON
(
empl_lab.LAB_GRP_TYPE = lab_acct.LAB_GRP_TYPE
AND proj.ACCT_GRP_CD = lab_acct.ACCT_GRP_CD
AND lab_acct.COMPANY_ID=@in_COMPANY_ID     --Added CR-1543
)

--ISOLATE
UPDATE dbo.XX_IMAPS_TS_PREP_TEMP
SET NOTES = RTRIM(NOTES) + '-CROSS_CHARGING-'
WHERE ACCT_ID IS NULL

/* No Longer needed, we have to miscode entire TC is one line fails
--CORRECTING TIMESHEETS ARE ALREADY ISOLATED BY PROJECT
--REGULAR TIMESHEETS CANNOT BE ISOLATED MORE THAN 9 (TS_HDR_SEQ_NO)
--SO TO ISOLATE REGULAR TIMESHEETS, CHANGE TS_HDR_SEQ_NO
UPDATE dbo.XX_IMAPS_TS_PREP_TEMP
SET TS_HDR_SEQ_NO = '2'
WHERE S_TS_TYPE_CD = 'R'
AND ACCT_ID IS NULL
*/
--MAKE NULL AGAIN, SO PREPROCESSOR CAN DEFAULT THE VALUES 
--IN CASE THINGS HAVE CHANGED
UPDATE dbo.XX_IMAPS_TS_PREP_TEMP
SET ACCT_ID = NULL

  SET @lv_error_code = @@ERROR

      IF @lv_error_code <> 0
         BEGIN
            -- Attempt to insert a XX_IMAPS_TS_PREP_TEMP record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
               @in_SQLServer_error_code = @lv_error_code,
               @in_placeholder_value1   = 'insert',
               @in_placeholder_value2   = 'XX_IMAPS_TS_PREP_CROSS_CHARGING_ERRORS',
               @in_calling_object_name  = @SP_NAME,
               @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END

--Begin DR-922 4/17/07
EXEC @lv_error_code = XX_ETIME_SIMULATE_COSTPOINT_SP
    @in_COMPANY_ID=@in_COMPANY_ID            -- Added CR-1543
    
--End DR-922 4/17/07


 IF @lv_error_code <> 0
         BEGIN
            -- Attempt to insert a XX_IMAPS_TS_PREP_TEMP record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
   @in_SQLServer_error_code = @lv_error_code,
               @in_placeholder_value1   = 'insert',
               @in_placeholder_value2   = 'XX_IMAPS_TS_PREP_CROSS_CHARGING_ERRORS',
               @in_calling_object_name  = @SP_NAME,
               @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
        RETURN(1)
         END

--Begin CR-4886 Change
    --Added 12/13/2012 
    --Convert 'DEF99?' to miscode the records, we do not want any labor to be processed if GLC is DEAFLT
    UPDATE dbo.XX_IMAPS_TS_PREP_TEMP
    SET GENL_LAB_CAT_CD='DEF99?'
    WHERE GENL_LAB_CAT_CD='DEFALT'
    --End 12/13/2012

    UPDATE dbo.XX_IMAPS_TS_PREP_TEMP
    SET lab_cst_amt=0
    WHERE effect_bill_dt>(select parameter_value
                            from xx_processing_parameters
                            where interface_name_cd='CERIS'
                            and UPPER(parameter_name)='ACTUALS_EFFECT_DT') 

    EXEC @lv_error_code = XX_ETIME_SIMULATE_TSHDRSEQ_SP

    IF @lv_error_code <> 0
         BEGIN
            -- Attempt to insert a XX_IMAPS_TS_PREP_TEMP record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
               @in_SQLServer_error_code = @lv_error_code,
			   @in_placeholder_value1   = 'insert',
               @in_placeholder_value2   = 'XX_R22_IMAPS_TS_PREP SIMULATE HDR SEQ ERRORS',
               @in_calling_object_name  = @SP_NAME,
           @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END

    -- Call procedure to reclass OT for non-exempt 
    EXEC @lv_error_code = XX_INSERT_TS_RECLASS_SP 

    IF @lv_error_code <> 0
         BEGIN
            -- Attempt to insert a XX_IMAPS_TS_PREP_TEMP record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
			   @in_SQLServer_error_code = @lv_error_code,
               @in_placeholder_value1   = 'insert',
               @in_placeholder_value2   = 'XX_IMAPS_TS_PREP_TEMP Reclass process',
               @in_calling_object_name  = @SP_NAME,
               @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END

--End CR-4886 Change



--Begin CR-1414 01/31/2008
--Copy data to XX_IMAPS_TS_UTIL_DATA for Utilization processing
-- This is the same data that was sent to Preprocessor
INSERT INTO dbo.XX_IMAPS_TS_UTIL_DATA
(   STATUS_RECORD_NUM,    TS_DT,  EMPL_ID,    S_TS_TYPE_CD,    WORK_STATE_CD,    FY_CD,    PD_NO,
    SUB_PD_NO,    CORRECTING_REF_DT,    PAY_TYPE ,    GENL_LAB_CAT_CD,    S_TS_LN_TYPE_CD,    LAB_CST_AMT,
    CHG_HRS,    WORK_COMP_CD,    LAB_LOC_CD,    ORG_ID,    ACCT_ID,    PROJ_ID,    BILL_LAB_CAT_CD,    REF_STRUC_1_ID,
    REF_STRUC_2_ID,    ORG_ABBRV_CD,    PROJ_ABBRV_CD,    TS_HDR_SEQ_NO,    EFFECT_BILL_DT,    PROJ_ACCT_ABBRV_CD,    NOTES,
    TIME_STAMP,     CP_PROCESS_DATE,     CP_TS_LN_KEY )
SELECT 
    --TS_LN_KEY,
    @in_STATUS_RECORD_NUM,    TS_DT,    EMPL_ID,    S_TS_TYPE_CD,    WORK_STATE_CD,    FY_CD,    PD_NO,
    SUB_PD_NO,    CORRECTING_REF_DT,    PAY_TYPE ,    GENL_LAB_CAT_CD,    S_TS_LN_TYPE_CD,    LAB_CST_AMT,
    CHG_HRS,    WORK_COMP_CD,    LAB_LOC_CD,    ORG_ID,    ACCT_ID,    PROJ_ID,    BILL_LAB_CAT_CD,    REF_STRUC_1_ID,
    REF_STRUC_2_ID,    ORG_ABBRV_CD,    PROJ_ABBRV_CD,    TS_HDR_SEQ_NO,    EFFECT_BILL_DT,    PROJ_ACCT_ABBRV_CD,    NOTES,
     convert(char, getdate(), 101) TIME_STAMP,    NULL CP_PROCESS_DATE,    NULL CP_TS_LN_KEY 
FROM  dbo.XX_IMAPS_TS_PREP_TEMP 

      SET @lv_error_code = @@ERROR

      IF @lv_error_code <> 0
         BEGIN
            -- Attempt to insert a XX_IMAPS_TS_UTIL_DATA record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
               @in_SQLServer_error_code = @lv_error_code,
               @in_placeholder_value1   = 'Insert',
               @in_placeholder_value2   = 'XX_IMAPS_TS_UTIL_DATA',
               @in_calling_object_name  = @SP_NAME,
               @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END

    update dbo.xx_imaps_ts_util_data
    set proj_id=b.PROJ_ID
    FROM dbo.xx_imaps_ts_util_data a
    Inner join    IMAPS.DELTEK.PROJ b
    ON a.PROJ_ABBRV_CD = b.PROJ_ABBRV_CD
    where a.PROJ_ID is null 
    and util_process_date is null --Added DR-2717

   UPDATE XX_IMAPS_TS_UTIL_DATA
    SET
    GENL_LAB_CAT_CD = ELI.GENL_LAB_CAT_CD,
    ORG_ID = ELI.ORG_ID
    --select distinct ts.empl_id, ts.org_id, eli.org_id
    FROM
    XX_IMAPS_TS_UTIL_DATA TS
    INNER JOIN
    IMAPS.DELTEK.EMPL_LAB_INFO ELI
    ON
    (
    ELI.EMPL_ID = TS.EMPL_ID
    AND
     (
        ( TS.S_TS_TYPE_CD = 'R'
          AND
          TS.TS_DT BETWEEN ELI.EFFECT_DT AND ELI.END_DT    )
        OR
        ( TS.S_TS_TYPE_CD in ( 'C','N','D') --Modified CR-4886
          AND
          TS.CORRECTING_REF_DT BETWEEN ELI.EFFECT_DT AND ELI.END_DT)
     )
    )
    --WHERE TS.TIME_STAMP=convert(char, getdate(), 101)
    --Modified DR-2717, Update all unprocessed records for year-1
    WHERE ts.util_process_date is null
        and datepart(year,TS.TIME_STAMP)>= datepart(year,getdate())-1

    --Added DR-2717
    --Update Accounts
    UPDATE XX_IMAPS_TS_UTIL_DATA
    SET ACCT_ID = LAGD.ACCT_ID
    --SELECT EMPL_ID, TS.ACCT_ID, LAGD.ACCT_ID 
    FROM XX_IMAPS_TS_UTIL_DATA TS
    INNER JOIN
    IMAPS.DELTEK.LAB_ACCT_GRP_DFLT LAGD
    ON
    ( 
     LAGD.LAB_GRP_TYPE = SUBSTRING(TS.ORG_ID, 10, 2)
     AND
     LAGD.COMPANY_ID=1 -- Modified for CR-1543, DR-2717
     AND
     LAGD.ACCT_GRP_CD = (SELECT ACCT_GRP_CD FROM IMAPS.DELTEK.PROJ WHERE PROJ_ABBRV_CD = TS.PROJ_ABBRV_CD) -- Modified for CR-1543, DR-2717
    )
    WHERE ts.util_process_date is null
    and datepart(year,TS.TIME_STAMP)>= datepart(year,getdate())-1

      
      SET @lv_error_code = @@ERROR

      IF @lv_error_code <> 0
         BEGIN
            -- Update to XX_IMAPS_TS_UTIL_DATA record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
               @in_SQLServer_error_code = @lv_error_code,
               @in_placeholder_value1   = 'update',
               @in_placeholder_value2   = 'XX_IMAPS_TS_UTIL_DATA',
               @in_calling_object_name  = @SP_NAME,
               @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END


--End CT-1414 01/31/2008

/*
    -- Begin CR-1539 5/1/2008
    --5 Miscode records with Standby pay_types and ACCT_ID is not found in map table
    
    INSERT INTO dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS
    (STATUS_RECORD_NUM_CREATED, TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
    SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, LAB_CST_AMT, CHG_HRS, ACCT_ID,ORG_ID,GENL_LAB_CAT_CD,
    LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
    EFFECT_BILL_DT, NOTES)
    SELECT 
    @in_STATUS_RECORD_NUM,
    TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
    SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, LAB_CST_AMT, CHG_HRS, ACCT_ID,ORG_ID, GENL_LAB_CAT_CD,
    LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
    EFFECT_BILL_DT, NOTES
    FROM dbo.XX_IMAPS_TS_PREP_TEMP
    WHERE RTRIM(PAY_TYPE)<>''
    and (ACCT_ID not in (SELECT DISTINCT ACCT_ID_SB from XX_ET_STB_ACCOUNT_MAP) 
            or RTRIM(ACCT_ID)='')     
            -- if ACCT_ID is not in Standby Acct list then miscode
            -- If Acct_id is NULL then miscode

      SET @lv_error_code = @@ERROR

      IF @lv_error_code <> 0
         BEGIN
            -- Update to XX_IMAPS_TS_UTIL_DATA record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
               @in_SQLServer_error_code = @lv_error_code,
               @in_placeholder_value1   = 'Insert',
               @in_placeholder_value2   = 'XX_IMAPS_TS_PREP_CONFIG_ERRORS',
               @in_calling_object_name  = @SP_NAME,
               @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END


    --6 Delete miscoded records so they can be processed next time
    DELETE
    FROM dbo.XX_IMAPS_TS_PREP_TEMP
    WHERE RTRIM(PAY_TYPE)<>''
    and (ACCT_ID not in (SELECT DISTINCT ACCT_ID_SB from XX_ET_STB_ACCOUNT_MAP) 
        or RTRIM(ACCT_ID)='')     
            -- if ACCT_ID is not in Standby Acct list then miscode
            -- If Acct_id is NULL then miscode     
    -- END CR-1539  5/1/2008
*/
      SET @lv_error_code = @@ERROR

      IF @lv_error_code <> 0
         BEGIN
            -- Update to XX_IMAPS_TS_UTIL_DATA record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
			   @in_SQLServer_error_code = @lv_error_code,
               @in_placeholder_value1   = 'Delete',
			   @in_placeholder_value2   = 'XX_IMAPS_TS_PREP_CONFIG_ERRORS',
               @in_calling_object_name  = @SP_NAME,
               @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END





RETURN(0)






go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_INSERT_TS_PREPROC_RECORDS') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_INSERT_TS_PREPROC_RECORDS >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_INSERT_TS_PREPROC_RECORDS >>>'
go

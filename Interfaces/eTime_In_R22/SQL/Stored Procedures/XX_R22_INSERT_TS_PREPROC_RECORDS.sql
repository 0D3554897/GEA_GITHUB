use imapsstg

IF OBJECT_ID('dbo.XX_R22_INSERT_TS_PREPROC_RECORDS') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_INSERT_TS_PREPROC_RECORDS
    IF OBJECT_ID('dbo.XX_R22_INSERT_TS_PREPROC_RECORDS') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_INSERT_TS_PREPROC_RECORDS >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_INSERT_TS_PREPROC_RECORDS >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go

CREATE PROCEDURE [dbo].[XX_R22_INSERT_TS_PREPROC_RECORDS]
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

CR-1333		ILC_ACTIVITY_CD added 12/07

Changed logic for January subperiod - January now has 3 subperiods

CR-1414     Modified for CR-1414 related changes

CR-1539 	PAY_TYPE added 04/29/08
CR-1543		COMPANY_ID Logic Added 04/29/08

CR-1649		Modified for Etime Research Div. 22 Development 8/1/08
CR-1649		Modified for Etime Research Div. 22 Development 10/25/08 Split week TS_DT issue
CR-1821     Modified for Account Reclass Map 
CR-1901     Modified for MTC to process as R Type (CR-1863, DR-1875)
CR-1921	    Modified for N,D TS HDR SEQ issue, Split Backout line, Split logic
CR-1926	    Modified for PD, SubPD issue 4/19/09
CR-2230     Modified for Split Backout line issue 9/1/09
CR-2419     Modified for ts_hdr_seq updates
DR-2414     modified for Dup. BO Line Issue - Modified Correcting Ref DT for Reg Lines
DR-2809     Modified for Changing the TS_DT, Cor Ref DT Split logic change 09/20/10

2014-02-20  CP7 changes
			DELTEK.USER_ID table replaced by DELTEK.W_USER_UGRP_LIST
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
        @in_PAY_TYPE			varchar(3), -- Added CR-1539
		@out_TS_DT              char(10),
        @out_EMPL_ID            char(12),
        @out_S_TS_TYPE_CD       char(2),
        @out_WORK_STATE_CD      char(2),
        @out_FY_CD              char(6),
  @out_PD_NO              char(2),
        @out_SUB_PD_NO  char(2),
        @out_CORRECTING_REF_DT  varchar(10),
        @out_PAY_TYPE           varchar(3),
        @out_LAB_CST_AMT	varchar(15),
        @out_CHG_HRS            varchar(10),
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
        @CHAR_VALUE_RONE        char(4),
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
        @ACCT_ID varchar(15),
        
		-- Added CR-1649
        --Encryption related params for R22
        @CERIS_PASSKEY_VALUE        varchar(128),
        @CERIS_KEYNAME        varchar(50),
        @CERIS_PASSKEY_VALUE_PARAM  varchar(30),
        @CERIS_KEYNAME_PARAM  varchar(30),
        @CERIS_INTERFACE_NAME       varchar(50),
        @CERIS_COMPANY_PARAM        varchar(50),
		@OPEN_KEY					varchar(400),
		@CLOSE_KEY					varchar(400),
		@DIV_22_COMPANY_ID			varchar(1)


-- set local constants
SET @SP_NAME = 'XX_R22_INSERT_TS_PREPROC_RECORDS'
SET @DAYS_IN_A_WEEK = 7
SET @CHAR_VALUE_NONE = 'NONE'
SET @CHAR_VALUE_RONE = 'RONE'


--Added for CR-1649
-- #3.4.1 Rename employee
-- Set params for R22
-- set local constants
SET @CERIS_INTERFACE_NAME = 'CERIS_R22'
SET @CERIS_PASSKEY_VALUE_PARAM = 'PASSKEY_VALUE'
SET @CERIS_KEYNAME_PARAM = 'CERIS_KEYNAME'
SET @CERIS_COMPANY_PARAM = 'COMPANY_ID'

SELECT @DIV_22_COMPANY_ID = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME    = @CERIS_COMPANY_PARAM
AND	INTERFACE_NAME_CD = @CERIS_INTERFACE_NAME

SELECT	@CERIS_PASSKEY_VALUE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME    = @CERIS_PASSKEY_VALUE_PARAM
AND		INTERFACE_NAME_CD = @CERIS_INTERFACE_NAME

SELECT @CERIS_KEYNAME = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME    = @CERIS_KEYNAME_PARAM
AND	INTERFACE_NAME_CD = @CERIS_INTERFACE_NAME

SET @OPEN_KEY = 'OPEN SYMMETRIC KEY' + '  ' + @CERIS_KEYNAME + '  ' + 'DECRYPTION BY PASSWORD = ''' +  @CERIS_PASSKEY_VALUE + '''' + '  '
SET @CLOSE_KEY = 'CLOSE SYMMETRIC KEY' + '  ' + @CERIS_KEYNAME


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
FROM dbo.XX_R22_IMAPS_ET_IN_TMP WHERE RECORD_TYPE = 'R'

--change KM 11/14/05
IF @MAX_WEEK_ENDING_DT IS NULL
BEGIN
-- THERE SHOULD BE AT LEAST 1 Regular Record in each batch
    EXEC dbo.XX_ERROR_MSG_DETAIL
             @in_error_code = 204,
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
	FROM IMAR.DELTEK.SUB_PD a
	WHERE a.SUB_PD_END_DT =
	(SELECT MIN(b.SUB_PD_END_DT)
	 FROM  IMAR.DELTEK.SUB_PD b
	       WHERE (b.SUB_PD_NO = 2 OR
		      b.SUB_PD_NO = 3) AND
	       DATEDIFF(day, @MAX_WEEK_ENDING_DT, b.SUB_PD_END_DT) >= 0)
--END CHAGE KM

	

DECLARE @CurrentFY int,
	@CurrentPeriod int,
    @MTCPeriod  int, -- Added for CR-1901
	@CurrentSubPeriod int,

	@EndDateOfSubPeriod_1 datetime,
	@EndDateOf_TS_SubPeriod datetime,

	@CORRECTING_EndDateOfSubPeriod_1 datetime,
	@CORRECTING_SubPeriod int,
	@EndDateOf_CORRECTING_TS_Subperiod datetime

SET @CurrentFY = DATEPART(year, @MAX_WEEK_ENDING_DT)
SET @CurrentPeriod = DATEPART(month, @MAX_WEEK_ENDING_DT)




    SELECT @EndDateOfSubPeriod_1 = SUB_PD_END_DT
    FROM IMAR.DELTEK.SUB_PD 
    WHERE PD_NO=@CurrentPeriod AND
    FY_CD = @CurrentFY AND
    SUB_PD_NO = 1

    -- Added CR-1901
    -- Pick the lowest open pds for MTCs to process thru CP
    SELECT @MTCPeriod=MIN(pd_no)
    FROM IMAR.DELTEK.SUB_PD 
    WHERE s_status_cd='O'
    and FY_CD = @CurrentFY



--CHANGE 2 sub period values derived inside loop
--ie for each day of timesheet week
TRUNCATE TABLE dbo.XX_R22_IMAPS_TS_PREP_TEMP
TRUNCATE TABLE dbo.XX_R22_IMAPS_TS_PREP_ZEROS
TRUNCATE TABLE dbo.XX_R22_ET_DAILY_IN

--Open Key for Reading the employee IDs
-- Close it once done
exec (@OPEN_KEY)

DECLARE cursor_one CURSOR FAST_FORWARD FOR
   SELECT * FROM dbo.XX_R22_IMAPS_ET_IN_TMP --where emp_serial_num=  '1D0883' 
   --order by ts_year,ts_month, ts_day,sat_reg_time desc, proj_abbr

OPEN cursor_one
FETCH cursor_one
INTO @in_EMP_SERIAL_NUM, @in_TS_YEAR, @in_TS_MONTH, @in_TS_DAY, @in_PROJ_ABBR, @in_SAT_REG_TIME, @in_SAT_OVERTIME,
@in_SUN_REG_TIME, @in_SUN_OVERTIME, @in_MON_REG_TIME, @in_MON_OVERTIME, @in_TUE_REG_TIME, @in_TUE_OVERTIME,
@in_WED_REG_TIME, @in_WED_OVERTIME, @in_THU_REG_TIME, @in_THU_OVERTIME, @in_FRI_REG_TIME, @in_FRI_OVERTIME,
@in_PLC, @in_RECORD_TYPE, @in_AMENDMENT_NUM, @in_ILC_ACTIVITY_CD, -- Added CR-1333
@in_PAY_TYPE -- Added CR-1539

WHILE (@@fetch_status = 0)
BEGIN


	-- Added CR-1649
	-- Retreive R22 Employee ID
	SELECT @out_empl_id=ISNULL((select empl_id
  	            from dbo.XX_R22_CERIS_EMPL_ID_MAP
            	where CONVERT(varchar(50), DECRYPTBYKEY(R_EMPL_ID)) = @in_EMP_SERIAL_NUM
            	and empl_id in (select empl_id from IMAR.DELTEK.empl)
            	),
    	@in_EMP_SERIAL_NUM)
    

      --SET @out_EMPL_ID = @in_EMP_SERIAL_NUM
      SET @out_FY_CD = @CurrentFY
      SET @out_PD_NO = @CurrentPeriod
      SET @out_PROJ_ABBRV_CD = substring(@in_PROJ_ABBR, 1, 4)
	  SET @out_PAY_TYPE=@in_PAY_TYPE -- Added CR-1539 
	  SET @out_CORRECTING_REF_DT=NULL  --Added DR-2414 04/27/2010 -- This will default the value to NULL for new loops 
      -- 08/26/2005: project labor category is defaulted to 'NONE' if @in_PLC does not have a value
      IF @in_PLC IS NULL
         SET @out_BILL_LAB_CAT_CD = @CHAR_VALUE_RONE
      ELSE
         IF DATALENGTH(RTRIM(@in_PLC)) = 0
            SET @out_BILL_LAB_CAT_CD = @CHAR_VALUE_RONE
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
		FROM IMAR.DELTEK.SUB_PD 
		WHERE PD_NO =  DATEPART(month, @ts_period_end_date) AND
		FY_CD = DATEPART(year, @ts_period_end_date) AND
		SUB_PD_NO = 1

	

	
	--CHANGE KM 
	--JANUARY NOW IS LIKE ALL OTHER MONTHS
	SELECT @CORRECTING_SubPeriod = a.SUB_PD_NO 
		    FROM IMAR.DELTEK.SUB_PD a
		    WHERE a.SUB_PD_END_DT =
			(SELECT MIN(b.SUB_PD_END_DT)
			FROM  IMAR.DELTEK.SUB_PD b
			WHERE (b.SUB_PD_NO = 2 OR
			b.SUB_PD_NO = 3) AND
			DATEDIFF(day,@ts_period_end_date,b.SUB_PD_END_DT) >= 0)
	--END CHANGE
	


	--loop for each day
	-- traverse thru the course of a timesheet period, from the first to the last day of the period
	SET @lcv = 0
   
	WHILE @lcv < 7
	BEGIN
        set @out_ts_dt= NULL
		
            SET @ts_period_day_date = @ts_period_start_date + @lcv
            -- effective billing date takes the date value of the timesheet day
            SET @out_EFFECT_BILL_DT = CONVERT(char(10), @ts_period_day_date, 120)		
		--CHANGE KM 
		--JANUARY NOW IS LIKE ALL OTHER MONTHS
	    SELECT @CurrentSubPeriod = a.SUB_PD_NO 
	    FROM IMAR.DELTEK.SUB_PD a
	    WHERE a.SUB_PD_END_DT =
		(SELECT MIN(b.SUB_PD_END_DT)
		FROM  IMAR.DELTEK.SUB_PD b
		WHERE (b.SUB_PD_NO = 2 OR
		b.SUB_PD_NO = 3) AND
		DATEDIFF(day,@ts_period_day_date,b.SUB_PD_END_DT) >= 0)
		--END CHANGE
	    
	    SELECT @EndDateOf_TS_SubPeriod = SUB_PD_END_DT
	    FROM IMAR.DELTEK.SUB_PD 
	    -- begin change KM 12/6/05
	    WHERE PD_NO =  DATEPART(month, @ts_period_day_date) AND
			FY_CD = DATEPART(year, @ts_period_day_date) AND
	    		SUB_PD_NO = @CurrentSubPeriod
	    -- end change KM 12/6/05

        -- Begin CR-1901 03/07/2009
        -- Make the date as 12/31 for split from 12/30 
        -- This is if pd=12 and subpd=3 does not have the date in SUB_PD table as 12/31
     
        if DATEPART(day, @EndDateOf_TS_SubPeriod)=30 and DATEPART(month, @EndDateOf_TS_SubPeriod)=12
            BEGIN
                set @EndDateOf_TS_SubPeriod=@EndDateOf_TS_SubPeriod+1
            END        
        -- END CR-1901


	    SELECT @EndDateOf_CORRECTING_TS_SubPeriod = SUB_PD_END_DT
	    FROM IMAR.DELTEK.SUB_PD 
	    WHERE 	PD_NO =  DATEPART(month, @ts_period_day_date) AND
			FY_CD = DATEPART(year, @ts_period_day_date) AND
	    		SUB_PD_NO = @CurrentSubPeriod

        --Added DR-2809 09/20/2010
        --We can now use staging sub_pd table to determine the split date for reg, PPA TCs
        --Prior to this date we used complicated logic to determine the splits.
        --The new logic will compare Effect_bill_date with sub_pd_begin and sub_pd_end dates and use sub_pd_end date as TS_DT or corr_ref_date.
        
         IF @out_S_TS_TYPE_CD in ('C','N','D') -- Modified CR-1649
	 	   BEGIN
                SELECT DISTINCT
                       @CurrentSubPeriod = a.SUB_PD_NO,
                       @out_CORRECTING_REF_DT = CONVERT(char(10),a.sub_pd_end_dt,120),
                       @out_TS_DT = CONVERT(char(10), @MAX_WEEK_ENDING_DT, 120)
                FROM XX_R22_SUB_PD a
                WHERE @out_EFFECT_BILL_DT>=a.SUB_PD_BEGIN_DT
                    and @out_EFFECT_BILL_DT<=a.SUB_PD_END_DT
           END
          ELSE IF  @out_S_TS_TYPE_CD in ('R')
           BEGIN
                SELECT DISTINCT
                       @CurrentSubPeriod = a.SUB_PD_NO,
                       @out_CORRECTING_REF_DT = NULL,
                       @out_TS_DT = CONVERT(char(10), a.SUB_PD_END_DT, 120) 
                FROM XX_R22_SUB_PD a
                WHERE @out_EFFECT_BILL_DT>=a.SUB_PD_BEGIN_DT
                    and @out_EFFECT_BILL_DT<=a.SUB_PD_END_DT
           END

			SET @out_SUB_PD_NO = @CurrentSubPeriod
            

/* Commented 09/20/2010 DR-2809-----
-- This block was used prior to this date to determine the split timecard logic

		--PRINT '--------------------'
		--PRINT @out_EMPL_ID
	    --TS_DT/SubPeriod/Correcting Reference Date calculation
	    --If correcting timesheet
	    IF @out_S_TS_TYPE_CD in ('C','N','D') -- Modified CR-1649
	 	BEGIN
			SET @out_SUB_PD_NO = @MAX_WEEK_ENDING_DT_SubPeriod
			SET @out_TS_DT = CONVERT(char(10), @MAX_WEEK_ENDING_DT, 120)
			
			/*Begin DR-922 4/17/07 
			  NO LONG TREATING CORRECTIONS/MISSING TIMECARDS DIFFERENTLY
			  ALL CORRECTIONS WILL BE COSTED AT CURRENT YEAR RATE
			  *SEE XX_ETIME_SIMULATE_COSTPOINT_SP

			--correcting reference date calculation
			-- change KM 1/26/05
			IF(
			   DATEDIFF(YEAR, GETDATE(), @ts_period_day_date) < 0
				AND
			  (
				(CAST(@in_AMENDMENT_NUM as int) = 0)
				OR --added KM 4/5/07
				@CurrentFY = (SELECT DATEPART(YEAR, MIN(CREATED_DATE)) FROM XX_ET_DAILY_IN_ARC WHERE EMP_SERIAL_NUM = @out_EMPL_ID AND TS_DATE = @ts_period_end_date AND AMENDMENT_NUM = 0)
			  )
			)
			BEGIN
				SET @out_CORRECTING_REF_DT = (CAST(DATEPART(YYYY,GETDATE()) AS CHAR(4)) + '-01-01')
			END
			--end change KM 1/26/05
			ELSE 
			 End DR-922 4/17/07 */
			IF(DATEDIFF(month, @ts_period_end_date, @ts_period_day_date) < 0)
			BEGIN
            BEGIN
                -- If the date is last of the month and if its Saturday or Sunday then do not split and assign period end date
                -- Added CR-1921
         IF ( datepart(dw,@out_effect_bill_dt) in (7,1) and @out_effect_bill_dt=dateadd(dd,-(day(dateadd(mm,1,@out_effect_bill_dt))),dateadd(mm,1,@out_effect_bill_dt)) )
             BEGIN
				    SET @out_CORRECTING_REF_DT = CONVERT(char(10), @ts_period_end_date, 120)
                  END
                -- If the date is 14,15,16 and they falls on Saturday or Sunday then Do not split
               ELSE IF ( datepart(dw,@out_effect_bill_dt)in (1,7) and datepart(day,@out_effect_bill_dt) in (14,15,16) )
                  BEGIN
                     SET @out_CORRECTING_REF_DT = CONVERT(char(10), @ts_period_end_date, 120)
                  END
               ELSE
				SET @out_CORRECTING_REF_DT = CONVERT(char(10), @CORRECTING_EndDateOfSubPeriod_1-1, 120)
               END
   

           --print 'a. TS Date '+@out_empl_id+' '+ @out_TS_DT +' '+@out_effect_bill_dt +' '+@out_CORRECTING_REF_DT
  				
			END
			ELSE IF(@CORRECTING_SubPeriod <> @CurrentSubPeriod)
			BEGIN   --CHANGE KM 11/11/05

            --Added CR-1921
            BEGIN
                -- If the date is last of the month and if its Saturday or Sunday then do not split and assign period end date
                -- Added CR-1921
               IF ( datepart(dw,@out_effect_bill_dt) in (7,1) and @out_effect_bill_dt<=dateadd(dd,-(day(dateadd(mm,1,@out_effect_bill_dt))),dateadd(mm,1,@out_effect_bill_dt)) )
                  -- Modified CR-2230, Added "<" sign.
                  BEGIN
				    SET @out_CORRECTING_REF_DT = CONVERT(char(10), @ts_period_end_date, 120)
                  END
                -- If the date is 14,15,16 and they falls on Saturday or Sunday then Do not split
               ELSE IF ( datepart(dw,@out_effect_bill_dt)in (1,7) and datepart(day,@out_effect_bill_dt) in (14,15,16) )
                  BEGIN
                     SET @out_CORRECTING_REF_DT = CONVERT(char(10), @ts_period_end_date, 120)
                  END
               ELSE
				SET @out_CORRECTING_REF_DT = CONVERT(char(10), @EndDateOf_CORRECTING_TS_SubPeriod, 120)
            END
            --print 'b. TS Date '+@out_empl_id+' '+ @out_TS_DT+' '+@out_effect_bill_dt+' '+@out_CORRECTING_REF_DT

			END
			ELSE
			BEGIN
				SET @out_CORRECTING_REF_DT = CONVERT(char(10), @ts_period_end_date, 120)
            --print 'c. TS Date '+@out_empl_id+' '+ @out_TS_DT+' '+@out_effect_bill_dt+' '+@out_CORRECTING_REF_DT

			END
			
		END
        -- Added this logic to simplify the process to derive TS_DT 
        -- CR-1901
        ELSE IF (@EndDateOf_TS_SubPeriod>=@ts_period_end_date-6 AND @EndDateOf_TS_SubPeriod<=@ts_period_end_date AND cast(@out_effect_bill_dt as datetime) >@EndDateOf_TS_SubPeriod and @in_AMENDMENT_NUM=0 )
            BEGIN
                SET @out_TS_DT = CONVERT(char(10), @ts_period_end_date, 120)
				--Print 'A'+@out_ts_dt
            END
        ELSE IF (@EndDateOf_TS_SubPeriod>=@ts_period_end_date-6 AND @EndDateOf_TS_SubPeriod<=@ts_period_end_date AND cast(@out_effect_bill_dt as datetime) <=@EndDateOf_TS_SubPeriod and @in_AMENDMENT_NUM=0 )
            BEGIN
                -- If the date is last of the month and if its Saturday or Sunday then do not split and assign period end date
                -- Added CR-1921
				-- Modified CR-2230, Added "<" sign. 
				-- TS_DT   Effect Bill DT
				/*	5/30         5/30 <--- Issue with 5/30
					6/5           5/31	<--- 5/31 worked ok
					6/5            6/1 & Other days.

					New Logic:
					TS_DT   Effect Bill DT
					6/5         5/30
					6/5           5/31
					6/5            6/1 & Other days.
				*/

               IF ( datepart(dw,@out_effect_bill_dt) in (7,1) and @out_effect_bill_dt<=dateadd(dd,-(day(dateadd(mm,1,@out_effect_bill_dt))),dateadd(mm,1,@out_effect_bill_dt)) )
                  BEGIN
                     SET @out_TS_DT = CONVERT(char(10), @ts_period_end_date, 120)
					 --Print 'B'+@out_ts_dt
        END
                -- If the date is 14,15,16 and they falls on Saturday or Sunday then Do not split
               ELSE IF ( datepart(dw,@out_effect_bill_dt)in (1,7) and datepart(day,@out_effect_bill_dt) in (14,15,16) )
                  BEGIN
                     SET @out_TS_DT = CONVERT(char(10), @ts_period_end_date, 120)
					 --Print 'C'+@out_ts_dt
                  END
               ELSE
                SET @out_TS_DT = CONVERT(char(10), @EndDateOf_TS_SubPeriod, 120)
					--Print 'D'+@out_ts_dt
            END
	    -- else everything is based off MAX_WEEK_ENDING_DT
	    ELSE
		BEGIN
			SET @out_SUB_PD_NO = @MAX_WEEK_ENDING_DT_SubPeriod
			--SET @out_TS_DT = CONVERT(char(10), @MAX_WEEK_ENDING_DT, 120)
			SET @out_TS_DT = CONVERT(char(10), @ts_period_end_date, 120)
			SET @out_CORRECTING_REF_DT = NULL
			--Print 'E'+@out_ts_dt
		END
			SET @out_SUB_PD_NO = '3'



/*
        -- For Regualr and MTCs
	    -- else if SubPeriod should be 1
	    ELSE IF (DATEDIFF(month,@MAX_WEEK_ENDING_DT,@EndDateOf_TS_SubPeriod) < 0)
		BEGIN
			SET @out_SUB_PD_NO = '1'
			--SET @out_TS_DT = CONVERT(char(10), @ts_period_end_date, 120) -- Test Commented
            --SET @out_TS_DT = CONVERT(char(10), @EndDateOfSubPeriod_1 - 1, 120)
            SET @out_TS_DT = CONVERT(char(10), @EndDateOf_TS_SubPeriod, 120)
			SET @out_CORRECTING_REF_DT = NULL		
            print 'a.IF Date'+ @out_TS_DT
		END
	    -- else if SubPeriod should be Previous, also if Its Missing TC then TS_DT=period_end_date
	    ELSE IF @CurrentSubPeriod <> @MAX_WEEK_ENDING_DT_SubPeriod AND @ts_period_end_date>@EndDateOf_TS_SubPeriod and @in_AMENDMENT_NUM=0 
		BEGIN
			SET @out_SUB_PD_NO = @CurrentSubPeriod
			--SET @out_TS_DT = CONVERT(char(10), @EndDateOf_TS_SubPeriod, 120) -- @ts_period_end_date Removed CR-1649 10/25/08
			SET @out_TS_DT = CONVERT(char(10), @EndDateOf_TS_SubPeriod, 120) -- @ts_period_end_date Removed DR-1875 10/25/08
			--SET @out_TS_DT = CONVERT(char(10), @TS_period_end_date, 120) -- @ts_period_end_date Removed DR-1901 10/25/08
			SET @out_CORRECTING_REF_DT = NULL
            print 'b1.IF Date'+ @out_TS_DT 
		END
	    -- else if SubPeriod should be Previous, also if Its Missing TC then TS_DT=period_end_date
	    ELSE IF @CurrentSubPeriod <> @MAX_WEEK_ENDING_DT_SubPeriod AND @in_AMENDMENT_NUM=0 
		BEGIN
			SET @out_SUB_PD_NO = @CurrentSubPeriod
			SET @out_TS_DT = CONVERT(char(10), @EndDateOf_TS_SubPeriod, 120) -- @ts_period_end_date Removed CR-1649 10/25/08
			SET @out_TS_DT = CONVERT(char(10), @ts_period_end_date, 120) -- @ts_period_end_date Removed DR-1875 10/25/08
			SET @out_CORRECTING_REF_DT = NULL
            print 'b.IF Date'+ @out_TS_DT 
		END
		-- else if SubPeriod should be Previous, also if Its Missing TC then TS_DT=period_end_date
	    ELSE IF @CurrentSubPeriod <> @MAX_WEEK_ENDING_DT_SubPeriod AND @in_AMENDMENT_NUM<>0
		BEGIN
			SET @out_SUB_PD_NO = @CurrentSubPeriod
			SET @out_TS_DT = CONVERT(char(10), @EndDateOf_TS_SubPeriod, 120)
			SET @out_CORRECTING_REF_DT = NULL
            print 'c.IF Date'+ @out_TS_DT
		END

	    -- else everything is based off MAX_WEEK_ENDING_DT
	    ELSE
		BEGIN
			SET @out_SUB_PD_NO = @MAX_WEEK_ENDING_DT_SubPeriod
			--SET @out_TS_DT = CONVERT(char(10), @MAX_WEEK_ENDING_DT, 120)
			SET @out_TS_DT = CONVERT(char(10), @ts_period_end_date, 120)
			SET @out_CORRECTING_REF_DT = NULL
            --print 'd.IF Date'+ @out_TS_DT
		END
  */
        
        -- CR-1901 Added to assign MTC Period to MTCs
        --IF @in_AMENDMENT_NUM=0 and (DATEPART(month,@MAX_WEEK_ENDING_DT)<> DATEPART(month,@ts_period_end_date))
        IF @in_AMENDMENT_NUM=0 and (DATEPART(month,@OUT_TS_DT)<> DATEPART(month,@ts_period_end_date))
            BEGIN
            SET @CurrentPeriod = @MTCPeriod
            END
        ELSE
            -- Modified 03/04/2009            
            BEGIN
            SET @CurrentPeriod = DATEPART(month, @MAX_WEEK_ENDING_DT)
            END
Commented 09/19/2010 DR-2809*/



-- BEGIN CONTINUED CHANGE TS_HDR_SEQ_NO 01/01/06
	
		-- HDR_SEQ_NO CALCULATION
		-- for correcting timesheets 
		-- distinct headers are not automatically created by preprocessor
		-- to ensure 1 header for each correcting reference date
		-- we must make use of the TS_HDR_SEQ_NO field
		
		-- 09/07/2006
		-- NEED TO GROUP TIMESHEETS BY PROJECT IN ORDER TO
		-- ISOLATE CROSS-CHARGING ERRORS
		IF @out_S_TS_TYPE_CD in ('C','N','D') -- Modified CR-1649
		BEGIN
			-- CHANGE KM 1/5/06
			-- needed in order to make NULL comparisons
			set @out_TS_HDR_SEQ_NO_int = NULL
			
			-- find out if header will already be created
			-- by previous line item
			select 	@out_TS_HDR_SEQ_NO_int = CAST(TS_HDR_SEQ_NO AS int)
			from 	dbo.XX_R22_IMAPS_TS_PREP_TEMP
			where 	EMPL_ID = @out_EMPL_ID AND
				TS_DT	= @out_TS_DT   AND
				S_TS_TYPE_CD = @out_S_TS_TYPE_CD AND
				--PROJ_ABBRV_CD = @out_PROJ_ABBRV_CD AND -- Commented CR-1921
				CORRECTING_REF_DT = @out_CORRECTING_REF_DT
			
			-- if not, find previous HDR_SEQ_NO
			-- and increment
			if @out_TS_HDR_SEQ_NO_int IS NULL
			BEGIN
				select 	@out_TS_HDR_SEQ_NO_int = MAX(CAST(TS_HDR_SEQ_NO AS int)) 
				from 	dbo.XX_R22_IMAPS_TS_PREP_TEMP
				where 	EMPL_ID = @out_EMPL_ID AND
					TS_DT	= @out_TS_DT   AND
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
            /* Commented CR-1901 -- 03/03/2009
            -- effective billing date takes the date value of the timesheet day
            SET @out_EFFECT_BILL_DT = CONVERT(char(10), @ts_period_day_date, 120)
            */
            
            /*
             * Add one new XX_ET_DAILY_IN record for each day of the timesheet period.
             * PK column ET_DAILY_IN_RECORD_NUM is an IDENTITY column.
	 * 
             */
            INSERT INTO dbo.XX_R22_ET_DAILY_IN
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
                     @in_placeholder_value2   = 'a XX_R22_ET_DAILY_IN record',
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
            SET @lv_identity_val = IDENT_CURRENT('dbo.XX_R22_ET_DAILY_IN')

            SET @out_NOTES = CONVERT(varchar(10), @in_STATUS_RECORD_NUM) + '-' + CONVERT(varchar(10), @lv_identity_val)+ '-' +'ACTVT_CD'+COALESCE(@in_ILC_ACTIVITY_CD,NULL,SPACE(6))+'-'+rtrim(@out_S_TS_TYPE_CD) -- Added CR-1333
            --SET @out_NOTES = CONVERT(varchar(10), @in_STATUS_RECORD_NUM) + '-' + CONVERT(varchar(10), @lv_identity_val)+'-'+@out_S_TS_TYPE_CD -- Added CR-1901
            -- add one new XX_IMAPS_TS_PREP_TEMP record for each day of the timesheet period
	    IF (CAST(@out_CHG_HRS as decimal(14,2)) <> .00)
	    BEGIN
		    INSERT INTO dbo.XX_R22_IMAPS_TS_PREP_TEMP
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
		    INSERT INTO dbo.XX_R22_IMAPS_TS_PREP_ZEROS
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
                     @in_placeholder_value2   = 'a XX_R22_IMAPS_TS_PREP_TEMP record',
                     @in_calling_object_name  = @SP_NAME,
                     @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT

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

--Open Key for Reading the employee IDs
-- Close it once done
exec (@OPEN_KEY)

SET @lv_error_code = @@ERROR

IF @lv_error_code <> 0
BEGIN
  -- Attempt to insert a XX_IMAPS_TS_PREP_TEMP record failed.
  EXEC dbo.XX_ERROR_MSG_DETAIL
     @in_error_code           = 204,
     @in_display_requested    = 1,
     @in_SQLServer_error_code = @lv_error_code,
     @in_placeholder_value1   = 'update',
     @in_placeholder_value2   = 'IMAR.DELTEK.DFLT_REG_TS',
     @in_calling_object_name  = @SP_NAME,
     @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
  RETURN(1) -- exit this sp
END



--begin change KM 02/27/05
UPDATE 	IMAR.DELTEK.DFLT_REG_TS
SET 	GENL_LAB_CAT_CD = empl_lab.GENL_LAB_CAT_CD,
     	CHG_ORG_ID = empl_lab.ORG_ID
FROM 	IMAR.DELTEK.DFLT_REG_TS as dflt_reg
INNER JOIN 
	IMAR.DELTEK.EMPL_LAB_INFO AS empl_lab
ON 	(
	dflt_reg.EMPL_ID = empl_lab.EMPL_ID
AND	empl_lab.EFFECT_DT <= @MAX_WEEK_ENDING_DT
AND	empl_lab.END_DT >= @MAX_WEEK_ENDING_DT
AND	(empl_lab.GENL_LAB_CAT_CD <> dflt_reg.GENL_LAB_CAT_CD
	OR empl_lab.ORG_ID <> dflt_reg.CHG_ORG_ID)
)
--end change KM 02/27/05


-- Defect 782 Begin

IF @current_month_posting_ind IS NOT NULL AND @current_month_posting_ind = 'Y'
   BEGIN
      DECLARE @CURRENT_PD_NO integer
      SET @CURRENT_PD_NO = DATEPART(month, GETDATE())

  --BEGIN SUB_PD CHANGE KM
      UPDATE dbo.XX_R22_IMAPS_TS_PREP_TEMP
         SET PD_NO = @CURRENT_PD_NO,
             SUB_PD_NO = 1
      WHERE  S_TS_TYPE_CD = 'R'

      UPDATE dbo.XX_R22_IMAPS_TS_PREP_TEMP
         SET PD_NO = @CURRENT_PD_NO,
             SUB_PD_NO = 2
      WHERE  S_TS_TYPE_CD in ('C','N','D')  -- Modified CR-1649
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
      		   @in_placeholder_value2   = 'IMAR.DELTEK.DFLT_REG_TS',
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
UPDATE dbo.XX_R22_IMAPS_TS_PREP_TEMP
SET ACCT_ID = lab_acct.ACCT_ID,
GENL_LAB_CAT_CD = empl_lab.GENL_LAB_CAT_CD
FROM dbo.XX_R22_IMAPS_TS_PREP_TEMP ts
INNER JOIN IMAR.DELTEK.EMPL_LAB_INFO empl_lab
on
(ts.empl_id = empl_lab.empl_id
	and 
	(
		(ts.S_TS_TYPE_CD = 'R' AND cast(ts.TS_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
		OR
		(ts.S_TS_TYPE_CD in ('C','N','D') AND cast(ts.CORRECTING_REF_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT) -- Modified CR-1649
	)
)
INNER JOIN IMAR.DELTEK.PROJ proj
on
(ts.PROJ_ABBRV_CD = proj.PROJ_ABBRV_CD
AND proj.COMPANY_ID=@in_COMPANY_ID) 	--Added CR-1543
INNER JOIN IMAR.DELTEK.LAB_ACCT_GRP_DFLT lab_acct
ON
(
empl_lab.LAB_GRP_TYPE = lab_acct.LAB_GRP_TYPE
AND proj.ACCT_GRP_CD = lab_acct.ACCT_GRP_CD
AND lab_acct.COMPANY_ID=@in_COMPANY_ID 	--Added CR-1543
)

--ISOLATE
UPDATE dbo.XX_R22_IMAPS_TS_PREP_TEMP
SET NOTES = RTRIM(NOTES) + '-CROSS_CHARGING-'
WHERE ACCT_ID IS NULL

--CORRECTING TIMESHEETS ARE ALREADY ISOLATED BY PROJECT
--REGULAR TIMESHEETS CANNOT BE ISOLATED MORE THAN 9 (TS_HDR_SEQ_NO)
--SO TO ISOLATE REGULAR TIMESHEETS, CHANGE TS_HDR_SEQ_NO
UPDATE dbo.XX_R22_IMAPS_TS_PREP_TEMP
SET TS_HDR_SEQ_NO = '2'
WHERE S_TS_TYPE_CD = 'R'
AND ACCT_ID IS NULL

--MAKE NULL AGAIN, SO PREPROCESSOR CAN DEFAULT THE VALUES 
--IN CASE THINGS HAVE CHANGED
UPDATE dbo.XX_R22_IMAPS_TS_PREP_TEMP
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
               @in_placeholder_value2   = 'XX_R22_IMAPS_TS_PREP_CROSS_CHARGING_ERRORS',
    @in_calling_object_name  = @SP_NAME,
               @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END

--Begin DR-922 4/17/07
EXEC @lv_error_code = XX_R22_ETIME_SIMULATE_COSTPOINT_SP
	@in_COMPANY_ID=@in_COMPANY_ID			-- Added CR-1543
	
--End DR-922 4/17/07

-- Added CR-1926
-- This block will update PD_NO
/*
update xx_r22_imaps_ts_prep_temp
set pd_no=
		(select pd_no from xx_r22_sub_pd
			where FY_CD=(datepart(yyyy,ts.ts_dt)) 
			and ts.ts_dt>=sub_pd_begin_dt and ts.ts_dt<=sub_pd_end_dt
			and pd_no+(datepart(yyyy,ts.ts_dt)) in (select pd_no+fy_cd from imar.deltek.accting_pd where s_status_cd='O')
		 )
from xx_r22_imaps_ts_prep_temp ts
*/
update xx_r22_imaps_ts_prep_temp
set pd_no=
	isnull(
		(select pd_no from xx_r22_sub_pd
			where FY_CD=(datepart(yyyy,ts.ts_dt)) 
			and ts.ts_dt>=sub_pd_begin_dt and ts.ts_dt<=sub_pd_end_dt
			and pd_no+(datepart(yyyy,ts.ts_dt)) in (select pd_no+fy_cd from imar.deltek.accting_pd where s_status_cd='O')
		 ),
			(select pd_no from xx_r22_sub_pd
					where FY_CD=(datepart(yyyy,@MAX_WEEK_ENDING_DT)) 
					and @MAX_WEEK_ENDING_DT>=sub_pd_begin_dt and @MAX_WEEK_ENDING_DT<=sub_pd_end_dt
					and pd_no+(datepart(yyyy,@MAX_WEEK_ENDING_DT)) in (select pd_no+fy_cd from imar.deltek.accting_pd where s_status_cd='O')
			 )
		   )
from xx_r22_imaps_ts_prep_temp ts

-- End CR-1926

/*
--Begin CR-1921 TS_HDR_SEQ Updates for N, Ds

    DECLARE @EMPL_ID varchar(12)

    DECLARE EMPL_ID_CURSOR CURSOR FAST_FORWARD FOR
    SELECT DISTINCT EMPL_ID FROM dbo.xx_r22_imaps_ts_prep_temp where s_ts_type_cd in ('N','D')

    OPEN EMPL_ID_CURSOR
    FETCH NEXT FROM EMPL_ID_CURSOR INTO @EMPL_ID

    WHILE @@FETCH_STATUS = 0
       BEGIN
	    --BECAUSE OF CHANGE TO CORRECTING TIMESHEETS, WE MUST USE THE TS_HDR_SEQ_NO
	    --SO THAT PREPROCESSOR DOES NOT GIVE INCONSISTENT HEADER DATA ERROR
	    --ON CORRECTING TIMESHEETS REFERENCE DATE
	    --S_TS_HDR_SEQ_NO MUST BE UNIQUE FOR THIS COMBINATION:
	    --TS_DT (all the same), TS_TYPE (all the same), EMPL_ID, CORRECTING_REF_DT
	    --TO ISOLATE CROSS-CHARGING, WE MUST exclude GROUP BY PROJ_ABBRV_CD

        --select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.[#XX_IMAPS_TS_HDR_SEQ_NO]')  and OBJECTPROPERTY(id, N'IsTable') = 1

       --drop table dbo.#XX_IMAPS_TS_HDR_SEQ_NO
       
       if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.[#XX_IMAPS_TS_HDR_SEQ_NO]') )
        BEGIN
            drop table [dbo].[#XX_IMAPS_TS_HDR_SEQ_NO]
        END    

	    CREATE TABLE dbo.#XX_IMAPS_TS_HDR_SEQ_NO (
		    [IDENTITY_TS_HDR_SEQ_NO] [int] IDENTITY (1, 1) NOT NULL ,
		    [EMPL_ID] [char] (12) NOT NULL,
		    [CORRECTING_REF_DT] [char] (10) NULL,
		    [S_TS_LN_TYPE_CD] [char] (1) NULL,
            [S_TS_TYPE_CD] [char] (1) NULL
          --  [PROJ_ABBRV_CD] [char] (10) NULL
	    )
	
	    INSERT INTO #XX_IMAPS_TS_HDR_SEQ_NO
	    (EMPL_ID, CORRECTING_REF_DT, S_TS_LN_TYPE_CD, S_TS_TYPE_CD)
	    SELECT 	EMPL_ID, CORRECTING_REF_DT, S_TS_LN_TYPE_CD, S_TS_TYPE_CD
	    FROM 	dbo.xx_r22_imaps_ts_prep_temp
	    WHERE 	EMPL_ID = @empl_id
	    AND S_TS_TYPE_CD in ('N','D')
	    GROUP BY EMPL_ID, CORRECTING_REF_DT, S_TS_LN_TYPE_CD, S_TS_TYPE_CD
	
	    UPDATE dbo.xx_r22_imaps_ts_prep_temp
	    SET TS_HDR_SEQ_NO = CAST(tmp.IDENTITY_TS_HDR_SEQ_NO as char(2))
	    FROM  dbo.xx_r22_imaps_ts_prep_temp ceris
	    INNER JOIN
		    #XX_IMAPS_TS_HDR_SEQ_NO tmp
	    ON
	    (ceris.EMPL_ID = tmp.EMPL_ID
	    and ceris.CORRECTING_REF_DT = tmp.CORRECTING_REF_DT
	    and ISNULL(ceris.S_TS_LN_TYPE_CD, '') = ISNULL(tmp.S_TS_LN_TYPE_CD, '')
	    and ceris.s_ts_type_cd=tmp.s_ts_type_cd
	    )
	
        IF OBJECT_ID('tempdb.dbo.#XX_IMAPS_TS_HDR_SEQ_NO') IS NOT NULL
        BEGIN
            drop table dbo.#XX_IMAPS_TS_HDR_SEQ_NO
        END
        
   	    FETCH NEXT FROM EMPL_ID_CURSOR INTO @EMPL_ID

       END 

    -- clean up empl_id_cursor
    CLOSE EMPL_ID_CURSOR
    DEALLOCATE EMPL_ID_CURSOR
    

--END CR-1921
*/

--Begin CR-2419 3/20/10
EXEC @lv_error_code = XX_R22_ETIME_SIMULATE_TSHDRSEQ_SP

--End CR-2419 3/20/10


 IF @lv_error_code <> 0
         BEGIN
            -- Attempt to insert a XX_IMAPS_TS_PREP_TEMP record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
               @in_SQLServer_error_code = @lv_error_code,
               @in_placeholder_value1   = 'insert',
               @in_placeholder_value2   = 'XX_R22_IMAPS_TS_PREP SIMULATE ERRORS',
               @in_calling_object_name  = @SP_NAME,
             @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END

 
EXEC @lv_error_code = XX_R22_INSERT_TS_RESPROC_SP

 IF @lv_error_code <> 0
         BEGIN
            -- Attempt to insert a XX_IMAPS_TS_PREP_TEMP record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
               @in_SQLServer_error_code = @lv_error_code,
               @in_placeholder_value1   = 'insert',
               @in_placeholder_value2   = 'XX_R22_IMAPS_TS_PREP_TEMP Research process',
               @in_calling_object_name  = @SP_NAME,
               @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END


--Begin CR-1414 01/31/2008
--Copy data to XX_IMAPS_TS_UTIL_DATA for Utilization processing
-- This is the same data that was sent to Preprocessor
INSERT INTO dbo.XX_R22_IMAPS_TS_UTIL_DATA
(   STATUS_RECORD_NUM,    TS_DT,  EMPL_ID,	S_TS_TYPE_CD,	WORK_STATE_CD,	FY_CD,	PD_NO,
	SUB_PD_NO,	CORRECTING_REF_DT,	PAY_TYPE ,	GENL_LAB_CAT_CD,	S_TS_LN_TYPE_CD,	LAB_CST_AMT,
	CHG_HRS,	WORK_COMP_CD,	LAB_LOC_CD,	ORG_ID,	ACCT_ID,	PROJ_ID,	BILL_LAB_CAT_CD,	REF_STRUC_1_ID,
	REF_STRUC_2_ID,	ORG_ABBRV_CD,	PROJ_ABBRV_CD,	TS_HDR_SEQ_NO,	EFFECT_BILL_DT,	PROJ_ACCT_ABBRV_CD,	NOTES,
    TIME_STAMP,     CP_PROCESS_DATE,     CP_TS_LN_KEY )
SELECT 
    --TS_LN_KEY,
    @in_STATUS_RECORD_NUM,    TS_DT,  EMPL_ID,	S_TS_TYPE_CD,	WORK_STATE_CD,	FY_CD,	PD_NO,
	SUB_PD_NO,	CORRECTING_REF_DT,	PAY_TYPE ,	GENL_LAB_CAT_CD,	S_TS_LN_TYPE_CD,	LAB_CST_AMT,
	CHG_HRS,	WORK_COMP_CD,	LAB_LOC_CD,	ORG_ID,	ACCT_ID,	PROJ_ID,	BILL_LAB_CAT_CD,	REF_STRUC_1_ID,
	REF_STRUC_2_ID,	ORG_ABBRV_CD,	PROJ_ABBRV_CD,	TS_HDR_SEQ_NO,	EFFECT_BILL_DT,	PROJ_ACCT_ABBRV_CD,	NOTES,
     convert(char, getdate(), 101) TIME_STAMP,    NULL CP_PROCESS_DATE,    NULL CP_TS_LN_KEY 
FROM  dbo.XX_R22_IMAPS_TS_PREP_TEMP 

      SET @lv_error_code = @@ERROR

 IF @lv_error_code <> 0
         BEGIN
            -- Attempt to insert a XX_IMAPS_TS_UTIL_DATA record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
               @in_SQLServer_error_code = @lv_error_code,
               @in_placeholder_value1   = 'Insert',
               @in_placeholder_value2   = 'XX_R22_IMAPS_TS_UTIL_DATA',
               @in_calling_object_name  = @SP_NAME,
               @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END

	update dbo.xx_R22_imaps_ts_util_data
	set proj_id=b.PROJ_ID
	FROM dbo.xx_R22_imaps_ts_util_data a
	Inner join	IMAR.DELTEK.PROJ b
	ON a.PROJ_ABBRV_CD = b.PROJ_ABBRV_CD
	where a.PROJ_ID is null

	UPDATE XX_R22_IMAPS_TS_UTIL_DATA
	SET
	GENL_LAB_CAT_CD = ELI.GENL_LAB_CAT_CD,
	ORG_ID = ELI.ORG_ID
	--select distinct ts.empl_id, ts.org_id, eli.org_id
	FROM
	XX_R22_IMAPS_TS_UTIL_DATA TS
	INNER JOIN
	IMAR.DELTEK.EMPL_LAB_INFO ELI
	ON
	(
	ELI.EMPL_ID = TS.EMPL_ID
	AND
	 (
		( TS.S_TS_TYPE_CD = 'R'
		  AND
		  TS.TS_DT BETWEEN ELI.EFFECT_DT AND ELI.END_DT	)
		OR
		( TS.S_TS_TYPE_CD in ('C','N','D')
		  AND
		  TS.CORRECTING_REF_DT BETWEEN ELI.EFFECT_DT AND ELI.END_DT)
	 )
	)
	WHERE TS.TIME_STAMP=convert(char, getdate(), 101)

      SET @lv_error_code = @@ERROR

      IF @lv_error_code <> 0
         BEGIN
            -- Update to XX_IMAPS_TS_UTIL_DATA record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
               @in_SQLServer_error_code = @lv_error_code,
               @in_placeholder_value1   = 'update',
               @in_placeholder_value2   = 'XX_R22_IMAPS_TS_UTIL_DATA',
               @in_calling_object_name  = @SP_NAME,
               @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END


--End CT-1414 01/31/2008

-- Modified CR-1649
-- Begin Div22 Changes
/*
3.4.2	For each time sheet week, ensure all employees with timesheets going to Costpoint are active 
in Costpoint; EMPL.S_EMPL_STATUS_CD = 'ACT'.  Also, ensure that active Costpoint users are active in Costpoint.  
In Costpoint, de-activate (EMPL.S_EMPL_STATUS_CD = 'IN') all employees who do not have timesheets being processed 
in the current timesheet period and who are not active users in Costpoint.  If an employee is in the USER_ID table
 with a DE_ACTIVATION_DT = NULL, they are an active end user of Costpoint.


select * from IMAR.DELTEK.empl
where company_id='2'

select * from IMAR.DELTEK.user_id

-- Employee's inactive and have TC
select * from xx_r22_imaps_ts_prep_temp 
where empl_id in (select empl_id from IMAR.DELTEK.empl where s_empl_status_cd='IN' and company_id='2')
*/

--2014-02-20  CP7 changes BEGIN
-- Mark employee's inactive if does not have any TC and not active EU in CP
update IMAR.DELTEK.empl
set s_empl_status_cd='IN'
where company_id=@in_company_id
and empl_id not in (select empl_id from xx_r22_imaps_ts_prep_temp)
and empl_id not in (select empl_id from IMAR.DELTEK.W_USER_UGRP_LIST where empl_id is not null and DE_ACTIVATION_DT = NULL )
--2014-02-20  CP7 changes END

update IMAR.DELTEK.empl
set s_empl_status_cd='ACT'
--select * from IMAR.DELTEK.empl
where company_id=@in_company_id
and empl_id in (select empl_id from xx_r22_imaps_ts_prep_temp)

-- End Div22 Changes

      SET @lv_error_code = @@ERROR

      IF @lv_error_code <> 0
         BEGIN
      -- Update to XX_IMAPS_TS_UTIL_DATA record failed.
         EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code  = 204,
       @in_display_requested    = 1,
    @in_SQLServer_error_code = @lv_error_code,
         @in_placeholder_value1   = 'Update',
               @in_placeholder_value2   = 'IMAR.DELTEK.EMPL',
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
IF OBJECT_ID('dbo.XX_R22_INSERT_TS_PREPROC_RECORDS') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_INSERT_TS_PREPROC_RECORDS >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_INSERT_TS_PREPROC_RECORDS >>>'
go

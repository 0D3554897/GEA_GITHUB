SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

use imapsstg
go

/****** Object:  Stored Procedure dbo.XX_RETRORATE_PREPARE_DATA_SP    Script Date: 04/17/2007 2:39:00 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_RETRORATE_PREPARE_DATA_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_RETRORATE_PREPARE_DATA_SP]
GO


CREATE PROCEDURE [dbo].[XX_RETRORATE_PREPARE_DATA_SP]
(
@in_STATUS_RECORD_NUM     integer,
@in_YEAR                  CHAR(4),
@in_process_date          CHAR(10),
@out_SQLServer_error_code INTEGER      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   VARCHAR(275) = NULL OUTPUT
)
AS

/************************************************************************************************  
Name:       	XX_RETRORATE_PREPARE_DATA_SP
Author:     	KM
Created:    	10/2005  
Purpose:    	Create the retroactive timesheet data which then are saved in the input table
                XX_RATE_RETRO_TS_PREP_TEMP to be used by the bulk copy (bcp) utility to create
                a flat file that will be fed to the Costpoint timesheet preprocessor.

                Called by XX_RETRORATE_RUN_INTERFACE_SP.
The plan

Stored Procedures - Writes in to :
			- xx_genl_lab_Cat
			- xx_rate_retro_ts_prep
			- xx_rate_retro_ts_prep_arc
		    Reads from:
			- IMAPS.Deltek.ts_ln_hs tlh
			- IMAPS.Deltek.ts_hdr_hs thh
		    Updates to:
			- IMAPS.Deltek.empl_lab_info (hrly_amt column)
			- IMAPS.Deltek.genl_lab_cat (genl_avg_rt_amt column)

Notes:      Examples of stored procedure call follow.

            Execute XX_RETRORATE_PREPARE_DATA_SP 
               @in_YEAR = '2006',
               @in_process_date = '01-03-2006' -- Process Date

            Execute XX_RETRORATE_PREPARE_DATA_SP 
               @in_YEAR = '2005',
               @in_process_date = null

Defect 592  Update the XX_IMAPS_INT_STATUS record with processing statistics.
Defect 612  Fix the display of the count values. Add ISNULL().

CR993 -  prior year rate changes

CR1541 - NonZero Pay Types - Standby
05/06/2008 - COMPANY_ID 

CR6127 - Exclude anything before 2012-12-29 (cutover from GLC rate to Actuals)
*************************************************************************************************/

BEGIN


--05/06/2008 - COMPANY_ID
DECLARE @COMPANY_ID varchar(10)

SELECT	@COMPANY_ID = PARAMETER_VALUE
FROM	XX_PROCESSING_PARAMETERS
WHERE	INTERFACE_NAME_CD='RETRORATE'
AND		PARAMETER_NAME='COMPANY_ID' --DR3205 needed for CR3782


DECLARE @PROCESSED_FL            CHAR(1),
	@TO_PROCESS		 CHAR(1),
	@PROCESS_DT              CHAR(10),
	@S_TS_TYPE_CD 		 CHAR(2),
    	@SP_NAME                 sysname,
	@IMAPS_error_number      INTEGER,
	@SQLServer_error_code    INTEGER,
	@row_count               INTEGER,
	@row_count2		 INTEGER,
	@error_msg_placeholder1  sysname,
	@error_msg_placeholder2  sysname,
-- Defect_592_Begin
        @total_LAB_CST_AMT       decimal(14, 2)
-- Defect_592_End

-- set local constants
SET @SQLServer_error_code = 0
SET @SP_NAME = 'XX_RETRORATE_PREPARE_DATA_SP'



/*CR1541 - NonZero Pay Types - Standby*/
declare @non_zero_pay_type varchar(3),
			@retro_pay_type varchar(3),
			@non_zero_pay_type_fctr_qty decimal(5,4)

UPDATE XX_GENL_LAB_CAT
SET STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM
WHERE STATUS_RECORD_NUM IS NULL



/* CR993 -  prior year rate changes */
DECLARE @PRIOR_YEAR varchar(10)
SET @PRIOR_YEAR = 'NO'

IF @in_year <> datepart(year, getdate())
BEGIN
	SET @PRIOR_YEAR = 'YES'
	PRINT 'Prior Year Rate Retro'
END
ELSE
BEGIN
	SET @PRIOR_YEAR = 'NO'
	PRINT 'Current Year Rate Retro'
END


/*CR6127 - Prevent interface from being run for 2013 or greater*/
IF cast(@in_year as int) >= 2013
BEGIN
    SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
    SET @error_msg_placeholder1 = 'VERIFY YEAR IS LESS THAN'
    SET @error_msg_placeholder2 = '2013'
    GOTO BL_ERROR_HANDLER	
END



-- initialize local variables
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert'
SET @error_msg_placeholder2 = 'records into table temp table'
-- Defect_592_Begin
SET @total_LAB_CST_AMT = 0
-- Defect_592_End

/*
 * Validation of user's command line is done in XX_RETRORATE_RUN_INTERFACE_SP
 * by calling XX_RETRORATE_VALIDATE_USR_CMD_LINE_SP.
 */

-- if process date is not passed as parameter then the default is today's date
IF @in_process_date is null
   SET @in_process_date = CONVERT(CHAR(10), GETDATE(), 121)

-- if process year is not passed as parameter then the default is current year
IF @in_year is null
   SET @in_year = DATEPART(yyyy, GETDATE())

PRINT 'Validate GLC data ...'

-- Check if there are any rows in XX_GENL_LAB_CAT exists that does not have a rate delta
-- Process only if new GLC exists without rate_delta
SELECT @row_count = COUNT(*)
  from dbo.XX_GENL_LAB_CAT
 where RATE_DELTA is null

IF @row_count = 0
   BEGIN
      SET @SQLServer_error_code = @@ERROR
      IF @SQLServer_error_code <> 0
         BEGIN
            SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
            SET @error_msg_placeholder1 = 'Process'
            SET @error_msg_placeholder2 = 'New GLC rates are not available, please load the GLC rate file first'
            GOTO BL_ERROR_HANDLER	
         END
   END



/* CR993 -  prior year rate changes */
SELECT @row_count = COUNT(1)
  from IMAPS.DELTEK.TS_HDR
 where POST_SEQ_NO is null

IF @row_count <> 0
   BEGIN
      SET @SQLServer_error_code = @@ERROR
      IF @SQLServer_error_code <> 0
         BEGIN
            SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
            SET @error_msg_placeholder1 = 'VERIFY'
            SET @error_msg_placeholder2 = 'ALL TIMESHEETS ARE POSTED'
            GOTO BL_ERROR_HANDLER	
         END
   END




-- GLC Delta Rate Calculation
-- BEGIN CHANGE TEJAS PATEL 02/23/2006
SELECT DISTINCT genl_lab_cat_cd,
 (SELECT (genl_avg_rt_amt) FROM dbo.xx_genl_lab_cat glc
 WHERE genl_lab_cat_cd= xglc.genl_lab_cat_cd
 and time_stamp=(SELECT MAX(time_stamp) FROM dbo.xx_genl_lab_cat
     WHERE genl_lab_cat_cd=xglc.genl_lab_cat_cd
    AND time_stamp<>(SELECT MAX(time_stamp) FROM dbo.xx_genl_lab_cat 
       WHERE genl_lab_cat_cd=glc.genl_lab_cat_cd))) old_rate,
 (SELECT (genl_avg_rt_amt) FROM dbo.xx_genl_lab_cat glc
 WHERE genl_lab_cat_cd= xglc.genl_lab_cat_cd
 and time_stamp=(SELECT MAX(time_stamp) FROM dbo.xx_genl_lab_cat
     WHERE genl_lab_cat_cd=xglc.genl_lab_cat_cd
     AND genl_lab_cat_cd=glc.genl_lab_cat_cd)) new_rate,
 ((SELECT (genl_avg_rt_amt) FROM dbo.xx_genl_lab_cat glc
 WHERE genl_lab_cat_cd= xglc.genl_lab_cat_cd
 and time_stamp=(SELECT MAX(time_stamp) FROM dbo.xx_genl_lab_cat
     WHERE genl_lab_cat_cd=xglc.genl_lab_cat_cd
     AND genl_lab_cat_cd=glc.genl_lab_cat_cd))-
 (SELECT (genl_avg_rt_amt) FROM dbo.xx_genl_lab_cat
 WHERE genl_lab_cat_cd= xglc.genl_lab_cat_cd
 and time_stamp=(
     SELECT MAX(time_stamp) FROM dbo.xx_genl_lab_cat  glc 
     WHERE genl_lab_cat_cd=xglc.genl_lab_cat_cd
    AND time_stamp<>(SELECT MAX(time_stamp) FROM dbo.xx_genl_lab_cat 
       WHERE genl_lab_cat_cd=glc.genl_lab_cat_cd)))) rate_delta
 INTO #xx_genl_lab_cat_temp
 FROM dbo.xx_genl_lab_cat xglc
 WHERE  (SELECT max(genl_avg_rt_amt) FROM dbo.xx_genl_lab_cat
  WHERE time_stamp=(
     SELECT MAX(time_stamp) FROM dbo.xx_genl_lab_cat  glc 
     WHERE genl_lab_cat_cd=xglc.genl_lab_cat_cd
    AND time_stamp<>(SELECT MAX(time_stamp) FROM dbo.xx_genl_lab_cat 
       WHERE genl_lab_cat_cd=glc.genl_lab_cat_cd))) IS NOT NULL
-- END CHANGE TEJAS PATEL 02/23/2006

   SET @SQLServer_error_code = @@ERROR

-- 02/23/2006 Change begin
        IF @SQLServer_error_code <> 0
           BEGIN
              SET @IMAPS_error_number = 100 -- Attempt to %1 %2 failed.
              SET @error_msg_placeholder1 = 'insert'
              SET @error_msg_placeholder2 = 'records into temporary table #XX_GENL_LAB_CAT_TEMP'
              GOTO BL_ERROR_HANDLER
           END
-- 02/23/2006 Change end

	
	UPDATE dbo.xx_genl_lab_cat 
	SET rate_delta= (SELECT rate_delta FROM #xx_genl_lab_cat_temp glct
			WHERE xx_genl_lab_cat.genl_lab_cat_cd=glct.genl_lab_cat_cd)
	WHERE genl_lab_cat_cd IN (SELECT DISTINCT genl_lab_cat_cd FROM #xx_genl_lab_cat_temp)
	      AND time_stamp=(SELECT MAX(glc1.time_stamp) 
					FROM dbo.xx_genl_lab_cat glc1
					WHERE xx_genl_lab_cat.genl_lab_cat_cd=glc1.genl_lab_cat_cd)
SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'records to XX_GENL_LAB_CAT'
      GOTO BL_ERROR_HANDLER
   END

PRINT 'Update table XX_GENL_LAB_CAT with rate delta ...'

DROP TABLE #xx_genl_lab_cat_temp



/* CR993 -  prior year rate changes */
IF @PRIOR_YEAR = 'NO'
BEGIN

	--We don't really care about the rate_delta anymore
	--Getting rid of it allows easy addition of GLCs (no refresh of XX_GENL_LAB_CAT)
	--Also added filter for fiscal year and time_stamp update

	UPDATE imaps.deltek.genl_lab_cat
		SET time_stamp = current_timestamp,
			genl_avg_rt_amt= (SELECT genl_avg_rt_amt
					FROM dbo.xx_genl_lab_cat 
					WHERE imaps.deltek.genl_lab_cat.genl_lab_cat_cd=genl_lab_cat_cd
					and imaps.deltek.genl_lab_cat.genl_avg_rt_amt<>genl_avg_rt_amt
					AND time_stamp=(SELECT MAX(time_stamp) 
							FROM dbo.xx_genl_lab_cat 
							WHERE genl_lab_cat_cd=imaps.deltek.genl_lab_cat.genl_lab_cat_cd
							AND fy_cd = @in_YEAR)
					--AND rate_delta<>0)
					AND fy_cd = @in_YEAR)
		where 
		--05/06/2008 COMPANY_ID
		company_id = @COMPANY_ID
		and
		genl_lab_cat_cd in (SELECT genl_lab_cat_cd
					FROM dbo.xx_genl_lab_cat 
					WHERE imaps.deltek.genl_lab_cat.genl_lab_cat_cd=genl_lab_cat_cd
					and imaps.deltek.genl_lab_cat.genl_avg_rt_amt<>genl_avg_rt_amt
					AND time_stamp=(SELECT MAX(time_stamp) 
							FROM dbo.xx_genl_lab_cat 
							WHERE genl_lab_cat_cd=imaps.deltek.genl_lab_cat.genl_lab_cat_cd
							AND fy_cd = @in_YEAR)
					--AND rate_delta<>0)					
					AND fy_cd = @in_YEAR)

	SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

	IF @SQLServer_error_code <> 0
		BEGIN
		   SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
		   SET @error_msg_placeholder1 = 'update'
		   SET @error_msg_placeholder2 = 'table IMAPS.Deltek.GENL_LAB_CAT with new rates'
		   GOTO BL_ERROR_HANDLER
		END

	IF @row_count > 0
	   PRINT 'Note: Costpoint table GENL_LAB_CAT was updated.'


END
IF @PRIOR_YEAR = 'YES'
BEGIN

		UPDATE imapsstg.dbo.xx_past_genl_lab_cat
		SET genl_avg_rt_amt= (SELECT genl_avg_rt_amt
					FROM dbo.xx_genl_lab_cat 
					WHERE imapsstg.dbo.xx_past_genl_lab_cat.genl_lab_cat_cd=genl_lab_cat_cd
					and imapsstg.dbo.xx_past_genl_lab_cat.genl_avg_rt_amt<>genl_avg_rt_amt
					AND time_stamp=(SELECT MAX(time_stamp) 
							FROM dbo.xx_genl_lab_cat 
							WHERE genl_lab_cat_cd=imapsstg.dbo.xx_past_genl_lab_cat.genl_lab_cat_cd
							AND fy_cd = @in_YEAR)
					--AND rate_delta<>0)
					AND fy_cd = @in_YEAR)
		where 
		/*CR1541 - NonZero Pay Types - Standby*/
		fy_cd = @in_YEAR
		and
		genl_lab_cat_cd in (SELECT genl_lab_cat_cd
					FROM dbo.xx_genl_lab_cat 
					WHERE imapsstg.dbo.xx_past_genl_lab_cat.genl_lab_cat_cd=genl_lab_cat_cd
					and imapsstg.dbo.xx_past_genl_lab_cat.genl_avg_rt_amt<>genl_avg_rt_amt
					AND time_stamp=(SELECT MAX(time_stamp) 
							FROM dbo.xx_genl_lab_cat 
							WHERE genl_lab_cat_cd=imapsstg.dbo.xx_past_genl_lab_cat.genl_lab_cat_cd
							AND fy_cd = @in_YEAR)
					--AND rate_delta<>0)					
					AND fy_cd = @in_YEAR)

	SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

	IF @SQLServer_error_code <> 0
		BEGIN
		   SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
		   SET @error_msg_placeholder1 = 'update'
		   SET @error_msg_placeholder2 = 'table XX_PAST_GENL_LAB_CAT with new rates'
		   GOTO BL_ERROR_HANDLER
		END

	IF @row_count > 0
	   PRINT 'Note: Stagin table XX_PAST_GENL_LAB_CAT was updated.'

END



/* CR993 -  prior year rate changes */
IF @PRIOR_YEAR = 'NO'
BEGIN
	PRINT 'Update Costpoint table EMPL_LAB_INFO directly with GLC rate ...'

		-- empl_lab_info table
		UPDATE imaps.deltek.empl_lab_info
		SET hrly_amt= glc.genl_avg_rt_amt,
			sal_amt = glc.genl_avg_rt_amt * (work_yr_hrs_no/52.0),
			annl_amt= glc.genl_avg_rt_amt * work_yr_hrs_no
		FROM 
		imaps.deltek.empl e
		INNER JOIN
		imaps.deltek.empl_lab_info eli
		on
		(
			e.empl_id = eli.empl_id
			AND
			--05/06/2008 COMPANY_ID
			e.company_id = @COMPANY_ID
		)
		INNER JOIN
		imaps.deltek.genl_lab_cat glc
		on
		(
			eli.genl_lab_cat_cd = glc.genl_lab_cat_cd
			AND datepart(year,eli.effect_dt)=@in_year
		)

	SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

	IF @SQLServer_error_code <> 0
	   BEGIN
		  SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
		  SET @error_msg_placeholder1 = 'update'
		  SET @error_msg_placeholder2 = 'table IMAPS.Deltek.EMPL_LAB_INFO with new rates'
		  GOTO BL_ERROR_HANDLER
	   END

	IF @row_count > 0
	   PRINT 'Note: Costpoint table EMPL_LAB_INFO was updated.'

END
IF @PRIOR_YEAR = 'YES'
BEGIN
	PRINT 'Update Costpoint table EMPL_LAB_INFO directly with GLC rate ...'

		-- empl_lab_info table
		UPDATE imaps.deltek.empl_lab_info
		SET hrly_amt= glc.genl_avg_rt_amt,
			sal_amt = glc.genl_avg_rt_amt * (work_yr_hrs_no/52.0),
			annl_amt= glc.genl_avg_rt_amt * work_yr_hrs_no
		FROM 
		imaps.deltek.empl e
		INNER JOIN
		imaps.deltek.empl_lab_info eli
		on
		(
			e.empl_id = eli.empl_id
			AND
			--05/06/2008 COMPANY_ID
			e.company_id = @COMPANY_ID
		)
		INNER JOIN
		XX_PAST_GENL_LAB_CAT glc
		on
		(
			glc.fy_cd = @in_year
			and
			eli.genl_lab_cat_cd = glc.genl_lab_cat_cd
			and 
			datepart(year,eli.effect_dt)=@in_year
		)

	SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

	IF @SQLServer_error_code <> 0
	   BEGIN
		  SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
		  SET @error_msg_placeholder1 = 'update'
		  SET @error_msg_placeholder2 = 'table IMAPS.Deltek.EMPL_LAB_INFO with new rates'
		  GOTO BL_ERROR_HANDLER
	   END

	IF @row_count > 0
	   PRINT 'Note: Costpoint table EMPL_LAB_INFO was updated.'	
END 




PRINT 'Archive retro rate cost change from previous interface run ...'

-- Move data from retro rate stage table to arc table
	INSERT INTO dbo.XX_RATE_RETRO_TS_PREP_ARC
	 (ts_dt,
	  empl_id,
	  s_ts_type_cd,
	  work_state_cd,
	  fy_cd,
	  pd_no,
	  sub_pd_no,
	  correcting_ref_dt,
	  pay_type,
	  org_id,
	  acct_id,
	  lab_cst_amt,
	  chg_hrs,
	  --entered_hrs,
	  --rate,
	  lab_loc_cd,
	  work_comp_cd,
	  proj_id,
	  bill_lab_cat_cd,
	  genl_lab_cat_cd,
	  s_ts_ln_type_cd,
	  effect_bill_dt
	  --time_stamp
	  )
	SELECT 	ts_dt,
	  empl_id,
	  s_ts_type_cd,
	  work_state_cd,
	  fy_cd,
	  pd_no,
	  sub_pd_no,
	  correcting_ref_dt,
	  pay_type,
	  org_id,
	  acct_id,
	  lab_cst_amt,
	  chg_hrs,
	  --entered_hrs,
	  --rate,
	  lab_loc_cd,
	  work_comp_cd,
	  proj_id,
	  bill_lab_cat_cd,
	  genl_lab_cat_cd,
	  s_ts_ln_type_cd,
	  effect_bill_dt
	  --time_stamp
	FROM dbo.XX_RATE_RETRO_TS_PREP_TEMP

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
      SET @error_msg_placeholder1 = 'Insert'
      SET @error_msg_placeholder2 = 'records to XX_RATE_RETRO_TS_PREP_ARC'
      GOTO BL_ERROR_HANDLER
   END

TRUNCATE TABLE dbo.XX_RATE_RETRO_TS_PREP_TEMP
TRUNCATE TABLE dbo.XX_RATE_RETRO_TS_PREP_ERRORS

PRINT 'Retrieve data from Costpoint ...'


/* CR993 -  prior year rate changes */
IF @PRIOR_YEAR = 'NO'
BEGIN

	/*CR1541 - NonZero Pay Types - Standby*/
		--current year
		PRINT 'CURRENT YEAR'

		DECLARE pay_types CURSOR FAST_FORWARD FOR
		select non_zero_pay_type, retro_pay_type
		from xx_retrorate_pay_types


		--begin loop
		OPEN pay_types
		FETCH pay_types
		INTO  @non_zero_pay_type, @retro_pay_type
		WHILE (@@fetch_status = 0)
		BEGIN

			SELECT	@non_zero_pay_type_fctr_qty = pay_type_fctr_qty
			FROM	imaps.deltek.pay_type
			WHERE	pay_type = @non_zero_pay_type

			PRINT 'retro for pay type '+ @non_zero_pay_type + ',' + @retro_pay_type

			
			INSERT INTO dbo.XX_RATE_RETRO_TS_PREP_TEMP
			 (ts_dt,
			  empl_id,
			  s_ts_type_cd,
			  work_state_cd,
			  fy_cd,
			  pd_no,
			  sub_pd_no,
			  correcting_ref_dt,
			  pay_type,
			  org_id,
			  acct_id,
			  lab_cst_amt,
			  chg_hrs,
			  lab_loc_cd,
			  work_comp_cd,
			  proj_id,
			  bill_lab_cat_cd,
			  genl_lab_cat_cd,
			  s_ts_ln_type_cd,
			  effect_bill_dt,
				  NOTES
			  )
			SELECT
				 CONVERT(CHAR(10), getdate(),121) ts_dt,
				 thh.empl_id,
				 'C' s_ts_type_cd,
				 'VA' work_state_cd,
				 datepart(YYYY,getdate()) fy_cd,
				 datepart(MONTH,getdate()) pd_no,
				 sub_pd_no= CASE 
	   					WHEN datepart(d,getdate())>=1 AND datepart(d,getdate())<=15 THEN 2
	  					ELSE 3
					   END,
				 CONVERT(CHAR(10), getdate(),121) corecting_ref_dt,
				 @retro_pay_type pay_type,
				 org_id,
				 tlh.acct_id,
				 sum(ROUND(tlh.chg_hrs * glc1.genl_avg_rt_amt * @non_zero_pay_type_fctr_qty, 2)) - sum(tlh.lab_cst_amt) lab_cst_amt_total,
				 0 chg_hrs,
				 'NONE' lab_loc_cd,
				 'NONE' work_comp_cd,
				 tlh.proj_id,
				 tlh.bill_lab_cat_cd,
				 tlh.genl_lab_cat_cd,
				 'A' s_ts_ln_type_cd,
				 CONVERT(CHAR(10), getdate(),121) effect_bill_dt,
					 CAST(@in_STATUS_RECORD_NUM as varchar)  notes
				 FROM 
				imaps.deltek.ts_ln_hs tlh
				inner join
				imaps.deltek.ts_hdr_hs thh
				on
				(
						--05/06/2008 COMPANY_ID
						thh.company_id = @COMPANY_ID
				AND		thh.ts_dt=tlh.ts_dt 
				AND 	thh.empl_id=tlh.empl_id
				AND 	thh.s_ts_type_cd=tlh.s_ts_type_cd
				AND 	thh.ts_hdr_seq_no=tlh.ts_hdr_seq_no
				AND		tlh.pay_type in (@non_zero_pay_type, @retro_pay_type)
				AND 	thh.fy_cd = @in_year
				AND		NOT(tlh.effect_bill_dt in ('2012-12-29','2012-12-30','2012-12-31') and tlh.pay_type in ('R','STB','STW'))  --CR6127 - Prevent work dates 12/29-12/31 from being included
				)
				inner join
				imaps.deltek.genl_lab_cat glc1
				on
				(	
					--05/06/2008 COMPANY_ID
					glc1.company_id = @COMPANY_ID
					AND
					glc1.genl_lab_cat_cd=tlh.genl_lab_cat_cd
				)
				GROUP BY thh.empl_id, thh.fy_cd, tlh.acct_id, tlh.proj_id, tlh.bill_lab_cat_cd, tlh.genl_lab_cat_cd, org_id
				HAVING sum(ROUND(tlh.chg_hrs * glc1.genl_avg_rt_amt * @non_zero_pay_type_fctr_qty, 2)) <> sum(tlh.lab_cst_amt)


		FETCH pay_types
		INTO  @non_zero_pay_type, @retro_pay_type
		END
		CLOSE pay_types
		DEALLOCATE pay_types
	
	SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

	IF @SQLServer_error_code <> 0
	   BEGIN
		  SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
		  SET @error_msg_placeholder1 = 'Insert'
		  SET @error_msg_placeholder2 = 'records to XX_RATE_RETRO_TS_PREP_TEMP'
		  GOTO BL_ERROR_HANDLER
	   END
END
/* CR993 -  prior year rate changes */
IF @PRIOR_YEAR = 'YES'
BEGIN
	
	/*CR1541 - NonZero Pay Types - Standby*/
	--prior year
	PRINT 'Prior Year'

	DECLARE pay_types CURSOR FAST_FORWARD FOR
	select non_zero_pay_type, retro_pay_type
	from xx_retrorate_pay_types

	--begin loop
	OPEN pay_types
	FETCH pay_types
	INTO  @non_zero_pay_type, @retro_pay_type
	WHILE (@@fetch_status = 0)
	BEGIN

		SELECT	@non_zero_pay_type_fctr_qty = pay_type_fctr_qty
		FROM	imaps.deltek.pay_type
		WHERE	pay_type = @non_zero_pay_type

		PRINT 'retro for pay type '+ @non_zero_pay_type + ',' + @retro_pay_type

		INSERT INTO dbo.XX_RATE_RETRO_TS_PREP_TEMP
			 (ts_dt,
			  empl_id,
			  s_ts_type_cd,
			  work_state_cd,
			  fy_cd,
			  pd_no,
			  sub_pd_no,
			  correcting_ref_dt,
			  pay_type,
			  org_id,
			  acct_id,
			  lab_cst_amt,
			  chg_hrs,
			  lab_loc_cd,
			  work_comp_cd,
			  proj_id,
			  bill_lab_cat_cd,
			  genl_lab_cat_cd,
			  s_ts_ln_type_cd,
			  effect_bill_dt,
				  NOTES
			  )
		SELECT
			 CONVERT(CHAR(10), getdate(),121) ts_dt,
			 thh.empl_id,
			 'C' s_ts_type_cd,
			 'VA' work_state_cd,
			 @in_year fy_cd,
			 13 pd_no,
			 1 sub_pd_no,
			 @in_year+'-12-31' corecting_ref_dt,
			 @retro_pay_type pay_type,
			 org_id,
			 tlh.acct_id,
			 sum(ROUND(tlh.chg_hrs * glc1.genl_avg_rt_amt * @non_zero_pay_type_fctr_qty, 2)) - sum(tlh.lab_cst_amt) lab_cst_amt_total,
			 0 chg_hrs,
			 'NONE' lab_loc_cd,
			 'NONE' work_comp_cd,
			 tlh.proj_id,
			 tlh.bill_lab_cat_cd,
			 tlh.genl_lab_cat_cd,
			 'A' s_ts_ln_type_cd,
			 @in_year+'-12-31' effect_bill_dt,
				 CAST(@in_STATUS_RECORD_NUM as varchar)  notes
			 FROM 
			imaps.deltek.ts_ln_hs tlh
			inner join
			imaps.deltek.ts_hdr_hs thh
			on
			(
					--05/06/2008 COMPANY_ID
					thh.company_id = @COMPANY_ID
			AND		thh.ts_dt=tlh.ts_dt 
			AND 	thh.empl_id=tlh.empl_id
			AND 	thh.s_ts_type_cd=tlh.s_ts_type_cd
			AND 	thh.ts_hdr_seq_no=tlh.ts_hdr_seq_no
			AND		tlh.pay_type in (@non_zero_pay_type, @retro_pay_type)
			AND 	thh.fy_cd = @in_year
			AND		NOT(tlh.effect_bill_dt in ('2012-12-29','2012-12-30','2012-12-31') and tlh.pay_type in ('R','STB','STW'))  --CR6127 - Prevent work dates 12/29-12/31 from being included
			)
			inner join
			xx_past_genl_lab_cat glc1
			on
			(
				glc1.fy_cd = @in_year
				and
				glc1.genl_lab_cat_cd=tlh.genl_lab_cat_cd
			)
			GROUP BY thh.empl_id, thh.fy_cd, tlh.acct_id, tlh.proj_id, tlh.bill_lab_cat_cd, tlh.genl_lab_cat_cd, org_id
			HAVING sum(ROUND(tlh.chg_hrs * glc1.genl_avg_rt_amt * @non_zero_pay_type_fctr_qty, 2)) <> sum(tlh.lab_cst_amt)


	FETCH pay_types
	INTO  @non_zero_pay_type, @retro_pay_type
	END
	CLOSE pay_types
	DEALLOCATE pay_types


	SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

	IF @SQLServer_error_code <> 0
	   BEGIN
		  SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
		  SET @error_msg_placeholder1 = 'Insert'
		  SET @error_msg_placeholder2 = 'records to XX_RATE_RETRO_TS_PREP_TEMP'
		  GOTO BL_ERROR_HANDLER
	   END


	--delete where project is not cost type?
END



--6/23/2008 change
SELECT @row_count = count(1)
FROM XX_RATE_RETRO_TS_PREP_TEMP


IF @row_count = 0
   /*
    * If XX_RATE_RETRO_TS_PREP_TEMP is empty, is it necessary to perform the rest of the program?
    * Table XX_GENL_LAB_CAT always has data populated from previous interface runs.
    */
   PRINT 'No rate change data exist to continue ...'

-- Defect_592_Begin
ELSE
   BEGIN
      -- update the XX_IMAPS_INT_STATUS record with processing statistics

      SELECT @total_LAB_CST_AMT = SUM(CONVERT(decimal(14, 2), ISNULL(LAB_CST_AMT, 0)))
        FROM dbo.XX_RATE_RETRO_TS_PREP_TEMP

      /*
       * "trailer record" column RECORD_COUNT_TRAILER refers to the footer record of the input file
       * supplied by the eT&E system which is not applicable here
       */
      UPDATE dbo.XX_IMAPS_INT_STATUS
         SET RECORD_COUNT_INITIAL = @row_count, -- total records resulting from populating timesheet preprocessor table XX_RATE_RETRO_TS_PREP_TEMP
             AMOUNT_INPUT = ISNULL(@total_LAB_CST_AMT, 0),
             MODIFIED_BY = SUSER_SNAME(),
             MODIFIED_DATE = GETDATE()
       WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

       SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

       IF @SQLServer_error_code <> 0
         BEGIN
            SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
            SET @error_msg_placeholder1 = 'update'
            SET @error_msg_placeholder2 = 'a XX_IMAPS_INT_STATUS record with processing totals'
            GOTO BL_ERROR_HANDLER
         END
   END
-- Defect_592_End






--begin change KM 5/03/2006
--ERROR PROCESSING REQUIRES
--NOTES FIELD TO BE DISTINCT
UPDATE dbo.XX_RATE_RETRO_TS_PREP_TEMP
SET NOTES = (
		CAST(@in_STATUS_RECORD_NUM as varchar)
+ '-' + RTRIM(EMPL_ID) + '-' + RTRIM(FY_CD) + '-' + RTRIM(ACCT_ID)
+ '-' + RTRIM(PROJ_ID) + '-' + RTRIM(BILL_LAB_CAT_CD) + '-' + RTRIM(GENL_LAB_CAT_CD)
+ '-' + RTRIM(ORG_ID) )


SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
    BEGIN
       SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
       SET @error_msg_placeholder1 = 'update notes column in'
       SET @error_msg_placeholder2 = 'table XX_RATE_RETRO_TS_PREP_TEMP'
       GOTO BL_ERROR_HANDLER
    END
--end change KM 5/03/2006




RETURN(0)

BL_ERROR_HANDLER:

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_number,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_placeholder_value3   = NULL,
   @in_display_requested    = 1,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)

END


SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_CERIS_PROCESS_RETRO_RATE_SP    Script Date: 1/3/2006 4:13:26 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_PROCESS_RETRO_RATE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_CERIS_PROCESS_RETRO_RATE_SP]
GO



CREATE PROCEDURE dbo.XX_CERIS_PROCESS_RETRO_RATE_SP
(
@in_YEAR CHAR(4),
@in_process_date CHAR(10),
@out_SQLServer_error_code INTEGER      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   VARCHAR(275) = NULL OUTPUT
)
AS

/************************************************************************************************  
Name:       	XX_CERIS_PROCESS_RETRO_RATE_SP
Author:     	KM
Created:    	10/2005  
Purpose:    	Process the retroactive timesheet data.
                Called by XX_CERIS_RUN_INTERFACE_SP.
The plan

Stored Procedures - Writes in to :
			- xx_genl_lab_Cat
			- xx_rate_retro_ts_prep
			- xx_rate_retro_ts_prep_arc
		    Reads from:
			- imaps.deltek.ts_ln_hs tlh
			- imaps.deltek.ts_hdr_hs thh
		    Updates to:
			- imaps.deltek.empl_lab_info (hrly_amt column)
			- imaps.deltek.genl_lab_cat (genl_avg_rt_amt column)

Notes:      Examples of stored procedure call follow.
		(1).
		Execute xx_ceris_process_retro_rate_sp 
			@in_YEAR='2006',
			@in_process_date = '01-03-2006' -- Process Date
		(2).
		Execute xx_ceris_process_retro_rate_sp 
			@in_YEAR='2005',
			@in_process_date = null

*************************************************************************************************/

BEGIN
PRINT 'Process Stage - Prepare retroactive rate timesheet data (conditional) ...'


DECLARE @PROCESSED_FL           CHAR(1),
	@TO_PROCESS		CHAR(1),
	@PROCESS_DT             CHAR(10),
	@S_TS_TYPE_CD 		CHAR(2),
    	@SP_NAME                 sysname,
	@IMAPS_error_number      INTEGER,
	@SQLServer_error_code    INTEGER,
	@row_count               INTEGER,
	@row_count2		 INTEGER,
	@error_msg_placeholder1  sysname,
	@error_msg_placeholder2  sysname

--BEGIN Transaction

	-- set local constants
	SET @SQLServer_error_code=0
	SET @SP_NAME = 'XX_CERIS_PROCESS_RETRO_RATE_SP'
	-- initialize local variables
	SET @IMAPS_error_number = 100 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'insert'
	SET @error_msg_placeholder2 = 'records into table XX_CERIS_RETRO_TS_PREP'
	-- if process date is not passed as parameter then the default is today's date
	IF @in_process_date is null
		SET @in_process_date=CONVERT(CHAR(10),getdate(),121)
	-- if process year is not passed as parameter then the default is current year
	IF @in_year is null
		SET @in_year=datepart(yyyy,getdate())

	PRINT 'Process Year -> '+@in_year+' '+'Process Date ->'+ @in_process_date

	SET @process_dt=@in_process_date
	set @to_process='Y'
	SET @S_TS_TYPE_CD = 'RO'
	select @row_count=0
	-- Check if process date is not in sub_pd
	SELECT @row_count=COUNT(*)
	from imaps.deltek.sub_pd
	where sub_pd_end_dt=@process_dt


	-- Check if there are multiple rows exist in the xx_genl_lab_cat table with blank rate_delta
	select @row_count2=0
	select distinct @row_count2= count(genl_lab_cat_cd)
	from dbo.xx_genl_lab_cat
	where rate_delta is null
	group by genl_lab_cat_cd
	having count(genl_lab_cat_cd)>1

	-- Add February
	-- Process date can not be on 1, 15, 16, 31 of the month
	IF datepart(d,@process_dt) NOT IN (1,15,16,31) 
	   SET @to_process='Y'
	   
	-- Process date can not be on 30th
	ELSE IF @row_count=0
	   set @to_process='Y'
	   
	ELSE IF datepart(d, DATEADD(DAY,-1,DATEADD(MONTH,1,(DATEADD(DAY,-DAY(@process_dt)+1,@process_dt)))))<>30
	   SET @to_process='Y'
	   
	-- Process date can not be Friday
	ELSE IF datepart(dw,@process_dt)<>6
	   SET @to_process='Y'   

	-- Process date should be the future date of not more than 4 days 
	ELSE IF CONVERT(datetime,@in_process_date)>=getdate() AND CONVERT(datetime,@in_process_date)<=getdate()+4
	   SET @to_process='Y'
	-- Process only if there are single rows per GLC code exists in GLC table with blank rate_delta
	ELSE IF @row_count2= 0
	   SET @to_process='Y'
	ELSE
	  begin
	   SET @to_process='N'
		SET @SQLServer_error_code = 100
		SET @IMAPS_error_number = 100 -- Attempt to %1 %2 failed.
		SET @error_msg_placeholder1 = 'Process'
		SET @error_msg_placeholder2 = 'The Date you entered is invalid. Date can not be 1,15,16,31, Last day of month,Friday.'
		Print 'The Date you entered is invalid. Date can not be 1,15,16,31, Last day of month,Friday.'
		Print 'or there is nothing to process in genl_lab_cat table'
        	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER	
	   end
  -- Start the processing if all checks are passed (to_process is Y)
  IF @to_process='Y'
	PRINT 'Validations completed- Starting the process'
    BEGIN

	-- Check if there are any rows in xx_genl_lab_cat exists that does not have a rate delta
	-- Process only if new GLC exists without rate_delta
	SELECT @row_count=COUNT(*)
	from xx_genl_lab_cat
	where rate_delta is null

	   IF @row_count=0
		begin
		 SET @to_process='N'
		 SET @SQLServer_error_code = @@error
		 SET @IMAPS_error_number = 100 -- Attempt to %1 %2 failed.
		 SET @error_msg_placeholder1 = 'Process'
		 SET @error_msg_placeholder2 = 'New GLC rates are not available, please load the GLC rate file first'
        	 IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER	
		end
	/*
	update xx_genl_lab_cat
	set rate_delta=0
	where rate_delta=10

	*/

	-- GLC Delta Rate Calculation
	SELECT DISTINCT genl_lab_cat_cd,
	(SELECT genl_avg_rt_amt FROM dbo.xx_genl_lab_cat
	WHERE time_stamp=(
			  SELECT MAX(time_stamp) FROM dbo.xx_genl_lab_cat  glc 
			  WHERE genl_lab_cat_cd=xglc.genl_lab_cat_cd
				AND time_stamp<>(SELECT MAX(time_stamp) FROM dbo.xx_genl_lab_cat 
						 WHERE genl_lab_cat_cd=glc.genl_lab_cat_cd))) old_rate,
	(SELECT genl_avg_rt_amt FROM dbo.xx_genl_lab_cat glc
	WHERE time_stamp=(SELECT MAX(time_stamp) FROM dbo.xx_genl_lab_cat
			  WHERE genl_lab_cat_cd=xglc.genl_lab_cat_cd
			  AND genl_lab_cat_cd=glc.genl_lab_cat_cd)) new_rate,
	((SELECT genl_avg_rt_amt FROM dbo.xx_genl_lab_cat glc
	WHERE time_stamp=(SELECT MAX(time_stamp) FROM dbo.xx_genl_lab_cat
			  WHERE genl_lab_cat_cd=xglc.genl_lab_cat_cd
			  AND genl_lab_cat_cd=glc.genl_lab_cat_cd))-
	(SELECT genl_avg_rt_amt FROM dbo.xx_genl_lab_cat
	WHERE time_stamp=(
			  SELECT MAX(time_stamp) FROM dbo.xx_genl_lab_cat  glc 
			  WHERE genl_lab_cat_cd=xglc.genl_lab_cat_cd
				AND time_stamp<>(SELECT MAX(time_stamp) FROM dbo.xx_genl_lab_cat 
						 WHERE genl_lab_cat_cd=glc.genl_lab_cat_cd)))) rate_delta
	INTO #xx_genl_lab_cat_temp
	FROM dbo.xx_genl_lab_cat xglc
	WHERE  (SELECT genl_avg_rt_amt FROM dbo.xx_genl_lab_cat
		WHERE time_stamp=(
			  SELECT MAX(time_stamp) FROM dbo.xx_genl_lab_cat  glc 
			  WHERE genl_lab_cat_cd=xglc.genl_lab_cat_cd
				AND time_stamp<>(SELECT MAX(time_stamp) FROM dbo.xx_genl_lab_cat 
						 WHERE genl_lab_cat_cd=glc.genl_lab_cat_cd))) IS NOT NULL;
        SET @SQLServer_error_code = @@ERROR
        IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER
	
	UPDATE dbo.xx_genl_lab_cat 
	SET rate_delta= (SELECT rate_delta FROM #xx_genl_lab_cat_temp glct
			WHERE xx_genl_lab_cat.genl_lab_cat_cd=glct.genl_lab_cat_cd)
	WHERE genl_lab_cat_cd IN (SELECT DISTINCT genl_lab_cat_cd FROM #xx_genl_lab_cat_temp)
	      AND time_stamp=(SELECT MAX(glc1.time_stamp) 
					FROM dbo.xx_genl_lab_cat glc1
					WHERE xx_genl_lab_cat.genl_lab_cat_cd=glc1.genl_lab_cat_cd)
	SET @SQLServer_error_code = @@ERROR
	SET @IMAPS_error_number = 100 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'Update'
	SET @error_msg_placeholder2 = 'records to XX_GENL_LAB_CAT'
	IF @SQLServer_error_code = 0 
	   PRINT 'XX_GENL_LAB_CAT table updated with rate delta'
        IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER	

	DROP TABLE #xx_genl_lab_cat_temp
/*
	select count(distinct tlh.empl_id)
	 FROM imaps.deltek.ts_ln_hs tlh, imaps.deltek.ts_hdr_hs thh
	 WHERE tlh.ts_dt=thh.ts_dt 
		--and tlh.empl_id='0D8336'
		AND (fy_cd='2005'
			OR (datepart(YYYY,corecting_ref_dt)='2005' OR corecting_ref_dt IS NULL))
		AND pay_type='R'
		AND thh.empl_id=tlh.empl_id
		AND thh.s_ts_type_cd=tlh.s_ts_type_cd
		AND thh.ts_hdr_seq_no=tlh.ts_hdr_seq_no
		AND tlh.genl_lab_cat_cd IN (SELECT genl_lab_cat_cd FROM xx_genl_lab_cat glc1
						WHERE genl_lab_cat_cd=tlh.genl_lab_cat_cd 
						AND rate_delta<>0
						AND time_stamp=(SELECT MAX(time_stamp) 
								FROM xx_genl_lab_cat
								WHERE genl_lab_cat_cd=glc1.genl_lab_cat_cd))
	 GROUP BY thh.empl_id, thh.fy_cd, tlh.acct_id,
		tlh.proj_id, tlh.bill_lab_cat_cd, tlh.genl_lab_cat_cd
	 HAVING (SUM(tlh.chg_hrs)<>0 AND SUM(tlh.lab_cst_amt)<>0)
	   IF @row_count>0
		SET @to_process='N'
		SET @SQLServer_error_code = 100
		SET @IMAPS_error_number = 100 -- Attempt to %1 %2 failed.
		SET @error_msg_placeholder1 = 'Process'
		SET @error_msg_placeholder2 = 'New GLC rates are not available, please load the GLC rate file first'
        	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER	*/
--	   END


	-- Move data from retro rate stage table to arc table
	INSERT INTO dbo.xx_rate_retro_ts_prep_arc
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
	FROM dbo.xx_rate_retro_ts_prep_temp

		SET @SQLServer_error_code = @@ERROR
		SET @IMAPS_error_number = 100 -- Attempt to %1 %2 failed.
		SET @error_msg_placeholder1 = 'Insert'
		SET @error_msg_placeholder2 = 'records to xx_rate_retro_ts_prep_arc'
		IF @SQLServer_error_code = 0 
		   PRINT 'Inserted records to xx_rate_retro_ts_prep_arc'
	        IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER	


	--select * from xx_rate_retro_ts_prep_temp

	-- prepare retro rate stage table
	DELETE dbo.xx_rate_retro_ts_prep_temp

		SET @SQLServer_error_code = @@ERROR
		SET @IMAPS_error_number = 100 -- Attempt to %1 %2 failed.
		SET @error_msg_placeholder1 = 'Delete'
		SET @error_msg_placeholder2 = 'records from xx_rate_retro_ts_prep_temp'
		IF @SQLServer_error_code = 0 
		   PRINT 'Deleted records from xx_rate_retro_ts_prep_temp'
	        IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER	


	-- populate retro rate stage table
	INSERT INTO dbo.xx_rate_retro_ts_prep_temp
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
	  --Delta_rate,
	  lab_loc_cd,
	  work_comp_cd,
	  proj_id,
	  bill_lab_cat_cd,
	  genl_lab_cat_cd,
	  s_ts_ln_type_cd,
	  effect_bill_dt
	  --time_stamp
	  )
	-- select * from imaps.deltek.sub_pd
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
	 'RO' pay_type,
	 org_id,
	 tlh.acct_id,
	 (SUM(tlh.entered_hrs)*(SELECT rate_delta
		FROM dbo.xx_genl_lab_cat 
		WHERE genl_lab_cat_cd=tlh.genl_lab_cat_cd
		AND fy_cd=@in_year
		AND time_stamp=(SELECT MAX(time_stamp) 
				FROM imapsstg.dbo.xx_genl_lab_cat 
				WHERE genl_lab_cat_cd=tlh.genl_lab_cat_cd))) lab_cst_amt_total,
	 0 chg_hrs,
	 --SUM(tlh.entered_hrs)entered_hrs_total,
	 /*(SELECT rate_delta
		FROM imapsstg.dbo.xx_genl_lab_cat 
		WHERE genl_lab_cat_cd=tlh.genl_lab_cat_cd
		AND fy_cd='2005'
		AND time_stamp=(SELECT MAX(time_stamp) 
				FROM imapsstg.dbo.xx_genl_lab_cat 
				WHERE genl_lab_cat_cd=tlh.genl_lab_cat_cd)) rate,*/
	 'NONE' lab_loc_cd,
	 'NONE' work_comp_cd,
	 tlh.proj_id,
	 tlh.bill_lab_cat_cd,
	 tlh.genl_lab_cat_cd,
	 'A' s_ts_ln_type_cd,
	 --tlh.proj_abbrv_cd,
	 CONVERT(CHAR(10), getdate(),121) effect_bill_dt
	 --getdate() time_stamp
	 FROM imaps.deltek.ts_ln_hs tlh, imaps.deltek.ts_hdr_hs thh
	 WHERE tlh.ts_dt=thh.ts_dt 
		--and tlh.empl_id='0D8336'
		AND ((fy_cd=@in_year and thh.s_ts_type_cd='R')
			OR (datepart(YYYY,corecting_ref_dt)=@in_year and thh.s_ts_type_Cd='C'))
		AND pay_type='R'
		AND thh.empl_id=tlh.empl_id
		AND thh.s_ts_type_cd=tlh.s_ts_type_cd
		AND thh.ts_hdr_seq_no=tlh.ts_hdr_seq_no
		AND tlh.genl_lab_cat_cd IN (SELECT genl_lab_cat_cd FROM dbo.xx_genl_lab_cat glc1
						WHERE genl_lab_cat_cd=tlh.genl_lab_cat_cd 
						AND rate_delta<>0
						AND time_stamp=(SELECT MAX(time_stamp) 
								FROM xx_genl_lab_cat
								WHERE genl_lab_cat_cd=glc1.genl_lab_cat_cd))
	 GROUP BY thh.empl_id, thh.fy_cd, tlh.acct_id,
		tlh.proj_id, tlh.bill_lab_cat_cd, tlh.genl_lab_cat_cd, org_id
	 HAVING (SUM(tlh.chg_hrs)<>0 AND SUM(tlh.lab_cst_amt)<>0)

		SET @SQLServer_error_code = @@ERROR
		SET @IMAPS_error_number = 100 -- Attempt to %1 %2 failed.
		SET @error_msg_placeholder1 = 'Insert'
		SET @error_msg_placeholder2 = 'records to xx_rate_retro_ts_prep_temp'
		IF @SQLServer_error_code = 0 
		   PRINT 'Inserted records into xx_rate_retro_ts_prep_temp'
	        IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER	

	-- empl_lab_info table
	UPDATE imaps.deltek.empl_lab_info
	SET hrly_amt= (SELECT distinct genl_avg_rt_amt
				FROM dbo.xx_genl_lab_cat 
				WHERE imaps.deltek.empl_lab_info.genl_lab_cat_cd=dbo.xx_genl_lab_cat.genl_lab_cat_cd
				and dbo.xx_genl_lab_cat.genl_avg_rt_amt<>imaps.deltek.empl_lab_info.hrly_amt
				AND time_stamp=(SELECT MAX(time_stamp) 
						FROM dbo.xx_genl_lab_cat 
						WHERE genl_lab_cat_cd=imaps.deltek.empl_lab_info.genl_lab_cat_cd)
				AND rate_delta<>0
				and genl_avg_rt_amt is not null)
	where genl_lab_cat_cd in (SELECT distinct genl_lab_cat_cd
					FROM dbo.xx_genl_lab_cat
					WHERE imaps.deltek.empl_lab_info.genl_lab_cat_cd=dbo.xx_genl_lab_cat.genl_lab_cat_cd
					and dbo.xx_genl_lab_cat.genl_avg_rt_amt<>imaps.deltek.empl_lab_info.hrly_amt
					AND dbo.xx_genl_lab_cat.time_stamp=(SELECT MAX(time_stamp) 
							FROM dbo.xx_genl_lab_cat 
							WHERE genl_lab_cat_cd=imaps.deltek.empl_lab_info.genl_lab_cat_cd)
					AND rate_delta<>0)

		SET @SQLServer_error_code = @@ERROR
		SET @IMAPS_error_number = 100 -- Attempt to %1 %2 failed.
		SET @error_msg_placeholder1 = 'Update'
		SET @error_msg_placeholder2 = 'empl_lab_info table with new rates'
		IF @SQLServer_error_code = 0 
		   PRINT 'Updated GLC rate into empl_lab_info table'
	        IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER	

	UPDATE imaps.deltek.genl_lab_cat
	SET genl_avg_rt_amt= (SELECT genl_avg_rt_amt
				FROM dbo.xx_genl_lab_cat 
				WHERE imaps.deltek.genl_lab_cat.genl_lab_cat_cd=genl_lab_cat_cd
				and imaps.deltek.genl_lab_cat.genl_avg_rt_amt<>genl_avg_rt_amt
				AND time_stamp=(SELECT MAX(time_stamp) 
						FROM dbo.xx_genl_lab_cat 
						WHERE genl_lab_cat_cd=imaps.deltek.genl_lab_cat.genl_lab_cat_cd)
				AND rate_delta<>0)
	where genl_lab_cat_cd in (SELECT genl_lab_cat_cd
				FROM dbo.xx_genl_lab_cat 
				WHERE imaps.deltek.genl_lab_cat.genl_lab_cat_cd=genl_lab_cat_cd
				and imaps.deltek.genl_lab_cat.genl_avg_rt_amt<>genl_avg_rt_amt
				AND time_stamp=(SELECT MAX(time_stamp) 
						FROM dbo.xx_genl_lab_cat 
						WHERE genl_lab_cat_cd=imaps.deltek.genl_lab_cat.genl_lab_cat_cd)
				AND rate_delta<>0)


		SET @SQLServer_error_code = @@ERROR
		SET @IMAPS_error_number = 100 -- Attempt to %1 %2 failed.
		SET @error_msg_placeholder1 = 'Update'
		SET @error_msg_placeholder2 = 'genl_lab_cat table with new rates'
		IF @SQLServer_error_code = 0 
		   PRINT 'Updated GLC rate into genl_lab_cat table'
	        IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER	


	--select * from imaps.deltek.genl_lab_cat
--   COMMIT TRANSACTION	
  END
  RETURN(0)

  BL_ERROR_HANDLER:

  -- clean up
--  ROLLBACK TRANSACTION
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



GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


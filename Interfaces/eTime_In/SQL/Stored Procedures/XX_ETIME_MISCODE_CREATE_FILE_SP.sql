IF OBJECT_ID('dbo.XX_ETIME_MISCODE_CREATE_FILE_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_ETIME_MISCODE_CREATE_FILE_SP
    IF OBJECT_ID('dbo.XX_ETIME_MISCODE_CREATE_FILE_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_ETIME_MISCODE_CREATE_FILE_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_ETIME_MISCODE_CREATE_FILE_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go




CREATE PROCEDURE [dbo].[XX_ETIME_MISCODE_CREATE_FILE_SP] 
(
@FILE_TO_REPROCESS SYSNAME  --MAKE SURE THIS POINTS TO THE SERVER UNC PATH
)  
AS
 /************************************************************************************************
NAME:       XX_ETIME_MISCODE_CREATE_FILE_SP
AUTHOR:     KM
CREATED:    01/04/2007
PURPOSE:   STEP 1 OF ETIME MISCODE PROCESS 
Modified: 10/26/2007 CR-1253
Modified: 05/01/2008 CR-1543 For Company_id logic
Modified: 04/14/2009 DR-1631 For Miscode Feedback
Modified: 03/16/2011 CR-3617 For Eliminating shared ID issue	
Modified: 09/08/2012 CR-4886 for Actuals Implementation
Modified: 10/22/2012 CR-4886 for Actuals Implementation Comments removed
Modified: 12/13/2012 CR-4887 DEFALT Logic Added
Modified: 02/08/2013 CR-5968 Reverse Reclass Logic, Added TS_HDR_SEQ fix for D to R TS.
Modified: 01/22/2015 CR-6706 Fix "multiple correcting timesheets for same week" problem

PARAMETERS: 
	INPUT: @FILE_TO_REPROCESS -- IDENTIFIER OF CURRENT INTERFACE RUN
	OUTPUT:  THE FILE TO BE REPROCESSED
              
************************************************************************************************/

BEGIN
	
	--0. DECLARE VARIABLES
	DECLARE @CURRENTFY INT,
		@CURRENTPERIOD INT,
		@CURRENTSUBPERIOD INT,
		@FORMATFILE SYSNAME,
		@PASSWORD SYSNAME,
		@in_COMPANY_ID SYSNAME	-- Added CR-1543

	--IF CERIS, ETIME, OR RATERETRO IS RUNNING,
	--DON'T DO ANYTHING
	DECLARE @RET_CODE INT


	SELECT @RET_CODE = COUNT(1)
	FROM DBO.XX_IMAPS_INT_STATUS
	WHERE INTERFACE_NAME IN ('CERIS', 'ETIME', 'RATERETRO')
	AND STATUS_CODE NOT IN ('COMPLETED', 'SUCCESS_WITH_ERROR', 'DUPLICATE')
	IF @RET_CODE <> 0
	BEGIN 
		
		RAISERROR ('CERIS, ETIME, OR RATERETRO IS RUNNING', 16, 1) 
		GOTO BL_ERROR_HANDLER
	END


	/*DR1631*/
	SELECT @RET_CODE = COUNT(1)
	FROM XX_ERROR_STATUS
	WHERE INTERFACE='ETIME'
	AND CONTROL_PT<>7
	IF @RET_CODE <> 0
	BEGIN 
		
		RAISERROR ('PREVIOUS ETIME MISCODE RUN STILL NEEDS TO BE CLOSED OUT', 16, 1) 
		GOTO BL_ERROR_HANDLER
	END


	/*DR1631*/
	INSERT INTO XX_ERROR_STATUS
	(STATUS_RECORD_NUM, ERROR_SEQUENCE_NO, 
	 INTERFACE, PREPROCESSOR, 
	 STATUS, CONTROL_PT, 
	 TOTAL_COUNT, TOTAL_AMOUNT, 
	 SUCCESS_COUNT, SUCCESS_AMOUNT,
	 ERROR_COUNT, ERROR_AMOUNT,
	 TIME_STAMP)
	SELECT 
	etime.STATUS_RECORD_NUM_CREATED, 
	(select isnull( (max(error_sequence_no)+1), 0)
	 from xx_error_status
	 where 	status_record_num = etime.STATUS_RECORD_NUM_CREATED
	), 
	'ETIME', 'TS', 
	'PREPROCESSOR STARTED', 3, 
	COUNT(1), SUM(cast(etime.chg_hrs as decimal(14,2))),
	0, 0,
	0, 0,  
	CURRENT_TIMESTAMP
	FROM XX_IMAPS_TS_PREP_CONFIG_ERRORS etime
	WHERE
	STATUS_RECORD_NUM_REPROCESSED IS NULL
	GROUP BY etime.STATUS_RECORD_NUM_CREATED




	
	-- SET VARIABLES
	SET @CURRENTFY = DATEPART(YEAR, GETDATE())
	SET @CURRENTPERIOD = DATEPART(MONTH, GETDATE())
	SELECT @CURRENTSUBPERIOD = A.SUB_PD_NO 
		FROM IMAPS.DELTEK.SUB_PD A
		WHERE A.SUB_PD_END_DT =
		(SELECT MIN(B.SUB_PD_END_DT)
		 FROM  IMAPS.DELTEK.SUB_PD B
		       WHERE (B.SUB_PD_NO = 2 OR
			      B.SUB_PD_NO = 3) AND
		       DATEDIFF(DAY, GETDATE(), B.SUB_PD_END_DT) >= 0)
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


	/*DR1631*/
	/*update period to post here because we are getting rid of special cross-charging logic*/
	UPDATE XX_IMAPS_TS_PREP_CONFIG_ERRORS
	SET FY_CD = @CURRENTFY, 
	    PD_NO = @CURRENTPERIOD,
	    SUB_PD_NO = @CURRENTSUBPERIOD
	WHERE STATUS_RECORD_NUM_REPROCESSED IS NULL
	
	
	SELECT @FORMATFILE = PARAMETER_VALUE
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD = 'ETIME'
	AND PARAMETER_NAME = 'IN_PREP_FORMAT_FILENAME'
	
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	
	SELECT @PASSWORD = PARAMETER_VALUE
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD = 'ETIME'
	AND PARAMETER_NAME = 'IN_USER_PASSWORD'
	
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER
	
	-- Added CR-1543
	
	SELECT @in_COMPANY_ID = PARAMETER_VALUE
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD = 'ETIME'
	AND PARAMETER_NAME = 'COMPANY_ID'
	
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER
	
	
	--
	--1.  MARK RECORDS THAT WERE SUCCESSFULLY IMPORTED
	DECLARE @NEW_STATUS_RECORD_NUM INT
    DECLARE @NDR_NEW_STATUS_RECORD_NUM INT -- Added CR-4886

	PRINT '1A'
	SELECT @NEW_STATUS_RECORD_NUM  = 
	 CAST(DATEPART(YEAR, GETDATE()) AS VARCHAR) 
	+ RIGHT('0' + CAST(DATEPART(MONTH, GETDATE()) AS VARCHAR), 2)
	+ RIGHT('0' + CAST(DATEPART(DAY, GETDATE()) AS VARCHAR), 2)
	+ '0' --ADDED TO DISTINGUISH BETWEEN WHAT GOES THROUGH CP AND WHAT GOT ZEROED OUT

    --Added CR-4886
	SELECT @NDR_NEW_STATUS_RECORD_NUM  = 
	'8'+ CAST(DATEPART(YEAR, GETDATE()) AS VARCHAR) -- Added 888 to distinguish between regular rec and N Recs
	+ RIGHT('0' + CAST(DATEPART(MONTH, GETDATE()) AS VARCHAR), 2)
	+ RIGHT('0' + CAST(DATEPART(DAY, GETDATE()) AS VARCHAR), 2)



	UPDATE XX_IMAPS_TS_PREP_CONFIG_ERRORS
	SET STATUS_RECORD_NUM_REPROCESSED = @NEW_STATUS_RECORD_NUM,
		UPDATE_DT=current_timestamp /*DR1631*/
	FROM XX_IMAPS_TS_PREP_CONFIG_ERRORS
	WHERE 
	STATUS_RECORD_NUM_REPROCESSED IS NULL
	AND 
	RTRIM(EMPL_ID)+RTRIM(EFFECT_BILL_DT)+RTRIM(PROJ_ABBRV_CD)+RTRIM(BILL_LAB_CAT_CD) 
	IN
	(
		SELECT RTRIM(EMPL_ID)+RTRIM(EFFECT_BILL_DT)+RTRIM(PROJ_ABBRV_CD)+RTRIM(BILL_LAB_CAT_CD) 
		FROM XX_IMAPS_TS_PREP_CONFIG_ERRORS
		WHERE STATUS_RECORD_NUM_REPROCESSED IS NULL
		GROUP BY EMPL_ID, EFFECT_BILL_DT, PROJ_ABBRV_CD, BILL_LAB_CAT_CD
		HAVING  SUM(CAST(CHG_HRS AS DECIMAL(14,2))) = .00
	)	
    --Added CR-4886 
    --This way we will keep old logic for records prior to Actuals implementation
    --Goging forward we can not use this logic, if used then there are chances that a part of timecard can be marked processed.
	AND EFFECT_BILL_DT<	(SELECT  distinct parameter_value
							FROM xx_processing_parameters
							WHERE interface_name_cd='CERIS'
							AND UPPER(parameter_name)='ACTUALS_EFFECT_DT' )


	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

    --Begin CR-4886 Change
	-- If Previous regular TC is miscoded and PPA is available then mark R, N as processed
	update XX_IMAPS_TS_PREP_CONFIG_ERRORS
	set status_record_num_reprocessed=@NDR_NEW_STATUS_RECORD_NUM
	--select *
	FROM XX_IMAPS_TS_PREP_CONFIG_ERRORS 
	where 
	s_ts_type_cd in ('R','N')
	and	STATUS_RECORD_NUM_REPROCESSED IS NULL
	and	RTRIM(EMPL_ID)+RTRIM(EFFECT_BILL_DT)+RTRIM(PROJ_ABBRV_CD)+RTRIM(BILL_LAB_CAT_CD) 
		IN
		(
			SELECT RTRIM(ts.EMPL_ID)+RTRIM(ts.EFFECT_BILL_DT)+RTRIM(ts.PROJ_ABBRV_CD)+RTRIM(ts.BILL_LAB_CAT_CD) 
			FROM XX_IMAPS_TS_PREP_CONFIG_ERRORS ts
			WHERE s_ts_type_cd in ('R','N')
				and ts.STATUS_RECORD_NUM_REPROCESSED IS NULL
			GROUP BY ts.EMPL_ID, ts.EFFECT_BILL_DT, ts.PROJ_ABBRV_CD, ts.BILL_LAB_CAT_CD
			HAVING  SUM(CAST(CHG_HRS AS DECIMAL(14,2))) = .00
		)	

	-- Change D type TC to regular if Regular TC is available.
	-- Remove the -D from the notes field for convert notes to -R regular notes value
	update XX_IMAPS_TS_PREP_CONFIG_ERRORS
	set s_ts_type_cd='R' , notes=replace(notes, '-D','-R'),
		ts_dt=correcting_ref_dt, correcting_ref_dt=NULL,
        ts_hdr_seq_no=1         -- Added CR-5698 Fix HDR_SEQ error on miscode run
	FROM XX_IMAPS_TS_PREP_CONFIG_ERRORS
	where s_ts_type_cd in ('D')
	and	STATUS_RECORD_NUM_REPROCESSED IS NULL
	and	RTRIM(EMPL_ID)+CONVERT(char(10),(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(cast(EFFECT_BILL_DT as datetime))),120)
		IN
		(
			SELECT RTRIM(EMPL_ID)+CONVERT(char(10),(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(cast(EFFECT_BILL_DT as datetime))),120)
			FROM XX_IMAPS_TS_PREP_CONFIG_ERRORS 
			WHERE 
				s_ts_type_cd in ('R','N')
			and	STATUS_RECORD_NUM_REPROCESSED like '8%'
			GROUP BY EMPL_ID, EFFECT_BILL_DT, PROJ_ABBRV_CD, BILL_LAB_CAT_CD
			HAVING  SUM(CAST(CHG_HRS AS DECIMAL(14,2))) = .00
		)	

    --End CR-4886 Change

-- CR-6706_begin
    DECLARE @NEW_STATUS_RECORD_NUM_oldDnewN INT

    SELECT @NEW_STATUS_RECORD_NUM_oldDnewN = CAST(DATEPART(YEAR, GETDATE()) AS VARCHAR) 
                                             + RIGHT('0' + CAST(DATEPART(MONTH, GETDATE()) AS VARCHAR), 2)
                                             + RIGHT('0' + CAST(DATEPART(DAY, GETDATE()) AS VARCHAR), 2)
                                             + '0' -- ADDED TO DISTINGUISH BETWEEN WHAT GOES THROUGH CP AND WHAT GOT ZEROED OUT

	UPDATE dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS
	SET STATUS_RECORD_NUM_REPROCESSED = @NEW_STATUS_RECORD_NUM_oldDnewN --*net out indicator
	FROM dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS ts
	WHERE
	STATUS_RECORD_NUM_REPROCESSED is null
	AND
	0 <>
	(	-- subquery identifying N/D that net out
		SELECT count(1)
		FROM 
		dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS n
		inner join
		dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS d
		on
		(
			n.s_ts_type_cd = 'N'
			and
			d.s_ts_type_cd = 'D'
			and
			d.status_record_num_reprocessed is NULL
			and
			n.status_record_num_reprocessed is NULL
			and
			n.empl_id = d.empl_id
			and
			n.correcting_ref_dt = d.correcting_ref_dt
			and
			-- the D corresponds to the earliest D for this week
			d.status_record_num_created = (select min(status_record_num_created)
							from dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS
							where status_record_num_reprocessed is NULL
							  and empl_id = d.empl_id
							  and correcting_ref_dt = d.correcting_ref_dt
							  and s_ts_type_cd = 'D')
			and
			-- the N corresponds to the earliest N for this week that is after the D
			n.status_record_num_created = (select min(status_record_num_created)
							from dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS
							where status_record_num_reprocessed is NULL
							  and empl_id = n.empl_id
							  and correcting_ref_dt = n.correcting_ref_dt
							  and status_record_num_created > d.status_record_num_created --*IMPORTANT: new N reverses old D for net
							  and s_ts_type_cd = 'N')
			and
			-- there is an older N
			0 <> (select count(1)
					from dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS
					where status_record_num_reprocessed is NULL
					and empl_id = n.empl_id
					and correcting_ref_dt = n.correcting_ref_dt
					and s_ts_type_cd = 'N'
					and status_record_num_created < n.status_record_num_created)
			and
			-- there is a newer D
			0 <> (select count(1)
					from dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS
					where status_record_num_reprocessed is NULL
					and empl_id = d.empl_id
					and correcting_ref_dt = d.correcting_ref_dt
					and s_ts_type_cd = 'D'
					and status_record_num_created > d.status_record_num_created)
			-- All accounting elements are the same with hours reversed (sanity check)
			and
			n.proj_abbrv_cd = d.proj_abbrv_cd
			and
			n.bill_lab_cat_cd = d.bill_lab_cat_cd
			and
			n.effect_bill_dt = d.effect_bill_dt
			and
			cast(n.chg_hrs as decimal(14,2)) = -1.0 * cast(d.chg_hrs as decimal(14,2))
		)
		WHERE
		-- TS is the D
		(ts.status_record_num_created = d.status_record_num_created
		and
		ts.empl_id = d.empl_id
		and
		ts.ts_dt = d.ts_dt
		and
		ts.s_ts_type_cd = d.s_ts_type_cd
		and
		ts.ts_hdr_seq_no = d.ts_hdr_seq_no
		and
		ts.correcting_ref_dt = d.correcting_ref_dt
		)
		or
		-- TS is the N
		(ts.status_record_num_created = n.status_record_num_created
		and
		ts.empl_id = n.empl_id
		and
		ts.ts_dt = n.ts_dt
		and
		ts.s_ts_type_cd = n.s_ts_type_cd
		and
		ts.ts_hdr_seq_no = n.ts_hdr_seq_no
		and
		ts.correcting_ref_dt = n.correcting_ref_dt
		)
	)

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	-- Update TS_DT for old N type to be same as new D type
	UPDATE n
	SET n.ts_dt = d.ts_dt
	FROM
	dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS n
	inner join
	dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS d
	on
	(
		n.s_ts_type_cd = 'N'
		and
		d.s_ts_type_cd = 'D'
		and
		d.status_record_num_reprocessed is NULL
		and
		n.status_record_num_reprocessed is NULL
		and
		n.empl_id = d.empl_id
		and
		n.correcting_ref_dt = d.correcting_ref_dt
	)
	WHERE
	n.ts_dt <> d.ts_dt

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER
-- CR-6706_end


	PRINT '1'
	SELECT @NEW_STATUS_RECORD_NUM  = 
		 CAST(DATEPART(YEAR, GETDATE()) AS VARCHAR) 
		+ RIGHT('0' + CAST(DATEPART(MONTH, GETDATE()) AS VARCHAR), 2)
		+ RIGHT('0' + CAST(DATEPART(DAY, GETDATE()) AS VARCHAR), 2)

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	
	UPDATE DBO.XX_IMAPS_TS_PREP_CONFIG_ERRORS
	SET STATUS_RECORD_NUM_REPROCESSED = @NEW_STATUS_RECORD_NUM,
		UPDATE_DT = current_timestamp /*DR1631*/ 
	FROM DBO.XX_IMAPS_TS_PREP_CONFIG_ERRORS stg
	WHERE 
	STATUS_RECORD_NUM_REPROCESSED IS NULL
	AND
	(
	NOTES IN
	(SELECT NOTES FROM IMAPS.DELTEK.TS_LN where empl_id=stg.empl_id)
		OR
	NOTES IN
	(SELECT NOTES FROM IMAPS.DELTEK.TS_LN_HS where empl_id=stg.empl_id)
	)
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER
	

	
	/*DR1631*/
	/*separate last week's bad from good*/
	UPDATE XX_IMAPS_TS_PREP_CONFIG_ERRORS
	SET FEEDBACK=''
	WHERE FEEDBACK IS NULL

	/*
	no longer needed CR 4886
	UPDATE XX_IMAPS_TS_PREP_CONFIG_ERRORS
	SET TS_HDR_SEQ_NO = '5'
	WHERE S_TS_TYPE_CD = 'R'
	AND TS_HDR_SEQ_NO in ('3','4')
	AND STATUS_RECORD_NUM_REPROCESSED IS NULL
	AND LEN(FEEDBACK)>0

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	UPDATE XX_IMAPS_TS_PREP_CONFIG_ERRORS
	SET TS_HDR_SEQ_NO = '6'
	WHERE S_TS_TYPE_CD = 'R'
	AND TS_HDR_SEQ_NO in ('3','4')
	AND STATUS_RECORD_NUM_REPROCESSED IS NULL
	AND LEN(FEEDBACK)=0
	

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


	--1b. CR-1253
	/*When etime extracts are run more than once in a week there is always a chance 
	that someone can submit a timecard on the first feed and  then alter it on the second.  
	When this happens the record will miscount because 2 records with a sequence of 1 violates the key.  
	The following script is run to fix it.*/
	UPDATE XX_IMAPS_TS_PREP_CONFIG_ERRORS
	SET TS_HDR_SEQ_NO = '3'
	WHERE TS_HDR_SEQ_NO = '1'
	AND S_TS_TYPE_CD = 'R'
	AND STATUS_RECORD_NUM_REPROCESSED IS NULL
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	 
	UPDATE XX_IMAPS_TS_PREP_CONFIG_ERRORS
	SET TS_HDR_SEQ_NO = '4'
	WHERE TS_HDR_SEQ_NO = '2'
	AND S_TS_TYPE_CD = 'R'
	AND STATUS_RECORD_NUM_REPROCESSED IS NULL

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	*/




	/*DR1631*/
	/*when there are more than 100 corrections submitted in one week*/
	/*we need to restart the ts_hrd_seq_no*/
	update xx_imaps_ts_prep_config_errors
	set ts_dt = convert( char(10), cast(ts_dt as datetime)+1, 120),
		ts_hdr_seq_no = cast( (cast(ts_hdr_seq_no as int) - 99) as varchar )
	where 
	S_TS_TYPE_CD='C'
	and
	cast(ts_hdr_seq_no as int) > 99
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	/*DR1631*/
	/*update x_record_no*/
	/*CR 4886 change to X_RECORD_NO logic*/
	/*
	UPDATE XX_IMAPS_TS_PREP_CONFIG_ERRORS
	SET X_RECORD_NO=NULL
	WHERE STATUS_RECORD_NUM_REPROCESSED IS NOT NULL

	UPDATE XX_IMAPS_TS_PREP_CONFIG_ERRORS
	SET X_RECORD_NO = (SELECT COUNT(1)
						FROM XX_IMAPS_TS_PREP_CONFIG_ERRORS
						WHERE STATUS_RECORD_NUM_REPROCESSED IS NULL
						AND ROW_ID >= ts.ROW_ID)
	FROM XX_IMAPS_TS_PREP_CONFIG_ERRORS ts
	*/

	--1b. End




	--2.  LOAD STAGING TABLE
	PRINT '2'
	TRUNCATE TABLE DBO.XX_IMAPS_TS_PREP_TEMP
	
	INSERT INTO DBO.XX_IMAPS_TS_PREP_TEMP
	(TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
	SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, LAB_CST_AMT, CHG_HRS,
	LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
	EFFECT_BILL_DT, NOTES)
	SELECT TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
	SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, LAB_CST_AMT, CHG_HRS,
	LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
	EFFECT_BILL_DT, NOTES
	FROM  DBO.XX_IMAPS_TS_PREP_CONFIG_ERRORS
	WHERE STATUS_RECORD_NUM_REPROCESSED IS NULL
	/*DR1631*/
	/*order by x_record_no*/
	ORDER BY X_RECORD_NO
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER
	


	--5.  SIMULATE COSTPOINT /*DR1631*/
	PRINT '5'
	EXEC @RET_CODE = XX_ETIME_MISCODE_SIMULATE_COSTPOINT_SP
		@in_COMPANY_ID=@in_COMPANY_ID 			

	IF @RET_CODE <> 0 GOTO BL_ERROR_HANDLER


	--6.  SIMULATE COSTPOINT
	PRINT '6'
	EXEC @RET_CODE = XX_ETIME_SIMULATE_COSTPOINT_SP
		@in_COMPANY_ID=@in_COMPANY_ID 			-- Added CR-1543

	IF @RET_CODE <> 0 GOTO BL_ERROR_HANDLER


    --Added CR-4886

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
   and UPPER(parameter_name)='ACTUALS_EFFECT_DT') -- Change it to 2012

	--7. Create Reclass
	-- We should recreate reclass 
	-- if employee's stad hrs are changed or exempt status changed since TC wa originally submitted
	PRINT '7'

	-- This step will split TS lines for newly mapped employees only
	DECLARE @out_STATUS_DESCRIPTION2 SYSNAME

    --Update notes value without -A- or -B-, that way we reassign -A- Again later on
    update dbo.XX_IMAPS_TS_PREP_TEMP 
	     set notes=
		            substring(notes,1,CHARINDEX('-', notes, 1))
		            +substring(notes, CHARINDEX('-', notes, 1)+1, (CHARINDEX('-', notes, (CHARINDEX('-', notes, 1)+1))-CHARINDEX('-', notes, 1)-1) )
			        +'-'
		            +substring(notes, CHARINDEX('ACTVT_CD', notes, 1), len(notes))
    where (notes like '%-A-%' or notes like '%-B-%')
	
	--Reversed to regular Reclass instead of special process of miscode CR-5698
	-- Changed from 
	--EXEC @RET_CODE = XX_INSERT_TS_RECLASS_MISCODE_SP --This SP is no Longer is not use
	EXEC @RET_CODE = XX_INSERT_TS_RECLASS_SP 
	-- END CR_5698 Change
	
 	IF @RET_CODE <> 0
         BEGIN
           -- Attempt to insert a XX_IMAPS_TS_PREP_TEMP record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
               @in_SQLServer_error_code = @RET_CODE,
               @in_placeholder_value1   = 'insert',
               @in_placeholder_value2   = 'XX_IMAPS_TS_PREP_TEMP Miscode process',
               @in_calling_object_name  = 'XX_ETIME_MISCODE_CREATE_FILE',
               @out_msg_text            = @out_STATUS_DESCRIPTION2 OUTPUT
            RETURN(1)
         END

	--8. Simulate TS_HDR_SEQ_NO
	PRINT '8'

	DECLARE @out_STATUS_DESCRIPTION SYSNAME

    EXEC @ret_code = XX_ETIME_SIMULATE_TSHDRSEQ_SP

    IF @ret_code <> 0
         BEGIN
            -- Attempt to insert a XX_IMAPS_TS_PREP_TEMP record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
               @in_SQLServer_error_code = @ret_code,
		       @in_placeholder_value1   = 'insert',
               @in_placeholder_value2   = 'XX_IMAPS_TS_PREP SIMULATE HDR SEQ ERRORS',
               @in_calling_object_name  = 'XX_ETIME_MISCODE_CREATE_FILE_SP',
			   @out_msg_text            =  @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END

	/* May not need this anymore since we discontinued reclass method -- CR-5698
	-- Commented on 02/08/2013

	--9. Clean Miscode table with records from PREP_TEMP
	-- Added CR-4886
	PRINT '9'


	-- Clean up the TEMP2 table if the sum of hours matches before and after split
	DECLARE @out_check_sum1 numeric(14,2), --Total from CONFIG_ERROR
		    @out_check_sum2 numeric(14,2)  --Total from TEMP where notes in CONFIG_ERROR

	--Check Sum Hrs-1
    select @out_check_sum1=sum(cast(chg_hrs as numeric(14,2)))
    FROM IMAPSStg.dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS
	WHERE 
        (substring(notes,1,CHARINDEX('-', notes, 1))
         +substring(notes, CHARINDEX('-', notes, 1)+1, (CHARINDEX('-', notes, (CHARINDEX('-', notes, 1)+1))-CHARINDEX('-', notes, 1)-1) )
        ) 
        in (select  substring(notes,1,CHARINDEX('-', notes, 1))
                    +substring(notes, CHARINDEX('-', notes, 1)+1, (CHARINDEX('-', notes, (CHARINDEX('-', notes, 1)+1))-CHARINDEX('-', notes, 1)-1) )
	        from xx_imaps_ts_prep_temp)
	and status_record_num_reprocessed is null

	--Check Sum Hrs-2
    select @out_check_sum2=sum(cast(chg_hrs as numeric(14,2)))
	FROM dbo.XX_IMAPS_TS_PREP_TEMP 


     IF @out_check_sum1<>@out_check_sum2 
        BEGIN
            PRINT 'Sum of hours are not matching between PREP_TEMP and MISCODE table #9'
            GOTO BL_ERROR_HANDLER
        END
     ELSE

	 -- IF the total hours in TEMP and TEMP2 tables are matching for Non-Exempt employees then 
	 -- Delete the data from TEMP table and xfer the data from TEMP2 table
	 BEGIN
		PRINT 'GOOD'
		--Delete records that was copied to PREP_TEMP
		--We will delete them from miscode table sinc the new records may have been reclassed
		--This way we will restore the newly reclassed records back to miscode table	
		DELETE FROM IMAPSStg.dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS
		WHERE 
			(substring(notes,1,CHARINDEX('-', notes, 1))
			 +substring(notes, CHARINDEX('-', notes, 1)+1, (CHARINDEX('-', notes, (CHARINDEX('-', notes, 1)+1))-CHARINDEX('-', notes, 1)-1) )
			) 
			in (select  substring(notes,1,CHARINDEX('-', notes, 1))
						+substring(notes, CHARINDEX('-', notes, 1)+1, (CHARINDEX('-', notes, (CHARINDEX('-', notes, 1)+1))-CHARINDEX('-', notes, 1)-1) )
				from xx_imaps_ts_prep_temp)
		and status_record_num_reprocessed is null


		--begin archive records that errored out
		INSERT INTO dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS
		(STATUS_RECORD_NUM_CREATED, TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
		SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, LAB_CST_AMT, CHG_HRS,
		LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
		EFFECT_BILL_DT, NOTES)
		SELECT 
		substring(notes,1,CHARINDEX('-', notes, 1)-1),
		TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
		SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, LAB_CST_AMT, CHG_HRS,
		LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
		EFFECT_BILL_DT, NOTES
		FROM dbo.XX_IMAPS_TS_PREP_TEMP 

	 END
	-- END Change CR-5698
	*/

	/*CR 4886 change to X_RECORD_NO logic*/
	select * into #XX_IMAPS_TS_PREP_TEMP_ORDERED
	from XX_IMAPS_TS_PREP_TEMP
	order by notes

	truncate table XX_IMAPS_TS_PREP_TEMP

	insert into XX_IMAPS_TS_PREP_TEMP
	select * 
	from #XX_IMAPS_TS_PREP_TEMP_ORDERED
	order by notes

	drop table #XX_IMAPS_TS_PREP_TEMP_ORDERED

	UPDATE XX_IMAPS_TS_PREP_CONFIG_ERRORS
	SET FEEDBACK=''
	WHERE FEEDBACK IS NULL

	/*DR1631*/
	/*update x_record_no*/
	UPDATE XX_IMAPS_TS_PREP_CONFIG_ERRORS
	SET X_RECORD_NO=NULL
	WHERE STATUS_RECORD_NUM_REPROCESSED IS NOT NULL

	UPDATE XX_IMAPS_TS_PREP_CONFIG_ERRORS
	SET X_RECORD_NO = (SELECT COUNT(1)
						FROM XX_IMAPS_TS_PREP_CONFIG_ERRORS
						WHERE STATUS_RECORD_NUM_REPROCESSED IS NULL
						AND NOTES <= ts.NOTES)
	FROM XX_IMAPS_TS_PREP_CONFIG_ERRORS ts
	WHERE STATUS_RECORD_NUM_REPROCESSED IS NULL

	UPDATE XX_IMAPS_TS_PREP_CONFIG_ERRORS
	SET X_RECORD_NO = (SELECT COUNT(1)+1
						FROM XX_IMAPS_TS_PREP_CONFIG_ERRORS
						WHERE STATUS_RECORD_NUM_REPROCESSED IS NULL)
	FROM XX_IMAPS_TS_PREP_CONFIG_ERRORS ts
	WHERE STATUS_RECORD_NUM_REPROCESSED IS NOT NULL

--END CR-4886

	PRINT '10'
	--9.  EXPORT TS_PREP.TXT FILE
	DECLARE @WORDS SYSNAME
	
	EXEC @RET_CODE = DBO.XX_EXEC_SHELL_CMD_OSUSER   --Modified CR-3617
		@IN_IMAPS_DB_NAME = 'IMAPSSTG',
		@IN_IMAPS_TABLE_OWNER = 'DBO',
		@IN_SOURCE_TABLE = 'XX_IMAPS_TS_PREP_TEMP',
		@IN_FORMAT_FILE = @FORMATFILE,
		@IN_OUTPUT_FILE = @FILE_TO_REPROCESS,
		--@IN_USR_PASSWORD = @PASSWORD, --Modified CR-3617
		@OUT_STATUS_DESCRIPTION = @WORDS
	
	IF @RET_CODE <> 0
	BEGIN
		PRINT @WORDS
		GOTO BL_ERROR_HANDLER
	END
	
	
	RETURN (0)
	
	BL_ERROR_HANDLER:
	
	PRINT 'ERROR CREATING FILE'
	RETURN(1)

END














go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_ETIME_MISCODE_CREATE_FILE_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_ETIME_MISCODE_CREATE_FILE_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_ETIME_MISCODE_CREATE_FILE_SP >>>'
go

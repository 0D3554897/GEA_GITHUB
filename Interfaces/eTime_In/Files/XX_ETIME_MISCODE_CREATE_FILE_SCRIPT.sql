
	DECLARE
	@FILE_TO_REPROCESS sysname 
	SET @FILE_TO_REPROCESS = '\\imapscluster01\interfaces\ETIME_MISCODES.TXT'
	
		
	--0. DECLARE VARIABLES
	DECLARE @CurrentFY int,
		@CurrentPeriod int,
		@CurrentSubPeriod int,
		@FormatFile sysname,
		@Password sysname
	
	
	--IF CERIS, ETIME, OR RATERETRO IS RUNNING,
	--DON'T DO ANYTHING
	DECLARE @ret_code int
	
	SELECT @ret_code = count(1)
	FROM dbo.XX_IMAPS_INT_STATUS
	WHERE INTERFACE_NAME in ('CERIS', 'ETIME', 'RATERETRO')
	and STATUS_CODE not in ('COMPLETED', 'SUCCESS_WITH_ERROR', 'DUPLICATE')
	IF @ret_code <> 0
	BEGIN 
		
		RAISERROR ('CERIS, ETIME, OR RATERETRO IS RUNNING', 16, 1) 
	END
	
	
	-- SET VARIABLES
	SET @CurrentFY = DATEPART(year, GETDATE())
	SET @CurrentPeriod = DATEPART(month, GETDATE())
	SELECT @CurrentSubPeriod = a.SUB_PD_NO 
		FROM IMAPS.DELTEK.SUB_PD a
		WHERE a.SUB_PD_END_DT =
		(SELECT MIN(b.SUB_PD_END_DT)
		 FROM  IMAPS.DELTEK.SUB_PD b
		       WHERE (b.SUB_PD_NO = 2 OR
			      b.SUB_PD_NO = 3) AND
		       DATEDIFF(day, GETDATE(), b.SUB_PD_END_DT) >= 0)
	
	IF @@ERROR <> 0 RAISERROR ('ERROR - 0', 16, 1) 
	
	
	SELECT @FormatFile = PARAMETER_VALUE
	from xX_processing_parameters
	where interface_name_cd = 'ETIME'
	and parameter_name = 'IN_PREP_FORMAT_FILENAME'
	
	
	IF @@ERROR <> 0 RAISERROR ('ERROR - 0', 16, 1) 
	
	
	SELECT @Password = PARAMETER_VALUE
	from xX_processing_parameters
	where interface_name_cd = 'ETIME'
	and parameter_name = 'IN_USER_PASSWORD'
	
	
	IF @@ERROR <> 0 RAISERROR ('ERROR - 0', 16, 1) 
	
	
	
	--
	--1.  MARK RECORDS THAT WERE SUCCESSFULLY IMPORTED
	DECLARE @NEW_STATUS_RECORD_NUM int

	
	SELECT @NEW_STATUS_RECORD_NUM  = 
	 CAST(DATEPART(year, GETDATE()) as varchar) 
	+ RIGHT('0' + CAST(DATEPART(month, GETDATE()) as varchar), 2)
	+ RIGHT('0' + CAST(DATEPART(day, GETDATE()) as varchar), 2)
	+ '0' --added to distinguish between what goes through CP and what got zeroed out


	update xx_imaps_ts_prep_config_errors
	set status_record_num_reprocessed = @NEW_STATUS_RECORD_NUM
	from xx_imaps_ts_prep_config_errors
	where 
	status_record_num_reprocessed is null
	and 
	rtrim(empl_id)+rtrim(effect_bill_dt)+rtrim(proj_abbrv_cd)+rtrim(bill_lab_cat_cd) 
	in
	(
		select rtrim(empl_id)+rtrim(effect_bill_dt)+rtrim(proj_abbrv_cd)+rtrim(bill_lab_cat_cd) 
		from xx_imaps_ts_prep_config_errors
		where status_record_num_reprocessed is null
		group by empl_id, effect_bill_dt, proj_abbrv_cd, bill_lab_cat_cd
		having  sum(cast(chg_hrs as decimal(14,2))) = .00
	)

	IF @@ERROR <> 0 RAISERROR ('ERROR - 1a', 16, 1) 

	SELECT @NEW_STATUS_RECORD_NUM  = 
		 CAST(DATEPART(year, GETDATE()) as varchar) 
		+ RIGHT('0' + CAST(DATEPART(month, GETDATE()) as varchar), 2)
		+ RIGHT('0' + CAST(DATEPART(day, GETDATE()) as varchar), 2)

	IF @@ERROR <> 0 RAISERROR ('ERROR - 1', 16, 1) 

	
	UPDATE dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS
	SET STATUS_RECORD_NUM_REPROCESSED = @NEW_STATUS_RECORD_NUM  
	WHERE 
	STATUS_RECORD_NUM_REPROCESSED IS NULL
	AND
	(
	NOTES IN
	(SELECT NOTES FROM IMAPS.DELTEK.TS_LN)
		OR
	NOTES IN
	(SELECT NOTES FROM IMAPS.DELTEK.TS_LN_HS)
	)
	
	IF @@ERROR <> 0 RAISERROR ('ERROR - 1', 16, 1) 
	
	
	--2.  LOAD STAGING TABLE
	TRUNCATE TABLE dbo.XX_IMAPS_TS_PREP_TEMP
	
	INSERT INTO dbo.XX_IMAPS_TS_PREP_TEMP
	(TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
	SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, LAB_CST_AMT, CHG_HRS,
	LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
	EFFECT_BILL_DT, NOTES)
	SELECT TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
	SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, LAB_CST_AMT, CHG_HRS,
	LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
	EFFECT_BILL_DT, NOTES
	FROM  dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS
	WHERE STATUS_RECORD_NUM_REPROCESSED is null
	
	IF @@ERROR <> 0 RAISERROR ('ERROR - 2', 16, 1) 
	
	
	
	
	--3.  UPDATE TIME CERIS AND FINANCIAL DATA
	--    AND IDENTIFY CROSS-CHARGING ERRORS
	UPDATE dbo.XX_IMAPS_TS_PREP_TEMP
	SET GENL_LAB_CAT_CD = empl_lab.GENL_LAB_CAT_CD,
	    FY_CD = @CurrentFY, 
	    PD_NO = @CurrentPeriod,
	    SUB_PD_NO = @CurrentSubPeriod,
	    ACCT_ID = lab_acct.ACCT_ID
	FROM dbo.XX_IMAPS_TS_PREP_TEMP ts
	INNER JOIN IMAPS.DELTEK.EMPL_LAB_INFO empl_lab
	on
	(ts.empl_id = empl_lab.empl_id
		and 
		(
			(ts.S_TS_TYPE_CD = 'R' AND cast(ts.TS_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
			OR
			(ts.S_TS_TYPE_CD = 'C' AND cast(ts.CORRECTING_REF_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
		)
	)
	INNER JOIN IMAPS.DELTEK.PROJ proj
	on
	(ts.PROJ_ABBRV_CD = proj.PROJ_ABBRV_CD)
	INNER JOIN IMAPS.DELTEK.LAB_ACCT_GRP_DFLT lab_acct
	ON
	(
	empl_lab.LAB_GRP_TYPE = lab_acct.LAB_GRP_TYPE
	AND proj.ACCT_GRP_CD = lab_acct.ACCT_GRP_CD
	)
	
	IF @@ERROR <> 0 RAISERROR ('ERROR - 3', 16, 1) 
	
	
	
	--4.  REMOVE CROSS_CHARGING ERRORS
	--    DO NOT BOTHER TRYING TO REPROCESS THEM
	DELETE FROM dbo.XX_IMAPS_TS_PREP_TEMP
	WHERE  EMPL_ID + S_TS_TYPE_CD + TS_DT + TS_HDR_SEQ_NO
	IN
	(SELECT EMPL_ID + S_TS_TYPE_CD + TS_DT + TS_HDR_SEQ_NO 
	 FROM dbo.XX_IMAPS_TS_PREP_TEMP
	 WHERE ACCT_ID IS NULL)
	
	IF @@ERROR <> 0 RAISERROR ('ERROR - 4', 16, 1) 
	
	
	--5.  LET ACCT_ID DEFAULT IN PREPROCESSOR
	UPDATE dbo.XX_IMAPS_TS_PREP_TEMP
	SET ACCT_ID = NULL
	
	IF @@ERROR <> 0 RAISERROR ('ERROR - 5', 16, 1) 
	
	
	--6.  EXPORT TS_PREP.TXT FILE
	DECLARE @words sysname
	
	EXEC @ret_code = dbo.XX_EXEC_SHELL_CMD
		@in_IMAPS_db_name = 'IMAPSStg',
		@in_IMAPS_table_owner = 'dbo',
		@in_source_table = 'XX_IMAPS_TS_PREP_TEMP',
		@in_format_file = @FormatFile,
		@in_output_file = @FILE_TO_REPROCESS,
		@in_usr_password = @Password,
		@out_STATUS_DESCRIPTION = @words
	
	IF @ret_code <> 0
	BEGIN
		PRINT @words
		RAISERROR ('ERROR - 6', 16, 1) 
	END
	
	











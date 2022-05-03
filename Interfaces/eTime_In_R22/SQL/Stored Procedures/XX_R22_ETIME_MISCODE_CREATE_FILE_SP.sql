IF OBJECT_ID('dbo.XX_R22_ETIME_MISCODE_CREATE_FILE_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_ETIME_MISCODE_CREATE_FILE_SP
    IF OBJECT_ID('dbo.XX_R22_ETIME_MISCODE_CREATE_FILE_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_ETIME_MISCODE_CREATE_FILE_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_ETIME_MISCODE_CREATE_FILE_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go



CREATE PROCEDURE [dbo].[XX_R22_ETIME_MISCODE_CREATE_FILE_SP] 
(
@FILE_TO_REPROCESS SYSNAME  --MAKE SURE THIS POINTS TO THE SERVER UNC PATH
)  
AS
 /************************************************************************************************
NAME:       XX_R22_ETIME_MISCODE_CREATE_FILE_SP
AUTHOR:     KM
CREATED:    01/04/2007
PURPOSE:   STEP 1 OF ETIME MISCODE PROCESS 
Modified: 10/26/2007 CR-1253
Modified: 05/01/2008 CR-1543 For Company_id logic
Modified: 08/01/2008 CR-2649 For Div.22 changes
Modified: 11/05/2008 CR-1649 changes - Simulate CP logic updated	
Modified: 01/15/2009 CR-1821 Modified for CR-1821, Added, ACCT_ID, PAY_TYPE in update
Modified: 02/04/2009 CR-1863 Removed ETIME, CERIS from the list
Modified: 03/05/2009 CR-1901 Modified Step-4 Missing ACCT_IDs will be now ??-??-??
Modified: 04/19/2009 CR-1926 Modified to update logic for PD no
Modified: 05/11/2009 CR-2042 Modified for new logic of processing PPAs
Modified: 03/21/2010 CR-2419 Modified for new logic of TSHDRSEQ
Modified: 04/27/2010 CR-2414 Modified for new logic of Dup BO Issue
Modified: 04/28/2010 CR-2414 Modified for issue with the updating D type records.
Modified: 04/28/2010 CR-2414 Modified for issue with hdr_seq_no.
Modified: 09/24/2010 DR-2809 PPA Partial TC reversed. When employee add D TS for other dates.
Modified: 05/05/2011 CR-3749 Modified for Shared Issue
Modified: 03/13/2012 DR-4037 Modified to correct error message.

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
	
	--IF ETIME_R22 OR CERIS_R22 IS RUNNING, DON'T DO ANYTHING
	DECLARE @RET_CODE INT
	
	SELECT @RET_CODE = COUNT(1)
	FROM DBO.XX_IMAPS_INT_STATUS
	WHERE INTERFACE_NAME IN ('ETIME_R22','CERIS_R22') -- CR-1863 Modified non-div 16 taken off on 02/03/09
	AND STATUS_CODE NOT IN ('COMPLETED', 'SUCCESS_WITH_ERROR', 'DUPLICATE')
	IF @RET_CODE <> 0
	BEGIN 
		
		RAISERROR ('ETIME_R22 OR CERIS_R22 IS RUNNING', 16, 1) -- DR4037
		GOTO BL_ERROR_HANDLER
	END


	-- SET VARIABLES
	SET @CURRENTFY = DATEPART(YEAR, GETDATE())
    --BEGIN CR-1926
    /*
	SET @CURRENTPERIOD = DATEPART(MONTH, GETDATE())
	SELECT @CURRENTSUBPERIOD = A.SUB_PD_NO 
		FROM IMAR.DELTEK.SUB_PD A
		WHERE A.SUB_PD_END_DT =
		(SELECT MIN(B.SUB_PD_END_DT)
		 FROM  IMAR.DELTEK.SUB_PD B
		       WHERE (B.SUB_PD_NO = 2 OR
			      B.SUB_PD_NO = 3) AND
		       DATEDIFF(DAY, GETDATE(), B.SUB_PD_END_DT) >= 0)
    */
    set @CURRENTPERIOD=
		 isnull((select pd_no from xx_r22_sub_pd
			    where FY_CD=(datepart(yyyy,getdate())) 
			    and getdate()>=sub_pd_begin_dt and getdate()<=sub_pd_end_dt
			    and pd_no+(datepart(yyyy,getdate())) in (select pd_no+fy_cd from imar.deltek.accting_pd where s_status_cd='O')
				), (datepart(mm,getdate()))
				)
    set @CURRENTSUBPERIOD='3'
    
    --END CR-1926


	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER
	
	--remove after testing
	--set @CURRENTSUBPERIOD=3	

	SELECT @FORMATFILE = PARAMETER_VALUE
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD = 'ETIME_R22'
	AND PARAMETER_NAME = 'IN_PREP_FORMAT_FILENAME'
	
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	
	SELECT @PASSWORD = PARAMETER_VALUE
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD = 'ETIME_R22'
	AND PARAMETER_NAME = 'IN_USER_PASSWORD'
	
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER
	
	-- Added CR-1543
	
	SELECT @in_COMPANY_ID = PARAMETER_VALUE
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD = 'ETIME_R22'
	AND PARAMETER_NAME = 'COMPANY_ID'
	
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER
	
	
	--
	--1.  MARK RECORDS THAT WERE SUCCESSFULLY IMPORTED
	DECLARE @NEW_STATUS_RECORD_NUM INT
	DECLARE @NDR_NEW_STATUS_RECORD_NUM INT


	PRINT '1A'
	SELECT @NEW_STATUS_RECORD_NUM  = 
	 CAST(DATEPART(YEAR, GETDATE()) AS VARCHAR) 
	+ RIGHT('0' + CAST(DATEPART(MONTH, GETDATE()) AS VARCHAR), 2)
	+ RIGHT('0' + CAST(DATEPART(DAY, GETDATE()) AS VARCHAR), 2)
	+ '0' --ADDED TO DISTINGUISH BETWEEN WHAT GOES THROUGH CP AND WHAT GOT ZEROED OUT

	SELECT @NDR_NEW_STATUS_RECORD_NUM  = 
	'8'+ CAST(DATEPART(YEAR, GETDATE()) AS VARCHAR) -- Added 888 to distinguish between regular rec and N Recs
	+ RIGHT('0' + CAST(DATEPART(MONTH, GETDATE()) AS VARCHAR), 2)
	+ RIGHT('0' + CAST(DATEPART(DAY, GETDATE()) AS VARCHAR), 2)
	

/*	--Commented 04/28/2010 We no longer need this section
    -- ACCT_ID and PAY_TYPE as the sum of reclass A, B and C was getting to zero when standard hours were wrong
	-- Added CR-1821
	UPDATE XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
	SET STATUS_RECORD_NUM_REPROCESSED = @NEW_STATUS_RECORD_NUM
	FROM XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
	WHERE 
	STATUS_RECORD_NUM_REPROCESSED IS NULL
	AND s_ts_type_cd in ('R','N') --Added DR-2414 4/28/10
	AND 
	RTRIM(EMPL_ID)+RTRIM(EFFECT_BILL_DT)+RTRIM(PROJ_ABBRV_CD)+RTRIM(BILL_LAB_CAT_CD)+RTRIM(ACCT_ID) +RTRIM(PAY_TYPE)
	IN
	(
		SELECT RTRIM(EMPL_ID)+RTRIM(EFFECT_BILL_DT)+RTRIM(PROJ_ABBRV_CD)+RTRIM(BILL_LAB_CAT_CD)+RTRIM(ACCT_ID)+ RTRIM(PAY_TYPE)
		FROM XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
		WHERE STATUS_RECORD_NUM_REPROCESSED IS NULL
		and s_ts_type_cd in ('N', 'R') -- Modified DR-2414 Duplicate BO issue
		-- Added to include N, D lines 03/08/2009
		GROUP BY EMPL_ID, EFFECT_BILL_DT, PROJ_ABBRV_CD, BILL_LAB_CAT_CD, ACCT_ID, PAY_TYPE
		HAVING  SUM(CAST(CHG_HRS AS DECIMAL(14,2))) = .00
	)	
*/
    --DR-2809 Change
    --This update will fix the correcting ref date with the actual split date
    --This will eliminate potential dup BO issue
    update xx_r22_imaps_ts_prep_config_errors
    set correcting_ref_dt=ts_dt, effect_bill_dt=ts_dt
    where 
        status_record_num_reprocessed is null
        and correcting_ref_dt<>ts_dt
        and pay_type='BO'

	--BEGIN CR-2042 change
	-- If Previous regular TC is miscoded and PPA is available then mark R, N as processed
	update XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
	set status_record_num_reprocessed=@NDR_NEW_STATUS_RECORD_NUM
	--select *
	FROM XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
	where 
	s_ts_type_cd in ('R','N')
	and	STATUS_RECORD_NUM_REPROCESSED IS NULL
	and	RTRIM(EMPL_ID)+RTRIM(EFFECT_BILL_DT)+RTRIM(PROJ_ABBRV_CD)+RTRIM(BILL_LAB_CAT_CD) 
		IN
		(
			SELECT RTRIM(EMPL_ID)+RTRIM(EFFECT_BILL_DT)+RTRIM(PROJ_ABBRV_CD)+RTRIM(BILL_LAB_CAT_CD) 
			FROM XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
			WHERE s_ts_type_cd in ('R','N')
				and STATUS_RECORD_NUM_REPROCESSED IS NULL
			GROUP BY EMPL_ID, EFFECT_BILL_DT, PROJ_ABBRV_CD, BILL_LAB_CAT_CD
			HAVING  SUM(CAST(CHG_HRS AS DECIMAL(14,2))) = .00
		)	

	-- Change D type TC to regular if Regular TC is available.
	-- Remove the -D from the notes field for convert notes to -R regular notes value
	update XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
	set s_ts_type_cd='R' , notes=replace(notes, '-D','-R'), --notes=left(notes,CHARINDEX('-D', notes, 1)-1 ), --Modified DR-2414
		ts_dt=correcting_ref_dt, correcting_ref_dt=NULL
	FROM XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
	where 
	 s_ts_type_cd in ('D')
	and	STATUS_RECORD_NUM_REPROCESSED IS NULL
    --Added DR2809 09/24/2010
	and	RTRIM(EMPL_ID)+CONVERT(char(10),(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(cast(EFFECT_BILL_DT as datetime))),120)
		IN
		(
			SELECT RTRIM(EMPL_ID)+CONVERT(char(10),(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(cast(EFFECT_BILL_DT as datetime))),120)
			FROM XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
    /* Commented DR2809 09/24/2010
	and	RTRIM(EMPL_ID)+RTRIM(EFFECT_BILL_DT) 
		IN
		(
			SELECT RTRIM(EMPL_ID)+RTRIM(EFFECT_BILL_DT) 
			FROM XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS */
			WHERE 
				s_ts_type_cd in ('R','N')
			and	STATUS_RECORD_NUM_REPROCESSED like '8%'
			GROUP BY EMPL_ID, EFFECT_BILL_DT, PROJ_ABBRV_CD, BILL_LAB_CAT_CD
			HAVING  SUM(CAST(CHG_HRS AS DECIMAL(14,2))) = .00
		)	

	--END CR-2042 change

    -- BEGIN CR2414 Changes
    -- First create tenp table with notes value for records converted from D to R
    SELECT empl_id, ts_dt, correcting_ref_dt,
    substring(notes,1,CHARINDEX('-', notes, 1))+cast(max(cast (substring(notes, CHARINDEX('-', notes, 1)+1, (CHARINDEX('-', notes, (CHARINDEX('-', notes, 1)+1))-CHARINDEX('-', notes, 1)-1) ) as numeric)) as varchar) as notes_rec_num
    INTO #XX_R22_IMAPS_TS_PREP_CONF_NOTES_REC
    FROM dbo.XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
    WHERE status_record_num_reprocessed is null
        and s_ts_type_cd='R'
    GROUP BY empl_id, ts_dt,correcting_ref_dt, substring(notes,1,CHARINDEX('-', notes, 1))

    -- Update all records converted from D to R where their notes values does not match with temp table
    --select * from #XX_R22_IMAPS_TS_PREP_CONF_NOTES_REC
    UPDATE xx_r22_imaps_ts_prep_config_errors
        SET notes=te.notes_rec_num
		        +'-C-'
        from xx_r22_imaps_ts_prep_config_errors ts
        inner join #XX_R22_IMAPS_TS_PREP_CONF_NOTES_REC te
        on (ts.empl_id=te.empl_id
            and rtrim(ts.ts_dt)=rtrim(te.ts_dt)
            and isnull(ts.correcting_ref_dt,'')=isnull(te.ts_dt,''))
        where status_record_num_reprocessed is null
        and rtrim(notes)<>rtrim(te.notes_rec_num)+'-C-'
        and s_ts_type_cd='C'
        and pay_type='BO'

    DROP TABLE #XX_R22_IMAPS_TS_PREP_CONF_NOTES_REC

    -- END CR2414 Changes

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


	PRINT '1'
	SELECT @NEW_STATUS_RECORD_NUM  = 
		 CAST(DATEPART(YEAR, GETDATE()) AS VARCHAR) 
		+ RIGHT('0' + CAST(DATEPART(MONTH, GETDATE()) AS VARCHAR), 2)
		+ RIGHT('0' + CAST(DATEPART(DAY, GETDATE()) AS VARCHAR), 2)

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

/*	TEMP BLOCKED
	UPDATE DBO.XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
	SET STATUS_RECORD_NUM_REPROCESSED = @NEW_STATUS_RECORD_NUM  
	WHERE 
	STATUS_RECORD_NUM_REPROCESSED IS NULL
	AND
	(
	NOTES IN
	(SELECT NOTES FROM IMAR.DELTEK.TS_LN )
		OR
	NOTES IN
	(SELECT NOTES FROM IMAR.DELTEK.TS_LN_HS)
	)
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER
*/	
	--1b. CR-1253
	/*When etime extracts are run more than once in a week there is always a chance 
	that someone can submit a timecard on the first feed and  then alter it on the second.  
	When this happens the record will miscount because 2 records with a sequence of 1 violates the key.  
	The following script is run to fix it.*/

    --Modified for CR-2414 Added 05/03/2010
    --Regs TS should have 1 HDR SEQ, C TC should have 2
	UPDATE XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
	SET TS_HDR_SEQ_NO = '1'
	WHERE TS_HDR_SEQ_NO <>'1'
	AND S_TS_TYPE_CD = 'R'
	AND STATUS_RECORD_NUM_REPROCESSED IS NULL
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	UPDATE XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
	SET TS_HDR_SEQ_NO = '2'
	WHERE TS_HDR_SEQ_NO <>'2'
	AND S_TS_TYPE_CD = 'C'
    AND PAY_TYPE='BO'
	AND STATUS_RECORD_NUM_REPROCESSED IS NULL
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

    /*Commented CR-2414 Added 5/3/2010
	UPDATE XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
	SET TS_HDR_SEQ_NO = '3'
	WHERE TS_HDR_SEQ_NO = '1'
	AND S_TS_TYPE_CD = 'R'
	AND STATUS_RECORD_NUM_REPROCESSED IS NULL
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	 
	UPDATE XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
	SET TS_HDR_SEQ_NO = '4'
	WHERE TS_HDR_SEQ_NO = '2'
	AND S_TS_TYPE_CD = 'R'
	AND STATUS_RECORD_NUM_REPROCESSED IS NULL

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER
    */
	--1b. End

	--2.  LOAD STAGING TABLE
	PRINT '2'
	TRUNCATE TABLE DBO.XX_R22_IMAPS_TS_PREP_TEMP
	
	INSERT INTO DBO.XX_R22_IMAPS_TS_PREP_TEMP
	(TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
	SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, LAB_CST_AMT, CHG_HRS, ACCT_ID,
	LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
	EFFECT_BILL_DT, NOTES)
	SELECT TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
	SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, LAB_CST_AMT, CHG_HRS, ACCT_ID,
	LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
	EFFECT_BILL_DT, NOTES
	FROM  DBO.XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
	WHERE STATUS_RECORD_NUM_REPROCESSED IS NULL
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER
	
	
	-- Begin CR-1649 Changes
  DECLARE
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

	-- Retreive R22 Employee ID

	--Open Key for Reading the employee IDs
	-- Close it once done
	exec (@OPEN_KEY)

	UPDATE XX_R22_IMAPS_TS_PREP_TEMP
	SET EMPL_ID = isnull(map.EMPL_ID,ts.empl_id)
    from XX_r22_IMAPS_TS_PREP_TEMP ts, dbo.XX_R22_CERIS_EMPL_ID_MAP map
    where CONVERT(varchar(50), DECRYPTBYKEY(map.R_EMPL_ID))=ts.empl_id
        and map.empl_id in (select empl_id from IMAR.DELTEK.empl)
    exec (@CLOSE_KEY)
	-- END CR-1649 Changes				
	
	PRINT '3'
	--3.  UPDATE TIME CERIS AND FINANCIAL DATA
	-- AND IDENTIFY CROSS-CHARGING ERRORS
	UPDATE DBO.XX_R22_IMAPS_TS_PREP_TEMP
	SET GENL_LAB_CAT_CD = EMPL_LAB.GENL_LAB_CAT_CD,
	    FY_CD = @CURRENTFY, 
	    PD_NO = @CURRENTPERIOD,
	    SUB_PD_NO = @CURRENTSUBPERIOD,
	    ACCT_ID = LAB_ACCT.ACCT_ID
	FROM DBO.XX_R22_IMAPS_TS_PREP_TEMP TS
	INNER JOIN IMAR.DELTEK.EMPL_LAB_INFO EMPL_LAB
	ON
	(TS.EMPL_ID = EMPL_LAB.EMPL_ID
		AND 
		(
			(TS.S_TS_TYPE_CD = 'R' AND CAST(TS.TS_DT AS DATETIME) BETWEEN EMPL_LAB.EFFECT_DT AND EMPL_LAB.END_DT)
			OR
			(TS.S_TS_TYPE_CD in ('C','N','D') AND CAST(TS.CORRECTING_REF_DT AS DATETIME) BETWEEN EMPL_LAB.EFFECT_DT AND EMPL_LAB.END_DT)
		)
	)
	INNER JOIN IMAR.DELTEK.PROJ PROJ
	ON
	(TS.PROJ_ABBRV_CD = PROJ.PROJ_ABBRV_CD
	AND PROJ.COMPANY_ID=@in_COMPANY_ID)		-- Added CR-1543
	INNER JOIN IMAR.DELTEK.LAB_ACCT_GRP_DFLT LAB_ACCT
	ON
	(
	EMPL_LAB.LAB_GRP_TYPE = LAB_ACCT.LAB_GRP_TYPE
	AND PROJ.ACCT_GRP_CD = LAB_ACCT.ACCT_GRP_CD
	)
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER
    
    --Added CR-1901 Update PDs and SUBPDs with latest pds/subpds
	UPDATE DBO.XX_R22_IMAPS_TS_PREP_TEMP
	SET FY_CD = @CURRENTFY, 
	    PD_NO = @CURRENTPERIOD,
	    SUB_PD_NO = @CURRENTSUBPERIOD

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	--MUST UPDATE ORG_ID FOR CORRECTING TIMESHEETS 
	--BECAUSE COSTPOINT IS DUMB
	UPDATE DBO.XX_R22_IMAPS_TS_PREP_TEMP
	SET ORG_ID = EMPL_LAB.ORG_ID
	FROM DBO.XX_R22_IMAPS_TS_PREP_TEMP TS
	INNER JOIN IMAR.DELTEK.EMPL_LAB_INFO EMPL_LAB
	ON
	(
	TS.EMPL_ID = EMPL_LAB.EMPL_ID
		AND 
		(
			(TS.S_TS_TYPE_CD = 'R' AND CAST(TS.TS_DT AS DATETIME) BETWEEN EMPL_LAB.EFFECT_DT AND EMPL_LAB.END_DT)
			OR
			(TS.S_TS_TYPE_CD in ('C','N','D') AND CAST(TS.CORRECTING_REF_DT AS DATETIME) BETWEEN EMPL_LAB.EFFECT_DT AND EMPL_LAB.END_DT)
		)
	)
	--ONLY WHERE HOME ORG GETS CHARGED
	INNER JOIN IMAR.DELTEK.PROJ PROJ
	ON
	(TS.PROJ_ABBRV_CD = PROJ.PROJ_ABBRV_CD
	AND PROJ.COMPANY_ID=@in_COMPANY_ID)		-- Added CR-1543
	WHERE PROJ.PROJ_ID NOT IN
	(SELECT PROJ_ID FROM IMAR.DELTEK.PROJ_TS_DFLT)
	
	
	PRINT '4'
	--4.  REMOVE CROSS_CHARGING ERRORS

	-- In order to being this lines on Sotpoint error report we will mark them as ??-??-??
	-- this will allow us to being them up and this will also eliminate issue of duplicate backout or missing backout line.

	-- Added 03/05/2009 CR-1901
	 UPDATE DBO.XX_R22_IMAPS_TS_PREP_TEMP
	 SET ACCT_ID='??-??-??'
	 WHERE ACCT_ID IS NULL

	--    DO NOT BOTHER TRYING TO REPROCESS THEM
	DELETE FROM DBO.XX_R22_IMAPS_TS_PREP_TEMP
	WHERE  EMPL_ID + S_TS_TYPE_CD + TS_DT + TS_HDR_SEQ_NO
	IN
	(SELECT EMPL_ID + S_TS_TYPE_CD + TS_DT + TS_HDR_SEQ_NO 
	 FROM DBO.XX_R22_IMAPS_TS_PREP_TEMP
	 WHERE ACCT_ID IS NULL)
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER
	
	PRINT '5'
	--5.  LET ACCT_ID DEFAULT IN PREPROCESSOR
	/* Modified 11/05/2008
	UPDATE DBO.XX_R22_IMAPS_TS_PREP_TEMP
	SET ACCT_ID = NULL
	*/
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	--6.  SIMULATE COSTPOINT
	Print '6'
	-- This step will update ORG_ID, ACCT_ID for labor records created in previous week

	/* Modified 11/05/2008
	PRINT '6'
	EXEC @RET_CODE = XX_R22_ETIME_SIMULATE_COSTPOINT_SP
		@in_COMPANY_ID=@in_COMPANY_ID 			-- Added CR-1543

	IF @RET_CODE <> 0 GOTO BL_ERROR_HANDLER
	*/

	--Manual Simulate step	
	UPDATE XX_R22_IMAPS_TS_PREP_TEMP
	SET
	GENL_LAB_CAT_CD = ELI.GENL_LAB_CAT_CD,
	ORG_ID = ELI.ORG_ID
	FROM
	XX_R22_IMAPS_TS_PREP_TEMP TS
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

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	-- Update Account ID only for non-reclass lines and non-backing out lines
	-- Only update account for original lines like -A-
	UPDATE dbo.XX_R22_IMAPS_TS_PREP_TEMP
	SET ACCT_ID = lab_acct.ACCT_ID
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
	AND proj.COMPANY_ID=2) 	--Added CR-1543
	INNER JOIN IMAR.DELTEK.LAB_ACCT_GRP_DFLT lab_acct
	ON
	(
	empl_lab.LAB_GRP_TYPE = lab_acct.LAB_GRP_TYPE
	AND proj.ACCT_GRP_CD = lab_acct.ACCT_GRP_CD
	AND lab_acct.COMPANY_ID=2 	--Added CR-1543
	)
	WHERE ts.notes not like '%-B-%' and ts.notes not like '%-C-%'

	-- Special Logic for RECLASS Lines
	-- This is required if employee's labor group has been changed
	update dbo.XX_R22_IMAPS_TS_PREP_TEMP
	set acct_id= 
			ISNULL((SELECT distinct map.acct_id
					from XX_R22_ACCT_RECLASS map
					where map.lab_grp_type=empl_lab.lab_grp_type
					and map.acct_grp_cd=prj.acct_grp_cd
					and line_type='RECLASS'),'99-99-99') 
	FROM dbo.XX_R22_IMAPS_TS_PREP_TEMP ts
	INNER JOIN IMAR.DELTEK.EMPL_LAB_INFO empl_lab
	on
	(ts.empl_id = empl_lab.empl_id
		and 
		(
			(ts.S_TS_TYPE_CD = 'R' AND cast(ts.TS_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
			OR
			(ts.S_TS_TYPE_CD in ('C','N','D') AND cast(ts.CORRECTING_REF_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
		)
	)
	INNER JOIN IMAR.DELTEK.proj prj
	on (ts.proj_abbrv_cd=prj.proj_abbrv_cd and prj.company_id=2)
	where exmpt_fl='Y'
	AND ts.notes  like '%-B-%'

	-- Special Logic for BACKOUT Lines
	-- This is required if employee's labor group has been changed
	update dbo.XX_R22_IMAPS_TS_PREP_TEMP
	set acct_id= 
/*		ISNULL((SELECT distinct map.acct_id
				from XX_R22_ACCT_RECLASS map
				where map.lab_grp_type=empl_lab.lab_grp_type
				and map.acct_grp_cd='RRD' -- All Backout accounts will have RRD PAG
				and line_type='BACKOUT'),'99-99-99') */
		ISNULL((SELECT distinct map.acct_id
			from XX_R22_ACCT_RECLASS map
			where map.lab_grp_type=empl_lab.lab_grp_type
			-- Modified by 1/8/09 Added PMP
			and map.acct_grp_cd IN('RRD','PMP') -- All Backout accounts will have RRD, PMP PAG
            and map.acct_grp_cd in 
            	(select distinct acct_grp_cd from IMAR.DELTEK.proj 
                    where company_id=2 
                    and rtrim(org_id)=rtrim(empl_lab.org_id) 
                    and substring(proj_id,1,4)='RRDE'
                    and empl_lab.org_id is not null
                    and proj_abbrv_cd is not null 
                    and rtrim(proj_abbrv_cd)<>'')
            and line_type='BACKOUT'),'99-99-99')				
	FROM dbo.XX_R22_IMAPS_TS_PREP_TEMP ts
	INNER JOIN IMAR.DELTEK.EMPL_LAB_INFO empl_lab
	on
	(ts.empl_id = empl_lab.empl_id
		and 
		(
			(ts.S_TS_TYPE_CD = 'R' AND cast(ts.TS_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
			OR
			(ts.S_TS_TYPE_CD in ('C','N','D') AND cast(ts.CORRECTING_REF_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
		)
	)
	where exmpt_fl='Y'
	AND ts.notes  like '%-C-%'
	
	
	--UPDATE ORG_ID FROM PROJ_TS_DFLT
	--FOR DIRECT PROJECTS
	UPDATE XX_R22_IMAPS_TS_PREP_TEMP
	SET ORG_ID = PTD.ORG_ID
	FROM 
	XX_R22_IMAPS_TS_PREP_TEMP TS
	INNER JOIN
	IMAR.DELTEK.PROJ_TS_DFLT PTD
	ON
	(PTD.PROJ_ID = (SELECT PROJ_ID FROM IMAR.DELTEK.PROJ WHERE PROJ_ABBRV_CD = TS.PROJ_ABBRV_CD AND COMPANY_ID=2)
	)



	PRINT '7'

	-- This step will split TS lines for newly mapped employees only
	DECLARE @out_STATUS_DESCRIPTION SYSNAME
	
 	-- Modified CR-1649
	EXEC @RET_CODE = XX_R22_INSERT_TS_RESPROC_MISCODE_SP 

 	IF @RET_CODE <> 0
         BEGIN
            -- Attempt to insert a XX_IMAPS_TS_PREP_TEMP record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
               @in_SQLServer_error_code = @RET_CODE,
               @in_placeholder_value1   = 'insert',
               @in_placeholder_value2   = 'XX_R22_IMAPS_TS_PREP_TEMP Research process',
               @in_calling_object_name  = 'XX_R22_ETIME_MISCODE_CREATE_FILE',
               @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END

	PRINT '8'
    
    --Begin CR-2419 3/20/10
    EXEC @RET_CODE = XX_R22_ETIME_SIMULATE_TSHDRSEQ_SP
 	IF @RET_CODE <> 0
         BEGIN
            -- Attempt to insert a XX_IMAPS_TS_PREP_TEMP record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
               @in_SQLServer_error_code = @RET_CODE,
               @in_placeholder_value1   = 'insert',
               @in_placeholder_value2   = 'XX_R22_IMAPS_TS_PREP_TEMP Research MISCODE/TSHDRSEQ',
               @in_calling_object_name  = 'XX_R22_ETIME_MISCODE_CREATE_FILE',
               @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END


    --End CR-2419 3/20/10
    
    
	--8.  EXPORT TS_PREP.TXT FILE
	DECLARE @WORDS SYSNAME
	
	EXEC @RET_CODE = DBO.XX_EXEC_SHELL_CMD_OSUSER  -- Modified CR-3749
		@IN_IMAPS_DB_NAME = 'IMAPSSTG',
		@IN_IMAPS_TABLE_OWNER = 'DBO',
		@IN_SOURCE_TABLE = 'XX_R22_IMAPS_TS_PREP_TEMP',
		@IN_FORMAT_FILE = @FORMATFILE,
		@IN_OUTPUT_FILE = @FILE_TO_REPROCESS,
		--@IN_USR_PASSWORD = @PASSWORD,  -- Modified CR-3749
		@OUT_STATUS_DESCRIPTION = @WORDS
	
	IF @RET_CODE <> 0
	BEGIN
		PRINT @WORDS
		GOTO BL_ERROR_HANDLER
	END


	PRINT '9'

	-- Begin CR-1649 Changes
	--8. Update employee as active, Will not mark as In-active during this miscode process
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

		update IMAR.DELTEK.empl
		set s_empl_status_cd='ACT'
		--select * from IMAR.DELTEK.empl
		where company_id=@in_company_id
		and empl_id in (select empl_id from xx_r22_imaps_ts_prep_temp)
		-- End Div22 Changes	

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


	
	
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
IF OBJECT_ID('dbo.XX_R22_ETIME_MISCODE_CREATE_FILE_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_ETIME_MISCODE_CREATE_FILE_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_ETIME_MISCODE_CREATE_FILE_SP >>>'
go

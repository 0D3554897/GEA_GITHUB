USE [IMAPSStg]
GO
/****** Object:  StoredProcedure [dbo].[XX_FIWLR_PROCESS_JE_SP]    Script Date: 11/02/2007 09:01:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_PROCESS_JE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_PROCESS_JE_SP]
GO


CREATE PROCEDURE [dbo].[XX_FIWLR_PROCESS_JE_SP] (
@out_STATUS_DESCRIPTION sysname = NULL OUTPUT
)
AS
BEGIN
/*
1M Changes:

Re-optimized to mimic Miscode Reprocessing logic

*/
DECLARE @SP_NAME                 sysname,
        @DIV_16_COMPANY_ID       varchar(10),
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
	@INTERFACE_NAME		 sysname,
	@ret_code		 int,
	@count			 int,
	@fy_cd			 char(4),
	@pd_no			 smallint,
	@sub_pd_no		 smallint,
	@ap_acct_desc		 varchar(30),
	@cash_acct_desc		 varchar(30),
	@source_group		 char(2),
	@pay_terms		 varchar(15),
	@source_wwer			 char(3),
	@vchrlno		 int,
	@s_status_cd		 char(1),
	@sjnlcd 		char(3), 
	@jeno			int,
	@jelno			int


	SET @INTERFACE_NAME = 'FIWLR'
	SET @SP_NAME = 'XX_FIWLR_PROCESS_JE_SP'
	SELECT
		@ap_acct_desc	= NULL, 
		@cash_acct_desc = NULL,
		@pay_terms = 'NET 30',
		@source_group = 'JE',  --changed to JE later
		@source_wwer = '005',
		@vchrlno = 1,
		@s_status_cd = 'U',
		@sjnlcd = 'AJE',
		@jeno = 1,
		@jelno = 0 ,
		@ret_code = 1


	-- CP600000322_Begin
	--DECLARE @DIV_16_COMPANY_ID varchar(10)

	SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
	  FROM dbo.XX_PROCESSING_PARAMETERS
	 WHERE PARAMETER_NAME = 'COMPANY_ID'
	   AND INTERFACE_NAME_CD = 'FIWLR'
	-- CP600000322_End	


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'GRAB FISCAL ACCOUNTING'
	SET @ERROR_MSG_PLACEHOLDER2 = 'CALENDAR DATA'
	
	SELECT	@fy_cd 		= fiscal_year, 
			@pd_no 		= CAST(period as SMALLINT), 
			@sub_pd_no	= CAST(sub_pd_no as SMALLINT)
	FROM	dbo.xx_fiwlr_rundate_acctcal
	WHERE 	CONVERT(VARCHAR(10),GETDATE(),120) BETWEEN run_start_date AND run_end_date



	/*TIME FOR JE STUFF*/
	SET @source_group = 'JE'

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT INTO'
	SET @ERROR_MSG_PLACEHOLDER2 = 'X2_AOPUTLJE_INP_TR_WORKING'

	INSERT INTO dbo.X2_AOPUTLJE_INP_TR_WORKING ( 
		status_record_num,
		unique_record_num,		
		grouping_clause,
		major, source, doc_no,
		s_status_cd,je_ln_no,inp_je_no,s_jnl_cd,
		fy_cd,pd_no,
		sub_pd_no,rvrs_fl,je_desc,trn_amt,
		acct_id,org_id,
		je_trn_desc,
		proj_id,ref_struc_1_id,ref_struc_2_id,cycle_dc,org_abbrv_cd,
		proj_abbrv_cd,proj_acct_abbrv_cd,update_obd_fl,
		notes,
		time_stamp)
	SELECT	a.status_rec_no,
		a.ident_rec_no,		
		CAST(a.status_rec_no AS VARCHAR)+ ',' +a.reference3,
		a.major, a.source, a.voucher_no,
		NULL,@jelno,@jeno,@sjnlcd,
		@fy_cd, @pd_no, 
		@sub_pd_no,'N', 
		'F' + ',' + a.major + ',' + RTRIM(LTRIM(a.source)) + ',' + RTRIM(LTRIM(a.voucher_no)),a.amount, 
		a.acct_id,--NULL, Commented by Clare Robbins on 2/2/06
		a.org_id, --Added by Clare Robbins on 2/2/06 
		(RTRIM(LTRIM(CAST(a.status_rec_no AS CHAR))) + ',' + a.source + ',' + a.major + ',' + a.voucher_no ),


		--KM 1M changes
		--temporarily place division in ref_struc_1_id 
		NULL,a.division,NULL,NULL,NULL,

		a.proj_abbr_cd,NULL,'Y',
			/*0*/  ISNULL(RTRIM(LTRIM(a.minor)), ' ') + ',' 
			/*1*/+ ISNULL(RTRIM(LTRIM(a.subminor)), ' ') + ',' 
			/*2*/+ ISNULL(RTRIM(LTRIM(a.analysis_code)), ' ') + ',' 
			/*3*/+ ISNULL(RTRIM(LTRIM(a.project_no)), ' ') + ',' 
			/*4*/+ ISNULL(RTRIM(LTRIM(a.department)), ' ') + ',' 
			/*5*/+ ISNULL(RTRIM(LTRIM(a.acct_month)), ' ') + ',' 
			/*6*/+ ISNULL(RTRIM(LTRIM(a.acct_year)), ' ') + ',' 
			/*7*/+ ISNULL(RTRIM(LTRIM(a.ap_idx)), ' ') + ',' 
			/*8*/+ ISNULL(RTRIM(LTRIM(a.po_no)), ' ') + ',' 
			/*9*/+ ISNULL(RTRIM(LTRIM(a.inv_no)), ' ') + ',' 
			/*10*/+ ISNULL(RTRIM(LTRIM(REPLACE(a.description1, ',', ';'))), ' ') + ',' 
			/*11*/+ ISNULL(RTRIM(LTRIM(REPLACE(a.description2, ',', ';'))), ' ') + ',' 
			/*12*/+ ISNULL(RTRIM(LTRIM(a.accountant_id)), ' ') + ',' 
			/*13*/+ ISNULL(RTRIM(LTRIM(a.etv_code)), ' ') + ',' 
			/*14*/+ ISNULL(RTRIM(LTRIM(a.input_type)), ' ') + ',' 
			/*15*/+ ISNULL(RTRIM(LTRIM(a.ap_doc_type)), ' ') + ',' 
			/*16*/+ ISNULL(RTRIM(LTRIM(a.employee_no)), ' ') + ',' 
			/*17*/+ ISNULL(RTRIM(LTRIM(REPLACE(a.emp_lastname, ',', ';'))), ' ') + ',' 
			/*18*/+ ISNULL(RTRIM(LTRIM(REPLACE(a.emp_firstname, ',', ';'))), ' ') + ',' 
			/*19*/+ ISNULL(RTRIM(LTRIM(a.vendor_id)), ' ') + ',' 
			/*20*/+ ISNULL(RTRIM(LTRIM(REPLACE(a.vend_name, ',', ';'))),'') + ',' 
			/*21*/+ ISNULL(RTRIM(LTRIM(a.val_nval_cd)), ' ') + ','
			/*22*/+ ISNULL(RTRIM(LTRIM(a.fiwlr_inv_date)), ' ') + ','
			/*23*/+ ISNULL(RTRIM(LTRIM(a.wwer_exp_dt)), ' ') + ','
			/*24*/+ CAST(a.ident_rec_no as varchar) + ','
			,GETDATE()
	FROM 	dbo.XX_FIWLR_USDET_V3 a
	WHERE 	a.source_group 	= @source_group
	AND 	CAST(a.status_rec_no AS VARCHAR)+','+a.reference3 in
		(SELECT CAST(status_rec_no AS VARCHAR)+','+reference3
		 FROM XX_FIWLR_USDET_V3 
		 WHERE source_group = @source_group)
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE X2_AOPUTLJE_INP_TR_WORKING'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH UNIQUE REC_NO & INP_JE_NO'

	UPDATE 	X2_AOPUTLJE_INP_TR_WORKING
	SET	inp_je_no = (SELECT MAX(REC_NO) FROM X2_AOPUTLJE_INP_TR_WORKING
 			     WHERE grouping_clause = a.grouping_clause)
	FROM	X2_AOPUTLJE_INP_TR_WORKING a
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE JE_LN_NO'
	SET @ERROR_MSG_PLACEHOLDER2 = 'IN X2_AOPUTLJE_INP_TR_WORKING'

	UPDATE X2_AOPUTLJE_INP_TR_WORKING
	SET JE_LN_NO = (SELECT COUNT(1) FROM X2_AOPUTLJE_INP_TR_WORKING WHERE INP_JE_NO = cur.INP_JE_NO AND REC_NO >= cur.REC_NO)
	FROM X2_AOPUTLJE_INP_TR_WORKING cur
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR	



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT OFFSETTING TRANSACTIONS'
	SET @ERROR_MSG_PLACEHOLDER2 = 'INTO X2_AOPUTLJE_INP_TR_WORKING'
	
	INSERT INTO X2_AOPUTLJE_INP_TR_WORKING
	( STATUS_RECORD_NUM, UNIQUE_RECORD_NUM, 
	 INP_JE_NO, JE_LN_NO,
	 S_STATUS_CD, S_JNL_CD, FY_CD, PD_NO, SUB_PD_NO,
	 RVRS_FL, JE_DESC, TRN_AMT, ACCT_ID, 
	 ORG_ID,
	 JE_TRN_DESC,
	 UPDATE_OBD_FL, NOTES, TIME_STAMP
	)
	SELECT STATUS_RECORD_NUM, 0, 
	INP_JE_NO, MAX(JE_LN_NO)+1,
	NULL /*S_STATUS_CD MUST BE NULL?!!?*/, 'AJE', FY_CD, PD_NO, SUB_PD_NO,
	'N', JE_DESC, -1.0*SUM(TRN_AMT), 
	(SELECT GENL_ID

	 FROM	IMAPS.Deltek.GENL_UDEF
	 WHERE	S_TABLE_ID = 'ACCT'
	 AND	UDEF_LBL_KEY = 32

	 AND	COMPANY_ID = @DIV_16_COMPANY_ID -- CP600000200

	 AND	UDEF_TXT = a.MAJOR), 

	ref_struc_1_id, --1M changes division temporarily placed in ref_struc_1_id

	CAST(STATUS_RECORD_NUM AS VARCHAR)+','+SOURCE+','+MAJOR+','+DOC_NO,
	'Y', 'Balancing Transaction', CURRENT_TIMESTAMP
	FROM X2_AOPUTLJE_INP_TR_WORKING a
	GROUP BY INP_JE_NO, JE_DESC, FY_CD, PD_NO, SUB_PD_NO, 
	STATUS_RECORD_NUM, SOURCE, MAJOR, DOC_NO, 
	ref_struc_1_id --division temporarily placed in ref_struc_1_id
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR	


	update X2_AOPUTLJE_INP_TR_WORKING
	set ref_struc_1_id = null

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT INTO'
	SET @ERROR_MSG_PLACEHOLDER2 = 'DELTEK.AOPUTLAP_INP_HDR'
	INSERT INTO IMAPS.DELTEK.AOPUTLAP_INP_HDR
	( REC_NO, S_STATUS_CD, VCHR_NO, FY_CD, PD_NO, SUB_PD_NO,
	  VEND_ID, TERMS_DC, INVC_ID, 
	 INVC_DT_FLD,  INVC_AMT, 
	 DISC_DT_FLD, DISC_PCT_RT, DISC_AMT, 
	 DUE_DT_FLD, HOLD_VCHR_FL, PAY_WHEN_PAID_FL, PAY_VEND_ID, PAY_ADDR_DC,
	  PO_ID, PO_RLSE_NO, RTN_RATE, AP_ACCT_DESC, CASH_ACCT_DESC, S_INVC_TYPE,
	  SHIP_AMT, CHK_FY_CD, CHK_PD_NO, CHK_SUB_PD_NO, CHK_NO, 
	 CHK_DT_FLD, CHK_AMT, DISC_TAKEN_AMT, 
	 INVC_POP_DT_FLD, PRINT_NOTE_FL, JNT_PAY_VEND_NAME, NOTES, 
     TIME_STAMP, SEP_CHK_FL,
	 COMPANY_ID) --CP11299
	SELECT 
	 REC_NO, S_STATUS_CD, VCHR_NO, FY_CD, PD_NO, SUB_PD_NO,
	 VEND_ID, TERMS_DC, INVC_ID, INVC_DT, INVC_AMT, DISC_DT, DISC_PCT_RT,
	 DISC_AMT, DUE_DT, HOLD_VCHR_FL, PAY_WHEN_PAID_FL, PAY_VEND_ID, PAY_ADDR_DC,
	 PO_ID, PO_RLSE_NO, RTN_RATE, AP_ACCT_DESC, CASH_ACCT_DESC, S_INVC_TYPE,
	 SHIP_AMT, CHK_FY_CD, CHK_PD_NO, CHK_SUB_PD_NO, CHK_NO, CHK_DT, CHK_AMT, 
	 DISC_TAKEN_AMT, INVC_POP_DT, PRINT_NOTE_FL, JNT_PAY_VEND_NAME, NOTES, 
     TIME_STAMP, SEP_CHK_FL,
		 '1' --CP11299
	FROM 	X2_AOPUTLAP_INP_HDR_WORKING	
	ORDER BY VCHR_NO
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT INTO'
	SET @ERROR_MSG_PLACEHOLDER2 = 'DELTEK.AOPUTLAP_INP_DETL'
	INSERT INTO IMAPS.DELTEK.AOPUTLAP_INP_DETL
	(REC_NO, S_STATUS_CD, VCHR_NO, FY_CD, VCHR_LN_NO, ACCT_ID, ORG_ID, PROJ_ID,
	 REF1_ID, REF2_ID, CST_AMT, TAXABLE_FL, S_TAXABLE_CD, SALES_TAX_AMT, DISC_AMT,
	 USE_TAX_AMT, AP_1099_FL, S_AP_1099_TYPE_CD, VCHR_LN_DESC, ORG_ABBRV_CD, 
	 PROJ_ABBRV_CD, PROJ_ACCT_ABBRV_CD, NOTES, TIME_STAMP,
	 COMPANY_ID) --CP11299
	SELECT
	 REC_NO, S_STATUS_CD, VCHR_NO, FY_CD, VCHR_LN_NO, ACCT_ID, ORG_ID, PROJ_ID,
	 REF1_ID, REF2_ID, CST_AMT, TAXABLE_FL, S_TAXABLE_CD, SALES_TAX_AMT, DISC_AMT,
	 USE_TAX_AMT, AP_1099_FL, S_AP_1099_TYPE_CD, VCHR_LN_DESC, ORG_ABBRV_CD, 
	 PROJ_ABBRV_CD, PROJ_ACCT_ABBRV_CD, NOTES, TIME_STAMP,
	 '1' --CP11299
	FROM X2_AOPUTLAP_INP_DETL_WORKING
	ORDER BY VCHR_NO, VCHR_LN_NO
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT INTO'
	SET @ERROR_MSG_PLACEHOLDER2 = 'DELTEK.AOPUTLJE_INP_TR'
	INSERT INTO IMAPS.DELTEK.AOPUTLJE_INP_TR
	(REC_NO, S_STATUS_CD, JE_LN_NO, INP_JE_NO, S_JNL_CD, FY_CD, PD_NO, SUB_PD_NO,
	 RVRS_FL, JE_DESC, TRN_AMT, ACCT_ID, ORG_ID, JE_TRN_DESC, PROJ_ID, REF_STRUC_1_ID,
	 REF_STRUC_2_ID, CYCLE_DC, ORG_ABBRV_CD, PROJ_ABBRV_CD, PROJ_ACCT_ABBRV_CD, 
	 UPDATE_OBD_FL, NOTES, TIME_STAMP,
	 COMPANY_ID) --CP11299
	SELECT
	 REC_NO, S_STATUS_CD, JE_LN_NO, INP_JE_NO, S_JNL_CD, FY_CD, PD_NO, SUB_PD_NO,
	 RVRS_FL, JE_DESC, TRN_AMT, ACCT_ID, ORG_ID, JE_TRN_DESC, PROJ_ID, REF_STRUC_1_ID,
	 REF_STRUC_2_ID, CYCLE_DC, ORG_ABBRV_CD, PROJ_ABBRV_CD, PROJ_ACCT_ABBRV_CD, 
	 UPDATE_OBD_FL, NOTES, TIME_STAMP,
	 '1' --CP11299
	FROM X2_AOPUTLJE_INP_TR_WORKING
	ORDER BY INP_JE_NO, JE_LN_NO
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


-- CP600000200 Begin



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'TRUNCATE PREPROCESSOR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WORKING TABLES ON IMAPSSTG'
	
	TRUNCATE TABLE X2_AOPUTLAP_INP_HDR_WORKING
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	TRUNCATE TABLE X2_AOPUTLAP_INP_DETL_WORKING
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	TRUNCATE TABLE X2_AOPUTLJE_INP_TR_WORKING
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	

RETURN 0

ERROR:


PRINT @out_STATUS_DESCRIPTION

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_number,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

PRINT @out_STATUS_DESCRIPTION


RETURN 1


END




GO



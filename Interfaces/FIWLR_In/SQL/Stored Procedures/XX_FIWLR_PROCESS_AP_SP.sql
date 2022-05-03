USE [IMAPSStg]
GO
/****** Object:  StoredProcedure [dbo].[XX_FIWLR_PROCESS_AP_SP]    Script Date: 11/02/2007 09:01:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_PROCESS_AP_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_PROCESS_AP_SP]
GO


CREATE PROCEDURE [dbo].[XX_FIWLR_PROCESS_AP_SP] (
@out_STATUS_DESCRIPTION sysname = NULL OUTPUT
)
AS
BEGIN
/*
1M Changes:

Re-optimized to mimic Miscode Reprocessing logic
Also includes adding new vendors to Costpoint

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
	SET @SP_NAME = 'XX_FIWLR_PROCESS_AP_SP'
	SELECT
		@ap_acct_desc	= NULL, 
		@cash_acct_desc = NULL,
		@pay_terms = 'NET 30',
		@source_group = 'AP',  --changed to JE later
		@source_wwer = '005',
		@vchrlno = 1,
		@s_status_cd = 'U',
		@sjnlcd = 'AJE',
		@jeno = 1,
		@jelno = 0 ,
		@ret_code = 1



	--the different date formats is messing everything up
	--let's be consistent in CP6
	update xx_fiwlr_usdet_v3
	set fiwlr_inv_Date = extract_date
	where len(fiwlr_inv_date) = 0

	update xx_fiwlr_usdet_v3
	set fiwlr_inv_date = left(fiwlr_inv_date, 4) + '-' + substring(fiwlr_inv_date, 5, 2) + '-' + right(fiwlr_inv_date, 2)
	where len(fiwlr_inv_date)=8



	/* UPDATE FOR MAX LINE ITEMS PER COSTPOINT DOCUMENT */

	--1M change, include division in grouping

	--GROUPING AP WWER
	UPDATE XX_FIWLR_USDET_V3
	SET REFERENCE3 = 
	(SELECT MAX(IDENT_REC_NO) FROM XX_FIWLR_USDET_V3  
	WHERE		
	--1M changes
	DIVISION = FIWLR.DIVISION
	AND		

	STATUS_REC_NO = FIWLR.STATUS_REC_NO  
	AND	    SOURCE_GROUP = FIWLR.SOURCE_GROUP  
	AND		VOUCHER_NO = FIWLR.VOUCHER_NO  
	AND		SOURCE = FIWLR.SOURCE  
	AND		MAJOR = FIWLR.MAJOR  
	AND		ISNULL(INV_NO, '') = ISNULL(FIWLR.INV_NO, '')
	--AND		EXTRACT_DATE = FIWLR.EXTRACT_DATE  
	AND		ISNULL(FIWLR_INV_DATE, '') = ISNULL(FIWLR.FIWLR_INV_DATE, '')  
	AND 		ISNULL(PO_NO, '') = ISNULL(FIWLR.PO_NO, '')
	AND 		ISNULL(VENDOR_ID, '')= ISNULL(FIWLR.VENDOR_ID, '')
	AND		ISNULL(EMPLOYEE_NO, '') = ISNULL(FIWLR.EMPLOYEE_NO, ''))	
	FROM 	XX_FIWLR_USDET_V3 FIWLR
	WHERE 	SOURCE_GROUP = 'AP'
	AND	SOURCE IN ('005', 'N16')
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	--GROUPING AP NONWWER
	UPDATE XX_FIWLR_USDET_V3
	SET REFERENCE3 = 
	(SELECT MAX(IDENT_REC_NO) FROM XX_FIWLR_USDET_V3  
	WHERE		
	--1M changes
	DIVISION = FIWLR.DIVISION
	AND		
	STATUS_REC_NO = FIWLR.STATUS_REC_NO  
	AND	    	SOURCE_GROUP = FIWLR.SOURCE_GROUP  
	AND		VOUCHER_NO = FIWLR.VOUCHER_NO  
	AND		SOURCE = FIWLR.SOURCE  
	AND		MAJOR = FIWLR.MAJOR  
	AND		ISNULL(INV_NO, '') = ISNULL(FIWLR.INV_NO, '')
	AND		EXTRACT_DATE = FIWLR.EXTRACT_DATE  
	AND		ISNULL(FIWLR_INV_DATE, '') = ISNULL(FIWLR.FIWLR_INV_DATE, '')  
	AND 		ISNULL(PO_NO, '') = ISNULL(FIWLR.PO_NO, '')
	AND 		ISNULL(VENDOR_ID, '')= ISNULL(FIWLR.VENDOR_ID, ''))
	--AND		ISNULL(EMPLOYEE_NO, '') = ISNULL(FIWLR.EMPLOYEE_NO, ''))	
	FROM 	XX_FIWLR_USDET_V3 FIWLR
	WHERE 	SOURCE_GROUP = 'AP'
	AND	SOURCE NOT IN ('005', 'N16')
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	--GROUPING je
	UPDATE XX_FIWLR_USDET_V3
	SET REFERENCE3 = 
	(SELECT MAX(IDENT_REC_NO) FROM XX_FIWLR_USDET_V3  
	WHERE		
	--1M changes
	DIVISION = FIWLR.DIVISION
	AND		

	STATUS_REC_NO = FIWLR.STATUS_REC_NO  
	AND	    	SOURCE_GROUP = FIWLR.SOURCE_GROUP  
	AND		VOUCHER_NO = FIWLR.VOUCHER_NO  
	AND		SOURCE = FIWLR.SOURCE  
	AND		MAJOR = FIWLR.MAJOR)
	--AND		INV_NO = FIWLR.INV_NO  
	--AND		EXTRACT_DATE = FIWLR.EXTRACT_DATE  
	--AND		FIWLR_INV_DATE = FIWLR.FIWLR_INV_DATE  
	--AND 		PO_NO = FIWLR.PO_NO  
	--AND 		VENDOR_ID = FIWLR.VENDOR_ID
	--AND		EMPLOYEE_NO = FIWLR.EMPLOYEE_NO)	
	FROM 	XX_FIWLR_USDET_V3 FIWLR
	WHERE 	SOURCE_GROUP = 'JE'
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	
	DECLARE @STATUS_REC_NO int,
		@REFERENCE3 varchar(125),
		@LINE_COUNT int
	
	START_MAX_LINES_CURSOR:
	
	DECLARE MAX_LINES_CURSOR CURSOR FAST_FORWARD FOR
		select status_rec_no, reference3, count(1)
		from XX_FIWLR_USDET_V3
		group by status_rec_no, reference3
		having count(1) > 1497
	
	OPEN MAX_LINES_CURSOR
	FETCH MAX_LINES_CURSOR
	INTO @STATUS_REC_NO, @REFERENCE3, @LINE_COUNT
	
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		DECLARE @CUTOFF_IDENT_REC_NO int
		
		SELECT top 1497 @CUTOFF_IDENT_REC_NO = IDENT_REC_NO
		FROM 	XX_FIWLR_USDET_V3
		WHERE 	STATUS_REC_NO = @STATUS_REC_NO
		AND	REFERENCE3 = @REFERENCE3
		ORDER BY IDENT_REC_NO
	
		UPDATE 	XX_FIWLR_USDET_V3
		SET	REFERENCE3 = REFERENCE3 + 'M'
		WHERE 	STATUS_REC_NO = @STATUS_REC_NO
		AnD	REFERENCE3 = @REFERENCE3
		AND	IDENT_REC_NO > @CUTOFF_IDENT_REC_NO
			
		FETCH MAX_LINES_CURSOR
		INTO @STATUS_REC_NO, @REFERENCE3, @LINE_COUNT
	END
	
	CLOSE MAX_LINES_CURSOR
	DEALLOCATE MAX_LINES_CURSOR
	
	select status_rec_no, reference3, count(1)
		from XX_FIWLR_USDET_V3
		group by status_rec_no, reference3
		having count(1) > 1497
	
	IF @@ROWCOUNT <> 0 GOTO START_MAX_LINES_CURSOR

	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE TO NULL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'INVNO'

	update XX_FIWLR_USDET_V3
	set inv_no = null
	where inv_no = 'null' 

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE TO NULL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FIWLR_INV_DATE'
	
	update XX_FIWLR_USDET_V3
	set FIWLR_INV_DATE = null
	where FIWLR_INV_DATE = 'null'

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE TO NULL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'PO_NO'

	update XX_FIWLR_USDET_V3
	set PO_NO = null
	where PO_NO = 'null'

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE TO NULL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'vendor_id'

	update XX_FIWLR_USDET_V3
	set vendor_id = null
	where vendor_id = 'null'

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR





	SET @IMAPS_ERROR_NUMBER = 204 -- Attempt to %1 %2 failed.
	SET @ERROR_MSG_PLACEHOLDER1 = 'access required processing parameter COMPANY_ID'
	SET @ERROR_MSG_PLACEHOLDER2 = 'for FIWLR Interface'

	SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
	FROM 	dbo.XX_PROCESSING_PARAMETERS
	WHERE 	PARAMETER_NAME = 'COMPANY_ID'
	AND	INTERFACE_NAME_CD = 'FIWLR'

	SET @count = @@ROWCOUNT

	IF @count = 0 OR LEN(RTRIM(LTRIM(@DIV_16_COMPANY_ID))) = 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY AP PREPROCESSOR TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'IS EMPTY'

	SELECT 	@count = count(1)
	FROM 	IMAPS.DELTEK.AOPUTLAP_INP_HDR
	
	IF @count <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY AP PREPROCESSOR TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'IS EMPTY'

	SELECT 	@count = count(1)
	FROM 	IMAPS.DELTEK.AOPUTLAP_INP_DETL
	
	IF @count <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY JE PREPROCESSOR TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'IS EMPTY'

	SELECT 	@count = count(1)
	FROM 	IMAPS.DELTEK.AOPUTLJE_INP_TR
	
	IF @count <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'AOPUTLAP_INP_HDR_WORKING IS EMPTY'

	SELECT 	@count = COUNT(1)
	FROM 	X2_AOPUTLAP_INP_HDR_WORKING
	
	IF @count <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'AOPUTLAP_INP_DETL IS EMPTY'
	
	SELECT 	@count = COUNT(1)
	FROM 	IMAPS.DELTEK.AOPUTLAP_INP_DETL
	
	IF @count <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'AOPUTLAP_INP_DETL_WORKING IS EMPTY'

	SELECT 	@count = COUNT(1)
	FROM 	X2_AOPUTLAP_INP_DETL_WORKING
	


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'GRAB FISCAL ACCOUNTING'
	SET @ERROR_MSG_PLACEHOLDER2 = 'CALENDAR DATA'
	
	SELECT	@fy_cd 		= fiscal_year, 
			@pd_no 		= CAST(period as SMALLINT), 
			@sub_pd_no	= CAST(sub_pd_no as SMALLINT)
	FROM	dbo.xx_fiwlr_rundate_acctcal
	WHERE 	CONVERT(VARCHAR(10),GETDATE(),120) BETWEEN run_start_date AND run_end_date

	DECLARE @BALANCING_ORG_ID varchar(30)
	SELECT 	@BALANCING_ORG_ID = PARAMETER_VALUE
	FROM 	XX_PROCESSING_PARAMETERS
	WHERE 	INTERFACE_NAME_CD = 'FIWLR'
	AND 	PARAMETER_NAME = 'BALANCING_ORG_ID'

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR



	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT INTO'
	SET @ERROR_MSG_PLACEHOLDER2 = 'X2_AOPUTLAP_INP_HDR_WORKING'

	--1M changes, include division in grouping
	INSERT INTO dbo.X2_AOPUTLAP_INP_HDR_WORKING
		(
		status_record_num,
		grouping_clause,
		s_status_cd,  --added by Clare Robbins on 3/29/06
		fy_cd, pd_no, sub_pd_no, vend_id, 
		terms_dc, invc_id, 
		invc_dt, 
		invc_amt, 
		disc_dt, disc_pct_rt, disc_amt, due_dt, 
		hold_vchr_fl, pay_when_paid_fl, pay_vend_id, pay_addr_dc, 
		po_id, po_rlse_no, rtn_rate, ap_acct_desc, 
		cash_acct_desc, s_invc_type, ship_amt, chk_fy_cd, 
		chk_pd_no, chk_sub_pd_no, chk_no, chk_dt, 
		chk_amt, disc_taken_amt, invc_pop_dt, print_note_fl, 
		jnt_pay_vend_name, notes, time_stamp, sep_chk_fl)
	SELECT  
		a.status_rec_no, 
		CAST(a.status_rec_no AS VARCHAR)+ ',' +a.reference3,
		@s_status_cd,
		@fy_cd, @pd_no, @sub_pd_no, a.vendor_id,
		@pay_terms, a.inv_no, 
		a.fiwlr_inv_date, 
		.00,
		NULL, NULL, NULL, NULL, 
		'N', 'N', NULL, NULL, 
		a.po_no, NULL, 0, @ap_acct_desc,
		@cash_acct_desc, NULL, 0, NULL, 
		NULL, NULL, NULL, NULL, 
		0, 0, NULL, 'N', 
		NULL, RTRIM(LTRIM(CAST(a.status_rec_no as char))) + ',' + RTRIM(LTRIM(a.major)) + '-' +  RTRIM(LTRIM(a.voucher_no) + ',' + LTRIM(RTRIM(a.source)) + ',' + LTRIM(RTRIM(a.division))), getdate(),'N'
	FROM 	dbo.XX_FIWLR_USDET_V3 a
	WHERE 	a.source_group 	= @source_group
	GROUP BY 
		a.division,
		a.status_rec_no,
		a.voucher_no,
		a.major,-- Added by Veera on 11/07/2005 - Defect : DEV00000243
		a.vendor_id,
		a.fiwlr_inv_date, 
		a.extract_date,
		a.inv_no,
		a.po_no,
		a.source,
		a.source_group,
		a.vend_name,
		a.reference3
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE X2_AOPUTLAP_INP_HDR_WORKING'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH UNIQUE REC_NO & VCHR_NO'

	UPDATE 	X2_AOPUTLAP_INP_HDR_WORKING
	SET	VCHR_NO = REC_NO
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT INTO'
	SET @ERROR_MSG_PLACEHOLDER2 = 'X2_AOPUTLAP_INP_DETL_WORKING'
	
	INSERT INTO dbo.X2_AOPUTLAP_INP_DETL_WORKING
		(
		status_record_num,
		unique_record_num,
		grouping_clause,
		major,
		source,
		doc_no,
		s_status_cd, --added by Clare Robbins on 3/29/06
		vchr_no, fy_cd, 
		vchr_ln_no, acct_id, org_id, 
		proj_id, ref1_id, ref2_id, 
		cst_amt, taxable_fl, s_taxable_cd,
		sales_tax_amt, disc_amt, use_tax_amt, 
		ap_1099_fl, s_ap_1099_type_cd, vchr_ln_desc, 
		org_abbrv_cd, 
		proj_abbrv_cd, proj_acct_abbrv_cd, 
		notes, 
		time_stamp)
	SELECT
		a.status_rec_no,
		a.ident_rec_no,
		CAST(a.status_rec_no AS VARCHAR)+ ',' +a.reference3,
		a.major,
		a.source,
		a.voucher_no,
		@s_status_cd, --added by Clare Robbins on 3/29/06
		b.vchr_no, b.fy_cd,
		1, a.acct_id, --NULL, Commented by Clare Robbins on 1/27/2006
		a.org_id, -- Added by Clare Robbins on 1/27/2006


		NULL, a.division, NULL,  --temporarily place division in ref1_id

		a.amount, 'N',  NULL,  -- CST_AMT, TAXABLE_FL, S_TAXABLE_CD,
		0, 0, 0,  
		'N', NULL, (RTRIM(LTRIM(CAST(a.status_rec_no AS CHAR))) + ',' + RTRIM(LTRIM(a.source)) + ',' + RTRIM(LTRIM(a.major)) + ',' + RTRIM(LTRIM(a.voucher_no))), 
	 	--a.org_id, 
		NULL,
		a.proj_abbr_cd, NULL,
			(
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
			),
			GETDATE()
	FROM	dbo.XX_FIWLR_USDET_V3 a
	inner join	
	dbo.X2_AOPUTLAP_INP_HDR_WORKING b
	on
		(
		b.grouping_clause = 
			(CAST(a.status_rec_no AS VARCHAR)+ ',' +a.reference3)
		) 
	ORDER BY b.vchr_no

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	
	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT BALANCING TRANSACTIONS'
	SET @ERROR_MSG_PLACEHOLDER2 = 'INTO X2_AOPUTLAP_INP_DETL_WORKING - FIWLR'

	INSERT INTO X2_AOPUTLAP_INP_DETL_WORKING
	( STATUS_RECORD_NUM, UNIQUE_RECORD_NUM, 
	  GROUPING_CLAUSE, MAJOR, SOURCE,
	  S_STATUS_CD, VCHR_NO, FY_CD, VCHR_LN_NO, 
	  ACCT_ID,
	  ORG_ID, CST_AMT, TAXABLE_FL, S_TAXABLE_CD, 
	  SALES_TAX_AMT, DISC_AMT, USE_TAX_AMT, AP_1099_FL,
	  VCHR_LN_DESC, NOTES )
	SELECT 
	STATUS_RECORD_NUM, 0, GROUPING_CLAUSE, MAJOR, SOURCE,
	@s_status_cd, VCHR_NO, FY_CD, MAX(VCHR_LN_NO)+1,
	(SELECT GENL_ID
	 FROM	IMAPS.Deltek.GENL_UDEF
	 WHERE	S_TABLE_ID = 'ACCT'
	 AND	UDEF_LBL_KEY = 32
	 AND	COMPANY_ID = @DIV_16_COMPANY_ID -- CP600000200
	 AND	UDEF_TXT = a.MAJOR),
	ref1_id, --division temporarily placed in ref1_id
	-1*SUM(CST_AMT), 'N', '', 
	.00, .00, .00, 'N', 
	CAST(STATUS_RECORD_NUM AS VARCHAR)+','+SOURCE+','+MAJOR+','+DOC_NO,
	'Balancing Transaction'
	FROM 	X2_AOPUTLAP_INP_DETL_WORKING a
	WHERE SOURCE <> 'N16'
	GROUP BY
	STATUS_RECORD_NUM, GROUPING_CLAUSE,
	VCHR_NO, FY_CD, MAJOR, SOURCE, DOC_NO, ref1_id --division temporarily placed in ref1_id
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	--division temporarily placed in ref1_id
	UPDATE 	X2_AOPUTLAP_INP_DETL_WORKING 
	SET REF1_ID = NULL
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR




	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT BALANCING TRANSACTIONS'
	SET @ERROR_MSG_PLACEHOLDER2 = 'INTO X2_AOPUTLAP_INP_DETL_WORKING - FIWN16'

	INSERT INTO X2_AOPUTLAP_INP_DETL_WORKING
	( STATUS_RECORD_NUM, UNIQUE_RECORD_NUM, 
	  GROUPING_CLAUSE, MAJOR, SOURCE,
	  S_STATUS_CD, VCHR_NO, FY_CD, VCHR_LN_NO, 
	  ACCT_ID, PROJ_ABBRV_CD, ORG_ABBRV_CD,
	  CST_AMT, TAXABLE_FL, S_TAXABLE_CD, 
	  SALES_TAX_AMT, DISC_AMT, USE_TAX_AMT, AP_1099_FL,
	  VCHR_LN_DESC, NOTES )
	SELECT 
	STATUS_RECORD_NUM, 0, GROUPING_CLAUSE, MAJOR, SOURCE,
	@s_status_cd, VCHR_NO, FY_CD, MAX(VCHR_LN_NO)+1, 
	(SELECT PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS
			   WHERE INTERFACE_NAME_CD = 'FIWLR'
			   AND	 PARAMETER_NAME = 'N16_CR_ACCT_ID'),
	PROJ_ABBRV_CD, ORG_ABBRV_CD, -1*SUM(CST_AMT), 'N', '', 
	.00, .00, .00, 'N', 
	CAST(STATUS_RECORD_NUM AS VARCHAR)+','+SOURCE+','+MAJOR+','+DOC_NO,
	'Balancing Transaction'
	FROM 	X2_AOPUTLAP_INP_DETL_WORKING a
	WHERE SOURCE = 'N16'
	GROUP BY
	STATUS_RECORD_NUM, GROUPING_CLAUSE, PROJ_ABBRV_CD, ORG_ABBRV_CD,
	VCHR_NO, FY_CD, MAJOR, SOURCE, DOC_NO
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	
-- CP600000200 Begin

/*
 * The following code is moved here from its former position where it is performed
 * right before ALL AP balancing transactions(for both FIWLR and FIWN16) are loaded
 * into working table X2_AOPUTLAP_INP_DETL_WORKING.
 */
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE X2_AOPUTLAP_INP_DETL_WORKING'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH UNIQUE VCHR_LN_NO'
	
	UPDATE X2_AOPUTLAP_INP_DETL_WORKING
	SET VCHR_LN_NO = (SELECT COUNT(1) FROM X2_AOPUTLAP_INP_DETL_WORKING WHERE VCHR_NO = cur.VCHR_NO AND REC_NO >= cur.REC_NO)
	FROM X2_AOPUTLAP_INP_DETL_WORKING cur
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

-- CP600000200 End








/*now we need to add new vendors to Costpoint*/
Declare @out_systemerror int

-- CP600000322_Begin
--DECLARE @DIV_16_COMPANY_ID varchar(10)

SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'FIWLR'
-- CP600000322_End	

DECLARE
	@vend_id		VARCHAR(10),
	@vend_name		VARCHAR(40),
	@in_vend_longname	VARCHAR(40), 
	@fiwlr_intername 	VARCHAR(20), 
	@fiwlr_rowversion	INT	  	,
	@doesvendorexists 	TINYINT


set		@fiwlr_intername  = 'FIWLR INTERFACE'
set		@fiwlr_rowversion = 5000 

DECLARE vend_cursor CURSOR FOR 
		SELECT 	
			vend_id
		FROM 	X2_AOPUTLAP_INP_HDR_WORKING h --imaps.deltek.aoputlap_inp_hdr h
		WHERE 0 = (select count(1) from imaps.deltek.vend where vend_id=h.vend_id)
		GROUP BY vend_id
		ORDER BY vend_id

	OPEN vend_cursor

	FETCH NEXT FROM vend_cursor INTO @vend_id 

	WHILE (@@fetch_status = 0)
	BEGIN


		SET @doesvendorexists = 0

		SELECT	@doesvendorexists = 1
		FROM	IMAPS.Deltek.VEND
		WHERE	vend_id = @vend_id
		AND 	COMPANY_ID = @DIV_16_COMPANY_ID

		IF @doesvendorexists <> 1 
			BEGIN
			 	SET @vend_name = NULL				

				SELECT 	TOP 1
					@vend_name = vend_name,
					@in_vend_longname = reference1
				FROM 	dbo.xx_fiwlr_usdet_v3
				WHERE 	vendor_id = @vend_id

				IF @vend_name IS NULL
					BEGIN
	  					SET @vend_name = @vend_id
					END
				EXEC @out_systemerror 	=  dbo.xx_add_vendor_sp
				     @in_vendorid 	= @vend_id,
				     @in_vendorname 	= @vend_name,
				     @in_vendorlongname = @in_vend_longname,
				     @in_modified_by 	= @fiwlr_intername,
				     @in_rowversion 	= @fiwlr_rowversion			
								


				IF   @out_systemerror <>0 
					GOTO ERROR
			END /* Vendor is inserted if does not exists in IMAPS */


	FETCH NEXT FROM vend_cursor INTO @vend_id 

	END 

	CLOSE vend_cursor
	DEALLOCATE vend_cursor



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


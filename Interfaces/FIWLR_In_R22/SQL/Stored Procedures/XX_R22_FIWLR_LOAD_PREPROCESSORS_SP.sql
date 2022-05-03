USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_LOAD_PREPROCESSORS_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_R22_FIWLR_LOAD_PREPROCESSORS_SP]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_FIWLR_LOAD_PREPROCESSORS_SP]    Script Date: 10/16/2008 14:13:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[XX_R22_FIWLR_LOAD_PREPROCESSORS_SP] (
@out_STATUS_DESCRIPTION sysname = NULL
)
AS
BEGIN
/************************************************************************************************/  
/* Name				: XX_R22_FIWLR_LOAD_PREPROCESSORS_SP										*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   							*/
/* Description    	: IMAPS FIW-LR Load Preprocessor tables with Research data					*/
/* Date				: August 10, 2008															*/
/* Notes			: IMAPS FIW-LR Load Preprocessors validates the Research data and loads		*/
/*					  into AP and JE Preprocessor Staging tables								*/
/* Prerequisites	: XX_R22_FIWLR_USDET_TEMP, X2_R22_AOPUTLAP_INP_HDR_WORKING,					*/
/*					  X2_R22_AOPUTLAP_INP_DETL_WORKING, X2_R22_AOPUTLJE_INP_TR_WORKING,			*/
/*					  X2_R22_AOPUTLJE_INP_VEN_WORKING Table(s) should be created.				*/
/*					  Access priveleges to AOPUTLAP_INP_HDR, AOPUTLAP_INP_DETL, AOPUTLJE_INP_TR */
/*					  AOPUTLJE_INP_VEN table(s) in DELTEK should be provided.					*/
/* Parameter(s)		: 																			*/
/*	Input			: Status Record Number														*/
/*	Output			: Error Code and Error Description											*/
/* Tables Updated	: XX_R22_FIWLR_USDET_TEMP, X2_R22_AOPUTLAP_INP_HDR_WORKING,					*/
/*					  X2_R22_AOPUTLAP_INP_DETL_WORKING, X2_R22_AOPUTLJE_INP_TR_WORKING,			*/
/*					  X2_R22_AOPUTLJE_INP_VEN_WORKING, AOPUTLAP_INP_HDR, AOPUTLAP_INP_DETL,		*/
/*					  AOPUTLJE_INP_TR and AOPUTLJE_INP_VEN										*/
/* Version			: 1.0																		*/
/************************************************************************************************/
/* Date			Modified By				Description of change			  						*/
/* ----------   -------------  	   		------------------------    			  				*/
/* 08-10-2008   Veera Veeramachanane   	Created Initial Version									*/
/*   05-18-2015  Tatiana Perova   CR7905 Div24            */
/************************************************************************************************/
DECLARE @sp_name                SYSNAME,
        @div22_company_id      VARCHAR(10),
        @IMAPS_error_number     INTEGER,
        @SQLServer_error_code   INTEGER,
        @error_msg_placeholder1 SYSNAME,
        @error_msg_placeholder2 SYSNAME,
		@interface_name			SYSNAME,
		@ret_code				INT,
		@count					INT,
		@fy_cd					CHAR(4),
		@pd_no					SMALLINT,
		@sub_pd_no				SMALLINT,
		@ap_acct_desc			VARCHAR(30),
		@cash_acct_desc			VARCHAR(30),
		@source_group			CHAR(2),
		@pay_terms				VARCHAR(15),
		@source_wwer			CHAR(3),
		@vchrlno				INT,
		@s_status_cd			CHAR(1),
		@sjnlcd 				CHAR(3), 
		@jeno					INT,
		@jelno					INT


	SET @interface_name = 'FIWLR_R22'
	SET @sp_name = 'XX_R22_FIWLR_LOAD_PREPROCESSORS_SP'

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


	SET @imaps_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'access required processing parameter COMPANY_ID'
	SET @error_msg_placeholder2 = 'for FIWLR Interface'

	SELECT	@div22_company_id = parameter_value
	FROM 	dbo.xx_processing_parameters
	WHERE 	parameter_name = 'COMPANY_ID'
	AND		interface_name_cd = 'FIWLR_R22'

	SET @count = @@ROWCOUNT

	IF @count = 0 OR LEN(RTRIM(LTRIM(@div22_company_id))) = 0 GOTO ERROR


	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'VERIFY NO PREVIOUS MISCODE RUN'
	SET @error_msg_placeholder2 = 'IS IN PROGRESS'

	SELECT 	@count = COUNT(1)
	FROM 	xx_error_status
	WHERE	control_pt <> 7
	and     interface='FIWLR_R22'
	
	IF @count <> 0 GOTO ERROR

	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'VERIFY AP PREPROCESSOR TABLE'
	SET @error_msg_placeholder2 = 'IS EMPTY'

	SELECT 	@count = COUNT(1)
	FROM 	IMAR.DELTEK.aoputlap_inp_hdr
	
	IF @count <> 0 GOTO ERROR

	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'VERIFY AP PREPROCESSOR TABLE'
	SET @error_msg_placeholder2 = 'IS EMPTY'

	SELECT 	@count = COUNT(1)
	FROM 	IMAR.DELTEK.aoputlap_inp_detl
	
	IF @count <> 0 GOTO ERROR

	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'VERIFY JE PREPROCESSOR TABLE'
	SET @error_msg_placeholder2 = 'IS EMPTY'

	SELECT 	@count = COUNT(1)
	FROM 	IMAR.DELTEK.aoputlje_inp_tr
	
	IF @count <> 0 GOTO ERROR

	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'VERIFY JE VEN PREPROCESSOR TABLE'
	SET @error_msg_placeholder2 = 'IS EMPTY'

	SELECT 	@count = COUNT(1)
	FROM 	IMAR.DELTEK.aoputlje_inp_ven
	
	IF @count <> 0 GOTO ERROR

	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'VERIFY TABLE'
	SET @error_msg_placeholder2 = 'AOPUTLAP_INP_HDR_WORKING IS EMPTY'

	SELECT 	@count = COUNT(1)
	FROM 	x2_r22_aoputlap_inp_hdr_working
	
	IF @count <> 0 GOTO ERROR

	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'VERIFY TABLE'
	SET @error_msg_placeholder2 = 'AOPUTLAP_INP_DETL IS EMPTY'
	
	SELECT 	@count = COUNT(1)
	FROM 	IMAR.DELTEK.aoputlap_inp_detl
	
	IF @count <> 0 GOTO ERROR

	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'VERIFY TABLE'
	SET @error_msg_placeholder2 = 'AOPUTLAP_INP_DETL_WORKING IS EMPTY'

	SELECT 	@count = COUNT(1)
	FROM 	x2_r22_aoputlap_inp_detl_working
	
	IF @count <> 0 GOTO ERROR

	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'VERIFY TABLE'
	SET @error_msg_placeholder2 = 'AOPUTLJE_INP_TR_WORKING IS EMPTY'

	SELECT 	@count = COUNT(1)
	FROM 	x2_r22_aoputlje_inp_tr_working
	
	IF @count <> 0 GOTO ERROR

	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'VERIFY TABLE'
	SET @error_msg_placeholder2 = 'AOPUTLJE_INP_VEN_WORKING IS EMPTY'

	SELECT 	@count = COUNT(1)
	FROM 	x2_r22_aoputlje_inp_ven_working
	
	IF @count <> 0 GOTO ERROR
		

	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'GRAB FISCAL ACCOUNTING'
	SET @error_msg_placeholder2 = 'CALENDAR DATA'
	
	SELECT	@fy_cd 		= fiscal_year, 
			@pd_no 		= CAST(period as SMALLINT), 
			@sub_pd_no	= CAST(sub_pd_no as SMALLINT)
	FROM	dbo.xx_r22_fiwlr_rundate_acctcal
	WHERE 	CONVERT(VARCHAR(10),GETDATE(),120) BETWEEN run_start_date AND run_end_date

	DECLARE @balancing_org_id VARCHAR(30)
	SELECT 	@balancing_org_id = parameter_value
	FROM 	xx_processing_parameters
	WHERE 	interface_name_cd = 'FIWLR_R22'
	AND 	parameter_name = 'BALANCING_ORG_ID'

	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR



		/* UPDATE FOR MAX LINE ITEMS PER COSTPOINT DOCUMENT */

	--GROUPING AP WWER
	UPDATE	xx_r22_fiwlr_usdet_temp
	SET		reference3 = 
		(
			SELECT	MAX(ident_rec_no) 
			FROM	xx_r22_fiwlr_usdet_temp  
			WHERE	status_rec_no = fiwlr.status_rec_no  
			AND	    source_group = fiwlr.source_group 
		    AND		division = fiwlr.division 
			AND		voucher_no = fiwlr.voucher_no  
			AND		source = fiwlr.source  
			AND		major = fiwlr.major  
			AND		ISNULL(inv_no, '') = ISNULL(fiwlr.inv_no, '')
			--AND	extract_date = fiwlr.extract_date  
			AND		ISNULL(fiwlr_inv_date, '') = ISNULL(fiwlr.fiwlr_inv_date, '')  
			AND 	ISNULL(po_no, '') = ISNULL(fiwlr.po_no, '')
			AND 	ISNULL(vendor_id, '')= ISNULL(fiwlr.vendor_id, '')
			AND		ISNULL(employee_no, '') = ISNULL(fiwlr.employee_no, ''))	
			FROM 	xx_r22_fiwlr_usdet_temp fiwlr
			WHERE 	source_group = 'AP'
			AND		source = '005'

	--GROUPING AP NONWWER
	UPDATE	xx_r22_fiwlr_usdet_temp
	SET		reference3 = 
				(
					SELECT	MAX(ident_rec_no) 
					FROM	xx_r22_fiwlr_usdet_temp  
					WHERE	status_rec_no = fiwlr.status_rec_no  
					AND	    source_group = fiwlr.source_group  
					AND		division = fiwlr.division 
					AND		voucher_no = fiwlr.voucher_no  
					AND		source = fiwlr.source  
					AND		major = fiwlr.major  
					AND		ISNULL(inv_no, '') = ISNULL(fiwlr.inv_no, '')
					AND		extract_date = fiwlr.extract_date  
					AND		ISNULL(fiwlr_inv_date, '') = ISNULL(fiwlr.fiwlr_inv_date, '')  
					AND 	ISNULL(po_no, '') = ISNULL(fiwlr.po_no, '')
					AND 	ISNULL(vendor_id, '')= ISNULL(fiwlr.vendor_id, ''))
					--AND	ISNULL(employee_no, '') = ISNULL(fiwlr.employee_no, ''))	
					FROM 	xx_r22_fiwlr_usdet_temp fiwlr
					WHERE 	source_group = 'AP'
					AND		source <> '005'
	
	--GROUPING je
	UPDATE	xx_r22_fiwlr_usdet_temp
	SET		reference3 = 
				(
					SELECT	MAX(ident_rec_no) 
					FROM	xx_r22_fiwlr_usdet_temp  
					WHERE		status_rec_no = fiwlr.status_rec_no  
					AND	    	source_group = fiwlr.source_group  
					AND		division = fiwlr.division  
					AND		voucher_no = fiwlr.voucher_no  
					AND		source = fiwlr.source  
					AND		major = fiwlr.major)
					--AND		inv_no = fiwlr.inv_no  
					--AND		extract_date = fiwlr.extract_date  
					--AND		fiwlr_inv_date = fiwlr.fiwlr_inv_date  
					--AND 		po_no = fiwlr.po_no  
					--AND 		vendor_id = fiwlr.vendor_id
					--AND		employee_no = fiwlr.employee_no)	
	FROM 	xx_r22_fiwlr_usdet_temp fiwlr
	WHERE 	source_group = 'JE'


	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR
	
	DECLARE 
		@status_rec_no INT,
		@reference3 VARCHAR(125),
		@line_count int
	
	START_MAX_LINES_CURSOR:
	
	DECLARE max_lines_cursor CURSOR fast_forward FOR
		SELECT	status_rec_no, reference3, COUNT(1)
		FROM	xx_r22_fiwlr_usdet_temp
		GROUP BY status_rec_no, reference3
		HAVING COUNT(1) > 1497
	
	OPEN max_lines_cursor
	FETCH max_lines_cursor
	INTO @status_rec_no, @reference3, @line_count
	
	WHILE(@@fetch_status = 0)
	BEGIN
		DECLARE @cutoff_ident_rec_no INT
		
		SELECT  top 1497 @cutoff_ident_rec_no = ident_rec_no
		FROM 	xx_r22_fiwlr_usdet_temp
		WHERE 	status_rec_no = @status_rec_no
		AND		reference3 = @reference3
		ORDER BY ident_rec_no
	
		UPDATE 	xx_r22_fiwlr_usdet_temp
		SET		reference3 = reference3 + 'M'
		WHERE 	status_rec_no = @status_rec_no
		AND		reference3 = @reference3
		AND		ident_rec_no > @cutoff_ident_rec_no
			
		FETCH max_lines_cursor
		INTO @status_rec_no, @reference3, @line_count
	END
	
	CLOSE max_lines_cursor
	DEALLOCATE max_lines_cursor
	
		SELECT	status_rec_no, reference3, COUNT(1)
		FROM	xx_r22_fiwlr_usdet_temp
		GROUP BY status_rec_no, reference3
		HAVING COUNT(1) > 1497
	
	IF @@rowcount <> 0 GOTO start_max_lines_cursor

	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR

	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'UPDATE XX_R22_FIWLR_USDET_TEMP'
	SET @error_msg_placeholder2 = 'FIWLR_INV_DATE FOR WWER'

	UPDATE xx_r22_fiwlr_usdet_temp
	SET fiwlr_inv_date = extract_date
	WHERE LEN(RTRIM(LTRIM(fiwlr_inv_date)))=0

	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR

	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'UPDATE XX_R22_FIWLR_USDET_TEMP'
	SET @error_msg_placeholder2 = 'FIWLR_INV_DATE FOR WWER'

	UPDATE	xx_r22_fiwlr_usdet_temp
	SET		fiwlr_inv_date = substring(fiwlr_inv_date,1,4)+'-'+substring(fiwlr_inv_date,5,2)+'-'+substring(fiwlr_inv_date,7,2)
	WHERE	LEN(RTRIM(LTRIM(fiwlr_inv_date)))=8

	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR


	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'INSERT INTO'
	SET @error_msg_placeholder2 = 'X2_R22_AOPUTLAP_INP_HDR_WORKING'

	INSERT INTO dbo.x2_r22_aoputlap_inp_hdr_working
		(
		status_record_num,
		grouping_clause,
		s_status_cd,
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
		a.DIVISION+','+CAST(a.status_rec_no AS VARCHAR)+ ',' +a.reference3,
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
		NULL, RTRIM(LTRIM(CAST(a.status_rec_no as char))) + ',' + RTRIM(LTRIM(a.major)) + '-' +  RTRIM(LTRIM(a.voucher_no) + ',' + LTRIM(RTRIM(a.source))), getdate(),'N'
	FROM 	dbo.xx_r22_fiwlr_usdet_temp a
	WHERE 	a.source_group 	= @source_group
	GROUP BY 
		a.status_rec_no,
		a.voucher_no,
		a.major,
		a.vendor_id,
		a.fiwlr_inv_date, 
		a.extract_date,
		a.inv_no,
		a.po_no,
		a.source,
		a.source_group,
		a.vend_name,
		a.reference3,
		a.DIVISION
	
	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR
	
	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'UPDATE X2_R22_AOPUTLAP_INP_HDR_WORKING'
	SET @error_msg_placeholder2 = 'WITH UNIQUE REC_NO & VCHR_NO'

	UPDATE 	x2_r22_aoputlap_inp_hdr_working
	SET	vchr_no = rec_no
	
	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR

	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'INSERT INTO'
	SET @error_msg_placeholder2 = 'X2_R22_AOPUTLAP_INP_DETL_WORKING'
	
	INSERT INTO dbo.x2_r22_aoputlap_inp_detl_working
		(
		status_record_num,
		unique_record_num,
		grouping_clause,
		major,
		source,
		doc_no,
		s_status_cd, 
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
		a.DIVISION+','+CAST(a.status_rec_no AS VARCHAR)+ ',' +a.reference3,
		a.major,
		a.source,
		a.voucher_no,
		@s_status_cd, 
		b.vchr_no, b.fy_cd,
		1, a.acct_id, 
		a.org_id, 
		NULL, NULL, NULL,
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
	FROM	dbo.xx_r22_fiwlr_usdet_temp a
	INNER JOIN	
	dbo.x2_r22_aoputlap_inp_hdr_working b
	ON
		(
		b.grouping_clause = 
			(a.DIVISION+','+CAST(a.status_rec_no AS VARCHAR)+ ',' +a.reference3)
		) 
	ORDER BY b.vchr_no

	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR
	
	
	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'INSERT BALANCING TRANSACTIONS'
	SET @error_msg_placeholder2 = 'INTO X2_R22_AOPUTLAP_INP_DETL_WORKING - FIWLR'

	INSERT INTO x2_r22_aoputlap_inp_detl_working
	  (	
		status_record_num, unique_record_num, 
		grouping_clause, major, source,
		s_status_cd, vchr_no, fy_cd, vchr_ln_no, 
		acct_id,
		org_id, cst_amt, taxable_fl, s_taxable_cd, 
		sales_tax_amt, disc_amt, use_tax_amt, ap_1099_fl,
		vchr_ln_desc, notes )
	SELECT 
		status_record_num, 0, grouping_clause, major, source,
		@s_status_cd, vchr_no, fy_cd, MAX(vchr_ln_no)+1,
		(SELECT	genl_id
		 FROM	IMAR.DELTEK.genl_udef
		WHERE	s_table_id = 'ACCT'
		AND		udef_lbl_key = 51
		AND		company_id = @div22_company_id 
		AND		udef_txt = a.major),
		CASE 
			WHEN left(grouping_clause,2)='22' THEN '22.D'
			WHEN left(grouping_clause,2)='SR' THEN '22.A'
			WHEN left(grouping_clause,2)='YA' THEN '22.W'
			WHEN left(grouping_clause,2)='YB' THEN '22.Z'
			WHEN left(grouping_clause,2)='24' THEN '24.B'    --CR7905
			WHEN left(grouping_clause,2)='QR' THEN '22.Q'    --CR13342
		END,
		 -1*SUM(cst_amt), 'N', '', 
		.00, .00, .00, 'N', 
		CAST(status_record_num AS VARCHAR)+','+source+','+major+','+doc_no,
		'Balancing Transaction'
	FROM 	x2_r22_aoputlap_inp_detl_working a
	GROUP BY
		status_record_num, grouping_clause,
		vchr_no, fy_cd, major, source, doc_no
	
	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR




	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'UPDATE X2_R22_AOPUTLAP_INP_DETL_WORKING'
	SET @error_msg_placeholder2 = 'WITH UNIQUE VCHR_LN_NO'
	
	UPDATE 	x2_r22_aoputlap_inp_detl_working
	SET 	vchr_ln_no = (SELECT COUNT(1) FROM x2_r22_aoputlap_inp_detl_working WHERE vchr_no = cur.vchr_no AND rec_no >= cur.rec_no)
	FROM 	x2_r22_aoputlap_inp_detl_working cur
	
	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR




	
	/*TIME FOR JE STUFF*/
	SET @source_group = 'JE'

	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'INSERT INTO'
	SET @error_msg_placeholder2 = 'X2_R22_AOPUTLJE_INP_TR_WORKING'

	INSERT INTO dbo.x2_r22_aoputlje_inp_tr_working ( 
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
		a.DIVISION+','+CAST(a.status_rec_no AS VARCHAR)+ ',' +a.reference3,
		a.major, a.source, a.voucher_no,
		NULL,@jelno,@jeno,@sjnlcd,
		@fy_cd, @pd_no, 
		@sub_pd_no,'N', 
		'F' + ',' + a.major + ',' + RTRIM(LTRIM(a.source)) + ',' + RTRIM(LTRIM(a.voucher_no)),a.amount, 
		a.acct_id,
		a.org_id, 
		(RTRIM(LTRIM(CAST(a.status_rec_no AS CHAR))) + ',' + a.source + ',' + a.major + ',' + a.voucher_no ),
		NULL,NULL,NULL,NULL,NULL,
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
	FROM 	dbo.xx_r22_fiwlr_usdet_temp a
	WHERE 	a.source_group 	= @source_group

	
	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR


	
	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'UPDATE X2_R22_AOPUTLJE_INP_TR_WORKING'
	SET @error_msg_placeholder2 = 'WITH UNIQUE REC_NO & INP_JE_NO'

	UPDATE 	x2_r22_aoputlje_inp_tr_working
	SET	inp_je_no = (
						SELECT	MAX(rec_no) 
						FROM	x2_r22_aoputlje_inp_tr_working
 						WHERE	grouping_clause = a.grouping_clause)
	FROM	x2_r22_aoputlje_inp_tr_working a
	
	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR



	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'INSERT OFFSETTING TRANSACTIONS'
	SET @error_msg_placeholder2 = 'INTO X2_R22_AOPUTLJE_INP_TR_WORKING'
	
	INSERT INTO x2_r22_aoputlje_inp_tr_working
	 ( 
		status_record_num, unique_record_num, 
		inp_je_no, je_ln_no,
		s_status_cd, s_jnl_cd, fy_cd, pd_no, sub_pd_no,
		rvrs_fl, je_desc, trn_amt, acct_id, 
		org_id,
		je_trn_desc,
		update_obd_fl, notes, time_stamp
	  )
	SELECT 
		status_record_num, 0, 
		inp_je_no, MAX(je_ln_no)+1,
		NULL /*S_STATUS_CD MUST BE NULL?!!?*/, 'AJE', fy_cd, pd_no, sub_pd_no,
		'N', je_desc, -1.0*SUM(trn_amt), 
		(	SELECT	genl_id
			FROM	IMAR.DELTEK.genl_udef
			WHERE	s_table_id = 'ACCT'
			AND		udef_lbl_key = 51
			AND		company_id = @div22_company_id 
			AND		udef_txt = a.major), 
		CASE 
			WHEN left(grouping_clause,2)='22' THEN '22.D'
			WHEN left(grouping_clause,2)='SR' THEN '22.A'
			WHEN left(grouping_clause,2)='YA' THEN '22.W'
			WHEN left(grouping_clause,2)='YB' THEN '22.Z'
			WHEN left(grouping_clause,2)='24' THEN '24.B'  --CR7905
			WHEN left(grouping_clause,2)='QR' THEN '22.Q'  --CR13342
		END,
		CAST(status_record_num AS VARCHAR)+','+source+','+major+','+doc_no,
		'Y', 'Balancing Transaction', current_timestamp
	FROM x2_r22_aoputlje_inp_tr_working a
	GROUP BY inp_je_no, je_desc, fy_cd, pd_no, sub_pd_no, 
	status_record_num, source, major, doc_no, grouping_clause
	
	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR	


	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'UPDATE JE_LN_NO'
	SET @error_msg_placeholder2 = 'IN X2_R22_AOPUTLJE_INP_TR_WORKING'

	UPDATE 	x2_r22_aoputlje_inp_tr_working
	SET 	je_ln_no = (SELECT COUNT(1) FROM x2_r22_aoputlje_inp_tr_working WHERE inp_je_no = cur.inp_je_no AND rec_no >= cur.rec_no)
	FROM 	X2_r22_aoputlje_inp_tr_working cur
	
	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR	



/*3.	Use vendor labor fields in the JE preprocessor to record hours pulled from FIWLR.  
	Set Vendor = IBM.  Leave vendor employee blank.  Set GLC = RLABOR.
*/
	
	INSERT INTO x2_r22_aoputlje_inp_ven_working
	(status_record_num, 
     unique_record_num, 
	 grouping_clause, 
     major, source, doc_no,
	 s_status_cd, je_ln_no, inp_je_no, s_jnl_cd, 
	 fy_cd, pd_no, 
	 vend_subln_no,
	 vend_id, genl_lab_cat_cd, bill_lab_cat_cd, lab_hrs, lab_amt, vend_empl_id, effect_bill_dt_fld,
	 time_stamp)
	 SELECT	a.status_rec_no,
		a.ident_rec_no,		
		CAST(a.status_rec_no AS VARCHAR)+ ',' +a.reference3,
		a.major, a.source, a.voucher_no,
		NULL,@jelno,@jeno,@sjnlcd,
		@fy_cd, @pd_no, 1,
		'IBM', 'RLABOR', 'RONE', hours, amount, NULL,  SUBSTRING(ref_creation_date,1,4)+'-'+SUBSTRING(ref_creation_date,5,2)+'-'+SUBSTRING(ref_creation_date,7,2) ,
		current_timestamp
	FROM 	dbo.xx_r22_fiwlr_usdet_temp a
	WHERE 	a.source_group 	= @source_group
	AND		hours IS NOT NULL
	AND		hours <> .00


	UPDATE x2_r22_aoputlje_inp_ven_working
	SET		inp_je_no = hdr.inp_je_no,
			je_ln_no = hdr.je_ln_no,
			vend_subln_no = 1
	FROM	x2_r22_aoputlje_inp_ven_working ln
	INNER JOIN
			x2_r22_aoputlje_inp_tr_working hdr
	ON
	(hdr.status_record_num=ln.status_record_num
		AND
	hdr.unique_record_num=ln.unique_record_num)


	--for COSTPOINT 7.1.1 were added COMPANY_ID
	
	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'INSERT INTO'
	SET @error_msg_placeholder2 = 'DELTEK.AOPUTLAP_INP_HDR'

	INSERT INTO IMAR.DELTEK.aoputlap_inp_hdr
	( rec_no, s_status_cd, vchr_no, fy_cd, pd_no, sub_pd_no,
	  vend_id, terms_dc, invc_id, 
	 invc_dt_fld,  invc_amt, 
	 disc_dt_fld, disc_pct_rt, disc_amt, 
	 due_dt_fld, hold_vchr_fl, pay_when_paid_fl, pay_vend_id, pay_addr_dc,
	  po_id, po_rlse_no, rtn_rate, ap_acct_desc, cash_acct_desc, s_invc_type,
	  ship_amt, chk_fy_cd, chk_pd_no, chk_sub_pd_no, chk_no, 
	 chk_dt_fld, chk_amt, disc_taken_amt, 
	 invc_pop_dt_fld, print_note_fl, jnt_pay_vend_name, notes, 
          time_stamp, sep_chk_fl,
		  COMPANY_ID) --CR 11302
	SELECT 
	 rec_no, s_status_cd, vchr_no, fy_cd, pd_no, sub_pd_no,
	 vend_id, terms_dc, invc_id, invc_dt, invc_amt, disc_dt, disc_pct_rt,
	 disc_amt, due_dt, hold_vchr_fl, pay_when_paid_fl, pay_vend_id, pay_addr_dc,
	 po_id, po_rlse_no, rtn_rate, ap_acct_desc, cash_acct_desc, s_invc_type,
	 ship_amt, chk_fy_cd, chk_pd_no, chk_sub_pd_no, chk_no, chk_dt, chk_amt, 
	 disc_taken_amt, invc_pop_dt, print_note_fl, jnt_pay_vend_name, notes, 
         time_stamp, sep_chk_fl,
		 @div22_company_id --CR 11302
	FROM 	x2_r22_aoputlap_inp_hdr_working	
	ORDER BY vchr_no
	
	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR

	
	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'INSERT INTO'
	SET @error_msg_placeholder2 = 'DELTEK.AOPUTLAP_INP_DETL'

	INSERT INTO IMAR.DELTEK.aoputlap_inp_detl
	(rec_no, s_status_cd, vchr_no, fy_cd, vchr_ln_no, acct_id, org_id, proj_id,
	 ref1_id, ref2_id, cst_amt, taxable_fl, s_taxable_cd, sales_tax_amt, disc_amt,
	 use_tax_amt, ap_1099_fl, s_ap_1099_type_cd, vchr_ln_desc, org_abbrv_cd, 
	 proj_abbrv_cd, proj_acct_abbrv_cd, notes, time_stamp,
	 COMPANY_ID) --CR 11302
	SELECT
	 rec_no, s_status_cd, vchr_no, fy_cd, vchr_ln_no, acct_id, org_id, proj_id,
	 ref1_id, ref2_id, cst_amt, taxable_fl, s_taxable_cd, sales_tax_amt, disc_amt,
	 use_tax_amt, ap_1099_fl, s_ap_1099_type_cd, vchr_ln_desc, org_abbrv_cd, 
	 proj_abbrv_cd, proj_acct_abbrv_cd, notes, time_stamp,
	 @div22_company_id --CR 11302
	FROM x2_r22_aoputlap_inp_detl_working
	ORDER BY vchr_no, vchr_ln_no
	
	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR

	
	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'INSERT INTO'
	SET @error_msg_placeholder2 = 'DELTEK.AOPUTLJE_INP_TR'

	INSERT INTO IMAR.DELTEK.aoputlje_inp_tr
	(rec_no, s_status_cd, je_ln_no, inp_je_no, s_jnl_cd, fy_cd, pd_no, sub_pd_no,
	 rvrs_fl, je_desc, trn_amt, acct_id, org_id, je_trn_desc, proj_id, ref_struc_1_id,
	 ref_struc_2_id, cycle_dc, org_abbrv_cd, proj_abbrv_cd, proj_acct_abbrv_cd, 
	 update_obd_fl, notes, time_stamp, 
	 COMPANY_ID) --CR 11302
	SELECT
	 rec_no, s_status_cd, je_ln_no, inp_je_no, s_jnl_cd, fy_cd, pd_no, sub_pd_no,
	 rvrs_fl, je_desc, trn_amt, acct_id, org_id, je_trn_desc, proj_id, ref_struc_1_id,
	 ref_struc_2_id, cycle_dc, org_abbrv_cd, proj_abbrv_cd, proj_acct_abbrv_cd, 
	 update_obd_fl, notes, time_stamp,
	 @div22_company_id --CR 11302
	FROM x2_r22_aoputlje_inp_tr_working
	ORDER BY inp_je_no, je_ln_no
	
	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR




	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'INSERT INTO'
	SET @error_msg_placeholder2 = 'DELTEK.AOPUTLJE_INP_VEN'

	INSERT INTO IMAR.DELTEK.aoputlje_inp_ven
	(rec_no, s_status_cd, je_ln_no, inp_je_no, s_jnl_cd, 
	 fy_cd, pd_no, 
	 vend_subln_no,
	 vend_id, genl_lab_cat_cd, bill_lab_cat_cd, lab_hrs, lab_amt, vend_empl_id, effect_bill_dt_fld,
	 time_stamp, 
	 COMPANY_ID) --CR 11302
	SELECT
	 rec_no, s_status_cd, je_ln_no, inp_je_no, s_jnl_cd, 
	 fy_cd, pd_no, 
	 vend_subln_no,
	 vend_id, genl_lab_cat_cd, bill_lab_cat_cd, lab_hrs, lab_amt, vend_empl_id, effect_bill_dt_fld,
	 time_stamp,
	 @div22_company_id --CR 11302
	FROM x2_r22_aoputlje_inp_ven_working
	ORDER BY inp_je_no, je_ln_no, vend_subln_no
	
	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR




	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'TRUNCATE PREPROCESSOR'
	SET @error_msg_placeholder2 = 'WORKING TABLES ON IMAPSSTG'
	
	TRUNCATE TABLE x2_r22_aoputlap_inp_hdr_working
	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR

	TRUNCATE TABLE x2_r22_aoputlap_inp_detl_working
	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR

	TRUNCATE TABLE x2_r22_aoputlje_inp_tr_working
	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR
	
	TRUNCATE TABLE x2_r22_aoputlje_inp_ven_working
	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR
	



	--set PLC to null for non-project required lines
	update imar.deltek.aoputlje_inp_ven
	set bill_lab_Cat_cd=null
	from imar.deltek.aoputlje_inp_ven ven
	where 
	1 = 
	(select count(1)
	from imar.deltek.aoputlje_inp_tr
	where inp_je_no=ven.inp_je_no
	and je_ln_no=ven.je_ln_no
	and proj_abbrv_cd is null
	and proj_id is null)

	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR



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
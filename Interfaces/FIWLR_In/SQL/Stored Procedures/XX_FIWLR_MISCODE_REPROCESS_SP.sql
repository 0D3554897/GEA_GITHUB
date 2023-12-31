USE [IMAPSStg]
GO
/****** Object:  StoredProcedure [dbo].[XX_FIWLR_MISCODE_REPROCESS_SP]    Script Date: 11/02/2007 09:01:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_MISCODE_REPROCESS_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_MISCODE_REPROCESS_SP]
GO


CREATE PROCEDURE [dbo].[XX_FIWLR_MISCODE_REPROCESS_SP] (
@out_STATUS_DESCRIPTION sysname = NULL
)
AS
BEGIN
/************************************************************************************************  
Name:       XX_FIWLR_MISCODE_REPROCESS_SP  
Author:     KM  


CP600000200 Reference BP&S Service Request DR1437

            02/25/2008 - Allow the Costpoint A/P Voucher Preprocessor and Journal Entry Preprocessor
            to run for the processes whose PROCESS_ID are 'AP_REPROCESS' and 'JE_REPROCESS',
            respectively, regardless of whether miscode data exist to process or not. This is done
            by removing the conditions that permit the updating of Deltek.PROCESS_QUE_ENTRY records
            for PROCESS_ID = 'AP_REPROCESS' and PROCESS_ID = 'JE_REPROCESS'.


            03/06/2008 - Accommodate the special case of N16 miscode documents having multiple
            balancing transactions by moving code to update X2_AOPUTLAP_INP_DETL_WORKING with unique
            VCHR_LN_NO to its correct position.

            05/05/2008 - Apply the Costpoint column COMPANY_ID to distinguish Division 16's data

            from those of Division 22's. There are four instances.

on change:

1.  LOAD AP & JE PREPROCESSORS WITH UPDATED DATA

exec XX_FIWLR_MISCODE_REPROCESS_SP

delete
from xx_error_Status
where control_pt<>7

truncate table imaps.deltek.aoputlap_inp_hdr
truncate table imaps.deltek.aoputlap_inp_detl
truncate table imaps.deltek.aoputlje_inp_tr

truncate table x2_aoputlap_inp_hdr_working
truncate table x2_aoputlap_inp_detl_working
truncate table x2_aoputlje_inp_tr_working


2010-09-14 1M changes

2014-02-19  Costpoint 7 changes
			Process Server replaced by Job Server
2019-11-26 Costpoint 7.1.1 changes CR11504
************************************************************************************************/  

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
	SET @SP_NAME = 'XX_FIWLR_MISCODE_REPROCESS_SP'
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

-- CP600000200 Begin

	SET @IMAPS_ERROR_NUMBER = 204 -- Attempt to %1 %2 failed.
	SET @ERROR_MSG_PLACEHOLDER1 = 'access required processing parameter COMPANY_ID'
	SET @ERROR_MSG_PLACEHOLDER2 = 'for FIWLR Interface'

	SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
	FROM 	dbo.XX_PROCESSING_PARAMETERS
	WHERE 	PARAMETER_NAME = 'COMPANY_ID'
	AND	INTERFACE_NAME_CD = 'FIWLR'

	SET @count = @@ROWCOUNT

	IF @count = 0 OR LEN(RTRIM(LTRIM(@DIV_16_COMPANY_ID))) = 0 GOTO ERROR

-- CP600000200 End

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY NO PREVIOUS MISCODE RUN'
	SET @ERROR_MSG_PLACEHOLDER2 = 'IS IN PROGRESS'

	SELECT 	@count = count(1)
	FROM 	XX_ERROR_STATUS
	WHERE	CONTROL_PT <> 7
	AND		INTERFACE='FIWLR'
	
	IF @count <> 0 GOTO ERROR

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
	
	IF @count <> 0 GOTO ERROR
	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY PCLAIM IS NOT RUNNING'
	SET @ERROR_MSG_PLACEHOLDER2 = ''

	SELECT 	@count = count(1)
	FROM 	XX_IMAPS_INT_STATUS
	WHERE 	INTERFACE_NAME = 'PCLAIM'
	AND	STATUS_CODE <> 'COMPLETED'
	
	IF @count <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY FIWLR IS NOT RUNNING'
	SET @ERROR_MSG_PLACEHOLDER2 = ''

	SELECT 	@count = count(1)
	FROM 	XX_IMAPS_INT_STATUS
	WHERE 	INTERFACE_NAME = 'FIWLR'
	AND	STATUS_CODE <> 'COMPLETED'
	
	IF @count <> 0 GOTO ERROR

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


	--1M
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'HELP CORRECT 1M '
	SET @ERROR_MSG_PLACEHOLDER2 = 'WWWER MISCODES'

	EXEC 	@count = XX_FIWLR_PROCESS_1MWWER_SP
	IF @count <> 0 GOTO ERROR


	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'RE-VALIDATE EVERYTHING'
	SET @ERROR_MSG_PLACEHOLDER2 = 'IN CASE COSTPOINT HAS CHANGED'

	EXEC @ret_code = XX_FIWLR_MISCODE_UPDATE_FEEDBACK_SP
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 OR @ret_code <> 0 GOTO ERROR

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE STATUS CODE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR DOCUMENTS THAT ARE ENTIRELY VALID'

	UPDATE 	XX_FIWLR_USDET_MISCODES
	SET	REFERENCE1 = 'V'
	FROM	XX_FIWLR_USDET_MISCODES miscodes
	WHERE 	
	0 = (SELECT COUNT(1)
		 FROM XX_FIWLR_USDET_MISCODES
		 WHERE STATUS_REC_NO = miscodes.STATUS_REC_NO
		 AND   REFERENCE3 = miscodes.REFERENCE3
		 AND   REFERENCE2 <> 'valid')

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
	FROM 	dbo.XX_FIWLR_USDET_MISCODES a
	WHERE 	a.source_group 	= @source_group
	AND 	a.reference1	= 'V'
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
	FROM	dbo.XX_FIWLR_USDET_MISCODES a
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
	FROM 	dbo.XX_FIWLR_USDET_MISCODES a
	WHERE 	a.source_group 	= @source_group
	AND 	CAST(a.status_rec_no AS VARCHAR)+','+a.reference3 in
		(SELECT CAST(status_rec_no AS VARCHAR)+','+reference3
		 FROM XX_FIWLR_USDET_MISCODES 
		 WHERE reference1 = 'V'
		 AND	source_group = @source_group)
	
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
	 COMPANY_ID) --CR11504
	SELECT 
	 REC_NO, S_STATUS_CD, VCHR_NO, FY_CD, PD_NO, SUB_PD_NO,
	 VEND_ID, TERMS_DC, INVC_ID, INVC_DT, INVC_AMT, DISC_DT, DISC_PCT_RT,
	 DISC_AMT, DUE_DT, HOLD_VCHR_FL, PAY_WHEN_PAID_FL, PAY_VEND_ID, PAY_ADDR_DC,
	 PO_ID, PO_RLSE_NO, RTN_RATE, AP_ACCT_DESC, CASH_ACCT_DESC, S_INVC_TYPE,
	 SHIP_AMT, CHK_FY_CD, CHK_PD_NO, CHK_SUB_PD_NO, CHK_NO, CHK_DT, CHK_AMT, 
	 DISC_TAKEN_AMT, INVC_POP_DT, PRINT_NOTE_FL, JNT_PAY_VEND_NAME, NOTES, 
         TIME_STAMP, SEP_CHK_FL,
	 @DIV_16_COMPANY_ID -- CR11504
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
	 COMPANY_ID) -- CR11504
	SELECT
	 REC_NO, S_STATUS_CD, VCHR_NO, FY_CD, VCHR_LN_NO, ACCT_ID, ORG_ID, PROJ_ID,
	 REF1_ID, REF2_ID, CST_AMT, TAXABLE_FL, S_TAXABLE_CD, SALES_TAX_AMT, DISC_AMT,
	 USE_TAX_AMT, AP_1099_FL, S_AP_1099_TYPE_CD, VCHR_LN_DESC, ORG_ABBRV_CD, 
	 PROJ_ABBRV_CD, PROJ_ACCT_ABBRV_CD, NOTES, TIME_STAMP,
	 @DIV_16_COMPANY_ID --CR11504
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
	 COMPANY_ID) -- CR11504
	SELECT
	 REC_NO, S_STATUS_CD, JE_LN_NO, INP_JE_NO, S_JNL_CD, FY_CD, PD_NO, SUB_PD_NO,
	 RVRS_FL, JE_DESC, TRN_AMT, ACCT_ID, ORG_ID, JE_TRN_DESC, PROJ_ID, REF_STRUC_1_ID,
	 REF_STRUC_2_ID, CYCLE_DC, ORG_ABBRV_CD, PROJ_ABBRV_CD, PROJ_ACCT_ABBRV_CD, 
	 UPDATE_OBD_FL, NOTES, TIME_STAMP,
	 @DIV_16_COMPANY_ID -- CR11504
	FROM X2_AOPUTLJE_INP_TR_WORKING
	ORDER BY INP_JE_NO, JE_LN_NO
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'LOAD TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_ERROR_STATUS'

	INSERT INTO XX_ERROR_STATUS
	(STATUS_RECORD_NUM, ERROR_SEQUENCE_NO, 
	 INTERFACE, PREPROCESSOR, 
	 STATUS, CONTROL_PT, 
	 TOTAL_COUNT, TOTAL_AMOUNT, 
	 SUCCESS_COUNT, SUCCESS_AMOUNT,
	 ERROR_COUNT, ERROR_AMOUNT,
	 TIME_STAMP)
	SELECT 
	fiwlr.STATUS_REC_NO, 
	(select isnull( (max(error_sequence_no)+1), 0)
	 from xx_error_status
	 where 	status_record_num = fiwlr.status_rec_no
	 and 	preprocessor = fiwlr.source_group
	), 
	'FIWLR', fiwlr.SOURCE_GROUP, 
	'PREPROCESSOR STARTED', 3, 
	COUNT(1), SUM(fiwlr.AMOUNT),
	0, 0,
	0, 0,  
	CURRENT_TIMESTAMP
	FROM XX_FIWLR_USDET_MISCODES fiwlr
	WHERE
	cast(fiwlr.status_rec_no as varchar)+fiwlr.source_group
	in
		(select cast(status_rec_no as varchar)+source_group
		 from xx_fiwlr_usdet_miscodes 
		 where reference1 = 'V')
	GROUP BY fiwlr.STATUS_REC_NO, fiwlr.SOURCE_GROUP

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

-- CP600000200 Begin

--	IF 0 <> (SELECT COUNT(1) FROM IMAPS.DELTEK.AOPUTLAP_INP_HDR)
--	BEGIN
		SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
		SET @ERROR_MSG_PLACEHOLDER1 = 'KICK OFF'
		SET @ERROR_MSG_PLACEHOLDER2 = 'AP_REPROCESS'
	
		--2014-02-19  Costpoint 7 changes BEGIN
		UPDATE IMAPS.Deltek.job_schedule
		SET 	SCH_START_DTT = CURRENT_TIMESTAMP,
			TIME_STAMP = CURRENT_TIMESTAMP
		WHERE	job_id = 'AP_REPROCESS'
		AND	COMPANY_ID = @DIV_16_COMPANY_ID -- CP600000200
		--2014-02-19  Costpoint 7 changes END


		SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
		IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
--	END


--	IF 0 <> (SELECT COUNT(1) FROM IMAPS.DELTEK.AOPUTLJE_INP_TR)
--	BEGIN
		SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
		SET @ERROR_MSG_PLACEHOLDER1 = 'KICK OFF'
		SET @ERROR_MSG_PLACEHOLDER2 = 'JE_REPROCESS'
			
		--2014-02-19  Costpoint 7 changes BEGIN
		UPDATE IMAPS.Deltek.job_schedule
		SET 	SCH_START_DTT = CURRENT_TIMESTAMP,
			TIME_STAMP = CURRENT_TIMESTAMP
		WHERE	job_id = 'JE_REPROCESS'
		AND	COMPANY_ID = @DIV_16_COMPANY_ID -- CP600000200
		--2014-02-19  Costpoint 7 changes END


		SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
		IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
--	END

-- CP600000200 End

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



USE [IMAPSStg]
GO
/****** Object:  StoredProcedure [dbo].[XX_FIWLR_STG_SP]    Script Date: 08/23/2007 14:14:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/****** Object:  Stored Procedure dbo.XX_FIWLR_STG_SP    Script Date: 8/23/2007 4:03:38 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_STG_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_STG_SP]
GO


CREATE PROCEDURE [dbo].[XX_FIWLR_STG_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_STG_SP							*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR AP staging Procedure					*/
/* Date			: October 15, 2005						        */
/* Notes		: IMAPS FIW-LR AP staging program will group the AP data and insert 	*/
/*			  the AP Preprocessor staging tables. 					*/
/* Prerequisites	: XX_FIWLR_USDET_V3, XX_AOPUTLAP_INP_HDRV and XX_AOPUTLAP_INP_DETLV  	*/
/*			  XX_SEQUENCES_HDR and XX_SEQUENCES_DETL Table(s) should be created.	*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: XX_AOPUTLAP_INP_HDRV and XX_AOPUTLAP_INP_DETLV			*/
/* Version		: 1.2									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 10-20-2005   Veera Veeramachanane   	Created Initial Version					*/
/* 11-06-2005	Veera Veeramachanane   	Modified Code to create vouchers by each major		*/
/*					Defect : DEV00000243					*/
/* 11-23-2005	Veera Veeramachanane   	Modified Code based on the new requirement to post 	*/
/*					transactions to Fiscal Year, Period and Sub Period	*/
/*					based on the FIWLR Run Date Calendar provided. 		*/
/*					Ref: Requirement FIWLR33 (Req Pro)			*/
/* 11-28-2005	Veera Veeramachanane   	Modified Code to add and change the column sequence 	*/
/*					populated in Voucher Line desc and Notes field based on */
/*					the miscode process walkthrough meeting.		*/
/*					Defect : DEV00000296					*/
/* 01-27-2006   Clare Robbins		Populate Org_ID in detail lines.  Feature: DEV00000468*/
/* 03-29-2006   Clare Robbins		Set s_status_cd in AP Preprocessor tables to 'U' for new Deltek patch  */
/* 04-03-2006	Keith McGuire		There was a bad join on the insert to the detail tables */
/* 04-24-2006   Clare Robbins		Add case statement to deal w/6 or 8 character date - DEV00000813 */
/* 04-25-2006	Keith McGuire		A new bad join was introduced by the previous patch 	*/
/*					FOR FUTURE REFERENCE: any change to the insert values	*/
/*					to the header table may require a change to the join 	*/
/*					join clause of the insert to the detail table		*/
/* 04-26-2006 	Keith McGuire		In order for join and group to work properly, 		*/
/*					the header table must contain whether source is @source */
/* 8/10/2006	Keith McGuire		Defect: DEV00001133					*/
/*					Code modified to update ENTR_USER_ID to  'FIWN16' 	*/
/*								for N16 source			*/
/* 8/14/2006 	Keith McGuire		DEV00001097 Modified code to facilitate FIWLR miscode process */
/*
	Date		Modified By		Description of change	
   ----------   -------------	------------------------ 
   2010-09-13	KM				1M changes

*/
/************************************************************************************************/

DECLARE 

	@vchrlno 		INT,
	@error_type		INT,
	@error_code		INT,
	@error_msg_placeholder1	SYSNAME,
	@error_msg_placeholder2 SYSNAME,
	@sp_name		SYSNAME,
	@ap_acct_desc		VARCHAR(30), 
	@cash_acct_desc		VARCHAR(30), 
	@source_group		VARCHAR(3),
	@source			VARCHAR(3),
	@fy_cd 			VARCHAR(6),
--	@pd_no 			NUMERIC(2), 
--	@sub_pd_no 		NUMERIC(2), 
	@pd_no 			SMALLINT, 
	@sub_pd_no 		SMALLINT,
	@pay_terms		VARCHAR(30),
	@s_status_cd		VARCHAR(1)  --added by Clare Robbins on 3/29/06

BEGIN

-- set local constants

	--the different date formats is messing everything up
	--let's be consistent in CP6
	update xx_fiwlr_usdet_v3
	set fiwlr_inv_Date = extract_date
	where len(fiwlr_inv_date) = 0

	update xx_fiwlr_usdet_v3
	set fiwlr_inv_date = left(fiwlr_inv_date, 4) + '-' + substring(fiwlr_inv_date, 5, 2) + '-' + right(fiwlr_inv_date, 2)
	where len(fiwlr_inv_date)=8


	SELECT	@sp_name = 'XX_FIWLR_STG_SP',
		@error_msg_placeholder1	= NULL,
		@error_msg_placeholder2 = NULL,
		@ap_acct_desc	= NULL, 
		@cash_acct_desc = NULL,
--		@ap_acct_desc	= 'INTERCOMPANY AP SUSPENSE',  
--		@cash_acct_desc = 'INTERCOMPANY AP SUSPENSE',
		@pay_terms = 'NET 30',
		@source_group = 'AP',
		@source = '005',
/*	Start Commented out by Veera on 11/23/2005 Ref: Requirement FIWLR33
--		@fy_cd = DATEPART(YEAR, GETDATE()) ,  
--		@pd_no = DATEPART(MONTH, GETDATE()),
	End Commented out by Veera on 11/23/2005 Ref: Requirement FIWLR33 */
		@vchrlno = 1,
--		@sub_pd_no = 1
		@s_status_cd = 'U' --added by Clare Robbins on 3/29/06

/* 	Start Veera -- Added the code based on the enhancement to post transactions to Fiscal Year, Period and 
	Sub Period based on the FIW-LR Run Dates calendar provided by IMAPS user community (Sean)
	Ref: Requirement FIWLR33 in Req Pro */

	SELECT	@fy_cd 		= fiscal_year, 
		@pd_no 		= CAST(period as SMALLINT), 
		@sub_pd_no	= CAST(sub_pd_no as SMALLINT)
	FROM	dbo.xx_fiwlr_rundate_acctcal
	WHERE 	CONVERT(VARCHAR(10),GETDATE(),120) BETWEEN run_start_date AND run_end_date


/*SELECT		@fy_cd = DATEPART(YEAR, GETDATE()) , 
		@pd_no = 6,
		@sub_pd_no = 2
*/
/* 	End Ref: Requirement FIWLR33 in Req Pro */

-- Group all expense transactions other than WWER from XX_FIWLR_USDET staging table and create voucher records in XX_AOPUTLAP_INP_HDR staging table
	INSERT INTO dbo.xx_aoputlap_inp_hdrv
		(
		rec_no, 
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
		@in_status_record_num, 
		@s_status_cd,
		@fy_cd, @pd_no, @sub_pd_no, a.vendor_id,
		@pay_terms, a.inv_no, 
		a.fiwlr_inv_date, 
		SUM(a.amount),
		NULL, NULL, NULL, NULL, 
		'N', 'N', NULL, NULL, 
		a.po_no, NULL, 0, @ap_acct_desc,
		@cash_acct_desc, NULL, 0, NULL, 
		NULL, NULL, NULL, NULL, 
		0, 0, NULL, 'N', 
		NULL, RTRIM(LTRIM(CAST(@in_status_record_num as char))) + ',' + RTRIM(LTRIM(a.major)) + '-' +  RTRIM(LTRIM(a.voucher_no) + ',' + LTRIM(RTRIM(a.source)+ ',' + LTRIM(RTRIM(a.division)) )), getdate(),'N'
	FROM 	dbo.xx_fiwlr_usdet_v3 a
	WHERE 	a.source_group 	= @source_group
	AND 	a.status_rec_no = @in_status_record_num
	GROUP BY a.voucher_no,
		a.major,-- Added by Veera on 11/07/2005 - Defect : DEV00000243
		a.vendor_id,
		a.fiwlr_inv_date, 
		a.extract_date,
		a.inv_no,
		a.po_no,
		a.source,
		a.division;

	SELECT @out_systemerror = @@ERROR
	IF @out_systemerror <> 0 
   		BEGIN
			SET @error_type = 1 
			GOTO ErrorProcessing
   		END


-- insert voucher details for all AP source group transactions except WWER in staging table XX_AOPUTLAP_INP_DETLV for all the vouchers from xx_fiwlr_usdet_v3 

	INSERT INTO dbo.xx_aoputlap_inp_detlv
		(rec_no,  
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
		b.rec_no, 
		@s_status_cd, --added by Clare Robbins on 3/29/06
		b.vchr_no, b.fy_cd,
		@vchrlno, a.acct_id, --NULL, Commented by Clare Robbins on 1/27/2006
		a.org_id, -- Added by Clare Robbins on 1/27/2006

		NULL, a.division, NULL,  --temporarily place division in ref1_id

		a.amount, 'N',  NULL,  -- CST_AMT, TAXABLE_FL, S_TAXABLE_CD,
		0, 0, 0,  
		'N', NULL, (RTRIM(LTRIM(CAST(@in_status_record_num AS CHAR))) + ',' + RTRIM(LTRIM(a.source)) + ',' + RTRIM(LTRIM(a.major)) + ',' + RTRIM(LTRIM(a.voucher_no)) ), 

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
FROM	dbo.xx_fiwlr_usdet_v3 a
	inner join	
	dbo.xx_aoputlap_inp_hdrv b
	on
		(
		a.source_group = 'AP'
	AND	b.notes = RTRIM(LTRIM(CAST(@in_status_record_num as char))) + ',' + RTRIM(LTRIM(a.major)) + '-' +  RTRIM(LTRIM(a.voucher_no) + ',' + RTRIM(LTRIM(a.source)+ ',' + LTRIM(RTRIM(a.division)) ))
	AND	 (a.vendor_id = b.vend_id OR a.employee_no = b.vend_id)
	AND	b.invc_dt =  a.fiwlr_inv_date
	AND	(a.inv_no = b.invc_id or (a.inv_no is null and b.invc_id is null)) -- updated by CR 4/12/06
	AND	(a.po_no = b.po_id or (a.po_no is null and b.po_id is null)) -- updated by CR 4/12/06
		) 
	ORDER BY b.vchr_no

		SELECT @out_systemerror = @@ERROR
		IF @out_systemerror <> 0 
   		   BEGIN
			SET @error_type = 2 
			GOTO ErrorProcessing
   		   END		

RETURN 0

ErrorProcessing:

	IF @error_type = 1
   		BEGIN
      			SET @error_code = 204 -- Attempt to insert a record into table XX_AOPUTLAP_INP_HDRV failed.
      			SET @error_msg_placeholder1 = 'insert'
      			SET @error_msg_placeholder2 = 'a record into table XX_AOPUTLAP_INP_HDRV'
   		END
	ELSE IF @error_type = 2
   		BEGIN
      			SET @error_code = 204 -- Attempt to insert a record into table XX_AOPUTLAP_INP_DETLV failed.
      			SET @error_msg_placeholder1 = 'insert'
      			SET @error_msg_placeholder2 = 'a record into table XX_AOPUTLAP_INP_DETLV'
   		END

		EXEC dbo.xx_error_msg_detail
	         		@in_error_code           = @error_code,
	         		@in_sqlserver_error_code = @out_systemerror,
	         		@in_display_requested    = 1,
				@in_placeholder_value1   = @error_msg_placeholder1,
		   		@in_placeholder_value2   = @error_msg_placeholder2,
	         		@in_calling_object_name  = @sp_name,
	         		@out_msg_text            = @out_status_description OUTPUT

RETURN 1
END












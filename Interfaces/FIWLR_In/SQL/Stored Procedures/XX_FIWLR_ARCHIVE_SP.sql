USE [IMAPSStg]
GO
/****** Object:  StoredProcedure [dbo].[XX_FIWLR_ARCHIVE_SP]    Script Date: 10/22/2007 11:03:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_ARCHIVE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_ARCHIVE_SP]
GO



CREATE PROCEDURE [dbo].[XX_FIWLR_ARCHIVE_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

BEGIN

-- archive errors
DECLARE 
	@resultofappreprocessorrun VARCHAR(10),
	@latestrecordnuminarchive INT,
	@doesinterfacestatusnumberpresent TINYINT,
	@error_type		INT,
	@error_code		INT,
	@error_msg_placeholder1	SYSNAME,
	@error_msg_placeholder2 SYSNAME,
	@sp_name		SYSNAME,
	@total_amt_inpstg_ap	DECIMAL(17,2),		
	@total_amt_inphdr_ap	DECIMAL(17,2),
	@total_amt_inphdr_err_ap DECIMAL(17,2),
	@total_amt_inpstg_je	DECIMAL(17,2),
	@total_amt_inpjtr_je	DECIMAL(17,2),
	@total_amt_inpjtr_err_je DECIMAL(17,2)


	SELECT	@sp_name = 'XX_FIWLR_ARCHIVE_SP',
		@error_msg_placeholder1	= NULL,
		@error_msg_placeholder2 = NULL,
		@total_amt_inpstg_ap	= 0,
		@total_amt_inphdr_ap	= 0,
		@total_amt_inphdr_err_ap = 0,
		@total_amt_inpstg_je	= 0,
		@total_amt_inpjtr_je	= 0,
		@total_amt_inpjtr_err_je = 0,
		@doesinterfacestatusnumberpresent = 0

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_ARCHIVE_SP							*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR Archive Procedure					*/
/* Date			: October 25, 2005						        */
/* Notes		: IMAPS FIW-LR Archive program archive the extracted FIW-LR and WWERN16 */
/*			  data along with the data that failed the validation in AP and JE	*/
/*			  Preprocessor table(s).						*/
/* Prerequisites	: XX_FIWLR_USDET_V3, DELETEK.AOPUTLAP_INP_HDR, DELTEK.AOPUTLAP_INP_DETL */
/*			  and DELTEK.AOPUTLJE_INP_TR Table(s) should exist.			*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: DELTEK.AOPUTLAP_INP_HDR, DELTEK.AOPUTLAP_INP_DETL and			*/
/*			  DELTEK.AOPUTLJE_INP_TR						*/
/* Version		: 1.4									*/
/***********************************************************************************************
 Date		Modified By		Description of change			  		
 ----------   -------------  	   	------------------------    			  	
 10-25-2005   Veera Veeramachanane   	Created Initial Version					
 11-07-2005   Veera Veeramachanane   	Modified Code to reconcile data based on the changes	
					in AP and JE Preprocessor staging data : DEV00000243	
 11-14-2005   Veera Veeramachanane   	Modified Code to pass status record number as char for 	
					extracting reconcile data. Defect : DEV00000269		
 11-25-2005   Veera Veeramachanane   	Modified Code for reconcilitation based on new FIWLR33	
					requirement and the line and notes field changes.	
					Defect: DEV0000296					
 12-06-2005   Veera Veeramachanane   	Modified Code for reconcilitation based on bug fix	
					and automatic import process. Defect: DEV0000311	
 03-14-2006	Keith McGuire		Modified Code for AP reconciliation during ETE testing	
 05-01-2006	Keith McGuire		Modified Code for AP reconciliation during UAT testing	
 6/23/2006	Keith McGuire		Defect: DEV00000692					
					Code modified to update ENTR_USER_ID to 'FIWLR' 	
 8/10/2006	Keith McGuire		Defect: DEV00001133					
					Code modified to update ENTR_USER_ID to 'FIWN16' 	
					for N16 source			                        
 05/15/2008   HVT                     Ref CP600000322. Multi-company fix (5 instances).       

 09/11/2009 Keith McGuire
					Changed EXTRACT_START_DATE to MAX(CDATE + CTIME)
************************************************************************************************/

-- ensure that interface run in staging table was not yet archived
/*
	SELECT	@doesinterfacestatusnumberpresent = 1
	FROM	dbo.xx_fiwlr_usdet_archive 
	WHERE	status_record_num = @in_status_record_num
	
	IF @doesinterfacestatusnumberpresent = 1 
	    BEGIN
			RETURN (521)
	    END
	
-- get number of last archived row
	SELECT @latestrecordnuminarchive = MAX(batch_id)
	FROM dbo.xx_fiwlr_usdet_archive

	IF  @latestrecordnuminarchive IS NULL BEGIN SET @latestrecordnuminarchive = 0 END
*/



-- CP600000322_Begin
DECLARE @DIV_16_COMPANY_ID varchar(10)
SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'FIWLR'
-- CP600000322_End

	--begin grab the JE and AP Cosptoint Numbers for Reporting Purposes
	truncate table xx_fiwlr_usdet_rpt_temp

	insert into xx_fiwlr_usdet_rpt_temp
	(SOURCE_GROUP, CP_LN_DESC, CP_LN_NOTES, CP_HDR_KEY, CP_LN_NO)
	SELECT 'AP', VCHR_LN_DESC, NOTES, VCHR_KEY, VCHR_LN_NO
	FROM	IMAPS.DELTEK.VCHR_LN
	WHERE	LEFT(NOTES, 3) <> 'Bal'
	
	insert into xx_fiwlr_usdet_rpt_temp
	(SOURCE_GROUP, CP_LN_DESC, CP_LN_NOTES, CP_HDR_KEY, CP_LN_NO)
	SELECT 'JE', JE_TRN_DESC, NOTES, JE_HDR_KEY, JE_LN_NO
	FROM	IMAPS.DELTEK.JE_TRN
	WHERE	LEFT(NOTES, 3) <> 'Bal'
	
	--DR1285
	UPDATE xx_fiwlr_usdet_rpt_temp
	set status_Rec_no = left(dbo.xx_parse_csv(cp_ln_desc, 0), 10),
	ident_rec_no = left(dbo.xx_parse_csv_backwards(cp_ln_notes, 1), 10)
	
	UPDATE xx_fiwlr_usdet_rpt_temp
	set cp_hdr_no = hdr.vchr_no,
	    fy_cd = hdr.fy_cd,
	    pd_no = hdr.pd_no,
	    sub_pd_no = hdr.sub_pd_no
	from xx_fiwlr_usdet_rpt_temp tmp
	inner join
	IMAPS.Deltek.VCHR_HDR hdr
	on
	(tmp.source_group = 'AP'
	and tmp.cp_hdr_key = hdr.vchr_key

-- CP600000322_Begin
	and hdr.COMPANY_ID = @DIV_16_COMPANY_ID)

-- CP600000322_End


	UPDATE xx_fiwlr_usdet_rpt_temp
	set cp_hdr_no = hdr.je_no,
	    fy_cd = hdr.fy_cd,
	    pd_no = hdr.pd_no,
	    sub_pd_no = hdr.sub_pd_no
	from xx_fiwlr_usdet_rpt_temp tmp
	inner join
	IMAPS.Deltek.JE_HDR hdr
	on
	(tmp.source_group = 'JE'
	and tmp.cp_hdr_key = hdr.je_hdr_key
-- CP600000322_Begin
	and hdr.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000322_End



--copy all records from staging table to archive table increasing record number on the number of last archived row
	INSERT INTO dbo.xx_fiwlr_usdet_archive 
	      (
		ident_rec_no,
		status_rec_no,stream_id,ledger_type,
		major,minor,subminor,analysis_code,
		division,extract_date,fiwlr_inv_date,voucher_no,
		voucher_grp_no,wwer_exp_key,wwer_exp_dt,
		source,acct_month,acct_year,ap_idx,project_no,
		description1,description2,department,accountant_id,
		po_no,inv_no,etv_code,country_code,
		vendor_id,employee_no,amount,input_type,
		ap_doc_type,ref_creation_date,ref_creation_time,creation_date,
		source_group,vend_name,emp_lastname,emp_firstname,
		proj_id,proj_abbr_cd,org_id,org_abbr_cd,
		pag_cd,val_nval_cd,acct_id
		,reference1,reference2,
		reference3,reference4,reference5,
cp_hdr_no, cp_ln_no, fy_cd, pd_no, sub_pd_no  ) 
	SELECT 
		usdet.ident_rec_no,
		usdet.status_rec_no,usdet.stream_id,usdet.ledger_type,
		usdet.major,usdet.minor,usdet.subminor,usdet.analysis_code,
		usdet.division,usdet.extract_date,usdet.fiwlr_inv_date,usdet.voucher_no,
		usdet.voucher_grp_no,usdet.wwer_exp_key,usdet.wwer_exp_dt,
		usdet.source,usdet.acct_month,usdet.acct_year,usdet.ap_idx,usdet.project_no,
		usdet.description1,usdet.description2,usdet.department,usdet.accountant_id,
		usdet.po_no,usdet.inv_no,usdet.etv_code,usdet.country_code,
		usdet.vendor_id,usdet.employee_no,usdet.amount,usdet.input_type,
		usdet.ap_doc_type,usdet.ref_creation_date,usdet.ref_creation_time,usdet.creation_date,
		usdet.source_group,usdet.vend_name,usdet.emp_lastname,usdet.emp_firstname,
		usdet.proj_id,usdet.proj_abbr_cd,usdet.org_id,usdet.org_abbr_cd,
		usdet.pag_cd,usdet.val_nval_cd,usdet.acct_id,
		usdet.reference1,usdet.reference2,
		usdet.reference3,usdet.reference4,usdet.reference5,

		tmp.cp_hdr_no, tmp.cp_ln_no, tmp.fy_cd, tmp.pd_no, tmp.sub_pd_no 
	FROM	dbo.xx_fiwlr_usdet_v3 usdet
	left join
	xx_fiwlr_usdet_rpt_temp tmp
	on
	(
	 usdet.status_rec_no = @in_status_record_num
	and
	 tmp.status_rec_no = cast(@in_status_record_num as varchar)
	and
	 cast(usdet.ident_rec_no as varchar) = tmp.ident_rec_no
	)
	WHERE	usdet.status_rec_no = @in_status_record_num
	



	SET @error_type = 8

	DECLARE @record_count_costpoint int,
		@record_count_imaps int,
		@dollar_amount_costpoint decimal(14,2),
		@dollar_amount_imaps decimal(14,2)

	SELECT 	@record_count_costpoint = COUNT(1),
		@dollar_amount_costpoint = ISNULL(SUM(CST_AMT), 0)
	FROM	imaps.deltek.aoputlap_inp_detl
	WHERE	s_status_cd = 'I'
	AND	left(notes, 3) <> 'Bal'

	SELECT  @record_count_imaps = COUNT(1),
		@dollar_amount_imaps = ISNULL(SUM(AMOUNT), 0)
	FROM	XX_FIWLR_USDET_ARCHIVE
	WHERE	STATUS_REC_NO = @in_status_record_num
	AND	CP_HDR_NO IS NOT NULL
	AND	SOURCE_GROUP = 'AP'

	PRINT 'AP'
	PRINT @record_count_costpoint
	PRINT @record_count_imaps
	IF	@record_count_costpoint <> @record_count_imaps GOTO ErrorProcessing
	IF	@dollar_amount_costpoint <> @dollar_amount_imaps GOTO ErrorProcessing

	SELECT 	@record_count_costpoint = COUNT(1),
		@dollar_amount_costpoint = ISNULL(SUM(TRN_AMT) ,0)
	FROM	imaps.deltek.aoputlje_inp_tr
	WHERE	s_status_cd = 'I'
	AND	left(notes, 3) <> 'Bal'

	SELECT  @record_count_imaps = COUNT(1),
		@dollar_amount_imaps = ISNULL(SUM(AMOUNT), 0)
	FROM	XX_FIWLR_USDET_ARCHIVE
	WHERE	STATUS_REC_NO = @in_status_record_num
	AND	CP_HDR_NO IS NOT NULL
	AND	SOURCE_GROUP = 'JE'

	
	PRINT 'JE'
	PRINT @record_count_costpoint
	PRINT @record_count_imaps
	IF	@record_count_costpoint <> @record_count_imaps GOTO ErrorProcessing
	IF	@dollar_amount_costpoint <> @dollar_amount_imaps GOTO ErrorProcessing	



	INSERT INTO XX_FIWLR_USDET_MISCODES
	SELECT * FROM XX_FIWLR_USDET_ARCHIVE
	WHERE	STATUS_REC_NO = @in_status_record_num
	AND	CP_HDR_NO IS NULL

	SELECT @out_systemerror = @@ERROR
	IF @out_systemerror <> 0 
   		BEGIN
			SET @error_type = 2 
			GOTO ErrorProcessing
   		END

	DECLARE @ret_code int
	SET @ret_code = 1
	EXEC @ret_code = XX_FIWLR_MISCODE_UPDATE_FEEDBACK_SP

	SELECT @out_systemerror = @@ERROR 
	IF @out_systemerror <> 0 OR @ret_code <> 0
   		BEGIN
			SET @error_type = 6 
			GOTO ErrorProcessing
   		END
   		 
--begin change KM
-- AP Preprocessor Reconciliation data
	SELECT	@total_amt_inpstg_ap = ISNULL(SUM(amount),0)
	FROM	dbo.xx_fiwlr_usdet_v3
	WHERE	source_group = 'AP'
	AND	status_rec_no = @in_status_record_num

	SELECT	@total_amt_inphdr_ap = ISNULL(sum(ln_chg_cst_amt), 0)
	from 	imaps.deltek.vchr_ln
	WHERE	LEFT(vchr_ln_desc,LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num as varchar)+',') 
	AND	LEFT(NOTES, 3) <> 'Bal'

	SELECT	@total_amt_inphdr_err_ap = ISNULL(SUM(CST_AMT),0)
	FROM	imaps.deltek.aoputlap_inp_detl
	WHERE	LEFT(vchr_ln_desc,LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num as varchar)+',')
	AND 	s_status_cd = 'E'
	AND 	LEFT(notes, 3) <> 'Bal'

-- JE Preprocessor Reconciliation data
	SELECT	@total_amt_inpstg_je = ISNULL(SUM(amount),0)
	FROM	dbo.xx_fiwlr_usdet_v3
	WHERE	source_group = 'JE'
	AND	status_rec_no = @in_status_record_num

	SELECT	@total_amt_inpjtr_je = 	ISNULL(sum(trn_amt), 0)
	from 	imaps.deltek.je_trn
	WHERE	LEFT(je_trn_desc,LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num as varchar)+ ',') 
	AND	LEFT(NOTES, 3) <> 'Bal'

	SELECT	@total_amt_inpjtr_err_je = ISNULL(SUM(trn_amt),0)
	FROM	imaps.deltek.aoputlje_inp_tr
	WHERE	LEFT(je_trn_desc,LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num as varchar)+ ',') 
	AND	LEFT(NOTES, 3) <> 'Bal'
	AND 	s_status_cd = 'E'
--end change KM


	UPDATE	dbo.XX_IMAPS_INT_STATUS
	SET	record_count_initial = @total_amt_inpstg_ap,
       		record_count_success = @total_amt_inphdr_ap,
       		record_count_error = @total_amt_inphdr_err_ap,
       		amount_input = @total_amt_inpstg_je,
       		amount_processed = @total_amt_inpjtr_je,
       		amount_failed = @total_amt_inpjtr_err_je,
       		modified_by = SUSER_SNAME(),
       		modified_date = GETDATE()
 	WHERE	status_record_num = @in_status_record_num

	-- Deleting the WWERN16 transactions that are picked as part of the interface run
	TRUNCATE TABLE dbo.xx_fiwlr_wwern16 -- Added by Veera on 12/06/2005 Defect : DEV0000311

	SELECT @out_systemerror = @@ERROR 
	IF @out_systemerror <> 0 
   		BEGIN
			SET @error_type = 5 
			GOTO ErrorProcessing
   		END

	--begin DEV00000692
	declare @FIWLR_USER_ID char(5)
	set @FIWLR_USER_ID = 'FIWLR'

	declare @FIWLR_N16_USER_ID char(6)
	set @FIWLR_N16_USER_ID = 'FIWN16'
	
	
	update IMAPS.Deltek.VCHR_HDR
	set ENTR_USER_ID = @FIWLR_USER_ID
	where vchr_key in (
	select vchr_key
	from imaps.deltek.vchr_ln
	where left(vchr_ln_desc, len(@in_status_record_num)+1) = (cast(@in_status_record_num as varchar) + ',')
	)
-- CP600000322_Begin

	and COMPANY_ID = @DIV_16_COMPANY_ID

-- CP600000322_End


	update IMAPS.Deltek.VCHR_HDR
	set ENTR_USER_ID = @FIWLR_N16_USER_ID
	where vchr_key in (
	select vchr_key
	from imaps.deltek.vchr_ln
	where left(vchr_ln_desc, len(@in_status_record_num)+1) = (cast(@in_status_record_num as varchar) + ',')
	)
	and left(right(rtrim(notes),6), 3) = 'N16' --DR3449
-- CP600000322_Begin

	and COMPANY_ID = @DIV_16_COMPANY_ID

-- CP600000322_End

	update IMAPS.Deltek.JE_HDR
	set ENTR_USER_ID = @FIWLR_USER_ID
	where je_hdr_key in (
	select je_hdr_key
	from imaps.deltek.je_trn
	where left(je_trn_desc, len(@in_status_record_num)+1) = (cast(@in_status_record_num as varchar) + ',')
	)
-- CP600000322_Begin

	and COMPANY_ID = @DIV_16_COMPANY_ID

-- CP600000322_End

	SELECT @out_systemerror = @@ERROR 
	IF @out_systemerror <> 0 
   		BEGIN
			SET @error_type = 6 
			GOTO ErrorProcessing
   		END
	--end DEV00000692


	--update extract parameter
	update xx_processing_parameters
	set parameter_value = 
		(select  max(ref_creation_date+ref_creation_time)
		from xx_fiwlr_usdet_archive)
	where interface_name_cd = 'FIWLR'
	and parameter_name = 'EXTRACT_START_DATE'
	
	SELECT @out_systemerror = @@ERROR 
	IF @out_systemerror <> 0 
   		BEGIN
			SET @error_type = 6 
			GOTO ErrorProcessing
   		END

RETURN 0

ErrorProcessing:

	IF @error_type = 1
   		BEGIN
      			SET @error_code = 204 -- Attempt to insert a record into table XX_FIWLR_USDET_ARCHIVE failed.
      			SET @error_msg_placeholder1 = 'insert'
      			SET @error_msg_placeholder2 = 'a record into table XX_FIWLR_USDET_ARCHIVE'
   		END
	ELSE IF @error_type = 2
   		BEGIN
      			SET @error_code = 204 -- Attempt to insert a record into table XX_AOPUTLAP_INP_HDR_ERR failed.
      			SET @error_msg_placeholder1 = 'insert'
      			SET @error_msg_placeholder2 = 'a record into table XX_AOPUTLAP_INP_HDR_ERR'
   		END
	ELSE IF @error_type = 3
   		BEGIN
      			SET @error_code = 204 -- Attempt to insert a record into table XX_AOPUTLAP_INP_DETL_ERR failed.
      			SET @error_msg_placeholder1 = 'insert'
      			SET @error_msg_placeholder2 = 'a record into table XX_AOPUTLAP_INP_DETL_ERR'
   		END
	ELSE IF @error_type = 4
   		BEGIN
      			SET @error_code = 204 -- Attempt to insert a record into table XX_AOPUTLJE_INP_TR_ERR failed.
      			SET @error_msg_placeholder1 = 'insert'
      			SET @error_msg_placeholder2 = 'a record into table XX_AOPUTLJE_INP_TR_ERR'
   		END
	ELSE IF @error_type = 5
   		BEGIN
      			SET @error_code = 204 -- Attempt to update a XX_IMAPS_INT_STATUS record failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'a record into table XX_IMAPS_INT_STATUS'
   		END
	ELSE IF @error_type = 6 --DEV00000692
   		BEGIN
      			SET @error_code = 204 -- Attempt to update a XX_IMAPS_INT_STATUS record failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'ENTR_USER_ID in VCHR_HDR and JE_HDR'
   		END
	ELSE IF @error_type = 7 --DEV00000692
   		BEGIN
      			SET @error_code = 204 -- Attempt to update a XX_IMAPS_INT_STATUS record failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'MISCODE feedback'
   		END
	ELSE IF @error_type = 8 --DEV00000692
   		BEGIN
      			SET @error_code = 204 -- Attempt to update a XX_IMAPS_INT_STATUS record failed.
    			SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY PREPROCESSOR TOTALS MATCH'
			SET @ERROR_MSG_PLACEHOLDER2 = 'COSTPOINT TOTALS'
   		END


		EXEC dbo.xx_error_msg_detail
		   @in_error_code           = @error_code,
		   @in_display_requested    = 1,
		   @in_sqlserver_error_code = @out_systemerror,
		   @in_placeholder_value1   = @error_msg_placeholder1,
		   @in_placeholder_value2   = @error_msg_placeholder2,
		   @in_calling_object_name  = @sp_name,
		   @out_msg_text            = @out_status_description OUTPUT

RETURN 1

END


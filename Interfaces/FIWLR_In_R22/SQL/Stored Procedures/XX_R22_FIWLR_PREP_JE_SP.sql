SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE ID = object_id(N'[dbo].[XX_R22_FIWLR_PREP_JE_SP]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[XX_R22_FIWLR_PREP_JE_SP]
GO

CREATE PROCEDURE [dbo].[XX_R22_FIWLR_PREP_JE_SP] (
	@in_status_record_num INT, 
	@out_systemerror INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) =NULL OUTPUT)
AS

/************************************************************************************************/
/* Procedure Name	: XX_R22_FIWLR_PREP_JE_SP													*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   							*/
/* Description    	: IMAPS FIW-LR Preprocessor Journal Entry Procedure							*/
/* Date				: August 10, 2008															*/
/* Notes			: IMAPS FIW-LR Preprocessor Journal Entry program will be executed 			*/
/*					  through FIW-LR Run interface program to group all the JE related			*/
/*					  transactions information and validate as per the JE Preprocessor			*/
/*					  data element requirements and also insert the JE Balancing transaction	*/
/* Prerequisites	: XX_R22_FIWLR_USDET_V3, DELTEK.AOPUTLJE_INP_TR Table(s) should be created. */
/*					  Access priveleges to AOPUTLJE_INP_TR table(s) should be provided.			*/
/* Parameter(s)		: 																			*/
/*	Input			: Status Record Number														*/
/*	Output			: Error Code and Error Description											*/
/* Tables Updated	: DELTEK.AOPUTLJE_INP_TR													*/
/* Version			: 1.0																		*/
/************************************************************************************************/
/* Date			Modified By				Description of change			  						*/
/* ----------   -------------  	   		------------------------    			  				*/
/* 08-10-2008   Veera Veeramachanane   	Created Initial Version									*/
/************************************************************************************************/
BEGIN

DECLARE 

	@retcode	 INT,
	@sp_name	 SYSNAME,
	@numberofrecords INT

	SELECT 	@sp_name	= 'XX_R22_FIWLR_PREP_JE_SP'

	--1.
	TRUNCATE TABLE xx_r22_fiwlr_usdet_temp

	--2.
	INSERT INTO xx_r22_fiwlr_usdet_temp
	(ident_rec_no,
	status_rec_no,
	stream_id,
	ledger_type,
	major,
	minor,
	subminor,
	analysis_code,
	division,
	extract_date,
	fiwlr_inv_date,
	voucher_no,
	voucher_grp_no,
	wwer_exp_key,
	wwer_exp_dt,
	source,
	acct_month,
	acct_year,
	ap_idx,
	project_no,
	description1,
	description2,
	department,
	accountant_id,
	po_no,
	inv_no,
	etv_code,
	country_code,
	vendor_id,
	employee_no,
	amount,
	input_type,
	ap_doc_type,
	ref_creation_date,
	ref_creation_time,
	creation_date,
	source_group,
	vend_name,
	emp_lastname,
	emp_firstname,
	proj_id,
	proj_abbr_cd,
	org_id,
	org_abbr_cd,
	pag_cd,
	val_nval_cd,
	acct_id,
	order_ref,
	proj,
	hours,
	reference1,
	reference2,
	reference3,
	reference4,
	reference5)
	SELECT
	ident_rec_no,
	status_rec_no,
	stream_id,
	ledger_type,
	major,
	minor,
	subminor,
	analysis_code,
	division,
	extract_date,
	fiwlr_inv_date,
	voucher_no,
	voucher_grp_no,
	wwer_exp_key,
	wwer_exp_dt,
	source,
	acct_month,
	acct_year,
	ap_idx,
	project_no,
	description1,
	description2,
	department,
	accountant_id,
	po_no,
	inv_no,
	etv_code,
	country_code,
	vendor_id,
	employee_no,
	amount,
	input_type,
	ap_doc_type,
	ref_creation_date,
	ref_creation_time,
	creation_date,
	source_group,
	vend_name,
	emp_lastname,
	emp_firstname,
	proj_id,
	proj_abbr_cd,
	org_id,
	org_abbr_cd,
	pag_cd,
	val_nval_cd,
	acct_id,
	order_ref,
	proj,
	hours,
	reference1,
	reference2,
	reference3,
	reference4,
	reference5
	FROM xx_r22_fiwlr_usdet_v3


	--3.
	EXEC @retcode = XX_R22_FIWLR_LOAD_PREPROCESSORS_SP @out_status_description

	IF @retcode <> 0
		GOTO ErrorProcessing


RETURN 0

	ErrorProcessing:

	PRINT @out_status_description

RETURN 1

END

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


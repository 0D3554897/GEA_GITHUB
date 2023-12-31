SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_WWERN16_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_WWERN16_SP]
GO


CREATE PROCEDURE [dbo].[XX_FIWLR_WWERN16_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_WWERN16_SP							*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR WWERN16 Data Procedure					*/
/* Date			: October 22, 2005						        */
/* Notes		: IMAPS FIW-LR WWERN16 expense information from XX_FIWLR_WWERN16 will 	*/
/*			  be update to the XX_FIWLR_USDET_V3 table				*/
/* Prerequisites	: XX_FIWLR_USDET_V3 and XX_FIWLR_WWERN16 table should be created	*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: XX_FIWLR_USDET_V3 							*/
/* Version		: 1.1									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 10-22-2005   Veera Veeramachanane   	Created Initial Version					*/
/* 11-05-2005   Veera Veeramachanane   	Modified Code to add Reference columns : DEV00000243	*/
/************************************************************************************************/


DECLARE 

	@batch_id		INT,
	@numberofrecords 	INT,
	@stream_id		SYSNAME,
	@ledger_type		SYSNAME,
	@cty_code		SYSNAME,
	@error_type		INT,	
	@error_code		INT,
	@error_msg_placeholder1	SYSNAME,
	@error_msg_placeholder2 SYSNAME,
	@sp_name		SYSNAME,
	@fiwlr_in_record_num 	INT

BEGIN

-- set local constants
	SELECT	@sp_name = 'XX_FIWLR_WWERN16_SP',
		@error_msg_placeholder1	= NULL,
		@error_msg_placeholder2 = NULL,
		@cty_code = '897',
		@stream_id = 'US',
		@ledger_type = 'L'

-- Insert all WWER N16 expense transactions from XX_FIWLR_USDET staging table and create voucher records in XX_AOPUTLAP_INP_HDR staging table

	INSERT INTO dbo.xx_fiwlr_usdet_v3 
	      (
		status_rec_no,stream_id,ledger_type,
		major,minor,subminor,analysis_code,division,
		extract_date,fiwlr_inv_date,
		voucher_no,voucher_grp_no,wwer_exp_key,
		wwer_exp_dt,
		source,acct_month,acct_year,ap_idx,
		project_no,description1,description2,
		department,accountant_id,po_no,inv_no,etv_code,
		country_code,vendor_id,employee_no,amount,
		input_type,ap_doc_type,ref_creation_date,
		ref_creation_time,creation_date,source_group,vend_name,
		emp_lastname,emp_firstname,proj_id,proj_abbr_cd,org_id,
		org_abbr_cd,pag_cd,val_nval_cd,acct_id
		,reference1,reference2,-- Added by Veera on 11/07/2005 - Defect : DEV00000243
		reference3,reference4,reference5 )-- Added by Veera on 11/07/2005 - Defect : DEV00000243
	SELECT  @in_status_record_num,@stream_id,@ledger_type,
		major,minor,subminor,expense_code,division,
		SUBSTRING(CONVERT(VARCHAR(10), processed_dt,121),1,10),
		SUBSTRING(CONVERT(VARCHAR(10), processed_dt,121),1,10),
		rptkey,	NULL,expkey,
		SUBSTRING(CONVERT(VARCHAR(10), expense_dt,121),1,10),
		source,NULL,NULL,NULL,
		igs_project_no,SUBSTRING(invoice_txt,1,30),SUBSTRING(invoice_txt,26,30),
		department,account_id,NULL,NULL,NULL,
		@cty_code,employee_ser,employee_ser,amount,
		NULL,NULL,NULL,
		NULL,creation_date,source_group,NULL,
		emp_last_nm,emp_inits_nm,NULL,NULL,NULL,
		NULL,NULL,NULL,NULL
		,NULL,NULL,-- Added by Veera on 11/07/2005 - Defect : DEV00000243
		NULL,NULL,NULL-- Added by Veera on 11/07/2005 - Defect : DEV00000243
	FROM	dbo.xx_fiwlr_wwern16

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 1 
				GOTO ErrorProcessing
   			END

--			Print 'Number of WWERN16 Records inserted ' + CAST(@NumberOfRecords AS char)
RETURN 0

ErrorProcessing:

	IF @error_type = 1
   		BEGIN
      			SET @error_code = 204 -- Attempt to insert a record into table XX_FIWLR_USDET_V3 failed.
      			SET @error_msg_placeholder1 = 'insert'
      			SET @error_msg_placeholder2 = 'a record into table XX_FIWLR_USDET_V3'
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

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

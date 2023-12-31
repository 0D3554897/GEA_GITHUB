SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_EMP_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_EMP_SP]
GO


CREATE PROCEDURE [dbo].[XX_FIWLR_EMP_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

DECLARE 

	@BID 			INT,
	@NumberOfRecords 	INT,
	@error_type		INT,	
	@error_code		INT,
	@error_msg_placeholder1	SYSNAME,
	@error_msg_placeholder2 SYSNAME,
	@sp_name		SYSNAME,
	@fiwlr_in_record_num 	INT

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_EMP_SP							*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR Employee Data Procedure					*/
/* Date			: October 22, 2005						        */
/* Notes		: IMAPS FIW-LR Employee information will update the XX_FIWLR_USDET_V3 	*/
/*			  table with the employee details received from FIW-LR. 		*/
/* Prerequisites	: XX_FIWLR_USDET_V3 and XX_FIWLR_EMP_V table should be created		*/
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
/* 05-11-2017   Tatiana Perova          CR9364  some employee alredy got names from WWER in XX_FIWLR_VENDOR_SP  */
/* 10-12-2017   Tatiana Perova          CR9840  Employee Last First name are not from IBM ledger  */
/************************************************************************************************/

BEGIN

-- set local constants
	SELECT	@sp_name = 'XX_FIWLR_EMP_SP',
		@error_msg_placeholder1	= NULL,
		@error_msg_placeholder2 = NULL

-- Update XX_FIWLR_USDET_V3 table with the employee detail information 
	INSERT INTO dbo.xx_fiwlr_usdet_v3 
       		(
		status_rec_no,stream_id,ledger_type,
		major,minor,subminor,analysis_code,
		division,extract_date,fiwlr_inv_date,
		voucher_no,voucher_grp_no,wwer_exp_key,
		wwer_exp_dt,source,acct_month,acct_year,
		ap_idx,project_no,description1,description2,
		department,accountant_id,po_no,inv_no,etv_code,
		country_code,vendor_id,employee_no,amount,
		input_type,ap_doc_type,ref_creation_date,
		ref_creation_time,creation_date,source_group,
		vend_name,emp_lastname,emp_firstname,proj_id,
		proj_abbr_cd,org_id,org_abbr_cd,pag_cd,
		val_nval_cd,acct_id
		,reference1,reference2,-- Added by Veera on 11/07/2005 - Defect : DEV00000243
		reference3,reference4,reference5 )-- Added by Veera on 11/07/2005 - Defect : DEV00000243
	SELECT 
		a.status_rec_no,a.stream_id,a.ledger_type,
		a.major,a.minor,a.subminor,a.analysis_code,
		a.division,a.extract_date,a.fiwlr_inv_date,
		a.voucher_no,a.voucher_grp_no,a.wwer_exp_key,
		a.wwer_exp_dt,a.source,a.acct_month,a.acct_year,
		a.ap_idx,a.project_no,a.description1,a.description2,
		a.department,a.accountant_id,a.po_no,a.inv_no,a.etv_code,
		a.country_code,a.vendor_id,a.employee_no,a.amount,
		a.input_type,a.ap_doc_type,a.ref_creation_date,
		a.ref_creation_time,getdate(),a.source_group,
		a.vend_name,
		case when  rtrim(isnull(a.emp_lastname,'')) = ''  and rtrim(isnull(e.LAST_NAME,'')) <> '' then e.LAST_NAME 
		     when  rtrim(isnull(a.emp_lastname,'')) = ''  and rtrim(isnull(v.VEND_NAME,'')) <> '' then  SUBSTRING(v.VEND_NAME, 1, case when CHARINDEX(',',v.VEND_NAME,1) > 1  then CHARINDEX(',',v.VEND_NAME,1) -1 else 0 end)
		     else a.emp_lastname end emp_lastname,       --  CR9364
		case when  rtrim(isnull(a.emp_lastname,'')) = ''  and rtrim(isnull(e.FIRST_NAME,'')) <> '' then e.FIRST_NAME 
		     when  rtrim(isnull(a.emp_lastname,'')) = ''  and rtrim(isnull(v.VEND_NAME,'')) <> '' then  SUBSTRING(v.VEND_NAME,  CHARINDEX(',',v.VEND_NAME,1)+1, case when CHARINDEX(',',v.VEND_NAME,1) > 1 then  LEN(v.VEND_NAME) - CHARINDEX(',',v.VEND_NAME,1)  else 0 end)
		     else  a.emp_firstname end emp_firstname,   --  CR9364
		a.proj_id,
		a.proj_abbr_cd,a.org_id,a.org_abbr_cd,a.pag_cd,
		a.val_nval_cd,a.acct_id
		,reference1,reference2,-- Added by Veera on 11/07/2005 - Defect : DEV00000243
		reference3,reference4,reference5 -- Added by Veera on 11/07/2005 - Defect : DEV00000243
	FROM	IMAPS.deltek.EMPL e 
	    RIGHT OUTER JOIN dbo.xx_fiwlr_usdet_v2 a  --CR9840  
   			ON a.employee_no = e.EMPL_ID
   		LEFT OUTER JOIN IMAPS.deltek.VEND v
   			ON a.EMPLOYEE_NO = v.VEND_ID
	WHERE (a.employee_no IS NOT NULL)

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 1 
				GOTO ErrorProcessing
   			END

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

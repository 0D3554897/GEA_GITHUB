use imapsstg

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_VENDOR_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_VENDOR_SP]
GO

CREATE PROCEDURE [dbo].[XX_FIWLR_VENDOR_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

DECLARE 

	@numberofrecords 	INT,
	@error_type		INT,	
	@error_code		INT,
	@error_msg_placeholder1	SYSNAME,
	@error_msg_placeholder2 SYSNAME,
	@sp_name		SYSNAME,
	@fiwlr_in_record_num 	INT

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_VENDOR_SP							*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR Vendor Data Procedure					*/
/* Date			: October 22, 2005						        */
/* Notes		: IMAPS FIW-LR Vendor information will update the XX_FIWLR_USDET_V2 	*/
/*			  table with the vendor details received from FIW-LR. 			*/
/* Prerequisites	: XX_FIWLR_USDET_V3 and XX_FIWLR_VEND_V table should be created		*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: XX_FIWLR_USDET_V2			 				*/
/* Version		: 1.0									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 10-22-2005   Veera Veeramachanane   	Created Initial Version					*/
/* 11-05-2005   Veera Veeramachanane   	Modified Code to add Reference columns : DEV00000243	*/
/* 05-11-2017   Tatiana Perova          CR9364  for source 005 data is from WWER staging XX_FIWLR_WWER_EMPL */
/************************************************************************************************/

BEGIN

-- set local constants

	SELECT	@sp_name = 'XX_FIWLR_VENDOR_SP',
		@error_msg_placeholder1	= NULL,
		@error_msg_placeholder2 = NULL

-- Update XX_FIWLR_USDET_V2 table with the vendor detail information recieved from FIW-LR 
	INSERT INTO dbo.xx_fiwlr_usdet_v2 
       	        (
		status_rec_no,stream_id,ledger_type,major,minor,subminor,
		analysis_code,division,extract_date,fiwlr_inv_date,
		voucher_no,voucher_grp_no,wwer_exp_key,wwer_exp_dt,
		source,acct_month,acct_year,ap_idx,project_no,
		description1,description2,department,accountant_id,
		po_no,inv_no,etv_code,country_code,vendor_id,
		employee_no,amount,input_type,ap_doc_type,
		ref_creation_date,ref_creation_time,creation_date,
		source_group,vend_name,emp_lastname,emp_firstname,
		proj_id,proj_abbr_cd,org_id,org_abbr_cd,pag_cd,
		val_nval_cd,acct_id
		,reference1,reference2,-- Added by Veera on 11/07/2005 - Defect : DEV00000243
		reference3,reference4,reference5 )-- Added by Veera on 11/07/2005 - Defect : DEV00000243
	SELECT
		@in_status_record_num,a.stream_id,a.ledger_type,a.major,a.minor,a.subminor,
		a.analysis_code,a.division,a.extract_date,a.fiwlr_inv_date,
		a.voucher_no,a.voucher_grp_no,a.wwer_exp_key,a.wwer_exp_dt,
		a.source,a.acct_month,a.acct_year,a.ap_idx,a.project_no,
		a.description1,a.description2,a.department,a.accountant_id,
		a.po_no,a.inv_no,a.etv_code,a.country_code,a.vendor_id,
		a.employee_no,a.amount,a.input_type,a.ap_doc_type,
		a.ref_creation_date,a.ref_creation_time,getdate(),
		a.source_group,v.vend_name,a.emp_lastname,a.emp_firstname,
		a.proj_id,a.proj_abbr_cd,a.org_id,a.org_abbr_cd,a.pag_cd,
		a.val_nval_cd,a.acct_id
		,reference1,reference2,-- Added by Veera on 11/07/2005 - Defect : DEV00000243
		reference3,reference4,reference5 -- Added by Veera on 11/07/2005 - Defect : DEV00000243
	FROM 	dbo.xx_fiwlr_vend_v v RIGHT OUTER JOIN dbo.xx_fiwlr_usdet_v1 a
   		ON v.vendor_id = a.vendor_id
	WHERE 	(a.vendor_id IS NOT NULL)
	AND 	major  
			IN (	SELECT major 
                        	FROM   dbo.xx_fiwlr_inc_exc as i
                        	WHERE 	EXISTS
                        		  (SELECT  CASE WHEN major IS NULL THEN a.major
                                      			ELSE	major 
                                      	      	   END
                               		   FROM	   dbo.xx_fiwlr_inc_exc as b
                               		   WHERE   i.major         = b.major
--                             		   AND	   a.minor         = b.minor
--					   AND	   a.subminor      = b.subminor
                                	   AND	   i.extract_type  = 'I'))


	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 1 
				GOTO ErrorProcessing
   			END


	--update vendor name changes
	--begin DR3606
	update v
	set vend_name= left(fv.vend_name,25) ,
	    vend_long_name=left(fv.vend_name,40) ,
		modified_by='FIWLR INTERFACE',
		time_stamp=current_timestamp
	from imaps.deltek.vend v inner join xx_fiwlr_vend_v fv  on  fv.vendor_id=v.vend_id
	where 
	v.vend_name <> left(fv.vend_name,25) or
	v.vend_long_name <> left(fv.vend_name,40)

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 1 
				GOTO ErrorProcessing
   			END

	
	--end DR3606
	
	
	-- begin CR9364   Retrive missed vendors from WWER data
	
	Update  fiwlr
	SET fiwlr.VENDOR_ID = wwer.EMPLOYEE_NO,
		fiwlr.VEND_NAME = LEFT(wwer.EMPLOYEE_NAME,30),
		fiwlr.EMPLOYEE_NO = wwer.EMPLOYEE_NO, 
		fiwlr.EMP_LASTNAME = LEFT(LEFT(wwer.EMPLOYEE_NAME,
		               case when CHARINDEX(',',wwer.EMPLOYEE_NAME,1) < 2 then LEN(wwer.EMPLOYEE_NAME) else CHARINDEX(',',wwer.EMPLOYEE_NAME,1) -1 end ),30),
		fiwlr.EMP_FIRSTNAME =  LEFT(LTRIM(SUBSTRING(wwer.EMPLOYEE_NAME,CHARINDEX(',',wwer.EMPLOYEE_NAME,1)+1,LEN(wwer.EMPLOYEE_NAME))),30)
	from dbo.xx_fiwlr_usdet_v2 fiwlr  inner join dbo.XX_FIWLR_WWER_EMPL wwer
	on fiwlr.VOUCHER_NO = wwer.VOUCHER_NO
	where wwer.EMPLOYEE_NAME is not NULL and wwer.EMPLOYEE_NO is not NULL
	
		SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 1 
				GOTO ErrorProcessing
   			END
	
	 	-- update vendor name in Costpoint
	 	
	update v
	set vend_name= left(fv.vend_name,25),
	    vend_long_name= left(fv.vend_name,40),
		modified_by='FIWLR INTERFACE',
		time_stamp=current_timestamp
	from imaps.deltek.vend v inner join 
	 ( select distinct EMPLOYEE_NO as VENDOR_ID, EMPLOYEE_NAME AS VEND_NAME from dbo.XX_FIWLR_WWER_EMPL) fv  
	   on  fv.vendor_id=v.vend_id
	where 
	(v.vend_name <> left(fv.vend_name,25) or
	v.vend_long_name <> left(fv.vend_name,40)) and isnull(fv.vend_name,'') <> '' 
	

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 1 
				GOTO ErrorProcessing
   			END
	-- end CR9364

	

RETURN 0

ErrorProcessing:

	IF @error_type = 1
   		BEGIN
      			SET @error_code = 204 -- Attempt to insert a record into table XX_FIWLR_USDET_V2 failed.
      			SET @error_msg_placeholder1 = 'insert'
      			SET @error_msg_placeholder2 = 'a record into table XX_FIWLR_USDET_V2'
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


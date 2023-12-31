USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_FIWLR_IMAPS_STG_SP]    Script Date: 08/16/2007 10:45:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/****** Object:  Stored Procedure dbo.XX_FIWLR_IMAPS_STG_SP    Script Date: 8/16/2007 10:46:05 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_IMAPS_STG_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   drop procedure [dbo].[XX_FIWLR_IMAPS_STG_SP]
GO



CREATE PROCEDURE [dbo].[XX_FIWLR_IMAPS_STG_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(275) = NULL OUTPUT) 
AS

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_IMAPS_STG_SP							*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR IMAPS Accounts Payable Procedure				*/
/* Date			: October 15, 2005						        */
/* Notes		: IMAPS FIW-LR IMAPS Accounts Payable program will group the AP data 	*/
/*			  and insert into AP Preprocessor tables. 				*/
/* Prerequisites	: XX_FIWLR_USDET_V3, DELETEK.AOPUTLAP_INP_HDR and 			*/
/*			  DELTEK.AOPUTLAP_INP_DETL Table(s) should be created.			*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: DELTEK.AOPUTLAP_INP_HDR and DELTEK.AOPUTLAP_INP_DETL 			*/
/* Version		: 1.2									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 10-20-2005   Veera Veeramachanane   	Created Initial Version					*/
/* 11-06-2005	Veera Veeramachanane   	Modified Code to make invoice amount = 0 in header table*/
/*					and add org_id in detail table. Defect : DEV00000243	*/
/* 11-22-2005	Veera Veeramachanane   	Modified Code to change the default values for AP Acct 	*/
/*					Cash Acct Description to NULL Defect : DEV00000269	*/
/* 03-29-2006	Veera Veeramachanane   	As per the latest bug fix provided by Deltek to imporve */
/*					the performance the default s_status_cd needs to be 	*/
/*					populated with 'U' instead of null. The procedure 	*/
/*					XX_FIWLR_IMAPS_STG_SP is modified to populate the 	*/
/*					S_STATUS_CD as 'U' in AOPUTLAP_INP_HDR and 		*/
/*					AOPUTLAP_INP_DETL Preprocessor tables.			*/
/*					Defect : DEV00000644					*/
/* 04-12-2006    Clare Robbins		If the vendor name is null, use employee name if not null.  */
/*					if employee name null, leave name set to vendor id.*/
/* 04-24-2006    Clare Robbins		change interface status number to varchar for comaprison in where clause. */
/*					Defect :DEV00000813. */
/* 07-27-2006	Veera Veeramachanane   	Fixed the vendor bug of repeating the same vendor name 	*/
/*					for all the vendor name populated for source WWER and 	*/
/*					N16. Also modified code to send vendor longname, 	*/
/*					modified by and rowversion to trace the vendors created	*/
/*					Feature :DEV00001077 					*/
/* 05/15/2008   HVT                     Ref CP600000322. Multi-company fix (1 instance).        */
/************************************************************************************************/

DECLARE @voucher_no 		VARCHAR(30),
	@spreturncode 		INT,
	@vchr_no_v		INT,
	@lastvchrno 		INT,
	@headercounter 		INT,
	@detailcounter 		INT,
	@vchr_detl_no		INT,
	@vchrlno 		INT,
	@numberofrecords 	INT,
	@fiwlr_in_record_num 	INT,
	
	@vrec_no		INT,
	@vvchr_no		INT,
	@vfy_cd			VARCHAR(6),
	@vacct_id		VARCHAR(20),
	@vorg_id		VARCHAR(30), -- Added by Veera on 11/07/2005 - Defect : DEV00000243
	@vproj_id		VARCHAR(30),
	@vamount		DECIMAL(15,2),
	@vvchrln_desc		VARCHAR(30),
	@vproj_abbr_cd		VARCHAR(10),
	@vnotes			VARCHAR(254),
	@vs_status_cd		VARCHAR(3),	-- Added by Veera on 03/29/2006 - Defect : DEV00000644
	@vchr_no		INT,
	@fy_cd			VARCHAR(6),
	@pd_no			NUMERIC(2),
	@sub_pd_no		NUMERIC(2),
	@vend_id		VARCHAR(10),
	@vend_name		VARCHAR(40),
	@invc_id		VARCHAR(10),
	@invc_dt		VARCHAR(10),
	@invc_amt		DECIMAL (15,2),
	@po_id			VARCHAR(10),
	@notes			VARCHAR(254),
	@doesvendorexists 	TINYINT,
	@pay_terms		VARCHAR(30),
	@ap_acct_desc		VARCHAR(30), 
	@cash_acct_desc		VARCHAR(30),
	@error_type		INT,
	@error_code		INT,
	@error_msg_placeholder1	SYSNAME,
	@error_msg_placeholder2 SYSNAME,
	@sp_name		SYSNAME,
	@seq_hdr		INT,
	@seq_detl		INT,
-- Start Added by Veera on 07/27/06 Feature : DEV00001077
--	@emp_firstname		VARCHAR(30),
--	@emp_lastname		VARCHAR(30)
	@in_vend_longname	VARCHAR(40), 
	@fiwlr_intername 	VARCHAR(20), 
	@fiwlr_rowversion	INT	     

BEGIN

-- CP600000322_Begin
DECLARE @DIV_16_COMPANY_ID varchar(10)

SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'FIWLR'
-- CP600000322_End

	SELECT	@SP_NAME = 'XX_FIWLR_IMAPS_STG_SP',
--	Start Added by Veera on 11/22/2005 Defect: DEV00000269
--		@ap_acct_desc	= 'INTERCOMPANY AP SUSPENSE', 
--		@cash_acct_desc = 'INTERCOMPANY AP SUSPENSE',
		@ap_acct_desc	= NULL,  
		@cash_acct_desc = NULL,
--	End Added by Veera on 11/22/2005 Defect: DEV00000269
		@pay_terms = 'NET 30',
		@lastvchrno = NULL,
		@vchrlno   = 0,			
		@invc_amt = 0, -- Added by Veera on 11/07/2005 - Defect : DEV00000243
		@vs_status_cd = 'U', -- Added by Veera on 03/29/2006 - Defect : DEV00000644
		@error_msg_placeholder1	= NULL,
		@error_msg_placeholder2 = NULL,
-- Start Added by Veera on 07/27/06 Feature : DEV00001077
		@fiwlr_intername  = 'FIWLR INTERFACE',
		@fiwlr_rowversion = 5000 


	DECLARE ap_hdr CURSOR FOR 

-- Cursor to insert records to AP Preprocessor tables from staging table XX_AOPUTLAP_INP_HDR
		SELECT 	
			vchr_no,
			fy_cd,
			pd_no,
			sub_pd_no,
			vend_id,
			invc_id,
			invc_dt,
			--invc_amt,
			po_id,
			notes
		FROM 	dbo.xx_aoputlap_inp_hdrv
		WHERE  	RTRIM(LTRIM(SUBSTRING(notes,1,len(@in_status_record_num)))) = @in_status_record_num
		ORDER BY vend_id

	OPEN ap_hdr

-- Start Modifications by Veera on 11/07/2005 - Defect : DEV00000243
--	FETCH NEXT FROM ap_hdr INTO @vchr_no, @fy_cd, @pd_no, @sub_pd_no, @vend_id, @invc_id, @invc_dt, @invc_amt, @po_id, @notes 
	FETCH NEXT FROM ap_hdr INTO @vchr_no, @fy_cd, @pd_no, @sub_pd_no, @vend_id, @invc_id, @invc_dt, @po_id, @notes 
-- End Modifications by Veera on 11/07/2005 - Defect : DEV00000243

--PRINT 'Vend_id 1 : ' + @vend_id
--PRINT 'Vend name 1 : ' + @vend_name
	WHILE (@@fetch_status = 0)
	BEGIN
-- Get values for REC_NO from xx_nextval_sp. xx_nextval_sp procedure will generate unique seuential values
		EXEC @seq_hdr =  dbo.xx_hdr_nextval_sp  a,1
		IF   @seq_hdr = NULL 
			GOTO ErrorProcessing	

-- Vendor Process to add vendor in IMAPS if does not exist 
		SET @doesvendorexists = 0

		SELECT	@doesvendorexists = 1
		FROM	IMAPS.Deltek.VEND
		WHERE	vend_id = @vend_id
-- CP600000322_Begin
		AND 	COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000322_End

--PRINT 'Vend_id 2 : ' + @vend_id
--PRINT 'Vend name 2 : ' + @vend_name


		IF @doesvendorexists <> 1 
			BEGIN
			 	SET @vend_name = NULL				

--PRINT 'Vend_id 3 : ' + @vend_id
--PRINT 'Vend name 3 : ' + @vend_name

				SELECT 	DISTINCT TOP 1
					@vend_name = vend_name,
-- Start Added by Veera on 07/27/06 Feature : DEV00001077
					@in_vend_longname = reference1
--					@emp_firstname = emp_firstname,  --added by CR 4/12/06
--					@emp_lastname = emp_lastname  --added by CR 4/12/06
				FROM 	dbo.xx_fiwlr_usdet_v3
				WHERE 	vendor_id = @vend_id
				AND	status_rec_no = @in_status_record_num

--PRINT 'Vend_id 4 : ' + @vend_id
--PRINT 'Vend name 4 : ' + @vend_name

				IF @vend_name IS NULL
					BEGIN
-- Start Commented out by Veera on 07/27/06 Feature : DEV00001077
/*					IF @emp_lastname IS NOT NULL
						SET @vend_name = @emp_firstname + ' ' + @emp_lastname
					ELSE
*/					 	SET @vend_name = NULL
	  					SET @vend_name = @vend_id
--PRINT 'Vend_id 5 : ' + @vend_id
--PRINT 'Vend name 5 : ' + @vend_name

					END
				EXEC @out_systemerror 	=  dbo.xx_add_vendor_sp
				     @in_vendorid 	= @vend_id,
				     @in_vendorname 	= @vend_name,
-- Start Added by Veera on 07/27/06 Feature : DEV00001077
				     @in_vendorlongname = @in_vend_longname,
				     @in_modified_by 	= @fiwlr_intername,
				     @in_rowversion 	= @fiwlr_rowversion			
								
--PRINT 'Vend_id 6 : ' + @vend_id
--PRINT 'Vend name 6 : ' + @vend_name
--PRINT 'Vend_ longname 6 : ' + @in_vend_longname
--PRINT 'Modifi 6 : ' +  @fiwlr_intername
--PRINT 'rowversion 6 : ' + @fiwlr_rowversion


				IF   @out_systemerror <>0 
					GOTO ErrorProcessing
			END /* Vendor is inserted if does not exists in IMAPS */

-- Insert all vouchers into AP Preprocressor header table AOPUTLAP_INP_HDR from the staging table XX_AOPUTLAP_INP_HDR
		INSERT INTO imaps.deltek.aoputlap_inp_hdr
			(
			rec_no,s_status_cd,vchr_no,fy_cd,
			pd_no,sub_pd_no,vend_id,terms_dc,
			invc_id,invc_dt_fld,invc_amt,disc_dt_fld,
			disc_pct_rt,disc_amt,due_dt_fld,hold_vchr_fl,
			pay_when_paid_fl,pay_vend_id,pay_addr_dc,po_id,
			po_rlse_no,rtn_rate,ap_acct_desc,cash_acct_desc,
			s_invc_type,ship_amt,chk_fy_cd,chk_pd_no,
			chk_sub_pd_no,chk_no,chk_dt_fld,chk_amt,
			disc_taken_amt,invc_pop_dt_fld,print_note_fl,jnt_pay_vend_name,
			notes,time_stamp,sep_chk_fl )
		VALUES 	(
			@seq_hdr,
			@vs_status_cd, -- Added by Veera on 03/29/2006 - Defect : DEV00000644
			@vchr_no,@fy_cd,
			@pd_no,@sub_pd_no,@vend_id,@pay_terms,
			@invc_id,@invc_dt,@invc_amt,NULL,
			NULL,NULL,NULL,'N',
			'N',NULL,NULL,@po_id,
			NULL,0,@ap_acct_desc, @cash_acct_desc, 
			NULL,0,NULL,NULL,
			NULL,NULL,NULL,0,
			0,NULL,'N',NULL,
			@notes,GETDATE(),'N' )
/*
PRINT 'Vend_id 7 : ' + @vend_id
PRINT 'Vend name 7 : ' + @vend_name
PRINT 'Vend_ longname 7 : ' + @in_vend_longname
PRINT 'Modifi 7 : ' +  @fiwlr_intername
--PRINT 'rowversion 7 : ' + @fiwlr_rowversion
*/
		SELECT @out_systemerror = @@error --,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 1 
			  GOTO ErrorProcessing
   			END

--		PRINT 'Number of Records inserted ' + CAST(@NumberOfRecords AS VARCHAR)

-- Start Modifications by Veera on 11/07/2005 - Defect : DEV00000243
--	FETCH NEXT FROM ap_hdr INTO @vchr_no, @fy_cd, @pd_no, @sub_pd_no, @vend_id, @invc_id, @invc_dt, @invc_amt, @po_id, @notes 
	FETCH NEXT FROM ap_hdr INTO @vchr_no, @fy_cd, @pd_no, @sub_pd_no, @vend_id, @invc_id, @invc_dt, @po_id, @notes 
-- End Modifications by Veera on 11/07/2005 - Defect : DEV00000243
	END /* While continues to insert all vouchers */
/*
PRINT 'Vend_id 8 : ' + @vend_id
PRINT 'Vend name 8 : ' + @vend_name
PRINT 'Vend_ longname 8 : ' + @in_vend_longname
PRINT 'Modifi 8 : ' +  @fiwlr_intername
--PRINT 'rowversion 8 : ' + @fiwlr_rowversion
*/
	CLOSE ap_hdr
	DEALLOCATE ap_hdr
/*
PRINT 'Vend_id 9 : ' + @vend_id
PRINT 'Vend name 9 : ' + @vend_name
PRINT 'Vend_ longname 9 : ' + @in_vend_longname
PRINT 'Modifi 9 : ' +  @fiwlr_intername
--PRINT 'rowversion 9 : ' + @fiwlr_rowversion
*/
-- Cursor to insert records to AP Preprocessor Detail table AOPUTLAP_INP_DETL from staging table XX_AOPUTLAP_INP_DETL
	DECLARE aop_detl_c CURSOR FOR

		SELECT 	v.vchr_no, 
			v.fy_cd, v.acct_id, v.org_id, 
			v.cst_amt,v.vchr_ln_desc, 
			v.proj_abbrv_cd, v.notes
		FROM 	dbo.xx_aoputlap_inp_detlv v,
			imaps.deltek.aoputlap_inp_hdr h
		WHERE 	v.vchr_no = h.vchr_no
		AND	RTRIM(LTRIM(SUBSTRING(h.notes,1,LEN(@in_status_record_num)))) = CAST(@in_status_record_num AS VARCHAR(20)) --updated by CR 4/24/06 DEV00000813
		ORDER BY v.vchr_no

	OPEN aop_detl_c
	FETCH NEXT FROM  aop_detl_c INTO @vvchr_no,@vfy_cd,@vacct_id,@vorg_id,@vamount,@vvchrln_desc,@vproj_abbr_cd,@vnotes

		SET 	@lastvchrno = @vvchr_no
		SET 	@vchrlno = 1 
	WHILE (@@fetch_status = 0)
	BEGIN
		EXEC @seq_detl =  dbo.xx_hdr_nextval_sp  a,1
		IF @seq_detl = NULL 
			GOTO ErrorProcessing	
	-- for each record in cursor add voucher detail record
		INSERT INTO imaps.deltek.aoputlap_inp_detl
			(rec_no,  
			s_status_cd, -- Added by Veera on 03/29/2006 - Defect : DEV00000644
			vchr_no, fy_cd, 
			vchr_ln_no, acct_id, org_id, 
			proj_id, ref1_id, ref2_id, 
			cst_amt, taxable_fl, s_taxable_cd,
			sales_tax_amt, disc_amt, use_tax_amt, 
			ap_1099_fl, s_ap_1099_type_cd, vchr_ln_desc, 
			org_abbrv_cd, proj_abbrv_cd, proj_acct_abbrv_cd, 
			notes, time_stamp)
		VALUES  (
			@seq_detl, 
			@vs_status_cd, -- Added by Veera on 03/29/2006 - Defect : DEV00000644
			@vvchr_no, @vfy_cd,
			@vchrlno, 
			@vacct_id, @vorg_id, -- @vorg_id Added by Veera on 11/07/2005 - Defect : DEV00000243
			NULL, NULL, NULL,
			@vamount, 'N',  '',  -- CST_AMT, TAXABLE_FL, S_TAXABLE_CD,
			0, 0, 0, 
			'N', NULL, @vvchrln_desc, 
			'', @vproj_abbr_cd, NULL,
			@vnotes, GETDATE())

		SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   		   BEGIN
			SET @error_type = 2 
		      GOTO ErrorProcessing
   		   END		
--		PRINT 'Number of Records inserted ' + CAST(@numberofrecords AS VARCHAR)
	FETCH NEXT FROM  aop_detl_c INTO @vvchr_no,@vfy_cd,@vacct_id,@vorg_id,@vamount,@vvchrln_desc,@vproj_abbr_cd,@vnotes

	--The Voucher Line Number is generated if more than one line exists for the voucher
		IF 	@vvchr_no <> @lastvchrno
			BEGIN
				SET @lastvchrno = @vvchr_no 
				SET @vchrlno = 1	
			END
		ELSE
			BEGIN 
				SET @vchrlno = @vchrlno +1 
			END

	END /* While continues to insert the detail records for all vouchers */

	CLOSE aop_detl_c 
	DEALLOCATE aop_detl_c 

RETURN 0
	
ErrorProcessing:

		CLOSE aop_detl_c
		DEALLOCATE aop_detl_c
		CLOSE ap_hdr
		DEALLOCATE ap_hdr
	
		IF @error_type = 1
   			BEGIN
      				SET @error_code = 204 -- Attempt to insert a record into table AOPUTLAP_INP_HDR failed.
      				SET @error_msg_placeholder1 = 'insert'
      				SET @error_msg_placeholder2 = 'a record into table AOPUTLAP_INP_HDR'
   			END
		ELSE IF @error_type = 2
   			BEGIN
      				SET @error_code = 204 -- Attempt to insert a record into table AOPUTLAP_INP_DETL failed.
      				SET @error_msg_placeholder1 = 'insert'
      				SET @error_msg_placeholder2 = 'a record into table AOPUTLAP_INP_DETL'
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

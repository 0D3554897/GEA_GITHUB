use imapsstg
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_FIWLR_STG_BAL_SP    Script Date: 02/20/2007 3:15:53 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_STG_BAL_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_STG_BAL_SP]
GO


CREATE PROCEDURE [dbo].[XX_FIWLR_STG_BAL_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_STG_BAL_SP							*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR AP staging Procedure					*/
/* Date			: October 15, 2005						        */
/* Notes		: IMAPS FIW-LR AP insert balancing transaction for each voucher by major*/
/* Prerequisites	: XX_FIWLR_USDET_V3, XX_AOPUTLAP_INP_DETLV, DELTEK.ACCT, DELTEK.ORG_ACCT*/
/*			  and DELTEK.GENL_UDEF Table(s) should be created.			*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: XX_AOPUTLAP_INP_DETLV							*/
/* Version		: 1.2									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 11-06-2005   Veera Veeramachanane   	Created Initial Version	Defect : DEV00000243		*/
/* 11-23-2005	Veera Veeramachanane   	Modified Code based on the new requirement to post 	*/
/*					transactions to Fiscal Year, Period and Sub Period	*/
/*					based on the FIWLR Run Date Calendar provided. 		*/
/*					Ref: Requirement FIWLR33 (Req Pro)			*/
/* 11-28-2005	Veera Veeramachanane   	Modified code based on the line and notes field values	*/
/*					Defect: DEV0000296 					*/
/*  2-13-2006	Clare Robbins		Balancing transaction for N16 should go to single acct set in parameter table. */
/*					Defect DEV00000479  */
/* 03-29-2006   Clare Robbins		Set s_status_cd in AP Preprocessor tables to 'U' for new Deltek patch  */
/* 04-11-2006   Clare Robbins		Provide project abbrev and set org to null for N16 balancing transactions.  */
/* 05/15/2008   HVT                     Ref CP600000322. Multi-company fix (1 instance).        */
/*
	Date		Modified By		Description of change	
   ----------   -------------	------------------------ 
   2010-09-13	KM				1M changes

*/
/************************************************************************************************/



DECLARE @vvchr_no 		VARCHAR(30),
	@spreturncode 		INT,
	@vchrlno 		INT,
	@numberofrecords 	INT,
	@error_type		INT,
	@error_code		INT,
	@error_msg_placeholder1	SYSNAME,
	@error_msg_placeholder2 SYSNAME,
	@sp_name		SYSNAME,
	@source_group		VARCHAR(3),
	@fy_cd 			VARCHAR(6), 
--	@pd_no 			NUMERIC(2), 
--	@sub_pd_no 		NUMERIC(2), 
	@pd_no 			SMALLINT, 
	@sub_pd_no 		SMALLINT,
	@vrec_no		INT,
	@vnotes			VARCHAR(254),
	@vacct_var		VARCHAR(30),
	@vvchr_ln_desc		VARCHAR(30),
	@vacct_id		VARCHAR(20),
	@vorg_id		VARCHAR(20),
	@vamount		DECIMAL(15,2),
	@vbalamount		DECIMAL(15,2),
	@int_name		VARCHAR(20), --Added by Clare Robbins on 2/13/06
	@param_name		VARCHAR(20), --Added by Clare Robbins on 2/13/06
	@sourcewwern16	VARCHAR(3),    --Added by Clare Robbins on 2/13/06
	@s_status_cd		VARCHAR(1)	--added by Clare Robbins on 3/29/06

BEGIN

	SELECT	@sp_name = 'XX_FIWLR_STG_BAL_SP',
		@error_msg_placeholder1	= NULL,
		@error_msg_placeholder2 = NULL,
--		@fy_cd = DATEPART(YEAR, GETDATE()) , 
--		@pd_no = DATEPART(MONTH, GETDATE()),
--		@sub_pd_no = 1,
		@vacct_var = 'ACCT',
--		@lastvchno = NULL,
		@source_group = 'AP',
		@vnotes = 'Balancing Transaction',
		@vchrlno = 1,
		@int_name = 'FIWLR' , --Added by Clare Robbins on 2/13/06
		@param_name = 'N16_CR_ACCT_ID', --Added by Clare Robbins on 2/13/06
		@sourcewwern16 = 'N16', --Added by Clare Robbins on 2/13/06
		@s_status_cd = 'U'  --added by Clare Robbins on 3/29/06

-- CP600000322_Begin
DECLARE @DIV_16_COMPANY_ID varchar(10)

SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'FIWLR'
-- CP600000322_End

/* 	Start Veera -- Added the code based on the enhancement to post transactions to Fiscal Year, Period and 
	Sub Period based on the FIW-LR Run Dates calendar provided by IMAPS user community (Sean)
	Ref: Requirement FIWLR33 in Req Pro */

	SELECT	@fy_cd 		= fiscal_year, 
		@pd_no 		= CAST(period as SMALLINT), 
		@sub_pd_no	= CAST(sub_pd_no as SMALLINT)
	FROM	dbo.xx_fiwlr_rundate_acctcal
	WHERE 	CONVERT(VARCHAR(10),GETDATE(),120) BETWEEN run_start_date AND run_end_date
/* 	End Ref: Requirement FIWLR33 in Req Pro */


--not being used anymore, because in XX_FIWLR_STG_SP, we temporarily place division in ref1_id (and the balancing org is division)
	DECLARE @BALANCING_ORG_ID varchar(30)
	SELECT 	@BALANCING_ORG_ID = PARAMETER_VALUE
	FROM 	XX_PROCESSING_PARAMETERS
	WHERE 	INTERFACE_NAME_CD = 'FIWLR'
	AND 	PARAMETER_NAME = 'BALANCING_ORG_ID'

-- Cursor to insert balancing records to AP Preprocessor staging table
	DECLARE	aop_inp_ap_bal_c CURSOR FOR
			
		SELECT	v.rec_no,
			v.vchr_ln_desc,
			u.genl_id, 

			--@BALANCING_ORG_ID,
			v.ref1_id,  --temporarily place division in ref1_id (balancing org is division)

			v.vchr_no,
--			u.udef_txt, 
			sum(v.cst_amt),
			SUM(v.cst_amt)*-1
		FROM	dbo.xx_aoputlap_inp_detlv v,
			IMAPS.Deltek.GENL_UDEF u
		WHERE 	u.s_table_id = @vacct_var
		AND	u.udef_lbl_key = 32
-- CP600000322_Begin
		AND	u.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000322_End
--	Start modified by Veera on 11/28/2005 based on the new line and notes field changes Defect: DEV0000296
		AND	u.udef_txt = SUBSTRING(vchr_ln_desc, len(@in_status_record_num) + 6, 3) 
--		AND	u.udef_txt = SUBSTRING(v.notes,1,3) 
		AND	SUBSTRING(v.vchr_ln_desc,1,LEN(@in_status_record_num)) = CAST(@in_status_record_num as CHAR)
--	End modified by Veera on 11/28/2005 based on the new line and notes field changes Defect: DEV0000296
		AND 	SUBSTRING(v.vchr_ln_desc, len(@in_status_record_num) + 2, 3) <> @sourcewwern16 --added by CR 4/11/06.  exclude N16.  create N16 balancing transactions separately.
		GROUP 	BY v.rec_no,
			v.vchr_ln_desc,
			v.vchr_no,
			v.ref1_id,
			u.genl_id 
--			,u.udef_txt
		ORDER 	BY v.vchr_no


	OPEN aop_inp_ap_bal_c
	FETCH NEXT FROM aop_inp_ap_bal_c INTO @vrec_no, @vvchr_ln_desc, @vacct_id, @vorg_id, @vvchr_no, @vamount, @vbalamount

-- Initiate je line no for the voucher

		WHILE (@@fetch_status = 0)
		BEGIN
			IF @vamount <> 0 

-- for each record in cursor add je line record
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
			VALUES
				(@vrec_no, 
				@s_status_cd, --added by Clare Robbins on 3/29/06
				@vvchr_no, @fy_cd,
				@vchrlno, @vacct_id, @vorg_id,
				NULL, NULL, NULL,
				@vbalamount, 'N',  NULL,  -- CST_AMT, TAXABLE_FL, S_TAXABLE_CD,
				0, 0, 0, 
				'N', NULL, @vvchr_ln_desc, 
	 			--a.org_id, 
				NULL,
				NULL, NULL,
				@vnotes, 
				GETDATE())
	
			SELECT @out_systemerror = @@ERROR
			IF @out_systemerror <> 0 
  	 		   BEGIN
				SET @error_type = 1 
			      	GOTO ErrorProcessing
  	 		   END		
	
	
	FETCH NEXT FROM aop_inp_ap_bal_c INTO @vrec_no, @vvchr_ln_desc, @vacct_id, @vorg_id, @vvchr_no, @vamount, @vbalamount


	END
	CLOSE aop_inp_ap_bal_c
	DEALLOCATE aop_inp_ap_bal_c



	update xx_aoputlap_inp_detlv
	set ref1_id=null  --temporarily place division in ref1_id (balancing org is division)

	
	/*Added by Clare Robbins on 2/13/06 -  Update N16 balancing transactions with correct account */
	/*UPDATE d
	SET d.acct_id = p.parameter_value 
	FROM  dbo.xx_aoputlap_inp_detlv d, dbo.xx_processing_parameters p
	WHERE d.notes = @vnotes
	AND SUBSTRING(d.vchr_ln_desc, len(@in_status_record_num) + 2, 3)= @sourcewwern16
	AND p.interface_name_cd = @int_name
	AND p.parameter_name = @param_name */

	SELECT @vacct_id = parameter_value
	FROM dbo.xx_processing_parameters
	WHERE interface_name_cd = @int_name
	AND parameter_name = @param_name

	INSERT INTO dbo.xx_aoputlap_inp_detlv
	SELECT rec_no, @s_status_cd, vchr_no, @fy_cd,
		@vchrlno, @vacct_id, NULL, 
		NULL, NULL, NULL,	
		SUM(cst_amt)*-1, 'N', NULL,		
		0,0,0,
		'N', NULL, vchr_ln_desc,
		NULL,
		proj_abbrv_cd, NULL,
		@vnotes, GETDATE()
		FROM	dbo.xx_aoputlap_inp_detlv
		WHERE SUBSTRING(vchr_ln_desc,1,LEN(@in_status_record_num)) = CAST(@in_status_record_num as CHAR)
		AND 	SUBSTRING(vchr_ln_desc, len(@in_status_record_num) + 2, 3) = @sourcewwern16 
		GROUP BY rec_no,
			vchr_ln_desc,
			vchr_no,
			proj_abbrv_cd
		ORDER BY vchr_no

	SELECT @out_systemerror = @@ERROR
	IF @out_systemerror <> 0  
		BEGIN
			SET @error_type = 2 
		      	GOTO ErrorProcessing
  	 	END	
	/* End added by Clare 2/13/06*/	

RETURN 0
	ErrorProcessing:
		
		CLOSE aop_inp_ap_bal_c
		DEALLOCATE aop_inp_ap_bal_c

			IF @error_type = 1 
				BEGIN
		      			SET @error_code = 204 -- Attempt to insert a record into table XX_AOPUTLAP_INP_DETLV failed.
			      		SET @error_msg_placeholder1 = 'insert'
			      		SET @error_msg_placeholder2 = 'a balancing record into table XX_AOPUTLAP_INP_DETLV'
			   	END

			IF @error_type = 2  --Added by Clare Robbins 2/13/06
		   		BEGIN
		      			SET @error_code = 204 -- Attempt to insert a record into table XX_AOPUTLAP_INP_DETLV failed.
	      				SET @error_msg_placeholder1 = 'insert '
	      				SET @error_msg_placeholder2 = 'an N16 balancing record into table XX_AOPUTLAP_INP_DETLV'
	   			END
			

			EXEC dbo.xx_error_msg_detail
			   @in_error_code           = @error_code,
			   @in_display_requested    = 1,
			   @in_SQLServer_error_code = @out_SystemError,
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


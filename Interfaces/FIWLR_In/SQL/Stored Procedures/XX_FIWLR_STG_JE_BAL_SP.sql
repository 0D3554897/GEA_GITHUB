use imapsstg

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_FIWLR_STG_JE_BAL_SP    Script Date: 03/15/2007 5:43:41 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_STG_JE_BAL_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_STG_JE_BAL_SP]
GO





CREATE PROCEDURE [dbo].[XX_FIWLR_STG_JE_BAL_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_STG_JE_BAL_SP						*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR IMAPS Journal Entry Procedure				*/
/* Date			: October 15, 2005						        */
/* Notes		: IMAPS FIW-LR IMAPS Journal Entry program will group the JE data 	*/
/*			  and insert into JE Preprocessor tables. 				*/
/* Prerequisites	: XX_FIWLR_USDET_V3 and DELETEK.AOPUTLJE_INP_TR Table(s) should be 	*/
/*			  created.								*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: DELTEK.AOPUTLJe_INP_TR 			 			*/
/* Version		: 1.1									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 10-20-2005   Veera Veeramachanane   	Created Initial Version	Defect : DEV00000243		*/
/* 11-23-2005	Veera Veeramachanane   	Modified Code based on the new requirement to post 	*/
/*					transactions to Fiscal Year, Period and Sub Period	*/
/*					based on the FIWLR Run Date Calendar provided. 		*/
/*					Ref: Requirement FIWLR33 (Req Pro)			*/
/* 11-28-2005	Veera Veeramachanane   	Modified code based on the line and notes field values	*/
/*					Defect: DEV0000296 					*/
/* 04-25-2006   Clare Robbins		defect DEV00000813 - convert int to char for comparison */
/* 05/15/2008   HVT                     Ref CP600000322. Multi-company fix (1 instance).        */
/*
	Date		Modified By		Description of change	
   ----------   -------------	------------------------ 
   2010-09-13	KM				1M changes

*/
/************************************************************************************************/

DECLARE @SpReturnCode 		INT,
	@fy_cd			VARCHAR(6),
--	@pd_no 			NUMERIC(2), 
--	@sub_pd_no 		NUMERIC(2), 
	@pd_no 			SMALLINT, 
	@sub_pd_no 		SMALLINT,
	@error_type		INT,
	@error_code		INT,
	@error_msg_placeholder1	SYSNAME,
	@error_msg_placeholder2 SYSNAME,
	@sp_name		SYSNAME,
	@seq			INT,
	@lastvchno		VARCHAR(30),
	@vvchr_no		VARCHAR(30),
	@vouch_no		VARCHAR(30),
	@vmajor_hdr		VARCHAR(3),
	@vmajor			VARCHAR(3),
	@vsource		VARCHAR(3),
	@vnotes			VARCHAR(254),
	@vvchrln_desc		VARCHAR(30),
	@source_group		VARCHAR(3),
	@sjnlcd			VARCHAR(10),
	@vje_no 		INT,
	@vjelno 		INT ,
	@vje_desc		VARCHAR(30),
	@vje_trn_desc		VARCHAR(30),
	@vacct_var		VARCHAR(30),
	@vacct_id		VARCHAR(20),
	@vorg_id		VARCHAR(20),
	@vamount		DECIMAL(15,2),
	@vbalamount		DECIMAL(15,2)

BEGIN

	SELECT	@sp_name = 'XX_FIWLR_STG_JE_BAL_SP',
		@error_msg_placeholder1	= NULL,
		@error_msg_placeholder2 = NULL,
/*	Start Commented out by Veera on 11/23/2005 Ref: Requirement FIWLR33
--		@fy_cd = DATEPART(YEAR, GETDATE()) , 
--		@pd_no = DATEPART(MONTH, GETDATE()),
--		@sub_pd_no = 1,
	End Commented out by Veera on 11/23/2005 Ref: Requirement FIWLR33 */
		@vacct_var = 'ACCT',
		@lastvchno = NULL,
		@source_group = 'JE',
		@sjnlcd = 'AJE',
		@vnotes = 'Balancing Transaction'

-- CP600000322_Begin
DECLARE @DIV_16_COMPANY_ID varchar(10)

SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'FIWLR'
-- CP600000322_End

-- Cursor to insert records to JE Preprocessor Transaction table from staging table XX_FIWLR_USDET_V3
	DECLARE @BALANCING_ORG_ID varchar(30)
	SELECT 	@BALANCING_ORG_ID = PARAMETER_VALUE
	FROM 	XX_PROCESSING_PARAMETERS
	WHERE 	INTERFACE_NAME_CD = 'FIWLR'
	AND 	PARAMETER_NAME = 'BALANCING_ORG_ID'
	

	DECLARE	aop_inp_je_tr_c CURSOR FOR
			
		SELECT	v.je_desc,
			v.je_trn_desc,
			u.genl_id, 

			--@BALANCING_ORG_ID,
			v.ref_struc_1_id,  --temporarily place division in ref_struc_1_id (balancing org is division)

			v.inp_je_no, 
-- 	Start Added by Veera on 11/23/2005 FIWLR33
			v.fy_cd,
			v.pd_no,
			v.sub_pd_no,
-- 	End Added by Veera on 11/23/2005 FIWLR33
			MAX(v.je_ln_no)+1,
			SUM(v.trn_amt),
			SUM(v.trn_amt)*-1
		FROM	imaps.deltek.aoputlje_inp_tr v,
			IMAPS.Deltek.GENL_UDEF u
		WHERE 	u.s_table_id = @vacct_var
		AND	u.udef_lbl_key = 32
-- CP600000322_Begin
		AND	u.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000322_End
--	Modification Start by Veera on 11/22/2005 Defect : DEV0000296  
		AND	u.udef_txt = SUBSTRING(je_desc,3,3) 
--		AND	u.udef_txt = SUBSTRING(je_desc,1,3) 
--	Modification End by Veera on 11/22/2005 Defect :  DEV0000296
		AND	SUBSTRING(v.je_trn_desc, 1, LEN(@in_status_record_num)) = CAST(@in_status_record_num AS VARCHAR(20)) -- modified by CR 2/25/06 
		GROUP BY v.je_desc,
			v.je_trn_desc,
			u.genl_id, 
			v.inp_je_no,
-- 	Start Added by Veera on 11/23/2005 FIWLR33
			v.fy_cd,
			v.pd_no,
			v.sub_pd_no,
			v. ref_struc_1_id --temporarily place division in ref1_id (balancing org is division
-- 	End Added by Veera on 11/23/2005 FIWLR33
		ORDER 	BY inp_je_no


	OPEN aop_inp_je_tr_c
	FETCH NEXT FROM aop_inp_je_tr_c INTO @vje_desc, @vje_trn_desc, @vacct_id, @vorg_id, @vje_no, @fy_cd, @pd_no, @sub_pd_no, @vjelno, @vamount, @vbalamount
--	FETCH NEXT FROM aop_inp_je_tr_c INTO @vje_desc, @vje_trn_desc, @vacct_id, @vorg_id, @vje_no,  @vjelno, @vamount, @vbalamount

-- Initiate je line no for the voucher

		WHILE (@@fetch_status = 0)
		BEGIN
			EXEC @seq =  dbo.xx_je_nextval_sp  a,1
			IF   @seq = NULL 
				GOTO ErrorProcessing	

			IF @vamount <> 0 


-- for each record in cursor add je balancing line record
			INSERT INTO imaps.deltek.aoputlje_inp_tr ( 
				rec_no,
				s_status_cd,je_ln_no,inp_je_no,s_jnl_cd,
				fy_cd,pd_no,
				sub_pd_no,rvrs_fl,je_desc,trn_amt,
				acct_id,org_id,
				je_trn_desc,
				proj_id,ref_struc_1_id,ref_struc_2_id,cycle_dc,org_abbrv_cd,
				proj_abbrv_cd,proj_acct_abbrv_cd,update_obd_fl,
				notes,
				time_stamp)
			VALUES	(
				@seq,
				NULL,@vjelno,@vje_no,@sjnlcd,
				@fy_cd, @pd_no, 
				@sub_pd_no,'N',@vje_desc,@vbalamount,
				@vacct_id,@vorg_id,
				@vje_trn_desc,
				NULL,NULL,NULL,NULL,NULL,
				NULL,NULL,'Y',
				@vnotes,
				GETDATE())		
		
			SELECT @out_systemerror = @@ERROR
			IF @out_systemerror <> 0 
  	 		   BEGIN
				SET @error_type = 1 
			      	GOTO ErrorProcessing
  	 		   END		

	FETCH NEXT FROM aop_inp_je_tr_c INTO @vje_desc, @vje_trn_desc, @vacct_id, @vorg_id, @vje_no, @fy_cd, @pd_no, @sub_pd_no, @vjelno, @vamount, @vbalamount	
--	FETCH NEXT FROM aop_inp_je_tr_c INTO @vje_desc, @vje_trn_desc, @vacct_id, @vorg_id, @vje_no,  @vjelno, @vamount, @vbalamount


	END
	CLOSE aop_inp_je_tr_c
	DEALLOCATE aop_inp_je_tr_c



	update imaps.deltek.aoputlje_inp_tr
	set ref_struc_1_id=null  --temporarily place division in ref_struc_1_id (balancing org is division)



RETURN 0
	ErrorProcessing:
		CLOSE aop_inp_je_tr_c
		DEALLOCATE aop_inp_je_tr_c

			IF @error_type = 1
		   		BEGIN
		      			SET @error_code = 204 -- Attempt to insert a record into table XX_AOPUTLJE_INP_TRV failed.
		      			SET @error_msg_placeholder1 = 'insert'
		      			SET @error_msg_placeholder2 = 'a record into table XX_AOPUTLJE_INP_TRV'
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


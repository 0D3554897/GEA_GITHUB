use imapsstg

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_FIWLR_PREPROCESSOR_JE_SP    Script Date: 03/14/2007 4:38:03 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_PREPROCESSOR_JE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_PREPROCESSOR_JE_SP]
GO


CREATE PROCEDURE [dbo].[XX_FIWLR_PREPROCESSOR_JE_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_PREPROCESSOR_JE_SP						*/
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
/* Tables Updated	: DELTEK.AOPUTLJE_INP_TR 			 			*/
/* Version		: 1.2									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 10-20-2005   Veera Veeramachanane   	Created Initial Version					*/
/* 11-07-2005   Veera Veeramachanane   	Modified Code to create JE NO grouping by Major,Voucher	*/
/*					Defect : DEV00000243					*/
/* 11-22-2005   Veera Veeramachanane   	Modified Code to create JE NO grouping by Major,Source,	*/
/*					Voucher	Defect : DEV00000269				*/
/* 11-23-2005	Veera Veeramachanane   	Modified Code based on the new requirement to post 	*/
/*					transactions to Fiscal Year, Period and Sub Period	*/
/*					based on the FIWLR Run Date Calendar provided. 		*/
/*					Ref: Requirement FIWLR33 (Req Pro)			*/
/* 11-28-2005	Veera Veeramachanane   	Modified Code to add and change the column sequence 	*/
/*					populated in JE Header Desc, JE Line desc and Notes 	*/
/*					field values based on the miscode process walkthrough 	*/
/*					meeting. Also populated value 'F' to determine FIW-LR	*/
/*					in JE Header Description. Defect : DEV00000296		*/
/* 2/2/2006	Clare Robbins		Add org ID to insert stmt to accomodate payroll transactions */
/*					(source 060) per DEV00000493				*/
/* 5/15/2006	Keith McGuire		Code added to limit max number of je lines to 1499	*/
/* 8/14/2006 	Keith McGuire		DEV00001097 Modified code to facilitate FIWLR miscode process */
/* 3/14/2007 	Keith McGuire		CHANGE FOR GROUPING OF BILLABLE JOURNAL ENTRIES		*/
/*
	Date		Modified By		Description of change	
   ----------   -------------	------------------------ 
   2010-09-13	KM				1M changes

*/
/************************************************************************************************/

DECLARE 

	@SpReturnCode 		INT,
	@NumberOfRecords 	INT,
	@fiwlr_in_record_num 	INT,
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
	@vamount		DECIMAL(15,2),
	@vacct_id		VARCHAR(20),
	@vmajor_hdr		VARCHAR(3),
	@vsrc_hdr		VARCHAR(3), -- Added by Veera on 11/22/2005 Defect: DEV00000269
	@vmajor			VARCHAR(3),
	@vsource		VARCHAR(3),
	@vdiv		VARCHAR(2),
	@vproj_abbr_cd		VARCHAR(10),
	@vnotes			VARCHAR(254),
	@vvchrln_desc		VARCHAR(30),
	@source_group		VARCHAR(3),
	@sjnlcd			VARCHAR(10),
	@jeno 			INT,
	@jelno 			INT ,
	@vchr_maj		VARCHAR(30),
	@org_id		VARCHAR(20)	--Added by Clare Robbins on 2/2/2006 DEV00000493

BEGIN

	SELECT	@sp_name = 'XX_FIWLR_PREPROCESSOR_JE_SP',
		@error_msg_placeholder1	= NULL,
		@error_msg_placeholder2 = NULL,
/*	Start Commented out by Veera on 11/23/2005 Ref: Requirement FIWLR33
--		@fy_cd = DATEPART(YEAR, GETDATE()) , 
--		@pd_no = DATEPART(MONTH, GETDATE()),
--		@sub_pd_no = 1,
	End Commented out by Veera on 11/23/2005 Ref: Requirement FIWLR33 */
		@lastvchno = NULL,
		@source_group = 'JE',
		@sjnlcd = 'AJE',
		@jeno = 1,
		@jelno = 0 

/* 	Start Veera -- Added the code based on the enhancement to post transactions to Fiscal Year, Period and 
	Sub Period based on the FIW-LR Run Dates calendar provided by IMAPS user community (Sean)
	Ref: Requirement FIWLR33 in Req Pro */

	SELECT	@fy_cd 		= fiscal_year, 
		@pd_no 		= CAST(period as SMALLINT), 
		@sub_pd_no	= CAST(sub_pd_no as SMALLINT)
	FROM	dbo.xx_fiwlr_rundate_acctcal
	WHERE 	CONVERT(VARCHAR(10),GETDATE(),120) BETWEEN run_start_date AND run_end_date
/*
SELECT		@fy_cd = DATEPART(YEAR, GETDATE()) , 
		@pd_no = 6,
		@sub_pd_no = 2

*/
/* 	End Ref: Requirement FIWLR33 in Req Pro */

-- Cursor to insert records to JE Preprocessor Transaction table from staging table XX_FIWLR_USDET_V3
	DECLARE	aop_inp_je_tr_c CURSOR FOR
			
		SELECT	RTRIM(LTRIM(a.major)),
			RTRIM(LTRIM(a.source)), -- Added by Veera on 11/22/2005 Defect: 
			RTRIM(LTRIM(a.voucher_no)),
			RTRIM(LTRIM(a.division)) --KM 1M changes
		FROM	dbo.xx_fiwlr_usdet_v3 a
		WHERE	a.status_rec_no = @in_status_record_num
		AND	a.source_group = @source_group
--		AND	RTRIM(LTRIM(a.voucher_no)) in ('NM12IA', '0001571', '0000146','F3L0933','0000005','0000009','0000010', '0000012', '0000023')--'272001', 
--		AND	RTRIM(LTRIM(a.voucher_no)) in ('0002490','0001082', '0002492') --('NM12IA', '0001571','0000005') --,'0000009','0000010' ) --, '0000012', '0000023')--'272001', 
--		Added by Veera on 11/06/2005 to group JE NO by Major and Voucher Number Defect:
		GROUP BY RTRIM(LTRIM(a.major)),
			RTRIM(LTRIM(a.source)), -- Added by Veera on 11/22/2005 Defect: DEV00000269
			RTRIM(LTRIM(a.voucher_no)) ,
			RTRIM(LTRIM(a.division)) --KM 1M changes
		ORDER BY RTRIM(LTRIM(a.voucher_no))

	OPEN aop_inp_je_tr_c
	FETCH NEXT FROM aop_inp_je_tr_c INTO @vmajor_hdr,@vsrc_hdr,@vvchr_no, @vdiv --KM 1M changes -- Added by Veera on 11/22/2005 Defect: DEV00000269
--	FETCH NEXT FROM aop_inp_je_tr_c INTO @vmajor_hdr,@vvchr_no -- Commented out by Veera on 11/22/2005 Defect: 
--	FETCH NEXT FROM aop_inp_je_tr_c INTO @vvchr_no --@vmajor_hdr,@vvchr_no
	
	WHILE (@@fetch_status = 0)
	BEGIN
	
		DECLARE aop_jeln_c CURSOR FOR
	
		SELECT	RTRIM(LTRIM(a.voucher_no)),a.amount,
			RTRIM(LTRIM(a.acct_id)),
			a.org_id, --Added by Clare Robbins on 2/2/2006 for DEV00000493
			a.source,
--		Added by Veera on 11/06/2005 to group JE NO by Major and Voucher Number Defect: DEV0000296
			RTRIM(LTRIM(a.major)),
			a.proj_abbr_cd, 
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
			/*23*/+ ISNULL(RTRIM(LTRIM(a.wwer_exp_dt)), ' ') + ',')
			/*24*/+ CAST(a.ident_rec_no as varchar) + ','
		FROM	dbo.xx_fiwlr_usdet_v3 a
		WHERE	a.status_rec_no = @in_status_record_num
		AND	a.source_group = @source_group
		AND	RTRIM(LTRIM(a.voucher_no)) = @vvchr_no
--		Added by Veera on 11/06/2005 to group JE NO by Major and Voucher Number Defect:DEV00000269
		AND	RTRIM(LTRIM(a.major)) = @vmajor_hdr
		AND	RTRIM(LTRIM(a.source)) = @vsrc_hdr -- Added by Veera on 11/22/05 Defect: DEV00000269		AND RTRIM(LTRIM(a.division)) = @vdiv --KM 1M changes
--		GROUP BY RTRIM(LTRIM(a.major))

		OPEN aop_jeln_c
		FETCH NEXT FROM aop_jeln_c INTO @vouch_no,@vamount,@vacct_id,@org_id,@vsource,@vmajor,@vproj_abbr_cd,@vnotes--org_id added by CR 2/2/06

-- Initiate je line no for the voucher

		WHILE (@@fetch_status = 0)
		BEGIN
			EXEC @seq =  dbo.xx_je_nextval_sp  a,1
			IF   @seq = NULL 
				GOTO ErrorProcessing	

--		Added by Veera on 11/06/2005 to group JE NO by Major and Voucher Number Defect:

			--KM 1M changes
			SET @vchr_maj = RTRIM(LTRIM(@vmajor_hdr)) + RTRIM(LTRIM(@vsrc_hdr)) + RTRIM(LTRIM(@vvchr_no)) + RTRIM(LTRIM(@vdiv))-- Added by Veera on 11/22/2005 Defect: DEV00000269
--			SET @vchr_maj = RTRIM(LTRIM(@vmajor_hdr)) + RTRIM(LTRIM(@vvchr_no))	
--			PRINT 'MAJOR and Voucher ' + @vchr_maj

			--KM CHANGE 5/15/2006 IF CLAUSE MODIFICATION IS ONLY CHANGE
			IF 	(@vchr_maj <> @lastvchno) or @jelno >= 1498 -- Added by Veera on 11/06/2005 to group JE NO by Major and Voucher Number Defect:
--				@vvchr_no <> @lastvchno -- Commented out by Veera on 11/06/2005 to group JE NO by Major and Voucher Number Defect:
				BEGIN
	
				SET  	@lastvchno = @vchr_maj -- Added by Veera on 11/06/2005 to group JE NO by Major and Voucher Number Defect:
--				SET  	@lastvchno = @vvchr_no -- Commented out by Veera on 11/06/2005 to group JE NO by Major and Voucher Number Defect:
					SET 	@jelno = 1 
					SET 	@jeno = @jeno + 1
				END
			ELSE
				BEGIN
					SET 	@lastvchno = @vchr_maj -- Added by Veera on 11/06/2005 to group JE NO by Major and Voucher Number Defect:
--					SET 	@lastvchno = @vvchr_no -- Commented out by Veera on 11/06/2005 to group JE NO by Major and Voucher Number Defect:
					SET 	@jelno = @jelno + 1 
				END

	-- for each record in cursor add je line record
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
				NULL,@jelno,@jeno,@sjnlcd,
				@fy_cd, @pd_no, 
				@sub_pd_no,'N', 
				'F' + ',' + @vmajor + ',' + RTRIM(LTRIM(@vsource)) + ',' + @vouch_no,@vamount, 
				@vacct_id,--NULL, Commented by Clare Robbins on 2/2/06
				@org_id, --Added by Clare Robbins on 2/2/06 
				(RTRIM(LTRIM(CAST(@in_status_record_num AS CHAR))) + ',' + @vsource + ',' + @vmajor + ',' + @vouch_no ),
				
				--KM 1M changes
				--temporarily place division in ref_struc_1_id 
				NULL,@vdiv,NULL,NULL,NULL,

				@vproj_abbr_cd,NULL,'Y',
				@vnotes,GETDATE())		
		
			SELECT @out_systemerror = @@ERROR
			IF @out_systemerror <> 0 
  	 		   BEGIN
				SET @error_type = 2 
			      	GOTO ErrorProcessing
  	 		   END		
	
	
		FETCH NEXT FROM aop_jeln_c INTO @vouch_no,@vamount,@vacct_id,@org_id,@vsource,@vmajor,@vproj_abbr_cd,@vnotes--org_id added by CR 2/2/06
	
		END /* While continues to insert the je and line records*/

		CLOSE aop_jeln_c 
		DEALLOCATE aop_jeln_c 

--	Start Added by Veera on 11/22/2005 Defect: DEV00000269, DEV0000296
	FETCH NEXT FROM aop_inp_je_tr_c INTO @vmajor_hdr,@vsrc_hdr,@vvchr_no,@vdiv
--	FETCH NEXT FROM aop_inp_je_tr_c INTO @vmajor_hdr,@vvchr_no -- Added by Veera on 11/06/2005 to group JE NO by Major and Voucher Number Defect:
--	End Added by Veera on 11/22/2005 Defect: DEV00000269, DEV0000296
	END

	CLOSE aop_inp_je_tr_c
	DEALLOCATE aop_inp_je_tr_c
	

RETURN 0
	ErrorProcessing:
		CLOSE aop_jeln_c
		DEALLOCATE aop_jeln_c
		CLOSE aop_inp_je_tr_c
		DEALLOCATE aop_inp_je_tr_c

			IF @error_type = 1
		   		BEGIN
		      			SET @error_code = 204 -- Attempt to insert a record into table XX_AOPUTLJE_INP_TRV failed.
		      			SET @error_msg_placeholder1 = 'insert'
		      			SET @error_msg_placeholder2 = 'a record into table XX_AOPUTLJE_INP_TRV'
		   		END
			ELSE IF @error_type = 2
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


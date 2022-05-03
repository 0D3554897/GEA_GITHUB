USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_ARCHIVE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_R22_FIWLR_ARCHIVE_SP]
GO


CREATE PROCEDURE [dbo].[XX_R22_FIWLR_ARCHIVE_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS
BEGIN

-- archive errors
DECLARE 
	@resultofappreprocessorrun			VARCHAR(10),
	@latestrecordnuminarchive			INT,
	@doesinterfacestatusnumberpresent	TINYINT,
	@error_type							INT,
	@IMAPS_ERROR_NUMBER					INT,
	@error_msg_placeholder1				SYSNAME,
	@error_msg_placeholder2				SYSNAME,
	@sp_name							SYSNAME,
	@total_amt_inpstg_ap				DECIMAL(17,2),		
	@total_amt_inphdr_ap				DECIMAL(17,2),
	@total_amt_inphdr_err_ap			DECIMAL(17,2),
	@total_amt_inpstg_je				DECIMAL(17,2),
	@total_amt_inpjtr_je				DECIMAL(17,2),
	@total_amt_inpjtr_err_je			DECIMAL(17,2)


	SELECT	
		@sp_name				= 'XX_R22_FIWLR_ARCHIVE_SP',
		@error_msg_placeholder1	= NULL,
		@error_msg_placeholder2 = NULL,
		@total_amt_inpstg_ap	= 0,
		@total_amt_inphdr_ap	= 0,
		@total_amt_inphdr_err_ap= 0,
		@total_amt_inpstg_je	= 0,
		@total_amt_inpjtr_je	= 0,
		@total_amt_inpjtr_err_je= 0,
		@doesinterfacestatusnumberpresent = 0

/************************************************************************************************/
/* Procedure Name	: XX_R22_FIWLR_ARCHIVE_SP													*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   							*/
/* Description    	: IMAPS FIW-LR Archive Procedure											*/
/* Date				: August 10, 2008															*/
/* Notes			: IMAPS FIWLR_R22 Archive program will archive the extracted FIW-LR			*/
/*					  research data along with the data that failed the validation in AP and JE	*/
/*					  Preprocessor table(s).													*/
/* Prerequisites	: XX_R22_FIWLR_USDET_V3, DELETEK.AOPUTLAP_INP_HDR, DELTEK.AOPUTLAP_INP_DETL */
/*					  and DELTEK.AOPUTLJE_INP_TR Table(s) should exist.							*/
/* Parameter(s)		: 																			*/
/*	Input			: Status Record Number														*/
/*	Output			: Error Code and Error Description											*/
/* Tables Updated	: DELTEK.AOPUTLAP_INP_HDR, DELTEK.AOPUTLAP_INP_DETL and						*/
/*					  DELTEK.AOPUTLJE_INP_TR													*/
/* Version			: 1.0																		*/
/************************************************************************************************/
/* Date			Modified By		Description of change			  								*/
/* ----------   -------------  	   	------------------------    			  					*/
/* 08-10-2008   Veera Veeramachanane   	Created Initial Version									*/
/************************************************************************************************/

DECLARE @div22_company_id VARCHAR(10)

	SELECT	@div22_company_id = parameter_value
	FROM	dbo.xx_processing_parameters
	WHERE	parameter_name = 'COMPANY_ID'
	AND		interface_name_cd = 'FIWLR_R22'

-- AP Preprocessor Reconciliation data
	SELECT	@total_amt_inpstg_ap = ISNULL(SUM(amount),0)
	FROM	dbo.xx_r22_fiwlr_usdet_v3
	WHERE	source_group = 'AP'
	AND		status_rec_no = @in_status_record_num

	SELECT	@total_amt_inphdr_ap = ISNULL(sum(ln_chg_cst_amt), 0)
	from 	IMAR.DELTEK.vchr_ln
	WHERE	LEFT(vchr_ln_desc,LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num as varchar)+',') 
	AND		LEFT(notes, 3) <> 'Bal'

	SELECT	@total_amt_inphdr_err_ap = ISNULL(SUM(CST_AMT),0)
	FROM	IMAR.DELTEK.aoputlap_inp_detl
	WHERE	LEFT(vchr_ln_desc,LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num as varchar)+',')
	AND 	s_status_cd = 'E'
	AND 	LEFT(notes, 3) <> 'Bal'

	-- JE Preprocessor Reconciliation data
	SELECT	@total_amt_inpstg_je = ISNULL(SUM(amount),0)
	FROM	dbo.xx_r22_fiwlr_usdet_v3
	WHERE	source_group = 'JE'
	AND		status_rec_no = @in_status_record_num

	SELECT	@total_amt_inpjtr_je = 	ISNULL(sum(trn_amt), 0)
	from 	IMAR.DELTEK.je_trn
	WHERE	LEFT(je_trn_desc,LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num as varchar)+ ',') 
	AND		LEFT(NOTES, 3) <> 'Bal'

	SELECT	@total_amt_inpjtr_err_je = ISNULL(SUM(trn_amt),0)
	FROM	IMAR.DELTEK.aoputlje_inp_tr
	WHERE	LEFT(je_trn_desc,LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num as varchar)+ ',') 
	AND		LEFT(NOTES, 3) <> 'Bal'
	AND 	s_status_cd = 'E'
	

	UPDATE	dbo.XX_IMAPS_INT_STATUS
	SET		record_count_initial = @total_amt_inpstg_ap,
       		record_count_success = @total_amt_inphdr_ap,
       		record_count_error = @total_amt_inphdr_err_ap,
       		amount_input = @total_amt_inpstg_je,
       		amount_processed = @total_amt_inpjtr_je,
       		amount_failed = @total_amt_inpjtr_err_je,
       		modified_by = SUSER_SNAME(),
       		modified_date = GETDATE()
 	WHERE	status_record_num = @in_status_record_num

	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'RUN XX_R22_FIWLR_PREPROCESSOR_CLOSEOUT_SP'
	SET @error_msg_placeholder2 = ''
	

	DECLARE @ret_code int
	SET @ret_code = 1
	EXEC @ret_code = XX_R22_FIWLR_PREPROCESSOR_CLOSEOUT_SP @out_STATUS_DESCRIPTION

	SELECT @out_systemerror = @@ERROR 
	IF @out_systemerror <> 0 OR @ret_code <> 0 GOTO ErrorProcessing


	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'LOAD ARCHIVE FROM'
	SET @error_msg_placeholder2 = 'TEMP'
	
	INSERT INTO xx_r22_fiwlr_usdet_archive
	SELECT * FROM xx_r22_fiwlr_usdet_temp
	WHERE	status_rec_no = @in_status_record_num	

	SELECT @out_systemerror = @@ERROR
	IF @out_systemerror <> 0  GOTO ErrorProcessing


	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'LOAD MISCODES FROM'
	SET @error_msg_placeholder2 = 'TEMP'

	INSERT INTO xx_r22_fiwlr_usdet_miscodes
	SELECT * 
	FROM	xx_r22_fiwlr_usdet_temp
	WHERE	status_rec_no = @in_status_record_num
	AND		cp_hdr_no IS NULL

	SELECT @out_systemerror = @@ERROR
	IF @out_systemerror <> 0  GOTO ErrorProcessing





	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'RUN XX_R22_FIWLR_MISCODE_UPDATE_FEEDBACK_SP'
	SET @error_msg_placeholder2 = ''

	SET @ret_code = 1
	EXEC @ret_code = XX_R22_FIWLR_MISCODE_UPDATE_FEEDBACK_SP

	SELECT @out_systemerror = @@ERROR 
	IF @out_systemerror <> 0 OR @ret_code <> 0 GOTO ErrorProcessing
   		 
	--Update extract parameter
	UPDATE	xx_processing_parameters
	SET		parameter_value = 
				(	SELECT  MAX(ref_creation_date+ref_creation_time)
					FROM	xx_r22_fiwlr_usdet_archive )
	WHERE	interface_name_cd = 'FIWLR_R22'
	AND		parameter_name = 'EXTRACT_START_DATE'


RETURN 0

ErrorProcessing:

	PRINT @out_STATUS_DESCRIPTION

		EXEC dbo.xx_error_msg_detail
		   @in_error_code           = @IMAPS_ERROR_NUMBER,
		   @in_display_requested    = 1,
		   @in_sqlserver_error_code = @out_systemerror,
		   @in_placeholder_value1   = @error_msg_placeholder1,
		   @in_placeholder_value2   = @error_msg_placeholder2,
		   @in_calling_object_name  = @sp_name,
		   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

	PRINT @out_STATUS_DESCRIPTION

RETURN 1

END

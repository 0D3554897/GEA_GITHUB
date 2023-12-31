SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_ERROR_AP_IMPORT_SP    Script Date: 08/23/2006 11:30:56 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_ERROR_AP_IMPORT_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_ERROR_AP_IMPORT_SP]
GO









CREATE PROCEDURE [dbo].[XX_ERROR_AP_IMPORT_SP] 
(
@in_status_record_num sysname,
@in_error_sequence_no sysname,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)  
AS
BEGIN
	--PREPROCESSOR TABLES SHOULD ALWAYS BE TRUNCATED
	--BEFORE HAND

	DECLARE	@SP_NAME	sysname,
	@IMAPS_error_number     int,
	@SQLServer_error_code 	int,
	@error_msg_placeholder1 sysname,
	@error_msg_placeholder2 sysname


	--0 SET ACCOUNTING DATE
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'GRAB APPROPRIATE'
	SET @error_msg_placeholder2 = 'ACCOUNTING DATE'
	
	DECLARE @FY_CD int, 
		@PD_NO int, 
		@SUB_PD_NO int
		
	SELECT 	@FY_CD = fiscal_year,
		@PD_NO = period,
		@SUB_PD_NO = sub_pd_no
	FROM	dbo.XX_FIWLR_RUNDATE_ACCTCAL
	WHERE	cast(run_start_date as datetime) <= GETDATE()
	AND	cast(run_end_date as datetime) >= GETDATE()
	
	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

	IF @FY_CD IS NULL GOTO BL_ERROR_HANDLER
	IF @PD_NO IS NULL GOTO BL_ERROR_HANDLER
	IF @SUB_PD_NO IS NULL GOTO BL_ERROR_HANDLER

	
	SET @SP_NAME = 'XX_ERROR_AP_IMPORT_SP'

	--1	
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'INSERT INTO'
	SET @error_msg_placeholder2 = 'IMAPS.DELTEK.AOPUTLAP_INP_HDR'
	
	INSERT INTO IMAPS.DELTEK.AOPUTLAP_INP_HDR
	SELECT
	REC_NO, 'U', VCHR_NO, @FY_CD, @PD_NO, @SUB_PD_NO,
	VEND_ID, TERMS_DC, INVC_ID, INVC_DT, INVC_AMT, DISC_DT, DISC_PCT_RT,
	DISC_AMT, DUE_DT, HOLD_VCHR_FL, PAY_WHEN_PAID_FL, PAY_VEND_ID,
	PAY_ADDR_DC, PO_ID, PO_RLSE_NO, RTN_RATE, AP_ACCT_DESC, CASH_ACCT_DESC,
	S_INVC_TYPE, SHIP_AMT, CHK_FY_CD, CHK_PD_NO, CHK_SUB_PD_NO, CHK_NO,
	CHK_DT, CHK_AMT, DISC_TAKEN_AMT, INVC_POP_DT, PRINT_NOTE_FL, 
	JNT_PAY_VEND_NAME, NOTES, GETDATE(), SEP_CHK_FL
	FROM dbo.AOPUTLAP_INP_HDR_ERRORS
	WHERE STATUS_RECORD_NUM = @in_status_record_num
	AND   ERROR_SEQUENCE_NO = @in_error_sequence_no
	
	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

	
	--2
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'INSERT INTO'
	SET @error_msg_placeholder2 = 'IMAPS.DELTEK.AOPUTLAP_INP_DETL'
	
	INSERT INTO IMAPS.DELTEK.AOPUTLAP_INP_DETL
	SELECT
	REC_NO, 'U', VCHR_NO, @FY_CD, VCHR_LN_NO, ACCT_ID,
	ORG_ID, PROJ_ID, REF1_ID, REF2_ID, CST_AMT,
	TAXABLE_FL, S_TAXABLE_CD, SALES_TAX_AMT, DISC_AMT,
	USE_TAX_AMT, AP_1099_FL, S_AP_1099_TYPE_CD,
	VCHR_LN_DESC, ORG_ABBRV_CD, PROJ_ABBRV_CD, 
	PROJ_ACCT_ABBRV_CD, NOTES, TIME_STAMP
	FROM dbo.AOPUTLAP_INP_DETL_ERRORS
	WHERE 	STATUS_RECORD_NUM = @in_status_record_num
	AND	ERROR_SEQUENCE_NO = @in_error_sequence_no
	ORDER BY VCHR_NO, VCHR_LN_NO

	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER


	--3
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'UPDATE TABLE'
	SET @error_msg_placeholder2 = 'IMAPS.DELTEK.AOPUTLAP_INP_DETL'
	

	UPDATE 	IMAPS.DELTEK.AOPUTLAP_INP_DETL
	SET 	ACCT_ID = modified.ACCT_ID,
		ORG_ID 	= modified.ORG_ID,
		PROJ_ABBRV_CD = modified.PROJ_ABBRV_CD
	FROM	IMAPS.DELTEK.AOPUTLAP_INP_DETL orig
	INNER JOIN
		dbo.XX_ERROR_AP_TEMP modified
	ON
	(
		orig.REC_NO = modified.REC_NO
	AND	modified.STATUS_RECORD_NUM = @in_status_record_num
	AND	modified.ERROR_SEQUENCE_NO = @in_error_sequence_no
	)	

	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER



	--4 IN CASE OF PCLAIM
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'INSERT INTO'
	SET @error_msg_placeholder2 = 'IMAPS.DELTEK.AOPUTLAP_INP_LAB'
	
	INSERT INTO IMAPS.DELTEK.AOPUTLAP_INP_LAB
	SELECT
	REC_NO, 'U', VCHR_NO, @FY_CD, VCHR_LN_NO,
	SUB_LN_NO, VEND_EMPL_ID, GENL_LAB_CAT_CD, BILL_LAB_CAT_CD,
	VEND_HRS, VEND_AMT, EFFECT_BILL_DT, TIME_STAMP
	FROM dbo.AOPUTLAP_INP_LAB_ERRORS
	WHERE 	STATUS_RECORD_NUM = @in_status_record_num
	AND	ERROR_SEQUENCE_NO = @in_error_sequence_no
	ORDER BY VCHR_NO, VCHR_LN_NO

	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER




	RETURN(0)
	
	BL_ERROR_HANDLER:
	
	EXEC dbo.XX_ERROR_MSG_DETAIL
	   @in_error_code           = @IMAPS_error_number,
	   @in_display_requested    = 1,
	   @in_SQLServer_error_code = @SQLServer_error_code,
	   @in_placeholder_value1   = @error_msg_placeholder1,
	   @in_placeholder_value2   = @error_msg_placeholder2,
	   @in_calling_object_name  = @SP_NAME,
	   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
	
	RETURN(1)
END










GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


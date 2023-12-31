SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_ERROR_AP_PCLAIM_GRAB_SP    Script Date: 08/23/2006 11:31:11 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_ERROR_AP_PCLAIM_GRAB_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_ERROR_AP_PCLAIM_GRAB_SP]
GO















CREATE PROCEDURE [dbo].[XX_ERROR_AP_PCLAIM_GRAB_SP] 
(
@in_status_record_num sysname,
@in_error_sequence_no sysname,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)  
AS
BEGIN
	DECLARE	@SP_NAME	sysname,
	@IMAPS_error_number     int,
	@SQLServer_error_code 	int,
	@error_msg_placeholder1 sysname,
	@error_msg_placeholder2 sysname
	
	SET @SP_NAME = 'XX_ERROR_AP_PCLAIM_GRAB_SP'


	--DATA GRABS

	--1	
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'INSERT INTO'
	SET @error_msg_placeholder2 = 'dbo.AOPUTLAP_INP_HDR_ERRORS'
	
	INSERT INTO dbo.AOPUTLAP_INP_HDR_ERRORS
	SELECT @in_status_record_num, @in_error_sequence_no,
	REC_NO, S_STATUS_CD, VCHR_NO, FY_CD, PD_NO, SUB_PD_NO,
	VEND_ID, TERMS_DC, INVC_ID, INVC_DT, INVC_AMT, DISC_DT, DISC_PCT_RT,
	DISC_AMT, DUE_DT, HOLD_VCHR_FL, PAY_WHEN_PAID_FL, PAY_VEND_ID,
	PAY_ADDR_DC, PO_ID, PO_RLSE_NO, RTN_RATE, AP_ACCT_DESC, CASH_ACCT_DESC,
	S_INVC_TYPE, SHIP_AMT, CHK_FY_CD, CHK_PD_NO, CHK_SUB_PD_NO, CHK_NO,
	CHK_DT, CHK_AMT, DISC_TAKEN_AMT, INVC_POP_DT, PRINT_NOTE_FL, 
	JNT_PAY_VEND_NAME, NOTES, TIME_STAMP, SEP_CHK_FL
	FROM IMAPS.DELTEK.AOPUTLAP_INP_HDR
	WHERE S_STATUS_CD = 'E'
	AND LEFT(NOTES, LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num as varchar) + ' ')

	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER


	--1b
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'INSERT INTO'
	SET @error_msg_placeholder2 = 'dbo.AOPUTLAP_INP_LAB_ERRORS'
	
	INSERT INTO dbo.AOPUTLAP_INP_LAB_ERRORS
	SELECT @in_status_record_num, @in_error_sequence_no,
	REC_NO, S_STATUS_CD, VCHR_NO, FY_CD, VCHR_LN_NO,
	SUB_LN_NO, VEND_EMPL_ID, GENL_LAB_CAT_CD, BILL_LAB_CAT_CD,
	VEND_HRS, VEND_AMT, EFFECT_BILL_DT, TIME_STAMP
	FROM IMAPS.DELTEK.AOPUTLAP_INP_LAB --change KM
	WHERE S_STATUS_CD = 'E'
	
	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER




	--3 
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'INSERT INTO'
	SET @error_msg_placeholder2 = 'dbo.AOPUTLAP_INP_DETL_ERRORS'


	INSERT INTO dbo.AOPUTLAP_INP_DETL_ERRORS
	SELECT @in_status_record_num, @in_error_sequence_no, '',
	REC_NO, S_STATUS_CD, VCHR_NO, FY_CD, VCHR_LN_NO, ACCT_ID,
	ORG_ID, PROJ_ID, REF1_ID, REF2_ID, CST_AMT,
	TAXABLE_FL, S_TAXABLE_CD, SALES_TAX_AMT, DISC_AMT,
	USE_TAX_AMT, AP_1099_FL, S_AP_1099_TYPE_CD,
	VCHR_LN_DESC, ORG_ABBRV_CD, PROJ_ABBRV_CD, 
	PROJ_ACCT_ABBRV_CD, NOTES, TIME_STAMP
	FROM IMAPS.DELTEK.AOPUTLAP_INP_DETL
	WHERE 	S_STATUS_CD  = 'E'
	AND	left(vchr_ln_desc, 6) = 'PCLAIM'
	ORDER BY VCHR_NO, VCHR_LN_NO

	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER




	--5
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'UPDATE FEEDBACK COLUMN IN'
	SET @error_msg_placeholder2 = 'dbo.AOPUTLAP_INP_DETL_ERRORS'


	
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'UPDATE FEEDBACK COLUMN IN'
	SET @error_msg_placeholder2 = 'dbo.AOPUTLAP_INP_DETL_ERRORS'

		UPDATE dbo.AOPUTLAP_INP_DETL_ERRORS
	SET FEEDBACK = CAST(FEEDBACK + 'ACCT_ID invalid,' as varchar(254))
	FROM	dbo.AOPUTLAP_INP_DETL_ERRORS a
	WHERE 0 =
	(
	SELECT COUNT(1)
	FROM 	imaps.deltek.acct
	WHERE	ACCT_ID = a.ACCT_ID
	)

	UPDATE dbo.AOPUTLAP_INP_DETL_ERRORS
	SET FEEDBACK = CAST(FEEDBACK + 'ORG_ID and PROJ_ABBRV_CD invalid,' as varchar(254))
	FROM	dbo.AOPUTLAP_INP_DETL_ERRORS a
	WHERE 0 =
	(
	SELECT COUNT(1)
	FROM 	imaps.deltek.org
	WHERE	ORG_ID = a.ORG_ID
	)
	AND
	a.PROJ_ABBRV_CD IS NULL
	
	UPDATE dbo.AOPUTLAP_INP_DETL_ERRORS
	SET FEEDBACK = CAST(FEEDBACK + 'PROJ_ABBRV_CD invalid,' as varchar(254))
	FROM	dbo.AOPUTLAP_INP_DETL_ERRORS a
	WHERE 0 =
	(
	SELECT COUNT(1)
	FROM 	imaps.deltek.proj
	WHERE	PROJ_ABBRV_CD = a.PROJ_ABBRV_CD
	)
	AND a.PROJ_ABBRV_CD IS NOT NULL
	
	UPDATE dbo.AOPUTLAP_INP_DETL_ERRORS
	SET FEEDBACK = CAST(FEEDBACK + 'ACCT_ID invalid for PROJ_ABBRV_CD,' as varchar(254))
	FROM   dbo.AOPUTLAP_INP_DETL_ERRORS a
	WHERE 0 = 
	(
	SELECT 	COUNT(1)
	FROM	imaps.deltek.acct_grp_setup acct_grp 
	INNER JOIN 
		imaps.deltek.proj proj 
	ON 		(proj.acct_grp_cd = acct_grp.acct_grp_cd)
	WHERE 		acct_grp.acct_id = a.ACCT_ID
	AND		proj.proj_abbrv_cd = a.PROJ_ABBRV_CD
	)
	AND a.PROJ_ABBRV_CD IS NOT NULL
	AND a.ACCT_ID IS NOT NULL
	
	
	UPDATE dbo.AOPUTLAP_INP_DETL_ERRORS
	SET FEEDBACK = CAST(FEEDBACK + 'ACCT_ID invalid for ORG_ID,' as varchar(254))
	FROM	dbo.AOPUTLAP_INP_DETL_ERRORS a
	WHERE 0 =
	(
	SELECT 	COUNT(1)
	FROM		imaps.deltek.org_acct
	WHERE	 	acct_id = a.ACCT_ID
	AND		org_id = a.ORG_ID
	)
	AND a.ORG_ID IS NOT NULL
	AND a.ACCT_ID IS NOT NULL


	UPDATE dbo.AOPUTLAP_INP_DETL_ERRORS
	SET FEEDBACK = CAST(FEEDBACK + 'ACCT_ID invalid for OWNING ORG_ID,' as varchar(254))
	FROM	dbo.AOPUTLAP_INP_DETL_ERRORS a
	INNER JOIN
		imaps.deltek.PROJ b
	ON
	(
		a.proj_abbrv_cd = b.proj_abbrv_cd
	)
	WHERE 0 =
	(
	SELECT 	COUNT(1)
	FROM		imaps.deltek.org_acct
	WHERE	 	acct_id = a.ACCT_ID
	AND		org_id = b.ORG_ID
	)
	AND a.ORG_ID IS NULL
	AND a.PROJ_ABBRV_CD IS NOT NULL
	AND a.ACCT_ID IS NOT NULL

	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER






	--DELETIONS
	
	--2
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'DELETE FROM'
	SET @error_msg_placeholder2 = 'IMAPS.DELTEK.AOPUTLAP_INP_HDR'

	DELETE FROM IMAPS.DELTEK.AOPUTLAP_INP_HDR
	WHERE LEFT(NOTES, LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num as varchar) + ' ') 

	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER


	--2b
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'DELETE FROM'
	SET @error_msg_placeholder2 = 'IMAPS.DELTEK.AOPUTLAP_INP_LAB'

	DELETE FROM IMAPS.DELTEK.AOPUTLAP_INP_LAB
	
	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER


	--4
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'DELETE FROM'
	SET @error_msg_placeholder2 = 'IMAPS.DELTEK.AOPUTLAP_INP_DETL'
	

	DELETE IMAPS.DELTEK.AOPUTLAP_INP_DETL
	WHERE 	left(vchr_ln_desc, 6) = 'PCLAIM'

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


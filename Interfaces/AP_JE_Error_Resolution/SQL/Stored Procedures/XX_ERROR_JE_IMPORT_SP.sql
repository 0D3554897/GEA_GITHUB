SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_ERROR_JE_IMPORT_SP    Script Date: 08/23/2006 11:31:59 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_ERROR_JE_IMPORT_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_ERROR_JE_IMPORT_SP]
GO









CREATE PROCEDURE [dbo].[XX_ERROR_JE_IMPORT_SP] 
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
	
	SET @SP_NAME = 'XX_ERROR_JE_IMPORT_SP'

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


	--1	
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'INSERT INTO'
	SET @error_msg_placeholder2 = 'IMAPS.DELTEK.AOPUTLJE_INP_TR'
	
	INSERT INTO IMAPS.DELTEK.AOPUTLJE_INP_TR
	SELECT 
	REC_NO, NULL, JE_LN_NO, INP_JE_NO, S_JNL_CD, @FY_CD,
	@PD_NO, @SUB_PD_NO, RVRS_FL, JE_DESC, TRN_AMT, ACCT_ID,
	ORG_ID, JE_TRN_DESC, PROJ_ID, REF_STRUC_1_ID, REF_STRUC_2_ID,
	CYCLE_DC, ORG_ABBRV_CD, PROJ_ABBRV_CD, PROJ_ACCT_ABBRV_CD, 
	UPDATE_OBD_FL, NOTES, GETDATE()
	FROM 	dbo.AOPUTLJE_INP_TR_ERRORS
	WHERE 	STATUS_RECORD_NUM = @in_status_record_num
	AND 	ERROR_SEQUENCE_NO = @in_error_sequence_no
	ORDER BY INP_JE_NO, JE_LN_NO

	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER


	--2
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'UPDATE TABLE'
	SET @error_msg_placeholder2 = 'IMAPS.DELTEK.AOPUTLJE_INP_TR'
	

	UPDATE 	IMAPS.DELTEK.AOPUTLJE_INP_TR
	SET 	ACCT_ID = modified.ACCT_ID,
		ORG_ID 	= modified.ORG_ID,
		PROJ_ABBRV_CD = modified.PROJ_ABBRV_CD
	FROM	IMAPS.DELTEK.AOPUTLJE_INP_TR orig
	INNER JOIN
		dbo.XX_ERROR_JE_TEMP modified
	ON
	(
		orig.REC_NO = modified.REC_NO
	AND	modified.STATUS_RECORD_NUM = @in_status_record_num
	AND	modified.ERROR_SEQUENCE_NO = @in_error_sequence_no
	)	

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


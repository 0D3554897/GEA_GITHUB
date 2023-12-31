SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_ERROR_FIWLR_CLOSEOUT_SP    Script Date: 06/20/2006 3:30:11 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_ERROR_FIWLR_CLOSEOUT_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_ERROR_FIWLR_CLOSEOUT_SP]
GO






CREATE PROCEDURE [dbo].[XX_ERROR_FIWLR_CLOSEOUT_SP] 
(
@in_status_record_num sysname,
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
	
	SET @SP_NAME = 'XX_ERROR_FIWLR_CLOSEOUT_SP'
	

	DECLARE @in_error_sequence_no int,
		@ret_code int
	
	DECLARE @AP_TOTAL_COUNT INT,
		@AP_SUCCESS_COUNT INT,
		@AP_ERROR_COUNT INT,
		@AP_TOTAL_AMOUNT DECIMAL(14,2),
		@AP_SUCCESS_AMOUNT DECIMAL(14,2),
		@AP_ERROR_AMOUNT DECIMAL(14,2),
	
		@JE_TOTAL_COUNT INT,
		@JE_SUCCESS_COUNT INT,
		@JE_ERROR_COUNT INT,
		@JE_TOTAL_AMOUNT DECIMAL(14,2),
		@JE_SUCCESS_AMOUNT DECIMAL(14,2),
		@JE_ERROR_AMOUNT DECIMAL(14,2)
	
	set @in_error_sequence_no = 0

/*
	--1 GET TOTALS
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'SELECT AP & JE'
	SET @error_msg_placeholder2 = 'STATUS TOTALS'
	
	SELECT	@AP_TOTAL_AMOUNT = ISNULL(SUM(CST_AMT),0),
		@AP_TOTAL_COUNT = COUNT(1)
	FROM	IMAPS.DELTEK.AOPUTLAP_INP_DETL
	WHERE	LEFT(VCHR_LN_DESC, LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num AS VARCHAR)+',')
	AND	LEFT(NOTES, 3) <> 'BAL'
	
	SELECT	@AP_SUCCESS_AMOUNT = ISNULL(SUM(CST_AMT),0),
		@AP_SUCCESS_COUNT = COUNT(1)
	FROM	IMAPS.DELTEK.AOPUTLAP_INP_DETL
	WHERE	LEFT(VCHR_LN_DESC, LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num AS VARCHAR)+',')
	AND	LEFT(NOTES, 3) <> 'BAL'
	AND	S_STATUS_CD <> 'E'
	
	SELECT	@AP_ERROR_AMOUNT = ISNULL(SUM(CST_AMT),0),
		@AP_ERROR_COUNT = COUNT(1)
	FROM	IMAPS.DELTEK.AOPUTLAP_INP_DETL
	WHERE	LEFT(VCHR_LN_DESC, LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num AS VARCHAR)+',')
	AND	LEFT(NOTES, 3) <> 'BAL'
	AND	S_STATUS_CD = 'E'
	
	
	
	SELECT	@JE_TOTAL_AMOUNT = ISNULL(SUM(TRN_AMT),0),
		@JE_TOTAL_COUNT = COUNT(1)
	FROM	IMAPS.DELTEK.AOPUTLJE_INP_TR
	WHERE	LEFT(JE_TRN_DESC, LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num AS VARCHAR)+',')
	AND	LEFT(NOTES, 3) <> 'BAL'
	
	SELECT	@JE_SUCCESS_AMOUNT = ISNULL(SUM(TRN_AMT),0),
		@JE_SUCCESS_COUNT = COUNT(1)
	FROM	IMAPS.DELTEK.AOPUTLJE_INP_TR
	WHERE	LEFT(JE_TRN_DESC, LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num AS VARCHAR)+',')
	AND	LEFT(NOTES, 3) <> 'BAL'
	AND	S_STATUS_CD <> 'E'
	
	SELECT	@JE_ERROR_AMOUNT = ISNULL(SUM(TRN_AMT),0),
		@JE_ERROR_COUNT = COUNT(1)
	FROM	IMAPS.DELTEK.AOPUTLJE_INP_TR
	WHERE	LEFT(JE_TRN_DESC, LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num AS VARCHAR)+',')
	AND	LEFT(NOTES, 3) <> 'BAL'
	AND	S_STATUS_CD = 'E'	
	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER
*/
	

	
	--2 GRAB AP ERROR RECORDS
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'GRAB AP'
	SET @error_msg_placeholder2 = 'ERROR RECORDS'
	
	exec @ret_code = xx_error_ap_fiwlr_grab_sp
		@in_status_record_num = @in_status_record_num,
		@in_error_sequence_no = @in_error_sequence_no
	
	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER
	
	


	--4 GRAB JE ERROR RECORDS
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'GRAB JE'
	SET @error_msg_placeholder2 = 'ERROR RECORDS'
	
	exec xx_error_je_fiwlr_grab_sp
		@in_status_record_num = @in_status_record_num,
		@in_error_sequence_no = @in_error_sequence_no
	
	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER
	

	
	
	--5 LOAD AP ERROR TABLE
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'LOAD AP'
	SET @error_msg_placeholder2 = 'ERROR EXPORT TABLE'

	exec dbo.xx_error_ap_export_sp
		@in_status_record_num = @in_status_record_num,
		@in_error_sequence_no = @in_error_sequence_no

	
	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

	
	--5 LOAD JE ERROR TABLE
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'LOAD JE'
	SET @error_msg_placeholder2 = 'ERROR EXPORT TABLE'

	exec dbo.xx_error_je_export_sp
		@in_status_record_num = @in_status_record_num,
		@in_error_sequence_no = @in_error_sequence_no
	
	
	
	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

	--last step is to run the following DTS
	--ERROR_JE_EXPORT
	--ERROR_AP_EXPORT

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


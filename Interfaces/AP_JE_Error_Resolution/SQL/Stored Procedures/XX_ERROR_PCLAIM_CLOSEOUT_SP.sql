SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_ERROR_PCLAIM_CLOSEOUT_SP    Script Date: 06/20/2006 3:31:15 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_ERROR_PCLAIM_CLOSEOUT_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_ERROR_PCLAIM_CLOSEOUT_SP]
GO






CREATE PROCEDURE [dbo].[XX_ERROR_PCLAIM_CLOSEOUT_SP] 
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
	
	SET @SP_NAME = 'XX_ERROR_PCLAIM_CLOSEOUT_SP'
	

	DECLARE @in_error_sequence_no int,
		@ret_code int
	
	DECLARE @TOTAL_COUNT INT,
		@SUCCESS_COUNT INT,
		@ERROR_COUNT INT,
		@TOTAL_AMOUNT DECIMAL(14,2),
		@SUCCESS_AMOUNT DECIMAL(14,2),
		@ERROR_AMOUNT DECIMAL(14,2)

	set @in_error_sequence_no = 0

/*
	--1 GET TOTALS
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'SELECT AP'
	SET @error_msg_placeholder2 = 'STATUS TOTALS'
	
	
	SELECT @TOTAL_AMOUNT = ISNULL(SUM(a.VEND_HRS),0), @TOTAL_COUNT = Count (*)
	FROM IMAPS.Deltek.AOPUTLAP_INP_LAB a INNER JOIN IMAPS.Deltek.AOPUTLAP_INP_HDR b 
		ON a.VCHR_NO = b.VCHR_NO
	WHERE 	b.Notes =  LTRIM(RTRIM(CAST (@in_status_record_num  As char))) + ' ' + LTRIM(RTRIM(CAST(a.VCHR_NO AS char)))
	
	SELECT @SUCCESS_AMOUNT = ISNULL(SUM(a.VEND_HRS),0), @SUCCESS_COUNT = Count (*)
	FROM IMAPS.Deltek.AOPUTLAP_INP_LAB a INNER JOIN IMAPS.Deltek.AOPUTLAP_INP_HDR b 
		ON a.VCHR_NO = b.VCHR_NO
	WHERE (a.S_STATUS_CD <> 'E' OR a.S_STATUS_CD is NULL) AND
		b.Notes =  LTRIM(RTRIM(CAST (@in_status_record_num  As char))) + ' ' + LTRIM(RTRIM(CAST(a.VCHR_NO AS char)))
	
	SELECT @ERROR_AMOUNT = ISNULL(SUM(a.VEND_HRS),0), @ERROR_COUNT = Count (*)
	FROM IMAPS.Deltek.AOPUTLAP_INP_LAB a INNER JOIN IMAPS.Deltek.AOPUTLAP_INP_HDR b 
		ON a.VCHR_NO = b.VCHR_NO
	WHERE a.S_STATUS_CD = 'E' AND 
		b.Notes =  LTRIM(RTRIM(CAST (@in_status_record_num  As char))) + ' ' + LTRIM(RTRIM(CAST(a.VCHR_NO AS char)))				
	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

	
*/
	
	--2 GRAB AP ERROR RECORDS
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'GRAB AP'
	SET @error_msg_placeholder2 = 'ERROR RECORDS'
	
	exec @ret_code = xx_error_ap_pclaim_grab_sp
		@in_status_record_num = @in_status_record_num,
		@in_error_sequence_no = @in_error_sequence_no
	
	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER
	

	/*
	--3 INSERT AP ERROR STATUS RECORD
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'INSERT AP'
	SET @error_msg_placeholder2 = 'ERROR STATUS RECORD'

	insert into xx_error_status
	(STATUS_RECORD_NUM, ERROR_SEQUENCE_NO,
	 INTERFACE, PREPROCESSOR, 
	 STATUS, CONTROL_PT,
	 TOTAL_COUNT, SUCCESS_COUNT, ERROR_COUNT,
	 TOTAL_AMOUNT, SUCCESS_AMOUNT, ERROR_AMOUNT,
	 TIME_STAMP)
	select 
	@in_status_record_num, @in_error_sequence_no,
	'PCLAIM', 'AP',
	'WAITING FOR EXPORT', 5,
	@TOTAL_COUNT, @SUCCESS_COUNT, @ERROR_COUNT,
	@TOTAL_AMOUNT, @SUCCESS_AMOUNT, @ERROR_AMOUNT,
	GETDATE()
	*/
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


IF OBJECT_ID('dbo.XX_ERROR_JE_EXPORT_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_ERROR_JE_EXPORT_SP
    IF OBJECT_ID('dbo.XX_ERROR_JE_EXPORT_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_ERROR_JE_EXPORT_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_ERROR_JE_EXPORT_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go









CREATE PROCEDURE [dbo].[XX_ERROR_JE_EXPORT_SP] 
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
	
	SET @SP_NAME = 'XX_ERROR_JE_EXPORT_SP'

	--1	
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'TRUNCATE TABLE'
	SET @error_msg_placeholder2 = 'XX_ERROR_JE_TEMP'

	TRUNCATE TABLE XX_ERROR_JE_TEMP

	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER


	--2 
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'INSERT INTO'
	SET @error_msg_placeholder2 = 'XX_ERROR_JE_TEMP'

	INSERT INTO dbo.XX_ERROR_JE_TEMP
	SELECT top 65000 
	a.INP_JE_NO,
	a.JE_LN_NO,
	a.TRN_AMT,
	a.ACCT_ID,
	a.ORG_ID, 
	a.PROJ_ABBRV_CD,
	dbo.XX_PARSE_CSV(a.NOTES, 3) as PROJECT_NO,
	proj.ACCT_GRP_CD as PAG,
	dbo.XX_PARSE_CSV(a.JE_TRN_DESC, 2) as MAJOR,
	dbo.XX_PARSE_CSV(a.NOTES, 0) as MINOR,
	dbo.XX_PARSE_CSV(a.NOTES, 1) as SUB_MINOR,
	dbo.XX_PARSE_CSV(a.JE_TRN_DESC, 1) as SOURCE,
	dbo.XX_PARSE_CSV(a.NOTES, 2) as ANALYSIS_CODE,
	dbo.XX_PARSE_CSV(a.NOTES, 4) as DEPT,
	dbo.XX_PARSE_CSV(a.JE_TRN_DESC + ',', 3) as VCHR_NO,
	dbo.XX_PARSE_CSV(a.NOTES, 12) as ACCOUNTANT_ID,
	dbo.XX_PARSE_CSV(a.NOTES, 7) as AP_IDX,
	a.FEEDBACK,
	a.STATUS_RECORD_NUM,
	a.ERROR_SEQUENCE_NO,
	a.REC_NO
	FROM dbo.aoputlje_inp_tr_errors a
	LEFT JOIN
 	imaps.deltek.proj proj
	ON
	(a.PROJ_ABBRV_CD = proj.PROJ_ABBRV_CD
	 and a.PROJ_ABBRV_CD<>' ' ) -- Added for Defact DEV1805 tpatel
	WHERE 
	a.ERROR_SEQUENCE_NO = @in_error_sequence_no
	AND
	LEFT(a.JE_TRN_DESC, LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num as varchar) + ',')

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










go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_ERROR_JE_EXPORT_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_ERROR_JE_EXPORT_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_ERROR_JE_EXPORT_SP >>>'
go
GRANT EXECUTE ON dbo.XX_ERROR_JE_EXPORT_SP TO imapsprd
go
GRANT EXECUTE ON dbo.XX_ERROR_JE_EXPORT_SP TO imapsstg
go

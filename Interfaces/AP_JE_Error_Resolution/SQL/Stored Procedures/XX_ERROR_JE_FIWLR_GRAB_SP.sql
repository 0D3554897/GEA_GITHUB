SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_ERROR_JE_FIWLR_GRAB_SP    Script Date: 08/23/2006 11:31:43 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_ERROR_JE_FIWLR_GRAB_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_ERROR_JE_FIWLR_GRAB_SP]
GO













CREATE PROCEDURE [dbo].[XX_ERROR_JE_FIWLR_GRAB_SP] 
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
	@error_msg_placeholder2 sysname,
	@row_count		int

	SET @SP_NAME = 'XX_ERROR_JE_FIWLR_GRAB_SP'

	--0 VALIDATE GRAB IS NEEDED
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'DATA HAS NOT ALREADY BEEN'
	SET @error_msg_placeholder2 = 'OBTAINED'

	SELECT @row_count = count(1) from dbo.AOPUTLJE_INP_TR_ERRORS
	WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM
	and ERROR_SEQUENCE_NO = @in_ERROR_SEQUENCE_NO

	IF @row_count <> 0 GOTO BL_ERROR_HANDLER

	--1
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'INSERT INTO'
	SET @error_msg_placeholder2 = 'dbo.AOPUTLJE_INP_TR_ERRORS'
	
	INSERT INTO dbo.AOPUTLJE_INP_TR_ERRORS
	SELECT @in_status_record_num, @in_error_sequence_no, '',
	REC_NO, S_STATUS_CD, JE_LN_NO, INP_JE_NO, S_JNL_CD, FY_CD,
	PD_NO, SUB_PD_NO, RVRS_FL, JE_DESC, TRN_AMT, ACCT_ID,
	ORG_ID, JE_TRN_DESC, PROJ_ID, REF_STRUC_1_ID, REF_STRUC_2_ID,
	CYCLE_DC, ORG_ABBRV_CD, PROJ_ABBRV_CD, PROJ_ACCT_ABBRV_CD, 
	UPDATE_OBD_FL, NOTES, TIME_STAMP
	FROM IMAPS.DELTEK.AOPUTLJE_INP_TR
	WHERE s_status_cd = 'E'
	AND	LEFT(JE_TRN_DESC, LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num as varchar) + ',')
	ORDER BY INP_JE_NO, JE_LN_NO

	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER



	--2
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'DELETE FROM'
	SET @error_msg_placeholder2 = 'IMAPS.DELTEK.AOPUTLJE_INP_TR'

	
	DELETE FROM IMAPS.DELTEK.AOPUTLJE_INP_TR
	WHERE  LEFT(JE_TRN_DESC, LEN(@in_status_record_num)+1) = (CAST(@in_status_record_num as varchar) + ',')
	

	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER



	--3
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'UPDATE FEEDBACK COLUMN IN'
	SET @error_msg_placeholder2 = 'dbo.AOPUTLJE_INP_TR_ERRORS'

	UPDATE dbo.AOPUTLJE_INP_TR_ERRORS
	SET FEEDBACK = CAST(FEEDBACK + 'ACCT_ID invalid,' as varchar(254))
	FROM	dbo.AOPUTLJE_INP_TR_ERRORS a
	WHERE 0 =
	(
	SELECT COUNT(1)
	FROM 	imaps.deltek.acct
	WHERE	ACCT_ID = a.ACCT_ID
	)

	UPDATE dbo.AOPUTLJE_INP_TR_ERRORS
	SET FEEDBACK = CAST(FEEDBACK + 'ORG_ID and PROJ_ABBRV_CD are invalid,' as varchar(254))
	FROM	dbo.AOPUTLJE_INP_TR_ERRORS a
	WHERE 0 =
	(
	SELECT COUNT(1)
	FROM 	imaps.deltek.org
	WHERE	ORG_ID = a.ORG_ID
	)
	AND
	a.PROJ_ABBRV_CD IS NULL
	
	UPDATE dbo.AOPUTLJE_INP_TR_ERRORS
	SET FEEDBACK = CAST(FEEDBACK + 'PROJ_ABBRV_CD invalid,' as varchar(254))
	FROM	dbo.AOPUTLJE_INP_TR_ERRORS a
	WHERE 0 =
	(
	SELECT COUNT(1)
	FROM 	imaps.deltek.proj
	WHERE	PROJ_ABBRV_CD = a.PROJ_ABBRV_CD
	)
	AND a.PROJ_ABBRV_CD IS NOT NULL
	
	UPDATE dbo.AOPUTLJE_INP_TR_ERRORS
	SET FEEDBACK = CAST(FEEDBACK + 'ACCT_ID invalid for PROJ_ABBRV_CD,' as varchar(254))
	FROM   dbo.AOPUTLJE_INP_TR_ERRORS a
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
	
	
	UPDATE dbo.AOPUTLJE_INP_TR_ERRORS
	SET FEEDBACK = CAST(FEEDBACK + 'ACCT_ID invalid for ORG_ID,' as varchar(254))
	FROM	dbo.AOPUTLJE_INP_TR_ERRORS a
	WHERE 0 =
	(
	SELECT 	COUNT(1)
	FROM		imaps.deltek.org_acct
	WHERE	 	acct_id = a.ACCT_ID
	AND		org_id = a.ORG_ID
	)
	AND a.ORG_ID IS NOT NULL
	AND a.ACCT_ID IS NOT NULL


	UPDATE dbo.AOPUTLJE_INP_TR_ERRORS
	SET FEEDBACK = CAST(FEEDBACK + 'ACCT_ID invalid for OWNING ORG_ID,' as varchar(254))
	FROM	dbo.AOPUTLJE_INP_TR_ERRORS a
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


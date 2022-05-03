USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_PREPROCESSOR_CLOSEOUT_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_R22_FIWLR_PREPROCESSOR_CLOSEOUT_SP]
GO

CREATE PROCEDURE [dbo].[XX_R22_FIWLR_PREPROCESSOR_CLOSEOUT_SP] (
@out_STATUS_DESCRIPTION sysname = NULL
)
AS
BEGIN

/************************************************************************************************/
/* Procedure Name	: XX_R22_FIWLR_PREPROCESSOR_CLOSEOUT_SP										*/
/* Created By		: Keith Mcguire and Veera Veeramachanane			   						*/
/* Description    	: IMAPS FIW-LR Preprocessor Closeout Procedure								*/
/* Date				: August 10, 2008															*/
/* Notes			: IMAPS FIWLR_R22 Preprocessor Closeout program								*/
/* Prerequisites	: XX_R22_FIWLR_USDET_TEMP, XX_R22_FIWLR_USDET_RPT_TEMP,						*/
/*					  DELETEK.AOPUTLAP_INP_HDR, DELTEK.AOPUTLAP_INP_DETL and					*/
/*					  DELTEK.AOPUTLJE_INP_TR Table(s) should exist								*/
/* Parameter(s)		: 																			*/
/*	Input			: Status Record Number														*/
/*	Output			: Error Code and Error Description											*/
/* Tables Updated	: XX_R22_FIWLR_USDET_TEMP, XX_R22_FIWLR_USDET_RPT_TEMP,						*/
/*					  DELTEK.AOPUTLAP_INP_HDR, DELTEK.AOPUTLAP_INP_DETL and						*/
/*					  DELTEK.AOPUTLJE_INP_TR and DELTEK.AOPUTLJE_INP_VEN						*/
/* Version			: 1.0																		*/
/************************************************************************************************/
/* Date			Modified By				Description of change			  						*/
/* ----------   -------------  	   		------------------------    			  				*/
/* 08-10-2008   Veera Veeramachanane   	Created Initial Version									*/
/************************************************************************************************/

	DECLARE	
		@sp_name				 SYSNAME,
        @imaps_error_number      INTEGER,
        @SQLServer_error_code    INTEGER,
        @error_msg_placeholder1  SYSNAME,
        @error_msg_placeholder2  SYSNAME,
		@interface_name			 SYSNAME,
		@ret_code				 INT,
		@count					 INT,
		
		@fiwlr_user_id			CHAR(10),
		@time_stamp				DATETIME,
		@process_time_stamp		DATETIME

	SET @interface_name = 'FIWLR_R22'
	SET @sp_name = 'XX_R22_FIWLR_PREPROCESSOR_CLOSEOUT_SP'
	SET @ret_code = 1

	SET @fiwlr_user_id = 'FIWLR22'

	UPDATE	IMAR.DELTEK.je_hdr
	SET	entr_user_id = @fiwlr_user_id
	WHERE	LEFT(RTRIM(je_desc), 30) IN 
		       (
			SELECT	LEFT(RTRIM(je_desc), 30)
			FROM	IMAR.DELTEK.aoputlje_inp_tr
		       )

	SELECT @sqlserver_error_code = @@error
	IF @sqlserver_error_code <> 0 GOTO ERROR

	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'UPDATE DELTEK.VCHR_HDR USER ID'
	SET @error_msg_placeholder2 = 'TO FIWLR'

	UPDATE	IMAR.DELTEK.vchr_hdr
	SET		entr_user_id = @fiwlr_user_id
	WHERE 	LEFT(RTRIM(notes), 30) IN
		       (
			SELECT	LEFT(RTRIM(notes), 30)
			FROM	IMAR.DELTEK.aoputlap_inp_hdr	
		       )

	SELECT @sqlserver_error_code = @@error
	IF @sqlserver_error_code <> 0 GOTO ERROR
	
	

	--begin grab the JE and AP Cosptoint Numbers for Reporting Purposes
	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'UPDATE XX_R22_FIWLR_USDET_TEMP'
	SET @error_msg_placeholder2 = 'WITH COSTPOINT RPT DATA'
	
	TRUNCATE TABLE xx_r22_fiwlr_usdet_rpt_temp

	INSERT INTO xx_r22_fiwlr_usdet_rpt_temp
		(source_group, cp_ln_desc, cp_ln_notes, cp_hdr_key, cp_ln_no)
	SELECT 'AP', vchr_ln_desc, notes, vchr_key, vchr_ln_no
	FROM	IMAR.DELTEK.vchr_ln
	WHERE	LEFT(notes, 3) <> 'Bal'
	
	INSERT INTO xx_r22_fiwlr_usdet_rpt_temp
		(source_group, cp_ln_desc, cp_ln_notes, cp_hdr_key, cp_ln_no)
	SELECT 'JE', je_trn_desc, notes, je_hdr_key, je_ln_no
	FROM	IMAR.DELTEK.je_trn
	WHERE	LEFT(notes, 3) <> 'Bal'
	
	
	UPDATE	xx_r22_fiwlr_usdet_rpt_temp
	SET		status_rec_no = LEFT(dbo.xx_parse_csv(cp_ln_desc, 0), 10),
			ident_rec_no  = LEFT(dbo.xx_parse_csv_backwards(cp_ln_notes, 1), 10)
	
	UPDATE	xx_r22_fiwlr_usdet_rpt_temp
	SET		cp_hdr_no = hdr.vchr_no,
	    	fy_cd = hdr.fy_cd,
	    	pd_no = hdr.pd_no,
	    	sub_pd_no = hdr.sub_pd_no
	FROM	xx_r22_fiwlr_usdet_rpt_temp tmp
	INNER JOIN
			IMAR.DELTEK.vchr_hdr hdr
	ON
			(tmp.source_group = 'AP'
	AND		tmp.cp_hdr_key = hdr.vchr_key)
	
	UPDATE	xx_r22_fiwlr_usdet_rpt_temp
	SET		cp_hdr_no = hdr.je_no,
	    	fy_cd = hdr.fy_cd,
	    	pd_no = hdr.pd_no,
	    	sub_pd_no = hdr.sub_pd_no
	FROM	xx_r22_fiwlr_usdet_rpt_temp tmp
	INNER JOIN
			IMAR.DELTEK.je_hdr hdr
	ON
			(tmp.source_group = 'JE'
	AND		tmp.cp_hdr_key = hdr.je_hdr_key)
	

	UPDATE	xx_r22_fiwlr_usdet_temp
	SET		cp_hdr_no = tmp.cp_hdr_no,
	    	cp_ln_no = tmp.cp_ln_no,
	    	fy_cd = tmp.fy_cd,
	    	pd_no = tmp.pd_no,
	    	sub_pd_no = tmp.sub_pd_no	  
	FROM	xx_r22_fiwlr_usdet_temp usdet
	INNER JOIN
			xx_r22_fiwlr_usdet_rpt_temp tmp
	ON
		(
	 	CAST(usdet.status_rec_no as varchar) = tmp.status_rec_no
	AND
	 	CAST(usdet.ident_rec_no as varchar) = tmp.ident_rec_no
		)
		
	SELECT @sqlserver_error_code = @@error
	IF @sqlserver_error_code <> 0 GOTO ERROR
	--end grab the JE and AP Cosptoint Numbers for Reporting Purposes


	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'VERIFY TOTALS MATCH'
	SET @error_msg_placeholder2 = 'COSTPOINT TOTALS - AP'

	DECLARE @record_count_costpoint  INT,
		@record_count_imaps 	 INT,
		@dollar_amount_costpoint DECIMAL(14,2),
		@dollar_amount_imaps     DECIMAL(14,2)

	SELECT 	@record_count_costpoint = ISNULL(COUNT(1), 0),
			@dollar_amount_costpoint = ISNULL(SUM(cst_amt), 0)
	FROM	IMAR.DELTEK.aoputlap_inp_detl
	WHERE	s_status_cd = 'I'
	AND		LEFT(notes, 3) <> 'Bal'

	SELECT  @record_count_imaps = ISNULL(COUNT(1), 0),
			@dollar_amount_imaps = ISNULL(SUM(amount), 0)
	FROM	xx_r22_fiwlr_usdet_temp
	WHERE	cp_hdr_no IS NOT NULL
	AND		source_group = 'AP'

	IF	@record_count_costpoint <> @record_count_imaps GOTO ERROR
	IF	@dollar_amount_costpoint <> @dollar_amount_imaps GOTO ERROR

	SET @imaps_error_number = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @error_msg_placeholder1 = 'VERIFY TOTALS MATCH'
	SET @error_msg_placeholder2 = 'COSTPOINT TOTALS - JE'

	SET @record_count_costpoint = NULL
	SET @record_count_imaps = NULL
	SET @dollar_amount_costpoint = NULL
	SET @dollar_amount_imaps = NULL

	SELECT 	@record_count_costpoint = ISNULL(COUNT(1), 0),
			@dollar_amount_costpoint = ISNULL(SUM(trn_amt),0)
	FROM	IMAR.DELTEK.aoputlje_inp_tr
	WHERE	s_status_cd = 'I'
	AND		LEFT(notes, 3) <> 'Bal'

	SELECT  @record_count_imaps = isnull(COUNT(1),0),
			@dollar_amount_imaps = isnull(SUM(AMOUNT),0)
	FROM	xx_r22_fiwlr_usdet_temp
	WHERE	cp_hdr_no IS NOT NULL
	AND		source_group = 'JE'

	IF	@record_count_costpoint <> @record_count_imaps GOTO ERROR
	IF	@dollar_amount_costpoint <> @dollar_amount_imaps GOTO ERROR


	--we're done here

	TRUNCATE TABLE IMAR.DELTEK.aoputlap_inp_hdr

	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR
	
	TRUNCATE TABLE IMAR.DELTEK.aoputlap_inp_detl

	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR

	TRUNCATE TABLE IMAR.DELTEK.aoputlje_inp_tr

	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR


	TRUNCATE TABLE IMAR.DELTEK.aoputlje_inp_ven

	SELECT @sqlserver_error_code = @@error	
	IF @sqlserver_error_code <> 0 GOTO ERROR


RETURN 0

ERROR:

PRINT @out_STATUS_DESCRIPTION

EXEC dbo.XX_ERROR_MSG_DETAIL
   	@in_error_code           = @IMAPS_error_number,
   	@in_display_requested    = 1,
   	@in_SQLServer_error_code = @SQLServer_error_code,
   	@in_placeholder_value1   = @error_msg_placeholder1,
   	@in_placeholder_value2   = @error_msg_placeholder2,
   	@in_calling_object_name  = @SP_NAME,
   	@out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

PRINT @out_STATUS_DESCRIPTION

RETURN 1


END


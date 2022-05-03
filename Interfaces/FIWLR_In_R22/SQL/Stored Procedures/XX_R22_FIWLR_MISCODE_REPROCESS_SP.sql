USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_MISCODE_REPROCESS_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_R22_FIWLR_MISCODE_REPROCESS_SP]
GO

CREATE PROCEDURE [dbo].[XX_R22_FIWLR_MISCODE_REPROCESS_SP] (
@out_STATUS_DESCRIPTION sysname = NULL
)
AS
BEGIN
/************************************************************************************************  
Name:       XX_R22_FIWLR_MISCODE_REPROCESS_SP  
Author:     KM  

2014-02-19  Costpoint 7 changes
			Process Server replaced by Job Server
************************************************************************************************/  

DECLARE @SP_NAME                 sysname,
        @DIV_22_COMPANY_ID       varchar(10),
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@INTERFACE_NAME		 sysname,
		@ret_code		 int,
		@count			 int,
		@fy_cd			 char(4),
		@pd_no			 smallint,
		@sub_pd_no		 smallint,
		@ap_acct_desc		 varchar(30),
		@cash_acct_desc		 varchar(30),
		@source_group		 char(2),
		@pay_terms		 varchar(15),
		@source_wwer			 char(3),
		@vchrlno		 int,
		@s_status_cd		 char(1),
		@sjnlcd 		char(3), 
		@jeno			int,
		@jelno			int


	SET @INTERFACE_NAME = 'FIWLR_R22'
	SET @SP_NAME = 'XX_R22_FIWLR_MISCODE_REPROCESS_SP'
	SELECT
		@ap_acct_desc	= NULL, 
		@cash_acct_desc = NULL,
		@pay_terms = 'NET 30',
		@source_group = 'AP',  --changed to JE later
		@source_wwer = '005',
		@vchrlno = 1,
		@s_status_cd = 'U',
		@sjnlcd = 'AJE',
		@jeno = 1,
		@jelno = 0 ,
		@ret_code = 1

	SET @IMAPS_ERROR_NUMBER = 204 -- Attempt to %1 %2 failed.
	SET @ERROR_MSG_PLACEHOLDER1 = 'access required processing parameter COMPANY_ID'
	SET @ERROR_MSG_PLACEHOLDER2 = 'for FIWLR Interface'

	SELECT @DIV_22_COMPANY_ID = PARAMETER_VALUE
	FROM 	dbo.XX_PROCESSING_PARAMETERS
	WHERE 	PARAMETER_NAME = 'COMPANY_ID'
	AND	INTERFACE_NAME_CD = 'FIWLR_R22'

	SET @count = @@ROWCOUNT

	IF @count = 0 OR LEN(RTRIM(LTRIM(@DIV_22_COMPANY_ID))) = 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY NO PREVIOUS MISCODE RUN'
	SET @ERROR_MSG_PLACEHOLDER2 = 'IS IN PROGRESS'

	SELECT 	@count = count(1)
	FROM 	XX_ERROR_STATUS
	WHERE	CONTROL_PT <> 7
	AND		INTERFACE='FIWLR_R22'
	
	IF @count <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY FIWLR_R22 IS NOT RUNNING'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FIWLR_R22'

	SELECT 	@count = count(1)
	FROM 	XX_IMAPS_INT_STATUS
	WHERE 	INTERFACE_NAME = 'FIWLR_R22'
	AND		STATUS_CODE <> 'COMPLETED'
	
	IF @count <> 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'RE-VALIDATE EVERYTHING'
	SET @ERROR_MSG_PLACEHOLDER2 = 'IN CASE COSTPOINT HAS CHANGED'

	EXEC @ret_code = XX_R22_FIWLR_MISCODE_UPDATE_FEEDBACK_SP
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 OR @ret_code <> 0 GOTO ERROR

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE STATUS CODE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR DOCUMENTS THAT ARE ENTIRELY VALID'

	UPDATE 	XX_R22_FIWLR_USDET_MISCODES
	SET	REFERENCE1 = 'V'
	FROM	XX_R22_FIWLR_USDET_MISCODES miscodes
	WHERE 	
	0 = (SELECT COUNT(1)
		 FROM XX_R22_FIWLR_USDET_MISCODES
		 WHERE STATUS_REC_NO = miscodes.STATUS_REC_NO
		 AND   REFERENCE3 = miscodes.REFERENCE3
		 AND   REFERENCE2 <> 'valid')

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'TRUNCATE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_R22_FIWLR_USDET_TEMP'

	TRUNCATE TABLE XX_R22_FIWLR_USDET_TEMP
	
	IF @@ERROR <> 0 GOTO ERROR

	

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT VALID MISCODES'
	SET @ERROR_MSG_PLACEHOLDER2 = 'INTO XX_R22_FIWLR_USDET_TEMP'
	
	INSERT INTO  XX_R22_FIWLR_USDET_TEMP
	SELECT * FROM XX_R22_FIWLR_USDET_MISCODES
	WHERE reference1 = 'V'
	
	IF @@ERROR <> 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'CALL XX_R22_FIWLR_LOAD_PREPROCESSORS_SP'
	SET @ERROR_MSG_PLACEHOLDER2 = 'INTO XX_R22_FIWLR_USDET_TEMP'

	EXEC @ret_code = XX_R22_FIWLR_LOAD_PREPROCESSORS_SP	

	IF @ret_code <> 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'LOAD TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_ERROR_STATUS'

	INSERT INTO XX_ERROR_STATUS
	(STATUS_RECORD_NUM, ERROR_SEQUENCE_NO, 
	 INTERFACE, PREPROCESSOR, 
	 STATUS, CONTROL_PT, 
	 TOTAL_COUNT, TOTAL_AMOUNT, 
	 SUCCESS_COUNT, SUCCESS_AMOUNT,
	 ERROR_COUNT, ERROR_AMOUNT,
	 TIME_STAMP)
	SELECT 
	fiwlr.STATUS_REC_NO, 
	(select isnull( (max(error_sequence_no)+1), 0)
	 from xx_error_status
	 where 	status_record_num = fiwlr.status_rec_no
	 and 	preprocessor = fiwlr.source_group
	), 
	'FIWLR_R22', fiwlr.SOURCE_GROUP, 
	'PREPROCESSOR STARTED', 3, 
	COUNT(1), SUM(fiwlr.AMOUNT),
	0, 0,
	0, 0,  
	CURRENT_TIMESTAMP
	FROM XX_R22_FIWLR_USDET_MISCODES fiwlr
	WHERE
	cast(fiwlr.status_rec_no as varchar)+fiwlr.source_group
	in
		(select cast(status_rec_no as varchar)+source_group
		 from XX_R22_FIWLR_usdet_miscodes 
		 where reference1 = 'V')
	GROUP BY fiwlr.STATUS_REC_NO, fiwlr.SOURCE_GROUP

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'KICK OFF'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FIWLR_R22_MISCODE'

	--2014-02-19  Costpoint 7 changes BEGIN
	UPDATE IMAR.DELTEK.job_schedule
	SET 	SCH_START_DTT = CURRENT_TIMESTAMP,
		TIME_STAMP = CURRENT_TIMESTAMP
	WHERE	job_id = 'FIWLR_R22_M'
	AND	COMPANY_ID = @DIV_22_COMPANY_ID 	
	--2014-02-19  Costpoint 7 changes END

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


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

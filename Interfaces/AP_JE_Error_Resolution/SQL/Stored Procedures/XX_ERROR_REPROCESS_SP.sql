SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_ERROR_REPROCESS_SP    Script Date: 12/06/2006 4:14:25 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_ERROR_REPROCESS_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_ERROR_REPROCESS_SP]
GO







CREATE PROCEDURE DBO.XX_ERROR_REPROCESS_SP
(
@PREPROCESSOR CHAR(2),
@STATUS_RECORD_NUM INT,
@ERROR_SEQUENCE_NO INT,
@INTERFACE VARCHAR(30)
)
AS
/************************************************************************************************  
NAME:       	XX_ERROR_REPROCESS_SP  
AUTHOR:     	KM
CREATED:    	06/2006
PURPOSE:    	RUN INTERFACE STORED PROCEDURE FOR 
		AP/JE ERROR MISCODES

PREREQUISITES: 	DTS HAS LOADED TEMP TABLES WITH DATA 

I WISH WE HAD JUST DONE THE WEBVERSION
IT WOULD HAVE BEEN SO MUCH MUCH EASIER  

VERSION: 	1.0
NOTES:      	

************************************************************************************************/  
BEGIN
	-- DECLARATIONS
	DECLARE	@SP_NAME	SYSNAME,
	@IMAPS_ERROR_NUMBER     INT,
	@SQLSERVER_ERROR_CODE 	INT,
	@ERROR_MSG_PLACEHOLDER1 SYSNAME,
	@ERROR_MSG_PLACEHOLDER2 SYSNAME,
	@OUT_STATUS_DESCRIPTION SYSNAME
	
	SET @SP_NAME = 'XX_ERROR_REPROCESS_SP'

	DECLARE @CONTROL_POINT_NUM INT,
	@STATUS VARCHAR(30),
	@RET_CODE INT,
	@ROW_COUNT INT,
	@LAST_CONTROL_PT INT,
	@FINAL_STATUS VARCHAR(30)

	SET @LAST_CONTROL_PT = 7
	SET @FINAL_STATUS = 'COMPLETED'


	--0. VALIDATE INPUT PARAMETERS
	--   AND LOAD OF TEMP TABLE
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VALIDATE @PREPROCESSOR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'IS AP OR JE'
	IF @PREPROCESSOR NOT IN ('AP', 'JE') GOTO BL_ERROR_HANDLER
	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VALIDATE @INTERFACE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'IS FIWLR OR PCLAIM'
	IF @INTERFACE NOT IN ('FIWLR', 'PCLAIM') GOTO BL_ERROR_HANDLER

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VALIDATE STATUS_RECORD_NUM'
	SET @ERROR_MSG_PLACEHOLDER2 = 'AND ERROR_SEQUENCE_NO'
	SELECT @row_count = count(1)
	FROM	dbo.XX_ERROR_STATUS
	WHERE 	STATUS_RECORD_NUM = @STATUS_RECORD_NUM
	AND	ERROR_SEQUENCE_NO = @ERROR_SEQUENCE_NO
	AND	PREPROCESSOR = @PREPROCESSOR
	AND 	INTERFACE = @INTERFACE
	IF @row_count = 0 GOTO BL_ERROR_HANDLER


	--1. GET LAST CONTROL POINT
	SELECT 	@CONTROL_POINT_NUM = CONTROL_PT,
		@STATUS = STATUS
	FROM	DBO.XX_ERROR_STATUS
	WHERE 	STATUS_RECORD_NUM = @STATUS_RECORD_NUM
	AND	ERROR_SEQUENCE_NO = @ERROR_SEQUENCE_NO
	AND	PREPROCESSOR = @PREPROCESSOR
	AND 	INTERFACE = @INTERFACE

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

	--2 IF CONTROL POINT IS LAST ONE
	--  ERROR OUT (NO REPROCESSING OF ANY FILES)
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'REPROCESS OLD'
	SET @ERROR_MSG_PLACEHOLDER2 = 'MISCODE FILE'
	
	IF @CONTROL_POINT_NUM >= @LAST_CONTROL_PT GOTO BL_ERROR_HANDLER


	--3 VERIFY AT LEAST CONTROL POINT 1 (LOADING OF SPREADSHEET)
	--  HAS BEEN PASSED
	--  ERROR OUT (DTS MUST LOAD TABLE AND INSERT FIRST STATUS RECORD)
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY SPREADSHEET'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WAS LOADED'
	
	IF @CONTROL_POINT_NUM IS NULL GOTO BL_ERROR_HANDLER
	IF @CONTROL_POINT_NUM <= 0 GOTO BL_ERROR_HANDLER

	
	--4 LET'S GO


	--CONTROL POINT 1 IS THE DTS IMPORT


	--IF NEXT CONTROL POINT = 2
	--LOAD PREPROCESSOR TABLE
	IF @CONTROL_POINT_NUM = 1
	BEGIN
		SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
		SET @ERROR_MSG_PLACEHOLDER1 = 'ATTEMPT TO LOAD' + @PREPROCESSOR
		SET @ERROR_MSG_PLACEHOLDER2 = 'PREPROCESSOR IMPORT TABLE'

		IF @PREPROCESSOR = 'AP'
		BEGIN
			EXEC @RET_CODE = DBO.XX_ERROR_AP_IMPORT_SP
				@IN_STATUS_RECORD_NUM = @STATUS_RECORD_NUM,
				@IN_ERROR_SEQUENCE_NO = @ERROR_SEQUENCE_NO,
				@OUT_SQLSERVER_ERROR_CODE = @SQLSERVER_ERROR_CODE OUTPUT,
				@OUT_STATUS_DESCRIPTION = @OUT_STATUS_DESCRIPTION OUTPUT
		END
		IF @PREPROCESSOR = 'JE'
		BEGIN
			EXEC @RET_CODE = DBO.XX_ERROR_JE_IMPORT_SP
				@IN_STATUS_RECORD_NUM = @STATUS_RECORD_NUM,
				@IN_ERROR_SEQUENCE_NO = @ERROR_SEQUENCE_NO,
				@OUT_SQLSERVER_ERROR_CODE = @SQLSERVER_ERROR_CODE OUTPUT,
				@OUT_STATUS_DESCRIPTION = @OUT_STATUS_DESCRIPTION OUTPUT
		END		
		
		IF @RET_CODE <> 0 GOTO BL_ERROR_HANDLER

		UPDATE DBO.XX_ERROR_STATUS
		SET	CONTROL_PT = 2,
			TIME_STAMP = GETDATE(),
			STATUS = 'PREPROCESSOR LOADED'
		WHERE 	STATUS_RECORD_NUM = @STATUS_RECORD_NUM
		AND	ERROR_SEQUENCE_NO = @ERROR_SEQUENCE_NO
		AND	PREPROCESSOR = @PREPROCESSOR 	
		AND 	INTERFACE = @INTERFACE

		SELECT @SQLSERVER_ERROR_CODE = @@ERROR
		IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

		SET @CONTROL_POINT_NUM = 2
	END



	--IF NEXT CONTROL POINT = 3
	--KICKOFF PREPROCESSOR
	IF @CONTROL_POINT_NUM = 2
	BEGIN
		SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
		SET @ERROR_MSG_PLACEHOLDER1 = 'ATTEMPT TO KICKOFF' + @PREPROCESSOR
		SET @ERROR_MSG_PLACEHOLDER2 = 'PREPROCESSOR'

		IF @PREPROCESSOR = 'AP'
		BEGIN
			UPDATE 	IMAPS.DELTEK.PROCESS_QUE_ENTRY
			SET 	SCH_START_DTT = GETDATE()
			WHERE 	PROCESS_ID = 'AP_REPROCESS'
			
			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
		END
		IF @PREPROCESSOR = 'JE'
		BEGIN
			UPDATE 	IMAPS.DELTEK.PROCESS_QUE_ENTRY
			SET 	SCH_START_DTT = GETDATE()
			WHERE 	PROCESS_ID = 'JE_REPROCESS'
			
			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
		END		

		UPDATE DBO.XX_ERROR_STATUS
		SET	CONTROL_PT = 3,
			TIME_STAMP = GETDATE(),
			STATUS = 'PREPROCESSOR STARTED'
		WHERE 	STATUS_RECORD_NUM = @STATUS_RECORD_NUM
		AND	ERROR_SEQUENCE_NO = @ERROR_SEQUENCE_NO
		AND	PREPROCESSOR = @PREPROCESSOR 	
		AND 	INTERFACE = @INTERFACE

		SELECT @SQLSERVER_ERROR_CODE = @@ERROR
		IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

		--ONCE WE ARE HERE, WE WANT TO EXIT WITH NO ERROR
		--AND WAIT FOR PREPROCESSOR TO COMPLETE
		RETURN(0)		
	END
	

	--IF NEXT CONTROL POINT = 4
	--CHECK FOR PREPROCESSOR COMPLETION
	IF @CONTROL_POINT_NUM = 3
	BEGIN
		DECLARE @S_PROC_STATUS_CD VARCHAR(10),
			@SCH_START_DTT DATETIME,
			@LAST_DATE DATETIME
	
		SELECT 	@LAST_DATE = TIME_STAMP
		FROM 	DBO.XX_ERROR_STATUS
		WHERE 	STATUS_RECORD_NUM = @STATUS_RECORD_NUM
		AND	ERROR_SEQUENCE_NO = @ERROR_SEQUENCE_NO
		AND	PREPROCESSOR = @PREPROCESSOR 
		AND 	INTERFACE = @INTERFACE

		SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
		SET @ERROR_MSG_PLACEHOLDER1 = 'ATTEMPT TO VERIFY'
		SET @ERROR_MSG_PLACEHOLDER2 = 'COMPLETION OF ' + @PREPROCESSOR

		IF @PREPROCESSOR = 'AP'
		BEGIN
			SELECT	@S_PROC_STATUS_CD = S_PROC_STATUS_CD,
				@SCH_START_DTT = SCH_START_DTT
			FROM	IMAPS.DELTEK.PROCESS_QUE_ENTRY
			WHERE 	PROCESS_ID = 'AP_REPROCESS'
		END
		IF @PREPROCESSOR = 'JE'
		BEGIN
			SELECT	@S_PROC_STATUS_CD = S_PROC_STATUS_CD,
				@SCH_START_DTT = SCH_START_DTT
			FROM	IMAPS.DELTEK.PROCESS_QUE_ENTRY
			WHERE 	PROCESS_ID = 'JE_REPROCESS'
		END		

		IF (@S_PROC_STATUS_CD <> 'PENDING'
		OR @SCH_START_DTT <= @LAST_DATE)
		BEGIN
			GOTO BL_ERROR_HANDLER
		END

		UPDATE DBO.XX_ERROR_STATUS
		SET	CONTROL_PT = 4,
			TIME_STAMP = GETDATE(),
			STATUS = 'PREPROCESSOR COMPLETED'
		WHERE 	STATUS_RECORD_NUM = @STATUS_RECORD_NUM
		AND	ERROR_SEQUENCE_NO = @ERROR_SEQUENCE_NO
		AND	PREPROCESSOR = @PREPROCESSOR 	
		AND 	INTERFACE = @INTERFACE

		SELECT @SQLSERVER_ERROR_CODE = @@ERROR
		IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

		SET @CONTROL_POINT_NUM = 4
	END
	

	--IF NEXT CONTROL POINT = 5
	--UPDATE ERROR STATUS TABLE
	IF @CONTROL_POINT_NUM = 4
	BEGIN
		SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
		SET @ERROR_MSG_PLACEHOLDER1 = 'ATTEMPT TO UPDATE'
		SET @ERROR_MSG_PLACEHOLDER2 = 'XX_ERROR_STATUS and ENTR_USER_ID'

		DECLARE @TOTAL_COUNT INT,
			@SUCCESS_COUNT INT,
			@ERROR_COUNT INT,
			@TOTAL_AMOUNT DECIMAL(14,2),
			@SUCCESS_AMOUNT DECIMAL(14,2),
			@ERROR_AMOUNT DECIMAL(14,2)		
	
		declare @FIWLR_USER_ID char(5)
		set @FIWLR_USER_ID = 'FIWLR'
				
		declare @PCLAIM_USER_ID char(6)
		set @PCLAIM_USER_ID = 'PCLAIM'
			
		declare @FIWLR_N16_USER_ID char(6)
		set @FIWLR_N16_USER_ID = 'FIWN16'
	
			

		IF @PREPROCESSOR = 'AP' AND @INTERFACE = 'FIWLR'
		BEGIN
			SELECT	@TOTAL_AMOUNT = ISNULL(SUM(CST_AMT),0),
				@TOTAL_COUNT = COUNT(1)
			FROM	IMAPS.DELTEK.AOPUTLAP_INP_DETL
			WHERE	LEFT(VCHR_LN_DESC, LEN(@STATUS_RECORD_NUM)+1) = (CAST(@STATUS_RECORD_NUM AS VARCHAR)+',')
			AND	LEFT(NOTES, 3) <> 'BAL'

			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
		
			SELECT	@SUCCESS_AMOUNT = ISNULL(SUM(CST_AMT),0),
				@SUCCESS_COUNT = COUNT(1)
			FROM	IMAPS.DELTEK.AOPUTLAP_INP_DETL
			WHERE	LEFT(VCHR_LN_DESC, LEN(@STATUS_RECORD_NUM)+1) = (CAST(@STATUS_RECORD_NUM AS VARCHAR)+',')
			AND	LEFT(NOTES, 3) <> 'BAL'
			AND	S_STATUS_CD <> 'E'

			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
		
			SELECT	@ERROR_AMOUNT = ISNULL(SUM(CST_AMT),0),
				@ERROR_COUNT = COUNT(1)
			FROM	IMAPS.DELTEK.AOPUTLAP_INP_DETL
			WHERE	LEFT(VCHR_LN_DESC, LEN(@STATUS_RECORD_NUM)+1) = (CAST(@STATUS_RECORD_NUM AS VARCHAR)+',')
			AND	LEFT(NOTES, 3) <> 'BAL'
			AND	S_STATUS_CD = 'E'


			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
			
			update imaps.deltek.vchr_hdr
			set ENTR_USER_ID = @FIWLR_USER_ID
			where vchr_key in (
			select vchr_key
			from imaps.deltek.vchr_ln
			where left(vchr_ln_desc, len(@STATUS_RECORD_NUM)+1) = (cast(@STATUS_RECORD_NUM as varchar) + ',')
			)

			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
			
			update imaps.deltek.vchr_hdr
			set ENTR_USER_ID = @FIWLR_N16_USER_ID
			where vchr_key in (
			select vchr_key
			from imaps.deltek.vchr_ln
			where left(vchr_ln_desc, len(@STATUS_RECORD_NUM)+1) = (cast(@STATUS_RECORD_NUM as varchar) + ',')
			)
			and right(notes, 3) = 'N16'


			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

			update xx_fiwlr_usdet_archive
			set cp_hdr_no = hdr.vchr_no,
			    cp_ln_no = ln.vchr_ln_no,
			    fy_cd = hdr.fy_cd,
			    pd_no = hdr.pd_no,
			    sub_pd_no = hdr.sub_pd_no
			from xx_fiwlr_usdet_archive usdet
			inner join
			imaps.deltek.vchr_ln ln
			on
			(
			usdet.status_rec_no = @STATUS_RECORD_NUM
			and
			usdet.source_group = 'AP'
			and
			left(ln.vchr_ln_desc, len(@STATUS_RECORD_NUM)+1) = cast(@STATUS_RECORD_NUM as varchar) + ','
			and 
			dbo.xx_parse_csv(ln.notes, 24) = cast(usdet.ident_rec_no as varchar)
			)
			inner join
			imaps.deltek.vchr_hdr hdr
			on (hdr.vchr_key = ln.vchr_key)


			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

		END
		ELSE IF @PREPROCESSOR = 'JE' AND @INTERFACE = 'FIWLR'
		BEGIN
			SELECT	@TOTAL_AMOUNT = ISNULL(SUM(TRN_AMT),0),
				@TOTAL_COUNT = COUNT(1)
			FROM	IMAPS.DELTEK.AOPUTLJE_INP_TR
			WHERE	LEFT(JE_TRN_DESC, LEN(@STATUS_RECORD_NUM)+1) = (CAST(@STATUS_RECORD_NUM AS VARCHAR)+',')
			AND	LEFT(NOTES, 3) <> 'BAL'

			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
		
			SELECT	@SUCCESS_AMOUNT = ISNULL(SUM(TRN_AMT),0),
				@SUCCESS_COUNT = COUNT(1)
			FROM	IMAPS.DELTEK.AOPUTLJE_INP_TR
			WHERE	LEFT(JE_TRN_DESC, LEN(@STATUS_RECORD_NUM)+1) = (CAST(@STATUS_RECORD_NUM AS VARCHAR)+',')
			AND	LEFT(NOTES, 3) <> 'BAL'
			AND	S_STATUS_CD <> 'E'

			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
		
			SELECT	@ERROR_AMOUNT = ISNULL(SUM(TRN_AMT),0),
				@ERROR_COUNT = COUNT(1)
			FROM	IMAPS.DELTEK.AOPUTLJE_INP_TR
			WHERE	LEFT(JE_TRN_DESC, LEN(@STATUS_RECORD_NUM)+1) = (CAST(@STATUS_RECORD_NUM AS VARCHAR)+',')
			AND	LEFT(NOTES, 3) <> 'BAL'
			AND	S_STATUS_CD = 'E'
		
			update imaps.deltek.je_hdr
			set ENTR_USER_ID = @FIWLR_USER_ID
			where je_hdr_key in (
			select je_hdr_key
			from imaps.deltek.je_trn
			where left(je_trn_desc, len(@STATUS_RECORD_NUM)+1) = (cast(@STATUS_RECORD_NUM as varchar) + ',')
			)

			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
			
			update imaps.deltek.vchr_hdr
			set ENTR_USER_ID = @FIWLR_N16_USER_ID
			where vchr_key in (
			select vchr_key
			from imaps.deltek.vchr_ln
			where left(vchr_ln_desc, len(@STATUS_RECORD_NUM)+1) = (cast(@STATUS_RECORD_NUM as varchar) + ',')
			)
			and right(notes, 3) = 'N16'

			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

			update xx_fiwlr_usdet_archive
			set cp_hdr_no = hdr.je_no,
			    cp_ln_no = ln.je_ln_no,
			    fy_cd = hdr.fy_cd,
			    pd_no = hdr.pd_no,
			    sub_pd_no = hdr.sub_pd_no
			from xx_fiwlr_usdet_archive usdet
			inner join
			imaps.deltek.je_trn ln
			on
			(
			usdet.status_rec_no = @STATUS_RECORD_NUM
			and
			usdet.source_group = 'JE'
			and
			left(ln.je_trn_desc, len(@STATUS_RECORD_NUM)+1) = (cast(@STATUS_RECORD_NUM as varchar) + ',')
			and 
			dbo.xx_parse_csv(ln.notes, 24) = cast(usdet.ident_rec_no as varchar)
			)
			inner join
			imaps.deltek.je_hdr hdr
			on
			(hdr.je_hdr_key = ln.je_hdr_key)

			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

		END		
		ELSE IF @PREPROCESSOR = 'AP' AND @INTERFACE = 'PCLAIM'
		BEGIN
			SELECT @TOTAL_AMOUNT = ISNULL(SUM(a.VEND_HRS),0), @TOTAL_COUNT = Count (*)
			FROM IMAPS.Deltek.AOPUTLAP_INP_LAB a INNER JOIN IMAPS.Deltek.AOPUTLAP_INP_HDR b 
				ON a.VCHR_NO = b.VCHR_NO
			WHERE 	b.Notes =  LTRIM(RTRIM(CAST (@STATUS_RECORD_NUM  As char))) + ' ' + LTRIM(RTRIM(CAST(a.VCHR_NO AS char)))
			

			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

			SELECT @SUCCESS_AMOUNT = ISNULL(SUM(a.VEND_HRS),0), @SUCCESS_COUNT = Count (*)
			FROM IMAPS.Deltek.AOPUTLAP_INP_LAB a INNER JOIN IMAPS.Deltek.AOPUTLAP_INP_HDR b 
				ON a.VCHR_NO = b.VCHR_NO
			WHERE (a.S_STATUS_CD <> 'E' OR a.S_STATUS_CD is NULL) AND
				b.Notes =  LTRIM(RTRIM(CAST (@STATUS_RECORD_NUM  As char))) + ' ' + LTRIM(RTRIM(CAST(a.VCHR_NO AS char)))
			

			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

			SELECT @ERROR_AMOUNT = ISNULL(SUM(a.VEND_HRS),0), @ERROR_COUNT = Count (*)
			FROM IMAPS.Deltek.AOPUTLAP_INP_LAB a INNER JOIN IMAPS.Deltek.AOPUTLAP_INP_HDR b 
				ON a.VCHR_NO = b.VCHR_NO
			WHERE a.S_STATUS_CD = 'E' AND 
				b.Notes =  LTRIM(RTRIM(CAST (@STATUS_RECORD_NUM  As char))) + ' ' + LTRIM(RTRIM(CAST(a.VCHR_NO AS char)))			
		

			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

			update imaps.deltek.vchr_hdr
			set ENTR_USER_ID = @PCLAIM_USER_ID
			where left(notes, len(@STATUS_RECORD_NUM)+1) = (cast(@STATUS_RECORD_NUM as varchar) + ' ')
			
			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
		END	


	
		UPDATE DBO.XX_ERROR_STATUS
		SET	CONTROL_PT = 5,
			TIME_STAMP = GETDATE(),
			TOTAL_AMOUNT = @TOTAL_AMOUNT,
			TOTAL_COUNT = @TOTAL_COUNT,
			SUCCESS_AMOUNT = @SUCCESS_AMOUNT,
			SUCCESS_COUNT = @SUCCESS_COUNT,
			ERROR_AMOUNT = @ERROR_AMOUNT,
			ERROR_COUNT = @ERROR_COUNT,
			STATUS = 'TOTALS UPDATED'
		WHERE 	STATUS_RECORD_NUM = @STATUS_RECORD_NUM
		AND	ERROR_SEQUENCE_NO = @ERROR_SEQUENCE_NO
		AND	PREPROCESSOR = @PREPROCESSOR 			
		AND 	INTERFACE = @INTERFACE

		SELECT @SQLSERVER_ERROR_CODE = @@ERROR
		IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

		SET @CONTROL_POINT_NUM = 5
	END
	
	--IF NEXT CONTROL POINT = 6
	--GRAB ERRORS AND LOAD THEM TO TEMP TABLE FOR EXPORTING
	IF @CONTROL_POINT_NUM = 5
	BEGIN

		SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
		SET @ERROR_MSG_PLACEHOLDER1 = 'ATTEMPT TO GRAB AND LOAD'
		SET @ERROR_MSG_PLACEHOLDER2 = 'NEW ERROR RECORDS'

		DECLARE @NEW_ERROR_SEQUENCE_NO int
		SET @NEW_ERROR_SEQUENCE_NO = @ERROR_SEQUENCE_NO + 1
		
		IF @PREPROCESSOR = 'AP' AND @INTERFACE = 'FIWLR'
		BEGIN
			EXEC @ret_code = dbo.XX_ERROR_AP_FIWLR_GRAB_SP
				@in_status_record_num = @STATUS_RECORD_NUM,
				@in_error_sequence_no = @NEW_ERROR_SEQUENCE_NO,
				@OUT_SQLSERVER_ERROR_CODE = @SQLSERVER_ERROR_CODE OUTPUT,
				@OUT_STATUS_DESCRIPTION = @OUT_STATUS_DESCRIPTION OUTPUT


			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

			IF @ret_code <> 0 GOTO BL_ERROR_HANDLER

			EXEC @ret_code = dbo.XX_ERROR_AP_EXPORT_SP
				@in_status_record_num = @STATUS_RECORD_NUM,
				@in_error_sequence_no = @NEW_ERROR_SEQUENCE_NO,
				@OUT_SQLSERVER_ERROR_CODE = @SQLSERVER_ERROR_CODE OUTPUT,
				@OUT_STATUS_DESCRIPTION = @OUT_STATUS_DESCRIPTION OUTPUT


			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

			IF @ret_code <> 0 GOTO BL_ERROR_HANDLER
		END
		ELSE IF @PREPROCESSOR = 'JE' AND @INTERFACE = 'FIWLR'
		BEGIN
			EXEC @ret_code = dbo.XX_ERROR_JE_FIWLR_GRAB_SP
				@in_status_record_num = @STATUS_RECORD_NUM,
				@in_error_sequence_no = @NEW_ERROR_SEQUENCE_NO,
				@OUT_SQLSERVER_ERROR_CODE = @SQLSERVER_ERROR_CODE OUTPUT,
				@OUT_STATUS_DESCRIPTION = @OUT_STATUS_DESCRIPTION OUTPUT

			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

			IF @ret_code <> 0 GOTO BL_ERROR_HANDLER

			EXEC @ret_code = dbo.XX_ERROR_JE_EXPORT_SP
				@in_status_record_num = @STATUS_RECORD_NUM,
				@in_error_sequence_no = @NEW_ERROR_SEQUENCE_NO,
				@OUT_SQLSERVER_ERROR_CODE = @SQLSERVER_ERROR_CODE OUTPUT,
				@OUT_STATUS_DESCRIPTION = @OUT_STATUS_DESCRIPTION OUTPUT


			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

			IF @ret_code <> 0 GOTO BL_ERROR_HANDLER
		END
		ELSE IF @PREPROCESSOR = 'AP' AND @INTERFACE = 'PCLAIM'
		BEGIN
			EXEC @ret_code = dbo.XX_ERROR_AP_PCLAIM_GRAB_SP
				@in_status_record_num = @STATUS_RECORD_NUM,
				@in_error_sequence_no = @NEW_ERROR_SEQUENCE_NO,
				@OUT_SQLSERVER_ERROR_CODE = @SQLSERVER_ERROR_CODE OUTPUT,
				@OUT_STATUS_DESCRIPTION = @OUT_STATUS_DESCRIPTION OUTPUT


			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

			IF @ret_code <> 0 GOTO BL_ERROR_HANDLER

			EXEC @ret_code = dbo.XX_ERROR_AP_EXPORT_SP
				@in_status_record_num = @STATUS_RECORD_NUM,
				@in_error_sequence_no = @NEW_ERROR_SEQUENCE_NO,
				@OUT_SQLSERVER_ERROR_CODE = @SQLSERVER_ERROR_CODE OUTPUT,
				@OUT_STATUS_DESCRIPTION = @OUT_STATUS_DESCRIPTION OUTPUT


			SELECT @SQLSERVER_ERROR_CODE = @@ERROR
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

			IF @ret_code <> 0 GOTO BL_ERROR_HANDLER
		END

		UPDATE DBO.XX_ERROR_STATUS
		SET	CONTROL_PT = 6,
			TIME_STAMP = GETDATE(),
			STATUS = 'NEW MISCODES LOADED'
		WHERE 	STATUS_RECORD_NUM = @STATUS_RECORD_NUM
		AND	ERROR_SEQUENCE_NO = @ERROR_SEQUENCE_NO
		AND	PREPROCESSOR = @PREPROCESSOR 	
		AND 	INTERFACE = @INTERFACE
		
		SELECT @SQLSERVER_ERROR_CODE = @@ERROR
		IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
	
		SET @CONTROL_POINT_NUM = 6
	END

	--CONTROL POINT 7 IS THE DTS EXPORT
	IF (	@CONTROL_POINT_NUM = 6 
		AND @PREPROCESSOR = 'AP' 
		AND 0 = (SELECT COUNT(1) FROM XX_ERROR_AP_TEMP) )
	BEGIN
		UPDATE DBO.XX_ERROR_STATUS
		SET	CONTROL_PT = 7,
			TIME_STAMP = GETDATE(),
			STATUS = 'COMPLETED'
		WHERE 	STATUS_RECORD_NUM = @STATUS_RECORD_NUM
		AND	ERROR_SEQUENCE_NO = @ERROR_SEQUENCE_NO
		AND	PREPROCESSOR = @PREPROCESSOR 	
		AND 	INTERFACE = @INTERFACE
		
		SELECT @SQLSERVER_ERROR_CODE = @@ERROR
		IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
	END

	--CONTROL POINT 7 IS THE DTS EXPORT
	IF (	@CONTROL_POINT_NUM = 6 
		AND @PREPROCESSOR = 'JE' 
		AND 0 = (SELECT COUNT(1) FROM XX_ERROR_JE_TEMP) )
	BEGIN
		UPDATE DBO.XX_ERROR_STATUS
		SET	CONTROL_PT = 7,
			TIME_STAMP = GETDATE(),
			STATUS = 'COMPLETED'
		WHERE 	STATUS_RECORD_NUM = @STATUS_RECORD_NUM
		AND	ERROR_SEQUENCE_NO = @ERROR_SEQUENCE_NO
		AND	PREPROCESSOR = @PREPROCESSOR 	
		AND 	INTERFACE = @INTERFACE
		
		SELECT @SQLSERVER_ERROR_CODE = @@ERROR
		IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
	END
								
	
RETURN(0)

BL_ERROR_HANDLER:
	
	EXEC DBO.XX_ERROR_MSG_DETAIL
	   @IN_ERROR_CODE           = @IMAPS_ERROR_NUMBER,
	   @IN_DISPLAY_REQUESTED    = 1,
	   @IN_SQLSERVER_ERROR_CODE = @SQLSERVER_ERROR_CODE,
	   @IN_PLACEHOLDER_VALUE1   = @ERROR_MSG_PLACEHOLDER1,
	   @IN_PLACEHOLDER_VALUE2   = @ERROR_MSG_PLACEHOLDER2,
	   @IN_CALLING_OBJECT_NAME  = @SP_NAME,
	   @OUT_MSG_TEXT            = @OUT_STATUS_DESCRIPTION OUTPUT

	UPDATE DBO.XX_ERROR_STATUS
	SET 	STATUS = CAST(@ERROR_MSG_PLACEHOLDER1 + ' ' + @ERROR_MSG_PLACEHOLDER2 as varchar)
	WHERE 	STATUS_RECORD_NUM = @STATUS_RECORD_NUM
		AND	ERROR_SEQUENCE_NO = @ERROR_SEQUENCE_NO
		AND	PREPROCESSOR = @PREPROCESSOR 			
		AND 	INTERFACE = @INTERFACE
	
	PRINT @ERROR_MSG_PLACEHOLDER1 + ' ' + @ERROR_MSG_PLACEHOLDER2
	
	RETURN(1)

END










































GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


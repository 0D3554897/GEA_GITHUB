USE [IMAPSStg]
GO
/****** Object:  StoredProcedure [dbo].[XX_FIWLR_PROCESS_1MWWER_SP]    Script Date: 11/02/2007 09:01:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_PROCESS_1MWWER_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_PROCESS_1MWWER_SP]
GO


CREATE PROCEDURE [dbo].[XX_FIWLR_PROCESS_1MWWER_SP] (
@out_STATUS_DESCRIPTION sysname = NULL OUTPUT
)
AS
BEGIN
/*
1M Changes:

Re-optimized to mimic Miscode Reprocessing logic
Also includes adding new vendors to Costpoint

exec xx_fiwlr_process_1mwwer_sp
*/
DECLARE @SP_NAME                 sysname,
        @DIV_16_COMPANY_ID       varchar(10),
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
	@INTERFACE_NAME		 sysname,
	@ret_code		 int,
	@count			 int


--pull 1M WWER details from N16 table
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT INTO'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_FIWLR_BMSIW_WWER1M_EXTRACT_ARCHIVE'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	INSERT INTO XX_FIWLR_BMSIW_WWER1M_EXTRACT_ARCHIVE
	(	RPT_KEY,
		EXP_KEY,
		ACCOUNT_ID,
		CHRG_AMT,
		CHRG_CRNCY_CD,
		CHRG_MIN_NUM,
		CHRG_SUBMIN_NUM,
		CONTROL_COUNTRY_CD,
		CONTROL_GROUP_CD,
		EXP_CD,
		EXP_CHRG_DT,
		EXP_CHRG_NM,
		EXP_BEGIN_DT,
		EXP_EFFECTIVE_DT,
		EXP_END_DT,
		CREATED_TMS,
		CHRG_COUNTRY_CD,
		CHRG_DIV_CD,
		CHRG_FINDPT_ID,
		CHRG_LEDGER_CD,
		CHRG_MAJ_NUM,
		CNUM_ID,
		EMP_LAST_NM,
		EMP_INITS_NM,
		EMP_SER_NUM,
		EXP_WEEK_END_DT,
		INVOICE_TXT,
		PROCESSED_DT)
	SELECT
		RPT_KEY,
		EXP_KEY,
		ACCOUNT_ID,
		CHRG_AMT,
		CHRG_CRNCY_CD,
		CHRG_MIN_NUM,
		CHRG_SUBMIN_NUM,
		CONTROL_COUNTRY_CD,
		CONTROL_GROUP_CD,
		EXP_CD,
		EXP_CHRG_DT,
		EXP_CHRG_NM,
		EXP_BEGIN_DT,
		EXP_EFFECTIVE_DT,
		EXP_END_DT,
		CREATED_TMS,
		CHRG_COUNTRY_CD,
		CHRG_DIV_CD,
		CHRG_FINDPT_ID,
		CHRG_LEDGER_CD,
		CHRG_MAJ_NUM,
		CNUM_ID,
		EMP_LAST_NM,
		EMP_INITS_NM,
		EMP_SER_NUM,
		EXP_WEEK_END_DT,
		INVOICE_TXT,
		PROCESSED_DT
	FROM XX_FIWLR_BMSIW_WWERN16_EXTRACT wwer
	WHERE CHRG_DIV_CD='1M'
	AND	0 = (select count(1) from XX_FIWLR_BMSIW_WWER1M_EXTRACT_ARCHIVE where rpt_key=wwer.rpt_key and exp_key=wwer.exp_key)
	AND 1 = (select count(1) from XX_FIWLR_BMSIW_WWERN16_EXTRACT where rpt_key=wwer.rpt_key and exp_key=wwer.exp_key)

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'RE-INDEX'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_FIWLR_BMSIW_WWER1M_EXTRACT_ARCHIVE'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	dbcc dbreindex ('XX_FIWLR_BMSIW_WWER1M_EXTRACT_ARCHIVE', '', 80)

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


--apply 1M WWER details where needed
	DECLARE @REFERENCE1 char(6)
	SET @REFERENCE1='WWER1M'

	update xx_fiwlr_usdet_miscodes
	set proj_abbr_cd = (select top 1 account_id from xx_fiwlr_bmsiw_wwer1m_extract_archive where rpt_key=fiwlr.voucher_no and exp_key=cast(fiwlr.wwer_exp_key as int)),
		reference1=@REFERENCE1,
		ORG_ABBR_CD = NULL,
		ORG_ID = NULL
	from xx_fiwlr_usdet_miscodes fiwlr
	where division='1M'
	and source='005'
	and pag_cd is null

	--reset PAG
	update xx_fiwlr_usdet_miscodes
	set pag_cd=(select acct_grp_cd from imaps.deltek.proj where proj_abbrv_cd<>'' and proj_abbrv_cd=fiwlr.proj_abbr_cd)
	from xx_fiwlr_usdet_miscodes fiwlr
	where reference1=@REFERENCE1

--re-do account mapping for updates

			SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
			SET @ERROR_MSG_PLACEHOLDER1 = 'PERFORM FIWLR WWER - 1'
			SET @ERROR_MSG_PLACEHOLDER2 = 'ACCOUNT MAPPING'
		
			UPDATE 	FIWLR
			SET	FIWLR.ACCT_ID = MAP.ACCT_ID
			FROM 
			XX_FIWLR_USDET_MISCODES AS FIWLR
			INNER JOIN
			XX_CLS_IMAPS_ACCT_MAP as MAP
			ON (
			
				FIWLR.REFERENCE1 = @REFERENCE1

				--1M change (include division in mapping
				AND	FIWLR.DIVISION = MAP.DIVISION	

				AND	ISNULL(FIWLR.pag_cd, '') =  ISNULL(MAP.PAG, '')
				
				AND	FIWLR.major		>= (CASE 	WHEN MAP.major_1 = '***' 	THEN FIWLR.major 
										WHEN MAP.major_1 = ' '   	THEN FIWLR.major 
										ELSE MAP.major_1 
								   END )
				AND 	FIWLR.major		<= (CASE	WHEN MAP.major_2 = '***' 	THEN FIWLR.major 
										WHEN MAP.major_2 = ' '   	THEN FIWLR.major
										ELSE MAP.major_2 
								   END )
				AND	FIWLR.minor		>= (CASE  	WHEN MAP.minor_1 = '****' 	THEN FIWLR.minor
									  	WHEN MAP.minor_1 = ' ' 		THEN FIWLR.minor
									  	ELSE MAP.minor_1 
								   END )
				AND	FIWLR.minor 		<= (CASE  	WHEN MAP.minor_2 = '****' 	THEN FIWLR.minor
									  	WHEN MAP.minor_2 = ' ' 		THEN FIWLR.minor
									  	ELSE MAP.minor_2 
								   END)
				AND	FIWLR.subminor 	>= (CASE  	WHEN MAP.sub_minor_1 = '****' 	THEN FIWLR.subminor
									  	WHEN MAP.sub_minor_1 = ' ' 	THEN FIWLR.subminor -- Added by Veera on 11/22/2005 Defect : DEV0000269
									  	ELSE MAP.sub_minor_1 
								   END )
				AND	FIWLR.subminor 	<= (CASE  	WHEN MAP.sub_minor_2 = '****' 	THEN FIWLR.subminor
									  	WHEN MAP.sub_minor_2 = ' ' 	THEN FIWLR.subminor
									  	ELSE MAP.sub_minor_2 
								   END)
				AND	MAP.analysis_cd is null
				AND	MAP.val_non_val_fl is null
			)
					
			SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

			SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
			SET @ERROR_MSG_PLACEHOLDER1 = 'PERFORM FIWLR WWER - 2'
			SET @ERROR_MSG_PLACEHOLDER2 = 'ACCOUNT MAPPING'
		
			UPDATE 	FIWLR
			SET	FIWLR.ACCT_ID = MAP.ACCT_ID
			FROM 
			XX_FIWLR_USDET_MISCODES AS FIWLR
			INNER JOIN
			XX_CLS_IMAPS_ACCT_MAP as MAP
			ON (
			
				FIWLR.REFERENCE1 = @REFERENCE1

				--1M change (include division in mapping
				AND	FIWLR.DIVISION = MAP.DIVISION	
			
				AND	ISNULL(FIWLR.pag_cd, '') =  ISNULL(MAP.PAG, '')
				
				AND	FIWLR.major		>= (CASE 	WHEN MAP.major_1 = '***' 	THEN FIWLR.major 
										WHEN MAP.major_1 = ' '   	THEN FIWLR.major 
										ELSE MAP.major_1 
								   END )
				AND 	FIWLR.major		<= (CASE	WHEN MAP.major_2 = '***' 	THEN FIWLR.major 
										WHEN MAP.major_2 = ' '   	THEN FIWLR.major
										ELSE MAP.major_2 
								   END )
				AND	FIWLR.minor		>= (CASE  	WHEN MAP.minor_1 = '****' 	THEN FIWLR.minor
									  	WHEN MAP.minor_1 = ' ' 		THEN FIWLR.minor
									  	ELSE MAP.minor_1 
								   END )
				AND	FIWLR.minor 		<= (CASE  	WHEN MAP.minor_2 = '****' 	THEN FIWLR.minor
									  	WHEN MAP.minor_2 = ' ' 		THEN FIWLR.minor
									  	ELSE MAP.minor_2 
								   END)
				AND	FIWLR.subminor 	>= (CASE  	WHEN MAP.sub_minor_1 = '****' 	THEN FIWLR.subminor
									  	WHEN MAP.sub_minor_1 = ' ' 	THEN FIWLR.subminor -- Added by Veera on 11/22/2005 Defect : DEV0000269
									  	ELSE MAP.sub_minor_1 
								   END )
				AND	FIWLR.subminor 	<= (CASE  	WHEN MAP.sub_minor_2 = '****' 	THEN FIWLR.subminor
									  	WHEN MAP.sub_minor_2 = ' ' 	THEN FIWLR.subminor
									  	ELSE MAP.sub_minor_2 
								   END)
				AND	MAP.analysis_cd is null
				AND	FIWLR.val_nval_cd = MAP.val_non_val_fl
			)
					
			SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
			
			SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
			SET @ERROR_MSG_PLACEHOLDER1 = 'PERFORM FIWLR WWER - 3'
			SET @ERROR_MSG_PLACEHOLDER2 = 'ACCOUNT MAPPING'
		
			UPDATE 	FIWLR
			SET	FIWLR.ACCT_ID = MAP.ACCT_ID
			FROM 
			XX_FIWLR_USDET_MISCODES AS FIWLR
			INNER JOIN
			XX_CLS_IMAPS_ACCT_MAP as MAP
			ON (
			
				FIWLR.REFERENCE1 = @REFERENCE1

				--1M change (include division in mapping
				AND	FIWLR.DIVISION = MAP.DIVISION	
			
				AND	ISNULL(FIWLR.pag_cd, '') =  ISNULL(MAP.PAG, '')
				
				AND	FIWLR.major		>= (CASE 	WHEN MAP.major_1 = '***' 	THEN FIWLR.major 
										WHEN MAP.major_1 = ' '   	THEN FIWLR.major 
										ELSE MAP.major_1 
								   END )
				AND 	FIWLR.major		<= (CASE	WHEN MAP.major_2 = '***' 	THEN FIWLR.major 
										WHEN MAP.major_2 = ' '   	THEN FIWLR.major
										ELSE MAP.major_2 
								   END )
				AND	FIWLR.minor		>= (CASE  	WHEN MAP.minor_1 = '****' 	THEN FIWLR.minor
									  	WHEN MAP.minor_1 = ' ' 		THEN FIWLR.minor
									  	ELSE MAP.minor_1 
								   END )
				AND	FIWLR.minor 		<= (CASE  	WHEN MAP.minor_2 = '****' 	THEN FIWLR.minor
									  	WHEN MAP.minor_2 = ' ' 		THEN FIWLR.minor
									  	ELSE MAP.minor_2 
								   END)
				AND	FIWLR.subminor 	>= (CASE  	WHEN MAP.sub_minor_1 = '****' 	THEN FIWLR.subminor
									  	WHEN MAP.sub_minor_1 = ' ' 	THEN FIWLR.subminor -- Added by Veera on 11/22/2005 Defect : DEV0000269
									  	ELSE MAP.sub_minor_1 
								   END )
				AND	FIWLR.subminor 	<= (CASE  	WHEN MAP.sub_minor_2 = '****' 	THEN FIWLR.subminor
									  	WHEN MAP.sub_minor_2 = ' ' 	THEN FIWLR.subminor
									  	ELSE MAP.sub_minor_2 
								   END)
							
				AND	FIWLR.analysis_code = MAP.analysis_cd
				AND	MAP.val_non_val_fl is null
			)
					
			SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

			SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
			SET @ERROR_MSG_PLACEHOLDER1 = 'PERFORM FIWLR WWER - 4'
			SET @ERROR_MSG_PLACEHOLDER2 = 'ACCOUNT MAPPING'
		
			UPDATE 	FIWLR
			SET	FIWLR.ACCT_ID = MAP.ACCT_ID
			FROM 
			XX_FIWLR_USDET_MISCODES AS FIWLR
			INNER JOIN
			XX_CLS_IMAPS_ACCT_MAP as MAP
			ON (
			
				FIWLR.REFERENCE1 = @REFERENCE1

				--1M change (include division in mapping
				AND	FIWLR.DIVISION = MAP.DIVISION	
			
				AND	ISNULL(FIWLR.pag_cd, '') =  ISNULL(MAP.PAG, '')
				
				AND	FIWLR.major		>= (CASE 	WHEN MAP.major_1 = '***' 	THEN FIWLR.major 
										WHEN MAP.major_1 = ' '   	THEN FIWLR.major 
										ELSE MAP.major_1 
								   END )
				AND 	FIWLR.major		<= (CASE	WHEN MAP.major_2 = '***' 	THEN FIWLR.major 
										WHEN MAP.major_2 = ' '   	THEN FIWLR.major
										ELSE MAP.major_2 
								   END )
				AND	FIWLR.minor		>= (CASE  	WHEN MAP.minor_1 = '****' 	THEN FIWLR.minor
									  	WHEN MAP.minor_1 = ' ' 		THEN FIWLR.minor
									  	ELSE MAP.minor_1 
								   END )
				AND	FIWLR.minor 		<= (CASE  	WHEN MAP.minor_2 = '****' 	THEN FIWLR.minor
									  	WHEN MAP.minor_2 = ' ' 		THEN FIWLR.minor
									  	ELSE MAP.minor_2 
								   END)
				AND	FIWLR.subminor 	>= (CASE  	WHEN MAP.sub_minor_1 = '****' 	THEN FIWLR.subminor
									  	WHEN MAP.sub_minor_1 = ' ' 	THEN FIWLR.subminor -- Added by Veera on 11/22/2005 Defect : DEV0000269
									  	ELSE MAP.sub_minor_1 
								   END )
				AND	FIWLR.subminor 	<= (CASE  	WHEN MAP.sub_minor_2 = '****' 	THEN FIWLR.subminor
									  	WHEN MAP.sub_minor_2 = ' ' 	THEN FIWLR.subminor
									  	ELSE MAP.sub_minor_2 
								   END)
							
							
				AND	FIWLR.analysis_code = MAP.analysis_cd
				AND	FIWLR.val_nval_cd = MAP.val_non_val_fl
			)
					
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


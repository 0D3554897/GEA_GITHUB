USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CERIS_LOAD_STEP1_SP]    Script Date: 04/07/2017 10:14:41 ******/

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_R22_CERIS_LOAD_STEP1_SP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[XX_R22_CERIS_LOAD_STEP1_SP]
GO

USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CERIS_LOAD_STEP1_SP]    Script Date: 04/07/2017 10:14:41 ******/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[XX_R22_CERIS_LOAD_STEP1_SP] (
	@out_STATUS_DESCRIPTION sysname = NULL output
)

AS

/************************************************************************************************
 Procedure Name	: XX_R22_CERIS_LOAD_STEP1_SP  									 
 Created By		: KM
 Modified By    : George Alvarez									   								 
 Description    : File Load Checks and Initialization											 
 Date			: 2012-06-26; 2016-06-16			        									 
 Notes			: Steps primarily copied from CERIS code																		 
 Prerequisites	: 																		 
 Parameter(s)	: 																		 
	Input		:																		 
	Output		: Error Code and Error Description	
 Expected Status: At the successful end of this step, the XX_IMAPS_INT_STATUS.STATUS_CODE value = INITIATED.									 
 Tables Updated	: XX_IMAPS_INT_STATUS, 	XX_IMAPS_INT_CONTROL,
					XX_R22_CERIS_FILE_STG, XX_R22_Ceris_data_stg_arch
					header table			 
 Version		: 1.0																	 
 ************************************************************************************************
 Date		  Modified By			Description of change	  								 
 ----------   -------------  	   	------------------------    			  				 
 2012-06-26   KM   					Created Initial Version		
 2016-06-16   GEA                   Adapted for Workday	
 2017-03-23   gea                   CR9296 - delete missing records from previous failed runs this week							 
						 
CR9296 - gea - 4/25/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
 ***********************************************************************************************/


BEGIN

DECLARE	@SP_NAME         	 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
	@ret_code		 int,
	@count			 int,
	@last_STATUS_RECORD_NUM int


PRINT '' --CR9296 *~^
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_R22_CERIS_LOAD_STEP1_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9296 *~^
-- *~^
SET @SP_NAME = 'XX_R22_CERIS_LOAD_STEP1_SP'

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY CERIS R22 LOAD'
	SET @ERROR_MSG_PLACEHOLDER2 = 'IS NOT ALREADY IN PROGRESS'

	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	set @count = 1
	select @count = count(1)
	from XX_IMAPS_INT_STATUS
	where
	interface_name='CERIS_R22'
	and 
	STATUS_CODE not in ('COMPLETED', 'RESET')
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	IF @count <> 0 GOTO ERROR


	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'GET LAST STATUS_RECORD_NUM'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR ARCHIVE PURPOSES'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2
	
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 102 : XX_R22_CERIS_LOAD_STEP1_SP.sql '  --CR9296
 
	SELECT @last_STATUS_RECORD_NUM=isnull(MAX(STATUS_RECORD_NUM),0)
	FROM XX_IMAPS_INT_STATUS
	WHERE interface_name='CERIS_R22'

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'ARCHIVE TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'xx_r22_ceris_file_stg'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2
	
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 119 : XX_R22_CERIS_LOAD_STEP1_SP.sql '  --CR9296
 
	insert into XX_R22_Ceris_file_stg_archival
	(STATUS_RECORD_NUM,
			EMPL_ID,
			LNAME,
			FNAME,
			NAME_INITIALS,
			HIRE_EFF_DT,
			IBM_START_DT,
			TERM_DT,
			MGR_SERIAL_NUM,
			MGR_LNAME,
			MGR_INITIALS,
			JOB_FAM,
			JOB_FAM_DT,
			SAL_BAND,
			LVL_DT_1,
			DIVISION,
			DIVISION_START_DT,
			DEPT,
			DEPT_START_DT,
			DEPT_SUF_DT,
			FLSA_STAT,
			EXEMPT_DT,
			POS_CODE,
			POS_DESC,
			POS_DT,
			REG_TEMP,
			STAT3,
			EMPL_STAT3_DT,
			STATUS,
			EMPL_STAT_DT,
			STD_HRS,
			WORK_SCHD_DT,
			LOA_BEG_DT,
			LOA_END_DT,
			LOA_TYPE,
			LVL_SUFFIX,
			DIVISION_FROM,
			WORK_OFF,
			CURR_DIV_FUNC_CODE,
			CURR_REP_LVL_CODE,
			PREV_DIV_FUNC_CODE,
			PREV_REP_LVL_CODE,
			MGR2_LNAME,
			MGR2_INITIALS,
			MGR3_LNAME,
			MGR3_INITIALS,
			HIRE_TYPE,
			HIRE_PRGM,
			SEPRSN,
			DEPT_FROM,
			VACELGD,
			CMPLN,
			BLDG_ID,
			DEPT_SHIFT_DT,
			DEPT_SHIFT_1,
			MGR_FLAG,
			SALARY,
			SALARY_DT,
			REFERENCE1,
			REFERENCE2,
			REFERENCE3,
			REFERENCE4,
			REFERENCE5,
			CREATION_DATE,
			CREATED_BY,
			UPDATE_DATE,
			UPDATED_BY,
			ASTYP,
			ASNTYP)
	select @last_STATUS_RECORD_NUM,
		EMPL_ID,
		LNAME,
		FNAME,
		NAME_INITIALS,
		HIRE_EFF_DT,
		IBM_START_DT,
		TERM_DT,
		MGR_SERIAL_NUM,
		MGR_LNAME,
		MGR_INITIALS,
		JOB_FAM,
		JOB_FAM_DT,
		SAL_BAND,
		LVL_DT_1,
		DIVISION,
		DIVISION_START_DT,
		DEPT,
		DEPT_START_DT,
		DEPT_SUF_DT,
		FLSA_STAT,
		EXEMPT_DT,
		POS_CODE,
		POS_DESC,
		POS_DT,
		REG_TEMP,
		STAT3,
		EMPL_STAT3_DT,
		STATUS,
		EMPL_STAT_DT,
		STD_HRS,
		WORK_SCHD_DT,
		LOA_BEG_DT,
		LOA_END_DT,
		LOA_TYPE,
		LVL_SUFFIX,
		DIVISION_FROM,
		WORK_OFF,
		CURR_DIV_FUNC_CODE,
		CURR_REP_LVL_CODE,
		PREV_DIV_FUNC_CODE,
		PREV_REP_LVL_CODE,
		MGR2_LNAME,
		MGR2_INITIALS,
		MGR3_LNAME,
		MGR3_INITIALS,
		HIRE_TYPE,
		HIRE_PRGM,
		SEPRSN,
		DEPT_FROM,
		VACELGD,
		CMPLN,
		BLDG_ID,
		DEPT_SHIFT_DT,
		DEPT_SHIFT_1,
		MGR_FLAG,
		SALARY,
		SALARY_DT,
		REFERENCE1,
		REFERENCE2,
		REFERENCE3,
		REFERENCE4,
		REFERENCE5,
		CREATION_DATE,
		CREATED_BY,
		UPDATE_DATE,
		UPDATED_BY,
		ASTYP,
		ASNTYP
	from XX_R22_Ceris_file_stg


	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'ARCHIVE TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'HEADER '
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2
	
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 274 : XX_R22_CERIS_LOAD_STEP1_SP.sql '  --CR9296
 
	insert into XX_R22_Ceris_data_hdr_stg_arch
	(STATUS_RECORD_NUM,
		REC_TYPE,
		LAB1,
		RUN_DATE,
		FIL2,
		RUN_TIME,
		LAB3,
		RECS_OUT,
		LAB4,
		SEQ_OUT,
		LAB5,
		HASH,
		LAB6,
		IBM_CLASSIFICATION,
		DMEM_AS_OF_DATE,
		LAB7,
		EMP_FILENAME,
		LAB8,
		WKL_FILENAME,
		CREATION_DATE,
		CREATED_BY,
	ARCHIVE_DATE,
	ARCHIVED_BY
	)
	select @last_STATUS_RECORD_NUM,
			REC_TYPE,
			LAB1,
			RUN_DATE,
			FIL2,
			RUN_TIME,
			LAB3,
			RECS_OUT,
			LAB4,
			SEQ_OUT,
			LAB5,
			HASH,
			LAB6,
			IBM_CLASSIFICATION,
			DMEM_AS_OF_DATE,
			LAB7,
			EMP_FILENAME,
			LAB8,
			WKL_FILENAME,
			CREATION_DATE,
			CREATED_BY,	
			getdate() as ARCHIVE_DATE,
			suser_sname() as ARCHIVED_BY
	from XX_R22_Ceris_data_hdr_stg

-- START CR9296
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'DELETE MISSING DATA RECORDS FROM'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_R22_CERIS_DATA_STG_MISSING'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	DELETE FROM xx_r22_ceris_data_stg_missing where CREATED_BY = 'MISSING'

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
-- END CR9296

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'TRUNCATE TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_R22_CERIS_FILE_STG'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 348 : XX_R22_CERIS_LOAD_STEP1_SP.sql '  --CR9296
 
	TRUNCATE TABLE XX_R22_CERIS_FILE_STG

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'TRUNCATE TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_R22_Ceris_data_hdr_stg'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 361 : XX_R22_CERIS_LOAD_STEP1_SP.sql '  --CR9296
 
	truncate table XX_R22_Ceris_data_hdr_stg

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INITIALIZE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_IMAPS_INT_STATUS'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	DECLARE 
        @IN_SOURCE_SYSOWNER             varchar(300),
        @OUT_DESTINATION_SYSOWNER       varchar(300),
		@current_STATUS_RECORD_NUM int

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 381 : XX_R22_CERIS_LOAD_STEP1_SP.sql '  --CR9296
 
	SELECT @IN_SOURCE_SYSOWNER=PARAMETER_VALUE
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='CERIS_R22'
	AND PARAMETER_NAME='IN_SOURCE_SYSOWNER'

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 389 : XX_R22_CERIS_LOAD_STEP1_SP.sql '  --CR9296
 
	SELECT @OUT_DESTINATION_SYSOWNER=PARAMETER_VALUE
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='CERIS_R22'
	AND PARAMETER_NAME='OUT_DESTINATION_SYSOWNER'

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 397 : XX_R22_CERIS_LOAD_STEP1_SP.sql '  --CR9296
 
	EXEC @ret_code = dbo.XX_INSERT_INT_STATUS_RECORD
         @in_IMAPS_db_name      = 'IMAPSSTG',
         @in_IMAPS_table_owner  = 'dbo',
         @in_int_name           = 'CERIS_R22',
         @in_int_type           = 'I',
         @in_int_source_sys     = 'WORKDAY',
         @in_int_dest_sys       = 'IMAPS',
		 @in_data_fname         = 'N/A',
         @in_int_source_owner   = @IN_SOURCE_SYSOWNER,
         @in_int_dest_owner     = @OUT_DESTINATION_SYSOWNER,
         @out_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM OUTPUT


	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	IF @ret_code <> 0 GOTO ERROR

/* not needed
	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_IMAPS_INT_CONTROL'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 425 : XX_R22_CERIS_LOAD_STEP1_SP.sql '  --CR9296
 
      EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
         @in_int_ctrl_pt_num     = 1,
         @in_lookup_domain_const = 'LD_CERIS_R_INTERFACE_CTRL_PT',
         @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	IF @ret_code <> 0 GOTO ERROR
	
*/


PRINT 'END XX_R22_CERIS_LOAD_STEP1_SP '

PRINT '' --CR9296 *~^
PRINT '*~^*************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF  XX_R22_CERIS_LOAD_STEP1_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9296 *~^
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

GO



USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_LOAD_STEP1_SP]    Script Date: 03/24/2017 11:36:07 ******/


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_CERIS_LOAD_STEP1_SP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[XX_CERIS_LOAD_STEP1_SP]
GO

USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_LOAD_STEP1_SP]    Script Date: 03/24/2017 11:36:07 ******/


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[XX_CERIS_LOAD_STEP1_SP] (
	@out_STATUS_DESCRIPTION sysname = NULL output
)

AS

/************************************************************************************************
 Procedure Name	: XX_CERIS_LOAD_STEP1_SP  									 
 Created By		: KM									   								 
 Description    : File Load Checks and Initialization											 
 Date			: 2012-06-26				        									 
 Notes			:																		 
 Prerequisites	: 																		 
 Parameter(s)	: 																		 
	Input		:																		 
	Output		: Error Code and Error Description										 
 Tables Updated	: XX_IMAPS_INT_STATUS, 	XX_IMAPS_INT_CONTROL,
					xx_ceris_data_stg, xx_ceris_data_stg_arch
					header table			 
 Version		: 1.0																	 
 ************************************************************************************************
 Date		  Modified By			Description of change	  								 
 ----------   -------------  	   	------------------------    			  				 
 2012-06-26   KM   					Created Initial Version		
 2017-03-23   gea                   CR9295 - delete missing records from previous failed runs this week							 

CR9295 - gea - 4/13/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
 ***********************************************************************************************/


BEGIN

 
 
PRINT '' -- *~^ CR9295
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        BEGIN XX_CERIS_LOAD_STEP1_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' -- *~^ CR9295
 
DECLARE	@SP_NAME         	 sysname,

        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@ret_code		 int,
		@count			 int,
		@last_STATUS_RECORD_NUM int



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY CERIS_LOAD'
	SET @ERROR_MSG_PLACEHOLDER2 = 'IS NOT ALREADY IN PROGRESS'

	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	set @count = 1
	select @count = count(1)
	from XX_IMAPS_INT_STATUS
	where
	interface_name='CERIS_LOAD'
	and 
	STATUS_CODE not in ('COMPLETED', 'RESET')
	
 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	IF @count <> 0 GOTO ERROR


	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'GET LAST STATUS_RECORD_NUM'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR ARCHIVE PURPOSES'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2
	
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 108 : XX_CERIS_LOAD_STEP1_SP.sql '  --CR9295
 
	SELECT @last_STATUS_RECORD_NUM=isnull(MAX(STATUS_RECORD_NUM),0)
	FROM XX_IMAPS_INT_STATUS
	WHERE interface_name='CERIS_LOAD'

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'ARCHIVE TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'xx_ceris_data_stg'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2
	
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 129 : XX_CERIS_LOAD_STEP1_SP.sql '  --CR9295
 
	insert into xx_ceris_data_stg_arch
	(STATUS_RECORD_NUM,
		REC_TYPE,
		SERIAL,
		HIRE_DATE_EFF,
		HIRE_DATE_SRD,
		SEP_DATE,
		DEPT_MGR_SER_1,
		DEPT_MGR_NAME_LAST,
		DEPT_MGR_NAME_INIT,
		JOB_FAMILY_1,
		JOB_FAMILY_DATE_1,
		LEVEL_PREFIX_1,
		LEVEL_SUFFIX_1,
		LVL_DATE_1,
		DIVISION_1,
		DIVISION_2,
		DIV_DATE,
		DEPT_PLUS_SFX,
		DEPT_DATE,
		DEPT_SUF_DATE,
		EX_NE_OUT,
		EXEMPT_DATE,
		POS_CODE_1,
		JOB_TITLE,
		POS_DATE_1,
		EMPL_STAT_1ST,
		EMPL_STAT_3RD,
		EMPL_STAT3_DATE,
		EMPL_STAT_2ND,
		EMPL_STAT_DATE,
		WORK_SCHD,
		WORK_SCHD_DATE,
		SET_ID,
		LOC_WORK_1,
		LOC_WORK_ST,
		LOC_WORK_DTE_1,
		TBWKL_CITY,
		SALARY,
		SAL_CHG_DTE_1,
		SAL_RTE_CDE,
		SAL_BASE,
		SAL_MO_OUT,
		NAME_LAST_MIXED,
		NAME_FIRST_MIXED,
		NAME_INIT,
		CREATION_DATE,
		CREATED_BY,
		ARCHIVE_DATE,
		ARCHIVED_BY)
	select @last_STATUS_RECORD_NUM,
			REC_TYPE,
			SERIAL,
			HIRE_DATE_EFF,
			HIRE_DATE_SRD,
			SEP_DATE,
			DEPT_MGR_SER_1,
			DEPT_MGR_NAME_LAST,
			DEPT_MGR_NAME_INIT,
			JOB_FAMILY_1,
			JOB_FAMILY_DATE_1,
			LEVEL_PREFIX_1,
			LEVEL_SUFFIX_1,
			LVL_DATE_1,
			DIVISION_1,
			DIVISION_2,
			DIV_DATE,
			DEPT_PLUS_SFX,
			DEPT_DATE,
			DEPT_SUF_DATE,
			EX_NE_OUT,
			EXEMPT_DATE,
			POS_CODE_1,
			JOB_TITLE,
			POS_DATE_1,
			EMPL_STAT_1ST,
			EMPL_STAT_3RD,
			EMPL_STAT3_DATE,
			EMPL_STAT_2ND,
			EMPL_STAT_DATE,
			WORK_SCHD,
			WORK_SCHD_DATE,
			SET_ID,
			LOC_WORK_1,
			LOC_WORK_ST,
			LOC_WORK_DTE_1,
			TBWKL_CITY,
			SALARY,
			SAL_CHG_DTE_1,
			SAL_RTE_CDE,
			SAL_BASE,
			SAL_MO_OUT,
			NAME_LAST_MIXED,
			NAME_FIRST_MIXED,
			NAME_INIT,
			CREATION_DATE,
			CREATED_BY,
			getdate() as ARCHIVE_DATE,
			suser_sname() as ARCHIVED_BY
	from xx_ceris_data_stg


 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'ARCHIVE TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'HEADER '
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2
	
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 247 : XX_CERIS_LOAD_STEP1_SP.sql '  --CR9295
 
	insert into xx_ceris_data_hdr_stg_arch
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
	from xx_ceris_data_hdr_stg

 
 
-- START CR9295
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'DELETE MISSING DATA RECORDS FROM'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_CERIS_DATA_STG_MISSING'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	DELETE FROM xx_ceris_data_stg_missing where CREATED_BY = 'MISSING'

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
-- END CR9295

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'TRUNCATE TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'xx_ceris_data_stg'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 325 : XX_CERIS_LOAD_STEP1_SP.sql '  --CR9295
 
	TRUNCATE TABLE xx_ceris_data_stg

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'TRUNCATE TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'xx_ceris_data_hdr_stg'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 342 : XX_CERIS_LOAD_STEP1_SP.sql '  --CR9295
 
	truncate table xx_ceris_data_hdr_stg

 
 
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

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 366 : XX_CERIS_LOAD_STEP1_SP.sql '  --CR9295
 
	SELECT @IN_SOURCE_SYSOWNER=PARAMETER_VALUE
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='CERIS_LOAD'
	AND PARAMETER_NAME='IN_SOURCE_SYSOWNER'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 376 : XX_CERIS_LOAD_STEP1_SP.sql '  --CR9295
 
	SELECT @OUT_DESTINATION_SYSOWNER=PARAMETER_VALUE
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='CERIS_LOAD'
	AND PARAMETER_NAME='OUT_DESTINATION_SYSOWNER'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 386 : XX_CERIS_LOAD_STEP1_SP.sql '  --CR9295
 
	EXEC @ret_code = dbo.XX_INSERT_INT_STATUS_RECORD
         @in_IMAPS_db_name      = 'IMAPSSTG',
         @in_IMAPS_table_owner  = 'dbo',
         @in_int_name           = 'CERIS_LOAD',
         @in_int_type           = 'I',
         @in_int_source_sys     = 'CERIS',
         @in_int_dest_sys       = 'IMAPS',
		 @in_data_fname         = 'N/A',
         @in_int_source_owner   = @IN_SOURCE_SYSOWNER,
         @in_int_dest_owner     = @OUT_DESTINATION_SYSOWNER,
         @out_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM OUTPUT


 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	IF @ret_code <> 0 GOTO ERROR

PRINT ' '
PRINT 'STATUS RECORD NUMBER FOR THIS RUN IS ' + CAST(@current_STATUS_RECORD_NUM as varchar)
PRINT ' ' 
	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_IMAPS_INT_CONTROL'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 419 : XX_CERIS_LOAD_STEP1_SP.sql '  --CR9295
 
      EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
         @in_int_ctrl_pt_num     = 1,
         @in_lookup_domain_const = 'LD_CERIS_LOAD_CTRL_PT',
         @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	IF @ret_code <> 0 GOTO ERROR
	


 
PRINT '' -- *~^ CR9295
PRINT '*~^*************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF  XX_CERIS_LOAD_STEP1_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' -- *~^ CR9295
 
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



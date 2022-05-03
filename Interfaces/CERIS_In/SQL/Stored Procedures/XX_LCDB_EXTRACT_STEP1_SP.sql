USE [IMAPSStg]
GO
/****** Object:  StoredProcedure [dbo].[XX_LCDB_EXTRACT_STEP1_SP]  ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_LCDB_EXTRACT_STEP1_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_LCDB_EXTRACT_STEP1_SP]
GO

CREATE PROCEDURE [dbo].[XX_LCDB_EXTRACT_STEP1_SP] (
@out_STATUS_DESCRIPTION sysname = NULL
)

AS

/************************************************************************************************
 Procedure Name	: XX_LCDB_EXTRACT_STEP1_SP  									 
 Created By		: KM									   								 
 Description    : ETL Checks and Initialization											 
 Date			: 2012-06-26				        									 
 Notes			:																		 
 Prerequisites	: 																		 
 Parameter(s)	: 																		 
	Input		:																		 
	Output		: Error Code and Error Description										 
 Tables Updated	: XX_IMAPS_INT_STATUS, 	XX_IMAPS_INT_CONTROL,
					xx_ceris_lcdb_codes_stg, xx_ceris_lcdb_codes_stg_arch
					xx_ceris_lcdb_empl_assignments_stg, xx_ceris_lcdb_empl_assignments_stg_arch						 
 Version		: 1.0																	 
 ************************************************************************************************
 Date		  Modified By			Description of change	  								 
 ----------   -------------  	   	------------------------    			  				 
 2012-06-26   KM   					Created Initial Version									 
 ***********************************************************************************************/

BEGIN

PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 42 : XX_LCDB_EXTRACT_STEP1_SP.sql '
 
DECLARE	@SP_NAME         	 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@ret_code		 int,
		@count			 int,
		@last_STATUS_RECORD_NUM int

	SET @SP_NAME = 'XX_LCDB_EXTRACT_STEP1_SP'

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY LCDB_EXTRACT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'IS NOT ALREADY IN PROGRESS'

	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	set @count = 1
	select @count = count(1)
	from XX_IMAPS_INT_STATUS
	where
	interface_name='LCDB_EXTRACT'
	and 
	STATUS_CODE not in ('COMPLETED', 'RESET')
	
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 70 : XX_LCDB_EXTRACT_STEP1_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	IF @count <> 0 GOTO ERROR


	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'GET LAST STATUS_RECORD_NUM'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR ARCHIVE PURPOSES'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2
	
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 85 : XX_LCDB_EXTRACT_STEP1_SP.sql '
 
	SELECT @last_STATUS_RECORD_NUM=isnull(MAX(STATUS_RECORD_NUM),0)
	FROM XX_IMAPS_INT_STATUS
	WHERE interface_name='LCDB_EXTRACT'

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 92 : XX_LCDB_EXTRACT_STEP1_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'ARCHIVE TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'xx_ceris_lcdb_codes_stg'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2
	
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 105 : XX_LCDB_EXTRACT_STEP1_SP.sql '
 
	insert into xx_ceris_lcdb_codes_stg_arch
	(STATUS_RECORD_NUM,
		GLC_RecNo,
		GLC_Code,
		GLC_Title,		
		GLC_Short_Title,
		TYPE_DESC,
		LOCA_DESC,
		GRAD_DESC,
		CATE_DESC,
		CREATION_DATE,
		CREATED_BY,
		ARCHIVE_DATE,
		ARCHIVED_BY)
	select @last_STATUS_RECORD_NUM,
			GLC_RecNo,
			GLC_Code,
			GLC_Title,		
			GLC_Short_Title,
			TYPE_DESC,
			LOCA_DESC,
			GRAD_DESC,
			CATE_DESC,
			CREATION_DATE,
			CREATED_BY,
			getdate() as ARCHIVE_DATE,
			suser_sname() as ARCHIVED_BY
	from xx_ceris_lcdb_codes_stg


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 138 : XX_LCDB_EXTRACT_STEP1_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'ARCHIVE TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'xx_ceris_lcdb_empl_assignments_stg'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2
	
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 151 : XX_LCDB_EXTRACT_STEP1_SP.sql '
 
	insert into xx_ceris_lcdb_empl_assignments_stg_arch
	(STATUS_RECORD_NUM,
		Emp_RecNo,
		SerialNo,
		StatusCode,
		Emp_StartDate,
		Emp_EndDate,
		GLC_RecNo,
		GLC_Code,
		EmpGLC_StartDate,
		EmpGLC_EndDate,
		CREATION_DATE,
		CREATED_BY,
		ARCHIVE_DATE,
		ARCHIVED_BY)
	select @last_STATUS_RECORD_NUM,
			Emp_RecNo,
			SerialNo,
			StatusCode,
			Emp_StartDate,
			Emp_EndDate,
			GLC_RecNo,
			GLC_Code,
			EmpGLC_StartDate,
			EmpGLC_EndDate,
			CREATION_DATE,
			CREATED_BY,
			getdate() as ARCHIVE_DATE,
			suser_sname() as ARCHIVED_BY
	from xx_ceris_lcdb_empl_assignments_stg

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 185 : XX_LCDB_EXTRACT_STEP1_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR





	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'TRUNCATE TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'xx_ceris_lcdb_codes_stg'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	TRUNCATE TABLE xx_ceris_lcdb_codes_stg

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 203 : XX_LCDB_EXTRACT_STEP1_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'TRUNCATE TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'xx_ceris_lcdb_empl_assignments_stg'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	TRUNCATE TABLE xx_ceris_lcdb_empl_assignments_stg

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 216 : XX_LCDB_EXTRACT_STEP1_SP.sql '
 
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

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 235 : XX_LCDB_EXTRACT_STEP1_SP.sql '
 
	SELECT @IN_SOURCE_SYSOWNER=PARAMETER_VALUE
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='LCDB_EXTRACT'
	AND PARAMETER_NAME='IN_SOURCE_SYSOWNER'

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 243 : XX_LCDB_EXTRACT_STEP1_SP.sql '
 
	SELECT @OUT_DESTINATION_SYSOWNER=PARAMETER_VALUE
	FROM XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD='LCDB_EXTRACT'
	AND PARAMETER_NAME='OUT_DESTINATION_SYSOWNER'

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 251 : XX_LCDB_EXTRACT_STEP1_SP.sql '
 
	EXEC @ret_code = dbo.XX_INSERT_INT_STATUS_RECORD
         @in_IMAPS_db_name      = 'IMAPSSTG',
         @in_IMAPS_table_owner  = 'dbo',
         @in_int_name           = 'LCDB_EXTRACT',
         @in_int_type           = 'I',
         @in_int_source_sys     = 'LCDB',
         @in_int_dest_sys       = 'IMAPS',
		 @in_data_fname         = 'N/A',
         @in_int_source_owner   = @IN_SOURCE_SYSOWNER,
         @in_int_dest_owner     = @OUT_DESTINATION_SYSOWNER,
         @out_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM OUTPUT


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 267 : XX_LCDB_EXTRACT_STEP1_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	IF @ret_code <> 0 GOTO ERROR


	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_IMAPS_INT_CONTROL'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 282 : XX_LCDB_EXTRACT_STEP1_SP.sql '
 
      EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
         @in_int_ctrl_pt_num     = 1,
         @in_lookup_domain_const = 'LD_LCDB_EXTRACT_CTRL_PT',
         @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM

-- PRINT convert(varchar, current_timestamp, 21) + ': WORKDAY - current status record number ' + @current_STATUS_RECORD_NUM
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 290 : XX_LCDB_EXTRACT_STEP1_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	IF @ret_code <> 0 GOTO ERROR
	


RETURN 0

ERROR:

PRINT @out_STATUS_DESCRIPTION

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 306 : XX_LCDB_EXTRACT_STEP1_SP.sql '
 
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

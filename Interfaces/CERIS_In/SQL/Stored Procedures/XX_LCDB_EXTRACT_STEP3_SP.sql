USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_LCDB_EXTRACT_STEP3_SP]  ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_LCDB_EXTRACT_STEP3_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_LCDB_EXTRACT_STEP3_SP]
GO

CREATE PROCEDURE [dbo].[XX_LCDB_EXTRACT_STEP3_SP] (
@out_STATUS_DESCRIPTION sysname = NULL
)

AS

/************************************************************************************************
Procedure Name	: XX_LCDB_EXTRACT_STEP3_SP  									 
Created By		: KM									   								 
Description    	: Extract Checks and Status Update											 
Date			: 2012-06-26				        									 
Notes			:																		 
Prerequisites	: Step 2 is the SSIS package and it should run before this				 
Parameter(s)	: 																		 
	Input		:																		 
	Output		: Error Code and Error Description						 
 Tables Updated	: XX_IMAPS_INT_STATUS, 	XX_IMAPS_INT_CONTROL									 
Version			: 1.0																	 
************************************************************************************************
Date		Modified By			Description of change	  								 
----------   -------------  	------------------------    			  				 
2012-06-26   KM   				Created Initial Version		
2013-01-15   KM   				CR5782							 
************************************************************************************************/

BEGIN

 
DECLARE	@SP_NAME         	 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@ret_code		 int,
		@count			 int,
		@current_STATUS_RECORD_NUM int

	SET @SP_NAME = 'XX_LCDB_EXTRACT_STEP3_SP'
	set @count = 1



	--1
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'FIND STATUS_RECORD_NUM'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR EXTRACT'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 63 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	select @count = count(1)
	from XX_IMAPS_INT_STATUS
	where
	interface_name='LCDB_EXTRACT'
	and 
	STATUS_CODE not in ('COMPLETED', 'RESET')


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 74 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @count <> 1 GOTO ERROR

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 81 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	select @current_STATUS_RECORD_NUM = STATUS_RECORD_NUM
	from XX_IMAPS_INT_STATUS
	where
	interface_name='LCDB_EXTRACT'
	and 
	STATUS_CODE not in ('COMPLETED', 'RESET')


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 92 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @current_STATUS_RECORD_NUM IS NULL GOTO ERROR


	--2
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY SSIS'
	SET @ERROR_MSG_PLACEHOLDER2 = 'EXECUTION'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 106 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	SELECT @count = COUNT(1)
	FROM xx_ceris_lcdb_codes_stg

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 112 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @count <= 1 GOTO ERROR

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 119 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	SELECT @count = COUNT(1)
	FROM xx_ceris_lcdb_empl_assignments_stg

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 125 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @count <= 1 GOTO ERROR



	--BEGIN CR5782
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'CR5782 EmpGLC_StartDate'
	SET @ERROR_MSG_PLACEHOLDER2 = 'UPDATE HOURS:MINS:SECS TO 0'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 140 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	UPDATE xx_ceris_lcdb_empl_assignments_stg
	set EmpGLC_StartDate=cast(convert(char(10),EmpGLC_StartDate,120) as datetime)
	where EmpGLC_StartDate<>cast(convert(char(10),EmpGLC_StartDate,120) as datetime)
	--just in case Larry changes the view again without telling us

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 148 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	--END CR5782


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY'
	SET @ERROR_MSG_PLACEHOLDER2 = 'NO DUPES'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 161 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	select GLC_Code, count(1)
	from xx_ceris_lcdb_codes_stg
	group by GLC_Code
	having count(1) >1

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 169 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	SELECT @count = @@ROWCOUNT

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 174 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @count <> 0 GOTO ERROR


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 182 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	select SerialNo, count(1)
	from xx_ceris_lcdb_empl_assignments_stg
	group by SerialNo
	having count(1) >1

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 190 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	SELECT @count = @@ROWCOUNT

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 195 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @count <> 0 GOTO ERROR



	--3
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE XX_IMAPS_INT_STATUS'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH CONTROL TOTALS'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 211 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	UPDATE XX_IMAPS_INT_STATUS
	SET 
	MODIFIED_BY = suser_name(),
	MODIFIED_DATE = current_timestamp,
	RECORD_COUNT_INITIAL = (SELECT count(1) FROM xx_ceris_lcdb_codes_stg),
	RECORD_COUNT_SUCCESS = (SELECT count(1) FROM xx_ceris_lcdb_codes_stg),
	RECORD_COUNT_ERROR=0,
	AMOUNT_INPUT= (SELECT count(1) FROM xx_ceris_lcdb_empl_assignments_stg),
	AMOUNT_PROCESSED= (SELECT count(1) FROM xx_ceris_lcdb_empl_assignments_stg),
	AMOUNT_FAILED=0
	WHERE 
	STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 227 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_IMAPS_INT_CONTROL'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 241 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
      EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
         @in_int_ctrl_pt_num     = 2,
         @in_lookup_domain_const = 'LD_LCDB_EXTRACT_CTRL_PT',
         @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 249 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	IF @ret_code <> 0 GOTO ERROR




 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 260 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
	   @in_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM,
	   @in_STATUS_CODE       = 'COMPLETED'

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 267 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @ret_code <> 0 GOTO ERROR

	-- Create e-mail data to be used by the PORT application to send e-mail to interface stakeholders
	EXEC @ret_code = dbo.XX_SEND_STATUS_MAIL_SP
	   @in_StatusRecordNum = @current_STATUS_RECORD_NUM

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 278 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @ret_code <> 0 GOTO ERROR
	



RETURN 0

ERROR:

PRINT @out_STATUS_DESCRIPTION

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 294 : XX_LCDB_EXTRACT_STEP3_SP.sql '
 
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

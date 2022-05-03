USE [IMAPSStg]
GO


/****** Object:  StoredProcedure [dbo].[XX_FIWLR_BMSIW_WWERN16_LOAD_LATEDOU_SP]  ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_BMSIW_WWERN16_LOAD_LATEDOU_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_BMSIW_WWERN16_LOAD_LATEDOU_SP]
GO

CREATE PROCEDURE [dbo].[XX_FIWLR_BMSIW_WWERN16_LOAD_LATEDOU_SP] (
@out_STATUS_DESCRIPTION sysname = NULL
)

AS

/************************************************************************************************
Procedure Name	: XX_FIWLR_BMSIW_WWERN16_LOAD_LATEDOU_SP  									 
Created By		: KM									   								 
Description    	: ETL Checks and Initialization											 
Date			: 2009-07-12				        									 
Notes			:																		 
Prerequisites	: Step 2 is the SSIS package and it should run before this				 
Parameter(s)	: 																		 
	Input		:																		 
	Output		: Error Code and Error Description									 
Tables Updated	: XX_FIWLR_WWERN16														 
Tables Updated	: XX_FIWLR_WWERN16_CONTROL												 
Tables Updated	: XX_PROCESSING_PARAMETERS											 
Tables Updated	: XX_FIWLR_BMSIW_WWERN16_LATEDOU											 
Version			: 1.0																	 
************************************************************************************************
Date		Modified By			Description of change	  								 
----------   -------------  	------------------------    			  				 
2009-07-12   KM   				Created Initial Version									 
************************************************************************************************/

BEGIN

 
DECLARE	@SP_NAME         	 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@ret_code		 int,
		@count			 int,
		@STATUS_ROW_ID int

	SET @SP_NAME = 'XX_FIWLR_BMSIW_WWERN16_LOAD_LATEDOU_SP'
	set @count = 1

	--0
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY FIWLR INTERFACE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'IS NOT RUNNING'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	SELECT @count = COUNT(1)
	FROM XX_IMAPS_INT_STATUS
	WHERE INTERFACE_NAME='FIWLR'
	AND STATUS_CODE <> 'COMPLETED'

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @count <> 0 GOTO ERROR



	--1
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY FIWLR_BMSIW_WWERN16_ETL IS NOT RUNNING'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	select @count = count(1)
	from XX_FIWLR_BMSIW_WWERN16_ETL_STATUS
	where STATUS_CODE NOT IN ('COMPLETED', 'RESET')

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @count <> 0 GOTO ERROR




	--12
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE XX_DIV16_DDOU_FL'
	SET @ERROR_MSG_PLACEHOLDER2 = '& XX_DIV16_DDOU_PROJ_ABBRV_CD in LATEDOU table'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	UPDATE XX_FIWLR_BMSIW_WWERN16_LATEDOU
	SET XX_DIV16_DDOU_FL='Y',
		XX_DIV16_DDOU_PROJ_ABBRV_CD=dou.JDE_PROJ_CODE
	FROM 
	XX_FIWLR_BMSIW_WWERN16_LATEDOU bmsiw
	INNER JOIN
	XX_FIWLR_WWERN16_DOU dou
	ON
	(
	bmsiw.ACCOUNT_ID=dou.ACCOUNT_ID
	and
	bmsiw.CONTROL_GROUP_CD=dou.CONTROL_GROUP_CD
	)

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR




	--13 update div16 at expense date flag again (things might have changed)
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_DIV16_EMPLOYEE_AT_EXP_CHRG_DT_FL - for LATEDOU'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	--takes a bit of time to execute this part
	UPDATE XX_FIWLR_BMSIW_WWERN16_LATEDOU
	SET XX_DIV16_EMPLOYEE_AT_EXP_CHRG_DT_FL=dbo.XX_GET_DIV16_STATUS_UF(EMP_SER_NUM, EXP_EFFECTIVE_DT)
	--TODO: find out what the charge date should be EXP_EFFECTIVE_DT or EXP_CHRG_DT or EXP_WEEK_END_DT

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

--14 load FIWLR staging table
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT LATEDOU INTO'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_FIWLR_WWERN16'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	insert into xx_fiwlr_wwern16
	(
	SOURCE,
	REGION,
	DIVISION,
	MAJOR,
	MINOR,
	SUBMINOR,
	AMOUNT,
	DEPARTMENT,
	PROCESSED_DT,
	INVOICE_TXT,
	EXPENSE_CODE,
	FROM_DIV,
	EMPLOYEE_SER,
	IGS_PROJECT_NO,
	EXPENSE_DT,
	RPTKEY,
	EXPKEY,
	ACCOUNT_ID,
	EMP_INITS_NM,
	EMP_LAST_NM,
	EXP_BEGIN_DT,
	EXP_CHRG_DT,
	EXP_EFFECTIVE_DT,
	EXP_END_DT,
	EXP_WEEK_END_DT,
	CREATION_DATE,
	CREATED_BY,
	SOURCE_GROUP
	)
	select
	'N16' as SOURCE,
	'' as REGION,
	'16' as DIVISION,
	CHRG_MAJ_NUM as MAJOR,
	CHRG_MIN_NUM as MINOR,
	CHRG_SUBMIN_NUM as SUBMINOR,
	CHRG_AMT as AMOUNT,
	LEFT(CHRG_FINDPT_ID,3) as DEPARTMENT,
	PROCESSED_DT as PROCESSED_DT,
	INVOICE_TXT as INVOICE_TXT,
	EXP_CD as EXPENSE_CODE,
	CHRG_DIV_CD as FROM_DIV,
	EMP_SER_NUM as EMPLOYEE_SER,
	XX_DIV16_DDOU_PROJ_ABBRV_CD as IGS_PROJECT_NO,

	EXP_EFFECTIVE_DT as EXPENSE_DT,	--TODO: find out what the charge date should be EXP_EFFECTIVE_DT or EXP_CHRG_DT or EXP_WEEK_END_DT

	RPT_KEY as RPTKEY,
	EXP_KEY as EXPKEY,
	ACCOUNT_ID as ACCOUNT_ID,
	EMP_INITS_NM as EMP_INITS_NM,
	EMP_LAST_NM as EMP_LAST_NM,
	EXP_BEGIN_DT as EXP_BEGIN_DT,
	EXP_CHRG_DT as EXP_CHRG_DT,
	EXP_EFFECTIVE_DT as EXP_EFFECTIVE_DT,
	EXP_END_DT as EXP_END_DT,
	EXP_WEEK_END_DT as EXP_WEEK_END_DT,
	
	cast( 
		(left(CREATED_TMS, 10) + ' ' + replace(substring(CREATED_TMS, 12, 8), '.', ':'))
	as datetime)
	 as CREATION_DATE,
	
	suser_name() as CREATED_BY,
	'AP' as SOURCE_GROUP
	from XX_FIWLR_BMSIW_WWERN16_LATEDOU
	WHERE
	REPROCESSED_DT IS NULL
	AND
	CHRG_MIN_NUM = '0300'
	AND
	CHRG_DIV_CD<>'16'
	AND
	XX_DIV16_EMPLOYEE_AT_EXP_CHRG_DT_FL = 'Y'
	and
	XX_DIV16_DDOU_PROJ_ABBRV_CD IS NOT NULL

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	

	--15 load FIWLR control table
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT LATEDOU INTO'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_FIWLR_WWERN16_CONTROL'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	INSERT INTO XX_FIWLR_WWERN16_CONTROL
	(
	PROCESS_NAME,
	RECORD_COUNT,
	RECORD_COUNT_INITIAL,
	TOTAL_AMOUNT,
	CREATED_BY,
	CREATED_DATE,
	MODIFIED_BY,
	MODIFIED_DATE
	)
	SELECT
	'WWERN16' as PROCESS_NAME,
	COUNT(1) as RECORD_COUNT,
	COUNT(1) as RECORD_COUNT_INITIAL,
	SUM(CHRG_AMT) as TOTAL_AMOUNT,
	suser_name() as CREATED_BY,
	current_timestamp as CREATED_DATE,
	suser_name() as MODIFIED_BY,
	current_timestamp as MODIFIED_DATE
	from XX_FIWLR_BMSIW_WWERN16_LATEDOU
	WHERE
	REPROCESSED_DT IS NULL
	AND
	CHRG_MIN_NUM = '0300'
	AND
	CHRG_DIV_CD<>'16'
	AND
	XX_DIV16_EMPLOYEE_AT_EXP_CHRG_DT_FL = 'Y'
	and
	XX_DIV16_DDOU_PROJ_ABBRV_CD IS NOT NULL
	--TODO: verify this where clause

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	--16 update reprocessed date
	UPDATE XX_FIWLR_BMSIW_WWERN16_LATEDOU
	SET REPROCESSED_DT = CURRENT_TIMESTAMP
	WHERE
	REPROCESSED_DT IS NULL
	AND
	CHRG_MIN_NUM = '0300'
	AND
	CHRG_DIV_CD<>'16'
	AND
	XX_DIV16_EMPLOYEE_AT_EXP_CHRG_DT_FL = 'Y'
	and
	XX_DIV16_DDOU_PROJ_ABBRV_CD IS NOT NULL
	--TODO: verify this where clause



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

USE [IMAPSStg]
GO
/****** Object:  StoredProcedure [dbo].[XX_FIWLR_BMSIW_WWERN16_ETL_STEP1_SP]  ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_BMSIW_WWERN16_ETL_STEP1_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_BMSIW_WWERN16_ETL_STEP1_SP]
GO

CREATE PROCEDURE [dbo].[XX_FIWLR_BMSIW_WWERN16_ETL_STEP1_SP] (
@out_STATUS_DESCRIPTION sysname = NULL
)

AS

/************************************************************************************************
 Procedure Name	: XX_FIWLR_BMSIW_WWERN16_ETL_STEP1_SP  									 
 Created By		: KM									   								 
 Description    : ETL Checks and Initialization											 
 Date			: 2009-07-12				        									 
 Notes			:																		 
 Prerequisites	: 																		 
 Parameter(s)	: 																		 
	Input		:																		 
	Output		: Error Code and Error Description										 
 Tables Updated	: XX_FIWLR_BMSIW_WWERN16_EXTRACT										 
 Tables Updated	: XX_FIWLR_BMSIW_WWERN16_ETL_STATUS										 
 Version		: 1.0																	 
 ************************************************************************************************
 Date		  Modified By			Description of change	  								 
 ----------   -------------  	   	------------------------    			  				 
 2009-07-12   KM   					Created Initial Version									 
 ***********************************************************************************************/

BEGIN

 
DECLARE	@SP_NAME         	 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@ret_code		 int,
		@count			 int

	SET @SP_NAME = 'XX_FIWLR_BMSIW_WWERN16_ETL_STEP1_SP'


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY XX_FIWLR_BMSIW_WWERN16_EXTRACT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'IS NOT ALREADY IN PROGRESS'
	PRINT @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	set @count = 1

	select @count = count(1)
	from XX_FIWLR_BMSIW_WWERN16_ETL_STATUS
	where STATUS_CODE not in ('COMPLETED', 'RESET')
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	IF @count <> 0 GOTO ERROR


	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'TRUNCATE TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_FIWLR_BMSIW_WWERN16_EXTRACT'
	PRINT @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	TRUNCATE TABLE XX_FIWLR_BMSIW_WWERN16_EXTRACT

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INITIALIZE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_FIWLR_BMSIW_WWERN16_ETL_STATUS'
	PRINT @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	INSERT INTO XX_FIWLR_BMSIW_WWERN16_ETL_STATUS
	(
	CREATED_USER,
	CREATED_DATE,
	STATUS_CODE,
	MODIFIED_USER,
	MODIFIED_DATE
	)
	SELECT
	suser_name() as CREATED_USER,
	current_timestamp as CREATED_DATE,
	'INITIATED' as STATUS_CODE,
	suser_name() as MODIFIED_USER,
	current_timestamp as MODIFIED_DATE	
	
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

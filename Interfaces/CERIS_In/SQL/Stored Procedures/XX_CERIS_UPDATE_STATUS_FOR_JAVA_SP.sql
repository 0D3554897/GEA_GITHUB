USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_UPDATE_STATUS_FOR_JAVA_SP]  ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_UPDATE_STATUS_FOR_JAVA_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_CERIS_UPDATE_STATUS_FOR_JAVA_SP]
GO

CREATE PROCEDURE [dbo].[XX_CERIS_UPDATE_STATUS_FOR_JAVA_SP] (
@out_STATUS_DESCRIPTION sysname = NULL output
)

AS

/************************************************************************************************
Procedure Name	: XX_CERIS_UPDATE_STATUS_FOR_JAVA_SP  									 
Created By		: GEA									   								 
Description    	: Update the status table to show how many records were loaded before verification											 
Date			: 2016-06-30				        									 
Notes			:																		 
Prerequisites	: A status code must have been already created				 
Parameter(s)	: 																		 
	Input		:																		 
	Output		: Error Code and Error Description						 
 Tables Updated	: XX_IMAPS_INT_STATUS, 	XX_IMAPS_INT_CONTROL									 
Version			: 1.0																	 
************************************************************************************************
Date		 Modified By		Description of change	  								 
----------   -------------  	------------------------    			  				 
2016-06-30   GEA  				Created Initial Version									 
************************************************************************************************/

BEGIN

 
DECLARE	@SP_NAME         	 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@ret_code		 int,
		@count			 int,
		@rec_count 		 int,
		@current_STATUS_RECORD_NUM int

	SET @SP_NAME = 'XX_CERIS_UPDATE_STATUS_FOR_JAVA_SP'
	set @count = 1

	select @rec_count = count(1)
	from XX_R22_CERIS_FILE_STG1

	--1
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'FIND STATUS_RECORD_NUM'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR EXTRACT'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	select @count = count(1)
	from XX_IMAPS_INT_STATUS
	where
	interface_name='CERIS_R22'
	and 
	STATUS_CODE not in ('COMPLETED', 'RESET')


	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @count <> 1 GOTO ERROR

	select @current_STATUS_RECORD_NUM = STATUS_RECORD_NUM
	from XX_IMAPS_INT_STATUS
	where
	interface_name='CERIS_R22'
	and 
	STATUS_CODE not in ('COMPLETED', 'RESET')


	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @current_STATUS_RECORD_NUM IS NULL GOTO ERROR

	UPDATE XX_IMAPS_INT_STATUS 
	SET STATUS_DESCRIPTION = 'JAVA PROGRAM EXECUTED ' + CAST(@rec_count AS varchar(10)) + ' RECORDS INSERTED' ,
	STATUS_CODE = 'CSV LOADED'
	WHERE STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM

/*
	EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
	   @in_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM,
	   @in_STATUS_CODE       = 'COMPLETED'

*/

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

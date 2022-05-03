if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_UTIL_RUN_INTERFACE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_UTIL_RUN_INTERFACE_SP]
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO



CREATE PROCEDURE [dbo].[XX_UTIL_RUN_INTERFACE_SP] 
( 
 @in_StartDate datetime = NULL,
 @in_EndDate datetime = NULL
 )  AS
 
  DECLARE
@LastExecutedInterfaceStatusNum int,
@LastExecutedInterfaceStatus varchar(10),
@LastExecutedControlPoint varchar(10),
@CurrentExecutionStep int, 
@CurrentInterfaceStatusNum int,
@CurrentExecutedControlPoint varchar(6),
@ExecutionStepProcedure varchar(50),
@ExecutionStepSystemError int,
@ProcedureReturnCode int,
@InterfaceSuccessfulExecutionStatus  varchar(20),
@InterfaceFailedExecutionStatus varchar(20),
@SystemErrorCode int,
@TotalNumberOfSteps int,
@NumberOfRecords int,
@SP_NAME varchar(50),
@out_STATUS_DESCRIPTION varchar(240),
@SystemErrorDescription varchar(275),
-- parameters for status record
	@UTIL_INTERFACE_NAME varchar(20),
	@IMAPS_DB_NAME  sysname,
	@IMAPS_SCHEMA_OWNER  sysname,
	@UTIL_INTERFACE varchar(50),
	@OUTBOUND_INT_TYPE varchar(1),
	@UTIL_SOURCE_SYSTEM varchar(50),
	@UTIL_DEST_SYSTEM varchar(50),
	@UTIL_Data_FName sysname,
	@UTIL_source_owner  varchar(50),
	@UTIL_dest_owner   varchar(300),
	@UTIL_CONTROL_POINT_DOMAIN varchar(50)


/********************************************************************************************************
Name:       XX_UTIL_RUN_INTERFACE_SP
Author:     Tatiana Perova
Created:    10/03/2005
Purpose:   
Parameters: @in_StartDate - parameter for custom requeat that will pick up all tisheet data within 
	    the start-end date
	    @in_EndDate - parameter for custom requeat that will pick up all tisheet data within the 
	    start-end date
	
Return Code:

Notes:      Starting point for interface run, calls all other procedures that do actual data processing.

CP600000199 02/08/2008 Reference BP&S Service Request: DR1427
            Enable more users to be notified by e-mail upon specific interface run events.
            Change the size of @UTIL_dest_owner from varchar(50) to varchar(300).
*********************************************************************************************************/

SELECT @UTIL_INTERFACE_NAME = 'UTIL', 
@InterfaceSuccessfulExecutionStatus = 'COMPLETED',
@InterfaceFailedExecutionStatus = 'FAILED',
@TotalNumberOfSteps = 3,
@ProcedureReturnCode = 301,
@SystemErrorCode = NULL,
@SP_NAME = 'XX_UTIL_RUN_INTERFACE_SP'

SELECT 
	@UTIL_SOURCE_SYSTEM  = 'UTIL',
	@UTIL_DEST_SYSTEM = 'IMAPS',
	@OUTBOUND_INT_TYPE  = 'O',
	@UTIL_CONTROL_POINT_DOMAIN = 'LD_UTIL_INTERFACE_CTRL_PT'
	

SELECT @UTIL_source_owner   = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'UTIL' AND PARAMETER_NAME = 'IN_SOURCE_SYSOWNER'
SELECT @UTIL_dest_owner = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'UTIL' AND PARAMETER_NAME = 'IN_DESTINATION_SYSOWNER'
SELECT @IMAPS_DB_NAME   = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'UTIL' AND PARAMETER_NAME = 'IMAPS_DATABASE_NAME'
SELECT @IMAPS_SCHEMA_OWNER = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'UTIL' AND PARAMETER_NAME = 'IMAPS_SCHEMA_OWNER'
SELECT @UTIL_Data_FName   = ' ' 



SELECT  @LastExecutedInterfaceStatusNum = STATUS_RECORD_NUM,
	 @LastExecutedInterfaceStatus = STATUS_CODE
FROM IMAPSStg.dbo.XX_IMAPS_INT_STATUS
WHERE 
	CREATED_DATE = (
		SELECT MAX(a1.CREATED_DATE) 
		FROM IMAPSStg.dbo.XX_IMAPS_INT_STATUS a1
		WHERE a1.INTERFACE_NAME = @UTIL_INTERFACE_NAME
		) 	AND
	INTERFACE_NAME = @UTIL_INTERFACE_NAME

SELECT @SystemErrorCode = @@ERROR,  @NumberOfRecords = @@ROWCOUNT

IF @SystemErrorCode > 0  BEGIN GOTO ErrorProcessing END
IF @NumberOfRecords > 1 BEGIN  GOTO ErrorProcessing END
	
IF 	@LastExecutedInterfaceStatusNum is NULL 
	BEGIN
		SELECT  @LastExecutedInterfaceStatusNum = COUNT(*)
		FROM IMAPSStg.dbo.XX_IMAPS_INT_STATUS
		WHERE INTERFACE_NAME = @UTIL_INTERFACE_NAME
		
		IF @LastExecutedInterfaceStatusNum = 0 
			-- the firts run of the interface
			BEGIN SET  @LastExecutedInterfaceStatus =  @InterfaceSuccessfulExecutionStatus END
		ELSE
			BEGIN GOTO ErrorProcessing END
	END


IF 	@LastExecutedInterfaceStatus <> @InterfaceSuccessfulExecutionStatus
	BEGIN
	-- look for last succesful control point	

	SELECT @LastExecutedControlPoint = CONTROL_PT_ID 
	FROM IMAPSStg.dbo.XX_IMAPS_INT_CONTROL
	WHERE  STATUS_RECORD_NUM = @LastExecutedInterfaceStatusNum AND
		INTERFACE_NAME = @UTIL_INTERFACE_NAME AND
		CONTROL_PT_STATUS = 'SUCCESS' AND
		CONTROL_RECORD_NUM = (
			SELECT MAX(CONTROL_RECORD_NUM) 
			FROM IMAPSStg.dbo.XX_IMAPS_INT_CONTROL a1
			WHERE a1.STATUS_RECORD_NUM  = @LastExecutedInterfaceStatusNum AND
				a1.INTERFACE_NAME = @UTIL_INTERFACE_NAME AND
				a1.CONTROL_PT_STATUS = 'SUCCESS'
			) 

			
	IF @LastExecutedControlPoint is NULL 
		BEGIN SET @CurrentExecutionStep = 1 END
	ELSE
		BEGIN
		Print 'Select cpt'
		PRINT @LastExecutedControlPoint
		SELECT @CurrentExecutionStep = PRESENTATION_ORDER + 1 
		FROM IMAPSStg.dbo.XX_LOOKUP_DETAIL 		
		WHERE 
			APPLICATION_CODE = @LastExecutedControlPoint 
		END

	SET @CurrentInterfaceStatusNum = @LastExecutedInterfaceStatusNum
	END
ELSE
	BEGIN SET @CurrentExecutionStep = 1 END

-- begin 01/16/2006 TP - creation of log record should be independent from status record
IF @CurrentInterfaceStatusNum is NULL 
	BEGIN
	-- create new record in status table
	EXEC  @ProcedureReturnCode = dbo.XX_INSERT_INT_STATUS_RECORD
		@in_IMAPS_db_name      = @IMAPS_DB_NAME,
		@in_IMAPS_table_owner  = @IMAPS_SCHEMA_OWNER,
		@in_int_name           = @UTIL_INTERFACE_NAME,
		@in_int_type           = @OUTBOUND_INT_TYPE,
		@in_int_source_sys     = @UTIL_SOURCE_SYSTEM,
		@in_int_dest_sys       = @UTIL_DEST_SYSTEM,
		@in_Data_FName         = @UTIL_Data_FName,
		@in_int_source_owner   = @UTIL_source_owner,
		@in_int_dest_owner     = @UTIL_dest_owner,
		@out_STATUS_RECORD_NUM = @CurrentInterfaceStatusNum OUTPUT
	IF  @ProcedureReturnCode <> 0 BEGIN GOTO ErrorProcessing END
END

IF  (SELECT count(*) FROM dbo.XX_UTIL_OUT_LOG 
WHERE STATUS_RECORD_NUM = @CurrentInterfaceStatusNum ) = 0 
BEGIN
	-- create log record
	INSERT INTO dbo.XX_UTIL_OUT_LOG (  STATUS_RECORD_NUM , START_DT,  END_DT)
             VALUES 
	(  @CurrentInterfaceStatusNum,@in_StartDate, @in_EndDate )
END
-- end 01/16/2006 TP

WHILE @CurrentExecutionStep <= @TotalNumberOfSteps
	BEGIN
		SELECT @ExecutionStepProcedure =
		CASE @CurrentExecutionStep
			WHEN 1 THEN 'dbo.XX_UTIL_LOAD_STAGING_DATA_SP'
			WHEN 2 THEN 'dbo.XX_UTIL_DATA_TRANSFER_SP'
			 WHEN 3 THEN 'dbo.XX_UTIL_ARCHIVE_SP'
		END

		
		EXEC  @ProcedureReturnCode = @ExecutionStepProcedure @CurrentInterfaceStatusNum, 
				@ExecutionStepSystemError  OUTPUT, @out_STATUS_DESCRIPTION OUTPUT
			
		
		IF @ProcedureReturnCode <> 0
			BEGIN
				-- for this procedure we assume that errors are logged by steps
				SELECT  @SP_NAME = @ExecutionStepProcedure, 
						@SystemErrorCode = @ExecutionStepSystemError
				GOTO ErrorProcessing
			END
		ELSE		
			BEGIN	
			-- insert another XX_IMAPS_INT_CONTROL record for the step
			EXEC dbo.XX_INSERT_INT_CONTROL_RECORD
				@in_int_ctrl_pt_num  =@CurrentExecutionStep,
				@in_lookup_domain_const =@UTIL_CONTROL_POINT_DOMAIN,
				@in_STATUS_RECORD_NUM  = @CurrentInterfaceStatusNum
			SET @CurrentExecutionStep = @CurrentExecutionStep+1
		END	
	END


-- update status record with "SUCCESS"
-- begin TP 11/08/2005 changed update by SQL to procedure call
EXEC dbo.XX_UPDATE_INT_STATUS_RECORD	@in_STATUS_RECORD_NUM  = @CurrentInterfaceStatusNum,
	@in_STATUS_CODE     =  @InterfaceSuccessfulExecutionStatus
-- end TP 11/08/2005

EXEC  [dbo].[XX_SEND_STATUS_MAIL_SP] @in_StatusRecordNum = @CurrentInterfaceStatusNum

RETURN 0

ErrorProcessing:
/*
Error processing depends on three values @ProcedureReturnCode,  @out_STATUS_DESCRIPTION and 
@SystemErrorCode. For error @ProcedureReturnCode >=1. If  @ProcedureReturnCode <> 1 we 
will look for IMAPS error message, combine it with system error message.
If @ProcedureReturnCode = 1, we expect  @out_STATUS_DESCRIPTION to be already populated by previous 
steps. @ProcedureReturnCode  = 1 AND @out_STATUS_DESCRIPTION is NULL standard unknown message 
will be displayed (extended by system messade if available)
*/
IF @ProcedureReturnCode  = 1 AND @out_STATUS_DESCRIPTION is NULL 
	BEGIN  SET @ProcedureReturnCode = 301 END
IF  @SystemErrorCode = 0 BEGIN SET @SystemErrorCode = NULL END 
IF @ProcedureReturnCode <> 1  
	BEGIN
	EXEC dbo.XX_ERROR_MSG_DETAIL
         		@in_error_code          = @ProcedureReturnCode,
         		@in_SQLServer_error_code = @SystemErrorCode, 		@in_display_requested   = 1,
         		@in_calling_object_name = @SP_NAME,
         		@out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT,
		@out_syserror_msg_text = @SystemErrorDescription OUTPUT
	IF  @SystemErrorDescription is NOT NULL 
		BEGIN 
			SET @out_STATUS_DESCRIPTION = RTRIM(@out_STATUS_DESCRIPTION) +  @SystemErrorDescription
		END
	END

	-- update status record with "FAILED"
	EXEC dbo.XX_UPDATE_INT_STATUS_RECORD	@in_STATUS_RECORD_NUM  = @CurrentInterfaceStatusNum,
	@in_STATUS_CODE     =  @InterfaceFailedExecutionStatus,
	@in_STATUS_DESCRIPTION =  @out_STATUS_DESCRIPTION


	EXEC  [dbo].[XX_SEND_STATUS_MAIL_SP] @in_StatusRecordNum = @CurrentInterfaceStatusNum
RETURN 1
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


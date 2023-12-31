SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PCLAIM_RUN_INTERFACE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_PCLAIM_RUN_INTERFACE_SP]
GO

CREATE PROCEDURE [dbo].[XX_PCLAIM_RUN_INTERFACE_SP] 
  AS
 
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
 @InterfaceStartedPreprocessorStatus varchar(20),
 @InterfaceFailedExecutionStatus varchar(20),
 @SystemErrorCode int,
 @TotalNumberOfSteps int,
 @NumberOfRecords int,
@SP_NAME varchar(50),
 @out_STATUS_DESCRIPTION varchar(240),
@syserror_msg_text varchar(275),
-- parameters for status record
	@PCLAIM_INTERFACE_NAME varchar(20),
	@IMAPS_DB_NAME  sysname,
	@IMAPS_SCHEMA_OWNER  sysname,
	@PCLAIM_INTERFACE varchar(50),
	@INBOUND_INT_TYPE varchar(1),
	@PCLAIM_SOURCE_SYSTEM varchar(50),
	@PCLAIM_DEST_SYSTEM varchar(50),
	@PCLAIM_Data_FName sysname,
	@PCLAIM_source_owner  varchar(50),
	@PCLAIM_dest_owner   varchar(300),
	@PCLAIM_CONTROL_POINT_DOMAIN varchar(50)

 
SELECT @PCLAIM_INTERFACE_NAME = 'PCLAIM', 
@InterfaceSuccessfulExecutionStatus = 'COMPLETED',
@InterfaceStartedPreprocessorStatus = 'CPIN_PROGRESS',
@InterfaceFailedExecutionStatus = 'FAILED',
@TotalNumberOfSteps = 5,
@ProcedureReturnCode = 301,
@SystemErrorCode = NULL,
@out_STATUS_DESCRIPTION = NULL,
@SP_NAME = 'XX_PCLAIM_RUN_INTERFACE_SP'

SELECT 
	@PCLAIM_SOURCE_SYSTEM  = 'PCLAIM',
	@PCLAIM_DEST_SYSTEM = 'IMAPS',
	@INBOUND_INT_TYPE  = 'I',
	@PCLAIM_CONTROL_POINT_DOMAIN = 'LD_PCLAIM_INTERFACE_CTRL_PT'
	

SELECT @PCLAIM_source_owner   = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'PCLAIM' AND PARAMETER_NAME = 'IN_SOURCE_SYSOWNER'
SELECT @PCLAIM_dest_owner = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'PCLAIM' AND PARAMETER_NAME = 'IN_DESTINATION_SYSOWNER'
SELECT @IMAPS_DB_NAME   = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'PCLAIM' AND PARAMETER_NAME = 'IMAPS_DATABASE_NAME'
SELECT @IMAPS_SCHEMA_OWNER = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'PCLAIM' AND PARAMETER_NAME = 'IMAPS_SCHEMA_OWNER'
SELECT @PCLAIM_Data_FName   = '' -- TP 11/10/2005 data picked from table

/*******************************************************************************************************
Name:       XX_RUN_PCLAIM_INTERFACE
Author:     Tatiana Perova
Created:    07/30/2005
Purpose:   
Parameters: 
	
Result Set: 
Notes:      Starting point for interface run, calls all other procedures that do actual data processing.

CP600000199 02/08/2008 Reference BP&S Service Request: DR1427
            Enable more users to be notified by e-mail upon specific interface run events. Change the
            size of @PCLAIM_dest_owner from varchar(50) to varchar(300).
********************************************************************************************************/

SELECT  @LastExecutedInterfaceStatusNum = STATUS_RECORD_NUM,
	 @LastExecutedInterfaceStatus = STATUS_CODE
FROM IMAPSStg.dbo.XX_IMAPS_INT_STATUS
WHERE 
	CREATED_DATE = (
		SELECT MAX(a1.CREATED_DATE) 
		FROM IMAPSStg.dbo.XX_IMAPS_INT_STATUS a1
		WHERE a1.INTERFACE_NAME = @PCLAIM_INTERFACE_NAME
		) 	AND
	INTERFACE_NAME = @PCLAIM_INTERFACE_NAME

SELECT @SystemErrorCode = @@ERROR,  @NumberOfRecords = @@ROWCOUNT
IF @SystemErrorCode > 0  BEGIN GOTO ErrorProcessing END
IF @NumberOfRecords > 1 BEGIN  GOTO ErrorProcessing END
	
IF 	@LastExecutedInterfaceStatusNum is NULL 
	BEGIN
		SELECT  @LastExecutedInterfaceStatusNum = COUNT(*)
		FROM IMAPSStg.dbo.XX_IMAPS_INT_STATUS
		WHERE INTERFACE_NAME = @PCLAIM_INTERFACE_NAME
		
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
		INTERFACE_NAME = @PCLAIM_INTERFACE_NAME AND
		CONTROL_PT_STATUS = 'SUCCESS' AND
		CONTROL_RECORD_NUM = (
			SELECT MAX(CONTROL_RECORD_NUM) 
			FROM IMAPSStg.dbo.XX_IMAPS_INT_CONTROL a1
			WHERE a1.STATUS_RECORD_NUM  = @LastExecutedInterfaceStatusNum AND
				a1.INTERFACE_NAME = @PCLAIM_INTERFACE_NAME AND
				a1.CONTROL_PT_STATUS = 'SUCCESS'
			) 
	SELECT  @SystemErrorCode = @@ERROR,  @NumberOfRecords = @@ROWCOUNT
	IF @SystemErrorCode > 0  BEGIN GOTO ErrorProcessing END
			
	IF @LastExecutedControlPoint is NULL 
		BEGIN SET @CurrentExecutionStep = 1 END
	ELSE
		BEGIN
		--select next control point to execute
		SELECT @CurrentExecutionStep = PRESENTATION_ORDER + 1 
		FROM IMAPSStg.dbo.XX_LOOKUP_DETAIL 		
		WHERE 
			APPLICATION_CODE = @LastExecutedControlPoint 
		END
	SET @CurrentInterfaceStatusNum = @LastExecutedInterfaceStatusNum
	END
ELSE
	BEGIN SET @CurrentExecutionStep = 1 END

IF @CurrentInterfaceStatusNum is NULL 
	BEGIN
	-- create new record in status table
	EXEC  @ProcedureReturnCode = dbo.XX_INSERT_INT_STATUS_RECORD
	   @in_IMAPS_db_name      = @IMAPS_DB_NAME,
                  @in_IMAPS_table_owner  = @IMAPS_SCHEMA_OWNER,
                  @in_int_name           = @PCLAIM_INTERFACE_NAME,
                  @in_int_type           = @INBOUND_INT_TYPE,
                  @in_int_source_sys     = @PCLAIM_SOURCE_SYSTEM,
                  @in_int_dest_sys       = @PCLAIM_DEST_SYSTEM,
                  @in_Data_FName         = @PCLAIM_Data_FName,
                  @in_int_source_owner   = @PCLAIM_source_owner,
                  @in_int_dest_owner     = @PCLAIM_dest_owner,
                  @out_STATUS_RECORD_NUM = @CurrentInterfaceStatusNum OUTPUT
	IF  @ProcedureReturnCode <> 0 BEGIN GOTO ErrorProcessing END
	END
	
WHILE @CurrentExecutionStep <= @TotalNumberOfSteps
	BEGIN
		/*step four control point should be created  by common code for  the successful preprocesor run 
		   therefor if interface received step 4 for execution it means that AP preprocessor fails and interface will do nothing*/
		IF  @CurrentExecutionStep = 4
			BEGIN 
			SET @ProcedureReturnCode = 520
			SET @InterfaceFailedExecutionStatus = @InterfaceStartedPreprocessorStatus
			GOTO ErrorProcessing
			END
		/*  10/26/2005 TP - all data should be pushed to XX_PCLAIM_IN table by PCLAIM system
		 bulk insert was put into separate procedure in order not to interfere with transactions
		IF  @CurrentExecutionStep = 1
			BEGIN 
			EXEC @ProcedureReturnCode = dbo.XX_PCLAIM_FILE_BULK_INSERT_SP @CurrentInterfaceStatusNum, @ExecutionStepSystemError  OUTPUT, @out_STATUS_DESCRIPTION OUTPUT
			IF @ProcedureReturnCode > 0 BEGIN GOTO ErrorProcessing END
			END
		 */
		SELECT @ExecutionStepProcedure =
		CASE @CurrentExecutionStep
			WHEN 1 THEN 'dbo.XX_PCLAIM_LOAD_STAGING_DATA_SP'
			WHEN 2 THEN 'dbo.XX_PCLAIM_FILL_PREPROCESSOR_STAGE_SP'
			WHEN 3 THEN 'dbo.XX_PCLAIM_START_AP_PREPROCESSOR_SP'
			WHEN 5 THEN 'dbo.XX_PCLAIM_ARCHIVE_SP'
		END
		BEGIN TRANSACTION ControlStep
		EXEC  @ProcedureReturnCode = @ExecutionStepProcedure @CurrentInterfaceStatusNum, @ExecutionStepSystemError  OUTPUT, @out_STATUS_DESCRIPTION OUTPUT
		
		IF @ProcedureReturnCode <> 0
			BEGIN
				-- for this procedure we assume that errors are logged by steps
				ROLLBACK TRANSACTION ControlStep
				SELECT  @SP_NAME = @ExecutionStepProcedure, @SystemErrorCode = @ExecutionStepSystemError
				GOTO ErrorProcessing
			END
		ELSE		
			BEGIN	
				COMMIT TRANSACTION ControlStep

			-- insert another XX_IMAPS_INT_CONTROL record for the step
			EXEC dbo.XX_INSERT_INT_CONTROL_RECORD
				@in_int_ctrl_pt_num  =@CurrentExecutionStep,
				@in_lookup_domain_const =@PCLAIM_CONTROL_POINT_DOMAIN,
				@in_STATUS_RECORD_NUM  = @CurrentInterfaceStatusNum

			SET @CurrentExecutionStep = @CurrentExecutionStep+1
			-- need to stop execution after starting preprocessor step 3
			IF  @CurrentExecutionStep = 4 
				BEGIN
				EXEC dbo.XX_UPDATE_INT_STATUS_RECORD					@in_STATUS_RECORD_NUM  = @CurrentInterfaceStatusNum,
					@in_STATUS_CODE     =  @InterfaceStartedPreprocessorStatus

				RETURN 0
				END
			END
	END


-- update status record with "COMPLETED"
EXEC dbo.XX_UPDATE_INT_STATUS_RECORD	@in_STATUS_RECORD_NUM  = @CurrentInterfaceStatusNum,
	@in_STATUS_CODE     = @InterfaceSuccessfulExecutionStatus

EXEC  [dbo].[XX_SEND_STATUS_MAIL_SP] @in_StatusRecordNum = @CurrentInterfaceStatusNum

RETURN 0

ErrorProcessing:
/*
Error processing depends on three values @ProcedureReturnCode,  @out_STATUS_DESCRIPTION and @SystemErrorCode.
For error @ProcedureReturnCode >=1. If  @ProcedureReturnCode <> 1 we will look for IMAPS error message, combine it with system error message.
If @ProcedureReturnCode = 1, we expect  @out_STATUS_DESCRIPTION to be already populated by previous steps.
@ProcedureReturnCode  = 1 AND @out_STATUS_DESCRIPTION is NULL standard unknown message will be displayed (extended
by system message, if available)
*/
IF @ProcedureReturnCode  = 1 AND @out_STATUS_DESCRIPTION is NULL 
	BEGIN  SET @ProcedureReturnCode = 301 END
IF  @SystemErrorCode = 0 BEGIN SET @SystemErrorCode = NULL END 
IF @ProcedureReturnCode <> 1  
	BEGIN
	EXEC dbo.XX_ERROR_MSG_DETAIL
         		@in_error_code          = @ProcedureReturnCode,
         		@in_SQLServer_error_code = @SystemErrorCode,
         		@in_display_requested   = 1,
         		@in_calling_object_name = @SP_NAME,
         		@out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT,
		@out_syserror_msg_text = @syserror_msg_text OUTPUT
	IF @syserror_msg_text is NOT NULL 
		BEGIN 
			SET @out_STATUS_DESCRIPTION = RTRIM(@out_STATUS_DESCRIPTION) + @syserror_msg_text
		END
	END

	-- 10/27/2005  TP update status record with "failed"
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


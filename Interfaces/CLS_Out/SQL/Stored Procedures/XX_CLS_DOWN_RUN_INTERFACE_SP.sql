USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_CLS_DOWN_RUN_INTERFACE_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 


CREATE PROCEDURE [dbo].[XX_CLS_DOWN_RUN_INTERFACE_SP] 
	( @in_FY char(4) = NULL, @in_MO char(2) = NULL)
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
 @InterfaceFailedExecutionStatus varchar(20),
 @SystemErrorCode int,
 @TotalNumberOfSteps int,
 @NumberOfRecords int,
 @SP_NAME varchar(50),
 @out_STATUS_DESCRIPTION varchar(240),
 @syserror_msg_text varchar(275),
 @on_demand_fl varchar(1),
@ARCH_DIR varchar(300),
-- parameters for status record
	@CLS_DOWN_INTERFACE_NAME varchar(20),
	@IMAPS_DB_NAME  sysname,
	@IMAPS_SCHEMA_OWNER  sysname,
	@CLS_DOWN_INTERFACE varchar(50),
	@INBOUND_INT_TYPE varchar(1),
	@CLS_DOWN_SOURCE_SYSTEM varchar(50),
	@CLS_DOWN_DEST_SYSTEM varchar(50),
	@CLS_DOWN_Data_FName sysname,
	@CLS_DOWN_source_owner  varchar(50),
	@CLS_DOWN_dest_owner   varchar(300),
	@CLS_DOWN_CONTROL_POINT_DOMAIN varchar(50),
	@ZERO INT,
	@error_msg_placeholder1         sysname,
    @error_msg_placeholder2         sysname

 
-- FINGERPRINT BLOCK
SELECT @ZERO=SUM(COALESCE(DIFF,999)) FROM
(SELECT PARAMETER_VALUE - DBO.XX_SP_FINGERPRINT(PARAMETER_NAME) AS DIFF
FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
WHERE PARAMETER_NAME LIKE '%XX_CLS%_SP')X

IF @ZERO <> 0
	BEGIN
	PRINT 'THE STORED PROCEDURES IN THE DATABASE ARE NOT UP TO DATE, OR THE CODE HAS BEEN MODIFIED'
	PRINT 'ERROR NUMBER: ' + CAST(@ZERO AS VARCHAR)

	-- Attempt to insert a record in table XX_SABRIX_INV_OUT_SUM_DTLS_STG failed.
    -- optional placeholders
	--SET @error_msg_placeholder1 = 'run'
	--SET @error_msg_placeholder2 = 'with latest source code'

	EXEC dbo.XX_ERROR_MSG_DETAIL
		@in_error_code           = 566,
		@in_display_requested    = 0,
		@in_SQLServer_error_code = @ZERO,
		@in_placeholder_value1   = @error_msg_placeholder1,
		@in_placeholder_value2   = @error_msg_placeholder2,
		@in_calling_object_name  = @SP_NAME,
		@out_msg_text            = 'FINGERPRINT CHECK'

	GOTO ErrorProcessing
	END
-- FINGERPRINT BLOCK

SELECT @CLS_DOWN_INTERFACE_NAME = 'CLS', 
@InterfaceSuccessfulExecutionStatus = 'COMPLETED',
@InterfaceFailedExecutionStatus = 'FAILED',
@TotalNumberOfSteps = 5,
@ProcedureReturnCode = 301,
@SystemErrorCode = NULL,
@out_STATUS_DESCRIPTION = NULL,
@SP_NAME = 'XX_CLS_DOWN_RUN_INTERFACE_SP'

SELECT 
	@CLS_DOWN_SOURCE_SYSTEM  = 'IMAPS',
	@CLS_DOWN_DEST_SYSTEM = 'CLS',
	@INBOUND_INT_TYPE  = 'O',
	@CLS_DOWN_CONTROL_POINT_DOMAIN = 'LD_CLS_DOWN_INTERFACE_CTRL_PT'
	

SELECT @CLS_DOWN_source_owner   = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'CLS' AND PARAMETER_NAME = 'IN_SOURCE_SYSOWNER'
SELECT @CLS_DOWN_dest_owner = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'CLS' AND PARAMETER_NAME = 'IN_DESTINATION_SYSOWNER'
SELECT @IMAPS_DB_NAME   = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'CLS' AND PARAMETER_NAME = 'IMAPS_DATABASE_NAME'
SELECT @IMAPS_SCHEMA_OWNER = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'CLS' AND PARAMETER_NAME = 'IMAPS_SCHEMA_OWNER'
SELECT @CLS_DOWN_Data_FName   = ''

/************************************************************************************************
Name:       XX_CLS_DOWN_RUN_INTERFACE
Author:     Tatiana Perova
Created:    07/30/2005
Purpose:   
Parameters: 
	
Result Set:

Notes:      Starting point for interface run, calls all other procedures that do actual data processing.

CP600000199 02/08/2008 Reference BP&S Service Request: DR1427
            Enable more users to be notified by e-mail upon specific interface run events.
            Change the size

 of @CLS_DOWN_dest_owner from varchar(50) to varchar(300).
************************************************************************************************/

SELECT  @LastExecutedInterfaceStatusNum = STATUS_RECORD_NUM,
	 @LastExecutedInterfaceStatus = STATUS_CODE
FROM IMAPSStg.dbo.XX_IMAPS_INT_STATUS
WHERE 
	CREATED_DATE = (
		SELECT MAX(a1.CREATED_DATE) 
		FROM IMAPSStg.dbo.XX_IMAPS_INT_STATUS a1
		WHERE a1.INTERFACE_NAME = @CLS_DOWN_INTERFACE_NAME
		) 	AND
	INTERFACE_NAME = @CLS_DOWN_INTERFACE_NAME

SELECT @SystemErrorCode = @@ERROR,  @NumberOfRecords = @@ROWCOUNT
IF @SystemErrorCode > 0  BEGIN GOTO ErrorProcessing END
IF @NumberOfRecords > 1 BEGIN  GOTO ErrorProcessing END
	
IF 	@LastExecutedInterfaceStatusNum is NULL 
	BEGIN
		SELECT  @LastExecutedInterfaceStatusNum = COUNT(*)
		FROM IMAPSStg.dbo.XX_IMAPS_INT_STATUS
		WHERE INTERFACE_NAME = @CLS_DOWN_INTERFACE_NAME
		
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
		INTERFACE_NAME = @CLS_DOWN_INTERFACE_NAME AND
		CONTROL_PT_STATUS = 'SUCCESS' AND
		CONTROL_RECORD_NUM = (
			SELECT MAX(CONTROL_RECORD_NUM) 
			FROM IMAPSStg.dbo.XX_IMAPS_INT_CONTROL a1
			WHERE a1.STATUS_RECORD_NUM  = @LastExecutedInterfaceStatusNum AND
				a1.INTERFACE_NAME = @CLS_DOWN_INTERFACE_NAME AND
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
                  @in_int_name           = @CLS_DOWN_INTERFACE_NAME,
                  @in_int_type           = @INBOUND_INT_TYPE,
                  @in_int_source_sys     = @CLS_DOWN_SOURCE_SYSTEM,
                  @in_int_dest_sys       = @CLS_DOWN_DEST_SYSTEM,
                  @in_Data_FName         = @CLS_DOWN_Data_FName,
                  @in_int_source_owner   = @CLS_DOWN_source_owner,
                  @in_int_dest_owner     = @CLS_DOWN_dest_owner,
                  @out_STATUS_RECORD_NUM = @CurrentInterfaceStatusNum OUTPUT
	IF  @ProcedureReturnCode <> 0 BEGIN  GOTO ErrorProcessing END


	END

IF  (SELECT COUNT(*) FROM  dbo.XX_CLS_DOWN_LOG WHERE STATUS_RECORD_NUM = @CurrentInterfaceStatusNum ) = 0
	BEGIN 
	-- create new record in log table
	EXEC @ProcedureReturnCode = dbo.XX_CLS_DOWN_CREATE_LOG_RECORD_SP @in_FY, @in_MO, @CurrentInterfaceStatusNum, @SystemErrorCode OUTPUT,@out_STATUS_DESCRIPTION OUTPUT
	IF  @ProcedureReturnCode <> 0  BEGIN	Print 'Error on Log creation' GOTO ErrorProcessing	END
	END

WHILE @CurrentExecutionStep <= @TotalNumberOfSteps
	BEGIN
		
		SELECT @ExecutionStepProcedure =
		CASE @CurrentExecutionStep
			WHEN 1 THEN 'dbo.XX_CLS_DOWN_LOAD_STAGE_SP'
			WHEN 2 THEN 'dbo.XX_CLS_DOWN_VALIDATE_CMR_SP'
			WHEN 3 THEN 'dbo.XX_CLS_DOWN_GET_TOTALS_SP'
			WHEN 4 THEN 'dbo.XX_CLS_DOWN_CREATE_FLAT_FILE_SP'
			WHEN 5 THEN 'dbo.XX_CLS_DOWN_ARCHIVE_FILES_SP'
		END
		BEGIN TRANSACTION ControlStep
		EXEC  @ProcedureReturnCode = @ExecutionStepProcedure @CurrentInterfaceStatusNum, 
									@ExecutionStepSystemError  OUTPUT, @out_STATUS_DESCRIPTION OUTPUT
		
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
				@in_lookup_domain_const =@CLS_DOWN_CONTROL_POINT_DOMAIN,
				@in_STATUS_RECORD_NUM  = @CurrentInterfaceStatusNum
			SET @CurrentExecutionStep = @CurrentExecutionStep+1
		END
	END


-- update status record with COMPLETED
EXEC dbo.XX_UPDATE_INT_STATUS_RECORD
	@in_STATUS_RECORD_NUM  = @CurrentInterfaceStatusNum,
	@in_STATUS_CODE     = @InterfaceSuccessfulExecutionStatus

-- get control file name (archived for this run) to mail it as attachment to the status mail
SELECT 	@ARCH_DIR = PARAMETER_VALUE 
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = 'CLS' 
AND	PARAMETER_NAME = 'ARCH_DIR'

Set @ARCH_DIR = @ARCH_DIR+ Cast(@CurrentInterfaceStatusNum as sysname)+ '_IMAPS_TO_CLS_ASCII.txt'

EXEC  [dbo].[XX_SEND_STATUS_MAIL_SP] @in_StatusRecordNum = @CurrentInterfaceStatusNum, 
 @in_Attachments =  @ARCH_DIR 
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

	--  update status record with failed
	EXEC dbo.XX_UPDATE_INT_STATUS_RECORD
	@in_STATUS_RECORD_NUM  = @CurrentInterfaceStatusNum,
	@in_STATUS_CODE     =  @InterfaceFailedExecutionStatus,
	@in_STATUS_DESCRIPTION =  @out_STATUS_DESCRIPTION
	

	EXEC  [dbo].[XX_SEND_STATUS_MAIL_SP] @in_StatusRecordNum = @CurrentInterfaceStatusNum
RETURN 1

 

GO
 


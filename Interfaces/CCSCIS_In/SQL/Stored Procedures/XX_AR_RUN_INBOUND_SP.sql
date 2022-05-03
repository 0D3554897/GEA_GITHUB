USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_AR_RUN_INBOUND_SP]    Script Date: 4/23/2020 11:25:47 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS (SELECT * FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[DBO].[XX_AR_RUN_INBOUND_SP]') AND OBJECTPROPERTY(ID, N'ISPROCEDURE') = 1)
   DROP PROCEDURE [DBO].[XX_AR_RUN_INBOUND_SP]
GO

CREATE PROCEDURE [dbo].[XX_AR_RUN_INBOUND_SP] AS

/****************************************************************************************************
Name:       XX_AR_RUN_INBOUND_SP
Author:     KM
Created:    11/18/2005
Purpose:    This stored procedure serves as a script to run and drive all necessary tasks to
            to perform the CCIS interface with IMAPS.
		select * from xx_lookup_detail
Parameters: 
Result Set: None
Notes:

CP600000199 02/08/2008 Reference BP&S Service Request: DR1427
            Enable more users to be notified by e-mail upon specific interface run events. Change
            the size of @IN_DESTINATION_SYSOWNER from sysname to varchar(300).
****************************************************************************************************/

BEGIN

DECLARE @SP_NAME                        sysname,
        @TOTAL_NUM_OF_EXEC_STEPS        integer,

        @IN_SOURCE_SYSOWNER             sysname,
        @IN_FINANCE_ANALYST             sysname,
        @IN_DESTINATION_SYSOWNER        varchar(300),
        @IMAPS_SCHEMA_OWNER             sysname,
       -- @IN_USER_NAME                   sysname,
       -- @IN_USER_PASSWORD               sysname,

        @SERVER_NAME                    sysname,
        @IMAPS_DB_NAME                  sysname,
        @AR_COLLECTION_INTERFACE_NAME   varchar(50),
        @INBOUND_INT_TYPE               char(1),
        @INT_DEST_SYSTEM                varchar(50),
        @LOOKUP_DOMAIN_BMS_IW_CTRL_PT   varchar(30),

        @INTERFACE_STATUS_SUCCESS       varchar(20),
        @INTERFACE_STATUS_COMPLETED     varchar(20),
        @INTERFACE_STATUS_FAILED        varchar(20),

        @current_STATUS_RECORD_NUM      integer,
        @current_STATUS_DESCRIPTION     varchar(240),
        @last_issued_STATUS_RECORD_NUM  integer,       -- XX_IMAPS_INT_STATUS.STATUS_RECORD_NUM
        @last_issued_STATUS_CODE        varchar(20),   -- XX_IMAPS_INT_STATUS.STATUS_CODE
        @last_issued_CONTROL_PT_ID      varchar(20),   -- XX_IMAPS_INT_CONTROL.CONTROL_PT_ID
        @current_execution_step         integer,
        @execution_step_sp_name         sysname,
        @called_SP_name                 sysname,
        @current_CTRL_PT_ID             varchar(20),

        @ret_code                       integer,
        @SQLServer_error_code           integer,
        @SQLServer_error_msg_text       varchar(275),
        @row_count                      integer

-- set local constants
SET @SP_NAME = 'XX_AR_RUN_INBOUND_SP'
SET @TOTAL_NUM_OF_EXEC_STEPS = 5
SET @SERVER_NAME = @@servername
SET @IMAPS_DB_NAME = db_name()
SET @AR_COLLECTION_INTERFACE_NAME = 'AR_COLLECTION'
SET @INBOUND_INT_TYPE = 'I' -- Inbound
SET @INT_DEST_SYSTEM = 'IMAPS'
SET @LOOKUP_DOMAIN_BMS_IW_CTRL_PT = 'LD_AR_CCIS_INTERFACE_CTRL_PT'
SET @INTERFACE_STATUS_SUCCESS = 'SUCCESS'
SET @INTERFACE_STATUS_COMPLETED = 'COMPLETED'
SET @INTERFACE_STATUS_FAILED = 'FAILED'

SET NOCOUNT ON

-- Retrieve necessary parameter data to run the BMS-IW interface
SELECT 	@IN_SOURCE_SYSOWNER = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @AR_COLLECTION_INTERFACE_NAME
AND	PARAMETER_NAME	= 'IN_SOURCE_SYSOWNER'

SELECT 	@IN_DESTINATION_SYSOWNER = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @AR_COLLECTION_INTERFACE_NAME
AND	PARAMETER_NAME	= 'IN_DESTINATION_SYSOWNER'

SELECT 	@IMAPS_SCHEMA_OWNER = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @AR_COLLECTION_INTERFACE_NAME
AND	PARAMETER_NAME	= 'IMAPS_SCHEMA_OWNER'

/*
CR3548 

SELECT 	@IN_USER_NAME = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @AR_COLLECTION_INTERFACE_NAME
AND	PARAMETER_NAME	= 'IN_USER_NAME'

SELECT 	@IN_USER_PASSWORD = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @AR_COLLECTION_INTERFACE_NAME
AND	PARAMETER_NAME	= 'IN_USER_PASSWORD'
*/

/*
 * Check status of the last interface job: if it is not completed, perform recovery
 * by picking up processing from the last sucessful control point.
 */

PRINT 'Check status of the last interface job ...'

-- retrieve the execution result data of the last interface run or job
SELECT @last_issued_STATUS_RECORD_NUM = STATUS_RECORD_NUM,
       @last_issued_STATUS_CODE = STATUS_CODE
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE INTERFACE_NAME = @AR_COLLECTION_INTERFACE_NAME
   AND CREATED_DATE   = (SELECT MAX(s.CREATED_DATE) 
                           FROM dbo.XX_IMAPS_INT_STATUS s
                          WHERE s.INTERFACE_NAME = @AR_COLLECTION_INTERFACE_NAME)

SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

IF @SQLServer_error_code > 0 or @row_count > 1
   GOTO BL_ERROR_HANDLER

IF @last_issued_STATUS_RECORD_NUM IS NULL
   BEGIN
      PRINT 'There was no last interface job to consider.'

      SELECT @last_issued_STATUS_RECORD_NUM = COUNT(1)
        FROM dbo.XX_IMAPS_INT_STATUS
       WHERE INTERFACE_NAME = @AR_COLLECTION_INTERFACE_NAME

      IF @last_issued_STATUS_RECORD_NUM = 0
         SET @last_issued_STATUS_CODE = @INTERFACE_STATUS_COMPLETED
      ELSE
        GOTO BL_ERROR_HANDLER
   END

IF @last_issued_STATUS_CODE <> @INTERFACE_STATUS_COMPLETED -- e.g., INITIATED, SUCCESS, FAILED
   BEGIN
      PRINT 'The last interface job was incomplete. Determine the next execution step ...'

      -- retrieve data recorded for the last successful control point	
      SELECT @last_issued_CONTROL_PT_ID = CONTROL_PT_ID
        FROM dbo.XX_IMAPS_INT_CONTROL
       WHERE STATUS_RECORD_NUM  = @last_issued_STATUS_RECORD_NUM
         AND INTERFACE_NAME     = @AR_COLLECTION_INTERFACE_NAME
         AND CONTROL_PT_STATUS  = @INTERFACE_STATUS_SUCCESS
         AND CONTROL_RECORD_NUM = (select MAX(c.CONTROL_RECORD_NUM) 
                                     from dbo.XX_IMAPS_INT_CONTROL c
                                    where c.STATUS_RECORD_NUM = @last_issued_STATUS_RECORD_NUM
                                      and c.INTERFACE_NAME    = @AR_COLLECTION_INTERFACE_NAME
                                      and c.CONTROL_PT_STATUS = @INTERFACE_STATUS_SUCCESS)

      SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

      IF @SQLServer_error_code > 0
         GOTO BL_ERROR_HANDLER

      IF @last_issued_CONTROL_PT_ID IS NULL -- no control point was ever passed successfully
         SET @current_execution_step = 1
      ELSE -- at least one control points was passed successfully
         BEGIN
            -- determine the next execution step where the interface run resumes
            SELECT @current_execution_step = t1.PRESENTATION_ORDER + 1
              FROM dbo.XX_LOOKUP_DETAIL t1,
                   dbo.XX_LOOKUP_DOMAIN t2
             WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
               AND t1.APPLICATION_CODE = @last_issued_CONTROL_PT_ID
               AND t2.DOMAIN_CONSTANT  = @LOOKUP_DOMAIN_BMS_IW_CTRL_PT
         END

      SET @current_STATUS_RECORD_NUM = @last_issued_STATUS_RECORD_NUM
   END
ELSE
-- GETTING THE FILES FROM SFTP IS NOT A CONTROL POINT.  HOWEVER, THE FILES MUST BE FETCHED FOR THE PROCESS TO COMPLETE'
-- THEREFORE, WE DO IT HERE

IF @current_STATUS_RECORD_NUM IS NULL -- this is the very first time that this interface job is run
   BEGIN
      PRINT 'Begin processing for the current ' + @AR_COLLECTION_INTERFACE_NAME + ' interface run ...'

      /*
       * call XX_INSERT_INT_STATUS_RECORD to get XX_IMAPS_INT_STATUS.STATUS_RECORD_NUM
       * Each interface run has exactly one XX_IMAPS_INT_STATUS record created and is subsequently updated
       * as many times as needed. When first created, XX_IMAPS_INT_STATUS.STATUS_CODE = 'INITIATED'.
       */ 
      EXEC @ret_code = dbo.XX_INSERT_INT_STATUS_RECORD
         @in_IMAPS_db_name      = @IMAPS_DB_NAME,
         @in_IMAPS_table_owner  = @IMAPS_SCHEMA_OWNER,
         @in_int_name           = @AR_COLLECTION_INTERFACE_NAME,
         @in_int_type           = 'I',
         @in_int_source_sys     = 'CCIS',
         @in_int_dest_sys       = 'IMAPS',
         @in_Data_FName         = 'N/A',
         @in_int_source_owner   = @IN_SOURCE_SYSOWNER,
         @in_int_dest_owner     = @IN_DESTINATION_SYSOWNER,
         @out_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM OUTPUT

      IF @ret_code <> 0 GOTO BL_ERROR_HANDLER
   END

   EXEC @ret_code = dbo.XX_AR_SFTP_INBOUND_SP
			@in_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM

   IF @ret_code <> 0 GOTO BL_ERROR_HANDLER

-- IF GETTING FILE IS SUCCESSFUL, WE CAN BEGIN TO EXECUTE CONTROL POINTS
   PRINT 'SFTP COMPLETED SUCCESSFULLY. NOW BEGIN PROCESSING CONTROL POINTS'

   SET @current_execution_step = 1 -- may proceed with the current interface job

--PRINT 'Next execution step to resume: @current_execution_step = ' + CAST(@current_execution_step as char(1))

WHILE @current_execution_step <= @TOTAL_NUM_OF_EXEC_STEPS
   BEGIN
      SELECT @execution_step_sp_name =
             CASE @current_execution_step
                WHEN 1 THEN 'dbo.XX_AR_CCIS_LOAD_SP'
                WHEN 2 THEN 'dbo.XX_AR_CCIS_PROCESS_SP'
                WHEN 3 THEN 'dbo.XX_AR_CCIS_VALIDATE_RECPTS_SP'
                WHEN 4 THEN 'dbo.XX_AR_CCIS_LOAD_CASH_RECPTS_SP'
                WHEN 5 THEN 'dbo.XX_AR_CCIS_ARCHIVE_SP'
             END

      SET @called_SP_name = @execution_step_sp_name


      /*
       * Do not subject processing of any control points  to the automatic rollback service provided by SQL Server.
       * The called SP has its own "manual rollback" service.
       * The SP's that make changes do so outside of SQL Server via XP_CMDSHELL
       */
    
    EXEC @ret_code = @execution_step_sp_name
       @in_STATUS_RECORD_NUM     = @current_STATUS_RECORD_NUM,
       @out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
       @out_STATUS_DESCRIPTION   = @current_STATUS_DESCRIPTION OUTPUT

    IF @ret_code <> 0 -- SP call results in error
       GOTO BL_ERROR_HANDLER

      PRINT 'Update the XX_IMAPS_INT_STATUS record with the latest control point processing result ...'

      SELECT @current_CTRL_PT_ID = t1.APPLICATION_CODE
        FROM dbo.XX_LOOKUP_DETAIL t1,
             dbo.XX_LOOKUP_DOMAIN t2
       WHERE t1.LOOKUP_DOMAIN_ID   = t2.LOOKUP_DOMAIN_ID         AND t1.PRESENTATION_ORDER = @current_execution_step
         AND t2.DOMAIN_CONSTANT    = @LOOKUP_DOMAIN_BMS_IW_CTRL_PT

      SET @current_STATUS_DESCRIPTION = 'INFORMATION: Processing for control point ' + @current_CTRL_PT_ID + ' completed successfully.'

      EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
         @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
         @in_STATUS_CODE        = @INTERFACE_STATUS_SUCCESS,
         @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION

      -- insert a XX_IMAPS_INT_CONTROL record for the successfully passed control point
      EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
         @in_int_ctrl_pt_num     = @current_execution_step,
         @in_lookup_domain_const = @LOOKUP_DOMAIN_BMS_IW_CTRL_PT,
         @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM

      IF @ret_code <> 0 -- the sp call results in error
         GOTO BL_ERROR_HANDLER

      SET @current_execution_step = @current_execution_step + 1

   END /* WHILE @current_execution_step <= @TOTAL_NUM_OF_EXEC_STEPS */

PRINT 'Final update to XX_IMAPS_INT_STATUS ...'

-- mark the current interface run as completed
EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
   @in_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM,
   @in_STATUS_CODE       = @INTERFACE_STATUS_COMPLETED

IF @ret_code <> 0 -- SP call results in error
   GOTO BL_ERROR_HANDLER

EXEC @ret_code = dbo.XX_SEND_STATUS_MAIL_SP
   @in_StatusRecordNum = @current_STATUS_RECORD_NUM

IF @ret_code <> 0 -- SP call results in error
   GOTO BL_ERROR_HANDLER

SET NOCOUNT OFF
RETURN(0)

BL_ERROR_HANDLER:

/*
 * When the called SP returns status 1, it has already handled the error itself.
 * When the called SP returns status that is greater than 1, it did not complete the handling of the error itself.
 */

-- handle specific exception from SFTP
 IF @ret_code = 562 AND @current_STATUS_DESCRIPTION is NULL 
    BEGIN
		SET @ret_code = 301 -- An error has occured. Please contact system administrator.
		PRINT 'CHECK EXECUTION OF SFTP. LIKELY FAILURE THERE'
		RETURN(562)
	END

IF @ret_code = 1 AND @current_STATUS_DESCRIPTION is NULL 
    BEGIN
		SET @ret_code = 301 -- An error has occured. Please contact system administrator.
	END

IF @SQLServer_error_code = 0
   SET @SQLServer_error_code = NULL

IF @ret_code <> 1 -- errors that were not handled by the called SP
   BEGIN
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = @ret_code,
         @in_SQLServer_error_code = @SQLServer_error_code,
         @in_display_requested    = 1,
         @in_calling_object_name  = @called_SP_name,
         @out_msg_text            = @current_STATUS_DESCRIPTION OUTPUT,
         @out_syserror_msg_text   = @SQLServer_error_msg_text OUTPUT

      IF @SQLServer_error_msg_text is NOT NULL
         SET @current_STATUS_DESCRIPTION = RTRIM(@current_STATUS_DESCRIPTION) + ' ' + @SQLServer_error_msg_text
   END

EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
   @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
   @in_STATUS_CODE        = @INTERFACE_STATUS_FAILED,
   @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION

EXEC dbo.XX_SEND_STATUS_MAIL_SP
   @in_StatusRecordNum = @current_STATUS_RECORD_NUM

SET NOCOUNT OFF
RETURN(1)
END


GO


SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_7KEYS_RUN_INTERFACE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_7KEYS_RUN_INTERFACE_SP]
GO








CREATE PROCEDURE dbo.XX_7KEYS_RUN_INTERFACE_SP
(
@in_FY_CD      varchar(6) = NULL,
@in_period_num smallint   = NULL
)
AS

/****************************************************************************************************
Name:       XX_7KEYS_RUN_INTERFACE_SP
Author:     HVT
Created:    11/04/2005
Purpose:    This stored procedure serves as a script to run and drive all necessary tasks to
            to produce an output file from IMAPS for 7KEYS/PSP DB system's consumption.
            Interface run is of two types, scheduled and manual/requested. For a manual run, the user
            must supply both the FY code and the period number as report data selection criteria.
Parameters: 
Result Set: None
Notes:      Examples of stored procedure call follow.

            Example 1: Run the interface in scheduled mode. This has the same effects as Example 2.
               EXEC XX_7KEYS_RUN_INTERFACE_SP

            Example 2: Run the interface in scheduled mode. This has the same effects as Example 1.
               EXEC XX_7KEYS_RUN_INTERFACE_SP
                  @in_FY_CD = null,
                  @in_period_num = null

            Example 3: Run the interface in manual mode.
               EXEC XX_7KEYS_RUN_INTERFACE_SP
                  @in_FY_CD = '2005',
                  @in_period_num = 8

Defect 647: When an interface run encounters errors and recovery must be performed, make sure that
            in between control points, when the user may execute the interface again and again,
            the user-supplied input parameter values remain consistent with the input parameter
            values recorded in the first attempt to run the interface.

CP600000199 02/08/2008 Reference BP&S Service Request: DR1427
            Enable more users to be notified by e-mail upon specific interface run events.
            Change the size of @OUT_DESTINATION_SYSOWNER from sysname to varchar(300).
****************************************************************************************************/

DECLARE @SP_NAME                        sysname,
        @TOTAL_NUM_OF_EXEC_STEPS        integer,
        @current_run_FY_CD              varchar(6),
        @current_run_PD_NO              smallint,
        @current_run_type_id            integer,

        @IMAPS_SCHEMA_OWNER             sysname,
        @IN_SOURCE_SYSOWNER             sysname,
        @OUT_DESTINATION_SYSOWNER       varchar(300),

        @SERVER_NAME                    sysname,
        @IMAPS_DB_NAME                  sysname,
        @7KEYS_INTERFACE_NAME           varchar(50),
        @OUTBOUND_INT_TYPE              char(1),
        @INT_DEST_SYSTEM                varchar(50),
        @LOOKUP_DOMAIN_7KEYS_CTRL_PT    varchar(30),

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
SET @SP_NAME = 'XX_7KEYS_RUN_INTERFACE_SP'
SET @TOTAL_NUM_OF_EXEC_STEPS = 3

SET @SERVER_NAME = @@servername
SET @IMAPS_DB_NAME = db_name()
SET @7KEYS_INTERFACE_NAME = '7KEYS/PSP'
SET @OUTBOUND_INT_TYPE = 'O' -- Outbound
SET @INT_DEST_SYSTEM = '7KEYS/PSP'
SET @LOOKUP_DOMAIN_7KEYS_CTRL_PT = 'LD_7KEYS_INTERFACE_CTRL_PT'
SET @INTERFACE_STATUS_SUCCESS = 'SUCCESS'
SET @INTERFACE_STATUS_COMPLETED = 'COMPLETED'
SET @INTERFACE_STATUS_FAILED = 'FAILED'

SET NOCOUNT ON

PRINT 'Retrieve necessary parameter data to run the 7KEYS/PSP interface ...'

EXEC @ret_code = dbo.XX_7KEYS_GET_PROCESSING_PARAMS_SP
   @out_IMAPS_SCHEMA_OWNER       = @IMAPS_SCHEMA_OWNER       OUTPUT,
   @out_IN_SOURCE_SYSOWNER       = @IN_SOURCE_SYSOWNER       OUTPUT,
   @out_OUT_DESTINATION_SYSOWNER = @OUT_DESTINATION_SYSOWNER OUTPUT

IF @ret_code <> 0 -- the called SP returns an error status
   GOTO BL_ERROR_HANDLER

-- make sure that the required 7KEYS/PSP interface resources exist
EXEC @ret_code = dbo.XX_7KEYS_CHK_RESOURCES_SP

IF @ret_code <> 0
   GOTO BL_ERROR_HANDLER

EXEC @ret_code = dbo.XX_7KEYS_PROCESS_RUN_INPUT_SP
   @in_FY_CD               = @in_FY_CD,
   @in_period_num          = @in_period_num,
   @out_FY_CD              = @current_run_FY_CD OUTPUT,
   @out_period_num         = @current_run_PD_NO OUTPUT,
   @out_run_type_id        = @current_run_type_id OUTPUT,
   @out_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION OUTPUT

IF @ret_code <> 0
   GOTO BL_ERROR_HANDLER

/*
 * Check status of the last interface job: if it is not completed, perform recovery
 * by picking up processing from the last sucessful control point.
 */

PRINT 'Check status of the last interface job ...'

-- retrieve the execution result data of the last interface run or job
SELECT @last_issued_STATUS_RECORD_NUM = STATUS_RECORD_NUM,
       @last_issued_STATUS_CODE = STATUS_CODE
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE INTERFACE_NAME = @7KEYS_INTERFACE_NAME
   AND CREATED_DATE   = (SELECT MAX(s.CREATED_DATE) 
                           FROM dbo.XX_IMAPS_INT_STATUS s
                          WHERE s.INTERFACE_NAME = @7KEYS_INTERFACE_NAME)

SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

IF @SQLServer_error_code > 0 or @row_count > 1
   GOTO BL_ERROR_HANDLER

IF @last_issued_STATUS_RECORD_NUM IS NULL
   BEGIN
      PRINT 'There wasn''t any last interface job to consider.'

      SELECT @last_issued_STATUS_RECORD_NUM = COUNT(1)
        FROM dbo.XX_IMAPS_INT_STATUS
       WHERE INTERFACE_NAME = @7KEYS_INTERFACE_NAME

      IF @last_issued_STATUS_RECORD_NUM = 0
         SET @last_issued_STATUS_CODE = @INTERFACE_STATUS_COMPLETED
      ELSE
        GOTO BL_ERROR_HANDLER
   END

IF @last_issued_STATUS_CODE <> @INTERFACE_STATUS_COMPLETED -- e.g., INITIATED, SUCCESS, FAILED
   BEGIN
      PRINT 'The last interface job was incomplete. Determine the next execution step ...'

-- Defect 647 Begin
      /*
       * Verify that the current input parameter values are the same as the ones already recorded
       * in the first attempted run for this interface job which is now undergoing recovery due to errors.
       */
      EXEC @ret_code = dbo.XX_7KEYS_PROCESS_RUN_INPUT_SP
         @in_FY_CD               = @current_run_FY_CD,
         @in_period_num          = @current_run_PD_NO,
         @in_RUN_TYPE_ID         = @current_run_type_id,
         @in_STATUS_RECORD_NUM   = @last_issued_STATUS_RECORD_NUM,
         @out_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION OUTPUT

      IF @ret_code <> 0 GOTO BL_ERROR_HANDLER

-- Defect 647 End

      -- retrieve data recorded for the last successful control point	
      SELECT @last_issued_CONTROL_PT_ID = CONTROL_PT_ID
        FROM dbo.XX_IMAPS_INT_CONTROL
       WHERE STATUS_RECORD_NUM  = @last_issued_STATUS_RECORD_NUM
         AND INTERFACE_NAME     = @7KEYS_INTERFACE_NAME
         AND CONTROL_PT_STATUS  = @INTERFACE_STATUS_SUCCESS
         AND CONTROL_RECORD_NUM = (select MAX(c.CONTROL_RECORD_NUM) 
                                     from dbo.XX_IMAPS_INT_CONTROL c
                                    where c.STATUS_RECORD_NUM = @last_issued_STATUS_RECORD_NUM
                                      and c.INTERFACE_NAME    = @7KEYS_INTERFACE_NAME
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
               AND t2.DOMAIN_CONSTANT  = @LOOKUP_DOMAIN_7KEYS_CTRL_PT
         END

      SET @current_STATUS_RECORD_NUM = @last_issued_STATUS_RECORD_NUM
   END
ELSE
   SET @current_execution_step = 1 -- may proceed with the current interface job

--PRINT 'Next execution step to resume: @current_execution_step = ' + CAST(@current_execution_step as char(1))

IF @current_STATUS_RECORD_NUM IS NULL -- this is the very first time that this interface job is run
   BEGIN
      PRINT 'Begin processing for the current ' + @7KEYS_INTERFACE_NAME + ' interface run ...'

      /*
       * call XX_INSERT_INT_STATUS_RECORD to get XX_IMAPS_INT_STATUS.STATUS_RECORD_NUM
       * Each interface run has exactly one XX_IMAPS_INT_STATUS record created and is subsequently updated
       * as many times as needed. When first created, XX_IMAPS_INT_STATUS.STATUS_CODE = 'INITIATED'.
       */ 
      EXEC @ret_code = dbo.XX_INSERT_INT_STATUS_RECORD
         @in_IMAPS_db_name      = @IMAPS_DB_NAME,
         @in_IMAPS_table_owner  = @IMAPS_SCHEMA_OWNER,
         @in_int_name           = @7KEYS_INTERFACE_NAME,
         @in_int_type           = @OUTBOUND_INT_TYPE,
         @in_int_source_sys     = 'IMAPS',
         @in_int_dest_sys       = @INT_DEST_SYSTEM,
         @in_Data_FName         = 'N/A',
         @in_int_source_owner   = @IN_SOURCE_SYSOWNER,
         @in_int_dest_owner     = @OUT_DESTINATION_SYSOWNER,
         @out_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM OUTPUT

      IF @ret_code <> 0 GOTO BL_ERROR_HANDLER

-- Defect 647 Begin
      /*
       * Insert a XX_7KEYS_RUN_LOG record now so that if the interface run encounters errors and recovery must be performed,
       * then there is an established record of the user's "original" input parameter values to prevent changes of these
       * values in between control points.
       */
      EXEC @ret_code = dbo.XX_7KEYS_LOG_RUN_DATA_SP
         @in_STATUS_RECORD_NUM     = @current_STATUS_RECORD_NUM,
         @in_FY_CD                 = @current_run_FY_CD,
         @in_period_num            = @current_run_PD_NO,
         @in_run_type_id           = @current_run_type_id,
         @out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
         @out_STATUS_DESCRIPTION   = @current_STATUS_DESCRIPTION OUTPUT

      IF @ret_code <> 0 GOTO BL_ERROR_HANDLER

-- Defect 647 End

   END

WHILE @current_execution_step <= @TOTAL_NUM_OF_EXEC_STEPS
   BEGIN
      SELECT @execution_step_sp_name =
             CASE @current_execution_step
                WHEN 1 THEN 'dbo.XX_7KEYS_GET_OUTPUT_DATA_SP'
                WHEN 2 THEN 'dbo.XX_7KEYS_BUILD_OUTPUT_FILE_SP'
                WHEN 3 THEN 'dbo.XX_7KEYS_ARCHIVE_MOVE_OUTPUT_SP'
             END

      SET @called_SP_name = @execution_step_sp_name

      BEGIN TRANSACTION CURRENT_CTRL_PT

      IF @current_execution_step = 1
         EXEC @ret_code = @execution_step_sp_name
            @in_STATUS_RECORD_NUM     = @current_STATUS_RECORD_NUM,
            @in_FY_CD                 = @current_run_FY_CD,
            @in_period_num            = @current_run_PD_NO,
            @out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
            @out_STATUS_DESCRIPTION   = @current_STATUS_DESCRIPTION OUTPUT

-- Defect 647 Begin
      ELSE IF @current_execution_step = 3
         IF @last_issued_STATUS_CODE = @INTERFACE_STATUS_FAILED
            EXEC @ret_code = dbo.XX_7KEYS_CHK_OUTPUT_FILES_SP
               @in_STATUS_RECORD_NUM     = @current_STATUS_RECORD_NUM,
               @out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
               @out_STATUS_DESCRIPTION   = @current_STATUS_DESCRIPTION OUTPUT
         ELSE
            EXEC @ret_code = dbo.XX_7KEYS_ARCHIVE_MOVE_OUTPUT_SP
               @in_STATUS_RECORD_NUM     = @current_STATUS_RECORD_NUM,
               @out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
               @out_STATUS_DESCRIPTION   = @current_STATUS_DESCRIPTION OUTPUT
-- Defect 647 End

      ELSE
         EXEC @ret_code = @execution_step_sp_name
            @in_STATUS_RECORD_NUM     = @current_STATUS_RECORD_NUM,
            @out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
            @out_STATUS_DESCRIPTION   = @current_STATUS_DESCRIPTION OUTPUT

      IF @ret_code <> 0 -- the called SP returns an error status
         BEGIN
            ROLLBACK TRANSACTION CURRENT_CTRL_PT
            GOTO BL_ERROR_HANDLER
         END
      ELSE -- SP call is successful
         COMMIT TRANSACTION CURRENT_CTRL_PT

      PRINT 'Update the XX_IMAPS_INT_STATUS record with the latest control point processing result ...'

      SELECT @current_CTRL_PT_ID = t1.APPLICATION_CODE
        FROM dbo.XX_LOOKUP_DETAIL t1,
             dbo.XX_LOOKUP_DOMAIN t2
       WHERE t1.LOOKUP_DOMAIN_ID   = t2.LOOKUP_DOMAIN_ID
         AND t1.PRESENTATION_ORDER = @current_execution_step
         AND t2.DOMAIN_CONSTANT    = @LOOKUP_DOMAIN_7KEYS_CTRL_PT

      SET @current_STATUS_DESCRIPTION = 'INFORMATION: Processing for control point ' + @current_CTRL_PT_ID + ' completed successfully.'

      EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
         @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
         @in_STATUS_CODE        = @INTERFACE_STATUS_SUCCESS,
         @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION

      -- insert a XX_IMAPS_INT_CONTROL record for the successfully passed control point
      EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
         @in_int_ctrl_pt_num     = @current_execution_step,
         @in_lookup_domain_const = @LOOKUP_DOMAIN_7KEYS_CTRL_PT,
         @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM

      IF @ret_code <> 0
         GOTO BL_ERROR_HANDLER

      SET @current_execution_step = @current_execution_step + 1

   END /* WHILE @current_execution_step <= @TOTAL_NUM_OF_EXEC_STEPS */

-- Defect 647 Begin

-- Move code to the part where the XX_INSERT_INT_STATUS_RECORD record is inserted

/*
-- Insert a record into table XX_7KEYS_RUN_LOG
EXEC @ret_code = dbo.XX_7KEYS_LOG_RUN_DATA_SP
   @in_STATUS_RECORD_NUM     = @current_STATUS_RECORD_NUM,
   @in_FY_CD                 = @current_run_FY_CD,
   @in_period_num            = @current_run_PD_NO,
   @in_run_type_id           = @current_run_type_id,
   @out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
   @out_STATUS_DESCRIPTION   = @current_STATUS_DESCRIPTION OUTPUT

IF @ret_code <> 0
   GOTO BL_ERROR_HANDLER
*/
-- Defect 647 End

PRINT 'Final update to XX_IMAPS_INT_STATUS ...'

-- mark the current interface run as completed
EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
   @in_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM,
   @in_STATUS_CODE       = @INTERFACE_STATUS_COMPLETED

IF @ret_code <> 0
   GOTO BL_ERROR_HANDLER

EXEC @ret_code = dbo.XX_SEND_STATUS_MAIL_SP
   @in_StatusRecordNum = @current_STATUS_RECORD_NUM

IF @ret_code <> 0
   GOTO BL_ERROR_HANDLER

SET NOCOUNT OFF
RETURN(0)

BL_ERROR_HANDLER:

/*
 * When the called SP returns status 1, it has already handled the error itself.
 * When the called SP returns status that is greater than 1, it did not complete the handling of the error itself.
 */

IF @ret_code = 1 AND @current_STATUS_DESCRIPTION is NULL 
   SET @ret_code = 301 -- An error has occured. Please contact system administrator.

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

IF @execution_step_sp_name IS NOT NULL
   BEGIN
      EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
         @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
         @in_STATUS_CODE        = @INTERFACE_STATUS_FAILED,
         @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION

      EXEC dbo.XX_SEND_STATUS_MAIL_SP
         @in_StatusRecordNum = @current_STATUS_RECORD_NUM
   END

SET NOCOUNT OFF
RETURN(1)






GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_RETRORATE_RUN_INTERFACE_SP    Script Date: 01/25/2006 3:24:10 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_RETRORATE_RUN_INTERFACE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   drop procedure [dbo].[XX_RETRORATE_RUN_INTERFACE_SP]
GO


CREATE PROCEDURE dbo.XX_RETRORATE_RUN_INTERFACE_SP
(
@in_year         char(4)  = NULL,
@in_process_date char(10) = NULL
)
AS
/****************************************************************************************************
Name:       XX_RETRORATE_RUN_INTERFACE_SP
Author:     HVT
Created:    11/04/2005
Purpose:    This stored procedure serves as a script to run and drive all necessary tasks to process
            Retro Cost Rate Change.

Parameters: 
Result Set: None
Notes:      Examples of stored procedure call follow.

            Example 1: Run the interface in scheduled mode. This has the same effects as Example 2.
               EXEC XX_RETRORATE_RUN_INTERFACE_SP

            Example 2: Run the interface in scheduled mode. This has the same effects as Example 1.
               EXEC XX_RETRORATE_RUN_INTERFACE_SP
                  @in_year = null,
                  @in_process_date = null

            Example 3: Run the interface in manual mode.
               EXEC XX_RETRORATE_RUN_INTERFACE_SP
                  @in_year = '2005',
                  @in_process_date = '01-03-2006'

Defect 559  Code changes.
Defect 592  Update the XX_IMAPS_INT_STATUS record with processing statistics.
Defect 612  Fix the display of the count values.
****************************************************************************************************/

DECLARE @SP_NAME                         sysname,
        @ETIME_INTERFACE_NAME            varchar(50),
        @RETRORATE_INTERFACE_NAME        varchar(50),
        @TOTAL_NUM_OF_EXEC_STEPS         integer,
        @INTERFACE_STATUS_SUCCESS        varchar(20),
        @INTERFACE_STATUS_COMPLETED      varchar(20),
        @INTERFACE_STATUS_FAILED         varchar(20),
        @INTERFACE_STATUS_CPIN_PROGRESS  varchar(20),
        @IMAPS_SCHEMA_OWNER              sysname,
        @IN_SOURCE_SYSOWNER              sysname,
        @OUT_DESTINATION_SYSOWNER        sysname,
        @SERVER_NAME                     sysname,
        @IMAPS_DB_NAME                   sysname,
        @INBOUND_INT_TYPE                char(1),
        @INT_DEST_SYSTEM                 varchar(50),
        @LOOKUP_DOMAIN_RETRORATE_CTRL_PT varchar(30),
        @current_STATUS_RECORD_NUM       integer,
        @current_STATUS_DESCRIPTION      varchar(240),
        @last_issued_STATUS_RECORD_NUM   integer,
        @last_issued_STATUS_CODE         varchar(20),
        @last_issued_CONTROL_PT_ID       varchar(20),
        @current_execution_step          integer,
        @execution_step_sp_name          sysname,
        @called_SP_name                  sysname,
        @current_CTRL_PT_ID              varchar(20),
        @ret_code                        integer,
        @SQLServer_error_code            integer,
        @SQLServer_error_msg_text        varchar(275),
        @job_status_msg                  varchar(255),
        @row_count                       integer

-- set local constants
SET @SP_NAME = 'XX_RETRORATE_RUN_INTERFACE_SP'
SET @TOTAL_NUM_OF_EXEC_STEPS = 4
SET @ETIME_INTERFACE_NAME = 'ETIME'
SET @RETRORATE_INTERFACE_NAME = 'RETRORATE'

SET @SERVER_NAME = @@servername
SET @IMAPS_DB_NAME = db_name()
SET @IMAPS_SCHEMA_OWNER = 'dbo'
SET @IN_SOURCE_SYSOWNER = 'RATERETRO'
SET @INT_DEST_SYSTEM = 'IMAPS' 
SET @OUT_DESTINATION_SYSOWNER = 'N/A'
SET @INBOUND_INT_TYPE = 'I'
SET @LOOKUP_DOMAIN_RETRORATE_CTRL_PT = 'LD_RETRORATE_INTERFACE_CTRL_PT'
SET @INTERFACE_STATUS_SUCCESS = 'SUCCESS'
SET @INTERFACE_STATUS_COMPLETED = 'COMPLETED'
SET @INTERFACE_STATUS_FAILED = 'FAILED'
SET @INTERFACE_STATUS_CPIN_PROGRESS = 'CPIN_PROGRESS'

SET NOCOUNT ON

-- Validate the user's command line
IF @in_year IS NOT NULL AND @in_process_date IS NOT NULL
   BEGIN
      EXEC @ret_code = dbo.XX_RETRORATE_VALIDATE_USR_CMD_LINE_SP
         @in_year = @in_year,
         @in_process_date = @in_process_date,
         @out_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION OUTPUT

      IF @ret_code <> 0
         GOTO BL_ERROR_HANDLER
   END

/*
 * Verify that retro rate change data exist to run the interface only if
 * there is no unfinished Retro Rate Change interface run or job.
 */
SELECT @last_issued_STATUS_CODE = STATUS_CODE
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE INTERFACE_NAME = @RETRORATE_INTERFACE_NAME
   AND CREATED_DATE   = (SELECT MAX(s.CREATED_DATE) 
                           FROM dbo.XX_IMAPS_INT_STATUS s
                          WHERE s.INTERFACE_NAME = @RETRORATE_INTERFACE_NAME)

SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

IF @SQLServer_error_code > 0 or @row_count > 1
   GOTO BL_ERROR_HANDLER

-- Defect_559_Begin
/*
IF @last_issued_STATUS_CODE = @INTERFACE_STATUS_COMPLETED
   BEGIN
      EXEC @ret_code = dbo.XX_RETRORATE_CHECK_DATA_SP
         @in_FY = @in_year
      IF @ret_code <> 0
         RETURN(0)
   END
*/
-- Defect_559_End

/*
 * First, check status of the last or current eTime interface job: if it is not completed,
 * then this Retro Cost Rate Change interface job cannot be run at this time.
 */

PRINT 'Check current eTime interface job execution activities ...'

-- retrieve the execution result data of the last interface run or job
SELECT @last_issued_STATUS_RECORD_NUM = STATUS_RECORD_NUM,
       @last_issued_STATUS_CODE = STATUS_CODE
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE INTERFACE_NAME = @ETIME_INTERFACE_NAME
   AND CREATED_DATE   = (SELECT MAX(s.CREATED_DATE) 
                           FROM dbo.XX_IMAPS_INT_STATUS s
                          WHERE s.INTERFACE_NAME = @ETIME_INTERFACE_NAME)

SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

IF @SQLServer_error_code > 0 or @row_count > 1
   GOTO BL_ERROR_HANDLER

IF @last_issued_STATUS_CODE <> @INTERFACE_STATUS_COMPLETED -- e.g., INITIATED, SUCCESS, FAILED, CPIN_PROGRESS
   BEGIN
      SET @job_status_msg = 'WARNING: There is an eTime interface job currently undergoing execution.'
      SET @current_STATUS_DESCRIPTION = @job_status_msg + ' Retro Rate interface cannot be run at this time.'
      IF @last_issued_STATUS_CODE = @INTERFACE_STATUS_CPIN_PROGRESS
         SET @job_status_msg = @job_status_msg + CHAR(13) +
                               'The Costpoint Timesheet Preprocessor is being run for Job ID ' +
                               CAST(@last_issued_STATUS_RECORD_NUM AS varchar(12)) + '.' 
      SET @job_status_msg = @job_status_msg + CHAR(13) + 'Please reschedule your Retro Rate interface run.'
      PRINT CHAR(13)
      PRINT @job_status_msg
      PRINT CHAR(13)
      SET @ret_code = 1
      GOTO BL_ERROR_HANDLER
   END

/*
 * Check status of the last Retro Rate interface job: if it is not completed, perform recovery
 * by picking up processing from the last sucessful control point.
 */

PRINT 'Check status of the last Retro Rate interface job ...'

-- retrieve the execution result data of the last Retro Rate interface run or job
SELECT @last_issued_STATUS_RECORD_NUM = STATUS_RECORD_NUM,
       @last_issued_STATUS_CODE = STATUS_CODE
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE INTERFACE_NAME = @RETRORATE_INTERFACE_NAME
   AND CREATED_DATE   = (SELECT MAX(s.CREATED_DATE) 
                           FROM dbo.XX_IMAPS_INT_STATUS s
                          WHERE s.INTERFACE_NAME = @RETRORATE_INTERFACE_NAME)

SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

IF @SQLServer_error_code > 0 or @row_count > 1
   GOTO BL_ERROR_HANDLER

IF @last_issued_STATUS_RECORD_NUM IS NULL
   BEGIN
      PRINT 'There wasn''t any last interface job to consider.'

      SELECT @last_issued_STATUS_RECORD_NUM = COUNT(1)
        FROM dbo.XX_IMAPS_INT_STATUS
       WHERE INTERFACE_NAME = @RETRORATE_INTERFACE_NAME

      IF @last_issued_STATUS_RECORD_NUM = 0
         SET @last_issued_STATUS_CODE = @INTERFACE_STATUS_COMPLETED
      ELSE
        GOTO BL_ERROR_HANDLER
   END

IF @last_issued_STATUS_CODE <> @INTERFACE_STATUS_COMPLETED -- e.g., INITIATED, SUCCESS, FAILED
   BEGIN
      -- special case: nothing left to do, exit now
      IF @TOTAL_NUM_OF_EXEC_STEPS = 1
         BEGIN
            SET @current_STATUS_DESCRIPTION = 'WARNING: The last Retro Rate interface job was incomplete.'
            PRINT @current_STATUS_DESCRIPTION
            SET @ret_code = 1
            GOTO BL_ERROR_HANDLER
         END

      PRINT 'The last Retro Rate interface job was incomplete. Determine the next execution step ...'

      -- retrieve data recorded for the last successful control point	
      SELECT @last_issued_CONTROL_PT_ID = CONTROL_PT_ID
        FROM dbo.XX_IMAPS_INT_CONTROL
       WHERE STATUS_RECORD_NUM  = @last_issued_STATUS_RECORD_NUM
         AND INTERFACE_NAME     = @RETRORATE_INTERFACE_NAME
         AND CONTROL_PT_STATUS  = @INTERFACE_STATUS_SUCCESS
         AND CONTROL_RECORD_NUM = (select MAX(c.CONTROL_RECORD_NUM) 
                                     from dbo.XX_IMAPS_INT_CONTROL c
                                    where c.STATUS_RECORD_NUM = @last_issued_STATUS_RECORD_NUM
                                      and c.INTERFACE_NAME    = @RETRORATE_INTERFACE_NAME
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
               AND t2.DOMAIN_CONSTANT  = @LOOKUP_DOMAIN_RETRORATE_CTRL_PT
         END

      SET @current_STATUS_RECORD_NUM = @last_issued_STATUS_RECORD_NUM
   END
ELSE
   SET @current_execution_step = 1 -- may proceed with the current interface job

IF @current_STATUS_RECORD_NUM IS NULL -- this is the very first time that this interface job is run
   BEGIN
      PRINT 'Begin processing for the current ' + @RETRORATE_INTERFACE_NAME + ' interface run ...'

      /*
       * call XX_INSERT_INT_STATUS_RECORD to get XX_IMAPS_INT_STATUS.STATUS_RECORD_NUM
       * Each interface run has exactly one XX_IMAPS_INT_STATUS record created and is subsequently updated
       * as many times as needed. When first created, XX_IMAPS_INT_STATUS.STATUS_CODE = 'INITIATED'.
       */ 
      EXEC @ret_code = dbo.XX_INSERT_INT_STATUS_RECORD
         @in_IMAPS_db_name      = @IMAPS_DB_NAME,
         @in_IMAPS_table_owner  = @IMAPS_SCHEMA_OWNER,
         @in_int_name           = @RETRORATE_INTERFACE_NAME,
         @in_int_type           = @INBOUND_INT_TYPE,
         @in_int_source_sys     = @RETRORATE_INTERFACE_NAME,
         @in_int_dest_sys       = @INT_DEST_SYSTEM,
         @in_Data_FName         = 'N/A',
         @in_int_source_owner   = @IN_SOURCE_SYSOWNER,
         @in_int_dest_owner     = @OUT_DESTINATION_SYSOWNER,
         @out_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM OUTPUT

      IF @ret_code <> 0 GOTO BL_ERROR_HANDLER
   END

WHILE @current_execution_step <= @TOTAL_NUM_OF_EXEC_STEPS
   BEGIN
      SELECT @execution_step_sp_name =
             CASE @current_execution_step
                WHEN 1 THEN 'dbo.XX_RETRORATE_PREPARE_DATA_SP' -- XX_CERIS_PROCESS_RETRO_RATE_SP
                WHEN 2 THEN 'dbo.XX_RETRORATE_READY_CP_RUN_SP'
                WHEN 4 THEN 'dbo.XX_RETRORATE_PROCESS_CP_ERROR_LOG_SP'
             END

      SET @called_SP_name = @execution_step_sp_name

      BEGIN TRANSACTION CURRENT_CTRL_PT

      IF @current_execution_step = 1 -- special case: called sp has parameters to satisfy

         EXEC @ret_code = @execution_step_sp_name
-- Defect_592_Begin
            @in_STATUS_RECORD_NUM     = @current_STATUS_RECORD_NUM,
-- Defect_592_End
            @in_year                  = @in_year,
            @in_process_date          = @in_process_Date,
            @out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
            @out_STATUS_DESCRIPTION   = @current_STATUS_DESCRIPTION OUTPUT

-- Defect_559_Begin
      ELSE IF 0 <> (SELECT COUNT(1) FROM dbo.XX_RATE_RETRO_TS_PREP_TEMP)

         EXEC @ret_code = @execution_step_sp_name
-- Defect_592_Begin
            @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM,
-- Defect_592_End
            @out_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION OUTPUT

      ELSE
	 SET @ret_code = 0
-- Defect_559_End

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
         AND t2.DOMAIN_CONSTANT    = @LOOKUP_DOMAIN_RETRORATE_CTRL_PT

      SET @current_STATUS_DESCRIPTION = 'INFORMATION: Processing for control point ' + @current_CTRL_PT_ID + ' completed successfully.'

      IF @current_execution_step <> 3
         BEGIN
            EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
               @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
               @in_STATUS_CODE        = @INTERFACE_STATUS_SUCCESS,
               @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION

            IF @ret_code <> 0
               GOTO BL_ERROR_HANDLER
         END

      -- insert a XX_IMAPS_INT_CONTROL record for the successfully passed control point
      EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
         @in_int_ctrl_pt_num     = @current_execution_step,
         @in_lookup_domain_const = @LOOKUP_DOMAIN_RETRORATE_CTRL_PT,
         @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM

      IF @ret_code <> 0
         GOTO BL_ERROR_HANDLER

      SET @current_execution_step = @current_execution_step + 1

      /*
       * Stop SQL Server job execution at the successful end of control point 2
       * in order to run the Costpoint timesheet preprocessor.
       */
      IF @current_execution_step = 3 
         BEGIN
            EXEC dbo.XX_UPDATE_INT_STATUS_RECORD
               @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
               @in_STATUS_CODE        = @INTERFACE_STATUS_CPIN_PROGRESS,
               @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION
            IF @ret_code <> 0
               GOTO BL_ERROR_HANDLER
            RETURN(0)
         END

   END /* WHILE @current_execution_step <= @TOTAL_NUM_OF_EXEC_STEPS */

IF @current_execution_step = @TOTAL_NUM_OF_EXEC_STEPS
   RETURN(0)

PRINT 'Final update to XX_IMAPS_INT_STATUS ...'

EXEC dbo.XX_GET_LOOKUP_DATA
   @usr_app_code    = @INTERFACE_STATUS_COMPLETED,
   @sys_lookup_desc = @current_STATUS_DESCRIPTION OUTPUT

-- Defect_592_Begin

/*
 * Mark the current interface run as completed.
 *
 * RECORD_COUNT_TRAILER is not applicable because this interface gets input data from Costpoint tables.
 * RECORD_COUNT_INITIAL and AMOUNT_INPUT are updated in XX_RETRORATE_PREPARE_DATA_SP.
 * RECORD_COUNT_ERROR and AMOUNT_FAILED are updated in XX_RETRORATE_PROCESS_CP_ERROR_LOG_SP and again here.
 * RECORD_COUNT_SUCCESS and AMOUNT_PROCESSED are updated here.
 *
 * For readability, also update columns RECORD_COUNT_ERROR and AMOUNT_FAILED here in case they are still null
 * due to no error log file was produced by the Costpoint timesheet preprocessor function.
 *
 * Defect 612 - Add ISNULL() to display 0.00 as default.
 */
UPDATE dbo.XX_IMAPS_INT_STATUS
   SET STATUS_CODE          = @INTERFACE_STATUS_COMPLETED,
       STATUS_DESCRIPTION   = @current_STATUS_DESCRIPTION,
       RECORD_COUNT_SUCCESS = ISNULL((RECORD_COUNT_INITIAL - ISNULL(RECORD_COUNT_ERROR, 0)), 0),
       AMOUNT_PROCESSED     = ISNULL((AMOUNT_INPUT - ISNULL(AMOUNT_FAILED, 0)), 0),
       RECORD_COUNT_ERROR   = ISNULL(RECORD_COUNT_ERROR, 0),
       AMOUNT_FAILED        = ISNULL(AMOUNT_FAILED, 0),
       MODIFIED_BY          = SUSER_SNAME(),
       MODIFIED_DATE        = GETDATE()
 WHERE STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM

SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

IF @SQLServer_error_code <> 0
   BEGIN
      SET @ret_code = 1

      -- Attempt to update a XX_IMAPS_INT_STATUS record failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = 204,
         @in_SQLServer_error_code = @SQLServer_error_code,
         @in_display_requested    = 1,
         @in_placeholder_value1   = 'update',
         @in_placeholder_value2   = 'a XX_IMAPS_INT_STATUS record',
         @in_calling_object_name  = @SP_NAME,
         @out_msg_text            = @current_STATUS_DESCRIPTION OUTPUT

      GOTO BL_ERROR_HANDLER
   END

-- Defect_592_End

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
   EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
      @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
      @in_STATUS_CODE        = @INTERFACE_STATUS_FAILED,
      @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION

SET NOCOUNT OFF
RETURN(1)














GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


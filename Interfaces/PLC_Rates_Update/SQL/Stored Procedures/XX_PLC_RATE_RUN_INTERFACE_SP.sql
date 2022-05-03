USE [IMAPSStg]
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PLC_RATE_RUN_INTERFACE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   DROP PROCEDURE [dbo].[XX_PLC_RATE_RUN_INTERFACE_SP]
GO

CREATE PROCEDURE [dbo].[XX_PLC_RATE_RUN_INTERFACE_SP] AS

/****************************************************************************************************
Name:    XX_PLC_RATE_RUN_INTERFACE_SP
Author:  HVT
Created: 02/22/2018
Purpose: This stored procedure drives the execution of all required tasks to update the DDOU PLC
         (project labor cost) rates data in Costpoint.

Notes:   Reference CR-10162 (IMAPS Help Request 20180108122548) Automate the process of updating
         the DDOU PLC rates data in Costpoint.
****************************************************************************************************/

DECLARE @SP_NAME                         sysname,
        @TOTAL_NUM_OF_EXEC_STEPS         integer,
        @IMAPS_SCHEMA_OWNER              sysname,
        @SERVER_NAME                     sysname,
        @IMAPS_DB_NAME                   sysname,
        @PLC_RATES_INTERFACE_NAME        varchar(50),
        @INBOUND_INT_TYPE                char(1),
        @INT_SOURCE_SYSTEM               varchar(20),
        @INT_DEST_SYSTEM                 varchar(20),
        @Data_FName                      sysname,
        @INT_SOURCE_SYSOWNER             varchar(100),
        @INT_DESTINATION_SYSOWNER        varchar(300),
        @LOOKUP_DOMAIN_PLC_RATES_CTRL_PT varchar(30),

        @INTERFACE_STATUS_SUCCESS        varchar(20),
        @INTERFACE_STATUS_COMPLETED      varchar(20),
        @INTERFACE_STATUS_FAILED         varchar(20),

        @current_STATUS_RECORD_NUM       integer,
        @current_STATUS_DESCRIPTION      varchar(240),
        @last_issued_STATUS_RECORD_NUM   integer,
        @last_issued_STATUS_CODE         varchar(20),
        @last_issued_CONTROL_PT_ID       varchar(20),
        @current_execution_step          integer,
        @execution_step_sp_name          sysname,
        @called_SP_name                  sysname,
        @current_CTRL_PT_ID              varchar(20),
        @ctrl_pt_task_desc               varchar(140),

        @task_desc                       varchar(140),
        @fail_text                       varchar(50),
        @user_error_msg                  varchar(500),
        @SS_Error_Number                 integer,
        @SS_Error_Message                varchar(180),
        @SS_Error_Procedure              sysname,
        @SS_Error_Line                   smallint,
        @SS_Error_Severity               tinyint,
        @SS_Error_State                  smallint,
        @ret_code                        integer,
        @exec_stat                       integer,
        @xstate                          integer,
        @transaction_count               integer,
        @row_count                       integer

-- Set local constants
SET @SP_NAME = 'XX_PLC_RATE_RUN_INTERFACE_SP'
SET @TOTAL_NUM_OF_EXEC_STEPS = 3
SET @SERVER_NAME = @@servername
SET @IMAPS_DB_NAME = db_name()
SET @PLC_RATES_INTERFACE_NAME = 'PLC_RATES'
SET @INT_SOURCE_SYSTEM = 'IMAPSSTG'
SET @INT_DEST_SYSTEM = 'COSTPOINT'
SET @LOOKUP_DOMAIN_PLC_RATES_CTRL_PT = 'LD_PLC_RATE_UPDATE_CTRL_PT'
SET @INTERFACE_STATUS_SUCCESS = 'SUCCESS'
SET @INTERFACE_STATUS_COMPLETED = 'COMPLETED'
SET @INTERFACE_STATUS_FAILED = 'FAILED'
SET @INBOUND_INT_TYPE = 'I' -- Inbound
SET @Data_Fname = 'N/A'
SET @fail_text = ': Task failed.'

SET NOCOUNT ON

BEGIN TRY

PRINT 'Retrieve processing parameter data to run ' + @PLC_RATES_INTERFACE_NAME + ' interface ...'

SELECT @INT_SOURCE_SYSOWNER = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'INT_SOURCE_SYSOWNER'
   AND INTERFACE_NAME_CD = @PLC_RATES_INTERFACE_NAME

SELECT @INT_DESTINATION_SYSOWNER = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'INT_DESTINATION_SYSOWNER'
   AND INTERFACE_NAME_CD = @PLC_RATES_INTERFACE_NAME

/*
 * Check status of the last interface job: if it is not completed, perform recovery
 * by picking up processing from the last sucessful control point.
 */

PRINT 'Check status of the last interface job ...'

-- Retrieve the execution result data of the last interface run or job
SELECT @last_issued_STATUS_RECORD_NUM = STATUS_RECORD_NUM,
       @last_issued_STATUS_CODE = STATUS_CODE
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE INTERFACE_NAME = @PLC_RATES_INTERFACE_NAME
   AND CREATED_DATE   = (SELECT MAX(s.CREATED_DATE) 
                           FROM dbo.XX_IMAPS_INT_STATUS s
                          WHERE s.INTERFACE_NAME = @PLC_RATES_INTERFACE_NAME)

IF @last_issued_STATUS_RECORD_NUM IS NULL
   BEGIN
      -- Special Case: This may well be the interface's very first run.
      PRINT 'There wasn''t any last interface job to consider.'

      -- Double-check
      SELECT @row_count = COUNT(1)
        FROM dbo.XX_IMAPS_INT_STATUS
       WHERE INTERFACE_NAME = @PLC_RATES_INTERFACE_NAME

      IF @row_count = 0
         -- Set default value for the last interface job's status
         SET @last_issued_STATUS_CODE = @INTERFACE_STATUS_COMPLETED
      ELSE
         BEGIN
            SET @task_desc = 'Double-checking existence of previous interface jobs: This error should never happen!'
            RAISERROR(@task_desc, 16, 1)
         END
   END

IF @last_issued_STATUS_CODE <> @INTERFACE_STATUS_COMPLETED -- e.g., INITIATED, SUCCESS, FAILED
   BEGIN
      PRINT 'The last interface job was incomplete. Determine the next execution step ...'

      -- Retrieve data recorded for the last successful control point	
      SELECT @last_issued_CONTROL_PT_ID = CONTROL_PT_ID
        FROM dbo.XX_IMAPS_INT_CONTROL
       WHERE STATUS_RECORD_NUM  = @last_issued_STATUS_RECORD_NUM
         AND INTERFACE_NAME     = @PLC_RATES_INTERFACE_NAME
         AND CONTROL_PT_STATUS  = @INTERFACE_STATUS_SUCCESS
         AND CONTROL_RECORD_NUM = (select MAX(c.CONTROL_RECORD_NUM) 
                                     from dbo.XX_IMAPS_INT_CONTROL c
                                    where c.STATUS_RECORD_NUM = @last_issued_STATUS_RECORD_NUM
                                      and c.INTERFACE_NAME    = @PLC_RATES_INTERFACE_NAME
                                      and c.CONTROL_PT_STATUS = @INTERFACE_STATUS_SUCCESS)

      -- Interface run is in progress. No control point was ever processed successfully.
      IF @last_issued_CONTROL_PT_ID IS NULL
         BEGIN
            SET @current_execution_step = 1
            PRINT 'Interface run is in progress: No control point has ever been completed successfully.'
         END
      ELSE
         BEGIN
            -- At least one control points was passed successfully
            -- Determine the next execution step where the interface run resumes
            PRINT 'The current STATUS_RECORD_NUM IS ' + CAST(@last_issued_STATUS_RECORD_NUM as varchar) +
                  ' and the last successful control point is ' + CAST(@last_issued_CONTROL_PT_ID as varchar)

            SELECT @current_execution_step = t1.PRESENTATION_ORDER + 1
              FROM dbo.XX_LOOKUP_DETAIL t1,
                   dbo.XX_LOOKUP_DOMAIN t2
             WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
               AND t1.APPLICATION_CODE = @last_issued_CONTROL_PT_ID
               AND t2.DOMAIN_CONSTANT  = @LOOKUP_DOMAIN_PLC_RATES_CTRL_PT
         END

      SET @current_STATUS_RECORD_NUM = @last_issued_STATUS_RECORD_NUM
   END
ELSE
   BEGIN
      -- May now proceed with the new interface job
      PRINT 'JOB EXECUTION STARTING OVER AT STEP 1'
      SET @current_execution_step = 1
   END

IF @current_STATUS_RECORD_NUM IS NULL  -- Brand new interface run
   BEGIN
      PRINT 'Begin processing for the current ' + @PLC_RATES_INTERFACE_NAME + ' interface run ...'

      /*
       * Call XX_INSERT_INT_STATUS_RECORD to get a value issued for XX_IMAPS_INT_STATUS.STATUS_RECORD_NUM
       * Each interface run has exactly one XX_IMAPS_INT_STATUS record created and is subsequently updated
       * as many times as needed. When first created, XX_IMAPS_INT_STATUS.STATUS_CODE = 'INITIATED'.
       */
      SET @task_desc = 'Insert a XX_IMAPS_INT_STATUS record'
      PRINT @task_desc

      EXEC @ret_code = dbo.XX_INSERT_INT_STATUS_RECORD
         @in_IMAPS_db_name      = @IMAPS_DB_NAME,
         @in_IMAPS_table_owner  = @IMAPS_SCHEMA_OWNER,
         @in_int_name           = @PLC_RATES_INTERFACE_NAME,
         @in_int_type           = @INBOUND_INT_TYPE,
         @in_int_source_sys     = @INT_SOURCE_SYSTEM,
         @in_int_dest_sys       = @INT_DEST_SYSTEM,
         @in_Data_FName         = @Data_Fname,
         @in_int_source_owner   = @INT_SOURCE_SYSOWNER,
         @in_int_dest_owner     = @INT_DESTINATION_SYSOWNER,
         @out_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM OUTPUT

      /*
       * When an error happens in the called SP, program control goes to the CATCH block immediately.
       * COMMON_INSERT_INT_STATUS_RECORD_SP produces its own user-defined error (Msg 60000).
       * Attempt to insert GHHS.XX_GHHS_INV_ERROR record should happen in post-error CATCH block.
       */
      IF @ret_code <> 0
         BEGIN
            SET @task_desc = @task_desc + @fail_text
            -- Raise user-defined exception to force standard error 50000 to execute the CATCH block. Use RAISERROR() to faciliate the SP exit.
            RAISERROR(@task_desc, 16, 1)
         END
   END

WHILE @current_execution_step <= @TOTAL_NUM_OF_EXEC_STEPS
   BEGIN
      SET @execution_step_sp_name =
         CASE @current_execution_step
            WHEN 1 THEN 'dbo.XX_PLC_RATE_CHECK_RESOURCE_SP'
            WHEN 2 THEN 'dbo.XX_PLC_RATE_LOAD_DATA_SP'
            WHEN 3 THEN 'dbo.XX_PLC_RATE_UPDATE_CP_SP'
         END

      SET @called_SP_name = @execution_step_sp_name

      -- Get the control point ID associated with the current execution step
      SELECT @current_CTRL_PT_ID = t1.APPLICATION_CODE
        FROM dbo.XX_LOOKUP_DETAIL t1,
             dbo.XX_LOOKUP_DOMAIN t2
       WHERE t1.LOOKUP_DOMAIN_ID   = t2.LOOKUP_DOMAIN_ID
         AND t1.PRESENTATION_ORDER = @current_execution_step
         AND t2.DOMAIN_CONSTANT    = @LOOKUP_DOMAIN_PLC_RATES_CTRL_PT

      PRINT 'Now processing control point ' + @current_CTRL_PT_ID + ' ...'

      BEGIN TRANSACTION CURRENT_CTRL_PT

      SET @ctrl_pt_task_desc = 'Call ' + @execution_step_sp_name + ' to process CP ' + @current_CTRL_PT_ID
      PRINT @ctrl_pt_task_desc

      -- This banner is displayed for all control points.
      PRINT '**********************************************************************************'
      PRINT 'BEGIN CP ' + @current_CTRL_PT_ID + ': EXECUTE ' + @execution_step_sp_name +' FOR [' + CAST(@current_STATUS_RECORD_NUM as varchar) + ']' 
      PRINT '**********************************************************************************'

      EXEC @ret_code = @execution_step_sp_name
         @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM,
         @out_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION OUTPUT

      PRINT '**********************************************************************************'				
      PRINT 'END OF CP ' + @current_CTRL_PT_ID + ' [' + CAST(@current_STATUS_RECORD_NUM as varchar) + ']'
      PRINT '**********************************************************************************'

      /*
       * Processing of the individual control point via SP call ended. Now evaluate the execution status returned by the called SP.
       * Either the SP call or the local processing of the control point failed. Both processing types return an execution status.
       */
      IF @ret_code <> 0 -- The called SP returns an error status
         BEGIN
            SET @ctrl_pt_task_desc = @ctrl_pt_task_desc + @fail_text
            ROLLBACK TRANSACTION CURRENT_CTRL_PT
            RAISERROR(@ctrl_pt_task_desc, 16, 1)
         END
      ELSE -- The SP call is successful
         COMMIT TRANSACTION CURRENT_CTRL_PT

      SET @task_desc = 'Insert a XX_IMAPS_INT_CONTROL record for the successfully completed control point ' + @current_CTRL_PT_ID
      PRINT @task_desc

      EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
         @in_int_ctrl_pt_num     = @current_execution_step,
         @in_lookup_domain_const = @LOOKUP_DOMAIN_PLC_RATES_CTRL_PT,
         @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM

      IF @ret_code <> 0
         BEGIN
            SET @task_desc = @task_desc + @fail_text
            RAISERROR(@task_desc, 16, 1)
         END

      SET @task_desc = 'Update the XX_IMAPS_INT_STATUS record with the latest control point processing result ...'
      PRINT @task_desc

      SET @current_STATUS_DESCRIPTION = 'Processing for control point ' + @current_CTRL_PT_ID + ' completed successfully.'

      EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
         @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
         @in_STATUS_CODE        = @INTERFACE_STATUS_SUCCESS,
         @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION

      IF @ret_code <> 0
         BEGIN
            SET @task_desc = @task_desc + @fail_text
            RAISERROR(@task_desc, 16, 1)
         END

      SET @current_STATUS_DESCRIPTION = NULL -- reset for the next iteration or control point
      SET @current_execution_step = @current_execution_step + 1

      IF (@current_execution_step - 1) = @TOTAL_NUM_OF_EXEC_STEPS
         BEGIN
            PRINT ''
            PRINT 'All control points have been processed successfully: Exiting WHILE loop ...'
            PRINT ''
         END
   END /* WHILE @current_execution_step <= @TOTAL_NUM_OF_EXEC_STEPS */

-- Update the XX_IMAPS_INT_STATUS record with interface run statistics is done in XX_PLC_RATE_UPDATE_CP_SP.

PRINT 'Final update to XX_IMAPS_INT_STATUS ...'

SET @task_desc = 'Mark the current interface run as completed'
PRINT @task_desc

EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
   @in_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM,
   @in_STATUS_CODE = @INTERFACE_STATUS_COMPLETED

IF @ret_code <> 0
   BEGIN
      SET @task_desc = @task_desc + @fail_text
      RAISERROR(@task_desc, 16, 1)
   END

SET @task_desc = 'Send email to the users (insert a XX_IMAPS_MAIL_OUT record)'
PRINT @task_desc

EXEC @ret_code = dbo.XX_SEND_STATUS_MAIL_SP
   @in_StatusRecordNum = @current_STATUS_RECORD_NUM

IF @ret_code <> 0
   BEGIN
      SET @task_desc = @task_desc + @fail_text
      RAISERROR(@task_desc, 16, 1)
   END

-- Return success execution status to the calling (caller) SQL Server job
SET @exec_stat = 0

END TRY

BEGIN CATCH
   -- There are two types of error to handle: (2) Error that occurs in the SP called by this driver SP, (2) Error that occurs within this driver SP.

   -- Retrieve error information
   SELECT @SS_Error_Number = ERROR_NUMBER(), @SS_Error_Severity = ERROR_SEVERITY(), @SS_Error_State = ERROR_STATE(),
          @SS_Error_Procedure = ERROR_PROCEDURE(), @SS_Error_Line = ERROR_LINE(), @SS_Error_Message = ERROR_MESSAGE()

   -- Build customized error message
   SET @user_error_msg = 'ERROR ' + CAST(@SS_Error_Number as VARCHAR(15)) + ': ' + @SS_Error_Message + ' [' +
                         @SS_Error_Procedure + ', Line ' + CAST(@SS_Error_Line as VARCHAR(10)) + ']'

   /*
    * Special Case: Display the error message (the value returned by ERROR_MESSAGE()) now because the called SP encounters and cannot handle
    * a specific type of SQL Server error such as a user-defined function being called does not exist (SQL Server 2017 allows stored procedures
    * which call non-existent user-defined function to be compiled successfully). The value of local variable @task_desc may be NULL, not yet
    * assigned a value. The value of @task_desc in the called SP is displayed in the SQL Server job log.
    */
   IF @user_error_msg IS NOT NULL
      PRINT @user_error_msg
   ELSE
      PRINT 'NOTICE: @user_error_msg is NULL.'

   -- Error Type 1: Error that occurs in the SPs called by this driver SP
   IF @ret_code <> 0
      PRINT 'Error Type 1: Error occurred in, and has already been handled (complete with error message display) by, the called SP itself.'
   ELSE
      -- Error Type 2: Error resulting from RAISERROR() issued in this driver SP, especially when a called SP returned an execution error status.
      IF @SS_Error_Number = 50000
         PRINT 'Error Type 2: Error that occurs within the driver SP: This is a user-defined Error 50000 raised by this driver SP'
      ELSE
         PRINT 'Error Type 3: Error that occurs within the driver SP: This is an error raised by SQL Server'

   IF @task_desc IS NOT NULL
      -- Display the failed task's description to the console
      PRINT 'NOTICE: ' + @ctrl_pt_task_desc + ' [Post-error]' -- Note: @fail_text is already appended above where the called SP's return code/status is evaluated

   -- Update interface run status
   SET @current_STATUS_DESCRIPTION = CAST(@user_error_msg as varchar(240))

   -- Restrict saving active successful transactions, if any, to this SP only.
   SELECT @xstate = XACT_STATE(), @transaction_count = @@TRANCOUNT

   -- Active uncommittable transactions
   IF @xstate = -1
      BEGIN
         PRINT 'CATCH block: @xstate = -1 --> ROLLBACK'
         ROLLBACK
      END

   -- Active committable transaction exists & one or more BEGIN TRANSACTION statements were issued
   -- The BEGIN TRANSACTION statement alone already increments @@TRANCOUNT by 1.
   IF @xstate = 1 AND @transaction_count > 0
      BEGIN
         PRINT 'CATCH block: @xstate = 1 AND @transaction_count > 0 --> COMMIT TRANSACTION CURRENT_CTRL_PT'
         COMMIT TRANSACTION CURRENT_CTRL_PT
      END

   IF @execution_step_sp_name IS NOT NULL
      BEGIN
         SET @task_desc = 'Update XX_IMAPS_INT_STATUS record [Post-error]'
         PRINT @task_desc

         EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
            @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
            @in_STATUS_CODE        = @INTERFACE_STATUS_FAILED,
            @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION

         IF @ret_code <> 0
            BEGIN
               SET @task_desc = @task_desc + @fail_text
               RAISERROR(@task_desc, 16, 1)
            END

         SET @task_desc = 'Send interface run error notification e-mail [Post-error]'
         PRINT @task_desc

         EXEC @ret_code = dbo.XX_SEND_STATUS_MAIL_SP
            @in_StatusRecordNum = @current_STATUS_RECORD_NUM

         IF @ret_code <> 0
            BEGIN
               SET @task_desc = @task_desc + @fail_text
               RAISERROR(@task_desc, 16, 1)
            END
      END

   -- Return failure execution status to the calling (caller) SQL Server job
   SET @exec_stat = 1
END CATCH

SET NOCOUNT OFF
RETURN(@exec_stat)

GO

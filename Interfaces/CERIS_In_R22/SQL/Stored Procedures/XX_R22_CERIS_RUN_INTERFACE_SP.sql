USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO 
SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE ID = object_id(N'[dbo].[XX_R22_CERIS_RUN_INTERFACE_SP]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[XX_R22_CERIS_RUN_INTERFACE_SP]
GO


CREATE PROCEDURE [dbo].[XX_R22_CERIS_RUN_INTERFACE_SP] AS

/****************************************************************************************************
Name:       XX_R22_CERIS_RUN_INTERFACE_SP
Author:     V Veera
Created:    05/18/2008 
      This stored procedure serves as a script to run and drive all necessary tasks to
            to perform the CERIS_R22/BluePages interface with IMAPS. COMMIT TRANSACTION and ROLL BACK
            TRANSACTION are applied to the processing for each control point.
Parameters: 
Result Set: None
Notes:

06/20/2011  CR3856 removal of application ids T Perova
12/03/2012  CR4107 Fix Costpoint TS Edit report issue
CR9296 - gea - 4/10/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
CR9296 - gea - 4/25/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
****************************************************************************************************/



DECLARE @SP_NAME                        sysname,
        @TOTAL_NUM_OF_EXEC_STEPS        integer,

        @IN_SOURCE_SYSOWNER             sysname,
        @IN_FINANCE_ANALYST             sysname,
        @IN_DESTINATION_SYSOWNER        varchar(300),
        @IMAPS_SCHEMA_OWNER             sysname,
 /*       @IN_USER_NAME                   sysname,
         @IN_USER_PASSWORD               sysname,  CR3856 */



        @SERVER_NAME                    sysname,
        @IMAPS_DB_NAME                  sysname,
        @CERIS_INTERFACE_NAME           varchar(50),
        @INBOUND_INT_TYPE               char(1),
        @INT_DEST_SYSTEM                varchar(50),
        @LOOKUP_DOMAIN_CERIS_CTRL_PT    varchar(30),

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
    @emp_map_sp           sysname,  --- XX_R22_EMP_MAP_SP
        @current_CTRL_PT_ID             varchar(20),

    @in_CPprogress_stat_code    varchar(30),
        @ret_code                       integer,
        @SQLServer_error_code           integer,
        @SQLServer_error_msg_text       varchar(275),
        @row_count                      integer

-- set local constants
 
 
 
PRINT '' --CR9296 *~^
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_R22_CERIS_RUN_INTERFACE_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9296 *~^
-- *~^
SET @SP_NAME = 'XX_R22_CERIS_RUN_INTERFACE_SP'
SET @emp_map_sp  = 'XX_R22_EMP_MAP_SP'
SET @TOTAL_NUM_OF_EXEC_STEPS = 8
SET @SERVER_NAME = @@servername
SET @IMAPS_DB_NAME = db_name()
SET @CERIS_INTERFACE_NAME = 'CERIS_R22'
SET @INBOUND_INT_TYPE = 'I' -- Inbound
SET @INT_DEST_SYSTEM = 'IMAPS'
SET @LOOKUP_DOMAIN_CERIS_CTRL_PT = 'LD_CERIS_R_INTERFACE_CTRL_PT'
SET @INTERFACE_STATUS_SUCCESS = 'SUCCESS'
SET @INTERFACE_STATUS_COMPLETED = 'COMPLETED'
SET @INTERFACE_STATUS_FAILED = 'FAILED'
SET @in_CPprogress_stat_code = 'CPIN_PROGRESS'

SET NOCOUNT ON

/* Commented out the mapping process and added it as a separate step in the job. This is not required by Rate Retro and will sometimes take considerable amount of time
  EXEC  @ret_code = @emp_map_sp 


 --         @out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
  --        @out_STATUS_DESCRIPTION   = @current_STATUS_DESCRIPTION OUTPUT

/*      
      @out_NO_DATA_FLAG       varchar(8) = NULL OUTPUT,
  @out_SYS_ERROR_FLAG     varchar(8) = NULL OUTPUT 
      @out_systemerror = @out_systemerror  OUTPUT, 
       @out_status_description = @out_status_description OUTPUT
*/  


  IF @ret_code <> 0 OR @@ERROR <> 0 
    GOTO BL_ERROR_HANDLER;

*/


-- retrieve necessary parameter data to run the CERIS interface
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 127 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
EXEC @ret_code = dbo.XX_R22_CERIS_GET_PROCESSING_PARAMS_SP
   @out_IN_SOURCE_SYSOWNER      = @IN_SOURCE_SYSOWNER      OUTPUT,
   @out_IN_FINANCE_ANALYST      = @IN_FINANCE_ANALYST      OUTPUT,
   @out_IN_DESTINATION_SYSOWNER = @IN_DESTINATION_SYSOWNER OUTPUT,
   @out_IMAPS_SCHEMA_OWNER      = @IMAPS_SCHEMA_OWNER      OUTPUT
/*  @out_IN_USER_NAME            = @IN_USER_NAME            OUTPUT
   ,@out_IN_USER_PASSWORD        = @IN_USER_PASSWORD        OUTPUT  CR3856 */



IF @ret_code <> 0 OR @@ERROR <> 0  -- SP call results in error
   GOTO BL_ERROR_HANDLER



/*
 * Check status of the last interface job: if it is not completed, perform recovery
 * by picking up processing from the last sucessful control point.
 */



PRINT 'Check status of the last interface job ...'

-- retrieve the execution result data of the last interface run or job
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 156 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
SELECT @last_issued_STATUS_RECORD_NUM = STATUS_RECORD_NUM,
       @last_issued_STATUS_CODE = STATUS_CODE
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE INTERFACE_NAME = @CERIS_INTERFACE_NAME
   AND CREATED_DATE   = (SELECT MAX(s.CREATED_DATE) 
                           FROM dbo.XX_IMAPS_INT_STATUS s
                          WHERE s.INTERFACE_NAME = @CERIS_INTERFACE_NAME)

SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

IF @SQLServer_error_code > 0 or @row_count > 1
   GOTO BL_ERROR_HANDLER

IF @last_issued_STATUS_RECORD_NUM IS NULL
   BEGIN
      PRINT 'There was not any last interface job to consider.'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 178 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
      SELECT @last_issued_STATUS_RECORD_NUM = COUNT(1)
        FROM dbo.XX_IMAPS_INT_STATUS
       WHERE INTERFACE_NAME = @CERIS_INTERFACE_NAME

      IF @last_issued_STATUS_RECORD_NUM = 0
         SET @last_issued_STATUS_CODE = @INTERFACE_STATUS_COMPLETED
      ELSE
        GOTO BL_ERROR_HANDLER
   END

IF @last_issued_STATUS_CODE <> @INTERFACE_STATUS_COMPLETED -- e.g., INITIATED, SUCCESS, FAILED
   BEGIN
      PRINT 'The last interface job was incomplete. Determine the next execution step ...'

      -- retrieve data recorded for the last successful control point 
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 199 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
      SELECT @last_issued_CONTROL_PT_ID = CONTROL_PT_ID
        FROM dbo.XX_IMAPS_INT_CONTROL
       WHERE STATUS_RECORD_NUM  = @last_issued_STATUS_RECORD_NUM
         AND INTERFACE_NAME     = @CERIS_INTERFACE_NAME
         AND CONTROL_PT_STATUS  = @INTERFACE_STATUS_SUCCESS
         AND CONTROL_RECORD_NUM = (select MAX(c.CONTROL_RECORD_NUM) 
                                     from dbo.XX_IMAPS_INT_CONTROL c
                                    where c.STATUS_RECORD_NUM = @last_issued_STATUS_RECORD_NUM
                                      and c.INTERFACE_NAME    = @CERIS_INTERFACE_NAME
                                      and c.CONTROL_PT_STATUS = @INTERFACE_STATUS_SUCCESS)

      SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

      IF @SQLServer_error_code > 0
         GOTO BL_ERROR_HANDLER

      IF @last_issued_CONTROL_PT_ID IS NULL -- no control point was ever passed successfully
         SET @current_execution_step = 1
      ELSE -- at least one control points was passed successfully
         BEGIN
            -- determine the next execution step where the interface run resumes
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 226 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
            SELECT @current_execution_step = t1.PRESENTATION_ORDER + 1
              FROM dbo.XX_LOOKUP_DETAIL t1,
                   dbo.XX_LOOKUP_DOMAIN t2
             WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
               AND t1.APPLICATION_CODE = @last_issued_CONTROL_PT_ID
               AND t2.DOMAIN_CONSTANT  = @LOOKUP_DOMAIN_CERIS_CTRL_PT
         END

      SET @current_STATUS_RECORD_NUM = @last_issued_STATUS_RECORD_NUM
   END
ELSE
   SET @current_execution_step = 1 -- may proceed with the current interface job

IF @current_STATUS_RECORD_NUM IS NULL -- this is the very first time that this interface job is run
   BEGIN
      PRINT 'Begin processing for the current ' + @CERIS_INTERFACE_NAME + ' interface run ...'

      /*
       * call XX_INSERT_INT_STATUS_RECORD to get XX_IMAPS_INT_STATUS.STATUS_RECORD_NUM
       * Each interface run has exactly one XX_IMAPS_INT_STATUS record created and is subsequently updated
       * as many times as needed. When first created, XX_IMAPS_INT_STATUS.STATUS_CODE = 'INITIATED'.
       */ 


 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 253 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
      EXEC @ret_code = dbo.XX_INSERT_INT_STATUS_RECORD
         @in_IMAPS_db_name      = @IMAPS_DB_NAME,
         @in_IMAPS_table_owner  = @IMAPS_SCHEMA_OWNER,
         @in_int_name           = @CERIS_INTERFACE_NAME,
         @in_int_type           = @INBOUND_INT_TYPE,
         @in_int_source_sys     = @CERIS_INTERFACE_NAME,
         @in_int_dest_sys       = @INT_DEST_SYSTEM,
         @in_Data_FName         = 'N/A',
         @in_int_source_owner   = @IN_SOURCE_SYSOWNER,
         @in_int_dest_owner     = @IN_DESTINATION_SYSOWNER,
         @out_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM OUTPUT

      IF @ret_code <> 0 OR @@ERROR <> 0  GOTO BL_ERROR_HANDLER
   END

WHILE @current_execution_step <= @TOTAL_NUM_OF_EXEC_STEPS
   BEGIN

	PRINT 'The next execution step is ' + cast(@current_execution_step as varchar)

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 276 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
      SELECT @execution_step_sp_name =
             CASE @current_execution_step
                WHEN 1 THEN 'dbo.XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP'
                WHEN 2 THEN 'dbo.XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP'
                WHEN 3 THEN 'dbo.XX_R22_CERIS_INSERT_CP_SP'
                WHEN 4 THEN 'dbo.XX_R22_CERIS_UPDATE_CP_SP'
                WHEN 5 THEN 'dbo.XX_R22_CERIS_PROCESS_RETRO_SP'
        WHEN 6 THEN 'dbo.XX_R22_CERIS_READY_CP_RUN_SP'
                WHEN 8 THEN 'dbo.XX_R22_CERIS_ARCHIVE_DATA_SP'
             END

      SET @called_SP_name = @execution_step_sp_name

/****************************************************************************************************************************

The use of BEGIN TRANSACTION and ROLLBACK TRANSACTION for transactions that involve a table,
possibly a non-SQL Server table, residing in another server that requires a DB link (viewable
using Enterprise Manager) and a distributed transaction, causes the following error.

Server: Msg 7391, Level 16, State 1, Procedure XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP, Line 42
The operation could not be performed because the OLE DB provider 'MSDASQL' was unable to begin a distributed transaction.

[OLE/DB provider returned message: [Microsoft][ODBC driver for Oracle]Driver not capable]
OLE DB error trace [OLE/DB Provider 'MSDASQL' ITransactionJoin::JoinTransaction returned 0x8004d00a].

Solution: Provide developer's own BEGIN TRANSACTION and ROLLBACK TRANSACTION processing as part
of the error handling. I.e., undo all INSERT and UPDATE actions.

****************************************************************************************************************************/ 


      /*
       * Do not subject processing of control point 1 to the automatic rollback service
       * provided by SQL Server. The called SP has its own "manual rollback" service.
       */


      IF @current_execution_step = 1
         BEGIN
            EXEC @ret_code = @execution_step_sp_name
               @in_STATUS_RECORD_NUM     = @current_STATUS_RECORD_NUM,
               @out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
               @out_STATUS_DESCRIPTION   = @current_STATUS_DESCRIPTION OUTPUT

            IF @ret_code <> 0 OR @@ERROR <> 0  -- SP call results in error
               GOTO BL_ERROR_HANDLER
         END
      ELSE IF @current_execution_step = 7 --CP_INPROGRESS
        BEGIN
          IF 0 <> (SELECT COUNT(1) FROM dbo.XX_R22_CERIS_RETRO_TS_PREP)
            BEGIN
           --control point handled by XX_R22_UPDATE_PROCESS_STATUS_SP
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 332 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
              EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
                  @in_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM,
                  @in_STATUS_CODE       = @in_CPprogress_stat_code
              
              PRINT 'Process Stage CERIS_R7 - Waiting For Costpoint Process Server to Complete...'
              RETURN 0
            END
          ELSE
            BEGIN
              PRINT 'Process Stage CERIS_R7 - No Correcting Timesheets Were Created'
            END
          END
-- CR4107_begin
/*
 * The SQL Server job "Run CERIS_R22 Closeout" calls this program to resume the current interface run's post-control point 7 execution.
 * Fix Costpoint TS Edit report issue
 * For exempt retro timesheets, for reversing timesheet lines with S_TS_TYPE_CD = 'N', PAY_TYPE 'OT' is converted to 'R'.
 * When records are processed thru the Costpoint Preprocessor, Costpoint changes PAY_TYPE 'OT' to 'R' on reversing timesheet lines.
 * Consequently, as part of the closeout process, PAY_TYPE should be changed from 'R' back to 'OT'.
 */


      ELSE IF @current_execution_step = 8
         BEGIN
            IF 0 <> (SELECT COUNT(1) FROM dbo.XX_R22_CERIS_RETRO_TS_PREP)
               AND 0 <> (SELECT COUNT(1)
                           FROM IMAR.Deltek.TS_LN
                          WHERE NOTES like '%-OT%'
                            AND NOTES like (CAST(@current_STATUS_RECORD_NUM as VARCHAR(15)) + '-CERIS-%'))
               BEGIN
                  UPDATE IMAR.Deltek.TS_LN
                     SET PAY_TYPE = 'OT'
                   WHERE NOTES like '%-OT%'
                     AND NOTES like (CAST(@current_STATUS_RECORD_NUM as VARCHAR(15)) + '-CERIS-%')
               END

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 372 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
            EXEC @ret_code = @execution_step_sp_name
               @in_STATUS_RECORD_NUM     = @current_STATUS_RECORD_NUM,
               @out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
               @out_STATUS_DESCRIPTION   = @current_STATUS_DESCRIPTION OUTPUT

            IF @ret_code <> 0 OR @@ERROR <> 0
               GOTO BL_ERROR_HANDLER
         END
-- CR4107_end 
      ELSE
         BEGIN
            BEGIN TRANSACTION CURRENT_CTRL_PT

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 390 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
            EXEC @ret_code = @execution_step_sp_name
               @in_STATUS_RECORD_NUM     = @current_STATUS_RECORD_NUM,
               @out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
               @out_STATUS_DESCRIPTION   = @current_STATUS_DESCRIPTION OUTPUT

            IF @ret_code <> 0 OR @@ERROR <> 0  -- SP call results in error
               BEGIN
                  ROLLBACK TRANSACTION CURRENT_CTRL_PT
                  GOTO BL_ERROR_HANDLER
               END
            ELSE -- SP call is successful
               COMMIT TRANSACTION CURRENT_CTRL_PT
         END

PRINT 'Update the XX_IMAPS_INT_STATUS ' + cast(@current_STATUS_RECORD_NUM as varchar) + ' record with the latest control point processing result ' + @current_STATUS_DESCRIPTION

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 411 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
      SELECT @current_CTRL_PT_ID = t1.APPLICATION_CODE
        FROM dbo.XX_LOOKUP_DETAIL t1,
             dbo.XX_LOOKUP_DOMAIN t2
       WHERE t1.LOOKUP_DOMAIN_ID   = t2.LOOKUP_DOMAIN_ID
         AND t1.PRESENTATION_ORDER = @current_execution_step
         AND t2.DOMAIN_CONSTANT    = @LOOKUP_DOMAIN_CERIS_CTRL_PT

      SET @current_STATUS_DESCRIPTION = 'INFORMATION: Processing for control point ' + @current_CTRL_PT_ID + ' completed successfully.'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 425 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
      EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
         @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
         @in_STATUS_CODE        = @INTERFACE_STATUS_SUCCESS,
         @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION

      -- insert a XX_IMAPS_INT_CONTROL record for the successfully passed control point
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 437 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
      EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
         @in_int_ctrl_pt_num     = @current_execution_step,
         @in_lookup_domain_const = @LOOKUP_DOMAIN_CERIS_CTRL_PT,
         @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM

      IF @ret_code <> 0 OR @@ERROR <> 0  -- the sp call results in error
         GOTO BL_ERROR_HANDLER

      SET @current_execution_step = @current_execution_step + 1

   END /* WHILE @current_execution_step <= @TOTAL_NUM_OF_EXEC_STEPS */


PRINT 'Final update to XX_IMAPS_INT_STATUS ...'

-- mark the current interface run as completed
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 458 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
   @in_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM,
   @in_STATUS_CODE       = @INTERFACE_STATUS_COMPLETED

IF @ret_code <> 0 OR @@ERROR <> 0  -- SP call results in error
   GOTO BL_ERROR_HANDLER

-- send e-mail upon a successfully completed interface run 
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 472 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
EXEC @ret_code = dbo.XX_SEND_STATUS_MAIL_SP
   @in_StatusRecordNum = @current_STATUS_RECORD_NUM

IF @ret_code <> 0 OR @@ERROR <> 0  -- SP call results in error
   GOTO BL_ERROR_HANDLER

PRINT 'RETURN CODE FROM XX_SEND_STATUS_MAIL_SP IS ' + CAST(@ret_code as varchar)

SET NOCOUNT OFF
RETURN 0

BL_ERROR_HANDLER:

/*
 * When the called SP returns status 1, it has already handled the error itself.
 * When the called SP returns status that is greater than 1, it did not complete the handling of the error itself.
 */



IF @ret_code = 1 AND @current_STATUS_DESCRIPTION is NULL 
   SET @ret_code = 301 -- An error has occured. Please contact system administrator.

IF @SQLServer_error_code = 0
   SET @SQLServer_error_code = NULL

/*
 * Errors that were not handled by the called SP
 * or special error conditions requiring special treatment.
 */


IF @ret_code <> 1
   BEGIN
      IF @ret_code = 210 AND @current_execution_step = 2
         BEGIN
            SELECT @row_count = COUNT(1) FROM dbo.XX_R22_CERIS_FILE_STG

            -- update the XX_IMAPS_INT_STATUS record to show success and failure rates
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 515 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
            UPDATE dbo.XX_IMAPS_INT_STATUS
               SET RECORD_COUNT_INITIAL = @row_count,
                   RECORD_COUNT_SUCCESS = 0,
                   RECORD_COUNT_ERROR = @row_count,
                   MODIFIED_BY = SUSER_SNAME(),
                   MODIFIED_DATE = GETDATE()
             WHERE STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM

            SELECT @SQLServer_error_code = @@ERROR

            IF @SQLServer_error_code <> 0
               -- Attempt to update a XX_IMAPS_INT_STATUS record failed.
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 533 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
               EXEC dbo.XX_ERROR_MSG_DETAIL
                  @in_error_code           = 204,
                  @in_SQLServer_error_code = @SQLServer_error_code,
                  @in_display_requested    = 1,
                  @in_placeholder_value1   = 'update',
                  @in_placeholder_value2   = 'a XX_IMAPS_INT_STATUS record',
                  @in_calling_object_name  = @SP_NAME
         END
      ELSE
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

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 559 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
   @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
   @in_STATUS_CODE        = @INTERFACE_STATUS_FAILED,
   @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION

-- send e-mail in the event of errors and thus an incomplete interface run 
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 571 : XX_R22_CERIS_RUN_INTERFACE_SP.sql '  --CR9296
 
EXEC dbo.XX_SEND_STATUS_MAIL_SP
   @in_StatusRecordNum = @current_STATUS_RECORD_NUM

SET NOCOUNT OFF
RETURN(1)

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_CERIS_RUN_INTERFACE_SP    Script Date: 03/08/2006 11:03:47 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_RUN_INTERFACE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_CERIS_RUN_INTERFACE_SP]
GO







CREATE PROCEDURE dbo.XX_CERIS_RUN_INTERFACE_SP AS

/****************************************************************************************************
Name:       XX_CERIS_RUN_INTERFACE_SP
Author:     HVT
Created:    10/01/2005
Purpose:    This stored procedure serves as a script to run and drive all necessary tasks to
            to perform the CERIS/BluePages interface with IMAPS. COMMIT TRANSACTION and ROLL BACK
            TRANSACTION are applied to the processing for each control point.
Parameters: 
Result Set: None
Notes:

CP600001216 05/13/2011 (FSST Service Request No. CR3735)
            Eliminate use of shared ID (e.g., in bcp call)
****************************************************************************************************/

DECLARE @SP_NAME                        sysname,
        @TOTAL_NUM_OF_EXEC_STEPS        integer,

        @IN_SOURCE_SYSOWNER             sysname,
        @IN_FINANCE_ANALYST             sysname,
        @IN_DESTINATION_SYSOWNER        sysname,
        @IMAPS_SCHEMA_OWNER             sysname,
-- CR3735_Begin
--      @IN_USER_NAME                   sysname,
--      @IN_USER_PASSWORD               sysname,
-- CR3735_End

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
        @current_CTRL_PT_ID             varchar(20),

        @ret_code                       integer,
        @SQLServer_error_code           integer,
        @SQLServer_error_msg_text       varchar(275),
        @row_count                      integer

-- set local constants
SET @SP_NAME = 'XX_CERIS_RUN_INTERFACE_SP'
SET @TOTAL_NUM_OF_EXEC_STEPS = 8
SET @SERVER_NAME = @@servername
SET @IMAPS_DB_NAME = db_name()
SET @CERIS_INTERFACE_NAME = 'CERIS'
SET @INBOUND_INT_TYPE = 'I' -- Inbound
SET @INT_DEST_SYSTEM = 'IMAPS'
SET @LOOKUP_DOMAIN_CERIS_CTRL_PT = 'LD_CERIS_INTERFACE_CTRL_PT'
SET @INTERFACE_STATUS_SUCCESS = 'SUCCESS'
SET @INTERFACE_STATUS_COMPLETED = 'COMPLETED'
SET @INTERFACE_STATUS_FAILED = 'FAILED'

SET NOCOUNT ON

-- retrieve necessary parameter data to run the CERIS interface
EXEC @ret_code = dbo.XX_CERIS_GET_PROCESSING_PARAMS_SP
   @out_IN_SOURCE_SYSOWNER      = @IN_SOURCE_SYSOWNER      OUTPUT,
   @out_IN_FINANCE_ANALYST      = @IN_FINANCE_ANALYST      OUTPUT,
   @out_IN_DESTINATION_SYSOWNER = @IN_DESTINATION_SYSOWNER OUTPUT,
   @out_IMAPS_SCHEMA_OWNER      = @IMAPS_SCHEMA_OWNER      OUTPUT
-- CR3735_Begin
-- @out_IN_USER_NAME            = @IN_USER_NAME            OUTPUT,
-- @out_IN_USER_PASSWORD        = @IN_USER_PASSWORD        OUTPUT
-- CR3735_End

IF @ret_code <> 0 -- SP call results in error
   GOTO BL_ERROR_HANDLER

-- make sure that the required CERIS/BluePages interface resources exist
EXEC @ret_code = dbo.XX_CERIS_CHK_RESOURCES_SP

IF @ret_code <> 0 -- SP call results in error
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
 WHERE INTERFACE_NAME = @CERIS_INTERFACE_NAME
   AND CREATED_DATE   = (SELECT MAX(s.CREATED_DATE) 
                           FROM dbo.XX_IMAPS_INT_STATUS s
                          WHERE s.INTERFACE_NAME = @CERIS_INTERFACE_NAME)

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 124 : XX_CERIS_RUN_INTERFACE_SP.sql '
 
SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

IF @SQLServer_error_code > 0 or @row_count > 1
   GOTO BL_ERROR_HANDLER

IF @last_issued_STATUS_RECORD_NUM IS NULL
   BEGIN
      PRINT 'There wasn''t any last interface job to consider.'

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 136 : XX_CERIS_RUN_INTERFACE_SP.sql '
 
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

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 165 : XX_CERIS_RUN_INTERFACE_SP.sql '
 
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

      IF @ret_code <> 0 GOTO BL_ERROR_HANDLER
   END

WHILE @current_execution_step <= @TOTAL_NUM_OF_EXEC_STEPS
   BEGIN
      SELECT @execution_step_sp_name =
             CASE @current_execution_step
                WHEN 1 THEN 'dbo.XX_CERIS_RETRIEVE_SOURCE_DATA_SP'
                WHEN 2 THEN 'dbo.XX_CERIS_VALIDATE_PREPARE_DATA_SP'
                WHEN 3 THEN 'dbo.XX_CERIS_INSERT_CP_SP'
                WHEN 4 THEN 'dbo.XX_CERIS_UPDATE_CP_SP'
                WHEN 5 THEN 'dbo.XX_CERIS_PROCESS_RETRO_SP'
		WHEN 6 THEN 'dbo.XX_CERIS_READY_CP_RUN_SP'
                WHEN 8 THEN 'dbo.XX_CERIS_ARCHIVE_DATA_SP'
             END

      SET @called_SP_name = @execution_step_sp_name

/****************************************************************************************************************************

The use of BEGIN TRANSACTION and ROLLBACK TRANSACTION for transactions that involve a table,
possibly a non-SQL Server table, residing in another server that requires a DB link (viewable
using Enterprise Manager) and a distributed transaction, causes the following error.

Server: Msg 7391, Level 16, State 1, Procedure XX_CERIS_RETRIEVE_SOURCE_DATA_SP, Line 42
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

            IF @ret_code <> 0 -- SP call results in error
               GOTO BL_ERROR_HANDLER
         END
      ELSE IF @current_execution_step = 7 --CP_INPROGRESS
	BEGIN
		IF 0 <> (SELECT COUNT(1) FROM dbo.XX_CERIS_RETRO_TS_PREP)
		BEGIN
			--control point handled by XX_UPDATE_PROCESS_STATUS_SP
			EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
	   			@in_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM,
	   			@in_STATUS_CODE       = 'CPIN_PROGRESS'
			
			PRINT 'Process Stage CERIS7 - Waiting For Costpoint Process Server to Complete...'
			RETURN 0
		END
		ELSE
		BEGIN
			PRINT 'Process Stage CERIS7 - No Correcting Timesheets Were Created'
		END
	END	
      ELSE
         BEGIN
            BEGIN TRANSACTION CURRENT_CTRL_PT

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 282 : XX_CERIS_RUN_INTERFACE_SP.sql '
 
            EXEC @ret_code = @execution_step_sp_name
               @in_STATUS_RECORD_NUM     = @current_STATUS_RECORD_NUM,
               @out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
               @out_STATUS_DESCRIPTION   = @current_STATUS_DESCRIPTION OUTPUT

            IF @ret_code <> 0 -- SP call results in error
               BEGIN
                  ROLLBACK TRANSACTION CURRENT_CTRL_PT
                  GOTO BL_ERROR_HANDLER
               END
            ELSE -- SP call is successful
               COMMIT TRANSACTION CURRENT_CTRL_PT
         END

      PRINT 'Update the XX_IMAPS_INT_STATUS record with the latest control point processing result ...'

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 301 : XX_CERIS_RUN_INTERFACE_SP.sql '
 
      SELECT @current_CTRL_PT_ID = t1.APPLICATION_CODE
        FROM dbo.XX_LOOKUP_DETAIL t1,
             dbo.XX_LOOKUP_DOMAIN t2
       WHERE t1.LOOKUP_DOMAIN_ID   = t2.LOOKUP_DOMAIN_ID
         AND t1.PRESENTATION_ORDER = @current_execution_step
         AND t2.DOMAIN_CONSTANT    = @LOOKUP_DOMAIN_CERIS_CTRL_PT

      SET @current_STATUS_DESCRIPTION = 'INFORMATION: Processing for control point ' + @current_CTRL_PT_ID + ' completed successfully.'

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 313 : XX_CERIS_RUN_INTERFACE_SP.sql '
 
      EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
         @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
         @in_STATUS_CODE        = @INTERFACE_STATUS_SUCCESS,
         @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION

      -- insert a XX_IMAPS_INT_CONTROL record for the successfully passed control point
      EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
         @in_int_ctrl_pt_num     = @current_execution_step,
         @in_lookup_domain_const = @LOOKUP_DOMAIN_CERIS_CTRL_PT,
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

-- send e-mail upon a successfully completed interface run 
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
-- DEV00000244_begin
      IF @ret_code = 210 AND @current_execution_step = 2
         BEGIN
            SELECT @row_count = COUNT(1) FROM dbo.XX_CERIS_HIST

            -- update the XX_IMAPS_INT_STATUS record to show success and failure rates
            UPDATE dbo.XX_IMAPS_INT_STATUS
               SET RECORD_COUNT_INITIAL = @row_count,
                   RECORD_COUNT_SUCCESS = 0,
                   RECORD_COUNT_ERROR = @row_count,
                   MODIFIED_BY = SUSER_SNAME(),
                   MODIFIED_DATE = GETDATE()
             WHERE STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 387 : XX_CERIS_RUN_INTERFACE_SP.sql '
 
            SELECT @SQLServer_error_code = @@ERROR

            IF @SQLServer_error_code <> 0
               -- Attempt to update a XX_IMAPS_INT_STATUS record failed.
               EXEC dbo.XX_ERROR_MSG_DETAIL
                  @in_error_code           = 204,
                  @in_SQLServer_error_code = @SQLServer_error_code,
                  @in_display_requested    = 1,
                  @in_placeholder_value1   = 'update',
                  @in_placeholder_value2   = 'a XX_IMAPS_INT_STATUS record',
                  @in_calling_object_name  = @SP_NAME
         END
      ELSE
-- DEV00000244_end
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

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 416 : XX_CERIS_RUN_INTERFACE_SP.sql '
 
EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
   @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
   @in_STATUS_CODE        = @INTERFACE_STATUS_FAILED,
   @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION

-- send e-mail in the event of errors and thus an incomplete interface run 
EXEC dbo.XX_SEND_STATUS_MAIL_SP
   @in_StatusRecordNum = @current_STATUS_RECORD_NUM

SET NOCOUNT OFF
RETURN(1)







GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


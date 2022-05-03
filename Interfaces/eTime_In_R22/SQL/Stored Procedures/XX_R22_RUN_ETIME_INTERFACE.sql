IF OBJECT_ID('dbo.XX_R22_RUN_ETIME_INTERFACE') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_RUN_ETIME_INTERFACE
    IF OBJECT_ID('dbo.XX_R22_RUN_ETIME_INTERFACE') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_RUN_ETIME_INTERFACE >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_RUN_ETIME_INTERFACE >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go
CREATE PROCEDURE [dbo].[XX_R22_RUN_ETIME_INTERFACE]
(
@current_month_posting_ind char(1) = NULL
)
AS

/*****************************************************************************************************
Name:       XX_RUN_ETIME_INTERFACE
Author:     HVT
Created:    07/01/2005
Purpose:    This stored procedure serves as a script to run and drive all necessary tasks to
            to perform the eTime interface with IMAPS.
Parameters: 
Result Set: None
Notes:

Defect 782: 04/25/2006 Provide the option to post timesheets from another month to the current month.
            This SP is called with input parameter @current_month_posting_ind in a separate
            SQL Server Enterprise Manager (SEM) job, tentatively labeled Run_eTime - Current Month
            Posting option. This SEM job is in addition to another SEM job that calls this SP
            without the input parameter to post timesheets to the month supplied in the eT&E
            input file as the default mode of processing.

CP600000199 02/08/2008 Reference BP&S Service Request: DR1427
            Enable more users to be notified by e-mail upon specific interface run events. Change
            the size of @IN_DESTINATION_SYSOWNER from sysname to varchar(300).
CR-1414 
           Modified to exclude preprocessor from Step:3
	With this change the Step:3 will be done without kicking off the preprocessor. 
	The pre-processor kick off will be done via the New Job.
CR-1543		Modified to add Company_id logic
CR-1649     Modified for Div.22 code IMAR Changes
CR-3749     Modified for Shared ID Issue 05/05/11
*****************************************************************************************************/

DECLARE @SP_NAME                        sysname,
        @IN_TS_SOURCE_FILENAME          sysname,
        @IN_SOURCE_SYSOWNER             sysname,
        @IN_DESTINATION_SYSOWNER        varchar(300),
        @IN_DETAIL_FORMAT_FILENAME      sysname,
        @IN_FOOTER_FORMAT_FILENAME      sysname,
        @IN_PREP_FORMAT_FILENAME        sysname,
        @IN_PREP_TABLE_NAME             sysname,
		@IN_COMPANY_ID					sysname, 	-- Added CR-1543        
        @OUT_TS_PREP_FILENAME           sysname,
        @IMAPS_SCHEMA_OWNER             sysname,
        @IN_USER_PASSWORD               sysname,
        @OUT_CP_ERROR_FILENAME          sysname,
        @IN_ETIME_CP_PROC_ID            sysname,
        @IN_ETIME_CP_PROC_QUEUE_ID      sysname,
        @SERVER_NAME                    sysname,
        @IMAPS_DB_NAME                  sysname,
        @ETIME_INTERFACE                varchar(50),
        @INBOUND_INT_TYPE               char(1),
        @INT_SOURCE_SYSTEM              varchar(50),
        @INT_DEST_SYSTEM                varchar(50),
        @STAGE_ONE                      integer,
        @STAGE_TWO                      integer,
        @STAGE_THREE                    integer,
        @INTERFACE_STATUS_INITIATED     varchar(20),
        @INTERFACE_STATUS_SUCCESS       varchar(20),
        @INTERFACE_STATUS_FAILED        varchar(20),
        @INTERFACE_STATUS_CPIN_PROGRESS varchar(20),
        @EXEC_STEP_DO_NOTHING           integer,
        @lv_STATUS_RECORD_NUM           integer,
        @resume_execution_step          integer,
        @lv_lookup_id                   integer,
        @lv_lookup_app_code             varchar(20),
        @lv_PROC_SERVER_ID              varchar(12),
        @lv_Load_Status                 integer,
        @lv_STATUS_DESCRIPTION          varchar(255),
        @lv_error                       integer,
        @lv_rowcount                    integer,
        @ret_code                       integer

-- set local constants
SET @SP_NAME = 'XX_R22_RUN_ETIME_INTERFACE'
SET @SERVER_NAME = @@servername
SET @IMAPS_DB_NAME = db_name()
SET @ETIME_INTERFACE = 'ETIME_R22'
SET @INBOUND_INT_TYPE = 'I' -- Inbound
SET @INT_SOURCE_SYSTEM = 'eTime'
SET @INT_DEST_SYSTEM = 'IMAPS'
SET @STAGE_ONE = 1
SET @STAGE_TWO = 2
SET @STAGE_THREE = 3
SET @INTERFACE_STATUS_INITIATED = 'INITIATED'
SET @INTERFACE_STATUS_SUCCESS = 'SUCCESS'
SET @INTERFACE_STATUS_FAILED = 'FAILED'
SET @INTERFACE_STATUS_CPIN_PROGRESS = 'CPIN_PROGRESS' -- Cospoint preprocessor job in progress
SET @EXEC_STEP_DO_NOTHING = 99

SET NOCOUNT ON

-- Defect 782 Begin
IF @current_month_posting_ind IS NOT NULL AND UPPER(@current_month_posting_ind) NOT IN ('Y', 'N')
   BEGIN
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 214, -- Please restrict %1 to %2.
         @in_display_requested   = 1,
         @in_placeholder_value1  = 'values for input parameter @in_current_month_ind',
         @in_placeholder_value2  = 'to Y and N',
         @in_calling_object_name = @SP_NAME

      SET NOCOUNT OFF
      RETURN(1)
   END
-- Defect 782 End

-- retrieve input parameter data necessary to run the eTime interface
EXEC @ret_code = dbo.XX_R22_GET_ET_PROCESSING_PARAMETERS
   @out_IN_TS_SOURCE_FILENAME     = @IN_TS_SOURCE_FILENAME     OUTPUT,
   @out_IN_SOURCE_SYSOWNER        = @IN_SOURCE_SYSOWNER        OUTPUT,
   @out_IN_DESTINATION_SYSOWNER   = @IN_DESTINATION_SYSOWNER   OUTPUT,
   @out_IN_DETAIL_FORMAT_FILENAME = @IN_DETAIL_FORMAT_FILENAME OUTPUT,
   @out_IN_FOOTER_FORMAT_FILENAME = @IN_FOOTER_FORMAT_FILENAME OUTPUT,
   @out_IN_PREP_FORMAT_FILENAME   = @IN_PREP_FORMAT_FILENAME   OUTPUT,
   @out_IN_PREP_TABLE_NAME        = @IN_PREP_TABLE_NAME        OUTPUT,
   @out_OUT_TS_PREP_FILENAME      = @OUT_TS_PREP_FILENAME      OUTPUT,
   @out_IMAPS_SCHEMA_OWNER        = @IMAPS_SCHEMA_OWNER        OUTPUT,
   @out_IN_USER_PASSWORD          = @IN_USER_PASSWORD          OUTPUT,
   @out_OUT_CP_ERROR_FILENAME     = @OUT_CP_ERROR_FILENAME     OUTPUT,
   @out_IN_ETIME_CP_PROC_ID       = @IN_ETIME_CP_PROC_ID       OUTPUT,
   @out_IN_ETIME_CP_PROC_QUEUE_ID = @IN_ETIME_CP_PROC_QUEUE_ID OUTPUT
   

IF @ret_code <> 0 -- previous execution step fails
   BEGIN
      SET NOCOUNT OFF
      RETURN(1)
   END

-- Retrieve Additional parameters
-- Added CR-1543
SELECT @in_COMPANY_ID= PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = @ETIME_INTERFACE   
   AND PARAMETER_NAME = 'COMPANY_ID'

-- check eTime interface resources and obtain IMAPS DB and schema owner names
EXEC @ret_code = dbo.XX_R22_CHK_ETIME_INT_RESOURCES

IF @ret_code <> 0 -- previous execution step fails
   BEGIN
      SET NOCOUNT OFF
      RETURN(1)
   END

/*
 * Check status of interface of the last job: if it is not completed, perform recovery
 * by picking up processing from the last sucessful control point
 */

EXEC @ret_code = dbo.XX_R22_GET_POSTERROR_EXEC_STEP
   @out_last_issued_STATUS_RECORD_NUM = @lv_STATUS_RECORD_NUM OUTPUT,
   @out_next_execution_step = @resume_execution_step OUTPUT

IF @ret_code <> 0 -- previous execution step fails
   BEGIN
      SET NOCOUNT OFF
      RETURN(1)
   END
ELSE
   IF @resume_execution_step IS NOT NULL
      BEGIN
      /*
       * There are 6 execution steps (or control points or stages) for eTime interface.
       * The first 3 execution steps are covered here.
       * SPECIAL CASE 1: Stage 4 (ETIME4 - Execution of Costpoint timesheet preprocessor) is an event
       * that is beyond the control of IMAPS interface application.
       * SPECIAL CASE 2: If the next execution step is 99, this means the interface job when last run
       * resulted in status that now prevents the current interface job from being run.
       */

      IF @resume_execution_step = @STAGE_ONE
         GOTO BL_STAGE_ONE
      ELSE IF @resume_execution_step = @STAGE_TWO -- ETIME2: Load labor files into staging tables
         GOTO BL_STAGE_TWO
      ELSE IF @resume_execution_step = @STAGE_THREE
         GOTO BL_STAGE_THREE
      ELSE IF @resume_execution_step = @EXEC_STEP_DO_NOTHING
         RETURN(0)

      END
-- Defect 782 Begin
   ELSE
      BEGIN
         PRINT 'There isn''t any incomplete last interface job to consider.'

         IF @current_month_posting_ind = 'Y'
            BEGIN
               -- Verify that all conditions required to run eTime interface in the current month are met
               EXEC @ret_code = dbo.XX_R22_ET_CHK_RUN_OPTION_SP
               @in_IMAPS_db_name       = @IMAPS_DB_NAME,
                @in_IMAPS_table_owner   = @IMAPS_SCHEMA_OWNER,
          @in_user_password       = @IN_USER_PASSWORD,
                  @in_Data_FName          = @IN_TS_SOURCE_FILENAME,
                  @in_Dtl_Fmt_FName       = @IN_DETAIL_FORMAT_FILENAME,
        @in_Ftr_Fmt_FName       = @IN_FOOTER_FORMAT_FILENAME,
                  @out_STATUS_DESCRIPTION = @lv_STATUS_DESCRIPTION OUTPUT

               IF @ret_code <> 0 -- called sp returned a failure status
                  BEGIN
                     SET NOCOUNT OFF
                     RETURN(1)
                  END
            END
      END
-- Defect 782 End

/*
 * Call XX_INSERT_INT_STATUS_RECORD to get XX_IMAPS_INT_STATUS.STATUS_RECORD_NUM.
 * Each interface run has exactly one XX_IMAPS_INT_STATUS record created and subsequently updated as many times as needed.
 * When first created, XX_IMAPS_INT_STATUS.STATUS_CODE = 'INITIATED'.
 */ 
EXEC @ret_code = dbo.XX_INSERT_INT_STATUS_RECORD
   @in_IMAPS_db_name      = @IMAPS_DB_NAME,
   @in_IMAPS_table_owner  = @IMAPS_SCHEMA_OWNER,
   @in_int_name           = @ETIME_INTERFACE,
   @in_int_type           = @INBOUND_INT_TYPE,
   @in_int_source_sys     = @INT_SOURCE_SYSTEM,
   @in_int_dest_sys       = @INT_DEST_SYSTEM,
   @in_Data_FName         = @IN_TS_SOURCE_FILENAME,
   @in_int_source_owner   = @IN_SOURCE_SYSOWNER,
   @in_int_dest_owner     = @IN_DESTINATION_SYSOWNER,
   @out_STATUS_RECORD_NUM = @lv_STATUS_RECORD_NUM OUTPUT
   

IF @ret_code <> 0 -- error occurs in previous execution step
   BEGIN
      SET NOCOUNT OFF
      RETURN(1)
   END

BL_STAGE_ONE:

/*
 * Insert the first XX_IMAPS_INT_CONTROL record in a series for the first stage or control point.
 * ETIME1 = Retrieve labor file from FTP directory
 */
EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
   @in_int_ctrl_pt_num     = @STAGE_ONE,
   @in_lookup_domain_const = 'LD_ETIME_R_INTERFACE_CTRL_PT',
   @in_STATUS_RECORD_NUM   = @lv_STATUS_RECORD_NUM

IF @ret_code <> 0 -- error occurs in previous execution step
   BEGIN
      SET NOCOUNT OFF
      RETURN(1)
   END

BL_STAGE_TWO:

EXEC @ret_code = dbo.XX_R22_LOAD_ET_STAGING_DATA_SP
   @in_IMAPS_db_name       = @IMAPS_DB_NAME,
   @in_IMAPS_table_owner   = @IMAPS_SCHEMA_OWNER,
   @in_STATUS_RECORD_NUM   = @lv_STATUS_RECORD_NUM,
   @in_Data_FName          = @IN_TS_SOURCE_FILENAME,
   @in_Dtl_Fmt_FName       = @IN_DETAIL_FORMAT_FILENAME,
   @in_Ftr_Fmt_FName       = @IN_FOOTER_FORMAT_FILENAME,
   @out_STATUS_DESCRIPTION = @lv_STATUS_DESCRIPTION OUTPUT

IF @ret_code <> 0
   BEGIN
      EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
         @in_STATUS_RECORD_NUM  = @lv_STATUS_RECORD_NUM,
         @in_STATUS_CODE        = @INTERFACE_STATUS_FAILED,
         @in_STATUS_DESCRIPTION = @lv_STATUS_DESCRIPTION

      IF @ret_code <> 0
         BEGIN
            SET NOCOUNT OFF
            RETURN(1)
         END

      SET NOCOUNT OFF
      RETURN(1)
   END
ELSE -- Loading labor files into staging tables was successful
   BEGIN
      SET @lv_STATUS_DESCRIPTION = 'INFORMATION: Loading eTime staging data completed successfully.'

      EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
         @in_STATUS_RECORD_NUM  = @lv_STATUS_RECORD_NUM,
         @in_STATUS_CODE        = @INTERFACE_STATUS_INITIATED,
         @in_STATUS_DESCRIPTION = @lv_STATUS_DESCRIPTION

      /*
       * insert another XX_IMAPS_INT_CONTROL record for the second stage
       * ETIME2: Load labor files into staging tables
       */
      EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
         @in_int_ctrl_pt_num     = @STAGE_TWO,
	 @in_lookup_domain_const = 'LD_ETIME_R_INTERFACE_CTRL_PT',
         @in_STATUS_RECORD_NUM   = @lv_STATUS_RECORD_NUM

      IF @ret_code <> 0
         BEGIN
            SET NOCOUNT OFF
            RETURN(1)
         END
   END

BL_STAGE_THREE:

-- Defect 782 Begin

-- load data into XX_IMAPS_TS_PREP_TEMP to enable the next execution step
EXEC @ret_code = dbo.XX_R22_INSERT_TS_PREPROC_RECORDS
 @in_STATUS_RECORD_NUM      = @lv_STATUS_RECORD_NUM,
   @current_month_posting_ind = @current_month_posting_ind,
   @in_COMPANY_ID			  = @in_COMPANY_ID,			-- Added CR-1543
   @out_STATUS_DESCRIPTION    = @lv_STATUS_DESCRIPTION OUTPUT

-- Defect 782 End

IF @ret_code <> 0 -- failure: previous execution step fails
   BEGIN
      EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
         @in_STATUS_RECORD_NUM  = @lv_STATUS_RECORD_NUM,
         @in_STATUS_CODE        = @INTERFACE_STATUS_FAILED,
         @in_STATUS_DESCRIPTION = @lv_STATUS_DESCRIPTION

      IF @ret_code <> 0
         BEGIN
            SET NOCOUNT OFF
            RETURN(1)
         END

      SET NOCOUNT OFF
      RETURN(1)
   END

-- produce a file to be used as input by Costpoint timesheet preprocessor
EXEC @ret_code = dbo.XX_EXEC_SHELL_CMD_OSUSER --Modified for CR-3749
   @in_IMAPS_db_name       = @IMAPS_DB_NAME,
   @in_IMAPS_table_owner   = @IMAPS_SCHEMA_OWNER,
   @in_source_table        = @IN_PREP_TABLE_NAME,
   @in_format_file         = @IN_PREP_FORMAT_FILENAME,
   @in_output_file         = @OUT_TS_PREP_FILENAME,
--   @in_usr_password        = @IN_USER_PASSWORD, --Modified for CR-3749
   @out_STATUS_DESCRIPTION = @lv_STATUS_DESCRIPTION OUTPUT

IF @ret_code <> 0
   BEGIN
      EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
         @in_STATUS_RECORD_NUM  = @lv_STATUS_RECORD_NUM,
         @in_STATUS_CODE        = @INTERFACE_STATUS_FAILED,
         @in_STATUS_DESCRIPTION = @lv_STATUS_DESCRIPTION

      IF @ret_code <> 0
         BEGIN
            SET NOCOUNT OFF
            RETURN(1)
         END

      SET NOCOUNT OFF
      RETURN(1)
   END
ELSE -- success
   BEGIN
      EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
         @in_STATUS_RECORD_NUM  = @lv_STATUS_RECORD_NUM,
         @in_STATUS_CODE        = @INTERFACE_STATUS_SUCCESS,
         @in_STATUS_DESCRIPTION = @lv_STATUS_DESCRIPTION

      IF @ret_code <> 0
         BEGIN
            SET NOCOUNT OFF
            RETURN(1)
         END

      /*
       * Insert another XX_IMAPS_INT_CONTROL record for the stage 3.
       * ETIME3 = Create file for IMAPS Preprocessor and notify Costpoint via database update
       */
      EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
         @in_int_ctrl_pt_num     = @STAGE_THREE,
   	 @in_lookup_domain_const = 'LD_ETIME_R_INTERFACE_CTRL_PT',
         @in_STATUS_RECORD_NUM   = @lv_STATUS_RECORD_NUM

      IF @ret_code <> 0
         BEGIN
            SET NOCOUNT OFF
            RETURN(1)
         END
   END

/*
-- Begin CR-1414 Change 03/07/08
-- Commented for CR-1414 As, this step will now run as part of the job after the file is created
-- supply Costpoint the necessary info to run its timesheet preprocessor
EXEC @ret_code = dbo.XX_IMAPS_UPDATE_PRQENT_SP
   @in_Proc_Que_ID         = @IN_ETIME_CP_PROC_QUEUE_ID,
   @in_Proc_ID             = @IN_ETIME_CP_PROC_ID,
   @in_PROC_SERVER_ID      = @lv_PROC_SERVER_ID,
   @out_STATUS_DESCRIPTION = @lv_STATUS_DESCRIPTION OUTPUT

IF @ret_code <> 0
   BEGIN
      EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
         @in_STATUS_RECORD_NUM  = @lv_STATUS_RECORD_NUM,
         @in_STATUS_CODE        = @INTERFACE_STATUS_FAILED,
         @in_STATUS_DESCRIPTION = @lv_STATUS_DESCRIPTION

      IF @ret_code <> 0
         BEGIN
            SET NOCOUNT OFF
            RETURN(1)
         END

      SET NOCOUNT OFF
      RETURN(1)
   END
*/   
-- END CR-1414 Change 03/07/08


/*
 * This is the point where the next control point of the interface processing is taken over by the Costpoint application.
 * Update the XX_IMAPS_INT_STATUS record to say so before exiting.
 * First, get the information message to use as parameter value in the next sp call.
 * Interface processing is successful at the completion of stage 3.
 */
EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code         = 206,
   @in_placeholder_value1 = 'stage 3',
   @out_msg_text          = @lv_STATUS_DESCRIPTION OUTPUT

EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
   @in_STATUS_RECORD_NUM  = @lv_STATUS_RECORD_NUM,
   @in_STATUS_CODE = @INTERFACE_STATUS_CPIN_PROGRESS,
 @in_STATUS_DESCRIPTION = @lv_STATUS_DESCRIPTION

IF @ret_code <> 0
   BEGIN
      SET NOCOUNT OFF
      RETURN(1)
   END

SET NOCOUNT OFF
RETURN(0)


go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_R22_RUN_ETIME_INTERFACE') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_RUN_ETIME_INTERFACE >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_RUN_ETIME_INTERFACE >>>'
go

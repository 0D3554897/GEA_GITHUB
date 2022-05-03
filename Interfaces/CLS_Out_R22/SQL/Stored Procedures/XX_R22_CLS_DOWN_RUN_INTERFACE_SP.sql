USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CLS_DOWN_RUN_INTERFACE_SP]    Script Date: 5/8/2020 12:27:07 PM ******/
DROP PROCEDURE [dbo].[XX_R22_CLS_DOWN_RUN_INTERFACE_SP]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CLS_DOWN_RUN_INTERFACE_SP]    Script Date: 5/8/2020 12:27:07 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE PROCEDURE [dbo].[XX_R22_CLS_DOWN_RUN_INTERFACE_SP]
(
@in_FY char(4) = NULL,
@in_MO char(2) = NULL
)
AS

/*****************************************************************************************************
Name:       XX_R22_CLS_DOWN_RUN_INTERFACE_SP
Created by: HVT
Created:    10/27/2008
Purpose:    This stored procedure runs and drives all necessary tasks to complete the predetermined
            control points. This interface may be run repeatedly for the same valid FY and accounting
            month combination.

            Usually called by Microsoft SQL Server job.
            Adapted from XX_CLS_DOWN_RUN_INTERFACE_SP.

Notes:

CP600000465 10/27/2008 Reference BP&S Service Request CR1656
            Leverage the existing CLS Down interface for Division 16 to develop an interface
            between Costpoint and CLS to meet Division 22 (aka Research) requirements.

******************************************************************************************************/

DECLARE @SP_NAME                        varchar(50),
        @CLS_R22_INTERFACE_NAME_CD      varchar(20),
        @LOOKUP_DOMAIN_CLS_R22_CTRL_PT  varchar(30),
        @INTERFACE_STATUS_SUCCESS       varchar(20),
        @INTERFACE_STATUS_COMPLETED     varchar(20),
        @INTERFACE_STATUS_FAILED        varchar(20),
        @TOTAL_EXECUTION_STEPS          integer,
        @INBOUND_INT_TYPE               char(1),
        @INTERFACE_SOURCE_SYSTEM        varchar(50),
        @INTERFACE_DEST_SYSTEM          varchar(50),
        @INTERFACE_FILE_NAME            varchar(100),

        @CLS_DOWN_source_owner          varchar(50),
        @CLS_DOWN_dest_owner            varchar(300),
        @IMAPS_DB_NAME                  sysname,
        @IMAPS_SCHEMA_OWNER             sysname,
        @ARCH_DIR                       varchar(300),

        @current_STATUS_RECORD_NUM      integer,
        @current_STATUS_DESCRIPTION     varchar(240),
        @last_issued_STATUS_RECORD_NUM  integer,
        @last_issued_STATUS_CODE        varchar(20),
        @last_issued_CONTROL_PT_ID      varchar(20),
        @current_execution_step         integer,
        @execution_step_sp_name         sysname,
        @called_sp_name                 sysname,
        @current_CTRL_PT_ID             varchar(20),
        @ret_code                       integer,
        @SQLServer_error_code           integer,
        @SQLServer_error_msg_text       varchar(275),
        @row_count                      integer

-- set local constants
SET @SP_NAME = 'XX_R22_CLS_DOWN_RUN_INTERFACE_SP'
SET @CLS_R22_INTERFACE_NAME_CD = 'CLS_R22'
SET @LOOKUP_DOMAIN_CLS_R22_CTRL_PT = 'LD_CLS_DOWN_R22_CTRL_PT'
SET @INTERFACE_STATUS_SUCCESS = 'SUCCESS'
SET @INTERFACE_STATUS_COMPLETED = 'COMPLETED'
SET @INTERFACE_STATUS_FAILED = 'FAILED'
SET @TOTAL_EXECUTION_STEPS = 4
SET @INBOUND_INT_TYPE = 'O'
SET @INTERFACE_SOURCE_SYSTEM = 'IMAPS'
SET @INTERFACE_DEST_SYSTEM = 'CLS'
SET @INTERFACE_FILE_NAME = 'N/A'

PRINT 'DETERMINING WHICH DRIVES WE ARE WORKING WITH'

DECLARE @DATA_DRIVE nvarchar(255), @PROG_DRIVE nvarchar(255)

DECLARE @MyTble TABLE(EnvVar NVARCHAR(255))

INSERT INTO @MyTble exec xp_cmdshell 'echo %DATA_DRIVE%'
SET @DATA_DRIVE = (SELECT TOP 1 EnvVar from @MyTble)
DELETE FROM @MyTble

INSERT INTO @MyTble exec xp_cmdshell 'echo %PROG_DRIVE%'
SET @PROG_DRIVE = (SELECT TOP 1 EnvVar from @MyTble)

PRINT 'Two drives are:  ' + @PROG_DRIVE + ' AND ' + @DATA_DRIVE

SELECT @CLS_DOWN_source_owner = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS 
 WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
   AND PARAMETER_NAME = 'IN_SOURCE_SYSOWNER'

SELECT @CLS_DOWN_dest_owner = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS 
 WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
   AND PARAMETER_NAME = 'IN_DESTINATION_SYSOWNER'

SELECT @IMAPS_DB_NAME = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS 
 WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
   AND PARAMETER_NAME = 'IMAPS_DATABASE_NAME'

SELECT @IMAPS_SCHEMA_OWNER = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS 
 WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD
   AND PARAMETER_NAME = 'IMAPS_SCHEMA_OWNER'

/*
 * Check status of the last interface job: if it is not completed, perform recovery
 * by picking up processing from the last successful control point.
 */

PRINT 'Check status of the last interface job ...'

-- retrieve the execution result data of the last interface run or job
SELECT @last_issued_STATUS_RECORD_NUM = STATUS_RECORD_NUM,
       @last_issued_STATUS_CODE = STATUS_CODE
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE INTERFACE_NAME = @CLS_R22_INTERFACE_NAME_CD
   AND CREATED_DATE = (SELECT MAX(a1.CREATED_DATE) 
                         FROM dbo.XX_IMAPS_INT_STATUS a1
                        WHERE a1.INTERFACE_NAME = @CLS_R22_INTERFACE_NAME_CD
                      )

SET @row_count = @@ROWCOUNT

IF @row_count > 1
   GOTO ERROR_HANDLER

IF @last_issued_STATUS_RECORD_NUM is NULL 
   BEGIN
      PRINT 'There wasn''t any incomplete interface job to consider.'

      SELECT @row_count = COUNT(1)
        FROM dbo.XX_IMAPS_INT_STATUS
       WHERE INTERFACE_NAME = @CLS_R22_INTERFACE_NAME_CD

      IF @row_count = 0 -- this shall be the maiden run of this interface
         SET @last_issued_STATUS_CODE = @INTERFACE_STATUS_COMPLETED
      ELSE
         GOTO ERROR_HANDLER
   END

IF @last_issued_STATUS_CODE <> @INTERFACE_STATUS_COMPLETED -- e.g., INITIATED, SUCCESS, FAILED
   BEGIN
      PRINT 'The last interface job was incomplete. Determine the next execution step ...'

      -- retrieve data recorded for the last successful control point
      SELECT @last_issued_CONTROL_PT_ID = CONTROL_PT_ID 
        FROM dbo.XX_IMAPS_INT_CONTROL
       WHERE STATUS_RECORD_NUM  = @last_issued_STATUS_RECORD_NUM
         AND INTERFACE_NAME     = @CLS_R22_INTERFACE_NAME_CD
         AND CONTROL_PT_STATUS  = @INTERFACE_STATUS_SUCCESS
         AND CONTROL_RECORD_NUM = (SELECT MAX(CONTROL_RECORD_NUM) 
                                     FROM dbo.XX_IMAPS_INT_CONTROL a1
                                    WHERE a1.STATUS_RECORD_NUM = @last_issued_STATUS_RECORD_NUM
                                      AND a1.INTERFACE_NAME    = @CLS_R22_INTERFACE_NAME_CD
                                      AND a1.CONTROL_PT_STATUS = @INTERFACE_STATUS_SUCCESS
                                  ) 
			
      IF @last_issued_CONTROL_PT_ID is NULL -- no control point was ever completed successfully
         SET @current_execution_step = 1
      ELSE
         -- select next control point to execute
         SELECT @current_execution_step = PRESENTATION_ORDER + 1 
           FROM dbo.XX_LOOKUP_DETAIL 		
          WHERE APPLICATION_CODE = @last_issued_CONTROL_PT_ID 

      SET @current_STATUS_RECORD_NUM = @last_issued_STATUS_RECORD_NUM
   END
ELSE
   BEGIN
      SET @current_execution_step = 1
   END

IF @current_STATUS_RECORD_NUM is NULL
   BEGIN
      -- create new record in status table
      EXEC @ret_code = dbo.XX_INSERT_INT_STATUS_RECORD
         @in_IMAPS_db_name      = @IMAPS_DB_NAME,
         @in_IMAPS_table_owner  = @IMAPS_SCHEMA_OWNER,
         @in_int_name           = @CLS_R22_INTERFACE_NAME_CD,
         @in_int_type           = @INBOUND_INT_TYPE,
         @in_int_source_sys     = @INTERFACE_SOURCE_SYSTEM,
         @in_int_dest_sys       = @INTERFACE_DEST_SYSTEM,
         @in_Data_FName         = @INTERFACE_FILE_NAME,
         @in_int_source_owner   = @CLS_DOWN_source_owner,
         @in_int_dest_owner     = @CLS_DOWN_dest_owner,
         @out_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM OUTPUT

      IF @ret_code <> 0
         GOTO ERROR_HANDLER
   END

IF (SELECT COUNT(1) FROM dbo.XX_R22_CLS_DOWN_LOG WHERE STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM) = 0
   BEGIN
      -- create new record in log table
      EXEC @ret_code = dbo.XX_R22_CLS_DOWN_CREATE_LOG_RECORD_SP
         @in_FY                  = @in_FY,
         @in_MO                  = @in_MO,
         @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM,
         @out_SystemError        = @SQLServer_error_code OUTPUT,
         @out_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION OUTPUT

      IF @ret_code <> 0
         GOTO ERROR_HANDLER
   END

WHILE @current_execution_step <= @TOTAL_EXECUTION_STEPS
   BEGIN
      /*
       * Note: Beyond the last control point, the SQL Server job "R22 CLS Down - Run Closeout"
       * empties and re-populate table XX_R22_CLS_DOWN_LAST_MONTH_YTD using XX_R22_CLS_DOWN_THIS_MONTH_YTD data.
       */
      SET @execution_step_sp_name =
         CASE @current_execution_step
            WHEN 1 THEN 'dbo.XX_R22_CLS_DOWN_LOAD_STAGE_SP'
            WHEN 2 THEN 'dbo.XX_R22_CLS_DOWN_GET_TOTALS_SP'
            WHEN 3 THEN 'dbo.XX_R22_CLS_DOWN_CREATE_FLAT_FILE_SP'
            WHEN 4 THEN 'dbo.XX_R22_CLS_DOWN_ARCHIVE_FILES_SP'
         END

      SET @called_sp_name = @execution_step_sp_name

      BEGIN TRANSACTION CURRENT_CONTROL_POINT

      EXEC @ret_code = @execution_step_sp_name
         @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM, 
         @out_SystemError        = @SQLServer_error_code   OUTPUT,
         @out_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION OUTPUT

      IF @ret_code <> 0 -- the called SP returned an error status
         BEGIN
            ROLLBACK TRANSACTION CURRENT_CONTROL_POINT
            GOTO ERROR_HANDLER
         END
      ELSE -- the SP call was successful
         COMMIT TRANSACTION CURRENT_CONTROL_POINT

      -- Update the XX_IMAPS_INT_STATUS record with the latest control point processing result

      SELECT @current_CTRL_PT_ID = t1.APPLICATION_CODE
        FROM dbo.XX_LOOKUP_DETAIL t1,
             dbo.XX_LOOKUP_DOMAIN t2
       WHERE t1.LOOKUP_DOMAIN_ID   = t2.LOOKUP_DOMAIN_ID
         AND t1.PRESENTATION_ORDER = @current_execution_step
         AND t2.DOMAIN_CONSTANT    = @LOOKUP_DOMAIN_CLS_R22_CTRL_PT

      SET @current_STATUS_DESCRIPTION = 'INFORMATION: Processing of control point ' + @current_CTRL_PT_ID + ' completed successfully.'

      EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
         @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
         @in_STATUS_CODE        = @INTERFACE_STATUS_SUCCESS,
         @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION

      IF @ret_code <> 0
         GOTO ERROR_HANDLER

      -- insert a XX_IMAPS_INT_CONTROL record for the successfully completed control point
      EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
         @in_int_ctrl_pt_num     = @current_execution_step,
         @in_lookup_domain_const = @LOOKUP_DOMAIN_CLS_R22_CTRL_PT,
         @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM

      IF @ret_code <> 0
         GOTO ERROR_HANDLER

      SET @current_execution_step = @current_execution_step + 1

   END /* WHILE @current_execution_step <= @TOTAL_EXECUTION_STEPS */

PRINT 'Final update to XX_IMAPS_INT_STATUS ...'

-- Final update to the XX_IMAPS_INT_STATUS record. Mark the current interface run as completed.
EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD

   @in_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM,
   @in_STATUS_CODE       = @INTERFACE_STATUS_COMPLETED

IF @ret_code <> 0
   GOTO ERROR_HANDLER

PRINT 'Prepare attachment and send notification e-mail ...'

-- Get control file name (archived for this run) to mail as attachment to the status notification e-mail
SELECT @ARCH_DIR = REPLACE(PARAMETER_VALUE,'%DATA_DRIVE%',@DATA_DRIVE) 
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = @CLS_R22_INTERFACE_NAME_CD 
   AND PARAMETER_NAME = 'ARCH_DIR'

SET @ARCH_DIR = @ARCH_DIR + CAST(@current_STATUS_RECORD_NUM as varchar(15)) + '_IMAR_TO_CLS_DOWN_SUMMARY.txt'

EXEC @ret_code = dbo.XX_SEND_STATUS_MAIL_SP
   @in_StatusRecordNum = @current_STATUS_RECORD_NUM,
   @in_Attachments = @ARCH_DIR

IF @ret_code <> 0
   GOTO ERROR_HANDLER

RETURN(0)

ERROR_HANDLER:

/*
 * Error processing depends on three values @ret_code, @current_STATUS_DESCRIPTION and @SQLServer_error_code.
 *
 * There are 3 scenarios:
 *
 * 1. If @ret_code = 1: Do nothing. The error has been handled by the called stored procedure.
 * 2. If @ret_code = 1 and @current_STATUS_DESCRIPTION is NULL: This should not happen. However, if it does,
 *    issue general error message together with system error message, if available.
 * 3. If @ret_code <> 1 (e.g., @ret_code = 301): Issue IMAPS error message together with system error message, if available.
 */

IF @ret_code = 1 AND @current_STATUS_DESCRIPTION is NULL 
   SET @ret_code = 301 -- An error has occured. Please contact system administrator.

IF @SQLServer_error_code = 0
   SET @SQLServer_error_code = NULL

IF @ret_code <> 1  
   EXEC dbo.XX_ERROR_MSG_DETAIL
      @in_error_code           = @ret_code,
      @in_SQLServer_error_code = @SQLServer_error_code,
      @in_display_requested    = 1, -- display both IMAPS error message and SQL Server error message, if any
      @in_calling_object_name  = @SP_NAME,
      @out_msg_text            = @current_STATUS_DESCRIPTION OUTPUT,
      @out_syserror_msg_text   = @SQLServer_error_msg_text OUTPUT

-- Update status record as "failed"
EXEC dbo.XX_UPDATE_INT_STATUS_RECORD

   @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
   @in_STATUS_CODE        = @INTERFACE_STATUS_FAILED,
   @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION
	
EXEC dbo.XX_SEND_STATUS_MAIL_SP
   @in_StatusRecordNum = @current_STATUS_RECORD_NUM

RETURN(1)

GO



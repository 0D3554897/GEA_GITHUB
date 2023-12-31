USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE ID = object_id(N'[dbo].[XX_R22_PROJEMPL_RUN_INTER_SP]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[XX_R22_PROJEMPL_RUN_INTER_SP]
GO

CREATE PROCEDURE [dbo].[XX_R22_PROJEMPL_RUN_INTER_SP] AS

/****************************************************************************************************
Name:       XX_R22_PROJEMPL_RUN_INTER_SP
Author:     Veera
Created:    06/28/2008
Purpose:    This stored procedure serves as a script to drive and execute all necessary tasks to
            to accomplish an PROJEMPL interface.
Parameters: 
Result Set: None
Notes:      Example of stored procedure call follow.

            EXEC dbo.XX_R22_PROJEMPL_RUN_INTER_SP
History:    CP600000392 - Modified to change the Domain constant variable to LD_PROJ_EMPL_INTERFACE_CTRL_PT
****************************************************************************************************/

DECLARE @SP_NAME                        sysname,
        @TOTAL_NUM_OF_CTRL_PTS          integer,
        @IMAPS_SCHEMA_OWNER             sysname,
        @IN_SOURCE_SYSOWNER             varchar(300),
        @OUT_DESTINATION_SYSOWNER       varchar(300),
        @SERVER_NAME                    sysname,
        @IMAPS_DB_NAME                  sysname,
        @PROJEMPL_INTERFACE_NAME             varchar(50),
        @INBOUND_INT_TYPE               char(1),
        @INT_DEST_SYSTEM                varchar(50),
        @LOOKUP_DOMAIN_PROJEMPL_CTRL_PT      varchar(30),
        @INTERFACE_STATUS_SUCCESS       varchar(20),
        @INTERFACE_STATUS_COMPLETED     varchar(20),
        @INTERFACE_STATUS_FAILED        varchar(20),

		@projempl_data_fname 		SYSNAME,

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
SET @SP_NAME = 'XX_PROJEMPL_RUN_INTER_SP'
SET @SERVER_NAME = @@servername
SET @IMAPS_DB_NAME = db_name()
SET @PROJEMPL_INTERFACE_NAME = 'PROJEMPL'
SET @INBOUND_INT_TYPE = 'O' -- O=Outbound
SET @INT_DEST_SYSTEM = 'PROJEMPL'
SET	@projempl_data_fname	= 'N/A'
SET @LOOKUP_DOMAIN_PROJEMPL_CTRL_PT = 'LD_PROJ_EMPL_INTERFACE_CTRL_PT' -- 'LD_PROJEMPL_INTERFACE_CTRL_PT' Modified by Veera 11/04/08 CP600000392
SET @INTERFACE_STATUS_SUCCESS = 'SUCCESS'
SET @INTERFACE_STATUS_COMPLETED = 'COMPLETED'
SET @INTERFACE_STATUS_FAILED = 'FAILED'


SET NOCOUNT ON

PRINT 'Retrieve the necessary application global constants to run the PROJEMPL interface ...'

SELECT @IMAPS_SCHEMA_OWNER = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = @PROJEMPL_INTERFACE_NAME
   AND PARAMETER_NAME = 'IMAPS_SCHEMA_OWNER'

SELECT @IN_SOURCE_SYSOWNER = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = @PROJEMPL_INTERFACE_NAME
   AND PARAMETER_NAME = 'IN_SOURCE_SYSOWNER'

SELECT @OUT_DESTINATION_SYSOWNER = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = @PROJEMPL_INTERFACE_NAME
   AND PARAMETER_NAME = 'OUT_DESTINATION_SYSOWNER'

SELECT @TOTAL_NUM_OF_CTRL_PTS = CAST(PARAMETER_VALUE as integer)
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = @PROJEMPL_INTERFACE_NAME
   AND PARAMETER_NAME = 'TOTAL_NUMBER_OF_CTRL_PTS'

/*
 * Check status of the last interface job: if it is not completed, perform recovery
 * by picking up processing from the last sucessful control point.
 */

PRINT 'Check status of the last interface job ...'

-- Retrieve the execution result data of the last interface run or job
SELECT @last_issued_STATUS_RECORD_NUM = STATUS_RECORD_NUM,
       @last_issued_STATUS_CODE = STATUS_CODE
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE INTERFACE_NAME = @PROJEMPL_INTERFACE_NAME
   AND CREATED_DATE   = (SELECT MAX(s.CREATED_DATE) 
                           FROM dbo.XX_IMAPS_INT_STATUS s
                          WHERE s.INTERFACE_NAME = @PROJEMPL_INTERFACE_NAME)

SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

IF @SQLServer_error_code > 0 or @row_count > 1
   GOTO ERROR_HANDLER

IF @last_issued_STATUS_RECORD_NUM IS NULL
   BEGIN
      PRINT 'There wasn''t any unfinished interface job to consider.'

      SELECT @last_issued_STATUS_RECORD_NUM = COUNT(1)
        FROM dbo.XX_IMAPS_INT_STATUS
       WHERE INTERFACE_NAME = @PROJEMPL_INTERFACE_NAME

      IF @last_issued_STATUS_RECORD_NUM = 0
         SET @last_issued_STATUS_CODE = @INTERFACE_STATUS_COMPLETED
      ELSE
        GOTO ERROR_HANDLER
   END

IF @last_issued_STATUS_CODE <> @INTERFACE_STATUS_COMPLETED -- e.g., INITIATED, SUCCESS, FAILED
   BEGIN
      PRINT 'The last interface job was incomplete. Determine the next execution step ...'

      -- Retrieve data recorded for the last successful control point	
      SELECT @last_issued_CONTROL_PT_ID = CONTROL_PT_ID
        FROM dbo.XX_IMAPS_INT_CONTROL
       WHERE STATUS_RECORD_NUM  = @last_issued_STATUS_RECORD_NUM
         AND INTERFACE_NAME     = @PROJEMPL_INTERFACE_NAME
         AND CONTROL_PT_STATUS  = @INTERFACE_STATUS_SUCCESS
         AND CONTROL_RECORD_NUM = (select MAX(c.CONTROL_RECORD_NUM) 
                                     from dbo.XX_IMAPS_INT_CONTROL c
                                    where c.STATUS_RECORD_NUM = @last_issued_STATUS_RECORD_NUM
                                      and c.INTERFACE_NAME    = @PROJEMPL_INTERFACE_NAME
                                      and c.CONTROL_PT_STATUS = @INTERFACE_STATUS_SUCCESS)

      SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

      IF @SQLServer_error_code > 0
         GOTO ERROR_HANDLER

      IF @last_issued_CONTROL_PT_ID IS NULL -- no control point was ever completed successfully
         SET @current_execution_step = 1
      ELSE -- at least one control point was completed successfully
         BEGIN
            -- Determine the next execution step where the interface run resumes
            SELECT @current_execution_step = t1.PRESENTATION_ORDER + 1
              FROM dbo.XX_LOOKUP_DETAIL t1,
                   dbo.XX_LOOKUP_DOMAIN t2
             WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
               AND t1.APPLICATION_CODE = @last_issued_CONTROL_PT_ID
               AND t2.DOMAIN_CONSTANT  = @LOOKUP_DOMAIN_PROJEMPL_CTRL_PT
         END

      SET @current_STATUS_RECORD_NUM = @last_issued_STATUS_RECORD_NUM
   END
ELSE
   SET @current_execution_step = 1 -- may proceed with the current interface job


-- This is the very first attempt to run this interface.
IF @current_STATUS_RECORD_NUM IS NULL
   BEGIN
      PRINT 'Begin processing for the current ' + @PROJEMPL_INTERFACE_NAME + ' interface run ...'

      /*
       * Call XX_INSERT_INT_STATUS_RECORD to add a new XX_IMAPS_INT_STATUS record.
       * Each interface job has exactly one XX_IMAPS_INT_STATUS record created and subsequently updated
       * as many times as needed. When first created, XX_IMAPS_INT_STATUS.STATUS_CODE = 'INITIATED'.
       */ 
      EXEC @ret_code = dbo.XX_INSERT_INT_STATUS_RECORD
         @in_IMAPS_db_name      = @IMAPS_DB_NAME,
         @in_IMAPS_table_owner  = @IMAPS_SCHEMA_OWNER,
         @in_int_name           = @PROJEMPL_INTERFACE_NAME,
         @in_int_type           = @INBOUND_INT_TYPE,
         @in_int_source_sys     = 'IMAPS',
         @in_int_dest_sys       = @INT_DEST_SYSTEM,
		 @in_data_fname         = @projempl_data_fname,
         @in_int_source_owner   = @IN_SOURCE_SYSOWNER,
         @in_int_dest_owner     = @OUT_DESTINATION_SYSOWNER,
         @out_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM OUTPUT

      IF @ret_code <> 0 GOTO ERROR_HANDLER
   END

-- Begin core interface processing

WHILE @current_execution_step <= @TOTAL_NUM_OF_CTRL_PTS
   BEGIN
      SELECT @execution_step_sp_name =
             CASE @current_execution_step
                WHEN 1 THEN 'dbo.XX_R22_PROJEMPL_INSERT_SP'
                WHEN 2 THEN 'dbo.XX_R22_PROJEMPL_ARCHIVE_SP'
             END

      SET @called_SP_name = @execution_step_sp_name

      --BEGIN TRANSACTION CURRENT_CTRL_PT

      EXEC @ret_code = @execution_step_sp_name
         @in_STATUS_RECORD_NUM     = @current_STATUS_RECORD_NUM,
         @out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
         @out_STATUS_DESCRIPTION   = @current_STATUS_DESCRIPTION OUTPUT

	  IF @ret_code <> 0 OR @@ERROR <> 0 -- the called SP returns an error status
      --IF @ret_code <> 0 -- the called SP returns an error status
         BEGIN
            --ROLLBACK TRANSACTION CURRENT_CTRL_PT
            GOTO ERROR_HANDLER
         END
     -- ELSE -- SP call is successful
       --  COMMIT TRANSACTION CURRENT_CTRL_PT

      PRINT 'Update the XX_IMAPS_INT_STATUS record with the latest control point processing result ...'

      SELECT @current_CTRL_PT_ID = t1.APPLICATION_CODE
        FROM dbo.XX_LOOKUP_DETAIL t1,
             dbo.XX_LOOKUP_DOMAIN t2
       WHERE t1.LOOKUP_DOMAIN_ID   = t2.LOOKUP_DOMAIN_ID
         AND t1.PRESENTATION_ORDER = @current_execution_step
         AND t2.DOMAIN_CONSTANT    = @LOOKUP_DOMAIN_PROJEMPL_CTRL_PT

      SET @current_STATUS_DESCRIPTION = 'INFORMATION: Processing for control point ' + @current_CTRL_PT_ID + ' completed successfully.'

      EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
         @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
         @in_STATUS_CODE        = @INTERFACE_STATUS_SUCCESS,
         @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION

      -- Insert a XX_IMAPS_INT_CONTROL record for the successfully completed control point
      EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
         @in_int_ctrl_pt_num     = @current_execution_step,
         @in_lookup_domain_const = @LOOKUP_DOMAIN_PROJEMPL_CTRL_PT,
         @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM

      IF @ret_code <> 0
         GOTO ERROR_HANDLER

      SET @current_execution_step = @current_execution_step + 1

   END /* WHILE @current_execution_step <= @TOTAL_NUM_OF_CTRL_PTS */

-- Final update to the XX_IMAPS_INT_STATUS record: Mark the current interface run as completed
EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
   @in_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM,
   @in_STATUS_CODE       = @INTERFACE_STATUS_COMPLETED

IF @ret_code <> 0
   GOTO ERROR_HANDLER

-- Create e-mail data to be used by the PORT application to send e-mail to interface stakeholders
EXEC @ret_code = dbo.XX_SEND_STATUS_MAIL_SP
   @in_StatusRecordNum = @current_STATUS_RECORD_NUM

IF @ret_code <> 0
   GOTO ERROR_HANDLER

SET NOCOUNT OFF
RETURN(0)

ERROR_HANDLER:

/*
 * When the called SP returns error status 1, it has already handled the error itself.
 * When the called SP returns error status that is greater than 1, it did not complete the handling of the error itself.
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
      -- Update XX_IMAPS_INT_STATUS record to show failure status
      EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
         @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
         @in_STATUS_CODE        = @INTERFACE_STATUS_FAILED,
         @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION

      -- Notify interface stakeholders of interface run failure via e-mail
      EXEC dbo.XX_SEND_STATUS_MAIL_SP
         @in_StatusRecordNum = @current_STATUS_RECORD_NUM
   END

SET NOCOUNT OFF
RETURN(1)

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_7KEYS_PROCESS_RUN_INPUT_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   drop procedure [dbo].[XX_7KEYS_PROCESS_RUN_INPUT_SP]
GO

CREATE PROCEDURE dbo.XX_7KEYS_PROCESS_RUN_INPUT_SP
(
@in_FY_CD               varchar(6)   = NULL,
@in_period_num          smallint     = NULL,

-- Defect_647_Begin
@in_RUN_TYPE_ID         integer      = NULL,
@in_STATUS_RECORD_NUM   integer      = NULL,
-- Defect_647_End

@out_FY_CD              varchar(6)   = NULL OUTPUT,
@out_period_num         smallint     = NULL OUTPUT,
@out_run_type_id        integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION varchar(255) = NULL OUTPUT
)
AS

/****************************************************************************************************
Name:       XX_7KEYS_PROCESS_RUN_INPUT_SP
Author:     HVT
Created:    11/15/2005
Purpose:    Process the interface run input parameter values supplied by the user.
            Interface run is of two types, scheduled and manual/requested. For a manual run, the user
            must supply both the FY code and the period number as report data selection criteria.
            FY code and period number returned by this sp are used to pass to stored procedure
            XX_7KEYS_GET_OUTPUT_DATA_SP.
            Called by XX_7KEYS_RUN_INTERFACE_SP.
Parameters: 
Result Set: This SP returns to the calling SP the values to assign to the columns FY_CD, PD_NO and
            RUN_TYPE_ID of the table XX_7KEYS_RUN_LOG, used especially for an INSERT statement.
Notes:      Call examples follow.

            For normal run:
            EXEC @ret_code = dbo.XX_7KEYS_PROCESS_RUN_INPUT_SP
               @in_FY_CD               = @in_FY_CD,
               @in_period_num          = @in_period_num,
               @out_FY_CD              = @current_run_FY_CD OUTPUT,
               @out_period_num         = @current_run_PD_NO OUTPUT,
               @out_run_type_id        = @current_run_type_id OUTPUT,
               @out_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION OUTPUT

            For recovery run:
            EXEC @ret_code = dbo.XX_7KEYS_PROCESS_RUN_INPUT_SP
               @in_FY_CD               = @current_run_FY_CD,
               @in_period_num          = @current_run_PD_NO,
               @in_RUN_TYPE_ID         = @current_run_type_id,
               @in_STATUS_RECORD_NUM   = @last_issued_STATUS_RECORD_NUM,
               @out_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION OUTPUT

02/09/2006: Fix the validation of the combination of FY and period input parameter values.

Defect 611: Fix the system-determined FY and period values when no input parameter values exist.

Defect 647: When an interface run encounters errors and recovery must be performed, make sure that
            in between control points, when the user may execute the interface again and again,
            the user-supplied input parameter values remain consistent with the input parameter
            values recorded in the first attempt to run the interface.

Defect 1575 When this interface is run for the very first time, allow it to be run in manual mode. 
****************************************************************************************************/

DECLARE @SP_NAME                    sysname,
        @LOOKUP_DOMAIN_RUN_TYPE     varchar(30),
        @RUN_TYPE_SCHEDULED         varchar(20),
        @RUN_TYPE_MANUAL            varchar(20),
        @7KEYS_INTERFACE_NAME       varchar(50),
        @INTERFACE_STATUS_COMPLETED varchar(20),
        @current_FY_CD              varchar(6),
        @current_PD_NO              smallint,
-- Defect_611_Begin
        @last_FY_CD                 varchar(6),
        @last_PD_NO                 smallint,
-- Defect_611_End
        @run_mode                   varchar(20),
        @IMAPS_error_code           integer,
        @error_msg_placeholder1     sysname,
        @error_msg_placeholder2     sysname,
        @row_count                  integer,
-- Defect_647_Begin
        @saved_FY_CD                varchar(6),
        @saved_PD_NO                smallint,
        @saved_RUN_TYPE_ID          integer
-- Defect_647_End

-- set local constants
SET @SP_NAME = 'XX_7KEYS_PROCESS_RUN_INPUT_SP'
SET @LOOKUP_DOMAIN_RUN_TYPE = 'LD_INTERFACE_RUN_TYPE'
SET @RUN_TYPE_SCHEDULED = 'SCHEDULED'
SET @RUN_TYPE_MANUAL = 'MANUAL'
SET @7KEYS_INTERFACE_NAME = '7KEYS/PSP'
SET @INTERFACE_STATUS_COMPLETED = 'COMPLETED'

-- initialize local variables
SET @current_FY_CD = DATEPART(year, GETDATE())
SET @current_PD_NO = DATEPART(month, GETDATE())

-- Defect 647 Begin

/*
 * If this interface run is a recovery run, make sure that the input parameters specified by the user now are 
 * the same as the ones specified in the previous run attempt. Note that a XX_7KEYS_RUN_LOG record is inserted
 * in XX_7KEYS_RUN_INTERFACE_SP when interface processing is initiated successfully.
 */

IF @in_STATUS_RECORD_NUM IS NOT NULL
   BEGIN
      PRINT 'Verify user-supplied input parameter values for interface recovery run ...'

      -- validate the stored procedure call command for required input parameters
      IF @in_FY_CD IS NULL OR @in_period_num IS NULL OR @in_RUN_TYPE_ID IS NULL
         BEGIN
            SET @IMAPS_error_code = 100 -- Missing required input parameter(s)
            GOTO BL_ERROR_HANDLER
         END

      -- retrieve current interface run's input log record
      SELECT @saved_FY_CD = FY_CD, @saved_PD_NO = PD_NO, @saved_RUN_TYPE_ID = RUN_TYPE_ID
        FROM dbo.XX_7KEYS_RUN_LOG
       WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

      SET @row_count = @@ROWCOUNT          
      IF @row_count = 0
         BEGIN
            SET @IMAPS_error_code = 203 -- Missing required %1 for %2.
            SET @error_msg_placeholder1 = 'XX_7KEYS_RUN_LOG record'
            SET @error_msg_placeholder2 = 'for the existing corresponding XX_IMAPS_INT_STATUS record. Please contact system administrator'
            GOTO BL_ERROR_HANDLER
         END

      IF @in_FY_CD != @saved_FY_CD
         BEGIN
            SET @IMAPS_error_code = 210 -- %1 failed validation due to %2.
            SET @error_msg_placeholder1 = 'User-supplied input parameter FY code'
            SET @error_msg_placeholder2 = 'discrepancy found in log record'
            GOTO BL_ERROR_HANDLER
         END

      IF @in_period_num != @saved_PD_NO
         BEGIN
            SET @IMAPS_error_code = 210 -- %1 failed validation due to %2.
            SET @error_msg_placeholder1 = 'User-supplied input parameter period number'
            SET @error_msg_placeholder2 = 'discrepancy found in log record'
            GOTO BL_ERROR_HANDLER
         END

      IF @in_RUN_TYPE_ID != @saved_RUN_TYPE_ID
         BEGIN
            SET @IMAPS_error_code = 210 -- %1 failed validation due to %2.
            SET @error_msg_placeholder1 = 'User-supplied input parameter interface run mode'
            SET @error_msg_placeholder2 = 'discrepancy found in log record'
            GOTO BL_ERROR_HANDLER
         END

      RETURN(0)
   END

-- Defect 647 End

PRINT 'Validate user''s command line to run 7KEYS/PSP interface ...'

IF @in_FY_CD IS NOT NULL AND ISNUMERIC(@in_FY_CD) = 0
   BEGIN
      -- %1 is invalid or does not exist.
      SET @IMAPS_error_code = 200
      SET @error_msg_placeholder1 = 'FY code'
      GOTO BL_ERROR_HANDLER
   END

IF (@in_FY_CD IS NULL AND @in_period_num IS NOT NULL) OR (@in_FY_CD IS NOT NULL AND @in_period_num IS NULL)
   BEGIN
      SET @IMAPS_error_code = 100
      GOTO BL_ERROR_HANDLER
   END

-- confirm manual run and validate input
IF (@in_FY_CD IS NOT NULL AND @in_period_num IS NOT NULL)
   BEGIN
      IF @in_period_num <= 0 OR @in_period_num > 12
         BEGIN
            SET @IMAPS_error_code = 200 -- USER ERROR: %1 is invalid or does not exist.
            SET @error_msg_placeholder1 = 'The requested accounting period'
            GOTO BL_ERROR_HANDLER
         END

      -- Next 2 scenarios: Cannot request a run that requires data far into the future.
      IF @in_FY_CD > @current_FY_CD
         BEGIN
            SET @IMAPS_error_code = 212 -- USER ERROR: %1 indicates a future %2
            SET @error_msg_placeholder1 = 'The requested FY'
            SET @error_msg_placeholder2 = 'FY'
            GOTO BL_ERROR_HANDLER
         END


      IF @in_FY_CD = @current_FY_CD AND @in_period_num > @current_PD_NO
         BEGIN
            -- The requested accounting period indicates a future period.
            SET @IMAPS_error_code = 212
            SET @error_msg_placeholder1 = 'The requested accounting period'
            SET @error_msg_placeholder2 = 'period'
            GOTO BL_ERROR_HANDLER
         END

      SET @run_mode = @RUN_TYPE_MANUAL
   END

IF (@in_FY_CD IS NULL AND @in_period_num IS NULL)
   SET @run_mode = @RUN_TYPE_SCHEDULED

-- retrieve the ID of the run type from reference
select @out_run_type_id = t1.LOOKUP_ID
  from dbo.XX_LOOKUP_DETAIL t1,
       dbo.XX_LOOKUP_DOMAIN t2
 where t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   and t1.APPLICATION_CODE = @run_mode
   and t2.DOMAIN_CONSTANT  = @LOOKUP_DOMAIN_RUN_TYPE

IF @out_run_type_id is null
   BEGIN
      SET @IMAPS_error_code = 213 -- SYSTEM ERROR: Missing %1 from %2.
      SET @error_msg_placeholder1 = 'interface run type ID'
      SET @error_msg_placeholder2 = 'system lookup table. Please contact system administrator'
      GOTO BL_ERROR_HANDLER
   END

/*
 * Special case: No XX_IMAPS_INT_STATUS record exists for 7KEYS/PSP interface.
 * The interface is being run for the very first time.
 */
select @row_count = COUNT(1)
  from dbo.XX_IMAPS_INT_STATUS
 where INTERFACE_NAME = @7KEYS_INTERFACE_NAME

IF @row_count = 0
-- Defect 11575 Begin
   IF @run_mode = @RUN_TYPE_SCHEDULED
      BEGIN
         -- return current FY and period to the calling SP
         SET @out_FY_CD = @current_FY_CD
         SET @out_period_num = @current_PD_NO
         RETURN(0)
      END
-- Defect 11575 End

-- Defect_611_Begin

-- retrieve input parameter data from the last logged 7KEYS/PSP interface run
select @last_FY_CD = t1.FY_CD, @last_PD_NO = t1.PD_NO
  from dbo.XX_7KEYS_RUN_LOG t1
 where t1.STATUS_RECORD_NUM = (select MAX(t2.STATUS_RECORD_NUM) 
                                 from dbo.XX_7KEYS_RUN_LOG t2,
                                      dbo.XX_IMAPS_INT_STATUS t3
                                where t2.STATUS_RECORD_NUM = t3.STATUS_RECORD_NUM
                                  and t3.INTERFACE_NAME = @7KEYS_INTERFACE_NAME
                                  and t3.STATUS_CODE = @INTERFACE_STATUS_COMPLETED
                                  and t2.RUN_TYPE_ID = @out_run_type_id)
-- Defect_611_End

SET @row_count = @@ROWCOUNT

IF @row_count = 0
   IF @run_mode = @RUN_TYPE_SCHEDULED
      BEGIN
         -- This scenario: Give it a chance to insert the first row in XX_7KEYS_RUN_LOG for a scheduled run.

         SET @IMAPS_error_code = 209 -- WARNING: No %1 exist to %2.
         SET @error_msg_placeholder1 = 'XX_7KEYS_RUN_LOG records'
         SET @error_msg_placeholder2 = 'determine the FY and accounting period ' + CHAR(13)
                                       + 'for this scheduled run. '
                                       + 'Use current FY and period as default input parameter values'

         EXEC dbo.XX_ERROR_MSG_DETAIL
            @in_error_code           = @IMAPS_error_code,
            @in_display_requested    = 1,
            @in_SQLServer_error_code = null,
            @in_placeholder_value1   = @error_msg_placeholder1,
            @in_placeholder_value2   = @error_msg_placeholder2,
            @in_calling_object_name  = @SP_NAME,
            @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

         -- return current FY and period to the calling SP
         SET @out_FY_CD = @current_FY_CD
         SET @out_period_num = @current_PD_NO
         RETURN(0)
      END

IF @run_mode = @RUN_TYPE_SCHEDULED
   BEGIN
-- Defect_611_Begin

      -- If no user-supplied input parameter values exist, set default
      SET @out_FY_CD = @last_FY_CD
      SET @out_period_num = @last_PD_NO

      /*
       * If the period of the last scheduled run is 12, for the current scheduled run, set the FY 
       * to the last scheduled run's FY incremented by 1, and the period to 1.
       */
      IF @last_PD_NO = 12
         BEGIN
            SET @out_FY_CD = CAST((CAST(@last_FY_CD AS integer) + 1) AS varchar(6))
            SET @out_period_num = 1
         END

-- Defect_611_End
   END

IF @run_mode = @RUN_TYPE_MANUAL
   BEGIN
      SET @out_FY_CD = @in_FY_CD
      SET @out_period_num = @in_period_num
   END

RETURN(0)

BL_ERROR_HANDLER:

IF @IMAPS_error_code is not null
   EXEC dbo.XX_ERROR_MSG_DETAIL
      @in_error_code           = @IMAPS_error_code,
      @in_display_requested    = 1,
      @in_SQLServer_error_code = null,
      @in_placeholder_value1   = @error_msg_placeholder1,
      @in_placeholder_value2   = @error_msg_placeholder2,
      @in_calling_object_name  = @SP_NAME,
      @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
ELSE
   PRINT @out_STATUS_DESCRIPTION

RETURN(1)

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


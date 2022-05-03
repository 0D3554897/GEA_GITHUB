IF OBJECT_ID('dbo.XX_R22_GET_POSTERROR_EXEC_STEP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_GET_POSTERROR_EXEC_STEP
    IF OBJECT_ID('dbo.XX_R22_GET_POSTERROR_EXEC_STEP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_GET_POSTERROR_EXEC_STEP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_GET_POSTERROR_EXEC_STEP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go

CREATE PROCEDURE [dbo].[XX_R22_GET_POSTERROR_EXEC_STEP]
(
@out_last_issued_STATUS_RECORD_NUM integer = NULL OUTPUT,
@out_next_execution_step           integer = NULL OUTPUT
)
AS

/*********************************************************************************************************
Name:       XX_R22_GET_POSTERROR_EXEC_STEP
Author:     HVT
Created:    08/20/2005
Purpose:    This is the "recovery" procedure to deal with the case where the last interface run resulted
            in error and therefore was not completed. This procedure determines which stage in the
            interface execution to pick up processing.
            Check the last successful control point recorded, determine the next control point to 
            "achieve." "The next control point" may be the only, first, or last execution step of a
            set of all remaining execution steps. Special case: if the next control point is the execution
            of the Costpoint timesheet preprocessor, then stop running the eTime interface. Note that
            there can be only one Costpoint timesheet preprocessor job to be run at any point in time.
            Called by XX_R22_RUN_ETIME_INTERFACE.
Parameters: 
Result Set: 
Notes:

Defect 782  04/25/2006 The interface job is also halted when the source ET&E input file is found to have
            been used successfully once before.

DR4037      03/13/2012 CP600001476
            Enable eTime interface and eTime miscode interfaces for divisions 16 and 22 to run simultaneously.
**********************************************************************************************************/
 
DECLARE @SP_NAME                        sysname,
        @ETIME_INTTERFACE               varchar(50),
        @INTERFACE_STATUS_SUCCESS       varchar(20),   -- applied to XX_IMAPS_INT_CONTROL records
        @INTERFACE_STATUS_FAILED        varchar(20),   -- applied to XX_IMAPS_INT_STATUS records
        @INTERFACE_STATUS_COMPLETED     varchar(20),   -- applied to XX_IMAPS_INT_STATUS records
        @INTERFACE_STATUS_DUPLICATE     varchar(20),   -- applied to XX_IMAPS_INT_STATUS records
        @LD_CONSTANT_ETIME_CTRL_PT      varchar(30),
        @STAGE_FOUR                     integer,
        @EXEC_STEP_DO_NOTHING           integer,
        @last_issued_STATUS_CODE        varchar(20),   -- XX_IMAPS_INT_STATUS.STATUS_CODE
        @last_issued_CONTROL_PT_ID      varchar(20),   -- XX_IMAPS_INT_CONTROL.CONTROL_PT_ID
        @return_code                    integer,       -- status code returned from a called sp
        @error_code                     integer,
        @row_count                      integer

-- set local constants
-- DR4037_Begin
SET @SP_NAME = 'XX_R22_GET_POSTERROR_EXEC_STEP'
SET @ETIME_INTTERFACE = 'ETIME_R22'
-- DR4037_End
SET @INTERFACE_STATUS_SUCCESS = 'SUCCESS'
SET @INTERFACE_STATUS_FAILED = 'FAILED'
SET @INTERFACE_STATUS_COMPLETED = 'COMPLETED'
-- Defect 782 Begin
SET @INTERFACE_STATUS_DUPLICATE = 'DUPLICATE'
-- Defect 782 End
SET @LD_CONSTANT_ETIME_CTRL_PT = 'LD_ETIME_INTERFACE_CTRL_PT'
SET @STAGE_FOUR = 4
SET @EXEC_STEP_DO_NOTHING = 99

-- this is the special case where no interface job has ever been run
SELECT @row_count = COUNT(1)
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE INTERFACE_NAME = @ETIME_INTTERFACE

IF @row_count = 0
   RETURN(0) -- no further recovery processing needed

-- retrieve the execution result data of the last interface run or job
SELECT @out_last_issued_STATUS_RECORD_NUM = STATUS_RECORD_NUM,
       @last_issued_STATUS_CODE = STATUS_CODE
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE INTERFACE_NAME = @ETIME_INTTERFACE
   AND CREATED_DATE = (SELECT MAX(s.CREATED_DATE) 
                         FROM dbo.XX_IMAPS_INT_STATUS s
                        WHERE s.INTERFACE_NAME = @ETIME_INTTERFACE)

SET @row_count = @@ROWCOUNT

IF @row_count = 0
   BEGIN
      -- this should not happen
      -- A database error has occured. Please contact system administrator.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 301,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
      RETURN(1)
   END

-- if the last interface run failed
IF @last_issued_STATUS_CODE = @INTERFACE_STATUS_FAILED
   BEGIN
      -- get data recorded for the last successful control point	
      SELECT @last_issued_CONTROL_PT_ID = CONTROL_PT_ID
        FROM dbo.XX_IMAPS_INT_CONTROL
       WHERE STATUS_RECORD_NUM  = @out_last_issued_STATUS_RECORD_NUM
         AND INTERFACE_NAME     = @ETIME_INTTERFACE
         AND CONTROL_PT_STATUS  = @INTERFACE_STATUS_SUCCESS
         AND CONTROL_RECORD_NUM = (SELECT MAX(c.CONTROL_RECORD_NUM) 
                                     FROM dbo.XX_IMAPS_INT_CONTROL c
                                    WHERE c.STATUS_RECORD_NUM = @out_last_issued_STATUS_RECORD_NUM
                                      AND c.INTERFACE_NAME    = @ETIME_INTTERFACE
                                      AND c.CONTROL_PT_STATUS = @INTERFACE_STATUS_SUCCESS)

      IF @last_issued_CONTROL_PT_ID is NULL -- no control point was ever passed successfully
         SET @out_next_execution_step = 1
      ELSE -- at least one control point was ever passed successfully
         -- determine the next execution step where the interface run resumes
         SELECT @out_next_execution_step = t1.PRESENTATION_ORDER + 1
           FROM dbo.XX_LOOKUP_DETAIL t1,
                dbo.XX_LOOKUP_DOMAIN t2
          WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
            AND t1.APPLICATION_CODE = @last_issued_CONTROL_PT_ID
            AND t2.DOMAIN_CONSTANT  = @LD_CONSTANT_ETIME_CTRL_PT
   END

-- Defect 782 Begin

ELSE IF @last_issued_STATUS_CODE NOT IN (@INTERFACE_STATUS_COMPLETED, @INTERFACE_STATUS_DUPLICATE) -- e.g., BAD_FILE, INITIATED, IN_PROGRESS

-- Defect 782 End

   BEGIN
      -- The interface job shall be halted here. Issue information message and exit.
      SET @out_next_execution_step = @EXEC_STEP_DO_NOTHING

      -- The last interface job has resulted in %1 status. The current %2 interface job cannot be run at this time.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 208,
         @in_placeholder_value1  = @last_issued_STATUS_CODE,
         @in_placeholder_value2  = 'ETIME_R22', -- DR4037
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
      RETURN(0)
   END

-- Special Case: ETIME4 - Execution of Costpoint timesheet preprocessor
IF @out_next_execution_step = @STAGE_FOUR
   BEGIN
      -- The last Costpoint %1 preprocessor job failed. The current %2 interface job cannot be run at this time.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 604,
         @in_placeholder_value1  = 'timesheet',
         @in_placeholder_value2  = 'ETIME_R22', -- DR4037
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
      RETURN(1)
   END

RETURN(0)

go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_R22_GET_POSTERROR_EXEC_STEP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_GET_POSTERROR_EXEC_STEP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_GET_POSTERROR_EXEC_STEP >>>'
go

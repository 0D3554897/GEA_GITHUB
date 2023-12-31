SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_7KEYS_LOG_RUN_DATA_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_7KEYS_LOG_RUN_DATA_SP]
GO


CREATE PROCEDURE dbo.XX_7KEYS_LOG_RUN_DATA_SP
(
@in_STATUS_RECORD_NUM     integer,
@in_FY_CD                 varchar(6),
@in_period_num            smallint,
@in_run_type_id           integer,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(255) = NULL OUTPUT
)
AS

/****************************************************************************************************
Name:       XX_7KEYS_LOG_RUN_DATA_SP
Author:     HVT
Created:    11/15/2005
Purpose:    Upon a successfully completed run of the 7KEYS/PSP interface, record the parameter values
            from the user's command line that serve as report data selection criteria by inserting a
            new row in the table XX_7KEYS_RUN_LOG.
            Called by XX_7KEYS_RUN_INTERFACE_SP.
Parameters: 
Result Set: None
Notes:      Example of call follows.

            EXEC @ret_code = dbo.XX_7KEYS_LOG_RUN_DATA_SP
               @in_STATUS_RECORD_NUM     = @current_STATUS_RECORD_NUM,
               @in_FY_CD                 = @current_run_FY_CD,
               @in_period_num            = @current_run_period_num,
               @in_run_type_id           = @current_run_type_id,
               @out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
               @out_STATUS_DESCRIPTION   = @current_STATUS_DESCRIPTION OUTPUT
****************************************************************************************************/

DECLARE @SP_NAME                 sysname,
        @SQLServer_error_code    integer,
        @IMAPS_error_code        integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname

-- set local constants
SET @SP_NAME = 'XX_7KEYS_LOG_RUN_DATA_SP'

IF @in_STATUS_RECORD_NUM IS NULL OR @in_FY_CD IS NULL OR @in_period_num IS NULL OR @in_run_type_id IS NULL
   BEGIN
      -- Missing required input parameter(s)
      SET @IMAPS_error_code = 100
      GOTO BL_ERROR_HANDLER
   END

PRINT 'Log interface run''s user-supplied parameter values in table XX_7KEYS_RUN_LOG ...'

INSERT INTO dbo.XX_7KEYS_RUN_LOG(STATUS_RECORD_NUM, FY_CD, PD_NO, RUN_TYPE_ID, CREATED_BY)
   VALUES(@in_STATUS_RECORD_NUM, @in_FY_CD, @in_period_num, @in_run_type_id, SUSER_SNAME())

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to %1 %2 failed.
      SET @IMAPS_error_code = 204
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_7KEYS_RUN_LOG'
      GOTO BL_ERROR_HANDLER
   END

RETURN(0)

BL_ERROR_HANDLER:

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_code,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


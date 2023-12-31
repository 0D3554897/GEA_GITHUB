use imapsstg

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_RETRORATE_GET_PROCESSING_PARAMS_SP    Script Date: 01/25/2006 3:20:34 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_RETRORATE_GET_PROCESSING_PARAMS_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_RETRORATE_GET_PROCESSING_PARAMS_SP]
GO


CREATE PROCEDURE dbo.XX_RETRORATE_GET_PROCESSING_PARAMS_SP
(
@out_IMAPS_SCHEMA_OWNER               sysname = NULL OUTPUT,
--@out_IN_USER_NAME                     sysname = NULL OUTPUT, -- CR3728 Remove Shared IDs
--@out_IN_USER_PASSWORD                 sysname = NULL OUTPUT, -- CR3728 Remove Shared IDs
@out_QUERYOUT_SQL					  sysname = NULL OUTPUT, -- CR 3728
@out_IN_TS_PREP_FORMAT_FILENAME       sysname = NULL OUTPUT,
@out_IN_TS_PREP_ERROR_FORMAT_FILENAME sysname = NULL OUTPUT,
@out_IN_TS_PREP_TABLENAME             sysname = NULL OUTPUT,
@out_IN_TS_PREP_ERRORS_TABLENAME      sysname = NULL OUTPUT,
@out_OUT_TS_PREP_FILENAME             sysname = NULL OUTPUT,
@out_OUT_CP_TS_PREP_ERROR_FILENAME    sysname = NULL OUTPUT,
@out_IN_RETRORATE_CP_PROC_ID          sysname = NULL OUTPUT,
@out_IN_RETRORATE_CP_PROC_QUEUE_ID    sysname = NULL OUTPUT
)
AS
BEGIN
/************************************************************************************************
Name:       XX_RETRORATE_GET_PROCESSING_PARAMS_SP
Author:     HVT
Created:    01/05/2006
Purpose:    Get all input parameter data necessary to run the Retro Rate Change interface.
            Each IMAPS interface has a unique set of parameters for execution purposes.
            Not all parameters are "represented" in the form of a XX_PROCESSING_PARAMETERS record.
            That is, some parameters are derived from other specific parameters.
            Called by XX_RETRORATE_READY_CP_RUN_SP, XX_RETRORATE_PROCESS_CP_ERROR_LOG_SP.
Parameters: 
Result Set: None
Notes:

CP600000199 02/08/2008 Reference BP&S Service Request: DR1427
            Enable more users to be notified by e-mail upon specific interface run events.
            Change the size of @param_value to varchar(300).
************************************************************************************************/

DECLARE @SP_NAME                   sysname,
        @LD_CONST_INTERFACE_NAME   char(30),
        @RETRORATE_INTERFACE_NAME  varchar(50),
        @lookup_id                 integer,
        @lookup_app_code           varchar(20),
        @param_name                varchar(50),
        @param_value               varchar(300),
        @rowcount                  integer,
        @ret_code                  integer

-- set local constants
SET @SP_NAME = 'XX_RETRORATE_GET_PROCESSING_PARAMS_SP'
SET @LD_CONST_INTERFACE_NAME = 'LD_INTERFACE_NAME'
SET @RETRORATE_INTERFACE_NAME = 'RETRORATE'

PRINT 'Retrieve necessary parameter data to run the Retro Rate interface ...'

-- first, search for any existing XX_PROCESSING_PARAMETERS record(s)
EXEC @ret_code = dbo.XX_GET_LOOKUP_DATA
   @usr_domain_const	   = @LD_CONST_INTERFACE_NAME,
   @usr_app_code           = @RETRORATE_INTERFACE_NAME,
   @usr_lookup_id	   = NULL,
   @usr_presentation_order = NULL,
   @sys_lookup_id          = @lookup_id OUTPUT,
   @sys_app_code           = @lookup_app_code OUTPUT,
   @sys_lookup_desc   	   = NULL

IF @ret_code <> 0 -- previous stored procedure call fails
   RETURN(1)

SELECT @rowcount = COUNT(1)
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_ID = @lookup_id
   AND INTERFACE_NAME_CD = @lookup_app_code

IF @rowcount = 0
   BEGIN
      -- Missing processing parameter data for CERIS/BluePages interface execution.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 112,
         @in_placeholder_value1  = @RETRORATE_INTERFACE_NAME,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
      RETURN(1)
   END
ELSE -- dbo.XX_PROCESSING_PARAMETERS records exist for a specific interface

   BEGIN
      -- retrieve execution parameter data
      DECLARE cursor_one CURSOR FOR
         SELECT PARAMETER_NAME, PARAMETER_VALUE
           FROM dbo.XX_PROCESSING_PARAMETERS
          WHERE INTERFACE_NAME_ID = @lookup_id
            AND INTERFACE_NAME_CD = @lookup_app_code

      OPEN cursor_one
      FETCH cursor_one INTO @param_name, @param_value

      WHILE (@@fetch_status = 0)
         BEGIN
            IF @param_name = 'IMAPS_SCHEMA_OWNER'
               SET @out_IMAPS_SCHEMA_OWNER = @param_value
           /* ELSE IF @param_name = 'IN_USER_NAME'
               SET @out_IN_USER_NAME = @param_value
            ELSE IF @param_name = 'IN_USER_PASSWORD'
               SET @out_IN_USER_PASSWORD = @param_value  */ -- CR3728 Remove Shared IDs
			ELSE IF @param_name = 'QUERYOUT_SQL'
				SET @out_QUERYOUT_SQL = @param_value  --CR 3728
            ELSE IF @param_name = 'IN_TS_PREP_FORMAT_FILENAME'
               SET @out_IN_TS_PREP_FORMAT_FILENAME = @param_value
            ELSE IF @param_name = 'IN_TS_PREP_ERROR_FORMAT_FILENAME'
               SET @out_IN_TS_PREP_ERROR_FORMAT_FILENAME = @param_value
            ELSE IF @param_name = 'IN_TS_PREP_TABLENAME'
               SET @out_IN_TS_PREP_TABLENAME = @param_value
            ELSE IF @param_name = 'IN_TS_PREP_ERRORS_TABLENAME'
               SET @out_IN_TS_PREP_ERRORS_TABLENAME = @param_value
            ELSE IF @param_name = 'OUT_TS_PREP_FILENAME'
               SET @out_OUT_TS_PREP_FILENAME = @param_value
            ELSE IF @param_name = 'OUT_CP_TS_PREP_ERROR_FILENAME'
               SET @out_OUT_CP_TS_PREP_ERROR_FILENAME = @param_value
            ELSE IF @param_name = 'IN_RETRORATE_CP_PROC_ID'
               SET @out_IN_RETRORATE_CP_PROC_ID = @param_value
            ELSE IF @param_name = 'IN_RETRORATE_CP_PROC_QUEUE_ID'
               SET @out_IN_RETRORATE_CP_PROC_QUEUE_ID = @param_value

            FETCH cursor_one INTO @param_name, @param_value
         END

      CLOSE cursor_one
      DEALLOCATE cursor_one
   END /* @rowcount <> 0 */

RETURN(0)

END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


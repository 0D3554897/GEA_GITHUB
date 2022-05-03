USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_ERROR_MSG_DETAIL]    Script Date: 8/24/2020 2:15:45 PM ******/
DROP PROCEDURE [dbo].[XX_ERROR_MSG_DETAIL]
GO

/****** Object:  StoredProcedure [dbo].[XX_ERROR_MSG_DETAIL]    Script Date: 8/24/2020 2:15:45 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[XX_ERROR_MSG_DETAIL]
(
@in_error_code           integer,
@in_SQLServer_error_code integer      = NULL,
@in_placeholder_value1   sysname      = NULL,
@in_placeholder_value2   sysname      = NULL,
@in_placeholder_value3   sysname      = NULL,
@in_display_requested    integer      = 0,
@in_calling_object_name  sysname      = NULL,

@out_error_type	         varchar(20)  = NULL OUTPUT,
@out_severity_level      integer      = NULL OUTPUT,
@out_msg_text            varchar(275) = NULL OUTPUT,
@out_error_source        varchar(35)  = NULL OUTPUT,
@out_syserror_msg_text   varchar(275) = NULL OUTPUT
)
AS

/*********************************************************************************************************
Name:       XX_ERROR_MSG_DETAIL
Author:     HVT
Created:    07/06/2005
Purpose:    Given a user-supplied error code (either IMAPS's version or SQL Server's system, or both) or
            information code, retrieve its details and, if requested, display the error message(s) to the
            output device of the current SQL Server execution environment. An information code is one that
            describes, for example, a processing status message.

            On receiving output from this sp, the user may further edit and display the final version
            of the error messages from the calling sp.

            If the error message text is one that contains one or more placeholders intended for
            number, string, datetime value, the user is responsible for passing the non-NULL parameter
            values in the correct sequential order (left to right) to replace the placeholders.

            IMPORTANT: The user is also responsible for creating and maintaining the desired error message,
            if one does not currently exist. That is, the user is responsible for maintaining the INSERT
            and UPDATE statements in the build script for the XX_INT_ERROR_MESSAGE records.

Parameters: @in_display_requested = 0 -- do not display any error message at all
            @in_display_requested = 1 -- display both IMAPS error message and SQL Server error message,
                                         if any
            @in_display_requested = 2 -- display only IMAPS error message; do not display SQL Server error
                                         message, if any
Result Set: None

Notes:      Examples of SP calls:

            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code          = 400,
               @in_display_requested   = 1,
               @in_placeholder_value1  = 'XX_IMAPS_ET_FTR_IN_TMP',
               @in_calling_object_name = @SP_NAME,
               @out_msg_text           = @out_Status_Desc OUTPUT

            DECLARE @int_var integer, @datetime_var datetime
            SELECT @int_var = 16
            SELECT @datetime_var = GETDATE()

            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code          = 999,
               @in_placeholder_value1  = 'MY_FILE.TXT',
               @in_placeholder_value2  = @int_var,
               @in_placeholder_value3  = @datetime_var,
               @in_display_requested   = 1,
               @in_calling_object_name = 'XX_STORED_PROCEDURE_NAME',
               @out_error_type	       = NULL,
               @out_severity_level     = NULL,
               @out_msg_text           = NULL,
               @out_error_source       = NULL

            DECLARE @param_value_2 sysname, @param_value_3 sysname
            SELECT @param_value_2 = CAST(@int_var AS varchar(3))
            SELECT @param_value_3 = CONVERT(char(10), @datetime_var, 120)

            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code          = 999,
               @in_placeholder_value1  = 'MY_FILE.TXT',
               @in_placeholder_value2  = @param_value_2,
               @in_placeholder_value3  = @param_value_3,
               @in_display_requested   = 1,
               @in_calling_object_name = 'XX_STORED_PROCEDURE_NAME',
               @out_error_type         = NULL,
               @out_severity_level     = NULL,
               @out_msg_text           = NULL,
               @out_error_source       = NULL

            -- This example also gets the SQL Server system error message text back for additional editing
            SELECT @lv_error = @@ERROR
            IF @lv_error <> 0
               EXEC dbo.XX_ERROR_MSG_DETAIL
                  @in_error_code           = 204,
                  @in_SQLServer_error_code = @lv_error,
                  @in_display_requested    = 1,
                  @in_placeholder_value1   = 'insert',
                  @in_placeholder_value2   = 'a XX_IMAPS_INT_STATUS record',
                  @in_calling_object_name  = @SP_NAME,
                  @out_msg_text            = @lv_status_desc OUTPUT,
                  @out_syserror_msg_text   = @lv_syserror_msg_text OUTPUT

            -- This example covers SQL Server system error, no placeholder values are provided
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = @ret_code, -- 1, the error status conventionally returned by the called SP
               @in_SQLServer_error_code = @SQLServer_error_code,
               @in_display_requested    = 1, -- display both IMAPS error message and SQL Server error message, if any
               @in_calling_object_name  = @SP_NAME,
               @out_msg_text            = @current_STATUS_DESCRIPTION OUTPUT,
               @out_syserror_msg_text   = @SQLServer_error_msg_text OUTPUT

            DECLARE @in_info_code integer
            SET @in_info_code = 503
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code         = @in_info_code,
               @in_placeholder_value1 = 'eTime',
               @out_msg_text          = @lv_status_desc OUTPUT

Defect 982  05/11/2006 Fix the problem of failure to capture Microsoft SQL Server error code.

11/27/2019  Fix Microsoft SQL Server (non-IMAPS) error event.
**********************************************************************************************************/

DECLARE @SP_NAME               sysname,
        @lv_row_count          integer,
        @lv_error_type_id      integer,
        @PLACEHOLDER_MAXIMUM   integer,
        @plholder_count        tinyint,
        @plholder_param_values tinyint,
        @lcv1                  integer,    -- loop counter variable
        @lcv2                  integer,    -- loop counter variable
        @search_str            varchar(2),
        @actual_placeholder    char(2),
        @error_type            integer,
        @SQLServer_msg_text    varchar(275),
        @working_msg_text      varchar(275),
        @warning_msg_text      varchar(275),
        @ret_code              integer

-- Initialize local constants
SELECT @SP_NAME = 'XX_ERROR_MSG_DETAIL'
SELECT @PLACEHOLDER_MAXIMUM = 3

PRINT '******************** ' + @SP_NAME +  '******************** '
-- Validate user input
IF @in_error_code IS NULL
   BEGIN
      EXEC dbo.XX_GET_ERROR_MSG_TEXT
         @in_ERROR_CODE = 100,
         @in_calling_object_name = @SP_NAME,
         @out_display_msg_text = @working_msg_text OUTPUT
      PRINT @working_msg_text
      RETURN(1)
   END
ELSE
   IF @in_error_code IN (101, 102, 103, 109, 110, 111)
      BEGIN
         EXEC dbo.XX_GET_ERROR_MSG_TEXT
            @in_ERROR_CODE = 111,
            @in_calling_object_name = @SP_NAME,
            @out_display_msg_text = @working_msg_text OUTPUT
         PRINT @working_msg_text
         RETURN(1)
      END

IF (@in_display_requested IS NOT NULL and @in_display_requested = 1 and @in_calling_object_name IS NULL) OR
   (@in_display_requested IS NULL and @in_calling_object_name IS NOT NULL)
   BEGIN
      EXEC dbo.XX_GET_ERROR_MSG_TEXT
         @in_ERROR_CODE = 100,
         @in_calling_object_name = @SP_NAME,
         @out_display_msg_text = @working_msg_text OUTPUT
      PRINT @working_msg_text
      RETURN(1)
   END

-- 11/27/2019 Begin
-- Two cases: Microsoft SQL Server error event (rare, fatal) vs. IMAPS error event (frequent, non-faltal)
IF @in_error_code = 1 -- Execution of the calling SP encounters an error and receives an execution error status
   -- The calling SP issues a SP call for a Microsoft SQL Server error event, not an IMAPS error event.
   GOTO BL_BUILD_FINAL_MSG_M -- skip the entire placeholder processing
ELSE
   BEGIN
      -- Retrieve the user-specified IMAPS error
      SELECT @lv_error_type_id   = ERROR_TYPE,
             @out_severity_level = ERROR_SEVERITY,
             @out_msg_text       = ERROR_MESSAGE,
             @out_error_source   = ERROR_SOURCE
        FROM dbo.XX_INT_ERROR_MESSAGE
       WHERE ERROR_CODE = @in_error_code

      SELECT @lv_row_count = @@ROWCOUNT

      IF @lv_row_count = 0
         BEGIN
            EXEC dbo.XX_GET_ERROR_MSG_TEXT
               @in_ERROR_CODE = 200,
               @in_calling_object_name = @SP_NAME,
               @out_display_msg_text = @working_msg_text OUTPUT
            PRINT REPLACE(@working_msg_text, '%1', 'The error code')
            RETURN (1)
         END
   END
-- 11/27/2019 End

-- Initialize local variables
SET @plholder_count = 0
SET @plholder_param_values = 0
SET @lcv1 = 1
SET @error_type = NULL

-- Local temporary table to hold the actual placeholders assigned by the user
CREATE TABLE #PlaceholderTempTable (PLACEHOLDER_ENCOUNTER char(2))

-- Validate user-supplied values for placeholders

-- This loop determines how many placeholders currently exist in the error message text
WHILE @lcv1 <= DATALENGTH(@out_msg_text)
   BEGIN
      IF SUBSTRING(@out_msg_text, @lcv1, 1) = '%'
         BEGIN
            SET @lcv2 = 1 -- initialize loop counter variable
            WHILE @lcv2 <= @PLACEHOLDER_MAXIMUM + 1
               BEGIN
                  IF CHARINDEX('%' + CAST(@lcv2 AS char(1)), @out_msg_text, @lcv1) > 0
                     BEGIN
                        -- populate local temporary table
                        INSERT INTO #PlaceholderTempTable VALUES('%' + CAST(@lcv2 AS char(1)))
                        SELECT @plholder_count = @plholder_count + 1
                        BREAK -- exit this inner WHILE loop
                     END
                  SET @lcv2 = @lcv2 + 1
               END
         END
      SET @lcv1 = @lcv1 + 1
   END

-- Compare the number of non-NULL input parameters containing placeholder values passed by the user to this sp
-- to the total number of possible placeholders found in the error message text.

IF @plholder_count = 0
   BEGIN
      IF @in_placeholder_value1 IS NOT NULL OR
         @in_placeholder_value2 IS NOT NULL OR
         @in_placeholder_value3 IS NOT NULL
         BEGIN
            -- Issue the warning: Placeholder replacement values are supplied for an error or information message
            -- that does not contain placeholders.
            EXEC @ret_code = dbo.XX_GET_ERROR_MSG_TEXT
               @in_ERROR_CODE          = 109,
               @in_calling_object_name = @SP_NAME,
               @out_display_msg_text   = @warning_msg_text OUTPUT
            PRINT @warning_msg_text
         END

      GOTO BL_BUILD_FINAL_MSG_I -- skip the entire placeholder processing
   END
ELSE
   BEGIN
      IF @plholder_count > @PLACEHOLDER_MAXIMUM
         BEGIN
            -- Please limit the number of placeholders in the error message text to three (3).
            EXEC dbo.XX_GET_ERROR_MSG_TEXT
               @in_ERROR_CODE = 205,
               @in_calling_object_name = @SP_NAME,
               @out_display_msg_text = @working_msg_text OUTPUT

            SELECT @working_msg_text = REPLACE(@working_msg_text, '%1', 'placeholders in the error message text')
            SELECT @working_msg_text = REPLACE(@working_msg_text, '%2', 'three (3)')
            PRINT @working_msg_text
            RETURN (1)
         END
      ELSE
         BEGIN
            IF @in_placeholder_value1 IS NOT NULL
               SELECT @plholder_param_values = @plholder_param_values + 1
            IF @in_placeholder_value2 IS NOT NULL
               SELECT @plholder_param_values = @plholder_param_values + 1
            IF @in_placeholder_value3 IS NOT NULL
               SELECT @plholder_param_values = @plholder_param_values + 1
         END

      -- Issue the WARNING: The number of user-specified placeholder values passed does not match the number
      -- of possible placeholders found in the error message text.
      IF @plholder_param_values <> @plholder_count
         BEGIN
            EXEC dbo.XX_GET_ERROR_MSG_TEXT
               @in_ERROR_CODE = 110,
               @in_calling_object_name = @SP_NAME,
               @out_display_msg_text = @warning_msg_text OUTPUT
            PRINT @warning_msg_text
         END
   END

SET @lcv1 = 1 -- reinitialize loop counter variable for another loop use

-- Ensure that the order of the placeholders in the error message text is strictly sequential, left to right
WHILE @lcv1 <= @plholder_count
   BEGIN
      SET @search_str = '%' + CAST(@lcv1 AS char(1))

      SELECT @lv_row_count = COUNT(1)
        FROM #PlaceholderTempTable
       WHERE PLACEHOLDER_ENCOUNTER = @search_str

      IF @lv_row_count = 0      -- error: gap in placeholder sequence
         BEGIN
            SET @error_type = 1
            BREAK
         END
      ELSE IF @lv_row_count > 1 -- error: the placeholder is repeated
         BEGIN
            SET @error_type = 2
            BREAK
         END

      SET @lcv1 = @lcv1 + 1
   END

IF @error_type IS NOT NULL -- error was found
   BEGIN
      IF @error_type = 1
         BEGIN
            -- The placeholders in the error message text are out of sequential order.
            EXEC dbo.XX_GET_ERROR_MSG_TEXT
               @in_ERROR_CODE = 102,
               @in_calling_object_name = @SP_NAME,
               @out_display_msg_text = @working_msg_text OUTPUT
            PRINT @working_msg_text
         END
      ELSE IF @error_type = 2
         BEGIN
            -- Repeated placeholders in the error message text.
            EXEC dbo.XX_GET_ERROR_MSG_TEXT
               @in_ERROR_CODE = 103,
               @in_calling_object_name = @SP_NAME,
               @out_display_msg_text = @working_msg_text OUTPUT
            PRINT @working_msg_text
         END

      -- clean up before exiting
      DROP TABLE #PlaceholderTempTable
      RETURN (1)
   END

-- clean up
DROP TABLE #PlaceholderTempTable

-- Assemble the error message using substitution and expansion

SELECT @lcv1 = 1 -- reinitialize loop counter variable for another loop use

-- Replace the placeholders with user-supplied values
WHILE @lcv1 <= @plholder_count
   BEGIN
      IF @lcv1 = 1 
         IF @in_placeholder_value1 IS NOT NULL
            SELECT @out_msg_text = REPLACE(@out_msg_text, '%1', @in_placeholder_value1)
         ELSE
            SELECT @out_msg_text = REPLACE(@out_msg_text, '%1', '')
      ELSE IF @lcv1 = 2
         IF @in_placeholder_value2 IS NOT NULL
            SELECT @out_msg_text = REPLACE(@out_msg_text, '%2', @in_placeholder_value2)
         ELSE
            SELECT @out_msg_text = REPLACE(@out_msg_text, '%2', '')
      ELSE IF @lcv1 = 3
         IF @in_placeholder_value3 IS NOT NULL
            SELECT @out_msg_text = REPLACE(@out_msg_text, '%3', @in_placeholder_value3)
         ELSE
            SELECT @out_msg_text = REPLACE(@out_msg_text, '%3', '')

      SELECT @lcv1 = @lcv1 + 1
   END /* WHILE @lcv1 <= @plholder_count */

BL_BUILD_FINAL_MSG_I: -- 11/27/2019

-- Look up error type from reference
EXEC dbo.XX_GET_LOOKUP_DATA
   @usr_domain_const	   = NULL,
   @usr_app_code           = NULL,
   @usr_lookup_id	   = @lv_error_type_id,
   @usr_presentation_order = NULL,
   @sys_lookup_id          = NULL,
   @sys_app_code           = @out_error_type OUTPUT,
   @sys_lookup_desc   	   = NULL

SELECT @out_msg_text = @out_error_type + ': ' + @out_msg_text

-- Finalize the IMAPS error message for output
IF @in_display_requested IS NOT NULL and @in_display_requested = 1
   PRINT @out_msg_text + ' [' + @in_calling_object_name + ']'

-- Defect 982 Begin

BL_BUILD_FINAL_MSG_M: -- 11/27/2019

-- Prepare the SQL Server system error message for output
IF @in_SQLServer_error_code IS NOT NULL
   BEGIN
      IF @in_SQLServer_error_code = 0 -- no use looking up SQL Server system message
-- 11/27/2019 Begin
         BEGIN
            IF @in_display_requested = 1
               PRINT 'WARNING: Microsoft SQL Server error number could not be captured, is invalid or does not exist.' + ' [' + @SP_NAME + ']'
         END
-- 11/27/2019 End
      ELSE
         BEGIN
            EXEC @ret_code = dbo.XX_GET_SQLSERVER_SYSMSG
               @in_SQLServer_error_num = @in_SQLServer_error_code,
               @out_SQLServer_msg_text = @SQLServer_msg_text OUTPUT

-- 11/27/2019 Begin
            IF @ret_code = 0
               BEGIN
                  IF @SQLServer_msg_text IS NOT NULL
                     BEGIN
                        -- Return the SQL Server system error message text such that the user may further edit it as desired
                        SET @out_syserror_msg_text = @SQLServer_msg_text

                        IF @in_display_requested = 1
                           PRINT @SQLServer_msg_text
                     END
               END
            ELSE
               BEGIN
                  PRINT '[BL_BUILD_FINAL_MSG_M] Execution of XX_GET_SQLSERVER_SYSMSG failed.'
               END
-- 11/27/2019 End
         END
   END

-- Defect 982 End

PRINT '**************** END ' + @SP_NAME +  '******************** '

RETURN (0)

GO



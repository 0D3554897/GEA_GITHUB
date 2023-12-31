SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_7KEYS_GET_PROCESSING_PARAMS_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   drop procedure [dbo].[XX_7KEYS_GET_PROCESSING_PARAMS_SP]
GO


CREATE PROCEDURE dbo.XX_7KEYS_GET_PROCESSING_PARAMS_SP
(
@out_IMAPS_SCHEMA_OWNER          sysname      = NULL OUTPUT,
@out_IMAPS_DATABASE_NAME         sysname      = NULL OUTPUT,
/*@out_IN_USER_NAME                sysname      = NULL OUTPUT,
@out_IN_USER_PASSWORD            sysname      = NULL OUTPUT,   CR3548  3/29/2011*/
@out_IN_SOURCE_SYSOWNER          sysname      = NULL OUTPUT,
@out_OUT_DESTINATION_SYSOWNER    varchar(300) = NULL OUTPUT,
@out_OUT_DETAIL_TABLE_NAME       sysname      = NULL OUTPUT,
@out_OUT_HEADER_TABLE_NAME       sysname      = NULL OUTPUT,
@out_OUT_DETAIL_FORMAT_FILENAME  sysname      = NULL OUTPUT,
@out_OUT_HEADER_FORMAT_FILENAME  sysname      = NULL OUTPUT,
@out_OUT_DETAIL_FILENAME         sysname      = NULL OUTPUT,
@out_OUT_HEADER_FILENAME         sysname      = NULL OUTPUT,
@out_OUT_FINAL_FILENAME_PREFIX   sysname      = NULL OUTPUT,
@out_OUT_ARCHIVAL_DIRECTORY      sysname      = NULL OUTPUT,
@out_OUT_FTP_SERVER              sysname      = NULL OUTPUT,
@out_OUT_FTP_RECEIVING_DIRECTORY sysname      = NULL OUTPUT,
-- CP600000288_Begin
@out_COMPANY_ID                  varchar(10)  = NULL OUTPUT
-- CP600000288_End
)
AS

/*************************************************************************************************
Name:       XX_7KEYS_GET_PROCESSING_PARAMS_SP
Author:     HVT
Created:    11/07/2005
Purpose:    Get all input parameter data necessary to run the eTime interface.
            Each IMAPS interface has a unique set of parameters for execution purposes.
            Not all parameters are "represented" in the form of a XX_PROCESSING_PARAMETERS record.
            That is, some parameters are derived from other specific parameters.
            Called by XX_7KEYS_RUN_INTERFACE_SP, XX_7KEYS_BUILD_OUTPUT_FILE_SP.

            !!IMPORTANT!!: Must set/reset local variable @PARAM_TOTAL_COUNT equal to the total
            number of this SP's output parameters defined (above) specifically for 7KEYS/PSP
            interface processing if this SP'sparameter list changes.

Parameters: 
Result Set: None
Notes:

02/09/2006: Add code to support FTP function.

Defect 631: 03/27/2006 - Improve error handling in the event of missing processing parameter data.

CP600000199 02/08/2008 Reference BP&S Service Request DR1427
            Enable more users to be notified by e-mail upon specific interface run events.
            Change the size of @out_OUT_DESTINATION_SYSOWNER and @param_value to varchar(300).

CP600000288 04/01/2008 Reference BP&S Service Request CR1543
            Costpoint multi-company fix.
from CP600001172 to CP600001246
*************************************************************************************************/

DECLARE @SP_NAME                  sysname,
        @LD_CONST_INTERFACE_NAME  char(30),
        @7KEYS_INTERFACE_NAME     varchar(50),
        @PARAM_TOTAL_COUNT        smallint,
        @lookup_id                integer,
        @lookup_app_code          varchar(20),
        @param_name               varchar(50),
        @param_value              varchar(300),
        @row_count                integer,
        @ret_code                 integer

-- set local constants
SET @SP_NAME = 'XX_7KEYS_GET_PROCESSING_PARAMS_SP'
SET @LD_CONST_INTERFACE_NAME = 'LD_INTERFACE_NAME'
SET @7KEYS_INTERFACE_NAME = '7KEYS/PSP'

-- @PARAM_TOTAL_COUNT is set equal to the total number of SP's output parameters defined for interface-specific processing
-- CP600000288_Begin
SET @PARAM_TOTAL_COUNT = 15 
-- number changed from 17  because login and password parameters were deleted by CR3548 3/29/11
-- CP600000288_End

-- first, search for any existing XX_PROCESSING_PARAMETERS record(s)
EXEC @ret_code = dbo.XX_GET_LOOKUP_DATA
   @usr_domain_const	   = @LD_CONST_INTERFACE_NAME,
   @usr_app_code           = @7KEYS_INTERFACE_NAME,
   @usr_lookup_id          = NULL,
   @usr_presentation_order = NULL,
   @sys_lookup_id          = @lookup_id OUTPUT,
   @sys_app_code           = @lookup_app_code OUTPUT,
   @sys_lookup_desc   	   = NULL

IF @ret_code <> 0 -- the called stored procedure returns an error status
   RETURN(1)

SELECT @row_count = COUNT(1)
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_ID = @lookup_id
   AND INTERFACE_NAME_CD = @lookup_app_code

IF @row_count = 0 OR (@row_count != 0 AND @row_count != @PARAM_TOTAL_COUNT)
   BEGIN
      -- Missing processing parameter data for 7KEYS/PSP interface execution.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 112,
         @in_placeholder_value1  = @7KEYS_INTERFACE_NAME,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
      RETURN(1)
   END
ELSE -- dbo.XX_PROCESSING_PARAMETERS records exist for a specific interface

   BEGIN
      -- retrieve interface execution parameter data
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
            ELSE IF @param_name = 'IMAPS_DATABASE_NAME'
               SET @out_IMAPS_DATABASE_NAME = @param_value
 /*         ELSE IF @param_name = 'IN_USER_NAME'
               SET @out_IN_USER_NAME = @param_value
            ELSE IF @param_name = 'IN_USER_PASSWORD'
               SET @out_IN_USER_PASSWORD = @param_value CR3548 3/29/2011*/
            ELSE IF @param_name = 'IN_SOURCE_SYSOWNER'
               SET @out_IN_SOURCE_SYSOWNER = @param_value
            ELSE IF @param_name = 'OUT_DESTINATION_SYSOWNER'
               SET @out_OUT_DESTINATION_SYSOWNER = @param_value
            ELSE IF @param_name = 'OUT_DETAIL_TABLE_NAME'
               SET @out_OUT_DETAIL_TABLE_NAME = @param_value
            ELSE IF @param_name = 'OUT_HEADER_TABLE_NAME'
               SET @out_OUT_HEADER_TABLE_NAME = @param_value
            ELSE IF @param_name = 'OUT_DETAIL_FORMAT_FILENAME'
               SET @out_OUT_DETAIL_FORMAT_FILENAME = @param_value
            ELSE IF @param_name = 'OUT_HEADER_FORMAT_FILENAME'
               SET @out_OUT_HEADER_FORMAT_FILENAME = @param_value
            ELSE IF @param_name = 'OUT_DETAIL_FILENAME'
               SET @out_OUT_DETAIL_FILENAME = @param_value
            ELSE IF @param_name = 'OUT_HEADER_FILENAME'
               SET @out_OUT_HEADER_FILENAME = @param_value
            ELSE IF @param_name = 'OUT_FINAL_FILENAME_PREFIX'
               SET @out_OUT_FINAL_FILENAME_PREFIX = @param_value
            ELSE IF @param_name = 'OUT_ARCHIVAL_DIRECTORY'
               SET @out_OUT_ARCHIVAL_DIRECTORY = @param_value
            ELSE IF @param_name = 'OUT_FTP_SERVER'
               SET @out_OUT_FTP_SERVER = @param_value
            ELSE IF @param_name = 'OUT_FTP_RECEIVING_DIRECTORY'
               SET @out_OUT_FTP_RECEIVING_DIRECTORY = @param_value
-- CP600000288_Begin
            ELSE IF @param_name = 'COMPANY_ID'
               SET @out_COMPANY_ID = @param_value
-- CP600000288_End

            FETCH cursor_one INTO @param_name, @param_value
         END

      CLOSE cursor_one
      DEALLOCATE cursor_one

   END /* @row_count <> 0 */

RETURN(0)

GRANT EXECUTE ON dbo.XX_7KEYS_GET_PROCESSING_PARAMS_SP TO PUBLIC

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


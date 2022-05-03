USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE ID = object_id(N'[dbo].[XX_R22_CERIS_GET_PROCESSING_PARAMS_SP]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[XX_R22_CERIS_GET_PROCESSING_PARAMS_SP]
GO

CREATE PROCEDURE [dbo].[XX_R22_CERIS_GET_PROCESSING_PARAMS_SP]
(
@out_IN_SOURCE_SYSOWNER      sysname      = NULL OUTPUT,
@out_IN_FINANCE_ANALYST      sysname      = NULL OUTPUT,
@out_IN_DESTINATION_SYSOWNER varchar(300) = NULL OUTPUT,
@out_IMAPS_SCHEMA_OWNER      sysname      = NULL OUTPUT
/*@out_IN_USER_NAME            sysname      = NULL OUTPUT
,@out_IN_USER_PASSWORD        sysname      = NULL OUTPUT   CR3856 */
)
AS

/************************************************************************************************
Name:       XX_R22_CERIS_GET_PROCESSING_PARAMS_SP
Author:     V Veera
Created:    05/18/2008 
Purpose:    Get all input parameter data necessary to run the eTime interface.
            Each IMAPS interface has a unique set of parameters for execution purposes.
            Not all parameters are "represented" in the form of a XX_PROCESSING_PARAMETERS record.
            That is, some parameters are derived from other specific parameters.
            Called by XX_R22_CERIS_RUN_INTERFACE.
Parameters: 
Result Set: None
Notes:

            Enable more users to be notified by e-mail upon specific interface run events. Change
            the size of @out_IN_DESTINATION_SYSOWNER and @param_value to varchar(300).
 06/20/2011  CR3856 removal of application ids T Perova
************************************************************************************************/

DECLARE @SP_NAME                   sysname,
        @LD_CONST_INTERFACE_NAME   char(30),
        @CERIS_INTERFACE_NAME      varchar(50),
        @lookup_id                 integer,
        @lookup_app_code           varchar(20),
        @lv_status_desc            varchar(255),
        @param_name                varchar(50),
        @param_value               varchar(300),
        @lv_error                  integer,
        @rowcount                  integer,
        @ret_code                  integer

-- set local constants
SET @SP_NAME = 'XX_R22_CERIS_GET_PROCESSING_PARAMS_SP'
SET @LD_CONST_INTERFACE_NAME = 'LD_INTERFACE_NAME'
SET @CERIS_INTERFACE_NAME = 'CERIS_R22'

PRINT 'Retrieve necessary parameter data to run the CERIS interface ...'

-- first, search for any existing XX_PROCESSING_PARAMETERS record(s)
EXEC @ret_code = dbo.XX_GET_LOOKUP_DATA
   @usr_domain_const	   = @LD_CONST_INTERFACE_NAME,
   @usr_app_code           = @CERIS_INTERFACE_NAME,
   @usr_lookup_id          = NULL,
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
      -- Missing processing parameter data for CERIS interface execution.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 112,
         @in_placeholder_value1  = @CERIS_INTERFACE_NAME,
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
            IF @param_name = 'IN_SOURCE_SYSOWNER'
               SET @out_IN_SOURCE_SYSOWNER = @param_value
            ELSE IF @param_name = 'IN_FINANCE_ANALYST'
               SET @out_IN_FINANCE_ANALYST = @param_value
            ELSE IF @param_name = 'IN_DESTINATION_SYSOWNER'
               SET @out_IN_DESTINATION_SYSOWNER = @param_value
            ELSE IF @param_name = 'IMAPS_SCHEMA_OWNER'
               SET @out_IMAPS_SCHEMA_OWNER = @param_value
         /*   ELSE IF @param_name = 'IN_USER_NAME'
               SET @out_IN_USER_NAME = @param_value
            ELSE IF @param_name = 'IN_USER_PASSWORD'
               SET @out_IN_USER_PASSWORD = @param_value      CR3856 */

            FETCH cursor_one INTO @param_name, @param_value
         END

      CLOSE cursor_one
      DEALLOCATE cursor_one
   END /* @rowcount <> 0 */

RETURN(0)







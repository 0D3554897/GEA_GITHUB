SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_CERIS_GET_PROCESSING_PARAMS_SP    Script Date: 03/08/2006 10:59:29 AM ******/

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_GET_PROCESSING_PARAMS_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_CERIS_GET_PROCESSING_PARAMS_SP]
GO



CREATE PROCEDURE dbo.XX_CERIS_GET_PROCESSING_PARAMS_SP
(
@out_IN_SOURCE_SYSOWNER      sysname = NULL OUTPUT,
@out_IN_FINANCE_ANALYST      sysname = NULL OUTPUT,
@out_IN_DESTINATION_SYSOWNER sysname = NULL OUTPUT,
@out_IMAPS_SCHEMA_OWNER      sysname = NULL OUTPUT
-- CR3735_Begin
-- @out_IN_USER_NAME            sysname = NULL OUTPUT,
-- @out_IN_USER_PASSWORD        sysname = NULL OUTPUT
-- CR3735_End
)
AS

/************************************************************************************************
Name:       XX_CERIS_GET_PROCESSING_PARAMS_SP
Author:     HVT
Created:    10/06/2005
Purpose:    Get all input parameter data necessary to run the eTime interface.
            Each IMAPS interface has a unique set of parameters for execution purposes.
            Not all parameters are "represented" in the form of a XX_PROCESSING_PARAMETERS record.
            That is, some parameters are derived from other specific parameters.
            Called by XX_CERIS_RUN_INTERFACE.
Parameters: 
Result Set: None
Notes:

CP600001216 05/13/2011 (FSST Service Request No. CR3735)
            Eliminate use of shared ID (e.g., in bcp call)
CR9295 - gea - 4/13/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
************************************************************************************************/


 
PRINT '' -- *~^ CR9295
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        BEGIN XX_CERIS_GET_PROCESSING_PARAMS_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' -- *~^ CR9295
 
DECLARE @SP_NAME                   sysname,

        @LD_CONST_INTERFACE_NAME   char(30),
        @CERIS_INTERFACE_NAME      varchar(50),
        @lookup_id                 integer,
        @lookup_app_code           varchar(20),
        @lv_status_desc            varchar(255),
        @param_name                varchar(50),
        @param_value               sysname,
        @lv_error                  integer,
        @rowcount                  integer,
        @ret_code                  integer

-- set local constants
SET @SP_NAME = 'XX_CERIS_GET_PROCESSING_PARAMS_SP'
SET @LD_CONST_INTERFACE_NAME = 'LD_INTERFACE_NAME'
SET @CERIS_INTERFACE_NAME = 'CERIS'

PRINT 'Retrieve necessary parameter data to run the CERIS interface ...'

-- first, search for any existing XX_PROCESSING_PARAMETERS record(s)
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 77 : XX_CERIS_GET_PROCESSING_PARAMS_SP.sql '  --CR9295
 
EXEC @ret_code = dbo.XX_GET_LOOKUP_DATA
   @usr_domain_const	   = @LD_CONST_INTERFACE_NAME,
   @usr_app_code           = @CERIS_INTERFACE_NAME,
   @usr_lookup_id	   = NULL,
   @usr_presentation_order = NULL,
   @sys_lookup_id          = @lookup_id OUTPUT,
   @sys_app_code           = @lookup_app_code OUTPUT,
   @sys_lookup_desc   	   = NULL

IF @ret_code <> 0 -- previous stored procedure call fails
   RETURN(1)

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 94 : XX_CERIS_GET_PROCESSING_PARAMS_SP.sql '  --CR9295
 
SELECT @rowcount = COUNT(1)
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_ID = @lookup_id
   AND INTERFACE_NAME_CD = @lookup_app_code

IF @rowcount = 0
   BEGIN
      -- Missing processing parameter data for CERIS/BluePages interface execution.
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 105 : XX_CERIS_GET_PROCESSING_PARAMS_SP.sql '  --CR9295
 
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
-- CR3735_Begin
/*
            ELSE IF @param_name = 'IN_USER_NAME'
               SET @out_IN_USER_NAME = @param_value
            ELSE IF @param_name = 'IN_USER_PASSWORD'

               SET @out_IN_USER_PASSWORD = @param_value
*/

-- CR3735_End

            FETCH cursor_one INTO @param_name, @param_value
         END

      CLOSE cursor_one
      DEALLOCATE cursor_one
   END /* @rowcount <> 0 */



 
PRINT '' -- *~^ CR9295
PRINT '*~^*************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF  XX_CERIS_GET_PROCESSING_PARAMS_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' -- *~^ CR9295
 
RETURN(0)

GRANT EXECUTE ON dbo.XX_CERIS_GET_PROCESSING_PARAMS_SP TO PUBLIC



GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


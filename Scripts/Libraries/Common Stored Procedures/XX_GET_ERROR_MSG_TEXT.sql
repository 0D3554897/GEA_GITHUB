SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_GET_ERROR_MSG_TEXT]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_GET_ERROR_MSG_TEXT]
GO



CREATE PROCEDURE dbo.XX_GET_ERROR_MSG_TEXT
(
@in_ERROR_CODE           integer,
@in_calling_object_name  sysname      = NULL,
@out_display_msg_text    varchar(300) = NULL OUTPUT
)
AS

/************************************************************************************************
Name:       XX_GET_ERROR_MSG_TEXT
Author:     HVT
Created:    07/21/2005
Purpose:    Construct and return an error message text string.
            Called by XX_ERROR_MSG_DETAIL.
Parameters:
Result Set: None
Notes:      Example of call
               DECLARE @lv_print_str varchar(300)
               EXEC dbo.XX_GET_ERROR_MSG_TEXT
                  @in_ERROR_CODE = 100,
                  @in_calling_object_name = 'XX_STORED_PROCEDURE_NAME',
                  @out_display_msg_text = @lv_print_str OUTPUT
************************************************************************************************/

DECLARE @lv_error_type_id    integer,
        @lv_error_type_desc  varchar(20),
        @lv_error_source     varchar(35)

select @lv_error_type_id = ERROR_TYPE,
       @out_display_msg_text = ERROR_MESSAGE,
       @lv_error_source  = ERROR_SOURCE
  from dbo.XX_INT_ERROR_MESSAGE
 where ERROR_CODE = @in_ERROR_CODE

-- look up error type from reference
EXEC dbo.XX_GET_LOOKUP_DATA
   @usr_domain_const       = NULL,
   @usr_app_code           = NULL,
   @usr_lookup_id	   = @lv_error_type_id,
   @usr_presentation_order = NULL,
   @sys_lookup_id          = NULL,
   @sys_app_code           = @lv_error_type_desc OUTPUT,
   @sys_lookup_desc   	   = NULL

SELECT @out_display_msg_text = @lv_error_type_desc + ': ' + @out_display_msg_text -- + ' [' + @lv_error_source + ']'

IF @in_calling_object_name IS NOT NULL
   SELECT @out_display_msg_text = @out_display_msg_text + ' [' + @in_calling_object_name + ']'

--GRANT EXECUTE ON IMAPSDev.dbo.XX_GET_ERROR_MSG_TEXT TO PUBLIC


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_UPDATE_INT_STATUS_RECORD]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_UPDATE_INT_STATUS_RECORD]
GO


CREATE PROCEDURE dbo.XX_UPDATE_INT_STATUS_RECORD
(
@in_STATUS_RECORD_NUM  integer,
@in_STATUS_CODE        varchar(20),
@in_STATUS_DESCRIPTION varchar(255) = NULL
)
AS

/************************************************************************************************
Name:       XX_UPDATE_INT_STATUS_RECORD
Author:     HVT
Created:    08/01/2005
Purpose:    Update a record in the table XX_IMAPS_INT_STATUS for each interface cycle.
            Each interface cycle has exactly one XX_IMAPS_INT_STATUS record.
            Called by XX_RUN_ETIME_INTERFACE.
Parameters: None
Result Set: None
Notes:      Call example
               EXEC dbo.XX_UPDATE_INT_STATUS_RECORD
                  @in_STATUS_RECORD_NUM = @lv_STATUS_RECORD_NUM,
                  @in_STATUS_CODE = @INTERFACE_STATUS_SUCCESS,
                  @in_STATUS_DESCRIPTION = @lv_STATUS_DESCRIPTION
*************************************************************************************************/

DECLARE @SP_NAME       sysname,
        @lv_error      integer,
        @lv_rowcount   integer

-- set local constants
SET @SP_NAME = 'XX_UPDATE_INT_STATUS_RECORD'

-- validate the stored procedure call command for required input parameters
IF @in_STATUS_RECORD_NUM IS NULL OR @in_STATUS_CODE IS NULL
   BEGIN
      -- Missing required input parameter(s)
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 100,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
      RETURN(1)
   END

-- begin TP 08/29 
IF @in_STATUS_DESCRIPTION is NULL 
BEGIN
   EXEC dbo.XX_GET_LOOKUP_DATA
	@usr_app_code     = @in_STATUS_CODE,
	@sys_lookup_desc   = @in_STATUS_DESCRIPTION OUTPUT

END
--end



UPDATE dbo.XX_IMAPS_INT_STATUS
   SET STATUS_CODE = @in_STATUS_CODE,
       STATUS_DESCRIPTION = @in_STATUS_DESCRIPTION,
       MODIFIED_BY = SUSER_SNAME(),
       MODIFIED_DATE = GETDATE()
 WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

SELECT @lv_error = @@ERROR, @lv_rowcount = @@ROWCOUNT

IF @lv_error <> 0 -- failure
   BEGIN
      -- Attempt to update a XX_IMAPS_INT_STATUS record failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = 204,
         @in_SQLServer_error_code = @lv_error,
         @in_display_requested    = 1,
         @in_placeholder_value1   = 'update',
         @in_placeholder_value2   = 'a XX_IMAPS_INT_STATUS record',
         @in_calling_object_name  = @SP_NAME
      RETURN(1)
   END

RETURN(0) -- success
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


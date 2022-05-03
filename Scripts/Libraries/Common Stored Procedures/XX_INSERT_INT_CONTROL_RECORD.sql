USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_INSERT_INT_CONTROL_RECORD]    Script Date: 8/24/2020 9:52:43 AM ******/
DROP PROCEDURE [dbo].[XX_INSERT_INT_CONTROL_RECORD]
GO

/****** Object:  StoredProcedure [dbo].[XX_INSERT_INT_CONTROL_RECORD]    Script Date: 8/24/2020 9:52:43 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[XX_INSERT_INT_CONTROL_RECORD]
(
@in_int_ctrl_pt_num     integer,
@in_lookup_domain_const char(30),
@in_STATUS_RECORD_NUM   integer
)
AS

/************************************************************************************************
Name:       XX_INSERT_INT_CONTROL_RECORD
Author:     HVT
Created:    06/23/2005
Purpose:    Insert a record into the table XX_IMAPS_INT_CONTROL for each control point or stage
            in the interface cycle that was successfully run.
            XX_IMAPS_INT_CONTROL's parent is XX_IMAPS_INT_STATUS.
            Called by XX_RUN_ETIME_INTERFACE.
Parameters: 
Result Set: None
Notes:
************************************************************************************************/

DECLARE @SP_NAME                 sysname,
        @SUCCESS_STATUS          varchar(10),
        @lv_ctrl_pt_id	   	 varchar(20),
        @lv_error                integer,
        @lv_rowcount             integer,
        @lv_display_msg_text     varchar(255),
		@comment_level	  varchar(10)

-- set local constants
SELECT @SP_NAME = 'XX_INSERT_INT_CONTROL_RECORD'
SELECT @SUCCESS_STATUS = 'SUCCESS'
PRINT '******************** ' + @SP_NAME +  '******************** '


SELECT @comment_level = PARAMETER_VALUE FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS 
WHERE INTERFACE_NAME_CD = 'UTIL' AND PARAMETER_NAME = 'COMMENT_LEVEL'



-- set local constants
-- validate user input
IF @in_int_ctrl_pt_num IS NULL OR @in_lookup_domain_const IS NULL OR @in_STATUS_RECORD_NUM IS NULL
   BEGIN
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 100, -- Missing required input parameter(s)
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
      RETURN(1) -- terminate execution and exit
   END

IF @comment_level = 'VERBOSE'
   BEGIN
		PRINT 'XX_IMAPS_INT_STATUS RECORD COUNT FOR THIS SRN IS: '
   END

-- verify that the XX_IMAPS_INT_STATUS record exists

	SELECT @lv_rowcount = COUNT(1)
	FROM dbo.XX_IMAPS_INT_STATUS
	WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM


IF @comment_level = 'VERBOSE'
   BEGIN
		PRINT '@lv_rowcount = ' + CAST(@lv_rowcount as VARCHAR(10))
   END


IF @lv_rowcount = 0
   BEGIN
      PRINT 'ERROR_MSG_DETAIL NEXT'
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 201,
         @in_placeholder_value1  = 'XX_IMAPS_INT_STATUS',
         @in_placeholder_value2  = 'PK column STATUS_RECORD_NUM',
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
      RETURN(1) -- terminate execution and exit
   END

IF @comment_level = 'VERBOSE'
   BEGIN
	PRINT 'LOOKUP DOMAIN - EXEC XX_GET_LOOKUP_DATA'
   END

-- retrieve the interface control point or stage ID from reference
EXEC dbo.XX_GET_LOOKUP_DATA
   @usr_domain_const       = @in_lookup_domain_const,
   @usr_app_code           = NULL,
   @usr_lookup_id          = NULL,
   @usr_presentation_order = @in_int_ctrl_pt_num,
   @sys_lookup_id          = NULL,
   @sys_app_code           = @lv_ctrl_pt_id OUTPUT,
   @sys_lookup_desc        = NULL


IF @comment_level = 'VERBOSE'
   BEGIN
	PRINT 'BEFORE INSERT INTO IMAPS_INT_CONTROL'
   END

INSERT INTO dbo.XX_IMAPS_INT_CONTROL
   (STATUS_RECORD_NUM, INTERFACE_NAME, INTERFACE_TYPE, INTERFACE_SOURCE_SYSTEM, INTERFACE_DEST_SYSTEM,
    INTERFACE_FILE_NAME, INTERFACE_SOURCE_OWNER, INTERFACE_DEST_OWNER, CONTROL_PT_ID, CONTROL_PT_STATUS,
    CREATED_BY, CREATED_DATE)
   SELECT STATUS_RECORD_NUM, INTERFACE_NAME, INTERFACE_TYPE, INTERFACE_SOURCE_SYSTEM, INTERFACE_DEST_SYSTEM,
          INTERFACE_FILE_NAME, INTERFACE_SOURCE_OWNER, INTERFACE_DEST_OWNER, @lv_ctrl_pt_id, @SUCCESS_STATUS,
          SUSER_SNAME(), GETDATE()
     FROM dbo.XX_IMAPS_INT_STATUS
    WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

SELECT @lv_error = @@ERROR

IF @comment_level = 'VERBOSE'
   BEGIN
	PRINT 'AFTER INSERT INTO IMAPS_INT_CONTROL'
   END


IF @lv_error <> 0
   BEGIN
      -- display both IMAPS's and SQL Server's error messages
      -- Attempt to insert a XX_IMAPS_INT_CONTROL record failed.
	  PRINT 'display both IMAPS and SQL Server error messages'
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = 204,
         @in_SQLServer_error_code = @lv_error,
         @in_display_requested    = 1,
         @in_placeholder_value1   = 'insert',
         @in_placeholder_value2   = 'a XX_IMAPS_INT_CONTROL record',
         @in_calling_object_name  = @SP_NAME
      RETURN(1)
   END
PRINT '**************** END ' + @SP_NAME +  '******************** '
RETURN(0)

GO



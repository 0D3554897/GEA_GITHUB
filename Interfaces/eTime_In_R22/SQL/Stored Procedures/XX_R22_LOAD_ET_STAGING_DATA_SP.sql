IF OBJECT_ID('dbo.XX_R22_LOAD_ET_STAGING_DATA_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_LOAD_ET_STAGING_DATA_SP
    IF OBJECT_ID('dbo.XX_R22_LOAD_ET_STAGING_DATA_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_LOAD_ET_STAGING_DATA_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_LOAD_ET_STAGING_DATA_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go

CREATE  PROCEDURE [dbo].[XX_R22_LOAD_ET_STAGING_DATA_SP]
(
@in_IMAPS_db_name        sysname,
@in_IMAPS_table_owner    sysname,
@in_STATUS_RECORD_NUM    integer,
@in_Data_FName           varchar(100),
@in_Dtl_Fmt_FName        varchar(100),
@in_Ftr_Fmt_FName        varchar(100), 
@out_STATUS_DESCRIPTION  varchar(255) OUTPUT
)
AS
/************************************************************************************************  
Name:       	XX_LOAD_ET_STAGING_DATA_SP  
Author:     	JG, HVT
Created:    	06/24/2005  
Purpose:    	Using the input Labor file from eTime to load the temporary staging tables
	    	i) XX_IMAPS_ET_IN_TMP -- Detail Data
	    	ii) XX_IMAPS_ET_FTR_IN_TMP -- Footer Data.  
            	The input file will consist of weekly labor data for Division 16 employees.  
            	See Labor_Interface_Design.doc for details  
                Called by XX_RUN_ETIME_INTERFACE.

Prerequisites: 	The following tables should be created-
			i) XX_INT_ERR_MSGS
	    		ii) XX_IMAPS_ET_IN_TMP 
	    		iii) XX_IMAPS_ET_FTR_IN_TMP 

Parameters: 
	Input: 	in_Data_FName -- Input File Name including path
		in_Dtl_Fmt_FName -- Format File name including path
		in_Ftr_Fmt_FName -- Footer Format name including path
	Output: out_Load_Status -- will hold the status of the load to return to the calling process   

Result Set: 	None  
Version: 	1.0
Notes:
Checked out for CR-1649

Modified : For CR-3749 For Imapsstg Shared ID 05/05/2011
**************************************************************************************************/  
  
DECLARE @SP_NAME             sysname,
        @out_NOTES           varchar(255),  
        @total_hours         decimal(14, 2),  
        @tot_ftr_rec_count   integer,  
        @tot_dtl_rec_count   integer,
	@tot_dtl_hours	     decimal(11,2),
	@tot_ftr_hours	     decimal(11,2),
        @lv_rcount           int,
        @lv_ftrcount         int,
	@lv_usr_password     sysname,
	@ret_code	     int

-- set local constants
SET @SP_NAME = 'XX_R22_LOAD_ET_STAGING_DATA_SP'

-- initialize local variables
--CHANGE KM 12/14/05
SELECT @lv_usr_password = PARAMETER_VALUE 
FROM dbo.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = 'ETIME_R22'
AND PARAMETER_NAME = 'IN_USER_PASSWORD'
--CHANGE KM 12/14/05
SET @tot_ftr_rec_count = 0
SET @tot_dtl_rec_count = 0  
SET @tot_dtl_hours = 0.0
SET @tot_ftr_hours = 0.0

BEGIN 

TRUNCATE TABLE dbo.XX_R22_IMAPS_ET_IN_TMP
TRUNCATE TABLE dbo.XX_R22_IMAPS_ET_FTR_IN_TMP

-- Insert records into table XX_IMAPS_ET_IN_TMP
EXEC @ret_code = dbo.XX_EXEC_SHELL_CMD_INSERT_OSUSER --Modified for CR-3749
   @in_IMAPS_db_name       = @in_IMAPS_db_name,
   @in_IMAPS_table_owner   = 'dbo',
   @in_dest_table          = 'XX_R22_IMAPS_ET_IN_TMP',
   @in_format_file         = @in_Dtl_Fmt_FName,
   @in_input_file          = @in_Data_FName,
   --@in_usr_password        = @lv_usr_password, --Modified for CR-3749
   @out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION OUTPUT

-- Replaced calling error message prc by following.. 
-- by JG on 08/23/05
IF @ret_code <> 0 -- called sp XX_EXEC_SHELL_CMD_INSERT was executed and returned a status code
   -- update of the XX_IMAPS_INT_STATUS record is done in the calling sp XX_RUN_ETIME_INTERFACE
   RETURN(1)
ELSE
   select @lv_rcount = count(*) from dbo.XX_R22_IMAPS_ET_IN_TMP
   IF @lv_rcount = 0 
      BEGIN
         -- Attempt to BULK INSERT into table %1 failed.
         EXEC dbo.XX_ERROR_MSG_DETAIL
            @in_error_code          = 400,
            @in_display_requested   = 1,
            @in_placeholder_value1  = 'XX_R22_IMAPS_ET_IN_TMP',
            @in_calling_object_name = @SP_NAME,
            @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT
         RETURN(1)
      END
   ELSE
      BEGIN
         -- this DELETE replaces the trigger that was executed in BULK INSERT
         DELETE FROM dbo.XX_R22_IMAPS_ET_IN_TMP where EMP_SERIAL_NUM = '999999'
         IF @@ERROR <> 0 
            BEGIN
               -- Attempt to delete XX_IMAPS_ET_IN_TMP records failed.
               EXEC dbo.XX_ERROR_MSG_DETAIL
                  @in_error_code           = 204,
                  @in_display_requested    = 1,
                  @in_SQLServer_error_code = @@ERROR,
                  @in_placeholder_value1   = 'delete',
                  @in_placeholder_value2   = 'XX_R22_IMAPS_ET_IN_TMP records',
                  @in_calling_object_name  = @SP_NAME,
                  @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
               RETURN(1)
            END
      END

-- Called sp XX_EXEC_SHELL_CMD_INSERT was not executed at all due any privilege/access errors
IF (@@ERROR <> 0)
   BEGIN
      -- Attempt to BULK INSERT into table %1 failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 400,
         @in_display_requested   = 1,
         @in_placeholder_value1  = 'XX_R22_IMAPS_ET_IN_TMP',
         @in_calling_object_name = @SP_NAME,
         @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT
         RETURN(1)
   END

-- Insert records into table XX_IMAPS_ET_FTR_IN_TMP
EXEC @ret_code = dbo.XX_EXEC_SHELL_CMD_INSERT_OSUSER  --Modified for CR-3749
   @in_IMAPS_db_name       = @in_IMAPS_db_name,
   @in_IMAPS_table_owner   = 'dbo',
   @in_dest_table          = 'XX_R22_IMAPS_ET_FTR_IN_TMP',
   @in_format_file         = @in_Ftr_Fmt_FName,
   @in_input_file          = @in_Data_FName,
   --@in_usr_password        = @lv_usr_password,   --Modified for CR-3749
   @out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION OUTPUT

-- Replaced calling error message prc by following.. 
-- by JG on 08/23/05
IF @ret_code <> 0 -- failure: previous execution step fails
   RETURN(1)
ELSE
   select @lv_ftrcount = count(1) from dbo.XX_R22_IMAPS_ET_FTR_IN_TMP
   IF @lv_ftrcount = 0 
      BEGIN
         -- Attempt to BULK INSERT into table %1 failed.
         EXEC dbo.XX_ERROR_MSG_DETAIL
            @in_error_code          = 400,
            @in_display_requested   = 1,
            @in_placeholder_value1  = 'XX_R22_IMAPS_ET_FTR_IN_TMP',
            @in_calling_object_name = @SP_NAME,
            @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT
         RETURN(1)
      END
   ELSE
      BEGIN
         -- this DELETE replaces the trigger that was executed in BULK INSERT
         DELETE FROM dbo.XX_R22_IMAPS_ET_FTR_IN_TMP where FOOTER_IND <> '999999'
         IF @@ERROR <> 0 
            BEGIN
               -- Attempt to delete XX_IMAPS_ET_FTR_IN_TMP records failed.
               EXEC dbo.XX_ERROR_MSG_DETAIL
                  @in_error_code           = 204,
                  @in_display_requested    = 1,
                  @in_SQLServer_error_code = @@ERROR,
                  @in_placeholder_value1   = 'delete',
                  @in_placeholder_value2   = 'XX_R22_IMAPS_ET_FTR_IN_TMP records',
                  @in_calling_object_name  = @SP_NAME,
                  @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
               RETURN(1)
            END
      END

IF (@@ERROR <> 0)
   BEGIN
      -- Attempt to BULK INSERT into table %1 failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 400,
         @in_display_requested   = 1,
         @in_placeholder_value1  = 'XX_R22_IMAPS_ET_FTR_IN_TMP',
         @in_calling_object_name = @SP_NAME,
         @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT
      RETURN(1)
   END

-- 09/19/2005 Change Begin

-- the next IF statement is now done in the sp XX_ET_VALIDATE_SOURCE_DATA_SP which is a part of stage 2

/*
IF ((SELECT COUNT(*) FROM dbo.XX_IMAPS_ET_IN_TMP) <> @tot_ftr_rec_count)
   BEGIN
      -- Footer record count does not match the detail record count
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 502,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME,
         @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT
      RETURN(1)
   END
*/

EXEC @ret_code = dbo.XX_R22_ET_VALIDATE_SOURCE_DATA_SP
   @out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION OUTPUT

IF @ret_code <> 0 -- above sp call fails
   RETURN(1)

-- 09/19/2005 Change End

SELECT @tot_ftr_rec_count = TOTAL_RECORDS,
       @tot_ftr_hours = TOTAL_REG_TIME
  FROM dbo.XX_R22_IMAPS_ET_FTR_IN_TMP
	
BEGIN
   -- update the XX_IMAPS_INT_STATUS record with the record totals
   UPDATE dbo.XX_IMAPS_INT_STATUS
      SET RECORD_COUNT_TRAILER = @tot_ftr_rec_count,
          RECORD_COUNT_INITIAL = @tot_ftr_rec_count,
          MODIFIED_BY = SUSER_SNAME(),
          MODIFIED_DATE = GETDATE()
    WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM
	
   IF (@@ROWCOUNT = 0)
      BEGIN
         -- Attempt to %1 IMAPS interface table %2 failed.
         EXEC dbo.XX_ERROR_MSG_DETAIL
            @in_error_code          = 302,
            @in_display_requested   = 1,
            @in_placeholder_value1  = 'update',
            @in_placeholder_value2  = 'XX_IMAPS_INT_STATUS',
            @in_calling_object_name = @SP_NAME,
            @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT
         RETURN(1)
      END
END
	
RETURN(0) 

END




go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_R22_LOAD_ET_STAGING_DATA_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_LOAD_ET_STAGING_DATA_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_LOAD_ET_STAGING_DATA_SP >>>'
go
	
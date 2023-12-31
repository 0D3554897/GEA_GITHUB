SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_INSERT_INT_STATUS_RECORD]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   DROP PROCEDURE [dbo].[XX_INSERT_INT_STATUS_RECORD]
GO

CREATE PROCEDURE dbo.XX_INSERT_INT_STATUS_RECORD
(
@in_IMAPS_db_name        sysname,
@in_IMAPS_table_owner    sysname,
@in_int_name             varchar(50),
@in_int_type             char(1),
@in_int_source_sys       varchar(50),
@in_int_dest_sys         varchar(50),
@in_Data_FName           sysname,
@in_int_source_owner     varchar(100),
@in_int_dest_owner       varchar(300),
@out_STATUS_RECORD_NUM   integer OUTPUT
)
AS

/*****************************************************************************************************
Name:       XX_INSERT_INT_STATUS_RECORD
Author:     HVT
Created:    06/23/2005
Purpose:    Insert into and update a record in the table XX_IMAPS_INT_STATUS for each interface cycle.
            Each interface cycle has exactly one XX_IMAPS_INT_STATUS record.

            For outbound interfaces, (1) the input parameter @in_Data_FName and the column
            INTERFACE_FILE_NAME should accept a zero-length or 'N/A' string, (2) toward the end of
            the interface run, the column INTERFACE_FILE_NAME is assigned the name of the output file
            (that is placed in the Out Box file directory).

Parameters:
Result Set: None
Notes:      Call example follows.

            EXEC dbo.XX_INSERT_INT_STATUS_RECORD
               @in_IMAPS_db_name      = @IMAPS_DB_NAME,
               @in_IMAPS_table_owner  = @IMAPS_SCHEMA_OWNER,
               @in_int_name           = @ETIME_INTERFACE_NAME,
               @in_int_type           = @INBOUND_INT_TYPE,
               @in_int_source_sys     = @INT_SOURCE_SYSTEM,
               @in_int_dest_sys       = @INT_DEST_SYSTEM,
               @in_Data_FName         = @in_Data_FName,
               @in_int_source_owner   = @in_int_source_owner,
               @in_int_dest_owner     = @in_int_dest_owner,
               @out_STATUS_RECORD_NUM = @lv_STATUS_RECORD_NUM OUTPUT

Defect 382: Change the interface status value from 'SUCCESS' to 'COMPLETED.'

Defect 982: 05/11/2006 In checking for the source input file (e.g., one supplied by the eT&E system)
            that may have been used successfully once before, fix the problem of the file's name
            having a carriage return character at the rightmost position saved in column
            INTERFACE_FILE_NAME.

CP600000199 02/08/2008 Reference BP&S Service Request: DR1427
            Enable more users to be notified by e-mail upon specific interface run events.
            Change the size of input parameter @in_int_dest_owner from varchar(100) to varchar(300).
*****************************************************************************************************/

DECLARE @SP_NAME                    sysname,
        @ETIME_INTERFACE            varchar(50),
        @PCLAIM_INTERFACE           varchar(50),
        @LD_CONST_INTERFACE_NAME    char(30),
        @INBOUND_INT_TYPE           char(1),
        @INTERFACE_STATUS_COMPLETED varchar(20),
        @INTERFACE_STATUS_INITIATED varchar(20),
        @INTERFACE_STATUS_DUPLICATE varchar(20),
        @lv_STATUS_RECORD_NUM       integer,
        @last_issued_STATUS_CODE    varchar(20),
        @lv_error                   integer,
        @lv_rowcount                integer,
        @lv_lookup_id               integer,
        @lv_lookup_app_code         varchar(20),
        @lv_identity_val            integer,
        @lv_status_desc             varchar(255),
        @ret_code                   integer

-- set local constants
SET @SP_NAME = 'XX_INSERT_INT_STATUS_RECORD'
SET @ETIME_INTERFACE = 'ETIME'
SET @PCLAIM_INTERFACE = 'PCLAIM'
SET @LD_CONST_INTERFACE_NAME = 'LD_INTERFACE_NAME'
SET @INBOUND_INT_TYPE = 'I' -- Inbound
SET @INTERFACE_STATUS_COMPLETED = 'COMPLETED'
SET @INTERFACE_STATUS_INITIATED = 'INITIATED'
SET @INTERFACE_STATUS_DUPLICATE = 'DUPLICATE'

-- validate the stored procedure call command for required input parameters
IF @in_int_name IS NULL OR
   @in_int_type IS NULL OR
   @in_int_source_sys IS NULL OR
   @in_int_dest_sys IS NULL OR
   @in_Data_FName IS NULL OR
   @in_int_source_owner IS NULL OR
   @in_int_dest_owner IS NULL
   BEGIN
      -- Missing required input parameter(s)
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 100,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
      RETURN(1) -- terminate execution and exit
   END

-- Validate interface name against reference
EXEC dbo.XX_GET_LOOKUP_DATA
   @usr_domain_const	   = @LD_CONST_INTERFACE_NAME,
   @usr_app_code           = @in_int_name,
   @usr_lookup_id	   = NULL,
   @usr_presentation_order = NULL,
   @sys_lookup_id          = @lv_lookup_id OUTPUT,
   @sys_app_code           = @lv_lookup_app_code OUTPUT,
   @sys_lookup_desc   	   = NULL

IF @lv_lookup_id IS NULL
   BEGIN
      -- %1 is invalid or does not exist.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 200,
         @in_placeholder_value1  = 'The interface name',
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
      RETURN(1)
   END

/*
 * Validate the file name: file name must not be of a file that has already been successfully processed
 * or one that already exists and therefore considered "DUPLICATE" file
 * Allow processing to proceed if the existing file name has status = "BAD FILE"
 */
IF @in_int_type = @INBOUND_INT_TYPE
   IF @in_int_name = @ETIME_INTERFACE 
      /* TP 11/10/2005 PCLAIM will work from table or @in_int_name = @PCLAIM_INTERFACE */
      BEGIN

-- Defect 982 Begin
         /*
          * The value of @in_Data_FName could come from XX_PROCESSING_PARAMETERS.PARAMETER_VALUE of a
          * previously completed run which includes a carriage return character at the rightmost position.
          */
         IF SUBSTRING(@in_Data_FName, LEN(@in_Data_FName), 1) = CHAR(13)
            OR SUBSTRING(@in_Data_FName, LEN(@in_Data_FName), 1) = CHAR(10)
            SET @in_Data_FName = SUBSTRING(@in_Data_FName, 1, LEN(@in_Data_FName) - 1)
-- Defect 982 End

         SELECT @lv_rowcount = COUNT(1)
           FROM dbo.XX_IMAPS_INT_STATUS
          WHERE INTERFACE_FILE_NAME = @in_Data_FName
            AND INTERFACE_NAME = @in_int_name

         IF @lv_rowcount = 1
            BEGIN
               SELECT @out_STATUS_RECORD_NUM = STATUS_RECORD_NUM, @last_issued_STATUS_CODE = STATUS_CODE
                 FROM dbo.XX_IMAPS_INT_STATUS
                WHERE INTERFACE_FILE_NAME = @in_Data_FName
                  AND INTERFACE_NAME = @in_int_name

               IF @last_issued_STATUS_CODE = @INTERFACE_STATUS_COMPLETED
                  BEGIN   
                     -- The input file has been processed successfully at least once before.
                     EXEC dbo.XX_ERROR_MSG_DETAIL
                        @in_error_code          = 501,
                        @in_display_requested   = 1,
                        @in_calling_object_name = @SP_NAME,
                        @out_msg_text           = @lv_status_desc OUTPUT

                     -- before exit, insert a new record to register this duplicate input file event
                     INSERT INTO dbo.XX_IMAPS_INT_STATUS
                        (INTERFACE_NAME, INTERFACE_TYPE, INTERFACE_SOURCE_SYSTEM, INTERFACE_DEST_SYSTEM,
                         INTERFACE_FILE_NAME, INTERFACE_SOURCE_OWNER, INTERFACE_DEST_OWNER, STATUS_CODE,
                         STATUS_DESCRIPTION, CREATED_BY, CREATED_DATE)
                        VALUES(@in_int_name, @in_int_type, @in_int_source_sys, @in_int_dest_sys,
                               @in_Data_FName, @in_int_source_owner, @in_int_dest_owner, @INTERFACE_STATUS_DUPLICATE,
                               @lv_status_desc, SUSER_SNAME(), GETDATE())

                     SELECT @lv_error = @@ERROR

                     IF @lv_error <> 0
                        BEGIN
                        -- Attempt to insert a XX_IMAPS_INT_STATUS record failed.
                           EXEC dbo.XX_ERROR_MSG_DETAIL
                              @in_error_code           = 204,
                              @in_display_requested    = 1,
                              @in_SQLServer_error_code = @lv_error,
                              @in_placeholder_value1   = 'insert',
                              @in_placeholder_value2   = 'a XX_IMAPS_INT_STATUS record',
                              @in_calling_object_name  = @SP_NAME,
                              @out_msg_text            = @lv_status_desc OUTPUT
                           RETURN(1)
                        END

-- Defect 982 Begin
                     -- End this interface run because the user submitted duplicate input file
                     RETURN(1)
-- Defect 982 End
                  END
            END
         ELSE IF @lv_rowcount > 1
            BEGIN
               /*
                * This is a worse case scenario.
                * Two XX_IMAPS_INT_STATUS records, one with status COMPLETED and one with status DUPLICATE, already exist.
                * Just issue error warning and exit.
                * Processing of the last interface job found the source input file to have been processed successfully
                * at least once before.
                */
               EXEC dbo.XX_ERROR_MSG_DETAIL
                  @in_error_code          = 403,
                  @in_display_requested   = 1,
                  @in_calling_object_name = @SP_NAME,
                  @out_msg_text           = @lv_status_desc OUTPUT
               RETURN(1)
            END

         /*
          * Get the information message to use as status description in the next INSERT
          * 'The %1 input file has been validated successfully. Interface processing is initiated.'
          */
         EXEC dbo.XX_ERROR_MSG_DETAIL
            @in_error_code         = 503,
            @in_placeholder_value1 = @lv_lookup_app_code,
            @out_msg_text          = @lv_status_desc OUTPUT

      END /* IF @in_int_name = @ETIME_INTERFACE or @in_int_name = @PCLAIM_INTERFACE */

   ELSE IF @in_int_name = @lv_lookup_app_code
      /*
       * Get the information message to use as status description in the next INSERT
       * 'Processing for %1 interface is initiated.'
       */
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code         = 504,
         @in_placeholder_value1 = @lv_lookup_app_code,
         @out_msg_text          = @lv_status_desc OUTPUT

/*
 * Insert a record into table XX_IMAPS_INT_STATUS for this interface run.
 * STATUS_RECORD_NUM is the PK and an IDENTITY column.
 */

-- 03/13/2006 HVT_Change_Begin
IF @lv_status_desc IS NULL
   SET @lv_status_desc = LTRIM(RTRIM(@in_int_name)) + ' interface processing is initiated.'
-- 03/13/2006 HVT_Change_End

INSERT INTO dbo.XX_IMAPS_INT_STATUS(INTERFACE_NAME, INTERFACE_TYPE, INTERFACE_SOURCE_SYSTEM,
   INTERFACE_DEST_SYSTEM, INTERFACE_FILE_NAME, INTERFACE_SOURCE_OWNER, INTERFACE_DEST_OWNER,
   STATUS_CODE, STATUS_DESCRIPTION, CREATED_BY, CREATED_DATE)
   VALUES(@in_int_name, @in_int_type, @in_int_source_sys,
          @in_int_dest_sys, @in_Data_FName, @in_int_source_owner, @in_int_dest_owner,
          @INTERFACE_STATUS_INITIATED, @lv_status_desc, SUSER_SNAME(), GETDATE())

SELECT @lv_error = @@ERROR

IF @lv_error <> 0
   BEGIN
      -- display both IMAPS's and SQL Server's error messages
      -- Attempt to insert a XX_IMAPS_INT_STATUS record failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = 204,
         @in_SQLServer_error_code = @lv_error,
         @in_display_requested    = 1,
         @in_placeholder_value1   = 'insert',
         @in_placeholder_value2   = 'a XX_IMAPS_INT_STATUS record',
         @in_calling_object_name  = @SP_NAME,
         @out_msg_text            = @lv_status_desc OUTPUT
      RETURN(1)
   END

/*
 * Retrieve the last-generated identity value assigned to the IDENTITY column
 * XX_IMAPS_INT_STATUS.STATUS_RECORD_NUM from the INSERT above
 */
SET @lv_identity_val = IDENT_CURRENT('dbo.XX_IMAPS_INT_STATUS')

-- for insurance and other purposes, verify that the XX_IMAPS_INT_STATUS record just inserted above exists
SELECT @lv_STATUS_RECORD_NUM = STATUS_RECORD_NUM
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE STATUS_RECORD_NUM = @lv_identity_val

SET @lv_rowcount = @@ROWCOUNT

IF @lv_rowcount = 0
   BEGIN
      -- A database error has occured. Please contact system administrator.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 301,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME,
         @out_msg_text           = @lv_status_desc OUTPUT
      RETURN(1)
   END

-- populate this sp's output parameter
SET @out_STATUS_RECORD_NUM = @lv_STATUS_RECORD_NUM

RETURN(0)

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

use imapsstg

IF OBJECT_ID('dbo.XX_R22_GET_ET_PROCESSING_PARAMETERS') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_GET_ET_PROCESSING_PARAMETERS
    IF OBJECT_ID('dbo.XX_R22_GET_ET_PROCESSING_PARAMETERS') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_GET_ET_PROCESSING_PARAMETERS >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_GET_ET_PROCESSING_PARAMETERS >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go


CREATE PROCEDURE dbo.XX_R22_GET_ET_PROCESSING_PARAMETERS
(
@out_IN_TS_SOURCE_FILENAME          sysname      = NULL OUTPUT,
@out_IN_SOURCE_SYSOWNER             sysname      = NULL OUTPUT,
@out_IN_DESTINATION_SYSOWNER        varchar(300) = NULL OUTPUT,
@out_IN_DETAIL_FORMAT_FILENAME      sysname      = NULL OUTPUT,
@out_IN_FOOTER_FORMAT_FILENAME      sysname      = NULL OUTPUT,
@out_IN_PREP_FORMAT_FILENAME        sysname      = NULL OUTPUT,
@out_IN_PREP_TABLE_NAME             sysname      = NULL OUTPUT,
@out_OUT_TS_PREP_FILENAME           sysname      = NULL OUTPUT,
@out_IMAPS_SCHEMA_OWNER             sysname      = NULL OUTPUT,
@out_IN_USER_NAME                   sysname      = NULL OUTPUT,
@out_IN_USER_PASSWORD               sysname      = NULL OUTPUT,
@out_OUT_CP_ERROR_FILENAME          sysname      = NULL OUTPUT,
@out_IN_TS_PREP_ERROR_TABLE         sysname      = NULL OUTPUT,
@out_IN_TS_PREP_ERR_FORMAT_FILENAME sysname      = NULL OUTPUT,
@out_IN_ETIME_CP_PROC_ID            sysname      = NULL OUTPUT,
@out_IN_ETIME_CP_PROC_QUEUE_ID      sysname      = NULL OUTPUT
)
AS

/***************************************************************************************************
Name:       XX_R22_GET_ET_PROCESSING_PARAMETERS
Author:     HVT
Created:    08/18/2005
Purpose:    Get all input parameter data necessary to run the eTime interface.
            Each IMAPS interface has a unique set of parameters for execution purposes.
            Not all parameters are "represented" in the form of a XX_PROCESSING_PARAMETERS record.
            That is, some parameters are derived from other specific parameters.
            The file names of the Costpoint preprocessor input and error log file are built using
            the file name of the source timesheet input file with a different file name extension,
            PIN, and ERR, respectively.
            Called by XX_R22_RUN_ETIME_INTERFACE.
Parameters: 
Result Set: None
Notes:

Example of call follows.

EXEC @ret_code = dbo.XX_R22_GET_ET_PROCESSING_PARAMETERS
   @out_IN_TS_SOURCE_FILENAME     = @IN_TS_SOURCE_FILENAME     OUTPUT,
   @out_IN_SOURCE_SYSOWNER        = @IN_SOURCE_SYSOWNER        OUTPUT,
   @out_IN_DESTINATION_SYSOWNER   = @IN_DESTINATION_SYSOWNER   OUTPUT,
   @out_IN_DETAIL_FORMAT_FILENAME = @IN_DETAIL_FORMAT_FILENAME OUTPUT,
   @out_IN_FOOTER_FORMAT_FILENAME = @IN_FOOTER_FORMAT_FILENAME OUTPUT,
   @out_IN_PREP_FORMAT_FILENAME   = @IN_PREP_FORMAT_FILENAME   OUTPUT,
   @out_IN_PREP_TABLE_NAME        = @IN_PREP_TABLE_NAME        OUTPUT,
   @out_OUT_TS_PREP_FILENAME      = @OUT_TS_PREP_FILENAME      OUTPUT,
   @out_IMAPS_SCHEMA_OWNER        = @IMAPS_SCHEMA_OWNER        OUTPUT,
   @out_IN_USER_NAME              = @IN_USER_NAME              OUTPUT,
   @out_IN_USER_PASSWORD          = @IN_USER_PASSWORD          OUTPUT,
   @out_OUT_CP_ERROR_FILENAME     = @OUT_CP_ERROR_FILENAME     OUTPUT,
   @out_IN_ETIME_CP_PROC_ID       = @IN_ETIME_CP_PROC_ID       OUTPUT,
   @out_IN_ETIME_CP_PROC_QUEUE_ID = @IN_ETIME_CP_PROC_QUEUE_ID OUTPUT

CP600000199 02/08/2008 Reference BP&S Service Request: DR1427
            Enable more users to be notified by e-mail upon specific interface run events.
            Change the size of @out_IN_DESTINATION_SYSOWNER and @lv_PARAMETER_VALUE to varchar(300).

CP600001476 03/13/2012 Reference FSST Service Request DR4037
            Enable eTime interface and eTime miscode interfaces for divisions 16 and 22 to run
            simultaneously.
            
2014-02-18  Costpoint 7 changes
			Process Server replaced by Job Server
***************************************************************************************************/

DECLARE @SP_NAME                   sysname,
        @LD_CONST_INTERFACE_NAME   char(30),
        @ETIME_INTERFACE           varchar(50),
        @lv_lookup_id              integer,
        @lv_lookup_app_code        varchar(20),
        @lv_status_desc            varchar(255),
        @lv_PARAMETER_NAME         varchar(50),
        @lv_PARAMETER_VALUE        varchar(300),
        @CP_ERROR_FILENAME_EXT     char(4),
        @TS_PREP_FILENAME_EXT      char(4),
        @lv_PROCESS_ID             varchar(12),
        @lv_error                  integer,
        @lv_rowcount               integer,
        @lv_ret_code      integer

-- set local constants
SET @SP_NAME = 'XX_R22_GET_ET_PROCESSING_PARAMETERS' -- DR4037
SET @LD_CONST_INTERFACE_NAME = 'LD_INTERFACE_NAME'
SET @ETIME_INTERFACE = 'ETIME_R22'
SET @CP_ERROR_FILENAME_EXT = '.ERR'
SET @TS_PREP_FILENAME_EXT = '.CPR'

-- first, search for any existing XX_PROCESSING_PARAMETERS record(s)
EXEC @lv_ret_code = dbo.XX_GET_LOOKUP_DATA
   @usr_domain_const	   = @LD_CONST_INTERFACE_NAME,
   @usr_app_code           = @ETIME_INTERFACE,
   @usr_lookup_id	   = NULL,
   @usr_presentation_order = NULL,
   @sys_lookup_id          = @lv_lookup_id OUTPUT,
   @sys_app_code           = @lv_lookup_app_code OUTPUT,
   @sys_lookup_desc   	   = NULL

IF @lv_ret_code <> 0 -- previous execution step fails
   RETURN(1)

SELECT @lv_rowcount = COUNT(1)
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_ID = @lv_lookup_id
   AND INTERFACE_NAME_CD = @lv_lookup_app_code

IF @lv_rowcount = 0
   BEGIN
      -- Missing processing parameter data for ETIME_R22 interface execution.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 112,
         @in_placeholder_value1  = 'ETIME_R22', -- DR4037
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
          WHERE INTERFACE_NAME_ID = @lv_lookup_id
            AND INTERFACE_NAME_CD = @lv_lookup_app_code

      OPEN cursor_one
      FETCH cursor_one INTO @lv_PARAMETER_NAME, @lv_PARAMETER_VALUE

      WHILE (@@fetch_status = 0)
         BEGIN
            IF @lv_PARAMETER_NAME = 'IN_TS_SOURCE_FILENAME'
               BEGIN
                  SET @out_IN_TS_SOURCE_FILENAME = @lv_PARAMETER_VALUE
--                SET @out_OUT_TS_PREP_FILENAME = REPLACE(@out_IN_TS_SOURCE_FILENAME, '.txt', @TS_PREP_FILENAME_EXT)
--                SET @out_OUT_CP_ERROR_FILENAME = REPLACE(@out_IN_TS_SOURCE_FILENAME, '.txt', @CP_ERROR_FILENAME_EXT)
               END
            ELSE IF @lv_PARAMETER_NAME = 'IN_SOURCE_SYSOWNER'
               SET @out_IN_SOURCE_SYSOWNER = @lv_PARAMETER_VALUE
            ELSE IF @lv_PARAMETER_NAME = 'IN_DESTINATION_SYSOWNER'
               SET @out_IN_DESTINATION_SYSOWNER = @lv_PARAMETER_VALUE
            ELSE IF @lv_PARAMETER_NAME = 'IN_DETAIL_FORMAT_FILENAME'
               SET @out_IN_DETAIL_FORMAT_FILENAME = @lv_PARAMETER_VALUE
            ELSE IF @lv_PARAMETER_NAME = 'IN_FOOTER_FORMAT_FILENAME'
               SET @out_IN_FOOTER_FORMAT_FILENAME = @lv_PARAMETER_VALUE
            ELSE IF @lv_PARAMETER_NAME = 'IN_PREP_FORMAT_FILENAME'
               SET @out_IN_PREP_FORMAT_FILENAME = @lv_PARAMETER_VALUE
            ELSE IF @lv_PARAMETER_NAME = 'IN_PREP_TABLE_NAME'
               SET @out_IN_PREP_TABLE_NAME = @lv_PARAMETER_VALUE
            ELSE IF @lv_PARAMETER_NAME = 'OUT_TS_PREP_FILENAME'
               SET @out_OUT_TS_PREP_FILENAME = @lv_PARAMETER_VALUE
            ELSE IF @lv_PARAMETER_NAME = 'OUT_CP_ERROR_FILENAME'
               SET @out_OUT_CP_ERROR_FILENAME = @lv_PARAMETER_VALUE
            ELSE IF @lv_PARAMETER_NAME = 'IN_TS_PREP_ERROR_TABLE'
               SET @out_IN_TS_PREP_ERROR_TABLE = @lv_PARAMETER_VALUE
            ELSE IF @lv_PARAMETER_NAME = 'IN_TS_PREP_ERR_FORMAT_FILENAME'
               SET @out_IN_TS_PREP_ERR_FORMAT_FILENAME = @lv_PARAMETER_VALUE
            ELSE IF @lv_PARAMETER_NAME = 'IMAPS_SCHEMA_OWNER'
               SET @out_IMAPS_SCHEMA_OWNER = @lv_PARAMETER_VALUE
            ELSE IF @lv_PARAMETER_NAME = 'IN_USER_NAME'
               SET @out_IN_USER_NAME = @lv_PARAMETER_VALUE
            ELSE IF @lv_PARAMETER_NAME = 'IN_USER_PASSWORD'
               SET @out_IN_USER_PASSWORD = @lv_PARAMETER_VALUE
            ELSE IF @lv_PARAMETER_NAME = 'IN_ETIME_CP_PROC_ID'
               SET @out_IN_ETIME_CP_PROC_ID = @lv_PARAMETER_VALUE
            ELSE IF @lv_PARAMETER_NAME = 'IN_ETIME_CP_PROC_QUEUE_ID'
               SET @out_IN_ETIME_CP_PROC_QUEUE_ID = @lv_PARAMETER_VALUE

            FETCH cursor_one INTO @lv_PARAMETER_NAME, @lv_PARAMETER_VALUE
         END

      CLOSE cursor_one
      DEALLOCATE cursor_one
   END /* @lv_rowcount <> 0 */


--2014-02-18  Costpoint 7 changes BEGIN
/*
-- ensure that the PROCESS_ID set up for eTime interface exists in Costpoint
IF @out_IN_ETIME_CP_PROC_ID IS NOT NULL
   BEGIN
      select 1 
        from IMAR.DELTEK.PROCESS_HDR
       where PROCESS_ID = @out_IN_ETIME_CP_PROC_ID

      IF @@ROWCOUNT = 0
         BEGIN
            -- Costpoint process ID for eTime interface does not exist (see DELTEK.PROCESS_HDR.PROCESS_ID).
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code          = 600,
               @in_display_requested   = 1,
               @in_calling_object_name = @SP_NAME
            RETURN(1)
         END
   END

-- ensure that the PROC_QUEUE_ID set up for eTime interface exists in Costpoint
IF @out_IN_ETIME_CP_PROC_QUEUE_ID IS NOT NULL
   BEGIN
      select 1
        from IMAR.DELTEK.PROCESS_QUE_ENTRY
       where PROC_QUEUE_ID = @out_IN_ETIME_CP_PROC_QUEUE_ID

      IF @@ROWCOUNT = 0
         BEGIN
            -- Costpoint process queue ID for eTime interface does not exist (see DELTEK.PROCESS_QUEUE.PROC_QUEUE_ID).
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code          = 601,
               @in_display_requested   = 1,
               @in_calling_object_name = @SP_NAME
            RETURN(1)
         END
   END
  */
  
--2014-02-18  Costpoint 7 changes END

RETURN(0)

go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_R22_GET_ET_PROCESSING_PARAMETERS') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_GET_ET_PROCESSING_PARAMETERS >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_GET_ET_PROCESSING_PARAMETERS >>>'
go

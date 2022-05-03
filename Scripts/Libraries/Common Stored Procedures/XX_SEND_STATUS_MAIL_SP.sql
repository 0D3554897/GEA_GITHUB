USE [IMAPSStg]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_SEND_STATUS_MAIL_SP]') AND type in (N'P', N'PC'))
   EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[XX_SEND_STATUS_MAIL_SP]AS' 
GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

ALTER PROCEDURE [dbo].[XX_SEND_STATUS_MAIL_SP] 
( 
@in_StatusRecordNum  int,
@in_Attachments      varchar(300) = NULL, -- DR-11928
@out_SystemErrorCode int = NULL OUTPUT 
)
AS
/**************************************************************************************************************
Name:       XX_SEND_STATUS_MAIL_SP
Author:     Tatiana Perova
Created:    07/18/2005
Purpose:    Send notification mail.

Parameters: @in_Attachments - full path to the attachments files on server
	    @in_StatusRecordNum  -  id of the record in interface status table that should be notification base
	    @out_SystemErrorCode - will have system message code if one available.
 
Return values: 
	    0 - success
	    1 - failure
	    304 - ERROR: no status record found
	    107 - no lookup data

Notes:      This procedure will create a record with received parameters in XX_IMAPS_MAIL_OUT table.  
            Than at scheduled time all new record will be read by other application,  PORT
              email message will be sent and TIME_SEND field on the mail record will be populated.

            Call example:
 
            EXEC dbo.XX_SEND_STATUS_MAIL_SP 325, 'C:\ddd\ddd.txt; C:\ddd\eee.xml'

CP600000199 02/08/2008 Reference BP&S Service Request: DR1427
            Enable more users to be notified by e-mail upon specific interface run events.
            Change the size of @MailTo from varchar(100) to varchar(300).

            04/11/2008 Fix the error --Msg 8152, Level 16, State 14 - String or binary data would be truncated.--
            caused by the dynamic construction of the value of column MESSAGE_SUBJECT of the XX_IMAPS_MAIL_OUT
            record inside the INSERT INTO statement.

CR9295      04/13/2017 GEA - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
CR9449      01/18/2018 GEA - Commented multiple PRINT statements - too much logging for other applications
CR9268      03/09/2018 GEA - Added for CLSDOWN

CR-11604    12/10/2019 Correct parameter @USR_APP_CODE's value for the first XX_GET_LOOKUP_DATA call.
            Fix the problem of using @@IDENTITY system function directly in an UPDATE statement (following a
            successful INSERT where the IDENTITY column MESSAGE_ID is assigned a value).

DR-11928    04/01/2020 Enable the email body's text message to contain MESSAGE_ID's value.
            Fix the problem of @in_Attachments, defined as char(300), that causes space characters to be padded
            to its RHS and results in Error 14628 issued by system procedure sp_GetAttachmentData.
****************************************************************************************************************/

 
-- PRINT '' -- *~^ CR9295
-- PRINT '*~^**************************************************************************************************************'
-- PRINT '*~^                                                                                                             *'
PRINT '*~^                        BEGIN XX_SEND_STATUS_MAIL_SP'
-- PRINT '*~^                                                                                                             *'
-- PRINT '*~^**************************************************************************************************************'
-- PRINT '' -- *~^ CR9295
 
DECLARE @StatusCode             varchar(20),
        @StatusCodeDescription  varchar(60),
        @InterfaceName          varchar(50),
        @InterfaceFullName      varchar(60),
        @AllRecords             numeric(9, 0),
        @ErrorRecords           numeric(9, 0),
        @StatusMessage          varchar(240),
        @MailTo                 varchar(300),
        @MailFrom               varchar(100),
        @IMAPSReturnCode        int,
        @RecordCount            int,
        @SP_NAME                sysname,
        @email_msg_text         varchar(3000),
        @email_msg_subject      varchar(100),
        @Server_Environment     varchar(20),
        @IMAPS_error_code       integer,
        @error_msg_placeholder1 sysname,
        @error_msg_placeholder2 sysname,
        @msg_id                 integer  -- DR-11928

-- Set local constants

SET @SP_NAME = 'XX_SEND_STATUS_MAIL_SP'

PRINT 'Status Record Number passed in is ' + cast(@in_StatusRecordNum as varchar(20))

-- the third query must be run in each environment
-- select max(interface_name_id)+1 from imapsstg.dbo.XX_PROCESSING_PARAMETERS <-- this gives you the value for first item in the insert
-- insert into imapsstg.dbo.xx_processing_parameters values ('143','SERVER','SERVER_ENVIRONMENT','IMAPS','GEORGE',getdate(),'GEORGE',GETDATE(),NULL)

 PRINT 'Looking for Environment name in parameters table'

-- Find the environment

 
-- PRINT convert(varchar, current_timestamp, 21) + ' : *~^ COMMON_CODE : Line 109 : XX_SEND_STATUS_MAIL.sql '  --CR9295
 
SELECT @Server_Environment = PARAMETER_VALUE
FROM   dbo.XX_PROCESSING_PARAMETERS
WHERE  parameter_name = 'SERVER_ENVIRONMENT'

SET @out_SystemErrorCode = @@ERROR

-- PRINT 'ERR IS ' +  @out_SystemErrorCode + ' and server is ' + @Server_Environment

--@out_SystemErrorCode > 0 OR

IF @out_SystemErrorCode > 0 OR @Server_Environment is NULL
   BEGIN
      -- Error No. 204: Attempt to identify server environment XX_PROCESSING_PARAMETERS failed.
      SET @IMAPS_error_code = 204
      SET @error_msg_placeholder1 = 'identify'
      SET @error_msg_placeholder2 = 'server environment in XX_PROCESSING_PARAMETERS'
      GOTO ErrorProcessing
   END

 PRINT 'Selecting status data'
-- Get interface run status data

 
-- PRINT convert(varchar, current_timestamp, 21) + ' : *~^ COMMON_CODE : Line 134 : XX_SEND_STATUS_MAIL.sql '  --CR9295
 
SELECT @StatusCode    = STATUS_CODE,
       @StatusMessage = STATUS_DESCRIPTION,
       @InterfaceName = INTERFACE_NAME,
       @AllRecords    = RECORD_COUNT_INITIAL,
       @ErrorRecords  = RECORD_COUNT_ERROR,
       @MailFrom      = INTERFACE_SOURCE_OWNER, 
       @MailTo        = INTERFACE_DEST_OWNER
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE STATUS_RECORD_NUM = @in_StatusRecordNum 

SET @RecordCount = @@ROWCOUNT

If @RecordCount <> 1
   BEGIN
      -- Error No. 304: Mail notification record could not be created due to invalid input value for STATUS_RECORD_NUM.
      SET @IMAPS_error_code = 304
      GOTO ErrorProcessing
   END
   
PRINT 'Executing SP for IMAPS Return Code and Lookup Data'

-- Get description of interface execution status code

 
-- PRINT convert(varchar, current_timestamp, 21) + ' : *~^ COMMON_CODE : Line 160 : XX_SEND_STATUS_MAIL.sql '  --CR9295
 
EXEC @IMAPSReturnCode = dbo.XX_GET_LOOKUP_DATA
   @usr_domain_const       = 'LD_EXECUTION_STATUS',
   @usr_app_code           = @StatusCode, -- DR-11928
   @usr_lookup_id          = NULL,
   @usr_presentation_order = NULL,
   @sys_lookup_id          = NULL,
   @sys_app_code           = NULL,
   @sys_lookup_desc        = @StatusCodeDescription OUTPUT

IF @IMAPSReturnCode > 0 OR @StatusCodeDescription is NULL
   BEGIN
      SET @IMAPS_error_code = 304
      GOTO ErrorProcessing
   END

-- Get description associated with interface ID

 
-- PRINT convert(varchar, current_timestamp, 21) + ' : *~^ COMMON_CODE : Line 180 : XX_SEND_STATUS_MAIL.sql '  --CR9295
 
EXEC @IMAPSReturnCode = dbo.XX_GET_LOOKUP_DATA
   @usr_domain_const       = 'LD_INTERFACE_NAME',
   @usr_app_code           = @InterfaceName,
   @usr_lookup_id          = NULL,
   @usr_presentation_order = NULL,
   @sys_lookup_id          = NULL,
   @sys_app_code           = NULL,
   @sys_lookup_desc        = @InterfaceFullName OUTPUT

IF @IMAPSReturnCode > 0 OR @InterfaceFullName is NULL
   BEGIN
      SET @IMAPS_error_code = 304
      GOTO ErrorProcessing
   END

-- Prepare column values to be used by the INSERT statement

PRINT 'Setting email message'

SET @email_msg_text = 'This message was generated by the IMAPS financial system resulting from execution of the '
                      + @InterfaceFullName
                      + ' interface with a status: ' + @StatusCodeDescription + '. '
                      + @StatusMessage + '. ' + -- DR-11928
                        CASE
                           WHEN (@AllRecords is NULL) THEN ''
                           ELSE ' Of ' +  CAST(@AllRecords AS VARCHAR(10)) + ' records submitted ' 
                        END + 
                        CASE
                           WHEN (@ErrorRecords is NULL) THEN ' '
                           ELSE CAST(@ErrorRecords AS VARCHAR(10)) + ' failed. '
                        END
                      + 'Please do not reply to this message. Address your requests to ' + @MailFrom
                      + '. Message ID '

PRINT 'Setting email subject'

SET @email_msg_subject = @Server_Environment + ' Notification for ' +  @StatusCodeDescription + ' run from IMAPS interface ' + @InterfaceFullName

PRINT 'Inserting Email in table'


 
-- PRINT convert(varchar, current_timestamp, 21) + ' : *~^ COMMON_CODE : Line 225 : XX_SEND_STATUS_MAIL.sql '  --CR9295
 
INSERT INTO dbo.XX_IMAPS_MAIL_OUT
   (MESSAGE_TEXT, MESSAGE_SUBJECT, MAIL_TO_ADDRESS, ATTACHMENTS, STATUS_RECORD_NUM)
   VALUES(@email_msg_text, @email_msg_subject, @MailTo, @in_Attachments, @in_StatusRecordNum)

SET @out_SystemErrorCode = @@ERROR

IF @out_SystemErrorCode > 0
   BEGIN
      -- Error No. 204: Attempt to insert a record in table XX_IMAPS_MAIL_OUT failed.
      SET @IMAPS_error_code = 204
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'a record in table XX_IMAPS_MAIL_OUT'
      GOTO ErrorProcessing
   END

-- DR-11928 Begin
-- When the XX_IMAPS_MAIL_OUT record is being inserted, the trigger XX_IMAPS_MAIL_OUT_INSTRIG appends MESSAGE_ID's value to MESSAGE_TEXT's value,
-- calls msdb.dbo.sp_send_dbmail to actually send the mail (this commits the record), and finally updates MESSAGE_TEXT and SEND_DT.

SELECT @msg_id = MESSAGE_ID
  FROM dbo.XX_IMAPS_MAIL_OUT
 WHERE STATUS_RECORD_NUM = @in_StatusRecordNum

PRINT 'Find the email here: SELECT * FROM IMAPSSTG.DBO.XX_IMAPS_MAIL_OUT WHERE MESSAGE_ID = ' + CAST(@msg_id as varchar(15))
PRINT '                       END OF XX_SEND_STATUS_MAIL_SP'

-- DR-11928 End

RETURN(0)

ErrorProcessing:

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_code,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @out_SystemErrorCode,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME

RETURN(1)

GO

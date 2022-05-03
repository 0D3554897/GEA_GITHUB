USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_SEND_MISSING_NOTICE_SP]    Script Date: 03/10/2017 09:41:59 ******/


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_CERIS_SEND_MISSING_NOTICE_SP]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE  [dbo].[XX_CERIS_SEND_MISSING_NOTICE_SP] AS' 
END
GO

USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_SEND_MISSING_NOTICE_SP]    Script Date: 03/10/2017 09:41:59 ******/


SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO


ALTER PROCEDURE [dbo].[XX_CERIS_SEND_MISSING_NOTICE_SP] 
( 
-- @in_StatusRecordNum  int,
-- @in_Attachments      char(300) = NULL,
@out_SystemErrorCode int       = NULL OUTPUT 
)
AS
/**************************************************************************************************************
Name:       XX_CERIS_SEND_MISSING_NOTICE_SP
Author:     George Alvarez, borrowing lots of code from Tatiana Perova (CR9295)
Created:    03/10/2017
Purpose:    Send notification mail that Workday file is missing data.

Parameters: @in_Attachments - full path to the attachments files on server
	    @in_StatusRecordNum  -  id of the record in interface status table that should be notification base
	    @out_SystemErrorCode - will have system message code if one available.
 
Return values: 
	    0 - success
	    1 - failure

Notes:      This procedure will create a record with received parameters in XX_IMAPS_MAIL_OUT table.  
            Than at scheduled time all new record will be read by other application, email message will be sent
            and TIME_SEND field on the mail record will be populated.

            Call example:

 

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 52 : XX_CERIS_SEND_MISSING_NOTICE_SP.sql '  --CR9295
 
            EXEC dbo.XX_CERIS_SEND_MISSING_NOTICE_SP 325, 'C:\ddd\ddd.txt; C:\ddd\eee.xml'



CR9295 - gea - 4/13/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
CR11631 - tp - 3/13/2020 - @@IDENTITY replaced with output clause for finging entered MESSAGE_ID
****************************************************************************************************************/
 
PRINT '' -- *~^ CR9295
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        BEGIN XX_CERIS_SEND_MISSING_NOTICE_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' -- *~^ CR9295
 
DECLARE @StatusCode             varchar(20),
        @StatusCodeDescription  varchar(60),
        @InterfaceName          varchar(50),
        @InterfaceFullName      varchar(60),
        @AllRecords             numeric(9, 0),
        @ErrorRecords           numeric(9, 0),
        @StatusMessage          varchar(240),
        @current_STATUS_RECORD_NUM int,
        @MailTo                 varchar(300),
        @MailFrom               varchar(100),
        @IMAPSReturnCode        int,
        @RecordCount            int,
        @SP_NAME                sysname,
        @email_msg_text         varchar(3000),
        @email_msg_subject      varchar(100),
        @Server_Environment		varchar(20),
        @IMAPS_error_code       integer,
        @error_msg_placeholder1 sysname,
        @error_msg_placeholder2 sysname

-- Set local constants



--if this first query returns no records
-- select parameter_value from imapsstg.dbo.XX_PROCESSING_PARAMETERS where parameter_name = 'SERVER_ENVIRONMENT'
-- the next query must be run in each environment, and its output put in the first value of the third query, then third query must be run in each environment
-- also, update 'GEORGE' as appropriate and update environment abbreviation as appropriate (DEV, TEST, PROD)
-- select max(interface_name_id)+1 from imapsstg.dbo.XX_PROCESSING_PARAMETERS <-- this gives you the value for first item in the insert, eg 143
-- insert into imapsstg.dbo.xx_processing_parameters values ('143','SERVER','SERVER_ENVIRONMENT','DEV','GEORGE',getdate(),'GEORGE',GETDATE(),NULL)

--ALSO,

--if this first query returns no records
-- select parameter_value from imapsstg.dbo.XX_PROCESSING_PARAMETERS where parameter_name = 'CERIS_MISSING_MAIL_TO'
-- update 'GEORGE' as appropriate and update MAIL_TO as appropriate (george.alvarez@us.ibm.com) Multiple addresses separated by semi-colons
-- insert into imapsstg.dbo.xx_processing_parameters values ('4','CERIS','CERIS_MISSING_MAIL_TO','george.alvarez@us.ibm.com;george.alvarez@us.ibm.com','GEORGE',getdate(),'GEORGE',GETDATE(),NULL)


PRINT 'Looking for Status Record Number'

 

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 114 : XX_CERIS_SEND_MISSING_NOTICE_SP.sql '  --CR9295
 
select  @current_STATUS_RECORD_NUM = max(STATUS_RECORD_NUM)
from    XX_IMAPS_INT_STATUS
where   interface_name='CERIS_LOAD'
and     STATUS_CODE ='COMPLETED'



PRINT 'Determine the Mail From'

 

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 128 : XX_CERIS_SEND_MISSING_NOTICE_SP.sql '  --CR9295
 
SELECT @MailFrom      = INTERFACE_SOURCE_OWNER
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE STATUS_RECORD_NUM = @current_Status_Record_Num 

PRINT 'Looking for Environment name in parameters table'

-- Find the environment
 

 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 141 : XX_CERIS_SEND_MISSING_NOTICE_SP.sql '  --CR9295
 
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

-- Find the mail to
 

 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 167 : XX_CERIS_SEND_MISSING_NOTICE_SP.sql '  --CR9295
 
SELECT @mailto = PARAMETER_VALUE
FROM   dbo.XX_PROCESSING_PARAMETERS
WHERE  parameter_name = 'CERIS_MISSING_MAIL_TO'

SET @out_SystemErrorCode = @@ERROR

-- PRINT 'ERR IS ' +  @out_SystemErrorCode + ' and server is ' + @Server_Environment

--@out_SystemErrorCode > 0 OR

IF @out_SystemErrorCode > 0 OR @mailto is NULL
   BEGIN
      -- Error No. 204: Attempt to identify recipients for bad Workday records failed.
      SET @IMAPS_error_code = 204
      SET @error_msg_placeholder1 = 'identify'
      SET @error_msg_placeholder2 = 'recipients for bad WORKDAY records'
      GOTO ErrorProcessing
   END


-- Prepare column values to be used by the INSERT statement

PRINT 'Setting email message'

SET @email_msg_text = 'This message was generated by the IMAPS financial system resulting from execution of the WORKDAY'
                      + ' interface. The WORKDAY file that has just been processed contained records with missing information '
                      + ' that is critical to the success of the interface process.  These records were set aside, and remain unprocessed.'
                      + ' You may find these records in the Cognos Missing Workday Data report.'
                      + 'Please do not reply to this message. Address your requests to ' + @MailFrom
                      + '. Message ID '

PRINT 'Setting email subject'

SET @email_msg_subject = @Server_Environment + ' Missing Workday Data Notification ' 

PRINT 'Inserting Email in table'

-- Insert a new record in mail table
 
-- Table variable to hold just one return id of the message
 
 DECLARE	@MESSAGE_ID  table (  ID INT);
 DECLARE    @MESSAGE_ID_OUTPUT int
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 211 : XX_CERIS_SEND_MISSING_NOTICE_SP.sql '  --CR9295
 
INSERT INTO dbo.XX_IMAPS_MAIL_OUT
   (MESSAGE_TEXT, MESSAGE_SUBJECT, MAIL_TO_ADDRESS, STATUS_RECORD_NUM)
   OUTPUT INSERTED.MESSAGE_ID INTO  @MESSAGE_ID 
   VALUES(@email_msg_text, @email_msg_subject, @MailTo, @current_Status_Record_Num)

SET @out_SystemErrorCode = @@ERROR
	
IF @out_SystemErrorCode > 0
   BEGIN
      -- Error No. 204: Attempt to insert a record in table XX_IMAPS_MAIL_OUT failed.
      SET @IMAPS_error_code = 204
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'a record in table XX_IMAPS_MAIL_OUT'
      GOTO ErrorProcessing
   END

PRINT 'Updating email table with message_id'

-- Update the XX_IMAPS_MAIL_OUT record just inserted above with its MESSAGE_ID generated upon insert	
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 235 : XX_CERIS_SEND_MISSING_NOTICE_SP.sql '  --CR9295
SELECT TOP 1  @MESSAGE_ID_OUTPUT = ID from @MESSAGE_ID

UPDATE dbo.XX_IMAPS_MAIL_OUT 
   SET MESSAGE_TEXT = MESSAGE_TEXT + CAST( MESSAGE_ID AS VARCHAR(10))
 WHERE MESSAGE_ID = @MESSAGE_ID_OUTPUT

SELECT @out_SystemErrorCode = @@ERROR, @RecordCount = @@ROWCOUNT

IF @out_SystemErrorCode > 0
   BEGIN
      -- Error No. 204: Attempt to update a record in table XX_IMAPS_MAIL_OUT failed.
      SET @IMAPS_error_code = 204
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'a record in table XX_IMAPS_MAIL_OUT'
      GOTO ErrorProcessing
   END

IF @RecordCount = 0
   BEGIN
      -- Error No. 204: Attempt to update a record in table XX_IMAPS_MAIL_OUT failed.
      SET @IMAPS_error_code = 204
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'a record in table XX_IMAPS_MAIL_OUT with an invalid MESSAGE_ID value'
      SET @out_SystemErrorCode = NULL
      GOTO ErrorProcessing
   END

PRINT 'Find the email here: SELECT * FROM IMAPSSTG.DBO.XX_IMAPS_MAIL_OUT WHERE MESSAGE_ID =' + CAST( @MESSAGE_ID_OUTPUT AS VARCHAR)




 
PRINT '' -- *~^ CR9295
PRINT '*~^*************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF  XX_CERIS_SEND_MISSING_NOTICE_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' -- *~^ CR9295
 
RETURN 0

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



USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_SABRIX_EMAIL_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 





CREATE PROCEDURE [dbo].[XX_SABRIX_EMAIL_SP]
(
@in_STATUS_RECORD_NUM      integer,
@out_SQLServer_error_code  integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION    varchar(255) = NULL OUTPUT
)
AS
/********************************************************************************************************
Name:       XX_SABRIX_EMAIL_SP
Author:     KM, HVT
Created:    02/15/2015
Purpose:    Email notification of Sent Invoices and invoice validation errors, if any, to customers.
            This SP does not use XX_SEND_STATUS_MAIL_SP. It directly inserts a XX_IMAPS_MAIL_OUT record.
            As of 10364, it does execute XX_SEND_STATUS_MAIL_SP to send a transaction file
            Called by: XX_SABRIX_RUN_INTERFACE_SP
Notes:

CR9449      Add new control point for GLIM file FTP
            12/14/2017 GEA Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
CR9449 - gea - 1/24/2018 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
CR10364 - 08/08/2018 - Inserted execution of XX_SEND_STATUS_MAIL_SP to send transaction file
                     - Added Status Record Number to email 
DR10839 - gea 1/24/2019 - can't mail attachements in prod                    
********************************************************************************************************/


DECLARE @CMD					  varchar(600),
		@SP_NAME                  sysname,
        @SABRIX_INTERFACE_NAME    varchar(50),
        @INT_SOURCE_OWNER         varchar(100),
        @INT_DEST_OWNER           varchar(300),
        @MAIL_TEXT                varchar(3000),
        @MAIL_SUBJECT             varchar(100),
        @FTP_DIR				  varchar(100),
		@LOG_DIR				  varchar(100),
        @TRX_FILE				  varchar(100),
        @NUM_INVCS                integer,
        @TOTAL_CCS                decimal(14, 2),
        @TOTAL_FDS                decimal(14, 2),
        @TOTAL_CSP                decimal(14, 2),
        @GLIM_TOT			      decimal(14, 2),
        @LINES					  integer,
        @SABR_CNT				  integer,
        @CCS2_CNT				  integer,
        @CCS2_AMT			      decimal(14, 2),        
        @SABR_REV				  decimal(14, 2),
        @SABR_TAX				  decimal(14, 2),
        @CTRL_PT4_RUN_FLAG        varchar(1),
        @SQLServer_error_code     integer,
        @IMAPS_error_code         integer,
        @error_msg_placeholder1   sysname,
        @error_msg_placeholder2   sysname,
        @row_count                integer,
        @Server_Environment	  varchar(20),
        @rtn_code				  integer

-- Set local constants
 
 
 
PRINT '' --CR9449 *~^
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_SABRIX_EMAIL_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^
-- *~^
SET @SP_NAME = 'XX_SABRIX_EMAIL_SP'
SET @SABRIX_INTERFACE_NAME = 'SABRIX'

PRINT 'Status Record Number passed in is ' + cast(@in_Status_Record_Num as varchar(20))

-- the third query must be run in each environment
-- select max(interface_name_id)+1 from imapsstg.dbo.XX_PROCESSING_PARAMETERS <-- this gives you the value for first item in the insert
-- insert into imapsstg.dbo.xx_processing_parameters values ('143','SERVER','SERVER_ENVIRONMENT','IMAPS','GEORGE',getdate(),'GEORGE',GETDATE(),NULL)

 PRINT 'Looking for Environment name in parameters table'

-- Find the environment
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 88 : XX_SABRIX_EMAIL_SP.sql '  --CR9449
 
SELECT @Server_Environment = PARAMETER_VALUE
FROM   dbo.XX_PROCESSING_PARAMETERS
WHERE  parameter_name = 'SERVER_ENVIRONMENT'

-- Initialize local variables
SET @IMAPS_error_code = 204 -- Attempt to %1 %2 failed.

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 100 : XX_SABRIX_EMAIL_SP.sql '  --CR9449
 
SELECT @INT_SOURCE_OWNER = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'INT_SRC_OWNER'
   AND INTERFACE_NAME_CD = @SABRIX_INTERFACE_NAME

 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 109 : XX_SABRIX_EMAIL_SP.sql '  --CR9449
 
SELECT @INT_DEST_OWNER = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'INT_DEST_OWNER'
   AND INTERFACE_NAME_CD = @SABRIX_INTERFACE_NAME

SELECT @LOG_DIR = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'JAVA_LOG_DIR'
   AND INTERFACE_NAME_CD = @SABRIX_INTERFACE_NAME

  
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 120 : XX_SABRIX_EMAIL_SP.sql '  --CR9449

-- SABRIX TOTALS

select @SABR_CNT = cast(record_count as int), @SABR_REV=CAST(rev as decimal(14,2))/100, 
@SABR_TAX =CAST(state_tax as decimal(14,2))/100 + CAST(county_tax as decimal(14,2))/100 + CAST(city_tax as decimal(14,2))/100 
from imapsstg.dbo.XX_SABRIX_INTERFACE_HDR_VW

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 131 : XX_SABRIX_EMAIL_SP.sql '  --CR9449

/*
 * IMPORTANT: Ensure that @MAIL_TEXT is not NULL is necessary to prevent the Microsoft SQL Server email scheduler
 * from being disabled upon reading a XX_IMAPS_MAIL_OUT record whose column MESSAGE_TEXT's value is NULL.
 */

-- Email Notification of Sent Invoices to DESTINATION SYSTEM OWNER
SET @MAIL_SUBJECT = @Server_Environment + ' IMAPS TO SABRIX Transmission Notification'  

IF @NUM_INVCS = 0 AND @CTRL_PT4_RUN_FLAG = 'N'
   BEGIN
      SET @MAIL_TEXT = 'No New Invoices Passed Validations ... No Files Created/Sent (Control point 4 was not executed)'
      PRINT 'ERROR: ' + @MAIL_TEXT
   END
ELSE
   BEGIN
-- CR9449 Begin
      PRINT '@NUM_INVCS > 0: New Invoices Passed Validations ... Files Created/Sent'
-- CR9449 End


      SET @MAIL_TEXT = 'Totals for SABRIX are:  Total Revenue = ' + cast(@SABR_REV as varchar(16))
                       + ', Total Sales Tax = ' + cast(@SABR_TAX as varchar(16)) + ', Number of Invoices = ' +  cast(@SABR_CNT as varchar(16))                 
                       + CHAR(13) + CHAR(13)
                       + 'Status Record Number for this run is ' + CAST(@in_STATUS_RECORD_NUM as varchar(10)) 
					   + '  and Message ID is '
      END

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 168 : XX_SABRIX_EMAIL_SP.sql '  --CR9449

-- CR10364
 -- GET THE LOCATION OF THE TRX FILE
 
 SELECT @FTP_DIR = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'SABRIX'
   AND PARAMETER_NAME = 'FTP_DIR'


 -- GET THE NAME OF THE TRX FILE
 SELECT @TRX_FILE = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'SABRIX_TRX_FILE'
   AND INTERFACE_NAME_CD = @SABRIX_INTERFACE_NAME


-- send the SABRIX transaction file to people who need it; includes tax team
set @TRX_FILE = @FTP_DIR + @TRX_FILE

PRINT 'Attachment passed in is ' + @TRX_FILE


INSERT INTO dbo.XX_IMAPS_MAIL_OUT
   (MESSAGE_TEXT, MESSAGE_SUBJECT, MAIL_TO_ADDRESS, ATTACHMENTS, STATUS_RECORD_NUM, CREATE_DT)
   SELECT @MAIL_TEXT, @MAIL_SUBJECT, @INT_DEST_OWNER, @TRX_FILE, @in_STATUS_RECORD_NUM, CURRENT_TIMESTAMP

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 135 : XX_SABRIX_EMAIL_SP.sql '  --CR9449



-- DELETE THE FTP SUCCESS OR FAILURE FILE FROM THE FTP FOLDER
   PRINT 'NEXT COMMAND DELETES FTP SUCCESS/FAILURE FILE IN FTP FOLDER.'
   --SET @CMD = 'ERASE /Q /F ' + @TRX_FILE -- don't delete the attachment!
   SET @CMD = 'ERASE /Q /F ' + @LOG_DIR + '*.ftp'
   PRINT @CMD
   EXEC @rtn_code = master.dbo.xp_cmdshell @CMD  

PRINT 'Mail record created. Query: select * from imapsstg.dbo.XX_IMAPS_MAIL_OUT WHERE STATUS_RECORD_NUM = ' + cast(@in_Status_Record_Num as varchar(10));
-- END 10364


SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to insert a record (Transmission Notification) into table XX_IMAPS_MAIL_OUT failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'a record (Transmission Notification) into table XX_IMAPS_MAIL_OUT'
      GOTO BL_ERROR_HANDLER
   END

-- This step is conditional. It builds the message text for the second notification email.
-- If Errors exist, SEND Notification to SOURCE SYSTEM OWNER and Email Notification of Sent Invoices to DESTINATION SYSTEM
-- Table XX_SABRIX_INV_OUTERROR is truncated in XX_AR_LOAD_SUM_SP and re-populated in many SPs: XX_AR_LOAD_DTL, XX_AR_LOAD_SENT_SP, XX_AR_VALIDATE_CMR_NUM_SP
 
 
 
SELECT @row_count = COUNT(1) FROM dbo.XX_IMAPS_INV_ERROR
IF @row_count <> 0
   BEGIN
      -- This SP does not use XX_SEND_STATUS_MAIL_SP. It directly inserts a XX_IMAPS_MAIL_OUT record.
      SET @MAIL_SUBJECT = @Server_Environment + ' IMAPS TO SABRIX ERROR Notification'
      SET @MAIL_TEXT = 'SABRIX has successfully completed, but has also detected invoices that contain errors preventing their transmission to SABRIX.'
		    + CHAR(13) + CHAR(13)
			+ 'Table XX_IMAPS_INV_ERROR contains ' + CAST(@ROW_COUNT AS VARCHAR(5)) +  ' invoices with validation errors. Please make the necessary corrections.'
			+ CHAR(13) + CHAR(13) + 'Message ID = 
			'
      PRINT '@MAIL_TEXT = ' + @MAIL_TEXT

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 202 : XX_SABRIX_EMAIL_SP.sql '  --CR9449
 
      INSERT INTO dbo.XX_IMAPS_MAIL_OUT
         (MESSAGE_TEXT, MESSAGE_SUBJECT, MAIL_TO_ADDRESS, STATUS_RECORD_NUM, CREATE_DT)
         SELECT @MAIL_TEXT, @MAIL_SUBJECT, @INT_SOURCE_OWNER, @in_STATUS_RECORD_NUM, CURRENT_TIMESTAMP

      SET @SQLServer_error_code = @@ERROR

      IF @SQLServer_error_code <> 0
         BEGIN
            -- Attempt to insert a record (Invoice Errors) into table XX_IMAPS_MAIL_OUT failed.
            SET @error_msg_placeholder1 = 'insert'
            SET @error_msg_placeholder2 = 'a record (Invoice Errors) into table XX_IMAPS_MAIL_OUT'
            GOTO BL_ERROR_HANDLER
         END
   END

PRINT '' --CR9449 *~^
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF XX_SABRIX_EMAIL_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^
  
 
RETURN(0)

BL_ERROR_HANDLER:

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_code,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(99)




 

 

 

 

 

 

 

GO
 


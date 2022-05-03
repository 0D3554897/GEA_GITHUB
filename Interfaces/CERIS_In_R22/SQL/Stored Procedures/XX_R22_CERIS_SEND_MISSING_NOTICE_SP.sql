USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CERIS_SEND_MISSING_NOTICE_SP]    Script Date: 03/10/2017 09:41:59 ******/


IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_R22_CERIS_SEND_MISSING_NOTICE_SP]') AND type in (N'P', N'PC'))
BEGIN
/**************************************************************************************************************
This functionality was replaced with mail from java program

Name:       XX_R22_CERIS_SEND_MISSING_NOTICE_SP
Author:     George Alvarez, borrowing lots of code from Tatiana Perova (CR9296)
Created:    04/07/2017
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

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 52 : XX_R22_CERIS_SEND_MISSING_NOTICE_SP.sql '  --CR9296
 
            EXEC dbo.XX_R22_CERIS_SEND_MISSING_NOTICE_SP 325, 'C:\ddd\ddd.txt; C:\ddd\eee.xml'


CR9296 - gea - 4/6/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
CR9296 - gea - 4/25/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
CR11633 - tp - 3/13/2020 - @@IDENTITY replaced with output clause for finging entered MESSAGE_ID and finally removal of the procedure
****************************************************************************************************************/
DROP PROCEDURE [dbo].[XX_R22_CERIS_SEND_MISSING_NOTICE_SP] 
END
GO


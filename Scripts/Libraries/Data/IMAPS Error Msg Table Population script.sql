/*
 * This is the script to populate the common table for IMAPS error messages XX_INT_ERROR_MESSAGE.

 * IMPORTANT: This script must be run after the table XX_LOOKUP_DETAIL has been populated.
 *
 * XX_INT_ERROR_MESSAGE records are used with stored procedure XX_ERROR_MSG_DETAIL.
 * See XX_ERROR_MSG_DETAIL for usage instructions.
 *
 * Severity level is not implemented. Consider using error type.
 *
 * Review the existing records below that might satisfy your needs. Add new records as needed.
 *
 * If the error message is not immediately clear to the user in terms of usage, please provide explanation and/or example
 * in the form of Transact-SQL comments.
 *
 * Column ERROR_TYPE's values come from XX_LOOKUP_DETAIL.LOOKUP_ID.
 *
 * Suggested IMAPS error number groupings (expandable, non-enforceable) follow.
 *
 * 100s - IMAPS-specific Transact-SQL syntax errors
 * 200s - Generic errors whose text possesses placeholders
 * 300s - IMAPS database data, resource errors
 * 400s - IMAPS mass IO errors (or information)
 * 500s - IMAPS processing errors (or information)
 * 600s - Costpoint-related errors
 * 700s - IMAPS's version of SQL Server database transaction errors (IMAPS's attempt to mask SQL Server error)
 *
 * NOTES: The value assigned to column ERROR_MESSAGE always ends with a period character.
 */

--truncate the table before each scrip run
truncate table dbo.XX_INT_ERROR_MESSAGE
GO
-- Series 100s
insert into dbo.XX_INT_ERROR_MESSAGE values(100, 33, NULL, 'Missing required input parameter(s).', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(101, 33, NULL, 'The number of user-supplied placeholder values does not match the number of possible placeholders found in the error message text.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(102, 33, NULL, 'The placeholders in the error message text are out of sequential order.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(103, 33, NULL, 'Repeated placeholders in the error message text.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(104, 33, NULL, 'At least an input value for XX_LOOKUP_DETAIL.LOOKUP_ID or XX_LOOKUP_DETAIL.APPLICATION_CODE, or a pair of input values for both XX_LOOKUP_DOMAIN.DOMAIN_CONSTANT and XX_LOOKUP_DOMAIN.PRESENTATION_ORDER must be supplied.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(105, 33, NULL, 'The supplied input value for XX_LOOKUP_DETAIL.DOMAIN_CONSTANT is invalid or does not exist.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(106, 33, NULL, 'The supplied input value for XX_LOOKUP_DETAIL.PRESENTATION_ORDER is invalid or does not exist.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(107, 33, NULL, 'The supplied input value for XX_LOOKUP_DETAIL.APPLICATION_CODE is invalid or does not exist.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(108, 33, NULL, 'The supplied input value for XX_LOOKUP_DETAIL.LOOKUP_ID is invalid or does not exist.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(109, 32, NULL, 'Placeholder replacement values are supplied for an error or information message that does not contain placeholders.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(110, 33, NULL, 'The number of user-specified placeholder values passed does not match the number of possible placeholders found in the error message text.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(111, 33, NULL, 'Error codes 101, 102, 103, 109, 110, 111 are reserved for internal use.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(112, 34, NULL, 'Missing processing parameter data for %1 interface execution.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go

-- Series 200s
insert into dbo.XX_INT_ERROR_MESSAGE values(200, 33, NULL, '%1 is invalid or does not exist.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(201, 34, NULL, 'The %1 record does not exist for the user-supplied value of %2.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(202, 33, NULL, '%1 is inactive.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(203, 33, NULL, 'Missing required %1 for %2.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
-- Attempt to INSERT a XX_TABLE_NAME record failed.
insert into dbo.XX_INT_ERROR_MESSAGE values(204, 33, NULL, 'Attempt to %1 %2 failed.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(205, 33, NULL, 'Please limit the number of %1 to %2.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(206, 31, NULL, 'Interface processing is successful at the completion of %1.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(207, 32, NULL, 'No %1 records that %2 exist.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(208, 32, NULL, 'The last interface job has resulted in %1 status. The current %2 interface job cannot be run at this time.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go

-- Series 300s
insert into dbo.XX_INT_ERROR_MESSAGE values(300, 34, NULL, 'Missing required eTime interface table(s).', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(301, 34, NULL, 'An error has occured. Please contact system administrator.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(302, 34, NULL, 'Attempt to %1 IMAPS interface table %2 failed.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(303, 34, NULL, 'Attempt to send %1 e-mail to %2 failed.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(304, 33, NULL, 'Mail notification record could not be created due to invalid input value for STATUS_RECORD_NUM.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go


-- Series 400s
insert into dbo.XX_INT_ERROR_MESSAGE values(400, 34, NULL, 'Attempt to BULK INSERT into table %1 failed.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(402, 34, NULL, 'Attempt to create input file for Costpoint timesheet preprocessor via bcp failed.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(403, 32, NULL, 'Processing of the last interface job found the source input file to have been processed successfully at least once before.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go

-- Series 500s
insert into dbo.XX_INT_ERROR_MESSAGE values(500, 31, NULL, 'There are no data available to generate fixed-format timesheet preprocessor input file.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(501, 33, NULL, 'The input file has been processed successfully at least once before.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(502, 32, NULL, 'Footer record count does not match detail record count.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(503, 31, NULL, 'The %1 input file has been validated successfully. Interface processing is initiated.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(520, 32, NULL, 'PCLAIM Interface processing resumed before Costpoint AP preprocessor finished stage 4.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(521, 32, NULL, 'PCLAIM Interface input data provided for the current interface run were already archived.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(522, 33, NULL, 'Total record count or total charged hours in the footer record is not in sync with that of the detail records of the input file.', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go

--PCLAIM changes 2005/09/16
INSERT INTO [dbo].[XX_INT_ERROR_MESSAGE]([ERROR_CODE], [ERROR_TYPE], 
[ERROR_SEVERITY], [ERROR_MESSAGE], [ERROR_SOURCE], [CREATED_BY], [CREATED_DATE], 
[MODIFIED_BY], [MODIFIED_DATE])
VALUES(523, 41, NULL, 'More than one week labor data is present in input file as regular records. 
Split input file by week or change previous week’s record type to "C".', 
'IMAPS execution environment', 'IMAPSStg', GETDATE(), NULL, NULL)

GO

-- Series 600s
insert into dbo.XX_INT_ERROR_MESSAGE values(600, 34, NULL, 'Costpoint process ID for eTime interface does not exist (see DELTEK.PROCESS_HDR.PROCESS_ID).', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(601, 34, NULL, 'Costpoint process queue ID for eTime interface does not exist (see DELTEK.PROCESS_QUEUE.PROC_QUEUE_ID).', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(602, 34, NULL, 'Costpoint process server for eTime interface is inactive (see DELTEK.PROCESS_SERVER.PROC_SERVER_ID).', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(603, 34, NULL, 'Attempt to update Costpoint process queue failed (see DELTEK.PROCESS_QUE_ENTRY).', 'IMAPS execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go
insert into dbo.XX_INT_ERROR_MESSAGE values(604, 32, NULL, 'The last Costpoint %1 preprocessor job failed. The current %2 interface job cannot be run at this time.', 'Costpoint execution environment', SUSER_SNAME(), GETDATE(), NULL, NULL)
go

USE [IMAPSSTG]
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_GET_SQLSERVER_SYSMSG]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   DROP PROCEDURE [dbo].[XX_GET_SQLSERVER_SYSMSG]
GO

CREATE PROCEDURE dbo.XX_GET_SQLSERVER_SYSMSG
(
@in_SQLServer_error_num  integer,
@out_SQLServer_msg_text  varchar(275) = NULL OUTPUT
) 
AS

/************************************************************************************************
Name:       XX_GET_SQLSERVER_SYSMSG
Author:     HVT
Created:    07/27/2005
Purpose:    Accept a SQL Server error number, retrieve its description, and return a formatted
            error message.
            Called by XX_ERROR_MSG_DETAIL.

Parameters: @in_SQLServer_error_num, @out_SQLServer_msg_text
Result Set: None

Notes:

Defect 982  05/11/2006 - When the Microsoft SQL Server error number cannot be captured, this SP
            is not called by XX_ERROR_MSG_DETAIL. E.g., when the utility bulk copy is used, an
            error that causes the insert operation to fail cannot be captured.

CR-11604    12/03/2019 Specify U.S. English language for Microsoft SQL Server error messages.
*************************************************************************************************/

DECLARE @SP_NAME              sysname,
        @SS_MSGLANGID_ENGLISH integer,       -- CR-11604
        @sys_error_msg        nvarchar(255),
        @row_count            integer

-- Set local constants
SELECT @SP_NAME = 'XX_GET_SQLSERVER_SYSMSG'

-- CR-11604 Begin

-- Retrieve system data
SELECT @SS_MSGLANGID_ENGLISH = CAST(PARAMETER_VALUE as INTEGER)
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'SS_MSGLANGID_ENGLISH'
   AND INTERFACE_NAME_CD = 'UTILITY'

SELECT @sys_error_msg = description
  FROM master.dbo.sysmessages
 WHERE error = @in_SQLServer_error_num
   AND msglangid = @SS_MSGLANGID_ENGLISH

-- CR-11604 End

SET @row_count = @@ROWCOUNT

IF @row_count <> 0
   SET @out_SQLServer_msg_text = 'SQL Server error ' + CONVERT(varchar(6), @in_SQLServer_error_num) + ': ' + @sys_error_msg

RETURN(0)

GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_AR_CCIS_ARCHIVE_SP    Script Date: 10/04/2006 9:58:23 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CCIS_ARCHIVE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_AR_CCIS_ARCHIVE_SP]
GO







CREATE PROCEDURE dbo.XX_AR_CCIS_ARCHIVE_SP
(
@in_STATUS_RECORD_NUM     integer,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS
/****************************************************************************************************
Name:       XX_AR_CCIS_ARCHIVE_SP
Author:      KM
Created:    12/2005
Purpose:    ARCHIVES THE CCIS
Parameters: 
Result Set: None
Notes:

exec xx_ar_ccis_archive_sp
	@in_STATUS_RECORD_NUM = 86


****************************************************************************************************/
BEGIN

DECLARE	@SP_NAME           	sysname,
        @IMAPS_error_number     integer,
        @SQLServer_error_code   integer,
        @row_count              integer,
        @error_msg_placeholder1 sysname,
        @error_msg_placeholder2 sysname,
        @INTERFACE_NAME	 	sysname

-- set local constants
SET @SP_NAME = 'XX_AR_CCIS_ARCHIVE_SP'
SET @INTERFACE_NAME = 'AR_COLLECTION'

--1. ATTEMPT TO ARCHIVE THE CCIS DATA FOR NEXT INTERFACE RUN
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'INSERT INTO'
SET @error_msg_placeholder2 = 'DBO.XX_AR_CCIS_ACTIV_ARCH'

INSERT INTO DBO.XX_AR_CCIS_ACTIV_ARCH
(STATUS_RECORD_NUM, 
 INVNO, INVC_DT, COMPANY, CUSTNO, CUSTNAME, CHECKDATE, CLEARDATE, ENTRYDATE, GROSSINV,
 TAXAMT, LPFAMT, ACTIVIN, ACTINMIN, ACTIVOUT, ACTOUTMIN, CHECKNO, DIRDEBIT, PPFLAG,
 PPD, REINSTATED, TIME_STAMP, PROCESSOR, SUBBATCH)
SELECT 
 @in_STATUS_RECORD_NUM, 
 INVNO, INVC_DT, COMPANY, CUSTNO, CUSTNAME, CHECKDATE, CLEARDATE, ENTRYDATE, GROSSINV,
 TAXAMT, LPFAMT, ACTIVIN, ACTINMIN, ACTIVOUT, ACTOUTMIN, CHECKNO, DIRDEBIT, PPFLAG,
 PPD, REINSTATED, TIME_STAMP, PROCESSOR, SUBBATCH
FROM DBO.XX_AR_CCIS_ACTIVITY
WHERE ACTIV_KEY NOT IN (SELECT ACTIV_KEY FROM DBO.XX_AR_CCIS_CLOSED_INVOICES WHERE VALIDATED = 'N')

IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

--2. ATTEMPT TO ARCHIVE THE CCIS DATA FILE
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'MOVE CCIS DATA FILES'
SET @error_msg_placeholder2 = 'TO THE ARCHIVE FOLDER'

DECLARE @ret_code int,
	@CCIS_ACTIV_FILE sysname,
	@CCIS_OPEN_FILE sysname,
	@CCIS_REMARKS_FILE sysname,
	@ARCH_DIR sysname,
	@CMD sysname

SELECT  @CCIS_ACTIV_FILE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'CCIS_ACTIV_FILE'
AND 	INTERFACE_NAME_CD = @INTERFACE_NAME

SELECT  @CCIS_OPEN_FILE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'CCIS_OPEN_FILE'
AND 	INTERFACE_NAME_CD = @INTERFACE_NAME

SELECT  @CCIS_REMARKS_FILE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'CCIS_REMARKS_FILE'
AND 	INTERFACE_NAME_CD = @INTERFACE_NAME

SELECT  @ARCH_DIR = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'ARCH_DIR'
AND 	INTERFACE_NAME_CD = @INTERFACE_NAME


SET	@CMD = 'MOVE ' + @CCIS_ACTIV_FILE + ' ' + @ARCH_DIR + CAST(@in_STATUS_RECORD_NUM as varchar(30)) + '_CCIS_ACTIVITY.txt'
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
PRINT @CMD

IF @ret_code <> 0 GOTO BL_ERROR_HANDLER

SET	@CMD = 'MOVE ' + @CCIS_OPEN_FILE + ' ' + @ARCH_DIR + CAST(@in_STATUS_RECORD_NUM as varchar(30)) + '_CCIS_OPEN_BALANCES.txt'
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
PRINT @CMD

IF @ret_code <> 0 GOTO BL_ERROR_HANDLER

SET	@CMD = 'MOVE ' + @CCIS_REMARKS_FILE + ' ' + @ARCH_DIR + CAST(@in_STATUS_RECORD_NUM as varchar(30)) + '_CCIS_OPEN_REMARKS.txt'
EXEC @ret_code = master.dbo.xp_cmdshell @CMD
PRINT @CMD

IF @ret_code <> 0 GOTO BL_ERROR_HANDLER


RETURN(0)


BL_ERROR_HANDLER:

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_number,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)


END








GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


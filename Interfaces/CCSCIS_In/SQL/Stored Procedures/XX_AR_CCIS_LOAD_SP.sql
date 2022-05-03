USE [IMAPSStg]
GO

IF EXISTS (SELECT * FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[DBO].[XX_AR_CCIS_LOAD_SP]') AND OBJECTPROPERTY(ID, N'ISPROCEDURE') = 1)
   DROP PROCEDURE [DBO].[XX_AR_CCIS_LOAD_SP]
GO

CREATE PROCEDURE [dbo].[XX_AR_CCIS_LOAD_SP]
(
@in_STATUS_RECORD_NUM     integer,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS
/*******************************************************************************************************
Name:       XX_AR_CCIS_LOAD_SP
Author:     KM
Created:    12/2005
Purpose:    This stored procedure loads the xx_ar_ccis_activity table from the ccis inbound file.
Parameters: 
Result Set: 
Notes:      CR-11452 04/23/2020 Call XX_EXEC_BCP_SHELL_CMD_OSUSER to work with Microsoft ODBC Driver 13.
********************************************************************************************************/

BEGIN

DECLARE	@SP_NAME                 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @row_count               integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
        @INTERFACE_NAME          sysname,
        @CCIS_ACTIV_FILE         sysname,
        @CCIS_ACTIV_FORMAT       sysname,
        @CCIS_OPEN_FILE          sysname,
        @CCIS_OPEN_FORMAT        sysname,
        @CCIS_REMARKS_FILE       sysname,
        @CCIS_REMARKS_FORMAT     sysname,
        @IMAPS_DB_NAME           sysname,
        @IMAPS_SCHEMA_OWNER      sysname,
        @BCP_ERROR_LOG_FILE      sysname,
        @ret_code                integer,
        @FTR_REC_CNT             integer,
        @REC_CNT                 integer

-- Set local constants
SET @INTERFACE_NAME = 'AR_COLLECTION'
SET @SP_NAME = 'XX_AR_CCIS_LOAD_SP'

-- 1. TRUNCATE TABLE
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'truncate tables XX_AR_CCIS_ACTIVITY,'
SET @error_msg_placeholder2 = 'XX_AR_CCIS_OPEN_BALANCES, and XX_AR_CCIS_OPEN_REMARKS'

TRUNCATE TABLE dbo.XX_AR_CCIS_ACTIVITY
TRUNCATE TABLE dbo.XX_AR_CCIS_OPEN_BALANCES
TRUNCATE TABLE dbo.XX_AR_CCIS_OPEN_REMARKS

IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

-- 2. LOAD ACTIVITY FILE TO TABLE
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'load CCIS file'
SET @error_msg_placeholder2 = 'to table XX_AR_CCIS_ACTIVITY'

SELECT  @CCIS_ACTIV_FILE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'CCIS_ACTIV_FILE'
AND 	INTERFACE_NAME_CD = @INTERFACE_NAME

SELECT  @CCIS_ACTIV_FORMAT = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'CCIS_ACTIV_FORMAT'
AND 	INTERFACE_NAME_CD = @INTERFACE_NAME

SELECT  @IMAPS_DB_NAME = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'IMAPS_DB_NAME'
AND 	INTERFACE_NAME_CD = @INTERFACE_NAME

SELECT  @IMAPS_SCHEMA_OWNER = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'IMAPS_SCHEMA_OWNER'
AND 	INTERFACE_NAME_CD = @INTERFACE_NAME

-- CR-11452 Begin
SELECT @BCP_ERROR_LOG_FILE = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'BCP_ERROR_LOG_FILE'
   AND INTERFACE_NAME_CD = @INTERFACE_NAME

-- bcp insert common stored procedure
EXEC @ret_code = dbo.XX_EXEC_BCP_SHELL_CMD_OSUSER
   @in_IMAPS_db_name       = @IMAPS_DB_NAME,
   @in_IMAPS_table_owner   = @IMAPS_SCHEMA_OWNER,
   @in_Dest_table          = 'XX_AR_CCIS_ACTIVITY',
   @in_format_file         = @CCIS_ACTIV_FORMAT,
   @in_input_file          = @CCIS_ACTIV_FILE,
   @in_error_log_file      = @BCP_ERROR_LOG_FILE,
   @out_STATUS_DESCRIPTION = @error_msg_placeholder1
-- CR-11452 End

IF @ret_code <> 0 GOTO BL_ERROR_HANDLER

-- 3. LOAD BALANCE FILE TO TABLE
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'load CCIS file'
SET @error_msg_placeholder2 = 'to table XX_AR_CCIS_OPEN_BALANCES'

SELECT  @CCIS_OPEN_FILE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'CCIS_OPEN_FILE'
AND 	INTERFACE_NAME_CD = @INTERFACE_NAME

SELECT  @CCIS_OPEN_FORMAT = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'CCIS_OPEN_FORMAT'
AND 	INTERFACE_NAME_CD = @INTERFACE_NAME

-- CR-11452 Begin
-- bcp insert common stored procedure
EXEC @ret_code = dbo.XX_EXEC_BCP_SHELL_CMD_OSUSER
   @in_IMAPS_db_name       = @IMAPS_DB_NAME,
   @in_IMAPS_table_owner   = @IMAPS_SCHEMA_OWNER,
   @in_Dest_table          = 'XX_AR_CCIS_OPEN_BALANCES',
   @in_format_file         = @CCIS_OPEN_FORMAT,
   @in_input_file          = @CCIS_OPEN_FILE,
   @in_error_log_file      = @BCP_ERROR_LOG_FILE,
   @out_STATUS_DESCRIPTION = @error_msg_placeholder1
-- CR-11452 End

IF @ret_code <> 0 GOTO BL_ERROR_HANDLER

--4. UPDATE VALIDATED FLAG TO 'N'
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'UPDATE VALIDATED COLUMN IN'
SET @error_msg_placeholder2 = 'table XX_AR_CCIS_OPEN_BALANCES'

UPDATE DBO.XX_AR_CCIS_OPEN_BALANCES
   SET VALIDATED = 'N'
 WHERE VALIDATED IS NULL

IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

-- 5. LOAD REMARKS FILE TO TABLE
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'load CCIS file'
SET @error_msg_placeholder2 = 'to table XX_AR_CCIS_OPEN_REMARKS'

SELECT  @CCIS_REMARKS_FILE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'CCIS_REMARKS_FILE'
AND 	INTERFACE_NAME_CD = @INTERFACE_NAME

SELECT  @CCIS_REMARKS_FORMAT = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'CCIS_REMARKS_FORMAT'
AND 	INTERFACE_NAME_CD = @INTERFACE_NAME

-- CR-11452 Begin
-- bcp insert common stored procedure
EXEC @ret_code = dbo.XX_EXEC_BCP_SHELL_CMD_OSUSER
   @in_IMAPS_db_name       = @IMAPS_DB_NAME,
   @in_IMAPS_table_owner   = @IMAPS_SCHEMA_OWNER,
   @in_Dest_table          = 'XX_AR_CCIS_OPEN_REMARKS',
   @in_format_file         = @CCIS_REMARKS_FORMAT,
   @in_input_file          = @CCIS_REMARKS_FILE,
   @in_error_log_file      = @BCP_ERROR_LOG_FILE,
   @out_STATUS_DESCRIPTION = @error_msg_placeholder1
-- CR-11452 End

IF @ret_code <> 0 GOTO BL_ERROR_HANDLER


select * from xx_ar_ccis_open_remarks
-- CHANGE KM 04/10/2006
-- ACTIVITY FILE IS TOO COMPLEX/UNPREDICTABLE TO MAKE ASSUMPTIONS ABOUT
-- WE WILL BASE EVERYTHING ON THE OPEN FILE
/*
--6. VALIDATE FILES BY ENSURING 
--   THAT NO OPEN INVOICES ARE ALSO CLOSED INVOICES
SET @IMAPS_error_number = 210 -- %1 failed validation due to %2.
SET @error_msg_placeholder1 = 'CCIS DATA FILES'
SET @error_msg_placeholder2 = 'SAME INVOICE EXISTING IN OPEN AND CLOSED FILES'

SELECT @row_count = count(CLOSED.INVNO)
  FROM DBO.XX_AR_CCIS_OPEN_BALANCES OPENED
       INNER JOIN
       DBO.XX_AR_CCIS_ACTIVITY CLOSED
       ON
       (
        CLOSED.INVNO = OPENED.INVNO
        and CLOSED.INVC_DT = OPENED.INVC_DT
        and CLOSED.CUSTNO = OPENED.CUSTNO
        and CLOSED.ENTRYDATE = OPENED.ENTRYDATE
        and CLOSED.ACTIVIN in ('B', 'N', 'J')
        and CLOSED.ACTIVOUT not in (' ', 'P', 'F')
       )

IF @row_count <> 0 GOTO BL_ERROR_HANDLER
*/


--7. VALIDATE FILE BY CHECKING RECORD COUNT 
--   WITH TRAILER RECORD
SET @IMAPS_error_number = 210 -- %1 failed validation due to %2.
SET @error_msg_placeholder1 = 'CCIS ACTIVITY FILE'
SET @error_msg_placeholder2 = 'INCORRECT RECORD COUNT IN TRAILER RECORD'

SELECT 	@REC_CNT = COUNT(1)
FROM	dbo.XX_AR_CCIS_ACTIVITY
WHERE	INVNO <> 'TRAILER'

SELECT  @FTR_REC_CNT = CAST(INVC_DT as int)
FROM	dbo.XX_AR_CCIS_ACTIVITY
WHERE 	INVNO = 'TRAILER'

/*
THE OPEN FILE IS THE ONLY FILE THAT WE REALLY CARE ABOUT
UPDATE 	dbo.XX_IMAPS_INT_STATUS
SET 	RECORD_COUNT_TRAILER = @FTR_REC_CNT*/

IF @REC_CNT <> @FTR_REC_CNT GOTO BL_ERROR_HANDLER


--8. VALIDATE FILE BY CHECKING RECORD COUNT 
--   WITH TRAILER RECORD
SET @IMAPS_error_number = 210 -- %1 failed validation due to %2.
SET @error_msg_placeholder1 = 'CCIS OPEN FILE'
SET @error_msg_placeholder2 = 'INCORRECT RECORD COUNT IN TRAILER RECORD'

SELECT 	@REC_CNT = COUNT(1)
FROM	dbo.XX_AR_CCIS_OPEN_BALANCES
WHERE	INVNO <> 'TRAILER'

SELECT  @FTR_REC_CNT = CAST(INVC_DT as int)
FROM	dbo.XX_AR_CCIS_OPEN_BALANCES
WHERE 	INVNO = 'TRAILER'

UPDATE 	dbo.XX_IMAPS_INT_STATUS
SET 	RECORD_COUNT_TRAILER = @FTR_REC_CNT
WHERE	STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

IF @REC_CNT <> @FTR_REC_CNT GOTO BL_ERROR_HANDLER


--8. VALIDATE FILE BY CHECKING RECORD COUNT 
--   WITH TRAILER RECORD
SET @IMAPS_error_number = 210 -- %1 failed validation due to %2.
SET @error_msg_placeholder1 = 'CCIS REMARKS FILE'
SET @error_msg_placeholder2 = 'INCORRECT RECORD COUNT IN TRAILER RECORD'

SELECT 	@REC_CNT = COUNT(1)
FROM	dbo.XX_AR_CCIS_OPEN_REMARKS
WHERE	RTRIM(CUSTNO) <> 'TRAILER'

SELECT  @FTR_REC_CNT = CAST(INVNO as int)
FROM	dbo.XX_AR_CCIS_OPEN_REMARKS
WHERE 	RTRIM(CUSTNO) = 'TRAILER'

IF @REC_CNT <> @FTR_REC_CNT GOTO BL_ERROR_HANDLER


-- DELETE TRAILER RECORDS
DELETE FROM dbo.XX_AR_CCIS_ACTIVITY
 WHERE INVNO = 'TRAILER'

DELETE FROM dbo.XX_AR_CCIS_OPEN_BALANCES
 WHERE INVNO = 'TRAILER'

DELETE FROM dbo.XX_AR_CCIS_OPEN_REMARKS
 WHERE RTRIM(CUSTNO) = 'TRAILER'

IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


--DR1130
/*BEGIN CMR LEFT PAD WITH ZEROS UPDATE */
SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
SET @ERROR_MSG_PLACEHOLDER1 = 'PAD CMR NUMBER'
SET @ERROR_MSG_PLACEHOLDER2 = 'WITH LEADING ZEROS'

UPDATE XX_AR_CCIS_OPEN_BALANCES
   SET CUSTNO = RIGHT('000000' + RTRIM(CUSTNO), 7)

UPDATE XX_AR_CCIS_ACTIVITY
   SET CUSTNO = RIGHT('000000' + RTRIM(CUSTNO), 7)

UPDATE XX_AR_CCIS_OPEN_REMARKS
   SET CUSTNO = RIGHT('000000' + RTRIM(CUSTNO), 7)

IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER
/*END CMR LEFT PAD WITH ZEROS UPDATE */


RETURN(0)

BL_ERROR_HANDLER:

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_number,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @@ERROR,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)

END
GO

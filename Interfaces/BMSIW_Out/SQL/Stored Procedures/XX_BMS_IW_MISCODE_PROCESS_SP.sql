use imapsstg
go

IF OBJECT_ID('dbo.XX_BMS_IW_MISCODE_PROCESS_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_BMS_IW_MISCODE_PROCESS_SP
    IF OBJECT_ID('dbo.XX_BMS_IW_MISCODE_PROCESS_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_BMS_IW_MISCODE_PROCESS_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_BMS_IW_MISCODE_PROCESS_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go



CREATE PROCEDURE [dbo].[XX_BMS_IW_MISCODE_PROCESS_SP]
(
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS
/****************************************************************************************************
Name:       XX_BMS_IW_MISCODE_PROCESS_SP
Author:     TP
Created:    09/25/07

Modified:   11/28/2011 Modified for CR-3890 (standardize BCP calls)

Purpose:    This stored procedure loads the REJECT Flat File and process it to load records in the miscode table for next week's run.
Parameters: 
Result Set: 
Notes:
****************************************************************************************************/
BEGIN


DECLARE	@SP_NAME                 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @row_count               integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@ret_code				 integer,
	@BMS_IW_INTERFACE_NAME	 sysname,
	@ARCH_DIR				 sysname,
	@ARCH_FILE_NAME			 sysname

DECLARE @RECORD_TYPE 	char(1),
		@FILLER_6	char(6)

--CHANGE KM 1/6/05
DECLARE @IMAPS_USR sysname,
	@IMAPS_PWD sysname

SELECT 	@RECORD_TYPE 	= '1',
	@FILLER_6	= '      '


SELECT 	@IMAPS_USR = PARAMETER_VALUE
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE	INTERFACE_NAME_CD = 'BMS_IW'
AND	PARAMETER_NAME = 'IN_USER_NAME'

SELECT 	@IMAPS_PWD = PARAMETER_VALUE
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE	INTERFACE_NAME_CD = 'BMS_IW'
AND	PARAMETER_NAME = 'IN_USER_PASSWORD'

SELECT 	@ARCH_DIR = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @BMS_IW_INTERFACE_NAME
AND	PARAMETER_NAME = 'ARCH_DIR'



-- set local const
SET @BMS_IW_INTERFACE_NAME = 'BMS_IW'
SET @SP_NAME = 'XX_BMS_IW_MISCODE_PROCESS_SP'

/*
-- 1.	TRUNCATE TABLES
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'truncate'
SET @error_msg_placeholder2 = 'tables XX_BMS_IW_REJECT'

TRUNCATE TABLE dbo.XX_BMS_IW_REJECT

SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER
*/

-- 2.	BCP IN TABLE XX_BMS_IW_REJECT
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'BCP IN'
SET @error_msg_placeholder2 = 'table XX_BMS_IW_REJECT'

DECLARE	@REJ_FILE	sysname,
	@REJ_FRMT	sysname,
	@CMD		varchar(600)

SELECT 	@REJ_FILE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @BMS_IW_INTERFACE_NAME
AND 	PARAMETER_NAME = 'REJ_FILE'

SELECT 	@REJ_FRMT = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @BMS_IW_INTERFACE_NAME
AND 	PARAMETER_NAME = 'REJ_FRMT'

/*
CR-3890 
SET 	@CMD = 'BCP IMAPSSTG.DBO.XX_BMS_IW_REJECT IN ' + @REJ_FILE + ' -f' + @REJ_FRMT + ' -U' + @IMAPS_USR + ' -P' + @IMAPS_PWD
EXEC @ret_code=MASTER.DBO.XP_CMDSHELL @CMD
*/
--begin CR-3890
SET @ret_code=1

EXEC @ret_code = dbo.XX_EXEC_SHELL_CMD_INSERT_OSUSER
	@in_IMAPS_db_name='IMAPSSTG',
	@in_IMAPS_table_owner='dbo',
	@in_Dest_table='XX_BMS_IW_REJECT',
	@in_format_file=@REJ_FRMT,
	@in_input_file=@REJ_FILE,
	@out_STATUS_DESCRIPTION=@out_STATUS_DESCRIPTION

--end CR-3890


IF @ret_code<>0
  BEGIN
	PRINT 'Error'
	GOTO BL_ERROR_HANDLER
  END
ELSE
  BEGIN
	-- BEGIN REJFILE ARCHIVE
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'Move REJECT file to'
	SET @error_msg_placeholder2 = 'Archive Folder'
	
	SELECT 	@REJ_FILE = PARAMETER_VALUE
	FROM	dbo.XX_PROCESSING_PARAMETERS
	WHERE 	INTERFACE_NAME_CD = @BMS_IW_INTERFACE_NAME
	AND 	PARAMETER_NAME = 'REJ_FILE'

	SELECT 	@ARCH_DIR = PARAMETER_VALUE
	FROM	dbo.XX_PROCESSING_PARAMETERS
	WHERE 	INTERFACE_NAME_CD = @BMS_IW_INTERFACE_NAME
	AND	PARAMETER_NAME = 'ARCH_DIR'

	
	SET @ARCH_FILE_NAME = 'REJFILE_BMS_IW_'+rtrim(CONVERT(char(10), getdate(), 112))+'.txt'
	
	SET @CMD = 'MOVE   ' + @REJ_FILE+ '   ' + @ARCH_DIR+@ARCH_FILE_NAME
    print @CMD
	EXEC @RET_CODE = MASTER.DBO.XP_CMDSHELL @CMD
		
	IF @RET_CODE <> 0 GOTO BL_ERROR_HANDLER

	-- END REJFILE ARCHIVE
  END



SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

-- 3.	UPDATE TABLE XX_BMS_IW_REJECT
-- TODO, FINALIZE data mappings
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert into'
SET @error_msg_placeholder2 = 'table XX_BMS_IW_DTL'

-- Code to fix the rejected records
PRINT 'No Updates were made to Rejected Data Please update manually and re-run the miscode'

SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER


-- END BMS_IW_REJECT updates

/*
-- 4. BEGIN REJECT --> Miscode transfer
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'Move REJECT Records to MISCODE table'
SET @error_msg_placeholder2 = 'for processing in next cycle'


-- Move records to BMSIW_DTL_MISCODE table for further processing during next cycle
-- Process only the record with the process flag='Y'
INSERT INTO dbo.XX_BMS_IW_DTL_MISCODE
		(RECORD_TYPE, EMP_SER_NUM, 
		CTRY_CD, CMPNY_CD, TOT_CLMED_HRS,
		ACCT_TYP_CD, TRVL_INDICATOR, 
		CLM_WK_ENDING_DT, OVRTM_HRS_IND,
		OWNG_LOB_CD, OWNG_CNTRY_CD, OWNG_CMPNY_CD, LBR_SYS_CD,
		CHRG_ACCT_ID, CHRG_ACTV_CD, FILLER)
SELECT 
		@RECORD_TYPE, EMP_SER_NUM, 
		CTRY_CD, CMPNY_CD, TOT_CLMED_HRS,
		ACCT_TYP_CD, TRVL_INDICATOR, 
		CLM_WK_ENDING_DT, OVRTM_HRS_IND,
		OWNG_LOB_CD, OWNG_CNTRY_CD, OWNG_CMPNY_CD, LBR_SYS_CD,
		CHRG_ACCT_ID, CHRG_ACTV_CD, @FILLER_6
FROM dbo.XX_BMS_IW_REJECT
where process_flag='Y'

-- Delete from miscode table as the data is sent to BMSIW
DELETE FROM dbo.XX_BMS_IW_REJECT
where process_flag='Y'
*/

SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

-- END REJECT --> Miscode transfer




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

go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_BMS_IW_MISCODE_PROCESS_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_BMS_IW_MISCODE_PROCESS_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_BMS_IW_MISCODE_PROCESS_SP >>>'
go

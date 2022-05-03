IF OBJECT_ID('dbo.XX_UTIL_DATA_TRANSFER_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_UTIL_DATA_TRANSFER_SP
    IF OBJECT_ID('dbo.XX_UTIL_DATA_TRANSFER_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_UTIL_DATA_TRANSFER_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_UTIL_DATA_TRANSFER_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER ON
go







CREATE PROCEDURE [dbo].[XX_UTIL_DATA_TRANSFER_SP]
( 
@in_STATUS_RECORD_NUM    integer, 
@out_SystemError int = NULL OUTPUT, 
@out_STATUS_DESCRIPTION varchar(275) =NULL OUTPUT) AS

DECLARE
@NumberOfRecords int,
@InvalidDataName varchar(50),
@StagingTableName varchar(30),
@SP_NAME varchar(50),
@StartDt datetime,
@OracleOrgRecordNum int,
@OracleLabRecordNum int,
@OracleTotalHours decimal(14, 2),
@IMAPSOrgRecordNum int,
@IMAPSLabRecordNum int,
@IMAPSTotalHours decimal(14, 2),
@ReturnCode int
/************************************************************************************************  
Name:       XX_UTIL_DATA_TRANSFER_SP 
Author:     	Tatiana Perova
Created:    	10/04/2005  
Purpose:  Step 2 of Utilization interface.
		It inserts data from IMAPS staging tables to the tables on the Linked Server ETIME
		schema INTERIM.It validates that number of records and hours exported to Oracle correspond
		to the same values from staging tables.If a difference is found update to the Oracle tables
		will be "rolled back" by deleting all records inserted by this interface run.
                Called by XX_UTIL_RUN_INTERFACE_SP

Parameters: 
	Input: @in_STATUS_RECORD_NUM -- identifier of current interface run
	Output:  @out_STATUS_DESCRIPTION --  generated error message
		@out_SystemError  -- system error code
Result Set: 	None  
Version: 	1.0
Notes:
Modified: 12/07/07 CR-1333/1335 related changes 

**************************************************************************************************/ 
SET @ReturnCode = 0
SET @OracleOrgRecordNum = 0
SET @OracleLabRecordNum = 0
SET @SP_NAME = 'XX_UTIL_DATA_TRANSFER_SP'

--change KM 1/11/06
-- isert data into Oracle tables
INSERT INTO [ETIME_RPT]..[CFRPTADM].[CP_UTIL_LAB_OUT]
(UTIL_LAB_RECORD_NUM, STATUS_RECORD_NUM , TS_LN_KEY, EMPL_ID, LAST_FIRST_NAME, EMPL_HOME_ORG_ID,
 EMPL_HOME_ORG_NAME, CONTRACT_ID, CONTRACT_NAME, PROJ_ABBRV_CD, PROJ_NAME,
INDUSTRY, KEY_ACCOUNT, HR_TYPE, TS_DT, POSTING_DT, ENTERED_HRS, PERIOD_STRT_DATE,
ACCT_STATUS, CONTACT_NAME, PRIME_CONTR_ID, CUSTOMER_NO, SOW_TYP_CD, 
OWNING_DIV_CD, OWNING_COUNTRY_CD, OWNING_COMPANY_CD, ACCT_TYP_CD, OWNING_LOB_CD,
CTRY_CD, CMPNY_CD, ACCOUNT_ID, PROJ_ID, PM_EMPL_ID, ACCTGRP_ID, 
CHRG_ACTV_CD, UTIL_TYP_CD, ACCT_GRP_CD, -- Added for CR-1333
PAY_TYPE ) -- Added for CR-1539
SELECT UTIL_LAB_RECORD_NUM, STATUS_RECORD_NUM ,TS_LN_KEY, EMPL_ID, LAST_FIRST_NAME, EMPL_HOME_ORG_ID,
 EMPL_HOME_ORG_NAME, CONTRACT_ID, CONTRACT_NAME, PROJ_ABBRV_CD, PROJ_NAME,
INDUSTRY, KEY_ACCOUNT, HR_TYPE,TS_DT, POSTING_DT, ENTERED_HRS, PERIOD_END_DT,
ACCT_STATUS, CONTACT_NAME, PRIME_CONTR_ID, CUSTOMER_NO, SOW_TYP_CD, 
OWNING_DIV_CD, OWNING_COUNTRY_CD, OWNING_COMPANY_CD, ACCT_TYP_CD, OWNING_LOB_CD,
CTRY_CD, CMPNY_CD, ACCOUNT_ID, PROJ_ID, PM_EMPL_ID, ACCTGRP_ID,
CHRG_ACTV_CD, UTIL_TYP_CD, ACCT_GRP_CD, -- Added for CR-1333
PAY_TYPE -- Added for CR-1539
FROM dbo.XX_UTIL_LAB_OUT
--end change KM 1/11/06


SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT
IF @out_SystemError > 0  
	BEGIN 
	SET @ReturnCode = 1
	GOTO ErrorProcessing 
	END

INSERT INTO [ETIME_RPT]..[CFRPTADM].[CP_UTIL_ORG_OUT]
	( UTIL_ORG_RECORD_NUM,   STATUS_RECORD_NUM , DIVISION ,
	PRACTICE_AREA,   ORG_ID ,  ORG_ABBRV_CD ,
	ORG_NAME,  SERVICE_AREA, SERVICE_AREA_DESC 
	)
SELECT
	[UTIL_ORG_RECORD_NUM], [STATUS_RECORD_NUM], [DIVISION], 
	[PRACTICE_AREA], [ORG_ID], [ORG_ABBRV_CD],
	[ORG_NAME], [SERVICE_AREA], [SERVICE_AREA_DESC]
FROM dbo.XX_UTIL_ORG_OUT

SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT
IF @out_SystemError > 0  
	BEGIN 
	SET @ReturnCode = 1
	GOTO ErrorProcessing 
	END

-- calculate control values in Oracle and compare with local

SELECT @OracleLabRecordNum = Count(*),
	@OracleTotalHours = SUM(CAST (ENTERED_HRS AS decimal(14, 2)))
FROM [ETIME_RPT]..[CFRPTADM].[CP_UTIL_LAB_OUT]
WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM


SELECT @IMAPSLabRecordNum = LAB_RECORD_COUNT,
	@IMAPSTotalHours = TOTAL_LABOR_HOURS,
	@IMAPSOrgRecordNum = ORG_RECORD_COUNT
FROM dbo.XX_UTIL_OUT_LOG
WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

IF @OracleLabRecordNum <> @IMAPSLabRecordNum 
	BEGIN
	SET @ReturnCode = 530
	SET @InvalidDataName = 'number of labor records'
	SET @StagingTableName = 'XX_UTIL_LAB_OUT'
	GOTO  ErrorProcessing
	END
IF( @OracleTotalHours is NOT NULL and @IMAPSTotalHours  is NULL) OR
	( @OracleTotalHours is  NULL and @IMAPSTotalHours  is NOT NULL) OR
	( @OracleTotalHours is NOT NULL and @IMAPSTotalHours  is NOT NULL AND 
	@OracleTotalHours <> @IMAPSTotalHours )
	BEGIN
	SET @ReturnCode = 530
	SET @InvalidDataName = 'sum of labor hours'
	SET @StagingTableName = 'XX_UTIL_LAB_OUT'
	GOTO  ErrorProcessing
	END
	

SELECT @OracleOrgRecordNum = Count(*)
FROM [ETIME_RPT]..[CFRPTADM].[CP_UTIL_ORG_OUT]
WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

IF @OracleOrgRecordNum <> @IMAPSOrgRecordNum
	BEGIN
	SET @ReturnCode = 530
	SET @InvalidDataName = 'number of organization records'
	SET @StagingTableName = 'XX_UTIL_ORG_OUT'
	GOTO  ErrorProcessing
	END

-- save control values in Oracle
INSERT INTO [ETIME_RPT]..[CFRPTADM].CP_UTIL_OUT_LOG
	( STATUS_RECORD_NUM,  LAB_RECORD_COUNT,
	ORG_RECORD_COUNT,TOTAL_LABOR_HOURS
	)
VALUES
	(@in_STATUS_RECORD_NUM,  @OracleLabRecordNum, 
	@OracleOrgRecordNum, @OracleTotalHours
	)

SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT
IF @out_SystemError > 0 
	BEGIN 
	SET @ReturnCode = 1
	GOTO ErrorProcessing 
	END


-- save last posted id in log table if it was not period request
SELECT @StartDt = START_DT
FROM dbo.XX_UTIL_OUT_LOG
WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM 

IF @StartDt is NULL
    BEGIN
	UPDATE dbo.XX_UTIL_OUT_LOG
	SET LAST_TS_LN_KEY =
		(SELECT  MAX(TS_LN_KEY)
		FROM dbo.XX_UTIL_LAB_OUT)
	WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM 
	
	SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT
	IF @out_SystemError > 0  
		BEGIN 
			SET @ReturnCode = 1
			GOTO ErrorProcessing 
		END
    END

RETURN 0

ErrorProcessing:
-- followng code rolling back possible changes done by  stored procedure.
DELETE FROM [ETIME_RPT]..[CFRPTADM].CP_UTIL_OUT_LOG 
WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM 

DELETE FROM [ETIME_RPT]..[CFRPTADM].CP_UTIL_LAB_OUT
WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM


DELETE FROM [ETIME_RPT]..[CFRPTADM].CP_UTIL_ORG_OUT
WHERE STATUS_RECORD_NUM =@in_STATUS_RECORD_NUM

UPDATE dbo.XX_UTIL_OUT_LOG
	SET LAST_TS_LN_KEY = NULL
	WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM 

IF @ReturnCode = 530
	BEGIN 
	/*message created in procedure in order not to return parameter 
	 @StagingTableName into  XX_UTIL_RUN_INTERFACE_SP
	 Message: Total %1 transferred to et&T is not in sync with the %2 in the staging table %3.*/
	EXEC dbo.XX_ERROR_MSG_DETAIL
			@in_error_code          = @ReturnCode,
			@in_SQLServer_error_code = NULL,
			-- begin 12/06/2005 TP	
			@in_placeholder_value1   = @InvalidDataName,
			@in_placeholder_value2   = @InvalidDataName,
			@in_placeholder_value3   = @StagingTableName,
			-- end 12/06/2005 TP	
			@in_display_requested   = 1,
			@in_calling_object_name = @SP_NAME,
			@out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT
	SET @ReturnCode = 1
	END

RETURN @ReturnCode






go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_UTIL_DATA_TRANSFER_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_UTIL_DATA_TRANSFER_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_UTIL_DATA_TRANSFER_SP >>>'
go
GRANT EXECUTE ON dbo.XX_UTIL_DATA_TRANSFER_SP TO imapsstg
go

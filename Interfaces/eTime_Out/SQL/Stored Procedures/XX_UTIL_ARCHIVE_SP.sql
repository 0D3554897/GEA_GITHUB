IF OBJECT_ID('dbo.XX_UTIL_ARCHIVE_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_UTIL_ARCHIVE_SP
    IF OBJECT_ID('dbo.XX_UTIL_ARCHIVE_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_UTIL_ARCHIVE_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_UTIL_ARCHIVE_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER ON
go







CREATE PROCEDURE [dbo].[XX_UTIL_ARCHIVE_SP]
( 
@in_STATUS_RECORD_NUM    integer, 
@out_SystemError int = NULL OUTPUT, 
@out_STATUS_DESCRIPTION varchar(275) =NULL OUTPUT) AS

Declare 
@TotalArchivedRecords int,
@TotalInputRecords int,
@NumberOfRecords int,
@DoesInterfaceStatusNumberPresent tinyint,
@ReturnCode int


 /************************************************************************************************
Name:       XX_UZTIL_ARCHIVE_SP
Author:     Tatiana Perova
Created:    10/03/2005
Purpose:   Step 3 of Utilization interface.
		Program copies records from staging table  to archive,
		updates interface status with number for RECORD_COUNT_SUCCESS
Modified: For CR-1305 on 10/22/07
Modified: For CR-1333/1335 on 12/18/07 ACCT_GRP_CD added
Modified: for CR-1539 PAY_TYPE added	
Parameters: 
	Input: @in_STATUS_RECORD_NUM -- identifier of current interface run
	Output:  @out_STATUS_DESCRIPTION --  generated error message
		@out_SystemError  -- system error code

************************************************************************************************/

BEGIN TRANSACTION
SET @DoesInterfaceStatusNumberPresent = 0
SET @TotalArchivedRecords = 0
SET @ReturnCode = 0

-- insure that interface run in staging table was not yet archived
SELECT @DoesInterfaceStatusNumberPresent = 1
FROM dbo.XX_UTIL_LAB_OUT_ARCH 
WHERE 
	STATUS_RECORD_NUM = @in_status_record_num
	
IF @DoesInterfaceStatusNumberPresent = 1 
	BEGIN
		/* Message:Utilization Interface data gathered 
		for the current interface run was already archived.*/
		SET @ReturnCode = 531
		GOTO ErrorProcessing
	END

SELECT @DoesInterfaceStatusNumberPresent = 1
FROM dbo.XX_UTIL_ORG_OUT_ARCH 
WHERE 
	STATUS_RECORD_NUM = @in_status_record_num
	
IF @DoesInterfaceStatusNumberPresent = 1 
	BEGIN
		/* Message:Utilization Interface data gathered 
		for the current interface run was already archived.*/
		SET @ReturnCode = 531
		GOTO ErrorProcessing
	END	
	
--copy all records from staging table to archive table 
INSERT INTO dbo.XX_UTIL_LAB_OUT_ARCH
(STATUS_RECORD_NUM ,TS_LN_KEY, EMPL_ID, LAST_FIRST_NAME, EMPL_HOME_ORG_ID,
 EMPL_HOME_ORG_NAME, CONTRACT_ID, CONTRACT_NAME, PROJ_ABBRV_CD, PROJ_NAME,
INDUSTRY, KEY_ACCOUNT, HR_TYPE,TS_DT, POSTING_DT, ENTERED_HRS, PERIOD_END_DT,
ACCT_STATUS, CONTACT_NAME, PRIME_CONTR_ID, CUSTOMER_NO, SOW_TYP_CD, 
OWNING_DIV_CD, OWNING_COUNTRY_CD, OWNING_COMPANY_CD, ACCT_TYP_CD, OWNING_LOB_CD,
CTRY_CD, CMPNY_CD, ACCOUNT_ID, PROJ_ID, PM_EMPL_ID, ACCTGRP_ID, CHRG_ACTV_CD, UTIL_TYP_CD,
ACCT_GRP_CD, PAY_TYPE)
SELECT STATUS_RECORD_NUM ,TS_LN_KEY, EMPL_ID, LAST_FIRST_NAME, EMPL_HOME_ORG_ID,
 EMPL_HOME_ORG_NAME, CONTRACT_ID, CONTRACT_NAME, PROJ_ABBRV_CD, PROJ_NAME,
INDUSTRY, KEY_ACCOUNT, HR_TYPE,TS_DT, POSTING_DT, ENTERED_HRS, PERIOD_END_DT,
ACCT_STATUS, CONTACT_NAME, PRIME_CONTR_ID, CUSTOMER_NO, SOW_TYP_CD, 
OWNING_DIV_CD, OWNING_COUNTRY_CD, OWNING_COMPANY_CD, ACCT_TYP_CD, OWNING_LOB_CD,
CTRY_CD, CMPNY_CD, ACCOUNT_ID, PROJ_ID, PM_EMPL_ID, ACCTGRP_ID, CHRG_ACTV_CD, UTIL_TYP_CD, 
ACCT_GRP_CD, -- Added for CR-1333/1335
pay_type -- Added CR-1539
FROM dbo.XX_UTIL_LAB_OUT

SELECT @out_SystemError= @@ERROR,  @NumberOfRecords = @@ROWCOUNT
if @out_SystemError > 0 
	BEGIN
		SET @ReturnCode = 1
		GOTO ErrorProcessing
	END


INSERT INTO dbo.XX_UTIL_ORG_OUT_ARCH
	(UTIL_ORG_RECORD_NUM, STATUS_RECORD_NUM, DIVISION,
	PRACTICE_AREA, ORG_ID, ORG_ABBRV_CD,
	ORG_NAME, SERVICE_AREA)
SELECT 
	UTIL_ORG_RECORD_NUM, STATUS_RECORD_NUM, DIVISION,
	PRACTICE_AREA,ORG_ID,ORG_ABBRV_CD,
	ORG_NAME,SERVICE_AREA
FROM dbo.XX_UTIL_ORG_OUT

SELECT @out_SystemError= @@ERROR,  @NumberOfRecords = @@ROWCOUNT
if @out_SystemError > 0 
	BEGIN
		SET @ReturnCode = 1
		GOTO ErrorProcessing
	END

-- get initial record count
SELECT
	@TotalInputRecords = ISNULL(RECORD_COUNT_INITIAL,0)
FROM  dbo.XX_IMAPS_INT_STATUS 	
WHERE 
	STATUS_RECORD_NUM = @in_status_record_num

-- get record count in archive
Select @TotalArchivedRecords = Count(*)
FROM dbo.XX_UTIL_LAB_OUT_ARCH
WHERE 
	STATUS_RECORD_NUM = @in_status_record_num

Select @TotalArchivedRecords = @TotalArchivedRecords + Count(*)
FROM dbo.XX_UTIL_ORG_OUT_ARCH
WHERE 
	STATUS_RECORD_NUM = @in_status_record_num

-- Validate archiving
IF @TotalInputRecords <> @TotalArchivedRecords 
	BEGIN
		/*Message:Total count of record archived is not in sync with 
		the number of records in the staging tables.*/
		SET @ReturnCode = 532
		GOTO ErrorProcessing
	END


-- update interface status record with the results of the run
UPDATE dbo.XX_IMAPS_INT_STATUS 
SET RECORD_COUNT_SUCCESS = @TotalArchivedRecords
WHERE 
	STATUS_RECORD_NUM = @in_status_record_num

SELECT @out_SystemError= @@ERROR,  @NumberOfRecords = @@ROWCOUNT
IF @out_SystemError > 0 
	BEGIN
		SET @ReturnCode = 1
		GOTO ErrorProcessing
	END

COMMIT TRANSACTION
RETURN 0

ErrorProcessing:
ROLLBACK TRANSACTION
RETURN @ReturnCode





go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_UTIL_ARCHIVE_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_UTIL_ARCHIVE_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_UTIL_ARCHIVE_SP >>>'
go

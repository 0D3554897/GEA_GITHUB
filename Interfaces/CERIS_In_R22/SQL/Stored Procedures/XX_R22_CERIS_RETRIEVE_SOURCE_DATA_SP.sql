USE [IMAPSStg]
GO
/****** Object:  StoredProcedure [dbo].[XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP]    Script Date: 12/7/2021 3:15:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP]
(
@in_STATUS_RECORD_NUM     integer,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS

/************************************************************************************************
Name:       XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP
Author:     V Veera
Created:    05/20/2008
Purpose:    Retrieve source data from CERIS Research file populated staging table
            XX_R22_CERIS_FILE_STG1.
            Called by XX_R22_CERIS_RUN_INTERFACE_SP.
Parameters: 
Result Set: None
Notes:

CP600000825 03/09/2010 Reference BP&S Service Request CR2653
            Provide report data on active and inactive employees.

CP600000825 03/09/2010 Reference BP&S Service Request CR2577
            Enable Research HR reporting.

CP600000709 05/10/2010 Reference BP&S Service Request CR2350 - KM track standard hours changes
            Need to keep track of standard hours changes
CR9296 - gea - 4/10/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
CR9296 - gea - 4/25/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^

DR9450      05/02/2017 Re-integrate code originally written for CR8005 by TP on 10/22/2015
            and disappeared as a result of CR8504.
CR-11277 tp- Modified for division changes YA/SR to 22
CR-13233 tp- Added QR to the list of divisions. 
************************************************************************************************/



DECLARE @SP_NAME                 sysname,
        @IMAPS_error_code        integer,
        @SQLServer_error_code    integer,
        @row_count               integer,
        @sql_count          integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,

        @CERIS_INTERFACE_NAME       varchar(50),
        @DIV_22_COMPANY_ID          varchar(10),
        @CERIS_COMPANY_PARAM        varchar(50),
        @CERIS_PASSKEY_VALUE        varchar(128),
        @CERIS_PASSKEY_VALUE_PARAM  varchar(30),
        @CERIS_KEYNAME        varchar(50),
  @CERIS_KEYNAME1             varchar(50),
        @CERIS_KEYNAME_PARAM        varchar(30),
  @OPEN_KEY                   varchar(400),
  @CLOSE_KEY                  varchar(400),
        @SQL_Server_Error_CD        integer,
        @ret_code                   integer

-- set local constants
 
 
 
PRINT '' --CR9296 *~^
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9296 *~^
-- *~^
SET @SP_NAME = 'XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP'
-- set local constants
SET @CERIS_INTERFACE_NAME = 'CERIS_R22'
SET @CERIS_PASSKEY_VALUE_PARAM = 'PASSKEY_VALUE'
SET @CERIS_KEYNAME_PARAM = 'CERIS_KEYNAME'
SET @CERIS_COMPANY_PARAM = 'COMPANY_ID'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 92 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
SELECT @DIV_22_COMPANY_ID = PARAMETER_VALUE
FROM  dbo.XX_PROCESSING_PARAMETERS
WHERE PARAMETER_NAME    = @CERIS_COMPANY_PARAM
AND   INTERFACE_NAME_CD = @CERIS_INTERFACE_NAME

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 102 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
SELECT  @CERIS_PASSKEY_VALUE = PARAMETER_VALUE
FROM  dbo.XX_PROCESSING_PARAMETERS
WHERE PARAMETER_NAME    = @CERIS_PASSKEY_VALUE_PARAM
AND   INTERFACE_NAME_CD = @CERIS_INTERFACE_NAME

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 112 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
SELECT @CERIS_KEYNAME = PARAMETER_VALUE
FROM  dbo.XX_PROCESSING_PARAMETERS
WHERE PARAMETER_NAME    = @CERIS_KEYNAME_PARAM
AND INTERFACE_NAME_CD = @CERIS_INTERFACE_NAME

PRINT 'USE STATUS_RECORD_NUMBER '
PRINT @in_STATUS_RECORD_NUM

SET @OPEN_KEY = 'OPEN SYMMETRIC KEY' + '  ' + @CERIS_KEYNAME + '  ' + 'DECRYPTION BY PASSWORD = ''' +  @CERIS_PASSKEY_VALUE + '''' + '  '
SET @CLOSE_KEY = 'CLOSE SYMMETRIC KEY' + '  ' + @CERIS_KEYNAME
PRINT 'OPEN SYMMETRIC KEY ' -- CR3548 03/30/2011
--PRINT @OPEN_KEY Removed for DR-9450 We dont have to print the key 5/10/17 TP

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 130 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
exec (@OPEN_KEY)

SET @SQL_Server_Error_CD = @@ERROR

IF @SQL_Server_Error_CD > 0
   BEGIN
      GOTO BL_ERROR_HANDLER
   END

PRINT 'Process Stage CERIS_R1 - Retrieve CERIS Research data from XX_R22_CERIS_FILE_STG populated from flat file ...'

PRINT 'Clear table XX_R22_CERIS_FILE_STG and all of its associated temporary staging tables ...'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 148 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
TRUNCATE TABLE dbo.XX_R22_CERIS_FILE_STG
TRUNCATE TABLE dbo.XX_R22_CERIS_CP_STG
TRUNCATE TABLE dbo.XX_R22_CERIS_CP_EMPL_STG
TRUNCATE TABLE dbo.XX_R22_CERIS_CP_EMPL_LAB_STG
TRUNCATE TABLE dbo.XX_R22_CERIS_CP_DFLT_TS_STG
TRUNCATE TABLE dbo.XX_R22_CERIS_RETRO_TS
TRUNCATE TABLE dbo.XX_R22_CERIS_RETRO_TS_PREP
TRUNCATE TABLE dbo.XX_R22_CERIS_RETRO_TS_PREP_ERRORS
TRUNCATE TABLE dbo.XX_R22_CERIS_VALIDAT_ERRORS

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 156 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
PRINT 'Before start the process we need to convert YA and SR, QR to 22' 

-- Added for CR-11277
-- Modified for CR-13233, Div QR Added
	-- Once employees are loaded to file_stg1 table then we will update division with 22
	-- So downstream applications will use 22
	update XX_R22_CERIS_FILE_STG1
	set DIVISION='22'
	where rtrim(division) in ('YA','SR','QR')

	update XX_R22_CERIS_FILE_STG1
	set DIVISION_FROM='22'
	where rtrim(DIVISION_FROM) in ('YA','SR','QR')

SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG1
PRINT 'Select Stg1 Row Count: ' 
PRINT @sql_count
SET @sql_count = 0

PRINT 'BEFORE Insert Attempt on dbo.XX_R22_CERIS_FILE_STG'
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 165 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG1
PRINT 'Select Stg1 Row Count: ' 
PRINT @sql_count
SET @sql_count = 0
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 175 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG
PRINT 'Select Stg Row Count: ' 
PRINT @sql_count
SET @sql_count = 0


/* load the staging table from the staging table1 (encrypted) poplated using
   the CERIS Research file provided
 
Requirement 3:
Maintain all serial numbers in secure mapping table within IMAPSStg.  
Map serial numbers to alternate number to be used as Employee ID in Costpoint 
and for translation within Etime interface.  The format of the alternate 
number should contain at least 7 characters (and limited to 12 by Costpoint)
to avoid potential for duplication with real serial numbers in Division 16.
*/
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 196 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
INSERT INTO dbo.XX_R22_CERIS_FILE_STG(
 STATUS_RECORD_NUM, EMPL_ID, LNAME, FNAME, NAME_INITIALS, HIRE_EFF_DT, 
 IBM_START_DT, TERM_DT, MGR_SERIAL_NUM, MGR_LNAME, MGR_INITIALS, JOB_FAM, 
 JOB_FAM_DT, SAL_BAND, LVL_DT_1, DIVISION, DIVISION_START_DT, DEPT, 
 DEPT_START_DT, DEPT_SUF_DT, FLSA_STAT, EXEMPT_DT, POS_CODE, POS_DESC, 
 POS_DT, REG_TEMP, STAT3, EMPL_STAT3_DT, STATUS, EMPL_STAT_DT, STD_HRS, 
 WORK_SCHD_DT, LOA_BEG_DT, LOA_END_DT, LOA_TYPE, LVL_SUFFIX, DIVISION_FROM, 
 WORK_OFF, CURR_DIV_FUNC_CODE, CURR_REP_LVL_CODE, PREV_DIV_FUNC_CODE, 
 PREV_REP_LVL_CODE, MGR2_LNAME, MGR2_INITIALS, MGR3_LNAME, MGR3_INITIALS, 
 HIRE_TYPE, HIRE_PRGM, SEPRSN, DEPT_FROM, VACELGD, CMPLN, BLDG_ID, 
 DEPT_SHIFT_DT, DEPT_SHIFT_1, MGR_FLAG, SALARY, SALARY_DT,
 CREATION_DATE, CREATED_BY,
-- CR2577_begin
 ASTYP, ASNTYP) -- CR2577_end
SELECT 
 @in_STATUS_RECORD_NUM, emap.EMPL_ID, LNAME, FNAME, NAME_INITIALS, hire_eff_dt, 
 IBM_START_DT, TERM_DT, NULL, MGR_LNAME, MGR_INITIALS, JOB_FAM, 
 JOB_FAM_DT, SAL_BAND, LVL_DT_1, DIVISION, DIVISION_START_DT, DEPT,
 DEPT_START_DT, DEPT_SUF_DT, FLSA_STAT, EXEMPT_DT, POS_CODE, POS_DESC,
 POS_DT, REG_TEMP, STAT3, EMPL_STAT3_DT, STATUS, EMPL_STAT_DT, 
 cast(std_hrs as decimal(15,2)), --STD_HRS,
 WORK_SCHD_DT, LOA_BEG_DT, LOA_END_DT, LOA_TYPE, LVL_SUFFIX, DIVISION_FROM,
 WORK_OFF, CURR_DIV_FUNC_CODE, CURR_REP_LVL_CODE, PREV_DIV_FUNC_CODE,
 PREV_REP_LVL_CODE, MGR2_LNAME, MGR2_INITIALS, MGR3_LNAME, MGR3_INITIALS,
 HIRE_TYPE, HIRE_PRGM, SEPRSN, DEPT_FROM, VACELGD, CMPLN, BLDG_ID,
 DEPT_SHIFT_DT, DEPT_SHIFT_1, MGR_FLAG, cast(convert (varchar(100), DECRYPTBYKEY(salary)) as decimal(15,2)),
 SALARY_DT, 
 getdate(), suser_name(),
-- CR2577_begin
 ASTYP, ASNTYP
-- CR2577_end
FROM dbo.XX_R22_CERIS_FILE_STG1 CSTG
inner join
    dbo.XX_R22_CERIS_EMPL_ID_MAP emap
on (CONVERT(VARCHAR(50),DECRYPTBYKEY(cstg.r_empl_id)) = CONVERT(VARCHAR(50),DECRYPTBYKEY(emap.r_empl_id)))

-- CR2577_begin
SET @row_count = @@ROWCOUNT
SET @SQLServer_error_code = @@ERROR

PRINT 'AFTER Insert Attempt on dbo.XX_R22_CERIS_FILE_STG'
PRINT 'SQLServer Error Code: ' 
PRINT @SQLServer_error_code
PRINT 'Insert Row Count: ' 
PRINT @row_count

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 247 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG1
PRINT 'Select Stg1 Row Count: ' 
PRINT @sql_count
SET @sql_count = 0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 257 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG
PRINT 'Select Stg Row Count: ' 
PRINT @sql_count
SET @sql_count = 0

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to insert records into table XX_R22_CERIS_FILE_STG failed.
      SET @error_msg_placeholder1 = 'Failed to insert'
      SET @error_msg_placeholder2 = 'records into table XX_R22_CERIS_FILE_STG'
      GOTO BL_ERROR_HANDLER
   END

-- This test checks the results of the decryption operation
IF @row_count = 0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to populate table XX_R22_CERIS_FILE_STG failed.
      SET @error_msg_placeholder1 = 'populate'
      SET @error_msg_placeholder2 = 'staging table XX_R22_CERIS_FILE_STG'
      GOTO BL_ERROR_HANDLER
   END
-- CR2577_end

/* Secured encrypted mapping table that maps IBM Serial number to the Costpoint Serial number */


/* Pading single digit sal_band with leading zeros */
/*
UPDATE dbo.XX_R22_CERIS_FILE_STG 
SET SAL_BAND = '0' + SAL_BAND
WHERE LEN(SAL_BAND)=1
*/



/*
Requirement 1 
1.  On import from flat file, replace blank Executive employee name with "Research Executive" and 
Executive Manager's name with "Research Manager".  Executives will have a stat1 = 2.  
*/


 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 299 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
UPDATE  dbo.XX_R22_CERIS_FILE_STG 
SET   LNAME= 'RESEARCH',
    FNAME = 'EXECUTIVE',
    NAME_INITIALS = 'RE',
    MGR_LNAME = 'RESEARCH MANAGER',
    MGR_INITIALS = 'RM'
WHERE reg_temp='2';

SET @SQLServer_error_code = @@ERROR

PRINT 'After Research Manager'
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG1
PRINT 'Select Stg1 Row Count: ' 
PRINT @sql_count
SET @sql_count = 0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 320 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG
PRINT 'Select Stg Row Count: ' 
PRINT @sql_count
SET @sql_count = 0

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to query table XX_R22_CERIS_FILE_STG failed.
      SET @error_msg_placeholder1 = 'query'
      SET @error_msg_placeholder2 = 'table XX_R22_CERIS_FILE_STG'
      GOTO BL_ERROR_HANDLER
   END

IF @row_count = 0 
   BEGIN
      SET @IMAPS_error_code = 209 -- No %1 exist to %2 
      SET @error_msg_placeholder1 = 'XX_R22_CERIS_FILE_STG data'
      SET @error_msg_placeholder2 = 'populate table XX_R22_CERIS_FILE_STG'
      GOTO BL_ERROR_HANDLER
   END


PRINT 'Update table XX_R22_CERIS_DIV22_STATUS...'

DECLARE @CURRENT_TIMESTAMP datetime
SELECT @CURRENT_TIMESTAMP = CURRENT_TIMESTAMP

--LOAD DIVISION STATUS FROM CURRENT WEEK CERIS TABLE (populated and maintained by ETIME)
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 354 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
INSERT INTO dbo.XX_R22_CERIS_DIV22_STATUS
(EMPL_ID, DIVISION, DIVISION_START_DT,
   DIVISION_FROM, CREATED_BY, CREATION_DATE)
SELECT 
  EMPL_ID, DIVISION, DIVISION_START_DT,
  DIVISION_FROM, SUSER_SNAME(), @CURRENT_TIMESTAMP
FROM dbo.XX_R22_CERIS_FILE_STG
WHERE DIVISION_START_DT IS NOT NULL

SET @SQLServer_error_code = @@ERROR

PRINT 'Select Row Count after Load Division Status: ' 
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG1
PRINT 'Select Stg1 Row Count: ' 
PRINT @sql_count
SET @sql_count = 0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 376 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG
PRINT 'Select Stg Row Count: ' 
PRINT @sql_count
SET @sql_count = 0


IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_R22_CERIS_DIV22_STATUS'
      GOTO BL_ERROR_HANDLER
   END


--DELETE BORING OLD DUPLICATE RECORDS
DELETE dbo.XX_R22_CERIS_DIV22_STATUS
FROM dbo.XX_R22_CERIS_DIV22_STATUS div
WHERE 
div.CREATION_DATE <> @CURRENT_TIMESTAMP
AND
1 <
(SELECT COUNT(1) FROM dbo.XX_R22_CERIS_DIV22_STATUS 
 WHERE 
 EMPL_ID = div.EMPL_ID 
 AND DIVISION = div.DIVISION
 AND DIVISION_START_DT = div.DIVISION_START_DT
 AND ISNULL(DIVISION_FROM, '') = ISNULL(div.DIVISION_FROM, '')
 )

SET @SQLServer_error_code = @@ERROR

PRINT 'After Delete of Duplicate Records'
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG1
PRINT 'Select Stg1 Row Count: ' 
PRINT @sql_count
SET @sql_count = 0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 419 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG
PRINT 'Select Stg Row Count: ' 
PRINT @sql_count
SET @sql_count = 0


IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 
      SET @error_msg_placeholder1 = 'delete'
      SET @error_msg_placeholder2 = 'duplicate records from XX_R22_CERIS_DIV16_STATUS'
      GOTO BL_ERROR_HANDLER
   END


--INSERT UKNOWN RECORD FOR EMPLOYEES WHO WERE IN DIV22, 
--BUT FELL OFF THE CERIS RESEARCH FILE FOR SOME REASON
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 442 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
INSERT INTO dbo.XX_R22_CERIS_DIV22_STATUS
(EMPL_ID, DIVISION, DIVISION_START_DT,
   DIVISION_FROM, CREATED_BY, CREATION_DATE)
SELECT 
  EMPL_ID, '??', @CURRENT_TIMESTAMP,
  '??', SUSER_SNAME(), @CURRENT_TIMESTAMP
FROM dbo.XX_R22_CERIS_DIV22_STATUS div
WHERE 
CREATION_DATE = (SELECT MAX(CREATION_DATE) FROM dbo.XX_R22_CERIS_DIV22_STATUS WHERE EMPL_ID = div.EMPL_ID)
AND
DIVISION = '22' 
AND 
0 =
(SELECT COUNT(1) FROM dbo.XX_R22_CERIS_FILE_STG WHERE EMPL_ID = div.EMPL_ID)

SET @SQLServer_error_code = @@ERROR

PRINT 'After Correcting for Missing 22 employees'
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG1
PRINT 'Select Stg1 Row Count: ' 
PRINT @sql_count
SET @sql_count = 0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 470 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG
PRINT 'Select Stg Row Count: ' 
PRINT @sql_count
SET @sql_count = 0
IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = '?? records into table XX_R22_CERIS_DIV22_STATUS'
      GOTO BL_ERROR_HANDLER
   END

-- DR-9450 Reapplied changes for CR-8005 TP 05/10/2017
-- Added for div 24 CR-8005
--INSERT UKNOWN RECORD FOR EMPLOYEES WHO WERE IN DIV24, 
--BUT FELL OFF THE CERIS RESEARCH FILE FOR SOME REASON
INSERT INTO dbo.XX_R22_CERIS_DIV22_STATUS
(EMPL_ID, DIVISION, DIVISION_START_DT,
	 DIVISION_FROM, CREATED_BY, CREATION_DATE)
SELECT 
	EMPL_ID, '??', @CURRENT_TIMESTAMP,
	'??', SUSER_SNAME(), @CURRENT_TIMESTAMP
FROM dbo.XX_R22_CERIS_DIV22_STATUS div
WHERE 
CREATION_DATE = (SELECT MAX(CREATION_DATE) FROM dbo.XX_R22_CERIS_DIV22_STATUS WHERE EMPL_ID = div.EMPL_ID)
AND
DIVISION = '24'
AND 
0 =
(SELECT COUNT(1) FROM dbo.XX_R22_CERIS_FILE_STG WHERE EMPL_ID = div.EMPL_ID)
SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = '?? records into table XX_R22_CERIS_DIV22_STATUS (24)'
      GOTO BL_ERROR_HANDLER
   END



-- CR2350_Begin

--KM track standard hours changes
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 492 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
insert into XX_R22_CERIS_STD_HRS_CHANGES
(
STATUS_RECORD_NUM,
EMPL_ID,
new_STD_HRS,
new_WORK_SCHD_DT,
old_STD_HRS,
old_WORK_SCHD_DT
)
select new.STATUS_RECORD_NUM, 
new.EMPL_ID, 
new.STD_HRS as new_STD_HRS, 
new.WORK_SCHD_DT as new_WORK_SCHD_DT,
old.STD_HRS as old_STD_HRS, 
old.WORK_SCHD_DT as old_WORK_SCHD_DT
from 
XX_R22_CERIS_FILE_STG new
inner join
XX_R22_CERIS_RPT_STG old
on
(new.EMPL_ID=old.EMPL_ID)
where
new.STD_HRS <> old.STD_HRS

-- CR2350_End
PRINT 'After Tracking Hours'
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG1
PRINT 'Select Stg1 Row Count: ' 
PRINT @sql_count
SET @sql_count = 0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 528 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG
PRINT 'Select Stg Row Count: ' 
PRINT @sql_count
SET @sql_count = 0
-- CR2653_begin
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 539 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
TRUNCATE TABLE dbo.XX_R22_CERIS_RPT_STG

PRINT 'After Truncating REport Stage'
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG1
PRINT 'Select Stg1 Row Count: ' 
PRINT @sql_count
SET @sql_count = 0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 552 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG
PRINT 'Select Stg Row Count: ' 
PRINT @sql_count
SET @sql_count = 0


 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 562 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
INSERT INTO dbo.XX_R22_CERIS_RPT_STG
   SELECT STATUS_RECORD_NUM, EMPL_ID, LNAME, FNAME, NAME_INITIALS, HIRE_EFF_DT, IBM_START_DT, TERM_DT, MGR_SERIAL_NUM, MGR_LNAME, 
          MGR_INITIALS, JOB_FAM, JOB_FAM_DT, SAL_BAND, LVL_DT_1, DIVISION, DIVISION_START_DT, DEPT, DEPT_START_DT, DEPT_SUF_DT, 
          FLSA_STAT, EXEMPT_DT, POS_CODE, POS_DESC, POS_DT, REG_TEMP, STAT3, EMPL_STAT3_DT, STATUS, EMPL_STAT_DT, STD_HRS, 
          WORK_SCHD_DT, LOA_BEG_DT, LOA_END_DT, LOA_TYPE, LVL_SUFFIX, DIVISION_FROM, WORK_OFF, CURR_DIV_FUNC_CODE, CURR_REP_LVL_CODE, 
          PREV_DIV_FUNC_CODE, PREV_REP_LVL_CODE, MGR2_LNAME, MGR2_INITIALS, MGR3_LNAME, MGR3_INITIALS, HIRE_TYPE, HIRE_PRGM, SEPRSN, 
          DEPT_FROM, VACELGD, CMPLN, BLDG_ID, DEPT_SHIFT_DT, DEPT_SHIFT_1, MGR_FLAG, SALARY_DT, ASTYP, ASNTYP,
          REFERENCE1, REFERENCE2, REFERENCE3, REFERENCE4, REFERENCE5, CREATION_DATE, CREATED_BY, UPDATE_DATE, UPDATED_BY
     FROM dbo.XX_R22_CERIS_FILE_STG

SET @SQLServer_error_code = @@ERROR

PRINT 'After Inserting into R{T Stage'
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG1
PRINT 'Select Stg1 Row Count: ' 
PRINT @sql_count
SET @sql_count = 0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 585 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG
PRINT 'Select Stg Row Count: ' 
PRINT @sql_count
SET @sql_count = 0


IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to insert records into table XX_R22_CERIS_RPT_STG failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_R22_CERIS_RPT_STG'
      GOTO BL_ERROR_HANDLER
   END

-- CR2653_end

-- CR2577_begin

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 608 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
EXEC @ret_code = dbo.XX_R22_CERIS_UPDATE_ASSIGNMENT_SP
   @in_STATUS_RECORD_NUM     = @in_STATUS_RECORD_NUM,
   @out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
   @out_STATUS_DESCRIPTION   = @out_STATUS_DESCRIPTION OUTPUT

IF @ret_code <> 0 OR @@ERROR <> 0 GOTO BL_ERROR_HANDLER

-- CR2577_end

PRINT 'Before NOT 22 or NOT Status 0'
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG where DIVISION <> '22' or STATUS <> '0'
PRINT 'To be deleted Row Count: ' 
PRINT @sql_count
SET @sql_count = 0

/*
Requirement2: Only load employees with a stat2 = 0; active.
*/

-- Reapplied changed of CR-8005 TP 05/10/2017
DELETE FROM dbo.XX_R22_CERIS_FILE_STG
WHERE division not in ('22','24') -- DR9450
OR status <> '0'

PRINT 'After NOT 22, 24 or NOT Status 0'
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG1
PRINT 'Select Stg1 Row Count: ' 
PRINT @sql_count
SET @sql_count = 0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 642 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG
PRINT 'Select Stg Row Count: ' 
PRINT @sql_count
SET @sql_count = 0


/*
PRINT 'Clear and populate table XX_R22_CERIS_BLUEPAGES_HIST ...'

-- clear table XX_R22_CERIS_BLUEPAGES_HIST for each interface run
DELETE dbo.XX_R22_CERIS_BLUEPAGES_HIST

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 659 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
INSERT INTO dbo.XX_R22_CERIS_BLUEPAGES_HIST(EMPL_ID, INTERNET_ID)
   SELECT SERIAL_NUM, ISNULL(INTERNETID, 'place.holder@us.ibm.com')
     FROM ETIME_RPT..CFRPTADM.IBM_BCS

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to insert records into table XX_R22_CERIS_BLUEPAGES_HIST failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_R22_CERIS_BLUEPAGES_HIST'
      GOTO BL_ERROR_HANDLER
   END

*/


 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 678 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
exec (@CLOSE_KEY)

 
 
RETURN(0)

BL_ERROR_HANDLER:

/*
 * Since BEGIN TRANSACTION and ROLLBACK TRANSACTION for transactions that involve a non-SQL Server table
 * causes error 7391, provide "manual rollback" here by emptying the affected IMAPS tables.
 */


 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 694 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
TRUNCATE TABLE dbo.XX_R22_CERIS_FILE_STG 

PRINT 'After Manual Rollback Truncate of File Stage'
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG1
PRINT 'Select Stg1 Row Count: ' 
PRINT @sql_count
SET @sql_count = 0

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 705 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
SELECT @sql_count = COUNT(1) FROM XX_R22_CERIS_FILE_STG
PRINT 'Select Stg Row Count: ' 
PRINT @sql_count
SET @sql_count = 0


 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 714 : XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.sql '  --CR9296
 
EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_code,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

/*
   BEGIN
      PRINT 'The decryption operation results in error.'
      SET @out_SYS_ERROR_FLAG = 'SYS_ERROR'
   END
*/



RETURN(1)



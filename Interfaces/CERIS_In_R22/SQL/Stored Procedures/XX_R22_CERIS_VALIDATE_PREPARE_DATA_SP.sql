USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE ID = object_id(N'[dbo].[XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP]
GO

CREATE PROCEDURE [dbo].[XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP]
(
@in_STATUS_RECORD_NUM      integer,
@out_SQLServer_error_code  integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION    varchar(255) = NULL OUTPUT
)
AS
/************************************************************************************************
Name:       XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP
Author:     V Veera
Created:    05/20/2008
Purpose:    Populate the temporary table XX_R22_CERIS_CP_STG using source data from table XX_R22_CERIS_FILE_STG.
            Perform the same validations as the Costpoint Employee Basic preprocessor
            Log failed validations in table XX_R22_CERIS_VALIDAT_ERRORS.
            Augment valid data and inserts them into staging table.
            Augmented data are to be inserted to Costpoint tables directly.
            Called by XX_R22_CERIS_RUN_INTERFACE.
Parameters: 
Result Set: None
Notes:

CP600000586 03/06/2009 Reference BP&S Service Request CR1970
            Implement new business rule to determine Long Term Supplemental employee.


CP600000631 04/23/2009 Reference BP&S Service Request CR2049
            Implement new business rule to determine employee's FLSA exempt status.

CP600000660 06/04/2009 Reference BP&S Service Request CR2128
            Implement new business rule for salary rate calculation of exempt supplemental co-op employees 
            (logic change for all those with daily salary rate in CERIS file).

CP600000708 09/10/2009 Reference BP&S Service Request CR2320
            LAB_GRP_TYPE currently being applied to employees with Reg Temp = 8 and stat3 = 6
            (Flex Work Leaves of absence) is R; it should be RR.

CR9296 - gea - 4/10/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
CR9296 - gea - 4/25/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
************************************************************************************************/



DECLARE @SP_NAME                   sysname,
        @S_EMPL_TYPE_CD            char(1),
		@LAB_GRP_TYPE              varchar(3),
        @IMAPS_error_code          integer,
        @SQLServer_error_code      integer,
        @row_count                 integer,
        @error_msg_placeholder1    sysname,
        @error_msg_placeholder2    sysname,
        @error_type                integer,
        @ret_code                  integer,
        @status_error_code         integer,		
        @DIV_22_COMPANY_ID         varchar(10)

-- set local constants
 
 
 
PRINT '' --CR9296 *~^
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9296 *~^
-- *~^
SET @SP_NAME = 'XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP'
-- initialize local variables
SET @status_error_code = 1

PRINT 'The status record number passed in was : ' + cast(@in_STATUS_RECORD_NUM as varchar)
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 89 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
SELECT @DIV_22_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'CERIS_R22'


SET @S_EMPL_TYPE_CD = 'R'



PRINT 'Process Stage CERIS_R2 - Validate and load CERIS data into staging tables ...'

-- verify that required input parameters are supplied, if not try to get it, if can't then error out
-- CR9296 general improvement
IF @in_STATUS_RECORD_NUM IS NULL
   BEGIN
      -- go get it
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 109 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
      select @in_STATUS_RECORD_NUM = STATUS_RECORD_NUM
      from dbo.XX_IMAPS_INT_STATUS
      where
      interface_name='CERIS_R22'
      and 
      STATUS_CODE not in ('COMPLETED', 'RESET')
   END 

IF @in_STATUS_RECORD_NUM IS NULL
  BEGIN
    SET @error_type = 6
    GOTO BL_ERROR_HANDLER
  END
   

-- verify that source data exist to continue processing
IF (select COUNT(1) from dbo.XX_R22_CERIS_FILE_STG) = 0 
   BEGIN
      PRINT 'No EMPLOYEES IN DIVISION 22 IN THE FILE - CHECK THAT FIRST'
      SET @error_type = 1
      GOTO BL_ERROR_HANDLER
   END

/*
 * Staging and error tables whose data come from table XX_R22_CERIS_FILE_STG
 * are truncated in XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP.
 */


-- Validate Employee ID
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 144 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
INSERT INTO dbo.XX_R22_CERIS_VALIDAT_ERRORS(EMPL_ID, STATUS_RECORD_NUM, ERROR_DESC)
   SELECT EMPL_ID, @in_STATUS_RECORD_NUM, ('EMPL ID value ' + EMPL_ID + ' is not alphanumeric.')
     FROM dbo.XX_R22_CERIS_FILE_STG
    WHERE PATINDEX('%[a-z0-9]%', EMPL_ID) = 0 -- pattern is not found

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END



/*
Halfway 
Requirement 12:	Determine and populate the appropriate GLC beginning with R followed by Job Family and then band.
-- Validate GLC
*/


 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 168 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
INSERT INTO dbo.XX_R22_CERIS_VALIDAT_ERRORS
   (EMPL_ID, STATUS_RECORD_NUM, ERROR_DESC)
   SELECT EMPL_ID, @in_STATUS_RECORD_NUM, 'GLC code R' + (JOB_FAM + SAL_BAND) + ' or GENL_AVG_RT_AMT is invalid.'
     FROM dbo.XX_R22_CERIS_FILE_STG
    WHERE ('R'+JOB_FAM + SAL_BAND) NOT IN (SELECT GENL_LAB_CAT_CD FROM IMAR.DELTEK.GENL_LAB_CAT where COMPANY_ID = @DIV_22_COMPANY_ID)


SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END



-- Validate FLSA exemption
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 192 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
INSERT INTO dbo.XX_R22_CERIS_VALIDAT_ERRORS
   (EMPL_ID, STATUS_RECORD_NUM, ERROR_DESC)
    SELECT EMPL_ID, @in_STATUS_RECORD_NUM, 'FLSA_STAT ' + FLSA_STAT + ' is invalid.'
      FROM dbo.XX_R22_CERIS_FILE_STG
     WHERE FLSA_STAT <> 'E'
       AND FLSA_STAT <> 'N'

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END



-- Validate ORG_ID/DEPARTMENT
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 216 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
INSERT INTO dbo.XX_R22_CERIS_VALIDAT_ERRORS
   (EMPL_ID, STATUS_RECORD_NUM, ERROR_DESC)
   SELECT EMPL_ID, @in_STATUS_RECORD_NUM, 'DEPT ' + SUBSTRING(DEPT,1,3) + ' does not exist in Costpoint.'
     FROM dbo.XX_R22_CERIS_FILE_STG
    WHERE LEFT(DEPT,3) NOT IN (SELECT ORG_ABBRV_CD FROM IMAR.DELTEK.ORG WHERE ORG_ABBRV_CD <> '' AND COMPANY_ID = @DIV_22_COMPANY_ID)

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END



PRINT 'Check validation results and determine processing status ...'

/* Commented out for the GLC AVG_AMT > 0.00001 and < 99999.99

/*
 * This scenario: ALL input data did not pass validation due mostly to insufficient Costpoint data setup.
 * Processing is halted here.
 */


DECLARE @source_rec_count integer, @bad_rec_count integer

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 248 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
SELECT @source_rec_count = COUNT(1) FROM dbo.XX_R22_CERIS_FILE_STG
SELECT @bad_rec_count = COUNT(DISTINCT(EMPL_ID)) FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS

IF (@source_rec_count > 0 AND @bad_rec_count > 0) AND (@source_rec_count = @bad_rec_count)
   BEGIN
      SET @error_type = 5
      GOTO BL_ERROR_HANDLER
   END

*/


-- CP600000660_Begin
-- blank SALARY_DT causes interface to not recognize logic change
-- getting rid of blank SALARY_DT with the following
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 268 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
update XX_R22_CERIS_FILE_STG
set SALARY_DT = IBM_START_DT
where len(SALARY_DT) = 0
or SALARY_DT is null
-- CP600000660_End

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 279 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
update XX_R22_CERIS_FILE_STG
set TERM_DT = null
where len(TERM_DT)=0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 288 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
update XX_R22_CERIS_FILE_STG
set EMPL_STAT3_DT = null
where len(EMPL_STAT3_DT)=0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 297 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
update XX_R22_CERIS_FILE_STG
set hire_eff_dt = null
where len(hire_eff_dt)=0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 306 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
update XX_R22_CERIS_FILE_STG
set IBM_START_DT = null
where len(IBM_START_DT)=0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 315 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
update XX_R22_CERIS_FILE_STG
set JOB_FAM_DT = null
where len(JOB_FAM_DT)=0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 324 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
update XX_R22_CERIS_FILE_STG
set POS_DT = null
where len(POS_DT)=0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 333 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
update XX_R22_CERIS_FILE_STG
set DIVISION_START_DT = null
where len(DIVISION_START_DT)=0


 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 342 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
update XX_R22_CERIS_FILE_STG
set DEPT_START_DT = null
where len(DEPT_START_DT)=0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 351 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
update XX_R22_CERIS_FILE_STG
set EMPL_STAT_DT = null
where len(EMPL_STAT_DT)=0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 360 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
update XX_R22_CERIS_FILE_STG
set LVL_DT_1 = null
where len(LVL_DT_1)=0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 369 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
update XX_R22_CERIS_FILE_STG
set DEPT_START_DT = null
where len(DEPT_START_DT)=0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 378 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
update XX_R22_CERIS_FILE_STG
set DEPT_SUF_DT = null
where len(DEPT_SUF_DT)=0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 387 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
update XX_R22_CERIS_FILE_STG
set EXEMPT_DT = null
where len(EXEMPT_DT)=0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 396 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
update XX_R22_CERIS_FILE_STG
set WORK_SCHD_DT = null
where len(WORK_SCHD_DT)=0

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 405 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
update XX_R22_CERIS_FILE_STG
set SALARY_DT = null
where len(SALARY_DT)=0

/*
Requirements
11.	Select appropriate org from Org table where CERIS department = the last 4 characters of the org.
12.	Determine and populate the appropriate GLC beginning with R followed by Job Family and then band.

halfway determined in this query and updated after insert
7.	Populate the employee_class_cd field on the empl_lab_info table with `1' for Regular or `2' for Non-regular using the following formula.
13.	Determine and populate Labor Group by selecting the first character of the Org, previously identified by department, and adding the Employee Class, also previously determined.

 */


 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 423 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
INSERT INTO dbo.XX_R22_CERIS_CP_STG
   (
	
	/*employee info*/


	EMPL_ID, LAST_NAME, FIRST_NAME, MID_NAME,
    SPVSR_NAME, 
	EMAIL_ID,

	/*effective dates*/	


    ORIG_HIRE_DT, ADJ_HIRE_DT, TERM_DT,
    JF_DT, POS_DT, DIVISION_START_DT, 
    DEPT_ST_DT, EMPL_STAT_DT, EMPL_STAT3_DT, LVL_DT_1,
    DEPT_DT, DEPT_SUF_DT, 
    EXEMPT_DT, 
    WORK_SCHD_DT, 
	SALARY_DT,

	/*HR info*/


    HRLY_AMT, 
    SAL_AMT, 
    ANNL_AMT,

    EXMPT_FL, S_EMPL_TYPE_CD, EMPL_CLASS_CD,
	ORG_ID, 
    TITLE_DESC,
    LAB_GRP_TYPE, 
    GENL_LAB_CAT_CD,
    REASON_DESC, 
    WORK_YR_HRS_NO)
	SELECT 
			/*employee info*/


			a.EMPL_ID, a.LNAME, a.FNAME, a.NAME_INITIALS,
           CAST((a.MGR_LNAME + ',' + a.MGR_INITIALS) AS varchar(25)),
           'place.holder@us.ibm.com',



			/*effective dates*/	
			left(hire_eff_dt, 4) + '-' + substring(hire_eff_dt, 5, 2) + '-' + right(hire_eff_dt, 2),
			left(IBM_START_DT, 4) + '-' + substring(IBM_START_DT, 5, 2) + '-' + right(IBM_START_DT, 2),
			isnull(left(TERM_DT, 4), null) + '-' + substring(TERM_DT, 5, 2) + '-' + right(TERM_DT, 2),	
			left(JOB_FAM_DT, 4) + '-' + substring(JOB_FAM_DT, 5, 2) + '-' + right(JOB_FAM_DT, 2),	
			left(POS_DT, 4) + '-' + substring(POS_DT, 5, 2) + '-' + right(POS_DT, 2),
			left(DIVISION_START_DT, 4) + '-' + substring(DIVISION_START_DT, 5, 2) + '-' + right(DIVISION_START_DT, 2),
			left(DEPT_START_DT, 4) + '-' + substring(DEPT_START_DT, 5, 2) + '-' + right(DEPT_START_DT, 2),	
			
			ISNULL( 
			left(EMPL_STAT_DT, 4) + '-' + substring(EMPL_STAT_DT, 5, 2) + '-' + right(EMPL_STAT_DT, 2),
			left(hire_eff_dt, 4) + '-' + substring(hire_eff_dt, 5, 2) + '-' + right(hire_eff_dt, 2)
			),

			left(EMPL_STAT3_DT, 4) + '-' + substring(EMPL_STAT3_DT, 5, 2) + '-' + right(EMPL_STAT3_DT, 2),
			left(LVL_DT_1, 4) + '-' + substring(LVL_DT_1, 5, 2) + '-' + right(LVL_DT_1, 2),	
			left(DEPT_START_DT, 4) + '-' + substring(DEPT_START_DT, 5, 2) + '-' + right(DEPT_START_DT, 2),	
			left(DEPT_SUF_DT, 4) + '-' + substring(DEPT_SUF_DT, 5, 2) + '-' + right(DEPT_SUF_DT, 2),
			
			ISNULL( 
			left(EXEMPT_DT, 4) + '-' + substring(EXEMPT_DT, 5, 2) + '-' + right(EXEMPT_DT, 2),
			left(hire_eff_dt, 4) + '-' + substring(hire_eff_dt, 5, 2) + '-' + right(hire_eff_dt, 2)
			),
			left(WORK_SCHD_DT, 4) + '-' + substring(WORK_SCHD_DT, 5, 2) + '-' + right(WORK_SCHD_DT, 2),
			left(SALARY_DT, 4) + '-' + substring(SALARY_DT, 5, 2) + '-' + right(SALARY_DT, 2),



		   /*HR info*/
			/*update salary information after insert*/
		   .00 ,
		   .00 ,
		   .00 ,  
			a.FLSA_STAT, @S_EMPL_TYPE_CD,
		
			/* update empl_class_cd after insert Requirement 14: halfway*/ 


			'1', 
			d.ORG_ID, CAST((a.POS_CODE + '-' + a.POS_DESC) AS varchar(30)),


		    /*update lab_grp_type after insert Requirement 13: halfway*/

			'R',
           --LEFT(d.L5_ORG_SEG_ID, 1),

           c.GENL_LAB_CAT_CD,
           CAST((CAST(a.REG_TEMP AS varchar(5)) + a.STATUS + ISNULL(a.STAT3, '')) AS varchar(30)),
			/*maybe work_yr_hrs_no after update*/


           (52.0 * a.STD_HRS)

      FROM dbo.XX_R22_CERIS_FILE_STG a,
           IMAR.DELTEK.GENL_LAB_CAT c,
           IMAR.DELTEK.ORG d
     WHERE ('R'+a.JOB_FAM + a.SAL_BAND) = c.GENL_LAB_CAT_CD
       AND LEFT(a.DEPT,3) =  d.ORG_ABBRV_CD 
       AND a.EMPL_ID not in (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)
       AND c.COMPANY_ID = d.COMPANY_ID
       AND d.COMPANY_ID = @DIV_22_COMPANY_ID



SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 3
      GOTO BL_ERROR_HANDLER
   END



/*UPDATE DIV 22 SALARY REQUIREMENTS

Requirement 4:
Extrapolate salary amount provided in the file for each status type (monthly, daily, hourly) to an annual amount, a weekly amount, and an hourly amount using weekly scheduled work hours provided in the file and the following formula.

*	If in the CERIS file stat1||stat2 = `30' and exmt = `E' and stat3 <> `2' then the salary amount provided in the file is at a daily rate.  
Annual amount = (salary amount provided in the file) x (scheduled work hours / 8) x 52
Weekly amount = Annual amount / 52
Hourly amount = Weekly amount / scheduled work hours

*	If in the CERIS file stat1||stat2 = `30' and exmt = `N' and stat3 <> `2' then the salary amount provided in the file is at an hourly rate.
Annual amount = (salary amount provided in the file) x (scheduled work hours) x 52
Weekly amount = Annual amount / 52
Hourly amount = salary amount provided in the file

*	Otherwise, the salary amount provided in the file is at a monthly rate.
Annual amount = salary amount provided in the file x 12
Weekly amount = Annual amount / 52
Hourly amount = Weekly amount / scheduled work hours


*/

-- CP600000660_Begin
-- old logic is being removed
/*
--daily
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 565 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
UPDATE XX_R22_CERIS_CP_STG
SET 
ANNL_AMT = SALARY * (ceris.STD_HRS / 8.0) * 52.0,
SAL_AMT =  SALARY * (ceris.STD_HRS / 8.0),
HRLY_AMT = SALARY * (ceris.STD_HRS / 8.0) / ceris.STD_HRS
FROM 
XX_R22_CERIS_CP_STG cp
INNER JOIN
XX_R22_CERIS_FILE_STG ceris
on
(cp.EMPL_ID = ceris.EMPL_ID)
WHERE 
RTRIM(ceris.REG_TEMP)+RTRIM(ceris.STATUS) = '30'
AND
RTRIM(ceris.STAT3)<> '2'
AND
FLSA_STAT ='E'
*/



/* this is the new daily logic */
-- new daily logic for Exempt Supplemental Co-Ops
-- Treat CERIS salary as daily rate.
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 593 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
UPDATE XX_R22_CERIS_CP_STG
   SET ANNL_AMT = ceris.SALARY * 5.0 * 52.0,              -- amt/year = amt/day * day/week * week/year
       SAL_AMT  = ceris.SALARY * 5.0,                     -- amt/week = amt/day * (day/week)
       HRLY_AMT = ceris.SALARY / ((ceris.STD_HRS / 5.0))  -- amt/hr = amt/day / ((hours/week) / (day/week))
  FROM XX_R22_CERIS_CP_STG cp
       INNER JOIN
       XX_R22_CERIS_FILE_STG ceris
       ON
       (cp.EMPL_ID = ceris.EMPL_ID)
 WHERE RTRIM(ceris.REG_TEMP) + RTRIM(ceris.STATUS) = '30'
   AND RTRIM(ceris.STAT3) <> '2'
   AND ceris.FLSA_STAT = 'E'
-- these are the special co-ops
   AND (ceris.JOB_FAM = '04A' and ceris.POS_CODE in ('501A', '501B', '501C'))


-- Rest of Exempt Supplemental 
-- Treat CERIS salary as weekly rate; apparently these people work at most 8 hours a week.
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 617 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
UPDATE XX_R22_CERIS_CP_STG
   SET ANNL_AMT = ceris.SALARY * 52.0,            -- amt/year = amt/week * week/year
       SAL_AMT  = ceris.SALARY,                   -- amt/week = amt/week
       HRLY_AMT = ceris.SALARY / ceris.STD_HRS    -- amt/hr = amt/week / (hr/week)
  FROM XX_R22_CERIS_CP_STG cp
       INNER JOIN
       XX_R22_CERIS_FILE_STG ceris
       ON
       (cp.EMPL_ID = ceris.EMPL_ID)
 WHERE RTRIM(ceris.REG_TEMP) + RTRIM(ceris.STATUS) = '30'
   AND RTRIM(ceris.STAT3) <> '2'
   AND ceris.FLSA_STAT = 'E'
-- not the special co-ops
   AND NOT (ceris.JOB_FAM = '04A' and ceris.POS_CODE in ('501A', '501B', '501C'))

-- CP600000660_End


--hourly
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 642 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
UPDATE XX_R22_CERIS_CP_STG
SET 
ANNL_AMT = SALARY * ceris.STD_HRS * 52.0,
SAL_AMT =  SALARY * ceris.STD_HRS,
HRLY_AMT = SALARY
FROM 
XX_R22_CERIS_CP_STG cp
INNER JOIN
XX_R22_CERIS_FILE_STG ceris
on
(cp.EMPL_ID = ceris.EMPL_ID)
WHERE 
RTRIM(ceris.REG_TEMP)+RTRIM(ceris.STATUS) = '30'
AND
RTRIM(ceris.STAT3)<> '2'
AND
ceris.FLSA_STAT ='N'

--monthly
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 667 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
UPDATE XX_R22_CERIS_CP_STG
SET 
ANNL_AMT = ceris.SALARY * 12.0,
SAL_AMT =  ceris.SALARY * 12.0/ 52.0,
HRLY_AMT = (ceris.SALARY * 12.0/ 52.0) / ceris.STD_HRS
FROM 
XX_R22_CERIS_CP_STG cp
INNER JOIN
XX_R22_CERIS_FILE_STG ceris
on
(cp.EMPL_ID = ceris.EMPL_ID)
WHERE 
cp.ANNL_AMT = .00



/*
Requirement 8: (Note: See CR2049 (CP600000631) for changes)
If in the CERIS file stat1||stat2 = `30' and exmt = `N' and stat3 <> `2' 
then on empl_lab info set exmpt = `N' and s_hrly_sal_cd = `H'.  

Otherwise, set exmpt = `Y' and s_hrly_sal_cd = `S'.
*/



 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 695 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
UPDATE XX_R22_CERIS_CP_STG
   SET S_HRLY_SAL_CD = 'H',
       EXMPT_FL = 'N'
  FROM XX_R22_CERIS_CP_STG cp
       INNER JOIN
       XX_R22_CERIS_FILE_STG ceris
       ON
       (cp.EMPL_ID = ceris.EMPL_ID)
 WHERE ceris.FLSA_STAT = 'N'
-- CP600000631_Begin
-- AND RTRIM(ceris.REG_TEMP) + RTRIM(ceris.STATUS) = '30'
-- AND RTRIM(ceris.STAT3) <> '2'
-- CP600000631_End


 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 714 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
UPDATE XX_R22_CERIS_CP_STG
   SET S_HRLY_SAL_CD = 'S',
       EXMPT_FL = 'Y'
 WHERE S_HRLY_SAL_CD IS NULL


/*UPDATE EMPL_CLASS_CD REQUIREMENTS

Requirement 7:	Populate the employee_class_cd field on the empl_lab_info table with `1' for Regular or `2' for Non-regular using the following formula.

Employee is non-regular when band = 6 or when stat1 = 3, 
otherwise employee is regular.
*/


 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 732 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
UPDATE XX_R22_CERIS_CP_STG
SET EMPL_CLASS_CD = '2'
FROM 
XX_R22_CERIS_CP_STG cp
INNER JOIN
XX_R22_CERIS_FILE_STG ceris
on
(cp.EMPL_ID = ceris.EMPL_ID)
WHERE
ceris.SAL_BAND = '06' 
OR
ceris.REG_TEMP = '3'


/*Augment LAB_GRP_TYPE

Requirement 13:	Determine and populate Labor Group
The first character should always be 'R'.
The second character could be R (Regular), L(Long Term Supp), or S (Short Term Supp), determined by the status 1 field in the CERIS file.
To derive the second character use the following logic:
If status 1 in ('1','2','4','5') then 'R'
If status 1 = 3 then 'S'
If status 1 = 8 then 'L'
*/


--UPDATE XX_R22_CERIS_CP_STG
--SET LAB_GRP_TYPE = LAB_GRP_TYPE+EMPL_CLASS_CD

/* RR - Research Regular */


 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 765 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
UPDATE XX_R22_CERIS_CP_STG
   SET LAB_GRP_TYPE = LAB_GRP_TYPE + 'R'
  FROM XX_R22_CERIS_CP_STG cp
       INNER JOIN
       XX_R22_CERIS_FILE_STG ceris
       ON
       (cp.EMPL_ID = ceris.EMPL_ID)
 WHERE ceris.REG_TEMP in ('1', '2', '4', '5')

-- CP600000708_Begin

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 781 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
UPDATE dbo.XX_R22_CERIS_CP_STG
   SET LAB_GRP_TYPE = LAB_GRP_TYPE + 'R'
  FROM dbo.XX_R22_CERIS_CP_STG cp
       INNER JOIN
       dbo.XX_R22_CERIS_FILE_STG ceris
       ON
       (cp.EMPL_ID = ceris.EMPL_ID)
 WHERE ceris.REG_TEMP = '8'
   AND ceris.STAT3 = '6'

-- CP600000708_End

-- CP600000586_Begin

/*RL Research Long Term Supp */


/*
UPDATE XX_R22_CERIS_CP_STG
   SET LAB_GRP_TYPE = LAB_GRP_TYPE + 'L'
  FROM XX_R22_CERIS_CP_STG cp
       INNER JOIN
       XX_R22_CERIS_FILE_STG ceris
       ON
       (cp.EMPL_ID = ceris.EMPL_ID)
 WHERE ceris.REG_TEMP = '8'
*/



/*
 * New rules for identifying Long Term Supplemental employees:  
 *
 * Employee Status - 1st Position = 3 (Supplemental)
 * Employee Status - 2nd Position = 0 (Active)
 * Employee Status - 3rd Position = 2 (Long-Term Supplemental)
 */



/* RL Research Long Term Supp 1 */
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 821 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
UPDATE dbo.XX_R22_CERIS_CP_STG
   SET LAB_GRP_TYPE = LAB_GRP_TYPE + 'L'
  FROM dbo.XX_R22_CERIS_CP_STG cp
       INNER JOIN
       dbo.XX_R22_CERIS_FILE_STG ceris
       ON
       (cp.EMPL_ID = ceris.EMPL_ID)
 WHERE ceris.REG_TEMP = '3'
   AND ceris.STAT3 = '2'


/* RL Research Long Term Supp 2 Alternate Work Arrangement */

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 836 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
UPDATE dbo.XX_R22_CERIS_CP_STG
   SET LAB_GRP_TYPE = LAB_GRP_TYPE + 'L'
  FROM dbo.XX_R22_CERIS_CP_STG cp
       INNER JOIN
       dbo.XX_R22_CERIS_FILE_STG ceris
       ON
       (cp.EMPL_ID = ceris.EMPL_ID)
 WHERE ceris.REG_TEMP = '8'
   AND ceris.STAT3 = '2'


/* RS - Research Short Term Supp */

/*
UPDATE XX_R22_CERIS_CP_STG
   SET LAB_GRP_TYPE = LAB_GRP_TYPE + 'S'
  FROM XX_R22_CERIS_CP_STG cp
       INNER JOIN
       XX_R22_CERIS_FILE_STG ceris
       ON
       (cp.EMPL_ID = ceris.EMPL_ID)
 WHERE ceris.REG_TEMP = '3'
*/



/* RS - Research Short Term Supp 3 Alternate Work Arrangement */
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 863 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
UPDATE dbo.XX_R22_CERIS_CP_STG
   SET LAB_GRP_TYPE = LAB_GRP_TYPE + 'S'
  FROM dbo.XX_R22_CERIS_CP_STG cp
       INNER JOIN
       dbo.XX_R22_CERIS_FILE_STG ceris
       ON
       (cp.EMPL_ID = ceris.EMPL_ID)
 WHERE ceris.REG_TEMP = '3'
   AND ceris.STAT3 <> '2'

-- CP600000586_End

-- Augment S_EMPL_TYPE_CD
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 882 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
UPDATE dbo.XX_R22_CERIS_CP_STG
   SET S_EMPL_TYPE_CD = 'P' 
 WHERE EMPL_ID in (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_FILE_STG WHERE STAT3 = '5')

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 4
      GOTO BL_ERROR_HANDLER
   END

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 899 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
UPDATE dbo.XX_R22_CERIS_CP_STG
   SET S_EMPL_TYPE_CD = CASE S_EMPL_TYPE_CD
                           WHEN '1' THEN 'R'
                           WHEN '4' THEN 'P'
                           WHEN '3' THEN 'T'
                           ELSE 'R'
                        END


 
RETURN(0)

BL_ERROR_HANDLER:

IF @error_type = 1
   BEGIN
      SET @IMAPS_error_code = 209 -- No %1 exist to %2 
      SET @error_msg_placeholder1 = 'XX_R22_CERIS_FILE_STG data'
      SET @error_msg_placeholder2 = 'perform validation.'
   END
ELSE IF @error_type = 2
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to insert a record into table XX_R22_CERIS_VALIDAT_ERRORS failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'a record into table XX_R22_CERIS_VALIDAT_ERRORS'
   END
ELSE IF @error_type = 3
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to insert a record into table XX_R22_CERIS_CP_STG failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'a record into table XX_R22_CERIS_CP_STG'
   END
ELSE IF @error_type = 4
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to update records in table XX_R22_CERIS_CP_STG failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'records in table XX_R22_CERIS_CP_STG'
   END
ELSE IF @error_type = 5
   BEGIN
      SET @status_error_code = 210
      SET @IMAPS_error_code = 210 -- %1 failed validation due to %2.
      SET @error_msg_placeholder1 = 'All source XX_R22_CERIS_FILE_STG input records'
      SET @error_msg_placeholder2 = 'insufficient Costpoint data setup'
      SET @SQLServer_error_code = NULL
   END
ELSE IF @error_type = 6
   BEGIN
      SET @IMAPS_error_code = 100 --  Missing required input parameter(s)
      SET @error_msg_placeholder1 = 'Status Record Number'
      SET @error_msg_placeholder2 = 'NOT FOUND'
      SET @SQLServer_error_code = NULL
   END

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 956 : XX_R22_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --CR9296
 
EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_code,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(@status_error_code)

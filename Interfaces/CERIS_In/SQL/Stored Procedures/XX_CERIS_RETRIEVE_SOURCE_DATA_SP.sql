USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_RETRIEVE_SOURCE_DATA_SP]    Script Date: 02/09/2018 17:03:51 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_CERIS_RETRIEVE_SOURCE_DATA_SP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[XX_CERIS_RETRIEVE_SOURCE_DATA_SP]
GO

USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_RETRIEVE_SOURCE_DATA_SP]    Script Date: 02/09/2018 17:03:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO



CREATE  PROCEDURE [dbo].[XX_CERIS_RETRIEVE_SOURCE_DATA_SP]
(
@in_STATUS_RECORD_NUM     integer,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS
/************************************************************************************************
Name:       XX_CERIS_RETRIEVE_SOURCE_DATA_SP
Author:     HVT
Created:    10/05/2005
Purpose:    Retrieve source data from ETIME_RPT..CFRPTADM.
            Called by XX_CERIS_RUN_INTERFACE_SP.
Parameters: 
Result Set: None
Notes:

CP600000284 04/15/2008 (BP&S Change Request No. CR1543)
            Apply the Costpoint column COMPANY_ID to distinguish Division 16's data from those
            of Division 22's. There is one instance.

CR4885 - IMAPS CERIS Interface Changes for Actuals - KM - 2012-05-09
CR6542 - Sal_Base instead of Salary for employees getting commissions - KM - 2013-08-14
CR6534 - Cognos Division Transfer Report (better name: Extra Timecard Report) - KM - 2013-09-10
CR6293 - Div1P - KM - 2013-09-24
CR8761 - Div2G - gea - 2016-07-14  : just added 2G to list of divisions in two lines below.
************************************************************************************************/

DECLARE @SP_NAME                 sysname,
        @DIV_16_COMPANY_ID       varchar(10),
        @IMAPS_error_code        integer,
        @SQLServer_error_code    integer,
        @row_count               integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname

-- set local constants
SET @SP_NAME = 'XX_CERIS_RETRIEVE_SOURCE_DATA_SP'

--CR4885 Begin
--PRINT 'Process Stage CERIS1 - Retrieve CERIS and BluePages data from eT&E system ...'
PRINT 'Process Stage CERIS1 - Retrieve CERIS and BluePages data ...'
--CR4885 End


PRINT 'Clear table XX_CERIS_HIST and all of its associated temporary staging tables ...'

TRUNCATE TABLE dbo.XX_CERIS_HIST
TRUNCATE TABLE dbo.XX_CERIS_CP_STG
TRUNCATE TABLE dbo.XX_CERIS_CP_EMPL_STG
TRUNCATE TABLE dbo.XX_CERIS_CP_EMPL_LAB_STG
TRUNCATE TABLE dbo.XX_CERIS_CP_DFLT_TS_STG
TRUNCATE TABLE dbo.XX_CERIS_RETRO_TS
TRUNCATE TABLE dbo.XX_CERIS_RETRO_TS_PREP
TRUNCATE TABLE dbo.XX_CERIS_RETRO_TS_PREP_ERRORS
TRUNCATE TABLE dbo.XX_CERIS_VALIDAT_ERRORS


-- CP600000284_Begin
SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'CERIS'
-- CP600000284_End


--CR4885 Begin
/*
No longer pulling CERIS data from ETIME linked server

PRINT 'Populate table XX_CERIS_HIST ...'

SELECT @row_count = COUNT(1) FROM ETIME_RPT..CFRPTADM.IBM_CERIS

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to query table ETIME_RPT..CFRPTADM.IBM_CERIS failed.
      SET @error_msg_placeholder1 = 'query'
      SET @error_msg_placeholder2 = 'table ETIME_RPT..CFRPTADM.IBM_CERIS'
      GOTO BL_ERROR_HANDLER
   END

IF @row_count = 0 
   BEGIN
      SET @IMAPS_error_code = 209 -- No %1 exist to %2 
      SET @error_msg_placeholder1 = 'ETIME_RPT..CFRPTADM.IBM_CERIS data'
      SET @error_msg_placeholder2 = 'populate table XX_CERIS_HIST.'
      GOTO BL_ERROR_HANDLER
   END
*/

PRINT 'Verify population of table XX_CERIS_DATA_STG and XX_CERIS_LCDB tables ...'

SET @row_count=0


SELECT @row_count=count(1) from xx_imaps_int_status where interface_name in ('CERIS_LOAD','LCDB_EXTRACT') and status_code not in ('COMPLETED','RESET')

SET @SQLServer_error_code = @@ERROR

IF @row_count<>0 OR @SQLServer_error_code<>0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to %1 %2 failed.
      SET @error_msg_placeholder1 = 'VERIFY INPUT LOAD'
      SET @error_msg_placeholder2 = 'COMPLETED'
      GOTO BL_ERROR_HANDLER
   END




SELECT @row_count = COUNT(1) FROM XX_CERIS_DATA_STG

SET @SQLServer_error_code = @@ERROR

IF @row_count=0 OR @SQLServer_error_code<>0
   BEGIN
      SET @IMAPS_error_code = 209 -- No %1 exist to %2 
      SET @error_msg_placeholder1 = 'XX_CERIS_data_STG data'
      SET @error_msg_placeholder2 = 'process through interface'
      GOTO BL_ERROR_HANDLER
   END

SELECT @row_count = COUNT(1) FROM XX_CERIS_LCDB_CODES_STG

SET @SQLServer_error_code = @@ERROR

IF @row_count=0 OR @SQLServer_error_code<>0
   BEGIN
      SET @IMAPS_error_code = 209 -- No %1 exist to %2 
      SET @error_msg_placeholder1 = 'XX_CERIS_LCDB_CODES_STG data'
      SET @error_msg_placeholder2 = 'process through interface'
      GOTO BL_ERROR_HANDLER
   END

SELECT @row_count = COUNT(1) FROM XX_CERIS_LCDB_EMPL_ASSIGNMENTS_STG

SET @SQLServer_error_code = @@ERROR

IF @row_count=0 OR @SQLServer_error_code<>0
   BEGIN
      SET @IMAPS_error_code = 209 -- No %1 exist to %2 
      SET @error_msg_placeholder1 = 'XX_CERIS_LCDB_EMPL_ASSIGNMENTS_STG data'
      SET @error_msg_placeholder2 = 'process through interface'
      GOTO BL_ERROR_HANDLER
   END
--CR4885 End







--CR4885 Begin
/*
No longer pulling CERIS data from ETIME linked server

--production version
--1M changes
insert into dbo.XX_CERIS_HIST
(
EMPL_ID,
LNAME,
FNAME,
NAME_INITIALS,
HIRE_EFF_DT,
IBM_START_DT,
TERM_DT,
MGR_SERIAL_NUM,
MGR_LNAME,
MGR_INITIALS,
JOB_FAM,
JOB_FAM_DT,
SAL_BAND,
LVL_DT_1,
DIVISION,
DIVISION_START_DT,
DEPT,
DEPT_START_DT,
DEPT_SUF_DT,
FLSA_STAT,
EXEMPT_DT,
POS_CODE,
POS_DESC,
POS_DT,
REG_TEMP,
STAT3,
EMPL_STAT3_DT,
STATUS,
EMPL_STAT_DT,
STD_HRS,
WORK_SCHD_DT,
SALSETID,
WKLNEW,
WKLCITY,
WKLST,
PAY_DIFFERENTIAL,
PAY_DIFFERENTIAL_DT
)
   select EMPLID, LNAME, FNAME, NAME_INIT,
          HIRE_DATE_EFF, IBM_START_DT, TERM_DT,
          MGR_SERIAL_NUM, MGR_LNAME, MGR_INITIAL,
          JOB_FAMILY, JF_DT, SAL_BAND, LVL_DATE_1,
          DIVISION, DIVISION_STRT_DATE,
          DEPT, 
	  ISNULL(DEPT_ST_DATE, DIVISION_STRT_DATE), 
	  DEPT_SUF_DATE,
          FLSA_STAT, EXEMPT_DATE,
          POS_CODE, POS_DESC, POS_DT,
          REG_TEMP,
          STAT3, EMPL_STAT3_DATE, STATUS, EMPL_STAT_DATE,
          STD_HRS, WORK_SCHD_DATE,

	/*todo map from ETIME*/
		SALESTID as SALSETID,
		WKLNEW as WKLNEW,
		WKLYCITY as WKLCITY,
		WKLST as WKLST,
		'?' as PAY_DIFFERENTIAL,
		CREATE_DATE as PAY_DIFFERENTIAL_DT
     from ETIME_RPT..CFRPTADM.IBM_CERIS
    where DIVISION IN ('16','1M')
--1M changes
--change KM 02/02/06


SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to insert records into table XX_CERIS_HIST failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_CERIS_HIST'
      GOTO BL_ERROR_HANDLER
   END
*/



PRINT 'check for ''BAD DATE'' data from CERIS (and move those to validation error table)'
INSERT INTO XX_CERIS_VALIDAT_ERRORS
(EMPL_ID, STATUS_RECORD_NUM, ERROR_DESC, TIME_STAMP)
SELECT SERIAL, @in_STATUS_RECORD_NUM, 'BAD DATE DATA IN CERIS SOURCE FILE', current_timestamp
from xx_ceris_data_stg
where
(HIRE_DATE_EFF not in ('        ','00000000') and isdate(HIRE_DATE_EFF)<>1)
or
(HIRE_DATE_SRD not in ('        ','00000000') and isdate(HIRE_DATE_SRD)<>1)
or
(SEP_DATE not in ('        ','00000000') and isdate(SEP_DATE)<>1)
or
(JOB_FAMILY_DATE_1 not in ('        ','00000000') and isdate(JOB_FAMILY_DATE_1)<>1)
or
(LVL_DATE_1 not in ('        ','00000000') and isdate(LVL_DATE_1)<>1)
or
(DIV_DATE not in ('        ','00000000') and isdate(DIV_DATE)<>1)
or
(DEPT_DATE not in ('        ','00000000') and isdate(DEPT_DATE)<>1)
or
(DEPT_SUF_DATE not in ('        ','00000000') and isdate(DEPT_SUF_DATE)<>1)
or
(EXEMPT_DATE not in ('        ','00000000') and isdate(EXEMPT_DATE)<>1)
or
(POS_DATE_1 not in ('        ','00000000') and isdate(POS_DATE_1)<>1)
or
(EMPL_STAT3_DATE not in ('        ','00000000') and isdate(EMPL_STAT3_DATE)<>1)
or
(EMPL_STAT_DATE not in ('        ','00000000') and isdate(EMPL_STAT_DATE)<>1)
or
(WORK_SCHD_DATE not in ('        ','00000000') and isdate(WORK_SCHD_DATE)<>1)
or
(LOC_WORK_DTE_1 not in ('        ','00000000') and isdate(LOC_WORK_DTE_1)<>1)
or
(SAL_CHG_DTE_1 not in ('        ','00000000') and isdate(SAL_CHG_DTE_1)<>1)

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to insert records into table XX_CERIS_VALIDAT_ERRORS failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_CERIS_VALIDAT_ERRORS'
      GOTO BL_ERROR_HANDLER
   END


INSERT INTO XX_CERIS_VALIDAT_ERRORS
(EMPL_ID, STATUS_RECORD_NUM, ERROR_DESC, TIME_STAMP)
SELECT SERIAL, @in_STATUS_RECORD_NUM, 'ZERO HOURS OR SALARY IN CERIS SOURCE FILE', current_timestamp
from xx_ceris_data_stg
where
cast(cast(WORK_SCHD as float) as int)=0
or
cast(cast(SALARY as float) as int)=0


SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to insert records into table XX_CERIS_VALIDAT_ERRORS failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_CERIS_VALIDAT_ERRORS'
      GOTO BL_ERROR_HANDLER
   END





PRINT 'insert into XX_CERIS_HIST ...'



INSERT INTO XX_CERIS_HIST
(
EMPL_ID,
LNAME,
FNAME,
NAME_INITIALS,
HIRE_EFF_DT,
IBM_START_DT,
TERM_DT,
MGR_SERIAL_NUM,
MGR_LNAME,
MGR_INITIALS,
JOB_FAM,
JOB_FAM_DT,
SAL_BAND,
LVL_SUFFIX,
LVL_DT_1,
DIVISION,
DIVISION_FROM,
DIVISION_START_DT,
DEPT,
DEPT_START_DT,
DEPT_SUF_DT,
FLSA_STAT,
EXEMPT_DT,
POS_CODE,
POS_DESC,
POS_DT,
REG_TEMP,
STAT3,
EMPL_STAT3_DT,
STATUS,
EMPL_STAT_DT,
STD_HRS,
WORK_SCHD_DT,
SALSETID,
WKLNEW,
WKLCITY,
WKLST,
WKL_DT,
PAY_DIFFERENTIAL,
PAY_DIFFERENTIAL_DT,
SALARY,
SALARY_DT,
SALARY_RTE_CD
)
select
rtrim(ltrim(SERIAL)) as EMPL_ID,
upper(rtrim(ltrim(left(NAME_LAST_MIXED,25)))),
upper(rtrim(ltrim(left(NAME_FIRST_MIXED,20)))),
upper(rtrim(ltrim(NAME_INIT))),

case
 when HIRE_DATE_EFF = '        ' THEN NULL
 when HIRE_DATE_EFF = '00000000' THEN NULL
 else cast(HIRE_DATE_EFF as datetime)
end as HIRE_EFF_DT,

case
 when HIRE_DATE_SRD = '        ' THEN NULL
 when HIRE_DATE_SRD = '00000000' THEN NULL
 else cast(HIRE_DATE_SRD as datetime)
end as IBM_START_DT,

case
 when SEP_DATE = '        ' THEN NULL
 when SEP_DATE = '00000000' THEN NULL
 else cast(SEP_DATE as datetime)
end as TERM_DT,

rtrim(ltrim(DEPT_MGR_SER_1)),
upper(rtrim(ltrim(left(DEPT_MGR_NAME_LAST,22)))),
upper(rtrim(ltrim(DEPT_MGR_NAME_INIT))),

rtrim(ltrim(JOB_FAMILY_1)),

case
 when JOB_FAMILY_DATE_1 = '        ' THEN NULL
 when JOB_FAMILY_DATE_1 = '00000000' THEN NULL
 else cast(JOB_FAMILY_DATE_1 as datetime)
end as JOB_FAM_DT,

rtrim(ltrim(LEVEL_PREFIX_1)) as SAL_BAND,
rtrim(ltrim(LEVEL_SUFFIX_1)) as LVL_SUFFIX,

case
 when LVL_DATE_1 = '        ' THEN NULL
 when LVL_DATE_1 = '00000000' THEN NULL
 else cast(LVL_DATE_1 as datetime)
end as LVL_DT_1,

rtrim(ltrim(DIVISION_1)) as DIVISION,
rtrim(ltrim(DIVISION_2)) as DIVISION_FROM,

case
 when DIV_DATE = '        ' THEN NULL
 when DIV_DATE = '00000000' THEN NULL
 else cast(DIV_DATE as datetime)
end as DIVISION_START_DT,

rtrim(ltrim(DEPT_PLUS_SFX)) as DEPT,


case
 when DEPT_DATE = '        ' THEN NULL
 when DEPT_DATE = '00000000' THEN NULL
 else cast(DEPT_DATE as datetime)
end as DEPT_START_DT,

case
 when DEPT_SUF_DATE = '        ' THEN NULL
 when DEPT_SUF_DATE = '00000000' THEN NULL
 else cast(DEPT_SUF_DATE as datetime)
end as DEPT_SUF_DT,

rtrim(ltrim(EX_NE_OUT)) as FLSA_STAT,

case
 when EXEMPT_DATE = '        ' THEN NULL
 when EXEMPT_DATE = '00000000' THEN NULL
 else cast(EXEMPT_DATE as datetime)
end as EXEMPT_DT,

rtrim(ltrim(POS_CODE_1)) as POS_CODE,
rtrim(ltrim(JOB_TITLE)) as POS_DESC,

case
 when POS_DATE_1 = '        ' THEN NULL
 when POS_DATE_1 = '00000000' THEN NULL
 else cast(POS_DATE_1 as datetime)
end as POS_DT,

rtrim(ltrim(EMPL_STAT_1ST)) as REG_TEMP,
rtrim(ltrim(EMPL_STAT_3RD)) as STAT3,

case
 when EMPL_STAT3_DATE = '        ' THEN NULL
 when EMPL_STAT3_DATE = '00000000' THEN NULL
 else cast(EMPL_STAT3_DATE as datetime)
end as EMPL_STAT3_DT, 

rtrim(ltrim(EMPL_STAT_2ND)) as STATUS,

case
 when EMPL_STAT_DATE = '        ' THEN NULL
 when EMPL_STAT_DATE = '00000000' THEN NULL
 else cast(EMPL_STAT_DATE as datetime)
end as  EMPL_STAT_DT,

cast(cast(WORK_SCHD as float) as int) as STD_HRS,

case
 when WORK_SCHD_DATE = '        ' THEN NULL
 when WORK_SCHD_DATE = '00000000' THEN NULL
 else cast(WORK_SCHD_DATE as datetime)
end as  WORK_SCHD_DT,

rtrim(ltrim(SET_ID)) as SALSETID,

rtrim(ltrim(LOC_WORK_1)) as WKLNEW,
rtrim(ltrim(TBWKL_CITY)) as WKLCITY,
rtrim(ltrim(LOC_WORK_ST)) as WKLST,

case
 when LOC_WORK_DTE_1 = '        ' THEN NULL
 when LOC_WORK_DTE_1 = '00000000' THEN NULL
 else cast(LOC_WORK_DTE_1 as datetime)
end as WKL_DT,


'?' as PAY_DIFFERENTIAL,
CREATION_DATE as PAY_DIFFERENTIAL_DT,

--CR6542 begin
case 
	when ((cast(SALARY as decimal(14,2)) <> cast(SAL_BASE as decimal(14,2))) and (cast(SAL_BASE as decimal(14,2))<>0)) then cast(SAL_BASE as decimal(14,2))
	else cast(SALARY as decimal(14,2))
end as SALARY,
--cast(SALARY as decimal(14,2)) as SALARY,
--CR6542 end

case
 when SAL_CHG_DTE_1 = '        ' THEN NULL
 when SAL_CHG_DTE_1 = '00000000' THEN NULL
 else cast(SAL_CHG_DTE_1 as datetime)
end as SALARY_DT,

rtrim(ltrim(SAL_RTE_CDE)) as SALARY_RTE_CD

from xx_ceris_data_stg
where serial not in (select empl_id from xx_ceris_validat_errors)
--where DIVISION_1 in ('16','1M')
--we will filter out records later on


SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to insert records into table XX_CERIS_HIST failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_CERIS_HIST'
      GOTO BL_ERROR_HANDLER
   END


update xx_ceris_hist
set division_start_dt=HIRE_EFF_DT
where division_start_dt is null

update xx_ceris_hist
set dept_start_dt=division_start_dt
where dept_start_dt is null

update xx_ceris_hist
set dept_start_dt=division_start_dt
where dept_start_dt is null

update xx_ceris_hist
set salary_dt=HIRE_EFF_DT
where salary_dt is null

update xx_ceris_hist
set WORK_SCHD_DT=HIRE_EFF_DT
where WORK_SCHD_DT is null


--replace dept_start_dt with division_start_date where null
--replace wkl_dt with hire_date where null
--replace salary_dt with hire_date where null
--replace work_schd_dt with hire_date where null


SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to insert records into table XX_CERIS_HIST failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_CERIS_HIST'
      GOTO BL_ERROR_HANDLER
   END





--change department start date for O&M orgs
update XX_CERIS_HIST
set DEPT_START_DT = cast('2009-01-01' as datetime)
where 
DEPT in
(
'U3GA',
'U39A',
'5CBA',
'5V6A',
'6P3A',
'6QLA',
'7G2A',
'FZNA',
'S8TA',
'T2UA',
'T3DA',
'THVA',
'UABA',
'UBKA',
'ULVA',
'VAHA',
'VCBA',
'XCPA',
'XWHA'
)
and
DEPT_START_DT < cast('2009-01-01' as datetime)

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to insert records into table XX_CERIS_HIST failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'O&M records for 2009 in table XX_CERIS_HIST'
      GOTO BL_ERROR_HANDLER
   END



--CR4885 Begin
/*
Pay Differential no longer part of GLC, but let's keep this here anyway
*/
--1M changes
EXEC @SQLServer_error_code = XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP
			 @out_STATUS_DESCRIPTION = @out_status_description OUTPUT


IF @SQLServer_error_code <> 0
   BEGIN
	  PRINT @out_status_description
      SET @IMAPS_error_code = 204 -- Attempt to insert records into table XX_CERIS_HIST failed.
      SET @error_msg_placeholder1 = 'execute'
      SET @error_msg_placeholder2 = 'XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP'
      GOTO BL_ERROR_HANDLER
   END
--1M changes




--CR6534 begin
PRINT 'Update table XX_CERIS_DIV16_STATUS_ORIG...'

DECLARE @CURRENT_TIMESTAMP datetime
SELECT @CURRENT_TIMESTAMP = CURRENT_TIMESTAMP

--LOAD DIVISION STATUS FROM CURRENT WEEK CERIS TABLE 

--change to treat employees who are new to the file as if they were on the file last week with division=--
INSERT INTO XX_CERIS_DIV16_STATUS_ORIG
(EMPL_ID, DIVISION, DIVISION_START_DT, DIVISION_FROM, CREATED_BY, CREATION_DT)
select c.empl_id, '--', cast('1900-01-01' as smalldatetime), '--' as division_from, SUSER_SNAME(), @CURRENT_TIMESTAMP-7 --need to pretend this happened last week
from xx_ceris_hist c
where
0=(select count(1) from XX_CERIS_DIV16_STATUS_ORIG where empl_id=c.empl_id)

--normal change
INSERT INTO XX_CERIS_DIV16_STATUS_ORIG
(EMPL_ID, DIVISION, DIVISION_START_DT, DIVISION_FROM, CREATED_BY, CREATION_DT)
select c.empl_id, c.division, cast(c.division_start_dt as smalldatetime), c.division_from, SUSER_SNAME(), @CURRENT_TIMESTAMP
from 
xx_ceris_hist c
inner join
XX_CERIS_DIV16_STATUS_ORIG div
on
(
 c.empl_id=div.empl_id
 and
 div.CREATION_DT=  (SELECT MAX(CREATION_DT) FROM XX_CERIS_DIV16_STATUS_ORIG WHERE EMPL_ID = div.EMPL_ID) 
)
where c.term_dt is null --not terminated
and
--values different
(
div.division<>c.division
or
div.DIVISION_START_DT<>cast(c.division_start_dt as smalldatetime)
or
div.DIVISION_FROM<>c.division_from
)

--change to treat terminations as transfers into division=##
INSERT INTO XX_CERIS_DIV16_STATUS_ORIG
(EMPL_ID, DIVISION, DIVISION_START_DT, DIVISION_FROM, CREATED_BY, CREATION_DT)
select c.empl_id, '##', cast(c.term_dt as smalldatetime)+1, c.division as division_from, SUSER_SNAME(), @CURRENT_TIMESTAMP
from 
xx_ceris_hist c
inner join
XX_CERIS_DIV16_STATUS_ORIG div
on
(
 c.empl_id=div.empl_id
 and
 div.CREATION_DT=(SELECT MAX(CREATION_DT) FROM XX_CERIS_DIV16_STATUS_ORIG WHERE EMPL_ID = div.EMPL_ID) 
)
where c.term_dt is not null
and
--values different
(
div.division<>'##'
or
div.DIVISION_START_DT<>(cast(c.term_dt as smalldatetime)+1)
or
div.DIVISION_FROM<>c.division
)


SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_CERIS_DIV16_STATUS_ORIG'
      GOTO BL_ERROR_HANDLER
   END



--INSERT UKNOWN RECORD FOR EMPLOYEES WHO WERE IN DIV16, 
--BUT FELL OFF THE FILE FOR SOME REASON
INSERT INTO XX_CERIS_DIV16_STATUS_ORIG
(EMPL_ID, DIVISION, DIVISION_START_DT,
	 DIVISION_FROM, CREATED_BY, CREATION_DT)
SELECT 
	EMPL_ID, '??', @CURRENT_TIMESTAMP,
	'??', SUSER_SNAME(), @CURRENT_TIMESTAMP
FROM XX_CERIS_DIV16_STATUS_ORIG div
WHERE 
CREATION_DT = (SELECT MAX(CREATION_DT) FROM XX_CERIS_DIV16_STATUS_ORIG WHERE EMPL_ID = div.EMPL_ID)
AND
--CR6534, change this to be for any employee who falls off the file (might be important later)
--DIVISION in ('16','1M') --,'1P') --CR6293 not part of this release
DIVISION not in ('??')
AND 
0 = (SELECT COUNT(1) FROM xx_ceris_hist WHERE empl_id = div.EMPL_ID)



SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = '?? records into table XX_CERIS_DIV16_STATUS_ORIG'
      GOTO BL_ERROR_HANDLER
   END



--now we get ready for the Cognos report (and other things)
truncate table XX_CERIS_DIV16_STATUS

insert into XX_CERIS_DIV16_STATUS
(empl_id, division, division_start_dt, division_from, creation_dt, created_by, prev_division, prev_division_start_dt, prev_division_from, prev_creation_dt)
select 
	cur.empl_id, 
	cur.division, 
	cur.division_start_dt, 
	cur.division_from, 
	cur.creation_dt,
	cur.created_by,
	prev.division as prev_division,
	prev.division_start_dt as prev_division_start_dt,
	prev.division_from as prev_division_from,
	prev.creation_dt as prev_creation_dt

from
xx_ceris_div16_status_orig cur
left join
xx_ceris_div16_status_orig prev
on
(cur.empl_id=prev.empl_id
and
 prev.creation_dt=(select max(creation_dt)
					from xx_ceris_div16_status_orig
					where empl_id=prev.empl_id
					and creation_dt<cur.creation_dt)
)



declare @max_swivel as int

select @max_swivel=cast(parameter_value as int)
from xx_processing_parameters
where interface_name_cd='CERIS'
and parameter_name='DIVISION_START_DATE_max_swivel'

delete t1
from xx_ceris_div16_status t1
where
0<> --not these records (these records are old, the division start date value has been retro-actively overwritten with a new value)
 (select count(1) 
  from xx_ceris_div16_status
  where  empl_id=t1.empl_id
  and	 isnull(prev_creation_dt,'1900-01-01')=t1.creation_dt
  and	 division=isnull(prev_division,'')
  and    isnull(division_from,'')=isnull(prev_division_from,'')
  --not deleting old record if the division_start_date value is being changed by more than X days
  --that's way too long and most likely some sort of user error
  and    abs(datediff(dd, t1.division_start_dt, division_start_dt)) <= @max_swivel --180
)


delete t1 --select *
from xx_ceris_div16_status t1
where
0<> --not these records (these records are old, the division value has been retro-actively overwritten with a new value)
 (select count(1) 
  from xx_ceris_div16_status
  where  empl_id=t1.empl_id
  and	 isnull(prev_creation_dt,'1900-01-01')=t1.creation_dt
  and	 division_start_dt=isnull(prev_division_start_dt,'')
  and    isnull(division_from,'')=isnull(prev_division_from,''))

--CR6534 end



      
PRINT 'Clear and populate table XX_CERIS_PORT_NEW_ORGS ...'

-- clear table XX_CERIS_PORT_NEW_ORGS for each interface run
DELETE dbo.XX_CERIS_PORT_NEW_ORGS

INSERT INTO dbo.XX_CERIS_PORT_NEW_ORGS(DEPT)
   SELECT distinct i.DEPT
	--CR4885 Begin
		FROM xx_ceris_hist i
     --FROM ETIME_RPT..CFRPTADM.IBM_CERIS i
	--CR4885 End
    WHERE i.DEPT not in (select o.ORG_ABBRV_CD
                           from IMAPS.Deltek.ORG o
                          where o.ORG_ABBRV_CD is not null
                            and datalength(rtrim(o.ORG_ABBRV_CD)) > 0
                            and o.COMPANY_ID = @DIV_16_COMPANY_ID) -- CP600000284
     AND i.DIVISION in ('16','1M','1P','2G') --CR6293, 8761
	--CR4885 Begin
     AND isnull(i.TERM_DT,'')=''
	--AND i.TERM_DT IS NULL
	--CR4885 End


SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to insert records into table XX_CERIS_PORT_NEW_ORGS failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_CERIS_PORT_NEW_ORGS'
      GOTO BL_ERROR_HANDLER
   END


/* CHANGE KM 2/7/06 - table XX_CERIS_FIWLR_DIV16_STATUS not being used

PRINT 'Clear and populate table XX_CERIS_FIWLR_DIV16_STATUS ...'

-- clear table XX_CERIS_FIWLR_DIV16_STATUS for each interface run
DELETE dbo.XX_CERIS_FIWLR_DIV16_STATUS

insert into dbo.XX_CERIS_FIWLR_DIV16_STATUS
   (EMPL_ID, LNAME, FNAME, STATUS, DEPT, DIVISION, DIVISION_FROM, DIVISION_START_DT, SERVICE_DT, CREATED_BY, CREATION_DT)
   select EMPLID, LNAME, FNAME, STATUS, DEPT, DIVISION, DIVISION_FROM, DIVISION_STRT_DATE, SERV_DT,
          SUSER_SNAME(), GETDATE()
     from ETIME_RPT..CFRPTADM.IBM_CERIS_HIST

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to insert records into table XX_CERIS_FIWLR_DIV16_STATUS failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_CERIS_FIWLR_DIV16_STATUS'
      GOTO BL_ERROR_HANDLER
   END
*/




PRINT 'Populate XX_CERIS_RPT table ...'

TRUNCATE TABLE XX_CERIS_RPT

INSERT INTO XX_CERIS_RPT
(
EMPL_ID,
LNAME,
FNAME,
NAME_INITIALS,
HIRE_EFF_DT,
IBM_START_DT,
TERM_DT,
MGR_SERIAL_NUM,
MGR_LNAME,
MGR_INITIALS,
JOB_FAM,
JOB_FAM_DT,
SAL_BAND,
LVL_DT_1,
DIVISION,
DIVISION_START_DT,
DEPT,
DEPT_START_DT,
DEPT_SUF_DT,
FLSA_STAT,
EXEMPT_DT,
POS_CODE,
POS_DESC,
POS_DT,
REG_TEMP,
STAT3,
EMPL_STAT3_DT,
STATUS,
EMPL_STAT_DT,
STD_HRS,
WORK_SCHD_DT,
SALSETID,
WKLNEW,
WKLCITY,
WKLST,
PAY_DIFFERENTIAL,
PAY_DIFFERENTIAL_DT,
LVL_SUFFIX,
DIVISION_FROM,
SALARY_RTE_CD,
SALARY_DT,
WKL_DT)
SELECT
EMPL_ID,
LNAME,
FNAME,
NAME_INITIALS,
HIRE_EFF_DT,
IBM_START_DT,
TERM_DT,
MGR_SERIAL_NUM,
MGR_LNAME,
MGR_INITIALS,
JOB_FAM,
JOB_FAM_DT,
SAL_BAND,
LVL_DT_1,
DIVISION,
DIVISION_START_DT,
DEPT,
DEPT_START_DT,
DEPT_SUF_DT,
FLSA_STAT,
EXEMPT_DT,
POS_CODE,
POS_DESC,
POS_DT,
REG_TEMP,
STAT3,
EMPL_STAT3_DT,
STATUS,
EMPL_STAT_DT,
STD_HRS,
WORK_SCHD_DT,
SALSETID,
WKLNEW,
WKLCITY,
WKLST,
PAY_DIFFERENTIAL,
PAY_DIFFERENTIAL_DT,
LVL_SUFFIX,
DIVISION_FROM,
SALARY_RTE_CD,
SALARY_DT,
WKL_DT
FROM XX_CERIS_HIST

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to delete records from XX_CERIS_RPT failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records from XX_CERIS_RPT'
      GOTO BL_ERROR_HANDLER
   END


PRINT 'Remove Division transfers from XX_CERIS_HIST'

DELETE FROM XX_CERIS_HIST WHERE DIVISION NOT IN ('1M','16','1P','2G') --CR6293, 8761

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to delete records from XX_CERIS_HIST failed.
      SET @error_msg_placeholder1 = 'delete'
      SET @error_msg_placeholder2 = 'records from XX_CERIS_HIST'
      GOTO BL_ERROR_HANDLER
   END


PRINT 'Clear and populate table XX_CERIS_BLUEPAGES_HIST ...'

-- clear table XX_CERIS_BLUEPAGES_HIST for each interface run
DELETE dbo.XX_CERIS_BLUEPAGES_HIST


--CR4885 begin
/*
INSERT INTO dbo.XX_CERIS_BLUEPAGES_HIST(EMPL_ID, INTERNET_ID)
   SELECT SERIAL_NUM, ISNULL(INTERNETID, 'place.holder@us.ibm.com')
     FROM ETIME_RPT..CFRPTADM.IBM_BCS
*/
-- CR9994 BEGIN
INSERT INTO imapsstg.dbo.XX_CERIS_BLUEPAGES_HIST(EMPL_ID, INTERNET_ID)
   SELECT t1.EMPL_ID, coalesce(t2.INTERNETID,'place.holder@us.ibm.com') as internet_id
     FROM imapsstg.dbo.XX_CERIS_HIST t1
     left join ETIME_RPT..CFRPTADM.IBM_BLUEPAGE t2
        on t1.EMPL_ID = t2.SERIALNO
    GROUP BY t1.EMPL_ID, T2.INTERNETID
-- CR9994 END
--CR4885 end

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to insert records into table XX_CERIS_BLUEPAGES_HIST failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_CERIS_BLUEPAGES_HIST'
      GOTO BL_ERROR_HANDLER
   END

-- on success, set status description of the interface run at this point
--CR4885 Begin
--SET @out_STATUS_DESCRIPTION = 'INFORMATION: Loading CERIS/BluePages data from eT&E system into staging tables completed successfully.'
SET @out_STATUS_DESCRIPTION = 'INFORMATION: Loading CERIS/LCDB/BluePages data into staging tables completed successfully.'
--CR4885 End

RETURN(0)

BL_ERROR_HANDLER:

/*
 * Since BEGIN TRANSACTION and ROLLBACK TRANSACTION for transactions that involve a non-SQL Server table
 * causes error 7391, provide "manual rollback" here by emptying the affected IMAPS tables.
 */
TRUNCATE TABLE dbo.XX_CERIS_HIST 
TRUNCATE TABLE dbo.XX_CERIS_PORT_NEW_ORGS
TRUNCATE TABLE dbo.XX_CERIS_FIWLR_DIV16_STATUS
TRUNCATE TABLE dbo.XX_CERIS_BLUEPAGES_HIST

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_code,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)



























































GO



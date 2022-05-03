use imapsstg

IF OBJECT_ID('dbo.XX_R22_CERIS_UPDATE_CP_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_CERIS_UPDATE_CP_SP
    IF OBJECT_ID('dbo.XX_R22_CERIS_UPDATE_CP_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_CERIS_UPDATE_CP_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_CERIS_UPDATE_CP_SP >>>'
END
go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER ON
go

CREATE PROCEDURE [dbo].[XX_R22_CERIS_UPDATE_CP_SP]
(
@in_STATUS_RECORD_NUM     integer,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS

/************************************************************************************************  
Name:       XX_R22_CERIS_UPDATE_CP_SP
Author:	    V Veera
Created:    05/21/2008 
Purpose:    Update data in Costpoint tables EMPL, EMPL_LAB_INFO and DFLT_REG_TS.
            Called by XX_R22_CERIS_RUN_INTERFACE_SP.
Notes:

CP600000586 03/06/2009 Reference BP&S Service Request CR1970
            Ensure that CERIS data changes for employee status (EMPL_STATUS_DT, EMPL_STAT3_DT)
            are tracked correctly and records inserted into Deltek.EMPL_LAB_INFO.

CP600000709 10/16/2009 Reference BP&S Service Request CR2350 - KM
            Retro-timesheet changes

CP600000709 01/20/2010 Reference BP&S Service Request DR2672 - KM
            Retro-timesheet bug for specific case
            Replace @PREV_END_DT with @FRONT_EFFECT_DT (5 instances in section 3b)

CP600000709 05/10/2010 Reference BP&S Service Request CR2350 - KM salary date
            Do not create retros for Salary Date change (only for salary change)

CP600000709 05/10/2010 Reference BP&S Service Request CR2350 - KM status effective date
			problem with status (reason_desc) effective date
            --KM status effective date

CP600000709 2011-09-19 Reference BP&S Service Request CR2350 - KM salary date & s_hrly_cd
            Requirement change above changed back : Do create retros for Salary Date change (not only for salary change)!
            Also: S_HRLY_SAL_CD should be tied to the EXMPT_FL (and both using the CERIS EXEMPT_DT as the effective date)

CP600001465 02/22/2012 Reference FSST Service Request DR4434
            Clear the default TERM_DT (reset to NULL) once the employee is reactivated within Division 22.

CP600001547 05/15/2012 Reference FSST Service Request DR4925
            Changes to LAB_GRP_TYPE not processed when EMPL_STAT3_DT value is NULL.

************************************************************************************************/  

BEGIN

-- ANSI NULLS MUST BE OFF


DECLARE @ERROR_DESC varchar(60),
	@EMPL_ID varchar(12)

DECLARE @S_EMPL_TYPE_CD char(1),
	@LAB_GRP_TYPE varchar(3),
	@ADJ_PAY_FREQ decimal(10, 8)
	
DECLARE --@EMPL_ID varchar(12),
	@LAST_EFFECT_DT smalldatetime,
	@PREV_SEC_ORG_ID varchar(20),
	@PREV_ORG_ID varchar(20),
	@PREV_LAB_GRP_TYPE varchar(3),
	@PREV_GENL_LAB_CAT_CD varchar(6),
	@CUR_ORG_ID varchar(20),
	@CUR_GENL_LAB_CAT_CD varchar(6),
	@PREV_END_DT smalldatetime,
	@CUR_HRLY_AMT decimal(10, 4),
	@PREV_HRLY_AMT decimal(10, 4),
	@PREV_SAL_AMT decimal(10, 2),
	@PREV_ANNL_AMT decimal(10, 2),
	@S_HRLY_SAL_CD varchar(1),
	@PREV_S_HRLY_SAL_CD varchar(1),
	@PREV_STD_EST_HRS smallint,	
	@STD_EST_HRS smallint,	
	@PREV_PCT_INCR_RT decimal(5,4),	
	@PREV_WORK_YR_HRS_NO smallint,	
	@CUR_WORK_YR_HRS_NO smallint,	
	@EFFECT_DT smalldatetime,
	@HRLY_AMT decimal(10, 4),
	@SAL_AMT decimal(10, 2),
	@ANNL_AMT decimal(10, 2),

--KM CR2350
	@PREV_EXMPT_FL char(1),
	@CUR_EXMPT_FL char(1),
--KM CR2350

	@EXMPT_FL char(1),
	--@S_EMPL_TYPE_CD char(1),
 	@ORG_ID	varchar(20),
	@SEC_ORG_ID varchar(20),
	@TITLE_DESC varchar(30),
	--@LAB_GRP_TYPE varchar(3),
	@GENL_LAB_CAT_CD varchar(6),
	@REASON_DESC varchar(30),
	@WORK_YR_HRS_NO smallint,
--	@S_HRLY_SAL_CD	char(1),
	@WORK_STATE_CD	varchar(2),
--	@STD_EST_HRS	decimal(14,2),
	@STD_EFFECT_AMT	decimal(10,4),
--	@MODIFIED_BY	varchar(20),
--	@TIME_STAMP	smalldatetime,
	@PCT_INCR_RT	decimal(5,4),		--calculated
	@DETL_JOB_CD	varchar(10),
	@PERS_ACT_RSN_CD	varchar(10),
	@LAB_LOC_CD	varchar(6),
	@MERIT_PCT_RT	decimal(5,4),
	@PROMO_PCT_RT	decimal(5,4),
	@SAL_GRADE_CD	varchar(10),
	@S_STEP_NO	smallint,
	--@MGR_EMPL_ID	varchar(12),
	@END_DT	smalldatetime,
	@COMMENTS	varchar(254),
        @EMPL_CLASS_CD	varchar(12),
        @PREV_EMPL_CLASS_CD varchar(12),
        @CUR_EMPL_CLASS_CD  varchar(12),
	@PERS_ACT_RSN_CD_2  varchar(10),
	@PERS_ACT_RSN_CD_3  varchar(10),
	@REASON_DESC_2	varchar(30),
	@REASON_DESC_3	varchar(30),
	@CORP_OFCR_FL	char(1),
	@SEASON_EMPL_FL	char(1),
	@HIRE_DT_FL	char(1),
	@TERM_DT_FL	char(1),
	@AA_COMMENTS	varchar(254),
	@TC_TS_SCHED_CD	varchar(10),
	@TC_WORK_SCHED_CD	varchar(10)
	--@ROWVERSION	int			--calculated	

DECLARE @SP_NAME                 sysname,
        @DIV_22_COMPANY_ID       varchar(10),
        @error_type              integer,
        @IMAPS_error_code        integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname


-- set local constants
SET @SP_NAME = 'XX_R22_CERIS_UPDATE_CP_SP'
--SET @SP_NAME = 'XX_R22_CERIS_PROCESS_RETRO_SP'

SELECT @DIV_22_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'CERIS_R22'


PRINT 'Process Stage CERIS_R4 - Perform direct UPDATEs against Costpoint tables ...'

-- BEGIN PREPROCESSING Employee records that need updating

-- We know these CERIS records require insertion/update to 
-- Costpoint tables, but we don't yet know what kind of insertion/update
-- We don't know what the actual changes are yet.
-- We will first assume all of the data has changed

/* 
 * Tables XX_R22_CERIS_CP_EMPL_STG, XX_R22_CERIS_CP_EMPL_LAB_STG, XX_R22_CERIS_CP_DFLT_TS_STG and XX_R22_CERIS_RETRO_TS
 * are truncated in XX_R22_CERIS_RETRIEVE_SOURCE_DATA_SP for each interface run.
 */

-- Staging table for Costpoint table EMPL
INSERT INTO dbo.XX_R22_CERIS_CP_EMPL_STG
   (EMPL_ID, ORIG_HIRE_DT, ADJ_HIRE_DT, SPVSR_NAME, 
    LAST_NAME, FIRST_NAME,
    LAST_FIRST_NAME,
    MID_NAME, EMAIL_ID)
   SELECT DISTINCT EMPL_ID, ORIG_HIRE_DT, ADJ_HIRE_DT, SPVSR_NAME,
	  LAST_NAME, FIRST_NAME,
          CAST((LAST_NAME + ',' + FIRST_NAME) AS varchar(25)),
          MID_NAME, EMAIL_ID
     FROM dbo.XX_R22_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 1
      GOTO BL_ERROR_HANDLER
   END



-- Staging table for Costpoint table EMPL_LAB_INFO

-- This table is set up very different from CERIS,
-- There is only 1 effective date column per row
-- As such, we must organize the CERIS data into
-- rows with single effective dates.

-- These changes must be ordered by date.
--declare @REASON_DESC varchar(30)


-- capture Salary effective date
--SET @REASON_DESC = 'SALARY CHANGE'
/*determine effective date based on which changed more recently - SALARY_DT or WORK_SCHD_DT )*/
INSERT INTO dbo.XX_R22_CERIS_CP_EMPL_LAB_STG
   (EMPL_ID, EFFECT_DT, ANNL_AMT, SAL_AMT, HRLY_AMT, WORK_YR_HRS_NO /*, S_HRLY_SAL_CD*/ ) --KM 2011-09-19 
   SELECT DISTINCT EMPL_ID, SALARY_DT, ANNL_AMT, SAL_AMT, HRLY_AMT, WORK_YR_HRS_NO /*, S_HRLY_SAL_CD*/
     FROM dbo.XX_R22_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)
	AND SALARY_DT >= WORK_SCHD_DT

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END
INSERT INTO dbo.XX_R22_CERIS_CP_EMPL_LAB_STG
   (EMPL_ID, EFFECT_DT, ANNL_AMT, SAL_AMT, HRLY_AMT, WORK_YR_HRS_NO /*, S_HRLY_SAL_CD*/) --KM 2011-09-19 
   SELECT DISTINCT EMPL_ID, WORK_SCHD_DT, ANNL_AMT, SAL_AMT, HRLY_AMT, WORK_YR_HRS_NO /*, S_HRLY_SAL_CD*/
     FROM dbo.XX_R22_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)
	AND WORK_SCHD_DT > SALARY_DT

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END



-- capture EMPL_CLASS_CD effective date
--SET @REASON_DESC = 'EMPL_CLASS_CD CHANGE'
/*determine effective date based on which changed more recently - SAL_BAND or REG_TEMP*/
INSERT INTO dbo.XX_R22_CERIS_CP_EMPL_LAB_STG
   (EMPL_ID, EFFECT_DT, EMPL_CLASS_CD, LAB_GRP_TYPE)
   SELECT DISTINCT EMPL_ID, EMPL_STAT_DT, EMPL_CLASS_CD, LAB_GRP_TYPE
     FROM dbo.XX_R22_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)
	AND EMPL_STAT_DT >= LVL_DT_1

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END

INSERT INTO dbo.XX_R22_CERIS_CP_EMPL_LAB_STG
   (EMPL_ID, EFFECT_DT, EMPL_CLASS_CD, LAB_GRP_TYPE)
   SELECT DISTINCT EMPL_ID, LVL_DT_1, EMPL_CLASS_CD, LAB_GRP_TYPE
     FROM dbo.XX_R22_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)
	AND LVL_DT_1 > EMPL_STAT_DT

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END



-- capture GLC change effective date
--SET @REASON_DESC = 'JOB FAMILY CHANGE'
/*determine effective date based on which changed more recently - JOB_FAM or SAL_BAND )*/
INSERT INTO dbo.XX_R22_CERIS_CP_EMPL_LAB_STG
   (EMPL_ID, EFFECT_DT, GENL_LAB_CAT_CD)
   SELECT DISTINCT EMPL_ID, JF_DT, GENL_LAB_CAT_CD
     FROM dbo.XX_R22_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)
      AND JF_DT >= LVL_DT_1

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END

--SET @REASON_DESC = 'BAND CHANGE'
INSERT INTO dbo.XX_R22_CERIS_CP_EMPL_LAB_STG (EMPL_ID, EFFECT_DT, GENL_LAB_CAT_CD)
   SELECT DISTINCT EMPL_ID, LVL_DT_1, GENL_LAB_CAT_CD
     FROM dbo.XX_R22_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)
      AND LVL_DT_1 > JF_DT

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END


-- capture Position effective date
--SET @REASON_DESC = 'POSITION CHANGE'
INSERT INTO dbo.XX_R22_CERIS_CP_EMPL_LAB_STG (EMPL_ID, EFFECT_DT, TITLE_DESC)
   SELECT DISTINCT EMPL_ID, POS_DT, TITLE_DESC
     FROM dbo.XX_R22_CERIS_CP_STG 
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END


-- capture Department effective date
--SET @REASON_DESC = 'DEPARTMENT CHANGE'
INSERT INTO dbo.XX_R22_CERIS_CP_EMPL_LAB_STG (EMPL_ID, EFFECT_DT, ORG_ID, LAB_GRP_TYPE, SEC_ORG_ID)
   SELECT DISTINCT EMPL_ID, DEPT_ST_DT, ORG_ID, LAB_GRP_TYPE, ORG_ID
     FROM dbo.XX_R22_CERIS_CP_STG 
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END


-- capture Employee Status effective date
--SET @REASON_DESC = 'STATUS CHANGE'
--KM status effective date
/*determine effective date based on which changed more recently - EMPL_STAT_DT or EMPL_STAT3_DT )*/
INSERT INTO dbo.XX_R22_CERIS_CP_EMPL_LAB_STG (EMPL_ID, EFFECT_DT, LAB_GRP_TYPE, REASON_DESC, S_EMPL_TYPE_CD)
   SELECT DISTINCT EMPL_ID, EMPL_STAT_DT, LAB_GRP_TYPE, REASON_DESC, S_EMPL_TYPE_CD
     FROM dbo.XX_R22_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)
-- DR4925_begin
      AND EMPL_STAT_DT >= ISNULL(EMPL_STAT3_DT, EMPL_STAT_DT)
-- DR4925_end

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END


-- CP600000586_Begin

-- capture Employee Status3 effective date
--SET @REASON_DESC = 'STATUS3 CHANGE'
--KM status effective date
/*determine effective date based on which changed more recently - EMPL_STAT_DT or EMPL_STAT3_DT )*/
INSERT INTO dbo.XX_R22_CERIS_CP_EMPL_LAB_STG (EMPL_ID, EFFECT_DT, REASON_DESC, LAB_GRP_TYPE, S_EMPL_TYPE_CD)
   SELECT DISTINCT EMPL_ID, EMPL_STAT3_DT, REASON_DESC, LAB_GRP_TYPE, S_EMPL_TYPE_CD
     FROM dbo.XX_R22_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)
      AND EMPL_STAT3_DT > EMPL_STAT_DT

-- CP600000586_End

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END

-- capture Exempt effective date
--SET @REASON_DESC = 'EXEMPT CHANGE'
INSERT INTO dbo.XX_R22_CERIS_CP_EMPL_LAB_STG (EMPL_ID, EFFECT_DT, EXMPT_FL, S_HRLY_SAL_CD) --KM 2011-09-19 
   SELECT DISTINCT EMPL_ID, EXEMPT_DT, EXMPT_FL, S_HRLY_SAL_CD
     FROM dbo.XX_R22_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)
      AND EXEMPT_DT IS NOT NULL

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END


-- Staging table for Costpoint table DFLT_REG_TS
INSERT INTO dbo.XX_R22_CERIS_CP_DFLT_TS_STG (EMPL_ID, GENL_LAB_CAT_CD, CHG_ORG_ID)
   SELECT DISTINCT EMPL_ID, GENL_LAB_CAT_CD, ORG_ID
     FROM dbo.XX_R22_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 3
      GOTO BL_ERROR_HANDLER
   END


-- Delete changes that aren't needed, then cursor through changes
-- check EMPL table changes

-- Delete EMPL changes that aren't needed
DELETE dbo.XX_R22_CERIS_CP_EMPL_STG
FROM dbo.XX_R22_CERIS_CP_EMPL_STG as a
INNER JOIN IMAR.DELTEK.EMPL as b
ON
(a.EMPL_ID = b.EMPL_ID) AND
(a.ORIG_HIRE_DT = b.ORIG_HIRE_DT) AND
(a.ADJ_HIRE_DT = b.ADJ_HIRE_DT) AND
(a.SPVSR_NAME = b.SPVSR_NAME) AND
(a.LAST_NAME = b.LAST_NAME) AND
(a.FIRST_NAME = b.FIRST_NAME) AND
(a.LAST_FIRST_NAME = b.LAST_FIRST_NAME) AND
(a.MID_NAME = b.MID_NAME) AND
-- CP600000284_Begin
(a.EMAIL_ID = b.EMAIL_ID) AND
(b.COMPANY_ID = @DIV_22_COMPANY_ID)
-- CP600000284_End



-- Delete EMPL_LAB_INFO changes that aren't needed
DELETE dbo.XX_R22_CERIS_CP_EMPL_LAB_STG
FROM dbo.XX_R22_CERIS_CP_EMPL_LAB_STG as a
INNER JOIN IMAR.DELTEK.EMPL_LAB_INFO as b
ON
(
-- job family/band changes that aren't needed
(
(a.EMPL_ID = b.EMPL_ID) AND
(a.GENL_LAB_CAT_CD = b.GENL_LAB_CAT_CD)AND
 --EFFECTIVE DATE CHANGES
 --check effective date change for GLC
(a.GENL_LAB_CAT_CD = (SELECT GENL_LAB_CAT_CD FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT))
) 
OR
-- SALARY changes
(
(a.EMPL_ID = b.EMPL_ID) AND
(a.ANNL_AMT = b.ANNL_AMT)AND
(a.WORK_YR_HRS_NO = b.WORK_YR_HRS_NO)AND

 --KM 2011-09-19 ( a.S_HRLY_SAL_CD = b.S_HRLY_SAL_CD) AND  

 --EFFECTIVE DATE CHANGES
 --check effective date change for SALARY
(a.ANNL_AMT = (SELECT ANNL_AMT FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT))
AND
(a.WORK_YR_HRS_NO = (SELECT WORK_YR_HRS_NO FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT))

 --KM 2011-09-19 AND  (a.S_HRLY_SAL_CD = (SELECT S_HRLY_SAL_CD FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT)) 
) 
OR
-- EMPL_CLASS_CD changes
(
(a.EMPL_ID = b.EMPL_ID) AND
(a.EMPL_CLASS_CD = b.EMPL_CLASS_CD) AND
 --EFFECTIVE DATE CHANGES
 --check effective date change for EMPL_CLASS_CD
(a.EMPL_CLASS_CD = (SELECT EMPL_CLASS_CD FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT))
)
OR -- position changes that aren't needed
( (a.EMPL_ID = b.EMPL_ID) AND
  (a.TITLE_DESC = b.TITLE_DESC)
)
OR -- department changes that aren't needed
( (a.EMPL_ID = b.EMPL_ID) AND
  (a.ORG_ID = b.ORG_ID AND a.SEC_ORG_ID = b.SEC_ORG_ID) AND
 --check effective date change for DEPARTMENT
 --EFFECTIVE DATE CHANGES
  (a.ORG_ID = (SELECT ORG_ID FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT))
)
OR -- status changes that aren't needed
(
  (a.EMPL_ID = b.EMPL_ID) AND
  (a.REASON_DESC = b.REASON_DESC) AND
  (a.LAB_GRP_TYPE = b.LAB_GRP_TYPE) AND
  ( (a.GENL_LAB_CAT_CD = NULL) AND
    (a.TITLE_DESC = NULL) AND
    (a.ORG_ID = NULL) AND
    (a.S_EMPL_TYPE_CD = NULL) AND
    (a.EXMPT_FL = NULL) AND
    (a.EMPL_CLASS_CD = NULL) AND
    (a.ANNL_AMT = NULL)
  )
)
OR -- status3 changes that aren't needed
(
  (a.EMPL_ID = b.EMPL_ID) AND
  (a.REASON_DESC = b.REASON_DESC) AND
-- CP600000586_Begin
  (a.LAB_GRP_TYPE = b.LAB_GRP_TYPE) AND
-- CP600000586_End
  (a.S_EMPL_TYPE_CD = b.S_EMPL_TYPE_CD)
)
OR -- exempt changes that aren't needed
(
  (a.EMPL_ID = b.EMPL_ID) 
	AND
  (a.EXMPT_FL = b.EXMPT_FL)
	AND
  (a.S_HRLY_SAL_CD = b.S_HRLY_SAL_CD)  --KM 2011-09-19
	AND
 --KM CR2350
 --check effective date change for EXMPT
 --EFFECTIVE DATE CHANGES
  (a.EXMPT_FL = (SELECT EXMPT_FL FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT))
	AND
  (a.S_HRLY_SAL_CD = (SELECT S_HRLY_SAL_CD FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT))  --KM 2011-09-19
)
)
AND b.EFFECT_DT = (SELECT MAX(EFFECT_DT)
		     FROM IMAR.DELTEK.EMPL_LAB_INFO
		     WHERE EMPL_ID = a.EMPL_ID)



-- Delete DFLT_REG_TS changes that aren't needed
DELETE dbo.XX_R22_CERIS_CP_DFLT_TS_STG
FROM dbo.XX_R22_CERIS_CP_DFLT_TS_STG as a
INNER JOIN IMAR.DELTEK.DFLT_REG_TS as b
ON
(a.EMPL_ID = b.EMPL_ID) AND
(a.GENL_LAB_CAT_CD = b.GENL_LAB_CAT_CD) AND
(a.CHG_ORG_ID = b.CHG_ORG_ID)



-- Process changes to EMPL, EMPL_LAB_INFO and DFLT_REG_TS tables


-- EMPL table updates/inserts

UPDATE IMAR.DELTEK.EMPL
SET TERM_DT = '2078-12-31 00:00:00',
S_EMPL_STATUS_CD = 'IN',
 ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
WHERE 
(TERM_DT IS NULL OR S_EMPL_STATUS_CD <> 'IN')
AND
EMPL_ID NOT IN
(
SELECT EMPL_ID FROM XX_R22_CERIS_FILE_STG
WHERE TERM_DT IS NULL
)
AND
COMPANY_ID = @DIV_22_COMPANY_ID

/*
UPDATE IMAR.DELTEK.EMPL
SET TERM_DT = NULL,
S_EMPL_STATUS_CD = 'ACT',
ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
WHERE 
(TERM_DT IS NOT NULL OR S_EMPL_STATUS_CD <> 'ACT')
AND 
EMPL_ID IN
(
SELECT EMPL_ID FROM XX_R22_CERIS_FILE_STG
WHERE TERM_DT IS NULL
)
AND
COMPANY_ID = @DIV_22_COMPANY_ID
*/



UPDATE 	IMAR.DELTEK.EMPL
SET 	MGR_EMPL_ID = stg.MGR_SERIAL_NUM,
	ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
FROM	IMAR.DELTEK.EMPL AS cp
INNER JOIN dbo.XX_R22_CERIS_FILE_STG AS stg
ON (cp.EMPL_ID = stg.EMPL_ID
AND ISNULL(cp.MGR_EMPL_ID, '') <> ISNULL(stg.MGR_SERIAL_NUM, '')
AND cp.COMPANY_ID = @DIV_22_COMPANY_ID)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
BEGIN
	SET @error_type = 4
	GOTO BL_ERROR_HANDLER
END

DECLARE @rows int
SELECT @rows = COUNT(EMPL_ID) FROM dbo.XX_R22_CERIS_CP_EMPL_STG

IF (@rows <> 0)
BEGIN
	-- EMPL records for updating
	UPDATE IMAR.DELTEK.EMPL
	SET ORIG_HIRE_DT = stg.ORIG_HIRE_DT,
	 ADJ_HIRE_DT = stg.ADJ_HIRE_DT,
	 TERM_DT = stg.TERM_DT,
	 SPVSR_NAME = stg.SPVSR_NAME,
	 FIRST_NAME = stg.FIRST_NAME,
	 LAST_NAME = stg.LAST_NAME,
	 MID_NAME = stg.MID_NAME,
	 LAST_FIRST_NAME = stg.LAST_FIRST_NAME,
	 EMAIL_ID = stg.EMAIL_ID,
	 ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
	FROM IMAR.DELTEK.EMPL AS cp
	INNER JOIN dbo.XX_R22_CERIS_CP_EMPL_STG AS stg
	ON (cp.EMPL_ID = stg.EMPL_ID)
        AND (cp.COMPANY_ID = @DIV_22_COMPANY_ID)

        SET @SQLServer_error_code = @@ERROR
        IF @SQLServer_error_code <> 0
           BEGIN
              SET @error_type = 4
              GOTO BL_ERROR_HANDLER
           END
	
END -- end updates/inserts for empl table

-- DR4434_begin
/*
 * When a "previously terminated" employee later joins Division 22 again (reactivated for another Division 22 tour of duty),
 * as indicated by the presence of a record bearing his ID in the current CERIS file,
 * the same employee that was terminated by Costpoint must be made active again.
 * Set TERM_DT to NULL based on the latest TERM_DT data from the CERIS file.
 */
UPDATE IMAR.Deltek.EMPL
   SET TERM_DT = NULL,
       TIME_STAMP = CURRENT_TIMESTAMP
 WHERE TERM_DT is not NULL
   AND EMPL_ID in
          (SELECT EMPL_ID
             FROM dbo.XX_R22_CERIS_FILE_STG
            WHERE TERM_DT IS NULL
          )
   AND COMPANY_ID = @DIV_22_COMPANY_ID

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 4
      GOTO BL_ERROR_HANDLER
   END
-- DR4434_end

/*
Notes to self: 

RETRO TIMESHEET LOGIC CHANGED:
Had been for Salary, Org, and Employee Class Code changes ... now just Salary!

LAB_GRP_TYPE LOGIC CHANGED:
Had been related to Org and Employee Class Code ... now just related to Status1 REG_TEMP (REASON_DESC)


--KM CR2350
CP600000586 
LAB_GRP_TYPE LOGIC CHANGED:
Now related to Status1 REG_TEMP & STAT3 
I'm adding this note here now just because the above LAB_GRP_TYPE LOGIC note is out-dated
(not because CR2350 is at all related to it ... thankfully, it is not :)


--KM CR2350
RETRO TIMESHEET LOGIC CHANGED AGAIN:
1.  The following retro-active CERIS changes should trigger retro-time sheets.
Changes to an employee's standard work hours
Changes to an employee's salary
Changes between Exempt and Non-exempt (empl_lab_info.exmpt)
Employee is non-exempt (N) when stat1||stat2 = '30 and exmt = 'N' on the CERIS file, otherwise the employee is exempt (Y).
Changes to an employee's department


*/

/* Tracking changes of Reg, Non-Reg, Band etc are processed below.  
Requirement 9:	Using effective date, track changes between Reg and Non-Reg in the employee class field using CERIS columns lvldt and statdt for band and stat1 changes respectively, changes to scheduled work hours using CERIS column schhrsdt, salary using a new column to be added to the CERIS file that will contain the date salary was changed, and department using CERIS column deptdt.  Where changes contain a date in the past, insert a new record with date on file and update any future records in empl_lab_info.  The same logic can be used when changes are retro-active to the prior calendar year.
*/
-- EMPL_LAB_INFO updates/inserts

-- *for retro GLC/ORG_ID changes, need retro timesheets
SELECT @rows = COUNT(EMPL_ID) FROM dbo.XX_R22_CERIS_CP_EMPL_LAB_STG
IF (@rows <> 0)
BEGIN
	
	--update empl_lab_info id's
	DECLARE EMPL_ID_CURSOR CURSOR FAST_FORWARD FOR
	SELECT DISTINCT EMPL_ID FROM dbo.XX_R22_CERIS_CP_EMPL_LAB_STG
	WHERE EMPL_ID IN (SELECT EMPL_ID FROM IMAR.DELTEK.EMPL_LAB_INFO GROUP BY EMPL_ID)

	OPEN EMPL_ID_CURSOR
	FETCH NEXT FROM EMPL_ID_CURSOR INTO @EMPL_ID

	-- for each empl_id that needs updating in empl_lab_info
	WHILE @@FETCH_STATUS = 0
	BEGIN
	
		-- The whole reason we've done this is
		-- because the changes MUST be ordered by 
		-- EFFECTIVE DATE
		DECLARE EMPL_LAB_CURSOR CURSOR FAST_FORWARD FOR
		SELECT DISTINCT CAST(EFFECT_DT AS smalldatetime) as Eff_Dt, 
			HRLY_AMT, SAL_AMT, ANNL_AMT,
			EXMPT_FL, S_EMPL_TYPE_CD, ORG_ID, SEC_ORG_ID,
			TITLE_DESC, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
			REASON_DESC, WORK_YR_HRS_NO,
  			EMPL_CLASS_CD,
			S_HRLY_SAL_CD,
			WORK_YR_HRS_NO --WORK_YR_HRS_NO is the same as STD_EST_HRS	
		FROM dbo.XX_R22_CERIS_CP_EMPL_LAB_STG
		WHERE EMPL_ID = @EMPL_ID
		ORDER BY Eff_Dt

		OPEN EMPL_LAB_CURSOR

		FETCH NEXT FROM EMPL_LAB_CURSOR
		INTO 	@EFFECT_DT, 
			@HRLY_AMT, @SAL_AMT, @ANNL_AMT,
			@EXMPT_FL, @S_EMPL_TYPE_CD, @ORG_ID, @SEC_ORG_ID,
			@TITLE_DESC, @LAB_GRP_TYPE, @GENL_LAB_CAT_CD,
			@REASON_DESC, @WORK_YR_HRS_NO,
  			@EMPL_CLASS_CD,
			@S_HRLY_SAL_CD,
			@STD_EST_HRS


		-- for each empl_lab change for current empl_id, ordered by date
		WHILE @@FETCH_STATUS = 0
		BEGIN
	
			-- do update processing
			
			-- figure out if change is retro or not
			-- get last records effective date
			SELECT @LAST_EFFECT_DT = MAX(EFFECT_DT)
			FROM IMAR.DELTEK.EMPL_LAB_INFO
			WHERE EMPL_ID = @EMPL_ID


			/*
			1.  IF CHANGE IS TO CURRENT EMPL_LAB_INFO RECORD, JUST UPDATE THAT RECORD
			*/
			IF (@LAST_EFFECT_DT = @EFFECT_DT)
			BEGIN
				-- figure out change, and update accordingly
				
				-- if job family, band change
				IF (@GENL_LAB_CAT_CD IS NOT NULL)
				BEGIN
					--EFFECTIVE DATE CHANGES
					--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
					SET @CUR_GENL_LAB_CAT_CD = NULL
					SET @PREV_GENL_LAB_CAT_CD = NULL	
					SET @PREV_END_DT = NULL	
					
					SELECT  @CUR_GENL_LAB_CAT_CD = GENL_LAB_CAT_CD
					FROM    IMAR.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND	EFFECT_DT = @LAST_EFFECT_DT
						
					--EFFECTIVE DATE CHANGES
					--IF CURRENT GLC IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
					--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
					IF @CUR_GENL_LAB_CAT_CD = @GENL_LAB_CAT_CD
					BEGIN
						SELECT 	@PREV_GENL_LAB_CAT_CD = GENL_LAB_CAT_CD,
							@PREV_END_DT = END_DT
						FROM 	IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID	
						AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND GENL_LAB_CAT_CD <> @GENL_LAB_CAT_CD)					

						--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
						IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
						BEGIN
							
							--ROLL OLD GLC FORWARD
							UPDATE IMAR.DELTEK.EMPL_LAB_INFO
							SET GENL_LAB_CAT_CD = @PREV_GENL_LAB_CAT_CD,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
							WHERE 	EMPL_ID = @EMPL_ID
							AND	EFFECT_DT > @PREV_END_DT
							AND	EFFECT_DT < @EFFECT_DT
						
							/*
							DIV 22 ONLY TRACKS RETRO TIMESHEETS FOR SALARY

							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, NULL, @PREV_GENL_LAB_CAT_CD, @PREV_END_DT+1, @EFFECT_DT-1
							*/
					
							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
						ELSE IF @PREV_END_DT IS NOT NULL
						BEGIN

							/*
							DIV 22 ONLY TRACKS RETRO TIMESHEETS FOR SALARY

							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, NULL, @GENL_LAB_CAT_CD, @EFFECT_DT, @PREV_END_DT
							*/
					
							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
					END
					ELSE 
					BEGIN

						  /*
							DIV 22 ONLY TRACKS RETRO TIMESHEETS FOR SALARY

							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, NULL, @GENL_LAB_CAT_CD, @EFFECT_DT, GETDATE()
							*/
				
						SET @SQLServer_error_code = @@ERROR
	                                        IF @SQLServer_error_code <> 0
	                                           BEGIN
	                                               SET @error_type = 7
	                                               GOTO BL_ERROR_HANDLER
	                                           END
					END
											
					--PROCESS GLC CHANGE
					UPDATE IMAR.DELTEK.EMPL_LAB_INFO
					SET 	GENL_LAB_CAT_CD = @GENL_LAB_CAT_CD,
						ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
					WHERE 	EMPL_ID = @EMPL_ID AND
					      	EFFECT_DT = @EFFECT_DT

                                        SET @SQLServer_error_code = @@ERROR
                                        IF @SQLServer_error_code <> 0
                                           BEGIN
                                              SET @error_type = 5
                                              GOTO BL_ERROR_HANDLER
                                           END
				END
				

				-- if position change
				ELSE IF (@TITLE_DESC IS NOT NULL)
				BEGIN
					UPDATE IMAR.DELTEK.EMPL_LAB_INFO
					SET 	TITLE_DESC = @TITLE_DESC,
						ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
					WHERE 	EMPL_ID = @EMPL_ID AND
						EFFECT_DT = @EFFECT_DT

                                        SET @SQLServer_error_code = @@ERROR
                                        IF @SQLServer_error_code <> 0
                                           BEGIN
                                              SET @error_type = 5
                                              GOTO BL_ERROR_HANDLER
                                           END
				END


				-- if department change
				ELSE IF (@ORG_ID IS NOT NULL)
				BEGIN
					--EFFECTIVE DATE CHANGES
					--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
					SET @CUR_ORG_ID = NULL
					SET @PREV_ORG_ID = NULL	
					SET @PREV_END_DT = NULL	
					
					SELECT  @CUR_ORG_ID = ORG_ID
					FROM    IMAR.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND	EFFECT_DT = @LAST_EFFECT_DT
					
					--EFFECTIVE DATE CHANGES
					--IF CURRENT ORG IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
					--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
					IF @CUR_ORG_ID = @ORG_ID
					BEGIN
						SELECT 	@PREV_ORG_ID = ORG_ID,
							@PREV_LAB_GRP_TYPE = LAB_GRP_TYPE, 
							@PREV_SEC_ORG_ID = SEC_ORG_ID,
							@PREV_END_DT = END_DT
						FROM 	IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID	
						AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND ORG_ID <> @ORG_ID)
												
						--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
						IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
						BEGIN
							
							--ROLL OLD ORG_ID FORWARD
							UPDATE IMAR.DELTEK.EMPL_LAB_INFO
							SET
							ORG_ID = @PREV_ORG_ID, 
							--LAB_GRP_TYPE = LEFT(@PREV_LAB_GRP_TYPE, 1) + EMPL_CLASS_CD,
							SEC_ORG_ID = @PREV_SEC_ORG_ID,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
							WHERE 	EMPL_ID = @EMPL_ID
							AND	EFFECT_DT > @PREV_END_DT
							AND	EFFECT_DT < @EFFECT_DT
						
							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @PREV_ORG_ID, @PREV_END_DT+1, @EFFECT_DT-1
							
					
							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
						ELSE IF @PREV_END_DT IS NOT NULL
						BEGIN
							
							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @ORG_ID, @EFFECT_DT, @PREV_END_DT
					
							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
					END
					ELSE
					BEGIN

						--KM CR2350 - uncommented
						--TRACK RETRO TIMESHEET DATA - SALARY ONLY
						INSERT INTO XX_R22_CERIS_RETRO_TS
						(EMPL_ID, NEW_ORG_ID, EFFECT_DT, END_DT)
						SELECT @EMPL_ID, @ORG_ID, @EFFECT_DT, GETDATE()
						
					
						SET @SQLServer_error_code = @@ERROR
	                                        IF @SQLServer_error_code <> 0
	                                           BEGIN
	                                               SET @error_type = 7	                                               
						       GOTO BL_ERROR_HANDLER
	                                           END
					END
					
					--PROCESS ORG CHANGE
					UPDATE IMAR.DELTEK.EMPL_LAB_INFO
					SET 	ORG_ID = @ORG_ID,
						--LAB_GRP_TYPE = LEFT(@LAB_GRP_TYPE,1)+EMPL_CLASS_CD,
						SEC_ORG_ID = @SEC_ORG_ID,
						ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
					WHERE 	EMPL_ID = @EMPL_ID AND
						EFFECT_DT = @EFFECT_DT

                                        SET @SQLServer_error_code = @@ERROR
                                        IF @SQLServer_error_code <> 0
                                           BEGIN
                                              SET @error_type = 5
                                              GOTO BL_ERROR_HANDLER
                                           END
				END

--begin EMPL_CLASS_CD & SALARY
				-- if EMPL_CLASS_CD change
				ELSE IF (@EMPL_CLASS_CD IS NOT NULL)
				BEGIN
					--EFFECTIVE DATE CHANGES
					--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
					SET @CUR_EMPL_CLASS_CD = NULL
					SET @PREV_EMPL_CLASS_CD = NULL	
					SET @PREV_END_DT = NULL	
					
					SELECT  @CUR_EMPL_CLASS_CD = EMPL_CLASS_CD
					FROM    IMAR.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND	EFFECT_DT = @LAST_EFFECT_DT
					
					--EFFECTIVE DATE CHANGES
					--IF CURRENT EMPL_CLASS_CD IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
					--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
					IF @CUR_EMPL_CLASS_CD = @EMPL_CLASS_CD
					BEGIN
						SELECT 	@PREV_EMPL_CLASS_CD = EMPL_CLASS_CD,
						--	@PREV_LAB_GRP_TYPE = LAB_GRP_TYPE, 
							@PREV_END_DT = END_DT
						FROM 	IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID	
						AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND EMPL_CLASS_CD <> @EMPL_CLASS_CD)
												
						--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
						IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
						BEGIN
							
							--ROLL OLD EMPL_CLASS_CD FORWARD
							UPDATE IMAR.DELTEK.EMPL_LAB_INFO
							SET
							EMPL_CLASS_CD = @PREV_EMPL_CLASS_CD, 
							--LAB_GRP_TYPE = LEFT(LAB_GRP_TYPE, 1) + @PREV_EMPL_CLASS_CD,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
							WHERE 	EMPL_ID = @EMPL_ID
							AND	EFFECT_DT > @PREV_END_DT
							AND	EFFECT_DT < @EFFECT_DT
						
							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_EMPL_CLASS_CD, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @PREV_EMPL_CLASS_CD, @PREV_END_DT+1, @EFFECT_DT-1

							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
						ELSE IF @PREV_END_DT IS NOT NULL
						BEGIN
							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_EMPL_CLASS_CD, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @EMPL_CLASS_CD, @EFFECT_DT, @PREV_END_DT

							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
					END
					ELSE
					BEGIN
						--KM CR2350 - uncommented
						--TRACK RETRO TIMESHEET DATA - SALARY ONLY
						INSERT INTO XX_R22_CERIS_RETRO_TS
						(EMPL_ID, NEW_EMPL_CLASS_CD, EFFECT_DT, END_DT)
						SELECT @EMPL_ID, @EMPL_CLASS_CD, @EFFECT_DT, GETDATE()
						
						SET @SQLServer_error_code = @@ERROR
	                                        IF @SQLServer_error_code <> 0
	                                           BEGIN
	                                               SET @error_type = 7	                                               
						       GOTO BL_ERROR_HANDLER
	                                           END
					END
					
					--PROCESS EMPL_CLASS_CD CHANGE
					UPDATE IMAR.DELTEK.EMPL_LAB_INFO
					SET 	EMPL_CLASS_CD = @EMPL_CLASS_CD,
						--LAB_GRP_TYPE = LEFT(LAB_GRP_TYPE,1)+@EMPL_CLASS_CD,
						ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
					WHERE 	EMPL_ID = @EMPL_ID AND
						EFFECT_DT = @EFFECT_DT

                                        SET @SQLServer_error_code = @@ERROR
                                        IF @SQLServer_error_code <> 0
                                           BEGIN
                                              SET @error_type = 5
                                              GOTO BL_ERROR_HANDLER
                                           END
				END

				-- if SALARY - HRLY_AMT change
				ELSE IF (@HRLY_AMT IS NOT NULL)
				BEGIN
					--EFFECTIVE DATE CHANGES
					--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
					SET @CUR_HRLY_AMT = NULL
					SET @CUR_WORK_YR_HRS_NO = NULL
					SET @PREV_HRLY_AMT = NULL
					SET @PREV_SAL_AMT = NULL
					SET @PREV_ANNL_AMT = NULL
					SET @PREV_WORK_YR_HRS_NO = NULL						
					--KM 2011-09-19 SET @PREV_S_HRLY_SAL_CD = NULL
					SET @PREV_STD_EST_HRS = NULL	
					SET @PREV_END_DT = NULL
					
-- CR2350_Begin KM
					SELECT  @CUR_HRLY_AMT = HRLY_AMT,
						@CUR_WORK_YR_HRS_NO = WORK_YR_HRS_NO
					FROM    IMAR.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND	EFFECT_DT = @LAST_EFFECT_DT
					
					--EFFECTIVE DATE CHANGES
					--IF CURRENT HRLY_AMT IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
					--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
					IF (@CUR_HRLY_AMT = @HRLY_AMT AND @CUR_WORK_YR_HRS_NO = @WORK_YR_HRS_NO)
					BEGIN
						SELECT 	@PREV_HRLY_AMT = HRLY_AMT,
							@PREV_SAL_AMT = SAL_AMT,
							@PREV_ANNL_AMT = ANNL_AMT,
							@PREV_WORK_YR_HRS_NO = WORK_YR_HRS_NO,
							--KM 2011-09-19 @PREV_S_HRLY_SAL_CD = S_HRLY_SAL_CD,
							@PREV_STD_EST_HRS = STD_EST_HRS,	
							@PREV_END_DT = END_DT
						FROM 	IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID	
						AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND (HRLY_AMT <> @HRLY_AMT OR WORK_YR_HRS_NO <> @WORK_YR_HRS_NO))
												
						--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
						IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
						BEGIN
							
							--ROLL OLD HRLY_AMT FORWARD
							UPDATE IMAR.DELTEK.EMPL_LAB_INFO
							SET
							HRLY_AMT = @PREV_HRLY_AMT, 
							SAL_AMT = @PREV_SAL_AMT,
							ANNL_AMT = @PREV_ANNL_AMT,
							WORK_YR_HRS_NO = @PREV_WORK_YR_HRS_NO,
							--KM 2011-09-19 S_HRLY_SAL_CD = @PREV_S_HRLY_SAL_CD,
							STD_EST_HRS = @PREV_STD_EST_HRS,	
							--END_DT = @PREV_END_DT,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
							WHERE 	EMPL_ID = @EMPL_ID
							AND	EFFECT_DT > @PREV_END_DT
							AND	EFFECT_DT < @EFFECT_DT
-- CR2350_End KM
						
							--KM salary date
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @PREV_HRLY_AMT, @PREV_END_DT+1, @EFFECT_DT-1
							
					
							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
						ELSE IF @PREV_END_DT IS NOT NULL
						BEGIN
							--KM salary date
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @HRLY_AMT, @EFFECT_DT, @PREV_END_DT
							
					
							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
					END
					ELSE
					BEGIN
						--TRACK RETRO TIMESHEET DATA - SALARY ONLY
						INSERT INTO XX_R22_CERIS_RETRO_TS
						(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
						SELECT @EMPL_ID, @HRLY_AMT, @EFFECT_DT, GETDATE()
				
						SET @SQLServer_error_code = @@ERROR
	                                        IF @SQLServer_error_code <> 0
	                                           BEGIN
	                                              SET @error_type = 7	                                               
		                                      GOTO BL_ERROR_HANDLER
	                                           END
					END
					
					--PROCESS HRLY_AMT CHANGE
					UPDATE IMAR.DELTEK.EMPL_LAB_INFO
					SET 	HRLY_AMT = @HRLY_AMT, 
						SAL_AMT = @SAL_AMT,
						ANNL_AMT = @ANNL_AMT,
						WORK_YR_HRS_NO = @WORK_YR_HRS_NO,
						--KM 2011-09-19 S_HRLY_SAL_CD = @S_HRLY_SAL_CD,
						STD_EST_HRS = @STD_EST_HRS,	
						ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
					WHERE 	EMPL_ID = @EMPL_ID AND
						EFFECT_DT = @EFFECT_DT

                                        SET @SQLServer_error_code = @@ERROR
                                        IF @SQLServer_error_code <> 0
                                           BEGIN
                                              SET @error_type = 5
                                              GOTO BL_ERROR_HANDLER
                                           END
				END
--end EMPL_CLASS_CD & SALARY


				-- else if status3 change
				ELSE IF (@S_EMPL_TYPE_CD IS NOT NULL)
				BEGIN
					UPDATE IMAR.DELTEK.EMPL_LAB_INFO
					SET 	REASON_DESC = @REASON_DESC,
						S_EMPL_TYPE_CD = @S_EMPL_TYPE_CD,
						LAB_GRP_TYPE = @LAB_GRP_TYPE, -- CP600000586
						ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
					WHERE 	EMPL_ID = @EMPL_ID AND
						EFFECT_DT = @EFFECT_DT

                                        SET @SQLServer_error_code = @@ERROR
                                        IF @SQLServer_error_code <> 0                                           
										BEGIN
                                              SET @error_type = 5
                                              GOTO BL_ERROR_HANDLER
                                           END
				END


-- CR2350_Begin KM
				-- if EXMPT_FL change
				ELSE IF (@EXMPT_FL IS NOT NULL)
				BEGIN
					--EFFECTIVE DATE CHANGES
					--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
					SET @CUR_EXMPT_FL = NULL
					SET @PREV_EXMPT_FL = NULL	
					SET @PREV_END_DT = NULL	
					SET @PREV_S_HRLY_SAL_CD = NULL --KM 2011-09-19
					
					SELECT  @CUR_EXMPT_FL = EXMPT_FL
					FROM    IMAR.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND	EFFECT_DT = @LAST_EFFECT_DT
					
					--EFFECTIVE DATE CHANGES
					--IF CURRENT EXMPT_FL IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
					--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
					IF @CUR_EXMPT_FL = @EXMPT_FL
					BEGIN
						SELECT 	@PREV_EXMPT_FL = EXMPT_FL,
								@PREV_S_HRLY_SAL_CD = S_HRLY_SAL_CD, --KM 2011-09-19
								@PREV_END_DT = END_DT							
						FROM 	IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID	
						AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND EXMPT_FL <> @EXMPT_FL)
												
						--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
						IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
						BEGIN
							
							--ROLL OLD EXMPT_FL FORWARD
							UPDATE IMAR.DELTEK.EMPL_LAB_INFO
							SET
							EXMPT_FL = @PREV_EXMPT_FL, 
							S_HRLY_SAL_CD = @PREV_S_HRLY_SAL_CD, --KM 2011-09-19
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
							WHERE 	EMPL_ID = @EMPL_ID
							AND	EFFECT_DT > @PREV_END_DT
							AND	EFFECT_DT < @EFFECT_DT
						
							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @PREV_EXMPT_FL, @PREV_END_DT+1, @EFFECT_DT-1				

							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
						ELSE IF @PREV_END_DT IS NOT NULL
						BEGIN
							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @EXMPT_FL, @EFFECT_DT, @PREV_END_DT

							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
					END
					ELSE
					BEGIN
						--KM CR2350 - uncommented
						--TRACK RETRO TIMESHEET DATA - SALARY ONLY
						INSERT INTO XX_R22_CERIS_RETRO_TS
						(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
						SELECT @EMPL_ID, @EXMPT_FL, @EFFECT_DT, GETDATE()
						
						SET @SQLServer_error_code = @@ERROR
	                                        IF @SQLServer_error_code <> 0
	                                           BEGIN
	                                               SET @error_type = 7	                                               
						       GOTO BL_ERROR_HANDLER
	                                           END
					END
					
					--PROCESS EXMPT_FL CHANGE
					UPDATE IMAR.DELTEK.EMPL_LAB_INFO
					SET 	EXMPT_FL = @EXMPT_FL,
							S_HRLY_SAL_CD = @S_HRLY_SAL_CD, --KM 2011-09-19
						ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
					WHERE 	EMPL_ID = @EMPL_ID AND
						EFFECT_DT = @EFFECT_DT

                                        SET @SQLServer_error_code = @@ERROR
                                        IF @SQLServer_error_code <> 0
                                           BEGIN
                                              SET @error_type = 5
                                              GOTO BL_ERROR_HANDLER
                                           END
				END
-- CR2350_End KM


				-- if only status change
				ELSE IF (@REASON_DESC IS NOT NULL AND (@S_EMPL_TYPE_CD = NULL))
				BEGIN
					UPDATE IMAR.DELTEK.EMPL_LAB_INFO
					SET 	REASON_DESC = @REASON_DESC,
						LAB_GRP_TYPE = @LAB_GRP_TYPE,
						ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
					WHERE 	EMPL_ID = @EMPL_ID AND
						EFFECT_DT = @EFFECT_DT

                                        SET @SQLServer_error_code = @@ERROR
                                        IF @SQLServer_error_code <> 0
                                           BEGIN
                                              SET @error_type = 5
                                              GOTO BL_ERROR_HANDLER
                                           END
				END
			END
			





			/*
			2.  IF CHANGE IS EFFECTIVE AFTER THE CURRENT EMPL_LAB_INFO RECORD, INSERT NEW RECORD AND MODIFY CURRENT RECORD
			*/
			ELSE IF (@LAST_EFFECT_DT < @EFFECT_DT)
			BEGIN

				-- figure out change, 
				-- get previous values
				-- insert previous values + changed values
				
				-- if job family, band change
				IF (@GENL_LAB_CAT_CD IS NOT NULL)
				BEGIN	
					--EFFECTIVE DATE CHANGES
					--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
					SET @CUR_GENL_LAB_CAT_CD = NULL
					SET @PREV_GENL_LAB_CAT_CD = NULL	
					SET @PREV_END_DT = NULL	
					
					SELECT  @CUR_GENL_LAB_CAT_CD = GENL_LAB_CAT_CD
					FROM    IMAR.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND	EFFECT_DT = @LAST_EFFECT_DT
						
					--EFFECTIVE DATE CHANGES
					--IF CURRENT GLC IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
					--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
					IF @CUR_GENL_LAB_CAT_CD = @GENL_LAB_CAT_CD
					BEGIN
						SELECT 	@PREV_GENL_LAB_CAT_CD = GENL_LAB_CAT_CD,
							@PREV_END_DT = END_DT
						FROM 	IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID	
						AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND GENL_LAB_CAT_CD <> @GENL_LAB_CAT_CD)
							
						--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
						IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
						BEGIN
							
							--ROLL OLD GLC FORWARD
							UPDATE IMAR.DELTEK.EMPL_LAB_INFO
							SET GENL_LAB_CAT_CD = 	@PREV_GENL_LAB_CAT_CD, 
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
							WHERE 	EMPL_ID = @EMPL_ID
							AND	EFFECT_DT > @PREV_END_DT
							AND	EFFECT_DT < @EFFECT_DT
									
							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
						ELSE IF @PREV_END_DT IS NOT NULL
						BEGIN
				
							/*
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, NULL, @GENL_LAB_CAT_CD, @EFFECT_DT, @PREV_END_DT
							*/
					
							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
					END
					ELSE
					BEGIN
				
						/*
						--TRACK RETRO TIMESHEET DATA - SALARY ONLY
						INSERT INTO XX_R22_CERIS_RETRO_TS
						(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
						SELECT @EMPL_ID, NULL, @GENL_LAB_CAT_CD, @EFFECT_DT, GETDATE()
						*/
				
						SET @SQLServer_error_code = @@ERROR
	                                        IF @SQLServer_error_code <> 0
	                                           BEGIN
	                                               SET @error_type = 7
	                                               GOTO BL_ERROR_HANDLER
	                                           END
					END
				
					--PROCESS GLC CHANGE
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'JOB FAMILY/BAND CHANGE'
					INSERT INTO IMAR.DELTEK.EMPL_LAB_INFO
					(EMPL_ID, EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
					 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
					 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
					 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, ROWVERSION)

					SELECT
					 @EMPL_ID, @EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
					 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,					 
					 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
					 STD_EFFECT_AMT, LAB_GRP_TYPE, @GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, 
					 REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
  					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
					FROM IMAR.DELTEK.EMPL_LAB_INFO
					WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @LAST_EFFECT_DT)

                                        SET @SQLServer_error_code = @@ERROR
                                        IF @SQLServer_error_code <> 0
                                           BEGIN
                                              SET @error_type = 6
                                              GOTO BL_ERROR_HANDLER
                                           END
				END



				-- if position change
				ELSE IF (@TITLE_DESC IS NOT NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'POSITION CHANGE'
					INSERT INTO IMAR.DELTEK.EMPL_LAB_INFO
					(EMPL_ID, EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
					 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
					 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
					 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
  					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,					 
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, ROWVERSION)

					SELECT
					 @EMPL_ID, @EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
					 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
					 ORG_ID, @TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
					 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
  					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
					FROM IMAR.DELTEK.EMPL_LAB_INFO
					WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @LAST_EFFECT_DT)
			
                                        SET @SQLServer_error_code = @@ERROR
                                        IF @SQLServer_error_code <> 0
                                           BEGIN
                                              SET @error_type = 6
                                              GOTO BL_ERROR_HANDLER
                                           END
				END

				ELSE IF (@ORG_ID IS NOT NULL)
				BEGIN
					--EFFECTIVE DATE CHANGES
					--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
					SET @CUR_ORG_ID = NULL
					SET @PREV_ORG_ID = NULL	
					SET @PREV_END_DT = NULL	
					
					SELECT  @CUR_ORG_ID = ORG_ID
					FROM    IMAR.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND	EFFECT_DT = @LAST_EFFECT_DT
					
					--EFFECTIVE DATE CHANGES
					--IF CURRENT ORG IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
					--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
					IF @CUR_ORG_ID = @ORG_ID
					BEGIN
						SELECT 	@PREV_ORG_ID = ORG_ID, 
							@PREV_LAB_GRP_TYPE = LAB_GRP_TYPE,
							@PREV_SEC_ORG_ID = SEC_ORG_ID,
							@PREV_END_DT = END_DT
						FROM 	IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID	
						AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND ORG_ID <> @ORG_ID)
						
						--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
						IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
						BEGIN							
							--ROLL OLD ORG_ID FORWARD
							UPDATE IMAR.DELTEK.EMPL_LAB_INFO
							SET
							ORG_ID = @PREV_ORG_ID, 
							--LAB_GRP_TYPE = LEFT(@PREV_LAB_GRP_TYPE, 1) + EMPL_CLASS_CD,
							SEC_ORG_ID = @PREV_SEC_ORG_ID,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
							WHERE 	EMPL_ID = @EMPL_ID
							AND	EFFECT_DT > @PREV_END_DT
							AND	EFFECT_DT < @EFFECT_DT
						
							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @PREV_ORG_ID, @PREV_END_DT+1, @EFFECT_DT-1
							

							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
						ELSE IF @PREV_END_DT IS NOT NULL
						BEGIN

							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @ORG_ID, @EFFECT_DT, @PREV_END_DT
							

							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END	
						END
					END
					ELSE
					BEGIN

						--KM CR2350 - uncommented
						--TRACK RETRO TIMESHEET DATA - SALARY ONLY
						INSERT INTO XX_R22_CERIS_RETRO_TS
						(EMPL_ID, NEW_ORG_ID, EFFECT_DT, END_DT)
						SELECT @EMPL_ID, @ORG_ID, @EFFECT_DT, GETDATE()
						
						SET @SQLServer_error_code = @@ERROR
	                                        IF @SQLServer_error_code <> 0
	                                           BEGIN
	                                               SET @error_type = 7
	                                               GOTO BL_ERROR_HANDLER
	                                           END	
					END
					
					--PROCESS ORG CHANGE
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'DEPARTMENT CHANGE'
					INSERT INTO IMAR.DELTEK.EMPL_LAB_INFO
					(EMPL_ID, EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
					 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
					 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
					 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
  					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, ROWVERSION)

					SELECT
					 @EMPL_ID, @EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
					 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
					 @ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
					 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, @SEC_ORG_ID, COMMENTS,
  					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
					FROM IMAR.DELTEK.EMPL_LAB_INFO
					WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @LAST_EFFECT_DT)

                                        SET @SQLServer_error_code = @@ERROR
                                        IF @SQLServer_error_code <> 0
                                           BEGIN
                                              SET @error_type = 6
                                              GOTO BL_ERROR_HANDLER
                                           END	
				END



--begin EMPL_CLASS_CD & SALARY
				-- if EMPL_CLASS_CD change
				ELSE IF (@EMPL_CLASS_CD IS NOT NULL)
				BEGIN
					--EFFECTIVE DATE CHANGES
					--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
					SET @CUR_EMPL_CLASS_CD = NULL
					SET @PREV_EMPL_CLASS_CD = NULL	
					SET @PREV_END_DT = NULL	
					
					SELECT  @CUR_EMPL_CLASS_CD = EMPL_CLASS_CD
					FROM    IMAR.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND	EFFECT_DT = @LAST_EFFECT_DT
					
					--EFFECTIVE DATE CHANGES
					--IF CURRENT EMPL_CLASS_CD IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
					--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
					IF @CUR_EMPL_CLASS_CD = @EMPL_CLASS_CD
					BEGIN
						SELECT 	@PREV_EMPL_CLASS_CD = EMPL_CLASS_CD,
							@PREV_LAB_GRP_TYPE = LAB_GRP_TYPE, 
							@PREV_END_DT = END_DT
						FROM 	IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID	
						AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND EMPL_CLASS_CD <> @EMPL_CLASS_CD)
												
						--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
						IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
						BEGIN
							
							--ROLL OLD EMPL_CLASS_CD FORWARD
							UPDATE IMAR.DELTEK.EMPL_LAB_INFO
							SET
							EMPL_CLASS_CD = @PREV_EMPL_CLASS_CD, 
							--LAB_GRP_TYPE = LEFT(LAB_GRP_TYPE, 1) + @PREV_EMPL_CLASS_CD,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
							WHERE 	EMPL_ID = @EMPL_ID
							AND	EFFECT_DT > @PREV_END_DT
							AND	EFFECT_DT < @EFFECT_DT
						
							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_EMPL_CLASS_CD, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @PREV_EMPL_CLASS_CD, @PREV_END_DT+1, @EFFECT_DT-1
							
							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
						ELSE IF @PREV_END_DT IS NOT NULL
						BEGIN
							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_EMPL_CLASS_CD, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @EMPL_CLASS_CD, @EFFECT_DT, @PREV_END_DT

							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
					END
					ELSE
					BEGIN
						--KM CR2350 - uncommented
						--TRACK RETRO TIMESHEET DATA - SALARY ONLY
						INSERT INTO XX_R22_CERIS_RETRO_TS
						(EMPL_ID, NEW_EMPL_CLASS_CD, EFFECT_DT, END_DT)
						SELECT @EMPL_ID, @EMPL_CLASS_CD, @EFFECT_DT, GETDATE()

						SET @SQLServer_error_code = @@ERROR
	                                        IF @SQLServer_error_code <> 0
	                                           BEGIN
	                                               SET @error_type = 7	                                               
						       GOTO BL_ERROR_HANDLER
	                                           END
					END
					
					--PROCESS EMPL_CLASS_CD CHANGE
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'EMPL_CLASS_CD CHANGE'
					INSERT INTO IMAR.DELTEK.EMPL_LAB_INFO
					(EMPL_ID, EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
					 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
					 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
					 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, ROWVERSION)

					SELECT
					 @EMPL_ID, @EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
					 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
					 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
					 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
					 @EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
					FROM IMAR.DELTEK.EMPL_LAB_INFO
					WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @LAST_EFFECT_DT)

                                        SET @SQLServer_error_code = @@ERROR
                                        IF @SQLServer_error_code <> 0
                                           BEGIN
                                              SET @error_type = 6
                                              GOTO BL_ERROR_HANDLER
                                           END	
				END

				-- if SALARY - HRLY_AMT change
				ELSE IF (@HRLY_AMT IS NOT NULL)
				BEGIN
					--EFFECTIVE DATE CHANGES
					--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
					SET @CUR_HRLY_AMT = NULL
					SET @CUR_WORK_YR_HRS_NO = NULL
					SET @PREV_HRLY_AMT = NULL
					SET @PREV_SAL_AMT = NULL
					SET @PREV_ANNL_AMT = NULL
					SET @PREV_WORK_YR_HRS_NO = NULL						
					--KM 2011-09-19 SET @PREV_S_HRLY_SAL_CD = NULL
					SET @PREV_STD_EST_HRS = NULL	
					SET @PREV_END_DT = NULL
					
-- CR2350_Begin KM
					SELECT  @CUR_HRLY_AMT = HRLY_AMT,
						@CUR_WORK_YR_HRS_NO = WORK_YR_HRS_NO
					FROM    IMAR.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND	EFFECT_DT = @LAST_EFFECT_DT
					
					--EFFECTIVE DATE CHANGES
					--IF CURRENT HRLY_AMT IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
					--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
					IF (@CUR_HRLY_AMT = @HRLY_AMT AND @CUR_WORK_YR_HRS_NO = @WORK_YR_HRS_NO)
					BEGIN
						SELECT 	@PREV_HRLY_AMT = HRLY_AMT,
							@PREV_SAL_AMT = SAL_AMT,
							@PREV_ANNL_AMT = ANNL_AMT,
							@PREV_WORK_YR_HRS_NO = WORK_YR_HRS_NO,
							--KM 2011-09-19 @PREV_S_HRLY_SAL_CD = S_HRLY_SAL_CD,
							@PREV_STD_EST_HRS = STD_EST_HRS,	
							@PREV_END_DT = END_DT
						FROM 	IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID	
						AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND (HRLY_AMT <> @HRLY_AMT OR WORK_YR_HRS_NO <> @WORK_YR_HRS_NO))
												
						--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
						IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
						BEGIN
							
							--ROLL OLD HRLY_AMT FORWARD
							UPDATE IMAR.DELTEK.EMPL_LAB_INFO
							SET
							HRLY_AMT = @PREV_HRLY_AMT, 
							SAL_AMT = @PREV_SAL_AMT,
							ANNL_AMT = @PREV_ANNL_AMT,
							WORK_YR_HRS_NO = @PREV_WORK_YR_HRS_NO,
							--KM 2011-09-19 S_HRLY_SAL_CD = @PREV_S_HRLY_SAL_CD,
							STD_EST_HRS = @PREV_STD_EST_HRS,	
							--END_DT = @PREV_END_DT,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
							WHERE 	EMPL_ID = @EMPL_ID
							AND	EFFECT_DT > @PREV_END_DT
							AND	EFFECT_DT < @EFFECT_DT
-- CR2350_End KM
							--KM salary date
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @PREV_HRLY_AMT, @PREV_END_DT+1, @EFFECT_DT-1
							
					
							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
						ELSE IF @PREV_END_DT IS NOT NULL
						BEGIN
							--KM salary date
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @HRLY_AMT, @EFFECT_DT, @PREV_END_DT
							
							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
					END
					ELSE
					BEGIN
						--TRACK RETRO TIMESHEET DATA - SALARY ONLY
						INSERT INTO XX_R22_CERIS_RETRO_TS
						(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
						SELECT @EMPL_ID, @HRLY_AMT, @EFFECT_DT, GETDATE()
				
						SET @SQLServer_error_code = @@ERROR
	                                        IF @SQLServer_error_code <> 0
	                                           BEGIN
	                                               SET @error_type = 7	                                               
						       GOTO BL_ERROR_HANDLER
	                                           END
					END
					
					--PROCESS HRLY_AMT CHANGE
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'SALARY CHANGE'
					INSERT INTO IMAR.DELTEK.EMPL_LAB_INFO
					(EMPL_ID, EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
					 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
					 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
					 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
  					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, ROWVERSION)
					SELECT
					 @EMPL_ID, @EFFECT_DT, /*KM 2011-09-19*/ S_HRLY_SAL_CD, @HRLY_AMT,
					 @SAL_AMT, @ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
					 ORG_ID, TITLE_DESC, WORK_STATE_CD, @STD_EST_HRS,
					 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
  					 EMPL_CLASS_CD, @WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
					FROM IMAR.DELTEK.EMPL_LAB_INFO
					WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @LAST_EFFECT_DT)

                                        SET @SQLServer_error_code = @@ERROR
                                        IF @SQLServer_error_code <> 0
                                           BEGIN
                                              SET @error_type = 6
                                              GOTO BL_ERROR_HANDLER
                                           END	
				END

--end EMPL_CLASS_CD & SALARY

				-- else if status3 change
				ELSE IF (@S_EMPL_TYPE_CD IS NOT NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'STATUS3 CHANGE'
					INSERT INTO IMAR.DELTEK.EMPL_LAB_INFO
					(EMPL_ID, EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
					 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
					 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
					 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
  					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, ROWVERSION)

					SELECT
					 @EMPL_ID, @EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
					 SAL_AMT, ANNL_AMT, EXMPT_FL, @S_EMPL_TYPE_CD,
					 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
					 STD_EFFECT_AMT,
					 @LAB_GRP_TYPE, -- CP600000586
					 GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, @REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
  					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
					FROM IMAR.DELTEK.EMPL_LAB_INFO
					WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @LAST_EFFECT_DT)

                                        SET @SQLServer_error_code = @@ERROR
                                        IF @SQLServer_error_code <> 0
                                           BEGIN
                                              SET @error_type = 6
                                              GOTO BL_ERROR_HANDLER
                                           END
				END


-- CR2350_Begin KM
				-- if EXMPT_FL change
				ELSE IF (@EXMPT_FL IS NOT NULL)
				BEGIN
					--EFFECTIVE DATE CHANGES
					--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
					SET @CUR_EXMPT_FL = NULL
					SET @PREV_EXMPT_FL = NULL	
					SET @PREV_END_DT = NULL	
					SET @PREV_S_HRLY_SAL_CD = NULL --KM 2011-09-19
					
					SELECT  @CUR_EXMPT_FL = EXMPT_FL
					FROM    IMAR.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND	EFFECT_DT = @LAST_EFFECT_DT
					
					--EFFECTIVE DATE CHANGES
					--IF CURRENT EXMPT_FL IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
					--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
					IF @CUR_EXMPT_FL = @EXMPT_FL
					BEGIN
						SELECT 	@PREV_EXMPT_FL = EXMPT_FL,
							@PREV_LAB_GRP_TYPE = LAB_GRP_TYPE,
							@PREV_S_HRLY_SAL_CD = S_HRLY_SAL_CD,   --KM 2011-09-19
							@PREV_END_DT = END_DT
						FROM 	IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID	
						AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND EXMPT_FL <> @EXMPT_FL)
												
						--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
						IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
						BEGIN
							
							--ROLL OLD EXMPT_FL FORWARD
							UPDATE IMAR.DELTEK.EMPL_LAB_INFO
							SET
							EXMPT_FL = @PREV_EXMPT_FL, 
							S_HRLY_SAL_CD = @PREV_S_HRLY_SAL_CD,  --KM 2011-09-19
							--LAB_GRP_TYPE = LEFT(LAB_GRP_TYPE, 1) + @PREV_EXMPT_FL,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
							WHERE 	EMPL_ID = @EMPL_ID
							AND	EFFECT_DT > @PREV_END_DT
							AND	EFFECT_DT < @EFFECT_DT
						
							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @PREV_EXMPT_FL, @PREV_END_DT+1, @EFFECT_DT-1
							

							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
						ELSE IF @PREV_END_DT IS NOT NULL
						BEGIN

							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @EXMPT_FL, @EFFECT_DT, @PREV_END_DT
							

							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
					END
					ELSE
					BEGIN

						--KM CR2350 - uncommented
						--TRACK RETRO TIMESHEET DATA - SALARY ONLY
						INSERT INTO XX_R22_CERIS_RETRO_TS
						(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
						SELECT @EMPL_ID, @EXMPT_FL, @EFFECT_DT, GETDATE()
						

						SET @SQLServer_error_code = @@ERROR
	                                        IF @SQLServer_error_code <> 0
	                                           BEGIN
	                                               SET @error_type = 7	                                               
						       GOTO BL_ERROR_HANDLER
	                                           END
					END
					
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'EXEMPT CHANGE'
					INSERT INTO IMAR.DELTEK.EMPL_LAB_INFO
					(EMPL_ID, EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
					 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
					 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
					 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, ROWVERSION)

					SELECT
					 @EMPL_ID, @EFFECT_DT, @S_HRLY_SAL_CD, HRLY_AMT,   --KM 2011-09-19
					 SAL_AMT, ANNL_AMT, @EXMPT_FL, S_EMPL_TYPE_CD,
					 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
					 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
					FROM IMAR.DELTEK.EMPL_LAB_INFO
					WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @LAST_EFFECT_DT)

                                        SET @SQLServer_error_code = @@ERROR
                                        IF @SQLServer_error_code <> 0
                                           BEGIN
                                              SET @error_type = 6
                                              GOTO BL_ERROR_HANDLER
                                           END
				END
-- CR2350_End KM


				-- if only status change
				ELSE IF (@REASON_DESC IS NOT NULL AND (@S_EMPL_TYPE_CD = NULL))
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'STATUS CHANGE'
					INSERT INTO IMAR.DELTEK.EMPL_LAB_INFO
					(EMPL_ID, EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
					 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
					 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
					 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
  					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, ROWVERSION)

					SELECT
					 @EMPL_ID, @EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
					 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
					 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
					 STD_EFFECT_AMT, @LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, @REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
  					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
					FROM IMAR.DELTEK.EMPL_LAB_INFO
					WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @LAST_EFFECT_DT)

                                        SET @SQLServer_error_code = @@ERROR
                                        IF @SQLServer_error_code <> 0
                                           BEGIN
                                              SET @error_type = 6
                                              GOTO BL_ERROR_HANDLER
                                           END
				END

				--NEED TO CLOSE OUT LAST RECORD AFTER INSERTING NEW ONE
				UPDATE 	IMAR.DELTEK.EMPL_LAB_INFO
				SET	END_DT = @EFFECT_DT - 1,
					ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
				WHERE 	EMPL_ID = @EMPL_ID AND EFFECT_DT = @LAST_EFFECT_DT
				
			END
			






			/*
			3.  IF CHANGE IS EFFECTIVE BEFORE THE CURRENT EMPL_LAB_INFO RECORD
			*/
			ELSE IF (@LAST_EFFECT_DT > @EFFECT_DT)
			BEGIN
				-- figure out if record with same effective date exists
				SELECT @rows = COUNT(EMPL_ID) FROM IMAR.DELTEK.EMPL_LAB_INFO
				WHERE EMPL_ID = @EMPL_ID AND EFFECT_DT = @EFFECT_DT


				/*
				3a.  AND A RECORD WITH THAT EFFECTIVE DATE ALREADY EXISTS, JUST UPDATE IT AND ROLL THE CHANGE FORWARD
				*/
				-- if record exists, just update it
				-- and do retro rollforward/ts if required
				IF (@rows <> 0)
				BEGIN
					-- figure out change, and update accordingly
				
					-- if job family, band, work sched change
					IF (@GENL_LAB_CAT_CD IS NOT NULL)
					BEGIN
						--EFFECTIVE DATE CHANGES
						--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
						SET @CUR_GENL_LAB_CAT_CD = NULL
						SET @PREV_GENL_LAB_CAT_CD = NULL	
						SET @PREV_END_DT = NULL	
						
						SELECT  @CUR_GENL_LAB_CAT_CD = GENL_LAB_CAT_CD
						FROM    IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID
						AND	EFFECT_DT = @LAST_EFFECT_DT
							
						--EFFECTIVE DATE CHANGES
						--IF CURRENT GLC IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
						--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
						IF @CUR_GENL_LAB_CAT_CD = @GENL_LAB_CAT_CD
						BEGIN
							SELECT 	@PREV_GENL_LAB_CAT_CD = GENL_LAB_CAT_CD, 
								@PREV_END_DT = END_DT
							FROM 	IMAR.DELTEK.EMPL_LAB_INFO
							WHERE 	EMPL_ID = @EMPL_ID	
							AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND GENL_LAB_CAT_CD <> @GENL_LAB_CAT_CD)
						
							--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
							IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
							BEGIN
								
								--ROLL OLD GLC FORWARD
								UPDATE IMAR.DELTEK.EMPL_LAB_INFO
								SET GENL_LAB_CAT_CD = 	@PREV_GENL_LAB_CAT_CD, 
									ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
								WHERE 	EMPL_ID = @EMPL_ID
								AND	EFFECT_DT > @PREV_END_DT
								AND	EFFECT_DT < @EFFECT_DT
							
								/*
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, NULL, @PREV_GENL_LAB_CAT_CD, @PREV_END_DT+1, @EFFECT_DT-1
								*/
						
								SET @SQLServer_error_code = @@ERROR
			                                        IF @SQLServer_error_code <> 0
			                                BEGIN
			                                               SET @error_type = 7
			                                               GOTO BL_ERROR_HANDLER
			                                           END
							END
							ELSE IF @PREV_END_DT IS NOT NULL
							BEGIN
								/*
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, NULL, @GENL_LAB_CAT_CD, @EFFECT_DT, @PREV_END_DT
								*/
						
								SET @SQLServer_error_code = @@ERROR
			                                        IF @SQLServer_error_code <> 0
			                                           BEGIN
			                                               SET @error_type = 7
			                                               GOTO BL_ERROR_HANDLER
			                                           END
							END
						END
						ELSE
						BEGIN
							/*
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, NULL, @GENL_LAB_CAT_CD, @EFFECT_DT, GETDATE()
							*/
					
							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
	
						--PROCESS GLC CHANGE
											
						UPDATE IMAR.DELTEK.EMPL_LAB_INFO
						SET 	GENL_LAB_CAT_CD = @GENL_LAB_CAT_CD,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						WHERE 	(EMPL_ID = @EMPL_ID) AND
							(EFFECT_DT >= @EFFECT_DT)

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 5
                                                       GOTO BL_ERROR_HANDLER
                                                   END

					END
					
					-- if position change
					ELSE IF (@TITLE_DESC IS NOT NULL)
					BEGIN
						UPDATE IMAR.DELTEK.EMPL_LAB_INFO
						SET 	TITLE_DESC = @TITLE_DESC,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						WHERE 	(EMPL_ID = @EMPL_ID) AND
							(EFFECT_DT >= @EFFECT_DT)

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 5
                                                       GOTO BL_ERROR_HANDLER
                                                   END
					END
	
					-- if department change
					-- requires retro-time sheet
					ELSE IF (@ORG_ID IS NOT NULL)
					BEGIN
						--EFFECTIVE DATE CHANGES
						--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
						SET @CUR_ORG_ID = NULL
						SET @PREV_ORG_ID = NULL	
						SET @PREV_END_DT = NULL	
						
						SELECT  @CUR_ORG_ID = ORG_ID
						FROM    IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID
						AND	EFFECT_DT = @LAST_EFFECT_DT
						
						--EFFECTIVE DATE CHANGES
						--IF CURRENT ORG IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
						--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
						IF @CUR_ORG_ID = @ORG_ID
						BEGIN
							SELECT 	@PREV_ORG_ID = ORG_ID, 
								@PREV_LAB_GRP_TYPE = LAB_GRP_TYPE,
								@PREV_SEC_ORG_ID = SEC_ORG_ID,
								@PREV_END_DT = END_DT
							FROM 	IMAR.DELTEK.EMPL_LAB_INFO
							WHERE 	EMPL_ID = @EMPL_ID	
							AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND ORG_ID <> @ORG_ID)
						
							--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
							IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
							BEGIN
								
								--ROLL OLD ORG_ID FORWARD
								UPDATE IMAR.DELTEK.EMPL_LAB_INFO
								SET
								ORG_ID = @PREV_ORG_ID, 
								--LAB_GRP_TYPE = LEFT(@PREV_LAB_GRP_TYPE,1)+EMPL_CLASS_CD,
								SEC_ORG_ID = @PREV_SEC_ORG_ID,
								ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
								WHERE 	EMPL_ID = @EMPL_ID
								AND	EFFECT_DT > @PREV_END_DT
								AND	EFFECT_DT < @EFFECT_DT
							
								--KM CR2350 - uncommented
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_ORG_ID, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @PREV_ORG_ID, @PREV_END_DT+1, @EFFECT_DT-1
								

								SET @SQLServer_error_code = @@ERROR
			                                        IF @SQLServer_error_code <> 0
			                                           BEGIN
			                                               SET @error_type = 7
			                                               GOTO BL_ERROR_HANDLER
			                                           END
							END
							ELSE IF @PREV_END_DT IS NOT NULL
							BEGIN
								--KM CR2350 - uncommented
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_ORG_ID, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @ORG_ID, @EFFECT_DT, @PREV_END_DT
								
								SET @SQLServer_error_code = @@ERROR
			                                        IF @SQLServer_error_code <> 0
			                                           BEGIN
			                                               SET @error_type = 7
			                                               GOTO BL_ERROR_HANDLER
			                                           END	
							END
						END
						ELSE
						BEGIN
							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @ORG_ID, @EFFECT_DT, GETDATE()
							
							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END	
						END
						
						--PROCESS ORG CHANGE
						UPDATE IMAR.DELTEK.EMPL_LAB_INFO
						SET 	ORG_ID = @ORG_ID,
							--LAB_GRP_TYPE = LEFT(@LAB_GRP_TYPE,1)+EMPL_CLASS_CD,
							SEC_ORG_ID = @SEC_ORG_ID,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						WHERE 	(EMPL_ID = @EMPL_ID) AND
							(EFFECT_DT >= @EFFECT_DT)

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 5
                                                       GOTO BL_ERROR_HANDLER
                                                   END
					END






--begin EMPL_CLASS_CD & SALARY
					-- if EMPL_CLASS_CD change
					ELSE IF (@EMPL_CLASS_CD IS NOT NULL)
					BEGIN
						--EFFECTIVE DATE CHANGES
						--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
						SET @CUR_EMPL_CLASS_CD = NULL
						SET @PREV_EMPL_CLASS_CD = NULL	
						SET @PREV_END_DT = NULL	
						
						SELECT  @CUR_EMPL_CLASS_CD = EMPL_CLASS_CD
						FROM    IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID
						AND	EFFECT_DT = @LAST_EFFECT_DT
						
						--EFFECTIVE DATE CHANGES
						--IF CURRENT EMPL_CLASS_CD IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
						--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
						IF @CUR_EMPL_CLASS_CD = @EMPL_CLASS_CD
						BEGIN
							SELECT 	@PREV_EMPL_CLASS_CD = EMPL_CLASS_CD,
								@PREV_LAB_GRP_TYPE = LAB_GRP_TYPE, 
								@PREV_END_DT = END_DT
							FROM 	IMAR.DELTEK.EMPL_LAB_INFO
							WHERE 	EMPL_ID = @EMPL_ID	
							AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND EMPL_CLASS_CD <> @EMPL_CLASS_CD)
													
							--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
							IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
							BEGIN
								
								--ROLL OLD EMPL_CLASS_CD FORWARD
								UPDATE IMAR.DELTEK.EMPL_LAB_INFO
								SET
								EMPL_CLASS_CD = @PREV_EMPL_CLASS_CD, 
								--LAB_GRP_TYPE = LEFT(LAB_GRP_TYPE, 1) + @PREV_EMPL_CLASS_CD,
								ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
								WHERE 	EMPL_ID = @EMPL_ID
								AND	EFFECT_DT > @PREV_END_DT
								AND	EFFECT_DT < @EFFECT_DT
							
								--KM CR2350 - uncommented
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_EMPL_CLASS_CD, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @PREV_EMPL_CLASS_CD, @PREV_END_DT+1, @EFFECT_DT-1

								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								BEGIN
								    SET @error_type = 7
								    GOTO BL_ERROR_HANDLER
								END
							END
							ELSE IF @PREV_END_DT IS NOT NULL
							BEGIN
								--KM CR2350 - uncommented
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_EMPL_CLASS_CD, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @EMPL_CLASS_CD, @EFFECT_DT, @PREV_END_DT
								
								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								BEGIN
								    SET @error_type = 7
								    GOTO BL_ERROR_HANDLER
								END
							END
						END
						ELSE
						BEGIN
							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_EMPL_CLASS_CD, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @EMPL_CLASS_CD, @EFFECT_DT, GETDATE()
							
							SET @SQLServer_error_code = @@ERROR
							IF @SQLServer_error_code <> 0
							BEGIN
							    SET @error_type = 7	                                               
							    GOTO BL_ERROR_HANDLER
							END
						END
						
						--PROCESS EMPL_CLASS_CD CHANGE
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'EMPL_CLASS_CD CHANGE'
						UPDATE IMAR.DELTEK.EMPL_LAB_INFO
						SET 	EMPL_CLASS_CD = @EMPL_CLASS_CD,
							--LAB_GRP_TYPE =  LEFT(LAB_GRP_TYPE,1)+@EMPL_CLASS_CD,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						WHERE 	(EMPL_ID = @EMPL_ID) AND
							(EFFECT_DT >= @EFFECT_DT)

						SET @SQLServer_error_code = @@ERROR
						IF @SQLServer_error_code <> 0
						BEGIN
						    SET @error_type = 5
						    GOTO BL_ERROR_HANDLER
						END
						 
					END

					-- if SALARY - HRLY_AMT change
					ELSE IF (@HRLY_AMT IS NOT NULL)
					BEGIN
						--EFFECTIVE DATE CHANGES
						--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
						SET @CUR_HRLY_AMT = NULL
						SET @CUR_WORK_YR_HRS_NO = NULL
						SET @PREV_HRLY_AMT = NULL
						SET @PREV_SAL_AMT = NULL
						SET @PREV_ANNL_AMT = NULL
						SET @PREV_WORK_YR_HRS_NO = NULL						
						 --KM 2011-09-19 SET @PREV_S_HRLY_SAL_CD = NULL
						SET @PREV_STD_EST_HRS = NULL	
						SET @PREV_END_DT = NULL
						
-- CR2350_Begin KM
						SELECT  @CUR_HRLY_AMT = HRLY_AMT,
							@CUR_WORK_YR_HRS_NO = WORK_YR_HRS_NO
						FROM    IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID
						AND	EFFECT_DT = @LAST_EFFECT_DT
						
						--EFFECTIVE DATE CHANGES
						--IF CURRENT HRLY_AMT IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
						--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
						IF (@CUR_HRLY_AMT = @HRLY_AMT AND @CUR_WORK_YR_HRS_NO = @WORK_YR_HRS_NO)
						BEGIN
							SELECT 	@PREV_HRLY_AMT = HRLY_AMT,
								@PREV_SAL_AMT = SAL_AMT,
								@PREV_ANNL_AMT = ANNL_AMT,
								@PREV_WORK_YR_HRS_NO = WORK_YR_HRS_NO,
								 --KM 2011-09-19 @PREV_S_HRLY_SAL_CD = S_HRLY_SAL_CD,
								@PREV_STD_EST_HRS = STD_EST_HRS,	
								@PREV_END_DT = END_DT
							FROM 	IMAR.DELTEK.EMPL_LAB_INFO
							WHERE 	EMPL_ID = @EMPL_ID	
							AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND (HRLY_AMT <> @HRLY_AMT OR WORK_YR_HRS_NO <> @WORK_YR_HRS_NO))
													
							--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
							IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
							BEGIN
								
								--ROLL OLD HRLY_AMT FORWARD
								UPDATE IMAR.DELTEK.EMPL_LAB_INFO
								SET
								HRLY_AMT = @PREV_HRLY_AMT, 
								SAL_AMT = @PREV_SAL_AMT,
								ANNL_AMT = @PREV_ANNL_AMT,
								WORK_YR_HRS_NO = @PREV_WORK_YR_HRS_NO,
								 --KM 2011-09-19 S_HRLY_SAL_CD = @PREV_S_HRLY_SAL_CD,
								STD_EST_HRS = @PREV_STD_EST_HRS,	
								--END_DT = @PREV_END_DT,
								ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
								WHERE 	EMPL_ID = @EMPL_ID
								AND	EFFECT_DT > @PREV_END_DT
								AND	EFFECT_DT < @EFFECT_DT
-- CR2350_End KM
							    --KM salary date
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @PREV_HRLY_AMT, @PREV_END_DT+1, @EFFECT_DT-1
								

								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								BEGIN
								    SET @error_type = 7
								    GOTO BL_ERROR_HANDLER
								END
							END
							ELSE IF @PREV_END_DT IS NOT NULL
							BEGIN
								--KM salary date
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @HRLY_AMT, @EFFECT_DT, @PREV_END_DT
								
								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								BEGIN
								    SET @error_type = 7
								    GOTO BL_ERROR_HANDLER
								END
							END
						END
						ELSE
						BEGIN
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @HRLY_AMT, @EFFECT_DT, GETDATE()
					
							SET @SQLServer_error_code = @@ERROR
							IF @SQLServer_error_code <> 0
							BEGIN
							    SET @error_type = 7	                                               
							    GOTO BL_ERROR_HANDLER
							END
						END
						
				
						
						--PROCESS HRLY_AMT CHANGE
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'SALARY CHANGE'

						UPDATE IMAR.DELTEK.EMPL_LAB_INFO
						SET 	HRLY_AMT = @HRLY_AMT,
							SAL_AMT = @SAL_AMT,
							ANNL_AMT = @ANNL_AMT,
							WORK_YR_HRS_NO = @WORK_YR_HRS_NO,
							 --KM 2011-09-19 S_HRLY_SAL_CD = @S_HRLY_SAL_CD,
							STD_EST_HRS = @STD_EST_HRS,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						WHERE 	(EMPL_ID = @EMPL_ID) AND
							(EFFECT_DT >= @EFFECT_DT)

						SET @SQLServer_error_code = @@ERROR
						IF @SQLServer_error_code <> 0
						BEGIN
						    SET @error_type = 5
						    GOTO BL_ERROR_HANDLER
						END
					END
--end EMPL_CLASS_CD & SALARY



					-- else if status3 change
					ELSE IF (@S_EMPL_TYPE_CD IS NOT NULL)
					BEGIN
						UPDATE IMAR.DELTEK.EMPL_LAB_INFO
						SET 	REASON_DESC = @REASON_DESC,
							S_EMPL_TYPE_CD = @S_EMPL_TYPE_CD,
							LAB_GRP_TYPE = @LAB_GRP_TYPE, -- CP600000586
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						WHERE 	(EMPL_ID = @EMPL_ID) AND
							(EFFECT_DT >= @EFFECT_DT)

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 5
                                                       GOTO BL_ERROR_HANDLER
                                                   END
					END

	
-- CR2350_Begin KM
					-- if EXMPT_FL change
					ELSE IF (@EXMPT_FL IS NOT NULL)
					BEGIN
						--EFFECTIVE DATE CHANGES
						--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
						SET @CUR_EXMPT_FL = NULL
						SET @PREV_EXMPT_FL = NULL	
						SET @PREV_END_DT = NULL	
						
						SELECT  @CUR_EXMPT_FL = EXMPT_FL
						FROM    IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID
						AND	EFFECT_DT = @LAST_EFFECT_DT
						
						--EFFECTIVE DATE CHANGES
						--IF CURRENT EXMPT_FL IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
						--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
						IF @CUR_EXMPT_FL = @EXMPT_FL
						BEGIN
							SELECT 	@PREV_EXMPT_FL = EXMPT_FL,
								@PREV_LAB_GRP_TYPE = LAB_GRP_TYPE, 
								@PREV_S_HRLY_SAL_CD = S_HRLY_SAL_CD,  --KM 2011-09-19
								@PREV_END_DT = END_DT
							FROM 	IMAR.DELTEK.EMPL_LAB_INFO
							WHERE 	EMPL_ID = @EMPL_ID	
							AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND EXMPT_FL <> @EXMPT_FL)
													
							--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
							IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
							BEGIN
								
								--ROLL OLD EXMPT_FL FORWARD
								UPDATE IMAR.DELTEK.EMPL_LAB_INFO
								SET
								EXMPT_FL = @PREV_EXMPT_FL, 
								S_HRLY_SAL_CD = @PREV_S_HRLY_SAL_CD,  --KM 2011-09-19
								--LAB_GRP_TYPE = LEFT(LAB_GRP_TYPE, 1) + @PREV_EXMPT_FL,
								ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
								WHERE 	EMPL_ID = @EMPL_ID
								AND	EFFECT_DT > @PREV_END_DT
								AND	EFFECT_DT < @EFFECT_DT
							
								--KM CR2350 - uncommented
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @PREV_EXMPT_FL, @PREV_END_DT+1, @EFFECT_DT-1
								

								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								BEGIN
								    SET @error_type = 7
								    GOTO BL_ERROR_HANDLER
								END
							END
							ELSE IF @PREV_END_DT IS NOT NULL
							BEGIN
								--KM CR2350 - uncommented
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @EXMPT_FL, @EFFECT_DT, @PREV_END_DT
								
								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								BEGIN
								    SET @error_type = 7
								    GOTO BL_ERROR_HANDLER
								END
							END
						END
						ELSE
						BEGIN
							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @EXMPT_FL, @EFFECT_DT, GETDATE()
							
							SET @SQLServer_error_code = @@ERROR
							IF @SQLServer_error_code <> 0
							BEGIN
							    SET @error_type = 7	                                               
							    GOTO BL_ERROR_HANDLER
							END
						END
						
						--PROCESS EXMPT_FL CHANGE
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'EXMPT_FL CHANGE'
						UPDATE IMAR.DELTEK.EMPL_LAB_INFO
						SET 	EXMPT_FL = @EXMPT_FL,
								S_HRLY_SAL_CD = @S_HRLY_SAL_CD,  --KM 2011-09-19
							--LAB_GRP_TYPE =  LEFT(LAB_GRP_TYPE,1)+@EXMPT_FL,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						WHERE 	(EMPL_ID = @EMPL_ID) AND
							(EFFECT_DT >= @EFFECT_DT)

						SET @SQLServer_error_code = @@ERROR
						IF @SQLServer_error_code <> 0
						BEGIN
						    SET @error_type = 5
						    GOTO BL_ERROR_HANDLER
						END
						 
					END
-- CR2350_End KM
	
					-- if only status change
					ELSE IF (@REASON_DESC IS NOT NULL AND (@S_EMPL_TYPE_CD = NULL))
					BEGIN
						UPDATE IMAR.DELTEK.EMPL_LAB_INFO
						SET 	REASON_DESC = @REASON_DESC,
							LAB_GRP_TYPE = @LAB_GRP_TYPE,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						WHERE 	(EMPL_ID = @EMPL_ID) AND
							(EFFECT_DT >= @EFFECT_DT)

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 5
                                                       GOTO BL_ERROR_HANDLER
                                                   END
					END
				END -- end update/retro






				/*
				3b.  AND A RECORD WITH THAT EFFECTIVE DATE DOES NOT EXIST EXISTS, WE HAVE THE MOST COMPLICATED CHANGE
				*/
				-- if record does not exist, insert it
				-- careful when inserting!!! 
				-- watch effect_dt/end_dts
				-- of front and back records
				-- and do retro rollforward/ts if required
				ELSE IF (@rows = 0)
				BEGIN
					DECLARE @FRONT_EFFECT_DT datetime,
						@BACK_EFFECT_DT datetime
					
					SELECT 	@FRONT_EFFECT_DT = MIN(EFFECT_DT)
					FROM 	IMAR.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND	EFFECT_DT > @EFFECT_DT
	
					SELECT 	@BACK_EFFECT_DT = MAX(EFFECT_DT)
					FROM	IMAR.DELTEK.EMPL_LAB_INFO
					WHERE	EMPL_ID = @EMPL_ID
					AND 	EFFECT_DT < @EFFECT_DT

					--if back record exists, update its end date
					IF @BACK_EFFECT_DT IS NOT NULL
					BEGIN
						UPDATE 	IMAR.DELTEK.EMPL_LAB_INFO
						SET 	END_DT = (@EFFECT_DT - 1),
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						WHERE 	EMPL_ID = @EMPL_ID
						AND	EFFECT_DT = @BACK_EFFECT_DT
					END
					ELSE IF @BACK_EFFECT_DT IS NULL
					BEGIN
						SET @BACK_EFFECT_DT = @FRONT_EFFECT_DT
					END
					
					-- if job family, band, work sched change
					IF (@GENL_LAB_CAT_CD IS NOT NULL)
					BEGIN
						--EFFECTIVE DATE CHANGES
						--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
						SET @CUR_GENL_LAB_CAT_CD = NULL
						SET @PREV_GENL_LAB_CAT_CD = NULL	
						SET @PREV_END_DT = NULL	
						
						SELECT  @CUR_GENL_LAB_CAT_CD = GENL_LAB_CAT_CD
						FROM    IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID
						AND	EFFECT_DT = @LAST_EFFECT_DT
							
						--EFFECTIVE DATE CHANGES
						--IF CURRENT GLC IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
						--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
						IF @CUR_GENL_LAB_CAT_CD = @GENL_LAB_CAT_CD
						BEGIN
							SELECT 	@PREV_GENL_LAB_CAT_CD = GENL_LAB_CAT_CD,
								@PREV_END_DT = END_DT
							FROM 	IMAR.DELTEK.EMPL_LAB_INFO
							WHERE 	EMPL_ID = @EMPL_ID	
							AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND GENL_LAB_CAT_CD <> @GENL_LAB_CAT_CD)
						
							--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
							IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
							BEGIN
								
								--ROLL OLD GLC FORWARD
								UPDATE IMAR.DELTEK.EMPL_LAB_INFO
								SET GENL_LAB_CAT_CD = 	@PREV_GENL_LAB_CAT_CD, 
									ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
								WHERE 	EMPL_ID = @EMPL_ID
								AND	EFFECT_DT > @PREV_END_DT
								AND	EFFECT_DT < @EFFECT_DT
							
								/*
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, NULL, @PREV_GENL_LAB_CAT_CD, @PREV_END_DT+1, @EFFECT_DT-1
								*/					
	
								SET @SQLServer_error_code = @@ERROR
			                                        IF @SQLServer_error_code <> 0
			                                           BEGIN
			                                               SET @error_type = 7
			                                               GOTO BL_ERROR_HANDLER
			                                           END
							END
-- DR2672_Begin
							ELSE IF @FRONT_EFFECT_DT IS NOT NULL
							BEGIN

								/*
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, NULL, @GENL_LAB_CAT_CD, @EFFECT_DT, @FRONT_EFFECT_DT
								*/
						
								SET @SQLServer_error_code = @@ERROR
			                                        IF @SQLServer_error_code <> 0
			                                           BEGIN
			                                               SET @error_type = 7
			                                               GOTO BL_ERROR_HANDLER
			                                           END
							END
-- DR2672_End
						END
						ELSE
						BEGIN	
							/*	
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, NULL, @GENL_LAB_CAT_CD, @EFFECT_DT, GETDATE()
							*/					

							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END

						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'JOB FAMILY/BAND/WORK SCHED CHANGE'
	
						INSERT INTO IMAR.DELTEK.EMPL_LAB_INFO
						(EMPL_ID, EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
						 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
						 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
						 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
  						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, ROWVERSION)
	
						SELECT
						 @EMPL_ID, @EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
						 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
						 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
						 STD_EFFECT_AMT, LAB_GRP_TYPE, @GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, 
						 REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, (@FRONT_EFFECT_DT - 1), SEC_ORG_ID, COMMENTS,
  						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
						FROM IMAR.DELTEK.EMPL_LAB_INFO
						WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @BACK_EFFECT_DT) --BACK_EFFECT_DT change KM 01/02/07

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                      SET @error_type = 6
                                                       GOTO BL_ERROR_HANDLER
                                                   END

						UPDATE IMAR.DELTEK.EMPL_LAB_INFO
						SET 	GENL_LAB_CAT_CD = @GENL_LAB_CAT_CD,
								ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						WHERE 	(EMPL_ID = @EMPL_ID) AND
							(EFFECT_DT > @EFFECT_DT)

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 5
                                                       GOTO BL_ERROR_HANDLER
                                                   END
					END
	
					-- if position change
					ELSE IF (@TITLE_DESC IS NOT NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'POSITION CHANGE'
						INSERT INTO IMAR.DELTEK.EMPL_LAB_INFO
						(EMPL_ID, EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
						 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
						 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
						 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
  						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, ROWVERSION)
	
						SELECT
						 @EMPL_ID, @EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
						 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
						 ORG_ID, @TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
						 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, (@FRONT_EFFECT_DT - 1), SEC_ORG_ID, COMMENTS,
  						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
						FROM IMAR.DELTEK.EMPL_LAB_INFO
						WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @BACK_EFFECT_DT) --BACK_EFFECT_DT change KM 01/02/07

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 6
                                                       GOTO BL_ERROR_HANDLER
                                                   END	

						UPDATE IMAR.DELTEK.EMPL_LAB_INFO
						SET 	TITLE_DESC = @TITLE_DESC,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						WHERE 	(EMPL_ID = @EMPL_ID) AND
							(EFFECT_DT > @EFFECT_DT)

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 5
                                                       GOTO BL_ERROR_HANDLER
                                                   END
					END
	
					-- if department change
					ELSE IF (@ORG_ID IS NOT NULL)
					BEGIN
						--EFFECTIVE DATE CHANGES
						--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
						SET @CUR_ORG_ID = NULL
						SET @PREV_ORG_ID = NULL	
						SET @PREV_END_DT = NULL	
						
						SELECT  @CUR_ORG_ID = ORG_ID
						FROM    IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID
						AND	EFFECT_DT = @LAST_EFFECT_DT
						
						--EFFECTIVE DATE CHANGES
						--IF CURRENT ORG IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
						--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
						IF @CUR_ORG_ID = @ORG_ID
						BEGIN
							SELECT 	@PREV_ORG_ID = ORG_ID, 
								@PREV_LAB_GRP_TYPE = LAB_GRP_TYPE,
								@PREV_SEC_ORG_ID = SEC_ORG_ID,
								@PREV_END_DT = END_DT
							FROM 	IMAR.DELTEK.EMPL_LAB_INFO
							WHERE 	EMPL_ID = @EMPL_ID	
							AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND ORG_ID <> @ORG_ID)
						
							--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
							IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
							BEGIN
								
								--ROLL OLD ORG_ID FORWARD
								UPDATE IMAR.DELTEK.EMPL_LAB_INFO
								SET
								ORG_ID = @PREV_ORG_ID, 
								--LAB_GRP_TYPE = LEFT(@PREV_LAB_GRP_TYPE,1)+EMPL_CLASS_CD,
								SEC_ORG_ID = @PREV_SEC_ORG_ID,
								ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
								WHERE 	EMPL_ID = @EMPL_ID
								AND	EFFECT_DT > @PREV_END_DT
								AND	EFFECT_DT < @EFFECT_DT

								--KM CR2350 - uncommented
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_ORG_ID, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @PREV_ORG_ID, @PREV_END_DT+1, @EFFECT_DT-1
								
								SET @SQLServer_error_code = @@ERROR
			                                        IF @SQLServer_error_code <> 0
			                                           BEGIN
			                                               SET @error_type = 7
			                                               GOTO BL_ERROR_HANDLER
			                                           END
							END
-- DR2672_Begin
							ELSE IF @FRONT_EFFECT_DT IS NOT NULL
							BEGIN
								--KM CR2350 - uncommented
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_ORG_ID, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @ORG_ID, @EFFECT_DT, @FRONT_EFFECT_DT
								
								SET @SQLServer_error_code = @@ERROR
			                                        IF @SQLServer_error_code <> 0
			                                           BEGIN
			                                               SET @error_type = 7
			                                               GOTO BL_ERROR_HANDLER
			                                           END
							END
-- DR2672_End
						END
						ELSE
						BEGIN
							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @ORG_ID, @EFFECT_DT, GETDATE()
							
							SET @SQLServer_error_code = @@ERROR
		                                        IF @SQLServer_error_code <> 0
		                                           BEGIN
		                                               SET @error_type = 7
		                                               GOTO BL_ERROR_HANDLER
		                                           END
						END
						
						--PROCESS ORG CHANGE
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'DEPARTMENT CHANGE'
						INSERT INTO IMAR.DELTEK.EMPL_LAB_INFO
						(EMPL_ID, EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
						 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
						 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
						 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
  						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, ROWVERSION) --BACK_EFFECT_DT change KM 01/02/07
	
						SELECT
						 @EMPL_ID, @EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
						 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
						 @ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
						 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, (@FRONT_EFFECT_DT - 1), @SEC_ORG_ID, COMMENTS,
  						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
						FROM IMAR.DELTEK.EMPL_LAB_INFO
						WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @BACK_EFFECT_DT) --BACK_EFFECT_DT change KM 01/02/07

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 6
                                                       GOTO BL_ERROR_HANDLER
                                                   END	

						UPDATE IMAR.DELTEK.EMPL_LAB_INFO
						SET 	ORG_ID = @ORG_ID,
							--LAB_GRP_TYPE = LEFT(@LAB_GRP_TYPE,1)+EMPL_CLASS_CD,
							SEC_ORG_ID = @SEC_ORG_ID,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						WHERE 	(EMPL_ID = @EMPL_ID) AND
							(EFFECT_DT > @EFFECT_DT)

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 5
                                                       GOTO BL_ERROR_HANDLER
                                                   END
					END
	




--begin EMPL_CLASS_CD & SALARY
					-- if EMPL_CLASS_CD change
					ELSE IF (@EMPL_CLASS_CD IS NOT NULL)
					BEGIN
						--EFFECTIVE DATE CHANGES
						--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
						SET @CUR_EMPL_CLASS_CD = NULL
						SET @PREV_EMPL_CLASS_CD = NULL	
						SET @PREV_END_DT = NULL	
						
						SELECT  @CUR_EMPL_CLASS_CD = EMPL_CLASS_CD
						FROM    IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID
						AND	EFFECT_DT = @LAST_EFFECT_DT
						
						--EFFECTIVE DATE CHANGES
						--IF CURRENT EMPL_CLASS_CD IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
						--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
						IF @CUR_EMPL_CLASS_CD = @EMPL_CLASS_CD
						BEGIN
							SELECT 	@PREV_EMPL_CLASS_CD = EMPL_CLASS_CD,
								@PREV_LAB_GRP_TYPE = LAB_GRP_TYPE, 
								@PREV_END_DT = END_DT
							FROM 	IMAR.DELTEK.EMPL_LAB_INFO
							WHERE 	EMPL_ID = @EMPL_ID	
							AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND EMPL_CLASS_CD <> @EMPL_CLASS_CD)
													
							--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
							IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
							BEGIN
								
								--ROLL OLD EMPL_CLASS_CD FORWARD
								UPDATE IMAR.DELTEK.EMPL_LAB_INFO
								SET
								EMPL_CLASS_CD = @PREV_EMPL_CLASS_CD, 
								--LAB_GRP_TYPE = LEFT(LAB_GRP_TYPE, 1) + @PREV_EMPL_CLASS_CD,
								ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
								WHERE 	EMPL_ID = @EMPL_ID
								AND	EFFECT_DT > @PREV_END_DT
								AND	EFFECT_DT < @EFFECT_DT

								--KM CR2350 - uncommented
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_EMPL_CLASS_CD, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @PREV_EMPL_CLASS_CD, @PREV_END_DT+1, @EFFECT_DT-1
								
								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								BEGIN
								    SET @error_type = 7
								    GOTO BL_ERROR_HANDLER
								END
							END
-- DR2672_Begin
							ELSE IF @FRONT_EFFECT_DT IS NOT NULL
							BEGIN
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_EMPL_CLASS_CD, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @EMPL_CLASS_CD, @EFFECT_DT, @FRONT_EFFECT_DT
								
								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								BEGIN
								    SET @error_type = 7
								    GOTO BL_ERROR_HANDLER
								END
							END
-- DR2672_End
						END
						ELSE
						BEGIN
							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_EMPL_CLASS_CD, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @EMPL_CLASS_CD, @EFFECT_DT, GETDATE()
							
							SET @SQLServer_error_code = @@ERROR
							IF @SQLServer_error_code <> 0
							BEGIN
							    SET @error_type = 7	                                               
							    GOTO BL_ERROR_HANDLER
							END
						END
						
						--PROCESS EMPL_CLASS_CD CHANGE
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'EMPL_CLASS_CD CHANGE'
						INSERT INTO IMAR.DELTEK.EMPL_LAB_INFO
						(EMPL_ID, EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
						 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
						 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
						 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, ROWVERSION) --BACK_EFFECT_DT change KM 01/02/07
	
						SELECT
						 @EMPL_ID, @EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
						 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
						 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
						 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, (@FRONT_EFFECT_DT - 1), SEC_ORG_ID, COMMENTS,
						 @EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
						FROM IMAR.DELTEK.EMPL_LAB_INFO
						WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @BACK_EFFECT_DT) --BACK_EFFECT_DT change KM 01/02/07

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 6
                                                       GOTO BL_ERROR_HANDLER
                                                   END	

						UPDATE IMAR.DELTEK.EMPL_LAB_INFO
						SET 	EMPL_CLASS_CD = @EMPL_CLASS_CD,
							--LAB_GRP_TYPE = LEFT(LAB_GRP_TYPE,1)+@EMPL_CLASS_CD,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						WHERE 	(EMPL_ID = @EMPL_ID) AND
							(EFFECT_DT > @EFFECT_DT)

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                 BEGIN
                                                       SET @error_type = 5
                                                       GOTO BL_ERROR_HANDLER
                                                   END
						 
					END

					-- if SALARY - HRLY_AMT change
					ELSE IF (@HRLY_AMT IS NOT NULL)
					BEGIN
						--EFFECTIVE DATE CHANGES
						--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
						SET @CUR_HRLY_AMT = NULL
						SET @CUR_WORK_YR_HRS_NO = NULL
						SET @PREV_HRLY_AMT = NULL
						SET @PREV_SAL_AMT = NULL
						SET @PREV_ANNL_AMT = NULL
						SET @PREV_WORK_YR_HRS_NO = NULL						
						 --KM 2011-09-19 SET @PREV_S_HRLY_SAL_CD = NULL
						SET @PREV_STD_EST_HRS = NULL	
						SET @PREV_END_DT = NULL
						
-- CR2350_Begin KM
						SELECT  @CUR_HRLY_AMT = HRLY_AMT,
							@CUR_WORK_YR_HRS_NO = WORK_YR_HRS_NO
						FROM    IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID
						AND	EFFECT_DT = @LAST_EFFECT_DT
						
						--EFFECTIVE DATE CHANGES
						--IF CURRENT HRLY_AMT IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
						--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
						IF (@CUR_HRLY_AMT = @HRLY_AMT AND @CUR_WORK_YR_HRS_NO = @WORK_YR_HRS_NO)
						BEGIN
							SELECT 	@PREV_HRLY_AMT = HRLY_AMT,
								@PREV_SAL_AMT = SAL_AMT,
								@PREV_ANNL_AMT = ANNL_AMT,
								@PREV_WORK_YR_HRS_NO = WORK_YR_HRS_NO,
								 --KM 2011-09-19 @PREV_S_HRLY_SAL_CD = S_HRLY_SAL_CD,
								@PREV_STD_EST_HRS = STD_EST_HRS,	
								@PREV_END_DT = END_DT
							FROM 	IMAR.DELTEK.EMPL_LAB_INFO
							WHERE 	EMPL_ID = @EMPL_ID	
							AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND (HRLY_AMT <> @HRLY_AMT OR WORK_YR_HRS_NO <> @WORK_YR_HRS_NO))
													
							--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
							IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
							BEGIN
								
								--ROLL OLD HRLY_AMT FORWARD
								UPDATE IMAR.DELTEK.EMPL_LAB_INFO
								SET
								HRLY_AMT = @PREV_HRLY_AMT, 
								SAL_AMT = @PREV_SAL_AMT,
								ANNL_AMT = @PREV_ANNL_AMT,
								WORK_YR_HRS_NO = @PREV_WORK_YR_HRS_NO,
								 --KM 2011-09-19 S_HRLY_SAL_CD = @PREV_S_HRLY_SAL_CD,
								STD_EST_HRS = @PREV_STD_EST_HRS,	
								--END_DT = @PREV_END_DT,
								ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
								WHERE 	EMPL_ID = @EMPL_ID
								AND	EFFECT_DT > @PREV_END_DT
								AND	EFFECT_DT < @EFFECT_DT
-- CR2350_End KM
							
								--KM salary date
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @PREV_HRLY_AMT, @PREV_END_DT+1, @EFFECT_DT-1
								
						
								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								BEGIN
								    SET @error_type = 7
								    GOTO BL_ERROR_HANDLER
								END
							END
-- DR2672_Begin
							ELSE IF @FRONT_EFFECT_DT IS NOT NULL
							BEGIN
								--KM salary date
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @HRLY_AMT, @EFFECT_DT, @FRONT_EFFECT_DT
								

								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								BEGIN
								    SET @error_type = 7
								    GOTO BL_ERROR_HANDLER
								END
							END
-- DR2672_End
						END
						ELSE
						BEGIN
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @HRLY_AMT, @EFFECT_DT, GETDATE()
					
							SET @SQLServer_error_code = @@ERROR
							IF @SQLServer_error_code <> 0
							BEGIN
							    SET @error_type = 7	                                               
							    GOTO BL_ERROR_HANDLER
							END
						END
						
						
						--PROCESS HRLY_AMT CHANGE
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'SALARY CHANGE'
						INSERT INTO IMAR.DELTEK.EMPL_LAB_INFO
						(EMPL_ID, EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
						 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
						 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
						 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
  						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, ROWVERSION) --BACK_EFFECT_DT change KM 01/02/07
	
						SELECT
						 @EMPL_ID, @EFFECT_DT, S_HRLY_SAL_CD, @HRLY_AMT,  --KM 2011-09-19
						 @SAL_AMT, @ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
						 ORG_ID, TITLE_DESC, WORK_STATE_CD, @STD_EST_HRS,
						 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, (@FRONT_EFFECT_DT - 1), SEC_ORG_ID, COMMENTS,
  						 EMPL_CLASS_CD, @WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
						FROM IMAR.DELTEK.EMPL_LAB_INFO
						WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @BACK_EFFECT_DT) --BACK_EFFECT_DT change KM 01/02/07

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 6
                                                       GOTO BL_ERROR_HANDLER
                                                   END	

						UPDATE IMAR.DELTEK.EMPL_LAB_INFO
						SET 	HRLY_AMT = @HRLY_AMT,
							SAL_AMT = @SAL_AMT,
							ANNL_AMT = @ANNL_AMT,
							WORK_YR_HRS_NO = @WORK_YR_HRS_NO,
							 --KM 2011-09-19 S_HRLY_SAL_CD = @S_HRLY_SAL_CD,
							STD_EST_HRS = @STD_EST_HRS,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						WHERE 	(EMPL_ID = @EMPL_ID) AND
							(EFFECT_DT > @EFFECT_DT)

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 5
                                                       GOTO BL_ERROR_HANDLER
                                                   END


					END
--end EMPL_CLASS_CD & SALARY


					-- else if status3 change
					ELSE IF (@S_EMPL_TYPE_CD IS NOT NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'STATUS3 CHANGE'
						INSERT INTO IMAR.DELTEK.EMPL_LAB_INFO
						(EMPL_ID, EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
						 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
						 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
						 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
  						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, ROWVERSION)
	
						SELECT
						 @EMPL_ID, @EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
						 SAL_AMT, ANNL_AMT, EXMPT_FL, @S_EMPL_TYPE_CD,
						 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
						 STD_EFFECT_AMT,
						 @LAB_GRP_TYPE, -- CP600000586
						 GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, @REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, (@FRONT_EFFECT_DT - 1), SEC_ORG_ID, COMMENTS,
  						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
						FROM IMAR.DELTEK.EMPL_LAB_INFO
						WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @BACK_EFFECT_DT) --BACK_EFFECT_DT change KM 01/02/07

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 6
                                                       GOTO BL_ERROR_HANDLER
                                                   END

						UPDATE IMAR.DELTEK.EMPL_LAB_INFO
						   SET REASON_DESC = @REASON_DESC,
						       S_EMPL_TYPE_CD = @S_EMPL_TYPE_CD,
-- DR4925_begin
						       LAB_GRP_TYPE = @LAB_GRP_TYPE, -- CP600000586
-- DR4925_end
						       ROWVERSION = ROWVERSION + 1, TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						 WHERE (EMPL_ID = @EMPL_ID)
						   AND (EFFECT_DT > @EFFECT_DT)

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 5
                                                       GOTO BL_ERROR_HANDLER
                                                   END
					END
	


-- CR2350_Begin KM
					-- if EXMPT_FL change
					ELSE IF (@EXMPT_FL IS NOT NULL)
					BEGIN
						--EFFECTIVE DATE CHANGES
						--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
						SET @CUR_EXMPT_FL = NULL
						SET @PREV_EXMPT_FL = NULL	
						SET @PREV_END_DT = NULL	
						
						SELECT  @CUR_EXMPT_FL = EXMPT_FL
						FROM    IMAR.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID
						AND	EFFECT_DT = @LAST_EFFECT_DT
						
						--EFFECTIVE DATE CHANGES
						--IF CURRENT EXMPT_FL IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
						--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
						IF @CUR_EXMPT_FL = @EXMPT_FL
						BEGIN
							SELECT 	@PREV_EXMPT_FL = EXMPT_FL,
								@PREV_S_HRLY_SAL_CD = S_HRLY_SAL_CD,  --KM 2011-09-19
								@PREV_LAB_GRP_TYPE = LAB_GRP_TYPE, 
								@PREV_END_DT = END_DT
							FROM 	IMAR.DELTEK.EMPL_LAB_INFO
							WHERE 	EMPL_ID = @EMPL_ID	
							AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND EXMPT_FL <> @EXMPT_FL)
													
							--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
							IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1
							BEGIN
								
								--ROLL OLD EXMPT_FL FORWARD
								UPDATE IMAR.DELTEK.EMPL_LAB_INFO
								SET
								EXMPT_FL = @PREV_EXMPT_FL, 
								S_HRLY_SAL_CD = @PREV_S_HRLY_SAL_CD,  --KM 2011-09-19
								--LAB_GRP_TYPE = LEFT(LAB_GRP_TYPE, 1) + @PREV_EXMPT_FL,
								ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
								WHERE 	EMPL_ID = @EMPL_ID
								AND	EFFECT_DT > @PREV_END_DT
								AND	EFFECT_DT < @EFFECT_DT
							
								--KM CR2350 - uncommented
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @PREV_EXMPT_FL, @PREV_END_DT+1, @EFFECT_DT-1
								
								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								BEGIN
								    SET @error_type = 7
								    GOTO BL_ERROR_HANDLER
								END
							END
-- DR2672_Begin
							ELSE IF @FRONT_EFFECT_DT IS NOT NULL
							BEGIN
								--KM CR2350 - uncommented
								--TRACK RETRO TIMESHEET DATA - SALARY ONLY
								INSERT INTO XX_R22_CERIS_RETRO_TS
								(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @EXMPT_FL, @EFFECT_DT, @FRONT_EFFECT_DT
								
								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								BEGIN
								    SET @error_type = 7
								    GOTO BL_ERROR_HANDLER
								END
							END
-- DR2672_End
						END
						ELSE
						BEGIN
							--KM CR2350 - uncommented
							--TRACK RETRO TIMESHEET DATA - SALARY ONLY
							INSERT INTO XX_R22_CERIS_RETRO_TS
							(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @EXMPT_FL, @EFFECT_DT, GETDATE()
							
							SET @SQLServer_error_code = @@ERROR
							IF @SQLServer_error_code <> 0
							BEGIN
							    SET @error_type = 7	                                               
							    GOTO BL_ERROR_HANDLER
							END
						END
						
						--PROCESS EXMPT_FL CHANGE
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'EXEMPT CHANGE'
						INSERT INTO IMAR.DELTEK.EMPL_LAB_INFO
						(EMPL_ID, EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
						 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
						 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
						 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
  						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, ROWVERSION)
	
						SELECT
						 @EMPL_ID, @EFFECT_DT, @S_HRLY_SAL_CD, HRLY_AMT,   --KM 2011-09-19
						 SAL_AMT, ANNL_AMT, @EXMPT_FL, S_EMPL_TYPE_CD,
						 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
						 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, (@FRONT_EFFECT_DT - 1), SEC_ORG_ID, COMMENTS,
  						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
						FROM IMAR.DELTEK.EMPL_LAB_INFO
						WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @BACK_EFFECT_DT) --BACK_EFFECT_DT change KM 01/02/07

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 6
                                                       GOTO BL_ERROR_HANDLER
                                                   END

						UPDATE IMAR.DELTEK.EMPL_LAB_INFO
						SET	EXMPT_FL = @EXMPT_FL,
							S_HRLY_SAL_CD = @S_HRLY_SAL_CD,  --KM 2011-09-19
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						WHERE 	(EMPL_ID = @EMPL_ID) AND
							(EFFECT_DT > @EFFECT_DT)

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 5
                                                       GOTO BL_ERROR_HANDLER
                                                   END
						 
					END
-- CR2350_End KM

	
					-- if only status change
					ELSE IF (@REASON_DESC IS NOT NULL AND (@S_EMPL_TYPE_CD = NULL))
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'STATUS CHANGE'
						INSERT INTO IMAR.DELTEK.EMPL_LAB_INFO
						(EMPL_ID, EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
						 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
						 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
						 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
  						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, ROWVERSION)
	
						SELECT
						 @EMPL_ID, @EFFECT_DT, S_HRLY_SAL_CD, HRLY_AMT,
						 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
						 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
						 STD_EFFECT_AMT, @LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, @REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, (@FRONT_EFFECT_DT - 1), SEC_ORG_ID, COMMENTS,
  						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
						FROM IMAR.DELTEK.EMPL_LAB_INFO						
						WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @BACK_EFFECT_DT) --BACK_EFFECT_DT change KM 01/02/07
                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 6
                                                       GOTO BL_ERROR_HANDLER
                                                   END

						UPDATE IMAR.DELTEK.EMPL_LAB_INFO
						SET 	REASON_DESC = @REASON_DESC,
								LAB_GRP_TYPE = @LAB_GRP_TYPE,
							ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						WHERE 	(EMPL_ID = @EMPL_ID) AND
							(EFFECT_DT > @EFFECT_DT)

                                                SET @SQLServer_error_code = @@ERROR
                                                IF @SQLServer_error_code <> 0
                                                   BEGIN
                                                       SET @error_type = 5
                                                       GOTO BL_ERROR_HANDLER
                                                   END
					END

				END -- end insert and update retro
			END -- end if retros

			-- loop
			FETCH NEXT FROM EMPL_LAB_CURSOR
			INTO 	@EFFECT_DT, 
				@HRLY_AMT, @SAL_AMT, @ANNL_AMT,
				@EXMPT_FL, @S_EMPL_TYPE_CD, @ORG_ID, @SEC_ORG_ID,
				@TITLE_DESC, @LAB_GRP_TYPE, @GENL_LAB_CAT_CD,
				@REASON_DESC, @WORK_YR_HRS_NO,
  				@EMPL_CLASS_CD,
				@S_HRLY_SAL_CD,
				@STD_EST_HRS	
		END -- end loop change
		
		-- clean up empl_lab_cursor
		CLOSE EMPL_LAB_CURSOR
		DEALLOCATE EMPL_LAB_CURSOR

		-- loop
		FETCH NEXT FROM EMPL_ID_CURSOR
		INTO @EMPL_ID
			
	END -- end loop empl_id
	
	--clean up empl_id_sursor
	CLOSE EMPL_ID_CURSOR
	DEALLOCATE EMPL_ID_CURSOR
	
END -- end empl_lab_info updates/inserts







-- DFLT_TS_REG table updates/inserts
UPDATE 	IMAR.DELTEK.DFLT_REG_TS
SET 	GENL_LAB_CAT_CD = empl_lab.GENL_LAB_CAT_CD,
     	CHG_ORG_ID = empl_lab.ORG_ID,
	ROWVERSION = dflt_reg.ROWVERSION+1
FROM 	IMAR.DELTEK.DFLT_REG_TS as dflt_reg
INNER JOIN 
	IMAR.DELTEK.EMPL_LAB_INFO AS empl_lab
ON 	(
	dflt_reg.EMPL_ID = empl_lab.EMPL_ID
AND	empl_lab.EFFECT_DT <= GETDATE()
AND	empl_lab.END_DT >= GETDATE()
AND	(empl_lab.GENL_LAB_CAT_CD <> dflt_reg.GENL_LAB_CAT_CD
	OR empl_lab.ORG_ID <> dflt_reg.CHG_ORG_ID)
)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
 BEGIN
    SET @error_type = 8
    GOTO BL_ERROR_HANDLER
 END




/*
IS THIS A DIV22 REQUIREMENT?  NOT THAT I KNOW OF
--BEGIN CHANGE DR-922 04/27/07
DECLARE @ret_code int

EXEC @ret_code = XX_R22_RETRORATE_ADD_NEW_REC_SP
			@in_effect_dt = null,
			@out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
			@out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION OUTPUT			

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 Or @ret_code <> 0
 BEGIN
    PRINT @out_STATUS_DESCRIPTION
    SET @error_type = 11
    GOTO BL_ERROR_HANDLER
 END
--END CHANGE DR-922 04/27/07

*/



RETURN(0)

BL_ERROR_HANDLER:


SET @IMAPS_error_code = 204 -- Attempt to %1 %2 failed.

IF @error_type = 1
   BEGIN
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_R22_CERIS_CP_EMPL_STG'
   END
ELSE IF @error_type = 2
   BEGIN
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_R22_CERIS_CP_EMPL_LAB_STG'
   END
ELSE IF @error_type = 3
   BEGIN
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_R22_CERIS_CP_DFLT_TS_STG'
   END
ELSE IF @error_type = 4
   BEGIN
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'records in table IMAR.DELTEK.EMPL'
   END
ELSE IF @error_type = 5
   BEGIN
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'records in table IMAR.DELTEK.EMPL_LAB_INFO'
   END
ELSE IF @error_type = 6
   BEGIN
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records in table IMAR.DELTEK.EMPL_LAB_INFO'
   END
ELSE IF @error_type = 7
   BEGIN
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records in table XX_R22_CERIS_RETRO_TS'
   END
ELSE IF @error_type = 8
   BEGIN
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'records in table IMAR.DELTEK.DFLT_REG_TS'
   END
ELSE IF @error_type = 9
   BEGIN
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'prior year records in table IMAR.DELTEK.EMPL_LAB_INFO'
   END
ELSE IF @error_type = 10
   BEGIN
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'current year records in table IMAR.DELTEK.EMPL_LAB_INFO'
   END
--BEGIN CHANGE DR-922 04/27/07
ELSE IF @error_type = 11
   BEGIN
      SET @error_msg_placeholder1 = 'call'
      SET @error_msg_placeholder2 = 'XX_R22_RETRORATE_ADD_NEW_REC_SP'
   END
--END CHANGE DR-922 04/27/07

IF @error_type in (5, 6, 7)
   BEGIN
      -- clean up
      CLOSE EMPL_LAB_CURSOR
      DEALLOCATE EMPL_LAB_CURSOR

      CLOSE EMPL_ID_CURSOR
      DEALLOCATE EMPL_ID_CURSOR
   END

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_code,
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
IF OBJECT_ID('dbo.XX_R22_CERIS_UPDATE_CP_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_CERIS_UPDATE_CP_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_CERIS_UPDATE_CP_SP >>>'
go

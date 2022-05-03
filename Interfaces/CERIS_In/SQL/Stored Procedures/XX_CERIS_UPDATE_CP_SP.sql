
use imapsstg

/****** Object:  Stored Procedure dbo.XX_CERIS_UPDATE_CP_SP    Script Date: 04/27/2007 11:57:53 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_UPDATE_CP_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_CERIS_UPDATE_CP_SP]
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO


CREATE PROCEDURE dbo.XX_CERIS_UPDATE_CP_SP
(
@in_STATUS_RECORD_NUM     integer,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS

/************************************************************************************************  
Name:       	XX_CERIS_UPDATE_CP_SP
Author:     	KM
Created:    	10/2005  
Purpose:    	UPDATES the data in costpoint empl tables.
                Called by XX_CERIS_RUN_INTERFACE_SP.
Notes:

03/21/2007: KM EFFECTIVE DATE CHANGES

TRUNCATE TABLE XX_CERIS_CP_EMPL_LAB_STG

CP600000284 04/15/2008 (BP&S Change Request No. CR1543)
            Apply the Costpoint column COMPANY_ID to distinguish Division 16's data from those
            of Division 22's. There are six instances.

DR2672

1M changes

CR4885 - IMAPS CERIS Interface Changes for Actuals - KM - 2012-05-25
CR5782 - modify CERIS interface to accomodate late LCDB GLC assignments - KM - 2013-01-15
CR6326 - T2R - KM - 2013-05-06
CR7366 - T2R 2014 - KM - 2014-07-15
************************************************************************************************/  

BEGIN

-- ANSI NULLS MUST BE OFF


DECLARE @ERROR_DESC varchar(60),
	@EMPL_ID varchar(12)

DECLARE @S_EMPL_TYPE_CD char(1),
	@LAB_GRP_TYPE varchar(3),
	@ADJ_PAY_FREQ decimal(10, 8)
	
DECLARE --@EMPL_ID varchar(12),
	@DIV_START_DT smalldatetime,
	@LAST_EFFECT_DT smalldatetime,
	@PREV_SEC_ORG_ID varchar(20),
	@PREV_ORG_ID varchar(20),
	@PREV_LAB_GRP_TYPE varchar(3),
	@PREV_GENL_LAB_CAT_CD varchar(6),
	@CUR_ORG_ID varchar(20),
	@CUR_GENL_LAB_CAT_CD varchar(6),
	@PREV_END_DT smalldatetime,
	@PREV_HRLY_AMT decimal(10, 4),
	@PREV_SAL_AMT decimal(10, 2),
	@PREV_ANNL_AMT decimal(10, 2),
	@PREV_PCT_INCR_RT decimal(5,4),
	@CUR_HRLY_AMT decimal(10, 4),
	@CUR_SAL_AMT decimal(10, 2),
	@CUR_ANNL_AMT decimal(10, 2),
	@CUR_PCT_INCR_RT decimal(5,4),		
	@EFFECT_DT smalldatetime,
	@HRLY_AMT decimal(10, 4),
	@SAL_AMT decimal(10, 2),
	@ANNL_AMT decimal(10, 2),
	@EXMPT_FL char(1),
	@PREV_EXMPT_FL char(1),
	@CUR_EXMPT_FL char(1),
	--@S_EMPL_TYPE_CD char(1),
 	@ORG_ID	varchar(20),
	@SEC_ORG_ID varchar(20),
	@TITLE_DESC varchar(30),
	--@LAB_GRP_TYPE varchar(3),
	@GENL_LAB_CAT_CD varchar(6),
	@REASON_DESC varchar(30),
	@WORK_YR_HRS_NO smallint,
	@PREV_WORK_YR_HRS_NO smallint,
	@CUR_WORK_YR_HRS_NO smallint,
	@S_HRLY_SAL_CD	char(1),
	@PREV_S_HRLY_SAL_CD	char(1), 
	@CUR_S_HRLY_SAL_CD	char(1), 
	@WORK_STATE_CD	varchar(2),
	@STD_EST_HRS	decimal(14,2),
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
	@PERS_ACT_RSN_CD_2	varchar(10),
	@PERS_ACT_RSN_CD_3	varchar(10),
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
        @DIV_16_COMPANY_ID       varchar(10),
        @error_type              integer,
        @IMAPS_error_code        integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname


-- set local constants
SET @SP_NAME = 'XX_CERIS_UPDATE_CP_SP'

-- CP600000284_Begin

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 144 : XX_CERIS_UPDATE_CP_SP.sql '
 
SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'CERIS'

-- CP600000284_End

PRINT 'Process Stage CERIS4 - Perform direct UPDATEs against Costpoint tables ...'

-- BEGIN PREPROCESSING Employee records that need updating

-- We know these CERIS records require insertion/update to 
-- Costpoint tables, but we don't yet know what kind of insertion/update
-- We don't know what the actual changes are yet.
-- We will first assume all of the data has changed

/* 
 * Tables XX_CERIS_CP_EMPL_STG, XX_CERIS_CP_EMPL_LAB_STG, XX_CERIS_CP_DFLT_TS_STG and XX_CERIS_RETRO_TS
 * are truncated in XX_CERIS_RETRIEVE_SOURCE_DATA_SP for each interface run.
 */

-- Staging table for Costpoint table EMPL

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 170 : XX_CERIS_UPDATE_CP_SP.sql '
 
INSERT INTO dbo.XX_CERIS_CP_EMPL_STG
   (EMPL_ID, ORIG_HIRE_DT, ADJ_HIRE_DT, SPVSR_NAME, 
    LAST_NAME, FIRST_NAME,
    LAST_FIRST_NAME,
    MID_NAME, EMAIL_ID)
   SELECT DISTINCT EMPL_ID, ORIG_HIRE_DT, ADJ_HIRE_DT, SPVSR_NAME,
	  LAST_NAME, FIRST_NAME,
          CAST((LAST_NAME + ',' + FIRST_NAME) AS varchar(25)),
          MID_NAME, EMAIL_ID
     FROM dbo.XX_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)

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

/*
begin CR4885
The mappings to EMPL_LAB_INFO changed.


-- capture Job Family effective date
--SET @REASON_DESC = 'JOB FAMILY CHANGE'
INSERT INTO dbo.XX_CERIS_CP_EMPL_LAB_STG (EMPL_ID, EFFECT_DT, GENL_LAB_CAT_CD, HRLY_AMT, SAL_AMT, ANNL_AMT, WORK_YR_HRS_NO)
  SELECT DISTINCT EMPL_ID, 
    CASE
        WHEN JF_DT >= LVL_DT_1 AND JF_DT >= PAY_DIFFERENTIAL_DT THEN JF_DT
        WHEN LVL_DT_1 >= JF_DT AND LVL_DT_1 >= PAY_DIFFERENTIAL_DT THEN LVL_DT_1
        WHEN PAY_DIFFERENTIAL_DT >= JF_DT AND PAY_DIFFERENTIAL_DT >= LVL_DT_1 THEN PAY_DIFFERENTIAL_DT
        ELSE                                        JF_DT
    END AS EFFECT_DT, 
		
	GENL_LAB_CAT_CD, CAST(HRLY_AMT AS decimal(10, 4)), 
          CAST(SAL_AMT AS decimal(10, 2)), CAST(ANNL_AMT AS decimal(10, 2)),
	  WORK_YR_HRS_NO
     FROM dbo.XX_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END
*/

-- capture LEGACY GLC effective date
--SET @REASON_DESC = 'LEGACY GLC'
INSERT INTO dbo.XX_CERIS_CP_EMPL_LAB_STG (EMPL_ID, EFFECT_DT, REASON_DESC_3)
  SELECT DISTINCT EMPL_ID, 
    CASE
        WHEN JF_DT >= LVL_DT_1 AND JF_DT >= PAY_DIFFERENTIAL_DT THEN JF_DT
        WHEN LVL_DT_1 >= JF_DT AND LVL_DT_1 >= PAY_DIFFERENTIAL_DT THEN LVL_DT_1
        WHEN PAY_DIFFERENTIAL_DT >= JF_DT AND PAY_DIFFERENTIAL_DT >= LVL_DT_1 THEN PAY_DIFFERENTIAL_DT
        ELSE                                        JF_DT
    END AS EFFECT_DT, 
		
	REASON_DESC_3
     FROM dbo.XX_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END


-- capture Position effective date
--SET @REASON_DESC = 'GENL_LAB_CAT_CD'
INSERT INTO dbo.XX_CERIS_CP_EMPL_LAB_STG (EMPL_ID, EFFECT_DT, GENL_LAB_CAT_CD)
   SELECT DISTINCT EMPL_ID, LCDB_GLC_EFFECTIVE_DT, GENL_LAB_CAT_CD
     FROM dbo.XX_CERIS_CP_STG 
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END


-- capture SALARY changes
--SET @REASON_DESC = 'SALARY CHANGE'
INSERT INTO dbo.XX_CERIS_CP_EMPL_LAB_STG (EMPL_ID, EFFECT_DT, HRLY_AMT, SAL_AMT, ANNL_AMT, WORK_YR_HRS_NO)
  SELECT DISTINCT EMPL_ID, 
    CASE
		--whichever changed most recently is what drives the effective date of the change in CP
		-- all these dates are related to elements that drive the salary calculation
        WHEN SALARY_DT >= WORK_SCHD_DT AND SALARY_DT >= EXEMPT_DT THEN SALARY_DT

        WHEN WORK_SCHD_DT > SALARY_DT AND WORK_SCHD_DT >= EXEMPT_DT THEN WORK_SCHD_DT

        WHEN EXEMPT_DT > SALARY_DT AND EXEMPT_DT > WORK_SCHD_DT THEN EXEMPT_DT

        ELSE SALARY_DT
    END AS EFFECT_DT, 		
	CAST(HRLY_AMT AS decimal(10, 4)), CAST(SAL_AMT AS decimal(10, 2)), CAST(ANNL_AMT AS decimal(10, 2)),
	  WORK_YR_HRS_NO
     FROM dbo.XX_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END

-- capture WORK LOCATION changes
--SET @REASON_DESC = 'WORK LOCATION CHANGE'
INSERT INTO dbo.XX_CERIS_CP_EMPL_LAB_STG (EMPL_ID, EFFECT_DT, WORK_STATE_CD)
  SELECT DISTINCT EMPL_ID, 
		WKL_DT AS EFFECT_DT, 		
		WORK_STATE_CD
     FROM dbo.XX_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END



-- capture Position effective date
--SET @REASON_DESC = 'POSITION CHANGE'
INSERT INTO dbo.XX_CERIS_CP_EMPL_LAB_STG (EMPL_ID, EFFECT_DT, TITLE_DESC)
   SELECT DISTINCT EMPL_ID, POS_DT, TITLE_DESC
     FROM dbo.XX_CERIS_CP_STG 
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END

-- capture Division effective date
-- TO DO - figure out how to handle non-division 16 employees

-- capture Department effective date
--SET @REASON_DESC = 'DEPARTMENT CHANGE'
INSERT INTO dbo.XX_CERIS_CP_EMPL_LAB_STG (EMPL_ID, EFFECT_DT, ORG_ID, LAB_GRP_TYPE, SEC_ORG_ID)
   SELECT DISTINCT EMPL_ID, DEPT_ST_DT, ORG_ID, LAB_GRP_TYPE, ORG_ID
     FROM dbo.XX_CERIS_CP_STG 
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END

-- capture Employee Status effective date
--SET @REASON_DESC = 'STATUS CHANGE'
INSERT INTO dbo.XX_CERIS_CP_EMPL_LAB_STG (EMPL_ID, EFFECT_DT, REASON_DESC, S_EMPL_TYPE_CD)
   SELECT DISTINCT EMPL_ID, EMPL_STAT_DT, REASON_DESC, S_EMPL_TYPE_CD
     FROM dbo.XX_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)
      AND EMPL_STAT_DT IS NOT NULL
	  AND EMPL_STAT_DT >= isnull(EMPL_STAT3_DT,EMPL_STAT_DT)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END

-- capture Employee Status3 effective date
--SET @REASON_DESC = 'STATUS3 CHANGE'
INSERT INTO dbo.XX_CERIS_CP_EMPL_LAB_STG (EMPL_ID, EFFECT_DT, REASON_DESC, S_EMPL_TYPE_CD)
   SELECT DISTINCT EMPL_ID, EMPL_STAT3_DT, REASON_DESC, S_EMPL_TYPE_CD
     FROM dbo.XX_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)
      AND EMPL_STAT3_DT IS NOT NULL
	  AND EMPL_STAT3_DT > isnull(EMPL_STAT_DT, EMPL_STAT3_DT)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END

-- capture Exempt effective date
--SET @REASON_DESC = 'EXEMPT CHANGE'
/*CR4885 - new mapping for S_HRLY_SAL_CD*/
INSERT INTO dbo.XX_CERIS_CP_EMPL_LAB_STG (EMPL_ID, EFFECT_DT, EXMPT_FL, S_HRLY_SAL_CD) 
   SELECT DISTINCT EMPL_ID, EXEMPT_DT, EXMPT_FL, S_HRLY_SAL_CD
     FROM dbo.XX_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)
      AND EXEMPT_DT <> NULL

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 2
      GOTO BL_ERROR_HANDLER
   END

-- Staging table for Costpoint table DFLT_REG_TS
INSERT INTO dbo.XX_CERIS_CP_DFLT_TS_STG (EMPL_ID, GENL_LAB_CAT_CD, CHG_ORG_ID)
   SELECT DISTINCT EMPL_ID, GENL_LAB_CAT_CD, ORG_ID
     FROM dbo.XX_CERIS_CP_STG
    WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_type = 3
      GOTO BL_ERROR_HANDLER
   END



-- Delete changes that aren't needed (no change), then cursor through changes
-- check EMPL table changes

-- Delete EMPL changes that aren't needed (no change)
DELETE dbo.XX_CERIS_CP_EMPL_STG
FROM dbo.XX_CERIS_CP_EMPL_STG as a
INNER JOIN IMAPS.DELTEK.EMPL as b
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
(b.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000284_End

-- Delete EMPL_LAB_INFO changes that aren't needed (no change)
DELETE dbo.XX_CERIS_CP_EMPL_LAB_STG
FROM dbo.XX_CERIS_CP_EMPL_LAB_STG as a
INNER JOIN IMAPS.DELTEK.EMPL_LAB_INFO as b
ON
(
	-- job family/band changes that aren't needed (no change)
	(
		(a.EMPL_ID = b.EMPL_ID)  AND
		(a.REASON_DESC_3 is not null) 	AND  --legacy GLC
		(a.REASON_DESC_3 = b.REASON_DESC_3) AND --current value
		(a.REASON_DESC_3 = (SELECT REASON_DESC_3 FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT) ) --effect_dt value
	)
	OR --Salary changes that aren't needed (no change)
	(
		(a.EMPL_ID = b.EMPL_ID) AND
		(a.ANNL_AMT is not null) AND --Salary
		(a.ANNL_AMT = b.ANNL_AMT)AND --current values
		(a.SAL_AMT = b.SAL_AMT)AND
		(a.HRLY_AMT = b.HRLY_AMT)AND
		(a.WORK_YR_HRS_NO = b.WORK_YR_HRS_NO)AND
		(a.ANNL_AMT = (SELECT ANNL_AMT FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT)) AND --effect_dt values
		(a.SAL_AMT = (SELECT SAL_AMT FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT)) AND
		(a.HRLY_AMT = (SELECT HRLY_AMT FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT)) AND
		(a.WORK_YR_HRS_NO = (SELECT WORK_YR_HRS_NO FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT)) AND
		0 =		(	select count(1) 
					from 
					xx_ceris_hist curr
					inner join
					xx_ceris_hist_previous prev
					on
					(curr.empl_id=prev.empl_id)
					where
					curr.empl_id=a.EMPL_ID
					and 
					curr.SALARY_DT<>prev.SALARY_DT
				)

	) 
	OR --Work Location that aren't needed (no change)
	(
		(a.EMPL_ID = b.EMPL_ID) AND
		(a.WORK_STATE_CD is not null) AND --Salary
		(a.WORK_STATE_CD = b.WORK_STATE_CD)AND --current value
		(a.WORK_STATE_CD = (SELECT WORK_STATE_CD FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT))  --effect_dt value
	) 
	OR --GLC changes that aren't needed (no change)
	(
		(a.EMPL_ID = b.EMPL_ID) AND
		(a.GENL_LAB_CAT_CD is not null) AND --GLC
		(a.GENL_LAB_CAT_CD = b.GENL_LAB_CAT_CD)AND --current value
		(a.GENL_LAB_CAT_CD = (SELECT GENL_LAB_CAT_CD FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT))--effect_dt value
	) 
	OR -- position changes that aren't needed (no change)
	( 
		(a.EMPL_ID = b.EMPL_ID) AND
		(a.TITLE_DESC is not null) AND --position
		(a.TITLE_DESC = b.TITLE_DESC) AND --current value	
		(a.TITLE_DESC = (SELECT TITLE_DESC FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT))--effect_dt value
	)
	OR -- department changes that aren't needed (no change)
	( 
		(a.EMPL_ID = b.EMPL_ID) AND
		(a.ORG_ID is not null) AND --department
		(a.ORG_ID = b.ORG_ID) AND --current values
		(a.LAB_GRP_TYPE = b.LAB_GRP_TYPE) AND
		(a.ORG_ID = (SELECT ORG_ID FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT)) AND --effect_dt values
		(a.LAB_GRP_TYPE = (SELECT LAB_GRP_TYPE FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT)) AND
		0 =		(	select count(1) 
					from 
					xx_ceris_hist curr
					inner join
					xx_ceris_hist_previous prev
					on
					(curr.empl_id=prev.empl_id)
					where
					curr.empl_id=a.EMPL_ID
					and 
					curr.DEPT_START_DT<>prev.DEPT_START_DT
				)
	)
	OR -- status changes that aren't needed (no change)
	(
		(a.EMPL_ID = b.EMPL_ID) AND
		(a.REASON_DESC is not null) AND --status 
		(a.REASON_DESC = b.REASON_DESC) AND --current values
		(a.S_EMPL_TYPE_CD = b.S_EMPL_TYPE_CD) AND
		(a.REASON_DESC = (SELECT REASON_DESC FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT)) AND --effect_dt values
		(a.S_EMPL_TYPE_CD = (SELECT S_EMPL_TYPE_CD FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT)) 
	)
	OR -- exempt changes that aren't needed (no change)
	(
		(a.EMPL_ID = b.EMPL_ID) AND
		(a.EXMPT_FL is not null) AND --exempt
		(a.EXMPT_FL = b.EXMPT_FL) AND --current values
		(a.S_HRLY_SAL_CD = b.S_HRLY_SAL_CD) AND 
		(a.EXMPT_FL = (SELECT EXMPT_FL FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT)) AND --effect_dt values
		(a.S_HRLY_SAL_CD = (SELECT S_HRLY_SAL_CD FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = a.EMPL_ID and EFFECT_DT = a.EFFECT_DT)) 
	)
)
AND b.EFFECT_DT = (SELECT MAX(EFFECT_DT)
		     FROM IMAPS.DELTEK.EMPL_LAB_INFO
		     WHERE EMPL_ID = a.EMPL_ID)


--special case
--salary stays the same, but exempt flag changed
--we don't want to process salary change (because it actually didn't change)
--but effective date did change, because of exempt change
DELETE dbo.XX_CERIS_CP_EMPL_LAB_STG
FROM dbo.XX_CERIS_CP_EMPL_LAB_STG as a
INNER JOIN IMAPS.DELTEK.EMPL_LAB_INFO as b
ON
(
	 --Salary changes that aren't needed (no change)
	(
		(a.EMPL_ID = b.EMPL_ID) AND
		(a.ANNL_AMT is not null) AND --Salary
		(a.ANNL_AMT = b.ANNL_AMT)AND --current values are same
		(a.SAL_AMT = b.SAL_AMT)AND
		(a.HRLY_AMT = b.HRLY_AMT)AND
		(a.WORK_YR_HRS_NO = b.WORK_YR_HRS_NO)AND
		0<>(select count(1) from XX_CERIS_CP_EMPL_LAB_STG where empl_id=a.empl_id and exmpt_fl is not null) --effective date for exempt change will be processed
	)

) 
AND b.EFFECT_DT = (SELECT MAX(EFFECT_DT)
		     FROM IMAPS.DELTEK.EMPL_LAB_INFO
		     WHERE EMPL_ID = a.EMPL_ID)




-- Delete DFLT_REG_TS changes that aren't needed (no change)
DELETE dbo.XX_CERIS_CP_DFLT_TS_STG
FROM dbo.XX_CERIS_CP_DFLT_TS_STG as a
INNER JOIN IMAPS.DELTEK.DFLT_REG_TS as b
ON
(a.EMPL_ID = b.EMPL_ID) AND
(a.GENL_LAB_CAT_CD = b.GENL_LAB_CAT_CD) AND
(a.CHG_ORG_ID = b.CHG_ORG_ID)


-- Process changes to EMPL, EMPL_LAB_INFO and DFLT_REG_TS tables


-- EMPL table updates/inserts

--change KM 10/03/2006
UPDATE IMAPS.DELTEK.EMPL
SET TERM_DT = '2078-12-31 00:00:00',
S_EMPL_STATUS_CD = 'IN',
 ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
WHERE 
(TERM_DT IS NULL OR S_EMPL_STATUS_CD <> 'IN')
AND
EMPL_ID NOT IN
(
SELECT EMPL_ID FROM XX_CERIS_HIST
WHERE TERM_DT IS NULL
)
-- CP600000284_Begin
AND
COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000284_End


--CR6326 begin
update imaps.deltek.empl
set term_dt=ceris.term_dt,
	ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
from imaps.deltek.empl e
inner join
xx_ceris_cp_stg ceris
on
(
e.empl_id=ceris.empl_id
)
where
ceris.term_dt<>e.term_dt
and
ceris.term_dt is not null

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 613 : XX_CERIS_UPDATE_CP_SP.sql '
 
update imaps.deltek.empl_lab_info
set empl_class_cd='T2R',
	ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
from imaps.deltek.empl_lab_info eli
inner join
xx_ceris_t2r_employees t2r
on
(
eli.empl_id=t2r.empl_id
and
eli.effect_dt>=t2r.effect_dt
)
where
	empl_class_cd<>'T2R'
--CR6326 end

--CR7366 begin
update imaps.deltek.empl_lab_info
set empl_class_cd='T2R',
	ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
from imaps.deltek.empl_lab_info eli
inner join
xx_ceris_t2r_employees_salary_factor t2r
on
(
eli.empl_id=t2r.empl_id
and
eli.effect_dt>=t2r.effect_dt
)
where
	empl_class_cd<>'T2R'
--CR7366 end




 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 652 : XX_CERIS_UPDATE_CP_SP.sql '
 
UPDATE IMAPS.DELTEK.EMPL
SET TERM_DT = NULL,
S_EMPL_STATUS_CD = 'ACT',
ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
WHERE 
(TERM_DT IS NOT NULL OR S_EMPL_STATUS_CD <> 'ACT')
AND 
EMPL_ID IN
(
SELECT EMPL_ID FROM XX_CERIS_HIST
WHERE TERM_DT IS NULL
)
-- CP600000284_Begin
AND
COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000284_End
--end change KM 10/03/2006


--change KM 02/03/2006
UPDATE 	IMAPS.DELTEK.EMPL
SET 	MGR_EMPL_ID = stg.MGR_SERIAL_NUM,
	ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
FROM	IMAPS.DELTEK.EMPL AS cp
INNER JOIN dbo.XX_CERIS_HIST AS stg
ON (cp.EMPL_ID = stg.EMPL_ID
AND ISNULL(cp.MGR_EMPL_ID, '') <> ISNULL(stg.MGR_SERIAL_NUM, '')
-- CP600000284_Begin
AND cp.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000284_End

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
BEGIN
	SET @error_type = 4
	GOTO BL_ERROR_HANDLER
END
--end change KM 02/03/2006

DECLARE @rows int
SELECT @rows = COUNT(EMPL_ID) FROM dbo.XX_CERIS_CP_EMPL_STG

IF(@rows <> 0)
BEGIN
	-- EMPL records for updating
	UPDATE IMAPS.DELTEK.EMPL
	SET ORIG_HIRE_DT = stg.ORIG_HIRE_DT,
	 ADJ_HIRE_DT = stg.ADJ_HIRE_DT,
	 --TERM_DT = stg.TERM_DT,
	 SPVSR_NAME = stg.SPVSR_NAME,
	 FIRST_NAME = stg.FIRST_NAME,
	 LAST_NAME = stg.LAST_NAME,
	 MID_NAME = stg.MID_NAME,
	 LAST_FIRST_NAME = stg.LAST_FIRST_NAME,
	 EMAIL_ID = stg.EMAIL_ID,
	 ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
	FROM IMAPS.DELTEK.EMPL AS cp
	INNER JOIN dbo.XX_CERIS_CP_EMPL_STG AS stg
	ON (cp.EMPL_ID = stg.EMPL_ID)
-- CP600000284_Begin
        AND (cp.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000284_End

        SET @SQLServer_error_code = @@ERROR
        IF @SQLServer_error_code <> 0
           BEGIN
              SET @error_type = 4
              GOTO BL_ERROR_HANDLER
           END
	
END -- end updates/inserts for empl table




--CR4885 TODO: pick up here
/*
Changes to EMPL_LAB_INFO mapping and retro timesheet creations

No longer create retros for GLC changes
Create retros for Dept/ORG, Salary, and Exmpt changes

Don't roll forward old values when effective date is related to mapping change for Actuals
*/
DECLARE @Actuals_EFFECT_DT smalldatetime

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 741 : XX_CERIS_UPDATE_CP_SP.sql '
 
select @Actuals_EFFECT_DT = cast(parameter_value as smalldatetime)
from xx_processing_parameters
where interface_name_cd='CERIS'
and parameter_name='Actuals_EFFECT_DT'


-- EMPL_LAB_INFO updates/inserts

-- *for retro GLC/ORG_ID changes, need retro timesheets
SELECT @rows = COUNT(EMPL_ID) FROM dbo.XX_CERIS_CP_EMPL_LAB_STG
IF (@rows <> 0)
BEGIN
	
	--update empl_lab_info id's
	DECLARE EMPL_ID_CURSOR CURSOR FAST_FORWARD FOR
	SELECT DISTINCT EMPL_ID FROM dbo.XX_CERIS_CP_EMPL_LAB_STG
	WHERE EMPL_ID IN (SELECT EMPL_ID FROM IMAPS.DELTEK.EMPL_LAB_INFO GROUP BY EMPL_ID)

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
			WORK_STATE_CD, S_HRLY_SAL_CD, REASON_DESC_3
		FROM dbo.XX_CERIS_CP_EMPL_LAB_STG
		WHERE EMPL_ID = @EMPL_ID
		ORDER BY Eff_Dt

		OPEN EMPL_LAB_CURSOR

		FETCH NEXT FROM EMPL_LAB_CURSOR
		INTO 	@EFFECT_DT, 
			@HRLY_AMT, @SAL_AMT, @ANNL_AMT,
			@EXMPT_FL, @S_EMPL_TYPE_CD, @ORG_ID, @SEC_ORG_ID,
			@TITLE_DESC, @LAB_GRP_TYPE, @GENL_LAB_CAT_CD,
			@REASON_DESC, @WORK_YR_HRS_NO,
			@WORK_STATE_CD, @S_HRLY_SAL_CD, @REASON_DESC_3

		-- for each empl_lab change for current empl_id, ordered by date
		WHILE @@FETCH_STATUS = 0
		BEGIN
	
			-- do update processing
			
			-- figure out if change is retro or not
			-- get last records effective date
			SELECT @LAST_EFFECT_DT = MAX(EFFECT_DT)
			FROM IMAPS.DELTEK.EMPL_LAB_INFO
			WHERE EMPL_ID = @EMPL_ID

			
			/*
			1.  IF CHANGE IS TO CURRENT EMPL_LAB_INFO RECORD, JUST UPDATE THAT RECORD
			*/
			IF(@LAST_EFFECT_DT = @EFFECT_DT)
			BEGIN
				-- figure out change, and update accordingly

				-- if legacy GLC change
				IF(@REASON_DESC_3 <> NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'LEGACY GLC CHANGE'
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 818 : XX_CERIS_UPDATE_CP_SP.sql '
 
					UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
					SET 	REASON_DESC_3 = @REASON_DESC_3,
							REASON_DESC_2 = @REASON_DESC_2,
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

				-- if Salary or Work Hours change				
				ELSE IF(@HRLY_AMT <> NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'SALARY or HRS CHANGE'

					--KM EFFECTIVE DATE CHANGES
					--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
					SET @CUR_HRLY_AMT = NULL
					SET @CUR_SAL_AMT = NULL
					SET @CUR_ANNL_AMT = NULL
					SET @CUR_WORK_YR_HRS_NO = NULL
					SET @CUR_PCT_INCR_RT = NULL
					SET @PREV_HRLY_AMT = NULL
					SET @PREV_SAL_AMT = NULL
					SET @PREV_ANNL_AMT = NULL
					SET @PREV_WORK_YR_HRS_NO = NULL
					SET @PREV_PCT_INCR_RT = NULL

					SET @PREV_END_DT = NULL	
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 856 : XX_CERIS_UPDATE_CP_SP.sql '
 
					SELECT  @CUR_HRLY_AMT = HRLY_AMT,
							@CUR_SAL_AMT = SAL_AMT,
							@CUR_ANNL_AMT = ANNL_AMT,
							@CUR_WORK_YR_HRS_NO = WORK_YR_HRS_NO,
							@CUR_PCT_INCR_RT = PCT_INCR_RT
					FROM    IMAPS.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND		EFFECT_DT = @LAST_EFFECT_DT
					
					--KM EFFECTIVE DATE CHANGES
					--IF CURRENT VALUES ARE THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
					--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
					IF ((@CUR_HRLY_AMT = @HRLY_AMT) AND (@CUR_ANNL_AMT = @ANNL_AMT) AND (@CUR_SAL_AMT = @SAL_AMT) AND (@CUR_WORK_YR_HRS_NO=@WORK_YR_HRS_NO))
					BEGIN
						SELECT  @PREV_HRLY_AMT = HRLY_AMT,
								@PREV_SAL_AMT = SAL_AMT,
								@PREV_ANNL_AMT = ANNL_AMT,
								@PREV_WORK_YR_HRS_NO = WORK_YR_HRS_NO,
								@PREV_PCT_INCR_RT = PCT_INCR_RT,
								@PREV_END_DT = END_DT
						FROM 	IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID	
						AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID 
																									AND (HRLY_AMT <> @HRLY_AMT
																										 OR SAL_AMT <> @SAL_AMT
																										 OR ANNL_AMT <> @ANNL_AMT
																										 OR WORK_YR_HRS_NO <> @WORK_YR_HRS_NO))												
						SELECT	@DIV_START_DT = DIVISION_START_DT
						FROM	XX_CERIS_HIST
						WHERE 	EMPL_ID = @EMPL_ID						

						--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
						IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1 AND @EFFECT_DT > @DIV_START_DT AND @EFFECT_DT > @Actuals_EFFECT_DT
						BEGIN							
							--ROLL OLD VALUES FORWARD
							UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
							SET		HRLY_AMT = @PREV_HRLY_AMT, 
									SAL_AMT = @PREV_SAL_AMT,
									ANNL_AMT = @PREV_ANNL_AMT,
									WORK_YR_HRS_NO = @PREV_WORK_YR_HRS_NO,
									PCT_INCR_RT = @PREV_PCT_INCR_RT,
									REASON_DESC_2 = @REASON_DESC_2,
									ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
							WHERE 	EMPL_ID = @EMPL_ID
								AND	EFFECT_DT > @PREV_END_DT
								AND	EFFECT_DT < @EFFECT_DT

							SET @SQLServer_error_code = @@ERROR
							IF @SQLServer_error_code <> 0
							   BEGIN
								  SET @error_type = 5
								  GOTO BL_ERROR_HANDLER
							   END
													
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
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
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
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
						--TRACK RETRO TIMESHEET DATA
						INSERT INTO XX_CERIS_RETRO_TS
						(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
						SELECT @EMPL_ID, @HRLY_AMT, @EFFECT_DT, GETDATE()
				
						SET @SQLServer_error_code = @@ERROR
                        IF @SQLServer_error_code <> 0
                           BEGIN
								SET @error_type = 7	                                               
								GOTO BL_ERROR_HANDLER
                           END
					END
					
					--PROCESS CHANGE
					SET @PCT_INCR_RT = 0
					IF @CUR_HRLY_AMT = @HRLY_AMT
					BEGIN
						SET @PCT_INCR_RT = isnull(@CUR_PCT_INCR_RT,0)
					END
					ELSE
					BEGIN
						SET @PCT_INCR_RT = isnull( cast(((@HRLY_AMT - @CUR_HRLY_AMT)/@CUR_HRLY_AMT) as decimal(5,4))  , 0)
					END

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 966 : XX_CERIS_UPDATE_CP_SP.sql '
 
					UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
					SET		ANNL_AMT = @ANNL_AMT,
							SAL_AMT = @SAL_AMT,
							HRLY_AMT = @HRLY_AMT,
							WORK_YR_HRS_NO = @WORK_YR_HRS_NO,
							PCT_INCR_RT = @PCT_INCR_RT,
							REASON_DESC_2 = @REASON_DESC_2,
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


				-- if Work Location change
				ELSE IF(@WORK_STATE_CD <> NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'WORK STATE CHANGE'
				
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 994 : XX_CERIS_UPDATE_CP_SP.sql '
 
					UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
					SET		WORK_STATE_CD = @WORK_STATE_CD,
							REASON_DESC_2 = @REASON_DESC_2,
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

				-- if LCDB change
				ELSE IF(@GENL_LAB_CAT_CD <> NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'LCDB GLC CHANGE'
				
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 1017 : XX_CERIS_UPDATE_CP_SP.sql '
 
					UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
					SET		GENL_LAB_CAT_CD = @GENL_LAB_CAT_CD,
							REASON_DESC_2 = @REASON_DESC_2,
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
				ELSE IF(@TITLE_DESC <> NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'POS CHANGE'
				
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 1041 : XX_CERIS_UPDATE_CP_SP.sql '
 
					UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
					SET 	TITLE_DESC = @TITLE_DESC,
							REASON_DESC_2 = @REASON_DESC_2,
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
				ELSE IF(@ORG_ID <> NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'ORG CHANGE'
				
					--KM EFFECTIVE DATE CHANGES
					--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
					SET @CUR_ORG_ID = NULL
					SET @PREV_ORG_ID = NULL	
					SET @PREV_END_DT = NULL	
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 1071 : XX_CERIS_UPDATE_CP_SP.sql '
 
					SELECT  @CUR_ORG_ID = ORG_ID
					FROM    IMAPS.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND		EFFECT_DT = @LAST_EFFECT_DT
					
					--KM EFFECTIVE DATE CHANGES
					--IF CURRENT ORG IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
					--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
					IF @CUR_ORG_ID = @ORG_ID
					BEGIN
						SELECT 	@PREV_ORG_ID = ORG_ID, 
								@PREV_LAB_GRP_TYPE = LAB_GRP_TYPE,
								@PREV_SEC_ORG_ID = SEC_ORG_ID,
								@PREV_END_DT = END_DT
						FROM 	IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID	
						AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND ORG_ID <> @ORG_ID)
												
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 1092 : XX_CERIS_UPDATE_CP_SP.sql '
 
						SELECT	@DIV_START_DT = DIVISION_START_DT
						FROM	XX_CERIS_HIST
						WHERE 	EMPL_ID = @EMPL_ID						

						--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
						IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1 AND @EFFECT_DT > @DIV_START_DT
						BEGIN							
							--ROLL OLD ORG_ID FORWARD
							UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
							SET		ORG_ID = @PREV_ORG_ID, 
									LAB_GRP_TYPE = @PREV_LAB_GRP_TYPE,
									SEC_ORG_ID = @PREV_SEC_ORG_ID,
									REASON_DESC_2 = @REASON_DESC_2,
									ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
							WHERE 	EMPL_ID = @EMPL_ID
								AND	EFFECT_DT > @PREV_END_DT
								AND	EFFECT_DT < @EFFECT_DT

							SET @SQLServer_error_code = @@ERROR
							IF @SQLServer_error_code <> 0
							   BEGIN
								  SET @error_type = 5
								  GOTO BL_ERROR_HANDLER
							   END
						
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @PREV_ORG_ID, NULL, @PREV_END_DT+1, @EFFECT_DT-1
					
							SET @SQLServer_error_code = @@ERROR
                            IF @SQLServer_error_code <> 0
                               BEGIN
                                   SET @error_type = 7
                                   GOTO BL_ERROR_HANDLER
                               END
						END
						ELSE IF @PREV_END_DT IS NOT NULL
						BEGIN
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @ORG_ID, NULL, @EFFECT_DT, @PREV_END_DT
					
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
						--TRACK RETRO TIMESHEET DATA
						INSERT INTO XX_CERIS_RETRO_TS
						(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
						SELECT @EMPL_ID, @ORG_ID, NULL, @EFFECT_DT, GETDATE()
				
						SET @SQLServer_error_code = @@ERROR
                        IF @SQLServer_error_code <> 0
                           BEGIN
								SET @error_type = 7	                                               
								GOTO BL_ERROR_HANDLER
                           END
					END
					
					--PROCESS ORG CHANGE
					UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
					SET 	ORG_ID = @ORG_ID,
							LAB_GRP_TYPE = @LAB_GRP_TYPE,
							SEC_ORG_ID = @SEC_ORG_ID,
							REASON_DESC_2 = @REASON_DESC_2,
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

				-- else if status or status3 change
				ELSE IF(@REASON_DESC<> NULL OR @S_EMPL_TYPE_CD <> NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'STATUS CHANGE'
				
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 1185 : XX_CERIS_UPDATE_CP_SP.sql '
 
					UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
					SET		REASON_DESC = @REASON_DESC,
							S_EMPL_TYPE_CD = @S_EMPL_TYPE_CD,
							REASON_DESC_2 = @REASON_DESC_2,
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

				-- if exempt change
				ELSE IF (@S_HRLY_SAL_CD <> NULL OR @EXMPT_FL <> NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'EXMPT CHANGE'
				
					--KM EFFECTIVE DATE CHANGES
					--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
					SET @CUR_S_HRLY_SAL_CD = NULL
					SET @CUR_EXMPT_FL = NULL
					SET @PREV_S_HRLY_SAL_CD = NULL
					SET @PREV_EXMPT_FL = NULL

					SET @PREV_END_DT = NULL	
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 1218 : XX_CERIS_UPDATE_CP_SP.sql '
 
					SELECT  @CUR_S_HRLY_SAL_CD = S_HRLY_SAL_CD,
							@CUR_EXMPT_FL = EXMPT_FL
					FROM    IMAPS.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND		EFFECT_DT = @LAST_EFFECT_DT
					
					--KM EFFECTIVE DATE CHANGES
					--IF CURRENT VALUES ARE THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
					--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
					IF ((@CUR_S_HRLY_SAL_CD = @S_HRLY_SAL_CD) AND (@CUR_EXMPT_FL=@EXMPT_FL))
					BEGIN
						SELECT  @PREV_S_HRLY_SAL_CD = S_HRLY_SAL_CD,
								@PREV_EXMPT_FL = EXMPT_FL,
								@PREV_END_DT = END_DT
						FROM 	IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID	
						AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID 
																									AND (S_HRLY_SAL_CD <> @S_HRLY_SAL_CD
																										 OR EXMPT_FL <> @EXMPT_FL) )
												
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 1241 : XX_CERIS_UPDATE_CP_SP.sql '
 
						SELECT	@DIV_START_DT = DIVISION_START_DT
						FROM	XX_CERIS_HIST
						WHERE 	EMPL_ID = @EMPL_ID						

						--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
						IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1 AND @EFFECT_DT > @DIV_START_DT AND @EFFECT_DT > @Actuals_EFFECT_DT
						BEGIN							
							--ROLL OLD VALUES FORWARD
							UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
							SET		S_HRLY_SAL_CD = @PREV_S_HRLY_SAL_CD, 
									EXMPT_FL = @PREV_EXMPT_FL,
									REASON_DESC_2 = @REASON_DESC_2,
									ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
							WHERE 	EMPL_ID = @EMPL_ID
								AND	EFFECT_DT > @PREV_END_DT
								AND	EFFECT_DT < @EFFECT_DT

							SET @SQLServer_error_code = @@ERROR
							IF @SQLServer_error_code <> 0
							   BEGIN
								  SET @error_type = 5
								  GOTO BL_ERROR_HANDLER
							   END
						
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
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
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
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
						--TRACK RETRO TIMESHEET DATA
						INSERT INTO XX_CERIS_RETRO_TS
						(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
						SELECT @EMPL_ID, @EXMPT_FL, @EFFECT_DT, GETDATE()
				
						SET @SQLServer_error_code = @@ERROR
                        IF @SQLServer_error_code <> 0
                           BEGIN
								SET @error_type = 7	                                               
								GOTO BL_ERROR_HANDLER
                           END
					END
					
					--PROCESS CHANGE
					UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
					SET		EXMPT_FL = @EXMPT_FL,
							S_HRLY_SAL_CD=@S_HRLY_SAL_CD,
							REASON_DESC_2 = @REASON_DESC_2,
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
			ELSE IF(@LAST_EFFECT_DT < @EFFECT_DT)
			BEGIN
				-- figure out change, 
				-- get previous values
				-- insert previous values + changed values


				-- if legacy GLC change
				IF(@REASON_DESC_3 <> NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'LEGACY GLC CHANGE'
					INSERT INTO IMAPS.DELTEK.EMPL_LAB_INFO
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
					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, @REASON_DESC_2, @REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
					FROM IMAPS.DELTEK.EMPL_LAB_INFO
					WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @LAST_EFFECT_DT)
			
                    SET @SQLServer_error_code = @@ERROR
                    IF @SQLServer_error_code <> 0
                       BEGIN
                          SET @error_type = 6
                          GOTO BL_ERROR_HANDLER
                       END
				END


				-- if Salary or Work Hours change				
				ELSE IF(@HRLY_AMT <> NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'SALARY or HRS CHANGE'
				
					--KM EFFECTIVE DATE CHANGES
					--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
					SET @CUR_HRLY_AMT = NULL
					SET @CUR_SAL_AMT = NULL
					SET @CUR_ANNL_AMT = NULL
					SET @CUR_WORK_YR_HRS_NO = NULL
					SET @CUR_PCT_INCR_RT = NULL
					SET @PREV_HRLY_AMT = NULL
					SET @PREV_SAL_AMT = NULL
					SET @PREV_ANNL_AMT = NULL
					SET @PREV_WORK_YR_HRS_NO = NULL
					SET @PREV_PCT_INCR_RT = NULL

					SET @PREV_END_DT = NULL	
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 1404 : XX_CERIS_UPDATE_CP_SP.sql '
 
					SELECT  @CUR_HRLY_AMT = HRLY_AMT,
							@CUR_SAL_AMT = SAL_AMT,
							@CUR_ANNL_AMT = ANNL_AMT,
							@CUR_WORK_YR_HRS_NO = WORK_YR_HRS_NO,
							@CUR_PCT_INCR_RT = PCT_INCR_RT
					FROM    IMAPS.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND		EFFECT_DT = @LAST_EFFECT_DT
					
					--KM EFFECTIVE DATE CHANGES
					--IF CURRENT VALUES ARE THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
					--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
					IF ((@CUR_HRLY_AMT = @HRLY_AMT) AND (@CUR_ANNL_AMT = @ANNL_AMT) AND (@CUR_SAL_AMT = @SAL_AMT) AND (@CUR_WORK_YR_HRS_NO=@WORK_YR_HRS_NO))
					BEGIN
						SELECT  @PREV_HRLY_AMT = HRLY_AMT,
								@PREV_SAL_AMT = SAL_AMT,
								@PREV_ANNL_AMT = ANNL_AMT,
								@PREV_WORK_YR_HRS_NO = WORK_YR_HRS_NO,
								@PREV_PCT_INCR_RT = PCT_INCR_RT,
								@PREV_END_DT = END_DT
						FROM 	IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID	
						AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID 
																									AND (HRLY_AMT <> @HRLY_AMT
																										 OR SAL_AMT <> @SAL_AMT
																										 OR ANNL_AMT <> @ANNL_AMT
																										 OR WORK_YR_HRS_NO <> @WORK_YR_HRS_NO))												
						SELECT	@DIV_START_DT = DIVISION_START_DT
						FROM	XX_CERIS_HIST
						WHERE 	EMPL_ID = @EMPL_ID						

						--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
						IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1 AND @EFFECT_DT > @DIV_START_DT AND @EFFECT_DT > @Actuals_EFFECT_DT
						BEGIN							
							--ROLL OLD VALUES FORWARD
							UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
							SET		HRLY_AMT = @PREV_HRLY_AMT, 
									SAL_AMT = @PREV_SAL_AMT,
									ANNL_AMT = @PREV_ANNL_AMT,
									WORK_YR_HRS_NO = @PREV_WORK_YR_HRS_NO,
									PCT_INCR_RT = @PREV_PCT_INCR_RT,
									REASON_DESC_2 = @REASON_DESC_2,
									ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
							WHERE 	EMPL_ID = @EMPL_ID
								AND	EFFECT_DT > @PREV_END_DT
								AND	EFFECT_DT < @EFFECT_DT

							SET @SQLServer_error_code = @@ERROR
							IF @SQLServer_error_code <> 0
							   BEGIN
								  SET @error_type = 5
								  GOTO BL_ERROR_HANDLER
							   END
						
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
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
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
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
						--TRACK RETRO TIMESHEET DATA
						INSERT INTO XX_CERIS_RETRO_TS
						(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
						SELECT @EMPL_ID, @HRLY_AMT, @EFFECT_DT, GETDATE()
				
						SET @SQLServer_error_code = @@ERROR
                        IF @SQLServer_error_code <> 0
                           BEGIN
								SET @error_type = 7	                                               
								GOTO BL_ERROR_HANDLER
                           END
					END
					
					--PROCESS CHANGE
					SET @PCT_INCR_RT = 0
					IF @CUR_HRLY_AMT = @HRLY_AMT
					BEGIN
						SET @PCT_INCR_RT = isnull(@CUR_PCT_INCR_RT,0)
					END
					ELSE
					BEGIN
						SET @PCT_INCR_RT = isnull( cast(((@HRLY_AMT - @CUR_HRLY_AMT)/@CUR_HRLY_AMT) as decimal(5,4))  , 0)
					END

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 1514 : XX_CERIS_UPDATE_CP_SP.sql '
 
					INSERT INTO IMAPS.DELTEK.EMPL_LAB_INFO
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
					 @EMPL_ID, @EFFECT_DT, S_HRLY_SAL_CD, @HRLY_AMT,
					 @SAL_AMT, @ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
					 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
					 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, @PCT_INCR_RT, REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
					 EMPL_CLASS_CD, @WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
					FROM IMAPS.DELTEK.EMPL_LAB_INFO
					WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @LAST_EFFECT_DT)
			
                    SET @SQLServer_error_code = @@ERROR
                    IF @SQLServer_error_code <> 0
                       BEGIN
                          SET @error_type = 6
                          GOTO BL_ERROR_HANDLER
                       END
				END

				
				-- if Work Location change
				ELSE IF(@WORK_STATE_CD <> NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'WORK STATE CHANGE'
				
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 1558 : XX_CERIS_UPDATE_CP_SP.sql '
 
					INSERT INTO IMAPS.DELTEK.EMPL_LAB_INFO
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
					 ORG_ID, TITLE_DESC, @WORK_STATE_CD, STD_EST_HRS,
					 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
					FROM IMAPS.DELTEK.EMPL_LAB_INFO
					WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @LAST_EFFECT_DT)
			
                    SET @SQLServer_error_code = @@ERROR
                    IF @SQLServer_error_code <> 0
                       BEGIN
                          SET @error_type = 6
                          GOTO BL_ERROR_HANDLER
                       END
				END


				-- if LCDB GLC change
				ELSE IF(@GENL_LAB_CAT_CD <> NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'LCDB GLC CHANGE'
				
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 1602 : XX_CERIS_UPDATE_CP_SP.sql '
 
					INSERT INTO IMAPS.DELTEK.EMPL_LAB_INFO
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
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
					FROM IMAPS.DELTEK.EMPL_LAB_INFO
					WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @LAST_EFFECT_DT)
			
                    SET @SQLServer_error_code = @@ERROR
                    IF @SQLServer_error_code <> 0
                       BEGIN
                          SET @error_type = 6
                          GOTO BL_ERROR_HANDLER
                       END
				END


				-- if position change
				ELSE IF(@TITLE_DESC <> NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'POS CHANGE'
					INSERT INTO IMAPS.DELTEK.EMPL_LAB_INFO
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
					FROM IMAPS.DELTEK.EMPL_LAB_INFO
					WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @LAST_EFFECT_DT)
			
                    SET @SQLServer_error_code = @@ERROR
                    IF @SQLServer_error_code <> 0
                       BEGIN
                          SET @error_type = 6
                          GOTO BL_ERROR_HANDLER
                       END
				END


				--if department change
				ELSE IF(@ORG_ID <> NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'ORG CHANGE'
				
					--KM EFFECTIVE DATE CHANGES
					--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
					SET @CUR_ORG_ID = NULL
					SET @PREV_ORG_ID = NULL	
					SET @PREV_END_DT = NULL	
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 1692 : XX_CERIS_UPDATE_CP_SP.sql '
 
					SELECT  @CUR_ORG_ID = ORG_ID
					FROM    IMAPS.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND	EFFECT_DT = @LAST_EFFECT_DT
					
					--KM EFFECTIVE DATE CHANGES
					--IF CURRENT ORG IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
					--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
					IF @CUR_ORG_ID = @ORG_ID
					BEGIN
						SELECT 	@PREV_ORG_ID = ORG_ID, 
								@PREV_LAB_GRP_TYPE = LAB_GRP_TYPE,
								@PREV_SEC_ORG_ID = SEC_ORG_ID,
								@PREV_END_DT = END_DT
						FROM 	IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID	
						AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND ORG_ID <> @ORG_ID)

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 1713 : XX_CERIS_UPDATE_CP_SP.sql '
 
						SELECT	@DIV_START_DT = DIVISION_START_DT
						FROM	XX_CERIS_HIST
						WHERE 	EMPL_ID = @EMPL_ID						

						--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
						IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1 AND @EFFECT_DT > @DIV_START_DT
						BEGIN				
							--ROLL OLD ORG_ID FORWARD
							UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
							SET		ORG_ID = @PREV_ORG_ID, 
									LAB_GRP_TYPE = @PREV_LAB_GRP_TYPE,
									SEC_ORG_ID = @PREV_SEC_ORG_ID,
									REASON_DESC_2=@REASON_DESC_2,
									ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
							WHERE 	EMPL_ID = @EMPL_ID
								AND	EFFECT_DT > @PREV_END_DT
								AND	EFFECT_DT < @EFFECT_DT

							SET @SQLServer_error_code = @@ERROR
							IF @SQLServer_error_code <> 0
							   BEGIN
								  SET @error_type = 5
								  GOTO BL_ERROR_HANDLER
							   END
						
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @PREV_ORG_ID, NULL, @PREV_END_DT+1, @EFFECT_DT-1
					
							SET @SQLServer_error_code = @@ERROR
                            IF @SQLServer_error_code <> 0
                               BEGIN
                                   SET @error_type = 7
                                   GOTO BL_ERROR_HANDLER
                               END
						END
						ELSE IF @PREV_END_DT IS NOT NULL
						BEGIN
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @ORG_ID, NULL, @EFFECT_DT, @PREV_END_DT
					
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
						--TRACK RETRO TIMESHEET DATA
						INSERT INTO XX_CERIS_RETRO_TS
						(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
						SELECT @EMPL_ID, @ORG_ID, NULL, @EFFECT_DT, GETDATE()
				
						SET @SQLServer_error_code = @@ERROR
                        IF @SQLServer_error_code <> 0
                           BEGIN
                               SET @error_type = 7
                               GOTO BL_ERROR_HANDLER
                           END	
					END
					
					--PROCESS ORG CHANGE
					INSERT INTO IMAPS.DELTEK.EMPL_LAB_INFO
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
					 STD_EFFECT_AMT, @LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, @SEC_ORG_ID, COMMENTS,
					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
					FROM IMAPS.DELTEK.EMPL_LAB_INFO
					WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @LAST_EFFECT_DT)

                    SET @SQLServer_error_code = @@ERROR
                    IF @SQLServer_error_code <> 0
                       BEGIN
                          SET @error_type = 6
                          GOTO BL_ERROR_HANDLER
                       END	
				END

				-- else if status or status3 change
				ELSE IF(@REASON_DESC <> NULL OR @S_EMPL_TYPE_CD <> NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'STATUS CHANGE'
				
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 1824 : XX_CERIS_UPDATE_CP_SP.sql '
 
					INSERT INTO IMAPS.DELTEK.EMPL_LAB_INFO
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
					 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
					 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, @REASON_DESC,
					 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
					 S_STEP_NO, MGR_EMPL_ID, END_DT, SEC_ORG_ID, COMMENTS,
					 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
					 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
					 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
					 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
					FROM IMAPS.DELTEK.EMPL_LAB_INFO
					WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @LAST_EFFECT_DT)

                    SET @SQLServer_error_code = @@ERROR
                    IF @SQLServer_error_code <> 0
                       BEGIN
                          SET @error_type = 6
                          GOTO BL_ERROR_HANDLER
                       END
				END

				-- if exempt change
				ELSE IF (@S_HRLY_SAL_CD <> NULL OR @EXMPT_FL <> NULL)
				BEGIN
					SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'EXMPT CHANGE'
				
					--KM EFFECTIVE DATE CHANGES
					--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
					SET @CUR_S_HRLY_SAL_CD = NULL
					SET @CUR_EXMPT_FL = NULL
					SET @PREV_S_HRLY_SAL_CD = NULL
					SET @PREV_EXMPT_FL = NULL

					SET @PREV_END_DT = NULL	
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 1876 : XX_CERIS_UPDATE_CP_SP.sql '
 
					SELECT  @CUR_S_HRLY_SAL_CD = S_HRLY_SAL_CD,
							@CUR_EXMPT_FL = EXMPT_FL
					FROM    IMAPS.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND		EFFECT_DT = @LAST_EFFECT_DT
					
					--KM EFFECTIVE DATE CHANGES
					--IF CURRENT VALUES ARE THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
					--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
					IF ((@CUR_S_HRLY_SAL_CD = @S_HRLY_SAL_CD) AND (@CUR_EXMPT_FL=@EXMPT_FL))
					BEGIN
						SELECT  @PREV_S_HRLY_SAL_CD = S_HRLY_SAL_CD,
								@PREV_EXMPT_FL = EXMPT_FL,
								@PREV_END_DT = END_DT
						FROM 	IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID	
						AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID 
																									AND (S_HRLY_SAL_CD <> @S_HRLY_SAL_CD
																										 OR EXMPT_FL <> @EXMPT_FL) )
												
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 1899 : XX_CERIS_UPDATE_CP_SP.sql '
 
						SELECT	@DIV_START_DT = DIVISION_START_DT
						FROM	XX_CERIS_HIST
						WHERE 	EMPL_ID = @EMPL_ID						

						--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
						IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1 AND @EFFECT_DT > @DIV_START_DT AND @EFFECT_DT > @Actuals_EFFECT_DT
						BEGIN							
							--ROLL OLD VALUES FORWARD
							UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
							SET		S_HRLY_SAL_CD = @PREV_S_HRLY_SAL_CD, 
									EXMPT_FL = @PREV_EXMPT_FL,
									REASON_DESC_2 = @REASON_DESC_2,
									ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
							WHERE 	EMPL_ID = @EMPL_ID
								AND	EFFECT_DT > @PREV_END_DT
								AND	EFFECT_DT < @EFFECT_DT

							SET @SQLServer_error_code = @@ERROR
							IF @SQLServer_error_code <> 0
							   BEGIN
								  SET @error_type = 5
								  GOTO BL_ERROR_HANDLER
							   END
						
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
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
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
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
						--TRACK RETRO TIMESHEET DATA
						INSERT INTO XX_CERIS_RETRO_TS
						(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
						SELECT @EMPL_ID, @EXMPT_FL, @EFFECT_DT, GETDATE()
				
						SET @SQLServer_error_code = @@ERROR
                        IF @SQLServer_error_code <> 0
                           BEGIN
								SET @error_type = 7	                                               
								GOTO BL_ERROR_HANDLER
                           END
					END
					
					--PROCESS CHANGE
					INSERT INTO IMAPS.DELTEK.EMPL_LAB_INFO
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
					 @EMPL_ID, @EFFECT_DT, @S_HRLY_SAL_CD, HRLY_AMT,
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
					FROM IMAPS.DELTEK.EMPL_LAB_INFO
					WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @LAST_EFFECT_DT)

                    SET @SQLServer_error_code = @@ERROR
                    IF @SQLServer_error_code <> 0
                       BEGIN
                          SET @error_type = 6
                          GOTO BL_ERROR_HANDLER
                       END
				END

				
				--CHANGE KM 1/19/06
				--NEED TO CLOSE OUT LAST RECORD AFTER INSERTING NEW ONE
				UPDATE 	IMAPS.DELTEK.EMPL_LAB_INFO
				SET		END_DT = @EFFECT_DT - 1,
						ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
				WHERE 	EMPL_ID = @EMPL_ID AND EFFECT_DT = @LAST_EFFECT_DT
				--END CHANGE KM 1/19/06			
			END


			


			/*
			3.  IF CHANGE IS EFFECTIVE BEFORE THE CURRENT EMPL_LAB_INFO RECORD
			*/
			-- if change is effective prior to
			-- most current record
			ELSE IF(@LAST_EFFECT_DT > @EFFECT_DT)
			BEGIN
				-- figure out if record with same effective date exists
				SELECT @rows = COUNT(EMPL_ID) FROM IMAPS.DELTEK.EMPL_LAB_INFO
				WHERE EMPL_ID = @EMPL_ID AND EFFECT_DT = @EFFECT_DT

				/*
				3a.  AND A RECORD WITH THAT EFFECTIVE DATE ALREADY EXISTS, JUST UPDATE IT AND ROLL THE CHANGE FORWARD
				*/
				-- if record exists, just update it
				-- and do retro rollforward/ts if required
				IF(@rows <> 0)
				BEGIN
					-- figure out change, and update accordingly

					-- if legacy GLC change
					IF(@REASON_DESC_3 <> NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'LEGACY GLC CHANGE'
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2043 : XX_CERIS_UPDATE_CP_SP.sql '
 
						UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
						SET 	REASON_DESC_3 = @REASON_DESC_3,
								REASON_DESC_2 = @REASON_DESC_2,
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

	
					-- if Salary or Work Hrs change
					ELSE IF(@HRLY_AMT <> NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'SALARY or HRS CHANGE'
					
						--KM EFFECTIVE DATE CHANGES
						--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
						SET @CUR_HRLY_AMT = NULL
						SET @CUR_SAL_AMT = NULL
						SET @CUR_ANNL_AMT = NULL
						SET @CUR_WORK_YR_HRS_NO = NULL
						SET @CUR_PCT_INCR_RT = NULL
						SET @PREV_HRLY_AMT = NULL
						SET @PREV_SAL_AMT = NULL
						SET @PREV_ANNL_AMT = NULL
						SET @PREV_WORK_YR_HRS_NO = NULL
						SET @PREV_PCT_INCR_RT = NULL

						SET @PREV_END_DT = NULL	
						
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2082 : XX_CERIS_UPDATE_CP_SP.sql '
 
						SELECT  @CUR_HRLY_AMT = HRLY_AMT,
								@CUR_SAL_AMT = SAL_AMT,
								@CUR_ANNL_AMT = ANNL_AMT,
								@CUR_WORK_YR_HRS_NO = WORK_YR_HRS_NO,
								@CUR_PCT_INCR_RT = PCT_INCR_RT
						FROM    IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID
						AND		EFFECT_DT = @LAST_EFFECT_DT
						
						--KM EFFECTIVE DATE CHANGES
						--IF CURRENT VALUES ARE THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
						--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
						IF ((@CUR_HRLY_AMT = @HRLY_AMT) AND (@CUR_ANNL_AMT = @ANNL_AMT) AND (@CUR_SAL_AMT = @SAL_AMT) AND (@CUR_WORK_YR_HRS_NO=@WORK_YR_HRS_NO))
						BEGIN
							SELECT  @PREV_HRLY_AMT = HRLY_AMT,
									@PREV_SAL_AMT = SAL_AMT,
									@PREV_ANNL_AMT = ANNL_AMT,
									@PREV_WORK_YR_HRS_NO = WORK_YR_HRS_NO,
									@PREV_PCT_INCR_RT = PCT_INCR_RT,
									@PREV_END_DT = END_DT
							FROM 	IMAPS.DELTEK.EMPL_LAB_INFO
							WHERE 	EMPL_ID = @EMPL_ID	
							AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID 
																										AND (HRLY_AMT <> @HRLY_AMT
																											 OR SAL_AMT <> @SAL_AMT
																											 OR ANNL_AMT <> @ANNL_AMT
																											 OR WORK_YR_HRS_NO <> @WORK_YR_HRS_NO))												
							SELECT	@DIV_START_DT = DIVISION_START_DT
							FROM	XX_CERIS_HIST
							WHERE 	EMPL_ID = @EMPL_ID						

							--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
							IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1 AND @EFFECT_DT > @DIV_START_DT AND @EFFECT_DT > @Actuals_EFFECT_DT
							BEGIN							
								--ROLL OLD VALUES FORWARD
								UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
								SET		HRLY_AMT = @PREV_HRLY_AMT, 
										SAL_AMT = @PREV_SAL_AMT,
										ANNL_AMT = @PREV_ANNL_AMT,
										WORK_YR_HRS_NO = @PREV_WORK_YR_HRS_NO,
										PCT_INCR_RT = @PREV_PCT_INCR_RT,
										REASON_DESC_2 = @REASON_DESC_2,
										ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
								WHERE 	EMPL_ID = @EMPL_ID
									AND	EFFECT_DT > @PREV_END_DT
									AND	EFFECT_DT < @EFFECT_DT

								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								   BEGIN
									  SET @error_type = 5
									  GOTO BL_ERROR_HANDLER
								   END
							
								--TRACK RETRO TIMESHEET DATA
								INSERT INTO XX_CERIS_RETRO_TS
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
								--TRACK RETRO TIMESHEET DATA
								INSERT INTO XX_CERIS_RETRO_TS
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
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
							(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @HRLY_AMT, @EFFECT_DT, GETDATE()
					
							SET @SQLServer_error_code = @@ERROR
							IF @SQLServer_error_code <> 0
							   BEGIN
									SET @error_type = 7	                                               
									GOTO BL_ERROR_HANDLER
							   END
						END
						
						--PROCESS CHANGE
						SET @PCT_INCR_RT = 0
						IF @CUR_HRLY_AMT = @HRLY_AMT
						BEGIN
							SET @PCT_INCR_RT = isnull(@CUR_PCT_INCR_RT,0)
						END
						ELSE
						BEGIN
							SET @PCT_INCR_RT = isnull( cast(((@HRLY_AMT - @CUR_HRLY_AMT)/@CUR_HRLY_AMT) as decimal(5,4))  , 0)
						END


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2193 : XX_CERIS_UPDATE_CP_SP.sql '
 
						UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
						SET		ANNL_AMT = @ANNL_AMT,
								SAL_AMT = @SAL_AMT,
								HRLY_AMT = @HRLY_AMT,
								WORK_YR_HRS_NO = @WORK_YR_HRS_NO,
								PCT_INCR_RT = @PCT_INCR_RT,
								REASON_DESC_2 = @REASON_DESC_2,
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


					-- if Work Location change
					IF(@WORK_STATE_CD <> NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'WORK STATE CHANGE'
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2221 : XX_CERIS_UPDATE_CP_SP.sql '
 
						UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
						SET		WORK_STATE_CD = @WORK_STATE_CD,
								REASON_DESC_2 = @REASON_DESC_2,
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



					-- if LCDB GLC change
					IF(@GENL_LAB_CAT_CD <> NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'LCDB GLC CHANGE'
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2246 : XX_CERIS_UPDATE_CP_SP.sql '
 
						UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
						SET		GENL_LAB_CAT_CD = @GENL_LAB_CAT_CD,
								REASON_DESC_2 = @REASON_DESC_2,
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
					ELSE IF(@TITLE_DESC <> NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'POS CHANGE'
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2269 : XX_CERIS_UPDATE_CP_SP.sql '
 
						UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
						SET 	TITLE_DESC = @TITLE_DESC,
								REASON_DESC_2 = @REASON_DESC_2,
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
					ELSE IF(@ORG_ID <> NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'ORG CHANGE'
					
						--KM EFFECTIVE DATE CHANGES
						--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
						SET @CUR_ORG_ID = NULL
						SET @PREV_ORG_ID = NULL	
						SET @PREV_END_DT = NULL	
						
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2300 : XX_CERIS_UPDATE_CP_SP.sql '
 
						SELECT  @CUR_ORG_ID = ORG_ID
						FROM    IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID
						AND	EFFECT_DT = @LAST_EFFECT_DT
						
						--KM EFFECTIVE DATE CHANGES
						--IF CURRENT ORG IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
						--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
						IF @CUR_ORG_ID = @ORG_ID
						BEGIN
							SELECT 	@PREV_ORG_ID = ORG_ID, 
									@PREV_LAB_GRP_TYPE = LAB_GRP_TYPE,
									@PREV_SEC_ORG_ID = SEC_ORG_ID,
									@PREV_END_DT = END_DT
							FROM 	IMAPS.DELTEK.EMPL_LAB_INFO
							WHERE 	EMPL_ID = @EMPL_ID	
							AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND ORG_ID <> @ORG_ID)
						
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2321 : XX_CERIS_UPDATE_CP_SP.sql '
 
							SELECT	@DIV_START_DT = DIVISION_START_DT
							FROM	XX_CERIS_HIST
							WHERE 	EMPL_ID = @EMPL_ID						

							--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
							IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1 AND @EFFECT_DT > @DIV_START_DT
							BEGIN
								
								--ROLL OLD ORG_ID FORWARD
								UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
								SET		ORG_ID = @PREV_ORG_ID, 
										LAB_GRP_TYPE = @PREV_LAB_GRP_TYPE,
										SEC_ORG_ID = @PREV_SEC_ORG_ID,
										REASON_DESC_2 = @REASON_DESC_2,
										ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
								WHERE 	EMPL_ID = @EMPL_ID
										AND	EFFECT_DT > @PREV_END_DT
										AND	EFFECT_DT < @EFFECT_DT

								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								   BEGIN
									  SET @error_type = 5
									  GOTO BL_ERROR_HANDLER
								   END
							
								--TRACK RETRO TIMESHEET DATA
								INSERT INTO XX_CERIS_RETRO_TS
								(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @PREV_ORG_ID, NULL, @PREV_END_DT+1, @EFFECT_DT-1
						
								SET @SQLServer_error_code = @@ERROR
                                IF @SQLServer_error_code <> 0
                                   BEGIN
                                       SET @error_type = 7
                                       GOTO BL_ERROR_HANDLER
                                   END
							END
							ELSE IF @PREV_END_DT IS NOT NULL
							BEGIN
								--TRACK RETRO TIMESHEET DATA
								INSERT INTO XX_CERIS_RETRO_TS
								(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @ORG_ID, NULL, @EFFECT_DT, @PREV_END_DT
						
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
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @ORG_ID, NULL, @EFFECT_DT, GETDATE()
					
							SET @SQLServer_error_code = @@ERROR
                            IF @SQLServer_error_code <> 0
                               BEGIN
                                   SET @error_type = 7
                                   GOTO BL_ERROR_HANDLER
                               END	
						END
						
						--PROCESS ORG CHANGE
						UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
						SET 	ORG_ID = @ORG_ID,
								LAB_GRP_TYPE = @LAB_GRP_TYPE,
								SEC_ORG_ID = @SEC_ORG_ID,
								REASON_DESC_2 = @REASON_DESC_2,
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
	

					-- else if status or status3 change
					ELSE IF(@REASON_DESC <> NULL OR @S_EMPL_TYPE_CD <> NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'STATUS CHANGE'
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2416 : XX_CERIS_UPDATE_CP_SP.sql '
 
						UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
						SET 	REASON_DESC = @REASON_DESC,
								S_EMPL_TYPE_CD = @S_EMPL_TYPE_CD,
								REASON_DESC_2 = @REASON_DESC_2,
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
	
					-- if exempt change
					ELSE IF (@S_HRLY_SAL_CD <> NULL OR @EXMPT_FL <> NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'EXMPT CHANGE'
					
						--KM EFFECTIVE DATE CHANGES
						--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
						SET @CUR_S_HRLY_SAL_CD = NULL
						SET @CUR_EXMPT_FL = NULL
						SET @PREV_S_HRLY_SAL_CD = NULL
						SET @PREV_EXMPT_FL = NULL

						SET @PREV_END_DT = NULL	
						
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2449 : XX_CERIS_UPDATE_CP_SP.sql '
 
						SELECT  @CUR_S_HRLY_SAL_CD = S_HRLY_SAL_CD,
								@CUR_EXMPT_FL = EXMPT_FL
						FROM    IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID
						AND		EFFECT_DT = @LAST_EFFECT_DT
						
						--KM EFFECTIVE DATE CHANGES
						--IF CURRENT VALUES ARE THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
						--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
						IF ((@CUR_S_HRLY_SAL_CD = @S_HRLY_SAL_CD) AND (@CUR_EXMPT_FL=@EXMPT_FL))
						BEGIN
							SELECT  @PREV_S_HRLY_SAL_CD = S_HRLY_SAL_CD,
									@PREV_EXMPT_FL = EXMPT_FL,
									@PREV_END_DT = END_DT
							FROM 	IMAPS.DELTEK.EMPL_LAB_INFO
							WHERE 	EMPL_ID = @EMPL_ID	
							AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID 
																										AND (S_HRLY_SAL_CD <> @S_HRLY_SAL_CD
																											 OR EXMPT_FL <> @EXMPT_FL) )
													
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2472 : XX_CERIS_UPDATE_CP_SP.sql '
 
							SELECT	@DIV_START_DT = DIVISION_START_DT
							FROM	XX_CERIS_HIST
							WHERE 	EMPL_ID = @EMPL_ID						

							--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
							IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1 AND @EFFECT_DT > @DIV_START_DT AND @EFFECT_DT > @Actuals_EFFECT_DT
							BEGIN							
								--ROLL OLD VALUES FORWARD
								UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
								SET		S_HRLY_SAL_CD = @PREV_S_HRLY_SAL_CD, 
										EXMPT_FL = @PREV_EXMPT_FL,
										REASON_DESC_2 = @REASON_DESC_2,
										ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
								WHERE 	EMPL_ID = @EMPL_ID
									AND	EFFECT_DT > @PREV_END_DT
									AND	EFFECT_DT < @EFFECT_DT
							
								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								   BEGIN
									  SET @error_type = 5
									  GOTO BL_ERROR_HANDLER
								   END

								--TRACK RETRO TIMESHEET DATA
								INSERT INTO XX_CERIS_RETRO_TS
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
								--TRACK RETRO TIMESHEET DATA
								INSERT INTO XX_CERIS_RETRO_TS
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
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
							(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @EXMPT_FL, @EFFECT_DT, GETDATE()
					
							SET @SQLServer_error_code = @@ERROR
							IF @SQLServer_error_code <> 0
							   BEGIN
									SET @error_type = 7	                                               
									GOTO BL_ERROR_HANDLER
							   END
						END
						
						--PROCESS CHANGE
						UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
						SET		EXMPT_FL = @EXMPT_FL,
								S_HRLY_SAL_CD = @S_HRLY_SAL_CD,
								REASON_DESC_2 = @REASON_DESC_2,
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
				ELSE IF(@rows = 0)
				BEGIN
					DECLARE @FRONT_EFFECT_DT datetime,
							@BACK_EFFECT_DT datetime
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2576 : XX_CERIS_UPDATE_CP_SP.sql '
 
					SELECT 	@FRONT_EFFECT_DT = MIN(EFFECT_DT)
					FROM 	IMAPS.DELTEK.EMPL_LAB_INFO
					WHERE 	EMPL_ID = @EMPL_ID
					AND	EFFECT_DT > @EFFECT_DT
	
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2584 : XX_CERIS_UPDATE_CP_SP.sql '
 
					SELECT 	@BACK_EFFECT_DT = MAX(EFFECT_DT)
					FROM	IMAPS.DELTEK.EMPL_LAB_INFO
					WHERE	EMPL_ID = @EMPL_ID
					AND 	EFFECT_DT < @EFFECT_DT

					--if back record exists, update its end date
					IF @BACK_EFFECT_DT IS NOT NULL
					BEGIN
						UPDATE 	IMAPS.DELTEK.EMPL_LAB_INFO
						SET 	END_DT = (@EFFECT_DT - 1),
								ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
						WHERE 	EMPL_ID = @EMPL_ID
							AND	EFFECT_DT = @BACK_EFFECT_DT
					END
					ELSE IF @BACK_EFFECT_DT IS NULL
					BEGIN
						SET @BACK_EFFECT_DT = @FRONT_EFFECT_DT
					END
					


					-- if legacy GLC change
					IF(@REASON_DESC_3 <> NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'LEGACY GLC CHANGE'
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2613 : XX_CERIS_UPDATE_CP_SP.sql '
 
						INSERT INTO IMAPS.DELTEK.EMPL_LAB_INFO
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
						 S_STEP_NO, MGR_EMPL_ID, (@FRONT_EFFECT_DT - 1), SEC_ORG_ID, COMMENTS,
						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, @REASON_DESC_2, @REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
						FROM IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @BACK_EFFECT_DT) --BACK_EFFECT_DT change KM 01/02/07

                        SET @SQLServer_error_code = @@ERROR
                        IF @SQLServer_error_code <> 0
                           BEGIN
                               SET @error_type = 6
                               GOTO BL_ERROR_HANDLER
                           END	

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2650 : XX_CERIS_UPDATE_CP_SP.sql '
 
						UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
						SET 	REASON_DESC_3 = @REASON_DESC_3,
								REASON_DESC_2 = @REASON_DESC_2,
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

					

					-- if Salary or Work Hrs change
					ELSE IF(@HRLY_AMT <> NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'SALARY or HRS CHANGE'
					
						--KM EFFECTIVE DATE CHANGES
						--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
						SET @CUR_HRLY_AMT = NULL
						SET @CUR_SAL_AMT = NULL
						SET @CUR_ANNL_AMT = NULL
						SET @CUR_WORK_YR_HRS_NO = NULL
						SET @CUR_PCT_INCR_RT = NULL
						SET @PREV_HRLY_AMT = NULL
						SET @PREV_SAL_AMT = NULL
						SET @PREV_ANNL_AMT = NULL
						SET @PREV_WORK_YR_HRS_NO = NULL
						SET @PREV_PCT_INCR_RT = NULL

						SET @PREV_END_DT = NULL	
						
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2690 : XX_CERIS_UPDATE_CP_SP.sql '
 
						SELECT  @CUR_HRLY_AMT = HRLY_AMT,
								@CUR_SAL_AMT = SAL_AMT,
								@CUR_ANNL_AMT = ANNL_AMT,
								@CUR_WORK_YR_HRS_NO = WORK_YR_HRS_NO,
								@CUR_PCT_INCR_RT = PCT_INCR_RT
						FROM    IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID
						AND		EFFECT_DT = @LAST_EFFECT_DT
						
						--KM EFFECTIVE DATE CHANGES
						--IF CURRENT VALUES ARE THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
						--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
						IF ((@CUR_HRLY_AMT = @HRLY_AMT) AND (@CUR_ANNL_AMT = @ANNL_AMT) AND (@CUR_SAL_AMT = @SAL_AMT) AND (@CUR_WORK_YR_HRS_NO=@WORK_YR_HRS_NO))
						BEGIN
							SELECT  @PREV_HRLY_AMT = HRLY_AMT,
									@PREV_SAL_AMT = SAL_AMT,
									@PREV_ANNL_AMT = ANNL_AMT,
									@PREV_WORK_YR_HRS_NO = WORK_YR_HRS_NO,
									@PREV_PCT_INCR_RT = PCT_INCR_RT,
									@PREV_END_DT = END_DT
							FROM 	IMAPS.DELTEK.EMPL_LAB_INFO
							WHERE 	EMPL_ID = @EMPL_ID	
							AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID 
																										AND (HRLY_AMT <> @HRLY_AMT
																											 OR SAL_AMT <> @SAL_AMT
																											 OR ANNL_AMT <> @ANNL_AMT
																											 OR WORK_YR_HRS_NO <> @WORK_YR_HRS_NO))												
							SELECT	@DIV_START_DT = DIVISION_START_DT
							FROM	XX_CERIS_HIST
							WHERE 	EMPL_ID = @EMPL_ID						

							--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
							IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1 AND @EFFECT_DT > @DIV_START_DT AND @EFFECT_DT > @Actuals_EFFECT_DT
							BEGIN							
								--ROLL OLD VALUES FORWARD
								UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
								SET		HRLY_AMT = @PREV_HRLY_AMT, 
										SAL_AMT = @PREV_SAL_AMT,
										ANNL_AMT = @PREV_ANNL_AMT,
										WORK_YR_HRS_NO = @PREV_WORK_YR_HRS_NO,
										PCT_INCR_RT = @PREV_PCT_INCR_RT,
										REASON_DESC_2 = @REASON_DESC_2,
										ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
								WHERE 	EMPL_ID = @EMPL_ID
									AND	EFFECT_DT > @PREV_END_DT
									AND	EFFECT_DT < @EFFECT_DT

								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								   BEGIN
									  SET @error_type = 5
									  GOTO BL_ERROR_HANDLER
								   END
							
								--TRACK RETRO TIMESHEET DATA
								INSERT INTO XX_CERIS_RETRO_TS
								(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @PREV_HRLY_AMT, @PREV_END_DT+1, @EFFECT_DT-1
						
								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								   BEGIN
									   SET @error_type = 7
									   GOTO BL_ERROR_HANDLER
								   END
							END
							ELSE IF @FRONT_EFFECT_DT IS NOT NULL  --DR2672 KM
							BEGIN
								--TRACK RETRO TIMESHEET DATA
								INSERT INTO XX_CERIS_RETRO_TS
								(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @HRLY_AMT, @EFFECT_DT, @FRONT_EFFECT_DT --DR2672 KM
						
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
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
							(EMPL_ID, NEW_HRLY_AMT, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @HRLY_AMT, @EFFECT_DT, GETDATE()
					
							SET @SQLServer_error_code = @@ERROR
							IF @SQLServer_error_code <> 0
							   BEGIN
									SET @error_type = 7	                                               
									GOTO BL_ERROR_HANDLER
							   END
						END
						
						--PROCESS CHANGE
						SET @PCT_INCR_RT = 0
						IF @CUR_HRLY_AMT = @HRLY_AMT
						BEGIN
							SET @PCT_INCR_RT = isnull(@CUR_PCT_INCR_RT,0)
						END
						ELSE
						BEGIN
							SET @PCT_INCR_RT = isnull( cast(((@HRLY_AMT - @CUR_HRLY_AMT)/@CUR_HRLY_AMT) as decimal(5,4))  , 0)
						END


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2801 : XX_CERIS_UPDATE_CP_SP.sql '
 
						INSERT INTO IMAPS.DELTEK.EMPL_LAB_INFO
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
						 @EMPL_ID, @EFFECT_DT, S_HRLY_SAL_CD, @HRLY_AMT,
						 @SAL_AMT, @ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
						 ORG_ID, TITLE_DESC, WORK_STATE_CD, STD_EST_HRS,
						 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, @PCT_INCR_RT, REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, (@FRONT_EFFECT_DT - 1), SEC_ORG_ID, COMMENTS,
						 EMPL_CLASS_CD, @WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
						FROM IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @BACK_EFFECT_DT) --BACK_EFFECT_DT change KM 01/02/07

                        SET @SQLServer_error_code = @@ERROR
                        IF @SQLServer_error_code <> 0
                           BEGIN
                               SET @error_type = 6
                               GOTO BL_ERROR_HANDLER
                           END	

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2838 : XX_CERIS_UPDATE_CP_SP.sql '
 
						UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
						SET 	ANNL_AMT = @ANNL_AMT,
								HRLY_AMT = @HRLY_AMT,
								SAL_AMT = @SAL_AMT,
								WORK_YR_HRS_NO = @WORK_YR_HRS_NO,
								PCT_INCR_RT = @PCT_INCR_RT,
								REASON_DESC_2 = @REASON_DESC_2,
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


	
					-- if Work Location change
					ELSE IF(@WORK_STATE_CD <> NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'WORK STATE CHANGE'
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2867 : XX_CERIS_UPDATE_CP_SP.sql '
 
						INSERT INTO IMAPS.DELTEK.EMPL_LAB_INFO
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
						 ORG_ID, TITLE_DESC, @WORK_STATE_CD, STD_EST_HRS,
						 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, (@FRONT_EFFECT_DT - 1), SEC_ORG_ID, COMMENTS,
						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
						FROM IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @BACK_EFFECT_DT) --BACK_EFFECT_DT change KM 01/02/07

                        SET @SQLServer_error_code = @@ERROR
                        IF @SQLServer_error_code <> 0
                           BEGIN
                               SET @error_type = 6
                               GOTO BL_ERROR_HANDLER
                           END	

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2904 : XX_CERIS_UPDATE_CP_SP.sql '
 
						UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
						SET 	WORK_STATE_CD = @WORK_STATE_CD,
								REASON_DESC_2 = @REASON_DESC_2,
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



					-- if LCDB GLC change
					ELSE IF(@GENL_LAB_CAT_CD <> NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'LCDB GLC CHANGE'
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2929 : XX_CERIS_UPDATE_CP_SP.sql '
 
						INSERT INTO IMAPS.DELTEK.EMPL_LAB_INFO
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
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, (@FRONT_EFFECT_DT - 1), SEC_ORG_ID, COMMENTS,
						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
						FROM IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @BACK_EFFECT_DT) --BACK_EFFECT_DT change KM 01/02/07

                        SET @SQLServer_error_code = @@ERROR
                        IF @SQLServer_error_code <> 0
                           BEGIN
                               SET @error_type = 6
                               GOTO BL_ERROR_HANDLER
                           END	

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2966 : XX_CERIS_UPDATE_CP_SP.sql '
 
						UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
						SET 	GENL_LAB_CAT_CD = @GENL_LAB_CAT_CD,
								REASON_DESC_2 = @REASON_DESC_2,
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
					ELSE IF(@TITLE_DESC <> NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'POS CHANGE'
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 2992 : XX_CERIS_UPDATE_CP_SP.sql '
 
						INSERT INTO IMAPS.DELTEK.EMPL_LAB_INFO
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
						FROM	IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE	(EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @BACK_EFFECT_DT) --BACK_EFFECT_DT change KM 01/02/07

						SET @SQLServer_error_code = @@ERROR
						IF @SQLServer_error_code <> 0
						   BEGIN
							   SET @error_type = 6
							   GOTO BL_ERROR_HANDLER
						   END	

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 3029 : XX_CERIS_UPDATE_CP_SP.sql '
 
						UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
						SET 	TITLE_DESC = @TITLE_DESC,
								REASON_DESC_2 = @REASON_DESC_2,
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
					ELSE IF(@ORG_ID <> NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'ORG CHANGE'
					
						--KM EFFECTIVE DATE CHANGES
						--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
						SET @CUR_ORG_ID = NULL
						SET @PREV_ORG_ID = NULL	
						SET @PREV_END_DT = NULL	
						
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 3060 : XX_CERIS_UPDATE_CP_SP.sql '
 
						SELECT  @CUR_ORG_ID = ORG_ID
						FROM    IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID
						AND		EFFECT_DT = @LAST_EFFECT_DT
						
						--KM EFFECTIVE DATE CHANGES
						--IF CURRENT ORG IS THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
						--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
						IF @CUR_ORG_ID = @ORG_ID
						BEGIN
							SELECT 	@PREV_ORG_ID = ORG_ID, 
									@PREV_LAB_GRP_TYPE = LAB_GRP_TYPE,
									@PREV_SEC_ORG_ID = SEC_ORG_ID,
									@PREV_END_DT = END_DT
							FROM 	IMAPS.DELTEK.EMPL_LAB_INFO
							WHERE 	EMPL_ID = @EMPL_ID	
							AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID AND ORG_ID <> @ORG_ID)
						
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 3081 : XX_CERIS_UPDATE_CP_SP.sql '
 
							SELECT	@DIV_START_DT = DIVISION_START_DT
							FROM	XX_CERIS_HIST
							WHERE 	EMPL_ID = @EMPL_ID						

							--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
							IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1 AND @EFFECT_DT > @DIV_START_DT
							BEGIN
								
								--ROLL OLD ORG_ID FORWARD
								UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
								SET		ORG_ID = @PREV_ORG_ID, 
										LAB_GRP_TYPE = @PREV_LAB_GRP_TYPE,
										SEC_ORG_ID = @PREV_SEC_ORG_ID,
										REASON_DESC_2 = @REASON_DESC_2,
										ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
								WHERE 	EMPL_ID = @EMPL_ID
									AND	EFFECT_DT > @PREV_END_DT
									AND	EFFECT_DT < @EFFECT_DT

								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								   BEGIN
									  SET @error_type = 5
									  GOTO BL_ERROR_HANDLER
								   END

								--TRACK RETRO TIMESHEET DATA
								INSERT INTO XX_CERIS_RETRO_TS
								(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @PREV_ORG_ID, NULL, @PREV_END_DT+1, @EFFECT_DT-1
						
								SET @SQLServer_error_code = @@ERROR
                                IF @SQLServer_error_code <> 0
                                   BEGIN
                                       SET @error_type = 7
                                       GOTO BL_ERROR_HANDLER
                                   END
							END
							ELSE IF @FRONT_EFFECT_DT IS NOT NULL  --DR2672 KM
							BEGIN
								--TRACK RETRO TIMESHEET DATA
								INSERT INTO XX_CERIS_RETRO_TS
								(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @ORG_ID, NULL, @EFFECT_DT, @FRONT_EFFECT_DT --DR2672 KM
						
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
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
							(EMPL_ID, NEW_ORG_ID, NEW_GLC, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @ORG_ID, NULL, @EFFECT_DT, GETDATE()
					
							SET @SQLServer_error_code = @@ERROR
                            IF @SQLServer_error_code <> 0
                               BEGIN
                                   SET @error_type = 7
                                   GOTO BL_ERROR_HANDLER
                               END
						END
						
						--PROCESS ORG CHANGE
						INSERT INTO IMAPS.DELTEK.EMPL_LAB_INFO
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
						 STD_EFFECT_AMT, @LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, (@FRONT_EFFECT_DT - 1), @SEC_ORG_ID, COMMENTS,
						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
						FROM IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @BACK_EFFECT_DT) --BACK_EFFECT_DT change KM 01/02/07

                        SET @SQLServer_error_code = @@ERROR
                        IF @SQLServer_error_code <> 0
                           BEGIN
                               SET @error_type = 6
                               GOTO BL_ERROR_HANDLER
                           END	

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 3187 : XX_CERIS_UPDATE_CP_SP.sql '
 
						UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
						SET 	ORG_ID = @ORG_ID,
								LAB_GRP_TYPE = @LAB_GRP_TYPE,
								SEC_ORG_ID = @SEC_ORG_ID,
								REASON_DESC_2 = @REASON_DESC_2,
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
	


					-- else if status3 change
					ELSE IF(@REASON_DESC <> NULL OR @S_EMPL_TYPE_CD <> NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'STATUS CHANGE'
					
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 3214 : XX_CERIS_UPDATE_CP_SP.sql '
 
						INSERT INTO IMAPS.DELTEK.EMPL_LAB_INFO
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
						 STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
						 MODIFIED_BY, TIME_STAMP, PCT_INCR_RT, @REASON_DESC,
						 LAB_LOC_CD, MERIT_PCT_RT, PROMO_PCT_RT, SAL_GRADE_CD,
						 S_STEP_NO, MGR_EMPL_ID, (@FRONT_EFFECT_DT - 1), SEC_ORG_ID, COMMENTS,
						 EMPL_CLASS_CD, WORK_YR_HRS_NO, PERS_ACT_RSN_CD_2, 
						 PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
						 CORP_OFCR_FL, SEASON_EMPL_FL, HIRE_DT_FL, TERM_DT_FL,
						 AA_COMMENTS, TC_TS_SCHED_CD, TC_WORK_SCHED_CD, 1
						FROM IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @BACK_EFFECT_DT) --BACK_EFFECT_DT change KM 01/02/07

                        SET @SQLServer_error_code = @@ERROR
                        IF @SQLServer_error_code <> 0
                           BEGIN
                               SET @error_type = 6
                               GOTO BL_ERROR_HANDLER
                           END

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 3251 : XX_CERIS_UPDATE_CP_SP.sql '
 
						UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
						SET 	REASON_DESC = @REASON_DESC,
								S_EMPL_TYPE_CD = @S_EMPL_TYPE_CD,
								REASON_DESC_2 = @REASON_DESC_2,
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
	
					
					-- if exempt change
					ELSE IF (@S_HRLY_SAL_CD <> NULL OR @EXMPT_FL <> NULL)
					BEGIN
						SET @REASON_DESC_2 = CAST(@in_STATUS_RECORD_NUM as varchar(10)) +  '-' +'EXMPT CHANGE'
					
						--KM EFFECTIVE DATE CHANGES
						--DETERMINE IF THIS IS JUST AN EFFECTIVE DATE CHANGE
						SET @CUR_S_HRLY_SAL_CD = NULL
						SET @CUR_EXMPT_FL = NULL
						SET @PREV_S_HRLY_SAL_CD = NULL
						SET @PREV_EXMPT_FL = NULL

						SET @PREV_END_DT = NULL	
						
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 3285 : XX_CERIS_UPDATE_CP_SP.sql '
 
						SELECT  @CUR_S_HRLY_SAL_CD = S_HRLY_SAL_CD,
								@CUR_EXMPT_FL = EXMPT_FL
						FROM    IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE 	EMPL_ID = @EMPL_ID
						AND		EFFECT_DT = @LAST_EFFECT_DT
						
						--KM EFFECTIVE DATE CHANGES
						--IF CURRENT VALUES ARE THE SAME, THIS IS JUST AN EFFECTIVE DATE CHANGE
						--FIND OUT IF THE EFFECTIVE DATE IS FORWARD OR BACKWARD
						IF ((@CUR_S_HRLY_SAL_CD = @S_HRLY_SAL_CD) AND (@CUR_EXMPT_FL=@EXMPT_FL))
						BEGIN
							SELECT  @PREV_S_HRLY_SAL_CD = S_HRLY_SAL_CD,
									@PREV_EXMPT_FL = EXMPT_FL,
									@PREV_END_DT = END_DT
							FROM 	IMAPS.DELTEK.EMPL_LAB_INFO
							WHERE 	EMPL_ID = @EMPL_ID	
							AND 	EFFECT_DT = (SELECT MAX(EFFECT_DT) FROM IMAPS.DELTEK.EMPL_LAB_INFO WHERE EMPL_ID = @EMPL_ID 
																										AND (S_HRLY_SAL_CD <> @S_HRLY_SAL_CD
																											 OR EXMPT_FL <> @EXMPT_FL) )
													
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 3308 : XX_CERIS_UPDATE_CP_SP.sql '
 
							SELECT	@DIV_START_DT = DIVISION_START_DT
							FROM	XX_CERIS_HIST
							WHERE 	EMPL_ID = @EMPL_ID						

							--IF THE OLD END DATE IS SUPPOSED TO BE MOVED FORWARD
							IF @PREV_END_DT IS NOT NULL AND @PREV_END_DT < @EFFECT_DT - 1 AND @EFFECT_DT > @DIV_START_DT AND @EFFECT_DT > @Actuals_EFFECT_DT
							BEGIN							
								--ROLL OLD VALUES FORWARD
								UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
								SET		S_HRLY_SAL_CD = @PREV_S_HRLY_SAL_CD, 
										EXMPT_FL = @PREV_EXMPT_FL,
										REASON_DESC_2 = @REASON_DESC_2,
										ROWVERSION = ROWVERSION+1,TIME_STAMP = CURRENT_TIMESTAMP, MODIFIED_BY = 'IMAPSSTG' 
								WHERE 	EMPL_ID = @EMPL_ID
									AND	EFFECT_DT > @PREV_END_DT
									AND	EFFECT_DT < @EFFECT_DT

								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								   BEGIN
									  SET @error_type = 5
									  GOTO BL_ERROR_HANDLER
								   END
							
								--TRACK RETRO TIMESHEET DATA
								INSERT INTO XX_CERIS_RETRO_TS
								(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @PREV_EXMPT_FL, @PREV_END_DT+1, @EFFECT_DT-1
						
								SET @SQLServer_error_code = @@ERROR
								IF @SQLServer_error_code <> 0
								   BEGIN
									   SET @error_type = 7
									   GOTO BL_ERROR_HANDLER
								   END
							END
							ELSE IF @FRONT_EFFECT_DT IS NOT NULL  --DR2672 KM
							BEGIN
								--TRACK RETRO TIMESHEET DATA
								INSERT INTO XX_CERIS_RETRO_TS
								(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
								SELECT @EMPL_ID, @EXMPT_FL, @EFFECT_DT, @FRONT_EFFECT_DT --DR2672 KM
						
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
							--TRACK RETRO TIMESHEET DATA
							INSERT INTO XX_CERIS_RETRO_TS
							(EMPL_ID, NEW_EXMPT_FL, EFFECT_DT, END_DT)
							SELECT @EMPL_ID, @EXMPT_FL, @EFFECT_DT, GETDATE()
					
							SET @SQLServer_error_code = @@ERROR
							IF @SQLServer_error_code <> 0
							   BEGIN
									SET @error_type = 7	                                               
									GOTO BL_ERROR_HANDLER
							   END
						END
						
						--PROCESS CHANGE
						INSERT INTO IMAPS.DELTEK.EMPL_LAB_INFO
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
						 @EMPL_ID, @EFFECT_DT, @S_HRLY_SAL_CD, HRLY_AMT,
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
						FROM IMAPS.DELTEK.EMPL_LAB_INFO
						WHERE (EMPL_ID = @EMPL_ID) AND (EFFECT_DT = @BACK_EFFECT_DT) --BACK_EFFECT_DT change KM 01/02/07

                        SET @SQLServer_error_code = @@ERROR
                        IF @SQLServer_error_code <> 0
                           BEGIN
                               SET @error_type = 6
                               GOTO BL_ERROR_HANDLER
                           END

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 3412 : XX_CERIS_UPDATE_CP_SP.sql '
 
						UPDATE	IMAPS.DELTEK.EMPL_LAB_INFO
						SET		EXMPT_FL = @EXMPT_FL,
								S_HRLY_SAL_CD = @S_HRLY_SAL_CD,
								REASON_DESC_2 = @REASON_DESC_2,
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
					@WORK_STATE_CD, @S_HRLY_SAL_CD, @REASON_DESC_3


	
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


--begin CR4885
/*
-- DFLT_TS_REG table updates/inserts
--begin change KM 02/27/05
UPDATE 	IMAPS.DELTEK.DFLT_REG_TS
SET 	GENL_LAB_CAT_CD = empl_lab.GENL_LAB_CAT_CD,
     	CHG_ORG_ID = empl_lab.ORG_ID,
	ROWVERSION = dflt_reg.ROWVERSION+1
FROM 	IMAPS.DELTEK.DFLT_REG_TS as dflt_reg
INNER JOIN 
	IMAPS.DELTEK.EMPL_LAB_INFO AS empl_lab
ON 	(
	dflt_reg.EMPL_ID = empl_lab.EMPL_ID
AND	empl_lab.EFFECT_DT <= GETDATE()
AND	empl_lab.END_DT >= GETDATE()
AND	(empl_lab.GENL_LAB_CAT_CD <> dflt_reg.GENL_LAB_CAT_CD
	OR empl_lab.ORG_ID <> dflt_reg.CHG_ORG_ID)
)
--end change KM 02/27/05
*/
--need this for testing the regular future (not the regular present)
UPDATE 	IMAPS.DELTEK.DFLT_REG_TS
SET 	GENL_LAB_CAT_CD = stg_dflt_reg.GENL_LAB_CAT_CD,
     	CHG_ORG_ID = stg_dflt_reg.CHG_ORG_ID,
		ROWVERSION = dflt_reg.ROWVERSION+1,
		modified_by=suser_sname(),
		time_stamp=current_timestamp
FROM 	IMAPS.DELTEK.DFLT_REG_TS as dflt_reg
INNER JOIN 
		XX_CERIS_CP_DFLT_TS_STG AS stg_dflt_reg
ON 	(
	dflt_reg.EMPL_ID = stg_dflt_reg.EMPL_ID
	AND	(stg_dflt_reg.GENL_LAB_CAT_CD <> dflt_reg.GENL_LAB_CAT_CD
		 OR stg_dflt_reg.CHG_ORG_ID <> dflt_reg.CHG_ORG_ID)
	)
--end CR4885

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
 BEGIN
    SET @error_type = 8
    GOTO BL_ERROR_HANDLER
 END


--CR4885
/* GLC rates no longer used by interface

--BEGIN CHANGE DR-922 04/27/07
DECLARE @ret_code int

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 3515 : XX_CERIS_UPDATE_CP_SP.sql '
 
EXEC @ret_code = XX_RETRORATE_ADD_NEW_REC_SP
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

--ensure previous year rates are not changed
update imaps.deltek.empl_lab_info
set hrly_amt= pglc.genl_avg_rt_amt,
    sal_amt = pglc.genl_avg_rt_amt * (work_yr_hrs_no/52.0),
    annl_amt= pglc.genl_avg_rt_amt * work_yr_hrs_no
from 
imaps.deltek.empl_lab_info eli
inner join
xx_past_genl_lab_cat pglc
on
(
pglc.fy_cd = datepart(year, eli.effect_dt)
and
pglc.genl_lab_cat_cd = eli.genl_lab_Cat_cd
and 
pglc.genl_avg_rt_amt <> eli.hrly_amt
)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
 BEGIN
    SET @error_type = 9
    GOTO BL_ERROR_HANDLER
 END


--ensure current year rates are not changed
UPDATE imaps.deltek.empl_lab_info
SET hrly_amt= glc.genl_avg_rt_amt,
    sal_amt = glc.genl_avg_rt_amt * (work_yr_hrs_no/52.0),
    annl_amt= glc.genl_avg_rt_amt * work_yr_hrs_no
FROM imaps.deltek.empl_lab_info eli
INNER JOIN
imaps.deltek.genl_lab_cat glc
on
(
datepart(year, getdate()) = datepart(year,eli.effect_dt)
and
glc.genl_lab_cat_cd = eli.genl_lab_Cat_cd
and 
glc.genl_avg_rt_amt <> eli.hrly_amt
-- CP600000284_Begin
and
glc.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000284_End
)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
 BEGIN
    SET @error_type = 10
    GOTO BL_ERROR_HANDLER
 END
*/
--legacy GLC rates

--std_est_hrs
update imaps.deltek.empl_lab_info
set std_est_hrs=work_yr_hrs_no
where std_est_hrs<>work_yr_hrs_no

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
 BEGIN
    SET @error_type = 12
    GOTO BL_ERROR_HANDLER
 END

--ensure previous year rates are not changed
update imaps.deltek.empl_lab_info
set hrly_amt= pglc.genl_avg_rt_amt,
    sal_amt = pglc.genl_avg_rt_amt * (work_yr_hrs_no/52.0),
    annl_amt= pglc.genl_avg_rt_amt * work_yr_hrs_no
from 
imaps.deltek.empl_lab_info eli
inner join
xx_past_genl_lab_cat pglc
on
(
pglc.fy_cd = datepart(year, eli.effect_dt)
and
pglc.genl_lab_cat_cd = eli.genl_lab_Cat_cd
and 
pglc.genl_avg_rt_amt <> eli.hrly_amt
)
and
pglc.fy_cd <= '2012'

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
 BEGIN
    SET @error_type = 9
    GOTO BL_ERROR_HANDLER
 END





--BEGIN CR5782
PRINT 'CR5782 - LATE LCDB GLC ASSIGNMENTS UPDATE'

--update ELI records with LCDB GLC
--for employees whose LCDB GLC assignment was late
update imaps.deltek.empl_lab_info
set genl_lab_cat_cd=lcdb.GLC_Code,
	modified_by='IMAPSSTG',
	time_stamp=current_timestamp
from 
imaps.deltek.empl_lab_info eli
inner join
imapsstg.dbo.XX_CERIS_LCDB_EMPL_ASSIGNMENTS_STG lcdb
on
(
	--join on employee
	eli.empl_id=lcdb.serialno
	and
	--ELI after Actuals logical effective date
	eli.effect_dt>=@Actuals_EFFECT_DT
	and
	--ELI effective date before than LCDB GLC StartDate
	eli.effect_dt<lcdb.empglc_startdate 
	and
	--ELI GLC is either 'DEFALT' or legacy GLC
	(
		--ELI GLC is 'DEFALT', but LCDB GLC is no longer 'DEFALT' 
		(eli.genl_lab_cat_cd='DEFALT' and lcdb.GLC_code<>'DEFALT')
		or
		--ELI GLC is legacy GLC
		0<>(select count(1) from xx_past_genl_lab_cat where fy_cd='2012' and genl_lab_cat_cd=eli.genl_lab_cat_cd)
	)
)


SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0
 BEGIN
    SET @error_type = 5
    GOTO BL_ERROR_HANDLER
 END
--END CR5782

RETURN(0)

BL_ERROR_HANDLER:


SET @IMAPS_error_code = 204 -- Attempt to %1 %2 failed.

IF @error_type = 1
   BEGIN
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_CERIS_CP_EMPL_STG'
   END
ELSE IF @error_type = 2
   BEGIN
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_CERIS_CP_EMPL_LAB_STG'
   END
ELSE IF @error_type = 3
   BEGIN
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_CERIS_CP_DFLT_TS_STG'
   END
ELSE IF @error_type = 4
   BEGIN
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'records in table IMAPS.Deltek.EMPL'
   END
ELSE IF @error_type = 5
   BEGIN
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'records in table IMAPS.Deltek.EMPL_LAB_INFO'
   END
ELSE IF @error_type = 6
   BEGIN
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records in table IMAPS.Deltek.EMPL_LAB_INFO'
   END
ELSE IF @error_type = 7
   BEGIN
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records in table XX_CERIS_RETRO_TS'
   END
ELSE IF @error_type = 8
   BEGIN
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'records in table IMAPS.Deltek.DFLT_REG_TS'
   END
ELSE IF @error_type = 9
   BEGIN
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'prior year records in table IMAPS.Deltek.EMPL_LAB_INFO'
   END
ELSE IF @error_type = 10
   BEGIN
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'current year records in table IMAPS.Deltek.EMPL_LAB_INFO'
   END
--BEGIN CHANGE DR-922 04/27/07
ELSE IF @error_type = 11
   BEGIN
      SET @error_msg_placeholder1 = 'call'
      SET @error_msg_placeholder2 = 'XX_RETRORATE_ADD_NEW_REC_SP'
   END
--END CHANGE DR-922 04/27/07
ELSE IF @error_type = 12
   BEGIN
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'std_est_hrs in table IMAPS.Deltek.EMPL_LAB_INFO'
   END

IF @error_type in (5, 6, 7)
   BEGIN
      -- clean up
      CLOSE EMPL_LAB_CURSOR
      DEALLOCATE EMPL_LAB_CURSOR

      CLOSE EMPL_ID_CURSOR
      DEALLOCATE EMPL_ID_CURSOR
   END

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 3754 : XX_CERIS_UPDATE_CP_SP.sql '
 
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









GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


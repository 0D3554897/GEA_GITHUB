USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_INSERT_CP_SP]    Script Date: 02/15/2017 16:26:18 ******/

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_CERIS_INSERT_CP_SP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[XX_CERIS_INSERT_CP_SP]
GO

USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_INSERT_CP_SP]    Script Date: 02/15/2017 16:26:18 ******/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[XX_CERIS_INSERT_CP_SP]
(
@in_STATUS_RECORD_NUM     integer,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS

/************************************************************************************************
Name:       XX_CERIS_INSERT_CP_SP
Author:     KM
Created:    10/18/2005
Purpose:    For new employees, insert records into Costpoint tables IMAPS.DELTEK.EMPL,  
            EMPL_LAB_INFO and DFLT_REG_TS.
            Called by XX_CERIS_RUN_INTERFACE_SP.
Parameters: 
Result Set: None
Notes:

CP600000284 04/15/2008 (BP&S Change Request No. CR1543)
            Apply the Costpoint column COMPANY_ID to distinguish Division 16's data from those
            of Division 22's. There are three instances.

CR4885 - IMAPS CERIS Interface Changes for Actuals - KM - 2012-05-09
DR9307 - gea - 5/8/2017 - Moved and modified misplaced PRINT statement
DR9307 - gea - 5/8/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
CR-11281 TP - 10/30/2019 - Modified for CP71
************************************************************************************************/


BEGIN

-- Constants used as preset values for IMAPS.DELTEK.EMPL columns
 
PRINT '' -- *~^ DR9307
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        BEGIN XX_CERIS_INSERT_CP_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' -- *~^ DR9307
 
DECLARE	@LV_PD_CD		varchar(4),

	@TAXBLE_ENTITY_ID	varchar(10),
	@SSN_ID			varchar(11),
	@S_EMPL_STATUS_CD	varchar(3),
	@UNIT_AMT		decimal(10,4),
	@PREF_NAME		varchar(10),
	@NAME_PRFX_CD		varchar(6),
	@NAME_SFX_CD		varchar(6),
	@NOTES			varchar(254),
	@TS_PD_CD		varchar(4),
	@BIRTH_DT		smalldatetime,
	@CITY_NAME		varchar(25),
	@LN_1_ADR		varchar(30),
	@LN_2_ADR		varchar(30),
	@LN_3_ADR		varchar(30),
	@POSTAL_CD		varchar(10),
	@MODIFIED_BY		varchar(20),
	@TIME_STAMP		smalldatetime,
	@LOCATOR_CD		varchar(6),
	@PRIR_NAME		varchar(25),
	@COMPANY_ID		varchar(10),
	@ELIG_AUTO_PAY_FL	char(1),
	@MGR_EMPL_ID		varchar(12),
	@S_RACE_CD		char(1),
	@PR_SERV_EMPL_ID	varchar(12),
	@COUNTY_NAME		varchar(25),
	@TS_PD_REG_HRS_NO	smallint,
	@PAY_PD_REG_HRS_NO	smallint,
	@DISABLED_FL		char(1),
	@MOS_REVIEW_NO		smallint,
	@CONT_NAME_1		varchar(25),
	@CONT_NAME_2		varchar(25),
	@CONT_PHONE_1		varchar(20),
	@CONT_PHONE_2		varchar(20),
	@CONT_REL_1		varchar(15),
	@CONT_REL_2		varchar(15),
	@UNION_EMPL_FL		char(1),
	@VET_STATUS_S		char(1),
	@VET_STATUS_V		char(1),
	@VET_STATUS_O		char(1),
	@VET_STATUS_R		char(1),
	@ESS_PIN_ID		varchar(120),
	@PIN_UPDATED_FL		char(1),
	@HOME_EMAIL_ID		varchar(60),
	@ROWVERSION		int,			-- calculated

        @SP_NAME                sysname,
        @error_number           int,
        @SQLServer_error_code	int,
        @row_count              int,
        @error_msg_placeholder1 sysname,
        @error_msg_placeholder2 sysname

-- Assign values to constants
SET @SP_NAME = 'XX_CERIS_INSERT_CP_SP'

PRINT 'HERE IN ' + @SP_NAME

SET @LV_PD_CD   =  'NONE'
SET @TAXBLE_ENTITY_ID   =  '1'
SET @SSN_ID   =  '999999999'
SET @S_EMPL_STATUS_CD   =  'ACT'
SET @UNIT_AMT	= .00
SET @PREF_NAME   =  ' '
SET @NAME_PRFX_CD   =  ' '
SET @NAME_SFX_CD   =  ' '
SET @NOTES   =  ' '
SET @TS_PD_CD   =  'WKLY'
SET @BIRTH_DT   =  '01/01/1901'
SET @CITY_NAME   =  ' '
SET @LN_1_ADR   =  ' '
SET @LN_2_ADR   =  ' '
SET @LN_3_ADR   =  ' '
SET @POSTAL_CD   =  ' '
SET @MODIFIED_BY = SUSER_SNAME()
SET @TIME_STAMP	= current_timestamp
SET @LOCATOR_CD   =  ' '
SET @PRIR_NAME   =  ' '
--SET @COMPANY_ID   =  '1' -- CP600000284
SET @ELIG_AUTO_PAY_FL   =  'N'
SET @MGR_EMPL_ID   =  ' '
SET @S_RACE_CD   =  ' '
SET @PR_SERV_EMPL_ID   =  ' '
SET @COUNTY_NAME   =  ' '
SET @TS_PD_REG_HRS_NO = 0
SET @PAY_PD_REG_HRS_NO = 0
SET @DISABLED_FL   =  'N'
SET @MOS_REVIEW_NO = 0
SET @CONT_NAME_1   =  ' '
SET @CONT_NAME_2   =  ' '
SET @CONT_PHONE_1   =  ' '
SET @CONT_PHONE_2   =  ' '
SET @CONT_REL_1   =  ' '
SET @CONT_REL_2   =  ' '
SET @UNION_EMPL_FL   =  'N'
SET @VET_STATUS_S   =  'N'
SET @VET_STATUS_V   =  'N'
SET @VET_STATUS_O   =  'N'
SET @VET_STATUS_R   =  'N'
SET @ESS_PIN_ID   =  ' '
SET @PIN_UPDATED_FL   =  ' '
SET @HOME_EMAIL_ID   =  ' '
SET @ROWVERSION = 0 		--calculated

-- Initialize local variables
SET @error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert'
SET @error_msg_placeholder2 = 'records into table '

PRINT 'Process Stage CERIS3 - Perform direct INSERTs against Costpoint tables ...'

DECLARE @count int

-- CP600000284_Begin

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 181 : XX_CERIS_INSERT_CP_SP.sql '  --DR9307
 
SELECT @COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'CERIS'

-- CP600000284_End

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 193 : XX_CERIS_INSERT_CP_SP.sql '  --DR9307
 
SELECT @count = COUNT(EMPL_ID)
  FROM dbo.XX_CERIS_CP_STG
 WHERE EMPL_ID NOT IN (SELECT EMPL_ID from IMAPS.Deltek.EMPL where COMPANY_ID = @COMPANY_ID) -- CP600000284

IF @count <> 0

BEGIN

PRINT CAST(@count AS VARCHAR) + ' employees are missing from IMAPS.Deltek.EMPL where COMPANY_ID = ' + @COMPANY_ID

PRINT 'DIAGNOSE WITH THIS: SELECT EMPL_ID FROM dbo.XX_CERIS_CP_STG  WHERE EMPL_ID NOT IN (SELECT EMPL_ID from IMAPS.Deltek.EMPL where COMPANY_ID = 16)'

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 208 : XX_CERIS_INSERT_CP_SP.sql '  --DR9307
 
INSERT INTO IMAPS.DELTEK.EMPL
	(EMPL_ID, LV_PD_CD, TAXBLE_ENTITY_ID, SSN_ID,
	 ORIG_HIRE_DT, ADJ_HIRE_DT, S_EMPL_STATUS_CD, 
	 -- UNIT_AMT, Modified for CR-11281
	 SPVSR_NAME, LAST_NAME, FIRST_NAME, MID_NAME,
	 PREF_NAME, NAME_PRFX_CD, NAME_SFX_CD, NOTES, TS_PD_CD,
	 BIRTH_DT, CITY_NAME, LAST_FIRST_NAME, LN_1_ADR, LN_2_ADR,
	 LN_3_ADR, POSTAL_CD, MODIFIED_BY, TIME_STAMP, LOCATOR_CD,
	 PRIR_NAME, COMPANY_ID, ELIG_AUTO_PAY_FL, EMAIL_ID, 
      	MGR_EMPL_ID, S_RACE_CD, PR_SERV_EMPL_ID, 
	 COUNTY_NAME, TS_PD_REG_HRS_NO, PAY_PD_REG_HRS_NO,
	 DISABLED_FL, MOS_REVIEW_NO, CONT_NAME_1, CONT_NAME_2, 
	 CONT_PHONE_1, CONT_PHONE_2, CONT_REL_1, CONT_REL_2, UNION_EMPL_FL,
	 VET_STATUS_S, VET_STATUS_V, VET_STATUS_O, VET_STATUS_R, ESS_PIN_ID,
	 PIN_UPDATED_FL, HOME_EMAIL_ID, ROWVERSION)
  SELECT EMPL_ID, @LV_PD_CD, @TAXBLE_ENTITY_ID, @SSN_ID,
	 ORIG_HIRE_DT, ADJ_HIRE_DT, @S_EMPL_STATUS_CD, 
	 -- @UNIT_AMT, Modified for CR-11281
	 SPVSR_NAME, LAST_NAME, FIRST_NAME, MID_NAME,
	 @PREF_NAME, @NAME_PRFX_CD, @NAME_SFX_CD, @NOTES, @TS_PD_CD,
	 @BIRTH_DT, @CITY_NAME, CAST((LAST_NAME + ',' + FIRST_NAME) AS varchar(25)), @LN_1_ADR, @LN_2_ADR,
	 @LN_3_ADR, @POSTAL_CD, @MODIFIED_BY, @TIME_STAMP, @LOCATOR_CD,
	 @PRIR_NAME, @COMPANY_ID, @ELIG_AUTO_PAY_FL, EMAIL_ID, 
      	 @MGR_EMPL_ID, @S_RACE_CD, @PR_SERV_EMPL_ID,
	 @COUNTY_NAME, @TS_PD_REG_HRS_NO, @PAY_PD_REG_HRS_NO,
	 @DISABLED_FL, @MOS_REVIEW_NO, @CONT_NAME_1, @CONT_NAME_2, 
	 @CONT_PHONE_1, @CONT_PHONE_2, @CONT_REL_1, @CONT_REL_2, @UNION_EMPL_FL,
	 @VET_STATUS_S, @VET_STATUS_V, @VET_STATUS_O, @VET_STATUS_R, @ESS_PIN_ID,
	 @PIN_UPDATED_FL, @HOME_EMAIL_ID, 1
    FROM dbo.XX_CERIS_CP_STG
   WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM IMAPS.Deltek.EMPL where COMPANY_ID = @COMPANY_ID) -- CP600000284
     AND EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)


SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

PRINT 'empl; rowcount first, then error code'
PRINT @row_count
PRINT @SQLServer_error_code

IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_msg_placeholder2 = @error_msg_placeholder2 + 'IMAPS.Deltek.EMPL'
      GOTO BL_ERROR_HANDLER
   END
END

-- Constants used as preset values for IMAPS.Deltek.EMPL_LAB_INFO columns
DECLARE --@EMPL_ID varchar(12),
	@LAST_EFFECT_DT 	smalldatetime,
	@PREV_ORG_ID 		varchar(20),
	@PREV_GENL_LAB_CAT_CD 	varchar(6),
	@PREV_LAB_GRP_TYPE 	varchar(3), 
	@PREV_HRLY_AMT 		decimal(10, 4),
	@EFFECT_DT 		smalldatetime,
	@HRLY_AMT 		decimal(10, 4),
	@SAL_AMT 		decimal(10, 2),
	@ANNL_AMT 		decimal(10, 2),
	@EXMPT_FL 		char(1),
--	@S_EMPL_TYPE_CD 	char(1),
 	@ORG_ID			varchar(20),
	@SEC_ORG_ID 		varchar(20),
	@TITLE_DESC 		varchar(30),
--	@LAB_GRP_TYPE 		varchar(3),
	@GENL_LAB_CAT_CD 	varchar(6),
	@REASON_DESC 		varchar(30),
	@WORK_YR_HRS_NO 	smallint,
	@S_HRLY_SAL_CD		char(1),
	@WORK_STATE_CD		varchar(2),
	@STD_EST_HRS		decimal(14,2),
	@STD_EFFECT_AMT		decimal(10,4),
--	@MODIFIED_BY		varchar(20),
--	@TIME_STAMP		smalldatetime,
	@PCT_INCR_RT		decimal(5,4),		--calculated
	@DETL_JOB_CD		varchar(10),
	@PERS_ACT_RSN_CD	varchar(10),
	@LAB_LOC_CD		varchar(6),
	@MERIT_PCT_RT		decimal(5,4),
	@PROMO_PCT_RT		decimal(5,4),
	@SAL_GRADE_CD		varchar(10),
	@S_STEP_NO		smallint,
	--@MGR_EMPL_ID		varchar(12),
	@END_DT			smalldatetime,
	@COMMENTS		varchar(254),
	@EMPL_CLASS_CD		varchar(12),
	@PERS_ACT_RSN_CD_2	varchar(10),
	@PERS_ACT_RSN_CD_3	varchar(10),
	@REASON_DESC_2		varchar(30),
	@REASON_DESC_3		varchar(30),
	@CORP_OFCR_FL		char(1),
	@SEASON_EMPL_FL		char(1),
	@HIRE_DT_FL		char(1),
	@TERM_DT_FL		char(1),
	@AA_COMMENTS		varchar(254),
	@TC_TS_SCHED_CD		varchar(10),
	@TC_WORK_SCHED_CD	varchar(10)
	
SET @S_HRLY_SAL_CD	 = 'H'
SET @WORK_STATE_CD	 = 'VA'
SET @STD_EST_HRS	 = .00
SET @STD_EFFECT_AMT	 = .0000
SET @PCT_INCR_RT 	 = .0000
SET @DETL_JOB_CD	 = ' ' 
SET @PERS_ACT_RSN_CD	 = ' '
SET @LAB_LOC_CD	 	 = 'NONE'
SET @MERIT_PCT_RT	 = .0000
SET @PROMO_PCT_RT	 = .0000
SET @SAL_GRADE_CD	 = ' '
SET @S_STEP_NO		 = 0
SET @MGR_EMPL_ID	 = ' '
SET @END_DT		 = '2078-12-31' --TO DO, something about this..maybe increase this
--ALSO TERM_DT?? (trigger on insert to empl???)
SET @COMMENTS	 = '' 	--calculated
SET @EMPL_CLASS_CD	 = ' '
SET @PERS_ACT_RSN_CD_2	 = ' '
SET @PERS_ACT_RSN_CD_3	 = ' '
SET @REASON_DESC_2	 = 'NEW EMPLOYEE ENTRY'
SET @REASON_DESC_3	 = ' '
SET @CORP_OFCR_FL	 = 'N'
SET @SEASON_EMPL_FL	 = 'N'
SET @HIRE_DT_FL		 = 'N'
SET @TERM_DT_FL		 = 'N'
SET @AA_COMMENTS	 = ' '
SET @TC_TS_SCHED_CD	 = ' '
SET @TC_WORK_SCHED_CD	 = ' '
SET @TIME_STAMP 	 = current_timestamp

PRINT 'Insert records into Costpoint table IMAPS.Deltek.EMPL_LAB_INFO ...'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 340 : XX_CERIS_INSERT_CP_SP.sql '  --DR9307
 
SELECT @count = COUNT(EMPL_ID) FROM dbo.XX_CERIS_CP_STG
WHERE EMPL_ID NOT IN (SELECT EMPL_ID from IMAPS.DELTEK.EMPL_LAB_INFO)

IF @count <> 0

BEGIN
  
PRINT CAST(@count AS VARCHAR) + ' employees are missing from IMAPS.DELTEK.EMPL_LAB_INFO'  --DR9307 print statement modified

PRINT ' '
PRINT 'BEGIN SQL STATEMENT DEBUG'
PRINT ' '

PRINT 'INSERT INTO IMAPS.DELTEK.EMPL_LAB_INFO
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
	SELECT EMPL_ID, ORIG_HIRE_DT, ~' + CAST(@S_HRLY_SAL_CD AS VARCHAR) + ', HRLY_AMT,
	 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
	 ORG_ID, TITLE_DESC, WORK_STATE_CD, WORK_YR_HRS_NO as STD_EST_HRS,
	 ~' + CAST(@STD_EFFECT_AMT AS VARCHAR) + ', LAB_GRP_TYPE, GENL_LAB_CAT_CD,
	 ~' + CAST(@MODIFIED_BY AS VARCHAR) + ', ~' + CAST(@TIME_STAMP AS VARCHAR) + ', ~' + CAST(@PCT_INCR_RT AS VARCHAR) + ', REASON_DESC,
	 ~' + CAST(@LAB_LOC_CD AS VARCHAR) + ', ~' + CAST(@MERIT_PCT_RT AS VARCHAR) + ', ~' + CAST(@PROMO_PCT_RT AS VARCHAR) + ', ~' + CAST(@SAL_GRADE_CD AS VARCHAR) + ',
	 ~' + CAST(@S_STEP_NO AS VARCHAR) + ', ~' + CAST(@MGR_EMPL_ID AS VARCHAR) + ', ~' + CAST(@END_DT AS VARCHAR) + ', ORG_ID, ~' + CAST(@COMMENTS AS VARCHAR) + ',
	 ~' + CAST(@EMPL_CLASS_CD AS VARCHAR) + ', WORK_YR_HRS_NO, ~' + CAST(@PERS_ACT_RSN_CD_2 AS VARCHAR) + ', 
	 ~' + CAST(@PERS_ACT_RSN_CD_3 AS VARCHAR) + ', ~' + CAST(@REASON_DESC_2 AS VARCHAR) + ', REASON_DESC_3,
	 ~' + CAST(@CORP_OFCR_FL AS VARCHAR) + ', ~' + CAST(@SEASON_EMPL_FL AS VARCHAR) + ', ~' + CAST(@HIRE_DT_FL AS VARCHAR) + ', ~' + CAST(@TERM_DT_FL AS VARCHAR) + ',
	 ~' + CAST(@AA_COMMENTS AS VARCHAR) + ', ~' + CAST(@TC_TS_SCHED_CD AS VARCHAR) + ', ~' + CAST(@TC_WORK_SCHED_CD AS VARCHAR) + ', 1
   FROM dbo.XX_CERIS_CP_STG 
   WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM IMAPS.DELTEK.EMPL_LAB_INFO GROUP BY EMPL_ID)
     AND EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)'	 

PRINT ' '
PRINT 'END SQL STATEMENT DEBUG'
PRINT ' '


 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 388 : XX_CERIS_INSERT_CP_SP.sql '  --DR9307
 
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
  --begin CR4885
  /*
  SELECT EMPL_ID, ORIG_HIRE_DT, @S_HRLY_SAL_CD, HRLY_AMT,
	 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
	 ORG_ID, TITLE_DESC, @WORK_STATE_CD, @STD_EST_HRS,
	 @STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
	 @MODIFIED_BY, @TIME_STAMP, @PCT_INCR_RT, REASON_DESC,
	 @LAB_LOC_CD, @MERIT_PCT_RT, @PROMO_PCT_RT, @SAL_GRADE_CD,
	 @S_STEP_NO, @MGR_EMPL_ID, @END_DT, ORG_ID, @COMMENTS,
	 @EMPL_CLASS_CD, WORK_YR_HRS_NO, @PERS_ACT_RSN_CD_2, 
	 @PERS_ACT_RSN_CD_3, @REASON_DESC_2, @REASON_DESC_3,
	 @CORP_OFCR_FL, @SEASON_EMPL_FL, @HIRE_DT_FL, @TERM_DT_FL,
	 @AA_COMMENTS, @TC_TS_SCHED_CD, @TC_WORK_SCHED_CD, 1
  */
	SELECT EMPL_ID, ORIG_HIRE_DT, @S_HRLY_SAL_CD, HRLY_AMT,
	 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
	 ORG_ID, TITLE_DESC, WORK_STATE_CD, WORK_YR_HRS_NO as STD_EST_HRS,
	 @STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
	 @MODIFIED_BY, @TIME_STAMP, @PCT_INCR_RT, REASON_DESC,
	 @LAB_LOC_CD, @MERIT_PCT_RT, @PROMO_PCT_RT, @SAL_GRADE_CD,
	 @S_STEP_NO, @MGR_EMPL_ID, @END_DT, ORG_ID, @COMMENTS,
	 @EMPL_CLASS_CD, WORK_YR_HRS_NO, @PERS_ACT_RSN_CD_2, 
	 @PERS_ACT_RSN_CD_3, @REASON_DESC_2, REASON_DESC_3,
	 @CORP_OFCR_FL, @SEASON_EMPL_FL, @HIRE_DT_FL, @TERM_DT_FL,
	 @AA_COMMENTS, @TC_TS_SCHED_CD, @TC_WORK_SCHED_CD, 1
  --end CR4885
    FROM dbo.XX_CERIS_CP_STG 
   WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM IMAPS.DELTEK.EMPL_LAB_INFO GROUP BY EMPL_ID)
     AND EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)

SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

PRINT 'empl_lab_info; rowcount first, then error code'
PRINT @row_count
PRINT @SQLServer_error_code

IF @SQLServer_error_code <> 0 OR @row_count = 0
   BEGIN
      SET @error_msg_placeholder2 = @error_msg_placeholder2 + 'IMAPS.Deltek.EMPL_LAB_INFO' 
      GOTO BL_ERROR_HANDLER
   END
END
-- Constants used as preset values for IMAPS.Deltek.DFLT_REG_TS columns


DECLARE @WORK_COMP_CD	varchar(6),
	@PAY_TYPE	varchar(3)

SET @WORK_COMP_CD = 'NONE'
SET @PAY_TYPE = 'R'
SET @LAB_LOC_CD = 'NONE'
SET @TIME_STAMP = current_timestamp

PRINT 'Insert records into Costpoint table IMAPS.Deltek.DFLT_REG_TS ...'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 463 : XX_CERIS_INSERT_CP_SP.sql '  --DR9307
 
SELECT @count = COUNT(EMPL_ID) FROM dbo.XX_CERIS_CP_STG
WHERE EMPL_ID NOT IN (SELECT EMPL_ID from IMAPS.DELTEK.DFLT_REG_TS)

IF @count <> 0
BEGIN

PRINT 'count not equal to zero FOR DFLT_REG_TS'

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 474 : XX_CERIS_INSERT_CP_SP.sql '  --DR9307
 
INSERT INTO IMAPS.DELTEK.DFLT_REG_TS
   (EMPL_ID, GENL_LAB_CAT_CD, WORK_COMP_CD, PAY_TYPE, CHG_ORG_ID,
    LAB_LOC_CD, MODIFIED_BY, TIME_STAMP, ROWVERSION)	
    SELECT EMPL_ID, GENL_LAB_CAT_CD, @WORK_COMP_CD, @PAY_TYPE, ORG_ID,
           @LAB_LOC_CD, @MODIFIED_BY, @TIME_STAMP, 1
      FROM dbo.XX_CERIS_CP_STG
     WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM IMAPS.DELTEK.DFLT_REG_TS)
       AND EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)

SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

PRINT 'dflt_reg_ts; rowcount first, then error code'
PRINT @row_count
PRINT @SQLServer_error_code
 
 
 
IF @SQLServer_error_code <> 0 OR @row_count = 0
   BEGIN
      SET @error_msg_placeholder2 = @error_msg_placeholder2 + 'IMAPS.Deltek.DFLT_REG_TS'
      GOTO BL_ERROR_HANDLER
   END
END

 
PRINT '' -- *~^ DR9307
PRINT '*~^*************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF  XX_CERIS_INSERT_CP_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' -- *~^ DR9307
 
RETURN(0)

BL_ERROR_HANDLER:

 

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @error_number,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)

END




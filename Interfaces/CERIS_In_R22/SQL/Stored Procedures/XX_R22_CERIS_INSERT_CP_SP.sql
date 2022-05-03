USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE ID = object_id(N'[dbo].[XX_R22_CERIS_INSERT_CP_SP]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[XX_R22_CERIS_INSERT_CP_SP]
GO

CREATE PROCEDURE [dbo].[XX_R22_CERIS_INSERT_CP_SP]
(
@in_STATUS_RECORD_NUM     integer,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS

/************************************************************************************************
Name:       XX_R22_CERIS_INSERT_CP_SP
Author:     V Veera
Created:    05/18/2008 
Purpose:    For new employees, insert records into Costpoint tables IMAR.DELTEK.EMPL,  
            EMPL_LAB_INFO and DFLT_REG_TS.
            Called by XX_R22_CERIS_RUN_INTERFACE_SP.
Parameters: 
Result Set: None
Notes:
Modified for -CR-11284 2019-12-05
************************************************************************************************/

BEGIN

-- Constants used as preset values for IMAR.DELTEK.EMPL columns
DECLARE	
	@LV_PD_CD		varchar(4),
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
SET @SP_NAME = 'XX_R22_CERIS_INSERT_CP_SP'

SET @LV_PD_CD   =  'RONE'
SET @TAXBLE_ENTITY_ID   =  '1'
SET @SSN_ID   =  '999999999'
/* Requirement 14: EMP_STATUS_CD is set to inactive for all Div 22 employees.
The default value in Costpoint empl.s_emp_status_cd should be `IN' (inactive) for all new employees loaded into Costpoint.
*/
SET @S_EMPL_STATUS_CD   =  'IN'
SET @UNIT_AMT	= .00
SET @PREF_NAME   =  ' '
SET @NAME_PRFX_CD   =  ' '
SET @NAME_SFX_CD   =  ' '
SET @NOTES   =  ' '

SET @TS_PD_CD   =  'RWK'

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

PRINT 'Process Stage CERIS_R3 - Perform direct INSERTs against Costpoint tables ...'

DECLARE @count int

SELECT @COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'CERIS_R22'

SELECT @count = COUNT(EMPL_ID)
  FROM dbo.XX_R22_CERIS_CP_STG
 WHERE EMPL_ID NOT IN (SELECT EMPL_ID from IMAR.DELTEK.EMPL where COMPANY_ID = @COMPANY_ID) 

IF @count <> 0
BEGIN
INSERT INTO IMAR.DELTEK.EMPL
	(EMPL_ID, LV_PD_CD, TAXBLE_ENTITY_ID, SSN_ID,
	 ORIG_HIRE_DT, ADJ_HIRE_DT, S_EMPL_STATUS_CD, 
	 -- UNIT_AMT, Commented CR-11284
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
	 -- @UNIT_AMT, Commented for CR-11-284
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
    FROM dbo.XX_R22_CERIS_CP_STG
   WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM IMAR.DELTEK.EMPL where COMPANY_ID = @COMPANY_ID) 
     AND EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      SET @error_msg_placeholder2 = @error_msg_placeholder2 + 'IMAR.DELTEK.EMPL'
      GOTO BL_ERROR_HANDLER
   END
END



/*

Requirement 15:	On insert of a new employee, the default value for the employee UDEF for DII certification flag should be `N'.

INSERT INTO IMAR.DELTEK.GENL_UDEF
()

SELECT EMPL_ID, 'N', ''
    FROM dbo.XX_R22_CERIS_CP_STG
   WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM IMAR.DELTEK.EMPL where COMPANY_ID = @COMPANY_ID)
     AND EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)

*/


-- Constants used as preset values for IMAR.DELTEK.EMPL_LAB_INFO columns
DECLARE --@EMPL_ID varchar(12),
	@LAST_EFFECT_DT 		smalldatetime,
	@PREV_ORG_ID 			varchar(20),
	@PREV_GENL_LAB_CAT_CD 	varchar(6),
	@PREV_LAB_GRP_TYPE 		varchar(3), 
	@PREV_HRLY_AMT 			decimal(10, 4),
	@EFFECT_DT 				smalldatetime,
	@HRLY_AMT 				decimal(10, 4),
	@SAL_AMT 				decimal(10, 2),
	@ANNL_AMT 				decimal(10, 2),
	@EXMPT_FL 				char(1),
--	@S_EMPL_TYPE_CD 	char(1),
 	@ORG_ID					varchar(20),
	@SEC_ORG_ID 			varchar(20),
	@TITLE_DESC 			varchar(30),
--	@LAB_GRP_TYPE 			varchar(3),
	@GENL_LAB_CAT_CD 		varchar(6),
	@REASON_DESC 			varchar(30),
	@WORK_YR_HRS_NO 		smallint,
	@S_HRLY_SAL_CD			char(1),
	@WORK_STATE_CD			varchar(2),
	@STD_EST_HRS			decimal(14,2),
	@STD_EFFECT_AMT			decimal(10,4),
--	@MODIFIED_BY			varchar(20),
--	@TIME_STAMP				smalldatetime,
	@PCT_INCR_RT			decimal(5,4),		--calculated
	@DETL_JOB_CD			varchar(10),
	@PERS_ACT_RSN_CD		varchar(10),
	@LAB_LOC_CD				varchar(6),
	@MERIT_PCT_RT			decimal(5,4),
	@PROMO_PCT_RT			decimal(5,4),
	@SAL_GRADE_CD			varchar(10),
	@S_STEP_NO				smallint,
	--@MGR_EMPL_ID			varchar(12),
	@END_DT					smalldatetime,
	@COMMENTS				varchar(254),
	@EMPL_CLASS_CD			varchar(12),
	@PERS_ACT_RSN_CD_2		varchar(10),
	@PERS_ACT_RSN_CD_3		varchar(10),
	@REASON_DESC_2			varchar(30),
	@REASON_DESC_3			varchar(30),
	@CORP_OFCR_FL			char(1),
	@SEASON_EMPL_FL			char(1),
	@HIRE_DT_FL				char(1),
	@TERM_DT_FL				char(1),
	@AA_COMMENTS			varchar(254),
	@TC_TS_SCHED_CD			varchar(10),
	@TC_WORK_SCHED_CD		varchar(10)
	
SET @S_HRLY_SAL_CD	 = 'H'
SET @WORK_STATE_CD	 = 'NY'

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
SET @END_DT				= '2078-12-31'
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

PRINT 'Insert records into Costpoint table IMAR.DELTEK.EMPL_LAB_INFO ...'

SELECT @count = COUNT(EMPL_ID) FROM dbo.XX_R22_CERIS_CP_STG
WHERE EMPL_ID NOT IN (SELECT EMPL_ID from IMAR.DELTEK.EMPL_LAB_INFO)

/* Calculate Hourly, Weekly and Annual amounts are loaded into EMPL_LAB_INFO from XX_R22_CERIS_CP_STG
Also loading STD_EST_HRS i.e. STD_HRS are loaded from XX_R22_CERIS_CP_STG

Requirement 5: Load calculated annual, weekly, and hourly salary 
values into the annl_amt, sal_amt, and hrly_amt columns of the empl_lab_info table respectively.

Requirement 6:	Ensure that hours loaded into std_est_hrs column of empl_lab_info is annual standard hours by multiplying the weekly standard hours provided in the file by 52.

Requirement 14: EMP_STATUS_CD is set to inactive for all Div 22 employees.
The default value in Costpoint empl.s_emp_status_cd should be `IN' (inactive) for all new employees loaded into Costpoint.


*/
IF @count <> 0
BEGIN
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
  SELECT EMPL_ID, ORIG_HIRE_DT, S_HRLY_SAL_CD, HRLY_AMT,
	 SAL_AMT, ANNL_AMT, EXMPT_FL, S_EMPL_TYPE_CD,
	 ORG_ID, TITLE_DESC, @WORK_STATE_CD, WORK_YR_HRS_NO,
	 @STD_EFFECT_AMT, LAB_GRP_TYPE, GENL_LAB_CAT_CD,
	 @MODIFIED_BY, @TIME_STAMP, @PCT_INCR_RT, REASON_DESC,
	 @LAB_LOC_CD, @MERIT_PCT_RT, @PROMO_PCT_RT, @SAL_GRADE_CD,
	 @S_STEP_NO, @MGR_EMPL_ID, @END_DT, ORG_ID, @COMMENTS,
	 EMPL_CLASS_CD, WORK_YR_HRS_NO, @PERS_ACT_RSN_CD_2, 
	 @PERS_ACT_RSN_CD_3, @REASON_DESC_2, @REASON_DESC_3,
	 @CORP_OFCR_FL, @SEASON_EMPL_FL, @HIRE_DT_FL, @TERM_DT_FL,
	 @AA_COMMENTS, @TC_TS_SCHED_CD, @TC_WORK_SCHED_CD, 1
    FROM dbo.XX_R22_CERIS_CP_STG 
   WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM IMAR.DELTEK.EMPL_LAB_INFO GROUP BY EMPL_ID)
     AND EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)

SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

IF @SQLServer_error_code <> 0 OR @row_count = 0
   BEGIN
      SET @error_msg_placeholder2 = @error_msg_placeholder2 + 'IMAR.DELTEK.EMPL_LAB_INFO'
      GOTO BL_ERROR_HANDLER
   END
END
-- Constants used as preset values for IMAR.DELTEK.DFLT_REG_TS columns
DECLARE 
	@WORK_COMP_CD	varchar(6),
	@PAY_TYPE	varchar(3)

SET @WORK_COMP_CD = 'NONE'
SET @PAY_TYPE = 'R'
SET @LAB_LOC_CD = 'NONE'
SET @TIME_STAMP = current_timestamp

PRINT 'Insert records into Costpoint table IMAR.DELTEK.DFLT_REG_TS ...'

SELECT @count = COUNT(EMPL_ID) FROM dbo.XX_R22_CERIS_CP_STG
WHERE EMPL_ID NOT IN (SELECT EMPL_ID from IMAR.DELTEK.DFLT_REG_TS)

IF @count <> 0
BEGIN
INSERT INTO IMAR.DELTEK.DFLT_REG_TS
   (EMPL_ID, GENL_LAB_CAT_CD, WORK_COMP_CD, PAY_TYPE, CHG_ORG_ID,
    LAB_LOC_CD, MODIFIED_BY, TIME_STAMP, ROWVERSION)	
    SELECT EMPL_ID, GENL_LAB_CAT_CD, @WORK_COMP_CD, @PAY_TYPE, ORG_ID,
           @LAB_LOC_CD, @MODIFIED_BY, @TIME_STAMP, 1
      FROM dbo.XX_R22_CERIS_CP_STG
     WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM IMAR.DELTEK.DFLT_REG_TS)
       AND EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_R22_CERIS_VALIDAT_ERRORS)

SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT

IF @SQLServer_error_code <> 0 OR @row_count = 0
   BEGIN
      SET @error_msg_placeholder2 = @error_msg_placeholder2 + 'IMAR.DELTEK.DFLT_REG_TS'
      GOTO BL_ERROR_HANDLER
   END
END

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

IF OBJECT_ID('dbo.XX_R22_DDC_BATCHAUTOADJ_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_DDC_BATCHAUTOADJ_SP
    IF OBJECT_ID('dbo.XX_R22_DDC_BATCHAUTOADJ_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_DDC_BATCHAUTOADJ_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_DDC_BATCHAUTOADJ_SP >>>'
END
go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
CREATE PROC dbo.XX_R22_DDC_BATCHAUTOADJ_SP
  @sTsPdCd            VARCHAR(4),
  @sHourlyFl          VARCHAR(1),
  @sSalaryFl          VARCHAR(1),
  @nDBErrorNum        INT OUT,
  @sProcAction        VARCHAR(100) OUT
--Developed by : Deltek
--Create Date: 08/05/2010
--Created by Rhonda Johnson
--Modified by Tejas Patel : 09/13/2010 Modified rounding function  
--Modified by Tejas Patel : 11/24/2019 for CP71 Upgrade CR-11291
AS
SET NOCOUNT ON
BEGIN
BEGIN TRAN
  DECLARE
    @nRowCount          INT,
    @nPrepCount         INT

  Select @nDBErrorNum = 0

  DELETE FROM dbo.XX_R22_DDC_TS_AUTO_ADJUST_ERRORS
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Delete XX_R22_DDC_TS_AUTO_ADJUST_ERRORS'
    Rollback Tran
    RETURN
  End
  DELETE FROM dbo.XX_R22_DDC_PREPTBL
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Delete XX_R22_DDC_PREPTBL'
    Rollback Tran
    RETURN
  End
  DELETE FROM dbo.XX_R22_DDC_WORKTBL1
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Delete XX_R22_DDC_WORKTBL1'
    Rollback Tran
    RETURN
  End
  DELETE FROM dbo.XX_R22_DDC_WORKTBL2
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Delete XX_R22_DDC_WORKTBL2'
    Rollback Tran
    RETURN
  End

  If @sHourlyFl != 'Y' and @sSalaryFl != 'Y'
  Begin
    INSERT INTO dbo.XX_R22_DDC_TS_AUTO_ADJUST_ERRORS(
    EMPL_ID, TS_DT, S_TS_TYPE_CD, TS_HDR_SEQ_NO, CORRRECTING_REF_DT, ERROR_MSG)
    VALUES (NULL, NULL, NULL, NULL, NULL, 
    'Either salaried or hourly employees must be included.')
    If @@error != 0
    Begin
      Select @nDBErrorNum = @@error
      Select @sProcAction = 'Insert XX_R22_DDC_TS_AUTO_ADJUST_ERRORS'
      Rollback Tran
      RETURN
    End
    COMMIT TRAN
    RETURN
  End

  /* Populate the driver table from the timesheets uploaded into Costpoint last */
  /* Get distinct combinations of TS_DT, EMPL_ID, S_TS_TYPE_CD, TS_HDR_SEQ_NO and CORRECTING_REF_DT */
  /* from staging table XX_R22_IMAPS_TS_PREP_TEMP. Get only R, N and D types */
  INSERT INTO dbo.XX_R22_DDC_PREPTBL(
  TS_DT, EMPL_ID, S_TS_TYPE_CD, TS_HDR_SEQ_NO, CORRECTING_REF_DT, COL_ID_NO)
  SELECT DISTINCT TS_DT, EMPL_ID, S_TS_TYPE_CD, TS_HDR_SEQ_NO, CORRECTING_REF_DT, 1
  FROM IMAPSstg.dbo.XX_R22_IMAPS_TS_PREP_TEMP
  WHERE S_TS_TYPE_CD IN ('R','D','N')
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Insert XX_R22_DDC_PREPTBL'
    Rollback Tran
    RETURN
  End

  /* Validate here that the correcting ref dt is not null for D and N types */
  /* If null, output to error table and exit */
  SELECT @nRowCount = COUNT(*)
  FROM dbo.XX_R22_DDC_PREPTBL
  WHERE CORRECTING_REF_DT IS NULL AND S_TS_TYPE_CD IN ('D','N')
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Select XX_R22_DDC_PREPTBL'
    Rollback Tran
    RETURN
  End
  If @nRowCount > 0
  Begin
    INSERT INTO dbo.XX_R22_DDC_TS_AUTO_ADJUST_ERRORS(
    EMPL_ID, TS_DT, S_TS_TYPE_CD, TS_HDR_SEQ_NO, CORRRECTING_REF_DT, ERROR_MSG)
    SELECT EMPL_ID, TS_DT, S_TS_TYPE_CD, TS_HDR_SEQ_NO, NULL, 
    'Correcting reference date is null.'
    FROM dbo.XX_R22_DDC_PREPTBL
    WHERE CORRECTING_REF_DT IS NULL AND S_TS_TYPE_CD IN ('D','N')
    If @@error != 0
    Begin
      Select @nDBErrorNum = @@error
      Select @sProcAction = 'Insert XX_R22_DDC_TS_AUTO_ADJUST_ERRORS'
      Rollback Tran
      RETURN
    End
    COMMIT TRAN
    RETURN
  End

  /* D and N get changed to C before inserting into Costpoint */
  UPDATE dbo.XX_R22_DDC_PREPTBL SET S_TS_TYPE_CD = 'C' WHERE S_TS_TYPE_CD IN ('D','N')
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Update XX_R22_DDC_PREPTBL'
    Rollback Tran
    RETURN
  End

  /* Validate that all timesheets in PREP table are in TS_HDR */
  /* If not in TS_HDR, output to error table then delete */
  INSERT INTO dbo.XX_R22_DDC_TS_AUTO_ADJUST_ERRORS(
  EMPL_ID, TS_DT, S_TS_TYPE_CD, TS_HDR_SEQ_NO, ERROR_MSG)
  SELECT A.EMPL_ID, A.TS_DT, A.S_TS_TYPE_CD, A.TS_HDR_SEQ_NO,
  'Timesheet does not exist in the Timesheet Header File.'
  FROM   dbo.XX_R22_DDC_PREPTBL A
  LEFT OUTER JOIN IMAR.DELTEK.TS_HDR B
  ON     A.EMPL_ID = B.EMPL_ID
  AND    A.TS_DT = B.TS_DT
  AND    A.S_TS_TYPE_CD = B.S_TS_TYPE_CD
  AND    A.TS_HDR_SEQ_NO = B.TS_HDR_SEQ_NO
  WHERE  B.EMPL_ID IS NULL
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Insert XX_R22_DDC_TS_AUTO_ADJUST_ERRORS'
    Rollback Tran
    RETURN
  End

  /* Remove timesheets from the process if they don't exist in Header File.*/
  DELETE FROM dbo.XX_R22_DDC_PREPTBL
  WHERE NOT EXISTS (
  SELECT * FROM IMAR.DELTEK.TS_HDR AS TS
  WHERE dbo.XX_R22_DDC_PREPTBL.EMPL_ID = TS.EMPL_ID 
  AND dbo.XX_R22_DDC_PREPTBL.TS_DT = TS.TS_DT
  AND dbo.XX_R22_DDC_PREPTBL.S_TS_TYPE_CD = TS.S_TS_TYPE_CD
  AND dbo.XX_R22_DDC_PREPTBL.TS_HDR_SEQ_NO = TS.TS_HDR_SEQ_NO)
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Delete XX_R22_DDC_PREPTBL'
    Rollback Tran
    RETURN
  End

  /* Get auto adj pct from XX_R22_SUB_PD based on SUB_PD_END_DT */
  /* 1 stands for 100%. In the table 80% is expressed as 80 so divide by 100 */
  /* Use TS_DT for R types and CORRECTING_REF_DT for C */
  INSERT INTO dbo.XX_R22_DDC_PREPTBL(
  TS_DT, EMPL_ID, S_TS_TYPE_CD, TS_HDR_SEQ_NO, CORRECTING_REF_DT, AUTOADJ_RT, COL_ID_NO)
  SELECT T1.TS_DT, EMPL_ID, T1.S_TS_TYPE_CD, T1.TS_HDR_SEQ_NO, T1.CORRECTING_REF_DT, 
  CONVERT(NUMERIC(7,3),T2.SPLIT_PER)/100, 2
  FROM dbo.XX_R22_DDC_PREPTBL T1, IMAPSstg.dbo.XX_R22_SUB_PD T2
  WHERE T1.S_TS_TYPE_CD = 'R' AND T1.TS_DT = T2.SUB_PD_END_DT
  AND T1.COL_ID_NO = 1
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Insert XX_R22_DDC_PREPTBL'
    Rollback Tran
    RETURN
  End

  INSERT INTO dbo.XX_R22_DDC_PREPTBL(
  TS_DT, EMPL_ID, S_TS_TYPE_CD, TS_HDR_SEQ_NO, CORRECTING_REF_DT, AUTOADJ_RT, COL_ID_NO)
  SELECT T1.TS_DT, EMPL_ID, T1.S_TS_TYPE_CD, T1.TS_HDR_SEQ_NO, T1.CORRECTING_REF_DT, 
  CONVERT(NUMERIC(7,3),T2.SPLIT_PER)/100, 2 --Modified Tejas Patel 09/13/2010
  FROM dbo.XX_R22_DDC_PREPTBL T1, IMAPSstg.dbo.XX_R22_SUB_PD T2
  WHERE T1.S_TS_TYPE_CD = 'C' AND T1.CORRECTING_REF_DT = T2.SUB_PD_END_DT
  AND T1.COL_ID_NO = 1
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Insert XX_R22_DDC_PREPTBL'
    Rollback Tran
    RETURN
  End

  /* Validate that we got one rate and only one rate */
  /* If not, output to error table and exit */
  SELECT @nPrepCount = COUNT(*)
  FROM dbo.XX_R22_DDC_PREPTBL A
  WHERE A.COL_ID_NO = 1 AND 1 != 
  (SELECT COUNT(*) FROM dbo.XX_R22_DDC_PREPTBL B
  WHERE B.COL_ID_NO = 2 AND A.TS_DT = B.TS_DT AND
  A.EMPL_ID = B.EMPL_ID AND A.S_TS_TYPE_CD = B.S_TS_TYPE_CD AND
  A.TS_HDR_SEQ_NO = B.TS_HDR_SEQ_NO)
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Select XX_R22_DDC_PREPTBL'
    Rollback Tran
    RETURN
  End
  If @nPrepCount != 0
  Begin
    INSERT INTO dbo.XX_R22_DDC_TS_AUTO_ADJUST_ERRORS(
    EMPL_ID, TS_DT, S_TS_TYPE_CD, TS_HDR_SEQ_NO, ERROR_MSG)
    SELECT NULL, NULL, NULL, NULL,
    'Subperiod ending date is either missing or duplicated in XX_R22_SUB_PD.'
    If @@error != 0
    Begin
      Select @nDBErrorNum = @@error
      Select @sProcAction = 'Insert XX_R22_DDC_TS_AUTO_ADJUST_ERRORS'
      Rollback Tran
      RETURN
    End
    COMMIT TRAN
    RETURN
  End

  /*Get rid of original rows keeping new ones with the auto adj rate */
  DELETE FROM dbo.XX_R22_DDC_PREPTBL WHERE COL_ID_NO = 1
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Delete XX_R22_DDC_PREPTBL'
    Rollback Tran
    RETURN
  End

  /* Get timesheet data from Costpoint for timesheets specified in PREPTBL */
  /* Get auto adj pct from PREPTBL */
  /* Set COL_ID_NO = 1 */
  INSERT INTO dbo.XX_R22_DDC_WORKTBL1(
  TS_DT,
  EMPL_ID,
  S_TS_TYPE_CD,
  TS_HDR_SEQ_NO,
  CORRECTING_REF_DT,
  TS_LN_KEY,
  TS_LN_NO,
  PAY_TYPE,
  GENL_LAB_CAT_CD,
  S_TS_LN_TYPE_CD,
  LAB_CST_AMT,
  ENTERED_HRS,
  WORK_COMP_CD,
  LAB_LOC_CD,
  S_CMPUT_MTHD_CD,
  CHG_HRS,
  HRLY_AMT,
  ORG_ID,
  ACCT_ID,
  ORG_ABBRV_CD,
  PROJ_ID,
  PROJ_ABBRV_CD,
  BILL_LAB_CAT_CD,
  REF_STRUC_1_ID,
  REF_STRUC_2_ID,
  NOTES,
  OT_PAY_TYPE_FL,
  CST_ONLY_FL,
  ELI_EFFECT_DT,
  WD_EFFECT_DT,
  TS_LN_UDEF1_FLD,
  TS_LN_UDEF2_FLD,
  TS_LN_UDEF3_FLD,
  TS_LN_UDEF4_FLD,
  PROJ_ACCT_ABBRV_CD,
  RECAST_LN,
  ALLOC_LN,
  RETRO_LN,
  ALLOW_LN,
  WH_STATE_CD,
  WH_LOCAL_CD,
  FRINGE_CD,
  EFFECT_BILL_DT,
  ROWVERSION,
  AUTOADJ_RT,
  COL_ID_NO) 
  SELECT 
  T1.TS_DT,
  T1.EMPL_ID,
  T1.S_TS_TYPE_CD,
  T1.TS_HDR_SEQ_NO,
  P1.CORRECTING_REF_DT,
  T2.TS_LN_KEY,
  T2.TS_LN_NO,
  T2.PAY_TYPE,
  T2.GENL_LAB_CAT_CD,
  T2.S_TS_LN_TYPE_CD,
  T2.LAB_CST_AMT,
  T2.ENTERED_HRS,
  T2.WORK_COMP_CD,
  T2.LAB_LOC_CD,
  T2.S_CMPUT_MTHD_CD,
  T2.CHG_HRS,
  T2.HRLY_AMT,
  T2.ORG_ID,
  T2.ACCT_ID,
  T2.ORG_ABBRV_CD,
  T2.PROJ_ID,
  T2.PROJ_ABBRV_CD,
  T2.BILL_LAB_CAT_CD,
  T2.REF_STRUC_1_ID,
  T2.REF_STRUC_2_ID,
  T2.NOTES,
  T3.OT_PAY_TYPE_FL,
  T3.CST_ONLY_FL,
  T2.ELI_EFFECT_DT,
  T2.WD_EFFECT_DT,
  T2.TS_LN_UDEF1_FLD,
  T2.TS_LN_UDEF2_FLD,
  T2.TS_LN_UDEF3_FLD,
  T2.TS_LN_UDEF4_FLD,
  T2.PROJ_ACCT_ABBRV_CD,
  T2.RECAST_LN,
  T2.ALLOC_LN,
  T2.RETRO_LN,
  T2.ALLOW_LN,
  T2.WH_STATE_CD,
  T2.WH_LOCAL_CD,
  T2.FRINGE_CD,
  T2.EFFECT_BILL_DT,
  T2.ROWVERSION,
  P1.AUTOADJ_RT,
  1 
  FROM dbo.XX_R22_DDC_PREPTBL P1,
  IMAR.DELTEK.TS_HDR T1,
  IMAR.DELTEK.TS_LN T2,
  IMAR.DELTEK.PAY_TYPE T3 
  WHERE P1.S_TS_TYPE_CD = T1.S_TS_TYPE_CD
      AND P1.EMPL_ID = T1.EMPL_ID
      AND P1.TS_DT = T1.TS_DT
      AND P1.TS_HDR_SEQ_NO = T1.TS_HDR_SEQ_NO
  AND T1.TS_PD_CD = @sTsPdCd
  AND T1.POST_SEQ_NO IS NULL 
  AND T1.PR_POSTED_FL = 'N'
  AND T1.PAY_PD_CD IS NULL 
  AND T1.EMPL_ID = T2.EMPL_ID 
  AND T1.TS_DT = T2.TS_DT 
  AND T1.S_TS_TYPE_CD = T2.S_TS_TYPE_CD 
  AND T1.TS_HDR_SEQ_NO = T2.TS_HDR_SEQ_NO 
  AND T2.CHG_HRS != 0 
  AND T2.PAY_TYPE = T3.PAY_TYPE 
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Insert XX_R22_DDC_WORKTBL1. COL_ID_NO = 1.'
    Rollback Tran
    RETURN
  End

  /* Get ELI salary info. Assume processing each individual time sheet. */
  /* Select COL_ID_NO = 1 and insert COL_ID_NO = 2 */
  /* Use TS_DT for R types but CORRECTING_REF_DT for C types */
  INSERT INTO dbo.XX_R22_DDC_WORKTBL1 ( 
  TS_DT,
  EMPL_ID,
  S_TS_TYPE_CD,
  TS_HDR_SEQ_NO,
  CORRECTING_REF_DT,
  TS_LN_KEY,
  TS_LN_NO,
  PAY_TYPE,
  GENL_LAB_CAT_CD,
  S_TS_LN_TYPE_CD,
  LAB_CST_AMT,
  ENTERED_HRS,
  WORK_COMP_CD,
  LAB_LOC_CD,
  S_CMPUT_MTHD_CD,
  CHG_HRS,
  HRLY_AMT,
  ORG_ID,
  ACCT_ID,
  ORG_ABBRV_CD,
  PROJ_ID,
  PROJ_ABBRV_CD,
  BILL_LAB_CAT_CD,
  REF_STRUC_1_ID,
  REF_STRUC_2_ID,
  NOTES,
  OT_PAY_TYPE_FL,
  CST_ONLY_FL,
  AUTOADJ_RT,
  SAL_AMT,
  ELI_EFFECT_DT,
  WD_EFFECT_DT,
  TS_LN_UDEF1_FLD,
  TS_LN_UDEF2_FLD,
  TS_LN_UDEF3_FLD,
  TS_LN_UDEF4_FLD,
  PROJ_ACCT_ABBRV_CD,
  RECAST_LN,
  ALLOC_LN,
  RETRO_LN,
  ALLOW_LN,
  WH_STATE_CD,
  WH_LOCAL_CD,
  FRINGE_CD,
  EFFECT_BILL_DT,
  ROWVERSION,
  TS_PD_CD,
  COL_ID_NO) 
  SELECT 
  T1.TS_DT,
  T1.EMPL_ID,
  T1.S_TS_TYPE_CD,
  T1.TS_HDR_SEQ_NO,
  T1.CORRECTING_REF_DT,
  T1.TS_LN_KEY,
  T1.TS_LN_NO, 
  T1.PAY_TYPE,
  T1.GENL_LAB_CAT_CD,
  T1.S_TS_LN_TYPE_CD,
  T1.LAB_CST_AMT,
  T1.ENTERED_HRS,
  T1.WORK_COMP_CD,
  T1.LAB_LOC_CD,
  T1.S_CMPUT_MTHD_CD,
  T1.CHG_HRS,
  T1.HRLY_AMT,
  T1.ORG_ID,
  T1.ACCT_ID,
  T1.ORG_ABBRV_CD,
  T1.PROJ_ID,
  T1.PROJ_ABBRV_CD,
  T1.BILL_LAB_CAT_CD,
  T1.REF_STRUC_1_ID,
  T1.REF_STRUC_2_ID,
  T1.NOTES,
  T1.OT_PAY_TYPE_FL,
  T1.CST_ONLY_FL,
  T1.AUTOADJ_RT,
  T2.SAL_AMT,
  T1.ELI_EFFECT_DT,
  T1.WD_EFFECT_DT,
  T1.TS_LN_UDEF1_FLD,
  T1.TS_LN_UDEF2_FLD,
  T1.TS_LN_UDEF3_FLD,
  T1.TS_LN_UDEF4_FLD,
  T1.PROJ_ACCT_ABBRV_CD,
  T1.RECAST_LN,
  T1.ALLOC_LN,
  T1.RETRO_LN,
  T1.ALLOW_LN,
  T1.WH_STATE_CD,
  T1.WH_LOCAL_CD,
  T1.FRINGE_CD,
  T1.EFFECT_BILL_DT,
  T1.ROWVERSION,
  T2.S_HRLY_SAL_CD,
  2 
  FROM dbo.XX_R22_DDC_WORKTBL1 T1,
  IMAR.DELTEK.EMPL_LAB_INFO T2 
  WHERE T1.COL_ID_NO = 1 
  AND T1.S_TS_TYPE_CD = 'R'
  AND T1.EMPL_ID = T2.EMPL_ID 
  AND T2.EFFECT_DT = 
  (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO 
  WHERE EMPL_ID = T1.EMPL_ID AND 
  EFFECT_DT <= T1.TS_DT)
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Insert XX_R22_DDC_WORKTBL1. COL_ID_NO = 2'
    Rollback Tran
    RETURN
  End

  INSERT INTO dbo.XX_R22_DDC_WORKTBL1 ( 
  TS_DT,
  EMPL_ID,
  S_TS_TYPE_CD,
  TS_HDR_SEQ_NO,
  CORRECTING_REF_DT,
  TS_LN_KEY,
  TS_LN_NO,
  PAY_TYPE,
  GENL_LAB_CAT_CD,
  S_TS_LN_TYPE_CD,
  LAB_CST_AMT,
  ENTERED_HRS,
  WORK_COMP_CD,
  LAB_LOC_CD,
  S_CMPUT_MTHD_CD,
  CHG_HRS,
  HRLY_AMT,
  ORG_ID,
  ACCT_ID,
  ORG_ABBRV_CD,
  PROJ_ID,
  PROJ_ABBRV_CD,
  BILL_LAB_CAT_CD,
  REF_STRUC_1_ID,
  REF_STRUC_2_ID,
  NOTES,
  OT_PAY_TYPE_FL,
  CST_ONLY_FL,
  AUTOADJ_RT,
  SAL_AMT,
  ELI_EFFECT_DT,
  WD_EFFECT_DT,
  TS_LN_UDEF1_FLD,
  TS_LN_UDEF2_FLD,
  TS_LN_UDEF3_FLD,
  TS_LN_UDEF4_FLD,
  PROJ_ACCT_ABBRV_CD,
  RECAST_LN,
  ALLOC_LN,
  RETRO_LN,
  ALLOW_LN,
  WH_STATE_CD,
  WH_LOCAL_CD,
  FRINGE_CD,
  EFFECT_BILL_DT,
  ROWVERSION,
  TS_PD_CD,
  COL_ID_NO) 
  SELECT 
  T1.TS_DT,
  T1.EMPL_ID,
  T1.S_TS_TYPE_CD,
  T1.TS_HDR_SEQ_NO,
  T1.CORRECTING_REF_DT,
  T1.TS_LN_KEY,
  T1.TS_LN_NO,
  T1.PAY_TYPE,
  T1.GENL_LAB_CAT_CD,
  T1.S_TS_LN_TYPE_CD,
  T1.LAB_CST_AMT,
  T1.ENTERED_HRS,
  T1.WORK_COMP_CD,
  T1.LAB_LOC_CD,
  T1.S_CMPUT_MTHD_CD,
  T1.CHG_HRS,
  T1.HRLY_AMT,
  T1.ORG_ID,
  T1.ACCT_ID,
  T1.ORG_ABBRV_CD,
  T1.PROJ_ID,
  T1.PROJ_ABBRV_CD,
  T1.BILL_LAB_CAT_CD,
  T1.REF_STRUC_1_ID,
  T1.REF_STRUC_2_ID,
  T1.NOTES,
  T1.OT_PAY_TYPE_FL,
  T1.CST_ONLY_FL,
  T1.AUTOADJ_RT,
  T2.SAL_AMT,
  T1.ELI_EFFECT_DT,
  T1.WD_EFFECT_DT,
  T1.TS_LN_UDEF1_FLD,
  T1.TS_LN_UDEF2_FLD,
  T1.TS_LN_UDEF3_FLD,
  T1.TS_LN_UDEF4_FLD,
  T1.PROJ_ACCT_ABBRV_CD,
  T1.RECAST_LN,
  T1.ALLOC_LN,
  T1.RETRO_LN,
  T1.ALLOW_LN,
  T1.WH_STATE_CD,
  T1.WH_LOCAL_CD,
  T1.FRINGE_CD,
  T1.EFFECT_BILL_DT,
  T1.ROWVERSION,
  T2.S_HRLY_SAL_CD,
  2 
  FROM dbo.XX_R22_DDC_WORKTBL1 T1,
  IMAR.DELTEK.EMPL_LAB_INFO T2 
  WHERE T1.COL_ID_NO = 1 
  AND T1.S_TS_TYPE_CD = 'C'
  AND T1.EMPL_ID = T2.EMPL_ID 
  AND T2.EFFECT_DT = 
  (SELECT MAX(EFFECT_DT) FROM IMAR.DELTEK.EMPL_LAB_INFO 
  WHERE EMPL_ID = T1.EMPL_ID AND 
  EFFECT_DT <= T1.CORRECTING_REF_DT)
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Insert XX_R22_DDC_WORKTBL1. COL_ID_NO = 2.'
    Rollback Tran
    RETURN
  End

  /* S_HRLY_SAL_CD was inserted into WORKTBL1 in the TS_PD_CD column */
  /* Select COL_ID_NO = 2 from WORKTBL1 and Set COL_ID_NO = 1 in WORKTBL2 */
  /* Sum hours for each timesheet. Do not include rows where OT_PAY_TYPE_FL = Y. */
  If @sSalaryFl = 'Y'
  Begin
    INSERT INTO dbo.XX_R22_DDC_WORKTBL2 (
    EMPL_ID,
    TS_DT,
    TS_HDR_SEQ_NO,
    S_TS_TYPE_CD,
    TOT_HRS_AMT,
    COL_ID_NO) 
    SELECT 
    T1.EMPL_ID,
    T1.TS_DT,
    T1.TS_HDR_SEQ_NO,
    T1.S_TS_TYPE_CD,
    SUM(T1.CHG_HRS),
    1 
    FROM dbo.XX_R22_DDC_WORKTBL1 T1 
    WHERE T1.COL_ID_NO = 2 
    AND T1.OT_PAY_TYPE_FL = 'N' 
    AND T1.TS_PD_CD != 'H'
    GROUP BY 
    T1.EMPL_ID,
    T1.TS_DT,
    T1.S_TS_TYPE_CD,
    T1.TS_HDR_SEQ_NO
    If @@error != 0
    Begin
      Select @nDBErrorNum = @@error
      Select @sProcAction = 'Insert XX_R22_DDC_WORKTBL2. COL_ID_NO = 1.'
      Rollback Tran
      RETURN
    End
  End

  If @sHourlyFl = 'Y'
  Begin
    INSERT INTO dbo.XX_R22_DDC_WORKTBL2 (
    EMPL_ID,
    TS_DT,
    S_TS_TYPE_CD,
    TS_HDR_SEQ_NO,
    TOT_HRS_AMT,
    COL_ID_NO) 
    SELECT 
    T1.EMPL_ID,
    T1.TS_DT,
    T1.S_TS_TYPE_CD,
    T1.TS_HDR_SEQ_NO,
    SUM(T1.CHG_HRS),
    1 
    FROM 
    dbo.XX_R22_DDC_WORKTBL1 T1 
    WHERE T1.COL_ID_NO = 2 
    AND T1.TS_PD_CD = 'H' 
    AND T1.OT_PAY_TYPE_FL = 'N'
    GROUP BY 
    T1.EMPL_ID,
    T1.TS_DT,
    T1.S_TS_TYPE_CD,
    T1.TS_HDR_SEQ_NO
    If @@error != 0
    Begin
      Select @nDBErrorNum = @@error
      Select @sProcAction = 'Insert XX_R22_DDC_WORKTBL2. COL_ID_NO = 1.'
      Rollback Tran
      RETURN
    End
  End

  /* Get all relevant info on one line (get the TOT_HRS_AMT from TBL2 on each line of TBL1) so new labor cost can be updated */
  /* Insert COL_ID_NO = 3 Select COL_ID_NO = 2 from WORKTBL1 */
  INSERT INTO dbo.XX_R22_DDC_WORKTBL1 ( 
  TS_DT,
  EMPL_ID,
  S_TS_TYPE_CD,
  TS_HDR_SEQ_NO,
  CORRECTING_REF_DT,
  TS_LN_KEY,
  TS_LN_NO,
  PAY_TYPE,
  GENL_LAB_CAT_CD,
  S_TS_LN_TYPE_CD,
  LAB_CST_AMT,
  ENTERED_HRS,
  WORK_COMP_CD,
  LAB_LOC_CD,
  S_CMPUT_MTHD_CD,
  CHG_HRS,
  HRLY_AMT,
  ORG_ID,
  ACCT_ID,
  ORG_ABBRV_CD,
  PROJ_ID,
  PROJ_ABBRV_CD,
  BILL_LAB_CAT_CD,
  REF_STRUC_1_ID,
  REF_STRUC_2_ID,
  NOTES,
  TS_PD_CD,
  OT_PAY_TYPE_FL,
  CST_ONLY_FL,
  AUTOADJ_RT,
  SAL_AMT,
  ELI_EFFECT_DT,
  WD_EFFECT_DT,
  TS_LN_UDEF1_FLD,
  TS_LN_UDEF2_FLD,
  TS_LN_UDEF3_FLD,
  TS_LN_UDEF4_FLD,
  PROJ_ACCT_ABBRV_CD,
  RECAST_LN,
  ALLOC_LN,
  RETRO_LN,
  ALLOW_LN,
  WH_STATE_CD,
  WH_LOCAL_CD,
  FRINGE_CD,
  EFFECT_BILL_DT,
  ROWVERSION,
  TOT_HRS_AMT,
  COL_ID_NO) 
  SELECT 
  T1.TS_DT,
  T1.EMPL_ID,
  T1.S_TS_TYPE_CD,
  T1.TS_HDR_SEQ_NO,
  T1.CORRECTING_REF_DT,
  T1.TS_LN_KEY,
  T1.TS_LN_NO,
  T1.PAY_TYPE,
  T1.GENL_LAB_CAT_CD,
  T1.S_TS_LN_TYPE_CD,
  T1.LAB_CST_AMT,
  T1.ENTERED_HRS,
  T1.WORK_COMP_CD,
  T1.LAB_LOC_CD,
  T1.S_CMPUT_MTHD_CD,
  T1.CHG_HRS,
  T1.HRLY_AMT,
  T1.ORG_ID,
  T1.ACCT_ID,
  T1.ORG_ABBRV_CD,
  T1.PROJ_ID,
  T1.PROJ_ABBRV_CD,
  T1.BILL_LAB_CAT_CD,
  T1.REF_STRUC_1_ID,
  T1.REF_STRUC_2_ID,
  T1.NOTES,
  T1.TS_PD_CD,
  T1.OT_PAY_TYPE_FL,
  T1.CST_ONLY_FL,
  T1.AUTOADJ_RT,
  T1.SAL_AMT,
  T1.ELI_EFFECT_DT,
  T1.WD_EFFECT_DT,
  T1.TS_LN_UDEF1_FLD,
  T1.TS_LN_UDEF2_FLD,
  T1.TS_LN_UDEF3_FLD,
  T1.TS_LN_UDEF4_FLD,
  T1.PROJ_ACCT_ABBRV_CD,
  T1.RECAST_LN,
  T1.ALLOC_LN,
  T1.RETRO_LN,
  T1.ALLOW_LN,
  T1.WH_STATE_CD,
  T1.WH_LOCAL_CD,
  T1.FRINGE_CD,
  T1.EFFECT_BILL_DT,
  T1.ROWVERSION,
  T2.TOT_HRS_AMT,
  3 
  FROM dbo.XX_R22_DDC_WORKTBL1 T1, 
  dbo.XX_R22_DDC_WORKTBL2 T2 
  WHERE T1.COL_ID_NO = 2 
  AND T1.EMPL_ID = T2.EMPL_ID 
  AND T1.TS_DT = T2.TS_DT 
  AND T1.S_TS_TYPE_CD = T2.S_TS_TYPE_CD
  AND T1.TS_HDR_SEQ_NO = T2.TS_HDR_SEQ_NO
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Insert XX_R22_DDC_WORKTBL1. COL_ID_NO = 3.'
    Rollback Tran
    RETURN
  End

  /* Mark row where the total hours are zero. TS_DT_RANGE = '*' */
  UPDATE dbo.XX_R22_DDC_WORKTBL1
  SET TS_DT_RANGE_CD = '*'
  WHERE TOT_HRS_AMT = 0 AND COL_ID_NO = 3 
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Update XX_R22_DDC_WORKTBL1. COL_ID_NO = 3.'
    Rollback Tran
    RETURN
  End

  /* Update labor cost for salaried empls */
  If @sSalaryFl = 'Y'
  Begin
    UPDATE dbo.XX_R22_DDC_WORKTBL1
    SET NEW_LAB_CST_AMT = (CHG_HRS/TOT_HRS_AMT) * SAL_AMT *  AUTOADJ_RT 
    WHERE COL_ID_NO = 3 
    AND TOT_HRS_AMT != 0 
    AND TS_PD_CD != 'H' 
    AND OT_PAY_TYPE_FL = 'N'
    If @@error != 0
    Begin
      Select @nDBErrorNum = @@error
      Select @sProcAction = 'Update XX_R22_DDC_WORKTBL1 for salaried. COL_ID_NO = 3.'
      Rollback Tran
      RETURN
    End
  End

  /* Update labor cost for hourly empls */
  If @sHourlyFl = 'Y'
  Begin
    UPDATE dbo.XX_R22_DDC_WORKTBL1
    SET NEW_LAB_CST_AMT = (CHG_HRS/TOT_HRS_AMT) * SAL_AMT * AUTOADJ_RT 
    WHERE COL_ID_NO = 3 AND 
    TOT_HRS_AMT != 0 AND 
    TS_PD_CD = 'H' 
    AND OT_PAY_TYPE_FL = 'N'
    If @@error != 0
    Begin
      Select @nDBErrorNum = @@error
      Select @sProcAction = 'Update XX_R22_DDC_WORKTBL1 for hourly. COL_ID_NO = 3.'
      Rollback Tran
      RETURN
    End
  End

  /* Insert into WORKTBL2 to determine residuals. Salaried empls */
  /* Insert COL_ID_NO = 2. Select COL_ID_NO = 3 from WORKTBL1 */
  If @sSalaryFl = 'Y'
  Begin
    INSERT INTO dbo.XX_R22_DDC_WORKTBL2 (
    EMPL_ID,
    TS_DT,
    TS_HDR_SEQ_NO,
    S_TS_TYPE_CD,
    RESID_AMT,
    COL_ID_NO) 
    SELECT 
    EMPL_ID,
    TS_DT,
    TS_HDR_SEQ_NO,
    S_TS_TYPE_CD,
    ((SAL_AMT * AUTOADJ_RT) - SUM(NEW_LAB_CST_AMT)),
    2 
    FROM dbo.XX_R22_DDC_WORKTBL1
    WHERE COL_ID_NO = 3 
    AND OT_PAY_TYPE_FL = 'N' 
    AND TS_PD_CD != 'H'
    GROUP BY 
    EMPL_ID,
    TS_DT,
    S_TS_TYPE_CD,
    TS_HDR_SEQ_NO,
    SAL_AMT,
    AUTOADJ_RT 
    If @@error != 0
    Begin
      Select @nDBErrorNum = @@error
      Select @sProcAction = 'Insert XX_R22_DDC_WORKTBL2 for salaried. COL_ID_NO = 2.'
      Rollback Tran
      RETURN
    End
  End

  /* Now do hourly empls */
  If @sHourlyFl = 'Y'
  Begin
    INSERT INTO dbo.XX_R22_DDC_WORKTBL2 (
    EMPL_ID,
    TS_DT,
    S_TS_TYPE_CD,
    TS_HDR_SEQ_NO,
    RESID_AMT,
    COL_ID_NO) 
    SELECT 
    EMPL_ID,
    TS_DT,
    S_TS_TYPE_CD,
    TS_HDR_SEQ_NO,
    ((SAL_AMT * AUTOADJ_RT) - SUM(NEW_LAB_CST_AMT)),
    2 
    FROM dbo.XX_R22_DDC_WORKTBL1
    WHERE COL_ID_NO = 3 
    AND TS_PD_CD = 'H' 
    AND OT_PAY_TYPE_FL = 'N' 
    GROUP BY 
    EMPL_ID,
    TS_DT,
    S_TS_TYPE_CD,
    TS_HDR_SEQ_NO,
    SAL_AMT,
    AUTOADJ_RT 
    If @@error != 0
    Begin
      Select @nDBErrorNum = @@error
      Select @sProcAction = 'Insert XX_R22_DDC_WORKTBL2 for hourly. COL_ID_NO = 2.'
      Rollback Tran
      RETURN
    End
  End

 /* Find the line to apply the residual to. Salaried empls */
 /* Select COL_ID_NO = 3. Insert WORKTBL1 COL_ID_NO = 4 */
  If @sSalaryFl = 'Y'
  Begin
    INSERT INTO dbo.XX_R22_DDC_WORKTBL1 (
    EMPL_ID,
    TS_DT,
    S_TS_TYPE_CD,
    TS_HDR_SEQ_NO,
    TS_LN_KEY,
    COL_ID_NO) 
    SELECT 
    EMPL_ID,
    TS_DT,
    S_TS_TYPE_CD,
    TS_HDR_SEQ_NO,
    MAX(TS_LN_KEY),
    4 
    FROM dbo.XX_R22_DDC_WORKTBL1
    WHERE COL_ID_NO = 3 
    AND TS_PD_CD != 'H' 
    AND OT_PAY_TYPE_FL = 'N' 
    GROUP BY 
    EMPL_ID,
    TS_DT,
    S_TS_TYPE_CD,
    TS_HDR_SEQ_NO
    If @@error != 0
    Begin
      Select @nDBErrorNum = @@error
      Select @sProcAction = 'Insert XX_R22_DDC_WORKTBL1 for salaried. COL_ID_NO = 4.'
      Rollback Tran
      RETURN
    End
  End

 /* Now do hourly */
  If @sHourlyFl = 'Y'
  Begin
    INSERT INTO dbo.XX_R22_DDC_WORKTBL1 (
    EMPL_ID,
    TS_DT,
    S_TS_TYPE_CD,
    TS_HDR_SEQ_NO,
    TS_LN_KEY,
    COL_ID_NO) 
    SELECT 
    EMPL_ID,
    TS_DT,
    S_TS_TYPE_CD,
    TS_HDR_SEQ_NO,
    MAX(TS_LN_KEY),
    4 
    FROM dbo.XX_R22_DDC_WORKTBL1
    WHERE COL_ID_NO = 3 
    AND TS_PD_CD = 'H' 
    AND OT_PAY_TYPE_FL = 'N' 
    GROUP BY 
    EMPL_ID,
    TS_DT,
    S_TS_TYPE_CD,
    TS_HDR_SEQ_NO
    If @@error != 0
    Begin
      Select @nDBErrorNum = @@error
      Select @sProcAction = 'Insert XX_R22_DDC_WORKTBL1 for hourly. COL_ID_NO = 4.'
      Rollback Tran
      RETURN
    End
  End

  /* Insert into work table 2 with COL_ID_NO = 3 to join residuals with max ts_ln_key (WORKTBL2 COL_ID_NO = 2) */
  INSERT INTO dbo.XX_R22_DDC_WORKTBL2 (
  EMPL_ID,
  TS_DT,
  S_TS_TYPE_CD,
  TS_HDR_SEQ_NO,
  TS_LN_KEY,
  RESID_AMT,
  COL_ID_NO) 
  SELECT 
  T1.EMPL_ID,
  T1.TS_DT,
  T1.S_TS_TYPE_CD,
  T1.TS_HDR_SEQ_NO,
  T1.TS_LN_KEY,
  T2.RESID_AMT,
  3 
  FROM dbo.XX_R22_DDC_WORKTBL1 T1, 
  dbo.XX_R22_DDC_WORKTBL2 T2 
  WHERE T1.COL_ID_NO = 4 
  AND T2.COL_ID_NO = 2 
  AND T1.EMPL_ID = T2.EMPL_ID 
  AND T1.TS_DT = T2.TS_DT 
  AND T1.S_TS_TYPE_CD = T2.S_TS_TYPE_CD
  AND T1.TS_HDR_SEQ_NO = T2.TS_HDR_SEQ_NO
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Insert XX_R22_DDC_WORKTBL2. COL_ID_NO = 3.'
    Rollback Tran
    RETURN
  End

  /* Outerjoin WORKTBL1 and WORKTBL2 to get residual amounts in TBL2 into TBL1 on the correct timesheet line. Both COL_ID_NO = 3. */
  INSERT INTO dbo.XX_R22_DDC_WORKTBL1 ( 
  TS_DT,
  EMPL_ID,
  S_TS_TYPE_CD,
  TS_HDR_SEQ_NO,
  CORRECTING_REF_DT,
  TS_LN_KEY,
  TS_LN_NO,
  PAY_TYPE,
  GENL_LAB_CAT_CD,
  S_TS_LN_TYPE_CD,
  LAB_CST_AMT,
  ENTERED_HRS,
  WORK_COMP_CD,
  LAB_LOC_CD,
  S_CMPUT_MTHD_CD,
  CHG_HRS,
  HRLY_AMT,
  ORG_ID,
  ACCT_ID,
  ORG_ABBRV_CD,
  PROJ_ID,
  PROJ_ABBRV_CD,
  BILL_LAB_CAT_CD,
  REF_STRUC_1_ID,
  REF_STRUC_2_ID,
  NOTES,
  OT_PAY_TYPE_FL,
  AUTOADJ_RT,
  SAL_AMT,
  ELI_EFFECT_DT,
  WD_EFFECT_DT,
  TS_LN_UDEF1_FLD,
  TS_LN_UDEF2_FLD,
  TS_LN_UDEF3_FLD,
  TS_LN_UDEF4_FLD,
  PROJ_ACCT_ABBRV_CD,
  RECAST_LN,
  ALLOC_LN,
  RETRO_LN,
  ALLOW_LN,
  WH_STATE_CD,
  WH_LOCAL_CD,
  FRINGE_CD,
  EFFECT_BILL_DT,
  ROWVERSION,
  NEW_LAB_CST_AMT,
  FUT_DEC1,
  TS_DT_RANGE_CD,
  COL_ID_NO) 
  SELECT 
  T1.TS_DT,
  T1.EMPL_ID,
  T1.S_TS_TYPE_CD,
  T1.TS_HDR_SEQ_NO,
  T1.CORRECTING_REF_DT,
  T1.TS_LN_KEY,
  T1.TS_LN_NO,
  T1.PAY_TYPE,
  T1.GENL_LAB_CAT_CD,
  T1.S_TS_LN_TYPE_CD,
  T1.LAB_CST_AMT,
  T1.ENTERED_HRS,
  T1.WORK_COMP_CD,
  T1.LAB_LOC_CD,
  T1.S_CMPUT_MTHD_CD,
  T1.CHG_HRS,
  T1.HRLY_AMT,
  T1.ORG_ID,
  T1.ACCT_ID,
  T1.ORG_ABBRV_CD,
  T1.PROJ_ID,
  T1.PROJ_ABBRV_CD,
  T1.BILL_LAB_CAT_CD,
  T1.REF_STRUC_1_ID,
  T1.REF_STRUC_2_ID,
  T1.NOTES,
  T1.OT_PAY_TYPE_FL,
  T1.AUTOADJ_RT,
  T1.SAL_AMT,
  T1.ELI_EFFECT_DT,
  T1.WD_EFFECT_DT,
  T1.TS_LN_UDEF1_FLD,
  T1.TS_LN_UDEF2_FLD,
  T1.TS_LN_UDEF3_FLD,
  T1.TS_LN_UDEF4_FLD,
  T1.PROJ_ACCT_ABBRV_CD,
  T1.RECAST_LN,
  T1.ALLOC_LN,
  T1.RETRO_LN,
  T1.ALLOW_LN,
  T1.WH_STATE_CD,
  T1.WH_LOCAL_CD,
  T1.FRINGE_CD,
  T1.EFFECT_BILL_DT,
  T1.ROWVERSION,
  T1.NEW_LAB_CST_AMT,
  T2.RESID_AMT,
  T1.TS_DT_RANGE_CD,
  5 
  FROM dbo.XX_R22_DDC_WORKTBL1 T1
  LEFT OUTER JOIN
  dbo.XX_R22_DDC_WORKTBL2 T2
  ON T1.COL_ID_NO = T2.COL_ID_NO
  AND T1.TS_LN_KEY = T2.TS_LN_KEY
  WHERE T1.COL_ID_NO = 3 
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Insert XX_R22_DDC_WORKTBL1. COL_ID_NO = 5.'
    Rollback Tran
    RETURN
  End

  /* Update null residuals */
  UPDATE dbo.XX_R22_DDC_WORKTBL1
  SET FUT_DEC1 = 0 
  WHERE FUT_DEC1 IS NULL 
  AND COL_ID_NO = 5
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Update XX_R22_DDC_WORKTBL1 for null residuals.'
    Rollback Tran
    RETURN
  End

  /* Add residuals to labor cost */
  UPDATE dbo.XX_R22_DDC_WORKTBL1
  SET NEW_LAB_CST_AMT = NEW_LAB_CST_AMT + FUT_DEC1 
  WHERE COL_ID_NO = 5
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Update XX_R22_DDC_WORKTBL1 to add residuals to the labor cost.'
    Rollback Tran
    RETURN
  End

  /* Set new labor cost = old labor cost for overtime pay types */
  UPDATE dbo.XX_R22_DDC_WORKTBL1
  SET NEW_LAB_CST_AMT = LAB_CST_AMT 
  WHERE COL_ID_NO = 5 
  AND OT_PAY_TYPE_FL = 'Y'
  AND NEW_LAB_CST_AMT IS NULL
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Update XX_R22_DDC_WORKTBL1 setting new labor cost for OT pay types.'
    Rollback Tran
    RETURN
  End

  /* Adjust for negative hours. If negative hours appear on C ts, the amount calculated still comes out positive. */
  UPDATE dbo.XX_R22_DDC_WORKTBL1
  SET NEW_LAB_CST_AMT = NEW_LAB_CST_AMT * (-1) 
  WHERE CHG_HRS < 0 
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Update XX_R22_DDC_WORKTBL1 adjusting for negative hours.'
    Rollback Tran
    RETURN
  End

  INSERT INTO dbo.XX_R22_DDC_TS_AUTO_ADJUST_ERRORS(
  EMPL_ID, TS_DT, S_TS_TYPE_CD, TS_HDR_SEQ_NO, CORRRECTING_REF_DT, ERROR_MSG)
  SELECT DISTINCT EMPL_ID, TS_DT, S_TS_TYPE_CD, TS_HDR_SEQ_NO, CORRECTING_REF_DT, 
  'Timesheet has zero total hours. It will not be auto adjusted.'
  FROM dbo.XX_R22_DDC_WORKTBL1
  WHERE COL_ID_NO = 5 
  AND TS_DT_RANGE_CD = '*'
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Insert XX_R22_DDC_TS_AUTO_ADJUST_ERRORS'
    Rollback Tran
    RETURN
  End

  COMMIT TRAN

  BEGIN TRAN
  DELETE FROM IMAR.DELTEK.TS_LN 
  WHERE TS_LN_KEY IN 
  (SELECT TS_LN_KEY 
  FROM dbo.XX_R22_DDC_WORKTBL1
  WHERE COL_ID_NO = 5 
  AND TS_DT_RANGE_CD IS NULL)
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Delete TS_LN'
    Rollback Tran
    RETURN
  End

  INSERT INTO IMAR.DELTEK.TS_LN ( 
  TS_DT,
  EMPL_ID,
  S_TS_TYPE_CD,
  TS_HDR_SEQ_NO,
  TS_LN_KEY,
  TS_LN_NO,
  PAY_TYPE,
  GENL_LAB_CAT_CD,
  S_TS_LN_TYPE_CD,
  LAB_CST_AMT,
  ENTERED_HRS,
  WORK_COMP_CD,
  LAB_LOC_CD,
  S_CMPUT_MTHD_CD,
  CHG_HRS,
  HRLY_AMT,
  PROJ_ID,
  ORG_ID,
  ACCT_ID,
  ORG_ABBRV_CD,
  PROJ_ABBRV_CD,
  BILL_LAB_CAT_CD,
  NOTES,
  REF_STRUC_1_ID,
  REF_STRUC_2_ID,
  ELI_EFFECT_DT,
  WD_EFFECT_DT,
  TS_LN_UDEF1_FLD,
  TS_LN_UDEF2_FLD,
  TS_LN_UDEF3_FLD,
  TS_LN_UDEF4_FLD,
  PROJ_ACCT_ABBRV_CD,
  RECAST_LN,
  ALLOC_LN,
  RETRO_LN,
  ALLOW_LN,
  WH_STATE_CD,
  WH_LOCAL_CD,
  FRINGE_CD,
  EFFECT_BILL_DT,
  MODIFIED_BY,
  TIME_STAMP,
  ROWVERSION,
    /* Added CP71 CR-11291*/
  TRN_CRNCY_DT,
  TRN_LAB_AMT,
  TS_LN_DT,
  TRN_CRNCY_CD,		-- 'USD'
  TRN_TO_EUR_RT,	-- '1.00000'
  EUR_TO_FUNC_RT,	-- '1.00000'
  TRN_TO_EUR_RT_FL	-- 'N'
  /*End CR-11291*/	 
  )

  SELECT 
  T1.TS_DT,
  T1.EMPL_ID,
  T1.S_TS_TYPE_CD,
  T1.TS_HDR_SEQ_NO,
  T1.TS_LN_KEY,
  T1.TS_LN_NO,
  T1.PAY_TYPE,
  T1.GENL_LAB_CAT_CD,
  T1.S_TS_LN_TYPE_CD,
  T1.NEW_LAB_CST_AMT,
  T1.ENTERED_HRS,
  T1.WORK_COMP_CD,
  T1.LAB_LOC_CD,
  T1.S_CMPUT_MTHD_CD,
  T1.CHG_HRS,
  T1.HRLY_AMT,
  T1.PROJ_ID,
  T1.ORG_ID,
  T1.ACCT_ID,
  T1.ORG_ABBRV_CD,
  T1.PROJ_ABBRV_CD,
  T1.BILL_LAB_CAT_CD,
  T1.NOTES,
  T1.REF_STRUC_1_ID,
  T1.REF_STRUC_2_ID,
  T1.ELI_EFFECT_DT,
  T1.WD_EFFECT_DT,
  T1.TS_LN_UDEF1_FLD,
  T1.TS_LN_UDEF2_FLD,
  T1.TS_LN_UDEF3_FLD,
  T1.TS_LN_UDEF4_FLD,
  T1.PROJ_ACCT_ABBRV_CD,
  T1.RECAST_LN,
  T1.ALLOC_LN,
  T1.RETRO_LN,
  T1.ALLOW_LN,
  T1.WH_STATE_CD,
  T1.WH_LOCAL_CD,
  T1.FRINGE_CD,
  T1.EFFECT_BILL_DT,
  'dbo',
  GETDATE(),
  (T1.ROWVERSION + 1) ,
   /* Added CP71 CR-11291*/
  T1.TS_DT,				-- TRN_CRNCY_DT			
  T1.NEW_LAB_CST_AMT,	-- TRN_LAB_AMT 	
  NULL		,			-- TS_LN_DT	
  'USD',				-- TRN_CRNCY_CD 
  1.0000,				-- TRN_TO_EUR_RT 
  1.0000,				-- EUR_TO_FUNC_RT 
  'N'					-- TRN_TO_EUR_RT_FL 
  /* END CR-11291*/
  FROM dbo.XX_R22_DDC_WORKTBL1 T1 
  WHERE T1.COL_ID_NO = 5 
  AND TS_DT_RANGE_CD IS NULL
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Insert TS_LN'
    Rollback Tran
    RETURN
  End

  /* Set the auto adjust rate on the header rows. */
  UPDATE IMAR.DELTEK.TS_HDR
  SET IMAR.DELTEK.TS_HDR.MODIFIED_BY = 'dbo', IMAR.DELTEK.TS_HDR.TIME_STAMP = GETDATE(),
  IMAR.DELTEK.TS_HDR.ROWVERSION = IMAR.DELTEK.TS_HDR.ROWVERSION + 1,
  IMAR.DELTEK.TS_HDR.AUTO_ADJ_PCT_RT = 
 (SELECT DISTINCT dbo.XX_R22_DDC_WORKTBL1.AUTOADJ_RT FROM dbo.XX_R22_DDC_WORKTBL1 
  WHERE dbo.XX_R22_DDC_WORKTBL1.EMPL_ID = IMAR.DELTEK.TS_HDR.EMPL_ID
  AND dbo.XX_R22_DDC_WORKTBL1.S_TS_TYPE_CD = IMAR.DELTEK.TS_HDR.S_TS_TYPE_CD
  AND dbo.XX_R22_DDC_WORKTBL1.TS_DT = IMAR.DELTEK.TS_HDR.TS_DT
  AND dbo.XX_R22_DDC_WORKTBL1.TS_HDR_SEQ_NO = IMAR.DELTEK.TS_HDR.TS_HDR_SEQ_NO
  AND dbo.XX_R22_DDC_WORKTBL1.COL_ID_NO = 5
  AND dbo.XX_R22_DDC_WORKTBL1.TS_DT_RANGE_CD IS NULL) 
  WHERE EXISTS (SELECT 1 FROM dbo.XX_R22_DDC_WORKTBL1 
  WHERE dbo.XX_R22_DDC_WORKTBL1.EMPL_ID = IMAR.DELTEK.TS_HDR.EMPL_ID
  AND dbo.XX_R22_DDC_WORKTBL1.S_TS_TYPE_CD = IMAR.DELTEK.TS_HDR.S_TS_TYPE_CD
  AND dbo.XX_R22_DDC_WORKTBL1.TS_DT = IMAR.DELTEK.TS_HDR.TS_DT
  AND dbo.XX_R22_DDC_WORKTBL1.TS_HDR_SEQ_NO = IMAR.DELTEK.TS_HDR.TS_HDR_SEQ_NO
  AND dbo.XX_R22_DDC_WORKTBL1.COL_ID_NO = 5
  AND dbo.XX_R22_DDC_WORKTBL1.TS_DT_RANGE_CD IS NULL) 
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Update TS_HDR'
    Rollback Tran
    RETURN
  End
  COMMIT TRAN
  
  BEGIN TRAN
  /* Clean up the work tables */
  DELETE FROM dbo.XX_R22_DDC_PREPTBL
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Delete XX_R22_DDC_PREPTBL'
    Rollback Tran
    RETURN
  End
  DELETE FROM dbo.XX_R22_DDC_WORKTBL1
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Delete XX_R22_DDC_WORKTBL1'
    Rollback Tran
    RETURN
  End
  DELETE FROM dbo.XX_R22_DDC_WORKTBL2
  If @@error != 0
  Begin
    Select @nDBErrorNum = @@error
    Select @sProcAction = 'Delete XX_R22_DDC_WORKTBL2'
    Rollback Tran
    RETURN
  End
  COMMIT TRAN
END
RETURN
go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_R22_DDC_BATCHAUTOADJ_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_DDC_BATCHAUTOADJ_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_DDC_BATCHAUTOADJ_SP >>>'
go

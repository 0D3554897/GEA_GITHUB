SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_CERIS_PROCESS_RETRO_GLC_SP    Script Date: 04/14/2006 11:13:38 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_PROCESS_RETRO_GLC_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_CERIS_PROCESS_RETRO_GLC_SP]
GO



/********************** just drop it  to put CC in agreement with PROD   CR 8761












CREATE PROCEDURE dbo.XX_CERIS_PROCESS_RETRO_GLC_SP
(
@in_STATUS_RECORD_NUM     integer,
@in_EMPL_ID		  varchar(12),
@in_NEW_GLC		  varchar(6),
@in_EFFECT_DT		  datetime,
@in_END_DT		  datetime,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS
/*
For Reversals, everything is explicitly copied from the original timesheet
except the LAB_CST_AMT which is recalculated based on the current GLC Rate

For New Timesheets with GLC changes, the LAB_CST_AMT is based on the 
new GLC Rate of the new GLC and the ACCT_ID and ORG are explicitly stated
*/
BEGIN
--NEW GLC, CERIS ts reversal
DECLARE @PROCESSED_FL            char(1),
	@TS_DT                   char(10),
	@FY_CD                   char(6),
	@PD_NO                   char(2),
	@SUB_PD_NO               char(2),
	@S_TS_TYPE_CD            char(2),
	@S_TS_HDR_SEQ_NO	 char(1),
	@NOTES                   varchar(254),
	@CORRECTING_REF_DT       char(10),
	@LAB_CST_AMT		 char(1),

        @SP_NAME                 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @row_count               integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname

-- set local constants
SET @SP_NAME = 'XX_CERIS_PROCESS_RETRO_GLC_SP'

-- initialize local variables
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert'
SET @error_msg_placeholder2 = 'records into table XX_CERIS_RETRO_TS_PREP'

SET @NOTES = CAST(@in_STATUS_RECORD_NUM as varchar(10)) + '-GLC-'
SET @PROCESSED_FL = 'N'
SET @FY_CD = DATEPART(year, GETDATE())
SET @PD_NO = DATEPART(month, GETDATE())

SELECT @SUB_PD_NO = a.SUB_PD_NO 
FROM IMAPS.Deltek.SUB_PD a
WHERE a.SUB_PD_END_DT =
	(SELECT MIN(b.SUB_PD_END_DT)
	FROM  IMAPS.Deltek.SUB_PD b
	WHERE (b.SUB_PD_NO = 2 OR b.SUB_PD_NO = 3)
          AND DATEDIFF(day, GETDATE(), b.SUB_PD_END_DT) >= 0)

SET @TS_DT = CONVERT(char(10), GETDATE(), 120)
SET @S_TS_TYPE_CD = 'R'
SET @S_TS_HDR_SEQ_NO = '9'
SET @CORRECTING_REF_DT = NULL


-- first do history tables


-- insert reversal timesheets
INSERT INTO dbo.XX_CERIS_RETRO_TS_PREP
	(TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
	 SUB_PD_NO, CORRECTING_REF_DT, LAB_CST_AMT,
	 GENL_LAB_CAT_CD, CHG_HRS, WORK_COMP_CD,
	 LAB_LOC_CD, ORG_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, PROJ_ID,
	 ACCT_ID,
	 TS_HDR_SEQ_NO, EFFECT_BILL_DT, NOTES)
SELECT 	 @TS_DT, a.EMPL_ID, @S_TS_TYPE_CD, b.WORK_STATE_CD, @FY_CD, @PD_NO,
	 @SUB_PD_NO, @CORRECTING_REF_DT, 
	 cast((-1.0 * a.CHG_HRS * c.GENL_AVG_RT_AMT * d.PAY_TYPE_FCTR_QTY) as decimal(14,2)),
	 a.GENL_LAB_CAT_CD, cast((-1.0 * a.CHG_HRS) as decimal(14,2)), a.WORK_COMP_CD,
	 a.LAB_LOC_CD, a.ORG_ID, a.BILL_LAB_CAT_CD, a.PROJ_ABBRV_CD, a.PROJ_ID,
	 a.ACCT_ID,
	 @S_TS_HDR_SEQ_NO, CONVERT(char(10), a.EFFECT_BILL_DT, 120),  CAST( (@NOTES + CAST(a.TS_LN_KEY as varchar(10)) + '-n') as char(254))
FROM 	IMAPS.DELTEK.TS_LN_HS a
INNER 	JOIN IMAPS.DELTEK.TS_HDR_HS b
ON 	(
	(a.EMPL_ID = b.EMPL_ID) 
	AND (a.TS_DT = b.TS_DT)
    	AND (a.S_TS_TYPE_CD = b.S_TS_TYPE_CD) 
	AND (a.TS_HDR_SEQ_NO = b.TS_HDR_SEQ_NO))
INNER 	JOIN IMAPS.DELTEK.GENL_LAB_CAT c
ON	(
	a.GENL_LAB_CAT_CD = c.GENL_LAB_CAT_CD
	)
INNER	JOIN IMAPS.DELTEK.PAY_TYPE d
ON	(
	a.PAY_TYPE = d.PAY_TYPE
	)
WHERE   (
	(a.EMPL_ID = @in_EMPL_ID) 
	AND
	(
		(
		(a.TS_DT >= @in_EFFECT_DT)
		AND (a.TS_DT < @in_END_DT)
		AND b.S_TS_TYPE_CD = 'R'
		)
		OR
		(
		b.CORECTING_REF_DT IS NOT NULL
		AND
		(b.CORECTING_REF_DT >= @in_EFFECT_DT)
		AND (b.CORECTING_REF_DT < @in_END_DT)
		AND b.S_TS_TYPE_CD = 'C'
		)
	)
	AND (a.GENL_LAB_CAT_CD <> @in_NEW_GLC)
	AND (a.PAY_TYPE <> 'RO')
	)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

-- insert new timesheets
INSERT INTO dbo.XX_CERIS_RETRO_TS_PREP
	(TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
	 SUB_PD_NO, CORRECTING_REF_DT, LAB_CST_AMT,
	 CHG_HRS, WORK_COMP_CD,
	 LAB_LOC_CD, ORG_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, PROJ_ID,
	 ACCT_ID,
	 TS_HDR_SEQ_NO, EFFECT_BILL_DT, NOTES)
SELECT 	 @TS_DT, a.EMPL_ID, @S_TS_TYPE_CD, b.WORK_STATE_CD, @FY_CD, @PD_NO,
	 @SUB_PD_NO, @CORRECTING_REF_DT, @LAB_CST_AMT,
	 a.CHG_HRS, a.WORK_COMP_CD,
	 a.LAB_LOC_CD, a.ORG_ID, a.BILL_LAB_CAT_CD, a.PROJ_ABBRV_CD, a.PROJ_ID,
	 a.ACCT_ID,
	@S_TS_HDR_SEQ_NO, CONVERT(char(10), a.EFFECT_BILL_DT, 120),  CAST( (@NOTES + CAST(a.TS_LN_KEY as varchar(10)) + '-p') as char(254))
FROM 	IMAPS.DELTEK.TS_LN_HS a
INNER 	JOIN IMAPS.DELTEK.TS_HDR_HS b
ON 	(
	(a.EMPL_ID = b.EMPL_ID) 
	AND (a.TS_DT = b.TS_DT)
    	AND (a.S_TS_TYPE_CD = b.S_TS_TYPE_CD) 
	AND (a.TS_HDR_SEQ_NO = b.TS_HDR_SEQ_NO)
	)
WHERE   (
	(a.EMPL_ID = @in_EMPL_ID) 
	AND
	(
		(
		(a.TS_DT >= @in_EFFECT_DT)
		AND (a.TS_DT < @in_END_DT)
		AND b.S_TS_TYPE_CD = 'R'
		)
		OR
		(
		b.CORECTING_REF_DT IS NOT NULL
		AND
		(b.CORECTING_REF_DT >= @in_EFFECT_DT)
		AND (b.CORECTING_REF_DT < @in_END_DT)
		AND b.S_TS_TYPE_CD = 'C'
		)
	)
	AND (a.GENL_LAB_CAT_CD <> @in_NEW_GLC)
	AND (a.PAY_TYPE <> 'RO')
	)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER





-- then do current month table

-- insert reversal timesheets
INSERT INTO dbo.XX_CERIS_RETRO_TS_PREP
	(TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
	 SUB_PD_NO, CORRECTING_REF_DT, LAB_CST_AMT,
	 GENL_LAB_CAT_CD, CHG_HRS, WORK_COMP_CD,
	 LAB_LOC_CD, ORG_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, PROJ_ID,
	 ACCT_ID,
	 TS_HDR_SEQ_NO, EFFECT_BILL_DT, NOTES)
SELECT 	 @TS_DT, a.EMPL_ID, @S_TS_TYPE_CD, b.WORK_STATE_CD, @FY_CD, @PD_NO,
	 @SUB_PD_NO, @CORRECTING_REF_DT, 
 	 cast((-1.0 * a.CHG_HRS * c.GENL_AVG_RT_AMT * d.PAY_TYPE_FCTR_QTY) as decimal(14,2)),
	 a.GENL_LAB_CAT_CD, cast((-1.0 * a.CHG_HRS) as decimal(14,2)), a.WORK_COMP_CD,
	 a.LAB_LOC_CD, a.ORG_ID, a.BILL_LAB_CAT_CD, a.PROJ_ABBRV_CD, a.PROJ_ID,
	 a.ACCT_ID,
	 @S_TS_HDR_SEQ_NO, CONVERT(char(10), a.EFFECT_BILL_DT, 120),  CAST( (@NOTES + CAST(a.TS_LN_KEY as varchar(10)) + '-n') as char(254))
FROM 	IMAPS.DELTEK.TS_LN a
INNER 	JOIN IMAPS.DELTEK.TS_HDR b
ON 	(
	(a.EMPL_ID = b.EMPL_ID) 
	AND (a.TS_DT = b.TS_DT)
    	AND (a.S_TS_TYPE_CD = b.S_TS_TYPE_CD) 
	AND (a.TS_HDR_SEQ_NO = b.TS_HDR_SEQ_NO))
INNER 	JOIN IMAPS.DELTEK.GENL_LAB_CAT c
ON	(
	a.GENL_LAB_CAT_CD = c.GENL_LAB_CAT_CD
	)
INNER	JOIN IMAPS.DELTEK.PAY_TYPE d
ON	(
	a.PAY_TYPE = d.PAY_TYPE
	)
WHERE   (
	(a.TS_LN_KEY not in (SELECT TS_LN_KEY FROM IMAPS.DELTEK.TS_LN_HS))
	AND
	(a.EMPL_ID = @in_EMPL_ID) 
	AND
	(
		(
		(a.TS_DT >= @in_EFFECT_DT)
		AND (a.TS_DT < @in_END_DT)
		AND b.S_TS_TYPE_CD = 'R'
		)
		OR
		(
		b.CORRECTING_REF_DT IS NOT NULL
		AND
		(b.CORRECTING_REF_DT >= @in_EFFECT_DT)
		AND (b.CORRECTING_REF_DT < @in_END_DT)
		AND b.S_TS_TYPE_CD = 'C'
		)
	)
	AND (a.GENL_LAB_CAT_CD <> @in_NEW_GLC)
	AND (a.PAY_TYPE <> 'RO')
	)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

-- insert new timesheets
INSERT INTO dbo.XX_CERIS_RETRO_TS_PREP
	(TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
	 SUB_PD_NO, CORRECTING_REF_DT, LAB_CST_AMT,
	 CHG_HRS, WORK_COMP_CD,
	 LAB_LOC_CD, ORG_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, PROJ_ID,
	 ACCT_ID,
	 TS_HDR_SEQ_NO, EFFECT_BILL_DT, NOTES)
SELECT 	 @TS_DT, a.EMPL_ID, @S_TS_TYPE_CD, b.WORK_STATE_CD, @FY_CD, @PD_NO,
	 @SUB_PD_NO, @CORRECTING_REF_DT, @LAB_CST_AMT,
	 a.CHG_HRS, a.WORK_COMP_CD,
	 a.LAB_LOC_CD, a.ORG_ID, a.BILL_LAB_CAT_CD, a.PROJ_ABBRV_CD, a.PROJ_ID,
	 a.ACCT_ID,
	 @S_TS_HDR_SEQ_NO, CONVERT(char(10), a.EFFECT_BILL_DT, 120), CAST( (@NOTES + CAST(a.TS_LN_KEY as varchar(10)) + '-p') as char(254))
FROM 	IMAPS.DELTEK.TS_LN a
INNER 	JOIN IMAPS.DELTEK.TS_HDR b
ON 	(
	(a.EMPL_ID = b.EMPL_ID) 
	AND (a.TS_DT = b.TS_DT)
    	AND (a.S_TS_TYPE_CD = b.S_TS_TYPE_CD) 
	AND (a.TS_HDR_SEQ_NO = b.TS_HDR_SEQ_NO)
	)
WHERE   (
	(a.EMPL_ID = @in_EMPL_ID) 
	AND
	(a.TS_LN_KEY not in (SELECT TS_LN_KEY FROM IMAPS.DELTEK.TS_LN_HS))
	AND
	(
		(
		(a.TS_DT >= @in_EFFECT_DT)
		AND (a.TS_DT < @in_END_DT)
		AND b.S_TS_TYPE_CD = 'R'
		)
		OR
		(
		b.CORRECTING_REF_DT IS NOT NULL
		AND
		(b.CORRECTING_REF_DT >= @in_EFFECT_DT)
		AND (b.CORRECTING_REF_DT < @in_END_DT)
		AND b.S_TS_TYPE_CD = 'C'
		)
	)
	AND (a.GENL_LAB_CAT_CD <> @in_NEW_GLC)
	AND (a.PAY_TYPE <> 'RO')
	)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER



RETURN(0)

BL_ERROR_HANDLER:

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_number,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)

END









*********************/



GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


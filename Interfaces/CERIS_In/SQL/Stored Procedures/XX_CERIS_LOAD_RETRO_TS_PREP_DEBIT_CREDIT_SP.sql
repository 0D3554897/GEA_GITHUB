USE [IMAPSStg]
GO

IF OBJECT_ID('XX_CERIS_LOAD_RETRO_TS_PREP_DEBIT_CREDIT_SP') IS NOT NULL
begin
    DROP PROCEDURE [dbo].[XX_CERIS_LOAD_RETRO_TS_PREP_DEBIT_CREDIT_SP]
end
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_LOAD_RETRO_TS_PREP_DEBIT_CREDIT_SP]    Script Date: 02/10/2013 12:10:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[XX_CERIS_LOAD_RETRO_TS_PREP_DEBIT_CREDIT_SP]
(
@in_STATUS_RECORD_NUM     integer,
@in_EMPL_ID		  varchar(12),
@in_START_DT	  datetime,
@in_END_DT		  datetime,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS

/***********************************************************************************************
Name:       XX_CERIS_LOAD_RETRO_TS_PREP_DEBIT_CREDIT_SP
Author:     KM
Created:    05/2012

Purpose: 

CR4885 - IMAPS CERIS Interface Changes for Actuals - KM - 2012-05-25
CR5968 - we need to leverage CERIS retro timesheet process to create debits/credits
************************************************************************************************/

BEGIN
DECLARE @PROCESSED_FL            char(1),
	@TS_DT                   char(10),
	@FY_CD                   char(6),
	@PD_NO                   char(2),
	@SUB_PD_NO               char(2),
	@NOTES                   varchar(254),
	@LAB_CST_AMT		 char(1),

        @SP_NAME                 sysname,
        @DIV_16_COMPANY_ID       varchar(10),
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @row_count               integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname

-- set local constants
SET @SP_NAME = 'XX_CERIS_LOAD_RETRO_TS_PREP_DEBIT_CREDIT_SP'

-- initialize local variables
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert'
SET @error_msg_placeholder2 = 'records into table XX_CERIS_RETRO_TS_PREP'

SET @LAB_CST_AMT = '0'
SET @PROCESSED_FL = 'N'

SET @FY_CD = DATEPART(year, GETDATE())
SET @PD_NO = DATEPART(month, GETDATE())
SET @TS_DT = CONVERT(char(10), GETDATE(), 120)


SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'CERIS'


SET @NOTES = CAST(@in_STATUS_RECORD_NUM as varchar(10))+'-CERIS-'

SELECT @SUB_PD_NO = a.SUB_PD_NO 
FROM IMAPS.Deltek.SUB_PD a
WHERE a.SUB_PD_END_DT =
	(SELECT MIN(b.SUB_PD_END_DT)
	FROM  IMAPS.Deltek.SUB_PD b
	WHERE (b.SUB_PD_NO = 2 OR b.SUB_PD_NO = 3)
          AND DATEDIFF(day, GETDATE(), b.SUB_PD_END_DT) >= 0)


--first do history table (posted timesheets)

-- insert reversal timesheets
INSERT INTO dbo.XX_CERIS_RETRO_TS_PREP
	(TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, 
	 FY_CD, PD_NO, SUB_PD_NO, 
	 CORRECTING_REF_DT, 

	 /*Reverse out as-is*/ 
     LAB_CST_AMT, PAY_TYPE,

	 GENL_LAB_CAT_CD, CHG_HRS, 
	 WORK_COMP_CD, LAB_LOC_CD, ORG_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, PROJ_ID, ACCT_ID,
	 TS_HDR_SEQ_NO, EFFECT_BILL_DT, NOTES)
SELECT 	 @TS_DT, ln.EMPL_ID, 'N', hdr.WORK_STATE_CD, 
	 @FY_CD, @PD_NO, @SUB_PD_NO, 
	 ISNULL( CONVERT(char(10), hdr.CORECTING_REF_DT, 120) , CONVERT(char(10), hdr.TS_DT, 120)),

	/*Reverse out as-is*/ 
	 sum(cast((-1.0 * ln.LAB_CST_AMT) as decimal(14,2))),
	 ln.PAY_TYPE,

	 ln.GENL_LAB_CAT_CD, sum(cast((-1.0 * ln.CHG_HRS) as decimal(14,2))), 
	 ln.WORK_COMP_CD, ln.LAB_LOC_CD, ln.ORG_ID, ln.BILL_LAB_CAT_CD, ln.PROJ_ABBRV_CD, ln.PROJ_ID, ln.ACCT_ID,
	 NULL, CONVERT(char(10), ln.EFFECT_BILL_DT, 120), CAST( (@NOTES + CAST(max(ln.TS_LN_KEY) as varchar(10)) + '-n') as char(254))
FROM 	IMAPS.DELTEK.TS_LN_HS ln
INNER 	JOIN IMAPS.DELTEK.TS_HDR_HS hdr
ON 	(
	(ln.EMPL_ID = hdr.EMPL_ID) 
	AND (ln.TS_DT = hdr.TS_DT)
    	AND (ln.S_TS_TYPE_CD = hdr.S_TS_TYPE_CD) 
	AND (ln.TS_HDR_SEQ_NO = hdr.TS_HDR_SEQ_NO)
-- CP600000284_begin
        AND (hdr.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000284_end
        )
INNER	JOIN IMAPS.DELTEK.PAY_TYPE d
ON	(
	ln.PAY_TYPE = d.PAY_TYPE
	)
WHERE   (
	(ln.EMPL_ID = @in_EMPL_ID) 
	AND
	(
		(
		(ln.TS_DT >= @in_START_DT)
		AND (ln.TS_DT <= @in_END_DT)
		AND hdr.S_TS_TYPE_CD = 'R'
		)
		OR
		(
		hdr.CORECTING_REF_DT IS NOT NULL
		AND
		(hdr.CORECTING_REF_DT >= @in_START_DT)
		AND (hdr.CORECTING_REF_DT <= @in_END_DT)
		AND hdr.S_TS_TYPE_CD in ('C','N','D')
		)
	)
	/*CR1541 - NonZero Pay Types - Standby*/
	AND (ln.PAY_TYPE not in (SELECT RETRO_PAY_TYPE FROM XX_RETRORATE_PAY_TYPES) )
	)
group by
ln.EMPL_ID, hdr.WORK_STATE_CD, 
ISNULL( CONVERT(char(10), hdr.CORECTING_REF_DT, 120) , CONVERT(char(10), hdr.TS_DT, 120)),
ln.PAY_TYPE,
ln.GENL_LAB_CAT_CD, 
ln.WORK_COMP_CD, ln.LAB_LOC_CD, ln.ORG_ID, ln.BILL_LAB_CAT_CD, ln.PROJ_ABBRV_CD, ln.PROJ_ID, ln.ACCT_ID,
ln.EFFECT_BILL_DT
having
sum(cast((-1.0 * ln.CHG_HRS) as decimal(14,2)))
<>
0


SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

-- insert new timesheets
INSERT INTO dbo.XX_CERIS_RETRO_TS_PREP
	(TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, 
	 FY_CD, PD_NO, SUB_PD_NO, 
	 CORRECTING_REF_DT, 

	 /*Let CP calculate cost*/ 
     LAB_CST_AMT, PAY_TYPE,

	 GENL_LAB_CAT_CD, CHG_HRS, 
	 WORK_COMP_CD, LAB_LOC_CD, ORG_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, PROJ_ID, ACCT_ID,
	 TS_HDR_SEQ_NO, EFFECT_BILL_DT, NOTES)
SELECT 	 @TS_DT, ln.EMPL_ID, 'D', hdr.WORK_STATE_CD, 
	 @FY_CD, @PD_NO, @SUB_PD_NO, 
	 ISNULL( CONVERT(char(10), hdr.CORECTING_REF_DT, 120) , CONVERT(char(10), hdr.TS_DT, 120)),

	/*Let CP calculate cost*/
	 @LAB_CST_AMT, ln.PAY_TYPE,

	 ln.GENL_LAB_CAT_CD, sum(cast((ln.CHG_HRS) as decimal(14,2))), 
	 ln.WORK_COMP_CD, ln.LAB_LOC_CD, ln.ORG_ID, ln.BILL_LAB_CAT_CD, ln.PROJ_ABBRV_CD, ln.PROJ_ID, ln.ACCT_ID,
	 NULL, CONVERT(char(10), ln.EFFECT_BILL_DT, 120), CAST( (@NOTES + CAST(max(ln.TS_LN_KEY) as varchar(10)) + '-p') as char(254))

FROM 	IMAPS.DELTEK.TS_LN_HS ln
INNER 	JOIN IMAPS.DELTEK.TS_HDR_HS hdr
ON 	(
	(ln.EMPL_ID = hdr.EMPL_ID) 
	AND (ln.TS_DT = hdr.TS_DT)
    	AND (ln.S_TS_TYPE_CD = hdr.S_TS_TYPE_CD) 
	AND (ln.TS_HDR_SEQ_NO = hdr.TS_HDR_SEQ_NO)
-- CP600000284_begin
        AND (hdr.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000284_end
        )
WHERE   (
	(ln.EMPL_ID = @in_EMPL_ID) 
	AND
	(
		(
		(ln.TS_DT >= @in_START_DT)
		AND (ln.TS_DT <= @in_END_DT)
		AND hdr.S_TS_TYPE_CD = 'R'
		)
		OR
		(
		hdr.CORECTING_REF_DT IS NOT NULL
		AND
		(hdr.CORECTING_REF_DT >= @in_START_DT)
		AND (hdr.CORECTING_REF_DT <= @in_END_DT)
		AND hdr.S_TS_TYPE_CD in ('C','N','D')
		)
	)
	/*CR1541 - NonZero Pay Types - Standby*/
	AND (ln.PAY_TYPE not in (SELECT RETRO_PAY_TYPE FROM XX_RETRORATE_PAY_TYPES) )
	)
group by
ln.EMPL_ID, hdr.WORK_STATE_CD, 
ISNULL( CONVERT(char(10), hdr.CORECTING_REF_DT, 120) , CONVERT(char(10), hdr.TS_DT, 120)),
ln.PAY_TYPE,
ln.GENL_LAB_CAT_CD, 
ln.WORK_COMP_CD, ln.LAB_LOC_CD, ln.ORG_ID, ln.BILL_LAB_CAT_CD, ln.PROJ_ABBRV_CD, ln.PROJ_ID, ln.ACCT_ID,
ln.EFFECT_BILL_DT
having
sum(cast((ln.CHG_HRS) as decimal(14,2)))
<>
0

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER




--then do import tables (non-posted timesheets)

-- insert reversal timesheets
INSERT INTO dbo.XX_CERIS_RETRO_TS_PREP
	(TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, 
	 FY_CD, PD_NO, SUB_PD_NO, 
	 CORRECTING_REF_DT, 

	/*Reverse out as-is*/
    LAB_CST_AMT, PAY_TYPE,

	 GENL_LAB_CAT_CD, CHG_HRS, 
	 WORK_COMP_CD, LAB_LOC_CD, ORG_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, PROJ_ID, ACCT_ID,
	 TS_HDR_SEQ_NO, EFFECT_BILL_DT, NOTES)
SELECT 	 @TS_DT, ln.EMPL_ID, 'N', hdr.WORK_STATE_CD, 
	 @FY_CD, @PD_NO, @SUB_PD_NO, 
	 ISNULL( CONVERT(char(10), hdr.CORRECTING_REF_DT, 120) , CONVERT(char(10), hdr.TS_DT, 120)), 

	/*Reverse out as-is*/
	 sum(cast((-1.0 * ln.LAB_CST_AMT) as decimal(14,2))),
	ln.PAY_TYPE,	

	 ln.GENL_LAB_CAT_CD, sum(cast((-1.0 * ln.CHG_HRS) as decimal(14,2))), 
	 ln.WORK_COMP_CD, ln.LAB_LOC_CD, ln.ORG_ID, ln.BILL_LAB_CAT_CD, ln.PROJ_ABBRV_CD, ln.PROJ_ID, ln.ACCT_ID,
	 NULL, CONVERT(char(10), ln.EFFECT_BILL_DT, 120), CAST( (@NOTES + CAST(max(ln.TS_LN_KEY) as varchar(10)) + '-n') as char(254))
FROM 	IMAPS.DELTEK.TS_LN ln
INNER 	JOIN IMAPS.DELTEK.TS_HDR hdr
ON 	(
	(ln.EMPL_ID = hdr.EMPL_ID) 
	AND (ln.TS_DT = hdr.TS_DT)
    	AND (ln.S_TS_TYPE_CD = hdr.S_TS_TYPE_CD) 
	AND (ln.TS_HDR_SEQ_NO = hdr.TS_HDR_SEQ_NO)
-- CP600000284_begin
        AND (hdr.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000284_end
        )
INNER	JOIN IMAPS.DELTEK.PAY_TYPE d
ON	(
	ln.PAY_TYPE = d.PAY_TYPE
	)
WHERE   (
	(hdr.POST_SEQ_NO IS NULL)
	AND
	(ln.EMPL_ID = @in_EMPL_ID) 
	AND
	(
		(
		(ln.TS_DT >= @in_START_DT)
		AND (ln.TS_DT <= @in_END_DT)
		AND hdr.S_TS_TYPE_CD = 'R'
		)
		OR
		(
		hdr.CORRECTING_REF_DT IS NOT NULL
		AND
		(hdr.CORRECTING_REF_DT >= @in_START_DT)
		AND (hdr.CORRECTING_REF_DT <= @in_END_DT)
		AND hdr.S_TS_TYPE_CD in ('C','N','D')
		)
	)
	/*CR1541 - NonZero Pay Types - Standby*/
	AND (ln.PAY_TYPE not in (SELECT RETRO_PAY_TYPE FROM XX_RETRORATE_PAY_TYPES) )
	)
group by
ln.EMPL_ID, hdr.WORK_STATE_CD, 
ISNULL( CONVERT(char(10), hdr.CORRECTING_REF_DT, 120) , CONVERT(char(10), hdr.TS_DT, 120)),
ln.PAY_TYPE,
ln.GENL_LAB_CAT_CD, 
ln.WORK_COMP_CD, ln.LAB_LOC_CD, ln.ORG_ID, ln.BILL_LAB_CAT_CD, ln.PROJ_ABBRV_CD, ln.PROJ_ID, ln.ACCT_ID,
ln.EFFECT_BILL_DT
having
sum(cast((-1.0 * ln.CHG_HRS) as decimal(14,2)))
<>
0

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

-- insert new timesheets
INSERT INTO dbo.XX_CERIS_RETRO_TS_PREP
	(TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, 
	 FY_CD, PD_NO, SUB_PD_NO, 
	 CORRECTING_REF_DT, 

	/*Let CP calculate cost*/
    LAB_CST_AMT, PAY_TYPE,

	 GENL_LAB_CAT_CD, CHG_HRS, 
	 WORK_COMP_CD, LAB_LOC_CD, ORG_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, PROJ_ID, ACCT_ID,
	 TS_HDR_SEQ_NO, EFFECT_BILL_DT, NOTES)
SELECT 	 @TS_DT, ln.EMPL_ID, 'D', hdr.WORK_STATE_CD, 
	 @FY_CD, @PD_NO, @SUB_PD_NO, 
	 ISNULL( CONVERT(char(10), hdr.CORRECTING_REF_DT, 120) , CONVERT(char(10), hdr.TS_DT, 120)), 

	/*Let CP calculate cost*/
	 @LAB_CST_AMT, ln.PAY_TYPE,

	 ln.GENL_LAB_CAT_CD, sum(cast((ln.CHG_HRS) as decimal(14,2))), 
	 ln.WORK_COMP_CD, ln.LAB_LOC_CD, ln.ORG_ID, ln.BILL_LAB_CAT_CD, ln.PROJ_ABBRV_CD, ln.PROJ_ID, ln.ACCT_ID,
	 NULL, CONVERT(char(10), ln.EFFECT_BILL_DT, 120), CAST( (@NOTES + CAST(max(ln.TS_LN_KEY) as varchar(10)) + '-p') as char(254))

FROM 	IMAPS.DELTEK.TS_LN ln
INNER 	JOIN IMAPS.DELTEK.TS_HDR hdr
ON 	(
	(ln.EMPL_ID = hdr.EMPL_ID) 
	AND (ln.TS_DT = hdr.TS_DT)
    	AND (ln.S_TS_TYPE_CD = hdr.S_TS_TYPE_CD) 
	AND (ln.TS_HDR_SEQ_NO = hdr.TS_HDR_SEQ_NO)
-- CP600000284_begin
        AND (hdr.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000284_end
        )
WHERE   (
	(hdr.POST_SEQ_NO IS NULL)
	AND
	(ln.EMPL_ID = @in_EMPL_ID) 
	AND
	(
		(
		(ln.TS_DT >= @in_START_DT)
		AND (ln.TS_DT <= @in_END_DT)
		AND hdr.S_TS_TYPE_CD = 'R'
		)
		OR
		(
		hdr.CORRECTING_REF_DT IS NOT NULL
		AND
		(hdr.CORRECTING_REF_DT >= @in_START_DT)
		AND (hdr.CORRECTING_REF_DT <= @in_END_DT)
		AND hdr.S_TS_TYPE_CD in ('C','N','D')
		)
	)
	/*CR1541 - NonZero Pay Types - Standby*/
	AND (ln.PAY_TYPE not in (SELECT RETRO_PAY_TYPE FROM XX_RETRORATE_PAY_TYPES) )
	)
group by
ln.EMPL_ID, hdr.WORK_STATE_CD, 
ISNULL( CONVERT(char(10), hdr.CORRECTING_REF_DT, 120) , CONVERT(char(10), hdr.TS_DT, 120)),
ln.PAY_TYPE,
ln.GENL_LAB_CAT_CD, 
ln.WORK_COMP_CD, ln.LAB_LOC_CD, ln.ORG_ID, ln.BILL_LAB_CAT_CD, ln.PROJ_ABBRV_CD, ln.PROJ_ID, ln.ACCT_ID,
ln.EFFECT_BILL_DT
having
sum(cast((ln.CHG_HRS) as decimal(14,2)))
<>
0

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







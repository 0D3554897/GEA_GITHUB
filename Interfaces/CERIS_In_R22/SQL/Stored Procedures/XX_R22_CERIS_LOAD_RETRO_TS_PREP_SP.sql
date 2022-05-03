IF OBJECT_ID('dbo.XX_R22_CERIS_LOAD_RETRO_TS_PREP_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_CERIS_LOAD_RETRO_TS_PREP_SP
    IF OBJECT_ID('dbo.XX_R22_CERIS_LOAD_RETRO_TS_PREP_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_CERIS_LOAD_RETRO_TS_PREP_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_CERIS_LOAD_RETRO_TS_PREP_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER ON
go



CREATE PROCEDURE [dbo].[XX_R22_CERIS_LOAD_RETRO_TS_PREP_SP]
(
@in_STATUS_RECORD_NUM     integer,
@in_EMPL_ID		  varchar(12),
@in_START_DT		  datetime,
@in_END_DT		  datetime,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS

/***********************************************************************************************
Name:       XX_R22_CERIS_LOAD_RETRO_TS_PREP_SP
Author:     Veera
Created:    05/2008

Purpose: 

For Reversals, everything is explicitly copied from the original timesheet
except the LAB_CST_AMT which is recalculated based on the current GLC Rate
of the old GLC. (Due to potential Retro GLC Rate changes)

For New Timesheets with ORG and/or GLC changes, everything is defaulted
so that the preprocessor will pick up the appropriate ORG/LAB_GRP_TYPE/GLC 
based on the Correcting Reference Date 
(week ending date of the original timesheet being corrected)

Notes:      Called by XX_R22_CERIS_PROCESS_RETRO_SP.


CP600000709 10/16/2009 Reference BP&S Service Request CR2350 KM
            Retro-timesheet changes (4 instances)

CP600000xxx 01/20/2010 Reference BP&S Service Request DR2672 KM
            All 8 instances of "< @in_END_DT" are changed to "<= @in_END_DT"

CP600000xxx 05/05/2010 Reference BP&S Service Request CR2350 KM
            Retro Logic

CR-2350     05/23/2011 Modified for CR-2350 SUB_PD_NO default value changed
CR-2350     09/28/2011 Modified for CR-2350 changed the date logic for retro of retro TS

************************************************************************************************/

BEGIN

DECLARE @PROCESSED_FL            char(1),
	@TS_DT                   char(10),
	@FY_CD                   char(6),
	@PD_NO                   char(2),
	@SUB_PD_NO               char(2),
	@S_TS_TYPE_CD            char(2),
	@NOTES                   varchar(254),
	@LAB_CST_AMT		 char(1),
	@SP_NAME                 sysname,
	@DIV_22_COMPANY_ID       varchar(10),
	@IMAPS_error_number      integer,
	@SQLServer_error_code    integer,
	@row_count               integer,
	@error_msg_placeholder1  sysname,
	@error_msg_placeholder2  sysname

-- set local constants
SET @SP_NAME = 'XX_R22_CERIS_LOAD_RETRO_TS_PREP_SP'

-- initialize local variables
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert'
SET @error_msg_placeholder2 = 'records into table XX_R22_CERIS_RETRO_TS_PREP'

SET @LAB_CST_AMT = '0'
SET @PROCESSED_FL = 'N'
SET @S_TS_TYPE_CD = 'C'

SET @FY_CD = DATEPART(year, GETDATE())
SET @PD_NO = DATEPART(month, GETDATE())
SET @TS_DT = CONVERT(char(10), GETDATE(), 120)


SELECT @DIV_22_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'CERIS_R22'


SET @NOTES = CAST(@in_STATUS_RECORD_NUM as varchar(10)) + '-CERIS-'

--Modified for CR-2350 05/23/2011
--22 is using subpd=3 for entire labor
SET @SUB_PD_NO=3
/*
SELECT @SUB_PD_NO = a.SUB_PD_NO 
FROM IMAR.DELTEK.SUB_PD a
WHERE a.SUB_PD_END_DT =
	(SELECT MIN(b.SUB_PD_END_DT)
	FROM  IMAR.DELTEK.SUB_PD b
	WHERE (b.SUB_PD_NO = 2 OR b.SUB_PD_NO = 3)
          AND DATEDIFF(day, GETDATE(), b.SUB_PD_END_DT) >= 0)
*/



--first do history table (posted timesheets)

-- insert reversal timesheets
INSERT INTO dbo.XX_R22_CERIS_RETRO_TS_PREP
	(TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, 
	 FY_CD, PD_NO, SUB_PD_NO, 
	 CORRECTING_REF_DT, 

   	 LAB_CST_AMT, 

	 PAY_TYPE,
	 GENL_LAB_CAT_CD, CHG_HRS, 
	 WORK_COMP_CD, LAB_LOC_CD, ORG_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, PROJ_ID, ACCT_ID,
	 TS_HDR_SEQ_NO, EFFECT_BILL_DT, NOTES)
SELECT 	 
	 @TS_DT, ln.EMPL_ID,
-- CR2350_Begin
         'N' as S_TS_TYPE_CD,
-- CR2350_End
         hdr.WORK_STATE_CD, 
	 @FY_CD, @PD_NO, @SUB_PD_NO, 
	 ISNULL( CONVERT(char(10), hdr.CORECTING_REF_DT, 120) , CONVERT(char(10), hdr.TS_DT, 120)),

	 -1.0 * ln.LAB_CST_AMT,

	 ln.PAY_TYPE,
	 ln.GENL_LAB_CAT_CD, cast((-1.0 * ln.CHG_HRS) as decimal(14,2)), 
	 ln.WORK_COMP_CD, ln.LAB_LOC_CD, ln.ORG_ID, ln.BILL_LAB_CAT_CD, ln.PROJ_ABBRV_CD, ln.PROJ_ID, ln.ACCT_ID,
	 NULL, CONVERT(char(10), ln.EFFECT_BILL_DT, 120), 
	 CAST( (@NOTES + casT(ln.TS_LN_KEY as varchar) +  ( CASE WHEN CHARINDEX('-A-', ln.notes, 1)<>0 then '-A'
										 WHEN CHARINDEX('-B-', ln.notes, 1)<>0 then '-B'
										 WHEN CHARINDEX('-C-', ln.notes, 1)<>0 then '-C'
										 ELSE '- '
									 END) 
		+'-n') as char(254))
FROM 	IMAR.DELTEK.TS_LN_HS ln
INNER 	JOIN IMAR.DELTEK.TS_HDR_HS hdr
ON 	(
	(ln.EMPL_ID = hdr.EMPL_ID) 
	AND (ln.TS_DT = hdr.TS_DT)
    	AND (ln.S_TS_TYPE_CD = hdr.S_TS_TYPE_CD) 
	AND (ln.TS_HDR_SEQ_NO = hdr.TS_HDR_SEQ_NO)
        AND (hdr.COMPANY_ID = @DIV_22_COMPANY_ID)
        )
INNER 	JOIN IMAR.DELTEK.GENL_LAB_CAT c
ON	(
	ln.GENL_LAB_CAT_CD = c.GENL_LAB_CAT_CD
        AND
        c.COMPANY_ID = @DIV_22_COMPANY_ID
	)
INNER	JOIN IMAR.DELTEK.PAY_TYPE d
ON	(
	ln.PAY_TYPE = d.PAY_TYPE
	)
WHERE   (
	(ln.EMPL_ID = @in_EMPL_ID) 
	AND
	(
		(
-- DR2672_Begin
		(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(hdr.TS_DT) >= @in_START_DT)
		AND (dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(hdr.TS_DT) <= @in_END_DT)
-- DR2672_End
		AND hdr.S_TS_TYPE_CD = 'R'
		)
		OR
		(
		hdr.CORECTING_REF_DT IS NOT NULL
		AND
-- DR2672_Begin
		(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(hdr.CORECTING_REF_DT) >= @in_START_DT)
		AND (dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(hdr.CORECTING_REF_DT) <= @in_END_DT)
-- DR2672_End
		AND hdr.S_TS_TYPE_CD in ('C', 'N', 'D')
		)
	)
	)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

-- insert new timesheets
INSERT INTO dbo.XX_R22_CERIS_RETRO_TS_PREP
	(TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, 
	 FY_CD, PD_NO, SUB_PD_NO, 
	 CORRECTING_REF_DT, 

	 LAB_CST_AMT, 

	 PAY_TYPE,
	 CHG_HRS, WORK_COMP_CD, LAB_LOC_CD, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, PROJ_ID,
	 TS_HDR_SEQ_NO, EFFECT_BILL_DT, NOTES)
SELECT 	 
	 @TS_DT, ln.EMPL_ID,
-- CR2350_Begin
         'D'as S_TS_TYPE_CD,
-- CR2350_End
         hdr.WORK_STATE_CD, 
	 @FY_CD, @PD_NO, @SUB_PD_NO, 


/* per Tejas 5/11/10
Whenever the pay_type='BO', s_ts_type_cd='C' in TS_LN table can you pull TS_DT into Correcting_REF_DT, effect_bill_dt in RETRO_TS table for CERIS. 
and this rule will only apply to +ve timesheet (i.e. D type).   */
/* 09/28/2011 test case#9B issue 09/27/2011 for retro of retro
Whenever the pay_type='BO', s_ts_type_cd='C', notes like CERIS in TS_LN table pull correcting_ref_dt into Correcting_REF_DT in RETRO_TS table for CERIS. 
if notes not CERIS then old logic
	(case 
		when ln.PAY_TYPE='BO' and hdr.S_TS_TYPE_CD='C' then CONVERT(char(10), hdr.TS_DT, 120)
		else ISNULL( CONVERT(char(10), hdr.CORECTING_REF_DT, 120) , CONVERT(char(10), hdr.TS_DT, 120))
	 end), 
*/
	--New Logic
	(case 
		when PAY_TYPE='BO' and hdr.S_TS_TYPE_CD='C' AND NOTES LIKE '%CERIS%' then CONVERT(char(10), hdr.CORECTING_REF_DT, 120)
		when PAY_TYPE='BO' and hdr.S_TS_TYPE_CD='C' AND NOTES NOT LIKE '%CERIS%' then CONVERT(char(10), hdr.TS_DT, 120)
		else ISNULL( CONVERT(char(10), hdr.CORECTING_REF_DT, 120) , CONVERT(char(10), hdr.TS_DT, 120))
	 end) ref_dt_new,

	/*letting this default*/
	 @LAB_CST_AMT, 

	 ln.PAY_TYPE,
	 ln.CHG_HRS as CHG_HRS, 
	 ln.WORK_COMP_CD, ln.LAB_LOC_CD, ln.BILL_LAB_CAT_CD, ln.PROJ_ABBRV_CD, ln.PROJ_ID,
	 NULL, 

/* per Tejas 5/11/10
Whenever the pay_type='BO', s_ts_type_cd='C' in TS_LN table can you pull TS_DT into Correcting_REF_DT, effect_bill_dt in RETRO_TS table for CERIS. 
and this rule will only apply to +ve timesheet (i.e. D type).   */

/* 09/28/2011 test case#9B issue 09/27/2011 for retro of retro
Whenever the pay_type='BO', s_ts_type_cd='C', notes like CERIS in TS_LN table pull correcting_ref_dt into Correcting_REF_DT in RETRO_TS table for CERIS. 
if notes not CERIS then old logic
	(case 
		when ln.PAY_TYPE='BO' and hdr.S_TS_TYPE_CD='C' then CONVERT(char(10), hdr.TS_DT, 120)
		else CONVERT(char(10), ln.EFFECT_BILL_DT, 120)
	 end), 
*/
	--New Logic
	(case 
		when ln.PAY_TYPE='BO' and hdr.S_TS_TYPE_CD='C' AND NOTES LIKE '%CERIS%' then CONVERT(char(10), ln.effect_bill_dt, 120)
		when ln.PAY_TYPE='BO' and hdr.S_TS_TYPE_CD='C' AND NOTES NOT LIKE '%CERIS%' then CONVERT(char(10), hdr.TS_DT, 120)
		else CONVERT(char(10), ln.EFFECT_BILL_DT, 120)
	 end) work_date_new,
  
	 CAST( (@NOTES + casT(ln.TS_LN_KEY as varchar) +  ( CASE WHEN CHARINDEX('-A-', ln.notes, 1)<>0 then '-A'
										 WHEN CHARINDEX('-B-', ln.notes, 1)<>0 then '-B'
										 WHEN CHARINDEX('-C-', ln.notes, 1)<>0 then '-C'
										 ELSE '- '
									 END) 
		+'-p') as char(254))
FROM 	IMAR.DELTEK.TS_LN_HS ln
INNER 	JOIN IMAR.DELTEK.TS_HDR_HS hdr
ON 	(
	(ln.EMPL_ID = hdr.EMPL_ID) 
	AND (ln.TS_DT = hdr.TS_DT)
    	AND (ln.S_TS_TYPE_CD = hdr.S_TS_TYPE_CD) 
	AND (ln.TS_HDR_SEQ_NO = hdr.TS_HDR_SEQ_NO)
        AND (hdr.COMPANY_ID = @DIV_22_COMPANY_ID)
        )
WHERE   (
	(ln.EMPL_ID = @in_EMPL_ID) 
	AND
	(
		(
-- DR2672_Begin
		(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(hdr.TS_DT) >= @in_START_DT)
		AND (dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(hdr.TS_DT) <= @in_END_DT)
-- DR2672_End
		AND hdr.S_TS_TYPE_CD = 'R'
		)
		OR
		(
		hdr.CORECTING_REF_DT IS NOT NULL
		AND
-- DR2672_Begin
		(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(hdr.CORECTING_REF_DT) >= @in_START_DT)
		AND (dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(hdr.CORECTING_REF_DT) <= @in_END_DT)
-- DR2672_End
		AND hdr.S_TS_TYPE_CD in ('C', 'N', 'D')
		)
	)
	)
SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER




--then do import tables (non-posted timesheets)

-- insert reversal timesheets
INSERT INTO dbo.XX_R22_CERIS_RETRO_TS_PREP
	(TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, 
	 FY_CD, PD_NO, SUB_PD_NO, 
	 CORRECTING_REF_DT, 

     LAB_CST_AMT, 

	 PAY_TYPE,
	 GENL_LAB_CAT_CD, CHG_HRS, 
	 WORK_COMP_CD, LAB_LOC_CD, ORG_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, PROJ_ID, ACCT_ID,
	 TS_HDR_SEQ_NO, EFFECT_BILL_DT, NOTES)
SELECT 	 @TS_DT, ln.EMPL_ID,
-- CR2350_Begin
         'N' as S_TS_TYPE_CD,
-- CR2350_End
         hdr.WORK_STATE_CD, 
	 @FY_CD, @PD_NO, @SUB_PD_NO, 
	 ISNULL( CONVERT(char(10), hdr.CORRECTING_REF_DT, 120) , CONVERT(char(10), hdr.TS_DT, 120)), 

	 -1.0 * ln.LAB_CST_AMT,

	 ln.PAY_TYPE,	
	 ln.GENL_LAB_CAT_CD, cast((-1.0 * ln.CHG_HRS) as decimal(14,2)), 
	 ln.WORK_COMP_CD, ln.LAB_LOC_CD, ln.ORG_ID, ln.BILL_LAB_CAT_CD, ln.PROJ_ABBRV_CD, ln.PROJ_ID, ln.ACCT_ID,
	 NULL, CONVERT(char(10), ln.EFFECT_BILL_DT, 120),
	 CAST( (@NOTES + casT(ln.TS_LN_KEY as varchar) +  ( CASE WHEN CHARINDEX('-A-', ln.notes, 1)<>0 then '-A'
										 WHEN CHARINDEX('-B-', ln.notes, 1)<>0 then '-B'
										 WHEN CHARINDEX('-C-', ln.notes, 1)<>0 then '-C'
										 ELSE '- '
									 END) 
		+'-n') as char(254))
FROM 	IMAR.DELTEK.TS_LN ln
INNER 	JOIN IMAR.DELTEK.TS_HDR hdr
ON 	(
	(ln.EMPL_ID = hdr.EMPL_ID) 
	AND (ln.TS_DT = hdr.TS_DT)
    	AND (ln.S_TS_TYPE_CD = hdr.S_TS_TYPE_CD) 
	AND (ln.TS_HDR_SEQ_NO = hdr.TS_HDR_SEQ_NO)
        AND (hdr.COMPANY_ID = @DIV_22_COMPANY_ID)
        )
INNER 	JOIN IMAR.DELTEK.GENL_LAB_CAT c
ON	(
	ln.GENL_LAB_CAT_CD = c.GENL_LAB_CAT_CD
        AND
        c.COMPANY_ID = @DIV_22_COMPANY_ID
	)
INNER	JOIN IMAR.DELTEK.PAY_TYPE d
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
-- DR2672_Begin
		(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(hdr.TS_DT) >= @in_START_DT)
		AND (dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(hdr.TS_DT) <= @in_END_DT)
-- DR2672_End
		AND hdr.S_TS_TYPE_CD = 'R'
		)
		OR
		(
		hdr.CORRECTING_REF_DT IS NOT NULL
		AND
-- DR2672_Begin
		(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(hdr.CORRECTING_REF_DT) >= @in_START_DT)
		AND (dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(hdr.CORRECTING_REF_DT) <= @in_END_DT)
-- DR2672_End
		AND hdr.S_TS_TYPE_CD in ('C', 'N', 'D')
		)
	)
	)

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

-- insert new timesheets
INSERT INTO dbo.XX_R22_CERIS_RETRO_TS_PREP
	(TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, 
	 FY_CD, PD_NO, SUB_PD_NO, 
	 CORRECTING_REF_DT, 

	 LAB_CST_AMT, 

     PAY_TYPE,
	 CHG_HRS, WORK_COMP_CD, LAB_LOC_CD, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, PROJ_ID,
	 TS_HDR_SEQ_NO, EFFECT_BILL_DT, NOTES)
SELECT 	 @TS_DT, ln.EMPL_ID,
-- CR2350_Begin
         'D' as S_TS_TYPE_CD,
-- CR2350_End
         hdr.WORK_STATE_CD, 
	 @FY_CD, @PD_NO, @SUB_PD_NO, 

/* per Tejas 5/11/10
Whenever the pay_type='BO', s_ts_type_cd='C' in TS_LN table can you pull TS_DT into Correcting_REF_DT, effect_bill_dt in RETRO_TS table for CERIS. 
and this rule will only apply to +ve timesheet (i.e. D type).   */
/* 09/28/2011 test case#9B issue 09/27/2011 for retro of retro
Whenever the pay_type='BO', s_ts_type_cd='C', notes like CERIS in TS_LN table pull correcting_ref_dt into Correcting_REF_DT in RETRO_TS table for CERIS. 
if notes not CERIS then old logic
	(case 
		when ln.PAY_TYPE='BO' and hdr.S_TS_TYPE_CD='C' then CONVERT(char(10), hdr.TS_DT, 120)
		else ISNULL( CONVERT(char(10), hdr.CORRECTING_REF_DT, 120) , CONVERT(char(10), hdr.TS_DT, 120))
	 end), 
*/
	--New Logic
	(case 
		when PAY_TYPE='BO' and hdr.S_TS_TYPE_CD='C' AND NOTES LIKE '%CERIS%' then CONVERT(char(10), hdr.CORRECTING_REF_DT, 120)
		when PAY_TYPE='BO' and hdr.S_TS_TYPE_CD='C' AND NOTES NOT LIKE '%CERIS%' then CONVERT(char(10), hdr.TS_DT, 120)
		else ISNULL( CONVERT(char(10), hdr.CORRECTING_REF_DT, 120) , CONVERT(char(10), hdr.TS_DT, 120))
	 end) ref_dt_new,

	/*letting this default*/
	 @LAB_CST_AMT, 

	 ln.PAY_TYPE,
	 ln.CHG_HRS, ln.WORK_COMP_CD, ln.LAB_LOC_CD, ln.BILL_LAB_CAT_CD, ln.PROJ_ABBRV_CD, ln.PROJ_ID,

	 NULL, 


/* per Tejas 5/11/10
Whenever the pay_type='BO', s_ts_type_cd='C' in TS_LN table can you pull TS_DT into Correcting_REF_DT, effect_bill_dt in RETRO_TS table for CERIS. 
and this rule will only apply to +ve timesheet (i.e. D type).  */
/* 09/28/2011 test case#9B issue 09/27/2011 for retro of retro
Whenever the pay_type='BO', s_ts_type_cd='C', notes like CERIS in TS_LN table pull correcting_ref_dt into Correcting_REF_DT in RETRO_TS table for CERIS. 
if notes not CERIS then old logic
	(case 
		when ln.PAY_TYPE='BO' and hdr.S_TS_TYPE_CD='C' then CONVERT(char(10), hdr.TS_DT, 120)
		else CONVERT(char(10), ln.EFFECT_BILL_DT, 120)
	 end), 
*/
	--New Logic
	(case 
		when ln.PAY_TYPE='BO' and hdr.S_TS_TYPE_CD='C' AND NOTES LIKE '%CERIS%' then CONVERT(char(10), ln.effect_bill_dt, 120)
		when ln.PAY_TYPE='BO' and hdr.S_TS_TYPE_CD='C' AND NOTES NOT LIKE '%CERIS%' then CONVERT(char(10), hdr.TS_DT, 120)
		else CONVERT(char(10), ln.EFFECT_BILL_DT, 120)
	 end) work_date_new,
	 CAST( (@NOTES + casT(ln.TS_LN_KEY as varchar) +  ( CASE WHEN CHARINDEX('-A-', ln.notes, 1)<>0 then '-A'
										 WHEN CHARINDEX('-B-', ln.notes, 1)<>0 then '-B'
										 WHEN CHARINDEX('-C-', ln.notes, 1)<>0 then '-C'
										 ELSE '- '
									 END) 
		+'-p') as char(254))
FROM 	IMAR.DELTEK.TS_LN ln
INNER 	JOIN IMAR.DELTEK.TS_HDR hdr
ON 	(
	(ln.EMPL_ID = hdr.EMPL_ID) 
	AND (ln.TS_DT = hdr.TS_DT)
    	AND (ln.S_TS_TYPE_CD = hdr.S_TS_TYPE_CD) 
	AND (ln.TS_HDR_SEQ_NO = hdr.TS_HDR_SEQ_NO)
        AND (hdr.COMPANY_ID = @DIV_22_COMPANY_ID)
        )
WHERE   (
	(hdr.POST_SEQ_NO IS NULL)
	AND
	(ln.EMPL_ID = @in_EMPL_ID) 
	AND
	(
		(
-- DR2672_Begin
		(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(hdr.TS_DT) >= @in_START_DT)
		AND (dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(hdr.TS_DT) <= @in_END_DT)
-- DR2672_End
		AND hdr.S_TS_TYPE_CD = 'R'
		)
		OR
		(
		hdr.CORRECTING_REF_DT IS NOT NULL
		AND
-- DR2672_Begin
		(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(hdr.CORRECTING_REF_DT) >= @in_START_DT)
		AND (dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(hdr.CORRECTING_REF_DT) <= @in_END_DT)
-- DR2672_End
		AND hdr.S_TS_TYPE_CD in ('C', 'N', 'D')
		)
	)
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











go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_R22_CERIS_LOAD_RETRO_TS_PREP_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_CERIS_LOAD_RETRO_TS_PREP_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_CERIS_LOAD_RETRO_TS_PREP_SP >>>'
go

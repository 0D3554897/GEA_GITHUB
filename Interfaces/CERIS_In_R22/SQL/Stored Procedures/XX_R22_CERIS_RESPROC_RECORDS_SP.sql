IF OBJECT_ID('dbo.XX_R22_CERIS_RESPROC_RECORDS_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_CERIS_RESPROC_RECORDS_SP
    IF OBJECT_ID('dbo.XX_R22_CERIS_RESPROC_RECORDS_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_CERIS_RESPROC_RECORDS_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_CERIS_RESPROC_RECORDS_SP >>>'
END
go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go

CREATE PROCEDURE [dbo].[XX_R22_CERIS_RESPROC_RECORDS_SP]
AS
/*******************************************************************************************************************  
Name:       XX_R22_CERIS_RESPORC_RECORDS
Author:     Tejas Patel
Created:    01/20/2010
Purpose:    This program is the result of implementing retroactive timesheet changes for CERIS_R22 Interface as
            specified by CR2350.
            It is CERIS_R22 Interface's version of ETIME_R22 Interface's program XX_R22_CERIS_RESPORC_RECORDS.
            For details of the business rules governing the "reclass" of (overtime) hours that exceed standard hours,
            see the requirements for ETIME_R22 Interface.

            Called by XX_R22_CERIS_PROCESS_RETRO_SP.

            This program implements business rules for (1) Exempt employee, and (2) Non-Exempt employee.

            Exempt employee needs a special logic to reclass the hours between default account and special account.
            Non-Exempt employee needs a special logic to default the account when the PAY_TYPE is OT.

Notes:

CP600000XXX 01/11/2010 - BP&S Service Request CR2350 - HVT
            Retro-timesheet changes
********************************************************************************************************************/ 

BEGIN

DECLARE @in_EMPL_ID                 char(12),
        @in_EFFECT_DT               datetime,
        @in_END_DT                  datetime,
        @in_exmpt_fl                char(1),
        @in_TS_DT                   datetime,
        @in_PROJ_ABBRV_CD           varchar(6),
        @in_PAY_TYPE                varchar(3),
        @in_BILL_LAB_CAT_CD         varchar(6),
        @in_STD_EST_HRS             numeric(14,2),
        @in_total_by_proj_plc_ptype numeric(14,2),
        @in_total_by_tc             numeric(14,2),
        @in_hrs_for_def_acc         numeric(14,2),
        @in_hrs_for_non_def_acc     numeric(14,2),
        @in_empl_org_id	            varchar(20),
        @in_reclass_proj_abbrv_cd   varchar(6),
        @in_reclass_acct_id         varchar(10),
        @in_S_TS_TYPE_CD            char(2),
        @in_WORK_STATE_CD           char(2),
        @in_effect_bill_dt_for_split_record datetime,
        @in_correcting_ref_dt	    datetime,
        @in_hrs_for_def_acc_factor  numeric(14,3),
        @out_ACCT_ID	            varchar(10),
        @out_PROJ_ABBRV_CD	        varchar(6),
        @out_BILL_LAB_CAT_CD	    varchar(6),
        @out_notes                  varchar(14),
        @in_pd_no		            varchar(2),
        @in_sub_pd_no	            varchar(2)


-- Set Constants
SET @out_ACCT_ID = '41-01-71'       -- special GL account for reclass hours in excess of standard hours
SET @out_PROJ_ABBRV_CD = 'IBM1'     -- IBM Research project
SET @out_BILL_LAB_CAT_CD = 'RONE'


-- Req#3.4.5
-- Non-Exempt and Regular Employee and Pay Type = 'OT'
-- Deltek.TS_LN.PAY_TYPE values are: R = regular, BO = backout
-- Deltek.TS_LN_HS.PAY_TYPE values are: AVP, BO, OS1, OT, R
UPDATE dbo.XX_R22_CERIS_RETRO_TS_PREP
   SET ACCT_ID = '41-81-61'
  FROM dbo.XX_R22_CERIS_RETRO_TS_PREP ts
       INNER JOIN
       IMAR.Deltek.EMPL_LAB_INFO empl_lab
       ON
       (ts.EMPL_ID = empl_lab.EMPL_ID
        AND 
        (
         (ts.S_TS_TYPE_CD = 'R' AND CAST(ts.TS_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
         OR
         (ts.S_TS_TYPE_CD IN ('C','N','D') AND CAST(ts.CORRECTING_REF_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
        )
       )
 WHERE EXMPT_FL = 'N'               -- Non-Exempt
   AND empl_lab.EMPL_CLASS_CD = '1' -- Regular Employee (Deltek.EMPL_LAB_INFO.EMPL_CLASS_CD = '1')
   AND ts.PAY_TYPE = 'OT'           -- overtime
   AND S_TS_TYPE_CD='D' 			-- Only update the ACCT_ID for D lines -- Added CR-2350



-- Non-Exempt and Non-Regular Employee and PayType = 'OT'
-- Timesheet types (Deltek.TS_LN.S_TS_TYPE_CD) are: R = regular, C = correcting, N = reverse, D = replacement
UPDATE dbo.XX_R22_CERIS_RETRO_TS_PREP
   SET ACCT_ID = '41-81-65'
  FROM dbo.XX_R22_CERIS_RETRO_TS_PREP ts
       INNER JOIN
       IMAR.Deltek.EMPL_LAB_INFO empl_lab
       ON
       (ts.EMPL_ID = empl_lab.EMPL_ID
        AND 
        (
         (ts.S_TS_TYPE_CD = 'R' AND CAST(ts.TS_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
         OR
         (ts.S_TS_TYPE_CD in ('C','N','D') AND CAST(ts.CORRECTING_REF_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
        )
       )
 WHERE EXMPT_FL = 'N'               -- Non-Exempt
   AND empl_lab.EMPL_CLASS_CD = '2' -- Non-Regular Employee (Deltek.EMPL_LAB_INFO.EMPL_CLASS_CD = '2')
   AND ts.PAY_TYPE = 'OT'           -- overtime
   AND S_TS_TYPE_CD='D' 			-- Only update the ACCT_ID for D lines -- Added CR-2350

--Added CR-2350
--Keeping it NULL creates a problem of missing reclassed lines
UPDATE  dbo.XX_R22_CERIS_RETRO_TS_PREP
set BILL_LAB_CAT_CD='RONE'
where BILL_LAB_CAT_CD in (NULL,'')

-- This cursor will calculate the hours for default account, and special account.
DECLARE cursor_two CURSOR FAST_FORWARD FOR
   SELECT ts.EMPL_ID, empl_lab.EFFECT_DT, empl_lab.END_DT, empl_lab.EXMPT_FL,
          ts.TS_DT, ts.CORRECTING_REF_DT, ts.PROJ_ABBRV_CD, 
        'R' PAY_TYPE,-- pay_type Commented-CR-2350
          ts.BILL_LAB_CAT_CD, 
          -- IF N type, then standard hrs will be -ve as later on we use it for > comparision
          CASE
             WHEN S_TS_TYPE_CD = 'N' THEN CAST((empl_lab.STD_EST_HRS / 52) * -1 as numeric(14,2))
             ELSE CAST((empl_lab.STD_EST_HRS / 52) as numeric(14,2))
          END as STD_EST_HRS, 
          SUM(CAST(ts.CHG_HRS as numeric(14,2))) as total_by_proj_plc_ptype,
          (select SUM(CAST(CHG_HRS as numeric(14,2))) 
             from dbo.XX_R22_CERIS_RETRO_TS_PREP
            where EMPL_ID = ts.EMPL_ID
              and S_TS_TYPE_CD = ts.S_TS_TYPE_CD
			  AND S_TS_TYPE_CD='D'	-- Added CR-2350
			  AND PAY_TYPE<>'BO'	-- Added CR-2350
              and dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS_DT) = dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.TS_DT)
              -- This will calculate sum of hrs for N, D lines
              and ISNULL(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(CORRECTING_REF_DT), '01-01-2078') = ISNULL(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.CORRECTING_REF_DT),'01-01-2078')
            group by EMPL_ID, S_TS_TYPE_CD, dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS_DT)
          ) as total_by_tc,
          CONVERT(numeric(14,2), SUM(CONVERT(numeric(14,2), ts.CHG_HRS)) * (empl_lab.STD_EST_HRS / 52) /
                 (select ABS(SUM(CAST(CHG_HRS as numeric(14,2))))
                    from dbo.XX_R22_CERIS_RETRO_TS_PREP
                   where EMPL_ID      = ts.EMPL_ID
                     and S_TS_TYPE_CD = ts.S_TS_TYPE_CD
					  AND S_TS_TYPE_CD='D'	-- Added CR-2350
					  AND PAY_TYPE<>'BO'	-- Added CR-2350
                     -- This will calculate sum of hrs for N, D lines
                     and ISNULL(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(CORRECTING_REF_DT), '01-01-2078') = ISNULL(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.CORRECTING_REF_DT),'01-01-2078')
                     and dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS_DT) = dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.TS_DT)
                   group by EMPL_ID, S_TS_TYPE_CD, dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS_DT)
                 )
          ) as hrs_for_def_acc,
          CONVERT(numeric(14,2),
                  SUM(CAST(ts.CHG_HRS as numeric(14,2))) - 
                     CONVERT(numeric(14,2),
                             SUM(CONVERT(numeric(14,2), ts.CHG_HRS)) * (empl_lab.STD_EST_HRS / 52) /
                                 (select ABS(SUM(CAST(CHG_HRS as numeric(14,2))))
                                    from dbo.XX_R22_CERIS_RETRO_TS_PREP
    where EMPL_ID      = ts.EMPL_ID
                                     and S_TS_TYPE_CD = ts.S_TS_TYPE_CD
									  AND S_TS_TYPE_CD='D'	-- Added CR-2350
									  AND PAY_TYPE<>'BO'	-- Added CR-2350
  -- This will calculate sum of hrs for N, D lines
                                     and ISNULL(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(CORRECTING_REF_DT), '01-01-2078') = ISNULL(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.CORRECTING_REF_DT),'01-01-2078')
                                     and dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS_DT) = dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.TS_DT)
                                   group by EMPL_ID, S_TS_TYPE_CD, dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS_DT)
                                 )
                            )
          ) as hrs_for_non_def_acc,
          CORRECTING_REF_DT as effect_bill_dt_for_split_record, --TS_DT replaced CR-2350 Tejas
          S_TS_TYPE_CD,
          ISNULL((SELECT distinct map.ACCT_ID
                    from dbo.XX_R22_ACCT_RECLASS map
                   where map.LAB_GRP_TYPE = empl_lab.LAB_GRP_TYPE
                     and map.ACCT_GRP_CD  = prj.ACCT_GRP_CD
                     and LINE_TYPE        = 'RECLASS'
                 ),
                 '99-99-99') as ACCT_ID
     FROM dbo.XX_R22_CERIS_RETRO_TS_PREP ts
          INNER JOIN
          IMAR.Deltek.EMPL_LAB_INFO empl_lab
          ON
          (ts.EMPL_ID = empl_lab.EMPL_ID
           AND 
           (
            (ts.S_TS_TYPE_CD = 'R' AND CAST(ts.TS_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
            OR
            (ts.S_TS_TYPE_CD IN ('C','N','D') AND CAST(ts.CORRECTING_REF_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
           )
          )
          INNER JOIN
          IMAR.Deltek.PROJ prj
          ON
          (ts.PROJ_ABBRV_CD = prj.PROJ_ABBRV_CD AND prj.COMPANY_ID = 2)
    WHERE EXMPT_FL = 'Y'
		  AND S_TS_TYPE_CD='D' -- Added CR-2350
		  AND PAY_TYPE<>'BO'   -- Added CR-2350
		  AND 0 <
            (SELECT COUNT(1) 
             FROM XX_R22_CERIS_RETRO_TS
             WHERE EMPL_ID=TS.EMPL_ID
             AND NEW_EXMPT_FL IS NOT NULL
             AND NEW_EXMPT_FL ='Y'
             AND TS.CORRECTING_REF_DT BETWEEN EFFECT_DT AND END_DT)
    GROUP BY empl_lab.EMPL_ID, empl_lab.EFFECT_DT, ts.CORRECTING_REF_DT,
	      (empl_lab.STD_EST_HRS / 52), empl_lab.END_DT, empl_lab.EXMPT_FL,
          ts.EMPL_ID, ts.TS_DT, ts.PROJ_ABBRV_CD, ts.BILL_LAB_CAT_CD, S_TS_TYPE_CD, empl_lab.ORG_ID, empl_lab.LAB_GRP_TYPE, prj.PROJ_ID, prj.ACCT_GRP_CD

    HAVING SUM(CAST(ts.CHG_HRS as numeric(14,2)))>0 
    --FOR PPA records the sum of hrs for a project can be zero and they will get divide by zero error
    --Having Added 05/24/10

-- Empty the working table so we can load new records from table XX_R22_CERIS_RETRO_TS_PREP
TRUNCATE TABLE dbo.XX_R22_CERIS_RETRO_TS_PREP2


-- Initate the loading of table XX_R22_CERIS_RETRO_TS_PREP2
OPEN cursor_two
FETCH cursor_two
   INTO @in_EMPL_ID, @in_EFFECT_DT, @in_END_DT, @in_exmpt_fl, @in_TS_DT, @in_correcting_ref_dt,
        @in_PROJ_ABBRV_CD, @in_PAY_TYPE, @in_bill_lab_cat_cd, @in_STD_EST_HRS, 
        @in_total_by_proj_plc_ptype, @in_total_by_tc, @in_hrs_for_def_acc, @in_hrs_for_non_def_acc,
        @in_effect_bill_dt_for_split_record, @in_s_ts_type_cd, @in_reclass_acct_id

WHILE (@@fetch_status = 0)
BEGIN

-- Resolve rounding issue
SET @in_hrs_for_def_acc_factor = CONVERT(numeric(14,3), @in_hrs_for_def_acc / @in_total_by_proj_plc_ptype)

/* Reclass - 1st Insert with Default Project Account */
INSERT INTO dbo.XX_R22_CERIS_RETRO_TS_PREP2
   (TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO, SUB_PD_NO,
    CORRECTING_REF_DT, PAY_TYPE, GENL_LAB_CAT_CD, S_TS_LN_TYPE_CD, LAB_CST_AMT,
    CHG_HRS,
    WORK_COMP_CD, LAB_LOC_CD, ORG_ID, ACCT_ID, PROJ_ID, BILL_LAB_CAT_CD, REF_STRUC_1_ID, REF_STRUC_2_ID,
    ORG_ABBRV_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO, EFFECT_BILL_DT, PROJ_ACCT_ABBRV_CD,
    NOTES
   ) 
   SELECT TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO, SUB_PD_NO,
          CORRECTING_REF_DT,
         'R' PAY_TYPE,-- pay_type Commented-CR-2350
          GENL_LAB_CAT_CD, S_TS_LN_TYPE_CD, '0' LAB_CST_AMT, 
 CASE
             WHEN ABS(@in_STD_EST_HRS) >= ABS(@in_total_by_tc) THEN sum(CONVERT(decimal(14,2), CHG_HRS))
             ELSE CONVERT(decimal(14,2), sum((CONVERT(decimal(14,2), CHG_HRS)) * @in_hrs_for_def_acc_factor))
          END,
          WORK_COMP_CD, LAB_LOC_CD, ORG_ID, ACCT_ID, PROJ_ID, BILL_LAB_CAT_CD, REF_STRUC_1_ID, REF_STRUC_2_ID,
          ORG_ABBRV_CD, PROJ_ABBRV_CD, MIN(TS_HDR_SEQ_NO), EFFECT_BILL_DT, PROJ_ACCT_ABBRV_CD,
 /* Modified CR-2350*/
          SUBSTRING(NOTES, 1, PATINDEX('%-CERIS-%', NOTES)+6)   --1861-CERIS-
            +	cast(rtrim(max(
	                substring(notes, CHARINDEX('-CERIS-', NOTES, 1)+7,abs(CHARINDEX('-CERIS-', NOTES, 1)+7-CHARINDEX('-p', NOTES, 1)))
		                )) as varchar)
            --SUBSTRING(NOTES, 1, PATINDEX('%-p%', NOTES))
		    + CASE
                  WHEN ABS(@in_STD_EST_HRS) >= ABS(@in_total_by_tc) THEN ''
                ELSE 'A'
               END
            +SUBSTRING(NOTES, PATINDEX('%-p%', NOTES),len(notes)) as NOTES
			--+SUBSTRING(NOTES, PATINDEX('%-p%', NOTES),len(notes)) AS NOTES
 
     FROM dbo.XX_R22_CERIS_RETRO_TS_PREP ts
    WHERE RTRIM(ts.EMPL_ID)      = RTRIM(@in_EMPL_ID)
      AND RTRIM(ts.S_TS_TYPE_CD) = RTRIM(@in_S_TS_TYPE_CD)
      AND ts.TS_DT               = @in_TS_DT
      AND ts.PROJ_ABBRV_CD       = @in_PROJ_ABBRV_CD
      AND ISNULL(CAST(ts.CORRECTING_REF_DT as datetime), '') = ISNULL(CAST(@in_correcting_ref_dt as datetime), '')
      AND ts.BILL_LAB_CAT_CD     = isnull(@in_bill_lab_cat_cd,'RONE')
      --AND ts.PAY_TYPE            = @in_pay_type
	  AND S_TS_TYPE_CD='D' -- Added CR-2350
	  AND PAY_TYPE<>'BO'   -- Added CR-2350
GROUP BY  TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO, SUB_PD_NO,
          CORRECTING_REF_DT, GENL_LAB_CAT_CD, S_TS_LN_TYPE_CD,            
          WORK_COMP_CD, LAB_LOC_CD, ORG_ID, ACCT_ID, PROJ_ID, BILL_LAB_CAT_CD, REF_STRUC_1_ID, REF_STRUC_2_ID,
          ORG_ABBRV_CD, PROJ_ABBRV_CD, EFFECT_BILL_DT, PROJ_ACCT_ABBRV_CD,
          --Added CR-2350
          SUBSTRING(NOTES, 1, PATINDEX('%-CERIS-%', NOTES)+6), SUBSTRING(NOTES, PATINDEX('%-p%', NOTES),len(notes))      


/* Reclass - 2nd Insert with Special Project Account */
INSERT INTO dbo.XX_R22_CERIS_RETRO_TS_PREP2
   (TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO, SUB_PD_NO,
    CORRECTING_REF_DT, PAY_TYPE, GENL_LAB_CAT_CD, S_TS_LN_TYPE_CD, LAB_CST_AMT,
    CHG_HRS,
    WORK_COMP_CD, LAB_LOC_CD, ORG_ID, ACCT_ID, PROJ_ID, BILL_LAB_CAT_CD, REF_STRUC_1_ID, REF_STRUC_2_ID,
    ORG_ABBRV_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO, EFFECT_BILL_DT, PROJ_ACCT_ABBRV_CD,
    NOTES)
   SELECT TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO, SUB_PD_NO,
          CORRECTING_REF_DT, 
         'R' PAY_TYPE,-- pay_type Commented-CR-2350
          GENL_LAB_CAT_CD, S_TS_LN_TYPE_CD, '0' LAB_CST_AMT,
          CASE
             WHEN ABS(@in_STD_EST_HRS) >= ABS(@in_total_by_tc) THEN 0.00
             ELSE sum(CONVERT(decimal(14,2), CHG_HRS)) - CONVERT(decimal(14,2), sum((CONVERT(decimal(14,2), CHG_HRS)) * @in_hrs_for_def_acc_factor))
          END,
      	  WORK_COMP_CD, LAB_LOC_CD, ORG_ID, @in_reclass_acct_id, PROJ_ID, BILL_LAB_CAT_CD, REF_STRUC_1_ID, REF_STRUC_2_ID,
          ORG_ABBRV_CD, PROJ_ABBRV_CD, min(TS_HDR_SEQ_NO), EFFECT_BILL_DT, PROJ_ACCT_ABBRV_CD,
          SUBSTRING(NOTES, 1, PATINDEX('%-CERIS-%', NOTES)+6)   --1861-CERIS-
            +	cast(rtrim(max(
	                substring(notes, CHARINDEX('-CERIS-', NOTES, 1)+7,abs(CHARINDEX('-CERIS-', NOTES, 1)+7-CHARINDEX('-p', NOTES, 1)))
		                )) as varchar)
            --SUBSTRING(NOTES, 1, PATINDEX('%-p%', NOTES))
		    + CASE
                  WHEN ABS(@in_STD_EST_HRS) >= ABS(@in_total_by_tc) THEN ''
                ELSE 'B'
               END
            +SUBSTRING(NOTES, PATINDEX('%-p%', NOTES),len(notes)) as NOTES
          /* Modified CR-2350*/
     FROM dbo.XX_R22_CERIS_RETRO_TS_PREP ts
    WHERE RTRIM(ts.EMPL_ID)      = RTRIM(@in_empl_id)
      AND RTRIM(ts.S_TS_TYPE_CD) = RTRIM(@in_S_TS_TYPE_CD)
      AND ts.TS_DT               = @in_TS_DT
      AND ts.PROJ_ABBRV_CD       = @in_PROJ_ABBRV_CD
      AND ISNULL(CAST(ts.CORRECTING_REF_DT as datetime), '') = ISNULL(CAST(@in_CORRECTING_REF_DT as datetime), '')
      AND ts.BILL_LAB_CAT_CD     = isnull(@in_bill_lab_cat_cd,'RONE')
      --AND ts.PAY_TYPE            = @in_pay_type
	  AND S_TS_TYPE_CD='D' -- Added CR-2350
	  AND PAY_TYPE<>'BO'   -- Added CR-2350
GROUP BY  TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO, SUB_PD_NO,
          CORRECTING_REF_DT, GENL_LAB_CAT_CD, S_TS_LN_TYPE_CD,            
          WORK_COMP_CD, LAB_LOC_CD, ORG_ID, ACCT_ID, PROJ_ID, BILL_LAB_CAT_CD, REF_STRUC_1_ID, REF_STRUC_2_ID,
          ORG_ABBRV_CD, PROJ_ABBRV_CD, EFFECT_BILL_DT, PROJ_ACCT_ABBRV_CD,
          --Added CR-2350
          SUBSTRING(NOTES, 1, PATINDEX('%-CERIS-%', NOTES)+6), SUBSTRING(NOTES, PATINDEX('%-p%', NOTES),len(notes))          


FETCH cursor_two
   INTO @in_EMPL_ID, @in_EFFECT_DT, @in_END_DT, @in_exmpt_fl, @in_TS_DT, @in_correcting_ref_dt,
        @in_PROJ_ABBRV_CD, @in_PAY_TYPE, @in_bill_lab_cat_cd, @in_STD_EST_HRS, 
        @in_total_by_proj_plc_ptype, @in_total_by_tc, @in_hrs_for_def_acc, @in_hrs_for_non_def_acc,
        @in_effect_bill_dt_for_split_record, @in_s_ts_type_cd, @in_reclass_acct_id

END /* WHILE (@@fetch_status = 0) */

CLOSE cursor_two
DEALLOCATE cursor_two





-- Delete the records created with zero hours this happens when the total timecards hours are same or less then standard hours
DELETE dbo.XX_R22_CERIS_RETRO_TS_PREP2
 WHERE CAST(CHG_HRS as numeric(14,2)) = 0.00


-- Req#3.4.7 (Create -ve IBM1 line item with standard hours)
-- For Exempt Employees
DECLARE cursor_three CURSOR FAST_FORWARD FOR

	SELECT  ts.empl_id, ts.TS_DT,  
	-- Added CR-1921
	case when
		-- This count will check if there is second split is missing
		-- if that's the case then apply 40hrs with split-1 otherwise pro rate them
		(select count(distinct ISNULL(correcting_ref_dt,ts_dt)) from XX_R22_CERIS_RETRO_TS_PREP
		where empl_id=ts.empl_id 
		and dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ISNULL(correcting_ref_dt,ts_dt))=dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ISNULL(ts.correcting_ref_dt,ts.ts_dt))
		)=1 
			then (empl_lab.std_est_hrs/52)
		else 
		((empl_lab.std_est_hrs/52)/5) * 
   -- Added 5/27/09 CR-2042
			-- Find Day multiplier 
			case	-- Condition for all cases simply use day of week (-1 is to exclude sunday from week)
					-- If dw of ts_dt is less then 5 then use dw-1
					when datepart(dw,ISNULL(correcting_ref_dt,ts_dt))<=5 
						then (datepart(dw,ISNULL(correcting_ref_dt,ts_dt))-1)
					-- Condition for second half of the week when week had 15th.
					-- when week had 15th then find the diff of days between ts_dt and 15th if the diff 
					-- is between 1 and 4 then use the difference e.g. 4/15/09 is Wed and 4/17 is Fri so diff is 2 days
					when datediff(day,convert(varchar(4),(datepart(yyyy,ISNULL(correcting_ref_dt,ts_dt))))+'-'+(convert(varchar(2),datepart(mm,ISNULL(correcting_ref_dt,ts_dt))))+'-15', ISNULL(correcting_ref_dt,ts_dt))<=4
						and datediff(day,convert(varchar(4),(datepart(yyyy,ISNULL(correcting_ref_dt,ts_dt))))+'-'+(convert(varchar(2),datepart(mm,ISNULL(correcting_ref_dt,ts_dt))))+'-15', ISNULL(correcting_ref_dt,ts_dt))>=1
						then datediff(day,convert(varchar(4),(datepart(yyyy,ISNULL(correcting_ref_dt,ts_dt))))+'-'+(convert(varchar(2),datepart(mm,ISNULL(correcting_ref_dt,ts_dt))))+'-15', ISNULL(correcting_ref_dt,ts_dt))
					-- Condition for second half of the week when week had 30, 31st.
					-- When 30th, 31st is in week then use diff of last day of prev month and ts_dt
					-- e.g. 
					when datediff(d,DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,ISNULL(correcting_ref_dt,ts_dt)),0)),ISNULL(correcting_ref_dt,ts_dt))<=4
						then datediff(d,DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,ISNULL(correcting_ref_dt,ts_dt)),0)),ISNULL(correcting_ref_dt,ts_dt))
				else 5 --Else Standard Days will be 5 only and no need for following logic
					-- Commented CR-2230 07/31/09 
					--(datepart(dw,dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.TS_DT))) -(datepart(dw,cast(ts_dt as datetime)-1))
				end
            /* case when datepart(day,ts_dt)=16 then 
					(datepart(dw,dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.TS_DT))-1) -(datepart(dw,cast(ts_dt as datetime)-1-1))
				else (datepart(dw,ts_dt)-1)
				end */
	end,
	-- (empl_lab.std_est_hrs/52), Commented CR-1921
	sum(cast(ts.chg_hrs as numeric(14,2))) chg_hrs,
	empl_lab.org_id empl_org_id,
	(select distinct proj_abbrv_cd from IMAR.DELTEK.proj 
        where company_id=2 
        and rtrim(org_id)=rtrim(empl_lab.org_id) 
        and substring(proj_id,1,4)='RRDE'
        and empl_lab.org_id is not null
        and proj_abbrv_cd is not null 
        and rtrim(proj_abbrv_cd)<>'') reclass_proj_abbrv_cd,
	ISNULL((SELECT distinct map.acct_id
			from XX_R22_ACCT_RECLASS map
			where map.lab_grp_type=empl_lab.lab_grp_type
			-- Modified by 1/8/09 Added PMP
			and map.acct_grp_cd IN('RRD','PMP') -- All Backout accounts will have RRD, PMP PAG
            and map.acct_grp_cd in 
            	(select distinct acct_grp_cd from IMAR.DELTEK.proj 
                    where company_id=2 
                    and rtrim(org_id)=rtrim(empl_lab.org_id) 
                    and substring(proj_id,1,4)='RRDE'
                    and empl_lab.org_id is not null
                    and proj_abbrv_cd is not null 
                    and rtrim(proj_abbrv_cd)<>'')
            and line_type='BACKOUT'),'99-99-99') ACCT_ID,
     max(pd_no) pd_no, -- Added 09/02/08
 max(sub_pd_no) sub_pd_no, -- Added 09/02/08,
	ts.correcting_ref_dt,
	-- ,dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.correcting_ref_dt) correcting_ref_dt -- Added 01/28/08 
	 s_ts_type_cd
	-- This will allow us to create BO lines for MTCs
	FROM dbo.XX_R22_CERIS_RETRO_TS_PREP ts
	INNER JOIN IMAR.DELTEK.EMPL_LAB_INFO empl_lab
	on
	(ts.empl_id = empl_lab.empl_id
		and 
		(
			(ts.S_TS_TYPE_CD = 'R' AND cast(ts.TS_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
			OR
			(ts.S_TS_TYPE_CD in ('C','N','D') AND cast(ts.CORRECTING_REF_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
		)
	)
	where exmpt_fl='Y'
	and ts.s_ts_type_cd in ('D')
	and pay_type<>'BO'
	--Added CR-2350 5/11/10
	AND 0 <
     (SELECT COUNT(1) 
             FROM XX_R22_CERIS_RETRO_TS
             WHERE EMPL_ID=TS.EMPL_ID
             AND NEW_EXMPT_FL IS NOT NULL
             AND NEW_EXMPT_FL ='Y'
             AND TS.CORRECTING_REF_DT BETWEEN EFFECT_DT AND END_DT)
	group by ts.empl_id, ts.TS_DT,  (empl_lab.std_est_hrs/52), empl_lab.org_id, empl_lab.lab_grp_type
	 ,ts.correcting_ref_dt, s_ts_type_cd, ISNULL(correcting_ref_dt,ts_dt)
	--dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.correcting_ref_dt)
	-- Added 01/28/08

          
OPEN cursor_three
FETCH cursor_three
   INTO @in_EMPL_ID, @in_TS_DT, @in_STD_EST_HRS, @in_total_by_tc, @in_empl_org_id, 
        @in_reclass_proj_abbrv_cd, @in_reclass_acct_id, @in_pd_no, @in_sub_pd_no, @in_correcting_ref_dt, @in_s_ts_type_cd

WHILE (@@fetch_status = 0)
BEGIN

SELECT 
    -- modified CR-2350
    @out_notes=
	cast(rtrim(max(
	substring(notes, CHARINDEX('-CERIS-', NOTES, 1)+7,abs(CHARINDEX('-CERIS-', NOTES, 1)+7-CHARINDEX('-p', NOTES, 1)))
		)) as varchar)

    --@out_notes = CAST(MAX(CAST(SUBSTRING(NOTES, CHARINDEX('-', NOTES, 1) + 1, (CHARINDEX('-', NOTES, (CHARINDEX('-', NOTES, 1) + 1)) - CHARINDEX('-', NOTES, 1) - 1)) as numeric)) as varchar)
  FROM dbo.XX_R22_CERIS_RETRO_TS_PREP
 WHERE EMPL_ID = @in_empl_id
   AND TS_DT = @in_TS_DT
   AND ((CORRECTING_REF_DT) = CAST(@in_CORRECTING_REF_DT as datetime)
        OR ((CORRECTING_REF_DT) IS NULL)
       )
   AND S_TS_TYPE_CD = @in_s_ts_type_cd
   AND S_TS_TYPE_CD='D'
   AND PAY_TYPE<>'BO'
   AND NOTES NOT LIKE '%-C-%'

/* Reclass - 3rd Insert with -(Std Hrs) Capacity */

INSERT INTO dbo.XX_R22_CERIS_RETRO_TS_PREP2
   (TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO, SUB_PD_NO,
    CORRECTING_REF_DT, PAY_TYPE, GENL_LAB_CAT_CD, S_TS_LN_TYPE_CD, LAB_CST_AMT,
  CHG_HRS,
    WORK_COMP_CD, LAB_LOC_CD, ORG_ID, ACCT_ID, PROJ_ID, BILL_LAB_CAT_CD, REF_STRUC_1_ID, REF_STRUC_2_ID,
    ORG_ABBRV_CD, PROJ_ABBRV_CD,
    TS_HDR_SEQ_NO,
    EFFECT_BILL_DT,
    PROJ_ACCT_ABBRV_CD,
    NOTES)
    SELECT DISTINCT CONVERT(char(10), ts.TS_DT, 120), EMPL_ID,'D' as S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, @in_PD_NO, @in_SUB_PD_NO,
           --S_TS_TYPE_CD=D as we want to make them as substitute TS
          CASE
             WHEN @in_s_ts_type_cd in ( 'C','D') THEN CONVERT(char(10), (CORRECTING_REF_DT), 120)
             ELSE CONVERT(char(10), TS_DT, 120)
          END as CORRECTING_REF_DT,
          'BO' as PAY_TYPE, GENL_LAB_CAT_CD, S_TS_LN_TYPE_CD, NULL as LAB_CST_AMT,
          -(@in_STD_EST_HRS) as CHG_HRS,
          WORK_COMP_CD, LAB_LOC_CD, @in_empl_org_id as ORG_ID, @in_reclass_acct_id as ACCT_ID, 
          (SELECT PROJ_ID FROM IMAR.DELTEK.PROJ where PROJ_ABBRV_CD=@in_reclass_proj_abbrv_cd)
          PROJ_ID ,@out_BILL_LAB_CAT_CD, REF_STRUC_1_ID, REF_STRUC_2_ID,
          ORG_ABBRV_CD, @in_reclass_proj_abbrv_cd as PROJ_ABBRV_CD,
          (select MAX(ts_hdr_seq_no) + 1 
             from dbo.XX_R22_CERIS_RETRO_TS_PREP2 ts2 -- Use XX_R22_CERIS_RETRO_TS_PREP2 as we have added more backout lines so SEQ_NO will be based on that
            where RTRIM(ts2.EMPL_ID) = RTRIM(ts.EMPL_ID)
              and ts2.TS_DT = ts.TS_DT
              and S_TS_TYPE_CD in ('R', 'N', 'C', 'D')
          ) as TS_HDR_SEQ_NO,
          CASE
             WHEN @in_s_ts_type_cd in ( 'C','D') THEN CONVERT(char(10), (CORRECTING_REF_DT), 120)
             ELSE CONVERT(char(10), TS_DT, 120)
          END as EFFECT_BILL_DT,
          PROJ_ACCT_ABBRV_CD,
          --SUBSTRING(NOTES, 1, CHARINDEX('-', NOTES, 1)) + @out_notes + '-C-'+'-p' 
          SUBSTRING(NOTES, 1, PATINDEX('%-CERIS-%', NOTES)+6)   --1861-CERIS-
            +  @out_notes                                       --2201720
            + '-C'                              
            +SUBSTRING(NOTES, PATINDEX('%-p%', NOTES),len(notes)) as NOTES  -- -p-HRLY_AMT or WORK_YR_HRS_NO

     FROM dbo.XX_R22_CERIS_RETRO_TS_PREP ts
    WHERE RTRIM(ts.EMPL_ID) = RTRIM(@in_empl_id)
      AND ts.TS_DT = @in_TS_DT
      AND (ISNULL((ts.CORRECTING_REF_DT), '') = ISNULL(CAST(@in_CORRECTING_REF_DT as datetime), '')
           OR (dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.CORRECTING_REF_DT) IS NULL)
 )
      AND S_TS_TYPE_CD = @in_s_ts_type_cd
	  AND PAY_TYPE<>'BO' -- Added CR-2350

FETCH cursor_three
   INTO @in_EMPL_ID, @in_TS_DT, @in_STD_EST_HRS, @in_total_by_tc, @in_empl_org_id, 
        @in_reclass_proj_abbrv_cd, @in_reclass_acct_id, @in_pd_no, @in_sub_pd_no, @in_correcting_ref_dt, @in_s_ts_type_cd

END /* WHILE (@@fetch_status = 0) */

CLOSE cursor_three
DEALLOCATE cursor_three


-- Update ACCT_ID with 99-99-99 for all A and B lines so they get miscoded. We don't want null value to be passed to the Costpoint preprocessor.
UPDATE dbo.XX_R22_CERIS_RETRO_TS_PREP2
   SET ACCT_ID = '99-99-99'
 WHERE ACCT_ID IS NULL
   AND NOTES like '%-A-%'
  AND NOTES like '%-B-%'
   AND NOTES like '%-C-%'


-- Clean up table XX_R22_CERIS_RETRO_TS_PREP2 if the sum of hours matches before and after split
DECLARE @out_check_sum1 numeric(14,2),
        @out_check_sum2 numeric(14,2)

SELECT @out_check_sum1 = SUM(CAST(CHG_HRS as numeric(14,2)))
  FROM dbo.XX_R22_CERIS_RETRO_TS_PREP ts
       INNER JOIN IMAR.Deltek.EMPL_LAB_INFO empl_lab
       ON
       (ts.EMPL_ID = empl_lab.EMPL_ID
        AND 
        (
         (ts.S_TS_TYPE_CD = 'R' AND CAST(ts.TS_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
         OR
         (ts.S_TS_TYPE_CD in ('C','N','D') AND CAST(ts.CORRECTING_REF_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
        )
       )
 WHERE EXMPT_FL = 'Y'
    AND S_TS_TYPE_CD='D'
    AND PAY_TYPE<>'BO'
    AND 0 <
     (SELECT COUNT(1) 
             FROM XX_R22_CERIS_RETRO_TS
 WHERE EMPL_ID=TS.EMPL_ID
             AND NEW_EXMPT_FL IS NOT NULL
             AND NEW_EXMPT_FL ='Y'
             AND TS.CORRECTING_REF_DT BETWEEN EFFECT_DT AND END_DT)

SELECT @out_check_sum2 = SUM(CAST(CHG_HRS as numeric(14,2)))
  FROM dbo.XX_R22_CERIS_RETRO_TS_PREP2 ts
   INNER JOIN
       IMAR.Deltek.EMPL_LAB_INFO empl_lab
       ON
       (ts.EMPL_ID = empl_lab.EMPL_ID
        AND 
        (
         (ts.S_TS_TYPE_CD = 'R' AND CAST(ts.TS_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
   OR
         (ts.S_TS_TYPE_CD in ('C','N','D') AND CAST(ts.CORRECTING_REF_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
        )
       )
 WHERE EXMPT_FL = 'Y'
   AND TS.NOTES not like '%-C-%'


IF @out_check_sum1 <> @out_check_sum2 
   BEGIN
      PRINT 'Sums of hours are not matching.'
      GOTO BL_ERROR_HANDLER
   END
ELSE
   BEGIN


    -- Before We start Let's Clen TS_PREP
    DELETE from dbo.XX_R22_CERIS_RETRO_TS_PREP
    FROM dbo.XX_R22_CERIS_RETRO_TS_PREP ts
    WHERE S_TS_TYPE_CD='D' and pay_type='BO'
	--Added CR-2350 5/11/10
	AND 0 <
            (SELECT COUNT(1) 
             FROM XX_R22_CERIS_RETRO_TS
             WHERE EMPL_ID=TS.EMPL_ID
             AND NEW_EXMPT_FL IS NOT NULL
             AND NEW_EXMPT_FL ='Y'
             AND TS.CORRECTING_REF_DT BETWEEN EFFECT_DT AND END_DT)



      -- If the total hours in tables XX_R22_CERIS_RETRO_TS_PREP and XX_R22_CERIS_RETRO_TS_PREP2 match for Exempt employees,
      -- then delete the data from XX_R22_CERIS_RETRO_TS_PREP and copy XX_R22_CERIS_RETRO_TS_PREP data to XX_R22_CERIS_RETRO_TS_PREP2
      DELETE dbo.XX_R22_CERIS_RETRO_TS_PREP 
       -- select *
        FROM dbo.XX_R22_CERIS_RETRO_TS_PREP ts
             INNER JOIN
             IMAR.Deltek.EMPL_LAB_INFO empl_lab
  ON
             (ts.EMPL_ID = empl_lab.EMPL_ID
              AND 
              (
               (ts.S_TS_TYPE_CD = 'R' AND CAST(ts.TS_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
                OR
               (ts.S_TS_TYPE_CD in ('C','N','D') AND CAST(ts.CORRECTING_REF_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
 )
             )
       WHERE EXMPT_FL = 'Y'
       AND S_TS_TYPE_CD='D'
		--Added CR-2350 5/11/10
		AND 0 <
            (SELECT COUNT(1) 
             FROM XX_R22_CERIS_RETRO_TS
             WHERE EMPL_ID=TS.EMPL_ID
             AND NEW_EXMPT_FL IS NOT NULL
             AND NEW_EXMPT_FL ='Y'
             AND TS.CORRECTING_REF_DT BETWEEN EFFECT_DT AND END_DT)


      INSERT INTO dbo.XX_R22_CERIS_RETRO_TS_PREP
         (TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO, SUB_PD_NO,
          CORRECTING_REF_DT, PAY_TYPE, GENL_LAB_CAT_CD, S_TS_LN_TYPE_CD, LAB_CST_AMT,
          CHG_HRS, WORK_COMP_CD, LAB_LOC_CD, ORG_ID, ACCT_ID, PROJ_ID, BILL_LAB_CAT_CD, REF_STRUC_1_ID, REF_STRUC_2_ID,
          ORG_ABBRV_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO, EFFECT_BILL_DT,PROJ_ACCT_ABBRV_CD, NOTES) 
         SELECT TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO, SUB_PD_NO,
                CORRECTING_REF_DT, PAY_TYPE, GENL_LAB_CAT_CD, S_TS_LN_TYPE_CD, LAB_CST_AMT,
                CHG_HRS, WORK_COMP_CD, LAB_LOC_CD, ORG_ID, ACCT_ID, PROJ_ID, BILL_LAB_CAT_CD, REF_STRUC_1_ID, REF_STRUC_2_ID,
                ORG_ABBRV_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO, EFFECT_BILL_DT, PROJ_ACCT_ABBRV_CD, NOTES
           FROM dbo.XX_R22_CERIS_RETRO_TS_PREP2
 
  
   END

IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

RETURN(0)
	
BL_ERROR_HANDLER:
	
PRINT 'ERROR UPDATING TABLE'
RETURN(1)

END


go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_R22_CERIS_RESPROC_RECORDS_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_CERIS_RESPROC_RECORDS_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_CERIS_RESPROC_RECORDS_SP >>>'
go

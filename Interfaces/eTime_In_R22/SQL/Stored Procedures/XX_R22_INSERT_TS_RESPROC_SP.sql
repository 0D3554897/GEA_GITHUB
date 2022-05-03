IF OBJECT_ID('dbo.XX_R22_INSERT_TS_RESPROC_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_INSERT_TS_RESPROC_SP
    IF OBJECT_ID('dbo.XX_R22_INSERT_TS_RESPROC_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_INSERT_TS_RESPROC_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_INSERT_TS_RESPROC_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go

CREATE procedure [dbo].[XX_R22_INSERT_TS_RESPROC_SP]
as

/************************************************************************************************  
Name:       	XX_R22_INSERT_TS_RESPROC_SP
Author:     	Tejas Patel
Created:    	07/2008  
Purpose:    	

	
	THIS ENTIRE STORED PROCEDURE IS FOR CR-1649 Div.22
	
	IMAPS ETIME-R22 INTERFACE HAS 2 TYPES OF logic
	
	1.Exempt employee
	2.Non-Exempt employee

	Exempt emplyee needs a special logic to reclassify the hours between default account and special account.
	Non-Exempt employee needs a special logic to default the account when the pay_type is OT
	THIS STORED PROCEDURE HANDLES CASES 1 AND 2

execute XX_R22_INSERT_TS_RESPROC_SP

Prerequisites: 	none 
Version: 	1.0
					CASE in Comment Added - 08/28/08
					PD/SUBPD added 09/02/2008
					Modified for ACCT_ID logic for Reclass 11/05/08
					Modified for Rounding fix and Blocking reclass lines when Tot TC Hrs<Std Hrs 11/11/2008
                    CR-1821     Modified for Account Reclass Map 
					DR-1875/CR-1901		Modified for MTCs processed as R timecards
                    CR-1901             Modified to fix some issues in cursor four 03/03/2009
					CR-2230		Modified for Backout Split line issue
                    DR-2809     Modified for convert of ts_hdr_seq_issue 09/27/2010
                    CR-2995     Modified for changing TS_DT logic to remove Friday function 02/03/2015
************************************************************************************************/ 
BEGIN
DECLARE
        @in_EMPL_ID            char(12),
        @in_EFFECT_DT          datetime,
        @in_END_DT             datetime,
        @in_exmpt_fl           char(1),
        @in_TS_DT              datetime,
        @in_PROJ_ABBRV_CD      varchar(6),
        @in_PAY_TYPE           varchar(3),
        @in_BILL_LAB_CAT_CD    varchar(6),
        @in_STD_EST_HRS             numeric(14,2),
        @in_total_by_proj_plc_ptype numeric(14,2),
        @in_total_by_tc             numeric(14,2),
        @in_hrs_for_def_acc         numeric(14,2),
        @in_hrs_for_non_def_acc     numeric(14,2),
		@in_empl_org_id			varchar(20),
		@in_reclass_proj_abbrv_cd	varchar(6),
		@in_reclass_acct_id		varchar(10),
        @in_S_TS_TYPE_CD       char(2),
        @in_WORK_STATE_CD      char(2),
        @in_effect_bill_dt_for_split_record datetime,
		@in_correcting_ref_dt	datetime,
		@in_hrs_for_def_acc_factor numeric(14,3), -- Added 11/11/2008 Proper Calculation
		@out_ACCT_ID			varchar(10),
		@out_PROJ_ABBRV_CD		varchar(6),
		@out_BILL_LAB_CAT_CD	varchar(6),
		@out_notes				varchar(14),
		@in_pd_no				varchar(2),	-- Added 09/02/2008
		@in_sub_pd_no			varchar(2)	-- Added 09/02/2008




-- Set Constants
set @out_ACCT_ID='41-01-71'
set @out_PROJ_ABBRV_CD='IBM1'
set @out_BILL_LAB_CAT_CD='RONE'

--Req#3.4.5
-- Non Exempt and Regular Employee and Paytype='OT'
UPDATE dbo.XX_R22_IMAPS_TS_PREP_TEMP
SET ACCT_ID='41-81-61'
--SELECT EMPL_ID, ACCT_ID, empl_class_cd, exmpt_fl
FROM dbo.XX_R22_IMAPS_TS_PREP_TEMP ts
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
where exmpt_fl='N' and empl_lab.EMPL_CLASS_CD='1' and ts.pay_type='OT'

-- Non Exempt and Non-Regular Employee and PayType='OT'
UPDATE dbo.XX_R22_IMAPS_TS_PREP_TEMP
SET ACCT_ID='41-81-65'
--SELECT EMPL_ID, ACCT_ID, empl_class_cd, exmpt_fl
FROM dbo.XX_R22_IMAPS_TS_PREP_TEMP ts
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
where exmpt_fl='N' and empl_lab.EMPL_CLASS_CD='2' and ts.pay_type='OT'

-- CR-2995 begin
-- Ensure that for split week, records for non-exempt employees with PAY_TYPE = 'BO' and S_TS_TYPE_CD = 'C'
-- have TS_DT = CORRECTING_REF_DT = EFFECT_BILL_DT
UPDATE dbo.XX_R22_IMAPS_TS_PREP_TEMP
   SET CORRECTING_REF_DT = TS_DT,
       EFFECT_BILL_DT = TS_DT,
       REF_STRUC_1_ID = 'CR2995_UPDATE'
  FROM dbo.XX_R22_IMAPS_TS_PREP_TEMP t1,
       IMAR.DELTEK.EMPL_LAB_INFO t2
 WHERE t1.EMPL_ID = t2.EMPL_ID
   AND t2.EFFECT_DT = (select MAX(t3.EFFECT_DT) from IMAR.DELTEK.EMPL_LAB_INFO t3 where t3.EMPL_ID = t2.EMPL_ID)
   AND t2.EXMPT_FL = 'N' -- only non-exempt employees
   AND t1.PAY_TYPE = 'BO'
   AND t1.S_TS_TYPE_CD = 'C'
   AND t1.CORRECTING_REF_DT <> t1.TS_DT
   AND t1.EFFECT_BILL_DT <> t1.TS_DT
-- CR-2995 end

-- This cursor will calculate the hours for default account, and special account.
DECLARE cursor_two CURSOR FAST_FORWARD FOR
   SELECT  ts.empl_id, empl_lab.effect_dt, empl_lab.end_dt, empl_lab.exmpt_fl,
  ts.ts_dt, ts.correcting_ref_dt, ts.proj_abbrv_cd, pay_type, ts.bill_lab_cat_cd, 
    -- Added 03/09/2009 CR-1901, IF N type then standard hrs will be -ve as later on we use it for > comparision
    case when s_ts_type_cd='N' then cast( (empl_lab.std_est_hrs/52)*-1 as numeric(14,2) )
        else
        cast( (empl_lab.std_est_hrs/52) as numeric(14,2) )
        END STD_EST_HRS, 
    sum(cast( ts.chg_hrs as numeric (14,2))) total_by_proj_plc_ptype ,

    (select sum(cast( chg_hrs as numeric(14,2))) 
        from dbo.XX_R22_IMAPS_TS_PREP_TEMP
   where empl_id=ts.EMPL_ID
    and s_ts_type_cd=ts.S_TS_TYPE_CD
               and dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS_DT)=dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.TS_DT)
				-- Added 03/08/2009 This will calculate sum of hrs for N, D lines
               and isnull(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt),'01-01-2078')=isnull(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.correcting_ref_dt),'01-01-2078')
        group by empl_id, s_ts_type_cd, dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS_DT)) total_by_tc ,

     convert(numeric(14,2),sum(CONVERT(numeric(14,2),ts.chg_hrs))* (empl_lab.std_est_hrs/52)/
                            (select abs(sum(cast( chg_hrs as numeric(14,2))))
                                from dbo.XX_R22_IMAPS_TS_PREP_TEMP
                                where empl_id=ts.EMPL_ID
                                       and s_ts_type_cd=ts.S_TS_TYPE_CD
										-- Added 03/08/2009 This will calculate sum of hrs for N, D lines
									   and isnull(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt),'01-01-2078')=isnull(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.correcting_ref_dt),'01-01-2078')
                                       and dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS_DT)=dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.TS_DT)
                                group by empl_id, s_ts_type_cd, dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS_DT)) 
            ) hrs_for_def_acc  ,
        convert(numeric(14,2),sum(cast( ts.chg_hrs as numeric(14,2)))-
     convert(numeric(14,2),sum(CONVERT(numeric(14,2),ts.chg_hrs))* (empl_lab.std_est_hrs/52)/
                            (select abs(sum(cast( chg_hrs as numeric(14,2))))
                                from dbo.XX_R22_IMAPS_TS_PREP_TEMP
                                where empl_id=ts.EMPL_ID
                                       and s_ts_type_cd=ts.S_TS_TYPE_CD
									-- Added 03/08/2009 This will calculate sum of hrs for N, D lines
									and isnull(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt),'01-01-2078')=isnull(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.correcting_ref_dt),'01-01-2078')
                                       and dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS_DT)=dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.TS_DT)
                                group by empl_id, s_ts_type_cd, dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS_DT)) 
            ) 
    )hrs_for_non_def_acc,
    ts_dt effect_bill_dt_for_split_record,
    s_ts_type_cd,
	ISNULL((SELECT distinct map.acct_id
			from XX_R22_ACCT_RECLASS map
			where map.lab_grp_type=empl_lab.lab_grp_type
			and map.acct_grp_cd=prj.acct_grp_cd
            and line_type='RECLASS'),'99-99-99') ACCT_ID
FROM dbo.XX_R22_IMAPS_TS_PREP_TEMP ts
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
INNER JOIN IMAR.DELTEK.proj prj
on (ts.proj_abbrv_cd=prj.proj_abbrv_cd and prj.company_id=2)
where exmpt_fl='Y'
--and ts.empl_id in ('R00270','R00238','R00255','R00869','R01307', 'R01656', 'R00149')
group by empl_lab.empl_id, empl_lab.effect_dt, ts.correcting_ref_dt, 
	(empl_lab.std_est_hrs/52),empl_lab.end_dt, empl_lab.exmpt_fl ,
	ts.empl_id, ts.TS_DT, ts.proj_abbrv_cd, pay_type, ts.bill_lab_cat_cd, s_ts_type_cd, empl_lab.org_id, empl_lab.lab_grp_type, prj.proj_id, prj.acct_grp_cd
	

-- Empty the temporary stage table so we can load new records from TS_PREP_TEMP table
truncate table dbo.XX_R22_IMAPS_TS_PREP_TEMP2

-- Initate the loading of TEMP2 table
OPEN cursor_two
FETCH cursor_two
INTO    @in_EMPL_ID,         @in_EFFECT_DT     ,@in_END_DT ,        @in_exmpt_fl,        @in_TS_DT,@in_correcting_ref_dt,
        @in_PROJ_ABBRV_CD,   @in_PAY_TYPE,      @in_bill_lab_cat_cd, @in_STD_EST_HRS, 
        @in_total_by_proj_plc_ptype,        @in_total_by_tc,        @in_hrs_for_def_acc,        @in_hrs_for_non_def_acc,
       @in_effect_bill_dt_for_split_record, @in_s_ts_type_cd, @in_reclass_acct_id

WHILE (@@fetch_status = 0)
BEGIN

-- Modified 11/11/2008
-- Resolve rounding issue
set @in_hrs_for_def_acc_factor=convert( numeric(14,3),@in_hrs_for_def_acc/@in_total_by_proj_plc_ptype)

/*
SELECT    @in_EMPL_ID,    @in_EFFECT_DT     ,@in_END_DT ,        @in_exmpt_fl,      @in_TS_DT, @in_correcting_ref_dt,
        @in_PROJ_ABBRV_CD,   @in_PAY_TYPE,      @in_bill_lab_cat_cd, @in_STD_EST_HRS,
        @in_total_by_proj_plc_ptype,        @in_total_by_tc,        @in_hrs_for_def_acc, @in_hrs_for_def_acc_factor, @in_hrs_for_non_def_acc,
       @in_effect_bill_dt_for_split_record, @in_s_ts_type_cd
*/
--select empl_id, chg_hrs, chg_hrs*@in_hrs_for_def_acc_factor, chg_hrs-(chg_hrs*@in_hrs_for_def_acc_factor)
-- 1st Insert with Default Project Account


INSERT INTO dbo.XX_R22_IMAPS_TS_PREP_TEMP2
           (TS_DT           ,EMPL_ID           ,S_TS_TYPE_CD           ,WORK_STATE_CD           ,FY_CD           ,PD_NO
           ,SUB_PD_NO           ,CORRECTING_REF_DT           ,PAY_TYPE            ,GENL_LAB_CAT_CD           ,S_TS_LN_TYPE_CD
           ,LAB_CST_AMT           ,CHG_HRS           ,WORK_COMP_CD           ,LAB_LOC_CD           ,ORG_ID
           ,ACCT_ID           ,PROJ_ID           ,BILL_LAB_CAT_CD           ,REF_STRUC_1_ID           ,REF_STRUC_2_ID
           ,ORG_ABBRV_CD           ,PROJ_ABBRV_CD           ,TS_HDR_SEQ_NO           ,EFFECT_BILL_DT           ,PROJ_ACCT_ABBRV_CD
           ,NOTES)

SELECT TS_DT      ,EMPL_ID      ,S_TS_TYPE_CD      ,WORK_STATE_CD      ,FY_CD      ,PD_NO      ,SUB_PD_NO
      ,CORRECTING_REF_DT      ,PAY_TYPE       ,GENL_LAB_CAT_CD      ,S_TS_LN_TYPE_CD      ,LAB_CST_AMT
    --,convert(decimal(14,2),(convert(decimal(14,2),chg_hrs)*@in_hrs_for_def_acc_factor)) CHG_HRS
       -- ABS added for N lines CR-1901
      ,CASE WHEN abs(@in_STD_EST_HRS)>=abs(@in_total_by_tc) THEN convert(decimal(14,2),chg_hrs)  -- Modified added 11/11/2008
			ELSE convert(decimal(14,2),(convert(decimal(14,2),chg_hrs)*@in_hrs_for_def_acc_factor))
			END
      ,WORK_COMP_CD      ,LAB_LOC_CD      ,ORG_ID      ,ACCT_ID      ,PROJ_ID      ,BILL_LAB_CAT_CD
      ,REF_STRUC_1_ID      ,REF_STRUC_2_ID      ,ORG_ABBRV_CD      ,PROJ_ABBRV_CD      ,TS_HDR_SEQ_NO
      ,EFFECT_BILL_DT      ,PROJ_ACCT_ABBRV_CD      ,
		substring(notes,1,CHARINDEX('-', notes, 1))
		+substring(notes, CHARINDEX('-', notes, 1)+1, (CHARINDEX('-', notes, (CHARINDEX('-', notes, 1)+1))-CHARINDEX('-', notes, 1)-1) )
		+CASE WHEN abs(@in_STD_EST_HRS)>=abs(@in_total_by_tc) THEN '-'  -- Modified > sign added 11/11/2008 -- Modified CR-1901 ABS added for N lines
			ELSE '-A-'
			END
		+substring(notes, CHARINDEX('ACTVT_CD', notes, 1), len(notes)) NOTES

from dbo.XX_R22_IMAPS_TS_PREP_TEMP ts
where rtrim(ts.empl_id)=rtrim(@in_empl_id)
    and rtrim(ts.s_ts_type_cd)=rtrim(@in_S_TS_TYPE_CD)
    and ts.ts_dt=@in_TS_DT
    and ts.proj_abbrv_Cd=@in_PROJ_ABBRV_CD
    and ISNULL(cast(ts.correcting_ref_dt as datetime),'')=ISNULL(cast(@in_CORRECTING_REF_DT as datetime),'')
   and ts.bill_lab_cat_cd=@in_bill_lab_cat_cd
    and ts.pay_type=@in_pay_type


-- Reclass 2nd Insert with Special Project Account

	INSERT INTO dbo.XX_R22_IMAPS_TS_PREP_TEMP2
           	(TS_DT           ,EMPL_ID           ,S_TS_TYPE_CD           ,WORK_STATE_CD           ,FY_CD ,PD_NO
  	,SUB_PD_NO           ,CORRECTING_REF_DT           ,PAY_TYPE   ,GENL_LAB_CAT_CD           ,S_TS_LN_TYPE_CD
           	,LAB_CST_AMT           ,CHG_HRS           ,WORK_COMP_CD  ,LAB_LOC_CD   ,ORG_ID
           	,ACCT_ID           ,PROJ_ID ,BILL_LAB_CAT_CD           ,REF_STRUC_1_ID           ,REF_STRUC_2_ID
           	,ORG_ABBRV_CD           ,PROJ_ABBRV_CD   ,TS_HDR_SEQ_NO           ,EFFECT_BILL_DT           ,PROJ_ACCT_ABBRV_CD
           	,NOTES)
           	
	SELECT TS_DT      ,EMPL_ID      ,S_TS_TYPE_CD      ,WORK_STATE_CD      ,FY_CD      ,PD_NO      ,SUB_PD_NO
      	,CORRECTING_REF_DT      ,PAY_TYPE       ,GENL_LAB_CAT_CD      ,S_TS_LN_TYPE_CD      ,LAB_CST_AMT
      	--,convert(decimal(14,2),chg_hrs)-convert(decimal(14,2),(convert(decimal(14,2),chg_hrs)*@in_hrs_for_def_acc_factor)) CHG_HRS
      ,CASE WHEN abs(@in_STD_EST_HRS)>=abs(@in_total_by_tc) THEN 0.00 -- Modified added 11/11/2008
			ELSE convert(decimal(14,2),chg_hrs)-convert(decimal(14,2),(convert(decimal(14,2),chg_hrs)*@in_hrs_for_def_acc_factor))
			END
      	,WORK_COMP_CD      ,LAB_LOC_CD      ,ORG_ID      ,@in_reclass_acct_id      ,PROJ_ID      ,BILL_LAB_CAT_CD
      	,REF_STRUC_1_ID      ,REF_STRUC_2_ID      ,ORG_ABBRV_CD      ,PROJ_ABBRV_CD      ,TS_HDR_SEQ_NO
      	,EFFECT_BILL_DT      ,PROJ_ACCT_ABBRV_CD      ,
			substring(notes,1,CHARINDEX('-', notes, 1))
			+substring(notes, CHARINDEX('-', notes, 1)+1, (CHARINDEX('-', notes, (CHARINDEX('-', notes, 1)+1))-CHARINDEX('-', notes, 1)-1) )
			+'-B-'
			+substring(notes, CHARINDEX('ACTVT_CD', notes, 1), len(notes)) NOTES
	
	from dbo.XX_R22_IMAPS_TS_PREP_TEMP ts
	where rtrim(ts.empl_id)=rtrim(@in_empl_id)
    	and rtrim(ts.s_ts_type_cd)=rtrim(@in_S_TS_TYPE_CD)
    	and ts.ts_dt=@in_TS_DT
    	and ts.proj_abbrv_Cd=@in_PROJ_ABBRV_CD
    	and ISNULL(cast(ts.correcting_ref_dt as datetime),'')=ISNULL(cast(@in_CORRECTING_REF_DT as datetime),'')
    	and ts.bill_lab_cat_cd=@in_bill_lab_cat_cd
    	and ts.pay_type=@in_pay_type

FETCH cursor_two
INTO    @in_EMPL_ID,         @in_EFFECT_DT     ,@in_END_DT ,        @in_exmpt_fl,        @in_TS_DT,@in_correcting_ref_dt,
        @in_PROJ_ABBRV_CD,   @in_PAY_TYPE,      @in_bill_lab_cat_cd, @in_STD_EST_HRS, 
        @in_total_by_proj_plc_ptype,        @in_total_by_tc,        @in_hrs_for_def_acc,        @in_hrs_for_non_def_acc,
       @in_effect_bill_dt_for_split_record, @in_s_ts_type_cd, @in_reclass_acct_id

END -- end while loop

CLOSE cursor_two
DEALLOCATE cursor_two

-- Delete the records created with zero hours this happens when the total timecards hours are same or less then standard hours
DELETE from dbo.XX_R22_IMAPS_TS_PREP_TEMP2
where cast( chg_hrs as numeric(14,2))=0.00



-- Req#3.4.7 (Create -ve IBM1 line item with standard hours)
-- For Exempt Employees 
DECLARE cursor_three CURSOR FAST_FORWARD FOR
	SELECT  ts.empl_id, ts.TS_DT,  
	-- Added CR-1921
	case when
		-- This count will check if there is second split is missing
		-- if that's the case then apply 40hrs with split-1 otherwise pro rate them
		(select count(distinct ts_dt) from xx_r22_imaps_ts_prep_temp
		where empl_id=ts.empl_id 
		and dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts_dt)=dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.ts_dt)
		)=1 
			then (empl_lab.std_est_hrs/52)
		else 
		((empl_lab.std_est_hrs/52)/5) * 
                    -- Added 5/27/09 CR-2042
			-- Find Day multiplier 
			case	-- Condition for all cases simply use day of week (-1 is to exclude sunday from week)
					-- If dw of ts_dt is less then 5 then use dw-1
					when datepart(dw,ts_dt)<=5 
						then (datepart(dw,ts_dt)-1)
					-- Condition for second half of the week when week had 15th.
					-- when week had 15th then find the diff of days between ts_dt and 15th if the diff 
					-- is between 1 and 4 then use the difference e.g. 4/15/09 is Wed and 4/17 is Fri so diff is 2 days
					when datediff(day,convert(varchar(4),(datepart(yyyy,ts_dt)))+'-'+(convert(varchar(2),datepart(mm,ts_dt)))+'-15', ts_dt)<=4
						and datediff(day,convert(varchar(4),(datepart(yyyy,ts_dt)))+'-'+(convert(varchar(2),datepart(mm,ts_dt)))+'-15', ts_dt)>=1
						then datediff(day,convert(varchar(4),(datepart(yyyy,ts_dt)))+'-'+(convert(varchar(2),datepart(mm,ts_dt)))+'-15', ts_dt)
					-- Condition for second half of the week when week had 30, 31st.
					-- When 30th, 31st is in week then use diff of last day of prev month and ts_dt
					-- e.g. 
					when datediff(d,DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,ts_dt),0)),ts_dt)<=4
						then datediff(d,DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,ts_dt),0)),ts_dt)
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
 max(sub_pd_no) sub_pd_no -- Added 09/02/08,
	 ,dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.correcting_ref_dt) correcting_ref_dt -- Added 01/28/08 
	 ,s_ts_type_cd
	-- This will allow us to create BO lines for MTCs
	FROM dbo.XX_R22_IMAPS_TS_PREP_TEMP ts
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
	and ts.s_ts_type_cd in ('R','C')
	group by ts.empl_id, ts.TS_DT,  (empl_lab.std_est_hrs/52), empl_lab.org_id, empl_lab.lab_grp_type
	 ,dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.correcting_ref_dt), s_ts_type_cd
	-- Added 01/28/08
	
OPEN cursor_three
FETCH cursor_three
INTO    @in_EMPL_ID,   @in_TS_DT, @in_STD_EST_HRS, @in_total_by_tc, @in_empl_org_id, 
		@in_reclass_proj_abbrv_cd, @in_reclass_acct_id, @in_pd_no, @in_sub_pd_no 	-- Modified on 09/02/2008
		,@in_correcting_ref_dt, @in_s_ts_type_cd
WHILE (@@fetch_status = 0)
BEGIN

/* No need for this logic anymore as Etime will force it on front end
   This logic was also screwing the backout lines when employee worked more hrs in either splits
-- If the total hrs in tc is less then Std hrs then use hrs charged to create -ve entry
IF  @in_total_by_tc<@in_STD_EST_HRS 
BEGIN
	set @in_STD_EST_HRS=@in_total_by_tc
END
*/

select 
@out_notes=cast(max(cast (substring(notes, CHARINDEX('-', notes, 1)+1, (CHARINDEX('-', notes, (CHARINDEX('-', notes, 1)+1))-CHARINDEX('-', notes, 1)-1) ) as numeric)) as varchar)
 from dbo.XX_R22_IMAPS_TS_PREP_TEMP a
where empl_id=@in_empl_id
    -- Added CR-1921
    and ts_dt=@in_TS_DT
    --Commented CR-1921
    --and dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts_dt)=@in_TS_DT
	and (dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt)=cast(@in_CORRECTING_REF_DT as datetime)
			or (dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt) IS NULL)
		)
	and s_ts_type_cd=@in_s_ts_type_cd

-- 3rd Insert with -(Std Hrs) Capacity
INSERT INTO dbo.XX_R22_IMAPS_TS_PREP_TEMP2
           (TS_DT           ,EMPL_ID    ,S_TS_TYPE_CD           ,WORK_STATE_CD  ,FY_CD           ,PD_NO
  ,SUB_PD_NO       ,CORRECTING_REF_DT           ,PAY_TYPE            ,GENL_LAB_CAT_CD           ,S_TS_LN_TYPE_CD
           ,LAB_CST_AMT           ,CHG_HRS           ,WORK_COMP_CD           ,LAB_LOC_CD           ,ORG_ID
           ,ACCT_ID           ,PROJ_ID           ,BILL_LAB_CAT_CD           ,REF_STRUC_1_ID           ,REF_STRUC_2_ID
           ,ORG_ABBRV_CD           ,PROJ_ABBRV_CD           ,TS_HDR_SEQ_NO           ,EFFECT_BILL_DT           ,PROJ_ACCT_ABBRV_CD
           ,NOTES)
-- Added Friday function for TS_DT 02/18/2009 DR-1875
-- Removed Friday function for TS_DT CR-1921
SELECT DISTINCT convert(char(10),ts.ts_dt,120) ,EMPL_ID      ,'C' S_TS_TYPE_CD      ,WORK_STATE_CD      ,FY_CD      ,@in_PD_NO      ,@in_SUB_PD_NO,
	CASE WHEN @in_s_ts_type_cd='C' THEN convert(char(10),dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt),120) -- Modified added 11/11/2008
			ELSE convert(char(10),ts_dt,120)
            -- Friday function is removed CR-1921
			-- Modified for TS_DT 02/18/2008 DR-1875
			END  CORRECTING_REF_DT  ,
	'BO' PAY_TYPE       ,GENL_LAB_CAT_CD      ,S_TS_LN_TYPE_CD      ,NULL LAB_CST_AMT
      ,-(@in_STD_EST_HRS) CHG_HRS
      ,WORK_COMP_CD      ,LAB_LOC_CD      ,@in_empl_org_id ORG_ID      ,
		 @in_reclass_acct_id ACCT_ID      ,
		PROJ_ID ,@out_BILL_LAB_CAT_CD
      ,REF_STRUC_1_ID      ,REF_STRUC_2_ID      ,ORG_ABBRV_CD      ,@in_reclass_proj_abbrv_cd PROJ_ABBRV_CD ,
      (select cast(max(cast(ts_hdr_seq_no as decimal(4,0)))+1 as varchar(3)) --Modified DR-2809 09/27/2010
        from dbo.XX_R22_IMAPS_TS_PREP_TEMP2 ts2 --Use temp2 as we have added more backout lines so seq_no will be based on that
        where rtrim(ts2.empl_id)=rtrim(ts.empl_id)
        and ts2.ts_dt= ts.ts_dt
	    and s_ts_type_cd in ('R', 'N','C','D') -- Added Tejas 01/27/08
        )TS_HDR_SEQ_NO,
			CASE WHEN @in_s_ts_type_cd='C' THEN convert(char(10),dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt),120) -- Modified added 11/11/2008
			ELSE convert(char(10),ts_dt,120)
            -- Friday function removed CR-1921
			-- Modified for Effect_Bill_DT 02/18/2008 DR-1875
			END  EFFECT_BILL_DT  ,
		PROJ_ACCT_ABBRV_CD      ,
		substring(notes,1,CHARINDEX('-', notes, 1))
		+@out_notes
		+'-C-' NOTES

from dbo.XX_R22_IMAPS_TS_PREP_TEMP ts
where rtrim(ts.empl_id)=rtrim(@in_empl_id)
    and ts.ts_dt=@in_TS_DT
    -- Friday Function removed CR-1921
	and (isnull(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.correcting_ref_dt),'')=isnull(cast(@in_CORRECTING_REF_DT as datetime),'')
			or (dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.correcting_ref_dt) IS NULL)
		)
	and s_ts_type_cd=@in_s_ts_type_cd

FETCH cursor_three
INTO    @in_EMPL_ID,   @in_TS_DT, @in_STD_EST_HRS, @in_total_by_tc, @in_empl_org_id, 
		@in_reclass_proj_abbrv_cd, @in_reclass_acct_id, @in_pd_no, @in_sub_pd_no, @in_correcting_ref_dt, @in_s_ts_type_cd

END 
CLOSE cursor_three
DEALLOCATE cursor_three

-- Req#3.4.7 (Create -ve IBM1 line item with standard hours)
-- For Non-Exempt employees
DECLARE cursor_four CURSOR FAST_FORWARD FOR
	SELECT  ts.empl_id, ts.TS_DT,  -- Friday Func removed CR-1921
	-- Added CR-1921
	case when
		-- This count will check if there is second split is missing
		-- if that's the case then apply 40hrs with split-1 otherwise pro rate them
		(select count(distinct ts_dt) from xx_r22_imaps_ts_prep_temp
		where empl_id=ts.empl_id 
		and dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts_dt)=dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.ts_dt)
		)=1 
			then (empl_lab.std_est_hrs/52)
		else 
		((empl_lab.std_est_hrs/52)/5) * 
            -- Added 5/27/09 CR-2042
			-- Find Day multiplier 
			case	-- Condition for all cases simply use day of week (-1 is to exclude sunday from week)
					-- If dw of ts_dt is less then 5 then use dw-1
					when datepart(dw,ts_dt)<=5 
						then (datepart(dw,ts_dt)-1)
					-- Condition for second half of the week when week had 15th.
					-- when week had 15th then find the diff of days between ts_dt and 15th if the diff 
					-- is between 1 and 4 then use the difference e.g. 4/15/09 is Wed and 4/17 is Fri so diff is 2 days
					when datediff(day,convert(varchar(4),(datepart(yyyy,ts_dt)))+'-'+(convert(varchar(2),datepart(mm,ts_dt)))+'-15', ts_dt)<=4
						and datediff(day,convert(varchar(4),(datepart(yyyy,ts_dt)))+'-'+(convert(varchar(2),datepart(mm,ts_dt)))+'-15', ts_dt)>=1
						then datediff(day,convert(varchar(4),(datepart(yyyy,ts_dt)))+'-'+(convert(varchar(2),datepart(mm,ts_dt)))+'-15', ts_dt)
					-- Condition for second half of the week when week had 30, 31st.
					-- When 30th, 31st is in week then use diff of last day of prev month and ts_dt
					-- e.g. 
					when datediff(d,DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,ts_dt),0)),ts_dt)<=4
						then datediff(d,DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,ts_dt),0)),ts_dt)
				else 5 --Else Standard Days will be 5 only and no need for following logic
					-- Commented CR-2230 07/31/09 
					--(datepart(dw,dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.TS_DT))) -(datepart(dw,cast(ts_dt as datetime)-1))
				end
			/*	case when datepart(day,ts_dt)=16 then 
					(datepart(dw,dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.TS_DT))-1) -(datepart(dw,cast(ts_dt as datetime)-1-1))
				else (datepart(dw,ts_dt)-1)
				end */
	end,
	sum(cast(ts.chg_hrs as numeric(14,2))) chg_hrs,
	empl_lab.org_id empl_org_id,
	(select distinct proj_abbrv_cd from IMAR.DELTEK.proj 
        where company_id=2 
        and rtrim(org_id)=rtrim(empl_lab.org_id) 
        and substring(proj_id,1,4)='RRDE'
        and empl_lab.org_id is not null
        and proj_abbrv_cd is not null 
        and rtrim(proj_abbrv_cd)<>'') reclass_proj_abbrv_cd,
	-- Modified 11/05/2008
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
     max(sub_pd_no) sub_pd_no -- Added 09/02/08
	,dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.correcting_ref_dt) correcting_ref_dt -- Added 01/28/08 
	 ,s_ts_type_cd
	-- This will allow us to create BO lines for MTCs
			
	FROM dbo.XX_R22_IMAPS_TS_PREP_TEMP ts
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
	where exmpt_fl='N'
	and ts.s_ts_type_cd in ('R','C')
	group by ts.empl_id, ts.TS_DT,  (empl_lab.std_est_hrs/52), 
	empl_lab.org_id, empl_lab.lab_grp_type
	 ,dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.correcting_ref_dt), s_ts_type_cd
	-- Added 01/28/08

OPEN cursor_four
FETCH cursor_four
INTO    @in_EMPL_ID,   @in_TS_DT, @in_STD_EST_HRS, @in_total_by_tc, @in_empl_org_id, 
		@in_reclass_proj_abbrv_cd, @in_reclass_acct_id, @in_pd_no, @in_sub_pd_no -- Modified 09/02/2008
		,@in_correcting_ref_dt -- added 01/28/2008
		,@in_s_ts_type_cd	-- added 01/28/2008
WHILE (@@fetch_status = 0)
BEGIN

/* No need for this logic anymore as Etime will force it on front end
   This logic was also screwing the backout lines when employee worked more hrs in either splits
-- If the total hrs in tc is less then Std hrs then use hrs charged to create -ve entry
IF  @in_total_by_tc<@in_STD_EST_HRS 
BEGIN
	set @in_STD_EST_HRS=@in_total_by_tc
END
*/

-- Modified for CR-1901 Block copied from Exempt employee
select 
@out_notes=cast(max(cast (substring(notes, CHARINDEX('-', notes, 1)+1, (CHARINDEX('-', notes, (CHARINDEX('-', notes, 1)+1))-CHARINDEX('-', notes, 1)-1) ) as numeric)) as varchar)
 from dbo.XX_R22_IMAPS_TS_PREP_TEMP a
where empl_id=@in_empl_id
    and ts_dt=@in_TS_DT -- Friday Func Removed CR-1921
	and (dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt)=cast(@in_CORRECTING_REF_DT as datetime)
			or (dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt) IS NULL)
		)
	and s_ts_type_cd=@in_s_ts_type_cd

-- 3rd Insert with -(Std Hrs) Capacity
INSERT INTO dbo.XX_R22_IMAPS_TS_PREP_TEMP2
           (TS_DT           ,EMPL_ID    ,S_TS_TYPE_CD           ,WORK_STATE_CD  ,FY_CD           ,PD_NO
		  ,SUB_PD_NO       ,CORRECTING_REF_DT           ,PAY_TYPE            ,GENL_LAB_CAT_CD           ,S_TS_LN_TYPE_CD
           ,LAB_CST_AMT           ,CHG_HRS           ,WORK_COMP_CD           ,LAB_LOC_CD           ,ORG_ID
           ,ACCT_ID           ,PROJ_ID           ,BILL_LAB_CAT_CD           ,REF_STRUC_1_ID           ,REF_STRUC_2_ID
           ,ORG_ABBRV_CD           ,PROJ_ABBRV_CD           ,TS_HDR_SEQ_NO           ,EFFECT_BILL_DT           ,PROJ_ACCT_ABBRV_CD
           ,NOTES)
-- Added Friday function for TS_DT 02/18/2009 DR-1875
-- removed Friday function for TS_DT CR-1921
SELECT DISTINCT convert(char(10),ts.ts_dt,120) ,EMPL_ID      ,'C' S_TS_TYPE_CD   ,WORK_STATE_CD      ,FY_CD      ,@in_PD_NO      ,@in_SUB_PD_NO,
	CASE WHEN @in_s_ts_type_cd='C' THEN convert(char(10),dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt),120) -- Modified added 11/11/2008
-- CR-2995_begin
-- Get rid of the use of Friday function for CORRECTING_REF_DT
--			ELSE convert(char(10),dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts_dt),120)
			ELSE convert(char(10), TS_DT, 120)
-- CR-2995_end
			-- Modified for TS_DT 02/18/2008 DR-1875
			END  CORRECTING_REF_DT  ,
	'BO' PAY_TYPE       ,GENL_LAB_CAT_CD      ,S_TS_LN_TYPE_CD      ,NULL LAB_CST_AMT
      ,-(@in_STD_EST_HRS) CHG_HRS
   ,WORK_COMP_CD      ,LAB_LOC_CD      ,@in_empl_org_id ORG_ID      ,
		 @in_reclass_acct_id ACCT_ID      ,
		PROJ_ID      ,@out_BILL_LAB_CAT_CD
      ,REF_STRUC_1_ID      ,REF_STRUC_2_ID      ,ORG_ABBRV_CD      ,@in_reclass_proj_abbrv_cd PROJ_ABBRV_CD ,
      (select cast(max(cast(ts_hdr_seq_no as decimal(4,0)))+1 as varchar(3)) --Modified DR-2809 09/27/2010
        from dbo.XX_R22_IMAPS_TS_PREP_TEMP ts2 --Use temp (for non-exempt) as we have added more backout lines so seq_no will be based on that
        where rtrim(ts2.empl_id)=rtrim(ts.empl_id)
        and ts2.ts_dt= ts.ts_dt
	    and s_ts_type_cd in ('R', 'N','C','D') -- Added Tejas 01/27/08
        )TS_HDR_SEQ_NO,
			CASE WHEN @in_s_ts_type_cd='C' THEN convert(char(10),dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt),120) -- Modified added 11/11/2008
-- CR-2995_begin
-- Get rid of the use of Friday function for EFFECT_BILL_DT
--			ELSE convert(char(10),dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts_dt),120)
			ELSE convert(char(10), TS_DT, 120)
-- CR-2995_end
			-- Modified for Effect_Bill_DT 02/18/2008 DR-1875
			END  EFFECT_BILL_DT  ,
		PROJ_ACCT_ABBRV_CD      ,
		substring(notes,1,CHARINDEX('-', notes, 1))
		+@out_notes
		+'-C-' NOTES

from dbo.XX_R22_IMAPS_TS_PREP_TEMP ts
where rtrim(ts.empl_id)=rtrim(@in_empl_id)
    and ts.ts_dt=@in_TS_DT -- Modified CR-1921
	and (isnull(dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.correcting_ref_dt),'')=isnull(cast(@in_CORRECTING_REF_DT as datetime),'')
			or (dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts.correcting_ref_dt) IS NULL)
		)
	and s_ts_type_cd=@in_s_ts_type_cd

FETCH cursor_four
INTO    @in_EMPL_ID,   @in_TS_DT, @in_STD_EST_HRS, @in_total_by_tc, @in_empl_org_id, 
		@in_reclass_proj_abbrv_cd, @in_reclass_acct_id, @in_pd_no, @in_sub_pd_no -- Modified 09/02/2008
		,@in_correcting_ref_dt -- added 01/28/2008
		,@in_s_ts_type_cd	-- added 01/28/2008
END 
CLOSE cursor_four
DEALLOCATE cursor_four

-- Update ACCT_ID with 99-99-99 for all A, B lines so they gets miscoded We dont want null value to be passed to preproc
UPDATE XX_R22_IMAPS_TS_PREP_TEMP2
SET ACCT_ID='99-99-99'
WHERE ACCT_ID IS NULL
AND notes like '%-A-%' and notes like '%-B-%' and notes like '%-C-%'

-- Clean up the TEMP2 table if the sum of hours matches before and after split
DECLARE @out_check_sum1 numeric(14,2),
		@out_check_sum2 numeric(14,2)

select @out_check_sum1=sum(cast(chg_hrs as numeric(14,2)))
FROM dbo.XX_R22_IMAPS_TS_PREP_TEMP ts
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

select @out_check_sum2=sum(cast(chg_hrs as numeric(14,2)))
FROM dbo.XX_R22_IMAPS_TS_PREP_TEMP2 ts
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
where exmpt_fl='Y' and TS.NOTES not like '%-C-%'

print @out_check_sum1


IF @out_check_sum1<>@out_check_sum2 
	BEGIN
		PRINT 'Sum of hours are not matching'
		GOTO BL_ERROR_HANDLER

	END

ELSE

-- IF the total hours in TEMP and TEMP2 tables are matching for Exempt employees then 
-- Delete the data from TEMP table and xfer the data from TEMP2 table
BEGIN

	DELETE FROM dbo.XX_R22_IMAPS_TS_PREP_TEMP 
	FROM dbo.XX_R22_IMAPS_TS_PREP_TEMP ts
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

INSERT INTO IMAPSStg.dbo.XX_R22_IMAPS_TS_PREP_TEMP
           (TS_DT           ,EMPL_ID           ,S_TS_TYPE_CD           ,WORK_STATE_CD           ,FY_CD
           ,PD_NO           ,SUB_PD_NO           ,CORRECTING_REF_DT           ,PAY_TYPE            ,GENL_LAB_CAT_CD
           ,S_TS_LN_TYPE_CD           ,LAB_CST_AMT           ,CHG_HRS           ,WORK_COMP_CD           ,LAB_LOC_CD
           ,ORG_ID           ,ACCT_ID           ,PROJ_ID           ,BILL_LAB_CAT_CD           ,REF_STRUC_1_ID
           ,REF_STRUC_2_ID           ,ORG_ABBRV_CD           ,PROJ_ABBRV_CD           ,TS_HDR_SEQ_NO           ,EFFECT_BILL_DT
           ,PROJ_ACCT_ABBRV_CD           ,NOTES) 
SELECT 	TS_DT           ,EMPL_ID           ,S_TS_TYPE_CD           ,WORK_STATE_CD    ,FY_CD
           ,PD_NO           ,SUB_PD_NO           ,CORRECTING_REF_DT           ,PAY_TYPE            ,GENL_LAB_CAT_CD
           ,S_TS_LN_TYPE_CD           ,LAB_CST_AMT           ,CHG_HRS           ,WORK_COMP_CD        ,LAB_LOC_CD
           ,ORG_ID           ,ACCT_ID           ,PROJ_ID           ,BILL_LAB_CAT_CD       ,REF_STRUC_1_ID
           ,REF_STRUC_2_ID           ,ORG_ABBRV_CD           ,PROJ_ABBRV_CD           ,TS_HDR_SEQ_NO           ,EFFECT_BILL_DT
           ,PROJ_ACCT_ABBRV_CD           ,NOTES
FROM IMAPSStg.dbo.XX_R22_IMAPS_TS_PREP_TEMP2

END

--DELETE from IMAPSStg.dbo.XX_R22_IMAPS_TS_PREP_TEMP2

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	RETURN (0)
	
	BL_ERROR_HANDLER:
	
	PRINT 'ERROR UPDATING TABLE'
	RETURN(1)

END



go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_R22_INSERT_TS_RESPROC_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_INSERT_TS_RESPROC_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_INSERT_TS_RESPROC_SP >>>'
go

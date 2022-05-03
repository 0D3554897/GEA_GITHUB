IF OBJECT_ID('dbo.XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_SP
    IF OBJECT_ID('dbo.XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_SP >>>'
END
go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
CREATE PROCEDURE [dbo].[XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_SP]
  @in_ETIME_or_CERIS  CHAR(5) = null
--Developed by : KM
--Create Date: 09/27/2012
/*
Need to tweak the AUTOADJ_RT for the following special cases:

1.  if employee worked in only one part of split week
and employee is active in div for both parts of split week 
then change the auto-adjust rate to 100% for the one part of the split with hours
(div transfer factored in)

2a.  if the employee was hired in middle of week
and employee did not record hours for days before hire date
then reduce the auto-adjust rate by 20% for each week day in grouping before hir
(previous split calculation factored in)

2b.  if the employee was terminated in middle of week
and employee did not record hours for days after termination
then reduce the auto-adjust rate by 20% for each week day in grouping after termination
(previous split calculation factored in)

3.  otherwise ignore division transfers 
(it's safe to assume they happen on 1st or 16th and are handled by existing split subperiod logic)

change KM - 2012-10-18 - small problem with logic for 2a&b where employee records hours after/before term/hire on split week

CR5968 -  Change Split Week and OT Apply for Labor costing - 2013-02-06
2013-02-05 Need to change the AUTOADJ_RT 
so that split period does not result 
in different effective hourly rate between both splits

DR-7853 - Modify the code to fix the subquery that attempts to 
identify the subperiod end date associated with the Monday part 
of the split (if it is split).
Modified on: 2015-04-22
Modified By: Tejas Patel
*/

AS
BEGIN

--1a
print convert(char(20), getdate(),121)
PRINT 'LOAD HDR TEMP TABLE'

SELECT TS_DT, EMPL_ID, S_TS_TYPE_CD, TS_HDR_SEQ_NO, CORRECTING_REF_DT, AUTOADJ_RT, COL_ID_NO, 


dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(isnull(ts.correcting_ref_dt,ts.ts_dt))-4 as MONDAY,
--Modified for DR-7853: Use >= instead of >
(select SUB_PD_END_DT
from imaps.deltek.sub_pd
where SUB_PD_END_DT >= (dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(isnull(ts.correcting_ref_dt,ts.ts_dt))-4)
and SUB_PD_END_DT = (select min(SUB_PD_END_DT)
					from imaps.deltek.sub_pd
					where SUB_PD_END_DT >= (dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(isnull(ts.correcting_ref_dt,ts.ts_dt))-4)) ) as MON_SUB_PD_END_DT,


dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(isnull(ts.correcting_ref_dt,ts.ts_dt)) as FRIDAY,

(select TOP 1 DIVISION
from XX_CERIS_DIV16_STATUS
where empl_id = ts.empl_id
and division_start_dt <= isnull(ts.correcting_ref_dt,ts.ts_dt)
order by creation_dt desc) as DIVISION,

(select TOP 1 DIVISION_START_DT
from XX_CERIS_DIV16_STATUS
where empl_id = ts.empl_id
and division_start_dt <= isnull(ts.correcting_ref_dt,ts.ts_dt)
order by creation_dt desc) as DIVISION_START_DT,

(select HIRE_EFF_DT 
 from XX_CERIS_HIST_PREVIOUS
 where empl_id=ts.empl_id ) as HIRE_EFF_DT,


(select TERM_DT 
 from XX_CERIS_HIST_PREVIOUS
 where empl_id=ts.empl_id ) as TERM_DT,


'N' as SPECIAL_CASE
INTO #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR
FROM XX_DDC_PREPTBL ts
where 
0 <> (select count(1) from XX_CERIS_HIST_PREVIOUS where empl_id=ts.empl_id)

IF @@ERROR <> 0 RETURN 1



--problem with subperiod 1
--causing issues
UPDATE #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR
SET MON_SUB_PD_END_DT=MON_SUB_PD_END_DT-1
WHERE datepart(day,MON_SUB_PD_END_DT)=1

IF @@ERROR <> 0 RETURN 1




--1b
print convert(char(20), getdate(),121)
PRINT 'PRUNE HDR TEMP TABLE'
DELETE FROM #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR
WHERE 
--not split week
not (FRIDAY > MON_SUB_PD_END_DT)
and
--not employee hired mid week
not (isnull(HIRE_EFF_DT,MONDAY) > MONDAY and isnull(HIRE_EFF_DT,MONDAY) <= FRIDAY)
and
--not employee terminated mid week
not (isnull(TERM_DT,FRIDAY) < FRIDAY and isnull(TERM_DT,FRIDAY) >= MONDAY)

IF @@ERROR <> 0 RETURN 1




PRINT 'PRUNE HDR TEMP TABLE - for special case of not Exempt Salaried in both parts of split'

DELETE spc
FROM #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR spc
WHERE 
--split week
(FRIDAY > MON_SUB_PD_END_DT)
and
--not Exempt Salaried in both parts of split week
NOT
(
	'S'=(select s_hrly_sal_cd
		 from imaps.deltek.empl_lab_info
		 where empl_id=spc.empl_id
		 and MON_SUB_PD_END_DT between effect_dt and end_dt)
	and
	'S'=(select s_hrly_sal_cd
		 from imaps.deltek.empl_lab_info
		 where empl_id=spc.empl_id
		 and (MON_SUB_PD_END_DT+1) between effect_dt and end_dt)
)
--if not salaried in both parts of split, keep payroll period split



--2
print convert(char(20), getdate(),121)
PRINT 'LOAD LN TEMP TABLE' 
 
SELECT TS_DT, EMPL_ID, S_TS_TYPE_CD, TS_HDR_SEQ_NO, TS_LN_KEY, TS_LN_NO, CHG_HRS, EFFECT_BILL_DT,
dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(EFFECT_BILL_DT) as FRIDAY,
'N' as SPECIAL_CASE
INTO #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_LN
FROM IMAPS.DELTEK.TS_LN ts
WHERE
0 <> (select count(1) 
	  from #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR 
	  where ts_dt=ts.ts_dt
		and empl_id=ts.empl_id
		and s_ts_type_cd=ts.s_ts_type_cd
		and ts_hdr_seq_no=ts.ts_hdr_seq_no)

IF @@ERROR <> 0 RETURN 1



--CR5968 -  Change Split Week and OT Apply for Labor costing - 2013-02-06
--this logic needs to group N and D together
--but, the Deltek Custom code part already did that
--for CERIS, it is not an issue, the autoadjust is only on the D
--for ETIME, it is an issue
IF (isnull(@in_ETIME_or_CERIS,'CERIS') = 'ETIME')
BEGIN
	PRINT 'ETIME - change C back to N/D'
	
	UPDATE #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR
	SET S_TS_TYPE_CD=imapsstg.S_TS_TYPE_CD
	FROM 
	#XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR hdr
	inner join
	XX_IMAPS_TS_PREP_TEMP imapsstg
	on
	(hdr.empl_id=imapsstg.empl_id
	 and
	 hdr.ts_dt=imapsstg.ts_dt
	 and
	 hdr.ts_hdr_seq_no=imapsstg.ts_hdr_seq_no
	 and
	 hdr.s_ts_type_cd='C'
	 and
	 imapsstg.s_ts_type_cd in ('N','D')
	 )

	 IF @@ERROR <> 0 RETURN 1


	UPDATE #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_LN
	SET S_TS_TYPE_CD=imapsstg.S_TS_TYPE_CD
	FROM 
	#XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_LN ln
	inner join
	XX_IMAPS_TS_PREP_TEMP imapsstg
	on
	(ln.empl_id=imapsstg.empl_id
	 and
	 ln.ts_dt=imapsstg.ts_dt
	 and
	 ln.ts_hdr_seq_no=imapsstg.ts_hdr_seq_no
	 and
	 ln.s_ts_type_cd='C'
	 and
	 imapsstg.s_ts_type_cd in ('N','D'))

	 IF @@ERROR <> 0 RETURN 1
	
END




--3
print convert(char(20), getdate(),121)
PRINT 'UPDATE HDR TEMP TABLE FOR SPECIAL CASE 1' 
/*
1.  if employee worked in only one part of split week
and employee is active in div for both parts of split week 
then change the auto-adjust rate to 100% for the one part of the split with hours
(div transfer factored in)
*/
UPDATE #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR
SET SPECIAL_CASE='Y',
	AUTOADJ_RT=1.0
FROM #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR one_part
WHERE
--split week
(FRIDAY > MON_SUB_PD_END_DT)
AND
AUTOADJ_RT<>1.0
AND
--no complementary split week exists
0 = (select count(1) 
	 from #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR
	 where 
	 EMPL_ID=one_part.EMPL_ID
	 and
	 FRIDAY=one_part.FRIDAY
	 and
	 isnull(CORRECTING_REF_DT,TS_DT)<>isnull(one_part.CORRECTING_REF_DT,one_part.TS_DT)
	 and
	 AUTOADJ_RT<>one_part.AUTOADJ_RT
	 and 
	 1.0 = AUTOADJ_RT + one_part.AUTOADJ_RT)
AND
--employee was in the division in both parts of split week
(
	--one_part is only 1st half of split
	(
		isnull(CORRECTING_REF_DT,TS_DT)<>FRIDAY 
		and 
		--in div 1M/16 after that mid week date
		(
			'Y'=dbo.XX_GET_DIV16_STATUS_UF(EMPL_ID, MON_SUB_PD_END_DT+1)
			or
			'Y'=dbo.XX_GET_DIV1M_STATUS_UF(EMPL_ID, MON_SUB_PD_END_DT+1)
		)
	)
	or
	--one_part is only 2nd half of split
	(
		isnull(CORRECTING_REF_DT,TS_DT)=FRIDAY 
		and 
		--in div 1M/16 before that mid week date
		(
			'Y'=dbo.XX_GET_DIV16_STATUS_UF(EMPL_ID, MON_SUB_PD_END_DT)
			or
			'Y'=dbo.XX_GET_DIV1M_STATUS_UF(EMPL_ID, MON_SUB_PD_END_DT)
		)
	)
)


IF @@ERROR <> 0 RETURN 1






--4
print convert(char(20), getdate(),121)
PRINT 'UPDATE HDR TEMP TABLE FOR SPECIAL CASE 2a - part1' 
/*
2a.  if the employee was hired in middle of week
and employee did not record hours for days before hire date
then reduce the auto-adjust rate by 20% for each week day in grouping before hire
(previous split calculation factored in)
*/


--2013-02-05 
UPDATE #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR
SET SPECIAL_CASE='Y',
	AUTOADJ_RT= AUTOADJ_RT - (0.2 * datediff(day, MON_SUB_PD_END_DT+1, HIRE_EFF_DT))
FROM #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR ts
WHERE
--employee hired mid week
(isnull(HIRE_EFF_DT,MONDAY) > MONDAY and isnull(HIRE_EFF_DT,MONDAY) <= FRIDAY)
AND
--employee did not record hours for days before hire date
--KM - 2012-10-18
0 = isnull((select count(1) 
     from #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_LN
	 where  --ts_dt=ts.ts_dt and
			empl_id=ts.empl_id
			and s_ts_type_cd=ts.s_ts_type_cd
			--and ts_hdr_seq_no=ts.ts_hdr_seq_no
			and effect_bill_dt < ts.hire_eff_dt
	 group by empl_id, s_ts_type_cd
	 having sum(cast(chg_hrs as decimal(14,2)))<>0),0)
and
--and ts is for second part of split week
(	(AUTOADJ_RT<>1.0 and isnull(CORRECTING_REF_DT,TS_DT)=FRIDAY and hire_eff_dt > MON_SUB_PD_END_DT) 
)
			

IF @@ERROR <> 0 RETURN 1





print convert(char(20), getdate(),121)
PRINT 'UPDATE HDR TEMP TABLE FOR SPECIAL CASE 2a - part2' 

--2013-02-05
--update, there is actually a small bug here
--need to fix it with the following

UPDATE #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR
SET SPECIAL_CASE='Y',
	AUTOADJ_RT= AUTOADJ_RT - (0.2 * datediff(day, MONDAY, HIRE_EFF_DT))
FROM #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR ts
WHERE
--employee hired mid week
(isnull(HIRE_EFF_DT,MONDAY) > MONDAY and isnull(HIRE_EFF_DT,MONDAY) <= FRIDAY)
AND
--employee did not record hours for days before hire date
--KM - 2012-10-18
0 = isnull((select count(1) 
     from #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_LN
	 where  --ts_dt=ts.ts_dt and
			empl_id=ts.empl_id
			and s_ts_type_cd=ts.s_ts_type_cd
			--and ts_hdr_seq_no=ts.ts_hdr_seq_no
			and effect_bill_dt < ts.hire_eff_dt
	 group by empl_id, s_ts_type_cd
	 having sum(cast(chg_hrs as decimal(14,2)))<>0),0)
and
--2013-02-05 
--and either ts is for full week or first part of split
(	AUTOADJ_RT=1.0 or 
	(AUTOADJ_RT<>1.0 and isnull(CORRECTING_REF_DT,TS_DT)<>FRIDAY and hire_eff_dt <= MON_SUB_PD_END_DT)
	-- (AUTOADJ_RT<>1.0 and isnull(CORRECTING_REF_DT,TS_DT)=FRIDAY and hire_eff_dt > MON_SUB_PD_END_DT) 
)
			

IF @@ERROR <> 0 RETURN 1






--5
print convert(char(20), getdate(),121)
PRINT 'UPDATE HDR TEMP TABLE FOR SPECIAL CASE 2b - part 1' 
/*
2b.  if the employee was terminated in middle of week
and employee did not record hours for days after termination
then reduce the auto-adjust rate by 20% for each week day in grouping after termination
(previous split calculation factored in)
*/

--2013-02-05
--update, there is actually a small bug here
--need to fix it with the following


print convert(char(20), getdate(),121)
PRINT 'UPDATE HDR TEMP TABLE FOR SPECIAL CASE 2b - part 2' 

--2013-02-05 
UPDATE #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR
SET SPECIAL_CASE='Y',
	AUTOADJ_RT= AUTOADJ_RT - (0.2 * datediff(day, TERM_DT, MON_SUB_PD_END_DT))
FROM #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR ts
WHERE
TERM_DT is not null
and
--employee terminated mid week
(isnull(TERM_DT,FRIDAY) < FRIDAY and isnull(TERM_DT,FRIDAY) >= MONDAY)
AND
--employee did not record hours for days after term date
--KM - 2012-10-18
0 = isnull((select count(1) 
     from #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_LN
	 where  --ts_dt=ts.ts_dt and
			empl_id=ts.empl_id
			and s_ts_type_cd=ts.s_ts_type_cd
			--and ts_hdr_seq_no=ts.ts_hdr_seq_no
			and effect_bill_dt > ts.term_dt
	 group by empl_id, s_ts_type_cd
	 having sum(cast(chg_hrs as decimal(14,2)))<>0),0)
and
--2013-02-05 
--and ts is for first part of split
( (AUTOADJ_RT<>1.0 and isnull(CORRECTING_REF_DT,TS_DT)<>FRIDAY and TERM_DT < MON_SUB_PD_END_DT)
)
			
IF @@ERROR <> 0 RETURN 1


UPDATE #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR
SET SPECIAL_CASE='Y',
	AUTOADJ_RT= AUTOADJ_RT - (0.2 * datediff(day, TERM_DT, FRIDAY))
FROM #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR ts
WHERE
TERM_DT is not null
and
--employee terminated mid week
(isnull(TERM_DT,FRIDAY) < FRIDAY and isnull(TERM_DT,FRIDAY) >= MONDAY)
AND
--employee did not record hours for days after term date
--KM - 2012-10-18
0 = isnull((select count(1) 
     from #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_LN
	 where  --ts_dt=ts.ts_dt and
			empl_id=ts.empl_id
			and s_ts_type_cd=ts.s_ts_type_cd
			--and ts_hdr_seq_no=ts.ts_hdr_seq_no
			and effect_bill_dt > ts.term_dt
	 group by empl_id, s_ts_type_cd
	 having sum(cast(chg_hrs as decimal(14,2)))<>0),0)
and
--2013-02-05 
--and either ts is for full week or second part of split
(
  AUTOADJ_RT=1.0
	or
 (AUTOADJ_RT<>1.0 and isnull(CORRECTING_REF_DT,TS_DT)=FRIDAY and TERM_DT > MON_SUB_PD_END_DT)
)
			
IF @@ERROR <> 0 RETURN 1





/*
special case - no op
3.  otherwise ignore division transfers 
(it's safe to assume they happen on 1st or 16th and are handled by existing split subperiod logic)
*/





/*
CR5968 -  Change Split Week and OT Apply for Labor costing - 2013-02-06

so that split period does not result 
in different effective hourly rate between both splits
*/


print convert(char(20), getdate(),121)
PRINT 'TRUNCATE WEIGHTED AVG CALCULATION TABLE' 

truncate table XX_IMAPS_BATCHAUTOADJ_WEIGHTEDAVG_TEMP_HDR

IF @@ERROR <> 0 RETURN 1


print convert(char(20), getdate(),121)
PRINT 'PREPARE FOR WEIGHTED AVG CALCULATION' 

insert into XX_IMAPS_BATCHAUTOADJ_WEIGHTEDAVG_TEMP_HDR
SELECT TS_DT, EMPL_ID, S_TS_TYPE_CD, TS_HDR_SEQ_NO, CORRECTING_REF_DT, 
	   FRIDAY, MON_SUB_PD_END_DT,
	   
		AUTOADJ_RT as OLD_AUTOADJ_RT,

		AUTOADJ_RT + (select top 1 AUTOADJ_RT
					  from #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR 
					  where empl_id=hdr.empl_id and s_ts_type_cd=hdr.s_ts_type_cd and friday=hdr.friday
					  and isnull(correcting_ref_dt,ts_dt)<>isnull(hdr.correcting_ref_dt,hdr.ts_dt)
					  )
						 as OLD_AUTOADJ_RT_FOR_FULL_WEEK,

	   (select sal_amt from imaps.deltek.empl_lab_info 
		where empl_id=hdr.empl_id and isnull(hdr.correcting_ref_dt,hdr.ts_dt) between effect_dt and end_dt) as WEEKLY_SAL,

		AUTOADJ_RT * (select sal_amt from imaps.deltek.empl_lab_info 
		where empl_id=hdr.empl_id and isnull(hdr.correcting_ref_dt,hdr.ts_dt) between effect_dt and end_dt) as UNWEIGHTED_CST,
	    
		(select abs(sum(CHG_HRS)) from #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_LN 
		 where empl_id=hdr.empl_id and s_ts_type_cd=hdr.s_ts_type_cd and friday=hdr.friday) as HRS_IN_WEEK,
		
		(select abs(sum(CHG_HRS)) from #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_LN 
		 where empl_id=hdr.empl_id and s_ts_type_cd=hdr.s_ts_type_cd and ts_dt=hdr.ts_dt and ts_hdr_seq_no=hdr.ts_hdr_seq_no) as SPLIT_HRS,

		AUTOADJ_RT as NEW_AUTOADJ_RT,
		AUTOADJ_RT * (select sal_amt from imaps.deltek.empl_lab_info where empl_id=hdr.empl_id and isnull(hdr.correcting_ref_dt,hdr.ts_dt) between effect_dt and end_dt) as WEIGHTED_CST
from #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR hdr
WHERE 
--split weeks only
(FRIDAY > MON_SUB_PD_END_DT)
and
--and both parts of split exist
0<>(select count(1) 
	  from #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR 
	  where empl_id=hdr.empl_id and s_ts_type_cd=hdr.s_ts_type_cd and friday=hdr.friday
	  and isnull(correcting_ref_dt,ts_dt)<>isnull(hdr.correcting_ref_dt,hdr.ts_dt)
	  )


IF @@ERROR <> 0 RETURN 1



--just in case closeout has not run yet
--and there is a partial week in TS_LN which that part has 0 hours
DELETE FROM XX_IMAPS_BATCHAUTOADJ_WEIGHTEDAVG_TEMP_HDR
WHERE HRS_IN_WEEK=0

IF @@ERROR <> 0 RETURN 1






print convert(char(20), getdate(),121)
PRINT 'WEIGHTED AVG CALCULATION - simple - part1' 
UPDATE XX_IMAPS_BATCHAUTOADJ_WEIGHTEDAVG_TEMP_HDR
SET NEW_AUTOADJ_RT= OLD_AUTOADJ_RT_FOR_FULL_WEEK * (SPLIT_HRS/HRS_IN_WEEK)
FROM XX_IMAPS_BATCHAUTOADJ_WEIGHTEDAVG_TEMP_HDR hdr
WHERE
--second part of split
isnull(CORRECTING_REF_DT,TS_DT)=FRIDAY
AND
--salary didn't change between the two splits
0=(select count(1) 
   from XX_IMAPS_BATCHAUTOADJ_WEIGHTEDAVG_TEMP_HDR
   where empl_id=hdr.empl_id
   and s_ts_type_cd=hdr.s_ts_type_cd
   and friday=hdr.friday
   and isnull(CORRECTING_REF_DT,TS_DT)<>friday
   and WEEKLY_SAL<>hdr.WEEKLY_SAL)

IF @@ERROR <> 0 RETURN 1


print convert(char(20), getdate(),121)
PRINT 'WEIGHTED AVG CALCULATION - simple - part2' 
UPDATE XX_IMAPS_BATCHAUTOADJ_WEIGHTEDAVG_TEMP_HDR
SET NEW_AUTOADJ_RT= OLD_AUTOADJ_RT_FOR_FULL_WEEK - 
										(select NEW_AUTOADJ_RT
										 from XX_IMAPS_BATCHAUTOADJ_WEIGHTEDAVG_TEMP_HDR
										 where empl_id=hdr.empl_id
										 and s_ts_type_cd=hdr.s_ts_type_cd
										 and friday=hdr.friday
										 and isnull(CORRECTING_REF_DT,TS_DT)=friday) --recalculated part of second part of split

FROM XX_IMAPS_BATCHAUTOADJ_WEIGHTEDAVG_TEMP_HDR hdr
WHERE
--first part of split
isnull(CORRECTING_REF_DT,TS_DT)<>FRIDAY
AND
--salary didn't change between the two splits
0=(select count(1) 
   from XX_IMAPS_BATCHAUTOADJ_WEIGHTEDAVG_TEMP_HDR
   where empl_id=hdr.empl_id
   and s_ts_type_cd=hdr.s_ts_type_cd
   and friday=hdr.friday
   and isnull(CORRECTING_REF_DT,TS_DT)=friday
   and WEEKLY_SAL<>hdr.WEEKLY_SAL)

IF @@ERROR <> 0 RETURN 1




print convert(char(20), getdate(),121)
PRINT 'WEIGHTED AVG CALCULATION - complex - salary change over split week' 
/*
Calculate Total Cost using 20/80 rule: 2078.25
(0.2*1924.30) + (0.8*2116.74) = 2078.25

Calculate Desired eff_rt for all 44 hours: 47.2329545
2078.25/44.0

Calculate Percent of Weekly Salary for Split 1 needed for that result is
(9*47.2329545)/1924.30= 0.22090973

Calculate Percent of Weekly Salary for Split 2 needed for that result is
select (35*47.2329545)/2116.74= 0.78099030

Note: the combination of those percentages is slightly above 100
0.22090973 + 0.78099030 = 1.00190003

*/
UPDATE XX_IMAPS_BATCHAUTOADJ_WEIGHTEDAVG_TEMP_HDR
SET NEW_AUTOADJ_RT= 
						(
							(--combine previous separated costs for splits (20/80, 40/60, etc)
							--total_cost in week
							(UNWEIGHTED_CST+
							(select UNWEIGHTED_CST
							 from XX_IMAPS_BATCHAUTOADJ_WEIGHTEDAVG_TEMP_HDR
							 where empl_id=hdr.empl_id
							 and s_ts_type_cd=hdr.s_ts_type_cd
							 and friday=hdr.friday
							 and isnull(CORRECTING_REF_DT,TS_DT)<>isnull(hdr.CORRECTING_REF_DT,hdr.TS_DT)))
							--divide that by the total hours in week
							 /HRS_IN_WEEK
							)
							--mulitply that by the hours in this part of the split
							*
							SPLIT_HRS						
						)
						--divide that by the sal_amt
						/WEEKLY_SAL
FROM XX_IMAPS_BATCHAUTOADJ_WEIGHTEDAVG_TEMP_HDR hdr
WHERE
--salary DID change between the two splits
0<>(select count(1) 
   from XX_IMAPS_BATCHAUTOADJ_WEIGHTEDAVG_TEMP_HDR
   where empl_id=hdr.empl_id
   and s_ts_type_cd=hdr.s_ts_type_cd
   and friday=hdr.friday
   and WEEKLY_SAL<>hdr.WEEKLY_SAL)

IF @@ERROR <> 0 RETURN 1
--don't care about rounding here





print convert(char(20), getdate(),121)
PRINT 'WEIGHTED AVG - UPDATE AUTOADJ_RT' 
update #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR
SET SPECIAL_CASE='Y',
	AUTOADJ_RT=wa.NEW_AUTOADJ_RT
FROM 
#XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR spc
inner join
XX_IMAPS_BATCHAUTOADJ_WEIGHTEDAVG_TEMP_HDR wa
on
(spc.empl_id=wa.empl_id
and
 spc.ts_dt=wa.ts_dt
and
 spc.s_ts_type_cd=wa.s_ts_type_cd
and
 spc.ts_hdr_seq_no=wa.ts_hdr_seq_no)





--CR5968 -  Change Split Week and OT Apply for Labor costing - 2013-02-06
--this logic needs to group N and D together
--but, the Deltek Custom code part already did that
--for CERIS, it is not an issue, the autoadjust is only on the D
--for ETIME, it is an issue
IF isnull(@in_ETIME_or_CERIS,'CERIS') = 'ETIME'
BEGIN
	PRINT 'ETIME - change N/D back to C'
	
	UPDATE #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR
	SET S_TS_TYPE_CD='C'
	WHERE S_TS_TYPE_CD in ('N','D')

	IF @@ERROR <> 0 RETURN 1

	UPDATE #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_LN
	SET S_TS_TYPE_CD='C'
	WHERE S_TS_TYPE_CD in ('N','D')

	IF @@ERROR <> 0 RETURN 1
	
END




--6
print convert(char(20), getdate(),121)
PRINT 'UPDATE AUTOADJ_RT for ALL SPECIAL CASES' 
/*
DO AFTER REVIEW OF LOGIC
*/

UPDATE XX_DDC_PREPTBL
SET AUTOADJ_RT=imaps.AUTOADJ_RT
FROM 
XX_DDC_PREPTBL ddc
INNER JOIN
#XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR imaps
on
(ddc.empl_id=imaps.empl_id
and
 ddc.ts_dt=imaps.ts_dt
and
 ddc.s_ts_type_cd=imaps.s_ts_type_cd
and
 ddc.ts_hdr_seq_no=imaps.ts_hdr_seq_no)
where
imaps.special_case='Y'


IF @@ERROR <> 0 RETURN 1



--LAST
print convert(char(20), getdate(),121)
PRINT 'DROP HDR TEMP TABLE'

DROP TABLE #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_HDR

IF @@ERROR <> 0 RETURN 1

print convert(char(20), getdate(),121)
PRINT 'DROP LN TEMP TABLE'

DROP TABLE #XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_TEMP_LN

IF @@ERROR <> 0 RETURN 1





/*LWP issues?  separate sp?*/

RETURN 0

END
go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_IMAPS_BATCHAUTOADJ_SPECIAL_CASES_SP >>>'
go

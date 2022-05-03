USE IMAPSSTG
GO



IF OBJECT_ID('dbo.XX_CERIS_INSERT_TS_RECLASS_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_CERIS_INSERT_TS_RECLASS_SP
    IF OBJECT_ID('dbo.XX_CERIS_INSERT_TS_RECLASS_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_CERIS_INSERT_TS_RECLASS_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_CERIS_INSERT_TS_RECLASS_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go

CREATE procedure [dbo].[XX_CERIS_INSERT_TS_RECLASS_SP]
as

/************************************************************************************************  
Name:           XX_CERIS_INSERT_TS_RECLASS_SP
Author:         KM
Created:        10/2012
Purpose:        

    
    THIS ENTIRE STORED PROCEDURE IS FOR CR-4885 Actuals Implementation
    
    1.Non-Exempt employee

    Non-Exempt emplyee needs a special logic to reclassify the hours between default account and special account.
    Non-Exempt employee needs a special logic to default the account when the pay_type is OT

execute XX_CERIS_INSERT_TS_RECLASS_SP

Prerequisites:     none 
Version:     1.0
                   
CR5968 -  Change Split Week and OT Apply for Labor costing - 2013-02-06
************************************************************************************************/ 
BEGIN


	--0
	PRINT 'TRUNCATE RECLASS TEMP TABLE'
	print convert(char(20), getdate(),121)
	TRUNCATE TABLE XX_CERIS_TS_PREP_OT_RECLASS
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


	--1
	PRINT 'LOAD TS PREP INTO TEMP TABLE'
	print convert(char(20), getdate(),121)

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 59 : XX_CERIS_INSERT_TS_RECLASS_SP.sql '
 
	insert into XX_CERIS_TS_PREP_OT_RECLASS
	select

	ts.TS_DT,ts.EMPL_ID,ts.S_TS_TYPE_CD,ts.WORK_STATE_CD,
	ts.FY_CD,ts.PD_NO,ts.SUB_PD_NO,
	ts.CORRECTING_REF_DT,
	'R' as PAY_TYPE,
	ts.GENL_LAB_CAT_CD,ts.S_TS_LN_TYPE_CD,
	ts.LAB_CST_AMT,
	sum(cast(ts.chg_hrs as decimal(14,2))) as CHG_HRS,
	ts.WORK_COMP_CD,ts.LAB_LOC_CD,
	ts.ORG_ID,ts.ACCT_ID,ts.PROJ_ID,ts.BILL_LAB_CAT_CD,
	ts.REF_STRUC_1_ID,ts.REF_STRUC_2_ID,
	ts.ORG_ABBRV_CD,ts.PROJ_ABBRV_CD,
	ts.TS_HDR_SEQ_NO,ts.EFFECT_BILL_DT,
	ts.PROJ_ACCT_ABBRV_CD, 
	MAX(ts.NOTES) as NOTES,	

	sum(cast(ts.chg_hrs as decimal(14,2))) as REG_HRS,
	cast('00.00' as decimal(14,2)) as OT_HRS,

	MAX(ts.NOTES) as REG_NOTES,
	MAX(ts.NOTES) as OT_NOTES,

	otrules.STATE_CD, 

	case 
		when eli.EXMPT_FL='N' then otrules.S_OT_BASIS_CD
		else 'E' --if they are exempt, don't do OT reclass, keep everything as R
	end as S_OT_BASIS_CD, 

	otrules.EXMPT_HRS

	--into XX_CERIS_TS_PREP_OT_RECLASS

	from 
	xx_ceris_retro_ts_prep ts
	inner join
	imaps.deltek.empl_lab_info eli
	on
	(
	ts.s_ts_type_cd in ('R','N','D')
	and
	ts.empl_id=eli.empl_id
	and
	cast(isnull(ts.correcting_ref_dt,ts.ts_dt) as datetime) between eli.effect_dt and eli.end_dt
	and
	eli.EXMPT_FL='N'  --CR5968 uncommenting this, it is needed now, not sure why/who uncommented it
	)
	inner join
	imaps.deltek.ot_rules_by_state otrules
	on
	(eli.WORK_STATE_CD=otrules.STATE_CD)
	where
	--CR5968 changing this
	--ts.notes like '%EXMPT%p' --only do for Exempt retros with D/p type
	ts.notes like '%p' --only do for D/p type
	and
	--not STB,STW
	ts.pay_type not in 
	(
	select pay_type
	from XX_PAY_TYPE_ACCT_MAP
	group by pay_type
	)
	and 
	--not SICK,LWOP
	ts.proj_abbrv_cd not in
	(
	select  proj_abbrv_cd
	from XX_ET_EXCLUDE_PROJECTS
	)
	group by 
	ts.TS_DT,ts.EMPL_ID,ts.S_TS_TYPE_CD,ts.WORK_STATE_CD,
	ts.FY_CD,ts.PD_NO,ts.SUB_PD_NO,
	ts.CORRECTING_REF_DT,
	--'R' as PAY_TYPE,
	ts.GENL_LAB_CAT_CD,ts.S_TS_LN_TYPE_CD,
	ts.LAB_CST_AMT,
	--sum(cast(ts.chg_hrs as decimal(14,2))) as CHG_HRS,
	ts.WORK_COMP_CD,ts.LAB_LOC_CD,
	ts.ORG_ID,ts.ACCT_ID,ts.PROJ_ID,ts.BILL_LAB_CAT_CD,
	ts.REF_STRUC_1_ID,ts.REF_STRUC_2_ID,
	ts.ORG_ABBRV_CD,ts.PROJ_ABBRV_CD,
	ts.TS_HDR_SEQ_NO,ts.EFFECT_BILL_DT,
	ts.PROJ_ACCT_ABBRV_CD, 
	--MAX(ts.NOTES) as NOTES
	
	otrules.STATE_CD,
	otrules.EXMPT_HRS,
	otrules.S_OT_BASIS_CD,
	eli.EXMPT_FL

	having 
	sum(cast(ts.chg_hrs as decimal(14,2)))<>0	

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER



	/* DON'T PRUNE THIS TABLE BECAUSE OF N to E */


	--3
	PRINT 'CALCULATE OT IN TEMP TABLE'
	print convert(char(20), getdate(),121)

	--calculate OT_HRS via ratio

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 171 : XX_CERIS_INSERT_TS_RECLASS_SP.sql '
 
	update XX_CERIS_TS_PREP_OT_RECLASS
	set OT_HRS= 

	REG_HRS * 

	((
	 select abs(sum(cast(chg_hrs as decimal(14,2))))
	 from XX_CERIS_TS_PREP_OT_RECLASS
	 where empl_id=t1.empl_id
	 and s_ts_type_cd=t1.s_ts_type_cd
	 and dbo.xx_get_friday_for_ts_week_day_uf(effect_bill_dt)=dbo.xx_get_friday_for_ts_week_day_uf(t1.effect_bill_dt)
	) - EXMPT_HRS )/ 
	(
	 select abs(sum(cast(chg_hrs as decimal(14,2))))
	 from XX_CERIS_TS_PREP_OT_RECLASS
	 where empl_id=t1.empl_id
	 and s_ts_type_cd=t1.s_ts_type_cd
	 and dbo.xx_get_friday_for_ts_week_day_uf(effect_bill_dt)=dbo.xx_get_friday_for_ts_week_day_uf(t1.effect_bill_dt)
	)
	from XX_CERIS_TS_PREP_OT_RECLASS t1
	where 
	S_OT_BASIS_CD='W'
	and
	EXMPT_HRS <
	(
	 select abs(sum(cast(chg_hrs as decimal(14,2))))
	 from XX_CERIS_TS_PREP_OT_RECLASS
	 where empl_id=t1.empl_id
	 and s_ts_type_cd=t1.s_ts_type_cd
	 and dbo.xx_get_friday_for_ts_week_day_uf(effect_bill_dt)=dbo.xx_get_friday_for_ts_week_day_uf(t1.effect_bill_dt)
	) 



	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 211 : XX_CERIS_INSERT_TS_RECLASS_SP.sql '
 
	update XX_CERIS_TS_PREP_OT_RECLASS
	set OT_HRS= 

	REG_HRS * 

	((
	 select abs(sum(cast(chg_hrs as decimal(14,2))))
	 from XX_CERIS_TS_PREP_OT_RECLASS
	 where empl_id=t1.empl_id
	 and s_ts_type_cd=t1.s_ts_type_cd
	 and effect_bill_dt=t1.effect_bill_dt
	) - EXMPT_HRS )/ 
	(
	 select abs(sum(cast(chg_hrs as decimal(14,2))))
	 from XX_CERIS_TS_PREP_OT_RECLASS
	 where empl_id=t1.empl_id
	 and s_ts_type_cd=t1.s_ts_type_cd
	 and effect_bill_dt=t1.effect_bill_dt
	)
	from XX_CERIS_TS_PREP_OT_RECLASS t1
	where 
	S_OT_BASIS_CD='D'
	and
	EXMPT_HRS < 
	(
	 select abs(sum(cast(chg_hrs as decimal(14,2))))
	 from XX_CERIS_TS_PREP_OT_RECLASS
	 where empl_id=t1.empl_id
	 and s_ts_type_cd=t1.s_ts_type_cd
	 and effect_bill_dt=t1.effect_bill_dt
	) 

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 249 : XX_CERIS_INSERT_TS_RECLASS_SP.sql '
 
	update XX_CERIS_TS_PREP_OT_RECLASS
	set REG_HRS = REG_HRS - OT_HRS

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER







	--4
	PRINT 'FIX ROUNDING ISSUES FOR WEEKLY OT'
	print convert(char(20), getdate(),121)

	--now do tenth of hour redistribution


	--WEEKLY OT RULES
	--LOOP THROUGH AND FIND OUT WHICH
	--HAVE ROUNDING ERRORS AND TRY TO FIX THEM
	DECLARE @empl_id varchar(6),
			@s_ts_type_cd char(1),
			@friday datetime,
			@exmpt_hrs decimal(14,2),
			@tot_hrs decimal(14,2),
			@reg_hrs decimal(14,2),
			@ot_hrs decimal(14,2),
			@temp_amt decimal(14,2),
			
			@notes varchar(254),
			@status int
			

	DECLARE WEEKS_WITH_REG_OT_ROUNDING_ISSUES CURSOR FAST_FORWARD FOR
	select empl_id, s_ts_type_cd, 
	dbo.xx_get_friday_for_ts_week_day_uf(effect_bill_dt) friday,
	EXMPT_HRS,
	sum(cast(chg_hrs as decimal(14,2)))hrs,sum(reg_hrs)reg_hrs,sum(ot_hrs)ot_hrs
	from XX_CERIS_TS_PREP_OT_RECLASS
	where 
	S_OT_BASIS_CD='W'
	group by empl_id, s_ts_type_cd,  EXMPT_HRS,
	dbo.xx_get_friday_for_ts_week_day_uf(effect_bill_dt)
	having 
	abs(sum(reg_hrs))<>EXMPT_HRS


	OPEN WEEKS_WITH_REG_OT_ROUNDING_ISSUES
	FETCH WEEKS_WITH_REG_OT_ROUNDING_ISSUES
	INTO  @empl_id, @s_ts_type_cd, @friday, @exmpt_hrs, @tot_hrs, @reg_hrs, @ot_hrs

	WHILE (@@fetch_status = 0)
	BEGIN

		--LOOP THROUGH LINES AND DISTRIBUTE EXTRA TENTH OF HOURS FOR WEEK

		DECLARE WEEKS_WITH_REG_OT_ROUNDING_ISSUES_lines CURSOR FAST_FORWARD FOR
		SELECT  NOTES
		FROM	XX_CERIS_TS_PREP_OT_RECLASS
		WHERE	empl_id=@empl_id
		and		s_ts_type_cd=@s_ts_type_cd
		and		dbo.xx_get_friday_for_ts_week_day_uf(effect_bill_dt)=@friday
		order by abs(cast(chg_hrs as decimal(14,2))) desc


		OPEN WEEKS_WITH_REG_OT_ROUNDING_ISSUES_lines
		FETCH WEEKS_WITH_REG_OT_ROUNDING_ISSUES_lines
		INTO @notes
		
		SET @status = @@fetch_status
		WHILE(@status = 0)
		BEGIN

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 326 : XX_CERIS_INSERT_TS_RECLASS_SP.sql '
 
			SELECT 	@temp_amt = SUM(reg_hrs)
			FROM	XX_CERIS_TS_PREP_OT_RECLASS
			WHERE	empl_id=@empl_id
			and		s_ts_type_cd=@s_ts_type_cd
			and		dbo.xx_get_friday_for_ts_week_day_uf(effect_bill_dt)=@friday
		
			IF( (abs(@temp_amt) < @exmpt_hrs AND @temp_amt>0)   OR  (abs(@temp_amt) > @exmpt_hrs AND @temp_amt<0) )
			BEGIN
				UPDATE  XX_CERIS_TS_PREP_OT_RECLASS
				SET		REG_HRS = REG_HRS + 0.01,
						OT_HRS = OT_HRS - 0.01
				WHERE	empl_id=@empl_id
				and		s_ts_type_cd=@s_ts_type_cd
				and		dbo.xx_get_friday_for_ts_week_day_uf(effect_bill_dt)=@friday
				and 	NOTES = @notes
		
				SET @temp_amt = @temp_amt + 0.01
			END

			IF( (abs(@temp_amt) < @exmpt_hrs AND @temp_amt<0)   OR  (abs(@temp_amt) > @exmpt_hrs AND @temp_amt>0) )
			BEGIN
				UPDATE  XX_CERIS_TS_PREP_OT_RECLASS
				SET		REG_HRS = REG_HRS - 0.01,
						OT_HRS = OT_HRS + 0.01
				WHERE	empl_id=@empl_id
				and		s_ts_type_cd=@s_ts_type_cd
				and		dbo.xx_get_friday_for_ts_week_day_uf(effect_bill_dt)=@friday
				and 	NOTES = @notes
		
				SET @temp_amt = @temp_amt - 0.01
			END


			FETCH WEEKS_WITH_REG_OT_ROUNDING_ISSUES_lines
			INTO @notes

			IF abs(@temp_amt) = @exmpt_hrs
			BEGIN
				SET @status = 1
			END
			ELSE
			BEGIN
				SET @status = @@fetch_status
			END
		END
		
		CLOSE WEEKS_WITH_REG_OT_ROUNDING_ISSUES_lines
		DEALLOCATE WEEKS_WITH_REG_OT_ROUNDING_ISSUES_lines
		

		FETCH WEEKS_WITH_REG_OT_ROUNDING_ISSUES
		INTO  @empl_id, @s_ts_type_cd, @friday, @exmpt_hrs, @tot_hrs, @reg_hrs, @ot_hrs

	END

	CLOSE WEEKS_WITH_REG_OT_ROUNDING_ISSUES
	DEALLOCATE WEEKS_WITH_REG_OT_ROUNDING_ISSUES

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER




	--4
	PRINT 'FIX ROUNDING ISSUES FOR DAILY OT'
	print convert(char(20), getdate(),121)

	--DAILY OT RULES
	--LOOP THROUGH AND FIND OUT WHICH
	--HAVE ROUNDING ERRORS AND TRY TO FIX THEM
	DECLARE @workday datetime
			

	DECLARE DAYS_WITH_REG_OT_ROUNDING_ISSUES CURSOR FAST_FORWARD FOR
	select empl_id, s_ts_type_cd, 
	effect_bill_dt as workday,
	EXMPT_HRS,
	sum(cast(chg_hrs as decimal(14,2)))hrs,sum(reg_hrs)reg_hrs,sum(ot_hrs)ot_hrs
	from XX_CERIS_TS_PREP_OT_RECLASS
	where 
	S_OT_BASIS_CD='D'
	group by empl_id, s_ts_type_cd,  EXMPT_HRS,
	effect_bill_dt
	having 
	abs(sum(reg_hrs))<>EXMPT_HRS


	OPEN DAYS_WITH_REG_OT_ROUNDING_ISSUES
	FETCH DAYS_WITH_REG_OT_ROUNDING_ISSUES
	INTO  @empl_id, @s_ts_type_cd, @workday, @exmpt_hrs, @tot_hrs, @reg_hrs, @ot_hrs

	WHILE (@@fetch_status = 0)
	BEGIN

		--LOOP THROUGH LINES AND DISTRIBUTE EXTRA TENTH OF HOURS FOR WEEK

		DECLARE DAYS_WITH_REG_OT_ROUNDING_ISSUES_lines CURSOR FAST_FORWARD FOR
		SELECT  NOTES
		FROM	XX_CERIS_TS_PREP_OT_RECLASS
		WHERE	empl_id=@empl_id
		and		s_ts_type_cd=@s_ts_type_cd
		and		effect_bill_dt=@workday
		order by abs(cast(chg_hrs as decimal(14,2))) desc


		OPEN DAYS_WITH_REG_OT_ROUNDING_ISSUES_lines
		FETCH DAYS_WITH_REG_OT_ROUNDING_ISSUES_lines
		INTO @notes
		
		SET @status = @@fetch_status
		WHILE(@status = 0)
		BEGIN

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 442 : XX_CERIS_INSERT_TS_RECLASS_SP.sql '
 
			SELECT 	@temp_amt = SUM(reg_hrs)
			FROM	XX_CERIS_TS_PREP_OT_RECLASS
			WHERE	empl_id=@empl_id
			and		s_ts_type_cd=@s_ts_type_cd
			and		effect_bill_dt=@workday
		
			IF( (abs(@temp_amt) < @exmpt_hrs AND @temp_amt>0)   OR  (abs(@temp_amt) > @exmpt_hrs AND @temp_amt<0) )
			BEGIN
				UPDATE  XX_CERIS_TS_PREP_OT_RECLASS
				SET		REG_HRS = REG_HRS + 0.01,
						OT_HRS = OT_HRS - 0.01
				WHERE	empl_id=@empl_id
				and		s_ts_type_cd=@s_ts_type_cd
				and		effect_bill_dt=@workday
				and 	NOTES = @notes
		
				SET @temp_amt = @temp_amt + 0.01
			END

			IF( (abs(@temp_amt) < @exmpt_hrs AND @temp_amt<0)   OR  (abs(@temp_amt) > @exmpt_hrs AND @temp_amt>0) )
			BEGIN
				UPDATE  XX_CERIS_TS_PREP_OT_RECLASS
				SET		REG_HRS = REG_HRS - 0.01,
						OT_HRS = OT_HRS + 0.01
				WHERE	empl_id=@empl_id
				and		s_ts_type_cd=@s_ts_type_cd
				and		effect_bill_dt=@workday
				and 	NOTES = @notes
		
				SET @temp_amt = @temp_amt - 0.01
			END


			FETCH DAYS_WITH_REG_OT_ROUNDING_ISSUES_lines
			INTO @notes

			IF abs(@temp_amt) = @exmpt_hrs
			BEGIN
				SET @status = 1
			END
			ELSE
			BEGIN
				SET @status = @@fetch_status
			END
		END
		
		CLOSE DAYS_WITH_REG_OT_ROUNDING_ISSUES_lines
		DEALLOCATE DAYS_WITH_REG_OT_ROUNDING_ISSUES_lines
		

		FETCH DAYS_WITH_REG_OT_ROUNDING_ISSUES
		INTO  @empl_id, @s_ts_type_cd, @friday, @exmpt_hrs, @tot_hrs, @reg_hrs, @ot_hrs

	END


	CLOSE DAYS_WITH_REG_OT_ROUNDING_ISSUES
	DEALLOCATE DAYS_WITH_REG_OT_ROUNDING_ISSUES


	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER




	PRINT 'UPDATE NOTES'
	print convert(char(20), getdate(),121)

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 513 : XX_CERIS_INSERT_TS_RECLASS_SP.sql '
 
	update XX_CERIS_TS_PREP_OT_RECLASS
	set reg_notes=replace(notes, '-p','-A-p'),
		ot_notes=replace(notes, '-p','-B-p')

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER



	PRINT 'RECON CHECK ON HOURS'
	print convert(char(20), getdate(),121)

	declare @count int
	select @count=count(1)
	from XX_CERIS_TS_PREP_OT_RECLASS
	where cast(chg_hrs as decimal(14,2))<>reg_hrs+ot_hrs

	if @count <> 0 GOTO BL_ERROR_HANDLER




	--XX_CERIS_TS_PREP_OT_RECLASS
	PRINT 'WEIGHTED AVG'
	print convert(char(20), getdate(),121)
	--CR5968
		print 'CR5968 changes'

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 543 : XX_CERIS_INSERT_TS_RECLASS_SP.sql '
 
	update XX_CERIS_TS_PREP_OT_RECLASS
	set OT_HRS=0	
	where s_ot_basis_cd='W'

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	--CR5968, BFR1.2
	--after all this, we are now told to not distribute OT across week for labor cost calculation
	--just do it when applying weighted average rate

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 556 : XX_CERIS_INSERT_TS_RECLASS_SP.sql '
 
	select empl_id, s_ts_type_cd, ts_dt, correcting_ref_dt, effect_bill_dt, exmpt_hrs,

	(select sum(cast(chg_hrs as decimal(14,2)))
	 from XX_CERIS_TS_PREP_OT_RECLASS
	 where empl_id=ts.empl_id
	 and s_ts_type_cd=ts.s_ts_type_cd 
	 and effect_bill_dt=ts.effect_bill_dt)  as chg_hrs,

	((select sum(cast(chg_hrs as decimal(14,2)))
	 from XX_CERIS_TS_PREP_OT_RECLASS
	 where empl_id=ts.empl_id
	 and s_ts_type_cd=ts.s_ts_type_cd
	 and
	 dbo.xx_get_friday_for_ts_week_day_uf(isnull(correcting_ref_dt,ts_dt)) 
	 =
	 dbo.xx_get_friday_for_ts_week_day_uf(isnull(ts.correcting_ref_dt,ts.ts_dt))  
	 and effect_bill_dt<=ts.effect_bill_dt) - exmpt_hrs) as ot_hrs

	into #XX_CERIS_TS_PREP_OT_WEEKLY_OT_DAYS

	from XX_CERIS_TS_PREP_OT_RECLASS ts
	where s_ts_type_cd in ('R','D')
	and s_ot_basis_cd='W'
	group by exmpt_hrs, empl_id, s_ts_type_cd, effect_bill_dt, ts_dt, correcting_ref_dt
	having 
	0 <
	((select sum(cast(chg_hrs as decimal(14,2)))
	 from XX_CERIS_TS_PREP_OT_RECLASS
	 where empl_id=ts.empl_id
	 and s_ts_type_cd=ts.s_ts_type_cd
	 and
	 dbo.xx_get_friday_for_ts_week_day_uf(isnull(correcting_ref_dt,ts_dt)) 
	 =
	 dbo.xx_get_friday_for_ts_week_day_uf(isnull(ts.correcting_ref_dt,ts.ts_dt))  
	 and effect_bill_dt<=ts.effect_bill_dt) - exmpt_hrs)

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 597 : XX_CERIS_INSERT_TS_RECLASS_SP.sql '
 
	UPDATE #XX_CERIS_TS_PREP_OT_WEEKLY_OT_DAYS
	SET OT_HRS=
				case
					when ot_hrs<0 then 0
					when ot_hrs>0 and ot_hrs<chg_hrs then ot_hrs
					when ot_hrs>0 and ot_hrs>=chg_hrs then chg_hrs
					else 0
				end
	WHERE 
	S_TS_TYPE_CD IN ('R','D')

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 613 : XX_CERIS_INSERT_TS_RECLASS_SP.sql '
 
	insert into #XX_CERIS_TS_PREP_OT_WEEKLY_OT_DAYS
	select empl_id, s_ts_type_cd, ts_dt, correcting_ref_dt, effect_bill_dt, exmpt_hrs,

	(select sum(cast(chg_hrs as decimal(14,2)))
	 from XX_CERIS_TS_PREP_OT_RECLASS
	 where empl_id=ts.empl_id
	 and s_ts_type_cd=ts.s_ts_type_cd 
	 and effect_bill_dt=ts.effect_bill_dt)  as chg_hrs,

	((select sum(cast(chg_hrs as decimal(14,2)))
	 from XX_CERIS_TS_PREP_OT_RECLASS
	 where empl_id=ts.empl_id
	 and s_ts_type_cd=ts.s_ts_type_cd
	 and
	 dbo.xx_get_friday_for_ts_week_day_uf(isnull(correcting_ref_dt,ts_dt)) 
	 =
	 dbo.xx_get_friday_for_ts_week_day_uf(isnull(ts.correcting_ref_dt,ts.ts_dt))   
	 and effect_bill_dt<=ts.effect_bill_dt) + exmpt_hrs) as ot_hrs

	from XX_CERIS_TS_PREP_OT_RECLASS ts
	where s_ts_type_cd in ('N')
	and s_ot_basis_cd='W'
	group by exmpt_hrs, empl_id, s_ts_type_cd, effect_bill_dt, ts_dt, correcting_ref_dt
	having 
	0 >
	(
	(select sum(cast(chg_hrs as decimal(14,2)))
	 from XX_CERIS_TS_PREP_OT_RECLASS
	 where empl_id=ts.empl_id
	 and s_ts_type_cd=ts.s_ts_type_cd
	 and
	 dbo.xx_get_friday_for_ts_week_day_uf(isnull(correcting_ref_dt,ts_dt)) 
	 =
	 dbo.xx_get_friday_for_ts_week_day_uf(isnull(ts.correcting_ref_dt,ts.ts_dt))    
	 and effect_bill_dt<=ts.effect_bill_dt) + exmpt_hrs)

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 654 : XX_CERIS_INSERT_TS_RECLASS_SP.sql '
 
	UPDATE #XX_CERIS_TS_PREP_OT_WEEKLY_OT_DAYS
	SET OT_HRS=
				case
					when ot_hrs>0 then 0
					when ot_hrs<0 and abs(ot_hrs)<abs(chg_hrs) then ot_hrs
					when ot_hrs<0 and abs(ot_hrs)>=abs(chg_hrs) then chg_hrs
					else 0
				end
	WHERE 
	S_TS_TYPE_CD IN ('N')

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER




    -- Added CR-5568 02/10/2013
    --BEGIN
    -- Add Sick and other paid hours back again so they will be part rate application
	PRINT 'LOAD TS PREP INTO TEMP TABLE'
	print convert(char(20), getdate(),121)

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 679 : XX_CERIS_INSERT_TS_RECLASS_SP.sql '
 
	insert into XX_CERIS_TS_PREP_OT_RECLASS
	select

	ts.TS_DT,ts.EMPL_ID,ts.S_TS_TYPE_CD,ts.WORK_STATE_CD,
	ts.FY_CD,ts.PD_NO,ts.SUB_PD_NO,
	ts.CORRECTING_REF_DT,
	'R' as PAY_TYPE,
	ts.GENL_LAB_CAT_CD,ts.S_TS_LN_TYPE_CD,
	ts.LAB_CST_AMT,
	sum(cast(ts.chg_hrs as decimal(14,2))) as CHG_HRS,
	ts.WORK_COMP_CD,ts.LAB_LOC_CD,
	ts.ORG_ID,ts.ACCT_ID,ts.PROJ_ID,ts.BILL_LAB_CAT_CD,
	ts.REF_STRUC_1_ID,ts.REF_STRUC_2_ID,
	ts.ORG_ABBRV_CD,ts.PROJ_ABBRV_CD,
	ts.TS_HDR_SEQ_NO,ts.EFFECT_BILL_DT,
	ts.PROJ_ACCT_ABBRV_CD, 
	MAX(ts.NOTES) as NOTES,	

	sum(cast(ts.chg_hrs as decimal(14,2))) as REG_HRS,
	cast('00.00' as decimal(14,2)) as OT_HRS,

	MAX(ts.NOTES) as REG_NOTES,
	MAX(ts.NOTES) as OT_NOTES,

	otrules.STATE_CD, 

	case 
		when eli.EXMPT_FL='N' then otrules.S_OT_BASIS_CD
		else 'E' --if they are exempt, don't do OT reclass, keep everything as R
	end as S_OT_BASIS_CD, 

	otrules.EXMPT_HRS

	--into XX_CERIS_TS_PREP_OT_RECLASS

	from 
	xx_ceris_retro_ts_prep ts
	inner join
	imaps.deltek.empl_lab_info eli
	on
	(
	ts.s_ts_type_cd in ('R','N','D')
	and
	ts.empl_id=eli.empl_id
	and
	cast(isnull(ts.correcting_ref_dt,ts.ts_dt) as datetime) between eli.effect_dt and eli.end_dt
	and
	eli.EXMPT_FL='N'  --CR5968 uncommenting this, it is needed now, not sure why/who uncommented it
	)
	inner join
	imaps.deltek.ot_rules_by_state otrules
	on
	(eli.WORK_STATE_CD=otrules.STATE_CD)
	where
	--CR5968 changing this
	--ts.notes like '%EXMPT%p' --only do for Exempt retros with D/p type
	ts.notes like '%p' --only do for D/p type
	and
	--not STB,STW
	ts.pay_type not in 
	(
	select pay_type
	from XX_PAY_TYPE_ACCT_MAP
	group by pay_type
	)
	and 
	--not SICK,LWOP
	ts.proj_abbrv_cd in            ---<<< Include the Sick and AD16 hours
	(
		select  proj_abbrv_cd
		from XX_ET_EXCLUDE_PROJECTS
        where active_fl='Y'
	)
	group by 
	ts.TS_DT,ts.EMPL_ID,ts.S_TS_TYPE_CD,ts.WORK_STATE_CD,
	ts.FY_CD,ts.PD_NO,ts.SUB_PD_NO,
	ts.CORRECTING_REF_DT,
	--'R' as PAY_TYPE,
	ts.GENL_LAB_CAT_CD,ts.S_TS_LN_TYPE_CD,
	ts.LAB_CST_AMT,
	--sum(cast(ts.chg_hrs as decimal(14,2))) as CHG_HRS,
	ts.WORK_COMP_CD,ts.LAB_LOC_CD,
	ts.ORG_ID,ts.ACCT_ID,ts.PROJ_ID,ts.BILL_LAB_CAT_CD,
	ts.REF_STRUC_1_ID,ts.REF_STRUC_2_ID,
	ts.ORG_ABBRV_CD,ts.PROJ_ABBRV_CD,
	ts.TS_HDR_SEQ_NO,ts.EFFECT_BILL_DT,
	ts.PROJ_ACCT_ABBRV_CD, 
	--MAX(ts.NOTES) as NOTES
	
	otrules.STATE_CD,
	otrules.EXMPT_HRS,
	otrules.S_OT_BASIS_CD,
	eli.EXMPT_FL

	having 
	sum(cast(ts.chg_hrs as decimal(14,2)))<>0	
    
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER
    -- END





 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 786 : XX_CERIS_INSERT_TS_RECLASS_SP.sql '
 
	select 
	ts.empl_id, ts.s_ts_type_cd,
	sum(cast(chg_hrs as decimal(14,2))) chg_hrs, 
	sum(cast(reg_hrs as decimal(14,2))) reg_hrs, 
	sum(cast(ot_hrs as decimal(14,2))) ot_hrs, 
	eli.hrly_amt,
	dbo.xx_get_friday_for_ts_week_day_uf(isnull(ts.correcting_ref_dt,ts.ts_dt)) as friday,
    (eli.hrly_amt*sum(cast(chg_hrs as decimal(14,2))) + eli.hrly_amt*0.5*sum(cast(ot_hrs as decimal(14,2)))) as lab_cst_amt   
	--(eli.hrly_amt*sum(cast(reg_hrs as decimal(14,2))) + eli.hrly_amt*1.5*sum(cast(ot_hrs as decimal(14,2)))) as lab_cst_amt -- Replaced
	into #XX_CERIS_TS_PREP_OT_RECLASS_FOR_WEIGHTED_AVG_T1
	from 
	XX_CERIS_TS_PREP_OT_RECLASS ts
	inner join
	imaps.deltek.empl_lab_info eli
	on
	(
	ts.empl_id=eli.empl_id
	 and
	isnull(ts.correcting_ref_dt,ts.ts_dt) between eli.effect_dt and eli.end_dt
	) 
	group by ts.empl_id, ts.s_ts_type_cd, eli.hrly_amt, isnull(ts.correcting_ref_dt,ts.ts_dt) 

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	--now the weekly OT labor cost calc
	insert into #XX_CERIS_TS_PREP_OT_RECLASS_FOR_WEIGHTED_AVG_T1
	select 
	ts.empl_id, ts.s_ts_type_cd,
	sum(cast('0' as decimal(14,2))) as chg_hrs, 
	sum(cast('0' as decimal(14,2))) as reg_hrs, 
	sum(cast(ot_hrs as decimal(14,2))) ot_hrs, 
	eli.hrly_amt,
	dbo.xx_get_friday_for_ts_week_day_uf(isnull(ts.correcting_ref_dt,ts.ts_dt)) as friday,
    eli.hrly_amt*0.5*sum(cast(ot_hrs as decimal(14,2))) as lab_cst_amt   
	from 
	#XX_CERIS_TS_PREP_OT_WEEKLY_OT_DAYS ts
	inner join
	imaps.deltek.empl_lab_info eli
	on
	(
	ts.empl_id=eli.empl_id
	 and
	isnull(ts.correcting_ref_dt,ts.ts_dt) between eli.effect_dt and eli.end_dt
	) 
	group by ts.empl_id, ts.s_ts_type_cd, eli.hrly_amt, isnull(ts.correcting_ref_dt,ts.ts_dt) 

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	

	--set LAB_CST_AMT as hours * weighted average rate
	update XX_CERIS_TS_PREP_OT_RECLASS
	SET LAB_CST_AMT = cast(
					  cast(chg_hrs as decimal(14,2)) 
						*
					  (
						  (select sum(lab_cst_amt)
						   from #XX_CERIS_TS_PREP_OT_RECLASS_FOR_WEIGHTED_AVG_T1
						   where empl_id=ts.empl_id
						   and s_ts_type_cd=ts.s_ts_type_cd
						   and friday= dbo.xx_get_friday_for_ts_week_day_uf(isnull(ts.correcting_ref_dt,ts.ts_dt))
							)
							/
						  (select sum(chg_hrs)
						   from #XX_CERIS_TS_PREP_OT_RECLASS_FOR_WEIGHTED_AVG_T1
						   where empl_id=ts.empl_id
						   and s_ts_type_cd=ts.s_ts_type_cd
						   and friday= dbo.xx_get_friday_for_ts_week_day_uf(isnull(ts.correcting_ref_dt,ts.ts_dt))
							)
						)
						as decimal(14,2))
	from XX_CERIS_TS_PREP_OT_RECLASS ts
	where
	--this should never happen, but in DEV, Tejas processed N & D without R
	--resulting in the total hours for this week being 0
	0<> (select sum(chg_hrs)
		   from #XX_CERIS_TS_PREP_OT_RECLASS_FOR_WEIGHTED_AVG_T1
		   where empl_id=ts.empl_id
		   and s_ts_type_cd=ts.s_ts_type_cd
		   and friday= dbo.xx_get_friday_for_ts_week_day_uf(isnull(ts.correcting_ref_dt,ts.ts_dt))
			)

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER



	DROP TABLE #XX_CERIS_TS_PREP_OT_RECLASS_FOR_WEIGHTED_AVG_T1

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	DROP TABLE #XX_CERIS_TS_PREP_OT_WEEKLY_OT_DAYS

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER






	--change here because of grouping logic
	PRINT 'DELETE NON RECLASSED TS LINES'
	print convert(char(20), getdate(),121)

	DELETE xx_ceris_retro_ts_prep
	from 
	xx_ceris_retro_ts_prep ts
	inner join
	imaps.deltek.empl_lab_info eli
	on
	(
	ts.s_ts_type_cd in ('R','N','D')
	and
	ts.empl_id=eli.empl_id
	and
	cast(isnull(ts.correcting_ref_dt,ts.ts_dt) as datetime) between eli.effect_dt and eli.end_dt
	and
	eli.EXMPT_FL='N'  --CR5968 uncommenting this, it is needed now, not sure why/who uncommented it
	)
	inner join
	imaps.deltek.ot_rules_by_state otrules
	on
	(eli.WORK_STATE_CD=otrules.STATE_CD)
	where	
	--CR5968 changing this
	--ts.notes like '%EXMPT%p' --only do for Exempt retros with D/p type
	ts.notes like '%p' --only do for D/p type
	and
	--not STB,STW
	ts.pay_type not in 
	(
	select pay_type
	from XX_PAY_TYPE_ACCT_MAP
	group by pay_type
	)
	and 
	--not SICK,LWOP
	ts.proj_abbrv_cd not in          ---<<< Include the Sick and AD16 hours
	(
		select  proj_abbrv_cd
		from XX_ET_EXCLUDE_PROJECTS
        where active_fl<>'Y'		--remember we included where ='Y' after OT distribution
	)

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER





	----CR5968
	/*
	PRINT 'INSERT RECLASSED REG LINES'
	print convert(char(20), getdate(),121)


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 944 : XX_CERIS_INSERT_TS_RECLASS_SP.sql '
 
    INSERT INTO IMAPSStg.dbo.xx_ceris_retro_ts_prep
           (TS_DT,EMPL_ID,S_TS_TYPE_CD,WORK_STATE_CD,FY_CD,PD_NO,SUB_PD_NO,CORRECTING_REF_DT,
			PAY_TYPE,
			GENL_LAB_CAT_CD,S_TS_LN_TYPE_CD,
			LAB_CST_AMT,CHG_HRS,
			WORK_COMP_CD,LAB_LOC_CD,ORG_ID,ACCT_ID,PROJ_ID,BILL_LAB_CAT_CD,REF_STRUC_1_ID,
			REF_STRUC_2_ID,ORG_ABBRV_CD,PROJ_ABBRV_CD,TS_HDR_SEQ_NO,EFFECT_BILL_DT,PROJ_ACCT_ABBRV_CD,
			NOTES) 
    SELECT  TS_DT,EMPL_ID,S_TS_TYPE_CD,WORK_STATE_CD,FY_CD,PD_NO,SUB_PD_NO,CORRECTING_REF_DT,
			'R' as PAY_TYPE,
			GENL_LAB_CAT_CD,S_TS_LN_TYPE_CD,
			'0' as LAB_CST_AMT, REG_HRS as CHG_HRS,
			WORK_COMP_CD,LAB_LOC_CD,ORG_ID,ACCT_ID,PROJ_ID,BILL_LAB_CAT_CD,REF_STRUC_1_ID,
			REF_STRUC_2_ID,ORG_ABBRV_CD,PROJ_ABBRV_CD,TS_HDR_SEQ_NO,EFFECT_BILL_DT,PROJ_ACCT_ABBRV_CD,
			REG_NOTES as NOTES
    FROM XX_CERIS_TS_PREP_OT_RECLASS

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


	PRINT 'INSERT RECLASSED OT LINES'
	print convert(char(20), getdate(),121)

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 970 : XX_CERIS_INSERT_TS_RECLASS_SP.sql '
 
    INSERT INTO IMAPSStg.dbo.xx_ceris_retro_ts_prep
           (TS_DT,EMPL_ID,S_TS_TYPE_CD,WORK_STATE_CD,FY_CD,PD_NO,SUB_PD_NO,CORRECTING_REF_DT,
			PAY_TYPE,
			GENL_LAB_CAT_CD,S_TS_LN_TYPE_CD,
			LAB_CST_AMT,CHG_HRS,
			WORK_COMP_CD,LAB_LOC_CD,ORG_ID,ACCT_ID,PROJ_ID,BILL_LAB_CAT_CD,REF_STRUC_1_ID,
			REF_STRUC_2_ID,ORG_ABBRV_CD,PROJ_ABBRV_CD,TS_HDR_SEQ_NO,EFFECT_BILL_DT,PROJ_ACCT_ABBRV_CD,
			NOTES) 
    SELECT  TS_DT,EMPL_ID,S_TS_TYPE_CD,WORK_STATE_CD,FY_CD,PD_NO,SUB_PD_NO,CORRECTING_REF_DT,
			'OT' as PAY_TYPE,
			GENL_LAB_CAT_CD,S_TS_LN_TYPE_CD,
			'0' as LAB_CST_AMT, OT_HRS as CHG_HRS,
			WORK_COMP_CD,LAB_LOC_CD,ORG_ID,ACCT_ID,PROJ_ID,BILL_LAB_CAT_CD,REF_STRUC_1_ID,
			REF_STRUC_2_ID,ORG_ABBRV_CD,PROJ_ABBRV_CD,TS_HDR_SEQ_NO,EFFECT_BILL_DT,PROJ_ACCT_ABBRV_CD,
			OT_NOTES as NOTES
    FROM XX_CERIS_TS_PREP_OT_RECLASS
	WHERE OT_HRS<>0 --need to add this to prevent exempts with still 0 OT hrs

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER
	*/

	PRINT 'INSERT RECLASSED REG LINES'
	print convert(char(20), getdate(),121)

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 997 : XX_CERIS_INSERT_TS_RECLASS_SP.sql '
 
    INSERT INTO IMAPSStg.dbo.xx_ceris_retro_ts_prep
           (TS_DT,EMPL_ID,S_TS_TYPE_CD,WORK_STATE_CD,FY_CD,PD_NO,SUB_PD_NO,CORRECTING_REF_DT,
			PAY_TYPE,
			GENL_LAB_CAT_CD,S_TS_LN_TYPE_CD,
			LAB_CST_AMT,CHG_HRS,
			WORK_COMP_CD,LAB_LOC_CD,ORG_ID,ACCT_ID,PROJ_ID,BILL_LAB_CAT_CD,REF_STRUC_1_ID,
			REF_STRUC_2_ID,ORG_ABBRV_CD,PROJ_ABBRV_CD,TS_HDR_SEQ_NO,EFFECT_BILL_DT,PROJ_ACCT_ABBRV_CD,
			NOTES) 
    SELECT  TS_DT,EMPL_ID,S_TS_TYPE_CD,WORK_STATE_CD,FY_CD,PD_NO,SUB_PD_NO,CORRECTING_REF_DT,
			'R' as PAY_TYPE,
			GENL_LAB_CAT_CD,S_TS_LN_TYPE_CD,
			LAB_CST_AMT, CHG_HRS,  --LAB_CST_AMT CALCULATED, CHG_HRS not changed
			WORK_COMP_CD,LAB_LOC_CD,ORG_ID,ACCT_ID,PROJ_ID,BILL_LAB_CAT_CD,REF_STRUC_1_ID,
			REF_STRUC_2_ID,ORG_ABBRV_CD,PROJ_ABBRV_CD,TS_HDR_SEQ_NO,EFFECT_BILL_DT,PROJ_ACCT_ABBRV_CD,
			REG_NOTES as NOTES --NOTES changed (A type) not sure if that means anything important
    FROM XX_CERIS_TS_PREP_OT_RECLASS

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER



    RETURN (0)
    
    BL_ERROR_HANDLER:
    
    PRINT 'ERROR IN XX_CERIS_INSERT_TS_RECLASS_SP'
    RETURN(1)

END


go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_CERIS_INSERT_TS_RECLASS_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_CERIS_INSERT_TS_RECLASS_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_CERIS_INSERT_TS_RECLASS_SP >>>'
go

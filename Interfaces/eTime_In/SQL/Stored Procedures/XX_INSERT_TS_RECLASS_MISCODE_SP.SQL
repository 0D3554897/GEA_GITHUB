IF OBJECT_ID('dbo.XX_INSERT_TS_RECLASS_MISCODE_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_INSERT_TS_RECLASS_MISCODE_SP
    IF OBJECT_ID('dbo.XX_INSERT_TS_RECLASS_MISCODE_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_INSERT_TS_RECLASS_MISCODE_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_INSERT_TS_RECLASS_MISCODE_SP >>>'
END
go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go

CREATE procedure [dbo].[XX_INSERT_TS_RECLASS_MISCODE_SP]
as

/************************************************************************************************  
Name:           [XX_INSERT_TS_RECLASS_MISCODE_SP]
Author:         KM
Created:        10/2012
Purpose:        

    
    THIS ENTIRE STORED PROCEDURE IS FOR CR-4886 Actuals Implementation
    
    1.Non-Exempt employee

    Non-Exempt emplyee needs a special logic to reclassify the hours between default account and special account.
    Non-Exempt employee needs a special logic to default the account when the pay_type is OT


execute XX_INSERT_TS_RECLASS_MISCODE_SP

Prerequisites:     none 
Version:     1.0
	Modified 12/13/2012 - Added GLCs in select list
                    
CR6702 -  Govt Shutdown - Apply NonRegular Pay Type Factor to NonExempt Labor - 2013-10-16
************************************************************************************************/ 
BEGIN

	--CR6702 begin
	insert into XX_ET_EXCLUDE_PROJECTS
	(proj_abbrv_cd, time_stamp, active_fl)
	select proj_abbrv_cd, getdate(), 'N'
	from imaps.deltek.proj p
	where proj_abbrv_cd<>''
	--(non regular pay type) pag
	and acct_grp_cd in (select acct_grp_cd from imaps.deltek.lab_acct_grp_dflt where isnull(reg_pay_type,'R')<>'R' group by acct_grp_cd) 
	and 0=(select count(1) from XX_ET_EXCLUDE_PROJECTS where proj_abbrv_cd=p.proj_abbrv_cd) --not already in table
	group by proj_abbrv_cd
	--CR6702 end


	DECLARE @in_begin_reclass_date  datetime

	SELECT  @in_begin_reclass_date=parameter_value
    FROM xx_processing_parameters
    WHERE interface_name_cd='CERIS'
    AND UPPER(parameter_name)='ACTUALS_EFFECT_DT' -- Change it to 2012


     --BEGIN MERGE of previous RECLASS
     --Added 09/19/2012
        --Replace OT pay type with blank, so when we merge we ignore STB/STW pay types
        update dbo.XX_IMAPS_TS_PREP_TEMP 
        set pay_type=''
        where pay_type='OT'
	    and s_ts_type_cd<>'N'

        --Update notes value without -A- or -B-, that way we can group the records later on
        update dbo.XX_IMAPS_TS_PREP_TEMP 
        set notes=
		            substring(notes,1,CHARINDEX('-', notes, 1))
		            +substring(notes, CHARINDEX('-', notes, 1)+1, (CHARINDEX('-', notes, (CHARINDEX('-', notes, 1)+1))-CHARINDEX('-', notes, 1)-1) )
			        +'-'
		            +substring(notes, CHARINDEX('ACTVT_CD', notes, 1), len(notes))
        where (notes like '%-A-%' or notes like '%-B-%')
	    and s_ts_type_cd<>'N'

        --Create temp table using group by so, reclass rows will be merged together
        SELECT 
	        TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
	        SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, 
	         sum(convert(numeric(14,2),LAB_CST_AMT)) LAB_CST_AMT, sum(convert(numeric(14,2),CHG_HRS)) CHG_HRS,
	        GENL_LAB_CAT_CD, LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO, --Added CR-4886 GLC Fix 12/13/12
	        EFFECT_BILL_DT,
				        substring(notes,1,CHARINDEX('-', notes, 1))
				        +substring(notes, CHARINDEX('-', notes, 1)+1, (CHARINDEX('-', notes, (CHARINDEX('-', notes, 1)+1))-CHARINDEX('-', notes, 1)-1) )
				        +'-'
				        +substring(notes, CHARINDEX('ACTVT_CD', notes, 1), len(notes)) NOTES
        INTO #XX_IMAPS_TS_PREP_TEMP3
        FROM dbo.XX_IMAPS_TS_PREP_TEMP 
	    WHERE S_TS_TYPE_CD<>'N'
        --WHERE empl_id IN (   '081761','566816','7D7652','439985','153298','7D7043','1G2913','052855','7D7268','7D7732' )
        GROUP BY TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
			 --Added CR-4886 GLC Fix 12/13/12
	        SUB_PD_NO, CORRECTING_REF_DT,  PAY_TYPE, LAB_LOC_CD, PROJ_ID, GENL_LAB_CAT_CD, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
	        EFFECT_BILL_DT,
				        substring(notes,1,CHARINDEX('-', notes, 1))
				        +substring(notes, CHARINDEX('-', notes, 1)+1, (CHARINDEX('-', notes, (CHARINDEX('-', notes, 1)+1))-CHARINDEX('-', notes, 1)-1) )
				        +'-'
				        +substring(notes, CHARINDEX('ACTVT_CD', notes, 1), len(notes))

        --Check the total between two tables so we can copy/move the data
        -- Clean up the TEMP3 table if the sum of hours matches before and after merge
        DECLARE @out_check_sum3 numeric(14,2),
		        @out_check_sum4 numeric(14,2)

        select @out_check_sum3=sum(cast(chg_hrs as numeric(14,2)))
	        FROM dbo.XX_IMAPS_TS_PREP_TEMP 
		    WHERE S_TS_TYPE_CD<>'N'

        select @out_check_sum4=sum(cast(chg_hrs as numeric(14,2)))
	        FROM #XX_IMAPS_TS_PREP_TEMP3

        print @out_check_sum3
        print @out_check_sum4


        IF @out_check_sum3<>@out_check_sum4 
	        BEGIN
		        PRINT 'Sum of hours are not matching between #temp3 and temp'
		        GOTO BL_ERROR_HANDLER
	        END
        ELSE
	        BEGIN
		        delete from dbo.XX_IMAPS_TS_PREP_TEMP
			    WHERE S_TS_TYPE_CD<>'N'

		        insert into dbo.XX_IMAPS_TS_PREP_TEMP
		        (TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
			        SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, GENL_LAB_CAT_CD, --Added CR-4886, GLC Fix 12/13/12
			         LAB_CST_AMT,  CHG_HRS,
			        LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
			        EFFECT_BILL_DT, NOTES)
		        SELECT 	TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
			        SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, GENL_LAB_CAT_CD, --Added CR-4886, GLC Fix 12/13/12
			         LAB_CST_AMT,  CHG_HRS,
			        LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
			        EFFECT_BILL_DT, NOTES
		        from #XX_IMAPS_TS_PREP_TEMP3
	        END


     --END MERGE of previous RECLASS


    --0 Clear OT Reclass table before we begin
    
    DELETE FROM XX_IMAPS_TS_PREP_OT_RECLASS




	--1
	PRINT 'LOAD TS PREP INTO TEMP TABLE'
	print convert(char(20), getdate(),121)

    INSERT INTO XX_IMAPS_TS_PREP_OT_RECLASS
        (
        TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO, 
        SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE , GENL_LAB_CAT_CD, S_TS_LN_TYPE_CD, 
        LAB_CST_AMT, CHG_HRS, WORK_COMP_CD, LAB_LOC_CD, ORG_ID, ACCT_ID, PROJ_ID, 
        BILL_LAB_CAT_CD, REF_STRUC_1_ID, REF_STRUC_2_ID, ORG_ABBRV_CD, PROJ_ABBRV_CD, 
        TS_HDR_SEQ_NO, EFFECT_BILL_DT, PROJ_ACCT_ABBRV_CD, NOTES, REG_HRS, OT_HRS, 
        REG_NOTES, OT_NOTES, STATE_CD, S_OT_BASIS_CD, EXMPT_HRS 
        )
	SELECT 
        ts.TS_DT, ts.EMPL_ID, ts.S_TS_TYPE_CD, ts.WORK_STATE_CD, ts.FY_CD, ts.PD_NO, 
        ts.SUB_PD_NO, ts.CORRECTING_REF_DT, ts.PAY_TYPE , ts.GENL_LAB_CAT_CD, ts.S_TS_LN_TYPE_CD, 
        ts.LAB_CST_AMT, ts.CHG_HRS, ts.WORK_COMP_CD, ts.LAB_LOC_CD, ts.ORG_ID, ts.ACCT_ID, ts.PROJ_ID, 
        ts.BILL_LAB_CAT_CD, ts.REF_STRUC_1_ID, ts.REF_STRUC_2_ID, ts.ORG_ABBRV_CD, ts.PROJ_ABBRV_CD, 
        ts.TS_HDR_SEQ_NO, ts.EFFECT_BILL_DT, ts.PROJ_ACCT_ABBRV_CD, ts.NOTES, 

	    cast(ts.chg_hrs as decimal(14,2)) as REG_HRS,
	    cast('00.00' as decimal(14,2)) as OT_HRS,

	    ts.NOTES as REG_NOTES,
	    ts.NOTES as OT_NOTES,

	    otrules.STATE_CD, otrules.S_OT_BASIS_CD, otrules.EXMPT_HRS

	from 
    	XX_IMAPS_TS_PREP_TEMP ts
	inner join
    	imaps.deltek.empl_lab_info eli
	on
		(
		ts.s_ts_type_cd in ('R','D')
		and
		ts.empl_id=eli.empl_id
		and
		cast(isnull(ts.correcting_ref_dt,ts.ts_dt) as datetime) between eli.effect_dt and eli.end_dt
		and
		eli.EXMPT_FL='N'
		)
	inner join
	imaps.deltek.ot_rules_by_state otrules
	on
		(eli.WORK_STATE_CD=otrules.STATE_CD)
	where
        --Only Reg and D timesheets will be reclassed since this is a miscode process
        ts.s_ts_type_cd in ('R','D') 
        and
		--Actuals_EFFECT_DT
		cast(ts.effect_bill_dt as datetime) >=@in_begin_reclass_date 
		and
		--not already OT
		ts.pay_type<>'OT'
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
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER



	--prune reclass table
	--2
	PRINT 'PRUNE TEMP TABLE FOR ONLY OT WORKED'
	print convert(char(20), getdate(),121)

	delete XX_IMAPS_TS_PREP_OT_RECLASS
	from XX_IMAPS_TS_PREP_OT_RECLASS t1
	where 
	S_OT_BASIS_CD='W'
	and 
	EXMPT_HRS >=
	(
	 select abs(sum(cast(chg_hrs as decimal(14,2))))
	 from XX_IMAPS_TS_PREP_OT_RECLASS
	 where empl_id=t1.empl_id
	 and s_ts_type_cd=t1.s_ts_type_cd
	 and dbo.xx_get_friday_for_ts_week_day_uf(effect_bill_dt)=dbo.xx_get_friday_for_ts_week_day_uf(t1.effect_bill_dt)
	)

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


	delete XX_IMAPS_TS_PREP_OT_RECLASS
	from XX_IMAPS_TS_PREP_OT_RECLASS t1
	where 
	S_OT_BASIS_CD='D'
	and 
	EXMPT_HRS >=
	(
	 select abs(sum(cast(chg_hrs as decimal(14,2))))
	 from XX_IMAPS_TS_PREP_OT_RECLASS
	 where empl_id=t1.empl_id
	 and s_ts_type_cd=t1.s_ts_type_cd
	 and effect_bill_dt=t1.effect_bill_dt
	)

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	--3
	PRINT 'CALCULATE OT IN TEMP TABLE'
	print convert(char(20), getdate(),121)

	--calculate OT_HRS via ratio

	update XX_IMAPS_TS_PREP_OT_RECLASS
	set OT_HRS= 
		REG_HRS * 
		((
		 select abs(sum(cast(chg_hrs as decimal(14,2))))
		 from XX_IMAPS_TS_PREP_OT_RECLASS
		 where empl_id=t1.empl_id
		 and s_ts_type_cd=t1.s_ts_type_cd
		 and dbo.xx_get_friday_for_ts_week_day_uf(effect_bill_dt)=dbo.xx_get_friday_for_ts_week_day_uf(t1.effect_bill_dt)
		) - EXMPT_HRS )/ 
		(
		 select abs(sum(cast(chg_hrs as decimal(14,2))))
		 from XX_IMAPS_TS_PREP_OT_RECLASS
		 where empl_id=t1.empl_id
		 and s_ts_type_cd=t1.s_ts_type_cd
		 and dbo.xx_get_friday_for_ts_week_day_uf(effect_bill_dt)=dbo.xx_get_friday_for_ts_week_day_uf(t1.effect_bill_dt)
		)
	from XX_IMAPS_TS_PREP_OT_RECLASS t1
	where 
	S_OT_BASIS_CD='W'

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	update XX_IMAPS_TS_PREP_OT_RECLASS
	set OT_HRS= 
	REG_HRS * 
	    ((
	     select abs(sum(cast(chg_hrs as decimal(14,2))))
	     from XX_IMAPS_TS_PREP_OT_RECLASS
	     where empl_id=t1.empl_id
	     and s_ts_type_cd=t1.s_ts_type_cd
	     and effect_bill_dt=t1.effect_bill_dt
	    ) - EXMPT_HRS )/ 
	    (
	     select abs(sum(cast(chg_hrs as decimal(14,2))))
	     from XX_IMAPS_TS_PREP_OT_RECLASS
	     where empl_id=t1.empl_id
	     and s_ts_type_cd=t1.s_ts_type_cd
	     and effect_bill_dt=t1.effect_bill_dt
	    )
	    from XX_IMAPS_TS_PREP_OT_RECLASS t1
	    where 
	    S_OT_BASIS_CD='D'

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


	update XX_IMAPS_TS_PREP_OT_RECLASS
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
	        from XX_IMAPS_TS_PREP_OT_RECLASS
	    where 
    	    S_OT_BASIS_CD='W'
	    group by empl_id, s_ts_type_cd,  EXMPT_HRS,	dbo.xx_get_friday_for_ts_week_day_uf(effect_bill_dt)
	    having 	abs(sum(reg_hrs))<>EXMPT_HRS


	OPEN WEEKS_WITH_REG_OT_ROUNDING_ISSUES
	FETCH WEEKS_WITH_REG_OT_ROUNDING_ISSUES
	INTO  @empl_id, @s_ts_type_cd, @friday, @exmpt_hrs, @tot_hrs, @reg_hrs, @ot_hrs

	WHILE (@@fetch_status = 0)
	BEGIN

		--LOOP THROUGH LINES AND DISTRIBUTE EXTRA TENTH OF HOURS FOR WEEK
		DECLARE WEEKS_WITH_REG_OT_ROUNDING_ISSUES_lines CURSOR FAST_FORWARD FOR
		    SELECT  NOTES
		    FROM	XX_IMAPS_TS_PREP_OT_RECLASS
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

			SELECT 	@temp_amt = SUM(reg_hrs)
			FROM	XX_IMAPS_TS_PREP_OT_RECLASS
			WHERE	empl_id=@empl_id
			and		s_ts_type_cd=@s_ts_type_cd
			and		dbo.xx_get_friday_for_ts_week_day_uf(effect_bill_dt)=@friday
		
			IF( (abs(@temp_amt) < @exmpt_hrs AND @temp_amt>0)   OR  (abs(@temp_amt) > @exmpt_hrs AND @temp_amt<0) )
			BEGIN
				UPDATE  XX_IMAPS_TS_PREP_OT_RECLASS				SET		REG_HRS = REG_HRS + 0.01,
						OT_HRS = OT_HRS - 0.01
				WHERE	empl_id=@empl_id
				and		s_ts_type_cd=@s_ts_type_cd
				and		dbo.xx_get_friday_for_ts_week_day_uf(effect_bill_dt)=@friday
				and 	NOTES = @notes
		
				SET @temp_amt = @temp_amt + 0.01
			END

			IF( (abs(@temp_amt) < @exmpt_hrs AND @temp_amt<0)   OR  (abs(@temp_amt) > @exmpt_hrs AND @temp_amt>0) )
			BEGIN
				UPDATE  XX_IMAPS_TS_PREP_OT_RECLASS				SET		REG_HRS = REG_HRS - 0.01,
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
	    from XX_IMAPS_TS_PREP_OT_RECLASS
	    where S_OT_BASIS_CD='D'
	    group by empl_id, s_ts_type_cd,  EXMPT_HRS,  effect_bill_dt
	    having abs(sum(reg_hrs))<>EXMPT_HRS


	OPEN DAYS_WITH_REG_OT_ROUNDING_ISSUES
	FETCH DAYS_WITH_REG_OT_ROUNDING_ISSUES
	INTO  @empl_id, @s_ts_type_cd, @workday, @exmpt_hrs, @tot_hrs, @reg_hrs, @ot_hrs

	WHILE (@@fetch_status = 0)
	BEGIN

		--LOOP THROUGH LINES AND DISTRIBUTE EXTRA TENTH OF HOURS FOR WEEK

		DECLARE DAYS_WITH_REG_OT_ROUNDING_ISSUES_lines CURSOR FAST_FORWARD FOR
		    SELECT  NOTES
		    FROM	XX_IMAPS_TS_PREP_OT_RECLASS
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

			SELECT 	@temp_amt = SUM(reg_hrs)
			FROM	XX_IMAPS_TS_PREP_OT_RECLASS
			WHERE	empl_id=@empl_id
			and		s_ts_type_cd=@s_ts_type_cd
			and		effect_bill_dt=@workday
		
			IF( (abs(@temp_amt) < @exmpt_hrs AND @temp_amt>0)   OR  (abs(@temp_amt) > @exmpt_hrs AND @temp_amt<0) )
			BEGIN
				UPDATE  XX_IMAPS_TS_PREP_OT_RECLASS				SET		REG_HRS = REG_HRS + 0.01,
						OT_HRS = OT_HRS - 0.01
				WHERE	empl_id=@empl_id
				and		s_ts_type_cd=@s_ts_type_cd
				and		effect_bill_dt=@workday
				and 	NOTES = @notes
		
				SET @temp_amt = @temp_amt + 0.01
			END

			IF( (abs(@temp_amt) < @exmpt_hrs AND @temp_amt<0)   OR  (abs(@temp_amt) > @exmpt_hrs AND @temp_amt>0) )
			BEGIN
				UPDATE  XX_IMAPS_TS_PREP_OT_RECLASS				SET		REG_HRS = REG_HRS - 0.01,
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

	update XX_IMAPS_TS_PREP_OT_RECLASS
	set reg_notes=replace(notes, '-ACTVT_CD','-A-ACTVT_CD'),
		ot_notes=replace(notes, '-ACTVT_CD','-B-ACTVT_CD')

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER



	PRINT 'RECON CHECK ON HOURS'
	print convert(char(20), getdate(),121)

	declare @count int
	    select @count=count(1)
	    from XX_IMAPS_TS_PREP_OT_RECLASS
	    where cast(chg_hrs as decimal(14,2))<>reg_hrs+ot_hrs

	if @count <> 0 GOTO BL_ERROR_HANDLER





	PRINT 'INSERT RECLASSED REG LINES'
	print convert(char(20), getdate(),121)

    INSERT INTO IMAPSStg.dbo.XX_IMAPS_TS_PREP_TEMP
           (TS_DT,EMPL_ID,S_TS_TYPE_CD,WORK_STATE_CD,FY_CD,PD_NO,SUB_PD_NO,CORRECTING_REF_DT,
			PAY_TYPE,
			GENL_LAB_CAT_CD,S_TS_LN_TYPE_CD,
			LAB_CST_AMT,CHG_HRS,
			WORK_COMP_CD,LAB_LOC_CD,ORG_ID,ACCT_ID,PROJ_ID,BILL_LAB_CAT_CD,REF_STRUC_1_ID,
			REF_STRUC_2_ID,ORG_ABBRV_CD,PROJ_ABBRV_CD,TS_HDR_SEQ_NO,EFFECT_BILL_DT,PROJ_ACCT_ABBRV_CD,
			NOTES) 
    SELECT  TS_DT,EMPL_ID,S_TS_TYPE_CD,WORK_STATE_CD,FY_CD,PD_NO,SUB_PD_NO,CORRECTING_REF_DT,
		    PAY_TYPE,
			GENL_LAB_CAT_CD,S_TS_LN_TYPE_CD,
			'0' as LAB_CST_AMT, REG_HRS as CHG_HRS,
			WORK_COMP_CD,LAB_LOC_CD,ORG_ID,ACCT_ID,PROJ_ID,BILL_LAB_CAT_CD,REF_STRUC_1_ID,
			REF_STRUC_2_ID,ORG_ABBRV_CD,PROJ_ABBRV_CD,TS_HDR_SEQ_NO,EFFECT_BILL_DT,PROJ_ACCT_ABBRV_CD,
			REG_NOTES as NOTES
    FROM XX_IMAPS_TS_PREP_OT_RECLASS

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


	PRINT 'INSERT RECLASSED OT LINES'
	print convert(char(20), getdate(),121)

    INSERT INTO IMAPSStg.dbo.XX_IMAPS_TS_PREP_TEMP
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
    FROM XX_IMAPS_TS_PREP_OT_RECLASS

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER



	PRINT 'DELETE NON RECLASSED TS LINES'
	print convert(char(20), getdate(),121)

	DELETE XX_IMAPS_TS_PREP_TEMP
	FROM XX_IMAPS_TS_PREP_TEMP ts
	WHERE 
	0 <> (select count(1) 
		  from XX_IMAPS_TS_PREP_OT_RECLASS
		  where empl_id=ts.empl_id
		  and ts_dt=ts.ts_dt
		  and s_ts_type_cd=ts.s_ts_type_cd
		  and ts_hdr_seq_no=ts.ts_hdr_seq_no
		  and effect_bill_dt=ts.effect_bill_dt
		  and notes=ts.notes)

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


    RETURN (0)
    
    BL_ERROR_HANDLER:
    
    PRINT 'ERROR IN XX_INSERT_TS_RECLASS_MISCODE_SP'
    RETURN(1)

END



go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_INSERT_TS_RECLASS_MISCODE_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_INSERT_TS_RECLASS_MISCODE_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_INSERT_TS_RECLASS_MISCODE_SP >>>'
go

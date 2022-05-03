IF OBJECT_ID('dbo.XX_R22_CERIS_PROCESS_RETRO_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_CERIS_PROCESS_RETRO_SP
    IF OBJECT_ID('dbo.XX_R22_CERIS_PROCESS_RETRO_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_CERIS_PROCESS_RETRO_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_CERIS_PROCESS_RETRO_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER ON
go




CREATE PROCEDURE [dbo].[XX_R22_CERIS_PROCESS_RETRO_SP]
(
@in_STATUS_RECORD_NUM     integer,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS

/************************************************************************************************  
Name:       	XX_R22_CERIS_PROCESS_RETRO_SP
Author:     	V Veera
Created:    	05/21/2008  
Purpose:    	Process the retroactive timesheet data.
                Called by XX_R22_CERIS_RUN_INTERFACE_SP.

--KM CR2350 retro-timesheets
--Tejas CR-2350 HDR_SEQ_NO logic moved after the NOTES update section
--Tejas Account/ORG Updates, Reclass sections added 5/10/2010
--KM track standard hours changes
--Tejas CR-2350 Std Hrs change triggers salary change and disregard the retro of salary 5/22/2011
--Tejas CR-2350 PROJ_ID change modified 8/17/2011
--Tejas CR-2350 ORG_ID Retros for ORG should move to HOLD table 09/19/2011
--Tejas CR-2350 Update OT pay type to R for reversing lines 09/19/2011 
--Tejas CR-2350 Updated Notes values, Fix partial TC process/hold issue 10/20/2011

-- Last checked into ClearCase on 10/21/2011 9:27:43 AM, size 25852, 737 lines

--CR4107 11/11/2011 - Create retro-active timesheets for CERIS department changes
--CR4107 03/13/2012 - Moved Project update block after ORG id update Tejas
*************************************************************************************************/

BEGIN

DECLARE @SP_NAME                 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @row_count               integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@ret_code		 integer

-- set local constants
SET @SP_NAME = 'XX_R22_CERIS_PROCESS_RETRO_SP'

PRINT 'Process Stage CERIS_R5 - Prepare retroactive timesheet data (conditional) ...'

/*
Requirement 10:
Process CERIS retro time sheet changes on employee class, salary, and department only for time occuring within the 
current quarter. For example, the current date is 4/22/08. We are in the second quarter of 2008.  If a CERIS action on the 
current file contains a change dated 1/22/08, only process retro-active timesheets for that change for hours occurring since 4/1/08.

comment above is OUTDATED
see CR2350 :)
*/

DECLARE EMPL_ID_CURSOR CURSOR FAST_FORWARD FOR
SELECT EMPL_ID, MIN(EFFECT_DT), MAX(END_DT) 
FROM XX_R22_CERIS_RETRO_TS
WHERE EFFECT_DT < END_DT
GROUP BY EMPL_ID ORDER BY EMPL_ID

DECLARE @EMPL_ID varchar(12),
		@START_DT smalldatetime,
		@END_DT smalldatetime

OPEN EMPL_ID_CURSOR
FETCH NEXT FROM EMPL_ID_CURSOR INTO @EMPL_ID,@START_DT,@END_DT

WHILE @@FETCH_STATUS = 0
BEGIN

	EXEC @ret_code = dbo.XX_R22_CERIS_LOAD_RETRO_TS_PREP_SP
			 @in_STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM,
			 @in_EMPL_ID = @EMPL_ID,
			 @in_START_DT = @START_DT,
			 @in_END_DT = @END_DT

	IF @ret_code <> 0 GOTO BL_ERROR_HANDLER

FETCH NEXT FROM EMPL_ID_CURSOR INTO @EMPL_ID,@START_DT,@END_DT
END
CLOSE EMPL_ID_CURSOR
DEALLOCATE EMPL_ID_CURSOR


--KM CR2350
--update notes to be descriptive

--KM track standard hours changes
UPDATE XX_R22_CERIS_RETRO_TS_PREP
SET NOTES = RTRIM(LTRIM(NOTES)) + '-WORK_YR_HRS_NO'
FROM XX_R22_CERIS_RETRO_TS_PREP TS
WHERE 
0 <
(SELECT COUNT(1) 
 FROM XX_R22_CERIS_STD_HRS_CHANGES
 WHERE 
 STATUS_RECORD_NUM=@in_STATUS_RECORD_NUM
 AND EMPL_ID=TS.EMPL_ID
 AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) >= cast(new_WORK_SCHD_DT as datetime)
 )
-- Modified CR-2350 05/23/2011 
-- Modified Friday function for Std Hrs Change
-- TC for entire week should be moved to HOLD table

UPDATE XX_R22_CERIS_RETRO_TS_PREP
SET NOTES = RTRIM(LTRIM(NOTES)) + '-EXMPT_FL'
FROM XX_R22_CERIS_RETRO_TS_PREP TS
WHERE 
0 <
(SELECT COUNT(1) 
 FROM XX_R22_CERIS_RETRO_TS
 WHERE EMPL_ID=TS.EMPL_ID
 AND NEW_EXMPT_FL IS NOT NULL
 AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN EFFECT_DT AND END_DT)
--Added Friday function to make sure notes of entire TC is updates
--Resolves issue of partial TC moving to hold table and to CP
--CR-2350 10/20/2011 TP

--TP CR-2350 Section moved before the HDR_SEQ_NO updates
UPDATE XX_R22_CERIS_RETRO_TS_PREP
SET NOTES = RTRIM(LTRIM(NOTES)) + '-ORG_ID'
FROM XX_R22_CERIS_RETRO_TS_PREP TS
WHERE 
0 <
(SELECT COUNT(1) 
 FROM XX_R22_CERIS_RETRO_TS
 WHERE EMPL_ID=TS.EMPL_ID
 AND NEW_ORG_ID IS NOT NULL
 AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN EFFECT_DT AND END_DT)
--Added Friday function to make sure notes of entire TC is updates
--Resolves issue of partial TC moving to hold table and to CP
--CR-2350 10/20/2011 TP


UPDATE XX_R22_CERIS_RETRO_TS_PREP
SET NOTES = RTRIM(LTRIM(NOTES)) + '-EMPL_CLASS_CD'
FROM XX_R22_CERIS_RETRO_TS_PREP TS
WHERE 
0 <
(SELECT COUNT(1) 
 FROM XX_R22_CERIS_RETRO_TS
 WHERE EMPL_ID=TS.EMPL_ID
 AND NEW_EMPL_CLASS_CD IS NOT NULL
 AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN EFFECT_DT AND END_DT)
--Added Friday function to make sure notes of entire TC is updates
--Resolves issue of partial TC moving to hold table and to CP
--CR-2350 10/20/2011 TP


UPDATE XX_R22_CERIS_RETRO_TS_PREP
SET NOTES = RTRIM(LTRIM(NOTES)) + '-HRLY_AMT'
FROM XX_R22_CERIS_RETRO_TS_PREP TS
WHERE 
0 <
(SELECT COUNT(1) 
 FROM XX_R22_CERIS_RETRO_TS
 WHERE EMPL_ID=TS.EMPL_ID
 AND NEW_HRLY_AMT IS NOT NULL
 AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN EFFECT_DT AND END_DT)
--Added Friday function to make sure notes of entire TC is updates
--Resolves issue of partial TC moving to hold table and to CP
--CR-2350 10/20/2011 TP

    ------BEGIN ACCOUNT ORG Updates


	-- Added CR-2350 05/11/2010 Tejas
	--Manual Simulate step	
	UPDATE XX_R22_CERIS_RETRO_TS_PREP 
	SET
	GENL_LAB_CAT_CD = ELI.GENL_LAB_CAT_CD,
	ORG_ID = ELI.ORG_ID
	FROM
	XX_R22_CERIS_RETRO_TS_PREP TS
	INNER JOIN
	IMAR.DELTEK.EMPL_LAB_INFO ELI
	ON
	(
	ELI.EMPL_ID = TS.EMPL_ID
	AND
	 (
		( TS.S_TS_TYPE_CD = 'R'
		  AND
		  TS.TS_DT BETWEEN ELI.EFFECT_DT AND ELI.END_DT	)
		OR
		( TS.S_TS_TYPE_CD in ('C','N','D')
		  AND
		  TS.CORRECTING_REF_DT BETWEEN ELI.EFFECT_DT AND ELI.END_DT)
	 )
	)
	WHERE S_TS_TYPE_CD='D' -- Only update values in D +ve lines
	
	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

 --Moved the block after org_id update CR-4107 03/13/2012 Tejas
 -- CR4107_Begin
   UPDATE dbo.XX_R22_CERIS_RETRO_TS_PREP
   SET PROJ_ID = (select distinct PROJ_ID
                    from IMAR.Deltek.PROJ
                   where ORG_ID = ts.ORG_ID
                     and len(rtrim(PROJ_ABBRV_CD)) > 0
                     and PROJ_ID like 'RRDE%'
                 ),
       PROJ_ABBRV_CD = (select distinct PROJ_ABBRV_CD
                          from IMAR.Deltek.PROJ
                         where ORG_ID = ts.ORG_ID
                           and len(rtrim(PROJ_ABBRV_CD)) > 0
                           and PROJ_ID like 'RRDE%'
                       )
   FROM dbo.XX_R22_CERIS_RETRO_TS_PREP ts
       INNER JOIN
       IMAR.DELTEK.EMPL_LAB_INFO empl_lab
       ON
       (ts.EMPL_ID = empl_lab.EMPL_ID
        AND 
        (
         (ts.S_TS_TYPE_CD = 'R' AND CAST(ts.TS_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
         OR
         (ts.S_TS_TYPE_CD in ('C','N','D') AND CAST(ts.CORRECTING_REF_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
        )
       )
   WHERE ts.S_TS_TYPE_CD = 'D'
    AND ts.PROJ_ID like 'RRDE%'
    AND ts.NOTES like '%ORG%'
 -- CR4107_End

	IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


	-- Update Account ID only for non-reclass lines and non-backing out lines
	-- Only update account for original lines like -A-
	UPDATE DBO.XX_R22_CERIS_RETRO_TS_PREP
	SET ACCT_ID = lab_acct.ACCT_ID
	FROM dbo.XX_R22_CERIS_RETRO_TS_PREP ts
	INNER JOIN IMAR.DELTEK.EMPL_LAB_INFO empl_lab
	on
	(ts.empl_id = empl_lab.empl_id
		and 
		(
			(ts.S_TS_TYPE_CD = 'R' AND cast(ts.TS_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT)
			OR
			(ts.S_TS_TYPE_CD in ('C','N','D') AND cast(ts.CORRECTING_REF_DT as datetime) BETWEEN empl_lab.EFFECT_DT AND empl_lab.END_DT) -- Modified CR-1649
		)
	)
	INNER JOIN IMAR.DELTEK.PROJ proj
	on
	(ts.PROJ_ABBRV_CD = proj.PROJ_ABBRV_CD
	AND proj.COMPANY_ID=2) 	--Added CR-1543
	INNER JOIN IMAR.DELTEK.LAB_ACCT_GRP_DFLT lab_acct
	ON
	(
	empl_lab.LAB_GRP_TYPE = lab_acct.LAB_GRP_TYPE
	AND proj.ACCT_GRP_CD = lab_acct.ACCT_GRP_CD
	AND lab_acct.COMPANY_ID=2 	--Added CR-1543
	)
	WHERE (ts.notes not like '%-B-%' and ts.notes not like '%-C-%')
    and ts.S_TS_TYPE_CD='D'
    and pay_type<>'BO'

	-- Special Logic for RECLASS Lines
	-- This is required if employee's labor group has been changed
    --Non Exempt employees are not suppose to reclass lines
	update dbo.XX_R22_CERIS_RETRO_TS_PREP
	set acct_id= 
			ISNULL((SELECT distinct map.acct_id
					from XX_R22_ACCT_RECLASS map
					where map.lab_grp_type=empl_lab.lab_grp_type
					and map.acct_grp_cd=prj.acct_grp_cd
					and line_type='RECLASS'),'99-99-99') 
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
	INNER JOIN IMAR.DELTEK.proj prj
	on (ts.proj_abbrv_cd=prj.proj_abbrv_cd and prj.company_id=2)
	where exmpt_fl='Y'
	AND ts.notes  like '%-B-%'
    and ts.S_TS_TYPE_CD='D'
    and pay_type<>'BO'

	-- Special Logic for BACKOUT Lines
	-- This is required if employee's labor group has been changed
	update dbo.XX_R22_CERIS_RETRO_TS_PREP
	set acct_id= 
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
            and line_type='BACKOUT'),'99-99-99')				
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
	where --exmpt_fl='Y' -- All employees are treated same for ACCT_ID updates
	ts.notes  like '%-C-%'
    AND ts.S_TS_TYPE_CD='D'

    --------------Non-Exempt Employees
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
	
	
    ------END ACCOUNT ORG Updates


--BEGIN RECLASS SECTION
    --Added CR-2350 Tejas 01/20/10
    --This section will create reclass and BO lines for D lines for Exempt Retros only
    EXEC @ret_code = dbo.XX_R22_CERIS_RESPROC_RECORDS_SP

     IF @ret_code <> 0
             BEGIN
                -- Attempt to insert a XX_IMAPS_TS_PREP_TEMP record failed.
                EXEC dbo.XX_ERROR_MSG_DETAIL
                   @in_error_code           = 204,
                   @in_display_requested    = 1,
                   @in_SQLServer_error_code = @ret_code,
                   @in_placeholder_value1   = 'insert',
                   @in_placeholder_value2   = 'XX_R22_CERIS_RETRO_TS_PREP Research process',
                   @in_calling_object_name  = @SP_NAME,
                   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
                RETURN(1)
             END

	-- Special Logic for BACKOUT Lines
	-- This is required if employee had ORG Retro, and for positive lines.
    -- Modified 08/15/2011 Tejas Patel
	update dbo.XX_R22_CERIS_RETRO_TS_PREP
	set proj_abbrv_cd= 
		(select distinct proj_abbrv_cd from IMAR.DELTEK.proj 
        where company_id=2 
        and rtrim(org_id)=rtrim(empl_lab.org_id) 
        and substring(proj_id,1,4)='RRDE'
        and empl_lab.org_id is not null
        and proj_abbrv_cd is not null 
        and rtrim(proj_abbrv_cd)<>'') ,
        --Added CR-2350 Tejas Patel 08/16/2011
        proj_id= 
		(select distinct proj_id from IMAR.DELTEK.proj 
        where company_id=2 
        and rtrim(org_id)=rtrim(empl_lab.org_id) 
        and substring(proj_id,1,4)='RRDE'
        and empl_lab.org_id is not null
        and proj_abbrv_cd is not null 
        and rtrim(proj_abbrv_cd)<>'') ,
		acct_id=		
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
            and line_type='BACKOUT'),'99-99-99')				
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
	where empl_lab.exmpt_fl='Y'
	AND ts.pay_type='BO' and ts.s_ts_type_cd='D'
        
    ----We will update only proj code for non-exmpt employees
	update dbo.XX_R22_CERIS_RETRO_TS_PREP
	set proj_abbrv_cd= 
		(select distinct proj_abbrv_cd from IMAR.DELTEK.proj 
        where company_id=2 
        and rtrim(org_id)=rtrim(empl_lab.org_id) 
        and substring(proj_id,1,4)='RRDE'
        and empl_lab.org_id is not null
        and proj_abbrv_cd is not null 
        and rtrim(proj_abbrv_cd)<>'') ,
        --Added CR-2350 Tejas Patel 08/16/2011
        proj_id= 
		(select distinct proj_id from IMAR.DELTEK.proj 
        where company_id=2 
        and rtrim(org_id)=rtrim(empl_lab.org_id) 
        and substring(proj_id,1,4)='RRDE'
        and empl_lab.org_id is not null
        and proj_abbrv_cd is not null 
        and rtrim(proj_abbrv_cd)<>'') 
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
	where empl_lab.exmpt_fl='N'
	AND ts.pay_type='BO' and ts.s_ts_type_cd='D'



             

--END RECLASS SECTION

-- BEGIN DATA MOVE
    --KM CR2350
    /*If the retro-active CERIS action crosses a fiscal year, only generate retro time sheets for the current year.  
    To determine the beginning of the current year, use the min sub_pd_begin_dt in the xx_r22_sub_pd table for the current fy_cd.  
    Note any CERIS actions; employee name, time sheet dates, and hours affected that cross the year in an accessible table or file to be used for follow up. 
    */
    INSERT INTO XX_R22_CERIS_RETRO_TS_PREP_PRIOR_YEAR_ARCH
    SELECT * FROM XX_R22_CERIS_RETRO_TS_PREP
    WHERE cast(CORRECTING_REF_DT as datetime) < 
    (select min(ts_dt) from xx_r22_sub_pd where fy_cd=DATEPART(YEAR, GETDATE()))

    SET @SQLServer_error_code = @@ERROR
    IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

    DELETE FROM XX_R22_CERIS_RETRO_TS_PREP
    WHERE cast(CORRECTING_REF_DT as datetime) < 
    (select min(ts_dt) from xx_r22_sub_pd where fy_cd=DATEPART(YEAR, GETDATE()))

    SET @SQLServer_error_code = @@ERROR
    IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

    --Added CR-2350 Tejas 5/11/2010
    --If There is retro for standard hours then move them to HOLD table so reports can look at it.
    --Move Records to hold table
    INSERT INTO XX_R22_CERIS_RETRO_TS_PREP_HOLD
    SELECT * FROM XX_R22_CERIS_RETRO_TS_PREP
    WHERE notes LIKE '%WORK_YR_HRS_NO%'

    SET @SQLServer_error_code = @@ERROR
    IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER


    --DELETE THESE RECORDS 
    DELETE FROM XX_R22_CERIS_RETRO_TS_PREP
    WHERE notes LIKE '%WORK_YR_HRS_NO%'

    SET @SQLServer_error_code = @@ERROR
    IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

    --Move records where Exempt Flg is changing from E to N
    INSERT INTO XX_R22_CERIS_RETRO_TS_PREP_HOLD
    select *
    FROM XX_R22_CERIS_RETRO_TS_PREP TS
    WHERE 
    0 <
    (SELECT COUNT(1) 
     FROM XX_R22_CERIS_RETRO_TS
     WHERE EMPL_ID=TS.EMPL_ID
     AND NEW_EXMPT_FL IS NOT NULL
     AND NEW_EXMPT_FL ='N'
-- CR4107_Begin
     AND dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN EFFECT_DT AND END_DT)
-- CR4107_End
     AND notes LIKE '%EXMPT%'

    SET @SQLServer_error_code = @@ERROR
    IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER


    --DELETE THESE RECORDS 
    DELETE FROM XX_R22_CERIS_RETRO_TS_PREP
    FROM XX_R22_CERIS_RETRO_TS_PREP TS
    WHERE 
    0 <
    (SELECT COUNT(1) 
     FROM XX_R22_CERIS_RETRO_TS
     WHERE EMPL_ID=TS.EMPL_ID
     AND NEW_EXMPT_FL IS NOT NULL
     AND NEW_EXMPT_FL ='N'
-- CR4107_Begin
     AND dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN EFFECT_DT AND END_DT)
-- CR4107_End
    AND notes LIKE '%EXMPT%'

    SET @SQLServer_error_code = @@ERROR
    IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

    --End CR-2350 Tejas 5/11/2010

    IF @@ERROR <> 0
    BEGIN
	    PRINT 'INSERT ERROR'
	    GOTO BL_ERROR_HANDLER
    END

-- CR4107_Begin
-- Disable code
/*
    --Added CR-2350 Tejas 9/19/2011
    --If There is retro for ORG change then move them to HOLD table so reports can look at it.
    --Move Records to hold table
    INSERT INTO XX_R22_CERIS_RETRO_TS_PREP_HOLD
    SELECT * FROM XX_R22_CERIS_RETRO_TS_PREP
    WHERE notes LIKE '%ORG%'

    SET @SQLServer_error_code = @@ERROR
    IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

    --DELETE THESE RECORDS
    DELETE FROM XX_R22_CERIS_RETRO_TS_PREP
    WHERE notes LIKE '%ORG%'

    SET @SQLServer_error_code = @@ERROR
    IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER
*/
-- CR4107_End

-- END DATA MOVE

--Special Update for OT paytype to R paytype
    --modified for CR-2350 09/19/2011 Tejas BFR:12 Change
    -- If OT pay type is found on reversing line then update it to R so it doesn't miscode.
    UPDATE XX_R22_CERIS_RETRO_TS_PREP
    SET NOTES=RTRIM(NOTES)+'-OT', pay_type='R'
    WHERE notes like '%-EXMPT_FL%'
	    and rtrim(s_ts_type_cd)='N'
	    and rtrim(pay_type)='OT'

    SET @SQLServer_error_code = @@ERROR
    IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

-- TS_HDR_SEQ logic will run after the above process as the new lines may be created by reclass SP
--BEGIN TS_HDR_SEQ LOGIC
    --Added CR-2350 Tejas 01/20/10
    -- To get seperate ts_hdr_seq_no for Backout line
    -- We will update the S_TS_TYPE_CD='X' and then reverse back to D
    UPDATE dbo.XX_R22_CERIS_RETRO_TS_PREP
    SET S_TS_TYPE_CD='X'
        WHERE S_TS_TYPE_CD = 'D'
	      AND PAY_TYPE='BO'

    UPDATE dbo.XX_R22_CERIS_RETRO_TS_PREP
    SET S_TS_TYPE_CD='Z'
        WHERE S_TS_TYPE_CD = 'N'
	      AND PAY_TYPE='BO'
    /* CR-2350-- Blocked as replaced by additional SP 5/3/2010 Tejas
    /*update TS_HDR_SEQ_NO in order to separate by CORRECTING_REF_DT*/
    CREATE TABLE #XX_R22_CERIS_TS_HDR_SEQ_NO (
	    [IDENTITY_TS_HDR_SEQ_NO] [INT] IDENTITY (1, 1) NOT NULL ,
	    [EMPL_ID] [CHAR] (12) NOT NULL,
	    [CORRECTING_REF_DT] [CHAR] (10) NULL,
	    /*KM CR2350*/
	 [S_TS_TYPE_CD] [char] (1) NOT NULL
    )

    INSERT INTO #XX_R22_CERIS_TS_HDR_SEQ_NO
    (EMPL_ID, CORRECTING_REF_DT, /*KM CR2350*/ S_TS_TYPE_CD)
    SELECT 	EMPL_ID, CORRECTING_REF_DT, /*KM CR2350*/ S_TS_TYPE_CD
    FROM 	DBO.XX_R22_CERIS_RETRO_TS_PREP
    --WHERE 	EMPL_ID = @EMPL_ID
    GROUP BY EMPL_ID, CORRECTING_REF_DT, S_TS_TYPE_CD

    UPDATE DBO.XX_R22_CERIS_RETRO_TS_PREP
    SET TS_HDR_SEQ_NO = CAST(TMP.IDENTITY_TS_HDR_SEQ_NO AS CHAR(3))
    FROM  DBO.XX_R22_CERIS_RETRO_TS_PREP CERIS
    INNER JOIN
	    #XX_R22_CERIS_TS_HDR_SEQ_NO TMP
    ON
    (
    CERIS.EMPL_ID = TMP.EMPL_ID
    AND CERIS.CORRECTING_REF_DT = TMP.CORRECTING_REF_DT
    /*KM CR2350*/
    AND CERIS.S_TS_TYPE_CD = TMP.S_TS_TYPE_CD
    )

    DROP TABLE #XX_R22_CERIS_TS_HDR_SEQ_NO
    */


    /*update TS_HDR_SEQ_NO in order to separate by CORRECTING_REF_DT*/
    --Begin CR-2350 5/03/10
    EXEC @RET_CODE = dbo.XX_R22_CERIS_SIMULATE_TSHDRSEQ_SP
 	IF @RET_CODE <> 0
         BEGIN
            -- Attempt to insert a XX_IMAPS_TS_PREP_TEMP record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
               @in_SQLServer_error_code = @RET_CODE,
               @in_placeholder_value1   = 'Update',
               @in_placeholder_value2   = 'XX_R22_CERIS_RETRO_TS_PREP Research TSHDRSEQ',
               @in_calling_object_name  = @SP_NAME,
               @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END


    --End CR-2419 5/03/10
    

    --Added CR-2350 Tejas 01/20/10
    -- To get seperate ts_hdr_seq_no for Backout line
    -- We will update the S_TS_TYPE_CD='X' and then reverse back to D
    UPDATE dbo.XX_R22_CERIS_RETRO_TS_PREP
    SET S_TS_TYPE_CD='D'
        WHERE S_TS_TYPE_CD = 'X'
	      AND PAY_TYPE='BO'

    UPDATE dbo.XX_R22_CERIS_RETRO_TS_PREP
    SET S_TS_TYPE_CD='N'
        WHERE S_TS_TYPE_CD = 'Z'
	      AND PAY_TYPE='BO'


    -- Added CR-2350
    -- IF TS_HDR_SEQ_NO>99 then we will increase TS_DT by one and restart seq no from 1
  update XX_R22_CERIS_RETRO_TS_PREP 
  set ts_dt = convert( char(10), cast(ts_dt as datetime)+1, 120),
      ts_hdr_seq_no = cast( (cast(ts_hdr_seq_no as int) - 99) as varchar )
  where 
     S_TS_TYPE_CD in ('C','D','N')
     and cast(ts_hdr_seq_no as int) > 99
--END TS_HDR_SEQ LOGIC


--Employee Activation
    /*
    -- Mark employee's inactive if does not have any TC and not active EU in CP
    update IMAR.DELTEK.empl
    set s_empl_status_cd='IN'
    --select * from IMAR.DELTEK.empl
    where company_id=@in_company_id
    and empl_id not in (select empl_id from xx_r22_imaps_ts_prep_temp)
    and empl_id not in (select empl_id from IMAR.DELTEK.user_id where DE_ACTIVATION_DT = NULL )
    */

    update IMAR.DELTEK.empl
    set s_empl_status_cd='ACT'
    --select * from IMAR.DELTEK.empl
    where empl_id in (select empl_id from xx_r22_ceris_retro_ts_prep)
--END of Employee Activation


DECLARE @NET_HRS DECIMAL(14,2)

SELECT 	@NET_HRS = SUM(CAST(CHG_HRS AS DECIMAL(14,2)))
FROM	DBO.XX_CERIS_RETRO_TS_PREP

SELECT @NET_HRS

IF 	@NET_HRS IS NOT NULL AND 
	@NET_HRS <> .00
BEGIN
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VALIDATE THAT NET HOURS IN'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_R22_CERIS_RETRO_TS_PREP  = .00'
	SET @SQLSERVER_ERROR_CODE = @@ERROR
	GOTO BL_ERROR_HANDLER
END


	SET @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER



RETURN(0)

BL_ERROR_HANDLER:

-- clean up
CLOSE EMPL_ID_CURSOR
DEALLOCATE EMPL_ID_CURSOR


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
IF OBJECT_ID('dbo.XX_R22_CERIS_PROCESS_RETRO_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_CERIS_PROCESS_RETRO_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_CERIS_PROCESS_RETRO_SP >>>'
go

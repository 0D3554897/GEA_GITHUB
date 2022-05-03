use imapsstg
go

IF OBJECT_ID('dbo.XX_CERIS_PROCESS_RETRO_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_CERIS_PROCESS_RETRO_SP
    IF OBJECT_ID('dbo.XX_CERIS_PROCESS_RETRO_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_CERIS_PROCESS_RETRO_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_CERIS_PROCESS_RETRO_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER ON
go



CREATE PROCEDURE dbo.XX_CERIS_PROCESS_RETRO_SP
(
@in_STATUS_RECORD_NUM     integer,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS

/************************************************************************************************  
Name:       	XX_CERIS_PROCESS_RETRO_SP
Author:     	KM
Created:    	10/2005  
Purpose:    	Process the retroactive timesheet data.
                Called by XX_CERIS_RUN_INTERFACE_SP.
Modified:       10/2007 for TS_HDR_SEQ_NO Logic Change CR-1134


CR4885 - IMAPS CERIS Interface Changes for Actuals - KM - 2012-05-25
CR-4885- IMAPS CERIS Change Added Reclass logic - Tejas - 2012-08-21
CR-4885- IMAPS CERIS Change Added TS_HDR_SEQ logic - Tejas - 2012-09-24 
CR-4885- IMAPS CERIS Change Commented Reclass logic- Tejas - 2012-09-25
CR4885 - IMAPS CERIS Interface Changes for Actuals - KM - 2012-10-02 - call simulate costpoint sp
CR4885 - IMAPS CERIS Interface Changes for Actuals - KM - 2012-10-10 - call OT reclass sp
CR4885 - IMAPS CERIS Interface Changes for Actuals - KM - 2012-10-17 - need to make sure FULL week is retro'd
CR4885 - IMAPS CERIS Interface Changes for Actuals - KM - 2012-10-18 - need to make sure FULL week is retro'd, small change for effect date change only

DR5811 - CERIS retro timesheet miscodes: inconsistent work state code - KM - 2013-01-15

DR6720 - CERIS retro timesheets miscode when max ts_hdr_seq_no of 99 is reached - KM - 2014-04-22
*************************************************************************************************/

BEGIN

PRINT 'Process Stage CERIS5 - Prepare retroactive timesheet data (conditional) ...'

-- there could be one or two records in the xx_ceris_retro_ts table
-- if two, they may have different effective dates


DECLARE @SP_NAME                 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @row_count               integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
	@ret_code		 integer

-- set local constants
SET @SP_NAME = 'XX_CERIS_PROCESS_RETRO_SP'


--new logic
DECLARE EMPL_ID_CURSOR CURSOR FAST_FORWARD FOR
--SELECT EMPL_ID, MIN(EFFECT_DT), MAX(END_DT)  --  KM - 2012-10-17
SELECT EMPL_ID, DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(MIN(EFFECT_DT))-5,  DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(MAX(END_DT))
FROM XX_CERIS_RETRO_TS ceris
WHERE EFFECT_DT < END_DT
--CR4885
--adding this to reduce looping through unnecessarily
--only loop when there are actually timesheets to loop for
AND 
(
0<>(select count(1) 
	from imaps.deltek.ts_hdr_hs 
	where empl_id=ceris.empl_id 
	and isnull(corecting_ref_dt,ts_dt) >= ceris.effect_dt 
	and isnull(corecting_ref_dt,ts_dt) <= ceris.end_dt)
or
0<>(select count(1) 
	from imaps.deltek.ts_hdr 
	where empl_id=ceris.empl_id 
	and isnull(correcting_ref_dt,ts_dt) >= ceris.effect_dt 
	and isnull(correcting_ref_dt,ts_dt) <= ceris.end_dt)
)
GROUP BY EMPL_ID ORDER BY EMPL_ID


DECLARE @EMPL_ID varchar(12),
		@START_DT smalldatetime,
		@END_DT smalldatetime

OPEN EMPL_ID_CURSOR
FETCH NEXT FROM EMPL_ID_CURSOR INTO @EMPL_ID,@START_DT,@END_DT

WHILE @@FETCH_STATUS = 0
BEGIN

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 108 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
	EXEC @ret_code = dbo.XX_CERIS_LOAD_RETRO_TS_PREP_SP
			 @in_STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM,
			 @in_EMPL_ID = @EMPL_ID,
			 @in_START_DT = @START_DT,
			 @in_END_DT = @END_DT

	IF @ret_code <> 0 GOTO BL_ERROR_HANDLER

FETCH NEXT FROM EMPL_ID_CURSOR INTO @EMPL_ID,@START_DT,@END_DT
END
CLOSE EMPL_ID_CURSOR
DEALLOCATE EMPL_ID_CURSOR


--update notes
UPDATE XX_CERIS_RETRO_TS_PREP
SET NOTES = replace(NOTES,'-n','-ORG_ID-n')
FROM XX_CERIS_RETRO_TS_PREP TS
WHERE 
0 <
(SELECT COUNT(1) 
 FROM XX_CERIS_RETRO_TS
 WHERE EMPL_ID=TS.EMPL_ID
 AND NEW_ORG_ID IS NOT NULL
  --  KM - 2012-10-18   AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN EFFECT_DT AND END_DT)
 AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(EFFECT_DT)-5 AND  DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(END_DT))


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 139 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
UPDATE XX_CERIS_RETRO_TS_PREP
SET NOTES = replace(NOTES,'-p','-ORG_ID-p')
FROM XX_CERIS_RETRO_TS_PREP TS
WHERE 
0 <
(SELECT COUNT(1) 
 FROM XX_CERIS_RETRO_TS
 WHERE EMPL_ID=TS.EMPL_ID
 AND NEW_ORG_ID IS NOT NULL
  --  KM - 2012-10-18   AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN EFFECT_DT AND END_DT)
 AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(EFFECT_DT)-5 AND  DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(END_DT))


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 155 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
UPDATE XX_CERIS_RETRO_TS_PREP
SET NOTES = replace(NOTES,'-n','-SAL_or_HRS-n')
FROM XX_CERIS_RETRO_TS_PREP TS
WHERE 
0 <
(SELECT COUNT(1) 
 FROM XX_CERIS_RETRO_TS
 WHERE EMPL_ID=TS.EMPL_ID
 AND NEW_HRLY_AMT IS NOT NULL
  --  KM - 2012-10-18   AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN EFFECT_DT AND END_DT)
 AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(EFFECT_DT)-5 AND  DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(END_DT))


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 171 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
UPDATE XX_CERIS_RETRO_TS_PREP
SET NOTES = replace(NOTES,'-p','-SAL_or_HRS-p')
FROM XX_CERIS_RETRO_TS_PREP TS
WHERE 
0 <
(SELECT COUNT(1) 
 FROM XX_CERIS_RETRO_TS
 WHERE EMPL_ID=TS.EMPL_ID
 AND NEW_HRLY_AMT IS NOT NULL
  --  KM - 2012-10-18   AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN EFFECT_DT AND END_DT)
 AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(EFFECT_DT)-5 AND  DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(END_DT))



 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 188 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
UPDATE XX_CERIS_RETRO_TS_PREP
SET NOTES = replace(NOTES,'-n','-EXMPT-n')
FROM XX_CERIS_RETRO_TS_PREP TS
WHERE 
0 <
(SELECT COUNT(1) 
 FROM XX_CERIS_RETRO_TS
 WHERE EMPL_ID=TS.EMPL_ID
 AND NEW_EXMPT_FL IS NOT NULL
  --  KM - 2012-10-18   AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN EFFECT_DT AND END_DT)
 AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(EFFECT_DT)-5 AND  DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(END_DT))



 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 205 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
UPDATE XX_CERIS_RETRO_TS_PREP
SET NOTES = replace(NOTES,'-p','-EXMPT-p')
FROM XX_CERIS_RETRO_TS_PREP TS
WHERE 
0 <
(SELECT COUNT(1) 
 FROM XX_CERIS_RETRO_TS
 WHERE EMPL_ID=TS.EMPL_ID
 AND NEW_EXMPT_FL IS NOT NULL
  --  KM - 2012-10-18   AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN EFFECT_DT AND END_DT)
 AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(EFFECT_DT)-5 AND  DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(END_DT))



--DELETE WHERE NO CHANGE
DELETE XX_CERIS_RETRO_TS_PREP
FROM XX_CERIS_RETRO_TS_PREP TS
WHERE
0 = 
(SELECT COUNT(1) 
 FROM XX_CERIS_RETRO_TS
 WHERE EMPL_ID=TS.EMPL_ID
  --  KM - 2012-10-18   AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN EFFECT_DT AND END_DT)
 AND DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(TS.CORRECTING_REF_DT) BETWEEN DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(EFFECT_DT)-5 AND  DBO.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(END_DT))




/*
OLD LOGIC

-- in case of both a dept and glc change with different dates
-- we must merge and overlap these changes in temporal order
DECLARE @EMPL_ID varchar(12),
	@NEW_ORG_ID varchar(20),
	@NEW_GLC varchar(6),
	@EFFECT_DT smalldatetime,
	@END_DT smalldatetime


DECLARE EMPL_ID_CURSOR CURSOR FAST_FORWARD FOR
SELECT DISTINCT EMPL_ID FROM dbo.XX_CERIS_RETRO_TS

OPEN EMPL_ID_CURSOR
FETCH NEXT FROM EMPL_ID_CURSOR INTO @EMPL_ID

WHILE @@FETCH_STATUS = 0
   BEGIN
	
	--SHOULD ONLY HAVE AT MOST TWO RECORDS - GLC AND ORG CHANGE

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 259 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
	SELECT @row_count = count(1) --DISTINCT EFFECT_DT
	FROM dbo.XX_CERIS_RETRO_TS 
	WHERE EMPL_ID = @EMPL_ID	

	
	-- if only one record for current empl_id, process it once
	IF(@row_count = 1)
	BEGIN
		SELECT 	@NEW_ORG_ID = NEW_ORG_ID,
			@NEW_GLC = NEW_GLC, 
			@EFFECT_DT = EFFECT_DT,
			@END_DT = END_DT
		FROM dbo.XX_CERIS_RETRO_TS
		WHERE EMPL_ID = @EMPL_ID

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 277 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
		EXEC @ret_code = dbo.XX_CERIS_PROCESS_RETRO_GLC_AND_ORG_SP
			@in_STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM,
			@in_EMPL_ID = @EMPL_ID,
			@in_NEW_GLC = @NEW_GLC,
			@in_NEW_ORG_ID = @NEW_ORG_ID,
			@in_EFFECT_DT = @EFFECT_DT,
			@in_END_DT = @END_DT,
			@out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION,
			@out_SQLServer_error_code = @out_SQLServer_error_code
		
		IF @ret_code <> 0 GOTO BL_ERROR_HANDLER
		
	END -- end if rowcount = 1

	-- if both and org and glc change
	-- we must merge the changes
	ELSE IF(@row_count = 2)
	BEGIN
		--IF TWO RECORDS, MERGE THEM IN TABLE
		UPDATE 	XX_CERIS_RETRO_TS 
		SET 	NEW_GLC = (SELECT NEW_GLC FROM XX_CERIS_RETRO_TS WHERE EMPL_ID = @EMPL_ID AND EFFECT_DT <= trs.EFFECT_DT AND NEW_GLC IS NOT NULL)
		FROM 	XX_CERIS_RETRO_TS trs
		WHERE 	EMPL_ID = @EMPL_ID
		AND 	NEW_GLC IS NULL
	
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 305 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
		UPDATE 	XX_CERIS_RETRO_TS 
		SET 	NEW_ORG_ID = (SELECT NEW_ORG_ID FROM XX_CERIS_RETRO_TS WHERE EMPL_ID = @EMPL_ID AND EFFECT_DT <= trs.EFFECT_DT AND NEW_ORG_ID IS NOT NULL)
		FROM 	XX_CERIS_RETRO_TS trs
		WHERE 	EMPL_ID = @EMPL_ID
		AND 	NEW_ORG_ID IS NULL		

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 314 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
		UPDATE 	XX_CERIS_RETRO_TS
		SET 	END_DT = (SELECT MAX(EFFECT_DT) FROM XX_CERIS_RETRO_TS WHERE EMPL_ID = @EMPL_ID)
		FROM 	XX_CERIS_RETRO_TS trs
		WHERE 	EMPL_ID = @EMPL_ID
		AND	EFFECT_DT <> (SELECT MAX(EFFECT_DT) FROM XX_CERIS_RETRO_TS WHERE EMPL_ID = @EMPL_ID)
		
	
		--FIRST CHANGE
		SELECT 	TOP 1
			@NEW_ORG_ID = NEW_ORG_ID,
			@NEW_GLC = NEW_GLC, 
			@EFFECT_DT = EFFECT_DT,
			@END_DT = END_DT
		FROM dbo.XX_CERIS_RETRO_TS
		WHERE EMPL_ID = @EMPL_ID
		ORDER BY EFFECT_DT

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 334 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
		EXEC @ret_code = dbo.XX_CERIS_PROCESS_RETRO_GLC_AND_ORG_SP
			@in_STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM,
			@in_EMPL_ID = @EMPL_ID,
			@in_NEW_GLC = @NEW_GLC,
			@in_NEW_ORG_ID = @NEW_ORG_ID,
			@in_EFFECT_DT = @EFFECT_DT,
			@in_END_DT = @END_DT,
			@out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION,
			@out_SQLServer_error_code = @out_SQLServer_error_code
		
		IF @ret_code <> 0 GOTO BL_ERROR_HANDLER	

		--IN CASE SOMEHOW THE MERGE CREATED DUPLICATE RECORDS
		SELECT DISTINCT NEW_ORG_ID,
				NEW_GLC, 
				EFFECT_DT,
				END_DT
		FROM dbo.XX_CERIS_RETRO_TS
		WHERE EMPL_ID = @EMPL_ID
		
		SET @row_count =@@ROWCOUNT
		IF @row_count = 1 GOTO SKIP_SECOND_CHANGE
		
		--SECOND CHANGE
		SELECT 	@NEW_ORG_ID = NEW_ORG_ID,
			@NEW_GLC = NEW_GLC, 
			@EFFECT_DT = EFFECT_DT,
			@END_DT = END_DT
		FROM dbo.XX_CERIS_RETRO_TS
		WHERE EMPL_ID = @EMPL_ID
		AND	EFFECT_DT > @EFFECT_DT

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 369 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
		EXEC @ret_code = dbo.XX_CERIS_PROCESS_RETRO_GLC_AND_ORG_SP
			@in_STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM,
			@in_EMPL_ID = @EMPL_ID,
			@in_NEW_GLC = @NEW_GLC,
			@in_NEW_ORG_ID = @NEW_ORG_ID,
			@in_EFFECT_DT = @EFFECT_DT,
			@in_END_DT = @END_DT,
			@out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION,
			@out_SQLServer_error_code = @out_SQLServer_error_code
		
		IF @ret_code <> 0 GOTO BL_ERROR_HANDLER	
		
		SKIP_SECOND_CHANGE:

	END -- end row count = 2

	-- if more than 2 records for 1 empl_id, there is an error
	ELSE
	BEGIN
		SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
		SET @error_msg_placeholder1 = 'insert MORE THAN 2'
		SET @error_msg_placeholder2 = 'records into table XX_CERIS_RETRO_TS_PREP'
		SET @SQLServer_error_code = @@ERROR
		GOTO BL_ERROR_HANDLER
	END

	
	/*--BECAUSE OF CHANGE TO CORRECTING TIMESHEETS, WE MUST USE THE TS_HDR_SEQ_NO
	--SO THAT PREPROCESSOR DOES NOT GIVE INCONSISTENT HEADER DATA ERROR
	--ON CORRECTING TIMESHEETS REFERENCE DATE
	
	--S_TS_HDR_SEQ_NO MUST BE UNIQUE FOR THIS COMBINATION:
	--TS_DT (all the same), TS_TYPE (all the same), EMPL_ID, CORRECTING_REF_DT
	
	--TO ISOLATE CROSS-CHARGING, WE MUST ALSO GROUP BY PROJ_ABBRV_CD
	CREATE TABLE #XX_CERIS_TS_HDR_SEQ_NO (
		[IDENTITY_TS_HDR_SEQ_NO] [int] IDENTITY (1, 1) NOT NULL ,
		[EMPL_ID] [char] (12) NOT NULL,
		[CORRECTING_REF_DT] [char] (10) NULL,
		[PROJ_ABBRV_CD] [char] (6) NULL,
	)
	
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 414 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
	INSERT INTO #XX_CERIS_TS_HDR_SEQ_NO
	(EMPL_ID, CORRECTING_REF_DT, PROJ_ABBRV_CD)
	SELECT EMPL_ID, CORRECTING_REF_DT, PROJ_ABBRV_CD
	FROM dbo.XX_CERIS_RETRO_TS_PREP
	WHERE EMPL_ID = @EMPL_ID
	GROUP BY EMPL_ID, CORRECTING_REF_DT, PROJ_ABBRV_CD
	
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 424 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
	UPDATE dbo.XX_CERIS_RETRO_TS_PREP
	SET TS_HDR_SEQ_NO = CAST(tmp.IDENTITY_TS_HDR_SEQ_NO as char(2))
	FROM  dbo.XX_CERIS_RETRO_TS_PREP ceris
	INNER JOIN
		#XX_CERIS_TS_HDR_SEQ_NO tmp
	ON
	(ceris.EMPL_ID = tmp.EMPL_ID
	and ceris.CORRECTING_REF_DT = tmp.CORRECTING_REF_DT
	and ceris.PROJ_ABBRV_CD = tmp.PROJ_ABBRV_CD)
	
	DROP TABLE #XX_CERIS_TS_HDR_SEQ_NO
	
	IF @@ERROR <> 0
	BEGIN
		SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
		SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE TS_HDR_SEQ_NO IN'
		SET @ERROR_MSG_PLACEHOLDER2 = 'XX_CERIS_RETRO_TS_PREP'
		SET @SQLSERVER_ERROR_CODE = @@ERROR
		GOTO BL_ERROR_HANDLER
	END

	SET @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER
	*/

       	FETCH NEXT FROM EMPL_ID_CURSOR INTO @EMPL_ID

   END /* WHILE @@FETCH_STATUS = 0 */

-- clean up empl_id_sursor
CLOSE EMPL_ID_CURSOR
DEALLOCATE EMPL_ID_CURSOR
*/



--CR4885 - IMAPS CERIS Interface Changes for Actuals - KM - 2012-10-02 - call simulate costpoint sp
--this procedure has been modified for Actuals
--BEGIN DR-922 4/17/07
EXEC @ret_code = XX_CERIS_SIMULATE_COSTPOINT_SP
IF @ret_code <> 0 GOTO BL_ERROR_HANDLER



--update KM CR4885
--design document open question #6

DECLARE @Actuals_EFFECT_DT smalldatetime

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 476 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
select @Actuals_EFFECT_DT = cast(parameter_value as smalldatetime)
from xx_processing_parameters
where interface_name_cd='CERIS'
and parameter_name='Actuals_EFFECT_DT'


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 485 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
INSERT INTO XX_CERIS_RETRO_TS_PREP_PRIOR_YEAR_ARCH
SELECT * FROM XX_CERIS_RETRO_TS_PREP
WHERE cast(EFFECT_BILL_DT as smalldatetime) < @Actuals_EFFECT_DT --LEFT(EFFECT_BILL_DT, 4) < DATEPART(YEAR, GETDATE())

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

DELETE FROM XX_CERIS_RETRO_TS_PREP
WHERE cast(EFFECT_BILL_DT as smalldatetime) < @Actuals_EFFECT_DT --LEFT(EFFECT_BILL_DT, 4) < DATEPART(YEAR, GETDATE())

SET @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER
--END DR-922 4/17/07



--BEGIN TS_HDR_SEQ_NO CHANGE


--IDENTIFY CROSS-CHARGING
/*
OLD LOGIC
UPDATE XX_CERIS_RETRO_TS_PREP
SET S_TS_LN_TYPE_CD = 'X'
WHERE TS_DT+EMPL_ID+S_TS_TYPE_CD+CORRECTING_REF_DT+PROJ_ABBRV_CD
IN
(SELECT TS_DT+EMPL_ID+S_TS_TYPE_CD+CORRECTING_REF_DT+PROJ_ABBRV_CD
 FROM XX_CERIS_RETRO_TS_PREP
 WHERE ACCT_ID IS NULL)
*/


DECLARE EMPL_ID_TS_HDR_CURSOR CURSOR FAST_FORWARD FOR
SELECT DISTINCT EMPL_ID FROM DBO.XX_CERIS_RETRO_TS_PREP

OPEN EMPL_ID_TS_HDR_CURSOR
FETCH NEXT FROM EMPL_ID_TS_HDR_CURSOR INTO @EMPL_ID

WHILE @@FETCH_STATUS = 0
   BEGIN
	

	--BECAUSE OF CHANGE TO CORRECTING TIMESHEETS, WE MUST USE THE TS_HDR_SEQ_NO
	--SO THAT PREPROCESSOR DOES NOT GIVE INCONSISTENT HEADER DATA ERROR
	--ON CORRECTING TIMESHEETS REFERENCE DATE
	
	--S_TS_HDR_SEQ_NO MUST BE UNIQUE FOR THIS COMBINATION:
	--TS_DT (ALL THE SAME), TS_TYPE (ALL THE SAME), EMPL_ID, CORRECTING_REF_DT
	
	--TO ISOLATE CROSS-CHARGING, WE MUST ALSO GROUP BY CROSS-CHARGING
	CREATE TABLE #XX_CERIS_TS_HDR_SEQ_NO (
		[IDENTITY_TS_HDR_SEQ_NO] [INT] IDENTITY (1, 1) NOT NULL ,
		[EMPL_ID] [CHAR] (12) NOT NULL,
		[CORRECTING_REF_DT] [CHAR] (10) NULL,
		[S_TS_LN_TYPE_CD] [CHAR] (1) NULL,
	)
	
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 545 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
	INSERT INTO #XX_CERIS_TS_HDR_SEQ_NO
	(EMPL_ID, CORRECTING_REF_DT, S_TS_LN_TYPE_CD)
	SELECT 	EMPL_ID, CORRECTING_REF_DT, S_TS_LN_TYPE_CD
	FROM 	DBO.XX_CERIS_RETRO_TS_PREP
	WHERE 	EMPL_ID = @EMPL_ID
	GROUP BY EMPL_ID, CORRECTING_REF_DT, S_TS_LN_TYPE_CD
	
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 555 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
	UPDATE DBO.XX_CERIS_RETRO_TS_PREP
	SET TS_HDR_SEQ_NO = CAST(TMP.IDENTITY_TS_HDR_SEQ_NO AS CHAR(2))
	FROM  DBO.XX_CERIS_RETRO_TS_PREP CERIS
	INNER JOIN
		#XX_CERIS_TS_HDR_SEQ_NO TMP
	ON
	(CERIS.EMPL_ID = TMP.EMPL_ID
	AND CERIS.CORRECTING_REF_DT = TMP.CORRECTING_REF_DT
	AND ISNULL(CERIS.S_TS_LN_TYPE_CD, '') = ISNULL(TMP.S_TS_LN_TYPE_CD, '')
	)
	
	DROP TABLE #XX_CERIS_TS_HDR_SEQ_NO
	
	IF @@ERROR <> 0
	BEGIN
		PRINT 'UPDATE ERROR'
		GOTO BL_ERROR_HANDLER
	END

       	FETCH NEXT FROM EMPL_ID_TS_HDR_CURSOR INTO @EMPL_ID

   END /* WHILE @@FETCH_STATUS = 0 */


CLOSE EMPL_ID_TS_HDR_CURSOR
DEALLOCATE EMPL_ID_TS_HDR_CURSOR


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 586 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
UPDATE XX_CERIS_RETRO_TS_PREP
SET S_TS_LN_TYPE_CD = NULL
--END TS_HDR_SEQ_NO CHANGE

--BEGIN RECLASS SECTION
    --Added CR-4885 Tejas 08/21/12
    --This section will create reclass and BO lines for D lines for Exempt Retros only
    --Commented until we figure out how to handle reclass on retros 09/25/2012

    -- EXEC @ret_code = dbo.XX_CERIS_PROCESS_RETRO_RECLASS_SP

     IF @ret_code <> 0
             BEGIN
                -- Attempt to insert a XX_CERIS_RETRO_TS_PREP record failed.
                EXEC dbo.XX_ERROR_MSG_DETAIL
                   @in_error_code           = 204,
                   @in_display_requested    = 1,
                   @in_SQLServer_error_code = @ret_code,
                   @in_placeholder_value1   = 'insert',
                   @in_placeholder_value2   = 'XX_CERIS_RETRO_TS_PREP Reclass process',
                   @in_calling_object_name  = @SP_NAME,
                   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
                RETURN(1)
             END

--END RECLASS SECTION

--Begin TS_HDR_SEQ_NO Logic
--Added CR-4885 Tejas Patel
--09/10/2012
    /*update TS_HDR_SEQ_NO in order to separate by CORRECTING_REF_DT*/
    --Begin CR-2350 5/03/10
    EXEC @RET_CODE = dbo.XX_CERIS_SIMULATE_TSHDRSEQ_SP
 	IF @RET_CODE <> 0
         BEGIN
            -- Attempt to insert a XX_IMAPS_TS_PREP_TEMP record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
               @in_SQLServer_error_code = @RET_CODE,
               @in_placeholder_value1   = 'Update',
               @in_placeholder_value2   = 'XX_CERIS_RETRO_TS_PREP TSHDRSEQ',
               @in_calling_object_name  = @SP_NAME,
               @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT
            RETURN(1)
         END

   

--DR6720 begin
declare @prob_count int,
		@max_seq int
set @prob_count=0

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 643 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
select @prob_count=count(1),
	   @max_seq = max(cast(ts_hdr_seq_no as int))
from xx_ceris_retro_ts_prep
where cast(ts_hdr_seq_no as int)>99

WHILE (@prob_count>0)
BEGIN
	
	-- IF TS_HDR_SEQ_NO>99 then we will increase TS_DT by one and restart seq no from 4
	update XX_CERIS_RETRO_TS_PREP  --was mistakenly put as XX_R22 originally
	set ts_dt = convert( char(10), cast(ts_dt as datetime)+1, 120),
	ts_hdr_seq_no = cast( (cast(ts_hdr_seq_no as int) - 96) as varchar ) 
	where 
	S_TS_TYPE_CD in ('C','D','N')
	and cast(ts_hdr_seq_no as int) > 99

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 662 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
	select	@prob_count=count(1),
			@max_seq = max(cast(ts_hdr_seq_no as int))
	from xx_ceris_retro_ts_prep
	where cast(ts_hdr_seq_no as int)>99

END
--DR6720 end



--CR4885 - IMAPS CERIS Interface Changes for Actuals - KM - 2012-10-10 - call OT reclass sp
PRINT 'XX_CERIS_INSERT_TS_RECLASS_SP call'
EXEC @ret_code = XX_CERIS_INSERT_TS_RECLASS_SP
IF @ret_code <> 0 GOTO BL_ERROR_HANDLER


--BEGIN DR5811 - CERIS retro timesheet miscodes: inconsistent work state code - KM - 2013-01-15
	SET @ERROR_MSG_PLACEHOLDER1 = 'DR5811 UPDATE WORK STATE CODE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR CONSISTENCY ON RETROS'

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 685 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
	update xx_ceris_retro_ts_prep
	set work_state_cd=eli.work_state_cd
	from 
	xx_ceris_retro_ts_prep ts
	inner join
	imaps.deltek.empl_lab_info eli
	on
	(
	ts.empl_id=eli.empl_id
	and
	cast(isnull(ts.correcting_ref_dt,ts.ts_dt) as datetime) between eli.effect_dt and eli.end_dt
	)

	SET @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER
--END   DR5811


DECLARE @NET_HRS DECIMAL(14,2)

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 708 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
SELECT 	@NET_HRS = SUM(CAST(CHG_HRS AS DECIMAL(14,2)))
FROM	DBO.XX_CERIS_RETRO_TS_PREP

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 714 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
SELECT @NET_HRS

IF 	@NET_HRS IS NOT NULL AND 
	@NET_HRS <> .00
BEGIN
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VALIDATE THAT NET HOURS IN'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_CERIS_RETRO_TS_PREP  = .00'
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

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 741 : XX_CERIS_PROCESS_RETRO_SP.sql '
 
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
IF OBJECT_ID('dbo.XX_CERIS_PROCESS_RETRO_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_CERIS_PROCESS_RETRO_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_CERIS_PROCESS_RETRO_SP >>>'
go

USE [IMAPSStg]
GO

IF OBJECT_ID('XX_CERIS_PROCESS_RETRO_DEBIT_CREDIT_SP') IS NOT NULL
begin
    DROP PROCEDURE [dbo].[XX_CERIS_PROCESS_RETRO_DEBIT_CREDIT_SP]
end
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_PROCESS_RETRO_DEBIT_CREDIT_SP]    Script Date: 02/10/2013 12:05:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[XX_CERIS_PROCESS_RETRO_DEBIT_CREDIT_SP]
(
@in_STATUS_RECORD_NUM     integer,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS

/************************************************************************************************  
Name:       	XX_CERIS_PROCESS_RETRO_DEBIT_CREDIT_SP
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

CR5968 - we need to leverage CERIS retro timesheet process to create debits/credits
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
SET @SP_NAME = 'XX_CERIS_PROCESS_RETRO_DEBIT_CREDIT_SP'


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

	EXEC @ret_code = dbo.XX_CERIS_LOAD_RETRO_TS_PREP_DEBIT_CREDIT_SP
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
NOTE: WE DO NOT WANT TO CALL THIS, BECAUSE THESE ARE DEBITS/CREDITS
NOT TRUE RETROS

--CR4885 - IMAPS CERIS Interface Changes for Actuals - KM - 2012-10-02 - call simulate costpoint sp
--this procedure has been modified for Actuals
--BEGIN DR-922 4/17/07
EXEC @ret_code = XX_CERIS_SIMULATE_COSTPOINT_SP
IF @ret_code <> 0 GOTO BL_ERROR_HANDLER
*/


--update KM CR4885
--design document open question #6

DECLARE @Actuals_EFFECT_DT smalldatetime

select @Actuals_EFFECT_DT = cast(parameter_value as smalldatetime)
from xx_processing_parameters
where interface_name_cd='CERIS'
and parameter_name='Actuals_EFFECT_DT'


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



DECLARE EMPL_ID_TS_HDR_CURSOR CURSOR FAST_FORWARD FOR
SELECT DISTINCT EMPL_ID FROM DBO.XX_CERIS_RETRO_TS_PREP

OPEN EMPL_ID_TS_HDR_CURSOR
FETCH NEXT FROM EMPL_ID_TS_HDR_CURSOR INTO @EMPL_ID

WHILE @@FETCH_STATUS = 0
   BEGIN
	

	CREATE TABLE #XX_CERIS_TS_HDR_SEQ_NO (
		[IDENTITY_TS_HDR_SEQ_NO] [INT] IDENTITY (1, 1) NOT NULL ,
		[EMPL_ID] [CHAR] (12) NOT NULL,
		[CORRECTING_REF_DT] [CHAR] (10) NULL,
		[S_TS_TYPE_CD] [CHAR] (1) NULL,
	)
	
	INSERT INTO #XX_CERIS_TS_HDR_SEQ_NO
	(EMPL_ID, CORRECTING_REF_DT, S_TS_TYPE_CD)
	SELECT 	EMPL_ID, CORRECTING_REF_DT, S_TS_TYPE_CD
	FROM 	DBO.XX_CERIS_RETRO_TS_PREP
	WHERE 	EMPL_ID = @EMPL_ID
	GROUP BY EMPL_ID, CORRECTING_REF_DT, S_TS_TYPE_CD
	
	UPDATE DBO.XX_CERIS_RETRO_TS_PREP
	SET TS_HDR_SEQ_NO = CAST(TMP.IDENTITY_TS_HDR_SEQ_NO+1 AS CHAR(2))
	FROM  DBO.XX_CERIS_RETRO_TS_PREP CERIS
	INNER JOIN
		#XX_CERIS_TS_HDR_SEQ_NO TMP
	ON
	(CERIS.EMPL_ID = TMP.EMPL_ID
	AND CERIS.CORRECTING_REF_DT = TMP.CORRECTING_REF_DT
	AND CERIS.S_TS_TYPE_CD = TMP.S_TS_TYPE_CD
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







--CR4885 - IMAPS CERIS Interface Changes for Actuals - KM - 2012-10-10 - call OT reclass sp
PRINT 'XX_CERIS_INSERT_TS_RECLASS_SP call'
EXEC @ret_code = XX_CERIS_INSERT_TS_RECLASS_SP
IF @ret_code <> 0 GOTO BL_ERROR_HANDLER


--BEGIN DR5811 - CERIS retro timesheet miscodes: inconsistent work state code - KM - 2013-01-15
	SET @ERROR_MSG_PLACEHOLDER1 = 'DR5811 UPDATE WORK STATE CODE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR CONSISTENCY ON RETROS'

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

SELECT 	@NET_HRS = SUM(CAST(CHG_HRS AS DECIMAL(14,2)))
FROM	DBO.XX_CERIS_RETRO_TS_PREP

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



















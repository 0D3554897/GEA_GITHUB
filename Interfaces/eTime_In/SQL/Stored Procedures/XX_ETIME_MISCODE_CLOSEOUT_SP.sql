IF OBJECT_ID('dbo.XX_ETIME_MISCODE_CLOSEOUT_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_ETIME_MISCODE_CLOSEOUT_SP
    IF OBJECT_ID('dbo.XX_ETIME_MISCODE_CLOSEOUT_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_ETIME_MISCODE_CLOSEOUT_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_ETIME_MISCODE_CLOSEOUT_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER ON
go






CREATE PROCEDURE [dbo].[XX_ETIME_MISCODE_CLOSEOUT_SP] 
AS
--Modified for CR-1414
--Modified: 04/14/2009 DR-1631 For Miscode Feedback
--Modified: 10/15/2012 CR-4886 for partial miscode logic
--Modified: 10/31/2012 CR-4886 for partial miscode logic-2

BEGIN


	--0.  MARK RECORDS THAT WERE SUCCESSFULLY IMPORTED
	DECLARE @NEW_STATUS_RECORD_NUM int
	SELECT @NEW_STATUS_RECORD_NUM  = 
		 CAST(DATEPART(year, GETDATE()) as varchar) 
		+ RIGHT('0' + CAST(DATEPART(month, GETDATE()) as varchar), 2)
		+ RIGHT('0' + CAST(DATEPART(day, GETDATE()) as varchar), 2)
	
	
	UPDATE dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS
	SET STATUS_RECORD_NUM_REPROCESSED = @NEW_STATUS_RECORD_NUM,
		  /*DR1631*/ UPDATE_DT = current_timestamp
	WHERE 
	STATUS_RECORD_NUM_REPROCESSED IS NULL
	AND
	NOTES IN
	(SELECT NOTES FROM IMAPS.DELTEK.TS_LN)

	-- BEGIN CR-4890 Change

    -- Mark records not processed if they have partial TC processed
    update dbo.XX_IMAPS_TS_PREP_config_errors
    set status_record_num_reprocessed=NULL
    --WHERE NOTES not in (SELECT NOTES FROM IMAPS.DELTEK.TS_LN)
    FROM dbo.XX_IMAPS_TS_PREP_config_errors ts
    where (empl_id+convert(char(10), dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts_dt),120)) in 
        (
        select distinct empl_id+convert(char(10), dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts_dt),120) 
        FROM dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS
        where notes not in (select notes from IMAPS.DELTEK.ts_ln where empl_id=ts.empl_id) --Modified 10/31/2012
        and status_record_num_reprocessed is null
		and empl_id=ts.empl_id
        )
    and s_ts_type_cd='R'
    
    --Modified CR-4886 10/31/2012
    and isnull(status_record_num_reprocessed,'') not like '8%' --Added CR-2414 5/4/2010
    
    -- Added DR-2809 09/24/2010 TP
    -- Mark records not processed if they have partial TC processed
    update dbo.XX_IMAPS_TS_PREP_config_errors
    set status_record_num_reprocessed=NULL
    --WHERE NOTES not in (SELECT NOTES FROM IMAPS.DELTEK.TS_LN)
    --select *
    FROM dbo.XX_IMAPS_TS_PREP_config_errors ts
    where (empl_id+convert(char(10), dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt),120)) in 
            (
            select distinct empl_id+convert(char(10), dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt),120) --correcting_ref_dt
            FROM dbo.XX_IMAPS_TS_PREP_CONFIG_ERRORS
            where notes not in (select notes from IMAPS.DELTEK.ts_ln where empl_id=ts.empl_id) --Modified 10/31/2012
            and (isnull(status_record_num_reprocessed,'') not like '8%')
            and notes in (select notes from XX_imaps_ts_prep_temp where empl_id=ts.empl_id) -- Only records to compare if they are in prep temp
            )
    and s_ts_type_cd in ('N','D')
    and isnull(status_record_num_reprocessed,'') not like '8%' --Added CR-2414 5/4/2010


    --Delete Partially processed Timecards from TS_LN Tables
    delete from IMAPS.DELTEK.ts_hdr
    --select hdr.*
    from IMAPS.DELTEK.ts_hdr hdr
        inner join
        IMAPS.DELTEK.ts_ln ln
        on
        (hdr.empl_id = ln.empl_id
        and hdr.ts_dt = ln.ts_dt
        and hdr.s_ts_type_cd = ln.s_ts_type_cd
        and hdr.ts_hdr_seq_no = ln.ts_hdr_seq_no)
	    and post_seq_no is null
    where ln.notes in (select notes 
                        from XX_imaps_ts_prep_config_errors
                        where empl_id=hdr.empl_id
                        and status_record_num_reprocessed is null)

    --END CR-4886 changes


	

	--Added for CR-1414
    --This will update TS_LN_KEY to UTIL data
    UPDATE dbo.XX_IMAPS_TS_UTIL_DATA
    SET CP_TS_LN_KEY = TS.TS_LN_KEY,
        CP_PROCESS_DATE = convert(char, TS.TIME_STAMP, 101) 
    FROM dbo.XX_IMAPS_TS_UTIL_DATA UTIL, IMAPS.DELTEK.TS_LN_HS TS
    WHERE UTIL.CP_TS_LN_KEY IS NULL
            AND UTIL.NOTES=TS.NOTES
            AND UTIL.EMPL_ID=TS.EMPL_ID
            and util.TS_DT=ts.ts_dt
            and util.s_ts_type_cd=ts.s_ts_type_cd
    
	IF @@ERROR <>0
       BEGIN
        GOTO BL_ERROR_HANDLER
       END



/*DR1631*/
/*grab Costpoint Errors*/
	DECLARE @ret_code int
	SELECT @ret_code = count(1)
	FROM IMAPS.DELTEK.X_Z_AOPUTLTS_ERROR ts
	WHERE 
	0 < (SELECT COUNT(1) 
		 FROM XX_IMAPS_TS_PREP_CONFIG_ERRORS
		 WHERE STATUS_RECORD_NUM_REPROCESSED IS NULL
		 AND X_RECORD_NO=ts.X_RECORD_NO
		 AND EMPL_ID=ts.EMPL_ID
		 AND TS_DT=convert(char(10),ts.TS_DT,120))

	--only do this if we know for sure that the Costpoint error table has new error messages for our miscodes
	IF @ret_code > 0
	BEGIN
		PRINT 'NEW ERROR MESSAGES FOUND'
		TRUNCATE TABLE XX_ETIME_MISCODE_AOPUTLTS_ERROR		
		INSERT INTO XX_ETIME_MISCODE_AOPUTLTS_ERROR
		(X_RECORD_NO,
		EMPL_ID,
		TS_DT,
		TS_HDR_SEQ_NO,
		S_TS_TYPE_CD,
		X_FIELD_NAME_S,
		X_CONTENTS_S,
		X_ERROR_MSG_S,
		MODIFIED_BY,
		TIME_STAMP,
		ERR_SUSP_WARN_NO,
		ROWVERSION)
		SELECT X_RECORD_NO,
				EMPL_ID,
				TS_DT,
				TS_HDR_SEQ_NO,
				S_TS_TYPE_CD,
				X_FIELD_NAME_S,
				X_CONTENTS_S,
				X_ERROR_MSG_S,
				MODIFIED_BY,
				TIME_STAMP,
				ERR_SUSP_WARN_NO,
				ROWVERSION
		FROM IMAPS.DELTEK.X_Z_AOPUTLTS_ERROR


		UPDATE XX_IMAPS_TS_PREP_CONFIG_ERRORS
		SET FEEDBACK='',
			UPDATE_DT=current_timestamp
		WHERE STATUS_RECORD_NUM_REPROCESSED IS NULL

		

		DECLARE @X_RECORD_NO int,
			@EMPL_ID varchar(12),
			@TS_DT char(10),
			@S_TS_TYPE_CD varchar(2),
			@X_FIELD_NAME_S varchar(20),
			@X_CONTENTS_S varchar(70),
			@X_ERROR_MSG_S varchar(150)

		DECLARE ETIME_MISCODE_FEEDBACK_CURSOR CURSOR FAST_FORWARD FOR
		SELECT X_RECORD_NO, EMPL_ID, convert(char(10),TS_DT,120) as TS_DT, S_TS_TYPE_CD, X_FIELD_NAME_S, X_CONTENTS_S, X_ERROR_MSG_S 
		FROM XX_ETIME_MISCODE_AOPUTLTS_ERROR
		ORDER BY ERR_SUSP_WARN_NO

		OPEN ETIME_MISCODE_FEEDBACK_CURSOR
		FETCH NEXT FROM ETIME_MISCODE_FEEDBACK_CURSOR 
		INTO @X_RECORD_NO, @EMPL_ID, @TS_DT, @S_TS_TYPE_CD, @X_FIELD_NAME_S, @X_CONTENTS_S, @X_ERROR_MSG_S

		WHILE @@FETCH_STATUS = 0
		   BEGIN

			UPDATE XX_IMAPS_TS_PREP_CONFIG_ERRORS
			SET FEEDBACK=FEEDBACK+','+ISNULL(@X_FIELD_NAME_S, '')+' '+ISNULL(@X_CONTENTS_S,'')+' '+ISNULL(@X_ERROR_MSG_S,''),
				UPDATE_DT=current_timestamp
			WHERE 
			STATUS_RECORD_NUM_REPROCESSED IS NULL
			AND EMPL_ID=@EMPL_ID
			AND	TS_DT=@TS_DT
			AND S_TS_TYPE_CD=@S_TS_TYPE_CD
			AND X_RECORD_NO=@X_RECORD_NO
						
			FETCH NEXT FROM ETIME_MISCODE_FEEDBACK_CURSOR 
			INTO @X_RECORD_NO, @EMPL_ID, @TS_DT, @S_TS_TYPE_CD, @X_FIELD_NAME_S, @X_CONTENTS_S, @X_ERROR_MSG_S

		   END /* WHILE @@FETCH_STATUS = 0 */

		-- clean up cursor
		CLOSE ETIME_MISCODE_FEEDBACK_CURSOR
		DEALLOCATE ETIME_MISCODE_FEEDBACK_CURSOR		
		
 
	END



	UPDATE XX_ERROR_STATUS
	SET 
	STATUS = 'REPROCESSED',
	CONTROL_PT = 7,
	TIME_STAMP = current_timestamp,
	SUCCESS_COUNT = 
	(select isnull(count(1),0) from XX_IMAPS_TS_PREP_CONFIG_ERRORS 
	 where 	STATUS_RECORD_NUM_CREATED = err_status.status_record_num
	 and	UPDATE_DT >= err_status.time_stamp
	 and	STATUS_RECORD_NUM_REPROCESSED is not null),
	SUCCESS_AMOUNT = 
	(select isnull(sum(cast(chg_hrs as decimal(14,2))), .00) from XX_IMAPS_TS_PREP_CONFIG_ERRORS 
	 where 	STATUS_RECORD_NUM_CREATED = err_status.status_record_num
	 and	UPDATE_DT >= err_status.time_stamp
	 and	STATUS_RECORD_NUM_REPROCESSED is not null),
	ERROR_COUNT = 
	(select isnull(count(1),0) from XX_IMAPS_TS_PREP_CONFIG_ERRORS 
	 where 	STATUS_RECORD_NUM_CREATED = err_status.status_record_num
	 and	STATUS_RECORD_NUM_REPROCESSED is null),
	ERROR_AMOUNT = 
	(select isnull(sum(cast(chg_hrs as decimal(14,2))), .00) from XX_IMAPS_TS_PREP_CONFIG_ERRORS 
	 where 	STATUS_RECORD_NUM_CREATED = err_status.status_record_num
	 and	STATUS_RECORD_NUM_REPROCESSED is null)
	FROM 	XX_ERROR_STATUS err_status
	WHERE	CONTROL_PT = 3
	AND		INTERFACE='ETIME'




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
IF OBJECT_ID('dbo.XX_ETIME_MISCODE_CLOSEOUT_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_ETIME_MISCODE_CLOSEOUT_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_ETIME_MISCODE_CLOSEOUT_SP >>>'
go

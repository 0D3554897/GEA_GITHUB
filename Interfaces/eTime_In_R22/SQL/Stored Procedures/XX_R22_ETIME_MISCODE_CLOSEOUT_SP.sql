IF OBJECT_ID('dbo.XX_R22_ETIME_MISCODE_CLOSEOUT_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_ETIME_MISCODE_CLOSEOUT_SP
    IF OBJECT_ID('dbo.XX_R22_ETIME_MISCODE_CLOSEOUT_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_ETIME_MISCODE_CLOSEOUT_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_ETIME_MISCODE_CLOSEOUT_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go


CREATE PROCEDURE [dbo].[XX_R22_ETIME_MISCODE_CLOSEOUT_SP] 
AS
--Modified for CR-1414
--Modified for CR-2043 03/23/2010
--Modified for CR-2414 05/04/2010
--Modified for DR-2809 09/24/2010 Modified for partial miscode for ND issue

BEGIN
	
	--0.  MARK RECORDS THAT WERE SUCCESSFULLY IMPORTED
	DECLARE @NEW_STATUS_RECORD_NUM int
	SELECT @NEW_STATUS_RECORD_NUM  = 
		 CAST(DATEPART(year, GETDATE()) as varchar) 
		+ RIGHT('0' + CAST(DATEPART(month, GETDATE()) as varchar), 2)
		+ RIGHT('0' + CAST(DATEPART(day, GETDATE()) as varchar), 2)
	
	
	UPDATE dbo.XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
	SET STATUS_RECORD_NUM_REPROCESSED = @NEW_STATUS_RECORD_NUM  
	WHERE 
	STATUS_RECORD_NUM_REPROCESSED IS NULL
	AND
	NOTES IN
	(SELECT NOTES FROM IMAR.DELTEK.TS_LN)

    -- Added CR-2043 03/20/2010 TP
    -- Mark records not processed if they have partial TC processed
    update dbo.XX_R22_IMAPS_TS_PREP_config_errors
    set status_record_num_reprocessed=NULL
    --WHERE NOTES not in (SELECT NOTES FROM IMAR.DELTEK.TS_LN)
    --select *
    FROM dbo.XX_R22_IMAPS_TS_PREP_config_errors
    where (empl_id+convert(char(10), dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts_dt),120)) in 
        (
        select distinct empl_id+convert(char(10), dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts_dt),120) 
        FROM dbo.XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
        where notes not in (select notes from imar.deltek.ts_ln)
        and status_record_num_reprocessed is null
        )
    and s_ts_type_cd not in ('N','D')
    and status_record_num_reprocessed not like '8%' --Added CR-2414 5/4/2010


    -- Added DR-2809 09/24/2010 TP
    -- Mark records not processed if they have partial TC processed
    update dbo.XX_R22_IMAPS_TS_PREP_config_errors
    set status_record_num_reprocessed=NULL
    --WHERE NOTES not in (SELECT NOTES FROM IMAR.DELTEK.TS_LN)
    --select *
    FROM dbo.XX_R22_IMAPS_TS_PREP_config_errors
    where (empl_id+convert(char(10), dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt),120)) in 
            (
            select distinct empl_id+convert(char(10), dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt),120) --correcting_ref_dt
            FROM dbo.XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
            where notes not in (select notes from imar.deltek.ts_ln)
            and (status_record_num_reprocessed not like '8%')
            and notes in (select notes from xx_r22_imaps_ts_prep_temp) -- Only records to compare if they are in prep temp
            )
    and s_ts_type_cd in ('N','D')
    and status_record_num_reprocessed not like '8%' --Added CR-2414 5/4/2010




    --Delete Partially processed Timecards from TS_LN Tables
    delete from imar.deltek.ts_hdr
    --select hdr.*
    from imar.deltek.ts_hdr hdr
        inner join
        imar.deltek.ts_ln ln
        on
        (hdr.empl_id = ln.empl_id
        and hdr.ts_dt = ln.ts_dt
        and hdr.s_ts_type_cd = ln.s_ts_type_cd
        and hdr.ts_hdr_seq_no = ln.ts_hdr_seq_no)
	    --and post_seq_no is null
    where ln.notes in (select notes 
                        from xx_r22_imaps_ts_prep_config_errors
                        where status_record_num_reprocessed is null)

    --END CR-2043 changes



	RETURN (0)

	--Added for CR-1414
    --This will update TS_LN_KEY to UTIL data
    UPDATE dbo.XX_R22_IMAPS_TS_UTIL_DATA
    SET CP_TS_LN_KEY = TS.TS_LN_KEY,
        CP_PROCESS_DATE = convert(char, TS.TIME_STAMP, 101) 
    FROM dbo.XX_R22_IMAPS_TS_UTIL_DATA UTIL, IMAR.DELTEK.TS_LN_HS TS
    WHERE UTIL.CP_TS_LN_KEY IS NULL
            AND UTIL.NOTES=TS.NOTES
            AND UTIL.EMPL_ID=TS.EMPL_ID
            and util.TS_DT=ts.ts_dt
            and util.s_ts_type_cd=ts.s_ts_type_cd
    
	IF @@ERROR <>0
       BEGIN
        GOTO BL_ERROR_HANDLER
       END

	BL_ERROR_HANDLER:
	
	PRINT 'ERROR UPDATING TABLE'
	RETURN(1)





END












go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_R22_ETIME_MISCODE_CLOSEOUT_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_ETIME_MISCODE_CLOSEOUT_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_ETIME_MISCODE_CLOSEOUT_SP >>>'
go

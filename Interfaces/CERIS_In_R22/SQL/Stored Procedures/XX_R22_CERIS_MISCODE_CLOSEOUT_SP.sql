IF OBJECT_ID('dbo.XX_R22_CERIS_MISCODE_CLOSEOUT_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_CERIS_MISCODE_CLOSEOUT_SP
    IF OBJECT_ID('dbo.XX_R22_CERIS_MISCODE_CLOSEOUT_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_CERIS_MISCODE_CLOSEOUT_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_CERIS_MISCODE_CLOSEOUT_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go





CREATE PROCEDURE [dbo].[XX_R22_CERIS_MISCODE_CLOSEOUT_SP] 
AS

/***********************************************************************************************
Name:       XX_R22_CERIS_MISCODE_CLOSEOUT_SP
Author:     KM
Created:    11/04/2009
Purpose:    Close out the CERIS_R22 miscode process.
Modified:   05/19/2010   modified for CR-2350 changes, partially processed TC

Notes:      Reference BP&S Service Request CR2350
************************************************************************************************/

BEGIN

DECLARE @NEW_STATUS_RECORD_NUM int

-- Mark records that were successfully imported

SELECT @NEW_STATUS_RECORD_NUM = 
   CAST(DATEPART(year, GETDATE()) as varchar) 
   + RIGHT('0' + CAST(DATEPART(month, GETDATE()) as varchar), 2)
   + RIGHT('0' + CAST(DATEPART(day, GETDATE()) as varchar), 2)
	
	
UPDATE XX_R22_CERIS_RETRO_TS_PREP_MISCODES
   SET STATUS_RECORD_NUM_REPROCESSED = @NEW_STATUS_RECORD_NUM,
       UPDATE_DT = current_timestamp
 WHERE STATUS_RECORD_NUM_REPROCESSED IS NULL
   AND NOTES IN (SELECT NOTES FROM IMAR.DELTEK.TS_LN)

    -- Added CR-2350 03/20/2010 TP
    -- Mark records not processed if they have partial TC processed
    update dbo.XX_R22_CERIS_RETRO_TS_PREP_MISCODES
    set status_record_num_reprocessed=NULL
    --WHERE NOTES not in (SELECT NOTES FROM IMAR.DELTEK.TS_LN)
    --select *
    FROM dbo.XX_R22_CERIS_RETRO_TS_PREP_MISCODES
    where (empl_id+convert(char(10), dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt),120)) in 
        (
        select distinct empl_id+convert(char(10), dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt),120) 
        FROM dbo.XX_R22_CERIS_RETRO_TS_PREP_MISCODES
        where notes not in (select notes from imar.deltek.ts_ln)
        and status_record_num_reprocessed is null
        )
    and s_ts_type_cd  in ('N','D')
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
                        from dbo.XX_R22_CERIS_RETRO_TS_PREP_MISCODES
                        where status_record_num_reprocessed is null)

    --END CR-2350 changes

	
UPDATE XX_ERROR_STATUS
   SET STATUS = 'REPROCESSED',
       CONTROL_PT = 7,
       TIME_STAMP = current_timestamp,
       SUCCESS_COUNT = 
          (select isnull(count(1),0)
             from XX_R22_CERIS_RETRO_TS_PREP_MISCODES 
            where STATUS_RECORD_NUM_CREATED = err_status.status_record_num
              and UPDATE_DT >= err_status.time_stamp
              and STATUS_RECORD_NUM_REPROCESSED is not null),
       SUCCESS_AMOUNT = 
          (select isnull(sum(cast(chg_hrs as decimal(14,2))), .00)
             from XX_R22_CERIS_RETRO_TS_PREP_MISCODES 
            where STATUS_RECORD_NUM_CREATED = err_status.status_record_num
              and UPDATE_DT >= err_status.time_stamp
              and STATUS_RECORD_NUM_REPROCESSED is not null),
       ERROR_COUNT = 
          (select isnull(count(1),0)
             from XX_R22_CERIS_RETRO_TS_PREP_MISCODES 
            where STATUS_RECORD_NUM_CREATED = err_status.status_record_num
              and STATUS_RECORD_NUM_REPROCESSED is null),
       ERROR_AMOUNT = 
          (select isnull(sum(cast(chg_hrs as decimal(14,2))), .00)
             from XX_R22_CERIS_RETRO_TS_PREP_MISCODES 
            where STATUS_RECORD_NUM_CREATED = err_status.status_record_num
              and STATUS_RECORD_NUM_REPROCESSED is null)
  FROM XX_ERROR_STATUS err_status
 WHERE CONTROL_PT = 3
   AND INTERFACE = 'CERIS_R22'


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
IF OBJECT_ID('dbo.XX_R22_CERIS_MISCODE_CLOSEOUT_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_CERIS_MISCODE_CLOSEOUT_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_CERIS_MISCODE_CLOSEOUT_SP >>>'
go

use imapsstg
go

IF OBJECT_ID('dbo.XX_CERIS_SIMULATE_TSHDRSEQ_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_CERIS_SIMULATE_TSHDRSEQ_SP
    IF OBJECT_ID('dbo.XX_CERIS_SIMULATE_TSHDRSEQ_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_CERIS_SIMULATE_TSHDRSEQ_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_CERIS_SIMULATE_TSHDRSEQ_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go


CREATE PROCEDURE [dbo].[XX_CERIS_SIMULATE_TSHDRSEQ_SP] 
(
@in_COMPANY_ID char(1)= NULL -- Added CR-1543
)
AS
/************************************************************************************************  
Name:       	XX_CERIS_SIMULATE_TSHDRSEQ_SP
Author:     	Tejas Patel
Created:    	09/25/2012
Modified:       09/25/2012 Added Close Cursor
Purpose:  This procedure will update ts_hdr_seq_no for all N/D timesheets.  	
	
	THIS ENTIRE STORED PROCEDURE IS FOR CR-4885
	
Prerequisites: 	All TS should be posted, CERIS Interface should have populated XX_CERIS_RETRO_TS_PREP
Version: 	1.0


DR6720 - CERIS retro timesheets miscode when max ts_hdr_seq_no of 99 is reached - KM - 2014-08-04
************************************************************************************************/  
BEGIN

DECLARE 
    @EMPL_ID varchar(12),
    @TS_DT	 datetime,
    @correcting_ref_dt datetime

-- 'TS_HDR_SEQ_NO UPDATE:  xx_imaps_ts_prep_temp'

DECLARE EMPL_ID_CURSOR CURSOR FAST_FORWARD FOR
    SELECT DISTINCT EMPL_ID, convert(datetime,TS_DT) as TS_DT, convert(datetime,CORRECTING_REF_DT) as CORRECTING_REF_DT 
	    FROM DBO.XX_CERIS_RETRO_TS_PREP where s_ts_type_cd not in ('R')
        order by empl_id, convert(datetime,CORRECTING_REF_DT)

OPEN EMPL_ID_CURSOR
FETCH NEXT FROM EMPL_ID_CURSOR INTO @EMPL_ID, @TS_DT, @CORRECTING_REF_DT

WHILE @@FETCH_STATUS = 0
    BEGIN
     

         --BECAUSE OF CHANGE TO CORRECTING TIMESHEETS, WE MUST USE THE TS_HDR_SEQ_NO
         --SO THAT PREPROCESSOR DOES NOT GIVE INCONSISTENT HEADER DATA ERROR
         --ON CORRECTING TIMESHEETS REFERENCE DATE
         
         --S_TS_HDR_SEQ_NO MUST BE UNIQUE FOR THIS COMBINATION:
         --TS_DT (all the same), TS_TYPE (all the same), EMPL_ID, CORRECTING_REF_DT
         
         --TO ISOLATE CROSS-CHARGING, WE MUST ALSO GROUP BY PROJ_ABBRV_CD
         --drop table #XX_IMAPS_TS_HDR_SEQ_NO


    CREATE TABLE #XX_IMAPS_CERIS_TS_HDR_SEQ_NO (
      [IDENTITY_TS_HDR_SEQ_NO] [int] IDENTITY (1, 1) NOT NULL ,
      [EMPL_ID] [char] (12) NOT NULL,
      [CORRECTING_REF_DT] [char] (10) NULL,
      [S_TS_LN_TYPE_CD] [char] (1) NULL,
            [S_TS_TYPE_CD] [char] (1) NULL,
            [PROJ_ABBRV_CD] [char] (10) NULL
     )

    declare @max_seq1 int,
            @max_seq2 int,
            @max_seq  int

    set @max_seq=0
    set @max_seq1=0
    set @max_seq2=0    
    -- Find the Max Seq assigned for the same employee,ts_date for Regular TS
    -- If can't find one then the default will be 2
	    select @max_seq1=isnull(max(ts.ts_hdr_seq_no),3)
	    FROM IMAPS.DELTEK.TS_LN_HS ts
	    inner join IMAPS.DELTEK.ts_hdr_HS hdr
		    on
		    (hdr.empl_id = ts.empl_id
		    and hdr.ts_dt = ts.ts_dt
		    and hdr.s_ts_type_cd = ts.s_ts_type_cd
		    and hdr.ts_hdr_seq_no = ts.ts_hdr_seq_no)
	    where ts.empl_id=@empl_id and ts.ts_dt=@ts_dt
	    and ts.S_TS_TYPE_CD<>'R'

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 101 : XX_CERIS_SIMULATE_TSHDRSEQ_SP.sql '
 
	    select @max_seq2=isnull(max(ts.ts_hdr_seq_no),3)
	    FROM IMAPS.DELTEK.TS_LN ts
	    inner join IMAPS.DELTEK.ts_hdr hdr
		    on
		    (hdr.empl_id = ts.empl_id
		    and hdr.ts_dt = ts.ts_dt
		    and hdr.s_ts_type_cd = ts.s_ts_type_cd
		    and hdr.ts_hdr_seq_no = ts.ts_hdr_seq_no)
	    where ts.empl_id=@empl_id and ts.ts_dt=@ts_dt
	    and ts.S_TS_TYPE_CD<>'R'

        -- Compare both seq_no and we will pick the largest number of both
        IF @max_seq1 > @max_seq2 
	        BEGIN
		        set @max_seq=@max_seq1
	        END
        ELSE IF @max_seq2 >= @max_seq1
	        BEGIN
		        set @max_seq=@max_seq2
	        END
        

	    set @max_seq=@max_seq+1

	    dbcc checkident(#XX_IMAPS_CERIS_TS_HDR_SEQ_NO, reseed, @max_seq)

     -- Load data into temp table
     INSERT INTO #XX_IMAPS_CERIS_TS_HDR_SEQ_NO
     (EMPL_ID, CORRECTING_REF_DT, S_TS_TYPE_CD)
     SELECT  EMPL_ID, CORRECTING_REF_DT, S_TS_TYPE_CD
     FROM  DBO.XX_CERIS_RETRO_TS_PREP
     WHERE  EMPL_ID = @empl_id
     AND S_TS_TYPE_CD not in ('R')
     GROUP BY EMPL_ID, CORRECTING_REF_DT, S_TS_TYPE_CD
     ORDER BY EMPL_ID, CORRECTING_REF_DT, S_TS_TYPE_CD --DR6720
     
     -- Update prep temp with ts hdr seq noj
     UPDATE DBO.XX_CERIS_RETRO_TS_PREP
     SET TS_HDR_SEQ_NO = CAST(tmp.IDENTITY_TS_HDR_SEQ_NO as char(3))
     FROM  DBO.XX_CERIS_RETRO_TS_PREP ceris
     INNER JOIN
      #XX_IMAPS_CERIS_TS_HDR_SEQ_NO tmp
     ON
     (ceris.EMPL_ID = tmp.EMPL_ID
     and ceris.CORRECTING_REF_DT = tmp.CORRECTING_REF_DT
     --and ISNULL(ceris.S_TS_LN_TYPE_CD, '') = ISNULL(tmp.S_TS_LN_TYPE_CD, '')
     and ceris.s_ts_type_cd=tmp.s_ts_type_cd
     --and ceris.proj_abbrv_cd=tmp.proj_abbrv_cd
     )
     
    -- Drop temp table
     DROP TABLE #XX_IMAPS_CERIS_TS_HDR_SEQ_NO

     FETCH NEXT FROM EMPL_ID_CURSOR INTO @EMPL_ID, @TS_DT, @CORRECTING_REF_DT
		
    END
CLOSE EMPL_ID_CURSOR
DEALLOCATE EMPL_ID_CURSOR

END

	    IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

	    RETURN (0)
	
	    BL_ERROR_HANDLER:
	
	    PRINT 'ERROR UPDATING HDR TS HDR SEQs'
	 RETURN(1)


go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_CERIS_SIMULATE_TSHDRSEQ_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_CERIS_SIMULATE_TSHDRSEQ_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_CERIS_SIMULATE_TSHDRSEQ_SP >>>'
go

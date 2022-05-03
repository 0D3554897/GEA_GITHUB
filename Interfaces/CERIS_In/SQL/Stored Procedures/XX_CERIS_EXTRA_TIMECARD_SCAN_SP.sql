USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_EXTRA_TIMECARD_SCAN_SP]    Script Date: 02/15/2017 16:30:04 ******/

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_CERIS_EXTRA_TIMECARD_SCAN_SP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[XX_CERIS_EXTRA_TIMECARD_SCAN_SP]
GO

USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_EXTRA_TIMECARD_SCAN_SP]    Script Date: 02/15/2017 16:30:04 ******/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[XX_CERIS_EXTRA_TIMECARD_SCAN_SP] (
	@out_STATUS_DESCRIPTION sysname = NULL output
)

AS

/************************************************************************************************
 Procedure Name	: XX_CERIS_EXTRA_TIMECARD_SCAN_SP  									 
 Created By		: KM									   							

	 
 Description    : Populates table for Cognos Report (CR6354)	Cognos: Federal Division Transfers Report									 
 Date			: 2013-09-10				        									 
 Notes			:																

		 
 Prerequisites	: 																	

	 
 Parameter(s)	: 																	

	 
	Input		:																

		 
	Output		: Error Code and Error Description										 
 Tables Updated	: xx_ceris_extra_timecard_scan_results		 
 Version		: 1.0																

	 
 ************************************************************************************************
 Date		  Modified By			Description of change	  								 
 ----------   -------------  	   	------------------------    			  				 
 2013-09-10   KM   					Created Initial Version	

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 59 : XX_CERIS_EXTRA_TIMECARD_SCAN_SP.sql '  --DR9291
 
exec XX_CERIS_EXTRA_TIMECARD_SCAN_SP	

Division=## means terminated
Division=-- means not on source file yet
Division=?? means dropped off source file because of CERIS feed criteria (div and div_from no longer PS/Federal)	
						 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 70 : XX_CERIS_EXTRA_TIMECARD_SCAN_SP.sql '  --DR9291
 
select top 10 *
from XX_CERIS_EXTRA_TIMECARD_SCAN_RESULTs

DR9291 - Div1P - gea - 2017-02-13  : inadvertently omitted 2G when doing CR 8761
DR9291 - gea - 2/23/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
 ***********************************************************************************************/


BEGIN
PRINT '' --DR9291
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_CERIS_EXTRA_TIMECARD_SCAN_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --DR9291

DECLARE	@SP_NAME         	 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@ret_code		 int,
		@count			 int,
		@last_STATUS_RECORD_NUM int,
        @PROCEDURE_START_DT datetime

	SET @SP_NAME = 'XX_CERIS_EXTRA_TIMECARD_SCAN_SP'



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'SET'
	SET @ERROR_MSG_PLACEHOLDER2 = 'TIMECARD SCAN DATE PARAMETERS'

	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2


    SET @PROCEDURE_START_DT = getdate()

	declare	@scan_start_dt datetime,
			@scan_end_dt datetime

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 117 : XX_CERIS_EXTRA_TIMECARD_SCAN_SP.sql '  --DR9291
 
	select @scan_start_dt = cast(parameter_value as datetime)
	from xx_processing_parameters
	where interface_name_cd='CERIS'
	and parameter_name='EXTRA_TIMECARD_SCAN_start_dt'
	
 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 132 : XX_CERIS_EXTRA_TIMECARD_SCAN_SP.sql '  --DR9291
 
	select @scan_end_dt = cast(parameter_value as datetime)
	from xx_processing_parameters
	where interface_name_cd='CERIS'
	and parameter_name='EXTRA_TIMECARD_SCAN_end_dt'
	
 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'TRUNCATE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'xx_ceris_extra_timecard_scan_results'

	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 152 : XX_CERIS_EXTRA_TIMECARD_SCAN_SP.sql '  --DR9291
 
	truncate table xx_ceris_extra_timecard_scan_results
	
 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT into xx_ceris_extra_timecard_scan_results'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR EXTERNAL TRANSFERS and TERMINATIONS'

	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2


	/*
	Case 1

	--Hire/Fire/Transfer in/out of Federal Divisions
	*/

	--query only looks for extra timesheets (not missing timesheets)
	--combine timesheet data with division transfer data (retro)

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 181 : XX_CERIS_EXTRA_TIMECARD_SCAN_SP.sql '  --DR9291
 
	INSERT INTO XX_CERIS_EXTRA_TIMECARD_SCAN_RESULTS
	(EMPL_ID, MIN_TS_DT, MAX_TS_DT, EXTRA_HRS, DIVISION, DIVISION_START_DT, DIVISION_FROM, CERIS_CHANGE_RUN_DT, CREATED_BY, CREATED_DT)
	select 
	ts_hdr.empl_id,  
	(min(isnull(ts_hdr.corecting_ref_dt,ts_hdr.ts_dt))) as min_ts_dt,
	(max(isnull(ts_hdr.corecting_ref_dt,ts_hdr.ts_dt))) as max_ts_dt,
		isnull(
			(	
				select sum(chg_hrs) from imaps.deltek.ts_ln_hs
				where empl_id=ts_hdr.empl_id and ts_dt between @scan_start_dt and @scan_end_dt --parameter date range
				and (
					effect_bill_dt between 
					dbo.xx_get_friday_for_ts_week_day_uf(min(isnull(ts_hdr.corecting_ref_dt,ts_hdr.ts_dt)))-6
					and
					max(isnull(ts_hdr.corecting_ref_dt,ts_hdr.ts_dt))
					)
				and
				effect_bill_dt>=ceris.division_start_dt
			)
			,0)
	 as extra_hrs,
	ceris.division,
	ceris.division_start_dt,
	ceris.division_from,
	convert(char(10),ceris.creation_dt,120) as CERIS_CHANGE_RUN_DT,
	suser_sname() as CREATED_BY,
	getdate() as CREATED_DATE
	from 
	imaps.deltek.ts_hdr_hs ts_hdr
	inner join
	xx_ceris_div16_status ceris
	on
	(
	ts_hdr.empl_id=ceris.empl_id --empl
	and
	--max ceris record after division start date
	--captures retro's
	ceris.creation_dt = (select max(creation_dt)
						 from xx_ceris_div16_status
						 where empl_id=ts_hdr.empl_id
						 and division_start_dt<=isnull(ts_hdr.corecting_ref_dt,ts_hdr.ts_dt))
	)
	where
	ts_hdr.ts_dt between @scan_start_dt and @scan_end_dt --parameter date range
	and
	isnull(ts_hdr.corecting_ref_dt,ts_hdr.ts_dt) between @scan_start_dt and @scan_end_dt --parameter date range
	and
	ceris.division not in ('16','1M','1P','2G') --not in 16 or 1M for given date, adding 1P now so we don't forget later
	and
	--exclude employees with 16/1P<->1M transfers in date range
	--these will be handled in CASE 2 by looking at TS_LN_HS table with filter on ORG
	ceris.empl_id not in
	(
	select empl_id
	from xx_ceris_div16_status
	where division in ('16','1M', '1P', '2G')
	and division_from in ('16','1M', '1P', '2G')
	and division_start_dt between @scan_start_dt and @scan_end_dt --parameter date range
	)
	group by 
	ts_hdr.empl_id, 
	ceris.division,
	ceris.division_start_dt,
	ceris.division_from,
	ceris.creation_dt,
	ceris.prev_creation_dt
	order by 
	ts_hdr.empl_id, 
	min(isnull(ts_hdr.corecting_ref_dt,ts_hdr.ts_dt))

	
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT into xx_ceris_extra_timecard_scan_results'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR INTERNAL TRANSFERS'
	/*
	Case 2

	--Transfers within Federal Divisions (16,1M,1P)
	*/

	--more complicated, need to look org on timesheet lines and compare that with division
	--trying to improve efficiency of this by limiting to just these types of employees
	
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 274 : XX_CERIS_EXTRA_TIMECARD_SCAN_SP.sql '  --DR9291
 
	INSERT INTO XX_CERIS_EXTRA_TIMECARD_SCAN_RESULTS
	(EMPL_ID, MIN_TS_DT, MAX_TS_DT, EXTRA_HRS, DIVISION, DIVISION_START_DT, DIVISION_FROM, CERIS_CHANGE_RUN_DT, CREATED_BY, CREATED_DT)
	select 
	ts_hdr.empl_id,  
	(min(isnull(ts_hdr.corecting_ref_dt,ts_hdr.ts_dt))) as min_ts_dt,
	(max(isnull(ts_hdr.corecting_ref_dt,ts_hdr.ts_dt))) as max_ts_dt,
		isnull(
			(	
				select sum(chg_hrs) from imaps.deltek.ts_ln_hs
				where empl_id=ts_hdr.empl_id and ts_dt between @scan_start_dt and @scan_end_dt --parameter date range
				and (
					effect_bill_dt between 
					dbo.xx_get_friday_for_ts_week_day_uf(min(isnull(ts_hdr.corecting_ref_dt,ts_hdr.ts_dt)))-6
					and
					max(isnull(ts_hdr.corecting_ref_dt,ts_hdr.ts_dt))
					)
				and
				effect_bill_dt>=ceris.division_start_dt
				and
				left(org_id,2)<>replace(replace(ceris.DIVISION,'1P','16'),'2G','16')--treat 1P and 2G as 16 in CP
			)
			,0)
	 as extra_hrs,
	ceris.division,
	ceris.division_start_dt,
	ceris.division_from,
	convert(char(10),ceris.creation_dt,120) as CERIS_CHANGE_RUN_DT,
	suser_sname() as CREATED_BY,
	getdate() as CREATED_DATE
	from 
	imaps.deltek.ts_hdr_hs ts_hdr
	inner join
	xx_ceris_div16_status ceris
	on
	(
	ts_hdr.empl_id=ceris.empl_id --empl
	and
	--max ceris record after division start date
	--captures retro's
	ceris.creation_dt = (select max(creation_dt)
						 from xx_ceris_div16_status
						 where empl_id=ts_hdr.empl_id
						 and division_start_dt<=isnull(ts_hdr.corecting_ref_dt,ts_hdr.ts_dt))
	)
	where
	ts_hdr.ts_dt between @scan_start_dt and @scan_end_dt --parameter date range
	and
	isnull(ts_hdr.corecting_ref_dt,ts_hdr.ts_dt) between @scan_start_dt and @scan_end_dt --parameter date range
	and
	--only include employees with 16/1P<->1M transfers in date range
	--this is handled in CASE 2 by looking at TS_LN_HS table with filter on ORG (see above)
	ceris.empl_id in
	(
	select empl_id
	from xx_ceris_div16_status
	where division in ('16','1M', '1P','2G')
	and division_from in ('16','1M', '1P','2G')
	and division_start_dt between @scan_start_dt and @scan_end_dt --parameter date range
	)
	group by 
	ts_hdr.empl_id, 
	ceris.division,
	ceris.division_start_dt,
	ceris.division_from,
	ceris.creation_dt,
	ceris.prev_creation_dt
	order by 
	ts_hdr.empl_id, 
	min(isnull(ts_hdr.corecting_ref_dt,ts_hdr.ts_dt))



	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT into xx_ceris_extra_timecard_scan_results'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR TRANSFERS NOT CAPTURED BY EXTRA TIMECARD SCAN LOGIC - part a'
	/*
	Case 3

	--All other types of transfers within date range that did not produce results from timesheet scanning
	--0 extra hours
	--no join on TS_HDR_HS at all, since there might not be anything there to join with
	*/

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 364 : XX_CERIS_EXTRA_TIMECARD_SCAN_SP.sql '  --DR9291
 
	INSERT INTO XX_CERIS_EXTRA_TIMECARD_SCAN_RESULTS
	(EMPL_ID, MIN_TS_DT, MAX_TS_DT, EXTRA_HRS, DIVISION, DIVISION_START_DT, DIVISION_FROM, CERIS_CHANGE_RUN_DT, CREATED_BY, CREATED_DT)
	select 
	ceris.empl_id,  
	(
		(
			select min(isnull(corecting_ref_dt,ts_dt))
			from imaps.deltek.ts_hdr_hs
			where empl_id=ceris.empl_id
			and s_ts_type_cd='R'
			and ts_dt>=ceris.division_start_dt
			and ts_dt between @scan_start_dt and @scan_end_dt --parameter date range
			and isnull(corecting_ref_dt,ts_dt) between @scan_start_dt and @scan_end_dt --parameter date range
		)
	) as min_ts_dt,
	(
		(
			select max(isnull(corecting_ref_dt,ts_dt))
			from imaps.deltek.ts_hdr_hs
			where empl_id=ceris.empl_id
			and s_ts_type_cd='R'
			and ts_dt>=ceris.division_start_dt
			and ts_dt between @scan_start_dt and @scan_end_dt --parameter date range
			and	isnull(corecting_ref_dt,ts_dt) between @scan_start_dt and @scan_end_dt --parameter date range
		)
	) as max_ts_dt,
	0 as extra_hrs,
	ceris.division,
	ceris.division_start_dt,
	ceris.division_from,
	convert(char(10),ceris.creation_dt,120) as CERIS_CHANGE_RUN_DT,
	suser_sname() as CREATED_BY,
	getdate() as CREATED_DATE
	from 
	xx_ceris_div16_status ceris
	where
	--max ceris record after division start date
	--captures retro's
	0 = (select count(1) from xx_ceris_div16_status where empl_id=ceris.empl_id and division_start_dt<=ceris.division_start_dt and 
	creation_dt>ceris.creation_dt)	
	and
	ceris.division_start_dt between @scan_start_dt and @scan_end_dt --parameter date range
	and
	--only include records not already processed by scan
	0 = (select count(1) from XX_CERIS_EXTRA_TIMECARD_SCAN_RESULTS where empl_id=ceris.empl_id and division=ceris.division and 
	division_start_dt=ceris.division_start_dt)
	and
	--and transfer is into or out of Federal division
	(	
		ceris.division in ('16','1M', '1P','2G')
		or
		ceris.division_from in ('16','1M', '1P','2G')
	)
	group by 
	ceris.empl_id, 
	ceris.division,
	ceris.division_start_dt,
	ceris.division_from,
	ceris.creation_dt,
	ceris.prev_creation_dt
	order by 
	ceris.empl_id, 
	ceris.division_start_dt


 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

    -- add record to the reports common status table will be used in Division Transfers report
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 437 : XX_CERIS_EXTRA_TIMECARD_SCAN_SP.sql '  --DR9291
 
    INSERT INTO [dbo].[XX_INTERNAL_SCRIPT_LOG] 
    ([SCRIPT]  ,[SCRIPT_START] ,[SCRIPT_END]  ,[MESSAGE])
    VALUES ('XX_CERIS_EXTRA_TIMECARD_SCAN_SP',@PROCEDURE_START_DT, getdate(), 'Procedure was run for range ' + 
	 CONVERT(VARCHAR(10),@scan_start_dt ,110) + ' - ' + CONVERT(VARCHAR(10),@scan_end_dt,110))

 
 
    	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


PRINT '' --DR9291
PRINT '*~^*************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF  XX_CERIS_EXTRA_TIMECARD_SCAN_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --DR9291
RETURN 0

ERROR:

PRINT @out_STATUS_DESCRIPTION

 
 
EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_number,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

PRINT @out_STATUS_DESCRIPTION

RETURN 1

END


GO



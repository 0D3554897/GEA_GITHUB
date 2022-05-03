USE [IMAPSStg]
GO
/****** Object:  StoredProcedure [dbo].[XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP]    Script Date: 11/02/2007 09:01:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP]
GO


CREATE PROCEDURE [dbo].[XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP] (
@out_STATUS_DESCRIPTION sysname = NULL OUTPUT
)
AS
BEGIN
/*
1M Changes:
new CERIS data element

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 25 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
exec XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP

CR4885 changes:
remove ETIME as source

DR6119:
remove hours/mins/secs from date
*/
DECLARE @SP_NAME                 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
	@INTERFACE_NAME		 sysname,
	@ret_code		 int,
	@count			 int

	SET @SP_NAME='XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP'


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'MAP PAY_DIFFERENTIAL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR EXEMPT'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2


	PRINT 'perform PAY_DIFFERENTIAL MAPPING for Exempt'
	--1M changes
	UPDATE XX_CERIS_HIST
	SET PAY_DIFFERENTIAL=map.PAY_DIFFERENTIAL
	FROM 
	XX_CERIS_HIST ceris
	INNER JOIN
	XX_CERIS_PAY_DIFFERENTIAL_MAPPING map
	on
	(
		ceris.DIVISION=map.DIVISION
		and
		map.SALSETID = ceris.SALSETID
	)
	--where ceris.FLSA_STAT='E'
	--apply this to all employees where SALSETID exists in MAPPING table


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 72 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'MAP PAY_DIFFERENTIAL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR NON-EXEMPT'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	PRINT 'perform PAY_DIFFERENTIAL MAPPING for NON-Exempt'
	--1M changes

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 87 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	UPDATE XX_CERIS_HIST
	SET PAY_DIFFERENTIAL=map.PAY_DIFFERENTIAL
	FROM 
	XX_CERIS_HIST ceris
	INNER JOIN
	XX_CERIS_NON_EXEMPT_WKL_MAPPING wkl
	on
	(
	/*ceris.FLSA_STAT='N'
	and*/
	--apply this to all employees where SALSETID is not already in MAPPING table
	ceris.PAY_DIFFERENTIAL = '?'
	and
	ceris.WKLCITY=wkl.WKLCITY
	and
	ceris.WKLST=wkl.WKLST
	)
	INNER JOIN
	XX_CERIS_PAY_DIFFERENTIAL_MAPPING map
	on
	(
		ceris.DIVISION=map.DIVISION
		and
		map.SALSETID=wkl.SALSETID
	)


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 117 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'SET PAY_DIFFERENTIAL_DT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'EQUAL TO NULL'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2
	
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 130 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	UPDATE XX_CERIS_HIST
	SET PAY_DIFFERENTIAL_DT=null

/*
	There is no Pay Differential effective date in CERIS.  The interface will derive the Pay Differential effective date using the following logic:

	-if the Pay Differential is mapped to a Foreign Department, then set the Pay Differential effective date equal to the the DEPT_START_DT 

	-otherwise, if the Pay Differential changes because the employee had a Division change, then set the Pay Differential effective date equal to the DIVISION_START_DT

	-otherwise, if the Pay Differential stays the same, and the Division stays the same, but the DIVISION_START_DT has changed, then set the Pay Differential effective date equal to 		the new DIVISION_START_DT

	-otherwise, if the Pay Differential stays the same, then keep the Pay Differential effective date the same as it was last week

	-otherwise, if the Pay Differential changes for a reason other than Foreign Department or Division changes, then use the current system date as the effective date of the change

	-otherwise, if the employee has never existed on the CERIS file before, then use the maximum of the JOB_FAM_DT & LVL_DT_1 as the initial effective date
*/

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 152 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'MAP PAY_DIFFERENTIAL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR FOREIGN'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2


	PRINT 'perform PAY_DIFFERENTIAL MAPPING for Foreign'
	--1M changes

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 168 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	UPDATE XX_CERIS_HIST
	SET PAY_DIFFERENTIAL=map.PAY_DIFFERENTIAL,
		PAY_DIFFERENTIAL_DT=ceris.DEPT_START_DT
	FROM 
	XX_CERIS_HIST ceris
	INNER JOIN
	XX_CERIS_PAY_DIFFERENTIAL_MAPPING map
	on
	(
		ceris.DIVISION=map.DIVISION
		and
		ceris.DEPT=map.DEPT
	)


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 186 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE PAY_DIFFERENTIAL_DT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR DIVISION CHANGE'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	/*
	**Needed to change the Pay Differential effective date logic to work for division/dept changes
	-use dept_start_dt if pay differential is mapped to Foreign Department (see above)
	-use divison_start_dt if pay differential is mapped to new Division (see below)
	-use divison_start_dt if Division stays the same and pay_differential stays the same, but the division_start_dt is changed
	-otherwise, uses current_timestamp (see below)
	*/
	UPDATE XX_CERIS_HIST
	SET PAY_DIFFERENTIAL_DT = ceris.DIVISION_START_DT
	FROM 
	XX_CERIS_HIST ceris
	inner join
	XX_CERIS_PAY_DIFFERENTIAL_FROM_LAST_WEEK last_week
	on
	(
	ceris.PAY_DIFFERENTIAL_DT is null
	and
	ceris.EMPL_ID=last_week.EMPL_ID
	and
	ceris.DIVISION<>last_week.DIVISION
	and
	ceris.PAY_DIFFERENTIAL<>last_week.PAY_DIFFERENTIAL
	)


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 223 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


--BEGIN TPR for when DIVISION effective date is changed
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE PAY_DIFFERENTIAL_DT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR DIVISION_START_DT CHANGE'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	/*
There is no effective date for the Pay Differential in the CERIS file.

The new logic for Pay Differential effective date is:

-if the Pay Differential is mapped to a Foreign Department, then set the Pay Differential effective date equal to the the DEPT_START_DT 
-otherwise, if the Pay Differential changes because the employee had a Division change, then set the Pay Differential effective date equal to the DIVISION_START_DT
-otherwise, if the Pay Differential stays the same, and the Division stays the same, but the DIVISION_START_DT has changed, then set the Pay Differential effective date equal to the new DIVISION_START_DT
-otherwise, if the Pay Differential stays the same, then keep the Pay Differential effective date the same as it was last week
-otherwise, if the Pay Differential changes for any reason, then use the current system date

	*/
	UPDATE XX_CERIS_HIST
	SET PAY_DIFFERENTIAL_DT = ceris.DIVISION_START_DT
	FROM 
	XX_CERIS_HIST ceris
	inner join
	XX_CERIS_PAY_DIFFERENTIAL_FROM_LAST_WEEK last_week
	on
	(	
	ceris.PAY_DIFFERENTIAL_DT is null
	and
	ceris.EMPL_ID=last_week.EMPL_ID
	and
	ceris.DIVISION=last_week.DIVISION
	and
	ceris.PAY_DIFFERENTIAL=last_week.PAY_DIFFERENTIAL
	and
	ceris.DIVISION_START_DT<>last_week.DIVISION_START_DT
	)

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 267 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
--END TPR for when DIVISION effective date is changed




	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE PAY_DIFFERENTIAL_DT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR NO CHANGE'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2


	--if nothing's changed, keep last_week's PAY_DIFFERENTIAL_DT
	UPDATE XX_CERIS_HIST
	SET PAY_DIFFERENTIAL_DT = last_week.PAY_DIFFERENTIAL_DT
	FROM 
	XX_CERIS_HIST this_week
	INNER JOIN
	XX_CERIS_PAY_DIFFERENTIAL_FROM_LAST_WEEK last_week
	ON
	(	
	this_week.PAY_DIFFERENTIAL_DT is null
	and
	this_week.empl_id=last_week.empl_id
	and
	this_week.PAY_DIFFERENTIAL=last_week.PAY_DIFFERENTIAL
	)


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 300 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	/*
	THIS MESSES UP THE LOGIC BECAUSE IT CAUSES AN EFFECTIVE DATE CHANGE FOR THE GLC
	the logic gets messed up because of the EMPL_LAB_INFO conversion changed to use N

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 309 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	UPDATE XX_CERIS_HIST
	SET PAY_DIFFERENTIAL_DT=cast('2011-01-01' as smalldatetime)
	WHERE PAY_DIFFERENTIAL_DT < cast('2011-01-01' as smalldatetime)


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 317 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	*/



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE PAY_DIFFERENTIAL_DT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR NEW EMPLOYEE AND JOB_FAM MOST RECENT CHANGE'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2


	--if never existed before, use max of job_fam/sal_band dates as pay_diff date
	UPDATE XX_CERIS_HIST
	SET PAY_DIFFERENTIAL_DT=JOB_FAM_DT
	FROM XX_CERIS_HIST ceris
	WHERE 
	0 = (select count(1) from XX_CERIS_PAY_DIFFERENTIAL_FROM_LAST_WEEK where empl_id=ceris.empl_id)
	and
	JOB_FAM_DT >= LVL_DT_1


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 342 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE PAY_DIFFERENTIAL_DT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR NEW EMPLOYEE AND SAL_BAND MOST RECENT CHANGE'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 355 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	UPDATE XX_CERIS_HIST
	SET PAY_DIFFERENTIAL_DT=LVL_DT_1
	FROM XX_CERIS_HIST ceris
	WHERE 
	0 = (select count(1) from XX_CERIS_PAY_DIFFERENTIAL_FROM_LAST_WEEK where empl_id=ceris.empl_id)
	and
	JOB_FAM_DT < LVL_DT_1


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 367 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE PAY_DIFFERENTIAL_DT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR ANY OTHER CHANGE'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	DECLARE @FILE_CREATE_DATE datetime

	--CR4885 begin
	/*
	SELECT @FILE_CREATE_DATE = MAX(CREATE_DATE)
     from ETIME_RPT..CFRPTADM.IBM_CERIS
    where DIVISION IN ('16','1M')
	*/
	SELECT @FILE_CREATE_DATE = MAX(CREATION_DATE)
     from XX_CERIS_DATA_STG
    where DIVISION_1 IN ('16','1M')
	--CR4885 end
	--DR6119 begin
	SET @FILE_CREATE_DATE = CONVERT(CHAR(10),@FILE_CREATE_DATE,120) 
	--DR6119 end


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 396 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	UPDATE XX_CERIS_HIST
	SET PAY_DIFFERENTIAL_DT = @FILE_CREATE_DATE
	FROM 
	XX_CERIS_HIST this_week
	INNER JOIN
	XX_CERIS_PAY_DIFFERENTIAL_FROM_LAST_WEEK last_week
	ON
	(	
	this_week.PAY_DIFFERENTIAL_DT is null
	and
	this_week.empl_id=last_week.empl_id
	and
	this_week.PAY_DIFFERENTIAL<>last_week.PAY_DIFFERENTIAL
	)
	
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 414 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'MAINTAIN'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_CERIS_PAY_DIFFERENTIAL_FROM_LAST_WEEK'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2


	--keep track for next week's changes
	TRUNCATE TABLE XX_CERIS_PAY_DIFFERENTIAL_FROM_LAST_WEEK
	INSERT INTO XX_CERIS_PAY_DIFFERENTIAL_FROM_LAST_WEEK
	(EMPL_ID, 
	division, division_start_dt,
	dept, dept_start_dt,
	job_fam, job_fam_dt,
	sal_band, lvl_dt_1,
	flsa_stat, exempt_dt,
	PAY_DIFFERENTIAL, PAY_DIFFERENTIAL_DT, CREATED_DATE)
	SELECT 
	EMPL_ID, 
	division, division_start_dt,
	dept, dept_start_dt,
	job_fam, job_fam_dt,
	sal_band, lvl_dt_1,
	flsa_stat, exempt_dt,
	PAY_DIFFERENTIAL, PAY_DIFFERENTIAL_DT, current_timestamp as CREATED_DATE
	FROM XX_CERIS_HIST
	WHERE PAY_DIFFERENTIAL<>'?'
			
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 449 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


RETURN 0

ERROR:


PRINT @out_STATUS_DESCRIPTION

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 463 : XX_CERIS_PROCESS_PAY_DIFFERENTIAL_SP.sql '
 
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


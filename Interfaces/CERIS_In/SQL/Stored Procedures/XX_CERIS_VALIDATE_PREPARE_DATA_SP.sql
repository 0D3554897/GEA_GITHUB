USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_VALIDATE_PREPARE_DATA_SP]    Script Date: 02/15/2017 16:25:46 ******/

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_CERIS_VALIDATE_PREPARE_DATA_SP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[XX_CERIS_VALIDATE_PREPARE_DATA_SP]
GO

USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_VALIDATE_PREPARE_DATA_SP]    Script Date: 02/15/2017 16:25:46 ******/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[XX_CERIS_VALIDATE_PREPARE_DATA_SP]
(
@in_STATUS_RECORD_NUM      integer,
@out_SQLServer_error_code  integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION    varchar(255) = NULL OUTPUT
)
AS

/************************************************************************************************
Name:       XX_CERIS_VALIDATE_PREPARE_DATA_SP
Author:     KM, HVT
Created:    10/07/2005
Purpose:    Populate the temporary table XX_CERIS_CP_STG using source data from table XX_CERIS_HIST.
            Perform the same validations as the Costpoint Employee Basic preprocessor
            Log failed validations in table XX_CERIS_VALIDAT_ERRORS.
            Augment valid data and inserts them into staging table.
            Augmented data are to be inserted to Costpoint tables directly.
            See Costpoint tables EMPL, EMPL_LAB_INFO and DFLT_REG_TS.
            Called by XX_CERIS_RUN_INTERFACE.
Parameters: 
Result Set: None
Notes:

CR037       09/26/2006 Labor group type value (XX_CERIS_CP_STG.LAB_GRP_TYPE), derived from
            IMAPS.Deltek.ORG.L4_ORG_SEG_ID, is changed from 1 to 2 characters.

CP600000284 04/15/2008 (BP&S Change Request No. CR1543)
            Apply the Costpoint column COMPANY_ID to distinguish Division 16's data from those
            of Division 22's. There are five instances.

2010-09-20	1M changes

CR4885 - IMAPS CERIS Interface Changes for Actuals - KM - 2012-05-09
DR5779 - 'DEFALT' LCDB GLC effective date is overwritten when LCDB_EXTRACT is not run before CERIS - KM - 2013-01-15
CR5810 - CERIS retro timesheet miscodes: add check on org_acct links as part of CERIS dept validation - KM - 2013-01-15

CR6326 - T2R - KM - 2013-05-06
CR6293 - Div1P - KM - 2013-09-24

DR6905 - Exempt Rehire Temp to Full - KM - 2014-01-08

CR7366 - T2R 2014 - KM - 2014-07-15
CR7366 - T2R 2014 - KM - SIT BUG 2014-09-04
CR8761 - Div2G - gea - 2016-07-14  : just added 2G to list of divisions in one line below.
DR9291 - Div1P - gea - 2017-02-13  : inadvertently deleted IP when doing CR 8761
DR9291 - gea - 2/23/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
************************************************************************************************/

BEGIN
PRINT '' --DR9291
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --DR9291


	DECLARE @SP_NAME                   sysname,
			@DIV_16_COMPANY_ID         varchar(10),
			@S_EMPL_TYPE_CD            char(1),
			@LAB_GRP_TYPE              varchar(3),
			--@ADJ_PAY_FREQ              decimal(10, 8),
			@IMAPS_error_code          integer,
			@SQLServer_error_code      integer,
			@row_count                 integer,
			@error_msg_placeholder1    sysname,
			@error_msg_placeholder2    sysname,
			@error_type                integer,
			@ret_code                  integer

	-- set local constants
	SET @SP_NAME = 'XX_CERIS_VALIDATE_PREPARE_DATA_SP'

	PRINT 'Process Stage CERIS2 - Validate and transform CERIS data into CP staging tables ...'


	--
	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INITIALIZE LOCAL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'VARIABLES'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	-- CP600000284_Begin
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 105 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
	  FROM dbo.XX_PROCESSING_PARAMETERS
	 WHERE PARAMETER_NAME = 'COMPANY_ID'
	   AND INTERFACE_NAME_CD = 'CERIS'
	-- CP600000284_End

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

	-- verify that required input parameters are supplied
	IF @in_STATUS_RECORD_NUM IS NULL GOTO BL_ERROR_HANDLER



	--CR4885 begin
	-- verify that source data exist to continue processing
	--
	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY SOURCE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'DATA EXISTS'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	/*
	IF (select COUNT(1) from dbo.XX_CERIS_HIST) = 0 OR
	   (select COUNT(1) from dbo.XX_CERIS_BLUEPAGES_HIST) = 0
	   BEGIN
		  SET @error_type = 1
		  GOTO BL_ERROR_HANDLER
	   END
	*/

	IF (select COUNT(1) from XX_CERIS_HIST) = 0 OR
	   (select COUNT(1) from XX_CERIS_BLUEPAGES_HIST) = 0 OR
	   (select COUNT(1) from xx_ceris_lcdb_codes_stg) = 0 OR
	   (select COUNT(1) from xx_ceris_lcdb_empl_assignments_stg) = 0 
	   BEGIN
		  GOTO BL_ERROR_HANDLER
	   END
	/*
	 * Staging and error tables 
	 * are truncated in XX_CERIS_RETRIEVE_SOURCE_DATA_SP.
	 */

	--CR4885 end



	--CR4885 start
	--first, EXEMPT_DT is not what we thought it was
	--based on Gary Maltzman, Exempt Date is the YYYYMM of position change that caused move from N to E
	--when it moves from E to N, Exempt Date stays the same (it is only date of N to E)
	--so, we need some new logic to make the exempt date be what we actually think it is
	/*
	TODO: update EXEMPT_DT logic
	if current exempt flag is different from previous exempt flag, use current position date as current exempt date
	if exempt flag stayed the same, use previous exempt date as current exempt date
	if no previous values, use exempt date provided by ceris (hire date as default)
	*/

	--
	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE EXEMPT_DT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'for E to N changes'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 174 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	update xx_ceris_hist
	set exempt_dt=hire_eff_dt
	where exempt_dt is null

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 188 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	update xx_ceris_hist
	set exempt_dt=prev.exempt_dt
	from 
	xx_ceris_hist curr
	inner join
	xx_ceris_hist_previous prev
	on
	(curr.empl_id=prev.empl_id)
	where
	curr.flsa_stat=prev.flsa_stat

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 209 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	update xx_ceris_hist
	set exempt_dt=curr.pos_dt
	from 
	xx_ceris_hist curr
	inner join
	xx_ceris_hist_previous prev
	on
	(curr.empl_id=prev.empl_id)
	where
	curr.flsa_stat<>prev.flsa_stat  --position is what drives changes

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
	--CR4885 end



	-- Validate Employee ID
	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VALIDATE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'EMPL_ID'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 239 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	INSERT INTO dbo.XX_CERIS_VALIDAT_ERRORS(EMPL_ID, STATUS_RECORD_NUM, ERROR_DESC)
	   SELECT EMPL_ID, @in_STATUS_RECORD_NUM, ('EMPL ID value ' + EMPL_ID + ' is not alphanumeric.')
		FROM dbo.XX_CERIS_HIST
		WHERE PATINDEX('%[a-z0-9]%', EMPL_ID) = 0 -- pattern is not found

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER


	-- Validate INTERNET_ID
	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VALIDATE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'EMAIL_ID'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	-- change KM 02/02/06 select * from xx_ceris_bluepages_hist
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 260 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	INSERT 	INTO dbo.XX_CERIS_BLUEPAGES_HIST
	SELECT 	EMPL_ID, 'place.holder@us.ibm.com', CURRENT_TIMESTAMP
	FROM dbo.XX_CERIS_HIST
	WHERE EMPL_ID NOT IN (SELECT EMPL_ID FROM dbo.XX_CERIS_BLUEPAGES_HIST)

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER



	--legacy GLC logic
	--CR4885 begin
	/*
	GLC logic changed

	-- BEGIN CR31 CHANGE
	-- UPDATE GLC
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 282 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE 	dbo.XX_CERIS_HIST
	SET	JOB_FAM = SUBSTRING(cleared.IMAPS_GLC_CD, 1, 3),
		SAL_BAND = SUBSTRING(cleared.IMAPS_GLC_CD, 4, 2)
	FROM	dbo.XX_CERIS_HIST ceris
	INNER JOIN
		dbo.XX_CERIS_CLEARED_DEPARTMENTS cleared
	ON
	(
		ceris.JOB_FAM+ceris.SAL_BAND = cleared.CERIS_GLC_CD
	AND	ceris.DEPT = cleared.CERIS_DEPT
	)


	-- UPDATE GLC EFFECTIVE DATE
	-- DEPT_START_DT, LVL_DT_1, JOB_FAM_DT, PAY_DIFFERENTIAL_DT
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 300 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE dbo.XX_CERIS_HIST 
	SET JOB_FAM_DT = DEPT_START_DT 
	--1M changes
	WHERE PAY_DIFFERENTIAL+JOB_FAM+SAL_BAND in (SELECT IMAPS_GLC_CD FROM dbo.XX_CERIS_CLEARED_DEPARTMENTS)
	AND DEPT_START_DT > JOB_FAM_DT
	AND DEPT_START_DT > LVL_DT_1
	-- END CR31 CHANGE

	-- Validate GLC
	--1M changes
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 313 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	INSERT INTO dbo.XX_CERIS_VALIDAT_ERRORS
	   (EMPL_ID, STATUS_RECORD_NUM, ERROR_DESC)
	   SELECT EMPL_ID, @in_STATUS_RECORD_NUM, 'GLC code ' + (PAY_DIFFERENTIAL + JOB_FAM + SAL_BAND) + ' or GENL_AVG_RT_AMT is invalid.'
		 FROM dbo.XX_CERIS_HIST
		WHERE ((PAY_DIFFERENTIAL+JOB_FAM + SAL_BAND) NOT IN (SELECT GENL_LAB_CAT_CD FROM IMAPS.Deltek.GENL_LAB_CAT where COMPANY_ID = @DIV_16_COMPANY_ID) -- CP600000284
			   OR
			   (PAY_DIFFERENTIAL+JOB_FAM + SAL_BAND) IN (SELECT GENL_LAB_CAT_CD
										  FROM IMAPS.Deltek.GENL_LAB_CAT 
										 WHERE (GENL_AVG_RT_AMT < 0.0001 OR GENL_AVG_RT_AMT > 999999.9999)
										   AND COMPANY_ID = @DIV_16_COMPANY_ID -- CP600000284
									   )
			  )

	SET @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0
	   BEGIN
		  SET @error_type = 2
		  GOTO BL_ERROR_HANDLER
	   END
	*/

	--CR4885 end



	--CR4885 begin
	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'LOAD GENL_LAB_CAT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH VALID LCDB GLC CODES'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 348 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	insert into imaps.deltek.genl_lab_cat
	(genl_lab_cat_cd, genl_lab_cat_desc, modified_by, time_stamp, company_id, genl_avg_rt_amt, rowversion)
	select 
	GLC_Code as genl_lab_cat_cd,
	left(GLC_Short_Title,30) as genl_lab_cat_desc,
	suser_sname() as modified_by,
	getdate() as time_stamp,
	@DIV_16_COMPANY_ID as company_id,
	0.0000 as genl_avg_rt_amt,
	0 as rowversion
	from xx_ceris_lcdb_codes_stg lcdb
	where 
	0=(select count(1) from imaps.deltek.genl_lab_cat where genl_lab_cat_cd=lcdb.GLC_Code)

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 372 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	update imaps.deltek.genl_lab_cat
	set genl_lab_cat_desc=left(lcdb.GLC_Short_Title,30),
		modified_by=suser_sname(),
		time_stamp=getdate()
	from 
	imaps.deltek.genl_lab_cat glc
	inner join
	xx_ceris_lcdb_codes_stg lcdb
	on
	(glc.genl_lab_cat_cd=lcdb.GLC_Code)
	where
	glc.genl_lab_cat_desc<>left(lcdb.GLC_Short_Title,30)

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER



	--logic for LCDB DEFAULTS
	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'ASSIGN DEFALT GLC'
	SET @ERROR_MSG_PLACEHOLDER2 = 'TO EMPLOYEES WITHOUT LCDB ASSIGNMENT'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 403 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	INSERT INTO XX_CERIS_LCDB_EMPL_ASSIGNMENTS_DEFALTS
	(Emp_RecNo,
	SerialNo,
	StatusCode,
	Emp_StartDate,
	Emp_EndDate,
	GLC_RecNo,
	GLC_Code,
	EmpGLC_StartDate,
	EmpGLC_EndDate)
	SELECT
	0 as Emp_RecNo,
	EMPL_ID as SerialNo,
	'?' as StatusCode,
	convert(char(10),getdate(),120) as Emp_StartDate,
	convert(char(10),getdate(),120) as Emp_EndDate,
	0 as GLC_RecNo,
	'DEFALT' as GLC_Code,
	convert(char(10),getdate(),120) as EmpGLC_StartDate,
	convert(char(10),getdate(),120) as EmpGLC_EndDate
	FROM XX_CERIS_HIST ceris
	WHERE
	0=(select count(1) from XX_CERIS_LCDB_EMPL_ASSIGNMENTS_DEFALTS where SerialNo=ceris.EMPL_ID)
	and
	0=(select count(1) from XX_CERIS_LCDB_EMPL_ASSIGNMENTS_STG where SerialNo=ceris.EMPL_ID)

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER


	--delete where assignment now exists
	DELETE XX_CERIS_LCDB_EMPL_ASSIGNMENTS_DEFALTS
	FROM XX_CERIS_LCDB_EMPL_ASSIGNMENTS_DEFALTS defalt
	WHERE 
	--BEGIN DR5779
	--0<>(select count(1) from XX_CERIS_LCDB_EMPL_ASSIGNMENTS_STG where SerialNo=defalt.SerialNo)
	0<>(select count(1) from XX_CERIS_LCDB_EMPL_ASSIGNMENTS_STG where SerialNo=defalt.SerialNo and GLC_Code<>'DEFALT') 
	--only delete DEFALT when they are no longer needed
	--END DR5779

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER


	--insert defalts into assignments table
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 455 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	INSERT INTO XX_CERIS_LCDB_EMPL_ASSIGNMENTS_STG
	SELECT * 
	FROM XX_CERIS_LCDB_EMPL_ASSIGNMENTS_DEFALTS defalt
	WHERE
	0=(select count(1) from XX_CERIS_LCDB_EMPL_ASSIGNMENTS_STG where SerialNo=defalt.SerialNo) 

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER



	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VALIDATE GLC CODES'
	SET @ERROR_MSG_PLACEHOLDER2 = 'ONE LAST TIME'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 478 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	INSERT INTO dbo.XX_CERIS_VALIDAT_ERRORS
	   (EMPL_ID, STATUS_RECORD_NUM, ERROR_DESC)
	   SELECT ceris.EMPL_ID, @in_STATUS_RECORD_NUM, 'GLC code ' + isnull(lcdb.GLC_Code,'?') + ' is invalid.'
	   FROM XX_CERIS_HIST ceris
		   left join
		   XX_CERIS_LCDB_EMPL_ASSIGNMENTS_STG lcdb
		   on
		   (ceris.EMPL_ID=lcdb.SerialNo)
		WHERE 
		0=(select count(1) from imaps.deltek.genl_lab_cat where genl_lab_cat_cd=isnull(lcdb.GLC_Code,'?'))

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
	--CR4885 end



	-- Validate FLSA exemption
	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VALIDATE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FLSA_STAT'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 508 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	INSERT INTO dbo.XX_CERIS_VALIDAT_ERRORS(EMPL_ID, STATUS_RECORD_NUM, ERROR_DESC)
	   SELECT EMPL_ID, @in_STATUS_RECORD_NUM, 'FLSA_STAT ' + FLSA_STAT + ' is invalid.'
		FROM dbo.XX_CERIS_HIST
		WHERE isnull(FLSA_STAT,'') not in ('E','N')

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER



	-- Validate ORG_ID/DEPARTMENT
	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VALIDATE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'DEPT'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 531 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	INSERT INTO dbo.XX_CERIS_VALIDAT_ERRORS
	   (EMPL_ID, STATUS_RECORD_NUM, ERROR_DESC)
	   SELECT EMPL_ID, @in_STATUS_RECORD_NUM, 'DEPT ' + DEPT + ' does not exist in Costpoint.'
		 FROM dbo.XX_CERIS_HIST ceris
		--CR8761 begin
		--CR6293 begin
		--CR4885 begin WHERE DEPT NOT IN (SELECT ORG_ABBRV_CD FROM IMAPS.Deltek.ORG WHERE LEFT(ORG_ID,2)=ceris.DIVISION and ORG_ABBRV_CD<>'' and COMPANY_ID = @DIV_16_COMPANY_ID) -- CP600000284
		WHERE 1 <> (select count(1) 
		            FROM IMAPS.Deltek.ORG 
		            WHERE LEFT(ORG_ID,2)=replace(replace(ceris.DIVISION,'1P','16'),'2G','16') and
		            ORG_ABBRV_CD<>'' and 
					ORG_ABBRV_CD=ceris.DEPT and 
					COMPANY_ID = @DIV_16_COMPANY_ID)
		--incorporate check for dups
		--CR4885 end
		--CR6293 end
		--CR8761 end

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER



	--BEGIN CR5810
	-- Validate ORG_ID/DEPARTMENT FOR ORG_ACCT LINKS
	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VALIDATE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'DEPT ORG_ACCT LINKS'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 568 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	INSERT INTO dbo.XX_CERIS_VALIDAT_ERRORS
	   (EMPL_ID, STATUS_RECORD_NUM, ERROR_DESC)
	   SELECT EMPL_ID, @in_STATUS_RECORD_NUM, 'DEPT ' + DEPT + ' exists in Costpoint, but its org_acct links do not.'
		FROM dbo.XX_CERIS_HIST ceris
		inner join 
		imaps.deltek.org o
		on
		(o.ORG_ABBRV_CD<>'' and ceris.DEPT=o.ORG_ABBRV_CD)
		WHERE
		0=(select count(1) from imaps.deltek.org_acct where org_id=o.org_id)

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
	--END CR5810



	--CR4885 begin
	-- Validate Work State Code
	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VALIDATE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WORK STATE'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 599 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	INSERT INTO dbo.XX_CERIS_VALIDAT_ERRORS
	   (EMPL_ID, STATUS_RECORD_NUM, ERROR_DESC)
	   SELECT EMPL_ID, @in_STATUS_RECORD_NUM, 'Work State ' + WKLST + ' does not exist in Costpoint.'
		 FROM dbo.XX_CERIS_HIST ceris
		WHERE WKLST NOT IN (select STATE_CD from imaps.deltek.ot_rules_by_state)

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER


	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VALIDATE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'LAB_GRP_TYPE for DEPT'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 621 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	INSERT INTO dbo.XX_CERIS_VALIDAT_ERRORS
	   (EMPL_ID, STATUS_RECORD_NUM, ERROR_DESC)
	   SELECT EMPL_ID, @in_STATUS_RECORD_NUM, 'DEPT ' + DEPT + ' does not have a valid Labor Group in Costpoint.'
		 FROM dbo.XX_CERIS_HIST ceris
		WHERE DEPT IN
				(	select org_abbrv_cd
					from imaps.deltek.org
					where org_abbrv_cd<>''
					and LEFT(L4_ORG_SEG_ID, 2) not in
					 (select lab_grp_type
					 from imaps.deltek.lab_grp)
				)

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
	--CR4885 end



	--CR6293 begin
	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VALIDATE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'LAB_GRP_TYPE for DIV'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 653 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	INSERT INTO dbo.XX_CERIS_VALIDAT_ERRORS
	   (EMPL_ID, STATUS_RECORD_NUM, ERROR_DESC)
	   SELECT EMPL_ID, @in_STATUS_RECORD_NUM, 'DEPT ' + DEPT + ' is invalid for employees Division.'
		 FROM dbo.XX_CERIS_HIST ceris
		INNER JOIN
			  IMAPS.DELTEK.ORG o
		on
			(ceris.DEPT=o.org_abbrv_cd
			 and o.org_abbrv_cd<>'')
		WHERE
		--labor group and division are NOT in mapping
		0=(select count(1) from XX_CERIS_DIV_LAB_GRP_RULES_MAP where division=ceris.division and LAB_GRP_TYPE=LEFT(o.L4_ORG_SEG_ID, 2))
		and
		(
			--Division is in mapping ex:div=1P, lab_grp_type<>1Ptype
			0<>(select count(1) from XX_CERIS_DIV_LAB_GRP_RULES_MAP where division=ceris.division and LAB_GRP_TYPE<>LEFT(o.L4_ORG_SEG_ID, 2))
			or
			--Labor Group is in mapping ex:div<>1P, lab_grp_type=1Ptype
			0<>(select count(1) from XX_CERIS_DIV_LAB_GRP_RULES_MAP where division<>ceris.division and LAB_GRP_TYPE=LEFT(o.L4_ORG_SEG_ID, 2))
		)

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
	--CR6293 end



	PRINT 'Check validation results and determine processing status ...'
	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY VALID'
	SET @ERROR_MSG_PLACEHOLDER2 = 'RECORDS EXIST TO PROCESS'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	-- DEV00000244_begin
	/*
	 * This scenario: ALL input data did not pass validation due mostly to insufficient Costpoint data setup.
	 * Processing is halted here.
	 */

	DECLARE @source_rec_count integer, @bad_rec_count integer

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 700 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	SELECT @source_rec_count = COUNT(1) FROM dbo.XX_CERIS_HIST
	SELECT @bad_rec_count = COUNT(DISTINCT(EMPL_ID)) FROM dbo.XX_CERIS_VALIDAT_ERRORS

	IF (@source_rec_count > 0 AND @bad_rec_count > 0) AND (@source_rec_count = @bad_rec_count)
	   BEGIN
		  GOTO BL_ERROR_HANDLER
	   END
	-- DEV00000244_end


	SET @S_EMPL_TYPE_CD = 'R'
	SET @LAB_GRP_TYPE = 'TEMP'

/*	CR 4885 - no longer needed/used
	SELECT @ADJ_PAY_FREQ = DFLT_AUTOADJ_RT
	  FROM IMAPS.Deltek.TS_PD
	 WHERE TS_PD_CD = 'WKLY'
	   AND COMPANY_ID = @DIV_16_COMPANY_ID -- CP600000284

	SET @ADJ_PAY_FREQ = 52.0 * @ADJ_PAY_FREQ
*/



	--CR4885 begin
	--old logic commented out
	/*
	 * EXEMPT_DT is required in Costpoint. EXEMPT_DT is not required in CERIS.
	 * If EXEMPT_DT is null, substitute HIRE_EFF_DT.
	 * XX_CERIS_HIST.STAT3 may be null in which case substitute ''.
	 */

	/* mapping logic changes

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 737 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	INSERT INTO dbo.XX_CERIS_CP_STG
	   (EMPL_ID, LAST_NAME, FIRST_NAME, MID_NAME,
		ORIG_HIRE_DT, ADJ_HIRE_DT, TERM_DT,
		SPVSR_NAME,
		EMAIL_ID,
		JF_DT, POS_DT, DIVISION_START_DT, 
		DEPT_ST_DT, EMPL_STAT_DT, EMPL_STAT3_DT, LVL_DT_1,
		DEPT_DT, DEPT_SUF_DT, 
		EXEMPT_DT, 
		WORK_SCHD_DT, 
		HRLY_AMT, 
		SAL_AMT, 
		ANNL_AMT,
		EXMPT_FL, S_EMPL_TYPE_CD, ORG_ID, 
		TITLE_DESC,
		LAB_GRP_TYPE, 
		GENL_LAB_CAT_CD,
		REASON_DESC, 
		WORK_YR_HRS_NO,
		--1M changes
		SALSETID, WKLNEW, WKLCITY, WKLST, PAY_DIFFERENTIAL, PAY_DIFFERENTIAL_DT
		)
		SELECT
			a.EMPL_ID, a.LNAME, a.FNAME, a.NAME_INITIALS,
			a.HIRE_EFF_DT, a.IBM_START_DT, a.TERM_DT,
			CAST((a.MGR_LNAME + ',' + a.MGR_INITIALS) AS varchar(25)),
		CAST(b.INTERNET_ID AS varchar(60)),
			a.JOB_FAM_DT, a.POS_DT, a.DIVISION_START_DT,
		a.DEPT_START_DT, a.EMPL_STAT_DT, a.EMPL_STAT3_DT, a.LVL_DT_1,
			a.DEPT_START_DT, a.DEPT_SUF_DT,
			ISNULL(a.EXEMPT_DT, a.HIRE_EFF_DT),
		a.WORK_SCHD_DT,
		CAST(c.GENL_AVG_RT_AMT AS decimal(10, 4)),
		--bug fixed
		CAST((c.GENL_AVG_RT_AMT * 52.0 * a.STD_HRS / @ADJ_PAY_FREQ) AS decimal(10, 2)),
		CAST((c.GENL_AVG_RT_AMT * 52.0 * a.STD_HRS) AS decimal(10, 2)),
		a.FLSA_STAT, @S_EMPL_TYPE_CD, d.ORG_ID,
		CAST((a.POS_CODE + '-' + a.POS_DESC) AS varchar(30)),
		-- CR037_begin
		LEFT(d.L4_ORG_SEG_ID, 2),
		-- CR037_end
		--1M changes
		(a.PAY_DIFFERENTIAL + a.JOB_FAM + a.SAL_BAND),
			CAST((CAST(a.REG_TEMP AS varchar(5)) + a.STATUS + ISNULL(a.STAT3, '')) AS varchar(30)),
		(52.0 * a.STD_HRS),
		--1M changes
		a.SALSETID, a.WKLNEW, a.WKLCITY, a.WKLST, a.PAY_DIFFERENTIAL, a.PAY_DIFFERENTIAL_DT

	   FROM dbo.XX_CERIS_HIST a,
			dbo.XX_CERIS_BLUEPAGES_HIST b,
			IMAPS.Deltek.GENL_LAB_CAT c,
			IMAPS.Deltek.ORG d
	  WHERE a.EMPL_ID = b.EMPL_ID
		AND (a.PAY_DIFFERENTIAL + a.JOB_FAM + a.SAL_BAND) = c.GENL_LAB_CAT_CD
		AND a.DEPT = d.ORG_ABBRV_CD
		AND a.EMPL_ID not in (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)
	-- CP600000284_begin
		AND c.COMPANY_ID = d.COMPANY_ID
		AND d.COMPANY_ID = @DIV_16_COMPANY_ID
	-- CP600000284_end

	SET @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0
	   BEGIN
		  SET @error_type = 3
		  GOTO BL_ERROR_HANDLER
	   END



	-- Augment FLSA
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 811 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE dbo.XX_CERIS_CP_STG
	   SET EXMPT_FL = 'Y'
	 WHERE EXMPT_FL = 'E'

	SET @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0
	   BEGIN
		  SET @error_type = 4
		  GOTO BL_ERROR_HANDLER
	   END

	-- Augment S_EMPL_TYPE_CD
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 826 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE dbo.XX_CERIS_CP_STG
	   SET S_EMPL_TYPE_CD = 'P' 
	 WHERE EMPL_ID in (SELECT EMPL_ID FROM dbo.XX_CERIS_HIST WHERE STAT3 = '5')

	SET @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0
	   BEGIN
		  SET @error_type = 4
		  GOTO BL_ERROR_HANDLER
	   END

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 842 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE dbo.XX_CERIS_CP_STG
	   SET S_EMPL_TYPE_CD = CASE S_EMPL_TYPE_CD
							   WHEN '1' THEN 'R'
							   WHEN '4' THEN 'P'
							   WHEN '3' THEN 'T'
							   ELSE 'R'
							END

	*/

	--CR4885 end

	-- CR037_begin
	-- For CR037, disable this UPDATE statement and make the change in the INSERT INTO dbo.XX_CERIS_CP_STG above.
	/*
	-- CHANGE KM 12/9/05
	-- LAB_GRP_TYPE MUST BE 1 CHARACTER, NOT 3
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 861 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE 	dbo.XX_CERIS_CP_STG
	SET 	LAB_GRP_TYPE = SUBSTRING(LAB_GRP_TYPE, 1, 1)
	-- END CHANGE KM 12/9/05

	SET @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0
	   BEGIN
		  SET @error_type = 4
		  GOTO BL_ERROR_HANDLER
	   END
	*/

	-- CR037_end



	--CR4885 begin
	
	--new logic for different number of weekdays in year
	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'CALCULATE NUMBER OF WEEKDAYS'
	SET @ERROR_MSG_PLACEHOLDER2 = 'IN CURRENT YEAR'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	declare @curr_year char(4)
	select @curr_year = cast(datepart(year,getdate()) as char(4))

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
	if @curr_year is null GOTO BL_ERROR_HANDLER

	declare @prev_week_days_in_current_year int
	select @prev_week_days_in_current_year = cast(parameter_value as int)
	from xx_processing_parameters 
	where interface_name_cd='CERIS'
	and parameter_name='week_days_in_current_year'
		
 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
	if @prev_week_days_in_current_year is null GOTO BL_ERROR_HANDLER

	declare @curr_week_days_in_current_year int,
			@curr_year_start datetime,
			@curr_year_end datetime

	set @curr_year_start = cast(@curr_year+'-01-01' as datetime)
	set @curr_year_end =  cast(@curr_year+'-12-31' as datetime)
		
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 917 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	select @curr_week_days_in_current_year = dbo.XX_GET_week_days_in_period_UF(@curr_year_start,@curr_year_end)

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
	if @curr_week_days_in_current_year is null GOTO BL_ERROR_HANDLER

	--IF week days in current year changed, then we must update the parameters accordingly
	IF @curr_week_days_in_current_year <> @prev_week_days_in_current_year
	BEGIN
		UPDATE XX_PROCESSING_PARAMETERS
		SET PARAMETER_VALUE=cast(@curr_week_days_in_current_year as varchar)
		where interface_name_cd='CERIS'
		and parameter_name='week_days_in_current_year'
			
 
 
		SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
		IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 943 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
		UPDATE XX_PROCESSING_PARAMETERS
		SET PARAMETER_VALUE=cast(@curr_year+'-01-01' as varchar)
		where interface_name_cd='CERIS'
		and parameter_name='min_SAL_HRS_CHANGE_EFFECT_DT'

 
 
		SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
		IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
	END

	DECLARE @WORK_WEEKS_IN_YEAR decimal(14,2)

	IF @curr_week_days_in_current_year = 260
	BEGIN
		SET @WORK_WEEKS_IN_YEAR = 52.0
	END
	IF @curr_week_days_in_current_year = 261
	BEGIN
		SET @WORK_WEEKS_IN_YEAR = 52.2
	END
	IF @curr_week_days_in_current_year = 262
	BEGIN
		SET @WORK_WEEKS_IN_YEAR = 52.4
	END

	IF @WORK_WEEKS_IN_YEAR IS NULL GOTO BL_ERROR_HANDLER


	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT XX_CERIS_HIST'
	SET @ERROR_MSG_PLACEHOLDER2 = 'INTO XX_CERIS_SP_STG'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 982 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
		INSERT INTO dbo.XX_CERIS_CP_STG
	   (EMPL_ID, LAST_NAME, FIRST_NAME, MID_NAME,
		ORIG_HIRE_DT, ADJ_HIRE_DT, TERM_DT,
		SPVSR_NAME, EMAIL_ID,

		JF_DT, POS_DT, DIVISION_START_DT, DEPT_ST_DT,  
		EMPL_STAT_DT, EMPL_STAT3_DT, 
		LVL_DT_1, DEPT_DT, DEPT_SUF_DT, EXEMPT_DT, WORK_SCHD_DT, 

		HRLY_AMT, 
		SAL_AMT, 
		ANNL_AMT,

		EXMPT_FL, 
		S_HRLY_SAL_CD,
		S_EMPL_TYPE_CD, 

		ORG_ID, 
		TITLE_DESC,
		LAB_GRP_TYPE, 
		GENL_LAB_CAT_CD,LCDB_GLC_EFFECTIVE_DT,
		REASON_DESC, 
		WORK_YR_HRS_NO,
		SALSETID, WKLNEW, WKLCITY, WKLST, PAY_DIFFERENTIAL, PAY_DIFFERENTIAL_DT,

		WKL_DT, SALARY_DT, WORK_STATE_CD, REASON_DESC_3
		)
		SELECT
		ceris.EMPL_ID as EMPL_ID, ceris.LNAME as LAST_NAME, ceris.FNAME as FIRST_NAME, ceris.NAME_INITIALS as MID_NAME,
		ceris.HIRE_EFF_DT as ORIG_HIRE_DT, ceris.IBM_START_DT as ADJ_HIRE_DT, ceris.TERM_DT as TERM_DT,

		CAST((ceris.MGR_LNAME + ',' + ceris.MGR_INITIALS) AS varchar(25)) as SPVSR_NAME, CAST(b.INTERNET_ID AS varchar(60)) as EMAIL_ID,

		ceris.JOB_FAM_DT as JF_DT, ceris.POS_DT, ceris.DIVISION_START_DT, ceris.DEPT_START_DT, 
		ceris.EMPL_STAT_DT, ceris.EMPL_STAT3_DT, 
		ceris.LVL_DT_1, ceris.DEPT_START_DT, ceris.DEPT_SUF_DT, ceris.EXEMPT_DT as EXEMPT_DT, ceris.WORK_SCHD_DT,
			
		--will update these after insert
		1.00 as HRLY_AMT,
		1.00 as SAL_AMT,
		1.00 as ANNL_AMT, 


		CASE 
			WHEN ceris.FLSA_STAT='E' then 'Y'
			WHEN ceris.FLSA_STAT='N' then 'N'
			ELSE '?'
		END as EXMPT_FL, 

		CASE 
			WHEN ceris.FLSA_STAT='E' then 'S'
			WHEN ceris.FLSA_STAT='N' then 'H'
			ELSE '?'
		END as S_HRLY_SAL_CD, 

		CASE
			WHEN ceris.REG_TEMP='1' then 'R'
			WHEN ceris.REG_TEMP='4' or isnull(ceris.STAT3,'')='5' then 'P'
			WHEN ceris.REG_TEMP='3' then 'T'
			ELSE 'R'
		END as S_EMPL_TYPE_CD,

		o.ORG_ID,
		CAST((ceris.POS_CODE + '-' + ceris.POS_DESC) AS varchar(30)) as TITLE_DESC,
		LEFT(o.L4_ORG_SEG_ID, 2) as LAB_GRP_TYPE,

		lcdb.GLC_Code as GENL_LAB_CAT_CD,
		lcdb.EmpGLC_StartDate as LCDB_GLC_EFFECTIVE_DT,

		CAST((CAST(ceris.REG_TEMP AS varchar(5)) + ceris.STATUS + ISNULL(ceris.STAT3, '')) AS varchar(30)) as REASON_DESC,

		(@WORK_WEEKS_IN_YEAR * ceris.STD_HRS) as WORK_YR_HRS_NO,

		ceris.SALSETID, ceris.WKLNEW, ceris.WKLCITY, ceris.WKLST, ceris.PAY_DIFFERENTIAL, ceris.PAY_DIFFERENTIAL_DT,

		ceris.WKL_DT, ceris.SALARY_DT, ceris.WKLST as WORK_STATE_CD, (ceris.PAY_DIFFERENTIAL + ceris.JOB_FAM + ceris.SAL_BAND) as REASON_DESC_3

	   FROM 
		   XX_CERIS_HIST ceris
		   inner join
		   XX_CERIS_BLUEPAGES_HIST b
		   on
		   (ceris.EMPL_ID=b.EMPL_ID)
		   inner join
		   XX_CERIS_LCDB_EMPL_ASSIGNMENTS_STG lcdb
		   on
		   (ceris.EMPL_ID=lcdb.SerialNo)
			inner join
			IMAPS.DELTEK.ORG o
			on
			(ceris.DEPT=o.ORG_ABBRV_CD and o.COMPANY_ID=@DIV_16_COMPANY_ID)
	  WHERE 
		ceris.EMPL_ID not in (SELECT EMPL_ID FROM dbo.XX_CERIS_VALIDAT_ERRORS)


 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER



	--cases where CERIS standard hours may not be weekly
	--could cause problems for the daily salary calculation
	--need to re-visit this
	--perhaps table-driven override for this?
	/*
	use imapsstg
	select empl_id, reg_temp, status, stat3, flsa_stat, pos_code, pos_desc, std_hrs
	from xx_ceris_hist ceris
	where term_dt is null
	and
		ceris.REG_TEMP='3' and ceris.FLSA_STAT='E' and isnull(ceris.STAT3,'')<>'2'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1100 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	select emp_serial_num, ts_week_end_Date, sum(cast(reg_time as decimal(14,2)))
	from xx_et_daily_in
	where emp_serial_num in
	(select empl_id 
	from xx_ceris_hist ceris
	where term_dt is null
	and
		ceris.REG_TEMP='3' and ceris.FLSA_STAT='E' and isnull(ceris.STAT3,'')<>'2'
	)
	group by emp_serial_num, ts_week_end_Date
	*/

	--CR4885 end

	PRINT 'Performing Standard Hours change for special cases ....'


	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE SPECIAL FLAVOR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'STD_HRS'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	PRINT 'Daily - Exempt, Supplemental, Not Long Term, Full Time'
	--Exempt, Supplemental, Not Long Term, Full Time
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1126 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE XX_CERIS_CP_STG
	SET WORK_YR_HRS_NO=ceris.STD_HRS*special.DAYS_PER_WEEK*@WORK_WEEKS_IN_YEAR --fix for jeff
	FROM 
		XX_CERIS_CP_STG cp
		inner join
		XX_CERIS_HIST ceris
		on
		(cp.empl_id=ceris.empl_id)
		inner join
		XX_CERIS_SPECIAL_FLAVORS special
		on
		(
			--transform daily hours to weekly
			(special.DATACOL_NAME='STD_HRS' AND special.FLAVOR='DAILY_FULL' 
			AND special.REG_TEMP=ceris.REG_TEMP and special.FLSA_STAT=ceris.FLSA_STAT and special.NOT_STAT3<>isnull(ceris.STAT3,'')
			AND special.STAT3=ceris.STAT3)
		)

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER


	--Exempt, Supplemental, Not Long Term, Full Time
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1154 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE XX_CERIS_HIST
	SET STD_HRS=ceris.STD_HRS*special.DAYS_PER_WEEK
	FROM 
		XX_CERIS_CP_STG cp
		inner join
		XX_CERIS_HIST ceris
		on
		(cp.empl_id=ceris.empl_id)
		inner join
		XX_CERIS_SPECIAL_FLAVORS special
		on
		(
			--transform daily hours to weekly
			(special.DATACOL_NAME='STD_HRS' AND special.FLAVOR='DAILY_FULL' 
			AND special.REG_TEMP=ceris.REG_TEMP and special.FLSA_STAT=ceris.FLSA_STAT and special.NOT_STAT3<>isnull(ceris.STAT3,'')
			AND special.STAT3=ceris.STAT3)
		)

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER



	PRINT 'Performing Salary calculation ...'


--CR7366 begin
	--need to apply this factor before the calculation starts
	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'APPLY SALARY_FACTOR TO'
	SET @ERROR_MSG_PLACEHOLDER2 = 'SALARY FOR T2R EMPLOYEES'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1194 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE ceris
	SET SALARY=ceris.SALARY * t2r.SALARY_FACTOR,
		SALARY_DT=t2r.EFFECT_DT
	FROM 
	XX_CERIS_HIST ceris
	INNER JOIN
	XX_CERIS_T2R_EMPLOYEES_SALARY_FACTOR t2r
	on
	(ceris.empl_id=t2r.empl_id)

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
--CR7366 end
--CR7366 SIT BUG begin
	--need to update the SALARY_DT value in this staging table
	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'APPLY SALARY_FACTOR DATE TO'
	SET @ERROR_MSG_PLACEHOLDER2 = 'CP_STG FOR T2R EMPLOYEES'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1221 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE cp_stg
	SET SALARY_DT=t2r.EFFECT_DT
	FROM 
	XX_CERIS_CP_STG cp_stg
	INNER JOIN
	XX_CERIS_T2R_EMPLOYEES_SALARY_FACTOR t2r
	on
	(cp_stg.empl_id=t2r.empl_id)

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
--CR7366 SIT BUG end



	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE SPECIAL FLAVOR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'SALARY'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	PRINT 'Daily - Exempt, Supplemental, Not Long Term, Full Time...'
	--daily salary provided in CERIS
	--Exempt, Supplemental, Not Long Term, Full Time
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1249 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE XX_CERIS_CP_STG
	SET	
	ANNL_AMT = ceris.SALARY * ((ceris.STD_HRS / 8.0) * @WORK_WEEKS_IN_YEAR),	-- salary/day * ((hours/week * day/hours) * week/year) = salary/year
	SAL_AMT =  ceris.SALARY * (ceris.STD_HRS / 8.0),			-- salary/day * (hours/week * day/hours) = salary/week
	HRLY_AMT = ceris.SALARY * (ceris.STD_HRS / 8.0) / ceris.STD_HRS	-- salary/day * (hours/week * day/hours) * week/hours = salary/hour
	FROM 
		XX_CERIS_CP_STG cp
		inner join
		XX_CERIS_HIST ceris
		on
		(cp.empl_id=ceris.empl_id)
	WHERE
	--Exempt, Supplemental, Not Long Term, Full Time
			0<>(select count(1) from XX_CERIS_SPECIAL_FLAVORS 
				where DATACOL_NAME='SALARY' AND FLAVOR='DAILY_FULL' AND REG_TEMP=ceris.REG_TEMP and FLSA_STAT=ceris.FLSA_STAT and NOT_STAT3<>isnull(ceris.STAT3,'') 
				AND STAT3=ceris.STAT3)

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER



	PRINT 'Daily - Exempt, Supplemental, Not Long Term, NOT Full Time (PART TIME)...'
	--daily salary provided in CERIS
	--Exempt, Supplemental, Not Long Term, NOT Full Time (PART TIME)
	--assumes 1 day a week (since they are part time, don't know how many days a week they work)
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1280 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE XX_CERIS_CP_STG
	SET	   ANNL_AMT = ceris.SALARY * @WORK_WEEKS_IN_YEAR,            -- amt/year = amt/day * 1 day/week * week/year
		   SAL_AMT  = ceris.SALARY,                   -- amt/week = amt/week * 1 day/week
		   HRLY_AMT = ceris.SALARY / ceris.STD_HRS    -- amt/hr = (amt/day) / (hr/day)
	FROM 
		XX_CERIS_CP_STG cp
		inner join
		XX_CERIS_HIST ceris
		on
		(cp.empl_id=ceris.empl_id)
	WHERE
	--NOT (Exempt, Supplemental, Not Long Term, Full Time)
			0=(select count(1) from XX_CERIS_SPECIAL_FLAVORS 
				where DATACOL_NAME='SALARY' AND FLAVOR='DAILY_FULL' AND REG_TEMP=ceris.REG_TEMP and FLSA_STAT=ceris.FLSA_STAT and NOT_STAT3<>isnull(ceris.STAT3,'') 
				AND STAT3=ceris.STAT3)
	and
	-- Exempt, Supplemental, Not Long Term, PART TIME
			0<>(select count(1) from XX_CERIS_SPECIAL_FLAVORS 
				where DATACOL_NAME='SALARY' AND FLAVOR='DAILY_PART' AND REG_TEMP=ceris.REG_TEMP and FLSA_STAT=ceris.FLSA_STAT and NOT_STAT3<>isnull(ceris.STAT3,'') 
				AND STAT3='*')


 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER



	Print 'Hourly ...'
	--hourly salary provided in CERIS
	--NonExempt, Supplemental, Not Long Term
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1314 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE XX_CERIS_CP_STG
	SET	
	ANNL_AMT = SALARY * ceris.STD_HRS * @WORK_WEEKS_IN_YEAR,	-- salary/hour * hours/week * week/year = salary/year
	SAL_AMT =  SALARY * ceris.STD_HRS,			-- salary/hour * hours/week = salary/week
	HRLY_AMT = SALARY							-- salary/hour
	FROM 
		XX_CERIS_CP_STG cp
		inner join
		XX_CERIS_HIST ceris
		on
		(cp.empl_id=ceris.empl_id)
	WHERE
	--NonExempt, Supplemental, Not Long Term
			0<>(select count(1) from XX_CERIS_SPECIAL_FLAVORS 
				where DATACOL_NAME='SALARY' AND FLAVOR='HOURLY' AND REG_TEMP=ceris.REG_TEMP and FLSA_STAT=ceris.FLSA_STAT and NOT_STAT3<>isnull(ceris.STAT3,'')
				AND STAT3='*')

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER



	Print 'Monthly normal ...'
	--monthly salary provided in CERIS
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1343 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE XX_CERIS_CP_STG
	SET	
	ANNL_AMT = ceris.SALARY * 12.0,			-- salary/month * month/year = salary/year
	SAL_AMT =  ceris.SALARY * 12.0/ @WORK_WEEKS_IN_YEAR,	-- salary/month * month/year * year/week = salary/week
	HRLY_AMT = (ceris.SALARY * 12.0/ @WORK_WEEKS_IN_YEAR) / ceris.STD_HRS -- salary/month * month/year * year/week * week/hour = salary/hour
	FROM 
		XX_CERIS_CP_STG cp
		inner join
		XX_CERIS_HIST ceris
		on
		(cp.empl_id=ceris.empl_id)
	WHERE
	--Regular (Monthly Salary, Weekly Hours)
	--NOT special cases
	--NOT (Exempt, Supplemental, Not Long Term, Full Time)
			0=(select count(1) from XX_CERIS_SPECIAL_FLAVORS 
				where DATACOL_NAME='SALARY' AND FLAVOR='DAILY_FULL' AND REG_TEMP=ceris.REG_TEMP and FLSA_STAT=ceris.FLSA_STAT and NOT_STAT3<>isnull(ceris.STAT3,'') 
				AND STAT3=ceris.STAT3)
	and
	--NOT (NonExempt, Supplemental, Not Long Term)
			0=(select count(1) from XX_CERIS_SPECIAL_FLAVORS 
				where DATACOL_NAME='SALARY' AND FLAVOR in ('HOURLY') AND REG_TEMP=ceris.REG_TEMP and FLSA_STAT=ceris.FLSA_STAT and NOT_STAT3<>isnull(ceris.STAT3,'') 
				AND STAT3='*')
	and
	--NOT (Exempt, Supplemental, Not Long Term, PART TIME)
			0=(select count(1) from XX_CERIS_SPECIAL_FLAVORS 
				where DATACOL_NAME='SALARY' AND FLAVOR='DAILY_PART' AND REG_TEMP=ceris.REG_TEMP and FLSA_STAT=ceris.FLSA_STAT and NOT_STAT3<>isnull(ceris.STAT3,'') 
				AND STAT3='*')

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER



	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE SPECIAL FLAVOR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'HOURLY CODE for E,S,NT,PT'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	PRINT 'Special case logic for Exempt, Supplemental, Not Long Term, Part Time'

	/*
	more special case logic related to 
	 (Exempt, Supplemental, Not Long Term, PART TIME)
	and
	(Exempt, Supplemental, Not Long Term, Full Time)
	*/

	--need to treat (Exempt, Supplemental, Not Long Term, PART TIME) as hourly
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1396 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE XX_CERIS_CP_STG
	SET	
	S_HRLY_SAL_CD='H'
	FROM 
		XX_CERIS_CP_STG cp
		inner join
		XX_CERIS_HIST ceris
		on
		(cp.empl_id=ceris.empl_id)
	WHERE
	--NOT (Exempt, Supplemental, Not Long Term, Full Time)
			0=(select count(1) from XX_CERIS_SPECIAL_FLAVORS 
				where DATACOL_NAME='SALARY' AND FLAVOR='DAILY_FULL' AND REG_TEMP=ceris.REG_TEMP and FLSA_STAT=ceris.FLSA_STAT and NOT_STAT3<>isnull(ceris.STAT3,'') 
				AND STAT3=ceris.STAT3)
	and
	-- Exempt, Supplemental, Not Long Term, PART TIME
			0<>(select count(1) from XX_CERIS_SPECIAL_FLAVORS 
				where DATACOL_NAME='SALARY' AND FLAVOR='DAILY_PART' AND REG_TEMP=ceris.REG_TEMP and FLSA_STAT=ceris.FLSA_STAT and NOT_STAT3<>isnull(ceris.STAT3,'') 
				AND STAT3='*')

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER


	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE SPECIAL FLAVOR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'EXMPT_DT for E,S,NT,PT'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	--argghghgh
	--need to capture effective date changes for stat3 between Full Time and Part Time
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1432 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE XX_CERIS_HIST
	SET EXEMPT_DT=isnull(curr.EMPL_STAT3_DT,curr.EMPL_STAT_DT)
	FROM 
	XX_CERIS_HIST curr
	inner join
	XX_CERIS_HIST_PREVIOUS prev
	on
	(curr.empl_id=prev.empl_id)
	WHERE
	(
		(
		--Previously was (Exempt, Supplemental, Not Long Term, PART TIME)
			--NOT (Exempt, Supplemental, Not Long Term, Full Time)
			0=(select count(1) from XX_CERIS_SPECIAL_FLAVORS 
				where DATACOL_NAME='SALARY' AND FLAVOR='DAILY_FULL' AND REG_TEMP=prev.REG_TEMP and FLSA_STAT=prev.FLSA_STAT and NOT_STAT3<>isnull(prev.STAT3,'') 
				AND STAT3=prev.STAT3)
			and
			-- Exempt, Supplemental, Not Long Term, PART TIME
			0<>(select count(1) from XX_CERIS_SPECIAL_FLAVORS 
				where DATACOL_NAME='SALARY' AND FLAVOR='DAILY_PART' AND REG_TEMP=prev.REG_TEMP and FLSA_STAT=prev.FLSA_STAT and NOT_STAT3<>isnull(prev.STAT3,'') 
				AND STAT3='*')
			and
		--Currently is Exempt (either Regular type or Supplemental, Not Long Term, Full Time type)
			(
				(curr.FLSA_STAT='E' and curr.REG_TEMP<>'3') --DR6905
				or
				0<>(select count(1) from XX_CERIS_SPECIAL_FLAVORS 
					where DATACOL_NAME='SALARY' AND FLAVOR='DAILY_FULL' AND REG_TEMP=curr.REG_TEMP and FLSA_STAT=curr.FLSA_STAT and NOT_STAT3<>isnull(curr.STAT3,'') 
					AND STAT3=curr.STAT3)
			)
		)
		or
		(
		--Currently is (Exempt, Supplemental, Not Long Term, PART TIME)
			--NOT (Exempt, Supplemental, Not Long Term, Full Time)
			0=(select count(1) from XX_CERIS_SPECIAL_FLAVORS 
				where DATACOL_NAME='SALARY' AND FLAVOR='DAILY_FULL' AND REG_TEMP=curr.REG_TEMP and FLSA_STAT=curr.FLSA_STAT and NOT_STAT3<>isnull(curr.STAT3,'') 
				AND STAT3=curr.STAT3)
			and
			-- Exempt, Supplemental, Not Long Term, PART TIME
			0<>(select count(1) from XX_CERIS_SPECIAL_FLAVORS 
				where DATACOL_NAME='SALARY' AND FLAVOR='DAILY_PART' AND REG_TEMP=curr.REG_TEMP and FLSA_STAT=curr.FLSA_STAT and NOT_STAT3<>isnull(curr.STAT3,'') 
				AND STAT3='*')
			and
		--Previously was Exempt (either Regular type or Supplemental, Not Long Term, Full Time type)
			(
				(prev.FLSA_STAT='E' and prev.REG_TEMP<>'3')  --DR6905
				or
				0<>(select count(1) from XX_CERIS_SPECIAL_FLAVORS 
					where DATACOL_NAME='SALARY' AND FLAVOR='DAILY_FULL' AND REG_TEMP=prev.REG_TEMP and FLSA_STAT=prev.FLSA_STAT and NOT_STAT3<>isnull(prev.STAT3,'') 
					AND STAT3=prev.STAT3)
			)
		)
	)


 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER



	--update EXEMPT_DT for change
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1498 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE XX_CERIS_CP_STG
	SET EXEMPT_DT=ceris.EXEMPT_DT
	from
	XX_CERIS_CP_STG cp
	inner join
	XX_CERIS_HIST ceris
	on
	(cp.empl_id=ceris.empl_id)
	where cp.EXEMPT_DT<>ceris.EXEMPT_DT


 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER



	--CR6326 begin	
	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE XX_CERIS_CP_STG'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR T2R employees'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1526 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE XX_CERIS_CP_STG
	SET	S_HRLY_SAL_CD='H',
		SALARY_DT=t2r.EFFECT_DT,
		HRLY_AMT=t2r.HRLY_AMT,
		ANNL_AMT=t2r.HRLY_AMT * cast(WORK_YR_HRS_NO as int),
		SAL_AMT=(t2r.HRLY_AMT * cast(WORK_YR_HRS_NO as int))/ @WORK_WEEKS_IN_YEAR
	FROM XX_CERIS_CP_STG ceris
	INNER JOIN
	XX_CERIS_T2R_EMPLOYEES t2r
	on
	(ceris.empl_id=t2r.empl_id)
	

 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER
	--CR6326 end



	--CR4885 begin
	--TODO update effective dates to min of '2013-01-01' (or '2012-12-29' or parameter or whatever)
	--then update insert and update procedures
	--for update procedure, make sure not to roll forward effective date changes for '2013-01-01'(or '2012-12-29' or parameter or whatever)
	--use new mappings for EMPL_LAB_INFO, etc

	PRINT 'Updating Costpoint Effective Dates related to mapping changes for Actuals ...'
	/*
		JF_DT, POS_DT, DIVISION_START_DT, 
		DEPT_ST_DT, EMPL_STAT_DT, EMPL_STAT3_DT, LVL_DT_1,
		DEPT_DT, DEPT_SUF_DT, EXEMPT_DT, WORK_SCHD_DT, 
		PAY_DIFFERENTIAL_DT,
		WKL_DT, SALARY_DT
	*/

	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE XX_CERIS_CP_STG'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR MIN ACTUALS_EFFECT_DT'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2


	DECLARE @Actuals_EFFECT_DT smalldatetime

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1573 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	select @Actuals_EFFECT_DT = cast(parameter_value as smalldatetime)
	from xx_processing_parameters
	where interface_name_cd='CERIS'
	and parameter_name='Actuals_EFFECT_DT'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1583 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE XX_CERIS_CP_STG SET SALARY_DT=@Actuals_EFFECT_DT 
	WHERE SALARY_DT is null or SALARY_DT<@Actuals_EFFECT_DT

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1596 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE XX_CERIS_CP_STG SET WORK_SCHD_DT=@Actuals_EFFECT_DT 
	WHERE WORK_SCHD_DT is null or WORK_SCHD_DT<@Actuals_EFFECT_DT

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1609 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE XX_CERIS_CP_STG SET WKL_DT=@Actuals_EFFECT_DT 
	WHERE WKL_DT is null or WKL_DT<@Actuals_EFFECT_DT
	  
 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1622 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE XX_CERIS_CP_STG SET EXEMPT_DT=@Actuals_EFFECT_DT 
	WHERE EXEMPT_DT is null or EXEMPT_DT<@Actuals_EFFECT_DT
	  
 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1635 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE XX_CERIS_CP_STG SET LCDB_GLC_EFFECTIVE_DT=@Actuals_EFFECT_DT
	WHERE LCDB_GLC_EFFECTIVE_DT is null or LCDB_GLC_EFFECTIVE_DT<@Actuals_EFFECT_DT

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER



	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE XX_CERIS_CP_STG'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR min_SAL_HRS_CHANGE_EFFECT_DT'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2


	DECLARE @min_SAL_HRS_CHANGE_EFFECT_DT smalldatetime

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1658 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	select @min_SAL_HRS_CHANGE_EFFECT_DT = cast(parameter_value as smalldatetime)
	from xx_processing_parameters
	where interface_name_cd='CERIS'
	and parameter_name='min_SAL_HRS_CHANGE_EFFECT_DT'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1668 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE XX_CERIS_CP_STG SET SALARY_DT=@min_SAL_HRS_CHANGE_EFFECT_DT 
	WHERE SALARY_DT is null or SALARY_DT<@min_SAL_HRS_CHANGE_EFFECT_DT

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1681 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	UPDATE XX_CERIS_CP_STG SET WORK_SCHD_DT=@min_SAL_HRS_CHANGE_EFFECT_DT 
	WHERE WORK_SCHD_DT is null or WORK_SCHD_DT<@min_SAL_HRS_CHANGE_EFFECT_DT

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER



	SET @IMAPS_error_code = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'BACKUP EMPL_LAB_INFO'
	SET @ERROR_MSG_PLACEHOLDER2 = 'BEFORE WE GO TO NEXT CP'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	--backup EMPL_LAB_INFO
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 1700 : XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql '  --DR9291
 
	EXEC @ret_code = dbo.XX_CERIS_BACKUP_EMPL_LAB_INFO_SP
			 @in_STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM,
			 @out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO BL_ERROR_HANDLER

	IF @ret_code <> 0 GOTO BL_ERROR_HANDLER 
	--CR4885 end



PRINT '' --DR9291
PRINT '*~^*************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF  XX_CERIS_VALIDATE_PREPARE_DATA_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --DR9291
RETURN(0)

BL_ERROR_HANDLER:

--CR4885 redesign
/*
IF @error_type = 1
   BEGIN
      SET @IMAPS_error_code = 209 -- No %1 exist to %2 
	  --CR4885 begin
      --SET @error_msg_placeholder1 = 'ETIME..INTERIM.IBM_CERIS or ETIME..INTERIM.IBM_BCS data'
      SET @error_msg_placeholder1 = 'staging data'
	  --CR4885 end
      SET @error_msg_placeholder2 = 'perform validation.'
   END
ELSE IF @error_type = 2
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to insert a record into table XX_CERIS_VALIDAT_ERRORS failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'a record into table XX_CERIS_VALIDAT_ERRORS'
   END
ELSE IF @error_type = 3
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to insert a record into table XX_CERIS_CP_STG failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'a record into table XX_CERIS_CP_STG'
   END
ELSE IF @error_type = 4
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to update records in table XX_CERIS_CP_STG failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'records in table XX_CERIS_CP_STG'
   END
-- DEV00000244_begin
ELSE IF @error_type = 5
   BEGIN
      SET @status_error_code = 210
      SET @IMAPS_error_code = 210 -- %1 failed validation due to %2.
      SET @error_msg_placeholder1 = 'All source CERIS_HIST input records'
      SET @error_msg_placeholder2 = 'insufficient Costpoint data setup'
      SET @SQLServer_error_code = NULL
   END
-- DEV00000244_end
--CR4885 begin
ELSE IF @error_type = 6
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to update records in table XX_CERIS_CP_STG failed.
      SET @error_msg_placeholder1 = 'Load GENL_LAB_CAT'
      SET @error_msg_placeholder2 = 'with LCDB GLC codes'
      SET @SQLServer_error_code = NULL
   END
ELSE IF @error_type = 7
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to update records in table XX_CERIS_CP_STG failed.
      SET @error_msg_placeholder1 = 'Backup EMPL_LAB_INFO'
      SET @error_msg_placeholder2 = 'Previous Values'
      SET @SQLServer_error_code = NULL
   END
ELSE IF @error_type = 8
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to update records in table XX_CERIS_CP_STG failed.
      SET @error_msg_placeholder1 = 'Update EXEMPT_DT'
      SET @error_msg_placeholder2 = 'for new logic'
      SET @SQLServer_error_code = NULL
   END
ELSE IF @error_type = 9
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to 1 2 failed
      SET @error_msg_placeholder1 = 'Perform LCDB'
      SET @error_msg_placeholder2 = 'DEFALT logic'
      SET @SQLServer_error_code = NULL
   END
*/

--CR4885 end


 
EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_code,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT


RETURN(1)


END


GO



use imapsstg
go

IF OBJECT_ID('dbo.XX_BMS_IW_CREATE_FLAT_FILE_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_BMS_IW_CREATE_FLAT_FILE_SP
    IF OBJECT_ID('dbo.XX_BMS_IW_CREATE_FLAT_FILE_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_BMS_IW_CREATE_FLAT_FILE_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_BMS_IW_CREATE_FLAT_FILE_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER ON
go








CREATE PROCEDURE [dbo].[XX_BMS_IW_CREATE_FLAT_FILE_SP]
(
@in_STATUS_RECORD_NUM     INTEGER,
@out_SQLServer_error_code INTEGER      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   VARCHAR(275) = NULL OUTPUT
)
AS
/****************************************************************************************************
Name:       XX_BMS_IW_CREATE_FLAT_FILE_SP
Author:     KM
Created:    11/01/2005
Modified:   09/26/2007 modified for DR-996
Modified: 	09/28/2007 statement uncommented
Modified: 	12/27/2007 modified for CR-1333
Modified:   10/15/2010 modified for CR-3102 for NISC Changes
Modified:   12/06/2010 modified for CR-3102 for NISC Changes- Tuned cursor statement
Modified:	14/1/2010 Modified for DR-3368 for miscode issue
Modified:   01/26/2010 Modifief for DR-3412 for Missing employee in EMF issue 
Modified:   01/28/2010 Modified to remove interim
Modified:   11/28/2011 Modified for CR-3890 (standardize BCP calls)
Modified:   01/14/2014 Modified for CR-6332 1P Changes
Modified:   11/11/2016 Modified for CR-8766 2G changes

Purpose:    This stored procedure creates the Flat File to be sent to BMS-IW
Parameters: 
Result Set: 
Notes:
select * from xx_util_lab_out_arch
****************************************************************************************************/
BEGIN


DECLARE	@SP_NAME                 sysname,
        @IMAPS_error_number      INTEGER,
        @SQLServer_error_code    INTEGER,
        @row_count               INTEGER,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
	@BMS_IW_INTERFACE_NAME	 sysname

--CHANGE KM 1/6/05
DECLARE @IMAPS_USR sysname,
	@IMAPS_PWD sysname

SELECT 	@IMAPS_USR = PARAMETER_VALUE
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE	INTERFACE_NAME_CD = 'BMS_IW'
AND	PARAMETER_NAME = 'IN_USER_NAME'

SELECT 	@IMAPS_PWD = PARAMETER_VALUE
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE	INTERFACE_NAME_CD = 'BMS_IW'
AND	PARAMETER_NAME = 'IN_USER_PASSWORD'
--END CHANGE KM 1/6/05


-- set local const
SET @BMS_IW_INTERFACE_NAME = 'BMS_IW'
SET @SP_NAME = 'XX_BMS_IW_CREATE_FLAT_FILE_SP'

-- initialize local variables
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'create'
SET @error_msg_placeholder2 = 'BMS_IW flat file'


--INSERT DETAIL RECORDS
DECLARE @RECORD_TYPE 	CHAR(1),
	@CTRY_CD 	CHAR(3),
	@CMPNY_CD	CHAR(8),
	@ACCT_TYP_CD	CHAR(1),
	@TRVL_INDICATOR CHAR(1),
	@OVRTM_HRS_IND	CHAR(1),
	@OWNG_LOB_CD	CHAR(3),
	@OWNG_CNTRY_CD  CHAR(3),
	@OWNG_CMPNY_CD	CHAR(8),
	@LBR_SYS_CD	CHAR(8),
	@FILLER_6	CHAR(6),
	@CHRG_ACCT_ID	CHAR(8),
	@CHRG_ACTV_CD	CHAR(6)

SELECT 	@RECORD_TYPE 	= '1',
	@CTRY_CD 	= '897',	
	@CMPNY_CD 	= 'IBM     ',	
	@ACCT_TYP_CD	= 'I',		-- *different for DOU/Shop Orders
	@TRVL_INDICATOR = 'N',		-- default
	@OVRTM_HRS_IND 	= ' ',		-- default
	@OWNG_LOB_CD 	= 'BIS',	-- *different for DOU/Shop Orders
	@OWNG_CNTRY_CD 	= '897',	-- *different for DOU/Shop Orders
	@OWNG_CMPNY_CD 	= 'IBM     ',	-- *different for DOU/Shop Orders
	@LBR_SYS_CD	= '        ', 
	@FILLER_6	= '      ',
	@CHRG_ACCT_ID	= '        ',	-- not sending
	@CHRG_ACTV_CD	= '      '	-- not sending


-- 1.	TRUNCATE TABLES
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'truncate'
SET @error_msg_placeholder2 = 'tables XX_BMS_IW_DTL, XX_BMS_IW_HDR'

TRUNCATE TABLE dbo.XX_BMS_IW_DTL
TRUNCATE TABLE dbo.XX_BMS_IW_HDR

SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER


-- 2.	INSERT TABLE XX_BMS_IW_DTL
-- TODO, FINALIZE data mappings
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert into'
SET @error_msg_placeholder2 = 'table XX_BMS_IW_DTL'

-- TO DO
-- There is some requirement that says the interface
-- must be able to get UTIL_LAB_OUT data from
-- certain timeperiods if needed
-- This requires that we build parameters
-- for type of Interface run - Standard or Custom
-- and dates boundaries for Custom run
DECLARE	@RUN_TYPE	VARCHAR(20),
	@START_DT	datetime,
	@END_DT		datetime


SELECT 	@RUN_TYPE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'RUN_TYPE'

IF(@RUN_TYPE = 'STANDARD')
BEGIN
	-- insert records from XX_UTIL_LAB_OUT
	INSERT INTO dbo.XX_BMS_IW_DTL
		(RECORD_TYPE, EMP_SER_NUM, 
		CTRY_CD, CMPNY_CD, TOT_CLMED_HRS,
		ACCT_TYP_CD, TRVL_INDICATOR, 
		CLM_WK_ENDING_DT, OVRTM_HRS_IND,
		OWNG_LOB_CD, OWNG_CNTRY_CD, OWNG_CMPNY_CD, LBR_SYS_CD,
		CHRG_ACCT_ID, CHRG_ACTV_CD, FILLER)
	SELECT 	@RECORD_TYPE, CAST(a.EMPL_ID AS CHAR(6)),
		a.CTRY_CD, a.CMPNY_CD, STR(ROUND(SUM(a.ENTERED_HRS),1), 7, 1) TOT_CLMED_HRS, --Modified 10/25/07
		a.ACCT_TYP_CD, @TRVL_INDICATOR TRVL_INDICATOR, 
		CONVERT(CHAR(10), a.PERIOD_END_DT, 120) CLM_WK_ENDING_DT, @OVRTM_HRS_IND OVRTM_HRS_IND,
		a.OWNING_LOB_CD, a.OWNING_COUNTRY_CD, a.OWNING_COMPANY_CD, 
        @LBR_SYS_CD LBR_SYS_CD,
		account_id chrg_acct_id,
        CHRG_ACTV_CD, 
        @FILLER_6 FILLER_6
	FROM 	dbo.XX_UTIL_LAB_OUT a
    GROUP BY  CAST(a.EMPL_ID AS CHAR(6)),
		a.CTRY_CD, a.CMPNY_CD, a.ACCT_TYP_CD, 
		CONVERT(CHAR(10), a.PERIOD_END_DT, 120) , 
		a.OWNING_LOB_CD, a.OWNING_COUNTRY_CD, a.OWNING_COMPANY_CD, 
        account_id ,CHRG_ACTV_CD
	HAVING 	ROUND(SUM(a.ENTERED_HRS),1)<>0 -- Added --Modified 10/25/07
END
ELSE --IF(@RUN_TYPE <> 'STANDARD')
BEGIN
	-- get Custom Interface Parameters
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'Convert Custom Interface Run'
	SET @error_msg_placeholder2 = 'Date Parameters Failed'

	SELECT 	@START_DT = CAST(PARAMETER_VALUE AS datetime)
	FROM	dbo.XX_PROCESSING_PARAMETERS
	WHERE	PARAMETER_NAME = 'START_DT'
	
	SELECT 	@END_DT = CAST(PARAMETER_VALUE AS datetime)
	FROM	dbo.XX_PROCESSING_PARAMETERS
	WHERE	PARAMETER_NAME = 'END_DT'

	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

-- BEGIN BMS_IW_DTL insert/updates

	-- insert records from XX_UTIL_LAB_OUT
	INSERT INTO dbo.XX_BMS_IW_DTL
		(RECORD_TYPE, EMP_SER_NUM, 
		CTRY_CD, CMPNY_CD, TOT_CLMED_HRS,
		ACCT_TYP_CD, TRVL_INDICATOR, 
		CLM_WK_ENDING_DT, OVRTM_HRS_IND,
		OWNG_LOB_CD, OWNG_CNTRY_CD, OWNG_CMPNY_CD, LBR_SYS_CD,
		CHRG_ACCT_ID, CHRG_ACTV_CD, FILLER)
	SELECT 	@RECORD_TYPE, CAST(a.EMPL_ID AS CHAR(6)),
		a.CTRY_CD, a.CMPNY_CD, STR(ROUND(SUM(a.ENTERED_HRS),1), 7, 1) TOT_CLMED_HRS,
		a.ACCT_TYP_CD, @TRVL_INDICATOR TRVL_INDICATOR, 
		CONVERT(CHAR(10), a.PERIOD_END_DT, 120) CLM_WK_ENDING_DT, @OVRTM_HRS_IND OVRTM_HRS_IND,
		a.OWNING_LOB_CD, a.OWNING_COUNTRY_CD, a.OWNING_COMPANY_CD, 
        @LBR_SYS_CD LBR_SYS_CD,
		account_id chrg_acct_id,
        CHRG_ACTV_CD, 
        @FILLER_6 FILLER_6
	FROM 	dbo.XX_UTIL_LAB_OUT_ARCH a
	WHERE	(a.PERIOD_END_DT <= @END_DT AND
		     a.PERIOD_END_DT >= @START_DT)
    GROUP BY  CAST(a.EMPL_ID AS CHAR(6)),
		a.CTRY_CD, a.CMPNY_CD, a.ACCT_TYP_CD, 
		CONVERT(CHAR(10), a.PERIOD_END_DT, 120) , 
		a.OWNING_LOB_CD, a.OWNING_COUNTRY_CD, a.OWNING_COMPANY_CD, 
        account_id ,CHRG_ACTV_CD
	HAVING 	ROUND(SUM(a.ENTERED_HRS),1)<>0 -- Added -- Modified 10/25/07

	
END

SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

UPDATE dbo.xx_bms_iw_dtl
SET TOT_CLMED_HRS= (CASE SIGN(CAST(TOT_CLMED_HRS AS DECIMAL(11, 1)))
                       WHEN 1 THEN ' '+substring(dbo.FormatNumber(TOT_CLMED_HRS,1,'z7z',''),2,11)
                       WHEN -1 THEN '-'+substring(dbo.FormatNumber(ABS(TOT_CLMED_HRS),1,'z7z',''),2,11)
                    END)
SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER


-- update needed for blank values that must be set to 
-- IMAPS default

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'update default values in'
SET @error_msg_placeholder2 = 'table XX_BMS_IW_DTL'

UPDATE dbo.XX_BMS_IW_DTL
SET ACCT_TYP_CD = @ACCT_TYP_CD
WHERE ACCT_TYP_CD = ' '

UPDATE dbo.XX_BMS_IW_DTL
SET OWNG_LOB_CD = @OWNG_LOB_CD
WHERE OWNG_LOB_CD = '   '

UPDATE dbo.XX_BMS_IW_DTL
SET OWNG_CNTRY_CD = @OWNG_CNTRY_CD
WHERE OWNG_CNTRY_CD = '   '

UPDATE dbo.XX_BMS_IW_DTL
SET OWNG_CMPNY_CD = @OWNG_CMPNY_CD
WHERE OWNG_CMPNY_CD = '        '

SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

/*
-- Cursor for updating labor_sys_cd
DECLARE	SITE_LOC_ID CURSOR FOR
		SELECT DISTINCT emp_ser_num 
			FROM dbo.XX_BMS_IW_DTL
			WHERE RTRIM(lbr_sys_cd) =''

DECLARE @emp_ser_num CHAR(6)

SELECT	@LBR_SYS_CD	= '        '

--Cursor fixed 12/05/2010
OPEN SITE_LOC_ID
FETCH NEXT FROM SITE_LOC_ID INTO @emp_ser_num
WHILE @@FETCH_STATUS = 0
BEGIN 
	SELECT @lbr_sys_cd=dbo.XX_GET_SITE_LOC_ID_UF(@emp_ser_num)

	UPDATE dbo.xx_bms_iw_dtl
	SET lbr_sys_cd=@lbr_sys_cd
	WHERE emp_ser_num=@emp_ser_num
	--Modified 12/05/2010
	FETCH NEXT FROM SITE_LOC_ID INTO @emp_ser_num
END

CLOSE SITE_LOC_ID
DEALLOCATE SITE_LOC_ID
*/

--The cursor was taking long time to make the updates. We will replace it with direct update statement.
--We will use MAX as there are multiple records for employee in EMF
/* Commented DR-3412
UPDATE dbo.xx_bms_iw_dtl
SET lbr_sys_cd=
	(SELECT MAX(emf.site_loc_id) 
        FROM BMSIW..BMSIW.EMP_MASTER_FILE_UV  emf
		WHERE dbo.xx_bms_iw_dtl.emp_ser_num=emf.emp_ser_num)
*/
--Added ISNULL, this will avoid the situation where employee is missing in EMF Table
--The Interface was failed once when employee missing in EMF
--We will also look for only CSIPROD in EMF
--If we can't find match then the default will be left blank
UPDATE dbo.xx_bms_iw_dtl
SET lbr_sys_cd=
	ISNULL((SELECT MAX(emf.site_loc_id) 
			FROM BMSIW..BMSIW.EMP_MASTER_FILE_UV  emf
			WHERE dbo.xx_bms_iw_dtl.emp_ser_num=emf.emp_ser_num
			AND site_loc_id='CSIPROD'), @LBR_SYS_CD)

SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

--END DR-3412 Changes
-- END BMS_IW_DTL Updates


-- BEGIN Miscode Handler
-- The following cursor will update lbr_sys_cd for miscoded records
-- If lbr_sys_cd is found that means employee exists in EMF table
/*
-- Cursor for updating labor_sys_cd of micode records
DECLARE	SITE_LOC_ID CURSOR FOR
		SELECT DISTINCT emp_ser_num 
			FROM dbo.XX_BMS_IW_DTL_MISCODE
			WHERE RTRIM(lbr_sys_cd) =''

--DECLARE @emp_ser_num char(6)

SELECT	@LBR_SYS_CD	= '        '

--Cursor fixed 12/05/2010
OPEN SITE_LOC_ID
FETCH NEXT FROM SITE_LOC_ID INTO @emp_ser_num
WHILE @@FETCH_STATUS = 0
BEGIN 
	SELECT @lbr_sys_cd=dbo.XX_GET_SITE_LOC_ID_UF(@emp_ser_num)

	UPDATE dbo.xx_bms_iw_dtl
	SET lbr_sys_cd=@lbr_sys_cd
	WHERE emp_ser_num=@emp_ser_num
	--Modified 12/05/2010
	FETCH NEXT FROM SITE_LOC_ID INTO @emp_ser_num
END

CLOSE SITE_LOC_ID
DEALLOCATE SITE_LOC_ID
*/

--The cursor was taking long time to make the updates. We will replace it with direct update statement.
--We will use MAX as there are multiple records for 
/* commented DR-3412
UPDATE dbo.xx_bms_iw_dtl_miscode
SET lbr_sys_cd=
	(SELECT MAX(emf.site_loc_id) 
        FROM BMSIW..BMSIW.EMP_MASTER_FILE_UV  emf
		WHERE dbo.xx_bms_iw_dtl_miscode.emp_ser_num=emf.emp_ser_num)
*/
--Added ISNULL, this will avoid the situation where employee is missing in EMF Table
--The Interface was failed once when employee missing in EMF
--We will also look for only CSIPROD in EMF
--If we can't find match then the default will be left blank
UPDATE dbo.xx_bms_iw_dtl_miscode
SET lbr_sys_cd=
	ISNULL((SELECT MAX(emf.site_loc_id) 
			FROM BMSIW..BMSIW.EMP_MASTER_FILE_UV  emf
			WHERE dbo.xx_bms_iw_dtl_miscode.emp_ser_num=emf.emp_ser_num
			AND site_loc_id='CSIPROD'), @LBR_SYS_CD)

SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER
--End DR-3412 Changes

-- Move records to BMSIW_DTL table where lbr_sys_cd WAS found
-- This means employee now exist in the EMF table
INSERT INTO dbo.XX_BMS_IW_DTL
		(RECORD_TYPE, EMP_SER_NUM, 
		CTRY_CD, CMPNY_CD, TOT_CLMED_HRS,
		ACCT_TYP_CD, TRVL_INDICATOR, 
		CLM_WK_ENDING_DT, OVRTM_HRS_IND,
		OWNG_LOB_CD, OWNG_CNTRY_CD, OWNG_CMPNY_CD, LBR_SYS_CD,
		CHRG_ACCT_ID, CHRG_ACTV_CD, FILLER)
SELECT 
		RECORD_TYPE, EMP_SER_NUM, 
		CTRY_CD, CMPNY_CD, TOT_CLMED_HRS,
		ACCT_TYP_CD, TRVL_INDICATOR, 
		CLM_WK_ENDING_DT, OVRTM_HRS_IND,
		OWNG_LOB_CD, OWNG_CNTRY_CD, OWNG_CMPNY_CD, LBR_SYS_CD,
		CHRG_ACCT_ID, CHRG_ACTV_CD, FILLER
FROM dbo.XX_BMS_IW_DTL_MISCODE
WHERE RTRIM(lbr_sys_cd)<>''

-- Delete from miscode table as the data is sent to BMSIW
DELETE FROM dbo.XX_BMS_IW_DTL_MISCODE
WHERE RTRIM(lbr_sys_cd)<>''

-- Move records to micode tables where lbr_sys_cd was not found
-- This means employee is not exist in the EMF table
INSERT INTO dbo.XX_BMS_IW_DTL_MISCODE
		(RECORD_TYPE, EMP_SER_NUM, 
		CTRY_CD, CMPNY_CD, TOT_CLMED_HRS,
		ACCT_TYP_CD, TRVL_INDICATOR, 
		CLM_WK_ENDING_DT, OVRTM_HRS_IND,
		OWNG_LOB_CD, OWNG_CNTRY_CD, OWNG_CMPNY_CD, LBR_SYS_CD,
		CHRG_ACCT_ID, CHRG_ACTV_CD, FILLER)
SELECT 
		RECORD_TYPE, EMP_SER_NUM, 
		CTRY_CD, CMPNY_CD, TOT_CLMED_HRS,
		ACCT_TYP_CD, TRVL_INDICATOR, 
		CLM_WK_ENDING_DT, OVRTM_HRS_IND,
		OWNG_LOB_CD, OWNG_CNTRY_CD, OWNG_CMPNY_CD, LBR_SYS_CD,
		CHRG_ACCT_ID, CHRG_ACTV_CD, FILLER
FROM dbo.XX_BMS_IW_DTL
WHERE RTRIM(lbr_sys_cd)=''

-- Delete from miscode table as the data is sent to BMSIW miscode
DELETE FROM dbo.XX_BMS_IW_DTL
WHERE RTRIM(lbr_sys_cd)=''

-- commented 10/25/2007
-- Move records to miscode table where claim wkend is not between the effective date of emp
/*
INSERT INTO dbo.XX_BMS_IW_DTL_MISCODE
		(RECORD_TYPE, EMP_SER_NUM, 
		CTRY_CD, CMPNY_CD, TOT_CLMED_HRS,
		ACCT_TYP_CD, TRVL_INDICATOR, 
		CLM_WK_ENDING_DT, OVRTM_HRS_IND,
		OWNG_LOB_CD, OWNG_CNTRY_CD, OWNG_CMPNY_CD, LBR_SYS_CD,
		CHRG_ACCT_ID, CHRG_ACTV_CD, FILLER)
SELECT 
		RECORD_TYPE, UTIL.EMP_SER_NUM, 
		UTIL.CTRY_CD, UTIL.CMPNY_CD, TOT_CLMED_HRS,
		ACCT_TYP_CD, TRVL_INDICATOR, 
		CLM_WK_ENDING_DT, OVRTM_HRS_IND,
		OWNG_LOB_CD, OWNG_CNTRY_CD, OWNG_CMPNY_CD, UTIL.LBR_SYS_CD,
		CHRG_ACCT_ID, CHRG_ACTV_CD, FILLER
FROM dbo.XX_BMS_IW_DTL UTIL
INNER JOIN
BMSIW..BMSIWUTILDM.EMF_UTIL_UV EMF 
ON 
	UTIL.EMP_SER_NUM=EMF.EMP_SER_NUM
	AND (CONVERT(DATETIME,UTIL.CLM_WK_ENDING_DT , 120) NOT BETWEEN convert(datetime,EMF.EFF_DT,120) AND convert(datetime,EMF.EXPIR_DT,120))
	AND (CONVERT(DATETIME,UTIL.CLM_WK_ENDING_DT, 120) NOT BETWEEN convert(datetime,EMF.EMP_EFF_DT, 120) AND convert(datetime,EMF.EMP_DISCON_DT)) -- uncommented 09/28
	AND EMF.CTRY_CD='897' AND EMF.CMPNY_CD='IBM'  AND EMF.DIV_CD='16'
	AND EMF.EMP_DISCON_DT = '9999-12-31'
*/
--10/25/2007 changes begin DR-1318
--Move records to miscode table if the labor claim weekend is not in the EMF_UTIL table for the 
--Div=16/1M
INSERT INTO dbo.XX_BMS_IW_DTL_MISCODE
		(RECORD_TYPE, EMP_SER_NUM, 
		CTRY_CD, CMPNY_CD, TOT_CLMED_HRS,
		ACCT_TYP_CD, TRVL_INDICATOR, 
		CLM_WK_ENDING_DT, OVRTM_HRS_IND,
		OWNG_LOB_CD, OWNG_CNTRY_CD, OWNG_CMPNY_CD, LBR_SYS_CD,
		CHRG_ACCT_ID, CHRG_ACTV_CD, FILLER)
SELECT 
		RECORD_TYPE, UTIL.EMP_SER_NUM, 
		UTIL.CTRY_CD, UTIL.CMPNY_CD, TOT_CLMED_HRS,
		ACCT_TYP_CD, TRVL_INDICATOR, 
		CLM_WK_ENDING_DT, OVRTM_HRS_IND,
		OWNG_LOB_CD, OWNG_CNTRY_CD, OWNG_CMPNY_CD, UTIL.LBR_SYS_CD,
		CHRG_ACCT_ID, CHRG_ACTV_CD, FILLER
FROM dbo.XX_BMS_IW_DTL UTIL
WHERE emp_ser_num+UTIL.CLM_WK_ENDING_DT IN 
		--Modified NOT IN to IN for DR-3368 2011-01-14
		(SELECT emp_ser_num+UTIL.CLM_WK_ENDING_DT
		FROM BMSIW..UTILDM.EMF_UTIL_UV EMF 
		WHERE
			UTIL.EMP_SER_NUM=EMF.EMP_SER_NUM
			AND (CONVERT(DATETIME,UTIL.CLM_WK_ENDING_DT , 120) BETWEEN CONVERT(datetime,EMF.EFF_DT,120) AND CONVERT(datetime,EMF.EXPIR_DT,120))
			AND EMF.CTRY_CD='897' AND EMF.CMPNY_CD NOT IN ('IBM','NIAS')  AND EMF.DIV_CD NOT IN ('16','1M','1P','2G')
			--Modified for CR-3102 2010-10-20
			--Modified for DR-3368 2011-01-14
			--Modified for CR-6332 2014-01-15 Added 1P to the list
			--Modified for CR-8766 2G added to list
		) 
--10/25/2007 changes end



-- Delete the miscoded records
DELETE FROM dbo.XX_BMS_IW_DTL
WHERE (emp_ser_num+clm_wk_ending_dt+tot_clmed_hrs+
         chrg_acct_id+ chrg_actv_cd+ acct_typ_cd)
   IN
    (SELECT emp_ser_num+clm_wk_ending_dt+tot_clmed_hrs+ 
            chrg_acct_id+ chrg_actv_cd+ acct_typ_cd
     FROM dbo.XX_BMS_IW_DTL_MISCODE)


-- END Miscode Handler

-- Update LBR_SYS_CD for all the employees with CSIPROD
-- For all Div 16 empls the valus should be CSIPROD
-- Added for CR-1333
-- Added at the end of miscode handler as at this point 
-- code determined that the employee is exist in EMF table

UPDATE dbo.XX_BMS_IW_DTL
SET LBR_SYS_CD='CSIPROD '

-- 3.	INSERT TABLE XX_BMS_IW_HDR
DECLARE @REGISTRATION_ID	CHAR(5),
	@CYCLE_NUMBER		CHAR(5),
	@THE_DATE		CHAR(10),
	@DETAIL_RECORD_COUNT	CHAR(7),
	@TOTAL_HOURS		CHAR(11),
	@FILLER_41		CHAR(41)

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'select from'
SET @error_msg_placeholder2 = 'table XX_BMS_IW_DTL'

SELECT 	@RECORD_TYPE 		= '0',
	@THE_DATE		= CONVERT(CHAR(10), GETDATE(), 120)

-- REGISTRATION_ID PARAMETER
SELECT 	@REGISTRATION_ID = CAST(PARAMETER_VALUE AS CHAR(5))
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'REGISTRATION_ID' AND
	INTERFACE_NAME_CD = 'BMS_IW'

-- CYCLE NUMBER CALCULATION
DECLARE @INT			INT
SELECT  @INT = PARAMETER_VALUE +1 -- Add one for every cycle
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'CYCLE_NUMBER' AND
	INTERFACE_NAME_CD = 'BMS_IW'
IF @INT=0
	SET @CYCLE_NUMBER = '0000' + '1' -- Default value for the first run
ELSE IF @INT < 10
	SET @CYCLE_NUMBER = '0000' + CAST(@INT AS CHAR(1))
ELSE IF @INT < 100
	SET @CYCLE_NUMBER = '000' + CAST(@INT AS CHAR(2))
ELSE IF @INT < 1000
	SET @CYCLE_NUMBER = '00' + CAST(@INT AS CHAR(3))
ELSE IF @INT < 10000
	SET @CYCLE_NUMBER = '0' + CAST(@INT AS CHAR(4))
ELSE IF @INT < 100000
	SET @CYCLE_NUMBER = CAST(@INT AS CHAR(5))
ELSE
	SET @CYCLE_NUMBER = '00000' -- for ftp parameter, update CYCLE_NUMBER

SELECT  @DETAIL_RECORD_COUNT 	= COUNT(*)
FROM	dbo.XX_BMS_IW_DTL
SELECT	@TOTAL_HOURS 		= STR(SUM(CAST(TOT_CLMED_HRS AS DECIMAL(11, 1))), 11, 1)
FROM	dbo.XX_BMS_IW_DTL
SET	@FILLER_41		= '                                         '

SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER




-- 4.	INSERT TABLE XX_BMS_IW_HDR
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'insert into'
SET @error_msg_placeholder2 = 'table XX_BMS_IW_HDR'

INSERT INTO dbo.XX_BMS_IW_HDR
	(RECORD_TYPE, REGISTRATION_ID, CYCLE_NUMBER, THE_DATE,
	 DETAIL_RECORD_COUNT, TOTAL_HOURS, FILLER)
SELECT	@RECORD_TYPE, @REGISTRATION_ID, @CYCLE_NUMBER, @THE_DATE,
	 @DETAIL_RECORD_COUNT, @TOTAL_HOURS, @FILLER_41


UPDATE dbo.xx_bms_iw_hdr
SET TOTAL_HOURS= (CASE SIGN(CAST(TOTAL_HOURS AS DECIMAL(11, 1)))
                    WHEN 1 THEN ' '+substring(dbo.FormatNumber(TOTAL_HOURS,1,'z11z',''),2,11)
                    WHEN -1 THEN '-'+substring(dbo.FormatNumber(ABS(TOTAL_HOURS),1,'z11z',''),2,11)
                 END),
   detail_record_count=dbo.FormatNumber(detail_record_count,0,'z7z','')
WHERE cycle_number=@cycle_number

SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER



-- 5.	BCP TABLE XX_BMS_IW_HDR
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'BCP'
SET @error_msg_placeholder2 = 'table XX_BMS_IW_HDR'

DECLARE	@HDR_FILE	sysname,
	@HDR_FRMT	sysname,
	@CMD		VARCHAR(500)

SELECT 	@HDR_FILE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @BMS_IW_INTERFACE_NAME
AND 	PARAMETER_NAME = 'HDR_FILE'

SELECT 	@HDR_FRMT = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @BMS_IW_INTERFACE_NAME
AND 	PARAMETER_NAME = 'HDR_FRMT'

/*
CR-3890
SET 	@CMD 		= 'BCP IMAPSSTG.DBO.XX_BMS_IW_HDR OUT ' + @HDR_FILE + ' -f' + @HDR_FRMT + ' -U' + @IMAPS_USR + ' -P' + @IMAPS_PWD

EXEC MASTER.DBO.XP_CMDSHELL @CMD
*/
--begin CR-3890
DECLARE @ret_code int
SET @ret_code=1

EXEC @ret_code = dbo.XX_EXEC_SHELL_CMD_OSUSER
	@in_IMAPS_db_name='IMAPSSTG',
	@in_IMAPS_table_owner='dbo',
	@in_source_table='XX_BMS_IW_HDR',
	@in_format_file=@HDR_FRMT,
	@in_output_file=@HDR_FILE,
	@out_STATUS_DESCRIPTION=@out_STATUS_DESCRIPTION

SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

IF @ret_code <> 0 GOTO BL_ERROR_HANDLER
--end CR-3890



-- 6.	BCP TABLE XX_BMS_IW_DTL
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'BCP'
SET @error_msg_placeholder2 = 'table XX_BMS_IW_DTL'


DECLARE	@DTL_FILE	sysname,
	@DTL_FRMT	sysname

SELECT 	@DTL_FILE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @BMS_IW_INTERFACE_NAME
AND 	PARAMETER_NAME = 'DTL_FILE'

SELECT 	@DTL_FRMT = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @BMS_IW_INTERFACE_NAME
AND 	PARAMETER_NAME = 'DTL_FRMT'

/*
CR-3890
SET 	@CMD 		= 'BCP IMAPSSTG.DBO.XX_BMS_IW_DTL OUT ' + @DTL_FILE + ' -f' + @DTL_FRMT + ' -U' + @IMAPS_USR + ' -P' + @IMAPS_PWD

EXEC MASTER.DBO.XP_CMDSHELL @CMD
*/
--begin CR-3890
SET @ret_code=1

EXEC @ret_code = dbo.XX_EXEC_SHELL_CMD_OSUSER
	@in_IMAPS_db_name='IMAPSSTG',
	@in_IMAPS_table_owner='dbo',
	@in_source_table='XX_BMS_IW_DTL',
	@in_format_file=@DTL_FRMT,
	@in_output_file=@DTL_FILE,
	@out_STATUS_DESCRIPTION=@out_STATUS_DESCRIPTION

SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

IF @ret_code <> 0 GOTO BL_ERROR_HANDLER
--end CR-3890


-- 7.	COMBINE HEADER WITH DETAILS
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'Combine BMS_IW header and detail record'
SET @error_msg_placeholder2 = 'into a single file'

DECLARE @COMBINED_FILE	sysname

SELECT 	@COMBINED_FILE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE 	INTERFACE_NAME_CD = @BMS_IW_INTERFACE_NAME
AND 	PARAMETER_NAME = 'FTP_FILE'

SET 	@CMD		= 'type ' + @HDR_FILE + ' > ' + @COMBINED_FILE
EXEC MASTER.DBO.XP_CMDSHELL @CMD
SET 	@CMD		= 'type ' + @DTL_FILE + ' >> ' + @COMBINED_FILE
EXEC MASTER.DBO.XP_CMDSHELL @CMD

SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER
 
-- 8. 	UPDATE PROCESSING PARAMETER and
--	UPDATE STATUS RECORD DETAILS
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'Update Status Record/Parameters'
SET @error_msg_placeholder2 = 'table details'

UPDATE 	dbo.XX_IMAPS_INT_STATUS
SET 	RECORD_COUNT_TRAILER = @DETAIL_RECORD_COUNT,
	RECORD_COUNT_INITIAL = @DETAIL_RECORD_COUNT,
	AMOUNT_INPUT = @TOTAL_HOURS
WHERE	STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

UPDATE 	dbo.XX_PROCESSING_PARAMETERS
SET 	PARAMETER_VALUE = CAST(@CYCLE_NUMBER AS INT)
WHERE	PARAMETER_NAME = 'CYCLE_NUMBER' AND
	INTERFACE_NAME_CD = 'BMS_IW'

SELECT @SQLServer_error_code = @@ERROR
IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER
 


RETURN(0)

BL_ERROR_HANDLER:

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
IF OBJECT_ID('dbo.XX_BMS_IW_CREATE_FLAT_FILE_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_BMS_IW_CREATE_FLAT_FILE_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_BMS_IW_CREATE_FLAT_FILE_SP >>>'
go

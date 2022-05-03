IF OBJECT_ID('dbo.XX_UTIL_LOAD_STAGING_DATA_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_UTIL_LOAD_STAGING_DATA_SP
    IF OBJECT_ID('dbo.XX_UTIL_LOAD_STAGING_DATA_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_UTIL_LOAD_STAGING_DATA_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_UTIL_LOAD_STAGING_DATA_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER ON
go



CREATE PROCEDURE [dbo].[XX_UTIL_LOAD_STAGING_DATA_SP] 
( 
@in_STATUS_RECORD_NUM    integer, 
@out_SystemError int = NULL OUTPUT, 
@out_STATUS_DESCRIPTION varchar(275) =NULL OUTPUT) AS

DECLARE 
@ReturnCode int,
@NumberOfRecords int,
@LastReportedTsLnKeyNum int,
@PeriodStartDate datetime,
@PeriodEndDate datetime,
@IMAPSOrgRecordNum int,
@IMAPSLabRecordNum int,
@IMAPSTotalHours decimal(14, 2),
-- begin 12/12/2005 TP
@ORG_SERVICE_AREA_LBL_KEY int,
@PROJ_CONTACT_NAME_LBL_KEY int,
@in_COMPANY_ID	sysname	-- Added for CR-1543
-- end 12/12/2005 TP

 /************************************************************************************************
Name:       XX_UTIL_LOAD_STAGING_DATA_SP_TEMP
Author:     Tatiana Perova
Created:    10/03/2005
Purpose:   Step 1 of Utilization interface.
		IMAPS data for employee hours and organization structure gathered into staging tables
		XX_UTIL_ORG_OUT,XX_UTIL_LAB_OUT
Modified on : 09/25/2007 for BMSIW CR-996
Modified on : 10/20/2007 for DR-1305
Modified on : 10/27/2007 for DR-1318
Modified on : 11/27/2007 for CR-1333 CHG_ACTV_CD changes	
Modified on : 12/05/2007 for CR-1335 DOU Related changes for '~~' type accounts
Modified on : 01/18/2008 for DR-1428 Owning LOB update modified
Modified on: 01/31/2008 for DR-1414 TS_LN_HS table changed to XX_IMAPS_TS_UTIL_DATA
Modified on: 05/01/2008	for CR-1543	COMPANY_ID Added
Modified on: 05/19/2008 for CR-1539 PAY_TYPE logic added
Modified on: 08/19/2009 for CR-2276 OA HR_Type Logic added
Modified on: 04/20/2010 for DR-2717 -p, -n
Modified on: 10/15/2010 for CR-3098 NISC/1M Changes
Modified on: 11/28/2012 for CR-4887 Collation change to differentiate -N and -n
Modified on: 01/17/2013 for CR-4887 Since the IW link from SQL is not working 
						the pointer is changed to a spcial view in Oracle.
						Issues was due to BH1.0 release
	     01/31/2013	Changed from PAY_TYPE IS NOT NULL to PAY_TYPE IN ('STB','STW')

Modified on: 11/18/2014 for CR-7554 New RPTGRP Control Code	  
Modified on: 06/11/2021 for CR-12915 Modified for BTO LOBs	     
Parameters: 
	Input: @in_STATUS_RECORD_NUM -- identifier of current interface run
	Output:  @out_STATUS_DESCRIPTION --  generated error message
		@out_SystemError  -- system error code
              
************************************************************************************************/

BEGIN TRANSACTION
SET @ReturnCode = 0
TRUNCATE TABLE dbo.XX_UTIL_LAB_OUT
TRUNCATE TABLE dbo.XX_UTIL_ORG_OUT
TRUNCATE TABLE dbo.XX_BMS_IW_DOU_DATA
TRUNCATE TABLE dbo.XX_BMS_IW_ACCOUNT_DATA

SELECT @PeriodStartDate = START_DT, @PeriodEndDate = END_DT FROM dbo.XX_UTIL_OUT_LOG
WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

-- Retrieve Additional parameters
-- Added CR-1543
SELECT @in_COMPANY_ID= PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'UTIL'   
   AND PARAMETER_NAME = 'COMPANY_ID'


SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT

IF @NumberOfRecords <> 1 OR @out_SystemError >0
	BEGIN
	-- status record should be already created
		Set @ReturnCode = 535 -- 01/18/2006 TP
		GOTO ErrorProcessing
	END 
  
IF @PeriodStartDate is NULL 
	BEGIN
		SELECT @LastReportedTsLnKeyNum = LAST_TS_LN_KEY
		FROM dbo.XX_UTIL_OUT_LOG
		WHERE STATUS_RECORD_NUM = 
			(SELECT MAX(STATUS_RECORD_NUM) 
			FROM dbo.XX_UTIL_OUT_LOG
			WHERE  LAST_TS_LN_KEY is NOT NULL)
	PRINT 'TEST'
	
	IF @LastReportedTsLnKeyNum is NULL 
		BEGIN
			SELECT @LastReportedTsLnKeyNum = COUNT(*)
			FROM dbo.XX_UTIL_OUT_LOG
			WHERE START_DT is NULL AND
			    STATUS_RECORD_NUM <> @in_STATUS_RECORD_NUM  -- TP 11/08/2005 should not pick current record
			
			IF @LastReportedTsLnKeyNum <> 0
				BEGIN 
				-- Message: Invalid last standard request record in XX_UTIL_OUT_LOG table
				Set @ReturnCode = 533
				GOTO ErrorProcessing 
				END
			ELSE 
				BEGIN SET @LastReportedTsLnKeyNum = 0 END
		END
	END
ELSE
	BEGIN
	IF @PeriodEndDate is NULL OR
		DateDiff(day, @PeriodEndDate, @PeriodStartDate) > 0 
		BEGIN
		Set @ReturnCode = 534
		GOTO ErrorProcessing 
		END
END

-- begin 12/12/2005 TP
-- Get UDEF lable keys
SELECT @ORG_SERVICE_AREA_LBL_KEY = [UDEF_LBL_KEY]
FROM [IMAPS].[DELTEK].[UDEF_LBL]
WHERE [UDEF_LBL]= 'SERVICE AREA' 
	AND S_TABLE_ID = 'ORG'
	AND COMPANY_ID=@in_COMPANY_ID -- Modified for CR-1543
	
SELECT @PROJ_CONTACT_NAME_LBL_KEY = [UDEF_LBL_KEY]
FROM [IMAPS].[DELTEK].[UDEF_LBL]
WHERE [UDEF_LBL]= 'FINANCIAL ANALYST' 
	AND S_TABLE_ID = 'PROJ'
	AND COMPANY_ID=@in_COMPANY_ID -- Modified for CR-1543
-- end 12/12/2005 TP



--load ETIME DOU DATA (grab only what is needed)
--BMSIW LINKED SERVER DOES NOT WORK
PRINT 'ETIME_DOU - ATTEMPTING TO LOAD DOU DATA FROM ET&E'
-- CR-1335 Changes BEGIN
/*
INSERT INTO dbo.XX_BMS_IW_DOU_DATA
	(ACCOUNT_ID,JDE_PROJ_CODE,CONTROL_GROUP_CD)
SELECT  ACCOUNT_ID,JDE_PROJ_CODE,CONTROL_GROUP_CD
FROM   	ETIME..INTERIM.RS_DOU
WHERE  	LEN_BORR_FLG = 'L'
AND	JDE_PROJ_CODE IN
	(SELECT PROJ_ABBRV_CD FROM IMAPS.DELTEK.TS_LN_HS
	 WHERE TS_LN_KEY > @LastReportedTsLnKeyNum)
*/

INSERT INTO dbo.XX_BMS_IW_DOU_DATA
	(ACCOUNT_ID,JDE_PROJ_CODE,CONTROL_GROUP_CD)
SELECT  ACCOUNT_ID,JDE_PROJ_CODE,CONTROL_GROUP_CD
FROM   	ETIME..INTERIM.RS_DOU
WHERE  	LEN_BORR_FLG = 'L'
AND	JDE_PROJ_CODE IN
	(SELECT DISTINCT PROJ_ABBRV_CD FROM DBO.XX_IMAPS_TS_UTIL_DATA --CR-1414 Changed from TS_LN_HS
	 WHERE TS_LN_KEY > @LastReportedTsLnKeyNum)
and account_id not like '~~%' -- Regular accounts
union
SELECT  account_id,JDE_PROJ_CODE,CONTROL_GROUP_CD
FROM   	ETIME..INTERIM.RS_DOU
WHERE  	LEN_BORR_FLG = 'L'
AND	JDE_PROJ_CODE IN
	(SELECT DISTINCT PROJ_ABBRV_CD FROM DBO.XX_IMAPS_TS_UTIL_DATA --CR-1414 Changed from TS_LN_HS
	 WHERE TS_LN_KEY > @LastReportedTsLnKeyNum)
and account_id like '~~%' -- ICA Accounts where account id is same as project code
and RTRIM(SUBSTRING(account_id,3,10))=JDE_PROJ_CODE
union
SELECT  RTRIM(SUBSTRING(account_id,3,10)),JDE_PROJ_CODE,CONTROL_GROUP_CD
FROM   	ETIME..INTERIM.RS_DOU
WHERE  	LEN_BORR_FLG = 'L'
AND	JDE_PROJ_CODE IN
	(SELECT DISTINCT PROJ_ABBRV_CD FROM DBO.XX_IMAPS_TS_UTIL_DATA --CR-1414 Changed from TS_LN_HS
	 WHERE TS_LN_KEY > @LastReportedTsLnKeyNum)
and account_id like '~~%' -- ICA Accounts where account id is not same as project code
and RTRIM(SUBSTRING(account_id,3,10))<>JDE_PROJ_CODE

--CR-1335 Changes END
PRINT 'ETIME_DOU - COMPLETE'


SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT

IF  @out_SystemError <> 0
	BEGIN
		Set @ReturnCode = 1
		GOTO ErrorProcessing
	END 


--BMSIW LINKED SERVER DOES NOT WORK
/*

-- Original Insert Statement Will no longer required 08/01/2007
--load BMSIW ACCOUNT DATA if needed
IF ( (SELECT COUNT(1) FROM dbo.XX_BMS_IW_DOU_DATA) > 0)
BEGIN
	--grab only what is needed
	PRINT 'BMSIW_ACCOUNT - ATTEMPTING TO LOAD ACCOUNT DATA FROM BMS_IW'
	INSERT INTO dbo.XX_BMS_IW_ACCOUNT_DATA
	(ACCOUNT_ID, ACCT_DESCRIPT, STATUS, CONTACT_NAME, CONTACT_EMP_NUM,
	CONTROL_GROUP_CD, OWNING_DIV_CD, OWNING_COUNTRY_CD, OWNING_COMPANY_CD, 
	ACCT_TYP_CD, OWNING_LOB_CD, SOW_TYP_CD)
	SELECT
	A.ACCOUNT_ID,
	A.ACCT_DESCRIPT,
	A.STATUS,
	A.CONTACT_NAME, 
	A.CONTACT_EMP_NUM,
	A.CONTROL_GROUP_CD,
	A.OWNING_DIV_CD, 
	A.OWNING_COUNTRY_CD, 
	A.OWNING_COMPANY_CD,
	A.ACCT_TYP_CD,
	B.LOB,
	A.SOW_TYP_CD
	FROM
	BMSIW..BMSIW.ACCOUNT_V A
	LEFT JOIN
	BMSIW..BMSIW.LOB_OFFER_REF2_V B
	ON
	(A.OFFERING_COMP_CD = B.OFFER_COMP_CD)
	WHERE RTRIM(a.CONTROL_GROUP_CD) + RTRIM(a.ACCOUNT_ID) IN
	(SELECT RTRIM(CONTROL_GROUP_CD) + RTRIM(ACCOUNT_ID) FROM dbo.XX_BMS_IW_DOU_DATA)
	PRINT 'BMSIW_ACCOUNT - COMPLETE'
END
*/
-- Added Tejas Patel 08/01/2007
--New Insert Statement for BMSIW
INSERT INTO dbo.XX_BMS_IW_ACCOUNT_DATA
	(ACCOUNT_ID, ACCT_DESCRIPT, STATUS, CONTACT_NAME, CONTACT_EMP_NUM,
	CONTROL_GROUP_CD, OWNING_DIV_CD, OWNING_COUNTRY_CD, OWNING_COMPANY_CD, 
	ACCT_TYP_CD, SOW_TYP_CD,LOB,OWNING_LOB_CD,OFFER_CD,CHRG_METHOD_CD,
    CHRG_COUNTRY_CD,CHRG_COMPANY_CD,CHRG_DIV_CD,CHRG_DEPT_ID,OFFERING_COMP_CD, LOB_ID, RPTGRP_CONTROL_CD, BUS_TYP_CD, 
BUS_MEAS_DIV_CD)
SELECT
	A.ACCOUNT_ID,
	A.ACCT_DESCRIPT,
	A.STATUS,
	A.CONTACT_NAME, 
	A.CONTACT_EMP_NUM,
	A.CONTROL_GROUP_CD,
	A.OWNING_DIV_CD, 
	A.OWNING_COUNTRY_CD, 
	A.OWNING_COMPANY_CD,
	A.ACCT_TYP_CD,
    A.SOW_TYP_CD,
	B.LOB,
	NULL OWNING_LOB_CD, -- Modified for CR-1414
	B.OFFER_CD,
	A.CHRG_METHOD_CD,
	A.CHRG_COUNTRY_CD,
	A.CHRG_COMPANY_CD,
	A.CHRG_DIV_CD,
	A.CHRG_DEPT_ID,
	A.OFFERING_COMP_CD,
--	NULL LOB_ID
	(SELECT 
		max(ISNULL(RTRIM(LOB_ID),NULL) )
		FROM ETIME..INTERIM.BMSIW_ACCOUNT_UV , BMSIW..BMSIW.DEPT_REF_UV 
		--Modified for CR-4887 01/17/2013 Pointer changed
		WHERE ACCOUNT_ID =a.account_id
		AND CONTROL_GROUP_CD=a.CONTROL_GROUP_CD 
		AND CHRG_COUNTRY_CD = COUNTRY_CD
		AND CHRG_COMPANY_CD = COMPANY_CD
		AND CHRG_DIV_CD = DIV_CD 
		AND CHRG_DEPT_ID = DPT_ID
		and rtrim(lob_id) is not null) LOB_ID,
	RPTGRP_CONTROL_CD, BUS_TYP_CD, NULL BUS_MEAS_DIV_CD
	FROM
	--ETIME..INTERIM.V_ACCOUNT_UV A
	ETIME..INTERIM.BMSIW_ACCOUNT_UV A
	--BMSIW.ACCOUNT_V@DB2BMSIW
	--Modified for CR-4887 01/17/2013 Pointer changed
	LEFT JOIN
	--BMSIW..BMSIW.LOB_OFFER_REF_UV B Changed to OFFER_REF2
	BMSIW..BMSIW.LOB_OFFER_REF2_UV B -- Modified CR-1414
	ON
	(A.OFFERING_COMP_CD = B.OFFER_COMP_CD)
	WHERE RTRIM(a.CONTROL_GROUP_CD) + RTRIM(a.ACCOUNT_ID) IN
	(SELECT RTRIM(CONTROL_GROUP_CD) + RTRIM(ACCOUNT_ID) FROM dbo.XX_BMS_IW_DOU_DATA)
	--WHERE ACCOUNT_ID in( 'AAAADDS ','C41CX   ')
	--AND CONTROL_GROUP_CD in ('NA1     ', 'NA2     ')

SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT

IF  @out_SystemError <> 0	
	BEGIN
		Set @ReturnCode = 1
		GOTO ErrorProcessing
	END 

	-- Update Owning_LOB_CD. (LOB=LOB_OFFER_REF2, LOB_ID=DEPT_REF)
	-- Added CR-1414
	--1. If account type = C and offering code <>'' then use LOB from Offer_LOB_Ref2 table
	UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
	set owning_lob_cd=RTRIM(LOB)
	where ACCT_TYP_CD='C' and RTRIM(OFFERING_COMP_CD)<>'' and owning_lob_cd IS NULL
	and (RTRIM(LOB)<>'')

	--2. If account type=C and offering code ='' then 'OTH'
	UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
	set owning_lob_cd='OTH'
	where ACCT_TYP_CD='C' and (RTRIM(OFFERING_COMP_CD)='' OR RTRIM(OFFERING_COMP_CD) IS NULL) 
		and owning_lob_cd IS NULL

	UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
	set owning_lob_cd='OTH'
	where ACCT_TYP_CD='C' and RTRIM(OFFERING_COMP_CD)<>'' and (RTRIM(LOB) IS NULL OR RTRIM(LOB)='')
		and owning_lob_cd IS NULL

	--3. If account type<>C and if not IRB or IBM-ACCT then owning lob is determined by dept ref
	UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
	set owning_lob_cd=LOB_ID
	where ACCT_TYP_CD<>'C' and owning_lob_cd IS NULL
	-- IRB updates will be done after the hr_type updates

	-- If still blank the update with OTH - Requirement from Carol
	UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
	set owning_lob_cd='OTH'
	where ACCT_TYP_CD<>'C' and (RTRIM(owning_lob_cd) IS NULL OR RTRIM(owning_lob_cd)='')


-- BEGIN DOU HR TYPE Updates
-- Modified for CR-1414, LOB & LOB_ID is replaced with OWNING_LOB_CD
-->>>>>>>>> C-ommercial Accounts
--  Now update Hr Type for Div 16 and for BMSIW   
--If account type is C and then check the LOB associated with the service offering code.
--If LOB = BIS and Chrg_Method_Cd <> NON then give BIL utilization
UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
SET HR_TYPE_BMSIW = 'BIL', HR_TYPE_16 = 'B'
WHERE RTRIM(ACCT_TYP_CD) = 'C'
AND RTRIM(OWNING_LOB_CD) = 'BIS' 
--AND RTRIM(CHRG_METHOD_CD) <> 'NON' No longer needed as of DR-1318
AND RTRIM(HR_TYPE_BMSIW) IS NULL;

/* No Longer needed as of DR-1318
-- If LOB = BIS and Chrg_Method_Cd = NON then give NPR utilization (0 record found)
UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
SET HR_TYPE_BMSIW = 'NPR', HR_TYPE_16 = 'OA' -- Here bench and Allowable Overhead are mapped.  I picked OA
WHERE RTRIM(ACCT_TYP_CD) = 'C'
AND RTRIM(LOB) = 'BIS'
AND RTRIM(CHRG_METHOD_CD) = 'NON'
AND RTRIM(HR_TYPE_BMSIW) IS NULL;
*/

--BEGIN DR-1318 Changes (10/27/2007)
/*
-- If LOB <> BIS then give RIG Utilization
UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
SET HR_TYPE_BMSIW = 'RIG', HR_TYPE_16 = 'CR'
WHERE RTRIM(ACCT_TYP_CD) = 'C'
AND RTRIM(ISNULL(LOB,'NA')) <> 'BIS'
AND RTRIM(HR_TYPE_BMSIW) IS NULL;
*/
-- This will replace the previous logic
-- If Acct_typ_cd='C' and LOB<>BIS and LOB is not NULL, and LOB=IGS LOB then assign CR/BOL
-- This will cover mainly ITS, SO LOBs
UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
set HR_TYPE_16='CR', HR_TYPE_BMSIW='BOL'
FROM dbo.XX_BMS_IW_ACCOUNT_DATA BMS
where acct_typ_cd='C' 
and (OWNING_LOB_CD <>'BIS' and RTRIM(OWNING_LOB_CD) is not null)
and 'Y'=(SELECT distinct IGS_IND from BMSIW..BMSIW.LOB_REF_UV where LOB_ID=ISNULL(BMS.OWNING_LOB_CD,'OTH'))
AND RTRIM(HR_TYPE_BMSIW) IS NULL

-- If Acct_typ_cd='C' and LOB<>BIS or LOB is NULL, and LOB<>IGS LOB then assign B/BOI
-- This will cover mainly NULL LOBs
UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
set HR_TYPE_16='CR', HR_TYPE_BMSIW='BOI'
FROM dbo.XX_BMS_IW_ACCOUNT_DATA BMS
where acct_typ_cd='C' 
and (OWNING_LOB_CD <>'BIS' OR RTRIM(OWNING_LOB_CD) is null)
and 'N'=(SELECT distinct IGS_IND from BMSIW..BMSIW.LOB_REF_UV where LOB_ID=ISNULL(BMS.OWNING_LOB_CD,'OTH'))
AND RTRIM(HR_TYPE_BMSIW) IS NULL
--END DR-1318 Changes


-->>>>>>>>> O-pportunity Accounts
-- If account type is O then check the LOB of the owning country, company, division, dept in the account table

-- If LOB of Cntry/Comp/Div/Dept combination = BIS and account type = O and Chrg Method Cd <> NON then give PIL Utilization  
UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
SET HR_TYPE_BMSIW = 'PIL', HR_TYPE_16 = 'BP'
WHERE RTRIM(ACCT_TYP_CD) = 'O'
AND RTRIM(OWNING_LOB_CD) = 'BIS'
--AND RTRIM(CHRG_METHOD_CD) <> 'NON' --No Longer needed as of DR-1318
AND RTRIM(HR_TYPE_BMSIW) IS NULL;

/* No Longer needed for DR-1318
--If LOB of Cntry/Comp/Div/Dept combination = BIS and account type = O and Chrg Method Cd = NON then give NPR Utilization
UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
SET HR_TYPE_BMSIW = 'NPR', HR_TYPE_16 = 'OA' -- Here bench and Allowable Overhead are mapped to NPR.  I picked OA
WHERE RTRIM(ACCT_TYP_CD) <> 'C'
AND RTRIM(LOB_ID) = 'BIS'
AND RTRIM(ACCT_TYP_CD) = 'O'
AND RTRIM(CHRG_METHOD_CD) = 'NON'
AND RTRIM(HR_TYPE_BMSIW) IS NULL;
*/

--BEGIN DR-1318 Change
/*
-- If LOB of Cntry/Comp/Div/Dept combination <> BIS and account type = O then give RIG Utilization
UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
SET HR_TYPE_BMSIW = 'RIG', HR_TYPE_16 = 'CR'
WHERE RTRIM(ACCT_TYP_CD) <> 'C'
AND RTRIM(ISNULL(LOB_ID,'NA')) <> 'BIS'
AND RTRIM(ACCT_TYP_CD) = 'O'
AND RTRIM(HR_TYPE_BMSIW) IS NULL;
*/
-- This will replace above statement
-- If LOB of Cntry/Comp/Div/Dept combination <> BIS and account type = O then give POL/CR, POI/CR Utilization
UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
SET HR_TYPE_BMSIW = 'POL', HR_TYPE_16 = 'CR'
FROM dbo.XX_BMS_IW_ACCOUNT_DATA BMS
WHERE RTRIM(ACCT_TYP_CD) = 'O'
AND RTRIM(ISNULL(OWNING_LOB_CD,'NA')) <> 'BIS'
and (OWNING_LOB_CD <>'BIS' and RTRIM(OWNING_LOB_CD) is not null)
and 'Y'=(SELECT distinct IGS_IND from BMSIW..BMSIW.LOB_REF_UV where LOB_ID=ISNULL(BMS.OWNING_LOB_CD,'OTH'))
AND RTRIM(HR_TYPE_BMSIW) IS NULL;

UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
SET HR_TYPE_BMSIW = 'POI', HR_TYPE_16 = 'CR'
FROM dbo.XX_BMS_IW_ACCOUNT_DATA BMS
WHERE RTRIM(ACCT_TYP_CD) = 'O'
AND RTRIM(ISNULL(OWNING_LOB_CD,'NA')) <> 'BIS'
and (OWNING_LOB_CD <>'BIS' OR RTRIM(OWNING_LOB_CD) is null)
and 'N'=(SELECT distinct IGS_IND from BMSIW..BMSIW.LOB_REF_UV where LOB_ID=ISNULL(BMS.OWNING_LOB_CD,'OTH'))
AND RTRIM(HR_TYPE_BMSIW) IS NULL;
--END DR-1318 Change

-->>>>>>>>> Internal/Transfer Pricing Accounts

--If LOB of Cntry/Comp/Div/Dept combination = BIS and account type = I or T and Chrg Method Cd <> NON then give MIN 
UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
SET HR_TYPE_BMSIW = 'MIN', HR_TYPE_16 = 'IP'
WHERE (RTRIM(ACCT_TYP_CD) = 'I' OR RTRIM(ACCT_TYP_CD) = 'T')
AND RTRIM(OWNING_LOB_CD) = 'BIS'
--AND RTRIM(CHRG_METHOD_CD) <> 'NON' -- No Longer needed DR-1318
AND RTRIM(HR_TYPE_BMSIW) IS NULL;

/* No Longer needed DR-1318

--If LOB of Cntry/Comp/Div/Dept combination = BIS and account type = I or T and Chrg Method Cd = NON then give NPR 
UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
SET HR_TYPE_BMSIW = 'NPR', HR_TYPE_16 = 'OA' -- Here bench and Allowable Overhead are mapped to NPR.  I picked OA
WHERE RTRIM(ACCT_TYP_CD) <> 'C'
AND RTRIM(LOB_ID) = 'BIS'
AND (RTRIM(ACCT_TYP_CD) = 'I' OR RTRIM(ACCT_TYP_CD) = 'T')
AND RTRIM(CHRG_METHOD_CD) = 'NON'
AND RTRIM(HR_TYPE_BMSIW) IS NULL;
*/

--If LOB of Cntry/Comp/Div/Dept combination <> BIS and account type = I or T then give RIG Utilization
UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
SET HR_TYPE_BMSIW = 'RIG', HR_TYPE_16 = 'CR'
FROM dbo.XX_BMS_IW_ACCOUNT_DATA BMS
WHERE (RTRIM(ACCT_TYP_CD) = 'I' OR RTRIM(ACCT_TYP_CD) = 'T')
AND RTRIM(OWNING_LOB_CD) <> 'BIS'
and (OWNING_LOB_CD <>'BIS' and RTRIM(OWNING_LOB_CD) is not null)
and 'Y'=(SELECT distinct IGS_IND from BMSIW..BMSIW.LOB_REF_UV where LOB_ID=ISNULL(BMS.OWNING_LOB_CD,'OTH'))
AND RTRIM(HR_TYPE_BMSIW) IS NULL

UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
SET HR_TYPE_BMSIW = 'RIN', HR_TYPE_16 = 'CR'
FROM dbo.XX_BMS_IW_ACCOUNT_DATA BMS
WHERE (RTRIM(ACCT_TYP_CD) = 'I' OR RTRIM(ACCT_TYP_CD) = 'T')
AND RTRIM(OWNING_LOB_CD) <> 'BIS'
and (OWNING_LOB_CD <>'BIS' OR RTRIM(OWNING_LOB_CD) is null)
and 'N'=(SELECT distinct IGS_IND from BMSIW..BMSIW.LOB_REF_UV where LOB_ID=ISNULL(BMS.OWNING_LOB_CD,'OTH'))
AND RTRIM(HR_TYPE_BMSIW) IS NULL

--Begin CR-1305 Changes 10/15/2007
/*
if RPTGRP_CONTROL_CD='IGS-IRB' then set SOW='I' and OWNING_LOB='IRB' 
UTIL_TYP_CD will be RIR (instead of RIG)-->HR_TYPE=CR -->CHRG_ACTVTY_CD='GB0020'
if RPTGRP_CONTROL_CD='IBM_ACCT' then set SOW='G' and OWNING_LOB='IGA'
UTIL_TYP_CD will be IGA (instead of RIG)-->HR_TYPE=CR-->CHRG_ACTVTY_CD='GB0020'
*/

Update  dbo.XX_BMS_IW_ACCOUNT_DATA
 SET HR_TYPE_BMSIW = 'RIR', OWNING_LOB_CD='IRB',HR_TYPE_16 = 'CR', acct_typ_cd='I'
 WHERE RTRIM(RPTGRP_CONTROL_CD)='IGS-IRB' --,'IBM-ACCT' ) --Added IBM-ACCT 9-18-07

Update  dbo.XX_BMS_IW_ACCOUNT_DATA
 SET HR_TYPE_BMSIW = 'IGA', OWNING_LOB_CD='IGA',HR_TYPE_16 = 'CR', acct_typ_cd='G'
 WHERE RTRIM(RPTGRP_CONTROL_CD)='IBM-ACCT' --Added IBM-ACCT 9-18-07


-- Begin CR-7554 Changes For all non div-16 accounts,
--if RPTGRP_CONTROL_CD is GBS-SI then UTIL_TYP_CD='SIU', acct_typ_cd=S
-- No change to Owning LOB 
Update  dbo.XX_BMS_IW_ACCOUNT_DATA
 SET HR_TYPE_BMSIW = 'SIU', ACCT_TYP_CD='S'
WHERE ACCT_TYP_CD in ('I','T')
AND RTRIM(RPTGRP_CONTROL_CD)='GBS-SI' 

SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT

IF  @out_SystemError <> 0	
	BEGIN
		Set @ReturnCode = 1
		GOTO ErrorProcessing
	END 



--END CR-1305 changes 10/15/2007



/* Commented 10/08/07 DR-1267
-- If the value in PACT's RPTGRP_CONTROL_CD  field is 'IGS-IRB' then provide CR Utilization credit.
UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA
SET HR_TYPE_BMSIW = 'RIG', HR_TYPE_16 = 'CR'
WHERE RTRIM(RPTGRP_CONTROL_CD)= 'IGS-IRB';
*/

/* No longer needed for DR-1318 BTOs will now get CR/BOL credit
-- If LOB of Cntry/Comp/Div/Dept combination = BIS and account type = I or T and the value in PACT's RPTGRP_CONTROL_CD field is 'IGS-IRB' or 'IBM-ACCT' 
-- then provide CR Utilization credit.
-- Added as recd from PD
 Update  dbo.XX_BMS_IW_ACCOUNT_DATA
 SET HR_TYPE_BMSIW = 'RIG', HR_TYPE_16 = 'CR'
 WHERE RTRIM(RPTGRP_CONTROL_CD) IN ( 'IGS-IRB','IBM-ACCT' ) --Added IBM-ACCT 9-18-07
 and acct_typ_cd IN('I','T') --Added 9-18-07
 and HR_TYPE_16 <> 'CR';


-- that is a way to select all contracts for BTO
UPDATE dbo.XX_BMS_IW_ACCOUNT_DATA 
SET BUS_MEAS_DIV_CD = t2.BUS_MEAS_DIV_CD
FROM dbo.XX_BMS_IW_ACCOUNT_DATA t
INNER JOIN
	BMSIW..BMSIW.BUS_TYP_REF_UV t2 
ON
    rtrim(t.OWNING_COUNTRY_CD)=rtrim(t2.COUNTRY_CD)
    AND rtrim(t.OWNING_COMPANY_CD)=rtrim(t2.COMPANY_CD)
    AND rtrim(t.BUS_TYP_CD)=rtrim(t2.BUS_TYP_CD)  
	and rtrim(t2.BUS_MEAS_DIV_CD)='7F'

-- If LOB = BTO and Chrg_Method_Cd <> NON then give BIL utilization 
UPDATE DBO.XX_BMS_IW_ACCOUNT_DATA
SET HR_TYPE_BMSIW = 'BIL', HR_TYPE_16 = 'B'
WHERE RTRIM(ACCT_TYP_CD) = 'C'
AND RTRIM(BUS_MEAS_DIV_CD) = '7F'
*/

--End of New Code 08/01/2007

-- END DOU HR TYPE Updates


--SATISFY CONSUMPTION REQUIREMENTS FOR NEWLY POSTED LABOR
INSERT INTO dbo.XX_UTIL_LAB_OUT
(STATUS_RECORD_NUM ,TS_LN_KEY, EMPL_ID, LAST_FIRST_NAME, EMPL_HOME_ORG_ID,
 EMPL_HOME_ORG_NAME, CONTRACT_ID, CONTRACT_NAME, PROJ_ABBRV_CD, PROJ_NAME,
INDUSTRY, KEY_ACCOUNT, HR_TYPE,TS_DT, POSTING_DT, ENTERED_HRS, PERIOD_END_DT,
ACCT_STATUS, CONTACT_NAME, PRIME_CONTR_ID, CUSTOMER_NO, SOW_TYP_CD, 
OWNING_DIV_CD, OWNING_COUNTRY_CD, OWNING_COMPANY_CD, ACCT_TYP_CD, OWNING_LOB_CD,
CTRY_CD, CMPNY_CD, ACCOUNT_ID, PROJ_ID, PM_EMPL_ID, ACCTGRP_ID, CHRG_ACTV_CD,
UTIL_TYP_CD, ACCT_GRP_CD, PAY_TYPE)

SELECT @in_STATUS_RECORD_NUM 	as STATUS_RECORD_NUM,
	a.TS_LN_KEY 		as TS_LN_KEY,
	a.EMPL_ID 		as EMPL_ID, 
	LEFT(b.LAST_NAME + ' ' + b.FIRST_NAME,40) as LAST_FIRST_NAME,
	c.ORG_ID	as EMPL_HOME_ORG_ID, --CR-1414 change EMPL_HOME_ORG Changed to ORG_ID
	LEFT(c.ORG_NAME,25) EMPL_HOME_ORG_NAME, 
	--LEFT(c.EMPL_HOME_ORG_NAME, 25) as EMPL_HOME_ORG_NAME, CR-1414 Change
	dbo.XX_GET_CONTRACT_UF(d.PROJ_ID) as CONTRACT_ID,
	LEFT(d.L1_PROJ_NAME, 25)	as CONTRACT_NAME, 
	d.PROJ_ABBRV_CD		as PROJ_ABBRV_CD,
	d.PROJ_NAME		as PROJ_NAME,
	h.INDUSTRY		as INDUSTRY,
	h.KEY_ACCOUNT		as KEY_ACCOUNT,
	dbo.XX_GET_HR_TYPE_UF(d.PROJ_ID, NULL) as HR_TYPE,
	a.EFFECT_BILL_DT 	as TS_DT, 
	dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(a.TS_DT ) as POSTING_DT,
	a.CHG_HRS		as ENTERED_HRS, -- CR-1414 changed ENTERED_HRS
	dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(a.EFFECT_BILL_DT )as PERIOD_END_DT,  
	CASE  	WHEN d.ACTIVE_FL = 'N'	THEN 'C'
		ELSE 'O'
	END	 as ACCT_STATUS,
	LEFT(g.UDEF_TXT, 15) as CONTACT_NAME,
	d.PRIME_CONTR_ID as PRIME_CONTR_ID,
	dbo.XX_GET_CUSTOMER_FOR_PROJECT_UF(d.PROJ_ID) as CUSTOMER_NO,
/*u*/	dbo.XX_GET_SOW_TYP_CD_UF(d.PROJ_ID) as SOW_TYP_CD,
	-- Modified for CR-3098
	CASE WHEN SUBSTRING(d.org_id,1,2)='16' THEN '16'
		ELSE '1M'
	END as OWNING_DIV_CD,
	--/*u*/	'16' as OWNING_DIV_CD,
/*u*/	'897' as OWNING_COUNTRY_CD,
	CASE WHEN SUBSTRING(d.org_id,1,2)='16' THEN 'IBM'
		ELSE 'NIAS'
	END as OWNING_COMPANY_CD,
	--/*u*/	'IBM' as OWNING_COMPANY_CD,
/*u*/   dbo.XX_GET_ACCT_TYP_CD_UF(dbo.XX_GET_HR_TYPE_UF(d.PROJ_ID, a.ACCT_ID)) as ACCT_TYP_CD,
/*u*/	'BIS' as OWNING_LOB_CD,
/*u*/	'897' as CTRY_CD,
	CASE WHEN SUBSTRING(c.org_id,1,2)='16' THEN 'IBM'
		ELSE 'NIAS'
	END as CMPNY_CD,
    --END for CR-3098
	--Modified 12/5/2010
/*u*/	d.PROJ_ABBRV_CD as ACCOUNT_ID,
	d.PROJ_ID as PROJ_ID,
	ISNULL(d.EMPL_ID, 'UNK') as PM_EMPL_ID,
	dbo.XX_GET_CONTRACT_UF(d.PROJ_ID)  as ACCTGRP_ID,
    CHRG_ACTV_CD=
        isnull(CASE CHARINDEX('ACTVT_CD', a.notes, 1)
          WHEN 0 THEN NULL
         ELSE substring(a.notes,CHARINDEX('ACTVT_CD', a.notes, 1)+8,6)
        END   --Added for CR-1333 , 
		,'000000'),
/*u*/   dbo.XX_GET_UTIL_TYP_CD_UF(dbo.XX_GET_HR_TYPE_UF(d.PROJ_ID, a.ACCT_ID)) as UTIL_TYP_CD, -- Added CR-1305
	d.ACCT_GRP_CD,
	RTRIM(a.pay_type)		-- Added CR-1539
--CR-1414 Change Begin
FROM dbo.XX_IMAPS_TS_UTIL_DATA a
	INNER JOIN IMAPS.Deltek.EMPL b ON a.EMPL_ID = b.EMPL_ID
	INNER JOIN 
		/*(SELECT
		TS_HDR_SEQ_NO,TS_DT,EMPL_ID,
		S_TS_TYPE_CD,EMPL_HOME_ORG_ID,
		ORG_NAME AS EMPL_HOME_ORG_NAME,
		PD_NO,SUB_PD_NO
		FROM IMAPS.Deltek.TS_HDR_HS a1 
			INNER JOIN */  
            IMAPS.Deltek.ORG c ON a.ORG_ID = c.ORG_ID AND c.COMPANY_ID=@in_COMPANY_ID -- Modified for CR-1543
		/*IMAPS.Deltek.ORG b1 ON a1.EMPL_HOME_ORG_ID = b1.ORG_ID
			) c ON 
			a.TS_HDR_SEQ_NO = c.TS_HDR_SEQ_NO AND
			a.TS_DT = c.TS_DT AND
			a.EMPL_ID = c.EMPL_ID AND
			a.S_TS_TYPE_CD = c.S_TS_TYPE_CD */
	INNER JOIN IMAPS.Deltek.PROJ d ON a.PROJ_ID = d.PROJ_ID AND d.COMPANY_ID=@in_COMPANY_ID -- Modified for CR-1543
	LEFT JOIN IMAPS.Deltek.proj_rpt_proj f ON ( (d.L1_PROJ_SEG_ID + '.' + d.L2_PROJ_SEG_ID) = f.PROJ_ID AND left(f.PROJ_RPT_ID, 4) = 'INDU')
				AND f.COMPANY_ID=@in_COMPANY_ID -- Modified for CR-1543
	LEFT JOIN dbo.XX_UTIL_ALT_PROJ_INDU h ON ( LEFT(f.PROJ_RPT_ID, 16) = h.PROJ_RPT_ID )
	LEFT JOIN IMAPS.Deltek.genl_udef g ON (g.GENL_ID = d.PROJ_ID AND g.UDEF_LBL_KEY = 8)
				AND g.COMPANY_ID=@in_COMPANY_ID -- Modified for CR-1543
WHERE
--here we have portion that will put last post or period restriction on timsheets selected
 ((@LastReportedTsLnKeyNum is NOT NULL AND
 @LastReportedTsLnKeyNum < a.TS_LN_KEY) OR
 (DATEDIFF(day, a.TS_DT,@PeriodStartDate) <= 0 AND 
DATEDIFF(day, a.TS_DT,@PeriodEndDate) >= 0))
-- end 01/27/2006 TP  DEV00000453

--begin 12/14/06 
AND
--prashant doesn't want retroactive timesheets in utilization
right(rtrim(a.notes), len(a.org_id)) <> a.org_id --rate retro timesheets
AND 
right(rtrim(a.notes), 2) COLLATE Latin1_General_CS_AS not in ('-n','-p') --ceris retro timesheets
--Modified for DR2717 added '-'
--end 12/14/06
--Added Collate CR-4887 11/26/2012

-- Miscode Processor
-- Insert the previously failed records to XX_UTIL_LAB_OUT
-- It may have been due to records failed join conditions
INSERT INTO dbo.XX_UTIL_LAB_OUT
(STATUS_RECORD_NUM ,TS_LN_KEY, EMPL_ID, LAST_FIRST_NAME, EMPL_HOME_ORG_ID,
 EMPL_HOME_ORG_NAME, CONTRACT_ID, CONTRACT_NAME, PROJ_ABBRV_CD, PROJ_NAME,
INDUSTRY, KEY_ACCOUNT, HR_TYPE,TS_DT, POSTING_DT, ENTERED_HRS, PERIOD_END_DT,
ACCT_STATUS, CONTACT_NAME, PRIME_CONTR_ID, CUSTOMER_NO, SOW_TYP_CD, 
OWNING_DIV_CD, OWNING_COUNTRY_CD, OWNING_COMPANY_CD, ACCT_TYP_CD, OWNING_LOB_CD,
CTRY_CD, CMPNY_CD, ACCOUNT_ID, PROJ_ID, PM_EMPL_ID, ACCTGRP_ID, CHRG_ACTV_CD,
UTIL_TYP_CD, ACCT_GRP_CD, PAY_TYPE)

SELECT @in_STATUS_RECORD_NUM 	as STATUS_RECORD_NUM,
	a.TS_LN_KEY 		as TS_LN_KEY,
	a.EMPL_ID 		as EMPL_ID, 
	LEFT(b.LAST_NAME + ' ' + b.FIRST_NAME,40) as LAST_FIRST_NAME,
	c.ORG_ID	as EMPL_HOME_ORG_ID, --CR-1414 change EMPL_HOME_ORG Changed to ORG_ID
	NULL EMPL_HOME_ORG_NAME, 
	--LEFT(c.EMPL_HOME_ORG_NAME, 25) as EMPL_HOME_ORG_NAME, CR-1414 Change
	dbo.XX_GET_CONTRACT_UF(d.PROJ_ID) as CONTRACT_ID,
	LEFT(d.L1_PROJ_NAME, 25)	as CONTRACT_NAME, 
	d.PROJ_ABBRV_CD		as PROJ_ABBRV_CD,
	d.PROJ_NAME		as PROJ_NAME,
	h.INDUSTRY		as INDUSTRY,
	h.KEY_ACCOUNT		as KEY_ACCOUNT,
	dbo.XX_GET_HR_TYPE_UF(d.PROJ_ID, NULL) as HR_TYPE,
	a.EFFECT_BILL_DT 	as TS_DT, 
	dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(a.TS_DT ) as POSTING_DT,
	a.CHG_HRS		as ENTERED_HRS, -- CR-1414 changed ENTERED_HRS
	dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(a.EFFECT_BILL_DT )as PERIOD_END_DT,  
	CASE  	WHEN d.ACTIVE_FL = 'N'	THEN 'C'
		ELSE 'O'
	END	 as ACCT_STATUS,
	LEFT(g.UDEF_TXT, 15) as CONTACT_NAME,
	d.PRIME_CONTR_ID as PRIME_CONTR_ID,
	dbo.XX_GET_CUSTOMER_FOR_PROJECT_UF(d.PROJ_ID) as CUSTOMER_NO,
/*u*/	dbo.XX_GET_SOW_TYP_CD_UF(d.PROJ_ID) as SOW_TYP_CD,
	-- Modified for CR-3098
	CASE WHEN SUBSTRING(d.org_id,1,2)='16' THEN '16'
		ELSE '1M'
	END as OWNING_DIV_CD,
	--/*u*/	'16' as OWNING_DIV_CD,
/*u*/	'897' as OWNING_COUNTRY_CD,
	CASE WHEN SUBSTRING(d.org_id,1,2)='16' THEN 'IBM'
		ELSE 'NIAS'
	END as OWNING_COMPANY_CD,
	--/*u*/	'IBM' as OWNING_COMPANY_CD,
/*u*/   dbo.XX_GET_ACCT_TYP_CD_UF(dbo.XX_GET_HR_TYPE_UF(d.PROJ_ID, a.ACCT_ID)) as ACCT_TYP_CD,
/*u*/	'BIS' as OWNING_LOB_CD,
/*u*/	'897' as CTRY_CD,
	CASE WHEN SUBSTRING(c.org_id,1,2)='16' THEN 'IBM'
		ELSE 'NIAS'
	END as CMPNY_CD,
    --END for CR-3098
/*u*/	d.PROJ_ABBRV_CD as ACCOUNT_ID,
	d.PROJ_ID as PROJ_ID,
	ISNULL(d.EMPL_ID, 'UNK') as PM_EMPL_ID,
	dbo.XX_GET_CONTRACT_UF(d.PROJ_ID)  as ACCTGRP_ID,
    CHRG_ACTV_CD=
        isnull(CASE CHARINDEX('ACTVT_CD', a.notes, 1)
          WHEN 0 THEN NULL
         ELSE substring(a.notes,CHARINDEX('ACTVT_CD', a.notes, 1)+8,6)
        END   --Added for CR-1333 , 
		,'000000'),
/*u*/   dbo.XX_GET_UTIL_TYP_CD_UF(dbo.XX_GET_HR_TYPE_UF(d.PROJ_ID, a.ACCT_ID)) as UTIL_TYP_CD, -- Added CR-1305
	d.ACCT_GRP_CD,
	RTRIM(a.PAY_TYPE)		--Added CR-1539
--CR-1414 Change Begin
FROM dbo.XX_IMAPS_TS_UTIL_DATA a
	INNER JOIN IMAPS.Deltek.EMPL b ON a.EMPL_ID = b.EMPL_ID
	INNER JOIN IMAPS.Deltek.ORG c ON a.ORG_ID = c.ORG_ID AND c.COMPANY_ID=@in_COMPANY_ID -- Modified for CR-1543
	INNER JOIN IMAPS.Deltek.PROJ d ON a.PROJ_ID = d.PROJ_ID AND d.COMPANY_ID=@in_COMPANY_ID -- Modified for CR-1543
	LEFT JOIN IMAPS.Deltek.proj_rpt_proj f ON ( (d.L1_PROJ_SEG_ID + '.' + d.L2_PROJ_SEG_ID) = f.PROJ_ID AND left(f.PROJ_RPT_ID, 4) = 'INDU')
			AND f.COMPANY_ID=@in_COMPANY_ID -- Modified for CR-1543
	LEFT JOIN dbo.XX_UTIL_ALT_PROJ_INDU h ON ( LEFT(f.PROJ_RPT_ID, 16) = h.PROJ_RPT_ID )
	LEFT JOIN IMAPS.Deltek.genl_udef g ON (g.GENL_ID = d.PROJ_ID AND g.UDEF_LBL_KEY = 8)
			AND g.COMPANY_ID=@in_COMPANY_ID -- Modified for CR-1543
WHERE UTIL_PROCESS_DATE is null and		-- Only Reprocess where the records failed to process earlier
(@LastReportedTsLnKeyNum is NOT NULL AND
 a.TS_LN_KEY<@LastReportedTsLnKeyNum)	-- Only pick the records where the TS_LN_KEY is of prior runs
AND
--prashant doesn't want retroactive timesheets in utilization
right(rtrim(a.notes), len(a.org_id)) <> a.org_id --rate retro timesheets
AND 
right(rtrim(a.notes), 1) COLLATE Latin1_General_CS_AS not in ('-n','-p') --ceris retro timesheets
--Modified for DR2717 added '-'
--Added Collate CR-4887 11/26/2012

-- Miscode updater
-- Update the UTIL_PROCESS_DATE for the records xfered to xx_util_lab_out table
UPDATE DBO.XX_IMAPS_TS_UTIL_DATA
SET util_process_date=CONVERT(CHAR, getdate(), 101) 
WHERE ts_ln_key IN (SELECT ts_ln_key FROM xx_util_lab_out)



-- END CR-1414 Change

/* CR-1414 Commented
FROM IMAPS.Deltek.TS_LN_HS a
	INNER JOIN IMAPS.Deltek.EMPL b ON a.EMPL_ID = b.EMPL_ID
	INNER JOIN 
		(SELECT
		TS_HDR_SEQ_NO,TS_DT,EMPL_ID,
		S_TS_TYPE_CD,EMPL_HOME_ORG_ID,
		ORG_NAME AS EMPL_HOME_ORG_NAME,
		PD_NO,SUB_PD_NO
		FROM IMAPS.Deltek.TS_HDR_HS a1 
			INNER JOIN IMAPS.Deltek.ORG b1 ON a1.EMPL_HOME_ORG_ID = b1.ORG_ID
			) c ON 
			a.TS_HDR_SEQ_NO = c.TS_HDR_SEQ_NO AND
			a.TS_DT = c.TS_DT AND
			a.EMPL_ID = c.EMPL_ID AND
			a.S_TS_TYPE_CD = c.S_TS_TYPE_CD 
	INNER JOIN IMAPS.Deltek.PROJ d ON a.PROJ_ID = d.PROJ_ID
	LEFT JOIN IMAPS.Deltek.proj_rpt_proj f ON ( (d.L1_PROJ_SEG_ID + '.' + d.L2_PROJ_SEG_ID) = f.PROJ_ID AND left(f.PROJ_RPT_ID, 4) = 'INDU')
	LEFT JOIN dbo.XX_UTIL_ALT_PROJ_INDU h ON ( LEFT(f.PROJ_RPT_ID, 16) = h.PROJ_RPT_ID )
	LEFT JOIN IMAPS.Deltek.genl_udef g ON (g.GENL_ID = d.PROJ_ID AND g.UDEF_LBL_KEY = 8)
WHERE
--here we have portion that will put last post or period restriction on timsheets selected
 ((@LastReportedTsLnKeyNum is NOT NULL AND
 @LastReportedTsLnKeyNum < a.TS_LN_KEY) OR
 (DATEDIFF(day, a.TS_DT,@PeriodStartDate) <= 0 AND 
DATEDIFF(day, a.TS_DT,@PeriodEndDate) >= 0))
-- end 01/27/2006 TP  DEV00000453

--begin 12/14/06 
AND
--prashant doesn't want retroactive timesheets in utilization
right(rtrim(a.notes), len(a.org_id)) <> a.org_id --rate retro timesheets
AND 
right(rtrim(a.notes), 1) not in ('n','p') --ceris retro timesheets
--end 12/14/06
*/

	
SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT

IF  @out_SystemError <> 0
	BEGIN
		Set @ReturnCode = 1
		GOTO ErrorProcessing
	END 


--update IMAPS UTIL DATA with DOU/BMSIW DATA
UPDATE dbo.XX_UTIL_LAB_OUT
SET 	ACCOUNT_ID = LEFT(ETIME_DOU.ACCOUNT_ID, 8)
FROM 	dbo.XX_UTIL_LAB_OUT IMAPS_UTIL
INNER JOIN
	dbo.XX_BMS_IW_DOU_DATA ETIME_DOU
ON
	IMAPS_UTIL.PROJ_ABBRV_CD = ETIME_DOU.JDE_PROJ_CODE 

-- Modified for BMSIW Interface 08/01/2007 Tejas
--THIS WILL BE DONE ON PRASHANT'S SIDE
PRINT 'PERFORMING IMAPS_UTIL UPDATE FOR DOU CONSUMPTION'
UPDATE 	dbo.XX_UTIL_LAB_OUT
SET 	SOW_TYP_CD 	= 	LEFT(BMSIW_ACCOUNT.SOW_TYP_CD, 2), 
	PROJ_NAME 	= 	LEFT(BMSIW_ACCOUNT.ACCT_DESCRIPT, 25),
	ACCT_STATUS 	= 	LEFT(BMSIW_ACCOUNT.STATUS, 1) ,
	CONTACT_NAME 	= 	LEFT(BMSIW_ACCOUNT.CONTACT_NAME, 15),
	PM_EMPL_ID 	= 	LEFT(BMSIW_ACCOUNT.CONTACT_EMP_NUM, 8) ,  
	OWNING_DIV_CD 	= 	LEFT(BMSIW_ACCOUNT.OWNING_DIV_CD, 2),
	OWNING_COUNTRY_CD = 	LEFT(BMSIW_ACCOUNT.OWNING_COUNTRY_CD, 3),
	OWNING_COMPANY_CD = 	LEFT(BMSIW_ACCOUNT.OWNING_COMPANY_CD, 8) ,
	ACCT_TYP_CD 	= 	LEFT(BMSIW_ACCOUNT.ACCT_TYP_CD, 1) ,
	OWNING_LOB_CD	= 	LEFT(BMSIW_ACCOUNT.OWNING_LOB_CD, 3) ,
	ACCOUNT_ID 	= 	LEFT(ETIME_DOU.ACCOUNT_ID, 8),
	UTIL_TYP_CD = LEFT(BMSIW_ACCOUNT.HR_TYPE_BMSIW, 3) --Added CR-1305
FROM 	dbo.XX_UTIL_LAB_OUT IMAPS_UTIL
INNER JOIN
	dbo.XX_BMS_IW_DOU_DATA ETIME_DOU
ON
	IMAPS_UTIL.PROJ_ABBRV_CD = ETIME_DOU.JDE_PROJ_CODE
INNER JOIN
	dbo.XX_BMS_IW_ACCOUNT_DATA BMSIW_ACCOUNT
ON
	ETIME_DOU.ACCOUNT_ID = BMSIW_ACCOUNT.ACCOUNT_ID
AND	ETIME_DOU.CONTROL_GROUP_CD = BMSIW_ACCOUNT.CONTROL_GROUP_CD

SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT

IF  @out_SystemError <> 0	
	BEGIN
		Set @ReturnCode = 1
		GOTO ErrorProcessing
	END 


PRINT 'IMAPS_UTIL - COMPLETE'
/* No Longer required as the function modified - CR-1305
-- This is currently being done in Oracle 
-- 08/01/2007
--Update Hour Types
	UPDATE dbo.XX_UTIL_LAB_OUT
	SET hr_type='OA'
	WHERE hr_type='GA'
*/


-- Update Hr Type based on BMSIW Data
UPDATE dbo.XX_UTIL_LAB_OUT 
	SET hr_type=(SELECT hr_type_16 FROM dbo.XX_BMS_IW_ACCOUNT_DATA 
				WHERE account_id=cp.account_id)
	from dbo.XX_UTIL_LAB_OUT cp
	WHERE rtrim(account_id) IN (SELECT rtrim(account_id) 
						FROM dbo.XX_BMS_IW_ACCOUNT_DATA 
						WHERE account_id=cp.account_id 
						AND cp.hr_type<>hr_type_16)

SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT

IF  @out_SystemError <> 0	
	BEGIN
		Set @ReturnCode = 1
		GOTO ErrorProcessing
	END 


-- Update Activity Code based on MAP table and HR_TYPE value
UPDATE 	dbo.XX_UTIL_LAB_OUT
SET 	CHRG_ACTV_CD	= 	ACTIVITY_CD
FROM 	dbo.XX_UTIL_LAB_OUT IMAPS_UTIL
INNER JOIN
	dbo.XX_BMSIW_UTIL_MAP UTIL_MAP
ON
	IMAPS_UTIL.HR_TYPE = UTIL_MAP.CHARGE_TYPE
WHERE IMAPS_UTIL.CHRG_ACTV_CD not in ('GN0900', 'GN0035') -- Added for CR-1333
--When Activity code is GN0900 or GN0035 then all hours should get CR Utilization credit in BMSIW
-- Update only where the CHRG_ACTV_CD is not in the list

--CR 1414 Change Begin
--Update Acct_typ_Cd='C' and CHRG_ACTV_CD='GN0035' for UNB Hours of direct projects
UPDATE 	dbo.XX_UTIL_LAB_OUT
SET 	CHRG_ACTV_CD	= 	'GN0035',
		ACCT_TYP_CD='C'
WHERE CHRG_ACTV_CD='GB0020'
	and ACCT_GRP_CD='UNB'
	and ACCT_TYP_CD='I'
--CR 1414 Change End

SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT

IF  @out_SystemError <> 0	
	BEGIN
		Set @ReturnCode = 1
		GOTO ErrorProcessing
	END
	
SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT

IF  @out_SystemError <> 0
	BEGIN
		Set @ReturnCode = 1
		GOTO ErrorProcessing
	END 
ELSE
	BEGIN
	SELECT @IMAPSLabRecordNum = Count(*),
		@IMAPSTotalHours = SUM(ENTERED_HRS)
	FROM dbo.XX_UTIL_LAB_OUT
	WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

	UPDATE dbo.XX_UTIL_OUT_LOG
	SET LAB_RECORD_COUNT = @IMAPSLabRecordNum,
		TOTAL_LABOR_HOURS = @IMAPSTotalHours
	WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

	END



-- get organizational structure
INSERT INTO dbo.XX_UTIL_ORG_OUT	( STATUS_RECORD_NUM,
	DIVISION,
	PRACTICE_AREA,
	ORG_ID,
	ORG_ABBRV_CD,
	ORG_NAME,
	SERVICE_AREA,
	SERVICE_AREA_DESC)
SELECT 	@in_STATUS_RECORD_NUM,
	LEFT(LTRIM(a.L1_ORG_SEG_ID),2) AS DIVISION,
	c.REORG_ID AS PRACTICE_AREA,
	a.ORG_ID,
	a.ORG_ABBRV_CD,
	a.ORG_NAME,
	CAST( (c.L3_REORG_SEG_ID + ',' + c.L4_REORG_SEG_ID) as varchar(20)) AS SERVICE_AREA,
	c.L4_REORG_NAME as SERVICE_AREA_DESC
FROM 
	IMAPS.Deltek.ORG a 
inner join
	IMAPS.Deltek.reorg_org_link  b
on
	( a.ORG_ID = b.ORG_ID )
inner join
	IMAPS.Deltek.reorg_struc c
on
	( b.REORG_ID = c.REORG_ID )
WHERE 	a.L2_ORG_SEG_ID <>'F' AND  
	a.L2_ORG_SEG_ID <>'N' AND
	a.L2_ORG_SEG_ID <>'S' AND   -- 01/26/2006 TP
	a.LVL_NO = 4 
	AND a.COMPANY_ID=@in_COMPANY_ID -- Modified for CR-1543
	AND b.COMPANY_ID=@in_COMPANY_ID -- Modified for CR-1543
	AND c.COMPANY_ID=@in_COMPANY_ID -- Modified for CR-1543
	AND RTRIM(a.ORG_ABBRV_CD) <>'' --Modified CR-3098
ORDER BY a.ORG_ID	

SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT

IF  @out_SystemError <> 0	
	BEGIN
		Set @ReturnCode = 1
		GOTO ErrorProcessing
	END 
ELSE
	BEGIN
	SELECT @IMAPSOrgRecordNum = Count(*)
	FROM dbo.XX_UTIL_ORG_OUT
	WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

	UPDATE dbo.XX_UTIL_OUT_LOG
	SET ORG_RECORD_COUNT = @IMAPSOrgRecordNum
	WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM
	END
	
/* upate status table with record total, hours will not be stored
in status table since record number is a mix of labor and org. records
for detailed info see XX_UTIL_OUT_LOG
*/
UPDATE dbo.XX_IMAPS_INT_STATUS 
SET 
RECORD_COUNT_INITIAL = @IMAPSOrgRecordNum + @IMAPSLabRecordNum
WHERE 
STATUS_RECORD_NUM = @in_status_record_num

SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT

IF  @out_SystemError <> 0	
	BEGIN
		Set @ReturnCode = 1
		GOTO ErrorProcessing
	END 


-- change KM 1/11/06
-- for the BMS_IW interface, these values cannot be NULL
-- therefore, they are defaulted when DOU account not found
-- in BMS_IW
UPDATE dbo.XX_UTIL_LAB_OUT
SET ACCT_TYP_CD = 'I'
WHERE ACCT_TYP_CD IS NULL

--============= Owning LOB updates BEGIN===========

-- No Longer needed Since CR-1414, All the owning LOB is now correctly identified
-- There should not be any record with OWNING_LOB_CD =NULL
-- Update OWNING_LOB_CD with LOB_ID(dept_ref) when OWNING_LOB_CD(lob_ref) is blank
/*
UPDATE DBO.XX_UTIL_LAB_OUT
SET OWNING_LOB_CD=BMS.LOB_ID
FROM DBO.XX_UTIL_LAB_OUT UTIL
INNER JOIN
DBO.XX_BMS_IW_ACCOUNT_DATA BMS
ON RTRIM(UTIL.ACCOUNT_ID)=RTRIM(BMS.ACCOUNT_ID)
WHERE 
--UTIL.OWNING_LOB_CD NOT IN ('IGA','IRB') AND  -- Removed 1/18/08 DR-1428
UTIL.OWNING_LOB_CD IS NULL -- Added 10/29/07
*/
-- Update Owning LOB for all commercial accounts of Div.16
-- Update Owning LOB for all commercial accounts FOR Div.16
-- The Non-Div16 accounts have already got the LOB value from LOB_REF_UV table
UPDATE DBO.XX_UTIL_LAB_OUT
SET owning_lob_cd=B.LOB
FROM 
	ETIME..INTERIM.BMSIW_ACCOUNT_UV A
	--Modified for CR-4887 01/17/2013 Pointer changed
	INNER JOIN
	BMSIW..BMSIW.LOB_OFFER_REF2_UV B  -- Modified for CR-1414 (REF2)
	ON
	(A.OFFERING_COMP_CD = B.OFFER_COMP_CD AND A.CONTROL_GROUP_CD ='NA1')
	INNER JOIN 
	DBO.XX_UTIL_LAB_OUT UTIL
	ON
	(A.ACCOUNT_ID=UTIL.ACCOUNT_ID
	and UTIL.ACCOUNT_ID NOT IN (SELECT ACCOUNT_ID FROM XX_BMS_IW_ACCOUNT_DATA)) --Added 10/29/07
WHERE util.acct_typ_cd='C'

--Added CR-1333 
-- ~~ accounts should get OTH as Owning LOB
UPDATE DBO.XX_UTIL_LAB_OUT
SET OWNING_LOB_CD='OTH'
WHERE ACCOUNT_ID like '~~%'

-- Update Owning LOB for IGS-IRB, IBM-ACCT types account (CR-1305)
UPDATE DBO.XX_UTIL_LAB_OUT
SET OWNING_LOB_CD=BMS.OWNING_LOB_CD
FROM DBO.XX_UTIL_LAB_OUT UTIL
     INNER JOIN
     DBO.XX_BMS_IW_ACCOUNT_DATA BMS
     ON RTRIM(UTIL.ACCOUNT_ID)=RTRIM(BMS.ACCOUNT_ID)
and RPTGRP_CONTROL_CD IN ('IGS-IRB','IBM-ACCT')

-- If acty_typ_cd is 'C' and owning lob is null then assign OTH
UPDATE DBO.XX_UTIL_LAB_OUT
SET owning_lob_cd='OTH'
WHERE acct_typ_cd='C' and owning_lob_cd is null

-- Update Owning LOB for I accounts where charge code is 'XL0H00', 'VL0947'
UPDATE DBO.XX_UTIL_LAB_OUT
SET OWNING_LOB_CD='EDU'
WHERE CHRG_ACTV_CD IN ('XL0H00', 'VL0947')
and ACCT_TYP_CD='E'

-- Update Owning LOB for I accounts where charge code is 'X%'
UPDATE DBO.XX_UTIL_LAB_OUT
SET OWNING_LOB_CD='TAW'
WHERE CHRG_ACTV_CD LIKE 'X%'
and ACCT_TYP_CD='A'

-- Update Owning LOB for I accounts where charge code is 'V%'
UPDATE DBO.XX_UTIL_LAB_OUT
SET OWNING_LOB_CD='NPR'
WHERE CHRG_ACTV_CD LIKE 'V%'
and ACCT_TYP_CD='I'

/*
--10/29/07 - No Longer needed
-- Update Owning LOB for all commercial accounts
-- Some Owning LOB came up blank so run this again.
UPDATE DBO.XX_UTIL_LAB_OUT
SET OWNING_LOB_CD=BMS.LOB_ID
FROM DBO.XX_UTIL_LAB_OUT UTIL
INNER JOIN
DBO.XX_BMS_IW_ACCOUNT_DATA BMS
ON RTRIM(UTIL.ACCOUNT_ID)=RTRIM(BMS.ACCOUNT_ID)
WHERE UTIL.OWNING_LOB_CD IS NULL
*/

--Added for CR-1333
-- Update Hr Type based on BMSIW Data
UPDATE dbo.XX_UTIL_LAB_OUT 
SET hr_type='CR', UTIL_TYP_CD='CNB'
where CHRG_ACTV_CD in ('GN0900', 'GN0035') -- Added for CR-1333
and ACCT_TYP_CD='C' and owning_lob_cd='BIS'

/*
UPDATE dbo.XX_UTIL_LAB_OUT 
SET hr_type='CR', UTIL_TYP_CD='RIG'
where CHRG_ACTV_CD in ('GN0900', 'GN0035') -- Added for CR-1333
and hr_type<>'CR'
*/


SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT

IF  @out_SystemError <> 0	
	BEGIN
		Set @ReturnCode = 1
		GOTO ErrorProcessing
	END 


--============= Owning LOB updates END===========

-- Update UTIL_TYP_CD for IGA and IRBs
--if RPTGRP_CONTROL_CD='IGS-IRB' then set SOW='I' and OWNING_LOB='IRB' ---> UTIL_TYP_CD will be RIR
UPDATE 	dbo.XX_UTIL_LAB_OUT
SET 	UTIL_TYP_CD='RIR'
WHERE OWNING_LOB_CD='IRB'

--if RPTGRP_CONTROL_CD='IBM_ACCT' then set SOW='G' and OWNING_LOB='IGA' ---> UTIL_TYP_CD will be IGA
UPDATE 	dbo.XX_UTIL_LAB_OUT
SET 	UTIL_TYP_CD='IGA'
WHERE OWNING_LOB_CD='IGA'
-- End UTIL_TYP_CD updates

UPDATE dbo.XX_UTIL_LAB_OUT
SET OWNING_LOB_CD = 'BIS' 
WHERE OWNING_LOB_CD IS NULL

UPDATE dbo.XX_UTIL_LAB_OUT
SET OWNING_COUNTRY_CD = '897'
WHERE OWNING_COUNTRY_CD IS NULL

UPDATE dbo.XX_UTIL_LAB_OUT
SET OWNING_COMPANY_CD = 'IBM     '
WHERE OWNING_COMPANY_CD IS NULL
--end change KM 1/11/06

--Begin CR-1539 Change
-- Update where PAY_TYPE is not blank and not null for DOUs
update dbo.xx_util_lab_out
set HR_TYPE='SB', ACCT_TYP_CD='N', CHRG_ACTV_CD='VL0809', UTIL_TYP_CD='NPR', OWNING_LOB_CD='NPR'
where (rtrim(pay_type)<>'' --and PAY_TYPE IS NOT NULL
and PAY_TYPE IN ('STB','STW') -- Added CR-4887 Commented NOT NULL
and account_id<>proj_abbrv_cd)

-- Update where PAY_TYPE is not blank and not null for Non-DOUs
update dbo.xx_util_lab_out
set HR_TYPE='SB', ACCT_TYP_CD='N', CHRG_ACTV_CD='VL0809', UTIL_TYP_CD='NPR', OWNING_LOB_CD='NPR', ACCOUNT_ID='SKSI'
where (rtrim(pay_type)<>'' --and PAY_TYPE IS NOT NULL
and PAY_TYPE IN ('STB','STW') -- Added CR-4887 Commented NOT NULL
and account_id=proj_abbrv_cd)
-- End CR-1539 Change

--Begin CR-2361 Change
--Projects in NonOA Codes will get IP Credit
UPDATE xx_util_lab_out 
SET hr_type='IP',util_typ_cd='MIN',chrg_actv_cd='GB0020', acct_typ_cd='I'
WHERE proj_id in (select proj_id from XX_UTIL_NONOA_CODES)

--End CR-2361 Change

-- Begin Change CR-12915 for BTO LOBs only.
--Additional overrides
-- If Owning LOB='BTO' and UTIL_TYPE_CD='BOL' then UTIL_TYPE_CD='BIL', HR_TYPE='B'
UPDATE xx_util_lab_out 
SET hr_type='B',util_typ_cd='BIL'
WHERE owning_lob_cd='BTO' and UTIL_TYP_CD='BOL'

-- If Owning LOB='BTO' and UTIL_TYPE_CD='POL' then UTIL_TYPE_CD='PIL', HR_TYPE='BP'
UPDATE xx_util_lab_out 
SET hr_type='BP',util_typ_cd='PIL'
WHERE owning_lob_cd='BTO' and UTIL_TYP_CD='POL'

-- If Owning LOB='BTO' and UTIL_TYPE_CD='RIG' then UTIL_TYPE_CD='MIN', HR_TYPE='IP'
UPDATE xx_util_lab_out 
SET hr_type='IP',util_typ_cd='MIN'
WHERE owning_lob_cd='BTO' and UTIL_TYP_CD='RIG'
-- End Change

SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT

IF  @out_SystemError <> 0	
	BEGIN
		Set @ReturnCode = 1
		GOTO ErrorProcessing
	END 
-- END CHANGE AMDE/KEITH 12/8/05






COMMIT TRANSACTION
RETURN 0

ErrorProcessing:
ROLLBACK TRANSACTION
RETURN @ReturnCode








go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_UTIL_LOAD_STAGING_DATA_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_UTIL_LOAD_STAGING_DATA_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_UTIL_LOAD_STAGING_DATA_SP >>>'
go



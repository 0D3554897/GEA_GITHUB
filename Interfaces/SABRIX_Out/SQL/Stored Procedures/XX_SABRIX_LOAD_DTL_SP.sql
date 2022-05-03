USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_SABRIX_LOAD_DTL_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 



CREATE PROCEDURE [dbo].[XX_SABRIX_LOAD_DTL_SP]
(
@in_STATUS_RECORD_NUM integer
)
AS

BEGIN

/************************************************************************************************  
Name:       	XX_SABRIX_LOAD_DTL_SP  
Author:     	GEA  
Created:    	08/2018  
Purpose:    	Using the IMAPS posted invoice tables to load the temp staging tables for the SABRIX interface.
	    		ii) XX_SABRIX_INV_OUT_DTL -- Detail Data.  
            	See AR Outbound Interfaces.doc for details  

Prerequisites: 	none 

Parameters: 
	Input: 	none
	Output: none   

Version: 	1.0
Notes:      	Call example  


************************************************************************************************/  


DECLARE @SP_NAME sysname

PRINT ' *~^'
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_SABRIX_LOAD_DTL_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '  *~^'
-- *~^
SET @SP_NAME = 'XX_SABRIX_LOAD_DTL_SP'




-- insert regular invoice detail records
-- there are 4 cases
-- with empl_name and with hr_bill_rate 11
-- with empl_name and without hr_bill_rate 10
-- without empl_name and with hr_bill_rate 01
-- without empl_nameout  and without hr_bill_rate 00

-- billable charge code inserted to detail record
-- calculated via XX_GET_SERVICE_OFFERING_UF

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 85 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
TRUNCATE TABLE XX_SABRIX_INV_OUT_DTL

IF @@ERROR <> 0 GOTO ERROR


-- with empl_name flag (hr_empl_name flag is the only one that actually matters)
declare @tc_agrmnt         varchar(2),
        @tc_prod_catgry    varchar(2),
        @tc_tax            varchar(2),
        @DIV_16_COMPANY_ID varchar(10)

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 103 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'SABRIX'
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 116 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
SELECT 	@tc_agrmnt = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'DFLT_TC_AGRMNT'
AND	INTERFACE_NAME_CD = 'FDS/CCS'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 126 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
SELECT 	@tc_prod_catgry = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'DFLT_TC_PROD_CATGRY'
AND	INTERFACE_NAME_CD = 'FDS/CCS'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 136 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
SELECT 	@tc_tax = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'DFLT_TC_TAX'
AND	INTERFACE_NAME_CD = 'FDS/CCS'
--end change

IF @@ERROR <> 0 GOTO ERROR

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 704 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
insert into dbo.XX_SABRIX_INV_OUT_dtl
(cust_id, proj_id, invc_id, invc_dt, acct_id, ts_dt, billed_hrs,
billed_amt, rtnge_amt, 
--bill_lab_cat_cd, bill_lab_cat_desc, --test
bill_fm_grp_no, bill_fm_grp_lbl, bill_fm_ln_no, bill_fm_ln_lbl,
cum_billed_hrs, cum_billed_amt, 
tc_agrmnt, tc_prod_catgry, tc_tax, 
ta_basic, sales_tax_amt, sales_tax_cd,
ri_billable_chg_cd,
i_mach_type,
m_product_code,
rf_gsa_indicator,
proj_abbrv_cd,
state_sales_tax_amt,
county_sales_tax_amt,
city_sales_tax_amt)
select a.cust_id, a.proj_id, a.invc_id, a.invc_dt, 
b.acct_id, isnull(a.invc_end_dt,a.invc_dt), --DR7649
0 , --sum(b.billed_hrs /* - b.write_off_hrs */), 
sum(b.billed_amt /* - b.write_off_amt */ - b.over_fee_ceil_amt - b.over_tot_ceil_amt - b.over_cst_ceil_amt + b.sales_tax_amt - b.rtnge_amt - b.disc_amt),
sum(b.rtnge_amt), 
--b.bill_lab_cat_cd, b.bill_lab_cat_desc, --test
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
0, --0 , --sum(b.billed_hrs /* - b.write_off_hrs */), 
0, --sum(b.billed_amt /* - b.write_off_amt */ - b.over_fee_ceil_amt - b.over_tot_ceil_amt - b.over_cst_ceil_amt + b.sales_tax_amt - b.rtnge_amt - b.disc_amt),
@tc_agrmnt, @tc_prod_catgry, @tc_tax,
sum(b.billed_amt /* - b.write_off_amt */ - b.over_fee_ceil_amt - b.over_tot_ceil_amt - b.over_cst_ceil_amt + b.sales_tax_amt - b.rtnge_amt - b.disc_amt), 
sum(b.sales_tax_amt), b.sales_tax_cd,
dbo.XX_GET_SERVICE_OFFERING_UF(b.trn_proj_id),
dbo.XX_GET_MACHINE_TYPE_UF(b.trn_proj_id),
dbo.XX_GET_PRODUCT_ID_UF(b.trn_proj_id),
dbo.XX_GET_GSA_UF(b.trn_proj_id),
dbo.XX_GET_PROJ_ABBRV_CD_UF(b.trn_proj_id), 
.00,
.00,
.00
from IMAPS.Deltek.BILL_INVC_HDR_HS AS a
     INNER JOIN
     IMAPS.Deltek.BILLING_DETL_HIST AS b
     ON
     (
		  (a.proj_id = b.invc_proj_id)
		  AND
		  (a.proj_spprt_sch_no = b.proj_spprt_sch_no)
		  AND
		  (a.COMPANY_ID = @DIV_16_COMPANY_ID)
     )
where a.invc_id in (select invc_id from XX_SABRIX_INV_OUT_sum where status_fl = 'U' AND bill_type = 'O')
group by a.cust_id, a.proj_id, a.invc_id, a.invc_dt, b.acct_id, a.invc_end_dt,
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
b.sales_tax_cd, b.trn_proj_id
,b.bill_lab_cat_cd, b.bill_lab_cat_desc --test
order by a.invc_id, b.bill_fm_grp_no, b.bill_fm_ln_no


IF @@ERROR <> 0 GOTO ERROR

 
 
update XX_SABRIX_INV_OUT_sum
set hr_cur_fl='Y',
	hr_cum_fl='N',
	hr_bill_rt_fl='N',
	hr_empl_name_fl='N'
--end CR 4888



-- insert milestone invoice detail records
declare @milestone_label varchar(20)
SET @milestone_label = 'MILESTONE'

 
 
insert into dbo.XX_SABRIX_INV_OUT_dtl
(cust_id, proj_id, invc_id, invc_dt, ts_dt,
billed_amt, rtnge_amt,
bill_fm_grp_no, bill_fm_grp_lbl, bill_fm_ln_no, bill_fm_ln_lbl,
cum_billed_amt, tc_agrmnt, tc_prod_catgry, tc_tax, ta_basic,
ri_billable_chg_cd,
i_mach_type,
m_product_code,
rf_gsa_indicator,
proj_abbrv_cd,
sales_tax_amt,
acct_id,
state_sales_tax_amt,
county_sales_tax_amt,
city_sales_tax_amt,
sales_tax_cd)
select a.cust_id, a.proj_id, a.invc_id, a.invc_dt, a.invc_dt,
(b.cur_due_amt - b.cur_rtnge_due), b.cur_rtnge_due, 
b.milestone_ln_key, @milestone_label, b.milestone_ln_no, CAST(b.line_desc AS varchar(20)),
(b.cur_due_amt - b.cur_rtnge_due + b.prev_billed_amt - b.prev_rtnge_amt), 
@tc_agrmnt, @tc_prod_catgry, @tc_tax,
b.cur_due_amt,
dbo.XX_GET_SERVICE_OFFERING_UF(a.proj_id),
dbo.XX_GET_MACHINE_TYPE_UF(a.proj_id),
dbo.XX_GET_PRODUCT_ID_UF(a.proj_id),
dbo.XX_GET_GSA_UF(a.proj_id),
dbo.XX_GET_PROJ_ABBRV_CD_UF(b.proj_id), 
.00,
'ANY',
.00,
.00,
.00,
a.sales_tax_cd
from imaps.deltek.milestone_hdr_hs AS a INNER JOIN imaps.deltek.milestone_ln_hs AS b
ON ((a.proj_id = b.proj_id) AND (a.milestone_invc_srl = b.milestone_invc_srl))
where a.invc_id in (select invc_id from XX_SABRIX_INV_OUT_sum where status_fl = 'U' AND hr_empl_name_fl = 'N' AND bill_type = 'M')
order by a.invc_id, b.milestone_invc_srl

IF @@ERROR <> 0 GOTO ERROR

-- insert milestone invoice tax line
--declare @milestone_label varchar(20)
SET @milestone_label = 'TOTAL TAX'

 
 
insert into dbo.XX_SABRIX_INV_OUT_dtl
(cust_id, proj_id, invc_id, invc_dt, ts_dt,
billed_amt, rtnge_amt,
bill_fm_grp_no, bill_fm_grp_lbl, bill_fm_ln_no, bill_fm_ln_lbl,
cum_billed_amt, tc_agrmnt, tc_prod_catgry, tc_tax, ta_basic,
ri_billable_chg_cd,
i_mach_type,
m_product_code,
rf_gsa_indicator,
proj_abbrv_cd,
sales_tax_amt,
acct_id,
state_sales_tax_amt,
county_sales_tax_amt,
city_sales_tax_amt,
sales_tax_cd)
select a.cust_id, a.proj_id, a.invc_id, a.invc_dt, a.invc_dt,
a.sales_tax_amt, .00, 
999, @milestone_label, 999, CAST(a.sales_tax_cd + ' TAX AMOUNT' AS varchar(20)),
a.sales_tax_amt, 
@tc_agrmnt, @tc_prod_catgry, @tc_tax,
a.sales_tax_amt,
dbo.XX_GET_SERVICE_OFFERING_UF(a.proj_id),
dbo.XX_GET_MACHINE_TYPE_UF(a.proj_id),
dbo.XX_GET_PRODUCT_ID_UF(a.proj_id),
dbo.XX_GET_GSA_UF(a.proj_id),
dbo.XX_GET_PROJ_ABBRV_CD_UF(a.proj_id), 
a.sales_tax_amt,
'ANY',
.00,
.00,
.00,
a.sales_tax_cd
from imaps.deltek.milestone_hdr_hs AS a 
where a.invc_id in (select invc_id from XX_SABRIX_INV_OUT_sum where status_fl = 'U' AND hr_empl_name_fl = 'N' AND bill_type = 'M')
and a.sales_tax_amt <> .00
order by a.invc_id

IF @@ERROR <> 0 GOTO ERROR


UPDATE XX_SABRIX_INV_OUT_DTL
SET BILL_FM_GRP_LBL=UPPER(BILL_FM_GRP_LBL)

IF @@ERROR <> 0 GOTO ERROR

-- Now that we have Detail records
declare @ERROR sysname


-- Verify Detail Total and Summary Total are EQUAL
-- If they are not equal, UPDATE ERROR TABLE AND STATUS FLAG
SET @ERROR = 'SUMMARY INVOICE AMOUNT AND BILL DETAIL TOTALS DO NOT MATCH'
INSERT INTO dbo.XX_IMAPS_INV_ERROR
(STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, ERROR_DESC)
SELECT STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, @ERROR FROM dbo.XX_SABRIX_INV_OUT_SUM a
WHERE INVC_AMT <> (SELECT (SUM(BILLED_AMT)) FROM dbo.XX_SABRIX_INV_OUT_DTL
		     WHERE INVC_ID = a.INVC_ID) 
AND	INVC_ID NOT IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)


IF @@ERROR <> 0 GOTO ERROR


-- Verify Invoice Total is Not Zero 
SET @ERROR = 'THERE ARE NO DETAIL RECORDS' 
INSERT INTO dbo.XX_IMAPS_INV_ERROR
(STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, ERROR_DESC)
SELECT STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, @ERROR FROM dbo.XX_SABRIX_INV_OUT_SUM a
WHERE (0 = (SELECT COUNT(INVC_ID) FROM dbo.XX_SABRIX_INV_OUT_DTL
		     WHERE INVC_ID = a.INVC_ID))
AND	INVC_ID NOT IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)


IF @@ERROR <> 0 GOTO ERROR
 
UPDATE dbo.XX_SABRIX_INV_OUT_SUM
SET STATUS_FL = 'E'
WHERE STATUS_FL = 'U' AND INVC_ID IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)


IF @@ERROR <> 0 GOTO ERROR

 
UPDATE dbo.XX_SABRIX_INV_OUT_DTL
SET RI_BILLABLE_CHG_CD = 'OSW'
WHERE 
PROJ_ABBRV_CD = ' '
AND
ACCT_ID IS NOT NULL
AND
ACCT_ID IN
(SELECT PARAMETER_VALUE
 FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS/CCS'
 AND PARAMETER_NAME= 'SCH_BILL_OSW_ACCT_ID')
 
 
 
UPDATE dbo.XX_SABRIX_INV_OUT_DTL
SET RI_BILLABLE_CHG_CD = 'OHW'
WHERE 
PROJ_ABBRV_CD = ' '
AND
ACCT_ID IS NOT NULL
AND
ACCT_ID IN
(SELECT PARAMETER_VALUE
 FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS/CCS'
 AND PARAMETER_NAME= 'SCH_BILL_OHW_ACCT_ID')


IF @@ERROR <> 0 GOTO ERROR


DECLARE 
@IgsProjCSIDflt varchar(7),
@IgsProjBTODflt varchar(7),
@IgsProjWEBDflt varchar(7)

 
 
SELECT @IgsProjCSIDflt = ISNULL(PARAMETER_VALUE, ' ') FROM  IMAPSstg.dbo.XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'CLS' AND PARAMETER_NAME = 'IGS_CSI_PROJ_ID'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 981 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
SELECT @IgsProjBTODflt = ISNULL(PARAMETER_VALUE, ' ') FROM  IMAPSstg.dbo.XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'CLS' AND PARAMETER_NAME = 'IGS_BTO_PROJ_ID'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 989 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
SELECT @IgsProjWEBDflt = ISNULL(PARAMETER_VALUE, ' ') FROM  IMAPSstg.dbo.XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'CLS' AND PARAMETER_NAME = 'IGS_WEB_PROJ_ID'



IF @@ERROR <> 0 GOTO ERROR


 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1001 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
UPDATE dbo.XX_SABRIX_INV_OUT_DTL
SET PROJ_ABBRV_CD = 
CASE 
WHEN (PROJ_ABBRV_CD is NULL or PROJ_ABBRV_CD = ' ')  AND RI_BILLABLE_CHG_CD = 'BTO' THEN @IgsProjBTODflt
WHEN (PROJ_ABBRV_CD is NULL or PROJ_ABBRV_CD = ' ')  AND RI_BILLABLE_CHG_CD = 'WEB' THEN @IgsProjWEBDflt
WHEN (PROJ_ABBRV_CD is NULL or PROJ_ABBRV_CD = ' ')  THEN @IgsProjCSIDflt
ELSE PROJ_ABBRV_CD
END


IF @@ERROR <> 0 GOTO ERROR

-- DO CSP CALCULATIONS
CREATE TABLE #TEMP_CSP
(
[INVC_ID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
[CSP_AMT] [decimal](14, 2) NOT NULL ,
[CSP_TAX_AMT] [decimal](14, 2) NOT NULL
)

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1031 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
INSERT INTO #TEMP_CSP
(INVC_ID, CSP_AMT, CSP_TAX_AMT)
SELECT INVC_ID, SUM(BILLED_AMT), SUM(SALES_TAX_AMT) 
FROM dbo.XX_SABRIX_INV_OUT_DTL
WHERE ACCT_ID IN (SELECT PARAMETER_VALUE FROM dbo.XX_PROCESSING_PARAMETERS
		  WHERE PARAMETER_NAME = 'CSP_ACCT_ID' AND
		  INTERFACE_NAME_CD = 'FDS/CCS')
GROUP BY INVC_ID
 
UPDATE dbo.XX_SABRIX_INV_OUT_SUM
SET CSP_AMT = csp.CSP_AMT,
CSP_TAX_AMT = csp.CSP_TAX_AMT,
FDS_INV_AMT = (inv_sum.INVC_AMT - csp.CSP_AMT),
FDS_SALES_TAX_AMT = (inv_sum.SALES_TAX_AMT - csp.CSP_TAX_AMT)

FROM #TEMP_CSP AS csp
INNER JOIN dbo.XX_SABRIX_INV_OUT_SUM AS inv_sum
ON csp.INVC_ID = inv_sum.INVC_ID

DROP TABLE #TEMP_CSP


IF @@ERROR <> 0 GOTO ERROR

--change KM 02/16/05
DECLARE	@OHW_TC_TAX varchar(2),
	@OHW_TC_PROD_CATGRY varchar(2),
	@OHW_TC_AGRMNT varchar(2),
	@OSW_TC_TAX varchar(2),
	@OSW_TC_PROD_CATGRY varchar(2),
	@OSW_TC_AGRMNT varchar(2),
	@WEB_TC_TAX varchar(2),
	@WEB_TC_PROD_CATGRY varchar(2),
	@WEB_TC_AGRMNT varchar(2)

 
 
SELECT 	@OHW_TC_TAX = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'OHW_TC_TAX'
AND	INTERFACE_NAME_CD = 'FDS/CCS'

SELECT 	@OHW_TC_PROD_CATGRY = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'OHW_TC_PROD_CATGRY'
AND	INTERFACE_NAME_CD = 'FDS/CCS'

SELECT 	@OHW_TC_AGRMNT = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'OHW_TC_AGRMNT'
AND	INTERFACE_NAME_CD = 'FDS/CCS'

SELECT 	@OSW_TC_TAX = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'OSW_TC_TAX'
AND	INTERFACE_NAME_CD = 'FDS/CCS'

SELECT 	@OSW_TC_PROD_CATGRY = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'OSW_TC_PROD_CATGRY'
AND	INTERFACE_NAME_CD = 'FDS/CCS'

SELECT 	@OSW_TC_AGRMNT = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'OSW_TC_AGRMNT'
AND	INTERFACE_NAME_CD = 'FDS/CCS'

SELECT 	@WEB_TC_TAX = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'WEB_TC_TAX'
AND	INTERFACE_NAME_CD = 'FDS/CCS'

SELECT 	@WEB_TC_PROD_CATGRY = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'WEB_TC_PROD_CATGRY'
AND	INTERFACE_NAME_CD = 'FDS/CCS'

SELECT 	@WEB_TC_AGRMNT = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'WEB_TC_AGRMNT'
AND	INTERFACE_NAME_CD = 'FDS/CCS'
--end change

IF @@ERROR <> 0 GOTO ERROR

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1123 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
UPDATE  DBO.XX_SABRIX_INV_OUT_DTL
SET 	TC_TAX = @OHW_TC_TAX,
	TC_PROD_CATGRY = @OHW_TC_PROD_CATGRY,
	TC_AGRMNT = @OHW_TC_AGRMNT
WHERE	RI_BILLABLE_CHG_CD = 'OHW'


PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1134 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
UPDATE  DBO.XX_SABRIX_INV_OUT_DTL
SET 	TC_TAX = @OSW_TC_TAX,
	TC_PROD_CATGRY = @OSW_TC_PROD_CATGRY,
	TC_AGRMNT = @OSW_TC_AGRMNT
WHERE	RI_BILLABLE_CHG_CD = 'OSW'


PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1145 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
UPDATE  DBO.XX_SABRIX_INV_OUT_DTL
SET 	TC_TAX = @WEB_TC_TAX,
	TC_PROD_CATGRY = @WEB_TC_PROD_CATGRY,
	TC_AGRMNT = @WEB_TC_AGRMNT
WHERE	RI_BILLABLE_CHG_CD = 'WEB'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1156 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
UPDATE 	DBO.XX_SABRIX_INV_OUT_DTL

SET	TC_AGRMNT = 'T'
WHERE	RI_BILLABLE_CHG_CD not in ('OHW', 'OSW', 'WEB')
AND	ACCT_ID in (SELECT DISTINCT ACCT_ID FROM IMAPS.DELTEK.ACCT
		    WHERE ACCT_NAME LIKE '%travel%')


IF @@ERROR <> 0 GOTO ERROR

-- only send I_MACH_TYPE for OHW
-- only send M_PRODUCT_CODE for OSW
 

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1178 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
UPDATE 	DBO.XX_SABRIX_INV_OUT_DTL
SET	I_MACH_TYPE = '     '
WHERE 	RI_BILLABLE_CHG_CD <> 'OHW'

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1187 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
UPDATE 	DBO.XX_SABRIX_INV_OUT_DTL
SET	M_PRODUCT_CODE = '        '

IF @@ERROR <> 0 GOTO ERROR
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1202 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
update XX_SABRIX_INV_OUT_dtl
set name = ' ',
id = ' '
where bill_lab_cat_cd IS NULL


IF @@ERROR <> 0 GOTO ERROR

--ALLOCATE SALES TAX ACROSS INVOICE ACCOUNT_IDs
--FOR EACH ACCOUNT_ID with SALES TAX
--THIS IS EXTREMELY TRICKY
--COSTPOINT CALCULATES TAX ON ACCT_ID
--FDS/IBM TAX PEOPLE WANT TAX ON LINE ITEMS
--AFTER MEETING WITH PETE MORELLI, HE APPROVED/REQUESTED
--TAX FOR LINE ITEMS and SPREADING OUT EXTRA PENNIES
--IF CALCULATIONS DO NOT MATCH

SET @ERROR = 'SALES_TAX_CD DOES NOT INDICATE WHETHER TAX IS FOR STATE/COUNTY/CITY' 
INSERT INTO dbo.XX_IMAPS_INV_ERROR
(STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, ERROR_DESC)
SELECT 	DISTINCT STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, @ERROR FROM dbo.XX_SABRIX_INV_OUT_SUM
WHERE 	INVC_ID IN 
(SELECT INVC_ID FROM XX_SABRIX_INV_OUT_DTL
 WHERE 	SALES_TAX_CD IS NOT NULL 
 AND	RIGHT(SALES_TAX_CD, 1) NOT IN ('1', '2', '3'))


IF @@ERROR <> 0 GOTO ERROR


 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1238 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
UPDATE dbo.XX_SABRIX_INV_OUT_SUM
SET STATUS_FL = 'E'
WHERE STATUS_FL = 'U' AND INVC_ID IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)


IF @@ERROR <> 0 GOTO ERROR


CREATE TABLE #TEMP_TAX
(
[INVC_ID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACCT_ID] [varchar](12) NULL ,
[ACCT_SALES_TAX_AMT] decimal (14, 2) NULL,
[ACCT_BILLED_AMT] decimal(14, 2) NULL, 
[SALES_TAX_CD] [varchar] (6) NULL
)
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1260 : XX_SABRIX_LOAD_DTL_SP.sql '  
 
INSERT INTO #TEMP_TAX
(INVC_ID, ACCT_ID, ACCT_SALES_TAX_AMT, ACCT_BILLED_AMT, SALES_TAX_CD)
SELECT 	a.INVC_ID, a.ACCT_ID, b.SALES_TAX_AMT, SUM(a.BILLED_AMT), b.SALES_TAX_CD
FROM 	XX_SABRIX_INV_OUT_DTL a
INNER JOIN
	XX_SABRIX_INV_OUT_DTL b
ON	(a.INVC_ID = b.INVC_ID
AND	 a.ACCT_ID = b.ACCT_ID
AND	 a.BILLED_AMT <> a.SALES_TAX_AMT
AND	 b.BILLED_AMT = b.SALES_TAX_AMT
AND	 b.SALES_TAX_AMT <> .00)
WHERE 	RIGHT(b.SALES_TAX_CD, 1) in ('1', '2', '3')
GROUP BY a.INVC_ID, a.ACCT_ID, b.SALES_TAX_AMT, b.SALES_TAX_CD


IF @@ERROR <> 0 GOTO ERROR
 
UPDATE dbo.XX_SABRIX_INV_OUT_DTL
SET STATE_SALES_TAX_AMT = tax.ACCT_SALES_TAX_AMT * (dtl.BILLED_AMT/tax.ACCT_BILLED_AMT)
FROM #TEMP_TAX AS tax
INNER JOIN dbo.XX_SABRIX_INV_OUT_DTL AS dtl
ON tax.INVC_ID = dtl.INVC_ID
AND tax.ACCT_ID = dtl.ACCT_ID
and RIGHT(tax.SALES_TAX_CD, 1) = '1' 
WHERE dtl.SALES_TAX_AMT <> dtl.BILLED_AMT


IF @@ERROR <> 0 GOTO ERROR


--COUNTY SALES TAX
 
 
UPDATE dbo.XX_SABRIX_INV_OUT_DTL
SET COUNTY_SALES_TAX_AMT = tax.ACCT_SALES_TAX_AMT * (dtl.BILLED_AMT/tax.ACCT_BILLED_AMT)
FROM #TEMP_TAX AS tax
INNER JOIN dbo.XX_SABRIX_INV_OUT_DTL AS dtl
ON tax.INVC_ID = dtl.INVC_ID
AND tax.ACCT_ID = dtl.ACCT_ID
and RIGHT(tax.SALES_TAX_CD, 1) = '2' 
WHERE dtl.SALES_TAX_AMT <> dtl.BILLED_AMT


IF @@ERROR <> 0 GOTO ERROR


--CITY SALES TAX
 
UPDATE dbo.XX_SABRIX_INV_OUT_DTL
SET CITY_SALES_TAX_AMT = tax.ACCT_SALES_TAX_AMT * (dtl.BILLED_AMT/tax.ACCT_BILLED_AMT)
FROM #TEMP_TAX AS tax
INNER JOIN dbo.XX_SABRIX_INV_OUT_DTL AS dtl
ON tax.INVC_ID = dtl.INVC_ID
AND tax.ACCT_ID = dtl.ACCT_ID
and RIGHT(tax.SALES_TAX_CD, 1) = '3' 
WHERE dtl.SALES_TAX_AMT <> dtl.BILLED_AMT


IF @@ERROR <> 0 GOTO ERROR

--LOOP THROUGH AND FIND OUT WHICH TAX ACCOUNTS
--HAVE ROUNDING ERRORS AND TRY TO FIX THEM
DECLARE @invc_id varchar(15),
	@acct_id varchar(12),
	@acct_sales_tax_amt decimal(14,2),

	@sales_tax_cd varchar(6),
	@temp_amt decimal(14,2)

DECLARE TAX_ACCT_CURSOR CURSOR FAST_FORWARD FOR
SELECT 	tax.INVC_ID, tax.ACCT_ID, tax.ACCT_SALES_TAX_AMT, tax.SALES_TAX_CD
FROM 	#TEMP_TAX as tax
WHERE 	
(
RIGHT(tax.SALES_TAX_CD, 1) = '1' 
AND	ACCT_SALES_TAX_AMT <> (SELECT SUM(STATE_SALES_TAX_AMT) FROM dbo.XX_SABRIX_INV_OUT_DTL as dtl
		     	       WHERE 
				dtl.INVC_ID = tax.INVC_ID 
				AND dtl.ACCT_ID = tax.ACCT_ID
				AND dtl.BILLED_AMT <> dtl.SALES_TAX_AMT)
)
OR
(
RIGHT(tax.SALES_TAX_CD, 1) = '2' 
AND	ACCT_SALES_TAX_AMT <> (SELECT SUM(COUNTY_SALES_TAX_AMT) FROM dbo.XX_SABRIX_INV_OUT_DTL as dtl
		     	       WHERE 
				dtl.INVC_ID = tax.INVC_ID 
				AND dtl.ACCT_ID = tax.ACCT_ID
				AND dtl.BILLED_AMT <> dtl.SALES_TAX_AMT)
)
OR
(
RIGHT(tax.SALES_TAX_CD, 1) = '3' 
AND	ACCT_SALES_TAX_AMT <> (SELECT SUM(CITY_SALES_TAX_AMT) FROM dbo.XX_SABRIX_INV_OUT_DTL as dtl
		     	       WHERE 
				dtl.INVC_ID = tax.INVC_ID 
				AND dtl.ACCT_ID = tax.ACCT_ID
				AND dtl.BILLED_AMT <> dtl.SALES_TAX_AMT)
)

OPEN TAX_ACCT_CURSOR
FETCH TAX_ACCT_CURSOR
INTO  @invc_id, @acct_id, @acct_sales_tax_amt, @sales_tax_cd

WHILE (@@fetch_status = 0)
BEGIN

	--LOOP THROUGH AND DISTRIBUTE EXTRA PENNIES FOR CURRENT INVC_ID, ACCT_ID
	DECLARE @invc_ln int,
		@status  int

	DECLARE TAX_PENNY_CURSOR CURSOR FAST_FORWARD FOR
	SELECT 	INVC_LN 
	FROM 	XX_SABRIX_INV_OUT_DTL
	WHERE	INVC_ID = @invc_id AND ACCT_ID = @acct_id
	AND 	BILLED_AMT <> SALES_TAX_AMT
	
	OPEN TAX_PENNY_CURSOR
	FETCH TAX_PENNY_CURSOR
	INTO @invc_ln
	
	SET @status = @@fetch_status
	WHILE(@status = 0)
	BEGIN
		--STATE SALES TAX AMT
		IF(RIGHT(@sales_tax_cd, 1) = '1')
		BEGIN
			SELECT 	@temp_amt = SUM(STATE_SALES_TAX_AMT) 
			FROM 	dbo.XX_SABRIX_INV_OUT_DTL
			WHERE 	INVC_ID = @invc_id 
			AND 	ACCT_ID = @acct_id
			AND 	BILLED_AMT <> SALES_TAX_AMT
		
			IF(@temp_amt < @acct_sales_tax_amt)
			BEGIN
				UPDATE  dbo.XX_SABRIX_INV_OUT_DTL
				SET 	STATE_SALES_TAX_AMT = STATE_SALES_TAX_AMT + 0.01	
				WHERE 	INVC_LN = @invc_ln
				SET @temp_amt = @temp_amt + 0.01
			END
			ELSE IF (@temp_amt > @acct_sales_tax_amt)
			BEGIN
				UPDATE  dbo.XX_SABRIX_INV_OUT_DTL
				SET 	STATE_SALES_TAX_AMT = STATE_SALES_TAX_AMT - 0.01	
				WHERE 	INVC_LN = @invc_ln

				SET @temp_amt = @temp_amt - 0.01
			END
		END
		--COUNTY SALES TAX AMT
		ELSE IF(RIGHT(@sales_tax_cd, 1) = '2')
		BEGIN
			SELECT 	@temp_amt = SUM(COUNTY_SALES_TAX_AMT) 
			FROM 	dbo.XX_SABRIX_INV_OUT_DTL
			WHERE 	INVC_ID = @invc_id 
			AND 	ACCT_ID = @acct_id
			AND 	BILLED_AMT <> SALES_TAX_AMT
		
			IF(@temp_amt < @acct_sales_tax_amt)
			BEGIN
				UPDATE  dbo.XX_SABRIX_INV_OUT_DTL
				SET 	COUNTY_SALES_TAX_AMT = COUNTY_SALES_TAX_AMT + 0.01	
				WHERE 	INVC_LN = @invc_ln
	
				SET @temp_amt = @temp_amt + 0.01
			END
			ELSE IF (@temp_amt > @acct_sales_tax_amt)
			BEGIN
				UPDATE  dbo.XX_SABRIX_INV_OUT_DTL
				SET 	COUNTY_SALES_TAX_AMT = COUNTY_SALES_TAX_AMT - 0.01	
				WHERE 	INVC_LN = @invc_ln

				SET @temp_amt = @temp_amt - 0.01
			END
		END
		--CITY SALES TAX AMT
		ELSE IF(RIGHT(@sales_tax_cd, 1) = '3')
		BEGIN
			SELECT 	@temp_amt = SUM(CITY_SALES_TAX_AMT) 
			FROM 	dbo.XX_SABRIX_INV_OUT_DTL
			WHERE 	INVC_ID = @invc_id 
			AND 	ACCT_ID = @acct_id
			AND 	BILLED_AMT <> SALES_TAX_AMT
		
			IF(@temp_amt < @acct_sales_tax_amt)
			BEGIN
				UPDATE  dbo.XX_SABRIX_INV_OUT_DTL
				SET 	CITY_SALES_TAX_AMT = CITY_SALES_TAX_AMT + 0.01	
				WHERE 	INVC_LN = @invc_ln
	
				SET @temp_amt = @temp_amt + 0.01
			END
			ELSE IF (@temp_amt > @acct_sales_tax_amt)
			BEGIN
				UPDATE  dbo.XX_SABRIX_INV_OUT_DTL
				SET 	CITY_SALES_TAX_AMT = CITY_SALES_TAX_AMT - 0.01	
				WHERE 	INVC_LN = @invc_ln

				SET @temp_amt = @temp_amt - 0.01
			END
		END

		FETCH TAX_PENNY_CURSOR
		INTO @invc_ln

		IF @temp_amt = @acct_sales_tax_amt
		BEGIN
			SET @status = 1
		END
		ELSE
		BEGIN
			SET @status = @@fetch_status
		END
	END
	
	CLOSE TAX_PENNY_CURSOR
	DEALLOCATE TAX_PENNY_CURSOR
	
	FETCH TAX_ACCT_CURSOR
	INTO  @invc_id, @acct_id, @acct_sales_tax_amt, @sales_tax_cd

END


CLOSE TAX_ACCT_CURSOR
DEALLOCATE TAX_ACCT_CURSOR



DROP TABLE #TEMP_TAX

IF @@ERROR <> 0 GOTO ERROR


SET @ERROR = 'SUMMARY AND DETAIL TAX CALCULATIONS DO NOT MATCH' 
INSERT INTO dbo.XX_IMAPS_INV_ERROR
(STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, ERROR_DESC)
SELECT STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, @ERROR FROM dbo.XX_SABRIX_INV_OUT_SUM a
WHERE SALES_TAX_AMT <> (SELECT SUM(STATE_SALES_TAX_AMT+COUNTY_SALES_TAX_AMT+CITY_SALES_TAX_AMT) FROM dbo.XX_SABRIX_INV_OUT_DTL
		     	WHERE INVC_ID = a.INVC_ID AND BILLED_AMT <> SALES_TAX_AMT)
AND	INVC_ID NOT IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)

IF @@ERROR <> 0 GOTO ERROR


 
UPDATE dbo.XX_SABRIX_INV_OUT_SUM
SET STATUS_FL = 'E'
WHERE STATUS_FL = 'U' AND INVC_ID IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)


IF @@ERROR <> 0 GOTO ERROR


SET @ERROR = 'INVC_ID MUST BE AT LEAST 7 CHARACTERS' 
INSERT INTO dbo.XX_IMAPS_INV_ERROR
(STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, ERROR_DESC)
SELECT STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, @ERROR FROM dbo.XX_SABRIX_INV_OUT_SUM a
WHERE LEN(INVC_ID) < 7
AND	INVC_ID NOT IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)


IF @@ERROR <> 0 GOTO ERROR


 
UPDATE dbo.XX_SABRIX_INV_OUT_SUM
SET STATUS_FL = 'E'
WHERE STATUS_FL = 'U' AND INVC_ID IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)


IF @@ERROR <> 0 GOTO ERROR

PRINT ' *~^'
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF XX_SABRIX_LOAD_DTL_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '  *~^'
 
RETURN 0


ERROR: 
RETURN 1

END


 

 

 

 

 

 

 

GO
 


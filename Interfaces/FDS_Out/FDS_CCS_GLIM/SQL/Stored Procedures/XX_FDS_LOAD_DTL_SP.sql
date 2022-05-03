USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_FDS_LOAD_DTL_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 




CREATE PROCEDURE [dbo].[XX_FDS_LOAD_DTL_SP]
(
@in_STATUS_RECORD_NUM integer
)
AS

BEGIN

/************************************************************************************************  
Name:       	XX_FDS_LOAD_DTL_SP  
Author:     	CR  
Created:    	07/2005  
Purpose:    	Using the IMAPS posted invoice tables to load the temp staging tables for the FDS and CCS interfaces.
	    	ii) XX_IMAPS_INV_OUT_DTL -- Detail Data.  
            	See AR Outbound Interfaces.doc for details  

Prerequisites: 	none 

Parameters: 
	Input: 	none
	Output: none   

Version: 	1.0
Notes:      	Call example  

CHANGE KM 03/06/2007 - CHANGE TO HANDLING OF WRITE_OFFS

CP600000325     04/25/2008 (BP&S Change Request No. CR1543)
                Costpoint multi-company fix (seven instances).

DR3854 - ensure BILL_FM_GRP_LBL is always uppercase in staging table
DR3892 - subtraction of DISC_AMT from detail lines
CR4888 - changes for Actuals (level of detail for CCS file must be changed so that the following elements are no longer included:
								 employee name, rate, hours, previous amounts
DR7649 - null TS_DT issue caused FDS to be unable to process files - KM - 2014-11-03
CR9449 - GEA - 12/14/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
CR9449 - gea - 1/24/2018 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
************************************************************************************************/  


DECLARE @SP_NAME sysname

PRINT '' --CR9449 *~^
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_FDS_LOAD_DTL_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^
-- *~^
SET @SP_NAME = 'XX_FDS_LOAD_DTL_SP'


-- modified by KM - 10/3/05

-- insert regular invoice detail records
-- there are 4 cases
-- with empl_name and with hr_bill_rate 11
-- with empl_name and without hr_bill_rate 10
-- without empl_name and with hr_bill_rate 01
-- without empl_nameout  and without hr_bill_rate 00

-- modified by KM - 11/17/05
-- billable charge code inserted to detail record
-- calculated via XX_GET_SERVICE_OFFERING_UF

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 85 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
TRUNCATE TABLE XX_IMAPS_INV_OUT_DTL

IF @@ERROR <> 0 GOTO ERROR


-- with empl_name flag (hr_empl_name flag is the only one that actually matters)
declare @tc_agrmnt         varchar(2),
        @tc_prod_catgry    varchar(2),
        @tc_tax            varchar(2),
        @DIV_16_COMPANY_ID varchar(10)

-- CP600000325_Begin
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 103 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'FDS'
-- CP600000325_End

--change KM 02/16/05
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 116 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
SELECT 	@tc_agrmnt = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'DFLT_TC_AGRMNT'
AND	INTERFACE_NAME_CD = 'FDS'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 126 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
SELECT 	@tc_prod_catgry = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'DFLT_TC_PROD_CATGRY'
AND	INTERFACE_NAME_CD = 'FDS'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 136 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
SELECT 	@tc_tax = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'DFLT_TC_TAX'
AND	INTERFACE_NAME_CD = 'FDS'
--end change

IF @@ERROR <> 0 GOTO ERROR



--begin CR4888
-- ###$$### Disabled code begin. Use SQL Server Management Studio to see disabled code much better. ###$$###
/*
-- with emplname and with bill rate - CUR
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 156 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
insert into dbo.xx_imaps_inv_out_dtl
(cust_id, proj_id, invc_id, invc_dt, acct_id, ts_dt, bill_rt_amt, billed_hrs,
billed_amt, rtnge_amt, id, name, bill_lab_cat_cd, bill_lab_cat_desc,
bill_fm_grp_no, bill_fm_grp_lbl, bill_fm_ln_no, bill_fm_ln_lbl,
cum_billed_hrs, cum_billed_amt, tc_agrmnt, tc_prod_catgry, tc_tax, 
ta_basic, sales_tax_amt, sales_tax_cd, 
ri_billable_chg_cd,
i_mach_type,
m_product_code,
rf_gsa_indicator,
proj_abbrv_cd,
state_sales_tax_amt,
county_sales_tax_amt,
city_sales_tax_amt)

 
 
select a.cust_id, a.proj_id, a.invc_id, a.invc_dt, b.acct_id, a.invc_end_dt, b.bill_rt_amt, 
sum(b.billed_hrs /* - b.write_off_hrs */), 


sum(b.billed_amt /* - b.write_off_amt */ - b.over_fee_ceil_amt - b.over_tot_ceil_amt - b.over_cst_ceil_amt + b.sales_tax_amt - b.rtnge_amt - b.disc_amt),

sum(b.rtnge_amt),  b.id, b.name, b.bill_lab_cat_cd, b.bill_lab_cat_desc,
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
sum(b.billed_hrs /* - b.write_off_hrs */), 


sum(b.billed_amt /* - b.write_off_amt */ - b.over_fee_ceil_amt - b.over_tot_ceil_amt - b.over_cst_ceil_amt + b.sales_tax_amt - b.rtnge_amt - b.disc_amt),

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
     ((a.proj_id = b.invc_proj_id)
      AND
      (a.proj_spprt_sch_no = b.proj_spprt_sch_no)
-- CP600000325_Begin
      AND
      (a.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000325_End
     )
where a.invc_id in (select invc_id from xx_imaps_inv_out_sum where status_fl = 'U' AND hr_empl_name_fl = 'Y' AND hr_bill_rt_fl = 'Y' AND bill_type = 'O')
group by a.cust_id, a.proj_id, a.invc_id, a.invc_dt, b.acct_id, a.invc_end_dt, b.bill_rt_amt, b.id, b.name, b.bill_lab_cat_cd, b.bill_lab_cat_desc,

b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,

b.sales_tax_cd, b.trn_proj_id
order by a.invc_id, b.bill_fm_grp_no, b.bill_fm_ln_no



IF @@ERROR <> 0 GOTO ERROR


-- with emplname and with bill rate - PREV
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 226 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
insert into dbo.xx_imaps_inv_out_dtl
(cust_id, proj_id, invc_id, invc_dt, acct_id, ts_dt, bill_rt_amt, billed_hrs,
billed_amt, rtnge_amt, id, name, bill_lab_cat_cd, bill_lab_cat_desc,
bill_fm_grp_no, bill_fm_grp_lbl, bill_fm_ln_no, bill_fm_ln_lbl,
cum_billed_hrs, cum_billed_amt, tc_agrmnt, tc_prod_catgry, tc_tax, 
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
b.acct_id, a.invc_end_dt, b.bill_rt_amt, 
.00, 
.00,
.00,  b.id, b.name, b.bill_lab_cat_cd, b.bill_lab_cat_desc,
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
sum(b.billed_hrs /* - b.write_off_hrs */), 


sum(b.billed_amt /* - b.write_off_amt */ - b.over_fee_ceil_amt - b.over_tot_ceil_amt - b.over_cst_ceil_amt + b.sales_tax_amt - b.rtnge_amt - b.disc_amt),

@tc_agrmnt, @tc_prod_catgry, @tc_tax,
.00, .00, b.sales_tax_cd,
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
      (a.proj_id = b.invc_proj_id) AND
      (a.proj_spprt_sch_no <>  b.proj_spprt_sch_no) AND
-- CP600000325_Begin
      (a.COMPANY_ID = @DIV_16_COMPANY_ID) AND
-- CP600000325_End
      b.proj_spprt_sch_no in
         (select proj_spprt_sch_no
            from IMAPS.Deltek.BILL_INVC_HDR_HS
           where proj_id      = a.proj_id
             and cust_addr_dc = a.cust_addr_dc
-- CP600000325_Begin
             and COMPANY_ID   = @DIV_16_COMPANY_ID
-- CP600000325_End
         )
     )
where a.invc_id in (select invc_id from xx_imaps_inv_out_sum where status_fl = 'U' AND hr_empl_name_fl = 'Y' AND hr_bill_rt_fl = 'Y' AND bill_type = 'O')
group by a.cust_id, a.proj_id, a.invc_id, a.invc_dt, b.acct_id, a.invc_end_dt, b.bill_rt_amt, b.id, b.name, b.bill_lab_cat_cd, b.bill_lab_cat_desc,
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
b.sales_tax_cd, b.trn_proj_id
order by a.invc_id, b.bill_fm_grp_no, b.bill_fm_ln_no



IF @@ERROR <> 0 GOTO ERROR



-- without empl_name and without bill rate - CUR
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 301 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
insert into dbo.xx_imaps_inv_out_dtl
(cust_id, proj_id, invc_id, invc_dt, acct_id, ts_dt, billed_hrs,
billed_amt, rtnge_amt, 
bill_fm_grp_no, bill_fm_grp_lbl, bill_fm_ln_no, bill_fm_ln_lbl,
cum_billed_hrs, cum_billed_amt, tc_agrmnt, tc_prod_catgry, tc_tax, 
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
b.acct_id, a.invc_end_dt, 
sum(b.billed_hrs /* - b.write_off_hrs */), 


sum(b.billed_amt /* - b.write_off_amt */ - b.over_fee_ceil_amt - b.over_tot_ceil_amt - b.over_cst_ceil_amt + b.sales_tax_amt - b.rtnge_amt - b.disc_amt),

sum(b.rtnge_amt), 
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
sum(b.billed_hrs /* - b.write_off_hrs */), 


sum(b.billed_amt /* - b.write_off_amt */ - b.over_fee_ceil_amt - b.over_tot_ceil_amt - b.over_cst_ceil_amt + b.sales_tax_amt - b.rtnge_amt - b.disc_amt),

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
     ((a.proj_id = b.invc_proj_id)
      AND
      (a.proj_spprt_sch_no = b.proj_spprt_sch_no)
-- CP600000325_Begin
      AND
      (a.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000325_End
     )
where a.invc_id in (select invc_id from xx_imaps_inv_out_sum where status_fl = 'U' AND hr_empl_name_fl = 'N' AND hr_bill_rt_fl = 'N' AND bill_type = 'O')
group by a.cust_id, a.proj_id, a.invc_id, a.invc_dt, b.acct_id, a.invc_end_dt,
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
b.sales_tax_cd, b.trn_proj_id
order by a.invc_id, b.bill_fm_grp_no, b.bill_fm_ln_no


IF @@ERROR <> 0 GOTO ERROR


-- without empl_name and without bill rate - PREV
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 369 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
insert into dbo.xx_imaps_inv_out_dtl
(cust_id, proj_id, invc_id, invc_dt, acct_id, ts_dt, billed_hrs,
billed_amt, rtnge_amt, 
bill_fm_grp_no, bill_fm_grp_lbl, bill_fm_ln_no, bill_fm_ln_lbl,
cum_billed_hrs, cum_billed_amt, tc_agrmnt, tc_prod_catgry, tc_tax, 
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
b.acct_id, a.invc_end_dt, 
.00, 
.00,
.00, 
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
sum(b.billed_hrs /* - b.write_off_hrs */), 


sum(b.billed_amt /* - b.write_off_amt */ - b.over_fee_ceil_amt - b.over_tot_ceil_amt - b.over_cst_ceil_amt + b.sales_tax_amt - b.rtnge_amt - b.disc_amt),

@tc_agrmnt, @tc_prod_catgry, @tc_tax,
.00,
.00, b.sales_tax_cd,
dbo.XX_GET_SERVICE_OFFERING_UF(b.trn_proj_id),
dbo.XX_GET_MACHINE_TYPE_UF(b.trn_proj_id),
dbo.XX_GET_PRODUCT_ID_UF(b.trn_proj_id),
dbo.XX_GET_GSA_UF(b.trn_proj_id),
dbo.XX_GET_PROJ_ABBRV_CD_UF(b.trn_proj_id), 
.00,
.00,
.00
from IMAPS.Deltek.BILL_INVC_HDR_HS AS a
     INNER JOIN IMAPS.Deltek.BILLING_DETL_HIST AS b
     ON
     ((a.proj_id = b.invc_proj_id)
      AND
      (a.proj_spprt_sch_no <> b.proj_spprt_sch_no)
-- CP600000325_Begin
      AND
      (a.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000325_Begin
     )
where a.invc_id in (select invc_id from xx_imaps_inv_out_sum where status_fl = 'U' AND hr_empl_name_fl = 'N' AND hr_bill_rt_fl = 'N' AND bill_type = 'O')
group by a.cust_id, a.proj_id, a.invc_id, a.invc_dt, b.acct_id, a.invc_end_dt,
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
b.sales_tax_cd, b.trn_proj_id
order by a.invc_id, b.bill_fm_grp_no, b.bill_fm_ln_no

IF @@ERROR <> 0 GOTO ERROR


-- with emplname and without bill rate - CUR
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 433 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
insert into dbo.xx_imaps_inv_out_dtl
(cust_id, proj_id, invc_id, invc_dt, acct_id, ts_dt, billed_hrs,
billed_amt, rtnge_amt, id, name, bill_lab_cat_cd, bill_lab_cat_desc,
bill_fm_grp_no, bill_fm_grp_lbl, bill_fm_ln_no, bill_fm_ln_lbl,
cum_billed_hrs, cum_billed_amt, tc_agrmnt, tc_prod_catgry, tc_tax, 
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
b.acct_id, a.invc_end_dt, 
sum(b.billed_hrs /* - b.write_off_hrs */), 


sum(b.billed_amt /* - b.write_off_amt */ - b.over_fee_ceil_amt - b.over_tot_ceil_amt - b.over_cst_ceil_amt + b.sales_tax_amt - b.rtnge_amt - b.disc_amt),

sum(b.rtnge_amt),  b.id, b.name, b.bill_lab_cat_cd, b.bill_lab_cat_desc,
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
sum(b.billed_hrs /* - b.write_off_hrs */), 


sum(b.billed_amt /* - b.write_off_amt */ - b.over_fee_ceil_amt - b.over_tot_ceil_amt - b.over_cst_ceil_amt + b.sales_tax_amt - b.rtnge_amt - b.disc_amt),

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
     ((a.proj_id = b.invc_proj_id)
      AND
      (a.proj_spprt_sch_no = b.proj_spprt_sch_no)
-- CP600000325_Begin
      AND
      (a.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000325_End
     )
where a.invc_id in (select invc_id from xx_imaps_inv_out_sum where status_fl = 'U' AND hr_empl_name_fl = 'Y' AND hr_bill_rt_fl = 'N' AND bill_type = 'O')
group by a.cust_id, a.proj_id, a.invc_id, a.invc_dt, b.acct_id, a.invc_end_dt, b.bill_rt_amt, b.id, b.name, b.bill_lab_cat_cd, b.bill_lab_cat_desc,
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
b.sales_tax_cd, b.trn_proj_id
order by a.invc_id, b.bill_fm_grp_no, b.bill_fm_ln_no


IF @@ERROR <> 0 GOTO ERROR


-- with emplname and without bill rate - PREV
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 501 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
insert into dbo.xx_imaps_inv_out_dtl
(cust_id, proj_id, invc_id, invc_dt, acct_id, ts_dt, billed_hrs,
billed_amt, rtnge_amt, id, name, bill_lab_cat_cd, bill_lab_cat_desc,
bill_fm_grp_no, bill_fm_grp_lbl, bill_fm_ln_no, bill_fm_ln_lbl,
cum_billed_hrs, cum_billed_amt, tc_agrmnt, tc_prod_catgry, tc_tax, 
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
b.acct_id, a.invc_end_dt, 
.00, 
.00,
.00,  b.id, b.name, b.bill_lab_cat_cd, b.bill_lab_cat_desc,
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
sum(b.billed_hrs /* - b.write_off_hrs */), 


sum(b.billed_amt /* - b.write_off_amt */ - b.over_fee_ceil_amt - b.over_tot_ceil_amt - b.over_cst_ceil_amt + b.sales_tax_amt - b.rtnge_amt - b.disc_amt),

@tc_agrmnt, @tc_prod_catgry, @tc_tax,
.00,
.00, b.sales_tax_cd,
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
     ((a.proj_id = b.invc_proj_id)
      AND
      (a.proj_spprt_sch_no <>  b.proj_spprt_sch_no)
-- CP600000325_Begin
      AND
      (a.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000325_End
     )
where a.invc_id in (select invc_id from xx_imaps_inv_out_sum where status_fl = 'U' AND hr_empl_name_fl = 'Y' AND hr_bill_rt_fl = 'N' AND bill_type = 'O')
group by a.cust_id, a.proj_id, a.invc_id, a.invc_dt, b.acct_id, a.invc_end_dt, b.bill_rt_amt, b.id, b.name, b.bill_lab_cat_cd, b.bill_lab_cat_desc,
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
b.sales_tax_cd, b.trn_proj_id
order by a.invc_id, b.bill_fm_grp_no, b.bill_fm_ln_no



IF @@ERROR <> 0 GOTO ERROR



-- without empl_name and with bill rate - CUR
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 569 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
insert into dbo.xx_imaps_inv_out_dtl
(cust_id, proj_id, invc_id, invc_dt, acct_id, ts_dt, bill_rt_amt, billed_hrs,
billed_amt, rtnge_amt, bill_lab_cat_cd, bill_lab_cat_desc,
bill_fm_grp_no, bill_fm_grp_lbl, bill_fm_ln_no, bill_fm_ln_lbl,
cum_billed_hrs, cum_billed_amt, tc_agrmnt, tc_prod_catgry, tc_tax, 
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
b.acct_id, a.invc_end_dt, b.bill_rt_amt, 
sum(b.billed_hrs /* - b.write_off_hrs */), 


sum(b.billed_amt /* - b.write_off_amt */ - b.over_fee_ceil_amt - b.over_tot_ceil_amt - b.over_cst_ceil_amt + b.sales_tax_amt - b.rtnge_amt - b.disc_amt),

sum(b.rtnge_amt),  b.bill_lab_cat_cd, b.bill_lab_cat_desc,
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
sum(b.billed_hrs /* - b.write_off_hrs */), 


sum(b.billed_amt /* - b.write_off_amt */ - b.over_fee_ceil_amt - b.over_tot_ceil_amt - b.over_cst_ceil_amt + b.sales_tax_amt - b.rtnge_amt - b.disc_amt),

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
     INNER JOIN IMAPS.Deltek.BILLING_DETL_HIST AS b
     ON
     ((a.proj_id = b.invc_proj_id)
      AND
      (a.proj_spprt_sch_no = b.proj_spprt_sch_no)
-- CP600000325_Begin
      AND
      (a.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000325_End
     )
where a.invc_id in (select invc_id from xx_imaps_inv_out_sum where status_fl = 'U' AND hr_empl_name_fl = 'N' AND hr_bill_rt_fl = 'Y' AND bill_type = 'O')
group by a.cust_id, a.proj_id, a.invc_id, a.invc_dt, b.acct_id, a.invc_end_dt, b.bill_lab_cat_cd, b.bill_lab_cat_desc,
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
b.sales_tax_cd, b.bill_rt_amt, b.trn_proj_id
order by a.invc_id, b.bill_fm_grp_no, b.bill_fm_ln_no


IF @@ERROR <> 0 GOTO ERROR


-- without empl_name and with bill rate - PREV
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 636 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
insert into dbo.xx_imaps_inv_out_dtl
(cust_id, proj_id, invc_id, invc_dt, acct_id, ts_dt, bill_rt_amt, billed_hrs,
billed_amt, rtnge_amt, bill_lab_cat_cd, bill_lab_cat_desc,
bill_fm_grp_no, bill_fm_grp_lbl, bill_fm_ln_no, bill_fm_ln_lbl,
cum_billed_hrs, cum_billed_amt, tc_agrmnt, tc_prod_catgry, tc_tax, 
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
b.acct_id, a.invc_end_dt, b.bill_rt_amt, 
.00, 
.00,
.00,  b.bill_lab_cat_cd, b.bill_lab_cat_desc,
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
sum(b.billed_hrs /* - b.write_off_hrs */), 


sum(b.billed_amt /* - b.write_off_amt */ - b.over_fee_ceil_amt - b.over_tot_ceil_amt - b.over_cst_ceil_amt + b.sales_tax_amt - b.rtnge_amt - b.disc_amt),

@tc_agrmnt, @tc_prod_catgry, @tc_tax,
sum(b.billed_amt /* - b.write_off_amt */ - b.over_fee_ceil_amt - b.over_tot_ceil_amt - b.over_cst_ceil_amt + b.sales_tax_amt - b.rtnge_amt - b.disc_amt),


.00, b.sales_tax_cd,
dbo.XX_GET_SERVICE_OFFERING_UF(b.trn_proj_id),
dbo.XX_GET_MACHINE_TYPE_UF(b.trn_proj_id),
dbo.XX_GET_PRODUCT_ID_UF(b.trn_proj_id),
dbo.XX_GET_GSA_UF(b.trn_proj_id),
dbo.XX_GET_PROJ_ABBRV_CD_UF(b.trn_proj_id), 
.00,
.00,
.00
from IMAPS.Deltek.BILL_INVC_HDR_HS AS a
     INNER JOIN IMAPS.Deltek.BILLING_DETL_HIST AS b
     ON
     ((a.proj_id = b.invc_proj_id)
      AND
      (a.proj_spprt_sch_no <> b.proj_spprt_sch_no)
-- CP600000325_Begin
      AND
      (a.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000325_Begin
     )
where a.invc_id in (select invc_id from xx_imaps_inv_out_sum where status_fl = 'U' AND hr_empl_name_fl = 'N' AND hr_bill_rt_fl = 'Y' AND bill_type = 'O')
group by a.cust_id, a.proj_id, a.invc_id, a.invc_dt, b.acct_id, a.invc_end_dt, b.bill_lab_cat_cd, b.bill_lab_cat_desc,
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
b.sales_tax_cd, b.bill_rt_amt, b.trn_proj_id
order by a.invc_id, b.bill_fm_grp_no, b.bill_fm_ln_no


IF @@ERROR <> 0 GOTO ERROR

*/

-- ###$$### Disabled code end. Use SQL Server Management Studio to see disabled code much better. ###$$###

-- no employee name, no rate, no hours, no previous amounts
 
 

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 704 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
insert into dbo.xx_imaps_inv_out_dtl
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
from IMAPS.Deltek.BILL_INVC_hdr_HS AS a
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
where a.invc_id in (select invc_id from xx_imaps_inv_out_sum where status_fl = 'U' AND bill_type = 'O')
group by a.cust_id, a.proj_id, a.invc_id, a.invc_dt, b.acct_id, a.invc_end_dt,
b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.bill_fm_ln_no, b.bill_fm_ln_lbl,
b.sales_tax_cd, b.trn_proj_id
,b.bill_lab_cat_cd, b.bill_lab_cat_desc --test
order by a.invc_id, b.bill_fm_grp_no, b.bill_fm_ln_no


IF @@ERROR <> 0 GOTO ERROR

 
 
update xx_imaps_inv_out_sum
set hr_cur_fl='Y',
	hr_cum_fl='N',
	hr_bill_rt_fl='N',
	hr_empl_name_fl='N'
--end CR 4888



-- insert milestone invoice detail records
declare @milestone_label varchar(20)
SET @milestone_label = 'MILESTONE'

 
 
insert into dbo.xx_imaps_inv_out_dtl
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
where a.invc_id in (select invc_id from xx_imaps_inv_out_sum where status_fl = 'U' AND hr_empl_name_fl = 'N' AND bill_type = 'M')
order by a.invc_id, b.milestone_invc_srl

IF @@ERROR <> 0 GOTO ERROR

-- insert milestone invoice tax line
--declare @milestone_label varchar(20)
SET @milestone_label = 'TOTAL TAX'

 
 
insert into dbo.xx_imaps_inv_out_dtl
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
where a.invc_id in (select invc_id from xx_imaps_inv_out_sum where status_fl = 'U' AND hr_empl_name_fl = 'N' AND bill_type = 'M')
and a.sales_tax_amt <> .00
order by a.invc_id

IF @@ERROR <> 0 GOTO ERROR



--begin DR3854
 
 
 
UPDATE XX_IMAPS_INV_OUT_DTL
SET BILL_FM_GRP_LBL=UPPER(BILL_FM_GRP_LBL)

IF @@ERROR <> 0 GOTO ERROR
--end DR3854



-- Now that we have Detail records
declare @ERROR sysname


-- Verify Detail Total and Summary Total are EQUAL
-- If they are not equal, UPDATE ERROR TABLE AND STATUS FLAG
SET @ERROR = 'SUMMARY INVOICE AMOUNT AND BILL DETAIL TOTALS DO NOT MATCH'
INSERT INTO dbo.XX_IMAPS_INV_ERROR
(STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, ERROR_DESC)
SELECT STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, @ERROR FROM dbo.XX_IMAPS_INV_OUT_SUM a
WHERE INVC_AMT <> (SELECT (SUM(BILLED_AMT)) FROM dbo.XX_IMAPS_INV_OUT_DTL
		     WHERE INVC_ID = a.INVC_ID) 
AND	INVC_ID NOT IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)


IF @@ERROR <> 0 GOTO ERROR


-- Verify Invoice Total is Not Zero 
SET @ERROR = 'THERE ARE NO DETAIL RECORDS' 
INSERT INTO dbo.XX_IMAPS_INV_ERROR
(STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, ERROR_DESC)
SELECT STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, @ERROR FROM dbo.XX_IMAPS_INV_OUT_SUM a
WHERE (0 = (SELECT COUNT(INVC_ID) FROM dbo.XX_IMAPS_INV_OUT_DTL
		     WHERE INVC_ID = a.INVC_ID))
AND	INVC_ID NOT IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)


IF @@ERROR <> 0 GOTO ERROR


 
UPDATE dbo.XX_IMAPS_INV_OUT_SUM
SET STATUS_FL = 'E'
WHERE STATUS_FL = 'U' AND INVC_ID IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)


IF @@ERROR <> 0 GOTO ERROR



--BEGIN KM 11/15/2006 UAT HOT FIX
--DEV00001592
 
 
 
UPDATE dbo.XX_IMAPS_INV_OUT_DTL
SET RI_BILLABLE_CHG_CD = 'OSW'
WHERE 
PROJ_ABBRV_CD = ' '
AND
ACCT_ID IS NOT NULL
AND
ACCT_ID IN
(SELECT PARAMETER_VALUE
 FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
 AND PARAMETER_NAME= 'SCH_BILL_OSW_ACCT_ID')
--DEV00001592
 
 
 
UPDATE dbo.XX_IMAPS_INV_OUT_DTL
SET RI_BILLABLE_CHG_CD = 'OHW'
WHERE 
PROJ_ABBRV_CD = ' '
AND
ACCT_ID IS NOT NULL
AND
ACCT_ID IN
(SELECT PARAMETER_VALUE
 FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'FDS'
 AND PARAMETER_NAME= 'SCH_BILL_OHW_ACCT_ID')


IF @@ERROR <> 0 GOTO ERROR


DECLARE 
@IgsProjCSIDflt varchar(7),
@IgsProjBTODflt varchar(7),
@IgsProjWEBDflt varchar(7)

 
 
SELECT @IgsProjCSIDflt = ISNULL(PARAMETER_VALUE, ' ') FROM  IMAPSstg.dbo.XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'CLS' AND PARAMETER_NAME = 'IGS_CSI_PROJ_ID'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 981 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
SELECT @IgsProjBTODflt = ISNULL(PARAMETER_VALUE, ' ') FROM  IMAPSstg.dbo.XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'CLS' AND PARAMETER_NAME = 'IGS_BTO_PROJ_ID'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 989 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
SELECT @IgsProjWEBDflt = ISNULL(PARAMETER_VALUE, ' ') FROM  IMAPSstg.dbo.XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'CLS' AND PARAMETER_NAME = 'IGS_WEB_PROJ_ID'



IF @@ERROR <> 0 GOTO ERROR


 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1001 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
UPDATE dbo.XX_IMAPS_INV_OUT_DTL
SET PROJ_ABBRV_CD = 
CASE 
WHEN (PROJ_ABBRV_CD is NULL or PROJ_ABBRV_CD = ' ')  AND RI_BILLABLE_CHG_CD = 'BTO' THEN @IgsProjBTODflt
WHEN (PROJ_ABBRV_CD is NULL or PROJ_ABBRV_CD = ' ')  AND RI_BILLABLE_CHG_CD = 'WEB' THEN @IgsProjWEBDflt
WHEN (PROJ_ABBRV_CD is NULL or PROJ_ABBRV_CD = ' ')  THEN @IgsProjCSIDflt
ELSE PROJ_ABBRV_CD
END


IF @@ERROR <> 0 GOTO ERROR

--END KM 11/15/2006 UAT HOT FIX

-- change KM 11/17/2005
-- CSP identification change

-- DO CSP CALCULATIONS
CREATE TABLE #TEMP_CSP
(
[INVC_ID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
[CSP_AMT] [decimal](14, 2) NOT NULL ,
[CSP_TAX_AMT] [decimal](14, 2) NOT NULL
)

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1031 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
INSERT INTO #TEMP_CSP
(INVC_ID, CSP_AMT, CSP_TAX_AMT)
SELECT INVC_ID, SUM(BILLED_AMT), SUM(SALES_TAX_AMT) 
FROM dbo.XX_IMAPS_INV_OUT_DTL
WHERE ACCT_ID IN (SELECT PARAMETER_VALUE FROM dbo.XX_PROCESSING_PARAMETERS
		  WHERE PARAMETER_NAME = 'CSP_ACCT_ID' AND
		  INTERFACE_NAME_CD = 'FDS')
GROUP BY INVC_ID


 
UPDATE dbo.XX_IMAPS_INV_OUT_SUM
SET CSP_AMT = csp.CSP_AMT,
CSP_TAX_AMT = csp.CSP_TAX_AMT,
FDS_INV_AMT = (inv_sum.INVC_AMT - csp.CSP_AMT),
FDS_SALES_TAX_AMT = (inv_sum.SALES_TAX_AMT - csp.CSP_TAX_AMT)

FROM #TEMP_CSP AS csp
INNER JOIN dbo.XX_IMAPS_INV_OUT_SUM AS inv_sum
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
AND	INTERFACE_NAME_CD = 'FDS'
SELECT 	@OHW_TC_PROD_CATGRY = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'OHW_TC_PROD_CATGRY'
AND	INTERFACE_NAME_CD = 'FDS'
SELECT 	@OHW_TC_AGRMNT = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'OHW_TC_AGRMNT'
AND	INTERFACE_NAME_CD = 'FDS'
SELECT 	@OSW_TC_TAX = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'OSW_TC_TAX'
AND	INTERFACE_NAME_CD = 'FDS'
SELECT 	@OSW_TC_PROD_CATGRY = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'OSW_TC_PROD_CATGRY'
AND	INTERFACE_NAME_CD = 'FDS'
SELECT 	@OSW_TC_AGRMNT = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'OSW_TC_AGRMNT'
AND	INTERFACE_NAME_CD = 'FDS'
SELECT 	@WEB_TC_TAX = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'WEB_TC_TAX'
AND	INTERFACE_NAME_CD = 'FDS'
SELECT 	@WEB_TC_PROD_CATGRY = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'WEB_TC_PROD_CATGRY'
AND	INTERFACE_NAME_CD = 'FDS'
SELECT 	@WEB_TC_AGRMNT = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'WEB_TC_AGRMNT'
AND	INTERFACE_NAME_CD = 'FDS'
--end change

IF @@ERROR <> 0 GOTO ERROR



-- change KM 11/17/2005
-- now that we know OEM Hardware, Software, Web Hosting tax Stuff
-- we can make these changes
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1123 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
UPDATE  DBO.XX_IMAPS_INV_OUT_DTL
SET 	TC_TAX = @OHW_TC_TAX,
	TC_PROD_CATGRY = @OHW_TC_PROD_CATGRY,
	TC_AGRMNT = @OHW_TC_AGRMNT
WHERE	RI_BILLABLE_CHG_CD = 'OHW'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1134 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
UPDATE  DBO.XX_IMAPS_INV_OUT_DTL
SET 	TC_TAX = @OSW_TC_TAX,
	TC_PROD_CATGRY = @OSW_TC_PROD_CATGRY,
	TC_AGRMNT = @OSW_TC_AGRMNT
WHERE	RI_BILLABLE_CHG_CD = 'OSW'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1145 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
UPDATE  DBO.XX_IMAPS_INV_OUT_DTL
SET 	TC_TAX = @WEB_TC_TAX,
	TC_PROD_CATGRY = @WEB_TC_PROD_CATGRY,
	TC_AGRMNT = @WEB_TC_AGRMNT
WHERE	RI_BILLABLE_CHG_CD = 'WEB'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1156 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
UPDATE 	DBO.XX_IMAPS_INV_OUT_DTL

SET	TC_AGRMNT = 'T'
WHERE	RI_BILLABLE_CHG_CD not in ('OHW', 'OSW', 'WEB')
AND	ACCT_ID in (SELECT DISTINCT ACCT_ID FROM IMAPS.DELTEK.ACCT
		    WHERE ACCT_NAME LIKE '%travel%')
-- end change KM 11/17/2005


IF @@ERROR <> 0 GOTO ERROR



-- change KM 01/18/2006
-- only send I_MACH_TYPE for OHW
-- only send M_PRODUCT_CODE for OSW
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1178 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
UPDATE 	DBO.XX_IMAPS_INV_OUT_DTL
SET	I_MACH_TYPE = '     '
WHERE 	RI_BILLABLE_CHG_CD <> 'OHW'

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1187 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
UPDATE 	DBO.XX_IMAPS_INV_OUT_DTL
SET	M_PRODUCT_CODE = '        '
--DR1306 WHERE 	RI_BILLABLE_CHG_CD <> 'OSW'
-- end change KM 01/18/2006

IF @@ERROR <> 0 GOTO ERROR


--change KM 02/07/06
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1202 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
update xx_imaps_inv_out_dtl
set name = ' ',
id = ' '
where bill_lab_cat_cd IS NULL
--end change KM 02/07/06


IF @@ERROR <> 0 GOTO ERROR


--04/2006
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
SELECT 	DISTINCT STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, @ERROR FROM dbo.XX_IMAPS_INV_OUT_SUM
WHERE 	INVC_ID IN 
(SELECT INVC_ID FROM XX_IMAPS_INV_OUT_DTL
 WHERE 	SALES_TAX_CD IS NOT NULL 
 AND	RIGHT(SALES_TAX_CD, 1) NOT IN ('1', '2', '3'))


IF @@ERROR <> 0 GOTO ERROR


 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1238 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
UPDATE dbo.XX_IMAPS_INV_OUT_SUM
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

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 1260 : XX_FDS_LOAD_DTL_SP.sql '  --CR9449
 
INSERT INTO #TEMP_TAX
(INVC_ID, ACCT_ID, ACCT_SALES_TAX_AMT, ACCT_BILLED_AMT, SALES_TAX_CD)
SELECT 	a.INVC_ID, a.ACCT_ID, b.SALES_TAX_AMT, SUM(a.BILLED_AMT), b.SALES_TAX_CD
FROM 	XX_IMAPS_INV_OUT_DTL a
INNER JOIN
	XX_IMAPS_INV_OUT_DTL b
ON	(a.INVC_ID = b.INVC_ID
AND	 a.ACCT_ID = b.ACCT_ID
AND	 a.BILLED_AMT <> a.SALES_TAX_AMT
AND	 b.BILLED_AMT = b.SALES_TAX_AMT
AND	 b.SALES_TAX_AMT <> .00)
WHERE 	RIGHT(b.SALES_TAX_CD, 1) in ('1', '2', '3')
GROUP BY a.INVC_ID, a.ACCT_ID, b.SALES_TAX_AMT, b.SALES_TAX_CD


IF @@ERROR <> 0 GOTO ERROR



--STATE SALES TAX
 
 
 
UPDATE dbo.XX_IMAPS_INV_OUT_DTL
SET STATE_SALES_TAX_AMT = tax.ACCT_SALES_TAX_AMT * (dtl.BILLED_AMT/tax.ACCT_BILLED_AMT)
FROM #TEMP_TAX AS tax
INNER JOIN dbo.XX_IMAPS_INV_OUT_DTL AS dtl
ON tax.INVC_ID = dtl.INVC_ID
AND tax.ACCT_ID = dtl.ACCT_ID
and RIGHT(tax.SALES_TAX_CD, 1) = '1' 
WHERE dtl.SALES_TAX_AMT <> dtl.BILLED_AMT


IF @@ERROR <> 0 GOTO ERROR


--COUNTY SALES TAX
 
 
 
UPDATE dbo.XX_IMAPS_INV_OUT_DTL
SET COUNTY_SALES_TAX_AMT = tax.ACCT_SALES_TAX_AMT * (dtl.BILLED_AMT/tax.ACCT_BILLED_AMT)
FROM #TEMP_TAX AS tax
INNER JOIN dbo.XX_IMAPS_INV_OUT_DTL AS dtl
ON tax.INVC_ID = dtl.INVC_ID
AND tax.ACCT_ID = dtl.ACCT_ID
and RIGHT(tax.SALES_TAX_CD, 1) = '2' 
WHERE dtl.SALES_TAX_AMT <> dtl.BILLED_AMT


IF @@ERROR <> 0 GOTO ERROR


--CITY SALES TAX
 
 
 
UPDATE dbo.XX_IMAPS_INV_OUT_DTL
SET CITY_SALES_TAX_AMT = tax.ACCT_SALES_TAX_AMT * (dtl.BILLED_AMT/tax.ACCT_BILLED_AMT)
FROM #TEMP_TAX AS tax
INNER JOIN dbo.XX_IMAPS_INV_OUT_DTL AS dtl
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
AND	ACCT_SALES_TAX_AMT <> (SELECT SUM(STATE_SALES_TAX_AMT) FROM dbo.XX_IMAPS_INV_OUT_DTL as dtl
		     	       WHERE 
				dtl.INVC_ID = tax.INVC_ID 
				AND dtl.ACCT_ID = tax.ACCT_ID
				AND dtl.BILLED_AMT <> dtl.SALES_TAX_AMT)
)
OR
(
RIGHT(tax.SALES_TAX_CD, 1) = '2' 
AND	ACCT_SALES_TAX_AMT <> (SELECT SUM(COUNTY_SALES_TAX_AMT) FROM dbo.XX_IMAPS_INV_OUT_DTL as dtl
		     	       WHERE 
				dtl.INVC_ID = tax.INVC_ID 
				AND dtl.ACCT_ID = tax.ACCT_ID
				AND dtl.BILLED_AMT <> dtl.SALES_TAX_AMT)
)
OR
(
RIGHT(tax.SALES_TAX_CD, 1) = '3' 
AND	ACCT_SALES_TAX_AMT <> (SELECT SUM(CITY_SALES_TAX_AMT) FROM dbo.XX_IMAPS_INV_OUT_DTL as dtl
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
	FROM 	XX_IMAPS_INV_OUT_DTL
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
			FROM 	dbo.XX_IMAPS_INV_OUT_DTL
			WHERE 	INVC_ID = @invc_id 
			AND 	ACCT_ID = @acct_id
			AND 	BILLED_AMT <> SALES_TAX_AMT
		
			IF(@temp_amt < @acct_sales_tax_amt)
			BEGIN
				UPDATE  dbo.XX_IMAPS_INV_OUT_DTL

				SET 	STATE_SALES_TAX_AMT = STATE_SALES_TAX_AMT + 0.01	
				WHERE 	INVC_LN = @invc_ln
	
				SET @temp_amt = @temp_amt + 0.01
			END
			ELSE IF (@temp_amt > @acct_sales_tax_amt)
			BEGIN
				UPDATE  dbo.XX_IMAPS_INV_OUT_DTL
				SET 	STATE_SALES_TAX_AMT = STATE_SALES_TAX_AMT - 0.01	
				WHERE 	INVC_LN = @invc_ln

				SET @temp_amt = @temp_amt - 0.01
			END
		END
		--COUNTY SALES TAX AMT
		ELSE IF(RIGHT(@sales_tax_cd, 1) = '2')
		BEGIN
			SELECT 	@temp_amt = SUM(COUNTY_SALES_TAX_AMT) 
			FROM 	dbo.XX_IMAPS_INV_OUT_DTL
			WHERE 	INVC_ID = @invc_id 
			AND 	ACCT_ID = @acct_id
			AND 	BILLED_AMT <> SALES_TAX_AMT
		
			IF(@temp_amt < @acct_sales_tax_amt)
			BEGIN
				UPDATE  dbo.XX_IMAPS_INV_OUT_DTL
				SET 	COUNTY_SALES_TAX_AMT = COUNTY_SALES_TAX_AMT + 0.01	
				WHERE 	INVC_LN = @invc_ln
	
				SET @temp_amt = @temp_amt + 0.01
			END
			ELSE IF (@temp_amt > @acct_sales_tax_amt)
			BEGIN
				UPDATE  dbo.XX_IMAPS_INV_OUT_DTL
				SET 	COUNTY_SALES_TAX_AMT = COUNTY_SALES_TAX_AMT - 0.01	
				WHERE 	INVC_LN = @invc_ln

				SET @temp_amt = @temp_amt - 0.01
			END
		END
		--CITY SALES TAX AMT
		ELSE IF(RIGHT(@sales_tax_cd, 1) = '3')
		BEGIN
			SELECT 	@temp_amt = SUM(CITY_SALES_TAX_AMT) 
			FROM 	dbo.XX_IMAPS_INV_OUT_DTL
			WHERE 	INVC_ID = @invc_id 
			AND 	ACCT_ID = @acct_id
			AND 	BILLED_AMT <> SALES_TAX_AMT
		
			IF(@temp_amt < @acct_sales_tax_amt)
			BEGIN
				UPDATE  dbo.XX_IMAPS_INV_OUT_DTL
				SET 	CITY_SALES_TAX_AMT = CITY_SALES_TAX_AMT + 0.01	
				WHERE 	INVC_LN = @invc_ln
	
				SET @temp_amt = @temp_amt + 0.01
			END
			ELSE IF (@temp_amt > @acct_sales_tax_amt)
			BEGIN
				UPDATE  dbo.XX_IMAPS_INV_OUT_DTL
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


SET @ERROR = 'INVOICE IS OUT OF BALANCE. LIKELY CAUSE: DISCOUNTS NOT PROPERLY RECORDED' 
INSERT INTO dbo.XX_IMAPS_INV_ERROR
(STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, ERROR_DESC)
SELECT STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, @ERROR FROM dbo.XX_IMAPS_INV_OUT_SUM a
WHERE INVC_ID IN (SELECT INVC_ID FROM IMAPSSTG.DBO.XX_GLIM_INTERFACE_OOB_VW)

IF @@ERROR <> 0 GOTO ERROR


SET @ERROR = 'SUMMARY AND DETAIL TAX CALCULATIONS DO NOT MATCH' 
INSERT INTO dbo.XX_IMAPS_INV_ERROR
(STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, ERROR_DESC)
SELECT STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, @ERROR FROM dbo.XX_IMAPS_INV_OUT_SUM a
WHERE SALES_TAX_AMT <> (SELECT SUM(STATE_SALES_TAX_AMT+COUNTY_SALES_TAX_AMT+CITY_SALES_TAX_AMT) FROM dbo.XX_IMAPS_INV_OUT_DTL
		     	WHERE INVC_ID = a.INVC_ID AND BILLED_AMT <> SALES_TAX_AMT)
AND	INVC_ID NOT IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)

IF @@ERROR <> 0 GOTO ERROR


 
UPDATE dbo.XX_IMAPS_INV_OUT_SUM
SET STATUS_FL = 'E'
WHERE STATUS_FL = 'U' AND INVC_ID IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)


IF @@ERROR <> 0 GOTO ERROR


SET @ERROR = 'INVC_ID MUST BE AT LEAST 7 CHARACTERS' 
INSERT INTO dbo.XX_IMAPS_INV_ERROR
(STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, ERROR_DESC)
SELECT STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, @ERROR FROM dbo.XX_IMAPS_INV_OUT_SUM a
WHERE LEN(INVC_ID) < 7
AND	INVC_ID NOT IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)


IF @@ERROR <> 0 GOTO ERROR


 
UPDATE dbo.XX_IMAPS_INV_OUT_SUM
SET STATUS_FL = 'E'
WHERE STATUS_FL = 'U' AND INVC_ID IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)


IF @@ERROR <> 0 GOTO ERROR
PRINT '' --CR9449 *~^
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF XX_FDS_LOAD_DTL_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^

 
RETURN 0


ERROR: 
RETURN 1

END



 

 

 

 

 

GO
 


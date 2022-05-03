USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_FDS_LOAD_SUM_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 




CREATE PROCEDURE [dbo].[XX_FDS_LOAD_SUM_SP]
(
@in_STATUS_RECORD_NUM integer
)
AS
/************************************************************************************************  
Name:       	XX_FDS_LOAD_SUM_SP  
Author:     	CR  
Created:    	07/2005  
Purpose:    	Using the IMAPS posted invoice tables to load the temp staging tables for the FDS and CCS interfaces.
	    	i) XX_IMAPS_INV_OUT_SUM -- Summary Data
            	See AR Oubound Interfaces.doc for details  

Prerequisites: 	none 

Parameters: 
	Input: 	none
	Output: none   

Version: 	1.0
Notes:      	Call example  
              	EXEC IMAPS.dbo.XX_FDS_LOAD_SUM_SP

CP600000325     04/25/2008 (BP&S Change Request No. CR1543)
                Costpoint multi-company fix (one instance).
CR-9449 - GEA - 12/14/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
CR9449 - gea - 1/24/2018 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
CR12117 - GEA  6/3/2020 - ADDED DUE DATE
************************************************************************************************/  

-- CP600000325_Begin
DECLARE @DIV_16_COMPANY_ID varchar(10),
        @SP_NAME sysname

PRINT '' --CR9449 *~^
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_FDS_LOAD_SUM.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^
-- *~^
SET @SP_NAME = 'XX_FDS_LOAD_SUM'


 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 62 : XX_FDS_LOAD_SUM.sql '  --CR9449
 
SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'FDS'
-- CP600000325_End

--clear interface temp tables
PRINT 'DELETING DETAIL TABLE'
DELETE dbo.XX_IMAPS_INV_OUT_DTL

IF @@ERROR <> 0 GOTO ERROR

PRINT 'DELETING SUM TABLE'
DELETE dbo.XX_IMAPS_INV_OUT_SUM

IF @@ERROR <> 0 GOTO ERROR

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 82 : XX_FDS_LOAD_SUM.sql '  --CR9449
 
TRUNCATE TABLE dbo.XX_IMAPS_INV_ERROR --change KM 1/11/06


IF @@ERROR <> 0 GOTO ERROR

--change KM 02/16/05
DECLARE @I_COLL_OFF varchar(3),
	@C_COLL_DIV varchar(2)

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 96 : XX_FDS_LOAD_SUM.sql '  --CR9449
 
SELECT 	@I_COLL_OFF = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'COLL_OFF'
AND	INTERFACE_NAME_CD = 'FDS'


IF @@ERROR <> 0 GOTO ERROR

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 109 : XX_FDS_LOAD_SUM.sql '  --CR9449
 
SELECT 	@C_COLL_DIV = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'COLL_DIV'
AND	INTERFACE_NAME_CD = 'FDS'


IF @@ERROR <> 0 GOTO ERROR
--end change 


--load regular invoices into summary staging table
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 126 : XX_FDS_LOAD_SUM.sql '  --CR9449
 
INSERT INTO dbo.xx_imaps_inv_out_sum
SELECT cust_id,
	proj_id,
	invc_id,
	invc_dt,
	'U' status_fl,
	@in_STATUS_RECORD_NUM, -- @lv_status_record_num,
	'O' bill_type,
	fy_cd,
	pd_no,
	0 cur_julian_dt, --TO DO - calculate current julian date
	' ' i_bo,
	cust_addr_dc,
	dbo.XX_GET_CONTRACT_UF(proj_id) prime_contr_id,
	left(cust_po_id,20), -- DR to accommodate CP 7.7 change
	cust_terms_dc,
	' ' i_enterprise,
	cust_name,
	' ' i_napcode,
	' ' c_std_ind_class,
	' ' c_indus,
	' ' c_state,
	' ' c_cnty,
	' ' c_city,
	' ' ti_cmr_cust_type,
	' ' c_fds_cust_type,
	' ' i_mkg_div,
	@I_COLL_OFF i_coll_off,
	@C_COLL_DIV c_coll_div,
	' ' t_cust_ref_1,
	invc_amt,
	sales_tax_amt,
	0 csp_amt,
	0 csp_tax_amt,
	invc_amt,  --fds_inv_amt
	sales_tax_amt, --fds_sales_tax_amt
	' ' ti_svc_bo,
	--' ' rf_gsa_indicator, moved to dtl table
	b.hr_bill_rt_fl,
	b.hr_cum_fl,
	b.hr_cur_fl,
	b.hr_empl_name_fl,
	' ' tc_certifc_status,
	' ' tc_tax_class,
	' ' f_ocl,
	dbo.XX_GET_DIV_FOR_PROJ_ID_UF(a.proj_id) division,
	A.INVC_DUE_DT
   FROM IMAPS.Deltek.BILL_INVC_HDR_hs a,
        IMAPS.Deltek.BILL_FRMT b
  WHERE a.bill_frmt_cd = b.bill_frmt_cd
-- CP600000325_Begin
    AND a.COMPANY_ID = b.COMPANY_ID
    AND a.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000325_End
    AND invc_id not in (SELECT invc_id FROM dbo.xx_imaps_invoice_sent)
    AND substring(a.PROJ_ID, 1, 4) <> 'DDOU'

IF @@ERROR <> 0 GOTO ERROR


--load milestone invoices into summary staging table
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 192 : XX_FDS_LOAD_SUM.sql '  --CR9449
 
INSERT INTO dbo.xx_imaps_inv_out_sum
SELECT cust_id,
	proj_id,
	invc_id,
	invc_dt,
	'U' status_fl,
	@in_STATUS_RECORD_NUM, -- @lv_status_record_num,
	'M' bill_type,
	DATEPART(yyyy, invc_dt) fy_cd,
	DATEPART(mm, invc_dt) pd_no,
	0 cur_julian_dt, --TO DO - calculate current julian date
	' ' i_bo,
	cust_addr_dc,
	dbo.XX_GET_CONTRACT_UF(proj_id) prime_contr_id,
	left(cust_po_id,20), -- DR to accommodate CP 7.7 change
	cust_terms_dc,
	' ' i_enterprise,
	' ' cust_name,
	' ' i_napcode,
	' ' c_std_ind_class,
	' ' c_indus,
	' ' c_state,
	' ' c_cnty,
	' ' c_city,
	' ' ti_cmr_cust_type,
	' ' c_fds_cust_type,
	' ' i_mkg_div,
	@I_COLL_OFF i_coll_off,
	@C_COLL_DIV c_coll_div,
	' ' t_cust_ref_1,
	invc_amt,
	sales_tax_amt,
	0 csp_amt,
	0 csp_tax_amt,
	invc_amt,  --fds_inv_amt
	sales_tax_amt, --fds_sales_tax_amt
	' ' ti_svc_bo,
	--' ' rf_gsa_indicator, moved to dtl table
	'N' hr_bill_rt_fl,
	'Y' hr_cum_fl,
	'Y' hr_cur_fl,
	'N' hr_empl_name_fl,
	' ' tc_certifc_status,
	' ' tc_tax_class,
	' ' f_ocl,
	dbo.XX_GET_DIV_FOR_PROJ_ID_UF(proj_id) division,
	DUE_DT
FROM IMAPS.deltek.milestone_hdr_hs
where  invc_id not in (SELECT invc_id
	FROM dbo.xx_imaps_invoice_sent)
and substring(proj_id, 1, 4) <> 'DDOU'

IF @@ERROR <> 0 GOTO ERROR

PRINT '' --CR9449 *~^
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF XX_FDS_LOAD_SUM.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^
 
RETURN 0

ERROR:

RETURN 1


 

GO
 


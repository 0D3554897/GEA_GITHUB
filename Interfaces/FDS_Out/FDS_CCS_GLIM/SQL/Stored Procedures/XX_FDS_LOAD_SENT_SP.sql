USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_FDS_LOAD_SENT_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 


 

 




CREATE PROCEDURE [dbo].[XX_FDS_LOAD_SENT_SP]
(
@in_STATUS_RECORD_NUM integer
)
AS
/************************************************************************************************  
Name:       	XX_FDS_LOAD_SENT_SP  
Author:     	CR  
Created:    	08/2005  
Purpose:    	To insert records into the XX_FDS_INVOICE_SENT table

Prerequisites: 	none 

Parameters: 
	Input: 	none
	Output: none   

Version: 	1.0
Notes:      	Call example  
              	EXEC IMAPS.dbo.XX_IMAPS_AR_LOAD_SENT_SP  

CP600000325     04/25/2008 (BP&S Change Request No. CR1543)
                Costpoint multi-company fix (one instance).
                
DR7644 - FDS interface - CLS Down reverse table not loaded correctly - KM - 2014-11-03
CR9449 - Add input parameter @in_STATUS_RECORD_NUM
CR9449 - gea - 1/24/2018 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
************************************************************************************************/  


-- CP600000325_Begin
DECLARE @DIV_16_COMPANY_ID varchar(10),
        @SP_NAME sysname

PRINT '' --CR9449 *~^
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_FDS_LOAD_SENT_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^
-- *~^
SET @SP_NAME = 'XX_FDS_LOAD_SENT_SP'


 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 62 : XX_FDS_LOAD_SENT_SP.sql '  --CR9449
 
SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'FDS'
-- CP600000325_End

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 71 : XX_FDS_LOAD_SENT_SP.sql '  --CR9449
 
INSERT INTO dbo.XX_IMAPS_INVOICE_SENT
   (CUST_ID, PROJ_ID, INVC_ID, INVC_AMT, INVC_DT, STATUS_RECORD_NUM, DIVISION)
   SELECT CUST_ID, PROJ_ID, INVC_ID, INVC_AMT, INVC_DT, STATUS_RECORD_NUM, DIVISION
     FROM dbo.XX_IMAPS_INV_OUT_SUM
    WHERE STATUS_FL = 'P'


IF @@ERROR <> 0 GOTO ERROR


DECLARE @ERROR varchar(250)
SET @ERROR = 'REVERSAL OF PREVIOUSLY SENT INVOICE - COMPARE INVC_AMT in dbo.XX_IMAPS_INVOICE_SENT to DELTEK.BILL_INVC_HDR_HS'

INSERT INTO dbo.XX_IMAPS_INV_ERROR
   (STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, ERROR_DESC)
   SELECT a.STATUS_RECORD_NUM, a.CUST_ID, a.PROJ_ID, a.INVC_ID, a.INVC_DT, @ERROR 
     FROM dbo.XX_IMAPS_INV_OUT_SUM a
          INNER JOIN
          IMAPS.DELTEK.BILL_INVC_HDR_HS b
          ON
          (a.invc_id = b.invc_id
           and a.invc_dt = b.invc_dt
           and a.invc_amt <> b.invc_amt
-- CP600000325_Begin
           and b.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000325_End
          )
          AND a.INVC_ID NOT IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)


IF @@ERROR <> 0 GOTO ERROR


-- change KM 11/17/05
-- LOAD FDS_REVERSE TABLE FOR CLS_DOWN
-- tatiana wants NA + MACH TYPE for OHW  
--  		 NA + PROD ID   for OSW  
-- CSP and TAX items must be excluded from FDS REVERSE table

--CSI, BTO, and WEB
INSERT INTO dbo.XX_CLS_DOWN_FDS_REVERSE
(RUN_DT, SERVICE_OFFERED, CUSTOMER_NUM, CONTRACT_NUM,  DOLLAR_AMT, PROJ_ABBRV_CD, DIVISION)
SELECT 	GETDATE(), b.RI_BILLABLE_CHG_CD, a.CUST_ADDR_DC, a.PRIME_CONTR_ID, SUM(b.BILLED_AMT), b.PROJ_ABBRV_CD, a.DIVISION
FROM 
dbo.XX_IMAPS_INV_OUT_SUM a
INNER JOIN
dbo.XX_IMAPS_INV_OUT_DTL b
ON
(	a.CUST_ID = b.CUST_ID 
AND 	a.PROJ_ID = b.PROJ_ID 
AND	a.INVC_ID = b.INVC_ID
AND	a.INVC_DT = b.INVC_DT
)
WHERE
a.STATUS_FL = 'P'
AND
--DR7644
b.RI_BILLABLE_CHG_CD not in ('OSW','OHW')
/*
(b.RI_BILLABLE_CHG_CD = 'CSI' OR b.RI_BILLABLE_CHG_CD = 'BTO' OR b.RI_BILLABLE_CHG_CD = 'WEB')
*/

AND
b.ACCT_ID NOT IN (SELECT PARAMETER_VALUE FROM dbo.XX_PROCESSING_PARAMETERS WHERE PARAMETER_NAME = 'CSP_ACCT_ID')
AND
b.BILLED_AMT <> b.SALES_TAX_AMT
GROUP BY
a.CUST_ADDR_DC, b.RI_BILLABLE_CHG_CD, a.PRIME_CONTR_ID, b.PROJ_ABBRV_CD, a.DIVISION


IF @@ERROR <> 0 GOTO ERROR



--OSW
declare @NA varchar(2)
SET @NA = 'NA'

INSERT INTO dbo.XX_CLS_DOWN_FDS_REVERSE
(RUN_DT, SERVICE_OFFERED, CUSTOMER_NUM, CONTRACT_NUM, PRODUCT_ID, DOLLAR_AMT, PROJ_ABBRV_CD, DIVISION)
SELECT 	GETDATE(), @NA, a.CUST_ADDR_DC, a.PRIME_CONTR_ID, b.M_PRODUCT_CODE, SUM(b.BILLED_AMT), b.PROJ_ABBRV_CD, a.DIVISION
FROM 
dbo.XX_IMAPS_INV_OUT_SUM a
INNER JOIN
dbo.XX_IMAPS_INV_OUT_DTL b
ON
(	a.CUST_ID = b.CUST_ID
	AND a.PROJ_ID = b.PROJ_ID
	AND a.INVC_ID = b.INVC_ID
	AND a.INVC_DT = b.INVC_DT
)
WHERE 
a.STATUS_FL = 'P'
AND
b.RI_BILLABLE_CHG_CD = 'OSW'
AND
b.ACCT_ID NOT IN (SELECT PARAMETER_VALUE FROM dbo.XX_PROCESSING_PARAMETERS WHERE PARAMETER_NAME = 'CSP_ACCT_ID')
AND
b.BILLED_AMT <> b.SALES_TAX_AMT
GROUP BY
a.CUST_ADDR_DC, b.RI_BILLABLE_CHG_CD, a.PRIME_CONTR_ID, b.M_PRODUCT_CODE, b.PROJ_ABBRV_CD, a.DIVISION


IF @@ERROR <> 0 GOTO ERROR


--OHW
INSERT INTO dbo.XX_CLS_DOWN_FDS_REVERSE
(RUN_DT, SERVICE_OFFERED, CUSTOMER_NUM, CONTRACT_NUM, MACHINE_TYPE, DOLLAR_AMT, PROJ_ABBRV_CD, DIVISION)
SELECT 	GETDATE(), @NA, a.CUST_ADDR_DC, a.PRIME_CONTR_ID, b.I_MACH_TYPE, SUM(b.BILLED_AMT), b.PROJ_ABBRV_CD, a.DIVISION
FROM 
dbo.XX_IMAPS_INV_OUT_SUM a
INNER JOIN
dbo.XX_IMAPS_INV_OUT_DTL b
ON
(	a.CUST_ID = b.CUST_ID
	AND a.PROJ_ID = b.PROJ_ID
	AND a.INVC_ID = b.INVC_ID
	AND a.INVC_DT = b.INVC_DT
)
WHERE 
a.STATUS_FL = 'P'
AND
b.RI_BILLABLE_CHG_CD = 'OHW'
AND
b.ACCT_ID NOT IN (SELECT PARAMETER_VALUE FROM dbo.XX_PROCESSING_PARAMETERS WHERE PARAMETER_NAME = 'CSP_ACCT_ID')
AND
b.BILLED_AMT <> b.SALES_TAX_AMT
GROUP BY
a.CUST_ADDR_DC, b.RI_BILLABLE_CHG_CD, a.PRIME_CONTR_ID, b.I_MACH_TYPE, b.PROJ_ABBRV_CD, a.DIVISION

-- end change KM 11/17/05

IF @@ERROR <> 0 GOTO ERROR

PRINT '' --CR9449 *~^
PRINT '*~^*************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF  XX_FDS_LOAD_SENT_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9449 *~^
RETURN(0)


ERROR:

RETURN(1)


 

 

 

GO
 


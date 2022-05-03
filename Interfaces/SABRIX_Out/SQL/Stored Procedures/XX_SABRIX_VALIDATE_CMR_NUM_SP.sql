USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_SABRIX_VALIDATE_CMR_NUM_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 

 

 

 

 

 

 



CREATE PROCEDURE [dbo].[XX_SABRIX_VALIDATE_CMR_NUM_SP]
(
@in_STATUS_RECORD_NUM integer
)
AS

/************************************************************************************************  
Name:       	XX_SABRIX_VALIDATE_CMR_NUM_SP
Author:     	KM
Created:    	10/05
Purpose:    	Verify that the CMR Number is in database
					If isn't flag as error
					If it is, update invoice summary record
					If zip code <> 9 digits or 5 digits then invalid, but only for US addresses

Prerequisites: 	Load summary invoice data to  XX_SABRIX_INV_OUT_SUM

Parameters: 
	Input: 	none
	Output: none   

Version: 	1.0
Notes:      	Call example  
              	EXEC dbo.XX_SABRIX_VALIDATE_CMR_NUM_SP
************************************************************************************************/


BEGIN

DECLARE @ERROR varchar(250),
	@ret_code int,
        @remain_cnt int,
        @err_cnt int,
        @SP_NAME   sysname

PRINT '  *~^'
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_SABRIX_VALIDATE_CRM_NUM_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '  *~^'
-- *~^
SET @SP_NAME = 'XX_SABRIX_VALIDATE_CRM_NUM_SP'

--DR7649
--fix strange C_CITY issue in CMR staging table
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 70 : XX_SABRIX_VALIDATE_CRM_NUM_SP.sql '  
 
update xx_imaps_cmr_stg
set C_SCC_CITY='0'+left(C_SCC_CITY,3)
where right(C_SCC_CITY,1)='.'

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 85 : XX_SABRIX_VALIDATE_CRM_NUM_SP.sql '  
 
update XX_SABRIX_INV_OUT_SUM
set cust_addr_dc = rtrim(ltrim(cust_addr_dc))


-- Validate CMR data
SET @ERROR = 'CMR NUMBER (CUST_ADDR_DC) IS NOT IN THE XX_IMAPS_CMR_STG TABLE'

/* 1M changes --- this is slow
INSERT INTO dbo.XX_IMAPS_INV_ERROR
(STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, ERROR_DESC)
SELECT STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, @ERROR FROM dbo.XX_SABRIX_INV_OUT_SUM
WHERE CUST_ADDR_DC NOT IN (SELECT RIGHT('0000000'+CAST(I_CUST_ENTITY as varchar), 7) FROM dbo.XX_IMAPS_CMR_STG)
*/
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 103 : XX_SABRIX_VALIDATE_CRM_NUM_SP.sql '  
 
INSERT INTO dbo.XX_IMAPS_INV_ERROR
(STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, ERROR_DESC)
SELECT imaps.STATUS_RECORD_NUM, imaps.CUST_ID, imaps.PROJ_ID, imaps.INVC_ID, imaps.INVC_DT, @ERROR 
FROM 
dbo.XX_SABRIX_INV_OUT_SUM AS imaps
LEFT OUTER JOIN 
dbo.XX_IMAPS_CMR_STG AS cmr
ON 
RIGHT('0000000'+CAST(I_CUST_ENTITY as varchar), 7)  = imaps.CUST_ADDR_DC
WHERE 
cmr.I_CUST_ENTITY IS NULL

IF @@ERROR <> 0 GOTO ERROR

 
 
UPDATE dbo.XX_SABRIX_INV_OUT_SUM
SET STATUS_FL = 'E'
WHERE STATUS_FL = 'U' AND INVC_ID IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)
AND STATUS_RECORD_NUM IN (SELECT STATUS_RECORD_NUM FROM IMAPSSTG.DBO.XX_IMAPS_INV_ERROR)

IF @@ERROR <> 0 GOTO ERROR

SELECT @remain_cnt = COUNT(*) FROM imapsstg.dbo.XX_SABRIX_INV_OUT_SUM where status_fl = 'U'

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 130 : XX_SABRIX_VALIDATE_CRM_NUM_SP.sql '  
 
SELECT @err_cnt = COUNT(*) FROM imapsstg.dbo.XX_SABRIX_INV_OUT_SUM where status_fl = 'E'

PRINT 'Invoices Validated. ' + cast(@err_cnt as varchar) + ' errors found and ' + cast(@remain_cnt as varchar) + ' invoices remain.'

-- Update CMR data

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 141 : XX_SABRIX_VALIDATE_CRM_NUM_SP.sql '  
 
UPDATE dbo.XX_SABRIX_INV_OUT_SUM

SET I_BO = cmr.I_MKTG_OFF,
I_ENTERPRISE = cmr.I_ENT,
CUST_NAME = cmr.N_ABBREV,  
I_NAPCODE = cmr.C_NAP,
C_STD_IND_CLASS = cmr.C_ESTAB_SIC,
C_INDUS = (cmr.I_INDUS_DEPT + cmr.I_INDUS_CLASS),
C_STATE = cmr.C_SCC_ST,
C_CNTY = cmr.C_SCC_CNTY,
C_CITY = cmr.C_SCC_CITY,
TI_CMR_CUST_TYPE = cmr.I_TYPE_CUST_1,
I_MKG_DIV = cmr.A_LEVEL_1_VALUE,
TI_SVC_BO = cmr.I_PRIMRY_SVC_OFF,
TC_CERTIFC_STATUS = cmr.C_ICC_TE,
TC_TAX_CLASS = cmr.C_ICC_TAX_CLASS, 
F_OCL = cmr.F_OCL
FROM dbo.XX_IMAPS_CMR_STG AS cmr
INNER JOIN dbo.XX_SABRIX_INV_OUT_SUM AS inv_sum
ON inv_sum.CUST_ADDR_DC = cmr.I_CUST_ENTITY

WHERE STATUS_FL = 'U'


IF @@ERROR <> 0 GOTO ERROR

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 176 : XX_SABRIX_VALIDATE_CRM_NUM_SP.sql '  
 
UPDATE dbo.XX_SABRIX_INV_OUT_SUM
SET F_OCL = '1'
WHERE F_OCL = 'Y'

IF @@ERROR <> 0 GOTO ERROR

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 187 : XX_SABRIX_VALIDATE_CRM_NUM_SP.sql '  
 
UPDATE dbo.XX_SABRIX_INV_OUT_SUM
SET F_OCL = '0'
WHERE F_OCL = 'N'

IF @@ERROR <> 0 GOTO ERROR

-- now validate the zip + 4
SET @ERROR = 'CMR NUMBER (CUST_ADDR_DC) ZIP CODE IS NOT CORRECT'


-- IF US ADDRESS ZIP CODE IS NOT EMPTY, 5 DIGITS OR 9 DIGITS, FAIL IT
INSERT INTO dbo.XX_IMAPS_INV_ERROR
(STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, ERROR_DESC)
SELECT A.STATUS_RECORD_NUM, A.CUST_ID, A.PROJ_ID, A.INVC_ID, A.INVC_DT, @ERROR 
FROM 
dbo.XX_SABRIX_INV_OUT_SUM A
join imaps.deltek.cust_addr c 
 on a.cust_addr_dc = c.ADDR_DC and a.CUST_ID = c.cust_id
WHERE 
coalesce(ltrim(rtrim(country_cd)),'USA')='USA'
AND
(coalesce(len(   (SELECT CAST(CAST((
        SELECT SUBSTRING(postal_cd, Number, 1)
        FROM master..spt_values
        WHERE Type='p' AND Number <= LEN(POSTAL_CD) AND
            SUBSTRING(POSTAL_CD, Number, 1) 
            LIKE '[0-9]' FOR XML Path(''))
    AS xml) AS varchar(MAX)))),0) not IN (0, 5,9)
    )

    
IF @@ERROR <> 0 GOTO ERROR



UPDATE DBO.XX_SABRIX_INV_OUT_SUM
SET STATUS_FL = 'E'
WHERE STATUS_FL = 'U' 
AND INVC_ID IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)
AND STATUS_RECORD_NUM IN (SELECT STATUS_RECORD_NUM FROM IMAPSSTG.DBO.XX_IMAPS_INV_ERROR)

IF @@ERROR <> 0 GOTO ERROR

PRINT '  *~^'
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF XX_SABRIX_VALIDATE_CRM_NUM_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '  *~^'

RETURN (0)


ERROR: 
RETURN 1


END

 

 

 

 

 

 

 

GO
 


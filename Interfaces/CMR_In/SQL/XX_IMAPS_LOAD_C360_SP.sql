USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_IMAPS_LOAD_C360_SP]    Script Date: 8/23/2022 11:16:51 AM ******/
DROP PROCEDURE [dbo].[XX_IMAPS_LOAD_C360_SP]
GO

/****** Object:  StoredProcedure [dbo].[XX_IMAPS_LOAD_C360_SP]    Script Date: 8/23/2022 11:16:51 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[XX_IMAPS_LOAD_C360_SP]

AS

/************************************************************************************************  
Name:       	XX_IMAPS_LOAD_C360_SP
Author:     	GEA
Created:    	08/2022
Purpose:    	Load IBM C360 Customer Data into local federal table
			    Federal customers and only those commercial customers required

Prerequisites: 	None

Parameters: 
	Input: 	none
	Output: none   

Version: 	1.0
Notes:      	Call example  
              	EXEC dbo.XX_IMAPS_LOAD_C360_SP


THIS JOB LOADS CUSTOMER DATA FROM MD360 DATABASE (SAME AS CREATE CMR) TO IMAPS

For support info, e.g. if we ever have to change the MD360 views: 

IMAPS CONFIG MANAGEMENT - MD360 <---- DB2 MD360 view source code in this folder

MD360 - https://w3.ibm.com/w3publisher/customer-master-data/operations/dous-and-slas

Art and Les (OPS) need to subscribe to CI-COM, it is a blog about downtime, notification, etc.  Here:

https://w3.ibm.com/w3publisher/cicomm/rd-customer-rdc

If none of this works, find EDWINA TIMS


************************************************************************************************/


BEGIN


DECLARE @FCNT INTEGER, @CCNT INTEGER

PRINT 'DELETING RECORDS FROM NEW STAGE TABLE'		

DELETE FROM IMAPSSTG.DBO.XX_IMAPS_C360

PRINT 'INSERT FEDERAL CUSTOMERS FIRST'

INSERT INTO IMAPSSTG.DBO.XX_IMAPS_C360
SELECT 
   I_CUST_ENTITY,
   I_CO,
   I_ENT,
   N_ABBREV,
   I_CUST_ADDR_TYPE,
   ADDR1,
   ADDR2,
   ADDR3,
   ADDR4,
   N_CITY,
   N_ST,
   C_ZIP,
   SCC_ST,
   C_SCC_CNTY,
   C_SCC_CITY,
   I_MKTG_OFF,
   A_LEVEL_1_VALUE,
   PRIMARY_SVC_OFF,
   C_ICC_TE,
   C_ICC_TAX_CLASS,
   C_ESTAB_SIC,
   I_INDUS_DEPT,
   I_INDUS_CLASS,
   C_NAP,
   I_TYPE_CUST_1,
   F_GENRL_SVC_ADMIN,
   F_OCL,
   XMIT_DATE
FROM C360..SAPR3.V_CI_USCMR_IMAPS

SELECT @CCNT = COUNT(*) FROM IMAPSSTG.DBO.XX_IMAPS_C360

PRINT CAST(@CCNT AS VARCHAR(10)) + ' FEDERAL RECORDS INSERTED'

PRINT 'INSERT FDS/SABRIX CUSTOMER FAILURES NOT INCLUDED IN CURRENT FEDERAL DOWNLOAD'

DELETE FROM  IMAPSSTG.DBO.XX_IMAPS_CUSTOMER_FAILURES

INSERT INTO IMAPSSTG.DBO.XX_IMAPS_CUSTOMER_FAILURES
SELECT DISTINCT CUST_ADDR_DC
FROM 
(SELECT CAST(CUST_ADDR_DC AS VARCHAR(20)) AS CUST_ADDR_DC
FROM IMAPSSTG.DBO.XX_SABRIX_INV_OUT_SUM
WHERE STATUS_FL <> 'P'
UNION
SELECT CAST(CUST_ADDR_DC AS VARCHAR(20)) AS CUST_ADDR_DC
FROM IMAPSSTG.DBO.XX_IMAPS_INV_OUT_SUM
WHERE STATUS_FL <> 'P') C
WHERE C.CUST_ADDR_DC NOT IN (SELECT I_CUST_ENTITY FROM IMAPSSTG.DBO.XX_IMAPS_C360)

INSERT INTO IMAPSSTG.DBO.XX_IMAPS_C360
SELECT 
   I_CUST_ENTITY,
   I_CO,
   I_ENT,
   N_ABBREV,
   I_CUST_ADDR_TYPE,
   ADDR1,
   ADDR2,
   ADDR3,
   ADDR4,
   N_CITY,
   N_ST,
   C_ZIP,
   SCC_ST,
   C_SCC_CNTY,
   C_SCC_CITY,
   I_MKTG_OFF,
   A_LEVEL_1_VALUE,
   PRIMARY_SVC_OFF,
   C_ICC_TE,
   C_ICC_TAX_CLASS,
   C_ESTAB_SIC,
   I_INDUS_DEPT,
   I_INDUS_CLASS,
   C_NAP,
   I_TYPE_CUST_1,
   F_GENRL_SVC_ADMIN,
   F_OCL,
   XMIT_DATE
FROM C360..SAPR3.V_CI_USCMR_IMAPS_NONFED
 WHERE 
 I_CUST_ENTITY_INT IN (SELECT I_CUST_ENTITY FROM IMAPSSTG.DBO.XX_IMAPS_CUSTOMER_FAILURES)

SELECT @FCNT = COUNT(*) FROM IMAPSSTG.DBO.XX_IMAPS_C360

IF @FCNT > @CCNT 
  BEGIN
	SET @FCNT = @FCNT - @CCNT
	PRINT CAST(@FCNT AS VARCHAR(10)) + ' NON-FEDERAL RECORDS INSERTED'
  END


IF @CCNT = 0
  BEGIN

    PRINT 'C360 RECORDS INSERT FAILED' 


  END

IF @CCNT > 0
  BEGIN
    PRINT 'LOCAL COUNT TEST PASSED. RECORDS EXIST IN IMAPSSTG.DBO.XX_IMAPS_C360'

	DELETE FROM IMAPSSTG.DBO.XX_IMAPS_CMR_STG;

	INSERT INTO IMAPSSTG.DBO.XX_IMAPS_CMR_STG
		(I_CUST_ENTITY,
		I_CO,
		I_ENT,
		N_ABBREV,
		I_CUST_ADDR_TYPE,
		T_ADDR_LINE_1,
		T_ADDR_LINE_2,
		T_ADDR_LINE_3,
		T_ADDR_LINE_4,
		N_CITY,
		N_ST,
		C_ZIP,
		C_SCC_ST,
		C_SCC_CNTY,
		C_SCC_CITY,
		I_MKTG_OFF,
		A_LEVEL_1_VALUE,
		I_PRIMRY_SVC_OFF,
		C_ICC_TE,
		C_ICC_TAX_CLASS,
		C_ESTAB_SIC,
		I_INDUS_DEPT,
		I_INDUS_CLASS,
		C_NAP,
		I_TYPE_CUST_1,
		F_GENRL_SVC_ADMIN,
		F_OCL)
		SELECT --TOP 5 
		   CAST(I_CUST_ENTITY AS INT),
		   CAST(I_CO AS INT),
		   CAST(I_ENT AS INT),
		   LEFT(LTRIM(N_ABBREV),15),
		   LEFT(LTRIM(I_CUST_ADDR_TYPE),1),
		   ADDR_LINE_1,
		   ADDR_LINE_2,
		   ADDR_LINE_3,
		   ADDR_LINE_4,
		   LEFT(LTRIM(N_CITY),13),
		   LEFT(LTRIM(N_ST),2),
		   CASE
				WHEN  ISNUMERIC(C_ZIP) = 0 THEN 0
				ELSE  CAST(C_ZIP AS INT)
		   END AS I_ZIP,
		   C_SCC_ST,
		   C_SCC_CNTY,
		   C_SCC_CITY,
		   LEFT(LTRIM(I_MKTG_OFF),3),
		   A_LEVEL_1_VALUE,
		   LEFT(LTRIM(I_PRIMRY_SVC_OFF),3),
		   C_ICC_TE,
		   C_ICC_TAX_CLASS,
		   LEFT(LTRIM(C_ESTAB_SIC),4),
		   LEFT(LTRIM(I_INDUS_DEPT),1),
		   LEFT(LTRIM(I_INDUS_CLASS),1),
		   C_NAP,
		   LEFT(LTRIM(I_TYPE_CUST_1),1),
		   F_GENRL_SVC_ADMIN,
		   F_OCL
		  -- XMIT_DATE
		FROM  -- C360..SAPR3.V_CI_USCMR_IMAPS
		IMAPSSTG.DBO.XX_IMAPS_C360
		WHERE 1=1;
	END


SELECT @CCNT = COUNT(*) FROM IMAPSSTG.DBO.XX_IMAPS_C360


PRINT CAST(@CCNT AS VARCHAR(10)) + ' RECORDS INSERTED, JOB COMPLETE'


PRINT '  *~^'
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF XX_IMAPS_LOAD_C360_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '  *~^'

RETURN (0)


ERROR: 
RETURN 1


END
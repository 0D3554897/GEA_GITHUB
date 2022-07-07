-- IMAPS UNDERLYING QUERY FOR VIEW SAPR3.V_CI_USCMR_IMAPS  (DIVISION 16)
-- 06/24/2022
-- GEORGE ALVAREZ, george.alvarez@us.ibm.com
-- GRANT PREPROD RIGHTS TO USERS george_alvarez_us_ibm_com and  
-- GRANT PROD RIGHTS TO USER  

SELECT
A.ZZKV_CUSNO AS I_CUST_ENTITY, 
A.ZZKV_NODE1 AS I_CO, 
A.ZZKV_NODE2 AS I_ENT, 
A.TELX1 AS N_ABBREV, 
A.KTOKD AS I_CUST_ADDR_TYPE,
A.ZZKV_SEQNO AS ADDRESS_SEQ_NO, 
SPACE(24) AS ADDR1,
SPACE(24) AS ADDR2,
SPACE(24) AS ADDR3,
SPACE(24) AS ADDR4,
A.ORT01 AS N_CITY, 
A.REGIO AS N_ST, 
REPLACE(A.PSTLZ, '-','') AS C_ZIP, 
LEFT(T.C_SCC,2) AS SCC_ST,
A.COUNC AS C_SCC_CNTY, 
RIGHT(T.C_SCC,4) AS C_SCC_CITY,
X.MKTG_DEPT AS I_MKTG_OFF,
LEFT(X.BO_DIVISION,2) AS A_LEVEL_1_VALUE, 
SPACE(30) AS PRIMARY_SVC_OFF,
T.C_ICC_TE AS C_ICC_TE, 
T.C_ICC_TAX_CLASS AS C_ICC_TAX_CLASS, 
A.ZZKV_LIC AS C_ESTAB_SIC, 
LEFT(A.BRAN1,1) AS I_INDUS_DEPT,
RIGHT(A.BRAN1,1) AS I_INDUS_CLASS, 
A.ZZKV_INACT AS C_NAP, 
LEFT(A.STCD2,1) AS I_TYPE_CUST_1,
CASE A.KUKLA
  WHEN 12 THEN 'Y'
  WHEN 15 THEN 'Y'
  ELSE 'N'
END AS F_GENRL_SVC_ADMIN,
T.F_OCL AS F_OCL, 
to_char(current_date, 'MMDDYYYY') AS XMIT_DATE

FROM	SAPR3.KNA1	A	
JOIN	SAPR3.KNVV_EXT	X	ON 
X.MANDT = A.MANDT AND 
X.KUNNR = A.KUNNR
JOIN	USINTERIM.US_TAX_DATA	T	
ON T.MANDT = A.MANDT AND 
T.KUNNR = A.KUNNR

Where 1=1

--/*************************** DATA DISCOVERY FILTERS, OMIT FROM TEST & PROD *********************/
--AND A.ZZKV_SEQNO = '102'
--AND A.ZZKV_CUSNO IN ('3684162') --('5115600')
--/******************************************************** EDWINA FILTERS **********************/
 AND 	 a.MANDT ='230'                                        -- Production Client 230=preprod, 100=PROD
--And      a.KATR6 = '897'                                       -- US 
And      a.LOEVM  != 'X'                                       -- Include only active records
And      a.KATR10 = ''        									-- Include IBM owned records only v. KYNDRYL
And      NOT(a.AUFSD in ('93', 'CL', '75'))                    -- Exclude Obsolete, CMRLite, Prospects
And      NOT(a.KTOKD in ('ZZ01', 'ZLST', 'ZORG'))              -- Exclude RDC internal Layer and List records)
And      TRIM (a.ZZKV_CUSNO)!= ''                              -- Exclude blank/ null CMR number records
And      (a.KUNNR NOT LIKE '0009%')                            -- Exclude RDH Direct records
--AND 	A.ZZKV_NODE1 IN ('10000030','10000081','10000113','10000172')   --?????
--/*********************************************************** DIV 16 DATA FILTERS **********************/
And 	A.KTOKD IN  ('ZS01','ZP01')				-- INSTALL ADDRESS
--And 	X.MKTG_RESP_CD =  						-- have to look at data see if it can be filtered further
And (
		(-- US FEDERAL COMMERCIAL CUSTOMERS
		LEFT (A.ZZKV_CUSNO, 2) NOT IN ('92', '93') AND (X.MKTG_AREA = '13')
    --  HOPEFULLY NEVER HAVE TO USE THIS, PULLS IN ALMOST EVERYBODY
	--	AND (
	--		(X.MKTG_AREA = '13') OR (X.PCC_MKTG_BO = 'Z3M')
	--		)
		)
OR
		(-- FEDERAL,STATE, LOCAL, EDUCATION, HEALTHCARE CUSTOMERS
		LEFT (A.ZZKV_CUSNO, 2) IN ('92', '93') AND X.MKTG_AREA IN ('02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '13') 
		)
)

-- GUESSES
AND A.ZZKV_SIC != ''

--/*********************************************************** LIMIT FILTER **********************/
--limit 100	
-- GROUP BY X.MKTG_AREA 
with UR														-- something about not locking tables
	
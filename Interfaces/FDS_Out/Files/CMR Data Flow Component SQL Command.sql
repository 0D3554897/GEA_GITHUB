-- CMR Data Flow Component's SQL command for SSIS pacakge CMR
-- Modified for both DR-10641 and CR-10290
-- 11/08/2019 Modified A_LEVEL_3_VALUE value list for DR-11842

SELECT
CUS.I_CUST_ENTITY,
CUS.I_CO,
COM.I_ENT,
BRO.A_LEVEL_1_VALUE,
CUS.N_ABBREV,
ADR.I_CUST_ADDR_TYPE,
'' as T_ADDR_LINE_1,
'' as T_ADDR_LINE_2,
'' as T_ADDR_LINE_3,
'' as T_ADDR_LINE_4,
ADR.N_CITY,
ADR.N_ST,
ADR.C_ZIP,
-- DR-10641 begin
CASE LENGTH(CAST(CAST(ADR.C_SCC as integer) as varchar(15)))
   WHEN 8 THEN CONCAT('0', LEFT(CAST(CAST(ADR.C_SCC as integer) as varchar(15)), 1))
   WHEN 9 THEN LEFT(CAST(CAST(ADR.C_SCC as integer) as varchar(15)), 2)
END as C_SCC_ST,
CASE LENGTH(CAST(CAST(ADR.C_SCC as integer) as varchar(15)))
   WHEN 8 THEN SUBSTR(CAST(CAST(ADR.C_SCC as integer) as varchar(15)), 2, 3)
   WHEN 9 THEN SUBSTR(CAST(CAST(ADR.C_SCC as integer) as varchar(15)), 3, 3)
END as C_SCC_CNTY,
RIGHT(CAST(CAST(ADR.C_SCC as integer) as varchar(15)), 4) as C_SCC_CITY,
-- DR-10641 end
ADR.I_MKTG_OFF,
ADR.I_PRIMRY_SVC_OFF,
CUS.C_ICC_TE,
CUS.C_ICC_TAX_CLASS,
CUS.C_ESTAB_SIC,
SIC.I_INDUS_DEPT,
SIC.I_INDUS_CLASS,
CUS.C_NAP,
CUS.I_TYPE_CUST_1,
CUS.F_GENRL_SVC_ADMIN,
ADR.F_OCL
FROM
CMRID.A11T0CUS CUS,
CMRID.A11T0BRO BRO,
CMRID.A11T0ADR ADR,
CMRID.A11T0SIC SIC,
CMRID.A11T0COM COM
WHERE
-- CR-10290 begin
BRO.A_LEVEL_3_VALUE IN ('02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '13') -- DR-11842
-- CR-10290 end
AND BRO.I_OFF = CUS.I_CUST_OFF_1
AND ADR.I_CUST_ENTITY = CUS.I_CUST_ENTITY
AND ADR.I_CUST_ADDR_TYPE IN ('1', '2')
AND CUS.C_ESTAB_SIC = SIC.C_SIC
AND ADR.I_CO = COM.I_CO

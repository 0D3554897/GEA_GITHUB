USE IMAPSSTG
DROP VIEW [dbo].[XX_SABRIX_INTERFACE_DTL_VW]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 

 

 

 

 

 

 

 



/* 
Used by CFF for Sabrix Interface

Len of field to be sent to packed decimal should be equal to first digit.  
For example, '00000000000' (LEN=11) would be sent to a DEC(11,2) packed decimal field
The number 12345.67 should be converted to 00001234567 for a total length of 11
To convert a column, use the general form:

packed decimal specification: DEC(X,Y)  (LENGTH, PRECISION)

RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(X,0),((COLUMN_NAME) * 100)) as varchar),X)

DECIMAL(X,0) TO REMOVE DECIMAL POINT, WHERE X = LENGTH OF THE PACKED DECIMAL SPECIFICATION
MULTIPLY THE AMOUNT (COLUMN_NAME) BY 100
ZEROES ARE APPENDED TO LEFT OF NUMBER
RIGHT FUNCTION LENGTH IS ALSO EQUAL TO X

DOING THIS PUTS A DASH (NEGATIVE CHAR) IN THE MIDDLE OF THE NUMBER... SO WE HAVE TO ADJUST:
WE USE A CASE STATEMENT, AND PUT THE GENERAL FORM INTO IT THREE TIMES

CASE CHARINDEX('-',
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(X,0),((COLUMN_NAME) * 100)) as varchar),X)
)WHEN 0 THEN 
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(X,0),((COLUMN_NAME) * 100)) as varchar),X)
ELSE '-' + REPLACE(
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(X,0),((COLUMN_NAME) * 100)) as varchar),X)
,'-','') END as TOT_AMT
*/

CREATE VIEW [dbo].[XX_SABRIX_INTERFACE_DTL_VW]
AS
Select * from (
	select 
	right('                  ' + c_state,2) as state_code,
	right('                  ' + c_cnty,3) as county_code,
	right('                  ' + c_city,4)as city_code,
	'0' as city_limit_code,
	' ' as cmr_override,
	-- bo = business office
	right('                  ' + I_BO,3) as marketing_bo,
	'   ' as accepting_bo,
	right('                  ' + ti_svc_bo,3) as service_bo,
	'0'+cust_addr_dc as customer_number,
	RIGHT('                              ' + CUST_NAME, 15) as customer_name,
	DIVISION as asset_division,
	'  ' as filler_01,
	tc_certifc_status as certificate_status_code,
	--' ' as certificate_status_code,
	TI_CMR_CUST_TYPE  as cmr_cust_type,
	--CASE TI_CMR_CUST_TYPE WHEN 'B' THEN 'F' WHEN 'E' THEN 'P' WHEN 'C' THEN 'S' WHEN 'A' THEN 'C' WHEN 'H' THEN 'A' WHEN 'K' THEN 'I' ELSE 'C' END as cmr_cust_type,
	right('                  ' + TC_TAX_CLASS,3) as tax_class_code,
	'142' as source_code,
	'9' as origin_code,
	--right('                  ' + tc_agrmnt,2) as agreement_code,
	LEFT(ltrim(tc_agrmnt) + '             ',2) as agreement_code,
	' ' as equip_code,
	DIVISION as Q_prod_catgy_code,
	'       ' as type_model,
	'       ' as serial,
	right(fy_cd,2) + RIGHT('0'+ cast(pd_no as varchar),2) as acct_date,
	right(a.INVC_ID,7) as invc_num,
	'       ' as invoice_idx,
	'       ' as factory_order,
	'       ' as cust_po,
	right(convert(varchar, a.invc_dt, 112),6) as invc_date,
	right(convert(varchar, b.ts_dt, 112),6) as actual_install,
	right(convert(varchar, b.ts_dt, 112),6) as actual_ship_date,
	right(convert(varchar, b.ts_dt, 112),6) as agreement_date,
	'   ' as ship_from_loc,
	'      ' as date_of_manuf,
	'1' as LOCAL_APP_CD,
	right('    ' + TC_TAX,2) as tax_id,
	'00001' as quantity,
	-- for diagnosis
	--a.invc_id,
	-- SUM(A.INVC_AMT - a.csp_amt) AS INVC_TOT,
	-- SUM(A.CSP_AMT) AS CSP_TOT,
	-- sum(b.BILLED_AMT - B.SALES_TAX_AMT) as BILLING,

	CASE CHARINDEX('-',
	  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),((sum(b.BILLED_AMT - B.SALES_TAX_AMT)) * 100)) as varchar),11)
	)WHEN 0 THEN 
	  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),((sum(b.BILLED_AMT - B.SALES_TAX_AMT)) * 100)) as varchar),11)
	ELSE '-' + REPLACE(
	  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),((sum(b.BILLED_AMT - B.SALES_TAX_AMT)) * 100)) as varchar),11)
	,'-','') END as REV,

	--RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),((sum(b.BILLED_AMT - B.SALES_TAX_AMT)) * 100)) as varchar),11) as REV,
	'000000000' as cost,
	'000000000' as opt,
	'000000000' as disc,
	'000000000' as zonechg,
	'000000000' as ti_me,

	CASE CHARINDEX('-',
	  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),(SUM(b.STATE_SALES_TAX_AMT) * 100)) as varchar),9)
	)WHEN 0 THEN 
	  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),(SUM(b.STATE_SALES_TAX_AMT) * 100)) as varchar),9)
	ELSE '-' + REPLACE(
	  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),(SUM(b.STATE_SALES_TAX_AMT) * 100)) as varchar),9)
	,'-','') END as statetax,

	--RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),(SUM(b.STATE_SALES_TAX_AMT) * 100)) as varchar),9) as statetax,

	CASE CHARINDEX('-',
	  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),(SUM(b.COUNTY_SALES_TAX_AMT) * 100)) as varchar),9)
	)WHEN 0 THEN 
	  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),(SUM(b.COUNTY_SALES_TAX_AMT) * 100)) as varchar),9)
	ELSE '-' + REPLACE(
	  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),(SUM(b.COUNTY_SALES_TAX_AMT) * 100)) as varchar),9)
	,'-','') END as countytax,

	--RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),(SUM(b.COUNTY_SALES_TAX_AMT) * 100)) as varchar),9)as countytax,

	CASE CHARINDEX('-',
	  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),(SUM(b.CITY_SALES_TAX_AMT) * 100)) as varchar),9)
	)WHEN 0 THEN 
	  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),(SUM(b.CITY_SALES_TAX_AMT) * 100)) as varchar),9)
	ELSE '-' + REPLACE(
	  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),(SUM(b.CITY_SALES_TAX_AMT) * 100)) as varchar),9)
	,'-','') END as citytax,

	--RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),(SUM(b.CITY_SALES_TAX_AMT) * 100)) as varchar),9) as citytax,
	'  ' as customer_control,
	'    ' as adj_num,
	'2' as fds_rev_type,
	0 as alpha_source,
	-- c.mail_state_dc as state_abbr,   <--- SABRIX doesn't like nulls
	coalesce(c.mail_state_dc, ' ') as state_abbr,
	coalesce(LEFT(c.CITY_NAME + '                       ',20),SPACE(20)) as city_name,
	coalesce(LEFT(postal_cd,5),SPACE(5)) as postcode,
	-- 4 digits only and fill nulls with 4 blanks
	coalesce((SELECT CAST(CAST((
			SELECT SUBSTRING(RIGHT(postal_cd,4), Number, 1)
			FROM master..spt_values
			WHERE Type='p' AND Number <= LEN(RIGHT(postal_cd,4)) AND
				SUBSTRING(RIGHT(postal_cd,4), Number, 1) LIKE '[0-9]' FOR XML Path(''))
		AS xml) AS varchar(MAX))),space(4)) as geocode 

	from imapsstg.dbo.XX_SABRIX_INV_OUT_SUM a 
	join imapsstg.dbo.XX_SABRIX_INV_OUT_DTL b on a.INVC_ID = b.invc_id 
	join imaps.deltek.cust_addr c on a.cust_addr_dc = c.ADDR_DC and a.CUST_ID = c.cust_id
	where 1=1
	--and right(a.INVC_ID,7) = '2478895'
	 and (coalesce(b.acct_id,'0') not in (SELECT PARAMETER_VALUE FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS WHERE PARAMETER_NAME = 'CSP_ACCT_ID'))
	AND A.STATUS_FL <> 'E'
	--AND (A.INVC_AMT - A.CSP_AMT) <> 0 
	--AND b.BILLED_AMT - B.SALES_TAX_AMT <> 0
	-- exclude non-US addresses, 
	AND c.mail_state_dc IS NOT NULL
	--but include nulls IN COUNTRY CODE
	AND coalesce(ltrim(rtrim(C.country_cd)),'USA') = 'USA'
	group by a.cust_id, a.C_STATE, a.C_CNTY,A.C_CITY,A.I_BO,A.TI_SVC_BO,A.CUST_ADDR_DC,A.CUST_NAME,A.DIVISION,A.TI_CMR_CUST_TYPE,A.TC_TAX_CLASS,B.TC_AGRMNT,A.FY_CD,A.PD_NO,A.INVC_ID,A.INVC_DT,B.TS_DT,B.TC_TAX,C.MAIL_STATE_DC,C.CITY_NAME,C.POSTAL_CD,TC_CERTIFC_STATUS
	union
	-- THIS QUERY GETS CSP INVOICES WITH NO DIV16 LINE ITEMS SO THAT SABRIX CAN REPORT ALL INVOICES, INCLUDING ZERO DOLLAR
	select
	right('                  ' + c_state,2) as state_code,
	right('                  ' + c_cnty,3) as county_code,
	right('                  ' + c_city,4)as city_code,
	'0' as city_limit_code,
	' ' as cmr_override,
	-- bo = business office
	right('                  ' + I_BO,3) as marketing_bo,
	'   ' as accepting_bo,
	right('                  ' + ti_svc_bo,3) as service_bo,
	'0'+cust_addr_dc as customer_number,
	RIGHT('                              ' + CUST_NAME, 15) as customer_name,
	DIVISION as asset_division,
	'  ' as filler_01,
	-- ' ' as certificate_status_code,
	TC_CERTIFC_STATUS  as certificate_status_code,
	-- CASE TI_CMR_CUST_TYPE WHEN 'B' THEN 'F' WHEN 'E' THEN 'P' WHEN 'C' THEN 'S' WHEN 'A' THEN 'C' WHEN 'H' THEN 'A' WHEN 'K' THEN 'I' ELSE 'C' END as cmr_cust_type,
	TI_CMR_CUST_TYPE as cmr_cust_type,
	right('                  ' + TC_TAX_CLASS,3) as tax_class_code,
	'142' as source_code,
	'9' as origin_code,
	--right('                  ' + tc_agrmnt,2) as agreement_code,
	LEFT(ltrim(tc_agrmnt) + '             ',2) as agreement_code,
	' ' as equip_code,
	DIVISION as prod_catgy_code,
	'       ' as type_model,
	'       ' as serial,
	right(fy_cd,2) + RIGHT('0'+ cast(pd_no as varchar),2) as acct_date,
	right(a.INVC_ID,7) as invc_num,
	'       ' as invoice_idx,
	'       ' as factory_order,
	'       ' as cust_po,
	right(convert(varchar, a.invc_dt, 112),6) as invc_date,
	right(convert(varchar, b.ts_dt, 112),6) as actual_install,
	right(convert(varchar, b.ts_dt, 112),6) as actual_ship_date,
	right(convert(varchar, b.ts_dt, 112),6) as agreement_date,
	'   ' as ship_from_loc,
	'      ' as date_of_manuf,
	'1' as LOCAL_APP_CD,
	right('    ' + TC_TAX,2) as tax_id,
	'00001' as quantity,
	-- for diagnosis
	--a.invc_id,
	-- SUM(A.INVC_AMT - a.csp_amt) AS INVC_TOT,
	-- SUM(A.CSP_AMT) AS CSP_TOT,
	-- sum(b.BILLED_AMT - B.SALES_TAX_AMT) as BILLING,
	-- NEGATIVE FORMATTING NOT NECESSARY FOR A ZERO
	RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),((0) * 100)) as varchar),11) as REV,
	'000000000' as cost,
	'000000000' as opt,
	'000000000' as disc,
	'000000000' as zonechg,
	'000000000' as ti_me,
	-- NEGATIVE FORMATTING NOT NECESSARY FOR A ZERO
	RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),((0) * 100)) as varchar),9) as statetax,
	RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),((0) * 100)) as varchar),9)as countytax,
	RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,0),((0) * 100)) as varchar),9) as citytax,
	'  ' as customer_control,
	'    ' as adj_num,
	'2' as fds_rev_type,
	0 as alpha_source,
	coalesce(c.mail_state_dc,SPACE(2)) as state_abbr,
	coalesce(LEFT(c.CITY_NAME + '                       ',20),space(20)) as city_name,
	coalesce(LEFT(postal_cd,5),space(5)) as postcode,
	-- 4 digits only, and fill nulls with 4 blanks
	coalesce((SELECT CAST(CAST((
			SELECT SUBSTRING(RIGHT(postal_cd,4), Number, 1)
			FROM master..spt_values
			WHERE Type='p' AND Number <= LEN(RIGHT(postal_cd,4)) AND
				SUBSTRING(RIGHT(postal_cd,4), Number, 1) LIKE '[0-9]' FOR XML Path(''))
		AS xml) AS varchar(MAX))),space(4)) as geocode 

	from imapsstg.dbo.XX_SABRIX_INV_OUT_SUM a 
	join imapsstg.dbo.XX_SABRIX_INV_OUT_DTL b on a.INVC_ID = b.invc_id 
	join imaps.deltek.cust_addr c on a.cust_addr_dc = c.ADDR_DC and a.CUST_ID = c.cust_id
	where 1=1
	--and right(a.INVC_ID,7) in ('2478174', '2476062', '2478895')
	 and (coalesce(b.acct_id,'0') not in (SELECT PARAMETER_VALUE FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS WHERE PARAMETER_NAME = 'CSP_ACCT_ID'))
	AND A.STATUS_FL <> 'E'
	and b.INVC_ID not in (select d.INVC_ID from imapsstg.dbo.XX_SABRIX_INV_OUT_DTL d where (coalesce(D.acct_id,'0') not in (SELECT PARAMETER_VALUE FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS WHERE PARAMETER_NAME = 'CSP_ACCT_ID'))
	-- exclude non-US addresses, 
	AND c.mail_state_dc IS NOT NULL
	--but include nulls IN COUNTRY CODE
	AND coalesce(ltrim(rtrim(C.country_cd)),'USA') = 'USA')
)vw
where state_code in
('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31', '32', '33', '34', '35', '36', '37', '38', '39', '40', '41', '42', '43', '44', '45', '46', '47', '48', '49', '50', '51', '53', '54', '61')

-- AND (A.INVC_AMT - A.CSP_AMT) <> 0 
-- AND b.BILLED_AMT - B.SALES_TAX_AMT <> 0
-- group by a.C_STATE, a.C_CNTY,A.C_CITY,A.I_BO,A.TI_SVC_BO,A.CUST_ADDR_DC,A.CUST_NAME,A.DIVISION,A.TI_CMR_CUST_TYPE,A.TC_TAX_CLASS,B.TC_AGRMNT,A.FY_CD,A.PD_NO,A.INVC_ID,A.INVC_DT,B.TS_DT,B.TC_TAX,C.MAIL_STATE_DC,C.CITY_NAME,C.POSTAL_CD
--order by INVC_ID


 

 

 

 

 

 

 

 

GO
 


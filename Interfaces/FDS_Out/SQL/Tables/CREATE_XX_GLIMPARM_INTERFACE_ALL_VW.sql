USE [IMAPSStg]
GO

/****** Object:  View [dbo].[XX_GLIMPARM_INTERFACE_ALL_VW]    Script Date: 09/13/2018 11:14:59 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[XX_GLIMPARM_INTERFACE_ALL_VW]'))
DROP VIEW [dbo].[XX_GLIMPARM_INTERFACE_ALL_VW]
GO

USE [IMAPSStg]
GO

/****** Object:  View [dbo].[XX_GLIMPARM_INTERFACE_ALL_VW]    Script Date: 09/13/2018 11:15:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


/* 
Used by CFF for Sabrix Interface

*/

CREATE VIEW [dbo].[XX_GLIMPARM_INTERFACE_ALL_VW]
AS




SELECT 'CC' AS CONSTANT,
A AS FILE_ID, 
B AS FILLER_01, 
C AS DATE, 
D AS FILLER_02, 
right('                         ' + left(cast(sum(debits) as varchar(25)),
LEN(cast(sum(debits) as varchar(25)))-2) + '.' + right(cast(sum(debits) as varchar(25)),2),16) AS DEBITS,
F AS FILLER_03, 
RIGHT('         ' + CAST(COUNT(G) AS VARCHAR(7)),7) AS CNT, 
H AS FILLER_04, 
I AS CONFCODE, 
J AS FILLER_05, 
K AS REVERSE, 
L AS FILLER_06, 
SUM(TOT)AS ZERO, 
N AS COUNTRY 

FROM (SELECT '121' AS A, SPACE(2) AS B, convert(varchar(6),getdate(),112) AS C,SPACE(2) AS D, case when CAST(AMOUNTLOCALCURRENCY AS bigINT) < 0 then 0 else CAST(AMOUNTLOCALCURRENCY AS bigINT) end AS DEBITS, 
      SPACE(2) AS F, 1 AS G, SPACE(1) AS H, VCODE.PADDED AS I,SPACE(1) AS J, 'N' AS K, SPACE(13) AS L, SUM(CAST(CAST(AMOUNTLOCALCURRENCY AS DECIMAL(16,2))/100 AS DECIMAL(15,2)))AS TOT, 
	  '         897' AS N 
	  /*****  this is the old glim detail query
	  FROM (
	  
	  select ID, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, invc, T, U, V, W, X, Y, Z, AA, AB, AC, AD, AE, AF, AG, AH, AI, AJ, AK, AL, AM, AN, AO, AP, AQ, AR, XAS, AT, AU, AV, AW 
	        from (select 'HDR' as ID ,'897' as A, '00' as B, '121' as C, '0000' as D, 'L' as E, '16' as F, '107' as G, '0112' as H, '0016' as I, 'FED   ' as J, space(28) as K, '121' as L, 'TBD' as M, 'FED    ' as N, space(5) as O, REPLACE(CONVERT(VARCHAR(10),GETDATE(),3),'/','') as P, month(GETDATE()) as Q, space(2) as R, case when AVG(a.INVC_AMT) - AVG(a.CSP_AMT) < 0 then left(ltrim(cast(avg(cast(A.INVC_AMT*100 as int))- avg(cast(CSP_AMT*100 as int)) as varchar(25))),1) else '0' end  + right('000000000000000' + ltrim(cast(abs(avg(cast(A.INVC_AMT*100 as int))- avg(cast(CSP_AMT*100 as int))) as varchar(25))),15) as invc, '000000000000000' as T, space(7) as U, left(right(A.INVC_ID,7)+'           ',10) as V, space(2) as W, left('GBS Federal Bill' + '                              ',30) as X, space(156) as Y, 'F' as Z, space(43) as AA, left(A.I_MKG_DIV + '  ',2) as AB, space(33) as AC, left(A.CUST_ADDR_DC + '       ',7) as AD, space(154) as AE, space(7) as AF, space(18) as AG, left(A.PRIME_CONTR_ID + '               ',12) as AH, space(41) as AI, left(A.I_BO + '   ',3) as AJ, space(150) as AK, left(A.C_STD_IND_CLASS + '     ',4) as AL, space(14) as AM, left(A.C_STATE + '  ',2) as AN, left(A.C_CNTY + '     ',3) as AO, left(A.C_CITY + '     ',4) as AP, space(46) as AQ, left(A.C_INDUS + '     ',2) as AR, space(1) as XAS, REPLACE(CONVERT(VARCHAR(10),A.INVC_DT,1),'/','') as AT, space(23) as AU, left(A.I_ENTERPRISE + '         ',7) as AV, space(93) as AW, space(1) as AX, space(1) as AY, space(1) as AZ, space(1) as BA, space(1) as BB, space(1) as BC, space(1) as BD, space(1) as BE, space(1) as BF, space(1) as BG, space(1) as BH, space(1) as BI, space(1) as BJ, space(1) as BK, space(1) as BL, space(1) as BM, space(1) as BN 
				  from IMAPSSTG.DBO.XX_IMAPS_INV_OUT_SUM a 
				  inner join IMAPSSTG.DBO.XX_IMAPS_INV_OUT_DTL b 
				       on a.INVC_ID = b.INVC_ID 
				  where (a.invc_amt - A.CSP_AMT) <> 0 AND A.STATUS_FL <> 'E' 
				  GROUP BY A.INVC_ID, A.I_MKG_DIV, A.CUST_ADDR_DC, A.PRIME_CONTR_ID, A.C_STD_IND_CLASS, A.C_STATE, A.C_CNTY, A.C_CITY, A.C_INDUS, A.I_ENTERPRISE, REPLACE(CONVERT(VARCHAR(10),A.INVC_DT,1),'/',''), A.I_BO
				  ) x 
	  UNION select ID, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, invc, T, U, V, W, X, Y, Z, AA, AB, AC, AD, AE, AF, AG, AH, AI, AJ, AK, AL, AM, AN, AO, AP, AQ, AR, XAS, AT, AU, AV, AW 
			FROM (select 'TAX' as ID ,'897' as A, '00' as B, '121' as C, '0000' as D, 'L' as E, '16' as F, '107' as G, '0112' as H, '0016' as I, 'FED   ' as J, space(28) as K, '121' as L, 'TBD' as M, 'FED    ' as N, space(5) as O, REPLACE(CONVERT(VARCHAR(10),GETDATE(),3),'/','') as P, month(GETDATE()) as Q, space(2) as R, case when sum(B.SALES_TAX_AMT)*-1 < 0 then left(ltrim(cast(sum(B.SALES_TAX_AMT)*-1 as varchar(25))),1) else '0' end  + right('000000000000000' + ltrim(cast(cast((abs(sum(B.SALES_TAX_AMT)*-100)) as int) as varchar(25))),15) as invc, '000000000000000' as T, space(7) as U, left(right(A.INVC_ID,7)+'           ',10) as V, space(2) as W, left('GBS Federal Bill' + '                              ',30) as X, space(156) as Y, 'F' as Z, space(43) as AA, left(A.I_MKG_DIV + '  ',2) as AB, space(33) as AC, left(A.CUST_ADDR_DC + '       ',7) as AD, space(154) as AE, space(7) as AF, space(18) as AG, left(A.PRIME_CONTR_ID + '               ',12) as AH, space(41) as AI ,left(A.I_BO + '   ',3) as AJ, space(150) as AK, left(A.C_STD_IND_CLASS + '     ',4) as AL, space(14) as AM, left(A.C_STATE + '  ',2) as AN, left(A.C_CNTY + '     ',3) as AO, left(A.C_CITY + '     ',4) as AP, space(46) as AQ, left(A.C_INDUS + '     ',2) as AR, space(1) as XAS, REPLACE(CONVERT(VARCHAR(10),A.INVC_DT, 1),'/','') as AT, space(23) as AU, left(A.I_ENTERPRISE + '         ',7) as AV, space(93) as AW, b.ri_billable_chg_cd as AX, b.m_product_code as AY, b.i_mach_type as AZ, b.tc_agrmnt as BA, b.tc_prod_catgry as BB, b.ts_dt as BC, b.tc_tax as BD, b.bill_rt_amt as BE, b.id as BF, b.name as BG, b.bill_lab_cat_cd as BH, b.bill_lab_cat_desc as BI, b.bill_fm_grp_no as BJ, b.bill_fm_grp_lbl as BK, b.rf_gsa_indicator as BL, b.bill_fm_ln_no as BM, b.bill_fm_ln_lbl as BN 
				  from IMAPSSTG.DBO.XX_IMAPS_INV_OUT_SUM a 
				  inner join IMAPSSTG.DBO.XX_IMAPS_INV_OUT_DTL b 
					   on a.INVC_ID = b.INVC_ID  
				  where A.STATUS_FL <> 'E' AND b.sales_tax_amt <> 0 and coalesce(b.acct_id,'0') not in ('48-79-08','49-79-08') 
				  group by a.INVC_ID, A.I_MKG_DIV, A.CUST_ADDR_DC, A.PRIME_CONTR_ID, A.C_STD_IND_CLASS, A.C_STATE, A.C_CNTY, A.C_CITY, A.C_INDUS, REPLACE(CONVERT(VARCHAR(10),A.INVC_DT,1),'/',''), A.I_ENTERPRISE, b.ri_billable_chg_cd, b.m_product_code, b.i_mach_type, b.tc_agrmnt, b.tc_prod_catgry, b.ts_dt, b.tc_tax, b.bill_rt_amt, b.id, b.name, b.bill_lab_cat_cd, b.bill_lab_cat_desc, b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.rf_gsa_indicator, b.bill_fm_ln_no, b.bill_fm_ln_lbl, A.I_BO 
				  )y 
	  UNION select ID, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, invc, T, U, V, W, X, Y, Z, AA, AB, AC, AD, AE, AF, AG, AH, AI, AJ, AK, AL, AM, AN, AO, AP, AQ, AR, XAS, AT, AU, AV, AW 
			FROM (select 'DTL' as ID ,'897' as A, '00' as B, '121' as C, '0000' as D, 'L' as E, '16' as F, '356' as G, '0300' as H, '0000' as I, 'FED   ' as J, space(28) as K, '121' as L, 'TBD' as M, 'FED    ' as N, space(5) as O, REPLACE(CONVERT(VARCHAR(10),GETDATE(),3),'/','') as P, month(GETDATE()) as Q, space(2) as R ,case when sum(B.BILLED_AMT - B.SALES_TAX_AMT)*-1 < 0 then left(ltrim(cast(sum(B.BILLED_AMT - B.SALES_TAX_AMT)*-1 as varchar(25))),1) else '0' end  + right('000000000000000' + ltrim(cast(cast((abs(sum(B.BILLED_AMT - B.SALES_TAX_AMT)*-100)) as int) as varchar(25))),15) as invc , '000000000000000' as T ,space(7) as U, left(right(A.INVC_ID,7)+'           ',10) as V, space(2) as W, left('GBS Federal Bill' + '                              ',30) as X, space(156) as Y, 'F' as Z, space(43) as AA, left(A.I_MKG_DIV + '  ',2) as AB, space(33) as AC, left(A.CUST_ADDR_DC + '       ',7) as AD, space(154) as AE, space(7) as AF ,space(18) as AG, left(A.PRIME_CONTR_ID + '               ',12) as AH, space(41) as AI, left(A.I_BO + '   ',3) as AJ, space(150) as AK, left(A.C_STD_IND_CLASS + '     ',4) as AL, space(14) as AM, left(A.C_STATE + '  ',2) as AN, left(A.C_CNTY + '     ',3) as AO,left(A.C_CITY + '     ',4) as AP, space(46) as AQ , left(A.C_INDUS + '     ',2) as AR, space(1) as XAS, REPLACE(CONVERT(VARCHAR(10),A.INVC_DT, 1), '/', '') as AT, space(23) as AU, left(A.I_ENTERPRISE + '         ',7) as AV, space(93) as AW, b.ri_billable_chg_cd as AX, b.m_product_code as AY, b.i_mach_type as AZ, b.tc_agrmnt as BA, b.tc_prod_catgry as BB, b.ts_dt as BC, b.tc_tax as BD, b.bill_rt_amt as BE, b.id as BF, b.name as BG, b.bill_lab_cat_cd as BH, b.bill_lab_cat_desc as BI, b.bill_fm_grp_no as BJ, b.bill_fm_grp_lbl as BK, b.rf_gsa_indicator as BL, b.bill_fm_ln_no as BM, b.bill_fm_ln_lbl as BN 
				  from IMAPSSTG.DBO.XX_IMAPS_INV_OUT_SUM a 
				  inner join IMAPSSTG.DBO.XX_IMAPS_INV_OUT_DTL b 
					   on a.INVC_ID = b.INVC_ID  
				  where A.STATUS_FL <> 'E' AND b.billed_amt <> 0  and coalesce(b. acct_id,'0') not in ('48-79-08','49-79-08')  
				  group by a.INVC_ID, A.I_MKG_DIV, A.CUST_ADDR_DC, B.PROJ_ABBRV_CD, A.PRIME_CONTR_ID, A.C_STD_IND_CLASS, A.C_STATE, A.C_CNTY, A.C_CITY, A.C_INDUS, REPLACE(CONVERT(VARCHAR(10),A.INVC_DT,1),'/',''), A.I_ENTERPRISE, b.ri_billable_chg_cd, b.m_product_code, b.i_mach_type, b.tc_agrmnt, b.tc_prod_catgry, b.ts_dt, b.tc_tax, b.bill_rt_amt, b.id, b.name, b.bill_lab_cat_cd, b.bill_lab_cat_desc, b.bill_fm_grp_no, b.bill_fm_grp_lbl, b.rf_gsa_indicator, b.bill_fm_ln_no, b.bill_fm_ln_lbl, A.I_BO 
				  )z 
	  )PARM 
	  *****   end of old glim detail query ********/

	  /*****  this is the new glim detail query that builds the view */
	  FROM (select  
		'HDR' as ID ,
		'897' as COUNTRY
		,'00' as LCODE
		,'121' as FILEID
		,'0000' as FILESEQUENCE
		,'L' as TYPEOFLEDGERINDICATORTOLI
		,'16' as DIVISION
		,'107' as MAJOR
		,'0112' as MINOR
		,'0016' as SUBMINORMANDATORYINLEADING
		,'FED   ' as LUNIT
		,space(28) as FILLER1
		,'121' as LEDGERSOURCE
		,'TBD' as ACCOUNTANT
		,'FED    ' as INDEXNUMBERVOUCHERNUMBER
		,space(5) as FILLER2
		,REPLACE(CONVERT(VARCHAR(10),GETDATE(),3),'/','') as DATEOFLEDGERENTRYMANDATORY
		,month(GETDATE()) as ACCOUNTINGMONTHLOCAL
		,space(2) as FILLER3
		,case when AVG(a.INVC_AMT) - AVG(a.CSP_AMT) < 0 then left(ltrim(cast(cast(AVG(A.INVC_AMT*100) AS bigint)- cast(AVG(CSP_AMT*100) as bigint) as varchar(25))),1) else '0' end  + right('000000000000000' + ltrim(cast(abs(cast(AVG(A.INVC_AMT*100) as bigint)- cast(AVG(CSP_AMT*100) as bigint)) as varchar(25))),15) as AMOUNTLOCALCURRENCY
		,'000000000000000' as ZERO
		,space(7) as FILLER4
		,left(right(A.INVC_ID,7)+'           ',10) as INVOICENUMBER
		,space(2) as FILLER5
		,left('GBS Federal Bill' + '                              ',30) as DESCRIPTION
		,space(156) as FILLER6
		,'F' as INPUTTYPE
		,space(43) as FILLER7
		,left(A.I_MKG_DIV + '  ',2) as MARKETINGDIVISIONAKABUSINESS
		,space(33) as FILLER8
		,left(A.CUST_ADDR_DC + '       ',7) as CUSTOMERNUMBERSECONDARYAUDITMUSTBEADIGIT
		,space(154) as FILLER9
		,space(7) as IGSPROJECTSECONDARYAUDITMUSTBE
		,space(18) as FILLER10
		,left(A.PRIME_CONTR_ID + '               ',12) as CONTRACT
		,space(41) as FILLER11
		,left(A.I_BO + '   ',3) as BRANCHOFCOWNR
		,space(150) as FILLER17
		,left(A.C_STD_IND_CLASS + '     ',4) as INDUSTRYCLASS
		,space(14) as FILLER12
		,left(A.C_STATE + '  ',2) as STATETAX
		,left(A.C_CNTY + '     ',3) as COUNTYTAX
		,left(A.C_CITY + '     ',4) as CITYTAX
		,space(46) as FILLER13
		,left(A.C_INDUS + '     ',2) as INDUSTRY
		,space(1) as FILLER14
		,REPLACE(CONVERT(VARCHAR(10),A.INVC_DT,1),'/','') as INVOICEDATE
		,space(23) as FILLER15
		,left(A.I_ENTERPRISE + '         ',7) as LENTERPRISE
		,space(93) as FILLER16



		/******************
		,space(1) as AX ,
		space(1) as AY ,
		space(1) as AZ ,
		space(1) as BA ,
		space(1) as BB ,
		space(1) as BC ,
		space(1) as BD ,
		space(1) as BE ,
		space(1) as BF ,
		space(1) as BG ,
		space(1) as BH ,
		space(1) as BI ,
		space(1) as BJ ,
		space(1) as BK ,
		space(1) as BL ,
		space(1) as BM ,
		space(1) as BN 
		*******************/

		from IMAPSSTG.DBO.XX_IMAPS_INV_OUT_SUM a  
		inner join IMAPSSTG.DBO.XX_IMAPS_INV_OUT_DTL b on a.INVC_ID = b.INVC_ID   
		where (a.invc_amt - A.CSP_AMT) <> 0 AND A.STATUS_FL <> 'E'  
		GROUP BY 
		A.INVC_ID,
		A.I_MKG_DIV,
		A.CUST_ADDR_DC,
		A.PRIME_CONTR_ID,
		A.C_STD_IND_CLASS,
		A.C_STATE,
		A.C_CNTY,
		A.C_CITY,
		A.C_INDUS,
		A.I_ENTERPRISE,
		REPLACE(CONVERT(VARCHAR(10),A.INVC_DT,1),'/',''),
		A.I_BO
		UNION
		-- TAX
		select 
		'TAX' as ID ,
		'897' as COUNTRY
		,'00' as LCODE
		,'121' as FILEID
		,'0000' as FILESEQUENCE
		,'L' as TYPEOFLEDGERINDICATORTOLI
		,'16' as DIVISION
		,'107' as MAJOR
		,'0112' as MINOR
		,'0016' as SUBMINORMANDATORYINLEADING
		,'FED   ' as LUNIT
		,space(28) as FILLER1
		,'121' as LEDGERSOURCE
		,'TBD' as ACCOUNTANT
		,'FED    ' as INDEXNUMBERVOUCHERNUMBER
		,space(5) as FILLER2
		,REPLACE(CONVERT(VARCHAR(10),GETDATE(),3),'/','') as DATEOFLEDGERENTRYMANDATORY
		,month(GETDATE()) as ACCOUNTINGMONTHLOCAL
		,space(2) as FILLER3
		,case when sum(B.SALES_TAX_AMT)*-1 < 0 then left(ltrim(cast(sum(B.SALES_TAX_AMT)*-1 as varchar(25))),1) else '0' end  + right('000000000000000' + ltrim(cast(cast((abs(sum(B.SALES_TAX_AMT)*-100)) as bigint) as varchar(25))),15) as AMOUNTLOCALCURRENCY
		,'000000000000000' as ZERO
		,space(7) as FILLER4
		,left(right(A.INVC_ID,7)+'           ',10) as INVOICENUMBER
		,space(2) as FILLER5
		,left('GBS Federal Bill' + '                              ',30) as DESCRIPTION
		,space(156) as FILLER6
		,'F' as INPUTTYPE
		,space(43) as FILLER7
		,left(A.I_MKG_DIV + '  ',2) as MARKETINGDIVISIONAKABUSINESS
		,space(33) as FILLER8
		,left(A.CUST_ADDR_DC + '       ',7) as CUSTOMERNUMBERSECONDARYAUDITMUSTBEADIGIT
		,space(154) as FILLER9
		,space(7) as IGSPROJECTSECONDARYAUDITMUSTBE
		,space(18) as FILLER10
		,left(A.PRIME_CONTR_ID + '               ',12) as CONTRACT
		,space(41) as FILLER11
		,left(A.I_BO + '   ',3) as BRANCHOFCOWNR
		,space(150) as FILLER17
		,left(A.C_STD_IND_CLASS + '     ',4) as INDUSTRYCLASS
		,space(14) as FILLER12
		,left(A.C_STATE + '  ',2) as STATETAX
		,left(A.C_CNTY + '     ',3) as COUNTYTAX
		,left(A.C_CITY + '     ',4) as CITYTAX
		,space(46) as FILLER13
		,left(A.C_INDUS + '     ',2) as INDUSTRY
		,space(1) as FILLER14
		,REPLACE(CONVERT(VARCHAR(10),A.INVC_DT,1),'/','') as INVOICEDATE
		,space(23) as FILLER15
		,left(A.I_ENTERPRISE + '         ',7) as LENTERPRISE
		,space(93) as FILLER16

		/********************************
		,b.ri_billable_chg_cd as AX  ,
		b.m_product_code as AY  ,
		b.i_mach_type as AZ  ,
		b.tc_agrmnt as BA  ,
		b.tc_prod_catgry as BB  ,
		b.ts_dt as BC  ,
		b.tc_tax as BD  ,
		b.bill_rt_amt as BE  ,
		b.id as BF  ,
		b.name as BG  ,
		b.bill_lab_cat_cd as BH  ,
		b.bill_lab_cat_desc as BI  ,
		b.bill_fm_grp_no as BJ  ,
		b.bill_fm_grp_lbl as BK  ,
		b.rf_gsa_indicator as BL  ,
		b.bill_fm_ln_no as BM  ,
		b.bill_fm_ln_lbl as BN 
		*********************************/

		from IMAPSSTG.DBO.XX_IMAPS_INV_OUT_SUM a  
		inner join IMAPSSTG.DBO.XX_IMAPS_INV_OUT_DTL b 
		  on a.INVC_ID = b.INVC_ID  
		where A.STATUS_FL <> 'E' 
		  AND b.sales_tax_amt <> 0  
		  and coalesce(b.acct_id,'0') not in ('48-79-08','49-79-08')  
		group by a.INVC_ID ,
		A.I_MKG_DIV ,
		A.CUST_ADDR_DC ,
		A.PRIME_CONTR_ID ,
		A.C_STD_IND_CLASS ,
		A.C_STATE ,
		A.C_CNTY ,
		A.C_CITY ,
		A.C_INDUS ,
		REPLACE(CONVERT(VARCHAR(10),A.INVC_DT,1),'/',''),
		A.I_ENTERPRISE ,
		b.ri_billable_chg_cd ,
		b.m_product_code ,
		b.i_mach_type ,
		b.tc_agrmnt ,
		b.tc_prod_catgry ,
		b.ts_dt ,
		b.tc_tax ,
		b.bill_rt_amt ,
		b.id ,
		b.name ,
		b.bill_lab_cat_cd ,
		b.bill_lab_cat_desc ,
		b.bill_fm_grp_no ,
		b.bill_fm_grp_lbl ,
		b.rf_gsa_indicator ,
		b.bill_fm_ln_no ,
		b.bill_fm_ln_lbl ,
		A.I_BO
		-- DETAIL INVOICE
		UNION
		select 'DTL' as ID ,
		'897' as COUNTRY
		,'00' as LCODE
		,'121' as FILEID
		,'0000' as FILESEQUENCE
		,'L' as TYPEOFLEDGERINDICATORTOLI
		,'16' as DIVISION
		,'356' as MAJOR
		,'0300' as MINOR
		,'0000' as SUBMINORMANDATORYINLEADING
		,'FED   ' as LUNIT
		,space(28) as FILLER1
		,'121' as LEDGERSOURCE
		,'TBD' as ACCOUNTANT
		,'FED    ' as INDEXNUMBERVOUCHERNUMBER
		,space(5) as FILLER2
		,REPLACE(CONVERT(VARCHAR(10), GETDATE(), 3), '/', '') as DATEOFLEDGERENTRYMANDATORY
		,month(GETDATE()) as ACCOUNTINGMONTHLOCAL
		,space(2) as FILLER3
		,case when sum(B.BILLED_AMT - B.SALES_TAX_AMT)*-1 < 0 then left(ltrim(cast(sum(B.BILLED_AMT - B.SALES_TAX_AMT)*-1 as varchar(25))),1) else '0' end + right('000000000000000' + ltrim(cast(cast((abs(sum(B.BILLED_AMT - B.SALES_TAX_AMT)*-100)) as bigint) as varchar(25))),15) as AMOUNTLOCALCURRENCY

/***
			case when sum(B.BILLED_AMT - B.SALES_TAX_AMT)*-1 < 0 
			then left(ltrim(cast(sum(B.BILLED_AMT - B.SALES_TAX_AMT)*-1 as varchar(25))),1) 
			else '0' end  
			+ right('000000000000000' + ltrim(cast(cast((abs(sum(B.BILLED_AMT - B.SALES_TAX_AMT)*-100)) as int) as varchar(25))),15) as invc , 

****/


		-- ,case when sum(B.SALES_TAX_AMT)*-1 < 0 then left(ltrim(cast(sum(B.BILLED_AMT - B.SALES_TAX_AMT) * -1)as varchar(25))),1) else '0' end  + right('000000000000000' + ltrim(cast(cast((abs(sum(B.BILLED_AMT - B.SALES_TAX_AMT)*-100)) as int) as varchar(25))),15) IS CURRENTLY


		,'000000000000000' as ZERO
		,space(7) as FILLER4
		,left(right(A.INVC_ID,7)+'           ',10) as INVOICENUMBER
		,space(2) as FILLER5
		,left('GBS Federal Bill' + '                              ',30) as DESCRIPTION
		,space(156) as FILLER6
		,'F' as INPUTTYPE
		,space(43) as FILLER7
		,left(A.I_MKG_DIV + '  ',2) as MARKETINGDIVISIONAKABUSINESS
		,space(33) as FILLER8
		,left(A.CUST_ADDR_DC + '       ',7) as CUSTOMERNUMBERSECONDARYAUDITMUSTBEADIGIT
		,space(154) as FILLER9
		,space(7) as IGSPROJECTSECONDARYAUDITMUSTBE
		,space(18) as FILLER10
		,left(A.PRIME_CONTR_ID + '               ',12) as CONTRACT
		,space(41) as FILLER11
		,left(A.I_BO + '   ',3) as BRANCHOFCOWNR
		,space(150) as FILLER17
		,left(A.C_STD_IND_CLASS + '     ',4) as INDUSTRYCLASS
		,space(14) as FILLER12
		,left(A.C_STATE + '  ',2) as STATETAX
		,left(A.C_CNTY + '     ',3) as COUNTYTAX
		,left(A.C_CITY + '     ',4) as CITYTAX
		,space(46) as FILLER13
		,left(A.C_INDUS + '     ',2) as INDUSTRY
		,space(1) as FILLER14
		,REPLACE(CONVERT(VARCHAR(10), A.INVC_DT, 1), '/', '') as INVOICEDATE
		,space(23) as FILLER15
		,left(A.I_ENTERPRISE + '         ',7) as LENTERPRISE
		,space(93) as FILLER16

		/*************************************
		 b.ri_billable_chg_cd as AX ,
		 b.m_product_code as AY ,
		 b.i_mach_type as AZ ,
		 b.tc_agrmnt as BA ,
		 b.tc_prod_catgry as BB ,
		 b.ts_dt as BC ,
		 b.tc_tax as BD ,
		 b.bill_rt_amt as BE ,
		 b.id as BF ,
		 b.name as BG ,
		 b.bill_lab_cat_cd as BH ,
		 b.bill_lab_cat_desc as BI ,
		 b.bill_fm_grp_no as BJ ,
		 b.bill_fm_grp_lbl as BK ,
		 b.rf_gsa_indicator as BL ,
		 b.bill_fm_ln_no as BM ,
		 b.bill_fm_ln_lbl as BN 
		 ****************************************/
		 
		 from IMAPSSTG.DBO.XX_IMAPS_INV_OUT_SUM a  
		 inner join IMAPSSTG.DBO.XX_IMAPS_INV_OUT_DTL b 
		   on a.INVC_ID = b.INVC_ID  
		 where A.STATUS_FL <> 'E' 
		   AND b.billed_amt <> 0  
		   and coalesce(b. acct_id,'0') not in ('48-79-08','49-79-08')  
		 group by 
		 a.INVC_ID, 
		 A.I_MKG_DIV,
		A.CUST_ADDR_DC,
		B.PROJ_ABBRV_CD,
		A.PRIME_CONTR_ID,
		A.C_STD_IND_CLASS,
		A.C_STATE,
		A.C_CNTY,
		A.C_CITY,
		A.C_INDUS,
		REPLACE(CONVERT(VARCHAR(10),A.INVC_DT,1),'/',''),
		A.I_ENTERPRISE,
		b.ri_billable_chg_cd,
		b.m_product_code,
		b.i_mach_type,
		b.tc_agrmnt,
		b.tc_prod_catgry,
		b.ts_dt,
		b.tc_tax,
		b.bill_rt_amt,
		b.id,
		b.name,
		b.bill_lab_cat_cd,
		b.bill_lab_cat_desc,
		b.bill_fm_grp_no,
		b.bill_fm_grp_lbl,
		b.rf_gsa_indicator,
		b.bill_fm_ln_no,
		b.bill_fm_ln_lbl,
		A.I_BO
	  
	  /*****   end of new glim detail query that builds the view ********/	
	  ) PARM  
	  
	  JOIN (SELECT '897' AS VA, LEFT(PARAMETER_value + '        ', 8) AS PADDED 
			FROM dbo.XX_PROCESSING_PARAMETERS WITH (NOLOCK) 
			WHERE INTERFACE_NAME_CD = 'FDS/CCS' AND PARAMETER_NAME = 'CONFRMCD') VCODE 
		ON PARM.COUNTRY = VCODE.VA 
	  group by AMOUNTLOCALCURRENCY, VCODE.PADDED)P 
GROUP BY  A, B, C, D, F, H, I, J, K, L, N



GO



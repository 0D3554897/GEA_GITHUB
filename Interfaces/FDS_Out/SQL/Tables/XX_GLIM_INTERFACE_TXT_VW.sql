USE [IMAPSStg]
GO

/****** Object:  View [dbo].[XX_GLIM_INTERFACE_TXT_VW]    Script Date: 5/11/2022 11:04:21 AM ******/
DROP VIEW [dbo].[XX_GLIM_INTERFACE_TXT_VW]
GO

/****** Object:  View [dbo].[XX_GLIM_INTERFACE_TXT_VW]    Script Date: 5/11/2022 11:04:21 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO



/* 
Used by CFF for GLIM Interface

select * from imapsstg.dbo.XX_GLIM_INTERFACE_TXT_VW

*/

CREATE VIEW [dbo].[XX_GLIM_INTERFACE_TXT_VW]
AS


SELECT  
	COUNTRY,
	LCODE,
	FILEID,
	FILESEQUENCE,
	TYPEOFLEDGERINDICATORTOLI,
	DIVISION,
	MAJOR,
	MINOR,
	SUBMINORMANDATORYINLEADING,
	LUNIT,
	PCY_IND,
	TASK,
	RVSL,
	CONDIV,
	CONMAJ,
	CONMIN,
	BK,
	LEDGERSOURCE,
	ACCOUNTANT,
	INDEXNUMBERVOUCHERNUMBER,
	VOUCHER_GRP_NBR,
	DATEOFLEDGERENTRYMANDATORY,
	ACCOUNTINGMONTHLOCAL,
	FMONTH,
	AMOUNTLOCALCURRENCY,
	ZERO,
	MTYP,
	MMOD,
	INVOICENUMBER,
	DESCRIPTION,
	DESCR1,
	LOCFLD1,
	LOCFLD2,
	LOCFLD3,
	LOCFLD4,
	LOCFLD5,
	USERID,
	FDIV,
	FMAJ,
	FMIN,
	ORIG_TOLI,
	ORIG_DIV,
	ORIG_MAJ,
	ORIG_MIN,
	ORIG_SMIN,
	ORIG_LERU,
	FRV_DATE6,
	TAI,
	HQ_CONV_ACCT,
	ITYP,
	STAT_ID,
	CHNG_ID,
	RECON_IND,
	APPR_ACCID,
	APPR_USERID,
	APPR_DATE4,
	DIR_CRNCY_IND,
	ORIG_FID,
	ORIG_FSEQ,
	ORIG_RSN,
	YTD_IND,
	CHANNEL,
	PID,
	REVAL_IND,
	BUSS_AREA_SBUSS_AREA,
	SOC,
	PART_NBR,
	EXCH_MINOR,
	XORG_IND,
	PROD_ID,
	CUSTOMERNUMBERSECONDARYAUDITMUSTBEADIGIT,
	FEATURE,
	FILLER,
	FROM_PROD_ID,
	QUANTITY,
	AREA,
	MES_NBR_RPQ,
	RECV_CTY,
	CORP_USE1,
	CORP_USE2,
	CORP_USE3_1,
	CORP_USE3_2,
	CORP_USE4_CORP_USE5,
	CORP_USE6,
	CORP_USE7,
	CORP_USE8,
	CORP_USE9_CORP_USE10,
	REV_TYPE,
	REASON,
	CONTR_TYPE,
	DOCU_TYPE,
	OFF_CODE,
	AGREE_TYPE,
	BUSS_TYPEA,
	PRINT_IND,
	EVENT_SEQ_NBR,
	EVENT_CODE,
	EVENT_TYPE,
	MATCH_CODE,
	GROUP_NBR,
	ACCT_GRP,
	ACCT_TYPE,
	ACCT_SEQ_NBR,
	SERIAL_NBR,
	PROJECT_NBR,
	DLVY_NOTE_NBR,
	ORDER_NBR,
	CONTRACT,
	SERV_PROD_ID,
	OEM_PROD_ID,
	ISIC_CODE,
	AGREE_REF_NBR,
	UNIT_OWN,
	UNIT_BIL,
	UNIT_USER,
	CUST_NBR_USER,
	CUST_NBR_BIL,
	CUST_NBR_OWNER,
	CUST_NBR_PAY,
	INV_NBR,
	TXMS_CODE,
	SHIP_DATE,
	INSTALL_DATE,
	PER_START,
	PER_END,
	ACCT_BRANCH,
	ACCT_DEPT,
	REV_BRANCH,
	COUNTRY_EXT
	FROM ( 
		/*HDR THEN TAX THEN INVC DTL*/ 
		select   
			0 as ID , 
			'897' as COUNTRY,  -- COUNTRY  START = 1  LEN = 3
			'00' as LCODE,  -- LCODE  START = 4  LEN = 2
			'121' as FILEID,  -- FILEID  START = 6  LEN = 3
			'0000' as FILESEQUENCE,  -- FILESEQUENCE  START = 9  LEN = 4
			'L' as TYPEOFLEDGERINDICATORTOLI,  -- TYPEOFLEDGERINDICATORTOLI  START = 13  LEN = 1
			'16' as DIVISION,  -- DIVISION  START = 14  LEN = 2
			'107' as MAJOR,  -- MAJOR  START = 16  LEN = 3
			'0112' as MINOR,  -- MINOR  START = 19  LEN = 4
			'0016' as SUBMINORMANDATORYINLEADING,  -- SUBMINORMANDATORYINLEADING  START = 23  LEN = 4
			'FED   ' as LUNIT ,  -- LUNIT  START = 27  LEN = 6
			SPACE(1) AS PCY_IND ,  --   START = 33  LEN = 1
			SPACE(15) AS TASK ,  --   START = 34  LEN = 15
			SPACE(1) AS RVSL ,  --   START = 49  LEN = 1
			SPACE(2) AS  CONDIV ,  --   START = 50  LEN = 2
			SPACE(3) AS CONMAJ ,  --   START = 52  LEN = 3
			SPACE(4) AS CONMIN ,  --   START = 55  LEN = 4
			SPACE(2) AS BK ,  -- FILLER1  START = 59  LEN = 2
			'121' as LEDGERSOURCE,  -- LEDGERSOURCE  START = 61  LEN = 3
			'TBD' as ACCOUNTANT,  -- ACCOUNTANT  START = 64  LEN = 3
			'FED    ' as INDEXNUMBERVOUCHERNUMBER,  -- INDEXNUMBERVOUCHERNUMBER  START = 67  LEN = 7
			SPACE(5) AS VOUCHER_GRP_NBR,  -- FILLER2  START = 74  LEN = 5
			REPLACE(CONVERT(VARCHAR(10),GETDATE(),3),'/','') as DATEOFLEDGERENTRYMANDATORY,  -- DATEOFLEDGERENTRYMANDATORY  START = 79  LEN = 6
			right('000' + cast(month(GETDATE()) as varchar),2) as ACCOUNTINGMONTHLOCAL,  -- ACCOUNTINGMONTHLOCAL  START = 85  LEN = 2
			right('000' + cast(month(GETDATE()) as varchar),2) as FMONTH,  -- FILLER3  START = 87  LEN = 2
			--IMAPSSTG.DBO.XX_NEG_OVERPUNCH_UF(case when AVG(a.INVC_AMT) - AVG(a.CSP_AMT) < 0 then left(ltrim(cast(cast(AVG(A.INVC_AMT*100) as bigint)- cast(AVG(CSP_AMT*100) as bigint) as varchar(25))),1) else '0' end  + right('000000000000000' + ltrim(cast(abs(cast(AVG(A.INVC_AMT*100) as bigint)- cast(AVG(CSP_AMT*100) as bigint)) as varchar(25))),14)) as AMOUNTLOCALCURRENCY,  -- AMOUNTLOCALCURRENCY  START = 89  LEN = 15
			-- this is the only difference between TEXT VIEW AND ALL VIEW, 1 OF 3
			 case when AVG(a.INVC_AMT) - AVG(a.CSP_AMT) < 0 then left(
			  ltrim(
				cast(
				  cast(
					AVG(A.INVC_AMT * 100) as bigint
				  )- cast(
					AVG(CSP_AMT * 100) as bigint
				  ) as varchar(25)
				)
			  ), 
			  1
			) else '0' end + right(
			  '000000000000000' + ltrim(
				cast(
				  abs(
					cast(
					  AVG(A.INVC_AMT * 100) as bigint
					)- cast(
					  AVG(CSP_AMT * 100) as bigint
					)
				  ) as varchar(25)
				)
			  ), 
			  14
			 ) as AMOUNTLOCALCURRENCY,

			'000000000000000' as ZERO,  -- ZERO  START = 104  LEN = 15
			SPACE(4) AS MTYP ,  --   START = 119  LEN = 4
			SPACE(3) AS MMOD ,  -- FILLER4  START = 123  LEN = 3
			left(right(A.INVC_ID,7)+'           ',12) as INVOICENUMBER,  -- INVOICENUMBER + 2 CHAR FILLER5 (TWO COLUMNS) COMBINED LENGTH SHOWN  START = 126  LEN = 12
			left('GBS Federal Bill' + space(30),30) as DESCRIPTION,  -- DESCRIPTION  START = 138  LEN = 30
			SPACE(30) AS DESCR1 ,  --   START = 168  LEN = 30
			SPACE(15) AS LOCFLD1 ,  --   START = 198  LEN = 15
			SPACE(15) AS LOCFLD2 ,  --   START = 213  LEN = 15
			SPACE(10) AS LOCFLD3 ,  --   START = 228  LEN = 10
			SPACE(10) AS LOCFLD4 ,  --   START = 238  LEN = 10
			SPACE(10) AS LOCFLD5 ,  --   START = 248  LEN = 10
			SPACE(8) AS USERID ,  --   START = 258  LEN = 8
			SPACE(2) AS FDIV ,  --   START = 266  LEN = 2
			SPACE(3) AS FMAJ ,  --   START = 268  LEN = 3
			SPACE(4) AS FMIN ,  --   START = 271  LEN = 4
			SPACE(1) AS ORIG_TOLI ,  --   START = 275  LEN = 1
			SPACE(2) AS ORIG_DIV ,  --   START = 276  LEN = 2
			SPACE(3) AS ORIG_MAJ ,  --   START = 278  LEN = 3
			SPACE(4) AS ORIG_MIN ,  --   START = 281  LEN = 4
			SPACE(4) AS ORIG_SMIN ,  --   START = 285  LEN = 4
			SPACE(6) AS ORIG_LERU ,  --   START = 289  LEN = 6
			SPACE(6) AS FRV_DATE6 ,  --   START = 295  LEN = 6
			SPACE(2) AS TAI ,  --   START = 301  LEN = 2
			SPACE(21) AS HQ_CONV_ACCT ,  -- FILLER6  START = 303  LEN = 21
			'F' AS ITYP ,  -- INPUTTYPE  START = 324  LEN = 1
			SPACE(1) AS STAT_ID,  --   START = 325  LEN = 1
			SPACE(1) AS CHNG_ID,  --   START = 326  LEN = 1
			SPACE(1) AS RECON_IND ,  --   START = 327  LEN = 1
			SPACE(3) AS APPR_ACCID ,  --   START = 328  LEN = 3
			SPACE(8) AS APPR_USERID ,  --   START = 331  LEN = 8
			SPACE(4) AS APPR_DATE4 ,  --   START = 339  LEN = 4
			SPACE(1) AS DIR_CRNCY_IND,  --   START = 343  LEN = 1
			SPACE(3) AS ORIG_FID ,  --   START = 344  LEN = 3
			SPACE(4) AS ORIG_FSEQ ,  --   START = 347  LEN = 4
			SPACE(4) AS ORIG_RSN ,  --   START = 351  LEN = 4
			SPACE(1) AS YTD_IND ,  --   START = 355  LEN = 1
			'6A ' AS CHANNEL ,  --   START = 356  LEN = 3
			SPACE(7) AS PID ,  --   START = 359  LEN = 7
			SPACE(2) AS REVAL_IND ,  -- FILLER7  START = 366  LEN = 2
			SPACE(4) AS BUSS_AREA_SBUSS_AREA ,  -- START = 368  LEN = 4
			SPACE(2) AS SOC,  --   START = 372  LEN = 2
			SPACE(12) AS PART_NBR ,  --   START = 374  LEN = 12
			SPACE(4) AS EXCH_MINOR ,  --   START = 386  LEN = 4
			SPACE(1) AS XORG_IND ,  --   START = 390  LEN = 1
			SPACE(12) AS PROD_ID ,  -- FILLER8A (LEN2) + FILLER8B (LEN31)  START = 391  LEN = 12
			left(A.CUST_ADDR_DC + '       ',7) as CUSTOMERNUMBERSECONDARYAUDITMUSTBEADIGIT,  -- CUSTOMERNUMBERSECONDARYAUDITMUSTBEADIGIT + 1 FROM FILLER  START = 403  LEN = 8
			SPACE(4) AS FEATURE ,  --   START = 411  LEN = 4
			SPACE(2) AS FILLER ,  --   START = 415  LEN = 2
			SPACE(12) AS FROM_PROD_ID ,  --   START = 417  LEN = 12
			SPACE(15) AS QUANTITY ,  --   START = 429  LEN = 15
			SPACE(2) AS AREA ,  --   START = 444  LEN = 2
			SPACE(12) AS MES_NBR_RPQ ,  --   START = 446  LEN = 12
			SPACE(3) AS RECV_CTY ,  --   START = 458  LEN = 3
			SPACE(2) AS CORP_USE1 ,  --   START = 461  LEN = 2
			SPACE(3) AS CORP_USE2 ,  --   START = 463  LEN = 3
			SPACE(1) AS CORP_USE3_1,  --   START = 466  LEN = 1
			SPACE(2) AS CORP_USE3_2,  --   START = 467  LEN = 2
			SPACE(9) AS CORP_USE4_CORP_USE5 ,  --   START = 469  LEN = 9
			SPACE(6) AS CORP_USE6 ,  --   START = 478  LEN = 6
			SPACE(7) AS CORP_USE7 ,  --   START = 484  LEN = 7 BLANK FOR HEADER
			SPACE(8) AS CORP_USE8 ,  --   START = 491  LEN = 8
			SPACE(19) AS CORP_USE9_CORP_USE10,  --   START = 499  LEN = 19"
			SPACE(3) AS REV_TYPE ,  --   START = 518  LEN = 3
			SPACE(3) AS REASON ,  --   START = 521  LEN = 3
			COALESCE(IMAPSSTG.DBO.XX_GET_CONTRACT_TYPE_CD_UF(A.PROJ_ID),SPACE(2)) AS CONTR_TYPE ,  --   START = 524  LEN = 2
			SPACE(2) AS DOCU_TYPE ,  --   START = 526  LEN = 2
			SPACE(3) AS OFF_CODE ,  --   START = 528  LEN = 3
			SPACE(1) AS AGREE_TYPE ,  --   START = 531  LEN = 1
			SPACE(1) AS BUSS_TYPEA,  --   START = 532  LEN = 1
			SPACE(1) AS PRINT_IND ,  --   START = 533  LEN = 1
			SPACE(4) AS EVENT_SEQ_NBR ,  --   START = 534  LEN = 4
			SPACE(3) AS EVENT_CODE ,  --   START = 538  LEN = 3
			SPACE(1) AS EVENT_TYPE ,  --   START = 541  LEN = 1
			SPACE(3) AS MATCH_CODE ,  --   START = 542  LEN = 3
			SPACE(4) AS GROUP_NBR ,  --   START = 545  LEN = 4
			SPACE(3) AS ACCT_GRP ,  --   START = 549  LEN = 3
			SPACE(1) AS ACCT_TYPE ,  --   START = 552  LEN = 1
			SPACE(2) AS ACCT_SEQ_NBR ,  --   START = 553  LEN = 2
			SPACE(9) AS SERIAL_NBR ,  --   START = 555  LEN = 9
			SPACE(7) AS PROJECT_NBR ,  --  START = 564  LEN = 7 BLANK FOR HEADER
			SPACE(12) AS DLVY_NOTE_NBR ,  --   START = 571  LEN = 12
			SPACE(6) AS ORDER_NBR ,  -- FILLER10  START = 583  LEN = 6
			left(A.PRIME_CONTR_ID + '                              ',15) as CONTRACT,  -- START = 589  LEN = 15
			SPACE(12) AS SERV_PROD_ID ,  --   START = 604  LEN = 12
			left(right(A.INVC_ID,12)+'                ',12) as OEM_PROD_ID,  --   START = 616  LEN = 12
			SPACE(5) AS ISIC_CODE ,  --   START = 628  LEN = 5
			SPACE(9) AS AGREE_REF_NBR ,  --START = 633  LEN = 9
			COALESCE(IMAPSSTG.DBO.XX_GET_COST_TYPE_CD_UF(ACCT_ID),SPACE(3)) AS UNIT_OWN,  -- BRANCHOFCOWNR  START = 642  LEN = 3
			SPACE(3) AS UNIT_BIL ,  --   START = 645  LEN = 3
			SPACE(3) AS UNIT_USER ,  --   START = 648  LEN = 3
			SPACE(8) AS CUST_NBR_USER,  --   START = 651  LEN = 8
			left(A.CUST_ADDR_DC + '       ',8) AS CUST_NBR_BIL ,  --   START = 659  LEN = 8
			SPACE(8) AS CUST_NBR_OWNER ,  --   START = 667  LEN = 8
			SPACE(8) AS CUST_NBR_PAY ,  --   START = 675  LEN = 8
			left(right(A.INVC_ID,7)+'                ',7) as INV_NBR,  --   START = 683  LEN = 7
			SPACE(10) AS TXMS_CODE ,  --   START = 690  LEN = 10
			SPACE(10) AS SHIP_DATE ,  --   START = 700  LEN = 10
			SPACE(10) AS INSTALL_DATE ,  --   START = 710  LEN = 10
			SPACE(10) AS PER_START ,  --   START = 720  LEN = 10
			SPACE(10) AS PER_END ,  --   START = 730  LEN = 10
			SPACE(3) AS ACCT_BRANCH ,  --   START = 740  LEN = 3
			SPACE(4) AS ACCT_DEPT ,  --   START = 743  LEN = 4
			SPACE(3) AS REV_BRANCH ,  --   START = 747  LEN = 3
			SPACE(250) AS COUNTRY_EXT   -- FILLER17  START = 750  LEN = 250
		from IMAPSSTG.DBO.XX_IMAPS_INV_OUT_SUM a
			inner join IMAPSSTG.DBO.XX_IMAPS_INV_OUT_DTL b 
			on a.INVC_ID = b.INVC_ID    
		where (a.invc_amt - A.CSP_AMT) <> 0 
			AND A.STATUS_FL <> 'E'   
			and (coalesce(b.acct_id,'0') not in (SELECT PARAMETER_VALUE FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS WHERE PARAMETER_NAME = 'CSP_ACCT_ID'))   
		GROUP BY  A.INVC_ID,
			A.PROJ_ID,
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
			A.I_BO ,
			B.ACCT_ID
		UNION  
		/*TAX*/ 
		select  
			b.INVC_LN,
			'897' as COUNTRY,  -- COUNTRY  START = 1  LEN = 3
			'00' as LCODE,  -- LCODE  START = 4  LEN = 2
			'121' as FILEID,  -- FILEID  START = 6  LEN = 3
			'0000' as FILESEQUENCE,  -- FILESEQUENCE  START = 9  LEN = 4
			'L' as TYPEOFLEDGERINDICATORTOLI,  -- TYPEOFLEDGERINDICATORTOLI  START = 13  LEN = 1
			'12' as DIVISION,  -- DIVISION  START = 14  LEN = 2
			'202' as MAJOR,  -- MAJOR  START = 16  LEN = 3
			'0112' as MINOR,  -- MINOR  START = 19  LEN = 4
			'0080' as SUBMINORMANDATORYINLEADING,  -- SUBMINORMANDATORYINLEADING  START = 23  LEN = 4
			'FED   ' as LUNIT ,  -- LUNIT  START = 27  LEN = 6
			SPACE(1) AS PCY_IND ,  --   START = 33  LEN = 1
			SPACE(15) AS TASK ,  --   START = 34  LEN = 15
			SPACE(1) AS RVSL ,  --   START = 49  LEN = 1
			SPACE(2) AS  CONDIV ,  --   START = 50  LEN = 2
			SPACE(3) AS CONMAJ ,  --   START = 52  LEN = 3
			SPACE(4) AS CONMIN ,  --   START = 55  LEN = 4
			SPACE(2) AS BK ,  -- FILLER1  START = 59  LEN = 2
			'121' as LEDGERSOURCE,  -- LEDGERSOURCE  START = 61  LEN = 3
			'TBD' as ACCOUNTANT,  -- ACCOUNTANT  START = 64  LEN = 3
			'FED    ' as INDEXNUMBERVOUCHERNUMBER,  -- INDEXNUMBERVOUCHERNUMBER  START = 67  LEN = 7
			SPACE(5) AS VOUCHER_GRP_NBR,  -- FILLER2  START = 74  LEN = 5
			REPLACE(CONVERT(VARCHAR(10),GETDATE(),3),'/','') as DATEOFLEDGERENTRYMANDATORY,  -- DATEOFLEDGERENTRYMANDATORY  START = 79  LEN = 6
			right('000' + cast(month(GETDATE()) as varchar),2) as ACCOUNTINGMONTHLOCAL,  -- ACCOUNTINGMONTHLOCAL  START = 85  LEN = 2
			right('000' + cast(month(GETDATE()) as varchar),2) as FMONTH,  -- FILLER3  START = 87  LEN = 2
			--IMAPSSTG.DBO.XX_NEG_OVERPUNCH_UF(case when AVG(a.INVC_AMT) - AVG(a.CSP_AMT) < 0 then left(ltrim(cast(cast(AVG(A.INVC_AMT*100) as bigint)- cast(AVG(CSP_AMT*100) as bigint) as varchar(25))),1) else '0' end  + right('000000000000000' + ltrim(cast(abs(cast(AVG(A.INVC_AMT*100) as bigint)- cast(AVG(CSP_AMT*100) as bigint)) as varchar(25))),14)) as AMOUNTLOCALCURRENCY,  -- AMOUNTLOCALCURRENCY  START = 89  LEN = 15
			-- DIFFERENCE BETWEEN TEXT VIEW AND ALL VIEW, 2 OF 3
			     case when sum(B.SALES_TAX_AMT)*-1 < 0 then left(
          ltrim(
            cast(
              sum(B.SALES_TAX_AMT)*-1 as varchar(25)
            )
          ), 
          1
        ) else '0' end + right(
          '000000000000000' + ltrim(
            cast(
              cast(
                (
                  abs(
                    sum(B.SALES_TAX_AMT)*-100
                  )
                ) as int
              ) as varchar(25)
            )
          ), 
          14
      ) as AMOUNTLOCALCURRENCY, 

			'000000000000000' as ZERO,  -- ZERO  START = 104  LEN = 15
			SPACE(4) AS MTYP ,  --   START = 119  LEN = 4
			SPACE(3) AS MMOD ,  -- FILLER4  START = 123  LEN = 3
			left(right(A.INVC_ID,7)+'           ',12) as INVOICENUMBER,  -- INVOICENUMBER + 2 CHAR FILLER5 (TWO COLUMNS) COMBINED LENGTH SHOWN  START = 126  LEN = 12
			left('GBS Federal Bill' + space(30),30) as DESCRIPTION,  -- DESCRIPTION  START = 138  LEN = 30
			SPACE(30) AS DESCR1 ,  --   START = 168  LEN = 30
			SPACE(15) AS LOCFLD1 ,  --   START = 198  LEN = 15
			SPACE(15) AS LOCFLD2 ,  --   START = 213  LEN = 15
			SPACE(10) AS LOCFLD3 ,  --   START = 228  LEN = 10
			SPACE(10) AS LOCFLD4 ,  --   START = 238  LEN = 10
			SPACE(10) AS LOCFLD5 ,  --   START = 248  LEN = 10
			SPACE(8) AS USERID ,  --   START = 258  LEN = 8
			SPACE(2) AS FDIV ,  --   START = 266  LEN = 2
			SPACE(3) AS FMAJ ,  --   START = 268  LEN = 3
			SPACE(4) AS FMIN ,  --   START = 271  LEN = 4
			SPACE(1) AS ORIG_TOLI ,  --   START = 275  LEN = 1
			SPACE(2) AS ORIG_DIV ,  --   START = 276  LEN = 2
			SPACE(3) AS ORIG_MAJ ,  --   START = 278  LEN = 3
			SPACE(4) AS ORIG_MIN ,  --   START = 281  LEN = 4
			SPACE(4) AS ORIG_SMIN ,  --   START = 285  LEN = 4
			SPACE(6) AS ORIG_LERU ,  --   START = 289  LEN = 6
			SPACE(6) AS FRV_DATE6 ,  --   START = 295  LEN = 6
			SPACE(2) AS TAI ,  --   START = 301  LEN = 2
			SPACE(21) AS HQ_CONV_ACCT ,  -- FILLER6  START = 303  LEN = 21
			SPACE(1) AS ITYP ,  -- INPUTTYPE  START = 324  LEN = 1
			'F' as INPUTTYPE,  --   START = 325  LEN = 1
			SPACE(1) AS CHNG_ID,  --   START = 326  LEN = 1
			SPACE(1) AS RECON_IND ,  --   START = 327  LEN = 1
			SPACE(3) AS APPR_ACCID ,  --   START = 328  LEN = 3
			SPACE(8) AS APPR_USERID ,  --   START = 331  LEN = 8
			SPACE(4) AS APPR_DATE4 ,  --   START = 339  LEN = 4
			SPACE(1) AS DIR_CRNCY_IND,  --   START = 343  LEN = 1
			SPACE(3) AS ORIG_FID ,  --   START = 344  LEN = 3
			SPACE(4) AS ORIG_FSEQ ,  --   START = 347  LEN = 4
			SPACE(4) AS ORIG_RSN ,  --   START = 351  LEN = 4
			SPACE(1) AS YTD_IND ,  --   START = 355  LEN = 1
			'6A ' AS CHANNEL ,  --   START = 356  LEN = 3
			SPACE(7) AS PID ,  --   START = 359  LEN = 7
			SPACE(2) AS REVAL_IND ,  -- FILLER7  START = 366  LEN = 2
			SPACE(4) AS BUSS_AREA_SBUSS_AREA ,  -- START = 368  LEN = 4
			SPACE(2) AS SOC,  --   START = 372  LEN = 2
			SPACE(12) AS PART_NBR ,  --   START = 374  LEN = 12
			SPACE(4) AS EXCH_MINOR ,  --   START = 386  LEN = 4
			SPACE(1) AS XORG_IND ,  --   START = 390  LEN = 1
			SPACE(12) AS PROD_ID ,  -- FILLER8A (LEN2) + FILLER8B (LEN31)  START = 391  LEN = 12
			left(A.CUST_ADDR_DC + '       ',7) as CUSTOMERNUMBERSECONDARYAUDITMUSTBEADIGIT,  -- CUSTOMERNUMBERSECONDARYAUDITMUSTBEADIGIT + 1 FROM FILLER  START = 403  LEN = 8
			SPACE(4) AS FEATURE ,  --   START = 411  LEN = 4
			SPACE(2) AS FILLER ,  --   START = 415  LEN = 2
			SPACE(12) AS FROM_PROD_ID ,  --   START = 417  LEN = 12
			SPACE(15) AS QUANTITY ,  --   START = 429  LEN = 15
			SPACE(2) AS AREA ,  --   START = 444  LEN = 2
			SPACE(12) AS MES_NBR_RPQ ,  --   START = 446  LEN = 12
			SPACE(3) AS RECV_CTY ,  --   START = 458  LEN = 3
			SPACE(2) AS CORP_USE1 ,  --   START = 461  LEN = 2
			SPACE(3) AS CORP_USE2 ,  --   START = 463  LEN = 3
			SPACE(1) AS CORP_USE3_1,  --   START = 466  LEN = 1
			SPACE(2) AS CORP_USE3_2,  --   START = 467  LEN = 2
			SPACE(9) AS CORP_USE4_CORP_USE5 ,  --   START = 469  LEN = 9
			SPACE(6) AS CORP_USE6 ,  --   START = 478  LEN = 6
			SPACE(7) AS CORP_USE7 ,  --   START = 484  LEN = 7 BLANK FOR TAX
			SPACE(8) AS CORP_USE8 ,  --   START = 491  LEN = 8
			SPACE(19) AS CORP_USE9_CORP_USE10,  --   START = 499  LEN = 19"
			SPACE(3) AS REV_TYPE ,  --   START = 518  LEN = 3
			SPACE(3) AS REASON ,  --   START = 521  LEN = 3
			COALESCE(IMAPSSTG.DBO.XX_GET_CONTRACT_TYPE_CD_UF(A.PROJ_ID),SPACE(2)) AS CONTR_TYPE ,  --   START = 524  LEN = 2
			SPACE(2) AS DOCU_TYPE ,  --   START = 526  LEN = 2
			SPACE(3) AS OFF_CODE ,  --   START = 528  LEN = 3
			SPACE(1) AS AGREE_TYPE ,  --   START = 531  LEN = 1
			SPACE(1) AS BUSS_TYPEA,  --   START = 532  LEN = 1
			SPACE(1) AS PRINT_IND ,  --   START = 533  LEN = 1
			SPACE(4) AS EVENT_SEQ_NBR ,  --   START = 534  LEN = 4
			SPACE(3) AS EVENT_CODE ,  --   START = 538  LEN = 3
			SPACE(1) AS EVENT_TYPE ,  --   START = 541  LEN = 1
			SPACE(3) AS MATCH_CODE ,  --   START = 542  LEN = 3
			SPACE(4) AS GROUP_NBR ,  --   START = 545  LEN = 4
			SPACE(3) AS ACCT_GRP ,  --   START = 549  LEN = 3
			SPACE(1) AS ACCT_TYPE ,  --   START = 552  LEN = 1
			SPACE(2) AS ACCT_SEQ_NBR ,  --   START = 553  LEN = 2
			SPACE(9) AS SERIAL_NBR ,  --   START = 555  LEN = 9
			SPACE(7) AS PROJECT_NBR ,  --  START = 564  LEN = 7 BLANK FOR TAX
			SPACE(12) AS DLVY_NOTE_NBR ,  --   START = 571  LEN = 12
			SPACE(6) AS ORDER_NBR ,  -- FILLER10  START = 583  LEN = 6
			--left(A.PRIME_CONTR_ID + '                              ',15) as CONTRACT,  -- START = 589  LEN = 15
			SPACE(15) AS CONTRACT, -- START = 589  LEN = 15                                                          BLANK FOR TAX?
			SPACE(12) AS SERV_PROD_ID ,  --   START = 604  LEN = 12
			left(right(A.INVC_ID,12)+'                ',12) as OEM_PROD_ID,  --   START = 616  LEN = 12
			SPACE(5) AS ISIC_CODE ,  --   START = 628  LEN = 5
			SPACE(9) AS AGREE_REF_NBR ,  --START = 633  LEN = 9
			COALESCE(IMAPSSTG.DBO.XX_GET_COST_TYPE_CD_UF(ACCT_ID),SPACE(3)) AS UNIT_OWN,  -- BRANCHOFCOWNR  START = 642  LEN = 3
			SPACE(3) AS UNIT_BIL ,  --   START = 645  LEN = 3
			SPACE(3) AS UNIT_USER ,  --   START = 648  LEN = 3
			SPACE(8) AS CUST_NBR_USER,  --   START = 651  LEN = 8
			left(A.CUST_ADDR_DC + '       ',8) AS CUST_NBR_BIL ,  --   START = 659  LEN = 8
			SPACE(8) AS CUST_NBR_OWNER ,  --   START = 667  LEN = 8
			SPACE(8) AS CUST_NBR_PAY ,  --   START = 675  LEN = 8
			left(right(A.INVC_ID,7)+'                ',7) as INV_NBR,  --   START = 683  LEN = 7
			SPACE(10) AS TXMS_CODE ,  --   START = 690  LEN = 10
			SPACE(10) AS SHIP_DATE ,  --   START = 700  LEN = 10
			SPACE(10) AS INSTALL_DATE ,  --   START = 710  LEN = 10
			SPACE(10) AS PER_START ,  --   START = 720  LEN = 10
			SPACE(10) AS PER_END ,  --   START = 730  LEN = 10
			SPACE(3) AS ACCT_BRANCH ,  --   START = 740  LEN = 3
			SPACE(4) AS ACCT_DEPT ,  --   START = 743  LEN = 4
			SPACE(3) AS REV_BRANCH ,  --   START = 747  LEN = 3
			SPACE(250) AS COUNTRY_EXT   -- FILLER17  START = 750  LEN = 250
		from IMAPSSTG.DBO.XX_IMAPS_INV_OUT_SUM a   
			inner join IMAPSSTG.DBO.XX_IMAPS_INV_OUT_DTL b    
			on a.INVC_ID = b.INVC_ID   
		where A.STATUS_FL <> 'E'    
			AND b.sales_tax_amt <> 0     
			/*and coalesce(b.acct_id,'0') not in ('48-79-08','49-79-08')*/   
			and (coalesce(b.acct_id,'0') not in (SELECT PARAMETER_VALUE FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS WHERE PARAMETER_NAME = 'CSP_ACCT_ID')) 
		group by a.INVC_ID ,
			A.PROJ_ID,
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
			A.I_BO,
			B.INVC_LN ,
			B.ACCT_ID  
		UNION 
		/*DETAIL INVOICE*/ 
		select  
		/*'DTL' as ID ,*/ 
			B.INVC_LN,
			'897' as COUNTRY,  -- COUNTRY  START = 1  LEN = 3
			'00' as LCODE,  -- LCODE  START = 4  LEN = 2
			'121' as FILEID,  -- FILEID  START = 6  LEN = 3
			'0000' as FILESEQUENCE,  -- FILESEQUENCE  START = 9  LEN = 4
			'L' as TYPEOFLEDGERINDICATORTOLI,  -- TYPEOFLEDGERINDICATORTOLI  START = 13  LEN = 1
			'16' as DIVISION,  -- DIVISION  START = 14  LEN = 2
			'356' as MAJOR,  -- MAJOR  START = 16  LEN = 3
			'0300' as MINOR,  -- MINOR  START = 19  LEN = 4
			'0000' as SUBMINORMANDATORYINLEADING,  -- SUBMINORMANDATORYINLEADING  START = 23  LEN = 4
			'FED   ' as LUNIT ,  -- LUNIT  START = 27  LEN = 6
			SPACE(1) AS PCY_IND ,  --   START = 33  LEN = 1
			SPACE(15) AS TASK ,  --   START = 34  LEN = 15
			SPACE(1) AS RVSL ,  --   START = 49  LEN = 1
			SPACE(2) AS  CONDIV ,  --   START = 50  LEN = 2
			SPACE(3) AS CONMAJ ,  --   START = 52  LEN = 3
			SPACE(4) AS CONMIN ,  --   START = 55  LEN = 4
			SPACE(2) AS BK ,  -- FILLER1  START = 59  LEN = 2
			'121' as LEDGERSOURCE,  -- LEDGERSOURCE  START = 61  LEN = 3
			'TBD' as ACCOUNTANT,  -- ACCOUNTANT  START = 64  LEN = 3
			'FED    ' as INDEXNUMBERVOUCHERNUMBER,  -- INDEXNUMBERVOUCHERNUMBER  START = 67  LEN = 7
			SPACE(5) AS VOUCHER_GRP_NBR,  -- FILLER2  START = 74  LEN = 5
			REPLACE(CONVERT(VARCHAR(10),GETDATE(),3),'/','') as DATEOFLEDGERENTRYMANDATORY,  -- DATEOFLEDGERENTRYMANDATORY  START = 79  LEN = 6
			right('000' + cast(month(GETDATE()) as varchar),2) as ACCOUNTINGMONTHLOCAL,  -- ACCOUNTINGMONTHLOCAL  START = 85  LEN = 2
			right('000' + cast(month(GETDATE()) as varchar),2) as FMONTH,  -- FILLER3  START = 87  LEN = 2
			---IMAPSSTG.DBO.XX_NEG_OVERPUNCH_UF(case when AVG(a.INVC_AMT) - AVG(a.CSP_AMT) < 0 then left(ltrim(cast(cast(AVG(A.INVC_AMT*100) as bigint)- cast(AVG(CSP_AMT*100) as bigint) as varchar(25))),1) else '0' end  + right('000000000000000' + ltrim(cast(abs(cast(AVG(A.INVC_AMT*100) as bigint)- cast(AVG(CSP_AMT*100) as bigint)) as varchar(25))),14)) as AMOUNTLOCALCURRENCY,  -- AMOUNTLOCALCURRENCY  START = 89  LEN = 15
			-- DIFFERENCE BETWEEN TEXT VIEW AND ALL VIEW, 3 OF 3
			     case when sum(B.BILLED_AMT - B.SALES_TAX_AMT)*-1 < 0 then left(
          ltrim(
            cast(
              sum(B.BILLED_AMT - B.SALES_TAX_AMT)*-1 as varchar(25)
            )
          ), 
          1
        ) else '0' end + right(
          '000000000000000' + ltrim(
            cast(
              cast(
                (
                  abs(
                    sum(B.BILLED_AMT - B.SALES_TAX_AMT)*-100
                  )
                ) as int
              ) as varchar(25)
            )
          ), 
          14
      ) as AMOUNTLOCALCURRENCY, 

			'000000000000000' as ZERO,  -- ZERO  START = 104  LEN = 15
			SPACE(4) AS MTYP ,  --   START = 119  LEN = 4
			SPACE(3) AS MMOD ,  -- FILLER4  START = 123  LEN = 3
			left(right(A.INVC_ID,7)+'           ',12) as INVOICENUMBER,  -- INVOICENUMBER + 2 CHAR FILLER5 (TWO COLUMNS) COMBINED LENGTH SHOWN  START = 126  LEN = 12
			left('GBS Federal Bill' + space(30),30) as DESCRIPTION,  -- DESCRIPTION  START = 138  LEN = 30
			SPACE(30) AS DESCR1 ,  --   START = 168  LEN = 30
			SPACE(15) AS LOCFLD1 ,  --   START = 198  LEN = 15
			SPACE(15) AS LOCFLD2 ,  --   START = 213  LEN = 15
			SPACE(10) AS LOCFLD3 ,  --   START = 228  LEN = 10
			SPACE(10) AS LOCFLD4 ,  --   START = 238  LEN = 10
			SPACE(10) AS LOCFLD5 ,  --   START = 248  LEN = 10
			SPACE(8) AS USERID ,  --   START = 258  LEN = 8
			SPACE(2) AS FDIV ,  --   START = 266  LEN = 2
			SPACE(3) AS FMAJ ,  --   START = 268  LEN = 3
			SPACE(4) AS FMIN ,  --   START = 271  LEN = 4
			SPACE(1) AS ORIG_TOLI ,  --   START = 275  LEN = 1
			SPACE(2) AS ORIG_DIV ,  --   START = 276  LEN = 2
			SPACE(3) AS ORIG_MAJ ,  --   START = 278  LEN = 3
			SPACE(4) AS ORIG_MIN ,  --   START = 281  LEN = 4
			SPACE(4) AS ORIG_SMIN ,  --   START = 285  LEN = 4
			SPACE(6) AS ORIG_LERU ,  --   START = 289  LEN = 6
			SPACE(6) AS FRV_DATE6 ,  --   START = 295  LEN = 6
			SPACE(2) AS TAI ,  --   START = 301  LEN = 2
			SPACE(21) AS HQ_CONV_ACCT ,  -- FILLER6  START = 303  LEN = 21
			SPACE(1) AS ITYP ,  -- INPUTTYPE  START = 324  LEN = 1
			'F' as INPUTTYPE,  --   START = 325  LEN = 1
			SPACE(1) AS CHNG_ID,  --   START = 326  LEN = 1
			SPACE(1) AS RECON_IND ,  --   START = 327  LEN = 1
			SPACE(3) AS APPR_ACCID ,  --   START = 328  LEN = 3
			SPACE(8) AS APPR_USERID ,  --   START = 331  LEN = 8
			SPACE(4) AS APPR_DATE4 ,  --   START = 339  LEN = 4
			SPACE(1) AS DIR_CRNCY_IND,  --   START = 343  LEN = 1
			SPACE(3) AS ORIG_FID ,  --   START = 344  LEN = 3
			SPACE(4) AS ORIG_FSEQ ,  --   START = 347  LEN = 4
			SPACE(4) AS ORIG_RSN ,  --   START = 351  LEN = 4
			SPACE(1) AS YTD_IND ,  --   START = 355  LEN = 1
			'6A ' AS CHANNEL ,  --   START = 356  LEN = 3
			SPACE(7) AS PID ,  --   START = 359  LEN = 7
			SPACE(2) AS REVAL_IND ,  -- FILLER7  START = 366  LEN = 2
			SPACE(4) AS BUSS_AREA_SBUSS_AREA ,  -- START = 368  LEN = 4
			SPACE(2) AS SOC,  --   START = 372  LEN = 2
			SPACE(12) AS PART_NBR ,  --   START = 374  LEN = 12
			SPACE(4) AS EXCH_MINOR ,  --   START = 386  LEN = 4
			SPACE(1) AS XORG_IND ,  --   START = 390  LEN = 1
			SPACE(12) AS PROD_ID ,  -- FILLER8A (LEN2) + FILLER8B (LEN31)  START = 391  LEN = 12
			left(A.CUST_ADDR_DC + '       ',7) as CUSTOMERNUMBERSECONDARYAUDITMUSTBEADIGIT,  -- CUSTOMERNUMBERSECONDARYAUDITMUSTBEADIGIT + 1 FROM FILLER  START = 403  LEN = 8
			SPACE(4) AS FEATURE ,  --   START = 411  LEN = 4
			SPACE(2) AS FILLER ,  --   START = 415  LEN = 2
			SPACE(12) AS FROM_PROD_ID ,  --   START = 417  LEN = 12
			SPACE(15) AS QUANTITY ,  --   START = 429  LEN = 15
			SPACE(2) AS AREA ,  --   START = 444  LEN = 2
			SPACE(12) AS MES_NBR_RPQ ,  --   START = 446  LEN = 12
			SPACE(3) AS RECV_CTY ,  --   START = 458  LEN = 3
			SPACE(2) AS CORP_USE1 ,  --   START = 461  LEN = 2
			SPACE(3) AS CORP_USE2 ,  --   START = 463  LEN = 3
			SPACE(1) AS CORP_USE3_1,  --   START = 466  LEN = 1
			SPACE(2) AS CORP_USE3_2,  --   START = 467  LEN = 2
			SPACE(9) AS CORP_USE4_CORP_USE5 ,  --   START = 469  LEN = 9
			SPACE(6) AS CORP_USE6 ,  --   START = 478  LEN = 6
			COALESCE(LEFT(B.PROJ_ABBRV_CD + SPACE(7),7),SPACE(7)) AS CORP_USE7 ,  -- PACT NUMBER  START = 484  LEN = 7  MIMICS PROJECT FOR LINES
			SPACE(8) AS CORP_USE8 ,  --   START = 491  LEN = 8
			SPACE(19) AS CORP_USE9_CORP_USE10,  --   START = 499  LEN = 19"
			SPACE(3) AS REV_TYPE ,  --   START = 518  LEN = 3
			SPACE(3) AS REASON ,  --   START = 521  LEN = 3
			COALESCE(IMAPSSTG.DBO.XX_GET_CONTRACT_TYPE_CD_UF(A.PROJ_ID),SPACE(2)) AS CONTR_TYPE ,  --   START = 524  LEN = 2
			SPACE(2) AS DOCU_TYPE ,  --   START = 526  LEN = 2
			SPACE(3) AS OFF_CODE ,  --   START = 528  LEN = 3
			SPACE(1) AS AGREE_TYPE ,  --   START = 531  LEN = 1
			SPACE(1) AS BUSS_TYPEA,  --   START = 532  LEN = 1
			SPACE(1) AS PRINT_IND ,  --   START = 533  LEN = 1
			SPACE(4) AS EVENT_SEQ_NBR ,  --   START = 534  LEN = 4
			SPACE(3) AS EVENT_CODE ,  --   START = 538  LEN = 3
			SPACE(1) AS EVENT_TYPE ,  --   START = 541  LEN = 1
			SPACE(3) AS MATCH_CODE ,  --   START = 542  LEN = 3
			SPACE(4) AS GROUP_NBR ,  --   START = 545  LEN = 4
			SPACE(3) AS ACCT_GRP ,  --   START = 549  LEN = 3
			SPACE(1) AS ACCT_TYPE ,  --   START = 552  LEN = 1
			SPACE(2) AS ACCT_SEQ_NBR ,  --   START = 553  LEN = 2
			SPACE(9) AS SERIAL_NBR ,  --   START = 555  LEN = 9
			COALESCE(LEFT(B.PROJ_ABBRV_CD + SPACE(7),7),SPACE(7)) AS PROJECT_NBR ,  --  START = 564  LEN = 7 
			SPACE(12) AS DLVY_NOTE_NBR ,  --   START = 571  LEN = 12
			SPACE(6) AS ORDER_NBR ,  -- FILLER10  START = 583  LEN = 6
			left(A.PRIME_CONTR_ID + '                              ',15) as CONTRACT,  -- START = 589  LEN = 15
			SPACE(12) AS SERV_PROD_ID ,  --   START = 604  LEN = 12
			left(right(A.INVC_ID,12)+'                ',12) as OEM_PROD_ID,  --   START = 616  LEN = 12
			SPACE(5) AS ISIC_CODE ,  --   START = 628  LEN = 5
			SPACE(9) AS AGREE_REF_NBR ,  --START = 633  LEN = 9
			COALESCE(IMAPSSTG.DBO.XX_GET_COST_TYPE_CD_UF(ACCT_ID),SPACE(3)) AS UNIT_OWN,  -- START = 642  LEN = 3
			SPACE(3) AS UNIT_BIL ,  --   START = 645  LEN = 3
			SPACE(3) AS UNIT_USER ,  --   START = 648  LEN = 3
			SPACE(8) AS CUST_NBR_USER,  --   START = 651  LEN = 8
			left(A.CUST_ADDR_DC + '       ',8) AS CUST_NBR_BIL ,  --   START = 659  LEN = 8
			SPACE(8) AS CUST_NBR_OWNER ,  --   START = 667  LEN = 8
			SPACE(8) AS CUST_NBR_PAY ,  --   START = 675  LEN = 8
			left(right(A.INVC_ID,7)+'                ',7) as INV_NBR,  --   START = 683  LEN = 7
			SPACE(10) AS TXMS_CODE ,  --   START = 690  LEN = 10
			SPACE(10) AS SHIP_DATE ,  --   START = 700  LEN = 10
			SPACE(10) AS INSTALL_DATE ,  --   START = 710  LEN = 10
			SPACE(10) AS PER_START ,  --   START = 720  LEN = 10
			SPACE(10) AS PER_END ,  --   START = 730  LEN = 10
			SPACE(3) AS ACCT_BRANCH ,  --   START = 740  LEN = 3
			SPACE(4) AS ACCT_DEPT ,  --   START = 743  LEN = 4
			SPACE(3) AS REV_BRANCH ,  --   START = 747  LEN = 3
			SPACE(250) AS COUNTRY_EXT   -- FILLER17  START = 750  LEN = 250
		from IMAPSSTG.DBO.XX_IMAPS_INV_OUT_SUM a    
			inner join IMAPSSTG.DBO.XX_IMAPS_INV_OUT_DTL b     
			on a.INVC_ID = b.INVC_ID    
		where A.STATUS_FL <> 'E'     
			AND b.billed_amt <> 0       
			and (coalesce(b.acct_id,'0') not in (SELECT PARAMETER_VALUE FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS WHERE PARAMETER_NAME = 'CSP_ACCT_ID'))  
		group by   
			a.INVC_ID,
			A.PROJ_ID,
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
			A.I_BO,
			B.INVC_LN ,
			B.ACCT_ID
		)GLIMVIEW  
			




GO



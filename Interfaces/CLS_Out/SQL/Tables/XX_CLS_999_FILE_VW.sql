USE [IMAPSStg]
GO

/****** Object:  View [dbo].[XX_CLS_999_FILE_VW]    Script Date: 5/11/2022 11:36:17 AM ******/
DROP VIEW [dbo].[XX_CLS_999_FILE_VW]
GO

/****** Object:  View [dbo].[XX_CLS_999_FILE_VW]    Script Date: 5/11/2022 11:36:17 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


/* 
Used by CFF for CLS Interface

usage: select * from imapsstg.dbo.XX_CLS_999_FILE_VW

Three special numeric formats in CLSDOWN FILE:


1) Signed Binary Integer
   Requires the following formatting:
   starts with ~, then one digit (usually a zero) for each position in the hex digit.  
   example: HEX 00 = '~00'   HEX F0 F0 F0 F0 = '~00000000'
   
2) overpunch
  All formatting can be done in query.  Uses a function (imapsstg.dbo.xx_full_overpunch_uf) to:
  a) remove decimal and sign
  b) substitute non-digit character for last digit, character indicates sign
  c) left pad with zeroes to specified length
  example: 
    decimal(13,2)
    right('000000000000000' + rtrim(ltrim(replace(imapsstg.dbo.xx_full_overpunch_uf(DOLLAR_AMT),'.',''))),13) 
    
3) packed decimal
  Packed decimal encodes the number into the bytes of the field.  For example, +1234.56
  would be a field that consists of 4 bytes, HEX values: 01 23 45 6D
  where D means positive and C means negative.
  Typically, the number is zero padded to left with some number of zeroes for consistent field length
  This transformation is currently made in java, so we format the number here to make it easy to convert in java 
    
  Len of field to be sent to packed decimal should be equal to first digit.  
  For example, '00000000000' (LEN=11) would be sent to a DEC(11,2) packed decimal field
  In our query, the number 12345.67 should be converted to 00001234567 for a total length of 11
  A negative number would appear as -0001234567, again, total length of 11

  To convert a column, use the general form:

  packed decimal specification: DEC(X,Y)  (LENGTH, PRECISION)
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(X,0),((COLUMN_NAME) * 100)) as varchar),X)
  
  this formatting is enough for zeroes and positive numbers.  

  DECIMAL(X,0) TO REMOVE DECIMAL POINT, WHERE X = LENGTH OF THE PACKED DECIMAL SPECIFICATION
  MULTIPLY THE AMOUNT (COLUMN_NAME) BY 100
  ZEROES ARE APPENDED TO LEFT OF NUMBER
  RIGHT FUNCTION LENGTH IS ALSO EQUAL TO X
  
  However, DOING THIS PUTS A DASH (NEGATIVE CHAR) IN THE MIDDLE OF THE NUMBER... 
  SO in the case where a column can contain either positives or negatives, WE HAVE TO ADJUST:
  WE USE A CASE STATEMENT, AND PUT THE GENERAL FORM INTO IT THREE TIMES

  CASE CHARINDEX('-',
    RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(X,0),((COLUMN_NAME) * 100)) as varchar),X)
  )WHEN 0 THEN 
    RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(X,0),((COLUMN_NAME) * 100)) as varchar),X)
  ELSE '-' + REPLACE(
    RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(X,0),((COLUMN_NAME) * 100)) as varchar),X)
  ,'-','') END as TOT_AMT
  
  Line numbers and formats in this view (packed info needed for CFF):
  
  25 overpunch
  68 packed
  108 signed bin
  112 signed bin
  115 signed bin	 
  147 packed
  205 packed
  206 packed
  207 packed



*/

CREATE VIEW [dbo].[XX_CLS_999_FILE_VW]
AS

Select 
-- reconcile field lengths to the spec, page 1: 3,2,3,4,1
(select LEFT(parameter_value,3) from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_COUNTRY_NUM') as Country_Number -- trailing to 3
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_LEDGER_CD')+REPLICATE(CHAR(160),2),2) as Ledger_Code -- trailing to 2
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_FILE_ID')+REPLICATE(CHAR(160),3),3) as THE_File_Id  -- trailing to 3
, '0000' as File_Sequence_No
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_TOLI')+REPLICATE(CHAR(160),1),1) as Type_of_Ledger_IndicatoR -- trailing to 1
, DIVISION as Division
, left(coalesce(CLS_MAJOR,'') + REPLICATE(CHAR(160),3),3) as Major  -- to 3 trailing spaces FIXED
, left(coalesce(CLS_MINOR,'') + REPLICATE(CHAR(160),4),4) as Minor   -- to 4 trailing spaces FIXED
, left(coalesce(CLS_SUB_MINOR,'') + REPLICATE(CHAR(160),4),4)  as Sub_Minor  -- to 4 trailing spaces FIXED
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_LERU_NUM') + REPLICATE(CHAR(160),6),6) as Ledger_Reporting_Unit  -- trailing to 6
,REPLICATE(CHAR(160),1) AS PCY_IND ,  --   START = 33  LEN = 1
REPLICATE(CHAR(160),15) AS TASK ,  --   START = 34  LEN = 15
REPLICATE(CHAR(160),1) AS RVSL ,  --   START = 49  LEN = 1
REPLICATE(CHAR(160),2) AS  CONDIV ,  --   START = 50  LEN = 2
REPLICATE(CHAR(160),3) AS CONMAJ ,  --   START = 52  LEN = 3
REPLICATE(CHAR(160),4) AS CONMIN ,  --   START = 55  LEN = 4
REPLICATE(CHAR(160),2) AS BK  -- FILLER1  START = 59  LEN = 2
 ,left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_LEDGER_SOURCE_CD')+ REPLICATE(CHAR(160),3),3) as Ledger_Source -- trailingto 3 FIX 20181016
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_ACCOUNTANT_ID')+ REPLICATE(CHAR(160),3),3)  as Accountant_ID   -- trailingto 3 FIX 20181016
, left(Coalesce(VOUCHER_NUM,'') + REPLICATE(CHAR(160),7),7) as Index_Number -- trailing spaces to 7
, REPLICATE(CHAR(160),5)  as Pre_Index_Number  -- 5 blank spaces
, REPLACE(CONVERT(VARCHAR(10), cast(clslog.LEDGER_ENTRY_DATE as date), 3),'/','')   as Date_Of_Ledger_Entry -- format DDMMYY FIXED
, right( '00' + coalesce(MONTH_SENT,''),2) as Accounting_Month_Local  --left zeros to 2
, REPLICATE(CHAR(160),3) as Accounting_Month_Fiscal    -- Filler(2)
,  right('000000000000000' + rtrim(ltrim(replace(imapsstg.dbo.xx_full_overpunch_uf(DOLLAR_AMT),'.',''))),15) as Amount_Local_Currency  --GetPIC(CLS_rs.getString("DOLLAR_AMT"), 13, 2) PENDING, REPLICATE(CHAR(160),15)  as Amount_US_Dollars --Filler(15)
,REPLICATE(CHAR(160),15) as Amount_US_Dollars
, left(isnull(MACHINE_TYPE_CD,'') + REPLICATE(CHAR(160),4), 4) as Machine_Type  --TSPC(CLS_rs.getString("MACHINE_TYPE_CD"), 4)
, REPLICATE(CHAR(160),3)  as Machine_Model --Filler(3)
, REPLICATE(CHAR(160),12)  as Invoice_Number -- Filler(10)
, left('IMAPS ' + right( '0000' + coalesce(clslog.FY_SENT,''),4) + right( '00' + coalesce(clslog.MONTH_SENT,''),2) + REPLICATE(CHAR(160),1) + coalesce(IMAPS_ACCT,'') + REPLICATE(CHAR(160),30),30)  as Description_1 --TSPC( "IMAPS " + Accounting_Year + Accounting_Month_Local + " " + IMAPS_ACCT , 30) trailing  spaces to 30 FIXED
, left(coalesce(DESCRIPTION2,'') + REPLICATE(CHAR(160),30), 30)  as Description_2 --TSPC(CLS_rs.getString("DESCRIPTION2"), 30) FIXED
,REPLICATE(CHAR(160),15) AS LOCFLD1 ,  --   START = 198  LEN = 15
REPLICATE(CHAR(160),15) AS LOCFLD2 ,  --   START = 213  LEN = 15
REPLICATE(CHAR(160),10) AS LOCFLD3 ,  --   START = 228  LEN = 10
REPLICATE(CHAR(160),10) AS LOCFLD4 ,  --   START = 238  LEN = 10
REPLICATE(CHAR(160),10) AS LOCFLD5 ,  --   START = 248  LEN = 10
REPLICATE(CHAR(160),8) AS USERID ,  --   START = 258  LEN = 8
REPLICATE(CHAR(160),2) AS FDIV ,  --   START = 266  LEN = 2
REPLICATE(CHAR(160),3) AS FMAJ ,  --   START = 268  LEN = 3
REPLICATE(CHAR(160),4) AS FMIN ,  --   START = 271  LEN = 4
 left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_TOLI') + REPLICATE(CHAR(160),1), 1)  as Reference_Type_Of_Ledger_Ind --trailing to 1 FIXED
, division as Reference_Division
, left(coalesce(CLS_MAJOR,'') + REPLICATE(CHAR(160),3),3)  as Reference_Major -- to 3 trailing spaces FIXED
, left(coalesce(CLS_MINOR,'') + REPLICATE(CHAR(160),4),4)  as Reference_Minor -- to 4 trailing spaces  FIXED
, left(coalesce(CLS_SUB_MINOR,'') + REPLICATE(CHAR(160),4),4)  as Reference_Sub_Minor --to 4 trailing spaces  FIXED
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_LERU_NUM') + REPLICATE(CHAR(160),6),6) as Reference_LERU -- trailing to 6
,REPLICATE(CHAR(160),6) AS FRV_DATE6 ,  --   START = 295  LEN = 6
REPLICATE(CHAR(160),2) AS TAI ,  --   START = 301  LEN = 2
 left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_LEDGER_CD') + REPLICATE(CHAR(160),2),2)  as HQ_Conversion_LC --trailing to2
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_INPUT_TYPE_ID') + REPLICATE(CHAR(160),1),1)  as Input_Type_Identifier -- parameter INPUT_TYPE_ID trailing  to 1
,REPLICATE(CHAR(160),1) AS STAT_ID,  --  START =325  LEN = 1
REPLICATE(CHAR(160),1) AS CHNG_ID,  --   START = 326  LEN = 1
REPLICATE(CHAR(160),1) AS RECON_IND ,  --   START = 327  LEN = 1
REPLICATE(CHAR(160),3) AS APPR_ACCID ,  --   START = 328  LEN = 3
REPLICATE(CHAR(160),8) AS APPR_USERID ,  --   START = 331  LEN = 8
REPLICATE(CHAR(160),4) AS APPR_DATE4 ,  --   START = 339  LEN = 4
REPLICATE(CHAR(160),1) AS DIR_CRNCY_IND,  --   START = 343  LEN = 1
REPLICATE(CHAR(160),3) AS ORIG_FID ,  --   START = 344  LEN = 3
REPLICATE(CHAR(160),4) AS ORIG_FSEQ ,  --   START = 347  LEN = 4
REPLICATE(CHAR(160),4) AS ORIG_RSN ,  --   START = 351  LEN = 4
REPLICATE(CHAR(160),1) AS YTD_IND ,  --   START = 355  LEN = 1
 left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_FULFILLMENT_CHANNEL_CD') + REPLICATE(CHAR(160),3), 3) as  Fulfillment_Channel --parameter 16_FULFILLMENT_CHANNEL_CD trailing 3
,REPLICATE(CHAR(160),7) AS PID ,  --   START = 359  LEN = 7
REPLICATE(CHAR(160),2) AS REVAL_IND ,  -- FILLER7  START = 366  LEN = 2
  left(coalesce(BUSINESS_AREA,'') + REPLICATE(CHAR(160),4),4) as Marketing_Division -- trailing 2 FIXED
,REPLICATE(CHAR(160),2) AS SOC,  --   START = 372  LEN = 2
  left(coalesce(MACHINE_TYPE_CD, coalesce(PRODUCT_ID,'')) + REPLICATE(CHAR(160),12),12)  as Part_Number  -- trailing 12 FIXED
,  REPLICATE(CHAR(160),4) as  Exchange_Minor -- Filler(4)
,  REPLICATE(CHAR(160),1)  as X_Org_Indicator -- Filler(1)
,  left(coalesce(MACHINE_TYPE_CD, coalesce(PRODUCT_ID,'')) + REPLICATE(CHAR(160),12),12)  as Product_ID  -- trailing 12 FIXED
,  left(coalesce(CUSTOMER_NUM,'')+ REPLICATE(CHAR(160),8),8) as Customer_Number  -- trailing 7 FIXED
,  REPLICATE(CHAR(160),4)  as Feature_Number  -- Filler(4)
,  REPLICATE(CHAR(160),2)  as Filler_1  -- Filler(1)
,  left(coalesce(MACHINE_TYPE_CD, coalesce(PRODUCT_ID,'')) + REPLICATE(CHAR(160),12),12) as From_Product_ID --if MACHINE_TYPE_CD is blank then PRODUCT_ID else MACHINE_TYPE_CDto trailing 12 FIXED
,  REPLICATE(CHAR(160),15)  as Quantity  -- Filler(15)
,  left(coalesce(MARKETING_AREA,'')+ REPLICATE(CHAR(160),2),2) as Marketing_Area  -- trailing to 2 FIXED
,REPLICATE(CHAR(160),12) AS MES_NBR_RPQ ,  --   START = 446  LEN = 12
REPLICATE(CHAR(160),3) AS RECV_CTY ,  --   START = 458  LEN = 3
REPLICATE(CHAR(160),2) AS CORP_USE1 ,  --   START = 461  LEN = 2
REPLICATE(CHAR(160),3) AS CORP_USE2 ,  --   START = 463  LEN = 3
REPLICATE(CHAR(160),1) AS CORP_USE3_1,  --   START = 466  LEN = 1
REPLICATE(CHAR(160),2) AS CORP_USE3_2,  --   START = 467  LEN = 2
REPLICATE(CHAR(160),9) AS CORP_USE4_CORP_USE5 ,  --   START = 469  LEN = 9
REPLICATE(CHAR(160),6) AS CORP_USE6 ,  --   START = 478  LEN = 6
COALESCE(LEFT(IMAPS_PROJ_ID + REPLICATE(CHAR(160),7),7),REPLICATE(CHAR(160),7)) AS CORP_USE7 ,  -- PACT NUMBER  START = 484  LEN = 7  MIMICS PROJECT FOR LINES
REPLICATE(CHAR(160),8) AS CORP_USE8 ,  --   START = 491  LEN = 8
REPLICATE(CHAR(160),19) AS CORP_USE9_CORP_USE10,  --   START = 499  LEN = 19
REPLICATE(CHAR(160),3) AS REV_TYPE ,  --   START = 518  LEN = 3
REPLICATE(CHAR(160),3) AS REASON ,  --   START = 521  LEN = 3
COALESCE(IMAPSSTG.DBO.XX_GET_CONTRACT_TYPE_CD_UF(IMAPS_PROJ_ID),REPLICATE(CHAR(160),2)) AS CONTR_TYPE ,  --   START = 524  LEN = 2
REPLICATE(CHAR(160),2) AS DOCU_TYPE ,  --   START = 526  LEN = 2
REPLICATE(CHAR(160),3) AS OFF_CODE ,  --   START = 528  LEN = 3
REPLICATE(CHAR(160),1) AS AGREE_TYPE ,  --   START = 531  LEN = 1
REPLICATE(CHAR(160),1) AS BUSS_TYPEA,  --   START = 532  LEN = 1
REPLICATE(CHAR(160),1) AS PRINT_IND ,  --   START = 533  LEN = 1
REPLICATE(CHAR(160),4) AS EVENT_SEQ_NBR ,  --   START = 534  LEN = 4
REPLICATE(CHAR(160),3) AS EVENT_CODE ,  --   START = 538  LEN = 3
REPLICATE(CHAR(160),1) AS EVENT_TYPE ,  --   START = 541  LEN = 1
REPLICATE(CHAR(160),3) AS MATCH_CODE ,  --   START = 542  LEN = 3
REPLICATE(CHAR(160),4) AS GROUP_NBR ,  --   START = 545  LEN = 4
REPLICATE(CHAR(160),3) AS ACCT_GRP ,  --   START = 549  LEN = 3
REPLICATE(CHAR(160),1) AS ACCT_TYPE ,  --   START = 552  LEN = 1
REPLICATE(CHAR(160),2) AS ACCT_SEQ_NBR ,  --   START = 553  LEN = 2
REPLICATE(CHAR(160),9) AS SERIAL_NBR ,  --   START = 555  LEN = 9
  left(isnull(IGS_PROJ,'') + REPLICATE(CHAR(160),7),7) as IGS_Project_No  --trailing to 7
,REPLICATE(CHAR(160),12) AS DLVY_NOTE_NBR ,  --   START = 571  LEN = 12
REPLICATE(CHAR(160),6) AS ORDER_NBR ,  -- FILLER10  START = 583  LEN = 6
  left(isnull(CONTRACT_NUM,'') + REPLICATE(CHAR(160),15),15) as Contract_Number  -- trailing to 15
,  left(coalesce(MACHINE_TYPE_CD, coalesce(PRODUCT_ID,'')) + REPLICATE(CHAR(160),12),12) as Service_Product_ID  -- FIXED
,  left(coalesce(MACHINE_TYPE_CD, coalesce(PRODUCT_ID,'')) + REPLICATE(CHAR(160),12),12) as OEM_Product_ID -- FIXED
,REPLICATE(CHAR(160),5) AS ISIC_CODE ,  --   START = 628  LEN = 5
REPLICATE(CHAR(160),9) AS AGREE_REF_NBR ,  --START = 633  LEN = 9
  left(isnull(MARKETING_OFFICE,'') + REPLICATE(CHAR(160),3),3) as Marketing_Branch_Office   --trailing to 3
,REPLICATE(CHAR(160),3) AS UNIT_BIL ,  --   START = 645  LEN = 3
REPLICATE(CHAR(160),3) AS UNIT_USER ,  --   START = 648  LEN = 3
REPLICATE(CHAR(160),8) AS CUST_NBR_USER,  --   START = 651  LEN = 8
left(CUSTOMER_NUM + REPLICATE(CHAR(160),8),8) AS CUST_NBR_BIL ,  --   START = 659  LEN = 8
REPLICATE(CHAR(160),8) AS CUST_NBR_OWNER ,  --   START = 667  LEN = 8
REPLICATE(CHAR(160),8) AS CUST_NBR_PAY ,  --   START = 675  LEN = 8
REPLICATE(CHAR(160),7) as INV_NBR,  --   START = 683  LEN = 7
REPLICATE(CHAR(160),10) AS TXMS_CODE ,  --   START = 690  LEN = 10
REPLICATE(CHAR(160),10) AS SHIP_DATE ,  --   START = 700  LEN = 10
REPLICATE(CHAR(160),10) AS INSTALL_DATE ,  --   START = 710  LEN = 10
REPLICATE(CHAR(160),10) AS PER_START ,  --   START = 720  LEN = 10
REPLICATE(CHAR(160),10) AS PER_END ,  --   START = 730  LEN = 10
REPLICATE(CHAR(160),3) AS ACCT_BRANCH ,  --   START = 740  LEN = 3
REPLICATE(CHAR(160),4) AS ACCT_DEPT ,  --   START = 743  LEN = 4
left(isnull(CONSOLIDATED_REV_BRANCH_OFFICE,'') + REPLICATE(CHAR(160),3),3) as Consolidated_Revenue_BO  -- trailing to 3
,REPLICATE(CHAR(160),250) AS COUNTRY_EXT   -- FILLER17  START = 750  LEN = 250
from IMAPSSTG.dbo.XX_CLS_DOWN, 
(select top 1 * from IMAPSSTG.dbo.XX_CLS_DOWN_LOG order by status_record_num desc) clslog

GO



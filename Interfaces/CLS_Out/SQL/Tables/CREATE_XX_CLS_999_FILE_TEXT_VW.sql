USE [IMAPSStg]
GO

/****** Object:  View [dbo].[XX_CLS_999_FILE_TEXT_VW]    Script Date: 11/05/2019 09:15:53 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[XX_CLS_999_FILE_TEXT_VW]'))
DROP VIEW [dbo].[XX_CLS_999_FILE_TEXT_VW]
GO

USE [IMAPSStg]
GO

/****** Object:  View [dbo].[XX_CLS_999_FILE_TEXT_VW]    Script Date: 11/05/2019 09:15:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO





/* 
Used by CFF for CLS Interface

usage: select * from imapsstg.dbo.XX_CLS_999_FILE_TEXT_VW

Three special numeric formats in CLSDOWN FILE:


1) Signed Binary Integer
   Requires no formatting in query other than return signed integer
   
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
  
  Line numbers and formats in this view (info needed for CFF):
  
  25 overpunch
  68 packed
  108 signed bin
  112 signed bin
  115 signed bin	 
  146 packed
  204 packed
  205 packed
  206 packed



*/

CREATE VIEW [dbo].[XX_CLS_999_FILE_TEXT_VW]
AS

Select 
(select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_COUNTRY_NUM')+Filler_3 as Country_Number -- trailing to 3
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_LEDGER_CD')+Filler_2,2) as Ledger_Code -- trailing to 2
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_FILE_ID')+ Filler_3,3) as File_Id  -- trailing to 3
, '0000' as File_Sequence_No
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_TOLI') + Filler_1,1) as Type_of_Ledger_Indicator -- trailing to 1
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_DIVISION') + Filler_2,2) as Division --trailing to 2
, left(coalesce(CLS_MAJOR,'') + Filler_3,3) as Major  -- to 3 trailing spaces FIXED
, left(coalesce(CLS_MINOR,'') + Filler_4,4) as Minor   -- to 4 trailing spaces FIXED
, left(coalesce(CLS_SUB_MINOR,'') + Filler_4,4)  as Sub_Minor  -- to 4 trailing spaces FIXED
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_LERU_NUM') + Filler_6,6) as Ledger_Reporting_Unit  -- trailing to 6
, Filler_1  as Past_Current_Year_Indicator -- 1 blank space 
, Filler_15  as Task_Field  --15 blank spaces
, Filler_1  as Reversal_Indicator -- 1 blank space
, Filler_2  as Contra_Acct_Org_Unit  -- 2 blank spaces
, Filler_3  as Contra_Acct_Major  -- 3 blank spaces
, Filler_4  as Contra_Acct_Minor  -- 4 blank spaces
, Filler_2  as Book_Number  -- 2 blank spaces
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_LEDGER_SOURCE_CD')+ Filler_3,3) as Ledger_Source -- trailing to 3 FIX 20181016
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_ACCOUNTANT_ID')+ Filler_3,3)  as Accountant_ID   -- trailing to 3 FIX 20181016
, left(Coalesce(VOUCHER_NUM,'') + Filler_7,7) as Index_Number -- trailing spaces to 7
, Filler_5  as Pre_Index_Number  -- 5 blank spaces
, REPLACE(CONVERT(VARCHAR(10), cast(clslog.LEDGER_ENTRY_DATE as date), 3),'/','')   as Date_Of_Ledger_Entry -- format DDMMYY FIXED
, right( '00' + coalesce(clslog.MONTH_SENT,''),2) as Accounting_Month_Local  --left zeros to 2
, Filler_2 as Accounting_Month_Fiscal    -- Filler(2)
/************ BEGIN OVERPUNCH FIELD *************/
,  right(space(20)+ rtrim(cast(DOLLAR_AMT as varchar(20))),15) as Amount_Local_Currency  --GetPIC(CLS_rs.getString("DOLLAR_AMT"), 13, 2) PENDING, Filler_15  as Amount_US_Dollars --Filler(15)
--,  right('000000000000000' + rtrim(ltrim(replace(imapsstg.dbo.xx_full_overpunch_uf(DOLLAR_AMT),'.',''))),13) as Amount_Local_Currency  --GetPIC(CLS_rs.getString("DOLLAR_AMT"), 13, 2) PENDING, space(15)  as Amount_US_Dollars --Filler(15)
/************ END OVERPUNCH FIELD *************/
, left(isnull(MACHINE_TYPE_CD,'') + Filler_4, 4) as Machine_Type  --TSPC(CLS_rs.getString("MACHINE_TYPE_CD"), 4)
, Filler_3  as Machine_Model --Filler(3)
, Filler_10  as Invoice_Number -- Filler(10)
,  Filler_2 as Invoice_Number_Reserve --Filler(2)
, left('IMAPS ' + right( '0000' + coalesce(clslog.FY_SENT,''),4) + right( '00' + coalesce(clslog.MONTH_SENT,''),2) + Filler_1 +coalesce(IMAPS_ACCT,'') + Filler_30,30)  as Description_1 --TSPC( "IMAPS " + Accounting_Year + Accounting_Month_Local + " " + IMAPS_ACCT , 30) trailing  spaces to 30 FIXED
, left(coalesce(DESCRIPTION2,'') + Filler_30, 30)  as Description_2 --TSPC(CLS_rs.getString("DESCRIPTION2"), 30) FIXED
, Filler_12  as WT_Invoice_Number --Filler(12)
, Filler_3  as Freight_Mode_Code --Filler(3)
, Filler_9  as Material_Group_Code  --Filler(9)
, Filler_6 as Ship_to_Location --Filler(6)
, Filler_6  as Employee_Serial_Number --Filler(6)
, Filler_4  as Job_Code --Filler(4)
, Filler_10  as Vendor_Bill_To_From --Filler(10)
, Filler_10  as Purchase_Order_No --Filler(10)
, Filler_8  as User_ID --Filler(8)
, Filler_2  as Fiscal_Acct_Org_Unit --Filler(2)
, Filler_3  as Fiscal_Acct_Major  --Filler(3)
, Filler_4  as Fiscal_Acct_Minor  --Filler(4)
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_TOLI') + Filler_1, 1)  as Reference_Type_Of_Ledger_Ind --trailing to 1 FIXED
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_DIVISION') + Filler_2, 2) as Reference_Division  --trailing to 2 FIXED

, left(coalesce(CLS_MAJOR,'') + Filler_3,3)  as Reference_Major -- to 3 trailing spaces FIXED 
, left(coalesce(CLS_MINOR,'') + Filler_4,4)  as Reference_Minor -- to 4 trailing spaces  FIXED
, left(coalesce(CLS_SUB_MINOR,'') + Filler_4,4)  as Reference_Sub_Minor --to 4 trailing spaces  FIXED
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_LERU_NUM') + Filler_6, 6)  as Reference_LERU -- trailing to 6
, Filler_6  as File_Record_Verification_Run_Date  --Filler(6)
, Filler_2 as Transfer_Account_Indicator  --Filler(2)
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_LEDGER_CD') + Filler_2,2)  as HQ_Conversion_LC --trailing to 2
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_DIVISION') + Filler_2,2)  as HQ_Conversion_Division --trailing to 2
, left(coalesce(CLS_MAJOR,'') + Filler_3,3) as HQ_Conversion_Major -- to 3 trailing spaces FIXED
, left(coalesce(CLS_MINOR,'') + Filler_4, 4)   as HQ_Conversion_Minor -- to 4 trailing spaces FIXED
, left(coalesce(CLS_SUB_MINOR,'') + Filler_4, 4)  as HQ_Conversion_Sub_Minor  -- to 4 trailing spaces FIXED
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_LERU_NUM')+Filler_6,6)  as HQ_Conversion_LERU -- trailing to 6
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_INPUT_TYPE_ID') + Filler_1,1)  as Input_Type_Identifier -- parameter INPUT_TYPE_ID trailing  to 1
, Filler_1  as Status_Identifier -- Filler(1)
, Filler_1  as Change_Identifier -- Filler(1)
, Filler_1  as Reconciliation_Indicator -- Filler(1)
, Filler_3  as Approver_Id  -- Filler(3)
, Filler_8  as Approver_User_Id  -- Filler(8)
, Filler_4  as Approval_Date  -- Filler(4)
, Filler_1  as Direct_Currency_Indicator -- Filler(1)
, left ((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_FILE_ID') + Filler_3,3)  as Reference_File_ID  -- trailing to 3
,  '0000'  as Reference_File_Sequence_No
/************ BEGIN PACKED FIELD *************/
--In BIN file, packed column  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(7,0),((0) * 100)) as varchar),7) as packed_Reference_Audit_Number
 ,  '00000.0' as Reference_Audit_Number
--,RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(7,0),((0) * 100)) as varchar),7) as Reference_Audit_Number
/************ END PACKED FIELD *************/
,  Filler_1  as YTD_Indicator --Filler(1)
, left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where parameter_name ='16_FULFILLMENT_CHANNEL_CD') + Filler_3, 3) 
as  Fulfillment_Channel --parameter 16_FULFILLMENT_CHANNEL_CD trailing 3
,  Filler_2  as Filler_2 -- Filler(2)
,  Filler_2  as  Revaluation_Indicator -- Filler(2)
,  left(coalesce(BUSINESS_AREA,'') + Filler_2,2) as Marketing_Division -- trailing 2 FIXED
,  Filler_2  as Sub_Business_Area -- Filler(2)
,  Filler_2  as  FDS_Segment_US  -- Filler(2)
,  left(coalesce(MACHINE_TYPE_CD, coalesce(PRODUCT_ID,'')) + Filler_12,12)  as Part_Number  -- trailing 12 FIXED
,  Filler_4 as  Exchange_Minor -- Filler(4)
,  Filler_1  as X_Org_Indicator -- Filler(1)
,  left(coalesce(MACHINE_TYPE_CD, coalesce(PRODUCT_ID,'')) + Filler_12,12)  as Product_ID  -- trailing 12 FIXED
,  left(coalesce(CUSTOMER_NUM,'')+ Filler_7,7) as Customer_Number  -- trailing 7 FIXED
,  Filler_1  as Customer_Number_Reserve 	-- Filler(1)
,  Filler_4  as Feature_Number  -- Filler(4)
,  Filler_1  as Filler_1  -- Filler(1)
,  left(coalesce(MACHINE_TYPE_CD, coalesce(PRODUCT_ID,'')) + Filler_12,12) as From_Product_ID --if MACHINE_TYPE_CD is blank then PRODUCT_ID else MACHINE_TYPE_CD to trailing 12 FIXED
,  Filler_15  as Quantity  -- Filler(15)
,  left(coalesce(MARKETING_AREA,'')+ Filler_2,2) as Marketing_Area  -- trailing to 2 FIXED
,  Filler_6  as MES_Number  -- Filler(6)
,  Filler_6  as RPQ  -- Filler(6)
,  Filler_3  as Receiving_Country  -- Filler(3)
,  Filler_2  as Corp_Use_1  -- Filler(2)
,  Filler_3  as Corp_Use_2  -- Filler(3)
,  Filler_3  as Corp_Use_3  -- Filler(3)
,  Filler_4 as  Corp_Use_4  -- Filler(4)
,  Filler_5  as Corp_Use_5  -- Filler(5)
,  Filler_6  as Corp_Use_6  -- Filler(6)
,  Filler_7  as Corp_Use_7  -- Filler(7)
,  Filler_8  as Corp_Use_8	-- Filler(8)
,  Filler_9  as Corp_Use_9	-- Filler(9)
,  Filler_10  as Corp_Use_10  -- Filler(10)
,  Filler_3  as Revenue_Type -- Filler(3)
,  Filler_3 as Reason_Code  -- Filler(3)
,  Filler_2  as Contract_Type   -- Filler(2)
,  Filler_2  as Document_Type   -- Filler(2)
,  Filler_3  as Offering_Code   -- Filler(3)
,  Filler_1  as Agreement_Type  -- Filler(1)
,  Filler_1  as Business_Type   -- Filler(1)
,  Filler_1  as Print_Indicator  -- Filler(1)
/************ BEGIN SIGNED BINARY FIELD *************/
--placeholder for Event_Sequence_No (integer 31) WriteSignedBin(CLS_Array, Event_Sequence_No, 31)
, '0000' as 	Event_Sequence_No 
/************ END SIGNED BINARY FIELD *************/			 
,  Filler_3 as  Event_Code  -- Filler(3)
,  Filler_1 as  Event_Type  -- Filler(1)
,  Filler_3 as  Cost_Revenue_Match_Code -- Filler(3)	
/************ BEGIN SIGNED BINARY FIELD *************/
--placeholder for Cost_Revenue_Group_No	(int 31	) WriteSignedBin(CLS_Array, Cost_Revenue_Group_No, 31)
, '0000' as Cost_Revenue_Group_No	
/************ END SIGNED BINARY FIELD *************/
,  Filler_3 as Account_Group  -- Filler(3)
,  Filler_1 as  Account_Type  -- Filler(1)	
/************ BEGIN SIGNED BINARY FIELD *************/
--placeholder for Account_Sequence_No (int 15) WriteSignedBin(CLS_Array, Account_Sequence_No, 15)
, '00' as Account_Sequence_No 
/************ BEGIN SIGNED BINARY FIELD *************/			 
,  Filler_7 as Machine_Serial_Property_Record_Number  -- Filler(7) 
,  Filler_2 as  Machine_Serial_Reserve   -- Filler(2)
,  left(isnull(IGS_PROJ,'') + Filler_7,7) as IGS_Project_No  --trailing to 7
,  Filler_12 as  Top_Bill_Part_No_US  -- Filler(12)
,  Filler_6 as  IBM_Order_No   -- Filler(6)
,  left(isnull(CONTRACT_NUM,'') + Filler_12,12) as Contract_Number  -- trailing to 12
,  Filler_3 as  Contract_No_Reserve_US   -- Filler(3)
,  left(coalesce(MACHINE_TYPE_CD, coalesce(PRODUCT_ID,'')) + Filler_12,12) as Service_Product_ID  -- FIXED
,  left(coalesce(MACHINE_TYPE_CD, coalesce(PRODUCT_ID,'')) + Filler_12,12) as OEM_Product_ID -- FIXED
,  Filler_5 as  ISIC_Code   -- Filler(5)
,  Filler_9 as Agreement_Reference_No   -- Filler(9)
,  left(isnull(MARKETING_OFFICE,'') + Filler_3,3) as Marketing_Branch_Office   --trailing to 3
,  Filler_3 as  Marketing_Unit_Billing_Cust   -- Filler(3)
,  Filler_3 as  Accepting_Branch_Office  -- Filler(3)
,  Filler_8 as  Customer_No_User   -- Filler(8)
,  Filler_8 as  Customer_No_Billed  -- Filler(8)
,  Filler_8 as  Customer_No_Owner   -- Filler(8)
,  Filler_8 as  Paying_Affiliated_Customer  -- Filler(8)
,  Filler_7  as  Factory_Order_No_US   -- Filler(7)
,  Filler_7  as  Form_Number  -- Filler(7)
,  Filler_3 as  Plant_Code   -- Filler(3)
,  Filler_10 as  Ship_Date   -- Filler(10)
,  Filler_10 as  Installation_Date   -- Filler(10)
,  Filler_10 as  Period_Start_Date   -- Filler(10)
,  Filler_10 as  Period_End_Date   -- Filler(10)
,  left(isnull(CONSOLIDATED_REV_BRANCH_OFFICE,'') + Filler_3,3) as Consolidated_Revenue_BO  -- trailing to 3
,  Filler_3 as  Department_Working_US  -- Filler(3)
,  Filler_1 as  Department_Working_Suffix   -- Filler(1)
,  Filler_3 as  Responsible_BO   -- Filler(3)
,  Filler_6 as  Appropriation_No  -- Filler(6) 
/********** BEGIN PACKED DECIMAL ***********/
--placeholder for Hours (0.0) , WritePacked(CLS_Array, Hours, 7, 1);
 , '00000.0' as Hours
--,RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(7,1),((0) * 100)) as varchar),7) as Hours
/********** END PACKED DECIMAL ***********/			
,  Filler_3 as  Filler_3 
,  Filler_1 as  Region   --Filler(1)
,  Filler_1 as  Dept_Charged_Suffix   --Filler(1)
,  Filler_2 as  Due_From_Div_Indicator   --Filler(2)
,  Filler_1 as  Pre_Inventory_Indicator   --Filler(1)
,  Filler_7 as  Engineering_Change_No   --Filler(7)
,  Filler_8 as  Order_Reference_Number   --Filler(8)
,  Filler_2 as  CTF_Indicator   --Filler(2)
,  Filler_3 as  Unit_of_Measure   --Filler(3)
,  Filler_2 as  Discount_Code   --Filler(2)
,  Filler_5 as  HQ_CIBS_Billing_Class   --Filler(5)
,  left(coalesce(INDUSTRY,'') + Filler_4,4) as Industry   --trailing to 4 FIXED
,  Filler_3 as Old_Model_No   --Filler(3)
,  Filler_1 as  Type_Device   --Filler(1)
,  Filler_10 as  Accounts_Payable_Index_No  --Filler(10)
,  Filler_2 as  State_Tax_Code   --Filler(2)
,  Filler_3 as  County_Tax_Code   --Filler(3)
,  Filler_4 as  City_Tax_Code   --Filler(4)
,  Filler_1 as  Use_Tax_Code   --Filler(1)
,  Filler_6 as  ETV_Code   --Filler(6)
,  Filler_1 as  Direct_Indirect_Indicator   --Filler(1)
,  Filler_1 as  Commissionable_Indicator   --Filler(1)
,  Filler_2 as  AP_SAP_Document_Type   --Filler(2)
,  Filler_2 as  AP_Charge_Type   --Filler(2)
,  Filler_2 as  Direction_IND   --Filler(2)
,  Filler_3 as  CIBS_Originator_ID   --Filler(3)
,  Filler_1 as  GSA_Indicator   --Filler(1)
,  Filler_4 as  Class_Number   --Filler(4)
,  Filler_3 as  Activity_Code   --Filler(3)
,  Filler_2 as  Start_Month   --Filler(2)
,  Filler_2 as  Start_Year   --Filler(2)
,  Filler_2 as  Stop_Month   --Filler(2)
,  Filler_2 as  Stop_Year    --Filler(2)
,  Filler_2 as  Number_of_Months   --Filler(2)
,  Filler_1 as  Machine_Type_Prefix   --Filler(1)
,  Filler_3 as  Original_Source   --Filler(3)
,  Filler_1 as  FDS_Customer_Type   --Filler(1)
,  Filler_3 as  Billing_Code   --Filler(3)
,  Filler_2 as  Retail_Division   --Filler(2)
,  Filler_2 as  Industry_Code   --Filler(2)
,  Filler_1 as  Marketing_Region   --Filler(1)
,  Filler_6 as  Invoice_Date  --Filler(6)
,  Filler_1 as  Accounting_Method   --Filler(1)
,  Filler_6 as  End_Finance_Date  --Filler(6)
,  Filler_3 as  Lease_Term   --Filler(3)
,  Filler_1 as  Lease_Type   --Filler(1)
,  Filler_6 as  Start_Finance_Date  --Filler(6)
,  Filler_3 as  Source_Transmission_Ind   --Filler(3) FIX 20181016
,  Filler_1 as  In_Out_City_Limits   --Filler(1)
,  Filler_1 as  Product_Type   --Filler(1)
,  Filler_1 as  Quarterly_Indicator  --Filler(1)
,  left(coalesce(ENTERPRISE_NUM_CD,'') + Filler_7, 7) as Enterprise_Number  --trailing to 7 FIXED
,  Filler_3 as  Master_Service_Office   --Filler(3)
,  Filler_4 as  Country_Code   --Filler(4)
,  Filler_4 as  Analysis_Code   --Filler(4)
,  Filler_4 as Filler_4
,  Filler_4 as Course_No_Category   --Filler(4)
/********** BEGIN PACKED DECIMAL ***********/
-----placeholder Burden_Amount, Use_Tax_Amount, Foreign_Currency_Amount 
-- WritePacked(CLS_Array, Burden_Amount, 11, 2);
--			 WritePacked(CLS_Array, Use_Tax_Amount, 7, 2);
--			 WritePacked(CLS_Array, Foreign_Currency_Amount, 15, 2);
, '000000000.00' as Burden_Amount
, '0000.00' as Use_Tax_Amount
, '000000000000.00' as Foreign_Currency_Amount
--,RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(11,2),((0) * 100)) as varchar),11) AS Burden_Amount
--,RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(7,2),((0) * 100)) as varchar),7) AS Use_Tax_Amount
--,RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(15,2),((0) * 100)) as varchar),15) AS Foreign_Currency_Amount
/********** END PACKED DECIMAL ***********/			

 , Filler_10 as Course_No
, Filler_4 as SAP_Identifier 
, Filler_12 as Part_Number_Machine_Type
, Filler_4 as SODT 
, Filler_1 as ASSETIND
, Filler_5

from IMAPSSTG.dbo.XX_CLS_DOWN , 

(select top 1 * from IMAPSSTG.dbo.XX_CLS_DOWN_LOG order by status_record_num desc) clslog,

(
Select Space(1) as Filler_1
, Space(2) as Filler_2
, Space(3) as Filler_3
, Space(4) as Filler_4
, Space(5) as Filler_5
, Space(6) as Filler_6
, Space(7) as Filler_7
, Space(8) as Filler_8
, Space(9) as Filler_9
, Space(10) as Filler_10
, Space(11) as Filler_11
, Space(12) as Filler_12
, Space(13) as Filler_13
, Space(14) as Filler_14
, Space(15) as Filler_15
, Space(30) as Filler_30

) as Fillers



GO



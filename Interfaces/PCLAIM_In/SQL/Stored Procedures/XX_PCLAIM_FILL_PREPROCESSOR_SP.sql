USE [IMAPSStg]
GO
/****** Object:  StoredProcedure [dbo].[XX_PCLAIM_FILL_PREPROCESSOR_STAGE_SP]    Script Date: 08/16/2007 10:46:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/****** Object:  Stored Procedure dbo.XX_PCLAIM_FILL_PREPROCESSOR_STAGE_SP    Script Date: 8/16/2007 10:47:42 AM ******/
if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PCLAIM_FILL_PREPROCESSOR_STAGE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[XX_PCLAIM_FILL_PREPROCESSOR_STAGE_SP]AS' 
END
GO



ALTER PROCEDURE [dbo].[XX_PCLAIM_FILL_PREPROCESSOR_STAGE_SP]
(@in_status_record_num   integer,
 @out_SystemError        integer      = NULL OUTPUT,
 @out_STATUS_DESCRIPTION varchar(275) = NULL OUTPUT
)
AS

/************************************************************************************************  
Name:        XX_PCLAIM_FILL_PREPROCESSOR_STAGE_SP 
Author:      Tatiana Perova
Created:     08/24/2005  
Purpose:     Step 2 of PCLAIM interface.
             Data grouping of XX_PCLAIM_IN staging data to populate AP preprocessor staging 
             tables: AOPUTLAP_INP_HDR, AOPUTLAP_INP_DETL, AOPUTLAP_INP_LAB.
             Procedure will also insert vendors and vendor's employee into Costpoint, if they are
             not yet present there.
             Called by XX_PCLAIM_RUN_INTERFACE_SP

Parameters: 
             Input:   @in_STATUS_RECORD_NUM -- identifier of current interface run
             Output:  @out_STATUS_DESCRIPTION --  generated error message
                      @out_SystemError  -- system error code
Result Set:  None  
Version:     1.0

Notes:

Feature 1068 07/24/2006 Reference CR-30. Restrict the range of effective account IDs.
             Specifically, '40-00-00' >= Deltek.ACCT_GRP_SETUP.ACCT_ID < '90-00-00'.

DEV00001077  07/27/2006 Added by Veera to trace the vendor created interface

10/23/06     KM - change VCHR grouping
             For Neil Rancours's MISCODE process, we must group vouchers by VEND_ID and VEND_EMPL_ID
             (currently just VEND_ID)

CP600000324  05/27/2008 - Reference BP&S Service Request CR1543
             Costpoint multi-company fix (five instances).

CP600000413  08/21/2008 - Reference BP&S Service Request CR1639
             Provide stand-by hour labor claim processing.

DR2314		 09/08/2009 - Reference BP&S Service Request DR2314
			 PCLAIM interface Costpoint account mapping discrepancy

CR1440		 09/08/2009 - Reference BP&S Service Request CR1440
			 Vendor employee name change in PCLAIM should flow through to Costpoint.

CR5507		 2013-01-16 - IMAPS PCLAIM interface - include work week in grouping of AP vouchers - KM

DR6201		 2013-04-17 - IMAPS PCLAIM interface - pay type account mapping bug - KM
CR11812      2020-02-19 - Costpoint 7.1.1 upgrade TP
**************************************************************************************************/

DECLARE @vend_id                   varchar(10),  -- TP 09/23/2005 type changed to varchar
        @vend_name                 char(40),
        @vend_st_address           char(40),
        @vend_city                 char(25),
        @vend_state                char(15),
        @vend_country              char(8),
        @vend_empl_id              varchar(8),   -- TP 09/23/2005 type changed to varchar
        @vend_empl_name            char(20),
        @bill_lab_cat_cd           char(6),
        @vend_hrs                  decimal(9,2), -- TP 02/17/2005 DEV00000543 type changed to decimal
        @effect_bill_date          char(10),
        @dummy                     varchar(10),
        @vchr_no                   int,
        @vchr_ln_no                int,
        @po_id                     char(10),
        @fy_cd                     char(6), 
        @LastFY                    char(6),
        @pd_no                     Numeric(2), 
        @sub_pd_no                 Numeric(2),
        @SpReturnCode              int,
        @LastVchrNo                int,
        @LastVchrLnNo              int,         -- TP 09/28/2005 subline grouping by line
        @proj_code                 char(6),
        @HeaderCounter             int,
        @VoucherCounter            int,
        @DetailCounter             int,
        @DetailLineCounter         int,
        @LaborCounter              int,
        @LaborSublineCounter       int,
        @DoesVendorExists          tinyint,
        @DoesVoucherExists         tinyint,
        @NumberOfRecords           int,
        @pclaim_in_record_num      int,
        @account_cd                varchar(8),  -- 02/03/2006 TP DEV0000412
        @VendEmplIdWithVendorError varchar(8),  -- 03/08/2006 TP DEV00000585

-- Begin 02/15/2006 TP DEV0000412
        @NON_DIV16_LABOR_ACCOUNT_MATCH     varchar(8),  
        @SUBCONTRACTOR_LABOR_ACCOUNT_MATCH varchar(8),
        @MATCH_LENGTH                      int,
        @SP_NAME                           sysname,
        @PROCESS_ERRORS_FL                 char(1),
        @pclaim_intername                  varchar(20), -- Added by Veera on 07/27/06 Feature DEV00001077
        @pclaim_rowversion                 int          -- Added by Veera on 07/27/06 Feature DEV00001077	

-- CP600000413_Begin
DECLARE @reg_ACCT_ID       varchar(15),
        @standby_ACCT_ID   varchar(15),
        @pay_type          varchar(3)
-- CP600000413_End

-- CP600000324_Begin
DECLARE @DIV_16_COMPANY_ID varchar(10)

SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'PCLAIM'
-- CP600000324_End


--CR5507
DECLARE @FRIDAY char(10)



-- Select parameters from parameter table
SELECT @NON_DIV16_LABOR_ACCOUNT_MATCH = PARAMETER_VALUE
  FROM XX_PROCESSING_PARAMETERS 
 WHERE INTERFACE_NAME_CD = 'PCLAIM'
   AND PARAMETER_NAME = 'NON_DIV16_LABOR_ACCOUNT_MATCH'

SELECT @SUBCONTRACTOR_LABOR_ACCOUNT_MATCH = PARAMETER_VALUE
  FROM XX_PROCESSING_PARAMETERS 
 WHERE INTERFACE_NAME_CD = 'PCLAIM'
   AND PARAMETER_NAME = 'SUBCONTRACTOR_LABOR_ACCOUNT_MATCH'

SELECT @MATCH_LENGTH = CAST(PARAMETER_VALUE AS INT)
  FROM XX_PROCESSING_PARAMETERS 
 WHERE INTERFACE_NAME_CD = 'PCLAIM'
   AND PARAMETER_NAME = 'MATCH_LENGTH'

-- End 02/15/2006 TP DEV0000412

SET @SP_NAME = 'XX_PCLAIM_FILL_PREPROCESSOR_STAGE_SP'

-- Start Added by Veera on 07/27/06 Feature DEV00001077
SELECT @pclaim_intername = 'PCLAIM INTERFACE',
       @pclaim_rowversion = 6000		

DECLARE @WEEK_ENDING_DT char(10)

SELECT @WEEK_ENDING_DT = MAX(WORK_DATE)
  FROM dbo.XX_PCLAIM_IN
 WHERE RECORD_TYPE = 'R'

IF @WEEK_ENDING_DT IS NULL
   SET @WEEK_ENDING_DT = CONVERT(char(10), GETDATE(), 120)


/*
 * Update for DEV00000775 TP 05/09/06 was done following way
 * PCLAIM_IN.VENDOR_ERROR is set to ‘Y’ one error cases
 * Interface is actually processing  PCLAIM_IN table twice.
 * First time for ‘N’ records, second for ‘Y’ creating two sets of vouchers.
 * Vouchers created from records with vendor error suppose to fail AP preprocessor,
 * But will not stop interface execution, as they previously did.
 */

UPDATE dbo.XX_PCLAIM_IN
   SET VENDOR_ERROR = 'Y'
 WHERE VEND_EMPL_SERIAL_NUM IN
       (SELECT a.VEND_EMPL_SERIAL_NUM
          FROM dbo.XX_PCLAIM_IN a
               INNER JOIN
               dbo.XX_PCLAIM_IN b
	       ON
               a.VEND_EMPL_SERIAL_NUM = b.VEND_EMPL_SERIAL_NUM 
         WHERE a.VENDOR_ID <> b.VENDOR_ID)

-- If subcontractor has multiple vendors, one with latest work date is recognized as valid one.
-- Begin change km
UPDATE dbo.XX_PCLAIM_IN
   SET VENDOR_ERROR = 'N'
 WHERE VEND_EMPL_SERIAL_NUM + VENDOR_ID IN
       (SELECT c.VEND_EMPL_SERIAL_NUM + c.VENDOR_ID
          FROM (select a.VEND_EMPL_SERIAL_NUM,
                       MAX(a.VENDOR_ID) AS VENDOR_ID 
                  FROM dbo.XX_PCLAIM_IN a
                 WHERE a.VENDOR_ERROR = 'Y'
                   AND a.WORK_DATE = (SELECT MAX(WORK_DATE)
                                        FROM dbo.XX_PCLAIM_IN b
                                       WHERE b.VENDOR_ERROR = 'Y'
                                         AND b.VEND_EMPL_SERIAL_NUM = a.VEND_EMPL_SERIAL_NUM
                                     )
                 GROUP BY a.VEND_EMPL_SERIAL_NUM
               ) c
       )
-- End change km


UPDATE dbo.XX_PCLAIM_IN
   SET VENDOR_ERROR = 'Y'
 WHERE VEND_EMPL_SERIAL_NUM IN
         (SELECT VEND_EMPL_SERIAL_NUM 
            FROM dbo.XX_PCLAIM_IN a
                 INNER JOIN
                 IMAPS.Deltek.VEND_EMPL b
                 ON
                 a.VEND_EMPL_SERIAL_NUM = b.VEND_EMPL_ID
           WHERE a.VENDOR_ID <> b.VEND_ID
-- CP600000324_Begin
             AND b.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000324_End

-- Separate error records 
DECLARE @Run2Times integer

SET @Run2Times  = 0
SET @PROCESS_ERRORS_FL = 'N'

WHILE @Run2Times < 2
BEGIN

-- group XX_PCLAIM_IN by voucher requirements
DECLARE HeaderCursor CURSOR FOR
   SELECT VENDOR_ID AS VEND_ID,
          --change KM VCHR grouping 10/23/06--
          VEND_EMPL_SERIAL_NUM AS VEND_EMPL_ID,
          PO_NUMBER AS PO_ID,
          FY_CD,
          PD_NO,
          SUB_PD_NO,

		  --CR5507
		  convert(char(10),dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(WORK_DATE),120) as FRIDAY

     FROM dbo.XX_PCLAIM_IN
    WHERE VENDOR_ERROR = @PROCESS_ERRORS_FL
          --change KM VCHR grouping 10/23/06--
    GROUP BY VENDOR_ID, VEND_EMPL_SERIAL_NUM, PO_NUMBER,FY_CD, PD_NO, SUB_PD_NO, dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(WORK_DATE) --CR5507

-- get initial values for voucher REC_NO and VCHR_NO
SELECT @HeaderCounter = MAX(REC_NO) + 1
  FROM IMAPS.Deltek.AOPUTLAP_INP_HDR

IF @HeaderCounter IS NULL BEGIN SET @HeaderCounter = 1 END

SET @VoucherCounter = @HeaderCounter

OPEN HeaderCursor

--change KM VCHR grouping 10/23/06--
FETCH NEXT FROM HeaderCursor INTO @vend_id, @vend_empl_id, @po_id, @fy_cd, @pd_no, @sub_pd_no, @FRIDAY --CR5507

WHILE (@@fetch_status = 0)
   BEGIN
      -- Add vendor to Costpoint if one does not exist
      SET @DoesVendorExists = 0

      SELECT @DoesVendorExists = 1
        FROM IMAPS.Deltek.VEND
       WHERE LTRIM(RTRIM(VEND_ID)) = @vend_id  -- TP 09/23/2005 
-- CP600000324_Begin
         AND COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000324_End

      IF @DoesVendorExists <> 1 
         BEGIN
            SELECT TOP 1 
                   @vend_name       = VEND_NAME,
                   @vend_st_address = VEND_ST_ADDRESS,
                   @vend_city       = VEND_CITY,
                   @vend_state      = VEND_STATE,
                   @vend_country    = VEND_COUNTRY
              FROM dbo.XX_PCLAIM_IN
             WHERE VENDOR_ID = @vend_id
	
            EXEC @SpReturnCode = dbo.XX_ADD_VENDOR_SP
               @in_VendorId         = @vend_id,
               @in_VendorName       = @vend_name,
               @in_VendorStreetAdr  = @vend_st_address,
               @in_VendorCity       = @vend_city,
               @in_VendorState      = NULL,
               @in_VendorCountry    = @vend_country,
               @out_SystemErrorCode = @out_SystemError,
               @in_VendorStateName  = @vend_state,
               @in_modified_by      = @pclaim_intername,  --Added by Veera on 07/27/06 Feature DEV00001077	
               @in_rowversion       = @pclaim_rowversion  --Added by Veera on 07/27/06 Feature DEV00001077
			
	    IF @SpReturnCode <> 0 BEGIN GOTO ErrorProcessing END

         END /* IF @DoesVendorExists <> 1 */

      -- Validate that new voucher number is not yet used
      SET @DoesVoucherExists = 0
	
      SELECT @DoesVoucherExists = 1
        FROM IMAPS.Deltek.AOPUTLAP_INP_HDR
       WHERE VCHR_NO = @VoucherCounter

      WHILE(@DoesVoucherExists = 1)
         BEGIN
            SET @VoucherCounter = @VoucherCounter + 1

            SELECT @DoesVoucherExists = 1
              FROM IMAPS.Deltek.AOPUTLAP_INP_HDR
             WHERE VCHR_NO = @VoucherCounter

            IF @@ROWCOUNT = 0 BEGIN SET @DoesVoucherExists = 0 END
         END

      -- For each record in cursor, add voucher record.

      INSERT INTO IMAPS.Deltek.AOPUTLAP_INP_HDR
            (REC_NO, S_STATUS_CD, VCHR_NO, FY_CD,
             PD_NO, SUB_PD_NO, VEND_ID, 
             TERMS_DC, 
             INVC_ID, INVC_DT_FLD, INVC_AMT, DISC_DT_FLD, DISC_PCT_RT, DISC_AMT, 
             DUE_DT_FLD, HOLD_VCHR_FL, PAY_WHEN_PAID_FL, 
             PAY_VEND_ID, PAY_ADDR_DC, PO_ID, 
             PO_RLSE_NO, RTN_RATE, AP_ACCT_DESC, CASH_ACCT_DESC, 
             S_INVC_TYPE, SHIP_AMT, CHK_FY_CD, CHK_PD_NO, 
             CHK_SUB_PD_NO, CHK_NO, CHK_DT_FLD, CHK_AMT, 
             DISC_TAKEN_AMT, INVC_POP_DT_FLD, PRINT_NOTE_FL, 
             JNT_PAY_VEND_NAME, NOTES, TIME_STAMP, SEP_CHK_FL,
			 COMPANY_ID)  --CR11812 
      VALUES (@HeaderCounter, 'U', @VoucherCounter, @fy_cd,                -- 04/04/2006 TP AP preprocessor update
	      @pd_no, @sub_pd_no, @vend_id,
              'NET 30',
              NULL, LEFT(CONVERT(char, GETDATE(), 120), 10), 0,            -- TP 09/28/2005 invoice date to current
              NULL, NULL, NULL,
              NULL, 'N', 'N',  -- DUE_DT, HOLD_VCHR_FL, PAY_WHEN_PAID_FL
--            @vend_id, 'PAYTO', @po_id , 
              --change KM VCHR grouping 10/23/06--
              @vend_empl_id, NULL, @po_id, 
              NULL, 0, NULL, NULL,
-- Commented out to fix AP Acct Description Error 
--            NULL, 0, 'INTER-COMPANY AP CLEARING', 'INTERCOMPANY AP SUSPENSE', 
              NULL, 0, NULL, NULL,  -- S_INVC_TYPE, SHIP_AMT,  CHK_FY_CD CHK_PD_NO
              NULL, 0, NULL, 0, 
             -- 0, NULL, 'N',  --CR5507 use INVC_POP_DT_FLD as temp location for @FRIDAY
			  0, @FRIDAY, 'N',
              NULL, @in_status_record_num, GETDATE(), 'N',
			  @DIV_16_COMPANY_ID) --CR11812 

      SELECT @out_SystemError = @@ERROR, @NumberOfRecords = @@ROWCOUNT

      IF @out_SystemError > 0  BEGIN GOTO ErrorProcessing END
      IF @NumberOfRecords <> 1 BEGIN GOTO ErrorProcessing END	

      SELECT @HeaderCounter = @HeaderCounter + 1, @VoucherCounter = @VoucherCounter + 1

      --change KM VCHR grouping 10/23/06--
      FETCH NEXT FROM HeaderCursor INTO @vend_id, @vend_empl_id, @po_id, @fy_cd, @pd_no, @sub_pd_no, @FRIDAY

   END /* WHILE (@@fetch_status = 0) */

CLOSE HeaderCursor
DEALLOCATE HeaderCursor 


-- Begin 03/08/2006 TP DEV00000528

-- Insert new vendor employees 

DECLARE EmployeeCursor CURSOR FOR
   SELECT DISTINCT
          a.VENDOR_ID AS VEND_ID,
          a.VEND_EMPL_SERIAL_NUM AS VEND_EMPL_ID,
          a.VEND_EMPL_NAME AS VEND_EMPL_NAME
     FROM dbo.XX_PCLAIM_IN a
          LEFT JOIN
          IMAPS.Deltek.VEND_EMPL b
          ON
          a.VEND_EMPL_SERIAL_NUM = LTRIM(RTRIM(b.VEND_EMPL_ID)) AND -- TP 09/23/2005 
          a.VENDOR_ID = LTRIM(RTRIM(b.VEND_ID))  -- TP 09/22/2005 
    WHERE b.VEND_EMPL_ID is NULL 
      AND a.VENDOR_ERROR = 'N'
-- CP600000324_Begin
     -- AND b.COMPANY_ID = @DIV_16_COMPANY_ID emergency DR1765 CP600000496
-- CP600000324_End

OPEN EmployeeCursor
FETCH NEXT FROM EmployeeCursor INTO @vend_id, @vend_empl_id, @vend_empl_name

WHILE (@@fetch_status = 0)
   BEGIN
      EXEC dbo.XX_ADD_VENDOR_EMPL_SP
         @in_VendorId       = @vend_id,
         @in_VendorEmplId   = @vend_empl_id,
         @in_VEndorEmplName = @vend_empl_name

      FETCH NEXT FROM EmployeeCursor INTO @vend_id, @vend_empl_id, @vend_empl_name
   END

CLOSE EmployeeCursor 
DEALLOCATE EmployeeCursor 

-- End 03/08/2006 TP DEV00000528

-- Group XX_PCLAIM_IN by voucher detail/line requirements (using already created vouchers)
DECLARE DetailCursor CURSOR FOR
   SELECT b.VCHR_NO,
          b.FY_CD,
          b.VEND_ID,
          --change KM VCHR grouping 10/23/06--
          a.VEND_EMPL_SERIAL_NUM,
          b.NOTES,
          a.PROJ_CODE,
			
		  --CR5507
		  b.INVC_POP_DT_FLD as FRIDAY,

		  --DR6201
		  a.PAY_TYPE

     FROM dbo.XX_PCLAIM_IN a
          INNER JOIN
          IMAPS.Deltek.AOPUTLAP_INP_HDR b
          ON
          a.VENDOR_ID = b.VEND_ID   AND
          a.PO_NUMBER = b.PO_ID     AND
          a.FY_CD     = b.FY_CD     AND
          a.PD_NO     = b.PD_NO     AND
          a.SUB_PD_NO = b.SUB_PD_NO AND
          --change KM VCHR grouping 10/23/06--
          a.VEND_EMPL_SERIAL_NUM = b.PAY_VEND_ID AND
		  --CR5507 
		   convert(char(10),dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(a.WORK_DATE),120)=b.INVC_POP_DT_FLD
		  
    WHERE VENDOR_ERROR = @PROCESS_ERRORS_FL
          --change KM VCHR grouping 10/23/06--
    GROUP BY b.VCHR_NO, b.FY_CD, b.VEND_ID, a.VEND_EMPL_SERIAL_NUM, b.PO_ID, b.PD_NO, b.SUB_PD_NO, b.NOTES, a.PROJ_CODE, b.INVC_POP_DT_FLD, a.PAY_TYPE --CR5507 & DR6201
   HAVING b.NOTES = CAST(@in_status_record_num AS varchar)
    ORDER BY b.FY_CD, b.VCHR_NO

OPEN DetailCursor

--change KM VCHR grouping 10/23/06--
FETCH NEXT FROM DetailCursor INTO @vchr_no, @fy_cd, @vend_id, @vend_empl_id, @dummy, @proj_code, @FRIDAY, @pay_type

-- Get initial values for detail/line REC_NO
SELECT @DetailCounter = MAX(REC_NO) + 1
  FROM IMAPS.Deltek.AOPUTLAP_INP_DETL

IF @DetailCounter IS NULL BEGIN SET @DetailCounter = 1 END

SET @LastVchrNo = @vchr_no
SET @LastFY = @fy_cd 	-- fy_cd should be the same for all records in XX_PCLAIM_IN

SET @DetailLineCounter = 1

WHILE (@@fetch_status = 0)
   BEGIN
      -- Begin 02/03/2006 TP DEV0000412

      /*
       * Instead of putting all values to suspense account
       * we attempt to find proper subcontractor / borrowed resource account in PAG
       */
		
/*BEGIN DR2314*/
	  set @account_cd = '??-??-??'

      SELECT @account_cd = ACCT_ID
        FROM IMAPS.Deltek.ACCT_GRP_SETUP		
       WHERE RIGHT(ACCT_ID, @MATCH_LENGTH) = (SELECT TOP 1
                                                     CASE LEFT(VEND_NAME, 3)
                                                        WHEN 'IBM' THEN @NON_DIV16_LABOR_ACCOUNT_MATCH
                                                        ELSE @SUBCONTRACTOR_LABOR_ACCOUNT_MATCH
                                                     END
                                                FROM IMAPS.Deltek.VEND
                                               WHERE VEND_ID = @vend_id
	                                         AND COMPANY_ID = @DIV_16_COMPANY_ID -- CP600000324
                                             )
         AND ACCT_GRP_CD = (SELECT ACCT_GRP_CD
                              FROM IMAPS.Deltek.PROJ
                             WHERE PROJ_ABBRV_CD = @proj_code
                               AND COMPANY_ID = @DIV_16_COMPANY_ID -- CP600000324
                           )
-- Feature 1068 Begin
         AND (ACCT_ID >= '40-00-00' AND ACCT_ID < '90-00-00')
-- Feature 1068 End
/*END DR2314*/

      SELECT @out_SystemError = @@ERROR, @NumberOfRecords = @@ROWCOUNT

      IF @out_SystemError > 0 BEGIN GOTO ErrorProcessing END

-- CP600000413_Begin

      SET @reg_ACCT_ID = @account_cd

		/*begin DR6201*/
		IF @pay_type in (select pay_type from XX_PCLAIM_PAY_TYPE_ACCT_MAP group by pay_type) -- i.e., STB,STW
        BEGIN
               SET @standby_ACCT_ID = '??-??-??'

            SELECT @standby_ACCT_ID = STB_ACCT_ID
              FROM dbo.XX_PCLAIM_PAY_TYPE_ACCT_MAP
             WHERE REG_ACCT_ID = @reg_ACCT_ID
			   AND PAY_TYPE = @pay_type
               AND COMPANY_ID = @DIV_16_COMPANY_ID

            -- Force error if regular account ID is not found in XX_PCLAIM_PAY_TYPE_ACCT_MAP. Do not leave regular account there.
            IF @standby_ACCT_ID IS NULL
               SET @standby_ACCT_ID = '??-??-??'

            SET @account_cd = @standby_ACCT_ID
         END
		/*begin DR6201*/

-- CP600000413_End

      -- End 02/03/2006 TP DEV0000412

      -- For each record in cursor, add voucher detail record
      INSERT INTO IMAPS.Deltek.AOPUTLAP_INP_DETL
            (REC_NO,
             S_STATUS_CD,
             VCHR_NO,
             FY_CD, 
             VCHR_LN_NO,
             ACCT_ID,
             ORG_ID, 
             PROJ_ID,
             REF1_ID,
             REF2_ID, 
             CST_AMT,
             TAXABLE_FL,
             S_TAXABLE_CD,
             SALES_TAX_AMT,
             DISC_AMT,
             USE_TAX_AMT, 
             AP_1099_FL,
             S_AP_1099_TYPE_CD,
             VCHR_LN_DESC, 
             ORG_ABBRV_CD,
             PROJ_ABBRV_CD,
             PROJ_ACCT_ABBRV_CD, 
             NOTES,
             TIME_STAMP,
			 COMPANY_ID)   --CR11812 
     VALUES (@DetailCounter,
             'U',
             @vchr_no,
             @fy_cd,    -- 04/04/2006 TP AP preprocessor update
             @DetailLineCounter,
             @account_cd,
             NULL, -- 02/03/2006 TP DEV0000412
             --change KM VCHR grouping 10/23/06-- --CR5507
             NULL,
             @FRIDAY,
             @vend_empl_id,
             0,
             'N',
             '',  -- CST_AMT, TAXABLE_FL, S_TAXABLE_CD,
             0,
             0,
             0, 
             'N',
             NULL,
             'PCLAIM INTERFACE', 
             '',
             @proj_code,
             @pay_type,  --DR6201
             @WEEK_ENDING_DT,
             GETDATE(),
			 @DIV_16_COMPANY_ID)  --CR11812 
		
      SELECT @out_SystemError = @@ERROR, @NumberOfRecords = @@ROWCOUNT

      IF @out_SystemError > 0  BEGIN GOTO ErrorProcessing END	
      IF @NumberOfRecords <> 1 BEGIN GOTO ErrorProcessing END
	
      --change KM VCHR grouping 10/23/06--
      FETCH NEXT FROM DetailCursor INTO @vchr_no, @fy_cd, @vend_id, @vend_empl_id, @dummy, @proj_code, @FRIDAY, @pay_type

      /*
       * Per AP preprocessor requirement:
       * The Voucher Line Number must start with "1" and be sequential within each
       * unique voucher number and fiscal year combination.
       */
      IF @vchr_no <> @LastVchrNo OR @fy_cd <> @LastFY 
         BEGIN
            SET @LastVchrNo = @vchr_no
            SET @LastFY = @fy_cd
            SET @DetailLineCounter = 1	
         END
      ELSE
         BEGIN
            SET @DetailLineCounter = @DetailLineCounter + 1
         END

      SET @DetailCounter = @DetailCounter + 1

   END /* WHILE (@@fetch_status = 0) */

CLOSE DetailCursor
DEALLOCATE DetailCursor


/* Group XX_PCLAIM_IN by voucher sub line requirements (using already created vouchers and details/lines) */
-- TP 10/27/2005 rows should be odered by VCHR_LN_NO
-- TP 02/17/2005 DEV00000543 @vend_hrs type change

DECLARE LabCursor CURSOR FOR
   SELECT a.VCHR_NO,
          a.FY_CD, 
          b.VCHR_LN_NO,
          c.VEND_EMPL_SERIAL_NUM AS VEND_EMPL_ID, 
          c.PLC AS BILL_LAB_CAT_CD,
          c.HOURS_CHARGED AS VEND_HRS, 
          c.WORK_DATE AS EFFECT_BILL_DT,
          c.PCLAIM_IN_RECORD_NUM
     FROM IMAPS.Deltek.AOPUTLAP_INP_HDR a
          INNER JOIN 
          IMAPS.DELTEK.AOPUTLAP_INP_DETL b
          ON
          a.VCHR_NO =b.VCHR_NO
          INNER JOIN
          dbo.XX_PCLAIM_IN c
          ON
          a.VEND_ID = c.VENDOR_ID AND
          a.PO_ID = c.PO_NUMBER AND
          a.FY_CD = c.FY_CD AND
          a.PD_NO = c.PD_NO AND
          a.SUB_PD_NO = c.SUB_PD_NO AND
          b.PROJ_ABBRV_CD = c.PROJ_CODE AND
          --change KM VCHR grouping 10/23/06--
          RTRIM(a.PAY_VEND_ID) = RTRIM(b.REF2_ID) AND
          RTRIM(a.PAY_VEND_ID) = c.VEND_EMPL_SERIAL_NUM AND
		  --CR5507
		  a.INVC_POP_DT_FLD = b.REF1_ID AND
		  a.INVC_POP_DT_FLD = convert(char(10),dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(c.WORK_DATE),120) AND
		  --DR6201
		  c.PAY_TYPE=b.PROJ_ACCT_ABBRV_CD
    WHERE a.NOTES = CAST(@in_status_record_num AS varchar)
      AND VENDOR_ERROR = @PROCESS_ERRORS_FL
    ORDER BY a.FY_CD, a.VCHR_NO, b.VCHR_LN_NO

OPEN LabCursor
FETCH NEXT FROM LabCursor INTO @vchr_no, @fy_cd, @vchr_ln_no, @vend_empl_id, @bill_lab_cat_cd, @vend_hrs,  @effect_bill_date, @pclaim_in_record_num

-- Get initial values for sub line REC_NO
SELECT @LaborCounter = MAX(REC_NO) + 1
  FROM IMAPS.Deltek.AOPUTLAP_INP_LAB

IF @LaborCounter is NULL BEGIN SET @LaborCounter = 1 END

SET @LastVchrNo = @vchr_no
SET @LastVchrLnNo = @vchr_ln_no -- TP 09/28/2005 subline grouping by line
SET @LastFY = @fy_cd
SET @LaborSublineCounter = 1

WHILE (@@fetch_status = 0)
   BEGIN
      INSERT INTO IMAPS.Deltek.AOPUTLAP_INP_LAB
             (REC_NO,
              S_STATUS_CD,
              FY_CD,
              VCHR_NO,
              VCHR_LN_NO,
              SUB_LN_NO,
              VEND_EMPL_ID,
              GENL_LAB_CAT_CD,
              BILL_LAB_CAT_CD,
              VEND_HRS,
              VEND_AMT, 
              EFFECT_BILL_DT_FLD,
              TIME_STAMP,
			  COMPANY_ID)  --CR11812 

      VALUES (@LaborCounter,
              'U',
              @fy_cd,
              @vchr_no,
              @vchr_ln_no,              -- 04/04/2006 TP - AP preprocessor update
              @LaborSublineCounter,
              @vend_empl_id,
              'VEND',
              @bill_lab_cat_cd,
              @vend_hrs,
              0,
              @effect_bill_date,
              GETDATE(),
			  @DIV_16_COMPANY_ID)  --CR11812
	
      SELECT @out_SystemError = @@ERROR, @NumberOfRecords = @@ROWCOUNT

      IF @out_SystemError > 0  BEGIN GOTO ErrorProcessing END	
      IF @NumberOfRecords <> 1 BEGIN GOTO ErrorProcessing END

      /*
       * We will keep one to one correspondence between XX_PCLAIM_IN records and
       * data in AP preprocessor tables by saving voucher number and subline number.
       */	

      UPDATE dbo.XX_PCLAIM_IN 
         SET SUB_LN_NO  = @LaborSublineCounter, 
             VCHR_NO    = @vchr_no,
             VCHR_LN_NO = @vchr_ln_no -- TP 09/29/2005 subline grouping by line
       WHERE PCLAIM_IN_RECORD_NUM = @pclaim_in_record_num 
	
      FETCH NEXT FROM LabCursor INTO @vchr_no, @fy_cd, @vchr_ln_no, @vend_empl_id, @bill_lab_cat_cd, @vend_hrs, @effect_bill_date, @pclaim_in_record_num

      /*
       * Per AP preprocessor requirement:
       * The Vendor Subline Number must start with "1" and be sequential within each
       * unique voucher, voucher line and fiscal year combination.
       * TP 09/28/2005 subline grouping by line
       */

      IF @vchr_no <> @LastVchrNo OR @fy_cd <> @LastFY OR @vchr_ln_no <> @LastVchrLnNo
         BEGIN
            SET @LastVchrNo   = @vchr_no
            SET @LastVchrLnNo = @vchr_ln_no    -- TP 09/28/2005 subline grouping by line
            SET @LastFY       = @fy_cd
            SET @LaborSublineCounter = 1	
         END
      ELSE
         BEGIN
            SET @LaborSublineCounter = @LaborSublineCounter + 1
         END

      SET @LaborCounter = @LaborCounter + 1

   END /* WHILE (@@fetch_status = 0) */

CLOSE LabCursor 
DEALLOCATE LabCursor 


/*
 * Update NOTES field with VCHR_NO, because import process could change it
 * and we will loose reference between archived data and Costpoint data.
 */

UPDATE IMAPS.Deltek.AOPUTLAP_INP_HDR
   SET NOTES = LTRIM(RTRIM(NOTES)) + ' ' + LTRIM(RTRIM(CAST(VCHR_NO AS char))),
       --change KM VCHR grouping 10/23/06--
	   --CR5507
       PAY_VEND_ID = null,
	   INVC_POP_DT_FLD = null
 WHERE NOTES = CAST(@in_status_record_num AS char)

SELECT @out_SystemError = @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 BEGIN GOTO ErrorProcessing END

--change KM VCHR grouping 10/23/06--
--CR5507
UPDATE IMAPS.Deltek.AOPUTLAP_INP_DETL
   SET REF2_ID = NULL,
	   REF1_ID = NULL,
	   PROJ_ACCT_ABBRV_CD = NULL  --DR6201

-- DEV00000775 TP 05/09/06 - Here the second run starts for records with vendor error
SET @Run2Times = @Run2Times + 1
SET @PROCESS_ERRORS_FL = 'Y'





--BEGIN CR1440
update	imaps.deltek.vend_empl
set		vend_empl_name = (	--get first pclaim vend_empl_name for vend_empl_id
							select top 1 vend_empl_name
							from xx_pclaim_in
							where vend_empl_serial_num=ve.vend_empl_id
						  )
from imaps.deltek.vend_empl ve
where
--vend_empl_id in pclaim table
0 < (select count(1) from xx_pclaim_in where vend_empl_serial_num=ve.vend_empl_id)
and
--vend_empl_name in pclaim table is not the same
0 = (select count(1) from xx_pclaim_in where vend_empl_serial_num=ve.vend_empl_id and vend_empl_name=ve.vend_empl_name)

SELECT @out_SystemError = @@ERROR

IF @out_SystemError > 0 BEGIN GOTO ErrorProcessing END
--END CR1440




END /* WHILE @Run2Times < 2 */

RETURN(0)

ErrorProcessing:

IF Cursor_Status('local', 'HeaderCursor') > 0 
   begin
      CLOSE HeaderCursor 
      DEALLOCATE HeaderCursor 
   end

IF Cursor_Status('local', 'DetailCursor') > 0 
   begin
      CLOSE DetailCursor 
      DEALLOCATE DetailCursor 
   end

IF Cursor_Status('local', 'EmployeeCursorr') > 0 
   begin
      CLOSE EmployeeCursor 
      DEALLOCATE EmployeeCursor 
   end

IF Cursor_Status('local', 'LabCursorr') > 0 
   begin
      CLOSE LabCursor 
      DEALLOCATE LabCursor 
   end

RETURN(1)

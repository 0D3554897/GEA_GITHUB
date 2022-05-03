USE [IMAPSStg]
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_ADD_VENDOR_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_R22_ADD_VENDOR_SP]
GO


CREATE PROCEDURE [dbo].[XX_R22_ADD_VENDOR_SP] 
( 
 @in_VendorId         VARCHAR(12),
 @in_VendorName       VARCHAR(40),
 @in_VendorStreetAdr  VARCHAR(120) = NULL,
 @in_VendorCity       VARCHAR(25) = NULL,
 @in_VendorState      VARCHAR(15) = NULL,
 @in_VendorCountry    VARCHAR(8) = NULL,
 @out_SystemErrorCode INT = NULL OUTPUT,
 @in_VendorStateName  VARCHAR(15) = NULL ,
 @in_VendorLongName   VARCHAR(40) = NULL,
 @in_modified_by      VARCHAR(20),
 @in_rowversion       INT
) AS
BEGIN
/************************************************************************************************
Name:       XX_R22_ADD_VENDOR_SP
Author:     Veera
Created:    08/10/2008
Purpose:    Create vendor and its address.
Parameters: 
	@in_VendorId - vendor id (required)
	@in_VendorName - vendor name (required)
	@in_VendorStreetAdr - vendor street address
	@in_VendorCity - vendor town address
	@in_VendorState - vendor state address 
	@in_VendorCountry - vendor country 
	@out_SystemErrorCode - 
 
Return values : 1 - failure
		0 - success
		
Notes:      This procedure will create a record with received parameters in
            VEND  and VEND_ADDRS tables. If requested id is already present in the VEND table 
            record will not be updated and success status will be returned.
            Combination State and Country is checked against MAIL_STATE table.

            Call example
               EXEC devuser.XX_R22_ADD_VENDOR_SP '325', 'Some nice company',NULL,NULL,'MD','USA'

************************************************************************************************/

DECLARE @DoesVendorExists bit,
	@RecordCount int,
	@SPReturnCode int,
	@VendorStateVerified VARCHAR(15), 
-- default values for vendor
	@defTERMS_DC  varchar(15),
	@defS_VEND_PO_CNTL_CD varchar(1),
	@defFOB_FLD varchar(15),
	@defSHIP_VIA_FLD varchar(15),
	@defHOLD_PMT_FL varchar(1),
	@defCL_DISADV_FL varchar(1),
	@defCL_WOM_OWN_FL varchar(1),
	@defCL_LAB_SRPL_FL varchar(1),
	@defCL_HIST_BL_CLG_FL varchar(1),
	@defPRNT_1099_FL varchar(1),
	@defAP_1099_TAX_ID varchar(20),
	@defCUST_ACCT_FLD varchar(20),
	@defVEND_NOTES varchar(254),
	@defVEND_NAME_EXT varchar(6),
	@defAP_ACCTS_KEY int,
	@defCASH_ACCTS_KEY int,
	@defPAY_WHEN_PAID_FL varchar(1),
	@defAP_CHK_VEND_ID varchar(12),
	@defED_VCH_PAY_VEND_FL varchar(1),
	@defAUTO_VCHR_FL varchar(1),
	@defMODIFIED_BY varchar(20),
	@defRECPT_LN_NO int,
	@defREJ_PCT_RT decimal(5,4),
	@defLATE_RECPT_PCT_RT decimal(5,4),
	@defEARLY_RECPT_PCT_RT decimal(5,4),
	@defLATE_REC_ORIG_RT decimal(5,4),
	@defS_CL_SM_BUS_CD varchar(1),
	@defCHK_MEMO_S varchar(25),
	@defVEND_GRP_CD varchar(6),
	@defS_SUBCTR_PAY_CD varchar(1),
	@defSUBCTR_FL varchar(1),
	@defLIMIT_TRN_CRNCY_FL varchar(1),
	@defLIMIT_PAY_CRNCY_FL varchar(1),
	@defDFLT_RT_GRP_ID varchar(6),
	@defSEP_CHK_FL varchar(1),
	@defPR_VEND_FL varchar(1),
	@defCL_VET_FL varchar(1),
	@defCL_SD_VET_FL varchar(1),
	@defEPROCURE_FL varchar(1),
	@defROWVERSION int,
	-- default values for vendor address     
	@defADDR_DC varchar(10),
	@defPOSTAL_CD VARCHAR(10), 
	@defS_PMT_ADDR_CD varchar(1),
	@defS_ORD_ADDR_CD varchar(1),
	@defPHONE_ID varchar(25),
	@defFAX_ID varchar(25),
	@defOTH_PHONE_ID varchar(25),
	--MODYFIED_BY is the same as for VEND

	@DIV_22_COMPANY_ID varchar(10),

	@defBANK_ACCT_ID_S varchar(17),
	@defS_ACH_TRN_CD varchar(2), 
	@defACTIVE_FL varchar(1),
	@defPRINT_EFT_FL varchar(1)
    
-- initialize vendor values
SELECT  @defTERMS_DC = 'NET 30',
	@defS_VEND_PO_CNTL_CD = 'O',
	@defFOB_FLD = '',
	@defSHIP_VIA_FLD = '',
	@defHOLD_PMT_FL = 'N',
	@defCL_DISADV_FL = 'N',
	@defCL_WOM_OWN_FL = 'N',
	@defCL_LAB_SRPL_FL = 'N',
	@defCL_HIST_BL_CLG_FL = 'N',
	@defPRNT_1099_FL = 'N',
	@defAP_1099_TAX_ID = '',
	@defCUST_ACCT_FLD = '',
	@defVEND_NOTES = '',
	@defVEND_NAME_EXT = '',
	@defPAY_WHEN_PAID_FL = 'N',
	@defAP_CHK_VEND_ID = @in_VendorId,
	@defED_VCH_PAY_VEND_FL = 'N',
	@defAUTO_VCHR_FL = 'N',
--	@defMODIFIED_BY = 'INTERFACE',
	@defMODIFIED_BY = @in_modified_by, 
	@defRECPT_LN_NO = 0,
	@defREJ_PCT_RT = 0,
	@defLATE_RECPT_PCT_RT  = 0,
	@defEARLY_RECPT_PCT_RT  = 0,
	@defLATE_REC_ORIG_RT = 0,
	@defS_CL_SM_BUS_CD = '',
	@defCHK_MEMO_S = '',
	@defVEND_GRP_CD = '',
	@defS_SUBCTR_PAY_CD = 'I',
	@defSUBCTR_FL = 'N',
	@defLIMIT_TRN_CRNCY_FL = 'N',
	@defLIMIT_PAY_CRNCY_FL = 'N',
	@defSEP_CHK_FL = 'N',
	@defPR_VEND_FL = 'N',
	@defCL_VET_FL = 'N',
	@defCL_SD_VET_FL = 'N',
	@defEPROCURE_FL = 'N',
--	@defROWVERSION = 0
	@defROWVERSION = @in_rowversion 


SELECT @DIV_22_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'FIWLR_R22'


SELECT TOP 1
       @defAP_ACCTS_KEY = AP_ACCTS_KEY
  FROM IMAR.DELTEK.DFLT_AP_ACCTS

 WHERE COMPANY_ID = @DIV_22_COMPANY_ID


SELECT TOP 1
       @defCASH_ACCTS_KEY = CASH_ACCTS_KEY
  FROM IMAR.DELTEK.DFLT_CASH_ACCTS
 WHERE COMPANY_ID = @DIV_22_COMPANY_ID


-- initialize vendor address values
SELECT	@defADDR_DC = 'PAYTO',
	@in_VendorStreetAdr = ISNULL(@in_VendorStreetAdr, ''),
	@in_VendorCity = ISNULL(@in_VendorCity , ''),
	@in_VendorLongName = ISNULL(@in_VendorLongName, @in_VendorName), 
	@defPOSTAL_CD = '', 
	@defS_PMT_ADDR_CD = 'D',
	@defS_ORD_ADDR_CD = '',
	@defPHONE_ID = '',
	@defFAX_ID = '',
	@defOTH_PHONE_ID = '',
	--MODIFIED_BY is the same as for VEND

--      @DIV_22_COMPANY_ID = '2',

	@defBANK_ACCT_ID_S = '',
	@defS_ACH_TRN_CD = '', 
	@defACTIVE_FL = 'Y',
	@defPRINT_EFT_FL = 'N'
	
-- Validate that this vendor is not in database
SET @DoesVendorExists = 0

SELECT @DoesVendorExists = 1
  FROM IMAR.DELTEK.VEND
 WHERE VEND_ID = @in_VendorId

   AND COMPANY_ID = @DIV_22_COMPANY_ID


SELECT @out_SystemErrorCode = @@ERROR, @RecordCount = @@ROWCOUNT
IF @out_SystemErrorCode > 0  
	GOTO ErrorProcessing

IF @DoesVendorExists = 1
	RETURN 0
	
BEGIN TRANSACTION VendorEntry

INSERT INTO IMAR.DELTEK.VEND
      (VEND_ID,
       VEND_NAME,
       TERMS_DC,
       S_VEND_PO_CNTL_CD,
       FOB_FLD,
       SHIP_VIA_FLD,
       HOLD_PMT_FL,
       CL_DISADV_FL,
       CL_WOM_OWN_FL,
       CL_LAB_SRPL_FL,
       CL_HIST_BL_CLG_FL,
       PRNT_1099_FL,
       AP_1099_TAX_ID,
       CUST_ACCT_FLD,
       VEND_NOTES,
       VEND_NAME_EXT,
       AP_ACCTS_KEY,
       CASH_ACCTS_KEY,
       PAY_WHEN_PAID_FL,
       AP_CHK_VEND_ID,
       USER_ID,
       ENTRY_DTT,
       ED_VCH_PAY_VEND_FL,
       AUTO_VCHR_FL,
       MODIFIED_BY,
       TIME_STAMP,
       COMPANY_ID, 
       RECPT_LN_NO,
       REJ_PCT_RT,
       LATE_RECPT_PCT_RT,
       EARLY_RECPT_PCT_RT,
       LATE_REC_ORIG_RT,
       S_CL_SM_BUS_CD,
       VEND_LONG_NAME,
       CHK_MEMO_S,
       VEND_GRP_CD ,
       S_SUBCTR_PAY_CD,
       SUBCTR_FL,
       LIMIT_TRN_CRNCY_FL,
       LIMIT_PAY_CRNCY_FL ,
       SEP_CHK_FL,
       PR_VEND_FL,
       CL_VET_FL,
       CL_SD_VET_FL,
       EPROCURE_FL,
       ROWVERSION,
       VEND_APPRVL_CD)
VALUES
      (@in_VendorId,
       LEFT(LTRIM(@in_VendorName), 25),
       @defTERMS_DC,
       @defS_VEND_PO_CNTL_CD,
       @defFOB_FLD,
       @defSHIP_VIA_FLD,
       @defHOLD_PMT_FL,
       @defCL_DISADV_FL,
       @defCL_WOM_OWN_FL ,
       @defCL_LAB_SRPL_FL,
       @defCL_HIST_BL_CLG_FL,
       @defPRNT_1099_FL,
       @defAP_1099_TAX_ID,
       @defCUST_ACCT_FLD,
       @defVEND_NOTES,
       @defVEND_NAME_EXT,
       @defAP_ACCTS_KEY,
       @defCASH_ACCTS_KEY,
       @defPAY_WHEN_PAID_FL,
       @defAP_CHK_VEND_ID,
       @defMODIFIED_BY,
       GETDATE(),
       @defED_VCH_PAY_VEND_FL,
       @defAUTO_VCHR_FL,
       @defMODIFIED_BY,
       GETDATE(),

       @DIV_22_COMPANY_ID,

       @defRECPT_LN_NO,
       @defREJ_PCT_RT,
       @defLATE_RECPT_PCT_RT,
       @defEARLY_RECPT_PCT_RT,
       @defLATE_REC_ORIG_RT,
       @defS_CL_SM_BUS_CD,
--     @in_VendorName,
       @in_VendorLongName, 
       @defCHK_MEMO_S,
       @defVEND_GRP_CD ,
       @defS_SUBCTR_PAY_CD,
       @defSUBCTR_FL,
       @defLIMIT_TRN_CRNCY_FL,
       @defLIMIT_PAY_CRNCY_FL,
       @defSEP_CHK_FL,
       @defPR_VEND_FL,
       @defCL_VET_FL,
       @defCL_SD_VET_FL,
       @defEPROCURE_FL,
       @defROWVERSION, 
       'A')

SELECT @out_SystemErrorCode = @@ERROR, @RecordCount = @@ROWCOUNT

IF @out_SystemErrorCode > 0  
	GOTO ErrorProcessing
	
If @RecordCount <> 1
	GOTO ErrorProcessing
	
IF @in_VendorState IS NULL AND @in_VendorStateName IS Not NULL 
	BEGIN
		SELECT @in_VendorState = MAIL_STATE_DC 
		FROM IMAR.DELTEK.MAIL_STATE
		WHERE MAIL_STATE_NAME = @in_VendorStateName 
		AND COUNTRY_CD = @in_VendorCountry 
	END	

 


/*
 * If mail state is not NULL and country is not NULL and mail state/country pair does not exist in the MAIL_STATE table,
 * then set mail state to NULL.
 */

IF @in_VendorState IS NOT NULL AND @in_VendorCountry IS NOT NULL 
   BEGIN
	SET @VendorStateVerified = NULL

	SELECT @VendorStateVerified = MAIL_STATE_DC 
	FROM IMAR.DELTEK.MAIL_STATE
	WHERE MAIL_STATE_DC = @in_VendorState	
	AND COUNTRY_CD = @in_VendorCountry
   END

INSERT INTO IMAR.DELTEK.VEND_ADDR
      (VEND_ID,
       ADDR_DC,
       LN_1_ADR,
       LN_2_ADR,
       LN_3_ADR,
       CITY_NAME ,
       MAIL_STATE_DC,
       POSTAL_CD,
       COUNTRY_CD,
       S_PMT_ADDR_CD,
       S_ORD_ADDR_CD,       PHONE_ID,
       FAX_ID,
       OTH_PHONE_ID,
       MODIFIED_BY,
       TIME_STAMP,
       COMPANY_ID,
       BANK_ACCT_ID_S,
       S_ACH_TRN_CD,
       ACTIVE_FL,
       PRINT_EFT_FL,
       ROWVERSION)
VALUES( 
       @in_VendorId,
       @defADDR_DC,
       SUBSTRING(@in_VendorStreetAdr, 1, 40),
       SUBSTRING(@in_VendorStreetAdr, 41, 80),
       SUBSTRING(@in_VendorStreetAdr, 81, 120),
       @in_VendorCity ,
       @VendorStateVerified,    
       @defPOSTAL_CD,
       @in_VendorCountry,
       @defS_PMT_ADDR_CD,
       @defS_ORD_ADDR_CD,
       @defPHONE_ID,
       @defFAX_ID,
       @defOTH_PHONE_ID,
       @defMODIFIED_BY,
       GETDATE(),

       @DIV_22_COMPANY_ID,

       @defBANK_ACCT_ID_S,
       @defS_ACH_TRN_CD,
       @defACTIVE_FL,
       @defPRINT_EFT_FL,
       @defROWVERSION)

SELECT @out_SystemErrorCode = @@ERROR, @RecordCount = @@ROWCOUNT
	
IF @out_SystemErrorCode > 0 
	GOTO ErrorProcessing

If @RecordCount <> 1
	GOTO ErrorProcessing

COMMIT TRANSACTION VendorEntry

RETURN 0

ErrorProcessing: 

ROLLBACK TRANSACTION VendorEntry

IF @SPReturnCode IS NOT NULL AND @SPReturnCode <> 0
	RETURN @SPReturnCode
ELSE
	RETURN 1

END


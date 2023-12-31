SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_ADD_VENDOR_EMPL_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_ADD_VENDOR_EMPL_SP]
GO

CREATE PROCEDURE [dbo].[XX_ADD_VENDOR_EMPL_SP] 
( 
 @in_VendorId         VARCHAR(12),
 @in_VendorEmplId     VARCHAR(12),
 @in_VEndorEmplName   VARCHAR(25) = NULL,
 @out_SystemErrorCode int         = NULL OUTPUT
) AS

/************************************************************************************************
Name:       XX_ADD_VENDOR_EMPL_SP
Author:     Tatiana Perova
Created:    08/09/2005
Purpose:   Add new vendor employee
Parameters: 
	@in_VendorId int - vendor id, must be present in VEND table (required)
	@in_VendorEmplId - vendor employee ID (required)
	@in_VEndorEmplName - vendor employee name
	@out_SystemErrorCode 
 
Return values : 1 - failure
		0 - success
		
Notes:      This procedure will create a record with received parameters in VEND_EMPL tables.
            If requested employee is already present in the VEND table 
            record will not be updated and success status will be returned. 

            Call example
               EXEC devuser.XX_ADD_VENDOR_EMPL_SP '325', '0d3737', C:\ddd\eee.xml'

CP600000324 05/27/2008 - Reference BP&S Service Request CR1543
            Costpoint multi-company fix (one instance).
************************************************************************************************/

DECLARE @DoesVendorEmplExists bit,
        @RecordCount          int,
	@defMODIFIED_BY       varchar(20),
	@defROWVERSION        int,
-- CP600000324_Begin
        @DIV_16_COMPANY_ID    varchar(10)
-- CP600000324_End

-- initialize default values
SET @defMODIFIED_BY = 'INTERFACE'
SET @defROWVERSION = 0

-- CP600000324_Begin
SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'PCLAIM'
-- CP600000324_End

-- Validate that this vendor employee is not in database
SET @DoesVendorEmplExists = 0

SELECT @DoesVendorEmplExists = COUNT(*)
  FROM IMAPS.Deltek.VEND_EMPL
 WHERE VEND_ID = @in_VendorId
   AND VEND_EMPL_ID = @in_VendorEmplId
-- CP600000324_Begin
   AND COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000324_End

IF @DoesVendorEmplExists = 1
   RETURN 0

IF @DoesVendorEmplExists > 1
   GOTO ErrorProcessing

INSERT INTO IMAPS.Deltek.VEND_EMPL
(VEND_EMPL_ID,
VEND_ID,
VEND_EMPL_NAME,
MODIFIED_BY,
TIME_STAMP,
COMPANY_ID,
ROWVERSION
)
VALUES (
       @in_VendorEmplId,
       @in_VendorId,
       ISNULL(@in_VendorEmplName, @in_VendorEmplId),
       @defMODIFIED_BY,
       GETDATE(),
-- CP600000324_Begin
       @DIV_16_COMPANY_ID,
-- CP600000324_End
       @defROWVERSION
)

SELECT @out_SystemErrorCode = @@ERROR, @RecordCount = @@ROWCOUNT

IF @out_SystemErrorCode > 0  
   GOTO ErrorProcessing
	
IF @RecordCount <> 1
   GOTO ErrorProcessing

RETURN 0 -- TP  DEV00001023

ErrorProcessing: 

RETURN 1 -- TP  DEV00001023

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


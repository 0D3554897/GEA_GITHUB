SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_AR_CCIS_VALIDATE_RECPTS_SP    Script Date: 04/12/2006 10:58:24 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_AR_CCIS_VALIDATE_RECPTS_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_AR_CCIS_VALIDATE_RECPTS_SP]
GO






CREATE PROCEDURE dbo.XX_AR_CCIS_VALIDATE_RECPTS_SP
(
@in_STATUS_RECORD_NUM     integer,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS
/****************************************************************************************************
Name:       XX_AR_CCIS_VALIDATE_RECPTS_SP
Author:      KM
Created:    12/2005
Purpose:    VALIDATES THE DATA IN CASH_RECPTS STAGING TABLES
Parameters: 
Result Set: None
Notes:

exec xx_ar_ccis_validate_recpts_sp
	@in_status_record_num = 86

select * from imaps1.deltek.ar_hdr_hs
select * from imaps1.deltek.bill_invc_hdr_hs

NOTHING IS PASSING VALIDATION

select c.addr_dc from xx_ar_ccis_activity a
inner join bprtest.deltek.ar_hdr_hs c
on right(a.invno, 5) = right(c.invc_id, 5)

select *
from (xx_ar_ccis_closed_invoices a
	inner join
     xx_ar_ccis_activity b
	on (a.activ_key = b.activ_key))
	inner join bprtest.deltek.ar_hdr_hs c
	on (b.INVNO = RIGHT(c.INVC_ID, 5) and c.ADDR_DC = b.CUSTNO)


****************************************************************************************************/
BEGIN

DECLARE	@SP_NAME           	sysname,
        @IMAPS_error_number     integer,
        @SQLServer_error_code   integer,
        @row_count              integer,
        @error_msg_placeholder1 sysname,
        @error_msg_placeholder2 sysname,
        @INTERFACE_NAME	 	varchar(5)
-- set local constants
SET @SP_NAME = 'XX_AR_CCIS_VALIDATE_RECPTS_SP'
SET @INTERFACE_NAME = 'AR_COLLECTION'



--5. VALIDATE BALANCING ENTRIES OF XX_AR_CASH_RECPT_TRN
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'VALIDATE BALANCE OF'
SET @error_msg_placeholder2 = 'XX_AR_CASH_RECPT_TRN'
DECLARE @SUMMARY_AMT decimal(14, 2)

SELECT 	@SUMMARY_AMT = SUM(TRN_AMT)
FROM	DBO.XX_AR_CASH_RECPT_TRN

IF @SUMMARY_AMT <> .00
	 GOTO BL_ERROR_HANDLER


-- CHANGE KM
-- THIS IS ALREADY CHECKED BY THE TRIGGER ON XX_AR_CASH_RECPT_TRN
/*
--6. VALIDATE ACCOUNT_ID EXISTS FOR AR Cleared
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'VALIDATE THAT THE ACCT_ID'
SET @error_msg_placeholder2 = 'FOR CLEARED A/R EXISTS'

SELECT ACCT_ID FROM IMAPS.DELTEK.ACCT
WHERE ACCT_ID = '20-08-30'

IF @@ROWCOUNT = 0 GOTO BL_ERROR_HANDLER*/


RETURN(0)

BL_ERROR_HANDLER:

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_number,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)


END






GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


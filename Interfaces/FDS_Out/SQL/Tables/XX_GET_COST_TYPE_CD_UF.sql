USE [IMAPSStg]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_GET_COST_TYPE_CD_UF]    Script Date: 5/4/2022 3:19:11 PM ******/
DROP FUNCTION [dbo].[XX_GET_COST_TYPE_CD_UF]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_GET_COST_TYPE_CD_UF]    Script Date: 5/4/2022 3:19:12 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[XX_GET_COST_TYPE_CD_UF](@in_acct_id varchar(8))  
RETURNS varchar(3) AS  
BEGIN
/************************************************************************************************  
Name:       	[XX_GET_COST_TYPE_CD_UF]
Author:     	GA
Created:    	05/2022 

CR 13721 - Get COST TYPE FOR 999 FILE FROM ACCOUNT ID
RETURN VALUE ?? MEANS WE'VE ADDED A NEW ONE AND NEED TO CHANGE THIS CODE

************************************************************************************************/

DECLARE @COST_TYPE varchar(3)

SELECT @COST_TYPE = 
	CASE 
	 WHEN LEFT(ACCT_ID,2) = '41' THEN 'LAB'  -- LABOR
	 WHEN LEFT(ACCT_ID,2) = '42' THEN 'TRV'  -- TRAVEL
	 WHEN LEFT(ACCT_ID,2) = '43' THEN 'ODC'  -- OTHER DIRECT COST
	 WHEN LEFT(ACCT_ID,2) = '48' THEN 'SCH'  -- SCH
	 WHEN LEFT(ACCT_ID,2) = '49' THEN 'CSP'  -- CSP
	 ELSE '   '
	END
	FROM .IMAPSSTG.DBO.XX_IMAPS_INV_OUT_DTL 
	WHERE ACCT_ID = @in_acct_id

RETURN isnull(@COST_TYPE,'   ')

END


GO



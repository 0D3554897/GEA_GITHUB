USE [IMAPSStg]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_GET_CONTRACT_TYPE_CD_UF]    Script Date: 7/26/2022 1:33:31 PM ******/
DROP FUNCTION [dbo].[XX_GET_CONTRACT_TYPE_CD_UF]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_GET_CONTRACT_TYPE_CD_UF]    Script Date: 7/26/2022 1:33:31 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE FUNCTION [dbo].[XX_GET_CONTRACT_TYPE_CD_UF](@in_proj_id varchar(30))  
RETURNS varchar(2) AS  
BEGIN
/************************************************************************************************  
Name:       	[XX_GET_CONTRACT_TYPE_CD_UF]
Author:     	GA
Created:    	05/2022 

CR 13721 - Get SERVICES CONTRACT TYPE FOR 999 FILE FROM PROJ_ID
RETURN VALUE ?? MEANS WE'VE ADDED A NEW ONE AND NEED TO CHANGE THIS CODE

************************************************************************************************/

DECLARE @BILL_FORMULA varchar(2)

SELECT @BILL_FORMULA = 
	CASE 
	 WHEN LEFT(S_BILL_FORMULA_CD,1) = 'C' THEN 'CP'  -- COST PLUS
	 WHEN LEFT(S_BILL_FORMULA_CD,3) = 'LLR' THEN 'HR'  -- HOURLY
	 WHEN LEFT(S_BILL_FORMULA_CD,2) = 'RS' THEN 'HR'  -- HOURLY
	 WHEN S_BILL_FORMULA_CD = 'NONE' THEN 'FP'  -- FIXED PRICE
	 WHEN S_BILL_FORMULA_CD = 'UNIT' THEN 'UP'  -- UNIT PRICE
	 ELSE replicate(char(160),2)
	END
	FROM imaps.dbo.XX_STAGE_PROJ_BILL_INFO  
	WHERE INVC_PROJ_ID = @in_proj_id

RETURN isnull(@BILL_FORMULA,replicate(char(160),2))

END


GO



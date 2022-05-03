USE [IMAPSStg]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_GET_PRODUCT_ID_UF]    Script Date: 4/15/2020 4:37:14 PM ******/
DROP FUNCTION [dbo].[XX_GET_PRODUCT_ID_UF]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_GET_PRODUCT_ID_UF]    Script Date: 4/15/2020 4:37:14 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE FUNCTION [dbo].[XX_GET_PRODUCT_ID_UF] 
(@in_PROJ_ID varchar(30))
RETURNS varchar(8) AS  
BEGIN 
DECLARE  
@returnvalue varchar(8)

/************************************************************************************************  
Name:       XX_GET_PRODUCT_ID_UF
Author:     	KM
Created:    	11/01/2005  
Purpose:  Conversion function called by FDS Interface

Parameters: 
	
**************************************************************************************************/ 

--check UDEF for PRODUCT_ID
SELECT 	@returnvalue = UDEF_TXT
FROM	IMAPS.DELTEK.GENL_UDEF
WHERE 	GENL_ID = @in_PROJ_ID
AND	S_TABLE_ID = 'PJ'
AND	UDEF_LBL_KEY = 35

--else use Default value
IF 	@returnvalue IS NULL
BEGIN
	SELECT 	@returnvalue = PARAMETER_VALUE
	FROM	dbo.XX_PROCESSING_PARAMETERS
	WHERE	PARAMETER_NAME = 'DFLT_PRODUCT_ID'
	AND 	INTERFACE_NAME_CD = 'FDS'
END	


RETURN  @returnvalue
END



GO



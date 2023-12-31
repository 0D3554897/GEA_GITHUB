SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  User Defined Function dbo.XX_GET_GSA_UF    Script Date: 1/13/2006 11:33:54 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_GET_GSA_UF]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[XX_GET_GSA_UF]
GO



CREATE FUNCTION [dbo].[XX_GET_GSA_UF] 
(@in_PROJ_ID varchar(30))
RETURNS char(1) AS
 
BEGIN 

/************************************************************************************************  
Name:       XX_GET_GSA_UF
Author:     KM
Created:    01/13/2006
Purpose:    Conversion function called by FDS Interface

Parameters: 
	
Version:    1.0

Notes:

CP600000325 04/25/2008 (BP&S Change Request No. CR1543)
            Costpoint multi-company fix (one instance).
**************************************************************************************************/ 

DECLARE @returnvalue       char(1),
        @row_count         int,
        @DIV_16_COMPANY_ID varchar(10)

-- CP600000325_Begin
SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'FDS/CCS'
-- CP600000325_End

SELECT @row_count = count(GENL_ID)
FROM	IMAPS.Deltek.GENL_UDEF
WHERE	S_TABLE_ID = 'PJ'
AND	GENL_ID = @in_PROJ_ID
AND	UDEF_LBL_KEY = 12
-- CP600000325_Begin
AND	COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000325_End

IF @row_count = 0
BEGIN
	SET @returnvalue = 'G'
END
ELSE
BEGIN
	SET @returnvalue = 'O'
END


RETURN  @returnvalue

END







GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


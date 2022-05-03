SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  User Defined Function dbo.XX_GET_CONTRACT_UF    Script Date: 07/24/2006 11:15:40 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_GET_CONTRACT_UF]') and xtype in (N'FN', N'IF', N'TF'))
   drop function [dbo].[XX_GET_CONTRACT_UF]
GO

CREATE FUNCTION [dbo].[XX_GET_CONTRACT_UF] 
(@in_PROJ_ID varchar(30))

RETURNS varchar(20) AS

BEGIN 

/************************************************************************************************  
Name:       XX_GET_CONTRACT_UF
Author:     KM
Created:    12/01/2005  
Purpose:    Conversion function called by FDS Interface

Parameters: 

Notes:

CP600000325 04/25/2008 (BP&S Change Request No. CR1543)
            Costpoint multi-company fix (one instance).
**************************************************************************************************/ 

DECLARE @returnvalue       varchar(30),
        @PROJ_L1           varchar(30),
        @DIV_16_COMPANY_ID varchar(10)

-- CP600000325_Begin
SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'FDS/CCS'
-- CP600000325_End

SELECT	@PROJ_L1 = L1_PROJ_SEG_ID 
FROM	IMAPS.Deltek.PROJ
WHERE	PROJ_ID = @in_PROJ_ID
-- CP600000325_Begin
AND	COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000325_End

IF LEFT(@PROJ_L1, 4) = 'MOSS'
BEGIN
	SET @returnvalue = 'PSMOS'
END
ELSE
BEGIN
	SET @returnvalue = 'PS' + SUBSTRING(@PROJ_L1, 2, (SELECT LEN(@PROJ_L1)))
END


RETURN @returnvalue

END





GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


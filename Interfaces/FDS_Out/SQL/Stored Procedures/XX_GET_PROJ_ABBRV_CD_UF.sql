SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  User Defined Function dbo.XX_GET_PROJ_ABBRV_CD_UF    Script Date: 10/04/2006 9:33:56 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_GET_PROJ_ABBRV_CD_UF]') and xtype in (N'FN', N'IF', N'TF'))
   drop function [dbo].[XX_GET_PROJ_ABBRV_CD_UF]
GO





CREATE FUNCTION [dbo].[XX_GET_PROJ_ABBRV_CD_UF] 
(@in_PROJ_ID varchar(30))
RETURNS varchar(6) AS

BEGIN

/************************************************************************************************  
Name:       XX_GET_PROJ_ABBRV_CD_UF
Author:     KM
Created:    09/08/2006
Purpose:    Conversion function called by FDS Interface

Parameters:

Notes:

CP600000325 04/25/2008 (BP&S Change Request No. CR1543)
            Costpoint multi-company fix (one instance).
**************************************************************************************************/ 

DECLARE @returnvalue       varchar(6),
        @DIV_16_COMPANY_ID varchar(10)

-- CP600000325_Begin
SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'FDS/CCS'
-- CP600000325_End


SELECT @returnvalue = PROJ_ABBRV_CD 
FROM 	IMAPS.Deltek.PROJ
WHERE 	PROJ_ID = @in_PROJ_ID
-- CP600000325_Begin
AND	COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000325_End

RETURN @returnvalue

END




GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


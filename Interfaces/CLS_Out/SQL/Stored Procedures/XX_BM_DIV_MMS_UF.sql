USE [IMAPSStg]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_BM_DIV_MMS_UF]    Script Date: 4/27/2022 4:56:23 PM ******/
DROP FUNCTION [dbo].[XX_BM_DIV_MMS_UF]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_BM_DIV_MMS_UF]    Script Date: 4/27/2022 4:56:23 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[XX_BM_DIV_MMS_UF] (
@in_val varchar(3),
@in_typ varchar(3)) 
RETURNS VARCHAR(4) 
AS 

/******************************************************************
CREATED BY:   gea
USAGE : select XX_BM_DIV_MMS_UF('VALUE', 'MAJ')....
DATE CREATED: 4/27/2020
PURPOSE : This function takes a value and converts it into
           business measurement division major, minor, subminor, 
		   whichever is specified, or null if not found
		   or wrong specification is provided. 

		   IN_VAL IS THE 3 CHARACTER LOOKUP VALUE
		     WHICH MUST EXIST AS PARAMETER NAME IN 
			 XX_PROCESSING_PARAMETERS
		   IN_TYP ACCEPTABLE VALUES ARE MAJ, MIN, OR SUB

******************************************************************/


    BEGIN

	DECLARE @PP_VAL VARCHAR(4)
	
	SELECT @PP_VAL = CASE @in_typ
	 WHEN 'MAJ' THEN LEFT(PARAMETER_VALUE,3)
	 WHEN 'MIN' THEN SUBSTRING(PARAMETER_VALUE,4,4)
	 WHEN 'SUB' THEN RIGHT(PARAMETER_VALUE,4)
	 ELSE NULL
	 END
	FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
	WHERE INTERFACE_NAME_CD = 'CLS'
	AND SUBSTRING(PARAMETER_NAME,3,1) IN ('3','4')
	AND PARAMETER_NAME = @in_val


 RETURN @PP_VAL

END
GO



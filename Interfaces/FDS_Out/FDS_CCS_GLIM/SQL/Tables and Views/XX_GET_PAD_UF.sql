USE [IMAPSStg]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_GET_PAD_UF]    Script Date: 11/30/2022 5:50:20 PM ******/
DROP FUNCTION [dbo].[XX_GET_PAD_UF]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_GET_PAD_UF]    Script Date: 11/30/2022 5:50:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[XX_GET_PAD_UF]() 
RETURNS INT 
AS 

/******************************************************************
CREATED BY:   gea
USAGE : select XX_GET_PAD_UF()....
DATE CREATED: 6/3/2020
PURPOSE : This function returns padding character value 
			to use in views from xx_processing_parameters
******************************************************************/


BEGIN

	DECLARE @varPadChar INT
	
	SELECT @varPadChar=CAST(PARAMETER_VALUE AS INT) FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS WHERE INTERFACE_NAME_CD = 'UTIL' AND PARAMETER_NAME = 'PAD_CHAR'

	RETURN @varPadChar

END
GO



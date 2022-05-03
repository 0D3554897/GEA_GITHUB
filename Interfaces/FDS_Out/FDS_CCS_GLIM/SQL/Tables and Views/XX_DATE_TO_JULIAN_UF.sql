USE [IMAPSStg]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_DATE_TO_JULIAN_UF]    Script Date: 6/3/2020 2:53:42 PM ******/
DROP FUNCTION [dbo].[XX_DATE_TO_JULIAN_UF]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_DATE_TO_JULIAN_UF]    Script Date: 6/3/2020 2:53:42 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[XX_DATE_TO_JULIAN_UF] (@in_val datetime) 
RETURNS VARCHAR(5) 
AS 

/******************************************************************
CREATED BY:   gea
USAGE : select XX_DATE_TO_JULIAN_UF(GETDATE() OR SOMEDATE)....
DATE CREATED: 6/3/2020
PURPOSE : This function takes a date and converts it into
           two digit year + number of days since Jan 1. 

******************************************************************/


    BEGIN

	DECLARE @jul_dt VARCHAR(5)
	
	SELECT @jul_dt=RIGHT(CAST(YEAR(@in_val) AS CHAR(4)),2) + RIGHT('000' + CAST(DATEPART(dy, @in_val) AS varchar(3)),3)


 RETURN @jul_dt

END
GO



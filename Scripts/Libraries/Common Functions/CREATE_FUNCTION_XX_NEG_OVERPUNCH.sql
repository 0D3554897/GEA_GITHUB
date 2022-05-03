IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_NEG_OVERPUNCH_UF]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[XX_NEG_OVERPUNCH_UF]
GO


CREATE FUNCTION dbo.XX_NEG_OVERPUNCH_UF (@in_val VARCHAR(20)) 
RETURNS VARCHAR(20) 
AS 

/******************************************************************
CREATED BY:   gea
DATE CREATED: 9/4/2018
PURPOSE : This function takes a formatted numeric string for CLS
           and creates the 999 file overpunch value required by 
           the IBM mainframe for negative numbers.

******************************************************************/


    BEGIN
	DECLARE @ovr_val VARCHAR(20)
	


	SET @ovr_val = case LEFT(@in_val,1) WHEN '-' THEN REPLACE(LEFT(@in_val,len(@in_val)-1),'-','0')  + CASE RIGHT(@in_val,1) 
	WHEN '0' THEN '}'
	WHEN '1' THEN 'J'
	WHEN '2' THEN 'K'
	WHEN '3' THEN 'L'
	WHEN '4' THEN 'M'
	WHEN '5' THEN 'N'
	WHEN '6' THEN 'O'
	WHEN '7' THEN 'P'
	WHEN '8' THEN 'Q'
	ELSE 'R'
	END
	ELSE @in_val
	END

 RETURN @ovr_val
 
END
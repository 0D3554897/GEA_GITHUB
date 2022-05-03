IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_FULL_OVERPUNCH_UF]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[XX_FULL_OVERPUNCH_UF]
GO


CREATE FUNCTION dbo.XX_FULL_OVERPUNCH_UF (@in_val VARCHAR(20)) 
RETURNS VARCHAR(20) 
AS 

/******************************************************************
CREATED BY:   gea
USAGE : select xx_full_overpunch_uf(12345)....
DATE CREATED: 10/11/2018
PURPOSE : This function takes a formatted numeric string for CLS
           and creates the 999 file overpunch value required by 
           the IBM mainframe for positive and negative numbers.

******************************************************************/


    BEGIN
	DECLARE @ovr_val VARCHAR(20)
	


	SET @ovr_val = case LEFT(@in_val,1) 
		WHEN '-' THEN REPLACE(LEFT(@in_val,len(@in_val)-1),'-','0') + CASE RIGHT(@in_val,1) 
			WHEN '0' THEN '}'
			WHEN '1' THEN 'J'
			WHEN '2' THEN 'K'
			WHEN '3' THEN 'L'
			WHEN '4' THEN 'M'
			WHEN '5' THEN 'N'
			WHEN '6' THEN 'O'
			WHEN '7' THEN 'P'
			WHEN '8' THEN 'Q'
			WHEN '9' THEN 'R'
			END
		ELSE REPLACE(LEFT(@in_val,len(@in_val)-1),'-','0') + CASE RIGHT(@in_val,1) 
			WHEN '0' THEN '{'
			WHEN '1' THEN 'A'
			WHEN '2' THEN 'B'
			WHEN '3' THEN 'C'
			WHEN '4' THEN 'D'
			WHEN '5' THEN 'E'
			WHEN '6' THEN 'F'
			WHEN '7' THEN 'G'
			WHEN '8' THEN 'H'
			WHEN '9' THEN 'I'	
		END
	END

 RETURN @ovr_val
 
END
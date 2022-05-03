IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_UN_OVERPUNCH_UF]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[XX_UN_OVERPUNCH_UF]
GO


CREATE FUNCTION dbo.XX_UN_OVERPUNCH_UF (@in_val VARCHAR(20)) 
RETURNS VARCHAR(20) 
AS 

/******************************************************************
CREATED BY:   gea
USAGE : select xx_un_overpunch_uf(1234G)....
DATE CREATED: 10/11/2018
PURPOSE : This function takes the overpunched value and decodes it
******************************************************************/


    BEGIN
	DECLARE @ovr_val VARCHAR(20)
	

	SET @ovr_val = case RIGHT(@in_val,1) 
			WHEN '}' THEN '-' + LEFT(@in_val,len(@in_val)-1) + '0'
			WHEN 'J' THEN '-' + LEFT(@in_val,len(@in_val)-1) + '1'
			WHEN 'K' THEN '-' + LEFT(@in_val,len(@in_val)-1) + '2'
			WHEN 'L' THEN '-' + LEFT(@in_val,len(@in_val)-1) + '3'
			WHEN 'M' THEN '-' + LEFT(@in_val,len(@in_val)-1) + '4'
			WHEN 'N' THEN '-' + LEFT(@in_val,len(@in_val)-1) + '5'
			WHEN 'O' THEN '-' + LEFT(@in_val,len(@in_val)-1) + '6'
			WHEN 'P' THEN '-' + LEFT(@in_val,len(@in_val)-1) + '7'
			WHEN 'Q' THEN '-' + LEFT(@in_val,len(@in_val)-1) + '8'
			WHEN 'R' THEN '-' + LEFT(@in_val,len(@in_val)-1) + '9'
			WHEN '{' THEN LEFT(@in_val,len(@in_val)-1) + '0'
			WHEN 'A' THEN LEFT(@in_val,len(@in_val)-1) + '1'
			WHEN 'B' THEN LEFT(@in_val,len(@in_val)-1) + '2'
			WHEN 'C' THEN LEFT(@in_val,len(@in_val)-1) + '3'
			WHEN 'D' THEN LEFT(@in_val,len(@in_val)-1) + '4'
			WHEN 'E' THEN LEFT(@in_val,len(@in_val)-1) + '5'
			WHEN 'F' THEN LEFT(@in_val,len(@in_val)-1) + '6'
			WHEN 'G' THEN LEFT(@in_val,len(@in_val)-1) + '7'
			WHEN 'H' THEN LEFT(@in_val,len(@in_val)-1) + '8'
			WHEN 'I' THEN LEFT(@in_val,len(@in_val)-1) + '9'
			ELSE @in_val	
		END  --CASE


 RETURN @ovr_val
 
END
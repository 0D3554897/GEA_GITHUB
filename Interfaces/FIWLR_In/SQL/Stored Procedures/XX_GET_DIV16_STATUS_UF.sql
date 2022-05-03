USE [IMAPSStg]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_GET_DIV16_STATUS_UF]    Script Date: 11/15/2016 11:35:40 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_GET_DIV16_STATUS_UF]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[XX_GET_DIV16_STATUS_UF]
GO

USE [IMAPSStg]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_GET_DIV16_STATUS_UF]    Script Date: 11/15/2016 11:35:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[XX_GET_DIV16_STATUS_UF] 
(@in_empl_id varchar(6), @in_effect_dt datetime)
RETURNS char(1) AS  
BEGIN 


/************************************************************************************************  
Name:       XX_GET_DIV16_STATUS
Author:     	KM
Created:    	03/07/2007
Purpose:  Returns Y if employee was in Division 16 for a given date
Parameters: 

CR6295 - Div1P - KM - 2013-04-29
For the purposes of this function (used by FIWLR and N16 interfaces), evaluate 1P as if it is the same as 16)

CR8762 - Div2G - TP - 2016-11-03
For the purposes of this function (used by FIWLR and N16 interfaces), evaluate 2G as if it is the same as 16
**************************************************************************************************/ 
	
	
	declare @empl_div char(2)
	
	select TOP 1 @empl_div = DIVISION
	from XX_CERIS_DIV16_STATUS
	where empl_id = @in_empl_id
	and division_start_dt <= @in_effect_dt
	order by creation_dt desc
	
	if (@empl_div in ('16','1P','2G')) return 'Y'
	
	return 'N'

END



GO


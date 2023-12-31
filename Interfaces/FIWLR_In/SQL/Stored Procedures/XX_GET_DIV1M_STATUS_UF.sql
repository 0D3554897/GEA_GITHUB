use imapsstg

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  User Defined Function dbo.XX_GET_DIV1M_STATUS_UF    Script Date: 03/07/2007 3:02:41 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_GET_DIV1M_STATUS_UF]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[XX_GET_DIV1M_STATUS_UF]
GO


CREATE FUNCTION [dbo].[XX_GET_DIV1M_STATUS_UF] 
(@in_empl_id varchar(6), @in_effect_dt datetime)
RETURNS char(1) AS  
BEGIN 


/************************************************************************************************  
Name:       XX_GET_DIV1M_STATUS
Author:     	KM
Created:    	2010-09-09
Purpose:  Returns Y if employee was in Division 1M for a given date
Parameters: 
**************************************************************************************************/ 
	
	
	declare @empl_div char(2)
	
	select TOP 1 @empl_div = DIVISION
	from XX_CERIS_DIV16_STATUS
	where empl_id = @in_empl_id
	and division_start_dt <= @in_effect_dt
	order by creation_dt desc
	
	if @empl_div = '1M' return 'Y'
	
	return 'N'

END


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


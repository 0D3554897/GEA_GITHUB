SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  User Defined Function dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF    Script Date: 10/04/2006 11:23:30 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF]
GO

CREATE FUNCTION [dbo].[XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF] (@in_date datetime)  
RETURNS datetime AS  
BEGIN 
/************************************************************************************************  
Name:       XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF
Author:     	Tatiana Perova
Created:    	01/13/2006
Purpose:  Conversion function called by Utilization Interface. Should return Friday  (end of
timesheet week) for the date entered.  Like return 01/27/2006 for 01/21/2006.

Parameters: 
	
Version: 	1.0
Notes:

**************************************************************************************************/ 
return (select DATEADD(dd, @@DATEFIRST - 3,
DATEADD(wk, DATEDIFF(wk,0, @in_date + @@DATEFIRST - 6), 0)))

END




GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


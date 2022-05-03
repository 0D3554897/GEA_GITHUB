use imapsstg
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_GET_week_days_in_period_UF]') and xtype in (N'FN', N'IF', N'TF'))
   drop function [dbo].[XX_GET_week_days_in_period_UF]
GO

CREATE FUNCTION [dbo].[XX_GET_week_days_in_period_UF] (@start_date datetime, @end_date datetime)
  RETURNS INT
  AS
  BEGIN
/************************************************************************************************  
Name:       XX_GET_week_days_in_period_UF
Author:     KM
Created:    2012-09-25 
Purpose:    Used by CERIS interface to determine number of week days in calendar year
			(and thus, number of available work hours)

Parameters: @start_date, @end_date

Notes: Initial version for CR4885
**************************************************************************************************/ 
	  --logic from 
	  --http://www.codersrevolution.com/index.cfm/2008/10/15/SQL-Server-How-Many-WorkWeek-Days-In-Date-Range
      
      -- If the start date is a weekend, move it foward to the next weekday
      WHILE datepart(weekday, @start_date) in (1,7) -- Sunday, Saturday
      BEGIN
          SET @start_date = dateadd(d,1,@start_date)
      END
      
      -- If the end date is a weekend, move it back to the last weekday
      WHILE datepart(weekday, @end_date) in (1,7) -- Sunday, Saturday
      BEGIN
          SET @end_date = dateadd(d,-1,@end_date)
      END
      
      -- Weekdays are total days in perion minus weekends. (2 days per weekend)
      -- Extra weekend days were trimmed off the period above.
      -- I am adding an extra day to the total to make it inclusive.
      --     i.e. 1/1/2008 to 1/1/2008 is one day because it includes the 1st
      RETURN (datediff(d,@start_date,@end_date) + 1) - (datediff(ww,@start_date,@end_date) * 2)
  
  END

GO


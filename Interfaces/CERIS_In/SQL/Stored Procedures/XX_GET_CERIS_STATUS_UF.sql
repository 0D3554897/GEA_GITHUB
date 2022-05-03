USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[XX_GET_CERIS_STATUS_UF] 
(@in_empl_id varchar(6), @in_effect_dt datetime)
RETURNS char(3) AS
  
BEGIN 


/************************************************************************************************************  
Name:       XX_GET_CERIS_STATUS_UF
Purpose:    Returns rtrim(reg_temp)+rtrim(status)+rtrim(stat3) from CERIS record for Employee for given date
Parameters: 
*************************************************************************************************************/

	declare @ceris_status char(3)


	select top 1 @ceris_status = rtrim(reg_temp)+rtrim(status)+rtrim(stat3)
	
	from xx_ceris_hist_archival 
	
	where empl_id=@in_empl_id
	and cast(empl_stat_dt as datetime) <= @in_effect_dt
	and 
	(
	case 
	when empl_stat3_dt is null then cast(empl_stat_dt as datetime) 
	else cast(empl_stat3_dt as datetime)
	end
	) <= @in_effect_dt
	order by created_dt desc
	
	return @ceris_status


END

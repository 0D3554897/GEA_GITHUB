USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CHECK_JOB_LAST_RUN_SP]    Script Date: 08/28/2018 17:02:30 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_CHECK_JOB_LAST_RUN_SP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[XX_CHECK_JOB_LAST_RUN_SP]
GO

USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CHECK_JOB_LAST_RUN_SP]    Script Date: 08/28/2018 17:02:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[XX_CHECK_JOB_LAST_RUN_SP] 
(
@in_job_name      varchar(500),
@in_days		  int
)
AS

/************************************************************************************************  
Name:       	XX_CHECK_JOB_LAST_RUN_SP  
Author:     	GEA
Created:    	03/2018  
Purpose:    	MAKE SURE JOB WAS RUN LAST MONTH BEFORE RUNNING THIS MONTH CLSDOWN

Prerequisites: 	none 

Parameters: 
	Input: 	@in_job_name,  @in_days
	Output: none   

Version: 	1.0
Notes:      	

************************************************************************************************/

BEGIN

		DECLARE @LAST INT

		select top 1 
		--v.name, j.step_id, h.run_status, h.run_date
		--,CAST(LEFT(cast(h.run_date as varchar),4)+'-'+ SUBSTRING(cast(h.run_date as varchar),5,2)+'-'+ RIGHT(cast(h.run_date as varchar),2) as date)
		@LAST = DATEDIFF(DAY, CAST(LEFT(cast(h.run_date as varchar),4)+'-'+ SUBSTRING(cast(h.run_date as varchar),5,2)+'-'+ RIGHT(cast(h.run_date as varchar),2) as date), GETDATE())
		from msdb.dbo.sysjobs_view v
		join msdb.dbo.sysjobsteps j
		on v.job_id = j.job_id
		join msdb.dbo.sysjobhistory h
		on h.job_id = j.job_id and 
		   h.step_id = j.step_id
		where name = @in_job_name
		and j.step_id = (select MAX(step_id) from msdb.dbo.sysjobsteps where job_id = j.job_id)
		and CHARINDEX('The step succeeded',h.message) > 0
		order by run_date desc

		IF @LAST > @in_days  
		  BEGIN
			PRINT 'FAILURE: ' + @in_job_name + ' WAS LAST RUN ' + CAST(@LAST AS VARCHAR(5)) + ' DAYS AGO'
		  END
		ELSE
		  BEGIN
			PRINT 'SUCCESS: ' + @in_job_name + ' WAS LAST RUN ' + CAST(@LAST AS VARCHAR(5)) + ' DAYS AGO'		  
		  END

END

RETURN(@LAST)






GO



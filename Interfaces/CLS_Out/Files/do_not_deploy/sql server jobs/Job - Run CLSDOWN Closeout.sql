USE [msdb]
GO

/****** Object:  Job [Run D16_ CLS Down Closeout]    Script Date: 03/09/2018 15:39:41 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Run D16_ CLS Down Closeout')
EXEC msdb.dbo.sp_delete_job @job_id=N'd620be89-e1da-443d-844f-45298928c28c', @delete_unused_schedule=1
GO

USE [msdb]
GO

/****** Object:  Job [Run D16_ CLS Down Closeout]    Script Date: 03/09/2018 15:39:41 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [D16 - FEDERAL]    Script Date: 03/09/2018 15:39:41 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'D16 - FEDERAL' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'D16 - FEDERAL'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Run D16_ CLS Down Closeout', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'D16 - FEDERAL', 
		@owner_login_name=N'DIV16\gealvare', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CLS Down Closeout]    Script Date: 03/09/2018 15:39:41 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'CLS Down Closeout', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'TRUNCATE TABLE XX_CLS_DOWN_LAST_MONTH_YTD
INSERT INTO XX_CLS_DOWN_LAST_MONTH_YTD
SELECT * FROM XX_CLS_DOWN_THIS_MONTH_YTD', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'D:\IMAPS_Data\Interfaces\logs\CLS_Closeout.log', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO



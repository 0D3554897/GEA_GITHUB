USE [msdb]

/*************************************************************************
this file creates a job that will run the extra timecard scan SP
However, it logs to a local file on D: drive, that may not work 
for all environments, so this non-deploy job is created to 
allow customization to fit each environment
**************************************************************************/




GO

/****** Object:  Job [D16_ WORKDAY 6 - Step 6 - Run Extra Timecard Scan]    Script Date: 02/23/2017 14:54:14 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'D16_ WORKDAY 6 - Step 6 - Run Extra Timecard Scan')
EXEC msdb.dbo.sp_delete_job @job_id=N'4603fba8-0fe7-4dc3-91db-436e16d385bf', @delete_unused_schedule=1
GO

USE [msdb]
GO

/****** Object:  Job [D16_ WORKDAY 6 - Step 6 - Run Extra Timecard Scan]    Script Date: 02/23/2017 14:54:14 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 02/23/2017 14:54:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'D16_ WORKDAY 6 - Step 6 - Run Extra Timecard Scan', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Log available at

D:\apps_to_compile\csv2db\sql_job_log\CERIS_D16.log
', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DIV16\gealvare', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run the Timecard Scan]    Script Date: 02/23/2017 14:54:15 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run the Timecard Scan', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @ret_code int
  EXEC @ret_code = dbo.XX_CERIS_EXTRA_TIMECARD_SCAN_SP
  IF @ret_code<> 0
  BEGIN
    RAISERROR(''TIMECARD SCAN JOB FAILURE'',16,1)
  END', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'D:\apps_to_compile\csv2db\sql_job_log\CERIS_D16.log', 
		@flags=2
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

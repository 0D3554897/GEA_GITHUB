USE [msdb]
GO

/****** Object:  Job [Run D16_ CLS Down]    Script Date: 03/09/2018 15:38:43 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Run D16_ CLS Down')
EXEC msdb.dbo.sp_delete_job @job_id=N'75ba4f5e-c5c6-4cdc-80f6-0d69e403b2a1', @delete_unused_schedule=1
GO

USE [msdb]
GO

/****** Object:  Job [Run D16_ CLS Down]    Script Date: 03/09/2018 15:38:44 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [D16 - FEDERAL]    Script Date: 03/09/2018 15:38:44 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'D16 - FEDERAL' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'D16 - FEDERAL'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Run D16_ CLS Down', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'CLS:', 
		@category_name=N'D16 - FEDERAL', 
		@owner_login_name=N'DIV16\gealvare', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Ensure Closeout Was Run for Last Month]    Script Date: 03/09/2018 15:38:44 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Ensure Closeout Was Run for Last Month', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @ret_code int
EXEC @ret_code = XX_CLS_DOWN_CHECK_JOB_SP  ''Run D16_ CLS Down Closeout'',  35
IF @ret_code <> 0
BEGIN
	RAISERROR (''CLSDOWN CLOSEOUT NOT RUN LAST MONTH'', 16, 1)
END
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run CLS Down]    Script Date: 03/09/2018 15:38:44 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run CLS Down', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=3, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @ret_code int
   EXEC @ret_code = dbo.XX_CLS_DOWN_RUN_INTERFACE_SP
   	@in_FY=''2018'',
 	@in_MO=''02''
    IF @ret_code <> 0
   BEGIN
      RAISERROR (''JOB FAILURE'', 16, 1)
   END', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'D:\IMAPS_Data\Interfaces\logs\Run_CLS_DOWN.log', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Clear Attachments]    Script Date: 03/09/2018 15:38:44 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Clear Attachments', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'update xx_imaps_mail_out
set attachments = null', 
		@database_name=N'IMAPSStg', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'OneTime', 
		@enabled=0, 
		@freq_type=1, 
		@freq_interval=0, 
		@freq_subday_type=0, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20140205, 
		@active_end_date=99991231, 
		@active_start_time=163700, 
		@active_end_time=235959, 
		@schedule_uid=N'c60fe15c-e6a6-415d-b5a1-dff07eed5cb4'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO



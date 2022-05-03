USE [msdb]
GO


/****** Object:  Job [Run R22_ 3. CLS Down Closeout]    Script Date: 6/5/2020 9:21:13 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [DIV22]    Script Date: 6/5/2020 9:21:13 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'DIV22' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'DIV22'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Run R22_ 3. CLS Down Closeout', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'DIV22', 
		@owner_login_name=N'DIV16\kingar', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CLS Down Closeout]    Script Date: 6/5/2020 9:21:13 AM ******/
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
		@command=N'PRINT ''*********************************************************************''
PRINT''      BEGIN  R22 CLS DOWN CLOSEOUT ''
PRINT ''*********************************************************************''


TRUNCATE TABLE XX_R22_CLS_DOWN_LAST_MONTH_YTD
INSERT INTO XX_R22_CLS_DOWN_LAST_MONTH_YTD
SELECT * FROM XX_R22_CLS_DOWN_THIS_MONTH_YTD

PRINT ''*********************************************************************''
PRINT''      END  R22 CLS DOWN CLOSEOUT ''
PRINT ''*********************************************************************''
', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'S:\IMAPS_DATA\Interfaces\LOGS\CLS_R22\Run_CLS_DOWN_R22.log', 
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



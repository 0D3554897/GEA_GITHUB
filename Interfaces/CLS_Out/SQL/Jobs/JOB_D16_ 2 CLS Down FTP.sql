USE [msdb]
GO

/****** Object:  Job [D16_ 2 CLS Down FTP]    Script Date: 4/7/2020 10:52:43 AM ******/
EXEC msdb.dbo.sp_delete_job @job_id=N'17f48742-5423-4031-9f2f-bd923f97af64', @delete_unused_schedule=1
GO

/****** Object:  Job [D16_ 2 CLS Down FTP]    Script Date: 4/7/2020 10:52:43 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 4/7/2020 10:52:43 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'D16_ 2 CLS Down FTP', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DIV16\gealvare', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [FTP CLS DOWN FILE]    Script Date: 4/7/2020 10:52:43 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'FTP CLS DOWN FILE', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'	DECLARE @STATUS_RECORD_NUM INT,
		@RET_CODE INT
	
	SELECT TOP 1 @STATUS_RECORD_NUM = STATUS_RECORD_NUM
	FROM XX_IMAPS_INT_STATUS
	WHERE INTERFACE_NAME = ''CLS''
	ORDER BY CREATED_DATE DESC
	
	EXEC @RET_CODE = XX_CLS_DOWN_FTP_FILE_SP
				@IN_STATUS_RECORD_NUM = @STATUS_RECORD_NUM
	
	IF @RET_CODE <> 0 OR @@ERROR <> 0
	BEGIN	
		PRINT ''FTP CLS FAILED''
		RAISERROR (''JOB FAILURE'', 16, 1)
	END
', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'D:\IMAPS_DATA\Interfaces\LOGS\CLS\D16_CLS_down.log', 
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



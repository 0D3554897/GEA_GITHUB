USE [msdb]
GO

/****** Object:  Job [Run R22_ 2. CLS Down Transmit Files]    Script Date: 5/8/2020 1:41:33 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [DIV22]    Script Date: 5/8/2020 1:41:33 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'DIV22' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'DIV22'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Run R22_ 2. CLS Down Transmit Files', 
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
/****** Object:  Step [Run CLS Transmit Files]    Script Date: 5/8/2020 1:41:33 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run CLS Transmit Files', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @STATUS_RECORD_NUM INT,
		@RET_CODE INT
	
	SELECT TOP 1 @STATUS_RECORD_NUM = STATUS_RECORD_NUM
	FROM XX_IMAPS_INT_STATUS
	WHERE INTERFACE_NAME = ''CLS_R22''
	ORDER BY CREATED_DATE DESC
	
	EXEC @RET_CODE = XX_R22_CLS_DOWN_FTP_FILE_SP
				@IN_STATUS_RECORD_NUM = @STATUS_RECORD_NUM
	
	IF @RET_CODE <> 0 OR @@ERROR <> 0
	BEGIN	
		PRINT ''FTP CLS_R22 FAILED''
		RAISERROR (''JOB FAILURE'', 16, 1)
	END', 
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


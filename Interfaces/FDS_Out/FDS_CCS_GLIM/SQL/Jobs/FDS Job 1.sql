USE [msdb]
GO

/****** Object:  Job [D16_ FDS 1 Create Files]    Script Date: 4/15/2020 1:44:01 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 4/15/2020 1:44:02 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'D16_ FDS 1 Create Files', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This is the first of two jobs to run FDS.

First, the entire process is run, and FILES_TRANSFER parameter set to NO.  This prevents FTP transmission of files to target. Instead, they get archived.  That''s what this job does.

The second job changes the parameter to yes, then re-runs the FTP SP''s.  This is how the files get FTP''d to the target server.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'itgsa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Delete Log File]    Script Date: 4/15/2020 1:44:02 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete Log File', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'rem Remove-Item –path T:\IMAPS_DATA\Interfaces\LOGS\FDS -include DIV16_FDS_LOG.TXT

del /f /q  T:\IMAPS_DATA\Interfaces\LOGS\FDS\DIV16_FDS_LOG.TXT', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Execute CMR SSIS Package]    Script Date: 4/15/2020 1:44:02 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Execute CMR SSIS Package', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'PRINT ''''
PRINT '' **************************************************** STARTING  STEP 2 *********************************************************************************** ''
PRINT ''''
PRINT ''''

DECLARE @ssuser varchar(50)
SELECT @ssuser = SUSER_SNAME() 
PRINT ''The user is '' + @ssuser

UPDATE XX_PROCESSING_PARAMETERS
SET PARAMETER_VALUE = ''NO''
, MODIFIED_DATE = getdate()
WHERE INTERFACE_NAME_CD = ''FDS''
AND PARAMETER_NAME = ''TRANSFER_FILES''

DECLARE @ret_code int
EXEC @ret_code = dbo.XX_FDS_RUN_INTERFACE_SP

IF @ret_code <> 0
BEGIN
	RAISERROR (''JOB FAILURE'', 16, 1)
END', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_DATA\Interfaces\LOGS\FDS\DIV16_FDS_LOG.TXT', 
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



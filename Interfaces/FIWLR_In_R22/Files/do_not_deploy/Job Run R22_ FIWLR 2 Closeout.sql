USE [msdb]
GO

/****** Object:  Job [Run R22_ FIWLR 2 Closeout]    Script Date: 01/27/2017 11:04:20 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [D22 - RESEARCH]    Script Date: 01/27/2017 11:04:20 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'D22 - RESEARCH' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'D22 - RESEARCH'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Run R22_ FIWLR 2 Closeout', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=3, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'D22 - RESEARCH', 
		@owner_login_name=N'DIV16\kingar', 
		@notify_email_operator_name=N'FSST_Admins', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run FIWLR_R22 Interface Closeout Process]    Script Date: 01/27/2017 11:04:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run FIWLR_R22 Interface Closeout Process', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'	DECLARE @count int
	SELECT @count=COUNT(1)
	FROM IMAR.DELTEK.AOPUTLAP_INP_HDR
	WHERE 
	(  S_STATUS_CD NOT IN (''I'', ''E'')
	OR S_STATUS_CD IS NULL )
	IF @count <> 0
	BEGIN
		RAISERROR (''AP RECORDS NOT PROCESSED'', 16, 1)
	END 

	SELECT @count=COUNT(1)
	FROM IMAR.DELTEK.AOPUTLAP_INP_HDR
	IF @count = 0
	BEGIN
		RAISERROR (''NO AP RECORDS EXIST'', 16, 1)
	END 

	SELECT @count=COUNT(1)
	FROM IMAR.DELTEK.AOPUTLJE_INP_TR
	WHERE 
	(  S_STATUS_CD NOT IN (''I'', ''E'')
	OR S_STATUS_CD IS NULL )
	IF @count <> 0
	BEGIN
		RAISERROR (''JE RECORDS NOT PROCESSED'', 16, 1)
	END', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_Data\Interfaces\logs\Run_FIWLR_R22_Closeout_step1.log', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run Update Process Status]    Script Date: 01/27/2017 11:04:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run Update Process Status', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'	DECLARE @ret_code int
	EXEC @ret_code = dbo.XX_R22_UPDATE_PROCESS_STATUS_SP
	IF @ret_code <> 0
	BEGIN
		RAISERROR (''JOB FAILURE'', 16, 1)
	END', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_Data\Interfaces\logs\Run_FIWLR_R22_Closeout_step2.log', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run FIWLR_R22 Interface]    Script Date: 01/27/2017 11:04:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run FIWLR_R22 Interface', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'	DECLARE @ret_code int
	EXEC @ret_code = dbo.XX_R22_FIWLR_RUN_INTER_SP
	IF @ret_code <> 0
	BEGIN
		RAISERROR (''JOB FAILURE'', 16, 1)
	END
', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_Data\Interfaces\logs\Run_FIWLR_R22_Closeout_step3.log', 
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

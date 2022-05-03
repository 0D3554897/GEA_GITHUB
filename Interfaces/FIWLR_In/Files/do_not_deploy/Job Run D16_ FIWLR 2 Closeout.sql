USE [msdb]
GO

/****** Object:  Job [Run D16_ FIWLR 2 Closeout]    Script Date: 01/27/2017 11:01:43 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [D16 - FEDERAL]    Script Date: 01/27/2017 11:01:43 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'D16 - FEDERAL' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'D16 - FEDERAL'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Run D16_ FIWLR 2 Closeout', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=3, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Run FIWLR Interface Closeout :', 
		@category_name=N'D16 - FEDERAL', 
		@owner_login_name=N'DIV16\kingar', 
		@notify_email_operator_name=N'FSST_Admins', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Successful]    Script Date: 01/27/2017 11:01:45 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Successful', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=2, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @count int
	SELECT @count=COUNT(1)
	FROM IMAPS.DELTEK.AOPUTLAP_INP_HDR
	WHERE 
	(  S_STATUS_CD NOT IN (''I'', ''E'')
	OR S_STATUS_CD IS NULL )
	IF @count <> 0
	BEGIN
		RAISERROR (''AP RECORDS NOT PROCESSED'', 16, 1)
	END 

	SELECT @count=COUNT(1)
	FROM IMAPS.DELTEK.AOPUTLAP_INP_HDR
	IF @count = 0
	BEGIN
		RAISERROR (''NO AP RECORDS EXIST'', 16, 1)
	END 

	SELECT @count=COUNT(1)
	FROM IMAPS.DELTEK.AOPUTLJE_INP_TR
	WHERE 
	(  S_STATUS_CD NOT IN (''I'', ''E'')
	OR S_STATUS_CD IS NULL )
	IF @count <> 0
	BEGIN
		RAISERROR (''JE RECORDS NOT PROCESSED'', 16, 1)
	END', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_Data\Interfaces\logs\FIWLR_Closeout_Step1.log', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run Update Process Status]    Script Date: 01/27/2017 11:01:45 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run Update Process Status', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=3, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @ret_code int
	EXEC @ret_code = dbo.XX_UPDATE_PROCESS_STATUS_SP
	IF @ret_code <> 0
	BEGIN
		RAISERROR (''JOB FAILURE'', 16, 1)
	END', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_Data\Interfaces\logs\FIWLR_Closeout_Step2.log', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run FIWLR Interface]    Script Date: 01/27/2017 11:01:45 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run FIWLR Interface', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=4, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @ret_code int
	EXEC @ret_code = dbo.XX_FIWLR_RUN_INTER_SP
	IF @ret_code <> 0
	BEGIN
		RAISERROR (''JOB FAILURE'', 16, 1)
	END', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_Data\Interfaces\logs\FIWLR_Closeout_Step3.log', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Truncate Preprocessor Tables]    Script Date: 01/27/2017 11:01:47 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Truncate Preprocessor Tables', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=5, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'TRUNCATE TABLE IMAPS.DELTEK.AOPUTLAP_INP_HDR
	TRUNCATE TABLE IMAPS.DELTEK.AOPUTLAP_INP_DETL
	TRUNCATE TABLE IMAPS.DELTEK.AOPUTLJE_INP_TR', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_Data\Interfaces\logs\FIWLR_Closeout_Step4.log', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Reindex Archive]    Script Date: 01/27/2017 11:01:47 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Reindex Archive', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'dbcc dbreindex (''XX_FIWLR_USDET_ARCHIVE'', '''', 80)', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_Data\Interfaces\logs\FIWLR_Closeout_Step5.log', 
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
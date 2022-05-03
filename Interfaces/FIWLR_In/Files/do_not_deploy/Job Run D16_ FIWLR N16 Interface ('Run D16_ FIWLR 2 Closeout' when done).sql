
USE [msdb]
GO

/****** Object:  Job [Run D16_ FIWLR N16 Interface ('Run D16_ FIWLR 2 Closeout' when done)]    Script Date: 01/27/2017 11:10:13 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [D16 - FEDERAL]    Script Date: 01/27/2017 11:10:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'D16 - FEDERAL' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'D16 - FEDERAL'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Run D16_ FIWLR N16 Interface (''Run D16_ FIWLR 2 Closeout'' when done)', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=3, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'D16 - FEDERAL', 
		@owner_login_name=N'DIV16\kingar', 
		@notify_email_operator_name=N'FSST_Admins', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Truncate Tables]    Script Date: 01/27/2017 11:10:14 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Truncate Tables', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=2, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'truncate table dbo.xx_fiwlr_usdet_v1
go
truncate table dbo.xx_fiwlr_usdet_v2
go
truncate table dbo.xx_fiwlr_usdet_v3
go
truncate table dbo.xx_aoputlap_inp_detlv
go
truncate table dbo.xx_aoputlap_inp_hdrv
go', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_Data\Interfaces\logs\N16_1.log', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run FIWLR Interface]    Script Date: 01/27/2017 11:10:15 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run FIWLR Interface', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
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
		@output_file_name=N'T:\IMAPS_Data\Interfaces\logs\N16_2.log', 
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


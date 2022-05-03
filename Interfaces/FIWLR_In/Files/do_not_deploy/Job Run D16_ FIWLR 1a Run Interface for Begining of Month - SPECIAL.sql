USE [msdb]
GO

/****** Object:  Job [Run D16_ FIWLR 1a Run Interface for Begining of Month - SPECIAL]    Script Date: 01/27/2017 11:00:48 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

/****** Object:  JobCategory [D16 - FEDERAL]    Script Date: 01/27/2017 11:00:49 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'D16 - FEDERAL' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'D16 - FEDERAL'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Run D16_ FIWLR 1a Run Interface for Begining of Month - SPECIAL', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=3, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Run FIWLR Interface for Begining of Month :', 
		@category_name=N'D16 - FEDERAL', 
		@owner_login_name=N'DIV16\kingar', 
		@notify_email_operator_name=N'FSST_Admins', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Validation that JE and VCHR tables have no data for current period]    Script Date: 01/27/2017 11:00:53 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Validation that the job have not run for current period already', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Declare @IsthereSpecialRunAlready as int
Declare @StartDate as date, @EndDate as date


--Select start and end date for the current period by the current date
Select @StartDate= a.run_start_date, @EndDate = run_end_date from
( select fiscal_year, period,MIN(run_start_date) run_start_date, MAX(run_end_date) run_end_date from  IMAPSstg.dbo.XX_R22_FIWLR_RUNDATE_ACCTCAL
 group by fiscal_year, period
) a
where getdate() < a.run_end_date and getdate() >= a.run_start_date


if @StartDate is NULL or  @EndDate is NULL begin
   RAISERROR (''There is no ledger period associated with the current date '',16,1) with log
end 

--Inside selected dates only one successful special job should reside 
-- the j.name should be compared with ename of the special job.
-- There is no sense to check if the job was completed
select @IsthereSpecialRunAlready = case when j.name IS NOT NULL then 1 else 0 end 
from msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobhistory h 
 ON j.job_id = h.job_id 
where j.enabled = 1  --Only Enabled Jobs
and j.name like ''Run D16_ FIWLR 1a Run Interface for Begining of Month - SPECIAL''
 and msdb.dbo.agent_datetime(run_date, run_time)  between  @StartDate and @EndDate 
 and step_id = 4  and run_status = 1 -- last steps was successful, so job was successful 

if @IsthereSpecialRunAlready = 1  begin
   RAISERROR (''There is a special job run in the period already'',16,1) with log
end 

', 
		@database_name=N'IMAPSStg', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Update Extract Date]    Script Date: 01/27/2017 11:00:55 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Update Extract Date', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=3, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'update xx_processing_parameters
	set parameter_value = ''1900-01-01''
	where interface_name_cd = ''FIWLR''
	and parameter_name = ''EXTRACT_START_DATE''', 
		@database_name=N'IMAPSStg', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [SSIS]    Script Date: 01/27/2017 11:00:57 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'SSIS', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=4, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/SQL "\FIWLR" /SERVER DSWSQLPFS03 /CHECKPOINTING OFF /REPORTING E', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run FIWLR Interface]    Script Date: 01/27/2017 11:01:04 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run FIWLR Interface', 
		@step_id=4, 
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
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
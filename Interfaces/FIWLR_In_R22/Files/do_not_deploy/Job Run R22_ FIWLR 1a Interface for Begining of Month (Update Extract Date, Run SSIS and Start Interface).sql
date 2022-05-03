/****** Object:  Job [Run R22_ FIWLR 1a Interface for Begining of Month (Update Extract Date, Run SSIS and Start Interface)]    Script Date: 01/27/2017 11:03:31 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [D22 - RESEARCH]    Script Date: 01/27/2017 11:03:32 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'D22 - RESEARCH' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'D22 - RESEARCH'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Run R22_ FIWLR 1a Interface for Begining of Month (Update Extract Date, Run SSIS and Start Interface)', 
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
/****** Object:  Step [Validation that JE and VCHR tables have no data for current period]    Script Date: 01/27/2017 11:03:33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Validation that JE and VCHR tables have no data for current period', 
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
Select @StartDate= a.run_start_date, @EndDate = run_end_date from IMAPSstg.dbo.XX_R22_FIWLR_RUNDATE_ACCTCAL a
where getdate() <= a.run_end_date and getdate() >= a.run_start_date

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
and j.name like ''Run R22_ FIWLR 1a Interface for Begining of Month (Update Extract Date, Run SSIS and Start Interface)'' 
 and msdb.dbo.agent_datetime(run_date, run_time)  between  @StartDate and @EndDate 
 and step_id = 4  and run_status = 1 -- last steps was successful, so job was successful 

if @IsthereSpecialRunAlready = 1  begin
   RAISERROR (''There is a special job run in the period already'',16,1) with log
end 

', 
		@database_name=N'IMAPSStg', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Update Extract Date]    Script Date: 01/27/2017 11:03:33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Update Extract Date', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'	update xx_processing_parameters
	set parameter_value = ''1900-01-01''
	where interface_name_cd = ''FIWLR_R22''
	and parameter_name = ''EXTRACT_START_DATE''', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_Data\Interfaces\logs\Run_FIWLR_R22_Interface_BOM_step1.log', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [SSIS]    Script Date: 12/3/2019 3:03:32 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'SSIS', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/ISSERVER "\"\SSISDB\Research\FIWLR_R22\FIWLR_R22.dtsx\"" /SERVER "\"dswwindap47.div16.ibm.com\"" /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [WWER_22]    Script Date: 12/3/2019 3:03:32 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'WWER_22', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/ISSERVER "\"\SSISDB\Research\FIWLR_R22\FIWLR_22_EMPL_from_WWER.dtsx\"" /SERVER DSWWINDAP47 /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run FIWLR_R22 Interface]    Script Date: 01/27/2017 11:03:36 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run FIWLR_R22 Interface', 
		@step_id=5, 
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
		@output_file_name=N'T:\IMAPS_Data\Interfaces\logs\Run_FIWLR_R22_Interface_BOM_step3.log', 
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


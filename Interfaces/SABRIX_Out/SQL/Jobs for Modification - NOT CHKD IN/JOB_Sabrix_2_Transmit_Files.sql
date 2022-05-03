USE [msdb]
GO

/****** Object:  Job [D16_ SABRIX 2 Transmit Files]    Script Date: 4/8/2020 3:20:08 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 4/8/2020 3:20:08 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'D16_ SABRIX 2 Transmit Files', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'

First, the entire process is run, and FILES_TRANSFER parameter set to NO.  This prevents FTP transmission of files to target. Instead, they get archived.  

This job, the second job, changes the parameter to YES, then re-runs the FTP SP''s.  This is how the files get FTP''d to the target server.

', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'itgsa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run D16_ SABRIX 2 Transmit Files]    Script Date: 4/8/2020 3:20:08 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run D16_ SABRIX 2 Transmit Files', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'PRINT ''''
PRINT '' *********************************************************************** STARTING FTP JOB ***************************************************************************** ''
PRINT ''*''
PRINT ''*''
PRINT '' ************************************************************************************************************************************************************************** ''
PRINT ''''

DECLARE @ssuser varchar(50), @RIGHTNOW VARCHAR(50)
SELECT @ssuser = SUSER_SNAME() 
PRINT ''The user is '' + @ssuser
PRINT ''And the time is '' + @RIGHTNOW

UPDATE dbo.XX_PROCESSING_PARAMETERS
   SET PARAMETER_VALUE = ''YES'',
       MODIFIED_DATE = getdate()
 WHERE INTERFACE_NAME_CD = ''SABRIX''
   AND PARAMETER_NAME = ''TRANSFER_FILES''
	
DECLARE @STATUS_RECORD_NUM INT,
        @RET_CODE INT
	
SELECT TOP 1 @STATUS_RECORD_NUM = STATUS_RECORD_NUM
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE INTERFACE_NAME = ''SABRIX''
 ORDER BY CREATED_DATE DESC
	
EXEC @RET_CODE = dbo.XX_SABRIX_RUN_INTERFACE_SP

IF @RET_CODE <> 0 OR @@ERROR <> 0
   BEGIN
      UPDATE dbo.XX_PROCESSING_PARAMETERS
         SET PARAMETER_VALUE = ''NO''
       WHERE INTERFACE_NAME_CD = ''SABRIX''
         AND PARAMETER_NAME = ''TRANSFER_FILES''
	
      PRINT ''SABRIX FTP PROCESS FAILED''
      RAISERROR(''JOB FAILURE: SABRIX FTP PROCESS FAILED'', 16, 1)
   END
	
UPDATE dbo.XX_PROCESSING_PARAMETERS
   SET PARAMETER_VALUE = ''NO''
 WHERE INTERFACE_NAME_CD = ''SABRIX''
   AND PARAMETER_NAME = ''TRANSFER_FILES''

', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_DATA\Interfaces\LOGS\SABRIX\D16_SABRIX.log', 
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



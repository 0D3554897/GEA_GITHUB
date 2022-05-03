USE [msdb]
GO

/****** Object:  Job [D16_ 0 CLS  Down Accounting Period]    Script Date: 7/22/2020 12:56:36 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 7/22/2020 12:56:36 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'D16_ 0 CLS  Down Accounting Period', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Use this job to report, advance or rollback the accounting period used by CLS_DOWN   The log can be found at:  

T:\IMAPS_DATA\Interfaces\LOGS\CLS
in the file:

Accounting Period Reporting.txt', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DIV16\gealvare', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Report the accouting Period]    Script Date: 7/22/2020 12:56:36 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Report the accouting Period', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @ret_code varchar(12), @MO int, @YR int

SELECT @MO=PARAMETER_VALUE 
FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = ''CLS''
AND PARAMETER_NAME = ''ACCT_MO''

SELECT @YR=PARAMETER_VALUE 
FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = ''CLS''
AND PARAMETER_NAME = ''ACCT_YR''

SElecT @ret_code=convert(varchar, getdate(), 101) 

PRINT ''Today is '' + @ret_code

PRINT ''The current accounting close period is '' + cast(@MO as varchar) + '':'' + cast(@YR as varchar)', 
		@database_name=N'master', 
		@output_file_name=N'T:\IMAPS_DATA\Interfaces\LOGS\CLS\Accounting Period Reporting.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Advance the Reporting Period]    Script Date: 7/22/2020 12:56:36 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Advance the Reporting Period', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @MO INTEGER, @YR INTEGER

/*****
TRUNCATE TABLE XX_CLS_DOWN_LAST_MONTH_YTD
INSERT INTO XX_CLS_DOWN_LAST_MONTH_YTD
SELECT * FROM XX_CLS_DOWN_THIS_MONTH_YTD
******/

SELECT @MO=PARAMETER_VALUE 
FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = ''CLS''
AND PARAMETER_NAME = ''ACCT_MO''

SELECT @YR=PARAMETER_VALUE 
FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = ''CLS''
AND PARAMETER_NAME = ''ACCT_YR''

PRINT ''FISCAL PERIOD BEFORE ADJUSTMENT IS '' + CAST(@MO AS VARCHAR) + '':'' + CAST(@YR AS VARCHAR)

SET @MO = @MO + 1

IF @MO = 13
  BEGIN
    SET @MO = 1
	SET @YR = @YR + 1
  END

UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
SET PARAMETER_VALUE = CAST(@MO AS VARCHAR)
WHERE INTERFACE_NAME_CD = ''CLS''
AND PARAMETER_NAME = ''ACCT_MO''

UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
SET PARAMETER_VALUE = CAST(@YR AS VARCHAR)
WHERE INTERFACE_NAME_CD = ''CLS''
AND PARAMETER_NAME = ''ACCT_YR''

PRINT ''FISCAL PERIOD AFTER ADJUSTMENT IS '' + CAST(@MO AS VARCHAR) + '':'' + CAST(@YR AS VARCHAR)', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_DATA\Interfaces\LOGS\CLS\Accounting Period Reporting.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Rollback the Accounting Period]    Script Date: 7/22/2020 12:56:36 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Rollback the Accounting Period', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @MO INTEGER, @YR INTEGER

/*****
TRUNCATE TABLE XX_CLS_DOWN_LAST_MONTH_YTD
INSERT INTO XX_CLS_DOWN_LAST_MONTH_YTD
SELECT * FROM XX_CLS_DOWN_THIS_MONTH_YTD
******/

SELECT @MO=PARAMETER_VALUE 
FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = ''CLS''
AND PARAMETER_NAME = ''ACCT_MO''

SELECT @YR=PARAMETER_VALUE 
FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = ''CLS''
AND PARAMETER_NAME = ''ACCT_YR''

PRINT ''FISCAL PERIOD BEFORE ADJUSTMENT IS '' + CAST(@MO AS VARCHAR) + '':'' + CAST(@YR AS VARCHAR)

SET @MO = @MO -  1

IF @MO = 0
  BEGIN
    SET @MO = 12
	SET @YR = @YR - 1
  END

UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
SET PARAMETER_VALUE = CAST(@MO AS VARCHAR)
WHERE INTERFACE_NAME_CD = ''CLS''
AND PARAMETER_NAME = ''ACCT_MO''

UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
SET PARAMETER_VALUE = CAST(@YR AS VARCHAR)
WHERE INTERFACE_NAME_CD = ''CLS''
AND PARAMETER_NAME = ''ACCT_YR''

PRINT ''FISCAL PERIOD AFTER ADJUSTMENT IS '' + CAST(@MO AS VARCHAR) + '':'' + CAST(@YR AS VARCHAR)

', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_DATA\Interfaces\LOGS\CLS\Accounting Period Reporting.txt', 
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


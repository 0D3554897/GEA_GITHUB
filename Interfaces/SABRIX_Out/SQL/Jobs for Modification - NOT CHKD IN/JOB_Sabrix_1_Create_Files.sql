USE [msdb]
GO

/****** Object:  Job [D16_ SABRIX 1 Create Files]    Script Date: 4/14/2020 2:37:23 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 4/14/2020 2:37:23 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'D16_ SABRIX 1 Create Files', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This is the first of two jobs to run SABRIX.

First, the entire process is run, and FILES_TRANSFER parameter set to NO.  This prevents FTP transmission of files to target. Instead, they get archived.  That''s what this job does.

The second job changes the parameter to yes, then re-runs the FTP SP''s.  This is how the files get FTP''d to the target server.

', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'itgsa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Delete Log File]    Script Date: 4/14/2020 2:37:23 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete Log File', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=5, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'del /F /Q T:\IMAPS_DATA\Interfaces\LOGS\SABRIX\D16_SABRIX.log', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [VALIDATE SABRIX FILES]    Script Date: 4/14/2020 2:37:23 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'VALIDATE SABRIX FILES', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @MyList TABLE (Value NVARCHAR(500))

INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\CFF.bat'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\FILE_CHECK_Q.BAT'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\FILE_CHECK_K.BAT'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\getfilename.bat'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\interface.bat'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\isit_current.bat'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\VALFTP.BAT'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\VALIDATE.BAT'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\VALJAVA.BAT'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\winscp_ftp.bat'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\DOIT_XST.bat'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\FAIL.bat'')

INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\java\cff\classes\com\ibm\imapsstg\cff.class'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\java\validate\classes\com\ibm\imapsstg\validate.class'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\java\ftp_chk\classes\com\ibm\imapsstg\ftp_chk.class'')

INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\SABRIX\jeskick.iefbr14sabrix'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\SABRIX\SABRIX.bat'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\SABRIX\sabrix16_hdr.properties'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\SABRIX\sabrix16_lin.properties'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\SABRIX\sabrix16_trx.properties'')

INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Props\SABRIX\sabrix_winscp.txt'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Props\SABRIX\sql16.credentials'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Props\SABRIX\v_sabrix_winscp.txt'')


DECLARE @ERR_CTR INT = 0
DECLARE @COUNTER INT = 0
DECLARE @MAX INT = (SELECT COUNT(*) FROM @MyList)
DECLARE  @CMD VARCHAR(200), @MYCMD VARCHAR(200), @TGT VARCHAR(500), @RTN_CODE INT 
SET @CMD = ''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\file_check_Q.BAT ''

WHILE @COUNTER < @MAX
BEGIN

	SET @TGT = (SELECT VALUE FROM
      (SELECT (ROW_NUMBER() OVER (ORDER BY (SELECT NULL))) [index] , Value from @MyList) R 
       ORDER BY R.[index] OFFSET @COUNTER 
       ROWS FETCH NEXT 1 ROWS ONLY);

	SET @MYCMD = @CMD + @TGT
	-- PRINT ''COMMAND IS: '' + @MYCMD
	EXEC @RTN_CODE = master.dbo.xp_cmdshell @MYCMD
	--PRINT @TGT + '' = ''  + CAST(COALESCE(@RTN_CODE,0) AS VARCHAR)
	IF COALESCE(@RTN_CODE,0)<>0 
	  BEGIN
	     -- PRINT @TGT +  '' FILE NOT FOUND''
	      SET @ERR_CTR = @ERR_CTR + 1 
	  END
	SET @COUNTER = @COUNTER + 1

END

--PRINT ''HERE WITH AN ERR_CTR = '' + CAST(@ERR_CTR AS VARCHAR)
IF @ERR_CTR > 0
  BEGIN
	SET @MYCMD = ''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\FAIL.BAT''
	-- PRINT ''COMMAND IS: '' + @MYCMD
	-- EXEC master.dbo.xp_cmdshell @MYCMD
                RAISERROR (''FILES MISSING - SEARCH THIS LOG FOR WORD: FAILURE'', 16, 1)
  END

IF @ERR_CTR = 0
  PRINT ''ALL FILES EXIST IN THE RIGHT PLACES!''
', 
		@database_name=N'master', 
		@output_file_name=N'T:\IMAPS_DATA\Interfaces\LOGS\SABRIX\D16_SABRIX.log', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Validate Java and FTP]    Script Date: 4/14/2020 2:37:23 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Validate Java and FTP', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
PRINT ''************************************************************''
PRINT''          SABRIX VALIDATE JAVA START''
PRINT ''************************************************************''

DECLARE @CMD sysname, @ret_code int

SET @CMD = ''T:\IMAPS_DATA\Interfaces\PROGRAMS\BATCH\VALJAVA.BAT "sabrix16_hdr" SABRIX''
PRINT ''Command is :'' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
IF @ret_code <> 0
	BEGIN
		RAISERROR (''STEP 2 VALJAVA FAILURE'', 16, 1)
	END


PRINT ''************************************************************''
PRINT''          CLSDOWN VALIDATE JAVA END''
PRINT ''************************************************************''


PRINT ''************************************************************''
PRINT''          CLSDOWN VALIDATE FTP START''
PRINT ''************************************************************''

SET @CMD = ''T:\IMAPS_DATA\Interfaces\PROGRAMS\BATCH\VALFTP.BAT "v_sabrix_winscp" sabrix 1 "is logged on"''
PRINT ''Command is :'' + @CMD
EXEC @ret_code = MASTER.DBO.XP_CMDSHELL @CMD
PRINT ''VALFTP RETURN CODE IS :'' + CAST(@ret_code as VARCHAR(5))
IF @ret_code <> 0
	BEGIN
		PRINT ''WE GOT INTO ERROR CODE''
		RAISERROR (''STEP 3 VALFTP FAILURE'', 16, 1)
	END

PRINT ''VALFTP SUCCEEDED!''


PRINT ''************************************************************''
PRINT''          SABRIX VALIDATE FTP END''
PRINT ''************************************************************''', 
		@database_name=N'master', 
		@output_file_name=N'T:\IMAPS_DATA\Interfaces\LOGS\SABRIX\D16_SABRIX.log', 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Execute CMR SSIS Package]    Script Date: 4/14/2020 2:37:23 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Execute CMR SSIS Package', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=6, 
		@on_fail_action=4, 
		@on_fail_step_id=5, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'PRINT " "
PRINT " **************************************************** STARTING  STEP 2 *********************************************************************************** "
PRINT " "
PRINT " "

DECLARE @ssuser varchar(50), @RIGHTNOW VARCHAR(50)
SELECT @ssuser = SUSER_SNAME() 
PRINT ''The user is '' + @ssuser
PRINT ''And the time is '' + @RIGHTNOW

UPDATE XX_PROCESSING_PARAMETERS
SET PARAMETER_VALUE = ''NO''
, MODIFIED_DATE = getdate()
WHERE INTERFACE_NAME_CD = ''SABRIX''
AND PARAMETER_NAME = ''TRANSFER_FILES''

DECLARE @ret_code int
EXEC @ret_code = dbo.XX_SABRIX_RUN_INTERFACE_SP

IF @ret_code <> 0
BEGIN
	RAISERROR (''JOB FAILURE'', 16, 1)
END', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_DATA\Interfaces\LOGS\SABRIX\D16_SABRIX.log', 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Notify Developers of Job Failure]    Script Date: 4/14/2020 2:37:23 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Notify Developers of Job Failure', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=2, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'PRINT ''********************************************************************''
PRINT ''            STEP 3 - JOB MAIL FAILURE NOTIFICATION ''
PRINT ''********************************************************************''

DECLARE @SRN INT

SELECT @SRN= MAX(STATUS_RECORD_NUM) FROM imapsstg.dbo.XX_IMAPS_INT_STATUS 
  WHERE INTERFACE_NAME = ''SABRIX''

EXEC IMAPSSTG.dbo.XX_SEND_STATUS_MAIL_SP @SRN, ''T:\IMAPS_DATA\Interfaces\LOGS\SABRIX\D16_SABRIX.log''', 
		@database_name=N'IMAPSStg', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Success]    Script Date: 4/14/2020 2:37:23 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Success', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @ssuser varchar(50), @RIGHTNOW VARCHAR(50)
SELECT @ssuser = SUSER_SNAME() 
PRINT ''The user is '' + @ssuser
PRINT ''And the time is '' + @RIGHTNOW

PRINT ''********************************************************************''
PRINT ''               SUCCESS !! ''
PRINT ''*********************************************************************''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Run_Once_04172007_9am', 
		@enabled=0, 
		@freq_type=1, 
		@freq_interval=0, 
		@freq_subday_type=0, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20070417, 
		@active_end_date=99991231, 
		@active_start_time=90000, 
		@active_end_time=235959, 
		@schedule_uid=N'd8eb90d2-22df-42a7-89f2-d00df576cbf8'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



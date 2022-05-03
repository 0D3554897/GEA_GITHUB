USE [msdb]
GO

/****** Object:  Job [D16_ 1 CLS Down]    Script Date: 7/22/2020 12:57:44 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 7/22/2020 12:57:44 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'D16_ 1 CLS Down', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'CLSDOWN month end run

Log can be found here: T:\IMAPS_DATA\Interfaces\LOGS\cls\D16_CLS_down.log

This job:
1) Checks to ensure CLSDOWN Closeout was run recently
2) Validates that all necessary files are on server in the correct places
3) Validates that all SP''s are current and up to date
4) Creates a 999 EBCDIC file and PARM file ready for transmission

', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DIV16\gealvare', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [MAKE SURE CLOSEOUT WAS RUN]    Script Date: 7/22/2020 12:57:44 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'MAKE SURE CLOSEOUT WAS RUN', 
		@step_id=1, 
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
PRINT''          CLSDOWN CHECK CLOSEOUT START''
PRINT ''************************************************************''




DECLARE @ret_code  int, @num_days int
SET @num_days = 35
EXEC @ret_code = XX_CHECK_JOB_LAST_RUN_SP ''D16_ 3 CLS Down Closeout'', @num_days
IF @ret_code > @num_days
  BEGIN
    PRINT ''CLOSEOUT FAILURE''
    RAISERROR (''CLSDOWN CLOSEOUT NOT RUN LAST MONTH'', 16, 1)
  END
else
  PRINT ''CLOSEOUT WAS RUN RECENTLY''


PRINT ''************************************************************''
PRINT''          CLSDOWN CHECK CLOSEOUT END''
PRINT ''************************************************************''
', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_DATA\Interfaces\LOGS\cls\D16_CLS_down.log', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [VALIDATE CLS FILES]    Script Date: 7/22/2020 12:57:44 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'VALIDATE CLS FILES', 
		@step_id=2, 
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
PRINT''          CLSDOWN VALIDATE FILES START''
PRINT ''************************************************************''

DECLARE @MyList TABLE (Value NVARCHAR(500))

INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\CFF.bat'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\FILE_CHECK_Q.BAT'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\FILE_CHECK_K.BAT'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\batch\FTP_CHK.BAT'')
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

INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\CLS\CLSDOWN.bat'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\CLS\clsdown.properties'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\CLS\clsdownparm.properties'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Interfaces\PROGRAMS\CLS\clsdownsummary.properties'')

INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Props\CLS\CLS_winscp.txt'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Props\CLS\sql16.credentials'')
INSERT INTO @MyList VALUES (''T:\IMAPS_DATA\Props\CLS\v_CLS_winscp.txt'')


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

PRINT ''************************************************************''
PRINT''          CLSDOWN VALIDATE FILES END''
PRINT ''************************************************************''

', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_DATA\Interfaces\LOGS\cls\D16_CLS_down.log', 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [VALIDATE JAVA AND FTP WORKS]    Script Date: 7/22/2020 12:57:45 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'VALIDATE JAVA AND FTP WORKS', 
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
PRINT''          CLSDOWN VALIDATE JAVA START''
PRINT ''************************************************************''

DECLARE @CMD sysname, @ret_code int

SET @CMD = ''T:\IMAPS_DATA\Interfaces\PROGRAMS\BATCH\VALJAVA.BAT "clsdownsummary" CLS''
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

SET @CMD = ''T:\IMAPS_DATA\Interfaces\PROGRAMS\BATCH\VALFTP.BAT "clsdownsummary" CLS 1 "is logged on"''
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
PRINT''          CLSDOWN VALIDATE FTP END''
PRINT ''************************************************************''', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_DATA\Interfaces\LOGS\cls\D16_CLS_down.log', 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [run interface]    Script Date: 7/22/2020 12:57:45 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'run interface', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'PRINT ''************************************************************''
PRINT''          CLSDOWN INTERFACE START''
PRINT ''************************************************************''

DECLARE @ret_code int, @MO varchar(2), @YR varchar(4)

SELECT @MO=PARAMETER_VALUE 
FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = ''CLS''
AND PARAMETER_NAME = ''ACCT_MO''

SELECT @YR=PARAMETER_VALUE 
FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = ''CLS''
AND PARAMETER_NAME = ''ACCT_YR''

PRINT ''FISCAL PERIOD BEING RUN IS '' + @MO + '':'' + @YR

	EXEC @ret_code = dbo.XX_CLS_DOWN_RUN_INTERFACE_SP
@in_FY=@YR,
@in_MO=@MO

	IF @ret_code <> 0
	BEGIN
		RAISERROR (''JOB FAILURE'', 16, 1)
	END

PRINT ''************************************************************''
PRINT''          CLSDOWN INTERFACE FINISH''
PRINT ''************************************************************''

', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_DATA\Interfaces\LOGS\cls\D16_CLS_down.log', 
		@flags=6
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


USE [msdb]
GO

/****** Object:  Job [D16_ 3 CLS Down Closeout]    Script Date: 7/22/2020 1:03:56 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [D16 - FEDERAL]    Script Date: 7/22/2020 1:03:56 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'D16 - FEDERAL' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'D16 - FEDERAL'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'D16_ 3 CLS Down Closeout', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'D16 - FEDERAL', 
		@owner_login_name=N'DIV16\gealvare', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Move the period forward]    Script Date: 7/22/2020 1:03:56 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Move the period forward', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @MO INTEGER, @YR INTEGER, @TO VARCHAR(500),@BODY VARCHAR(500),@SRN INT


-- closeout steps for this month
TRUNCATE TABLE XX_CLS_DOWN_LAST_MONTH_YTD

INSERT INTO IMAPSSTG.DBO.XX_CLS_DOWN_LAST_MONTH_YTD
SELECT * FROM IMAPSSTG.DBO.XX_CLS_DOWN_THIS_MONTH_YTD


select @SRN=MAX(STATUS_RECORD_NUM)
 from IMAPSSTG.dbo.XX_IMAPS_INT_STATUS
 where INTERFACE_NAME = ''CLS''


SELECT @MO=PARAMETER_VALUE 
FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = ''CLS''
AND PARAMETER_NAME = ''ACCT_MO''

SELECT @YR=PARAMETER_VALUE 
FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = ''CLS''
AND PARAMETER_NAME = ''ACCT_YR''


SELECT @TO=PARAMETER_VALUE 
FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = ''CLS''
AND PARAMETER_NAME = ''IN_DESTINATION_SYSOWNER''

PRINT ''FISCAL PERIOD BEFORE CLOSE IS '' + CAST(@MO AS VARCHAR) + '':'' + CAST(@YR AS VARCHAR)

SET @MO = @MO + 1

IF @MO = 13
  BEGIN

    -- additional year end step.  truncate LM YTD table that we just put data into
    -- so that both TM YTD and LM YTD are empty.
    TRUNCATE TABLE IMAPSSTG.DBO.XX_CLS_DOWN_LAST_MONTH_YTD

     SET @MO = 1
	SET @YR = @YR + 1
  END

UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
SET PARAMETER_VALUE = CAST(@MO AS VARCHAR(2))
WHERE INTERFACE_NAME_CD = ''CLS''
AND PARAMETER_NAME = ''ACCT_MO''

UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
SET PARAMETER_VALUE = CAST(@YR AS VARCHAR(4))
WHERE INTERFACE_NAME_CD = ''CLS''
AND PARAMETER_NAME = ''ACCT_YR''

PRINT ''FISCAL PERIOD AFTER CLOSE IS '' + CAST(@MO AS VARCHAR) + '':'' + CAST(@YR AS VARCHAR)

SET @BODY = ''The CLSDOWN period closeout has been run.  The accounting period is now set to '' + RIGHT(''000'' + CAST(@MO AS VARCHAR(2)),2) + ''/'' + CAST(@YR AS VARCHAR(4)) 
-- in case the new month is January
SET @BODY = REPLACE(@BODY,''01/'' + CAST(@YR AS VARCHAR(4)) ,''01/'' +  CAST(@YR AS VARCHAR) + ''. The tables have been prepared for the new year.  No AI is necessary.  '')
SET @BODY = @BODY + '' Message ID: ''


INSERT INTO IMAPSSTG.DBO.XX_IMAPS_MAIL_OUT (MESSAGE_TEXT,MESSAGE_SUBJECT,MAIL_TO_ADDRESS,ATTACHMENTS, STATUS_RECORD_NUM,CREATE_DT)
VALUES (@BODY,''CLSDOWN CLOSEOUT RUN'',@TO,NULL,@SRN,GETDATE())

', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'D:\IMAPS_Data\Interfaces\logs\CLS\CLS_Closeout.log', 
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


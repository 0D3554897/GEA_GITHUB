USE [msdb]
GO

/****** Object:  Job [D16  _AR Collection Reset (CCIS)]    Script Date: 5/1/2020 9:31:12 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 5/1/2020 9:31:12 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'D16  _AR Collection Reset (CCIS)', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DIV16\gealvare', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [RESET JOB STATUS]    Script Date: 5/1/2020 9:31:13 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'RESET JOB STATUS', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'PRINT ''****************************************************************''
PRINT ''               DEV and TEST ONLY STEPS  ''
PRINT ''****************************************************************''

PRINT ''Populate the Accounting Calendar''

DECLARE @cnt numeric, @SUMMARY_AMT numeric

SET @cnt = (select COUNT(*)
              from (select rowid, run_start_date, run_end_date
                      from dbo.XX_FIWLR_RUNDATE_ACCTCAL
                     where (LEN(run_start_date) + LEN(run_end_date)) = 20
                   ) a
             where CAST(a.run_start_date as datetime) <= GETDATE()
               and CAST(a.run_end_date as datetime) >= GETDATE() 
           )

IF @cnt = 0
   BEGIN
      PRINT ''Zero records found -- inserting''

      INSERT INTO imapsstg.dbo.XX_FIWLR_RUNDATE_ACCTCAL
         (fiscal_year,
          period,
          sub_pd_no,
          run_start_date,
          run_end_date,
          creation_date,
          created_by)
         VALUES
               (
	 CONVERT(varchar(4), getdate(), 112),  -- fy
    	 CONVERT(varchar(2), getdate(), 110),  -- pd
                 3, 			                -- subpd
                  CONVERT(varchar(4), getdate(), 112)
                    + ''-''
                    + CONVERT(varchar(2), getdate(), 110)
                    + ''-01'', 				  -- run_start_date, the first of this month
               CONVERT(varchar,
		DATEADD(DAY, -(DAY(DATEADD(MONTH, 1, getdate()))), DATEADD(MONTH, 1, GETDATE()) + 10),
                         	110),			  -- run_end_date, the last day of this month + 10 days
               getdate(),				  -- today
              ''FOR TESTING'')
   END

IF @cnt > 0
   PRINT ''Accounting calendar already populated''

SELECT @SUMMARY_AMT = SUM(TRN_AMT)
  FROM dbo.XX_AR_CASH_RECPT_TRN


     -- PRINT ''Unposted Cash Receipts exist.  Post first''
     PRINT ''DELETE UNPOSTED CASH RECEIPTS''

     DELETE dbo.XX_AR_CASH_RECPT_TRN
     DELETE dbo.XX_AR_CASH_RECPT_HDR
     DELETE IMAPS.Deltek.CASH_RECPT_HDR
     DELETE IMAPS.Deltek.CASH_RECPT_TRN
  
PRINT ''****************************************************************''
PRINT ''               DEV AND TEST ONLY STEPS COMPLETED ''
PRINT ''****************************************************************''



/**************************************************************************************

RESET THE JOB

**************************************************************************************/

-- BEFORE 
SELECT * FROM 
-- UPDATE
imapsstg.dbo.XX_IMAPS_INT_STATUS
-- SET STATUS_CODE = ''COMPLETED''
WHERE INTERFACE_NAME = ''AR_COLLECTION''
and STATUS_RECORD_NUM in 
(SELECT MAX(STATUS_RECORD_NUM) FROM imapsstg.dbo.XX_IMAPS_INT_STATUS 
  WHERE INTERFACE_NAME = ''AR_COLLECTION'') 


--UPDATE 
--SELECT * FROM 
UPDATE
imapsstg.dbo.XX_IMAPS_INT_STATUS
SET STATUS_CODE = ''COMPLETED'',
STATUS_DESCRIPTION = ''DEV RESET: RUN ENDED AT > '' + STATUS_DESCRIPTION
WHERE INTERFACE_NAME = ''AR_COLLECTION''
and STATUS_RECORD_NUM in 
(SELECT MAX(STATUS_RECORD_NUM) FROM imapsstg.dbo.XX_IMAPS_INT_STATUS 
  WHERE INTERFACE_NAME = ''AR_COLLECTION'') 

SELECT ''XX_IMAPS_INT_STATUS TABLE UPDATED'' AS UPDATE_STATUS
  
--AFTER   
SELECT * FROM 
-- UPDATE
imapsstg.dbo.XX_IMAPS_INT_STATUS
-- SET STATUS_CODE = ''COMPLETED''
WHERE INTERFACE_NAME = ''AR_COLLECTION''
and STATUS_RECORD_NUM in 
(SELECT MAX(STATUS_RECORD_NUM) FROM imapsstg.dbo.XX_IMAPS_INT_STATUS 
  WHERE INTERFACE_NAME = ''AR_COLLECTION'') 
  
', 
		@database_name=N'IMAPSStg', 
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



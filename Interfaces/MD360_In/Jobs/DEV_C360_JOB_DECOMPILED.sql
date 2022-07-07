USE [msdb]
GO

/****** Object:  Job [D16_C360_LOAD]    Script Date: 7/7/2022 11:27:19 AM ******/
EXEC msdb.dbo.sp_delete_job @job_id=N'2b3d5dd0-64f8-4555-b41d-4a18b01be2b0', @delete_unused_schedule=1
GO

/****** Object:  Job [D16_C360_LOAD]    Script Date: 7/7/2022 11:27:19 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [D16 - FEDERAL]    Script Date: 7/7/2022 11:27:19 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'D16 - FEDERAL' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'D16 - FEDERAL'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'D16_C360_LOAD', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'THIS JOB LOADS CUSTOMER DATA FROM MD360 DATABASE (SAME AS CREATE CMR) TO IMAPS

For support info, e.g. if we ever have to change the MD360 views: 

IMAPS CONFIG MANAGEMENT - MD360 <---- MD360 view source code in this folder

MD360 - https://w3.ibm.com/w3publisher/customer-master-data/operations/dous-and-slas

Art and Les (OPS) need to subscribe to CI-COM, it is a blog about downtime, notification, etc.  Here:

https://w3.ibm.com/w3publisher/cicomm/rd-customer-rdc

', 
		@category_name=N'D16 - FEDERAL', 
		@owner_login_name=N'DIV16\gealvare', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LOAD CMR]    Script Date: 7/7/2022 11:27:20 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'LOAD CMR', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/***
For support info, like if we ever have to change the views:  https://w3.ibm.com/w3publisher/customer-master-data/operations/dous-and-slas

Art and Les (OPS) need to subscribe to CI-COM, it is a blog about downtime, notification, etc.  Here:

https://w3.ibm.com/w3publisher/cicomm/rd-customer-rdc

***/

DECLARE @FCNT INTEGER, @CCNT INTEGER

PRINT ''DELETING RECORDS FROM NEW STAGE TABLE''		

DELETE FROM IMAPSSTG.DBO.XX_IMAPS_C360

PRINT ''INSERT FEDERAL CUSTOMERS FIRST''

INSERT INTO IMAPSSTG.DBO.XX_IMAPS_C360
SELECT 
   I_CUST_ENTITY,
   I_CO,
   I_ENT,
   N_ABBREV,
   I_CUST_ADDR_TYPE,
   ADDR1,
   ADDR2,
   ADDR3,
   ADDR4,
   N_CITY,
   N_ST,
   C_ZIP,
   SCC_ST,
   C_SCC_CNTY,
   C_SCC_CITY,
   I_MKTG_OFF,
   A_LEVEL_1_VALUE,
   PRIMARY_SVC_OFF,
   C_ICC_TE,
   C_ICC_TAX_CLASS,
   C_ESTAB_SIC,
   I_INDUS_DEPT,
   I_INDUS_CLASS,
   C_NAP,
   I_TYPE_CUST_1,
   F_GENRL_SVC_ADMIN,
   F_OCL,
   XMIT_DATE
FROM C360..SAPR3.V_CI_USCMR_IMAPS

SELECT @CCNT = COUNT(*) FROM IMAPSSTG.DBO.XX_IMAPS_C360

PRINT CAST(@CCNT AS VARCHAR(10)) = '' FEDERAL RECORDS INSERTED''

PRINT ''INSERT FDS/SABRIX CUSTOMER FAILURES NOT INCLUDED IN CURRENT FEDERAL DOWNLOAD''

DELETE FROM  IMAPSSTG.DBO.XX_IMAPS_CUSTOMER_FAILURES

INSERT INTO IMAPSSTG.DBO.XX_IMAPS_CUSTOMER_FAILURES
SELECT DISTINCT CUST_ADDR_DC
FROM 
(SELECT CAST(CUST_ADDR_DC AS VARCHAR(20)) AS CUST_ADDR_DC
FROM IMAPSSTG.DBO.XX_SABRIX_INV_OUT_SUM
WHERE STATUS_FL <> ''P''
UNION
SELECT CAST(CUST_ADDR_DC AS VARCHAR(20)) AS CUST_ADDR_DC
FROM IMAPSSTG.DBO.XX_IMAPS_INV_OUT_SUM
WHERE STATUS_FL <> ''P'') C
WHERE C.CUST_ADDR_DC NOT IN (SELECT I_CUST_ENTITY FROM IMAPSSTG.DBO.XX_IMAPS_C360)

INSERT INTO IMAPSSTG.DBO.XX_IMAPS_C360
SELECT 
   I_CUST_ENTITY,
   I_CO,
   I_ENT,
   N_ABBREV,
   I_CUST_ADDR_TYPE,
   ADDR1,
   ADDR2,
   ADDR3,
   ADDR4,
   N_CITY,
   N_ST,
   C_ZIP,
   SCC_ST,
   C_SCC_CNTY,
   C_SCC_CITY,
   I_MKTG_OFF,
   A_LEVEL_1_VALUE,
   PRIMARY_SVC_OFF,
   C_ICC_TE,
   C_ICC_TAX_CLASS,
   C_ESTAB_SIC,
   I_INDUS_DEPT,
   I_INDUS_CLASS,
   C_NAP,
   I_TYPE_CUST_1,
   F_GENRL_SVC_ADMIN,
   F_OCL,
   XMIT_DATE
FROM C360..SAPR3.V_CI_USCMR_IMAPS_NONFED
 WHERE 
 I_CUST_ENTITY_INT IN (SELECT I_CUST_ENTITY FROM IMAPSSTG.DBO.XX_IMAPS_CUSTOMER_FAILURES)

SELECT @FCNT = COUNT(*) FROM IMAPSSTG.DBO.XX_IMAPS_C360

IF @FCNT > @CCNT 
  BEGIN
	SET @FCNT = @FCNT - @CCNT
	PRINT CAST(@FCNT AS VARCHAR(10)) + '' NON-FEDERAL RECORDS INSERTED''
  END


IF @CCNT = 0
  BEGIN

    PRINT ''C360 RECORDS INSERT FAILED'' 


  END

IF @CCNT > 0
  BEGIN
    PRINT ''LOCAL COUNT TEST PASSED. RECORDS EXIST IN IMAPSSTG.DBO.XX_IMAPS_C360''

	DELETE FROM IMAPSSTG.DBO.XX_IMAPS_CMR_STG;

	INSERT INTO IMAPSSTG.DBO.XX_IMAPS_CMR_STG
		(I_CUST_ENTITY,
		I_CO,
		I_ENT,
		N_ABBREV,
		I_CUST_ADDR_TYPE,
		T_ADDR_LINE_1,
		T_ADDR_LINE_2,
		T_ADDR_LINE_3,
		T_ADDR_LINE_4,
		N_CITY,
		N_ST,
		C_ZIP,
		C_SCC_ST,
		C_SCC_CNTY,
		C_SCC_CITY,
		I_MKTG_OFF,
		A_LEVEL_1_VALUE,
		I_PRIMRY_SVC_OFF,
		C_ICC_TE,
		C_ICC_TAX_CLASS,
		C_ESTAB_SIC,
		I_INDUS_DEPT,
		I_INDUS_CLASS,
		C_NAP,
		I_TYPE_CUST_1,
		F_GENRL_SVC_ADMIN,
		F_OCL)
		SELECT --TOP 5 
		   CAST(I_CUST_ENTITY AS INT),
		   CAST(I_CO AS INT),
		   CAST(I_ENT AS INT),
		   LEFT(LTRIM(N_ABBREV),15),
		   LEFT(LTRIM(I_CUST_ADDR_TYPE),1),
		   ADDR_LINE_1,
		   ADDR_LINE_2,
		   ADDR_LINE_3,
		   ADDR_LINE_4,
		   LEFT(LTRIM(N_CITY),13),
		   LEFT(LTRIM(N_ST),2),
		   CASE
				WHEN  ISNUMERIC(C_ZIP) = 0 THEN 0
				ELSE  CAST(C_ZIP AS INT)
		   END AS I_ZIP,
		   C_SCC_ST,
		   C_SCC_CNTY,
		   C_SCC_CITY,
		   LEFT(LTRIM(I_MKTG_OFF),3),
		   A_LEVEL_1_VALUE,
		   LEFT(LTRIM(I_PRIMRY_SVC_OFF),3),
		   C_ICC_TE,
		   C_ICC_TAX_CLASS,
		   LEFT(LTRIM(C_ESTAB_SIC),4),
		   LEFT(LTRIM(I_INDUS_DEPT),1),
		   LEFT(LTRIM(I_INDUS_CLASS),1),
		   C_NAP,
		   LEFT(LTRIM(I_TYPE_CUST_1),1),
		   F_GENRL_SVC_ADMIN,
		   F_OCL
		  -- XMIT_DATE
		FROM  -- C360..SAPR3.V_CI_USCMR_IMAPS
		IMAPSSTG.DBO.XX_IMAPS_C360
		WHERE 1=1;
	END


SELECT @CCNT = COUNT(*) FROM IMAPSSTG.DBO.XX_IMAPS_C360


PRINT CAST(@CCNT AS VARCHAR(10)) = '' RECORDS INSERTED, JOB COMPLETE''






', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_DATA\Interfaces\logs\CMR\C360_LOG.TXT', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [FAILURE EMAIL]    Script Date: 7/7/2022 11:27:20 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'FAILURE EMAIL', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @MailTo                 varchar(300),
        @email_msg_text         varchar(3000),
        @email_msg_subject      varchar(100),
        @Server_Environment     varchar(20)
		
	SELECT @Server_Environment = PARAMETER_VALUE
	FROM   dbo.XX_PROCESSING_PARAMETERS
	WHERE  parameter_name = ''SERVER_ENVIRONMENT''
	
	SELECT @MailTo = PARAMETER_VALUE
	FROM   dbo.XX_PROCESSING_PARAMETERS
	WHERE  parameter_name = ''C360 ERROR MAIL''

    SET @email_msg_subject =  @Server_Environment + '' Notification - C360 INTERFACE FAILURE ''

	SET @email_msg_text = ''This message was generated by the IMAPS financial system resulting from execution of the C360 Inbound Interface.  The customer download failed.''
	
	SET @email_msg_text =	@email_msg_text + '' Please check the job log and/or job history for details.  Do not reply to this message. ''

	INSERT INTO dbo.XX_IMAPS_MAIL_OUT
   (MESSAGE_TEXT, MESSAGE_SUBJECT, MAIL_TO_ADDRESS, ATTACHMENTS, STATUS_RECORD_NUM)
   VALUES(@email_msg_text, @email_msg_subject, @MailTo, '''',0)


PRINT ''FAILURE EMAIL SENT - REVIEW JOB LOGS FOR DETAIL''', 
		@database_name=N'IMAPSStg', 
		@output_file_name=N'T:\IMAPS_DATA\Interfaces\logs\CMR\C360_LOG.TXT', 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'TEST', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=127, 
		@freq_subday_type=8, 
		@freq_subday_interval=2, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20220624, 
		@active_end_date=20220722, 
		@active_start_time=200000, 
		@active_end_time=40500, 
		@schedule_uid=N'f72a22c9-f567-444a-9d4b-c3e9165f15f2'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



USE [msdb]
GO

/****** Object:  Job [D16_ SABRIX 0 - SETUP/RESET/CORRECT DATA]    Script Date: 08/15/2018 13:33:02 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/15/2018 13:33:02 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'D16_ SABRIX 0 - SETUP/RESET/CORRECT DATA', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'There are fiver tasks in this job, each must be run independently:  Most steps also contain before/after SQL if you want to examine results

1) Remove CSP invoices in "Already Sent" table.  A lot easier than creating new invoices

2) Remove REGULAR  invoices in "Already Sent" table.  A lot easier than creating new invoices

3) Reset a job after failure so it can be run again from the beginning.

4) Correct the out of balance error.  This script may need to be changed for SIT/PROD, but run as-is for', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DIV16\gealvare', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [****** NOTICE - THESE STEPS DO NOT RUN IN SEQUENCE.  THEY MUST BE RUN INDIVIDUALLY  **********]    Script Date: 08/15/2018 13:33:02 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'****** NOTICE - THESE STEPS DO NOT RUN IN SEQUENCE.  THEY MUST BE RUN INDIVIDUALLY  **********', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [REMOVE CSP INVOICES FROM ALREADY SENT TABLE]    Script Date: 08/15/2018 13:33:02 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'REMOVE CSP INVOICES FROM ALREADY SENT TABLE', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/**************************************************************************************

--  USE THE FOLLOWING QUERY TO CHOOSE INVOICES YOU''D LIKE TO INCLUDE IN TEST
--  DELETING THEM FROM SENT TABLE WILL ALLOW THEM TO BE PROCESSED AGAIN
--  IF YOU USE AND SAVE THIS SQL SEPARTELY, BE SURE TO KEEP THE INVOICE NUMBERS UNPOPULATED IN THE
--  WHERE CLAUSE.  THAT WAY, IT WON''T DELETE THE ENTIRE TABLE.

****************************************************************************************/

-- csp invoices with $0 invoice amounts
DELETE
FROM IMAPSSTG.dbo.XX_SABRIX_INVOICE_SENT
WHERE INVC_ID IN (''IBM-0002478577'',''IBM-0002478174'',''IBM-0002476233'',''IBM-0002476062'',''IBM-0002475906'',''IBM-0002475552'',''IBM-0002473563'',''IBM-0002472647'')


-- csp invoices with invoice amounts
DELETE
FROM IMAPSSTG.dbo.XX_SABRIX_INVOICE_SENT
WHERE INVC_ID IN (''IBM-0002478896'',''IBM-0002478895'')
', 
		@database_name=N'IMAPSStg', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [REMOVE NORMAL INVOICES FROM ALREADY SENT TABLE]    Script Date: 08/15/2018 13:33:02 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'REMOVE NORMAL INVOICES FROM ALREADY SENT TABLE', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/**************************************************************************************

--  USE THE FOLLOWING QUERY TO CHOOSE INVOICES YOU''D LIKE TO INCLUDE IN TEST
--  DELETING THEM FROM SENT TABLE WILL ALLOW THEM TO BE PROCESSED AGAIN
--  IF YOU USE AND SAVE THIS SQL SEPARTELY, BE SURE TO KEEP THE INVOICE NUMBERS UNPOPULATED IN THE
--  WHERE CLAUSE.  THAT WAY, IT WON''T DELETE THE ENTIRE TABLE.

****************************************************************************************/
DELETE
FROM IMAPSSTG.dbo.XX_SABRIX_INVOICE_SENT
WHERE INVC_ID IN (''IBM-0002479274'',''IBM-0002479298'',''IBM-0002479304'')


DELETE
FROM IMAPSSTG.dbo.XX_SABRIX_INVOICE_SENT
WHERE INVC_ID IN (''IBM-0002479111'',''IBM-0002479112'',''IBM-0002479114'',''IBM-0002479120'',''IBM-0002479121''  )


', 
		@database_name=N'IMAPSStg', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [RESET STATUS TABLE FOR FAILED JOB TO ALLOW START FROM SCRATCH]    Script Date: 08/15/2018 13:33:02 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'RESET STATUS TABLE FOR FAILED JOB TO ALLOW START FROM SCRATCH', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- BEFORE 
SELECT * FROM 
-- UPDATE
imapsstg.dbo.XX_IMAPS_INT_STATUS
-- SET STATUS_CODE = ''COMPLETED''
WHERE INTERFACE_NAME = ''SABRIX''
and STATUS_RECORD_NUM in 
(SELECT MAX(STATUS_RECORD_NUM) FROM imapsstg.dbo.XX_IMAPS_INT_STATUS 
  WHERE INTERFACE_NAME = ''SABRIX'') 


--UPDATE 
--SELECT * FROM 
UPDATE
imapsstg.dbo.XX_IMAPS_INT_STATUS
SET STATUS_CODE = ''COMPLETED'',
STATUS_DESCRIPTION = ''DEV RESET: RUN ENDED AT > '' + STATUS_DESCRIPTION
WHERE INTERFACE_NAME = ''SABRIX''
and STATUS_RECORD_NUM in 
(SELECT MAX(STATUS_RECORD_NUM) FROM imapsstg.dbo.XX_IMAPS_INT_STATUS 
  WHERE INTERFACE_NAME = ''SABRIX'') 

SELECT ''XX_IMAPS_INT_STATUS TABLE UPDATED'' AS UPDATE_STATUS
  
--AFTER   
SELECT * FROM 
-- UPDATE
imapsstg.dbo.XX_IMAPS_INT_STATUS
-- SET STATUS_CODE = ''COMPLETED''
WHERE INTERFACE_NAME = ''SABRIX''
and STATUS_RECORD_NUM in 
(SELECT MAX(STATUS_RECORD_NUM) FROM imapsstg.dbo.XX_IMAPS_INT_STATUS 
  WHERE INTERFACE_NAME = ''SABRIX'') 
  
SELECT COUNT(*) FROM IMAPSSTG.dbo.XX_SABRIX_INVOICE_SENT', 
		@database_name=N'IMAPSStg', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CORRECT OUT OF BALANCE ERROR]    Script Date: 08/15/2018 13:33:02 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'CORRECT OUT OF BALANCE ERROR', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/******************************************

Script can be found in: D:\DEV_SHARE\FDS-CCS Out-Of-Balance Error Handling SQL

 INSTRUCTIONS
 1) UNLESS RUNNING FROM JOB, MAKE YOUR OWN COPY OF THIS FILE RIGHT NOW. DON''T CHANGE JOB IN DEV, JUST RUN IT
 2) DON''T CHANGE BACKUP SECTION
 3) REVIEW ALL DROP STATEMENTS IN SAVE SECTION
 4) IF YOU DROP TABLES, THEN LEAVE DEFAULTS (PREFERRED)
    IF YOU DON''T, THEN CHANGE CREATE TABLES TO INSERTS
 5) USE OPTIONAL PREVENT TABLE INSERT CODE TO PREVENT THESE INVOICES FROM PROCESSING AGAIN
    COMMENT THIS INSERT CODE OUT, AND INVOICES WILL BE INCLUDED IN NEXT RUN
 6) AFTER ANY CHANGES, SAVE AGAIN IN YOUR SEPARATE FILE AND RUN THE STATEMENTS
 7) STATISTICS ARE PROVIDED AT THE END:
    COUNT, SUM OF REMAINING INVOICE HEADERS TO BE PROCESSED
    COUNT, SUM OF REMAINING INVOICE DETAIL TO BE PROCESSED - SUM SHOULD MATCH HEADERS
    COUNT, SUM OF INVOICE HEADERS SAVED FOR OUT OF BALANCE HEADER
    COUNT, SUM OF INVOICE DETAILS SAVED FOR OUT OF BALANCE DETAIL
    INVC_ID, COUNT, SUM OF HEADER, SUM OF DETAILS, DIFFERENCE REMAINING TO BE PROCESSED. SHOULD BE NONE.

******************************************/



/******************************************

 FIRST, BACKUP TABLE

******************************************/


-- for SAFETY, make a backup copy of sum and detail tables

drop table IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum_BAK

select * into IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum_BAK
from IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum	


drop table IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl_BAK

select * into IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl_BAK
from IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl

/******************************************

 NEXT, SAVE ALL OFFENDING RECORDS 
   IN OUT OF BALANCE TABLES

******************************************/

-- Type 1: mismatches where invoice_id exists in both, but invoice doesn''t balance

-- optional drop table:
drop table  IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum_oob

-- insert or create (default). to insert, remove comments from insert line, comment out select * line
-- insert
select * 
into IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum_oob
-- invoice headers where there are no detail records
-- delete 
from IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum	
where INVC_ID not in 
(select a.invc_id
--,  COUNT(*), avg(a.invc_amt), SUM(b.BILLED_AMT) ,  avg(a.invc_amt) - SUM(b.BILLED_AMT) as diff
from IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum a
inner join 	IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl	b 
on a.INVC_ID = b.INVC_ID
group by a.INVC_ID)

-- optional drop table:
drop table  IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl_oob

-- insert or create (default). to insert, remove comments from insert line, comment out select * line
-- insert
select * 
into IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl_oob
-- invoice detail where matching detail records exist, but are out of balance
-- delete
from IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl		
where INVC_ID in 
(select INVC_ID from 
(select a.invc_id
,  COUNT(*) as cnt, avg(a.invc_amt) as amt, SUM(b.BILLED_AMT) as billed ,  avg(a.invc_amt) - SUM(b.BILLED_AMT) as diff
from IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum a
inner join 	IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl	b 
on a.INVC_ID = b.INVC_ID
group by a.INVC_ID) a
where a.diff <> 0 )

-- add invoice headers where invoice number may exist in oob_detail but not in oob_header

insert into IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum_oob
select * 
from IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum	
where INVC_ID in
-- invoice id in detail_oob not in header_oob
(select b.invc_id from IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum a
left outer join IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl b
on a.INVC_ID = b.invc_id
where a.INVC_ID is NULL) 

-- add invoice detail where invoice number may exist in oob_header but not in oob_detail
set identity_insert IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl_oob ON

insert into IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl_oob
(CUST_ID, PROJ_ID, PROJ_ABBRV_CD, INVC_ID, INVC_DT, INVC_LN, CLIN_ID, ACCT_ID, TRN_DESC, TS_DT, BILL_RT_AMT, BILLED_HRS, RI_BILLABLE_CHG_CD, I_MACH_TYPE, M_PRODUCT_CODE, BILLED_AMT, RTNGE_AMT, ID, NAME, BILL_LAB_CAT_CD, BILL_LAB_CAT_DESC, BILL_FM_GRP_NO, BILL_FM_GRP_LBL, BILL_FM_LN_NO, BILL_FM_LN_LBL, CUM_BILLED_HRS, CUM_BILLED_AMT, TC_AGRMNT, TC_PROD_CATGRY, TC_TAX, TA_BASIC, RF_GSA_INDICATOR, SALES_TAX_AMT, STATE_SALES_TAX_AMT, COUNTY_SALES_TAX_AMT, CITY_SALES_TAX_AMT, SALES_TAX_CD)
select CUST_ID, PROJ_ID, PROJ_ABBRV_CD, INVC_ID, INVC_DT, INVC_LN, CLIN_ID, ACCT_ID, TRN_DESC, TS_DT, BILL_RT_AMT, BILLED_HRS, RI_BILLABLE_CHG_CD, I_MACH_TYPE, M_PRODUCT_CODE, BILLED_AMT, RTNGE_AMT, ID, NAME, BILL_LAB_CAT_CD, BILL_LAB_CAT_DESC, BILL_FM_GRP_NO, BILL_FM_GRP_LBL, BILL_FM_LN_NO, BILL_FM_LN_LBL, CUM_BILLED_HRS, CUM_BILLED_AMT, TC_AGRMNT, TC_PROD_CATGRY, TC_TAX, TA_BASIC, RF_GSA_INDICATOR, SALES_TAX_AMT, STATE_SALES_TAX_AMT, COUNTY_SALES_TAX_AMT, CITY_SALES_TAX_AMT, SALES_TAX_CD
from IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl	
where INVC_ID in  
--invoice id in header_oob not in detail_oob
(select a.invc_id from IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum_oob a
right outer join IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl_oob b
on a.INVC_ID = b.invc_id
where b.INVC_ID is NULL)

-- Type 2: add invoice headers where missing from detail
insert into IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum_oob
select * 
from IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum	
where INVC_ID in
-- invoice id in header not in detail
(select a.invc_id from IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum a
left outer join IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl b
on a.INVC_ID = b.invc_id
where b.INVC_ID is NULL)

-- Type 3: add invoice detail where missing from header
set identity_insert IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl_oob ON

insert into IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl_oob
(CUST_ID, PROJ_ID, PROJ_ABBRV_CD, INVC_ID, INVC_DT, INVC_LN, CLIN_ID, ACCT_ID, TRN_DESC, TS_DT, BILL_RT_AMT, BILLED_HRS, RI_BILLABLE_CHG_CD, I_MACH_TYPE, M_PRODUCT_CODE, BILLED_AMT, RTNGE_AMT, ID, NAME, BILL_LAB_CAT_CD, BILL_LAB_CAT_DESC, BILL_FM_GRP_NO, BILL_FM_GRP_LBL, BILL_FM_LN_NO, BILL_FM_LN_LBL, CUM_BILLED_HRS, CUM_BILLED_AMT, TC_AGRMNT, TC_PROD_CATGRY, TC_TAX, TA_BASIC, RF_GSA_INDICATOR, SALES_TAX_AMT, STATE_SALES_TAX_AMT, COUNTY_SALES_TAX_AMT, CITY_SALES_TAX_AMT, SALES_TAX_CD)
select CUST_ID, PROJ_ID, PROJ_ABBRV_CD, INVC_ID, INVC_DT, INVC_LN, CLIN_ID, ACCT_ID, TRN_DESC, TS_DT, BILL_RT_AMT, BILLED_HRS, RI_BILLABLE_CHG_CD, I_MACH_TYPE, M_PRODUCT_CODE, BILLED_AMT, RTNGE_AMT, ID, NAME, BILL_LAB_CAT_CD, BILL_LAB_CAT_DESC, BILL_FM_GRP_NO, BILL_FM_GRP_LBL, BILL_FM_LN_NO, BILL_FM_LN_LBL, CUM_BILLED_HRS, CUM_BILLED_AMT, TC_AGRMNT, TC_PROD_CATGRY, TC_TAX, TA_BASIC, RF_GSA_INDICATOR, SALES_TAX_AMT, STATE_SALES_TAX_AMT, COUNTY_SALES_TAX_AMT, CITY_SALES_TAX_AMT, SALES_TAX_CD
from IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl	
where INVC_ID in
-- invoice id in detail not in header
(select b.invc_id from IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum a
left outer join IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl b
on a.INVC_ID = b.invc_id
where a.INVC_ID is NULL)

/******************************************

 MEXT, DELETE ALL OFFENDING RECORDS

******************************************/

-- invoice headers in the oob table
delete 
from IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum	
where INVC_ID in 
(select a.invc_id
from IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum_oob a
group by a.INVC_ID)

-- detail records in the oob table
delete 
from IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl		
where INVC_ID in 
(select a.invc_id
--,  COUNT(*) as cnt, avg(a.invc_amt) as amt, SUM(b.BILLED_AMT) as billed ,  avg(a.invc_amt) - SUM(b.BILLED_AMT) as diff
from IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl_oob a
group by a.INVC_ID) 

/******************************************

 END DELETE ALL OFFENDING RECORDS

******************************************/

/******************************************

  OPTIONAL : INSERT INVC_ID IN PREVENT TABLE
  SO YOU NEVER PULL THEM IN AGAIN 

******************************************/

INSERT INTO imapsstg.dbo.XX_SABRIX_INVOICE_SENT
   (CUST_ID, PROJ_ID, INVC_ID, INVC_AMT, INVC_DT, STATUS_RECORD_NUM, DIVISION)
   SELECT CUST_ID, PROJ_ID, INVC_ID, INVC_AMT, INVC_DT, STATUS_RECORD_NUM, DIVISION
     FROM dbo.XX_SABRIX_INV_OUT_SUM_oob
     
     
/******************************************

  Statistics

******************************************/

SELECT ''STATISTICS ARE PROVIDED BELOW'' AS RECORD_STATISTICS

select COUNT(*) as hdr_cnt, SUM(invc_AMT)as hdr_sum from IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum	

select COUNT(*) as dtl_cnt, SUM(BILLED_AMT) as dtl_sum from IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl	

select COUNT(*) as oob_hdr_cnt, SUM(invc_AMT)as hdr_sum from IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum_oob	

select COUNT(*) as oob_dtl_cnt, SUM(BILLED_AMT) as dtl_sum from IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl_oob	

select * from 
(select a.invc_id as oob_invc_id,
COUNT(*) as oob_cnt, avg(a.invc_amt) as hdr, SUM(b.BILLED_AMT) as dtl ,  avg(a.invc_amt) - SUM(b.BILLED_AMT) as diff
from IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum a
inner join 	IMAPSStg.dbo.XX_SABRIX_INV_OUT_dtl b 
on a.INVC_ID = b.INVC_ID
group by a.INVC_ID) x
where x.diff <> 0

select COUNT(*) as "Bad Invoices added to Prevention Table"
from imapsstg.dbo.XX_SABRIX_INVOICE_SENT
where INVC_ID in (select INVC_ID from IMAPSStg.dbo.XX_SABRIX_INV_OUT_sum_oob)



	
', 
		@database_name=N'IMAPSStg', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [RESET STATUS TABLE TO RETURN COMPLETED JOB TO START OF JOB 2 (CP 005)]    Script Date: 08/15/2018 13:33:02 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'RESET STATUS TABLE TO RETURN COMPLETED JOB TO START OF JOB 2 (CP 005)', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- BEFORE STATUS TABLE
SELECT * FROM 
-- UPDATE
imapsstg.dbo.XX_IMAPS_INT_STATUS
-- SET STATUS_CODE = ''IN PROGRESS''
WHERE INTERFACE_NAME = ''SABRIX''
and STATUS_RECORD_NUM in 
(SELECT MAX(STATUS_RECORD_NUM) FROM imapsstg.dbo.XX_IMAPS_INT_STATUS 
  WHERE INTERFACE_NAME = ''SABRIX'') 

-- BEFORE  CONTROL POINT                                   
SELECT t1.control_pt_id     AS "Last Success",
       t1.status_record_num AS "For Status Record Number",
       CREATED_DATE as "on this date/time"
FROM   dbo.xx_imaps_int_control t1
WHERE  t1.status_record_num = (SELECT t1.status_record_num
                               FROM   dbo.xx_imaps_int_status t1
                               WHERE  t1.interface_name = ''SABRIX''
                                      AND t1.created_date =
              (SELECT
              Max(t2.created_date)
                                 FROM   dbo.xx_imaps_int_status t2
                                 WHERE
              t2.interface_name = ''SABRIX''))
       AND t1.interface_name = ''SABRIX''
       AND t1.control_pt_status = ''SUCCESS''
       AND t1.control_record_num = (SELECT Max(t2.control_record_num)
                                    FROM   dbo.xx_imaps_int_control t2
                                    WHERE  t2.status_record_num =
                                           (SELECT t1.status_record_num
                                            FROM   dbo.xx_imaps_int_status t1
                                            WHERE  t1.interface_name = ''SABRIX''
                                                   AND t1.created_date =
                                                   (SELECT
                                                   Max(t2.created_date)
                                                                      FROM
                                                   dbo.xx_imaps_int_status t2
                                                                      WHERE
                                                   t2.interface_name = ''SABRIX''
                                                   ))
                                           AND t2.interface_name = ''SABRIX''
                                           AND t2.control_pt_status = ''SUCCESS'') 

-- UPDATE STATUS TABLE
UPDATE
imapsstg.dbo.XX_IMAPS_INT_STATUS
SET STATUS_CODE = ''IN PROGRESS'',
STATUS_DESCRIPTION = ''DEV RESET TO CONTROL POINT 5 '' 
WHERE INTERFACE_NAME = ''SABRIX''
and STATUS_RECORD_NUM in 
(SELECT MAX(STATUS_RECORD_NUM) FROM imapsstg.dbo.XX_IMAPS_INT_STATUS 
  WHERE INTERFACE_NAME = ''SABRIX'') 


-- UPDATE CONTROL POINT
UPDATE dbo.xx_imaps_int_control
SET CONTROL_PT_ID = ''SABRIX-005''
WHERE  status_record_num = 
  (SELECT t1.status_record_num FROM   dbo.xx_imaps_int_status t1 WHERE  t1.interface_name = ''SABRIX'' AND t1.created_date =
        (SELECT Max(t2.created_date) FROM   dbo.xx_imaps_int_status t2 WHERE t2.interface_name = ''SABRIX'')
   )
AND interface_name = ''SABRIX''
AND control_pt_status = ''SUCCESS''
AND control_record_num = 
   (SELECT Max(t2.control_record_num) FROM   dbo.xx_imaps_int_control t2 WHERE  t2.status_record_num =
           (SELECT t1.status_record_num FROM   dbo.xx_imaps_int_status t1 WHERE  t1.interface_name = ''SABRIX'' AND t1.created_date =
                   (SELECT max(t2.created_date) FROM dbo.xx_imaps_int_status t2 WHERE t2.interface_name = ''SABRIX'')
            )
            AND t2.interface_name = ''SABRIX''
            AND t2.control_pt_status = ''SUCCESS''
    )  


-- AFTER STATUS TABLE 
SELECT * FROM 
-- UPDATE
imapsstg.dbo.XX_IMAPS_INT_STATUS
-- SET STATUS_CODE = ''IN PROGRESS''
WHERE INTERFACE_NAME = ''SABRIX''
and STATUS_RECORD_NUM in 
(SELECT MAX(STATUS_RECORD_NUM) FROM imapsstg.dbo.XX_IMAPS_INT_STATUS 
  WHERE INTERFACE_NAME = ''SABRIX'') 


-- AFTER  CONTROL POINT                                      
SELECT t1.control_pt_id     AS "Last Success",
       t1.status_record_num AS "For Status Record Number",
       CREATED_DATE as "on this date/time"
FROM   dbo.xx_imaps_int_control t1
WHERE  t1.status_record_num = (SELECT t1.status_record_num
                               FROM   dbo.xx_imaps_int_status t1
                               WHERE  t1.interface_name = ''SABRIX''
                                      AND t1.created_date =
              (SELECT
              Max(t2.created_date)
                                 FROM   dbo.xx_imaps_int_status t2
                                 WHERE
              t2.interface_name = ''SABRIX''))
       AND t1.interface_name = ''SABRIX''
       AND t1.control_pt_status = ''SUCCESS''
       AND t1.control_record_num = (SELECT Max(t2.control_record_num)
                                    FROM   dbo.xx_imaps_int_control t2
                                    WHERE  t2.status_record_num =
                                           (SELECT t1.status_record_num
                                            FROM   dbo.xx_imaps_int_status t1
                                            WHERE  t1.interface_name = ''SABRIX''
                                                   AND t1.created_date =
                                                   (SELECT
                                                   Max(t2.created_date)
                                                                      FROM
                                                   dbo.xx_imaps_int_status t2
                                                                      WHERE
                                                   t2.interface_name = ''SABRIX''
                                                   ))
                                           AND t2.interface_name = ''SABRIX''
                                           AND t2.control_pt_status = ''SUCCESS'')', 
		@database_name=N'master', 
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



USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_SABRIX_RUN_INTERFACE_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 


 


CREATE PROCEDURE [dbo].[XX_SABRIX_RUN_INTERFACE_SP]
AS

/*****************************************************************************************************************
Name:       XX_SABRIX_RUN_INTERFACE_SP
Author:     GEA
Created:    08/15/2018
Purpose:    Driver stored procedure for IMAPS Division 16 AR Outbound SABRIX Interface.
Parameters: None

******************************************************************************************************************/



DECLARE @CMD							varchar(800),
		@SP_NAME                        sysname,
        @TOTAL_NUM_OF_EXEC_STEPS        integer,
        @STOPPED_AT						integer,
        @SERVER_NAME                    sysname,
        @IMAPS_DB_NAME                  sysname,
        @IMAPS_SCHEMA_OWNER             sysname,
        @SABRIX_INTERFACE_NAME          varchar(50),
        @OUTBOUND_INT_TYPE              char(1),
        @INT_SOURCE_SYSTEM              varchar(50),
        @INT_DEST_SYSTEM                varchar(50),
        @Data_FName                     sysname,
        @INTERFACE_FILE_NAME            varchar(100),
        @INT_SOURCE_OWNER               varchar(100),
        @INT_DEST_OWNER                 varchar(300),
-- CR9449 Begin
        @TRANSFER_FILES                 sysname,
        @sp_exec_status                 varchar(20),   -- Values are 'TRUE' and 'FALSE'
        @NO_FILES_XFER_STEPS            integer,
        @no_files_xfer_exit             char(1),
        @INTERFACE_STATUS_IN_PROGRESS   varchar(20),
        @TOTAL_HDR_INVC_AMT             decimal(14, 2),
        @TOTAL_DTL_BILL_AMT             decimal(14, 2),
        @TOTAL_HDR_GLIM_AMT             decimal(14, 2),
        @TOTAL_DTL_GLIM_AMT             decimal(14, 2),        
        @transcount                     integer,
        @user_xact_state                integer,
-- CR9449 End
        @LOOKUP_DOMAIN_FCSCCS_CTRL_PT   varchar(30),
        @INTERFACE_STATUS_SUCCESS       varchar(20),
        @INTERFACE_STATUS_COMPLETED     varchar(20),
        @INTERFACE_STATUS_FAILED        varchar(20),

        @NUM_INVCS                      integer,
        @TOTAL_CCS                      decimal(14, 2),
        @TOTAL_FDS                      decimal(14, 2),
        @TOTAL_CSP                      decimal(14, 2),
        @TEST1                          decimal(14, 2),        
        @passed                         integer,
        @TEST2                          decimal(14, 2), 
        @TEST3                          decimal(14, 2), 
        @failed                         integer,
        @passed_amt                     decimal(14, 2),
        @failed_amt                     decimal(14, 2),

        @STATUS_RECORD_ERROR_DESC       varchar(250),
        @current_STATUS_RECORD_NUM      integer,
        @current_STATUS_DESCRIPTION     varchar(240),
        @last_issued_STATUS_RECORD_NUM  integer,       -- XX_IMAPS_INT_STATUS.STATUS_RECORD_NUM
        @last_issued_STATUS_CODE        varchar(20),   -- XX_IMAPS_INT_STATUS.STATUS_CODE
        @last_issued_CONTROL_PT_ID      varchar(20),   -- XX_IMAPS_INT_CONTROL.CONTROL_PT_ID
        @current_execution_step         integer,
        @execution_step_sp_name         sysname,
        @called_SP_name                 sysname,
        @current_CTRL_PT_ID             varchar(20),
		@ZERO                           INTEGER,

        @IMAPS_error_code               integer,
        @SQLServer_error_code           integer,
        @SQLServer_error_msg_text       varchar(275),
        @error_msg_placeholder1         sysname,
        @error_msg_placeholder2         sysname,
        @interface_status_desc_text     varchar(255),
        @ret_code                       integer,
        @row_count                      integer

-- Set local constants
 
 
 
PRINT '' 
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_SABRIX_RUN_INTERFACE_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' 
-- *~^
SET @SP_NAME = 'XX_SABRIX_RUN_INTERFACE_SP'

SELECT @ZERO=SUM(COALESCE(DIFF,999)) FROM
(SELECT PARAMETER_VALUE - DBO.XX_SP_FINGERPRINT(PARAMETER_NAME) AS DIFF
FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS
WHERE PARAMETER_NAME LIKE '%XX_SABRIX%_SP')X

IF @ZERO <> 0
	BEGIN

	PRINT 'THE STORED PROCEDURES IN THE DATABASE ARE NOT UP TO DATE, OR THE CODE HAS BEEN MODIFIED'
	PRINT 'ERROR NUMBER: ' + CAST(@ZERO AS VARCHAR)
	PRINT 'CHECK THESE VALUES AGAINST DEV/CLEAR CASE'
	PRINT 'SELECT * FROM (SELECT PARAMETER_NAME, PARAMETER_VALUE, DBO.XX_SP_FINGERPRINT(PARAMETER_NAME) CALC, PARAMETER_VALUE - DBO.XX_SP_FINGERPRINT(PARAMETER_NAME) AS DIFF
FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS WHERE PARAMETER_NAME LIKE ''%XX_SABRIX%_SP'')A WHERE DIFF<>0'


	-- Attempt to insert a record in table XX_SABRIX_INV_OUT_SUM_DTLS_STG failed.
    -- optional placeholders
	--SET @error_msg_placeholder1 = 'run'
	--SET @error_msg_placeholder2 = 'with latest source code'

 
	EXEC dbo.XX_ERROR_MSG_DETAIL
		@in_error_code           = 566,
		@in_display_requested    = 0,
		@in_SQLServer_error_code = @ZERO,
		@in_placeholder_value1   = @error_msg_placeholder1,
		@in_placeholder_value2   = @error_msg_placeholder2,
		@in_calling_object_name  = @SP_NAME,
		@out_msg_text            = @current_STATUS_DESCRIPTION OUTPUT

	GOTO BL_ERROR_HANDLER
	END


SET @TOTAL_NUM_OF_EXEC_STEPS = 7 /***** CHANGE THIS WHEN YOU CHANGE CONTROL POINTS *******/
SET @NO_FILES_XFER_STEPS = 5
SET @STOPPED_AT = @TOTAL_NUM_OF_EXEC_STEPS -@NO_FILES_XFER_STEPS
SET @sp_exec_status = 'TRUE'
SET @INTERFACE_STATUS_IN_PROGRESS = 'IN_PROGRESS'
SET @no_files_xfer_exit = 'N'
SET @transcount = @@TRANCOUNT

SET @SERVER_NAME = @@servername
SET @IMAPS_DB_NAME = db_name()
SET @SABRIX_INTERFACE_NAME = 'SABRIX'
SET @INT_SOURCE_SYSTEM = 'IMAPS'
SET @INT_DEST_SYSTEM = 'SABRIX'
SET @LOOKUP_DOMAIN_FCSCCS_CTRL_PT = 'LD_SABRIX_FEED_CTRL_PT'
SET @INTERFACE_STATUS_SUCCESS = 'SUCCESS'
SET @INTERFACE_STATUS_COMPLETED = 'COMPLETED'
SET @INTERFACE_STATUS_FAILED = 'FAILED'
SET @OUTBOUND_INT_TYPE = 'O'
SET @IMAPS_SCHEMA_OWNER = 'N/A'
SET @Data_Fname = 'N/A'

SET @STATUS_RECORD_ERROR_DESC = 'UNABLE TO CREATE A NEW XX_IMAPS_INT_STATUS RECORD'
SET @IMAPS_error_code = 204 -- Attempt to %1 %2 failed.

SET NOCOUNT ON

PRINT 'Retrieve necessary parameter data to run the SABRIX interface ...'
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 138 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
SELECT @INT_SOURCE_OWNER = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'INT_SRC_OWNER'
   AND INTERFACE_NAME_CD = @SABRIX_INTERFACE_NAME


 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 148 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
SELECT @INT_DEST_OWNER = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'INT_DEST_OWNER'
   AND INTERFACE_NAME_CD = @SABRIX_INTERFACE_NAME
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 160 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
SELECT @TRANSFER_FILES = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = @SABRIX_INTERFACE_NAME
   AND PARAMETER_NAME = 'TRANSFER_FILES'

/*
 * Check status of the last interface job: if it is not completed, perform recovery
 * by picking up processing from the last successful control point.
 */

PRINT 'Check status of the last interface job ...'

-- Retrieve the execution result data of the last interface run or job
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 181 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
SELECT @last_issued_STATUS_RECORD_NUM = t1.STATUS_RECORD_NUM,
       @last_issued_STATUS_CODE = t1.STATUS_CODE
  FROM dbo.XX_IMAPS_INT_STATUS t1
 WHERE t1.INTERFACE_NAME = @SABRIX_INTERFACE_NAME
   AND t1.CREATED_DATE   = (SELECT MAX(t2.CREATED_DATE) 
                              FROM dbo.XX_IMAPS_INT_STATUS t2
                             WHERE t2.INTERFACE_NAME = @SABRIX_INTERFACE_NAME)

SET @SQLServer_error_code = @@ERROR
SET @row_count = @@ROWCOUNT

IF @SQLServer_error_code > 0 OR @row_count > 1
   GOTO BL_ERROR_HANDLER

IF @last_issued_STATUS_RECORD_NUM IS NULL
   BEGIN
      -- This may well be the interface's very first run.
      PRINT 'There wasn''t any last interface job to consider.'

      -- Double-check
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 207 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
      SELECT @row_count = COUNT(1)
        FROM dbo.XX_IMAPS_INT_STATUS
       WHERE INTERFACE_NAME = @SABRIX_INTERFACE_NAME

      IF @row_count = 0
         -- Set default value for last interface job's status
         SET @last_issued_STATUS_CODE = @INTERFACE_STATUS_COMPLETED
      ELSE
         GOTO BL_ERROR_HANDLER
   END

IF @last_issued_STATUS_CODE <> @INTERFACE_STATUS_COMPLETED -- e.g., INITIATED, SUCCESS, FAILED
   BEGIN
      PRINT 'The last interface job was incomplete. Determine the next execution step ...'

      -- Retrieve data recorded for the last successful control point	
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 229 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
      SELECT @last_issued_CONTROL_PT_ID = t1.CONTROL_PT_ID
        FROM dbo.XX_IMAPS_INT_CONTROL t1
       WHERE t1.STATUS_RECORD_NUM  = @last_issued_STATUS_RECORD_NUM
         AND t1.INTERFACE_NAME     = @SABRIX_INTERFACE_NAME
         AND t1.CONTROL_PT_STATUS  = @INTERFACE_STATUS_SUCCESS
         AND t1.CONTROL_RECORD_NUM = (select MAX(t2.CONTROL_RECORD_NUM) 
                                        from dbo.XX_IMAPS_INT_CONTROL t2
                                       where t2.STATUS_RECORD_NUM = @last_issued_STATUS_RECORD_NUM
                                         and t2.INTERFACE_NAME    = @SABRIX_INTERFACE_NAME
                                         and t2.CONTROL_PT_STATUS = @INTERFACE_STATUS_SUCCESS)

      -- No control point was ever passed successfully
      IF @last_issued_CONTROL_PT_ID IS NULL
        BEGIN
         SET @current_execution_step = 1
         PRINT 'The last control point recorded does not exist'
        END
      ELSE
         -- At least one control point was passed successfully
         -- Determine the next execution step where the interface run resumes
         PRINT 'The current STATUS_RECORD_NUM IS ' + CAST(@last_issued_STATUS_RECORD_NUM as varchar) + ' and the last successful control point is ' + cast(@last_issued_CONTROL_PT_ID as varchar) 
         -- Special case: Control point 4 was incomplete and is performed again for the TRANSFER_FILES = 'YES' logic
         IF @last_issued_STATUS_CODE = @INTERFACE_STATUS_IN_PROGRESS AND @TRANSFER_FILES = 'YES'
            BEGIN
                SET @current_execution_step = 6
            END
         ELSE 
            SELECT @current_execution_step = t1.PRESENTATION_ORDER + 1
              FROM dbo.XX_LOOKUP_DETAIL t1,
                   dbo.XX_LOOKUP_DOMAIN t2
             WHERE t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
               AND t1.APPLICATION_CODE = @last_issued_CONTROL_PT_ID
               AND t2.DOMAIN_CONSTANT  = @LOOKUP_DOMAIN_FCSCCS_CTRL_PT

      SET @current_STATUS_RECORD_NUM = @last_issued_STATUS_RECORD_NUM
   END
ELSE
   BEGIN
      -- May now proceed with the current interface job
      PRINT 'JOB EXECUTION STARTING OVER AT STEP 1'
      SET @current_execution_step = 1
   END

IF @current_STATUS_RECORD_NUM IS NULL -- this is the very first time that this interface job is run
   BEGIN
      -- Begin processing for the current SABRIX interface run ...
      PRINT 'Begin processing for the current ' + @SABRIX_INTERFACE_NAME + ' interface run ...'

      /*
       * Call XX_INSERT_INT_STATUS_RECORD to get a value issued for XX_IMAPS_INT_STATUS.STATUS_RECORD_NUM.
       * Each interface run has exactly one XX_IMAPS_INT_STATUS record created and subsequently updated
       * as many times as needed. When first created, XX_IMAPS_INT_STATUS.STATUS_CODE = 'INITIATED'.
       */ 

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 286 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
      EXEC @ret_code = dbo.XX_INSERT_INT_STATUS_RECORD
         @in_IMAPS_db_name      = @IMAPS_DB_NAME,
         @in_IMAPS_table_owner  = @IMAPS_SCHEMA_OWNER,
         @in_int_name           = @SABRIX_INTERFACE_NAME,
         @in_int_type           = @OUTBOUND_INT_TYPE,
         @in_int_source_sys     = @INT_SOURCE_SYSTEM,
         @in_int_dest_sys       = @INT_DEST_SYSTEM,
         @in_Data_FName         = @Data_Fname,
         @in_int_source_owner   = @INT_SOURCE_OWNER,
         @in_int_dest_owner     = @INT_DEST_OWNER,
         @out_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM OUTPUT

      IF @ret_code <> 0
         BEGIN
            INSERT INTO dbo.XX_IMAPS_INV_ERROR (ERROR_DESC) VALUES (@STATUS_RECORD_ERROR_DESC)
            GOTO BL_ERROR_HANDLER
         END
   END

WHILE @current_execution_step <= @TOTAL_NUM_OF_EXEC_STEPS
   BEGIN
      -- For control point 7, instead of performing the e-mail notification process locally
      -- in the driver stored procedure, call a separate stored procedure to perform the same task.
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 315 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
      SELECT @execution_step_sp_name =
         CASE @current_execution_step
            WHEN 1 THEN 'dbo.XX_SABRIX_LOAD_SUM_SP'
            WHEN 2 THEN 'dbo.XX_SABRIX_VALIDATE_CMR_NUM_SP'
            WHEN 3 THEN 'dbo.XX_SABRIX_LOAD_DTL_SP'
            WHEN 4 THEN 'dbo.XX_SABRIX_CREATE_FILES_SP'
            WHEN 5 THEN 'dbo.XX_SABRIX_LOAD_SENT_SP'
            WHEN 6 THEN 'dbo.XX_SABRIX_FTP_FILE_SP'  
			WHEN 7 THEN 'dbo.XX_SABRIX_EMAIL_SP'

         END

      SET @called_SP_name = @execution_step_sp_name

      -- Get the control point ID associated with the current execution step
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 339 : XX_SABRIX_RUN_INTERFACE_SP.sql '  

 PRINT 'Current execution step is ' + cast(@current_execution_step as varchar)


      SELECT @current_CTRL_PT_ID = t1.APPLICATION_CODE
        FROM dbo.XX_LOOKUP_DETAIL t1,
             dbo.XX_LOOKUP_DOMAIN t2
       WHERE t1.LOOKUP_DOMAIN_ID   = t2.LOOKUP_DOMAIN_ID
         AND t1.PRESENTATION_ORDER = @current_execution_step
         AND t2.DOMAIN_CONSTANT    = @LOOKUP_DOMAIN_FCSCCS_CTRL_PT
         
         
      --set @CMD =  'SELECT ' + cast(@current_CTRL_PT_ID as varchar(10)) + ' = t1.APPLICATION_CODE FROM dbo.XX_LOOKUP_DETAIL t1, dbo.XX_LOOKUP_DOMAIN t2 WHERE t1.LOOKUP_DOMAIN_ID   = t2.LOOKUP_DOMAIN_ID  AND t1.PRESENTATION_ORDER = ' + cast(@current_execution_step as varchar(10)) + ' AND t2.DOMAIN_CONSTANT = ' + cast(@LOOKUP_DOMAIN_FCSCCS_CTRL_PT as varchar(10))
      --PRINT @CMD
     
      PRINT 'Now processing control point ' + @current_CTRL_PT_ID + ' ...'

      BEGIN TRANSACTION CURRENT_CTRL_PT

      IF @current_execution_step IN (1, 2, 3, 5)
         BEGIN
			EXEC @ret_code = @execution_step_sp_name
				@in_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM
				
				PRINT 'END OF CP ' + @current_CTRL_PT_ID   + ' and control point status is ' + @sp_exec_status
         END 
      ELSE IF @current_execution_step = 4
         BEGIN
            /*
             * Get Summary Details
             * @TOTAL_CCS, @TOTAL_FDS and @TOTAL_CSP are used to build the text string for XX_IMAPS_MAIL_OUT.MESSAGE_TEXT used by the final control point.
             * @NUM_INVCS is only captured once here and used in control points 4. 
			 * It is calculated again before control points 6, 7, 8 to determine if performing these control points is necessary.
             * It is calculated again in control point 9 for interface run status notification email.
             * Instead of relying on local variables, use a staging table to store the summary details such that they can be used anywhere and at any time
             * from control point 4 forward until the interface run is complete. In this way, when an interface recovery run is required, especially
             * when control point SABRIX-004 is not a part of the recovery, then the summary details are available.
             */

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 370 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
            SELECT @NUM_INVCS = COUNT(*), @TOTAL_CCS = SUM(INVC_AMT), @TOTAL_FDS = SUM(FDS_INV_AMT), @TOTAL_CSP = SUM(CSP_AMT)
              FROM dbo.XX_SABRIX_INV_OUT_SUM
             WHERE STATUS_FL = 'U'

            -- CHANGE KM 10/24/05: No New Invoices Passed Validations ... No Files Created/Sent
            IF @NUM_INVCS = 0
               BEGIN
                  SET @ret_code = 0
                  PRINT 'No New Invoices Passed Validations: Control point 4 is not executed'

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 385 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
                  INSERT INTO dbo.XX_SABRIX_INV_OUT_SUM_DTLS_STG (STATUS_RECORD_NUM, CTRL_PT4_RUN_FLAG, TOTAL_INVCS)
                     VALUES (@current_STATUS_RECORD_NUM, 'N', @NUM_INVCS)

                  SET @SQLServer_error_code = @@ERROR

                  IF @SQLServer_error_code <> 0
                     BEGIN
                        -- Attempt to insert a record in table XX_SABRIX_INV_OUT_SUM_DTLS_STG failed.
                        SET @error_msg_placeholder1 = 'insert'
                        SET @error_msg_placeholder2 = 'a record in table XX_SABRIX_INV_OUT_SUM_DTLS_STG'

                        EXEC dbo.XX_ERROR_MSG_DETAIL
                           @in_error_code           = @IMAPS_error_code,
                           @in_display_requested    = 1,
                           @in_SQLServer_error_code = @SQLServer_error_code,
                           @in_placeholder_value1   = @error_msg_placeholder1,
                           @in_placeholder_value2   = @error_msg_placeholder2,
                           @in_calling_object_name  = @SP_NAME,
                           @out_msg_text            = @current_STATUS_DESCRIPTION OUTPUT

                        GOTO BL_ERROR_HANDLER
                     END
               END
            ELSE
               BEGIN
-- 01/17/2018 HVT Begin
                  -- XX_SABRIX_INV_OUT_SUM records exist.
                  -- Check for $$ balance: Verify that header invoice amount total is equal to detail billed amount total
                  -- before allowing flat file creation process to commence.
                  -- test1: basic in balance test
                  PRINT ' '
                  PRINT cast(@NUM_INVCS as varchar(10)) + ' INVOICES FOUND. PROCESSING CONTINUES.'
                  PRINT ' '
                  
                  SELECT @TOTAL_HDR_INVC_AMT = SUM(INVC_AMT) FROM dbo.XX_SABRIX_INV_OUT_SUM WHERE STATUS_FL <> 'E' -- 03/27/2018 HVT
                  SELECT @TOTAL_DTL_BILL_AMT = SUM(BILLED_AMT) FROM dbo.XX_SABRIX_INV_OUT_DTL WHERE INVC_ID IN (SELECT INVC_ID FROM dbo.XX_SABRIX_INV_OUT_SUM WHERE STATUS_FL <> 'E')
				  SET @TEST1 = @TOTAL_HDR_INVC_AMT - @TOTAL_DTL_BILL_AMT
				  -- test2: GLIM in balance test
				  -- 7/19/2018 - next two lines addresses rare case (testing) when totals yield nulls by forcing zeroes
				  SELECT @TOTAL_HDR_GLIM_AMT = sum(coalesce(s.GLIMHDR,0)) from (select AVG(A.INVC_AMT - A.CSP_AMT) as GLIMHDR, a.invc_id from IMAPSSTG.DBO.XX_SABRIX_INV_OUT_SUM a inner join IMAPSSTG.DBO.XX_SABRIX_INV_OUT_DTL b on a.INVC_ID = b.INVC_ID  where (a.invc_amt-a.csp_amt) <> 0 AND A.STATUS_FL <> 'E' and b.BILLED_AMT <> 0 group by a.INVC_ID)s
				  SELECT @TOTAL_DTL_GLIM_AMT = SUM(coalesce(B.BILLED_AMT,0)) from IMAPSSTG.DBO.XX_SABRIX_INV_OUT_SUM a inner join IMAPSSTG.DBO.XX_SABRIX_INV_OUT_DTL b on a.INVC_ID = b.INVC_ID where (a.invc_amt-a.csp_amt) <> 0 AND A.STATUS_FL <> 'E' AND b.billed_amt <> 0 and coalesce(b. acct_id,'0') not in ('48-79-08','49-79-08')
				  SET @TEST2 = @TOTAL_HDR_GLIM_AMT - @TOTAL_DTL_GLIM_AMT
				  SET @TEST3 = @TEST1 + @TEST2
				  PRINT 'TESTING FOR OUT OF BALANCE CONDITIONS. ALL TESTS HAVE PASSED UNLESS OUT OF BALANCE ERROR IS DISPLAYED NEXT AND PROCESSING STOPS'
                  IF @TEST3 != 0
                     BEGIN
                        SET @interface_status_desc_text =
                               'DATA ERROR: Out of balance: Header invoice amount total is not equal to detail billed amount total. '
                               + 'Invoices Header = ' + CAST(ABS(@TOTAL_HDR_INVC_AMT) as VARCHAR(35))
                               + '; Invoices Detail = ' + CAST(ABS(@TOTAL_DTL_BILL_AMT) as VARCHAR(35))
                               + '; Invoices Difference = ' + CAST(ABS(@TEST1) as VARCHAR(35))

						PRINT @interface_status_desc_text

                        SET @interface_status_desc_text =
                               + ' SABRIX: Header SUM = ' + CAST(@TOTAL_HDR_GLIM_AMT AS VARCHAR(35))
                               + ', Detail SUM = ' + CAST(@TOTAL_DTL_GLIM_AMT AS VARCHAR(35))
                               + ', and SABRIX Difference = ' + CAST(ABS(@TEST2) as VARCHAR(35))
                               + '.'
                        PRINT @interface_status_desc_text
                        SET @interface_status_desc_text =
                               'REMEDY: For DEV OOB handling, go to D:\DEV_SHARE\SABRIX Out-Of-Balance Error Handling SQL\.'
                        PRINT @interface_status_desc_text

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 437 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
                        EXEC dbo.XX_ERROR_MSG_DETAIL
                           @in_error_code          = 556,
                           @in_display_requested   = 1,
                           @in_calling_object_name = @SP_NAME,
                           @out_msg_text           = @current_STATUS_DESCRIPTION OUTPUT

-- 03/27/2018 HVT Begin
                        -- Since CP4 will not be performed and although no SP was called, 
                        -- set @ret_code != 0 to simulate failed SP call
                        PRINT 'CP4 will not be performed and XX_AR_CREATE_SABRIX_FILES_SP was not called. See developer notes in source code.'
                        SET @ret_code = 1
-- 03/27/2018 HVT End
                        GOTO BL_ERROR_HANDLER
                     END
-- 01/17/2018 HVT End

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 452 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
                  TRUNCATE TABLE dbo.XX_SABRIX_INV_OUT_SUM_DTLS_STG


 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 459 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
                  INSERT INTO dbo.XX_SABRIX_INV_OUT_SUM_DTLS_STG
                     (STATUS_RECORD_NUM, CTRL_PT4_RUN_FLAG, TOTAL_INVCS, TOTAL_CCS, TOTAL_FDS, TOTAL_CSP)
                     VALUES(@current_STATUS_RECORD_NUM, 'Y', @NUM_INVCS, @TOTAL_CCS, @TOTAL_FDS, @TOTAL_CSP)

                  SET @SQLServer_error_code = @@ERROR

                  IF @SQLServer_error_code <> 0
                     BEGIN
                        -- Attempt to insert a record in table XX_SABRIX_INV_OUT_SUM_DTLS_STG failed.
                        SET @error_msg_placeholder1 = 'insert'
                        SET @error_msg_placeholder2 = 'a record in table XX_SABRIX_INV_OUT_SUM_DTLS_STG'

 
 
                        EXEC dbo.XX_ERROR_MSG_DETAIL
                           @in_error_code           = @IMAPS_error_code,
                           @in_display_requested    = 1,
                           @in_SQLServer_error_code = @SQLServer_error_code,
                           @in_placeholder_value1   = @error_msg_placeholder1,
                           @in_placeholder_value2   = @error_msg_placeholder2,
                           @in_calling_object_name  = @SP_NAME,
                           @out_msg_text            = @current_STATUS_DESCRIPTION OUTPUT

                        GOTO BL_ERROR_HANDLER
                     END

 
 
                  EXEC @ret_code = @execution_step_sp_name
                     @in_STATUS_REC_NUM = @current_STATUS_RECORD_NUM

                  IF @ret_code = 0
                     BEGIN
                        -- Update STATUS_FL from 'U' to 'P'
 
 
 
                        UPDATE dbo.XX_SABRIX_INV_OUT_SUM 
                           SET STATUS_FL = 'P'
                         WHERE STATUS_FL = 'U'

                        SET @SQLServer_error_code = @@ERROR
                        
                        IF @SQLServer_error_code <> 0
                           BEGIN
                              -- Attempt to update records in table XX_SABRIX_INV_OUT_SUM failed.
                              SET @error_msg_placeholder1 = 'update'
                              SET @error_msg_placeholder2 = 'records in table XX_SABRIX_INV_OUT_SUM'

 
 
                              EXEC dbo.XX_ERROR_MSG_DETAIL
                                 @in_error_code           = @IMAPS_error_code,
                                 @in_display_requested    = 1,
                                 @in_SQLServer_error_code = @SQLServer_error_code,
                                 @in_placeholder_value1   = @error_msg_placeholder1,
                                 @in_placeholder_value2   = @error_msg_placeholder2,
                                 @in_calling_object_name  = @SP_NAME,
                                 @out_msg_text            = @current_STATUS_DESCRIPTION OUTPUT

                              GOTO BL_ERROR_HANDLER
                           END

                        -- CHANGE KM 11/08/05
                        -- KEEP TRACK OF NUMBER OF INVOICES THAT PASSED/FAILED VALIDATION AND THE NUMBER OF INVOICES/DOLLAR AMOUNT THAT WAS PROCESSED
 
 
 
                        SELECT @passed = coalesce(COUNT(INVC_ID),0), @passed_amt = coalesce(SUM(INVC_AMT),0) FROM dbo.XX_SABRIX_INV_OUT_SUM WHERE STATUS_FL = 'P'
						SELECT @failed = coalesce(COUNT(INVC_ID),0), @failed_amt = coalesce(SUM(INVC_AMT),0) FROM dbo.XX_SABRIX_INV_OUT_SUM WHERE STATUS_FL <> 'P'
                     END
               END
               PRINT 'END OF CP 4 and control point status is ' + @sp_exec_status
         END
      
    
-- CR9449 Begin

      ELSE IF @current_execution_step IN (6)
         BEGIN
         
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 543 : XX_SABRIX_RUN_INTERFACE_SP.sql '  

       	   SELECT @NUM_INVCS = COUNT(*)
             FROM dbo.XX_SABRIX_INV_OUT_SUM
             WHERE STATUS_FL = 'P'
         
           IF @NUM_INVCS = 0
              BEGIN
               SET @sp_exec_status = 'FALSE'
               SET @ret_code = 0
              END
           ELSE 
            IF @NUM_INVCS != 0
              BEGIN
                IF @TRANSFER_FILES = 'YES'
                  BEGIN
                    PRINT '@TRANSFER_FILES = ' + @TRANSFER_FILES + ' -- ' + @execution_step_sp_name + ' is executed.'
                    EXEC @ret_code = @execution_step_sp_name
                       @in_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM,
                       @in_exec_mode = 'F' -- A = Archive file(s), F = FTP file(s)
                       
					   PRINT 'BACK IN XX_AR_SABRIX_RUN_INTERFACE'
                       PRINT 'FTP CHECK SUCCESS RETURN CODE IS ' + CAST(@RET_CODE AS VARCHAR)
                        IF @ret_code <> 0
                           BEGIN
                              -- Attempt to FTP to external IBM system failed. Check job log.
                              SET @error_msg_placeholder1 = 'update'
                              SET @error_msg_placeholder2 = 'to external IBM system failed. Check job log.'

                              EXEC dbo.XX_ERROR_MSG_DETAIL
                                 @in_error_code           = @ret_code,
                                 @in_display_requested    = 1,
                                 @in_SQLServer_error_code = 0,
                                 @in_placeholder_value1   = @error_msg_placeholder1,
                                 @in_placeholder_value2   = @error_msg_placeholder2,
                                 @in_calling_object_name  = @SP_NAME,
                                 @out_msg_text            = @current_STATUS_DESCRIPTION OUTPUT

                              GOTO BL_ERROR_HANDLER
                           END
                       PRINT 'FTP CHECK SUCCESS RETURN CODE IS ' + CAST(@RET_CODE AS VARCHAR)



                  END
                ELSE
                -- IF @TRANSER_FILES = NO
                  BEGIN
                    PRINT '@TRANSFER_FILES = ' + @TRANSFER_FILES + ' -- ' + @execution_step_sp_name + ' is not executed.'
                    SET @sp_exec_status = 'FALSE'
                    SET @ret_code = 0
                  END
               END
               PRINT 'END OF CP ' + @current_CTRL_PT_ID  + ' and control point status is ' + @sp_exec_status
           END
          
          
      ELSE IF @current_execution_step = 7 
         -- Only attempt control point 7 task once the interface run has successfully completed the FTP tasks of control points 6
        BEGIN
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 574 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
         SELECT @NUM_INVCS = COUNT(*)
           FROM dbo.XX_SABRIX_INV_OUT_SUM
           WHERE STATUS_FL = 'p'

         IF @TRANSFER_FILES = 'YES'
            BEGIN
               PRINT '@TRANSFER_FILES = ' + @TRANSFER_FILES + ' -- ' + @execution_step_sp_name + ' is executed.'
               EXEC @ret_code = @execution_step_sp_name
                  @in_STATUS_RECORD_NUM     = @current_STATUS_RECORD_NUM,
                  @out_SQLServer_error_code = @SQLServer_error_code OUTPUT,
                  @out_STATUS_DESCRIPTION   = @current_STATUS_DESCRIPTION OUTPUT
            END
         ELSE
            BEGIN
               PRINT '@TRANSFER_FILES = ' + @TRANSFER_FILES + ' -- ' + @execution_step_sp_name + ' is not executed.  Why not?'
               SET @sp_exec_status = 'FALSE'
               SET @ret_code = 0
            END
            PRINT 'END OF CP' +  @current_CTRL_PT_ID  + '  and sp_exec_status is '  + @sp_exec_status   
         END
       
         


      -- Either the SP call or the local processing of the control point failed. Both processing types return an error status.
      IF @ret_code <> 0
         BEGIN
            -- The attempted control point failed. Prepare interface status description
            SET @interface_status_desc_text = 'CONTROL POINT FAILURE: ' + @current_CTRL_PT_ID + ' - '
            SET @interface_status_desc_text =
               CASE @current_execution_step
                  WHEN 1 THEN @interface_status_desc_text + 'Loading invoice summary data'
                  WHEN 2 THEN @interface_status_desc_text + 'Validating CMR data'
                  WHEN 3 THEN @interface_status_desc_text + 'Loading invoice detail data'
                  WHEN 4 THEN @interface_status_desc_text + 'Creating and archiving SABRIX files'
                  WHEN 5 THEN @interface_status_desc_text + 'Adding XX_SABRIX_SENT records' -- sourced on XX_SABRIX_INV_OUT_SUM.STATUS_FL = 'P'
                  WHEN 6 THEN @interface_status_desc_text + 'FTP delivery of SABRIX file'
                  WHEN 7 THEN @interface_status_desc_text + 'Emailing control file and transaction report'
-- CR9449 End
               END

            ROLLBACK TRANSACTION CURRENT_CTRL_PT
            SET @SQLServer_error_code = 0
            GOTO BL_ERROR_HANDLER
         END
      ELSE
         BEGIN
            -- The SP call completed successfully. The attempted control point is successful.
            COMMIT TRANSACTION CURRENT_CTRL_PT
         END

 

      -- Insert a XX_IMAPS_INT_CONTROL record for the successfully completed control point
      IF @sp_exec_status = 'TRUE'
         BEGIN
            EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
               @in_int_ctrl_pt_num     = @current_execution_step,
               @in_lookup_domain_const = @LOOKUP_DOMAIN_FCSCCS_CTRL_PT,
               @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM

            IF @ret_code <> 0 GOTO BL_ERROR_HANDLER
         END

      PRINT 'Update the XX_IMAPS_INT_STATUS record with the latest control point processing result ...'

      SET @current_STATUS_DESCRIPTION = 'INFORMATION: Processing for control point ' + @current_CTRL_PT_ID + ' completed successfully.'

      -- Special case: When @TRANSFER_FILES = 'NO' and control point SABRIX-004 is successfully completed, begin program exit.
      IF @TRANSFER_FILES = 'NO' AND @current_execution_step = @NO_FILES_XFER_STEPS
         BEGIN
            SET @current_STATUS_DESCRIPTION = 'Control point SABRIX-005 is successful. Interface execution is incomplete. '
            SET @current_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION + 'There remain ' + CAST(@STOPPED_AT AS VARCHAR(2)) + ' control points to process.' 
            PRINT @current_STATUS_DESCRIPTION

 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 653 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
            EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
               @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
               @in_STATUS_CODE        = @INTERFACE_STATUS_IN_PROGRESS,
               @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION -- value is set right above

            SET @no_files_xfer_exit = 'Y'
         END
      ELSE
         BEGIN
            EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
               @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
               @in_STATUS_CODE        = @INTERFACE_STATUS_SUCCESS,
               @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION -- value is set right above

 
         END

      IF @ret_code <> 0 GOTO BL_ERROR_HANDLER

      SET @current_STATUS_DESCRIPTION = NULL -- reset for the next iteration
      PRINT 'TESTING FOR STOP'
      IF @TRANSFER_FILES = 'NO' AND @current_execution_step = @NO_FILES_XFER_STEPS
         SET @current_execution_step = 99 -- force exit of WHILE loop
      ELSE
         SET @current_execution_step = @current_execution_step + 1
         PRINT 'CURRENT NUMBER OF EXECUTION STEPS ARE : ' + CAST(@CURRENT_EXECUTION_STEP AS VARCHAR(10));
         PRINT 'TOTAL NUMBER OF EXECUTION STEPS ARE : ' + CAST(@TOTAL_NUM_OF_EXEC_STEPS AS VARCHAR(10));
   END /* WHILE @current_execution_step <= @TOTAL_NUM_OF_EXEC_STEPS */



-- Record interface run statistics
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 688 : XX_SABRIX_RUN_INTERFACE_SP.sql '  

SELECT @passed = coalesce(COUNT(INVC_ID),0), @passed_amt = coalesce(SUM(INVC_AMT),0) FROM dbo.XX_SABRIX_INV_OUT_SUM WHERE STATUS_FL = 'P'
SELECT @failed = coalesce(COUNT(INVC_ID),0), @failed_amt = coalesce(SUM(INVC_AMT),0) FROM dbo.XX_SABRIX_INV_OUT_SUM WHERE STATUS_FL <> 'P'

 
UPDATE dbo.XX_IMAPS_INT_STATUS
   SET RECORD_COUNT_INITIAL = @passed + @failed,
       RECORD_COUNT_SUCCESS = @passed,
       RECORD_COUNT_ERROR   = @failed,
       AMOUNT_INPUT         = @passed_amt + @failed_amt,
       AMOUNT_PROCESSED     = @passed_amt,
       AMOUNT_FAILED        = @failed_amt	
 WHERE STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to update a record in table XX_IMAPS_INT_STATUS failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'a record in table XX_IMAPS_INT_STATUS'


 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 710 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = @IMAPS_error_code,
         @in_display_requested    = 1,
         @in_SQLServer_error_code = @SQLServer_error_code,
         @in_placeholder_value1   = @error_msg_placeholder1,
         @in_placeholder_value2   = @error_msg_placeholder2,
         @in_calling_object_name  = @SP_NAME,
         @out_msg_text            = @current_STATUS_DESCRIPTION OUTPUT

      GOTO BL_ERROR_HANDLER
   END

IF @TRANSFER_FILES = 'YES' AND @no_files_xfer_exit = 'N'
   BEGIN
      PRINT 'Final update to XX_IMAPS_INT_STATUS ...'


 
      -- Mark the current interface run as completed
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 735 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
      EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
         @in_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM,
         @in_STATUS_CODE       = @INTERFACE_STATUS_COMPLETED

      IF @ret_code <> 0 GOTO BL_ERROR_HANDLER
   END

SET NOCOUNT OFF
RETURN(0)

BL_ERROR_HANDLER:

IF @ZERO <> 0 RETURN(ABS(@ZERO))


/*
 * SABRIX interface maintains its own error log table, XX_IMAPS_INV_ERROR, which is also used to record interface run errors,
 * specifically: UNABLE TO CREATE A NEW XX_IMAPS_INT_STATUS RECORD.
 * When the called SP returns status 1, it has already handled the error itself.
 * When the called SP returns status that is greater than 1, it did not complete the handling of the error itself.
 */
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 758 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
SELECT @transcount = @@TRANCOUNT, @user_xact_state = XACT_STATE()

-- Active committable user transaction exists & one or more BEGIN TRANSACTION statements were issued
IF @user_xact_state = 1 and @transcount > 0
   BEGIN
      COMMIT TRANSACTION CURRENT_CTRL_PT
      PRINT 'ON EXIT: XACT_STATE() = 1 and @@TRANCOUNT > 0'
   END

-- Special case
IF @ret_code = 1 AND @current_STATUS_DESCRIPTION is NULL 
   SET @ret_code = 301 -- An error has occured. Please contact system administrator.

IF @SQLServer_error_code != 0
   -- For errors from local processing of non-control point tasks that issues DML commands.
   -- This takes care of the case where @SQLServer_error_code != 0.
   BEGIN
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = @ret_code,
         @in_SQLServer_error_code = @SQLServer_error_code,
         @in_display_requested    = 1,
         @in_calling_object_name  = @called_SP_name,
         @out_msg_text            = @current_STATUS_DESCRIPTION OUTPUT, -- receive value returned by called SP
         @out_syserror_msg_text   = @SQLServer_error_msg_text OUTPUT

      -- Include details of error
      IF @SQLServer_error_msg_text is NOT NULL
         SET @current_STATUS_DESCRIPTION = RTRIM(@current_STATUS_DESCRIPTION) + ' ' + @SQLServer_error_msg_text
   END
ELSE
   SET @SQLServer_error_code = NULL

-- At least one control point was being processed when the error occurred.
-- For errors returned by the called SP: IF @ret_code <> 0
-- Use @current_STATUS_DESCRIPTION's value which is returned by the called SP.
IF @execution_step_sp_name IS NOT NULL
   BEGIN
      -- Update XX_IMAPS_INT_STATUS record
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 802 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
      EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
         @in_STATUS_RECORD_NUM  = @current_STATUS_RECORD_NUM,
         @in_STATUS_CODE        = @INTERFACE_STATUS_FAILED,
         @in_STATUS_DESCRIPTION = @current_STATUS_DESCRIPTION -- value is set right above

      -- Send interface run error notification e-mail
 
 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ SABRIX : Line 814 : XX_SABRIX_RUN_INTERFACE_SP.sql '  
 
     EXEC dbo.XX_SEND_STATUS_MAIL_SP        
        @in_StatusRecordNum = @current_STATUS_RECORD_NUM
         
         PRINT 'return code: '
         PRINT @ret_code
   END
   
PRINT  'end'

SET NOCOUNT OFF

RETURN(1)

 

 

 

 

 

 

 

GO
 


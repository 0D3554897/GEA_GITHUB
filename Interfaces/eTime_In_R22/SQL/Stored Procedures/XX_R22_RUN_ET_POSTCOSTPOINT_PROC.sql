IF OBJECT_ID('dbo.XX_R22_RUN_ET_POSTCOSTPOINT_PROC') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_RUN_ET_POSTCOSTPOINT_PROC
    IF OBJECT_ID('dbo.XX_R22_RUN_ET_POSTCOSTPOINT_PROC') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_RUN_ET_POSTCOSTPOINT_PROC >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_RUN_ET_POSTCOSTPOINT_PROC >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go

CREATE PROCEDURE [dbo].[XX_R22_RUN_ET_POSTCOSTPOINT_PROC] AS

/********************************************************************************************************
Name:       XX_RUN_ET_POSTCOSTPOINT_PROC
Author:     HVT
Created:    08/25/2005
Purpose:    For a given interface job, after the interface-specific Costpoint preprocessor execution step
            is completed successfully, (1) archive source input records, (2) report I/O and processing 
            statistics, (3) insert the last XX_IMAPS_INT_CONTROL record in the series to mark the 
            successfully executed final stage or control point, (4) send e-mail to user, (5) update the
            XX_IMAPS_INT_STATUS record with status COMPLETED.
Parameters: 
Result Set: None
Notes:

Defect 382  Update columns RECORD_COUNT_SUCCESS and RECORD_COUNT_ERROR of the XX_IMAPS_INT_STATUS record.

Feature 415 01/26/2006 - Add code to process new column XX_ET_DAILY_IN_ARC.AMENDMENT_NUM.

Defect 741  06/05/2006 - Change the way column XX_IMAPS_INT_STATUS.RECORD_COUNT_SUCCESS gets its value.

CR-1649     11/05/2008 - Modified to rename TS_PREP.txt to R22_TS_PREP.txt
CR-1821     Modified for renaiming IMAPS.DELTEK to IMAR.DELTEK
CR-2043     Modified for partial timesheet miscode issue (03/20/2010)
DR-2809     Modified for partial TS miscode issue for N/D Types (09/24/2010)
CR-3749     Modified for Shared ID issue 05/05/2011
DR-2484     Correct interface run results as recorded in XX_IMAPS_INT_STATUS record
*********************************************************************************************************/

DECLARE @SP_NAME                           sysname,
        @LD_CONSTANT_ETIME_CTRL_PT         varchar(30),
        @ETIME_INTERFACE                   varchar(50),
        @INTERFACE_STATUS_CP_COMPLETE      varchar(20),
        @INTERFACE_STATUS_COMPLETED        varchar(20),
        @STAGE_FOUR                        integer,
        @STAGE_FIVE                        integer,
        @STAGE_SIX                         integer,
        @IMAPS_DB_NAME                     sysname,
        @lv_STATUS_RECORD_NUM              integer,
        @lv_status_desc                    varchar(255),
        @lv_OUT_CP_ERROR_FILENAME          sysname,
        @lv_IN_TS_PREP_ERROR_TABLE         sysname,
        @lv_IN_TS_PREP_ERR_FORMAT_FILENAME sysname,
        @lv_IMAPS_SCHEMA_OWNER             sysname,
        @lv_IN_USER_PASSWORD               sysname,
        @lv_DOS_cmd                        varchar(255),
        @total_REG_TIME                    decimal(14, 2),
        @total_OVERTIME                    decimal(14, 2),
        @total_CHG_HRS                     decimal(14, 2),
        @total_RECORD_COUNT_SUCCESS        decimal(17, 2),
        @total_RECORD_COUNT_ERROR          decimal(17, 2),
        @lv_error                          integer,
        @lv_rowcount                       integer,
        @ret_code                          integer

--for change KM 4/13/06
DECLARE @ARCH_DIR sysname,
    @PROCESS_DIR sysname,
    @ERROR_DIR sysname,
    @TS_PREP sysname,
    @ET_FILE sysname,
    @error_msg_placeholder1 sysname,
    @error_msg_placeholder2 sysname,
    @CMD varchar(500),
    @out_STATUS_DESCRIPTION sysname

SELECT  @ARCH_DIR = PARAMETER_VALUE
FROM    dbo.XX_PROCESSING_PARAMETERS
WHERE   INTERFACE_NAME_CD = 'ETIME_R22'
AND PARAMETER_NAME = 'ARCH_DIR'

SELECT  @PROCESS_DIR = PARAMETER_VALUE
FROM    dbo.XX_PROCESSING_PARAMETERS
WHERE   INTERFACE_NAME_CD = 'ETIME_R22'
AND PARAMETER_NAME = 'PROCESS_DIR'

SELECT  @ERROR_DIR = PARAMETER_VALUE
FROM    dbo.XX_PROCESSING_PARAMETERS
WHERE   INTERFACE_NAME_CD = 'ETIME_R22'
AND PARAMETER_NAME = 'ERROR_DIR'

SELECT  @TS_PREP = PARAMETER_VALUE
FROM    dbo.XX_PROCESSING_PARAMETERS
WHERE   INTERFACE_NAME_CD = 'ETIME_R22'
AND PARAMETER_NAME = 'OUT_TS_PREP_FILENAME'

SELECT  @ET_FILE = PARAMETER_VALUE
FROM    dbo.XX_PROCESSING_PARAMETERS
WHERE   INTERFACE_NAME_CD = 'ETIME_R22'
AND PARAMETER_NAME = 'IN_TS_SOURCE_FILENAME'

SET     @ET_FILE = SUBSTRING(@ET_FILE, 1, LEN(@ET_FILE) - 1) -- to get rid of \n
--end for change KM 4/13/06...continued below

-- set local constants
SET @SP_NAME = 'XX_R22_RUN_ET_POSTCOSTPOINT_PROC'
SET @INTERFACE_STATUS_CP_COMPLETE = 'CP_COMPLETE' -- the Cospoint preprocessor job is completed
SET @INTERFACE_STATUS_COMPLETED = 'COMPLETED'
SET @ETIME_INTERFACE = 'ETIME_R22'
SET @STAGE_FOUR = 4
SET @STAGE_FIVE = 5
SET @STAGE_SIX = 6
SET @LD_CONSTANT_ETIME_CTRL_PT = 'LD_ETIME_R_INTERFACE_CTRL_PT'
SET @IMAPS_DB_NAME = db_name()


-- initialize local variables
SET @total_REG_TIME = 0
SET @total_OVERTIME = 0
SET @total_CHG_HRS = 0
SET @total_RECORD_COUNT_SUCCESS = 0.0
SET @total_RECORD_COUNT_ERROR = 0.0

/*
 * Verify that the XX_IMAPS_INT_STATUS record has been update to reflect the Costpoint timesheet preprocessor
 * execution step has been successfully completed.
 */

select @lv_STATUS_RECORD_NUM = STATUS_RECORD_NUM
  from dbo.XX_IMAPS_INT_STATUS
 where INTERFACE_NAME = @ETIME_INTERFACE
   and INTERFACE_TYPE = 'I'
   and STATUS_CODE = @INTERFACE_STATUS_CP_COMPLETE

SET @lv_rowcount = @@ROWCOUNT

/*
 * There cannot be more than one eTime interface job at any point in time
 * because the Costpoint timesheet preprocessor can only run one job at 
 * any point in time.
 */
IF @lv_rowcount > 1
   RETURN(1)

-- There is no eTime interface job to consider.
IF @lv_STATUS_RECORD_NUM IS NULL
   RETURN(0)

/*
 * Archive input timesheet records.
 * Note: XX_ET_DAILY_IN records are inserted by stored procedure XX_INSERT_TS_PREPROC_RECORDS.
 * XX_ET_DAILY_IN_ARC's PK column ET_DAILY_IN_ARC_NUM is an IDENTITY column.
 */
insert into dbo.XX_R22_ET_DAILY_IN_ARC
   (STATUS_RECORD_NUM, EMP_SERIAL_NUM, TS_YEAR, TS_MONTH, TS_DAY, TS_DATE, TS_WEEK_END_DATE,
    PROJ_ABBR, REG_TIME, OVERTIME, PLC, RECORD_TYPE, AMENDMENT_NUM,
    CREATED_BY, CREATED_DATE, MODIFIED_BY, MODIFIED_DATE)
   select STATUS_RECORD_NUM, EMP_SERIAL_NUM, TS_YEAR, TS_MONTH, TS_DAY, TS_DATE, TS_WEEK_END_DATE,
          PROJ_ABBR, REG_TIME, OVERTIME, PLC, RECORD_TYPE, AMENDMENT_NUM,
          CREATED_BY, CREATED_DATE, SUSER_SNAME(), GETDATE() 
     from dbo.XX_R22_ET_DAILY_IN

SELECT @lv_error = @@ERROR, @lv_rowcount = @@ROWCOUNT

IF @lv_rowcount = 0
   BEGIN
      -- Attempt to %1 IMAPS interface table %2 failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = 302,
         @in_SQLServer_error_code = @lv_error,
         @in_display_requested    = 1,
         @in_placeholder_value1   = 'INSERT records into',
         @in_placeholder_value2   = 'XX_R22_ET_DAILY_IN_ARC',
         @in_calling_object_name  = @SP_NAME,
         @out_msg_text            = @lv_status_desc
      RETURN(1)
   END

-- Report the total hours charged, processed, and failed, if any, of the eTime interface batch.

SELECT @total_REG_TIME = SUM(CONVERT(decimal(14, 2), REG_TIME)),
       @total_OVERTIME = SUM(CONVERT(decimal(14, 2), OVERTIME))
  FROM dbo.XX_R22_ET_DAILY_IN

/*
 * Check for the existence of the error file produced by Costpoint timesheet preprocessor.
 * First, retrieve input parameter data necessary to run the eTime interface.
 */
EXEC @ret_code = dbo.XX_R22_GET_ET_PROCESSING_PARAMETERS
   @out_OUT_CP_ERROR_FILENAME          = @lv_OUT_CP_ERROR_FILENAME          OUTPUT,
   @out_IN_TS_PREP_ERROR_TABLE         = @lv_IN_TS_PREP_ERROR_TABLE         OUTPUT,
   @out_IN_TS_PREP_ERR_FORMAT_FILENAME = @lv_IN_TS_PREP_ERR_FORMAT_FILENAME OUTPUT,
   @out_IMAPS_SCHEMA_OWNER             = @lv_IMAPS_SCHEMA_OWNER             OUTPUT,
   @out_IN_USER_PASSWORD               = @lv_IN_USER_PASSWORD               OUTPUT

IF @ret_code <> 0
   RETURN(1)

SET @lv_DOS_cmd = 'DIR ' + @lv_OUT_CP_ERROR_FILENAME
EXEC @ret_code = master.dbo.xp_cmdshell @lv_DOS_cmd

/*
 * Error file does not exist: no error processing needed, jump to the specified branch label
 */
IF @ret_code = 1
   GOTO bl_UPDATE_STATUS

TRUNCATE TABLE XX_R22_TS_PREP_ERRORS_TMP

/*
 * Error log file produced by the Costpoint timesheet preprocessor exists.
 * Insert records into table XX_IMAPS_ET_FTR_IN_TMP using the Costpoint error log file as input.
 */
EXEC @ret_code = dbo.XX_EXEC_SHELL_CMD_INSERT_OSUSER    --Modified for CR-3749
   @in_IMAPS_db_name       = @IMAPS_DB_NAME,
   @in_IMAPS_table_owner   = @lv_IMAPS_SCHEMA_OWNER,
   @in_dest_table          = @lv_IN_TS_PREP_ERROR_TABLE,
   @in_format_file     = @lv_IN_TS_PREP_ERR_FORMAT_FILENAME,
   @in_input_file        = @lv_OUT_CP_ERROR_FILENAME,
  -- @in_usr_password        = @lv_IN_USER_PASSWORD, --Modified for CR-3749
   @out_STATUS_DESCRIPTION = @lv_status_desc OUTPUT

IF @ret_code <> 0
   RETURN(1)


--begin change KM 4/13/06

-- Get Rid of Non Distinct Records If Needed
IF (
    (SELECT COUNT(1) FROM dbo.XX_R22_TS_PREP_ERRORS_TMP)
    <>
    (SELECT COUNT(DISTINCT NOTES) FROM dbo.XX_R22_TS_PREP_ERRORS_TMP)
)
BEGIN
    PRINT 'Costpoint Error file contains duplicate records...'
    DECLARE @DISTINCT_FILENAME sysname  

    --CREATE DISTINCT ERROR FILE
    SET @DISTINCT_FILENAME = REPLACE(@lv_OUT_CP_ERROR_FILENAME, '.ERR', '_DISTINCT.ERR')

    SET @CMD = 'BCP "SELECT DISTINCT * FROM IMAPSStg.dbo.XX_R22_TS_PREP_ERRORS_TMP" queryout ' + @DISTINCT_FILENAME + ' -f' + @lv_IN_TS_PREP_ERR_FORMAT_FILENAME + ' -S' + @@servername + '-T'
    --Modified for CR-3749

    EXEC @ret_code = master.dbo.xp_cmdshell @CMD

    IF @ret_code <> 0
       BEGIN
          SET @error_msg_placeholder1 = 'BCP DISTINCT error file FROM'
          SET @error_msg_placeholder2 = 'XX_R22_TS_PREP_ERRORS_TMP'
          GOTO BL_ERROR_HANDLER
       END
    
    --RENAME DISTINCT ERROR FILE
    EXEC @ret_code = dbo.XX_RENAME_FILE_SP
        @in_SRC_PATH_FILE = @DISTINCT_FILENAME, 
        @in_NEW_FILE_NAME = 'TS_PREP_DISTINCT.ERR'
    IF @ret_code <> 0
       BEGIN
          SET @error_msg_placeholder1 = 'RENAME DISTINCT ERROR FILE'
          SET @error_msg_placeholder2 = ''
          GOTO BL_ERROR_HANDLER
       END

    SET @CMD = @PROCESS_DIR + '*_DISTINCT.ERR'
    EXEC @ret_code = dbo.XX_MOVE_FILE_SP
        @in_SRC = @CMD, 
        @in_DST = @ERROR_DIR
    IF @ret_code <> 0
       BEGIN
          SET @error_msg_placeholder1 = 'MOVE THE DISTINCT ERROR FILE'
          SET @error_msg_placeholder2 = ''
          GOTO BL_ERROR_HANDLER
       END

END

--RENAME NORMAL ERROR FILE
EXEC dbo.XX_RENAME_FILE_SP
   @in_SRC_PATH_FILE = @lv_OUT_CP_ERROR_FILENAME, 
   @in_NEW_FILE_NAME = 'R22_TS_PREP.ERR' -- Modified 11/05/2008 CR-1649

IF @ret_code <> 0
   BEGIN
      SET @error_msg_placeholder1 = 'RENAME NORMAL ERROR FILE'
      SET @error_msg_placeholder2 = ''
      GOTO BL_ERROR_HANDLER
   END

--ARCHIVE ERROR FILES
SET @CMD = @PROCESS_DIR + '*.ERR'

EXEC @ret_code = dbo.XX_MOVE_FILE_SP
   @in_SRC = @CMD,
   @in_DST = @ERROR_DIR

IF @ret_code <> 0
   BEGIN
      SET @error_msg_placeholder1 = 'MOVE THE ERROR FILE'
      SET @error_msg_placeholder2 = ''
      GOTO BL_ERROR_HANDLER
   END

--end change KM 4/13/06

bl_UPDATE_STATUS:

/*
   @in_NEW_FILE_NAME = replace(convert(varchar(10),getdate(),8 ),':','_')+@in_NEW_FILE_NAME
-- Modified for CR-1901 Added to differentiate the file name with timestamp
*/

--RENAME TS_PREP FILE
--for some reason, Costpoint 6 renames the .TXT file to .ZZZ
SET @TS_PREP = REPLACE(@TS_PREP, '.TXT', '.ZZZ')
EXEC @ret_code = dbo.XX_RENAME_FILE_SP
   @in_SRC_PATH_FILE = @TS_PREP, 
   @in_NEW_FILE_NAME = 'R22_TS_PREP.TXT' -- Modified 05/11/2008 CR-1649

IF @ret_code <> 0
   BEGIN
      SET @error_msg_placeholder1 = 'RENAME PREP FILE'
      SET @error_msg_placeholder2 = ''
      GOTO BL_ERROR_HANDLER
   END

--ARCHIVE FILE
SET @PROCESS_DIR = @PROCESS_DIR + '*.TXT'

EXEC @ret_code = dbo.XX_MOVE_FILE_SP
   @in_SRC = @PROCESS_DIR, 
   @in_DST = @ARCH_DIR

IF @ret_code <> 0
   BEGIN
      SET @error_msg_placeholder1 = 'MOVE TS_PREP FILE'
      SET @error_msg_placeholder2 = ''
      GOTO BL_ERROR_HANDLER
   END

EXEC @ret_code = dbo.XX_MOVE_FILE_SP
   @in_SRC = @ET_FILE, 
   @in_DST = @ARCH_DIR

IF @ret_code <> 0
   BEGIN
      SET @error_msg_placeholder1 = 'MOVE ET INPUT FILE'
      SET @error_msg_placeholder2 = ''
      GOTO BL_ERROR_HANDLER
   END

/* Commented CR-2043 03/20/2010
--begin archive records that errored out
INSERT INTO dbo.XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
(STATUS_RECORD_NUM_CREATED, TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, ACCT_ID, LAB_CST_AMT, CHG_HRS,
LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
EFFECT_BILL_DT, NOTES)
SELECT 
@lv_STATUS_RECORD_NUM,
TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, ACCT_ID, LAB_CST_AMT, CHG_HRS, -- Added ACCT_ID CR-1649
LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
EFFECT_BILL_DT, NOTES
FROM dbo.XX_R22_IMAPS_TS_PREP_TEMP 
WHERE NOTES not in (SELECT NOTES FROM IMAR.DELTEK.TS_LN)
--end archive records that errored out
*/

-- Begin of Miscode Closeout Code CR-2043 Added 03/20/2010 tp
--Non PPA Records
--begin archive records that errored out
INSERT INTO dbo.XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
(STATUS_RECORD_NUM_CREATED, TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, ACCT_ID, LAB_CST_AMT, CHG_HRS,
LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
EFFECT_BILL_DT, NOTES)
SELECT 
@lv_STATUS_RECORD_NUM,
TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, ACCT_ID, LAB_CST_AMT, CHG_HRS,
LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
EFFECT_BILL_DT, NOTES
FROM dbo.XX_R22_IMAPS_TS_PREP_TEMP 
--WHERE NOTES not in (SELECT NOTES FROM IMAR.DELTEK.TS_LN)
-- Move the Regular TC records to miscode evenif partial week is processed
where (empl_id+convert(char(10), dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts_dt),120)) in 
        (
        select distinct empl_id+convert(char(10), dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(ts_dt),120) --correcting_ref_dt
        from xx_r22_imaps_ts_prep_temp
        where notes not in (select notes from imar.deltek.ts_ln)
        )
and s_ts_type_cd not in ('N','D')

--PPA Records Only
--begin archive records that errored out
INSERT INTO dbo.XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS
(STATUS_RECORD_NUM_CREATED, TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, ACCT_ID, LAB_CST_AMT, CHG_HRS,
LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
EFFECT_BILL_DT, NOTES)
SELECT 
@lv_STATUS_RECORD_NUM,
TS_DT, EMPL_ID, S_TS_TYPE_CD, WORK_STATE_CD, FY_CD, PD_NO,
SUB_PD_NO, CORRECTING_REF_DT, PAY_TYPE, ACCT_ID, LAB_CST_AMT, CHG_HRS,
LAB_LOC_CD, PROJ_ID, BILL_LAB_CAT_CD, PROJ_ABBRV_CD, TS_HDR_SEQ_NO,
EFFECT_BILL_DT, NOTES
FROM dbo.XX_R22_IMAPS_TS_PREP_TEMP 
/* Commented DR2809 09/24/2010
WHERE NOTES not in (SELECT NOTES FROM IMAR.DELTEK.TS_LN)
    and notes not in (select notes 
                      from dbo.XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS)
    and s_ts_type_cd in ('N','D')
*/
--Added DR2809 09/24/2010
where (empl_id+convert(char(10), dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt),120)) in 
        (
        select distinct empl_id+convert(char(10), dbo.XX_GET_FRIDAY_FOR_TS_WEEK_DAY_UF(correcting_ref_dt),120) --correcting_ref_dt
        from xx_r22_imaps_ts_prep_temp
        where notes not in (select notes from imar.deltek.ts_ln)
        )
and s_ts_type_cd in ('N','D')



--Remove partially processed timecard from TS_LN table from CP
--as we already moved it to miscode table
--we can not remove if TC is already posted
delete from imar.deltek.ts_hdr
from imar.deltek.ts_hdr hdr
    inner join
    imar.deltek.ts_ln ln
    on
    (hdr.empl_id = ln.empl_id
    and hdr.ts_dt = ln.ts_dt
    and hdr.s_ts_type_cd = ln.s_ts_type_cd
    and hdr.ts_hdr_seq_no = ln.ts_hdr_seq_no)
    and post_seq_no is null
where ln.notes in (select notes from xx_r22_imaps_ts_prep_config_errors)


--End of Code CR-2043


--begin status record update
DECLARE @total_AMOUNT_FAILED    decimal(14,2),
        @total_AMOUNT_PROCESSED decimal(14,2),
-- DR2484_Begin
        @RECORD_COUNT_INITIAL   integer

SELECT @total_REG_TIME = SUM(CONVERT(decimal(14, 2), REG_TIME)),
       @total_OVERTIME = SUM(CONVERT(decimal(14, 2), OVERTIME))
  FROM dbo.XX_R22_ET_DAILY_IN

SELECT @RECORD_COUNT_INITIAL = COUNT(1) 
  FROM dbo.XX_R22_IMAPS_TS_PREP_TEMP

select @total_AMOUNT_FAILED = SUM(CONVERT(decimal(14, 2), CHG_HRS)) 
  from dbo.XX_R22_IMAPS_TS_PREP_TEMP
 where NOTES not in (select NOTES from IMAR.Deltek.TS_LN)
   and NOTES not like '%-C%'

select @total_AMOUNT_PROCESSED = SUM(CONVERT(decimal(14, 2), CHG_HRS)) 
  from dbo.XX_R22_IMAPS_TS_PREP_TEMP
 where NOTES in (select NOTES from IMAR.Deltek.TS_LN)
   and NOTES not like '%-C%'

select @total_RECORD_COUNT_SUCCESS = count(1)
  from dbo.XX_R22_IMAPS_TS_PREP_TEMP
 where NOTES in (select NOTES from IMAR.Deltek.TS_LN)

select @total_RECORD_COUNT_ERROR = count(1)
  from dbo.XX_R22_IMAPS_TS_PREP_TEMP
 where NOTES not in (select NOTES from IMAR.Deltek.TS_LN)
-- DR2484_End


--zero hours treated differently
DECLARE @total_RECORD_COUNT_ZERO int

select @total_RECORD_COUNT_ZERO = count(1)
from xx_R22_imaps_ts_prep_zeros



update dbo.XX_IMAPS_INT_STATUS
-- DR2484_Begin
   SET RECORD_COUNT_INITIAL = @RECORD_COUNT_INITIAL,
       RECORD_COUNT_SUCCESS = @total_RECORD_COUNT_SUCCESS, -- + @total_RECORD_COUNT_ZERO
-- DR2484_End
       RECORD_COUNT_ERROR   = @total_RECORD_COUNT_ERROR,
       AMOUNT_INPUT         = (@total_REG_TIME + @total_OVERTIME),
       AMOUNT_PROCESSED     = @total_AMOUNT_PROCESSED,
       AMOUNT_FAILED        = @total_AMOUNT_FAILED,
       MODIFIED_BY          = SUSER_SNAME(),
       MODIFIED_DATE        = GETDATE()
 where STATUS_RECORD_NUM = @lv_STATUS_RECORD_NUM
--end status record update


SELECT @lv_error = @@ERROR, @lv_rowcount = @@ROWCOUNT

IF @lv_error <> 0
   BEGIN
      -- Attempt to update a XX_IMAPS_INT_STATUS record failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = 204,
         @in_SQLServer_error_code = @lv_error,
         @in_display_requested    = 1,
         @in_placeholder_value1   = 'update',
         @in_placeholder_value2   = 'a XX_R22_IMAPS_INT_STATUS record',
         @in_calling_object_name  = @SP_NAME,
         @out_msg_text            = @lv_status_desc OUTPUT
      RETURN(1)
   END
 
-- Insert one XX_IMAPS_INT_CONTROL record for stage ETIME5 - Update Control and Error tables
EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
   @in_int_ctrl_pt_num     = @STAGE_FIVE,
   @in_lookup_domain_const = @LD_CONSTANT_ETIME_CTRL_PT,
   @in_STATUS_RECORD_NUM   = @lv_STATUS_RECORD_NUM

IF @ret_code <> 0
   RETURN(1)

-- Send notification e-mail
EXEC @ret_code = dbo.XX_SEND_STATUS_MAIL_SP
   @in_StatusRecordNum = @lv_STATUS_RECORD_NUM

IF @ret_code <> 0
   BEGIN
      -- Attempt to send notification e-mail to destination system owner failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 303,
         @in_display_requested   = 1,
         @in_placeholder_value1  = 'notification',
         @in_placeholder_value2  = 'destination system owner',
         @in_calling_object_name = @SP_NAME,
         @out_msg_text           = @lv_status_desc OUTPUT
      RETURN(1)
   END

-- Insert one more XX_IMAPS_INT_CONTROL record for the final stage
EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
   @in_int_ctrl_pt_num     = @STAGE_SIX,
   @in_lookup_domain_const = @LD_CONSTANT_ETIME_CTRL_PT,
   @in_STATUS_RECORD_NUM   = @lv_STATUS_RECORD_NUM
                          
IF @ret_code <> 0
   RETURN(1)

-- This is the final update of the XX_IMAPS_INT_STATUS record for the interface job
SET @lv_status_desc = 'Execution of eTime interface job completed successfully.'

EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
   @in_STATUS_RECORD_NUM  = @lv_STATUS_RECORD_NUM,
   @in_STATUS_CODE        = @INTERFACE_STATUS_COMPLETED,
   @in_STATUS_DESCRIPTION = @lv_status_desc

IF @ret_code <> 0
   RETURN(1)


RETURN(0)

BL_ERROR_HANDLER:

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code          = 204,
   @in_display_requested   = 1,
   @in_placeholder_value1  = @error_msg_placeholder1,
   @in_placeholder_value2  = @error_msg_placeholder2,
   @in_calling_object_name = @SP_NAME,
   @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)









go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_R22_RUN_ET_POSTCOSTPOINT_PROC') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_RUN_ET_POSTCOSTPOINT_PROC >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_RUN_ET_POSTCOSTPOINT_PROC >>>'
go

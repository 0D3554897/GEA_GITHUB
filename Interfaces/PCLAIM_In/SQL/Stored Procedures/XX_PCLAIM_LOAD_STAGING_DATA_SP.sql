use imapsstg


/****** Object:  Stored Procedure dbo.XX_PCLAIM_LOAD_STAGING_DATA_SP    Script Date: 10/23/2007 9:49:03 AM ******/
IF OBJECT_ID('dbo.XX_PCLAIM_LOAD_STAGING_DATA_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_PCLAIM_LOAD_STAGING_DATA_SP
    IF OBJECT_ID('dbo.XX_PCLAIM_LOAD_STAGING_DATA_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_PCLAIM_LOAD_STAGING_DATA_SP >>> - WTF?'
    ELSE
        PRINT ''
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go


CREATE PROCEDURE [dbo].[XX_PCLAIM_LOAD_STAGING_DATA_SP]
(
@in_STATUS_RECORD_NUM   integer, 
@out_SystemError        integer      = NULL OUTPUT, 
@out_STATUS_DESCRIPTION varchar(275) = NULL OUTPUT
)
AS

/**********************************************************************************************************  
Name:       XX_PCLAIM_LOAD_STAGING_DATA_SP  
Author:     Tatiana Perova
Created:    08/24/2005  
Purpose:    Perform control point number 1 of PCLAIM interface.

            Table XX_PCLAIM_IN_TMP is used to store the periodic vendor labor claim data which are loaded
            directly by Neil Rancour's java agent. Neil's agent also creates a record in table XX_PCLAIM_IN_LOG.

            Table XX_PCLAIM_IN is used to store the refined XX_PCLAIM_IN_TMP data that will be the source for
            the Costpoint AP processor staging data.

            Called by XX_PCLAIM_RUN_INTERFACE_SP.

Parameters: Input:  @in_STATUS_RECORD_NUM -- identifier of the current interface run
            Output: @out_STATUS_DESCRIPTION --  generated error message
                    @out_SystemError  -- system error code
Result Set: None  

Notes:

CR-1082     10/23/2007 - PD/SUB_PD changes

CP600000413 08/21/2008 - Reference BP&S Service Request CR1639
            Provide stand-by hour labor claim processing.

CR1470		02/013/2009 - PCLAIM miscode process :)

CR5888		2013-02-27 - Change the IMAPS PCLAIM interface to assign PLC of SB for DDOU.NPUB and DDOU.ICAB projects
**********************************************************************************************************/

DECLARE @SP_NAME              varchar(50),
        @REGULAR_RECORD_TYPE  char(1),
        @ret_code             integer,
        @EndDateOfSubPeriod_1 DateTime,
        @CurrentSubPeriod     smallint,
        @CurrentPeriod        smallint,
        @CurrentFY            char(4),
        @tot_log_rec_count    integer,  
        @tot_tabl_rec_count   integer,
        @tot_null_status      integer,
        @tot_log_hours        decimal(14, 2),
        @tot_tabl_hours       decimal(14, 2),
        @NumberOfRecords      integer,
        @CurrentWeekEndDate   datetime,
        @CurrentWeekStartDate datetime

-- Set local constants
SET @SP_NAME = 'XX_PCLAIM_LOAD_STAGING_DATA_SP'
SET @REGULAR_RECORD_TYPE = 'R'


/* begin CR5888 */
update xx_pclaim_in_tmp
set PLC='SB'
from xx_pclaim_in_tmp pclaim
where
--fits DDOU PLC criteria
0<>(select count(1) 
	from imaps.deltek.proj 
	where left(proj_id,9) in ('DDOU.NPUB','DDOU.ICAB')
	and proj_abbrv_cd<>''
	and proj_abbrv_cd=pclaim.proj_code)
/* end CR5888 */






/* begin 01/12/2006 TP */

/* 
 * At this moment of processing, XX_PCLAIM_IN table should be empty, but if previous
 * interface run fail and was not correctly completed next statement will fix it
 */
DELETE  FROM dbo.XX_PCLAIM_IN

/* end 01/12/2006 TP */


-- 10/26/2005 TP working from tables instead of file (big piece of code removed)

-- Compare staging table  record count with log values
SELECT @tot_log_rec_count = TOTAL_RECORDS,
       @tot_log_hours = TOTAL_HOURS
  FROM dbo.XX_PCLAIM_IN_LOG
 WHERE STATUS_RECORD_NUM is NULL -- 04/04/2006 TP missed condition


SELECT @tot_tabl_hours  = SUM(HOURS_CHARGED),
       @tot_tabl_rec_count = COUNT(*)
  FROM dbo.XX_PCLAIM_IN_TMP

IF @tot_tabl_rec_count = 0 
   BEGIN
      -- Input data was not supplied by PCLAIM system to the XX_PCLAIM_IN table
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 525,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME,
         @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT
      RETURN(1)
   END
ELSE
   BEGIN
   -- update the XX_IMAPS_INT_STATUS record with the  totals
   UPDATE dbo.XX_IMAPS_INT_STATUS
      SET RECORD_COUNT_TRAILER = @tot_log_rec_count,
          RECORD_COUNT_INITIAL = @tot_tabl_rec_count,
          AMOUNT_INPUT         = @tot_log_hours,
          AMOUNT_PROCESSED     = @tot_tabl_hours,
          MODIFIED_BY          = SUSER_SNAME(),
          MODIFIED_DATE        = GETDATE()
    WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM
	
   SELECT @out_SystemError = @@ERROR, @NumberOfRecords = @@ROWCOUNT
   
   IF @out_SystemError > 0 BEGIN GOTO ErrorProcessing END
   
   IF (@NumberOfRecords = 0) -- error: UPDATE zero record
      BEGIN
         -- Attempt to %1 IMAPS interface table %2 failed.
         EXEC dbo.XX_ERROR_MSG_DETAIL
            @in_error_code          = 302,
            @in_display_requested   = 1,
            @in_placeholder_value1  = 'update',
            @in_placeholder_value2  = 'XX_IMAPS_INT_STATUS',
            @in_calling_object_name = @SP_NAME,
            @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT
         RETURN(1)
      END
   END

-- 10/26/2005 TP - Validate that log table has only one record without status number
SELECT @tot_null_status = COUNT(*) 
  FROM dbo.XX_PCLAIM_IN_LOG
 WHERE STATUS_RECORD_NUM is NULL

IF @tot_null_status <> 1
   BEGIN
      /*
       * Please validate PCLAIM input data and leave only one record with Null
       * STATUS_RECORD_NUM in XX_PCLAIM_IN_LOG table.
       */
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 526,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME,
         @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT
      RETURN(1)
   END

-- 10/26/2005 TP - Messages changed from file  to log table
IF (@tot_tabl_rec_count <> @tot_log_rec_count) 
   BEGIN
      -- Log table %1 does not match the actual %2.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 527,
-- begin 12/6/2005 TP
         @in_placeholder_value1  = 'number of records',
         @in_placeholder_value2  = 'number of records',
-- end 12/6/2005 TP
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME,
         @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT
      RETURN(1)
   END

IF (@tot_tabl_hours <> @tot_log_hours)
   BEGIN
      -- Log table %1 does not match the actual %2.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 527,
-- begin 12/6/2005 TP
         @in_placeholder_value1  = 'total sum of hours',
         @in_placeholder_value2  = 'total sum of hours',
-- end 12/6/2005 TP
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME,
         @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT
      RETURN(1)
   END

INSERT INTO dbo.XX_PCLAIM_IN
   (
    STATUS_RECORD_NUM,
    WORK_DATE, 
    VEND_EMPL_NAME,
    PO_NUMBER,
    VEND_EMPL_SERIAL_NUM,
    PROJ_CODE,
    VENDOR_ID,
    DEPT_CODE,
    HOURS_CHARGED,
    COST, 
    PLC,
    BILL_RATE,
    RECORD_TYPE,
    VEND_NAME,
    VEND_ST_ADDRESS,
    VEND_CITY, 
    VEND_STATE,
    VEND_COUNTRY,
    CREATED_BY,
    CREATED_DATE,
-- CP600000413_Begin
    PAY_TYPE
-- CP600000413_End
-- CR1470 BEGIN
	,
	UNID,
	REVISION_NUM
-- CR1470 END
   )
   SELECT @in_STATUS_RECORD_NUM,
          LEFT(LTRIM(WORK_DATE), 4) + '-' + RIGHT(LEFT(LTRIM(WORK_DATE), 6), 2) + '-' + RIGHT(RTRIM(WORK_DATE), 2), 
          LTRIM(RTRIM(VEND_EMPL_NAME)),
          LTRIM(RTRIM(PO_NUMBER)),
          LTRIM(RTRIM(VEND_EMPL_SERIAL_NUM)),
          LTRIM(RTRIM(PROJ_CODE)),
          LTRIM(RTRIM(VENDOR_ID)),
          LTRIM(RTRIM(DEPT_CODE)),
          HOURS_CHARGED,
          COST, 
          ISNULL(LTRIM(RTRIM(PLC)), 'NONE'),
          BILL_RATE,
          RECORD_TYPE,
          LTRIM(RTRIM(VEND_NAME)),
          VEND_ST_ADDRESS,
          LTRIM(RTRIM(VEND_CITY)), 
          LTRIM(RTRIM(VEND_STATE)),
          LTRIM(RTRIM(VEND_COUNTRY)),
          'INTERFACE',
	  GETDATE(),
-- CP600000413_Begin
          LTRIM(RTRIM(PAY_TYPE))
-- CP600000413_End 
-- CR1470 BEGIN
		,
		UNID,
		REVISION_NUM
-- CR1470 END
     FROM dbo.XX_PCLAIM_IN_TMP

SELECT @out_SystemError = @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 BEGIN GOTO ErrorProcessing END

IF @NumberOfRecords <> @tot_log_rec_count  
   BEGIN
      -- Footer record count does not match the detail record count
      RETURN(502) 
   END

/* Check that all regular records in the file have WORK_DATE in one TS_PD_SCH weekthis one week will be considered current */

SELECT @CurrentWeekEndDate = a.END_DT,
       @CurrentWeekStartDate = a.START_DT
  FROM IMAPS.Deltek.TS_PD_SCH a
       INNER JOIN
       dbo.XX_PCLAIM_IN b
       ON
       DATEDIFF(day, b.WORK_DATE,END_DT) >= 0
       AND
       DATEDIFF(day, b.WORK_DATE,START_DT) <= 0
       AND
       b.RECORD_TYPE = @REGULAR_RECORD_TYPE
 GROUP BY a.END_DT, a.START_DT

SELECT @out_SystemError = @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 BEGIN GOTO ErrorProcessing END -- probably date conversion error

IF @NumberOfRecords > 1 
   BEGIN
      /*
       * More than one week labor data is present in input file as regular records. 
       * Split input file by week or change previous week's record type to 'C'.
       */
      RETURN(523) 
   END

IF @NumberOfRecords = 0
   -- If file has no regular records find cu
   BEGIN
      SELECT @CurrentWeekEndDate = a.END_DT,
             @CurrentWeekStartDate = a.START_DT
        FROM IMAPS.Deltek.TS_PD_SCH a
       WHERE DATEDIFF(day, GETDATE(), END_DT) >= 0
         AND DATEDIFF(day, GETDATE(), START_DT) <= 0
   END

-- select open period for current week end date
SET @CurrentFY = DATEPART(year, @CurrentWeekEndDate)
SET @CurrentPeriod = DATEPART(month, @CurrentWeekEndDate)

SELECT @CurrentSubPeriod = a.SUB_PD_NO 
  FROM IMAPS.Deltek.SUB_PD a
 WHERE a.SUB_PD_END_DT =
          (SELECT MIN(b.SUB_PD_END_DT)
             FROM IMAPS.Deltek.SUB_PD b
            WHERE (b.SUB_PD_NO = 2 OR b.SUB_PD_NO = 3)
              AND DATEDIFF(day, @CurrentWeekEndDate, b.SUB_PD_END_DT) >= 0)
		
/* BEGIN SUB_PD CHANGE KM CR-1082 */

UPDATE dbo.XX_PCLAIM_IN
   SET FY_CD     = SUB_PD.FY_CD,
       PD_NO     = SUB_PD.PD_NO,
       SUB_PD_NO = SUB_PD.SUB_PD_NO
  FROM dbo.XX_PCLAIM_IN PCLAIM
       INNER JOIN
       IMAPS.Deltek.SUB_PD SUB_PD
       ON
       (PCLAIM.RECORD_TYPE = 'R'
        AND
        SUB_PD.SUB_PD_END_DT = (SELECT MIN(b.SUB_PD_END_DT)
                                  FROM IMAPS.Deltek.SUB_PD b
                                 WHERE (b.SUB_PD_NO = 2 OR b.SUB_PD_NO = 3)
                                   AND DATEDIFF(day, PCLAIM.WORK_DATE, b.SUB_PD_END_DT) >= 0)
       )

UPDATE dbo.XX_PCLAIM_IN
   SET FY_CD     = @CurrentFY,
       PD_NO     = @CurrentPeriod,
       SUB_PD_NO = @CurrentSubPeriod
 WHERE RECORD_TYPE = 'C'

DECLARE @CURRENT_MONTH_POSTING sysname

SELECT @CURRENT_MONTH_POSTING = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = 'PCLAIM'
   AND PARAMETER_NAME    = 'CURRENT_MONTH_POSTING'

-- Month end special job
IF @CURRENT_MONTH_POSTING = 'YES'
   BEGIN
      DECLARE @CurrentMonthFY char(4),
              @CurrentMonthPeriod integer

      SET @CurrentMonthFY = DATEPART(year, GETDATE())
      SET @CurrentMonthPeriod = DATEPART(month, GETDATE())
	
      UPDATE dbo.XX_PCLAIM_IN
         SET FY_CD = @CurrentMonthFY,
	     PD_NO = @CurrentMonthPeriod, -- Added by Tejas For Current Month Posting=Y TCs will be posted to the next period
	     SUB_PD_NO = 1
	/*WHERE	RECORD_TYPE = 'R'
	
	UPDATE XX_PCLAIM_IN
	   SET FY_CD = @CurrentFY,
	       PD_NO = @CurrentPeriod,
	       SUB_PD_NO = 2
	 WHERE RECORD_TYPE = 'C'*/
   END

/* END SUB_PD CHANGE KM CR-1082 */

-- check that current week is not split between months
IF MONTH(@CurrentWeekEndDate) <> MONTH(@CurrentWeekStartDate) 
   BEGIN
      /*
       * We need to use prior period 1 for the week. For the begining and the end of 
       * a year TS_PD_SCH table has "cut for the year" week, so period one issue will not pop up.
       */

      -- Select end dates for subperiod 1
      SELECT @EndDateOfSubPeriod_1 = SUB_PD_END_DT
        FROM IMAPS.Deltek.SUB_PD 
       WHERE PD_NO = @CurrentPeriod
         AND FY_CD = @CurrentFY
         AND SUB_PD_NO = 1

	
      -- BEGIN SUB_PD CHANGE KM
      -- CANNOT SPLIT WEEKS OTHERWISE MISCODE PROCESS DOES NOT WORK

      -- Put regular records that have WORK_DATES in previous month to subperiod 1
      UPDATE dbo.XX_PCLAIM_IN
         SET FY_CD = @CurrentFY,
             PD_NO = @CurrentPeriod,
             SUB_PD_NO = 1
       WHERE DATEDIFF(day, WORK_DATE, @EndDateOfSubPeriod_1) > 0
         AND RECORD_TYPE = @REGULAR_RECORD_TYPE

      -- END SUB_PD CHANGE KM

      SELECT @out_SystemError = @@ERROR, @NumberOfRecords = @@ROWCOUNT

      IF @out_SystemError > 0 BEGIN GOTO ErrorProcessing END
   END

SELECT @out_SystemError = @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 BEGIN GOTO ErrorProcessing END

-- 10/26/2005 TP
-- Delete data from temporary table
TRUNCATE TABLE dbo.XX_PCLAIM_IN_TMP -- uncommented 11/10/2005 TP

-- Update log table with the interface status number
UPDATE dbo.XX_PCLAIM_IN_LOG 
   SET STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM 
 WHERE STATUS_RECORD_NUM is NULL

SELECT @out_SystemError = @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 BEGIN GOTO ErrorProcessing END

RETURN (0)

ErrorProcessing:

RETURN (1)




go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_PCLAIM_LOAD_STAGING_DATA_SP') IS NOT NULL
    PRINT ''
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_PCLAIM_LOAD_STAGING_DATA_SP >>> - WTF'
go

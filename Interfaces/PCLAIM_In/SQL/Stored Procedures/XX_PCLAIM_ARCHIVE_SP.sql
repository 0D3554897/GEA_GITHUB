use imapsstg

/****** Object:  Stored Procedure dbo.XX_PCLAIM_ARCHIVE_SP    Script Date: 10/25/2007 10:34:09 AM ******/

IF OBJECT_ID('dbo.XX_PCLAIM_ARCHIVE_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_PCLAIM_ARCHIVE_SP
    IF OBJECT_ID('dbo.XX_PCLAIM_ARCHIVE_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_PCLAIM_ARCHIVE_SP >>> - WTF?'
    ELSE
        PRINT ''
END
go

SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER ON
go


CREATE PROCEDURE [dbo].[XX_PCLAIM_ARCHIVE_SP]
(
@in_status_record_num   int,
@out_SystemError        int = NULL OUTPUT, 
@out_STATUS_DESCRIPTION varchar(275) = NULL OUTPUT
)
AS

/**********************************************************************************************************
Name:       XX_PCLAIM_ARCHIVE_SP
Author:     Tatiana Perova
Created:    08/25/2005
Purpose:    Step 5 of PCLAIM interface.
            Program copies records from staging table and statuses of their validation by AP preprocessor
            to archive, updates interface status with number for RECORD_COUNT_SUCCESS, RECORD_COUNT_ERROR,
            AMOUNT_PROCESSED, AMOUNT_FAILED 

Parameters: 
            Input:  @in_STATUS_RECORD_NUM -- identifier of current interface run
            Output: @out_STATUS_DESCRIPTION --  generated error message
                    @out_SystemError  -- system error code
Notes:

CR-1082     PD_SUBPD change 10/25/2007

CP600000324 05/27/2008 - Reference BP&S Service Request CR1543
            Costpoint multi-company fix (four instances).

CP600000413 08/21/2008 - Reference BP&S Service Request CR1639
            Provide stand-by hour labor claim processing.

CR1470      02/013/2009 - PCLAIM miscode process :)

DR1842      Closeout is taking forever.

CR8954      09/28/2016 - Change data type of @LatestRecordNumInArchive from INT to BIGINT
            to deal with arithmetic overflow error.
***********************************************************************************************************/

DECLARE @TotalErrorHours                  decimal(14,2),
        @NumberOfRecords                  int,
        @TotalErrorRecords                int,
        @TotalImportedHours               decimal(14,2),
        @TotalImportedRecords             int,
        @TotalInputHours                  decimal(14,2),
        @TotalInputRecords                int,
        @ResultOfAPpreprocessorRun        varchar(10),
-- CR8954_begin
        @LatestRecordNumInArchive         bigint,
-- CR8954_end
        @DoesInterfaceStatusNumberPresent tinyint,
-- CP600000324_Begin
        @DIV_16_COMPANY_ID                varchar(10)
-- CP600000324_End

SET @DoesInterfaceStatusNumberPresent = 0
SET @TotalErrorHours = 0
SET @TotalErrorRecords = 0
SET @TotalImportedHours = 0
SET @TotalImportedRecords = 0

-- CP600000324_Begin
SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'PCLAIM'
-- CP600000324_End






--DR1842 changes
-- update validation status by preprocessor status values
UPDATE dbo.XX_PCLAIM_IN
   SET MODIFIED_BY = (SELECT ISNULL(a.S_STATUS_CD, 'V')
                        FROM IMAPS.Deltek.AOPUTLAP_INP_LAB a
                       WHERE a.VCHR_NO    = dbo.XX_PCLAIM_IN.VCHR_NO
                         AND a.VCHR_LN_NO = dbo.XX_PCLAIM_IN.VCHR_LN_NO
                         AND a.SUB_LN_NO  = dbo.XX_PCLAIM_IN.SUB_LN_NO
                     )

SELECT @out_SystemError = @@ERROR, @NumberOfRecords = @@ROWCOUNT
IF @out_SystemError > 0 GOTO ErrorProcessing


--BEGIN SUB_PD CHANGE KM CR-1082
DECLARE MISCODE_SPLIT_VCHR_CURSOR CURSOR FAST_FORWARD FOR

SELECT VCHR_NO
  FROM dbo.XX_PCLAIM_IN
 WHERE MODIFIED_BY <> 'E'
   AND record_type = 'R'
   AND vend_empl_serial_num IN
       (select vend_empl_serial_num
          from dbo.XX_PCLAIM_IN
         where MODIFIED_BY = 'E'
           and record_type = 'R')
	GROUP BY VCHR_NO
--DR1842

DECLARE @MISCODE_SPLIT_VCHR_NO int

OPEN MISCODE_SPLIT_VCHR_CURSOR
FETCH NEXT FROM MISCODE_SPLIT_VCHR_CURSOR INTO @MISCODE_SPLIT_VCHR_NO

WHILE @@FETCH_STATUS = 0
   BEGIN
      DELETE 
        FROM IMAPS.Deltek.VCHR_HDR
       WHERE NOTES = cast(@in_status_record_num as varchar) + ' ' + cast(@MISCODE_SPLIT_VCHR_NO as varchar)
-- CP600000324_Begin
         AND COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000324_End

      UPDATE dbo.XX_PCLAIM_IN
         SET MODIFIED_BY = 'E'
       WHERE VCHR_NO = @MISCODE_SPLIT_VCHR_NO

		UPDATE IMAPS.Deltek.AOPUTLAP_INP_HDR
		SET S_STATUS_CD='E'
       WHERE VCHR_NO = @MISCODE_SPLIT_VCHR_NO

		UPDATE IMAPS.Deltek.AOPUTLAP_INP_DETL
		SET S_STATUS_CD='E'
       WHERE VCHR_NO = @MISCODE_SPLIT_VCHR_NO

		UPDATE IMAPS.Deltek.AOPUTLAP_INP_LAB
		SET S_STATUS_CD='E'
       WHERE VCHR_NO = @MISCODE_SPLIT_VCHR_NO

      FETCH NEXT FROM MISCODE_SPLIT_VCHR_CURSOR INTO @MISCODE_SPLIT_VCHR_NO
   END

SELECT @out_SystemError = @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 GOTO ErrorProcessing
--END SUB_PD CHANGE KM
--DR1842 KM
CLOSE MISCODE_SPLIT_VCHR_CURSOR
DEALLOCATE MISCODE_SPLIT_VCHR_CURSOR







--DR1842 moved this to happen after the split miscode change
-- insure that interface run in staging table was not yet archived
SELECT @DoesInterfaceStatusNumberPresent = 1
  FROM dbo.XX_PCLAIM_IN_ARCH 
 WHERE STATUS_RECORD_NUM = @in_status_record_num
	
IF @DoesInterfaceStatusNumberPresent = 1 
   RETURN (521)
	
-- get number of last archived row
SELECT @LatestRecordNumInArchive = MAX(PCLAIM_IN_RECORD_NUM)
  FROM dbo.XX_PCLAIM_IN_ARCH

IF @LatestRecordNumInArchive is NULL BEGIN SET @LatestRecordNumInArchive = 0 END

-- copy all records from staging table to archive table increasing record number on the number of last archived row
INSERT INTO dbo.XX_PCLAIM_IN_ARCH
   (PCLAIM_IN_RECORD_NUM,
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
    MODIFIED_BY,
    MODIFIED_DATE,
    VCHR_NO,
    VCHR_LN_NO,
    SUB_LN_NO,
-- CP600000413_Begin
    PAY_TYPE
-- CP600000413_End
-- CR1470 BEGIN
	,
	UNID,
	REVISION_NUM
-- CR1470 END
-- DR1842 START
	,
	S_STATUS_CD
-- DR1842 END
   )
   SELECT @LatestRecordNumInArchive + PCLAIM_IN_RECORD_NUM,
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
          MODIFIED_BY,
          MODIFIED_DATE,
          VCHR_NO,
          VCHR_LN_NO,
          SUB_LN_NO,
-- CP600000413_Begin
          PAY_TYPE
-- CP600000413_End
-- CR1470 BEGIN
			,
			UNID,
			REVISION_NUM
-- CR1470 END
-- DR1842 START
	,
			MODIFIED_BY
-- DR1842 END
     FROM dbo.XX_PCLAIM_IN

SELECT @out_SystemError = @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 GOTO ErrorProcessing





SELECT @TotalErrorHours = ISNULL(SUM(a.VEND_HRS), 0),
       @TotalErrorRecords = Count (*)
  FROM IMAPS.Deltek.AOPUTLAP_INP_LAB a
       INNER JOIN
       IMAPS.Deltek.AOPUTLAP_INP_HDR b 
       ON a.VCHR_NO = b.VCHR_NO
 WHERE a.S_STATUS_CD = 'E'
   AND b.NOTES = LTRIM(RTRIM(CAST(@in_status_record_num as char))) + ' ' + LTRIM(RTRIM(CAST(a.VCHR_NO AS char)))

SELECT @TotalImportedHours = ISNULL(SUM(a.VEND_HRS), 0),
       @TotalImportedRecords = Count (*)
  FROM IMAPS.Deltek.AOPUTLAP_INP_LAB a
       INNER JOIN
       IMAPS.Deltek.AOPUTLAP_INP_HDR b 
       ON a.VCHR_NO = b.VCHR_NO
 WHERE (a.S_STATUS_CD <> 'E' OR a.S_STATUS_CD is NULL)
   AND b.NOTES = LTRIM(RTRIM(CAST(@in_status_record_num as char))) + ' ' + LTRIM(RTRIM(CAST(a.VCHR_NO as char)))


UPDATE IMAPS.Deltek.VEND
   SET VEND_NAME = LEFT(c.VEND_NAME, 25)
  FROM (SELECT a.VENDOR_ID, a.VEND_NAME
          FROM dbo.XX_PCLAIM_IN a 
         WHERE WORK_DATE = (SELECT MAX(b.WORK_DATE) AS WORK_DATE
                              FROM dbo.XX_PCLAIM_IN b
                             WHERE a.VENDOR_ID = b.VENDOR_ID)
         GROUP BY a.VENDOR_ID, a.VEND_NAME
       ) c
 WHERE VEND_ID = c.VENDOR_ID 
-- CP600000324_Begin
   AND COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000324_End

-- 10/10/2006_begin
SELECT @out_SystemError = @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 GOTO ErrorProcessing
-- 10/10/2006_end

UPDATE IMAPS.Deltek.VEND_ADDR
   SET LN_1_ADR  = ISNULL(SUBSTRING(c.VEND_ST_ADDRESS, 1,   40), LN_1_ADR),
       LN_2_ADR  = ISNULL(SUBSTRING(c.VEND_ST_ADDRESS, 41,  80), LN_2_ADR),
       LN_3_ADR  = ISNULL(SUBSTRING(c.VEND_ST_ADDRESS, 81, 120), LN_3_ADR),
       CITY_NAME = ISNULL(c.VEND_CITY, CITY_NAME),
       MAIL_STATE_DC = CASE
                          WHEN c.VEND_COUNTRY is NULL THEN c.VEND_STATE
                          ELSE d.MAIL_STATE_DC
                       END,
       COUNTRY_CD = c.VEND_COUNTRY
  FROM (SELECT a.VENDOR_ID, a.VEND_NAME, a.VEND_ST_ADDRESS, a.VEND_CITY,
               a.VEND_STATE, a.VEND_COUNTRY
          FROM dbo.XX_PCLAIM_IN a
         WHERE WORK_DATE = (SELECT MAX(b.WORK_DATE) AS WORK_DATE
                              FROM dbo.XX_PCLAIM_IN b
                             WHERE a.VENDOR_ID = b.VENDOR_ID
                           )
         GROUP BY a.VENDOR_ID, a.VEND_NAME, a.VEND_ST_ADDRESS, a.VEND_CITY,
                  a.VEND_STATE, a.VEND_COUNTRY) c
       left join IMAPS.Deltek.MAIL_STATE d
       ON (d.MAIL_STATE_NAME = c.VEND_STATE and d.COUNTRY_CD = c.VEND_COUNTRY)
 WHERE VEND_ID = c.VENDOR_ID
   AND ADDR_DC = 'PAYTO'
-- CP600000324_Begin
   AND COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000324_End

-- 10/10/2006_begin
SELECT @out_SystemError = @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 GOTO ErrorProcessing
-- 10/10/2006_end

--TRUNCATE TABLE dbo.XX_PCLAIM_IN

-- update status record with preprocessor validation data
UPDATE dbo.XX_IMAPS_INT_STATUS 
   SET RECORD_COUNT_SUCCESS = @TotalImportedRecords, 
       RECORD_COUNT_ERROR   = @TotalErrorRecords,
       AMOUNT_PROCESSED     = @TotalImportedHours,
       AMOUNT_FAILED        = @TotalErrorHours
 WHERE STATUS_RECORD_NUM = @in_status_record_num

SELECT @out_SystemError= @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 GOTO ErrorProcessing

SELECT @TotalInputHours = ISNULL(AMOUNT_INPUT, 0),
       @TotalInputRecords = ISNULL(RECORD_COUNT_INITIAL, 0)
  FROM dbo.XX_IMAPS_INT_STATUS 	
 WHERE STATUS_RECORD_NUM = @in_status_record_num

SELECT @out_SystemError= @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 GOTO ErrorProcessing

IF @TotalInputRecords <> (@TotalImportedRecords + @TotalErrorRecords) OR
   @TotalInputHours <> (@TotalImportedHours + @TotalErrorHours)
   RETURN(522)

declare @PCLAIM_USER_ID char(6)

set @PCLAIM_USER_ID = 'PCLAIM'

update IMAPS.Deltek.VCHR_HDR
   set ENTR_USER_ID = @PCLAIM_USER_ID
 where left(notes, len(@in_status_record_num) + 1) = (cast(@in_status_record_num as varchar) + ' ')
-- CP600000324_Begin
   and COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000324_End

SELECT @out_SystemError= @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 GOTO ErrorProcessing





--new miscode reporting

PRINT 'ARCHIVE PREVIOUS MISCODES'

INSERT INTO XX_PCLAIM_IN_MISCODES_ARCH
SELECT * FROM XX_PCLAIM_IN_MISCODES

SELECT @out_SystemError= @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 GOTO ErrorProcessing




PRINT 'TRUNCATE PREVIOUS MISCODES'

TRUNCATE TABLE XX_PCLAIM_IN_MISCODES

SELECT @out_SystemError= @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 GOTO ErrorProcessing



PRINT 'GET CURRENT MISCODES'

INSERT INTO XX_PCLAIM_IN_MISCODES
(PCLAIM_IN_RECORD_NUM,
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
MODIFIED_BY,
MODIFIED_DATE,
VCHR_NO,
SUB_LN_NO,
S_STATUS_CD,
VCHR_LN_NO,
PAY_TYPE,
UNID,
REVISION_NUM)
SELECT PCLAIM_IN_RECORD_NUM,
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
MODIFIED_BY,
MODIFIED_DATE,
VCHR_NO,
SUB_LN_NO,
S_STATUS_CD,
VCHR_LN_NO,
PAY_TYPE,
UNID,
REVISION_NUM
  FROM dbo.XX_PCLAIM_IN_ARCH
 WHERE status_record_num = @in_status_record_num
   AND s_status_cd = 'E'

SELECT @out_SystemError= @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 GOTO ErrorProcessing



PRINT 'UPDATE MISCODE FEEDBACK'
UPDATE XX_PCLAIM_IN_MISCODES
SET FEEDBACK=''


UPDATE XX_PCLAIM_IN_MISCODES
SET FEEDBACK = FEEDBACK+',PLC not in Costpoint,'
where status_record_num = @in_status_record_num
and s_status_cd='E'
and plc not in
(select bill_lab_cat_cd from 
 imaps.deltek.bill_lab_cat)


SELECT @out_SystemError= @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 GOTO ErrorProcessing



UPDATE XX_PCLAIM_IN_MISCODES
SET FEEDBACK = FEEDBACK+',PLC not in Costpoint,'
where status_record_num = @in_status_record_num
and s_status_cd='E'
and plc not in
(select bill_lab_cat_cd from 
 imaps.deltek.bill_lab_cat)


SELECT @out_SystemError= @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 GOTO ErrorProcessing



UPDATE XX_PCLAIM_IN_MISCODES
SET FEEDBACK = FEEDBACK+',VEN_EMPL_SERIAL_NUM not in Costpoint,'
where status_record_num = @in_status_record_num
and s_status_cd='E'
and 
rtrim(VEND_EMPL_SERIAL_NUM)+rtrim(VENDOR_ID) not in
(select rtrim(vend_empl_id)+rtrim(vend_id) from imaps.deltek.vend_empl)


SELECT @out_SystemError= @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 GOTO ErrorProcessing





UPDATE XX_PCLAIM_IN_MISCODES
SET FEEDBACK = FEEDBACK+',PROJ_CODE inactive or not in Costpoint,'
where status_record_num = @in_status_record_num
and s_status_cd='E'
and PROJ_CODE not in (select proj_abbrv_cd from imaps.deltek.proj where proj_abbrv_cd<>'' and active_fl='Y')

SELECT @out_SystemError= @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 GOTO ErrorProcessing








UPDATE XX_PCLAIM_IN_MISCODES
SET FEEDBACK = FEEDBACK+',PROJ_CODE and PLC combination invalid,'
from  xx_pclaim_in_miscodes pclaim
inner join
imaps.deltek.proj proj
on
(pclaim.PROJ_CODE = proj.proj_abbrv_cd)
where status_record_num = @in_status_record_num
and pclaim.s_status_cd='E'
and proj.proj_id in
(select proj_id from imaps.deltek.tm_rt_order)
and
pclaim.PLC not in
(
 select bill_lab_cat_cd from
 imaps.deltek.proj_lab_cat plc
 inner join
 imaps.deltek.tm_rt_order tm
 on
 (tm.srce_proj_id = plc.proj_id
 and tm.seq_no = 1
 and tm.proj_id = proj.proj_id)
)
and 
pclaim.PLC in
(select bill_lab_cat_cd from imaps.deltek.bill_lab_cat)


SELECT @out_SystemError= @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 GOTO ErrorProcessing






UPDATE XX_PCLAIM_IN_MISCODES
SET FEEDBACK = FEEDBACK+',PROJ_CODE PAG does not allow subcontractors,'
from  xx_pclaim_in_miscodes pclaim
inner join
imaps.deltek.proj proj
on
(pclaim.PROJ_CODE = proj.proj_abbrv_cd)
where status_record_num = @in_status_record_num
and pclaim.s_status_cd='E'
and
0 = 
(select count(1)
 from imaps.deltek.acct_grp_setup
 where acct_grp_cd = proj.acct_grp_cd
 and acct_id > '40-00-00' and acct_id < '90-00-00'
 and (acct_id like '%4-20' or acct_id like '%4-25'))


SELECT @out_SystemError= @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 GOTO ErrorProcessing





UPDATE XX_PCLAIM_IN_MISCODES
SET FEEDBACK = FEEDBACK+',PROJ_CODE Owning ORG does not allow subcontractors,'
from  xx_pclaim_in_miscodes pclaim
inner join
imaps.deltek.proj proj
on
(pclaim.PROJ_CODE = proj.proj_abbrv_cd)
where status_record_num = @in_status_record_num
and pclaim.s_status_cd='E'
and
0 = 
(select count(1)
 from imaps.deltek.org_acct
 where org_id = proj.org_id
 and active_fl='Y'
 and acct_id > '40-00-00' and acct_id < '90-00-00'
 and (acct_id like '%4-20' or acct_id like '%4-25'))


SELECT @out_SystemError= @@ERROR, @NumberOfRecords = @@ROWCOUNT

IF @out_SystemError > 0 GOTO ErrorProcessing






RETURN(0)

ErrorProcessing:

RETURN(1)


go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_PCLAIM_ARCHIVE_SP') IS NOT NULL
    PRINT ''
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_PCLAIM_ARCHIVE_SP >>> - WTF?'
go

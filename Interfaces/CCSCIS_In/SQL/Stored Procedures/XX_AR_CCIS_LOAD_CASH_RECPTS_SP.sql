USE [IMAPSStg]
GO

IF EXISTS (SELECT * FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[dbo].[XX_AR_CCIS_LOAD_CASH_RECPTS_SP]') AND OBJECTPROPERTY(ID, N'ISPROCEDURE') = 1)
   DROP PROCEDURE [dbo].[XX_AR_CCIS_LOAD_CASH_RECPTS_SP]
GO

CREATE PROCEDURE dbo.XX_AR_CCIS_LOAD_CASH_RECPTS_SP
(
@in_STATUS_RECORD_NUM     integer,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS
/*******************************************************************************************************
Name:       XX_AR_CCIS_LOAD_CASH_RECPTS_SP
Author:     KM
Created:    12/2005
Purpose:    LOADS the CASH RECPTS TABLE
Parameters: 
Result Set: None
Notes:

CR-1543  05/20/2008 Costpoint multi-company fix (two instances).
         Reference No. CP600000321

CR-11452 10/30/2019 Costpoint 7.1.1 Upgrade - The definition of Costpoint tables DELTEK.CASH_RECPT_HDR
         and DELTEK.CASH_RECPT_TRN has changed. Update definition of staging tables XX_AR_CASH_RECPT_HDR
         and XX_AR_CASH_RECPT_TRN.
********************************************************************************************************/

BEGIN

DECLARE	@SP_NAME           	sysname,
        @IMAPS_error_number     integer,
        @SQLServer_error_code   integer,
        @row_count              integer,
        @error_msg_placeholder1 sysname,
        @error_msg_placeholder2 sysname,
        @INTERFACE_NAME	 	varchar(5),
        @DIV_16_COMPANY_ID      varchar(10),
        @amount                 decimal(14,2)

-- Set local constants
SET @SP_NAME = 'XX_AR_CCIS_LOAD_CASH_RECPTS_SP'
SET @INTERFACE_NAME = 'AR_COLLECTION'

-- CP600000321_Begin
SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = @INTERFACE_NAME
-- CP600000321_End

PRINT 'Update XX_IMAPS_INT_STATUS.AMOUNT_INPUT ...'

--0. UPDATE INTERFACE STATUS RECORD WITH AMOUNT INPUT
--DR3459
SELECT @amount = SUM(TRN_AMT)
  FROM dbo.XX_AR_CASH_RECPT_TRN
 WHERE TRN_DESC = 'A/R Cleared Summary'

UPDATE DBO.XX_IMAPS_INT_STATUS
   SET AMOUNT_INPUT = @amount,
       MODIFIED_BY = SUSER_SNAME(),
       MODIFIED_DATE = GETDATE()
 WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

PRINT 'Insert one DELTEK.CASH_RECPT_HDR record using dbo.XX_AR_CASH_RECPT_HDR data ...'

--1. ATTEMPT TO INSERT TO IMAPS.DELTEK.CASH_RECPT_HDR
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'INSERT INTO'
SET @error_msg_placeholder2 = 'IMAPS.DELTEK.CASH_RECPT_HDR'

INSERT INTO IMAPS.DELTEK.CASH_RECPT_HDR
   SELECT * FROM DBO.XX_AR_CASH_RECPT_HDR

IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

PRINT 'Update DELTEK.SEQ_GENERATOR.LAST_KEY with MAX(DELTEK.CASH_RECPT_HDR.CASH_RECPT_HDR_KEY) for S_TABLE_ID = ''CASH_RECPT_HDR'' ...'

--KM 1M changes
--1a. UPDATE SEQ_GEN FOR IMAPS.DELTEK.CASH_RECPT_HDR
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'UPDATE SEQ_GEN FOR'
SET @error_msg_placeholder2 = 'IMAPS.DELTEK.CASH_RECPT_HDR'


UPDATE IMAPS.DELTEK.SEQ_GENERATOR
   SET LAST_KEY = (select MAX(CASH_RECPT_HDR_KEY) from IMAPS.DELTEK.CASH_RECPT_HDR),
       MODIFIED_BY = 'CCIS Interface',
       TIME_STAMP = GETDATE()
 WHERE S_TABLE_ID = 'CASH_RECPT_HDR' -- CR-11452

IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


--2. ATTEMPT TO INSERT TO IMAPS.DELTEK.CASH_RECPT_TRN
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'INSERT INTO'
SET @error_msg_placeholder2 = 'IMAPS.DELTEK.CASH_RECPT_TRN'


PRINT 'Insert DELTEK.CASH_RECPT_TRN records using XX_AR_CASH_RECPT_TRN data ...'

INSERT INTO IMAPS.DELTEK.CASH_RECPT_TRN
   SELECT * FROM DBO.XX_AR_CASH_RECPT_TRN

IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


PRINT 'Update DELTEK.SEQ_GENERATOR.LAST_KEY with MAX(DELTEK.CASH_RECPT_HDR.CASH_RECPT_TRN_KEY) for S_TABLE_ID = ''CASH_RECPT_TRN'' ...'

--KM 1M changes
--2a. UPDATE SEQ_GEN FOR IMAPS.DELTEK.CASH_RECPT_HDR
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'UPDATE SEQ_GEN FOR'
SET @error_msg_placeholder2 = 'IMAPS.DELTEK.CASH_RECPT_TRN'


SELECT MAX(CASH_RECPT_TRN_KEY) FROM IMAPS.DELTEK.CASH_RECPT_TRN

UPDATE IMAPS.DELTEK.SEQ_GENERATOR
   SET LAST_KEY = (select MAX(CASH_RECPT_TRN_KEY) from IMAPS.DELTEK.CASH_RECPT_TRN),
       MODIFIED_BY = 'CCIS Interface',
       TIME_STAMP = GETDATE()
 WHERE S_TABLE_ID = 'CASH_RECPT_TRN' -- CR-11452

IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


PRINT 'Update XX_IMAPS_INT_STATUS.AMOUNT_PROCESSED ...'

--3. UPDATE INTERFACE STATUS RECORD WITH NUMBER SUCCESS
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'UPDATE XX_IMAPS_INT_STATUS'
SET @error_msg_placeholder2 = 'NUMBER RECORDS SUCCESS'


SELECT @row_count = COUNT(CASH_RECPT_TRN_KEY)
  FROM DBO.XX_AR_CASH_RECPT_TRN
 WHERE TRN_DESC <> 'A/R Cleared Summary'

--DR3459
SELECT @amount = SUM(TRN_AMT)
  FROM dbo.XX_AR_CASH_RECPT_TRN
 WHERE TRN_DESC = 'A/R Cleared Summary'

UPDATE dbo.XX_IMAPS_INT_STATUS
   SET AMOUNT_PROCESSED = @amount,
       AMOUNT_FAILED = (AMOUNT_INPUT - @amount),
       MODIFIED_BY = SUSER_SNAME(),
       MODIFIED_DATE = GETDATE()
 WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER


PRINT 'Insert DELTEK.AR_NOTES_HS records via cursor using XX_AR_CCIS_OPEN_REMARKS data ...'

--4. LOAD AR NOTES TABLE WITH OPEN REMARKS

--IT SUCKS, BUT I HAD TO:

--PUT A CURSOR AND WHILE LOOP HERE TO SET NOTES_DT = NOTES_DT + 00:01:00 SO THAT IT DOES NOT VIOLATE THE INDEX ON THE COSTPOINT TABLE

SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'INSERT CCIS REMARKS'
SET @error_msg_placeholder2 = 'TO DELTEK.AR_NOTES_HS'

DECLARE @INVC_ID     VARCHAR(15),
	@NOTES_DT    SMALLDATETIME,
	@NOTES_DESC  VARCHAR(60),
	@MODIFIED_BY VARCHAR(20),
	@TIME_STAMP  DATETIME,
	@COMPANY_ID  VARCHAR(10)

SET @MODIFIED_BY = USER_NAME()
SET @TIME_STAMP = GETDATE()

DECLARE REMARKS_CURSOR CURSOR FAST_FORWARD FOR
   SELECT IMAPS.INVC_ID, CAST(GETDATE() as smalldatetime), 
          CAST( (CCIS.REMARK + ':' + AMTOPEN) as varchar(60)), 
          IMAPS.COMPANY_ID
     FROM IMAPS.DELTEK.AR_HDR_HS IMAPS
          INNER JOIN
          dbo.XX_AR_CCIS_OPEN_REMARKS CCIS
          ON
          (
          CCIS.INVNO = RIGHT(IMAPS.INVC_ID, 7)
          AND RTRIM(CCIS.CUSTNO) = IMAPS.ADDR_DC
-- CP600000321_Begin
          AND IMAPS.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000321_End
          )
    ORDER BY CCIS.TIME_STAMP

OPEN REMARKS_CURSOR
FETCH NEXT FROM REMARKS_CURSOR INTO @INVC_ID, @NOTES_DT, @NOTES_DESC, @COMPANY_ID

WHILE @@FETCH_STATUS = 0
   BEGIN
      DECLARE @GOOD_DATE INT
		
      SET @GOOD_DATE = 1
	
      WHILE @GOOD_DATE <> 0
         BEGIN
            IF (0 <> (SELECT COUNT(1)
                        FROM IMAPS.DELTEK.AR_NOTES_HS
                       WHERE INVC_ID = @INVC_ID 
                         AND NOTES_DT = @NOTES_DT
                         AND COMPANY_ID = @COMPANY_ID
                         AND COMPANY_ID = @DIV_16_COMPANY_ID)
                     )
               BEGIN
                  SET @NOTES_DT = @NOTES_DT + '00:01:00'
               END
            ELSE
               BEGIN
                  SET @GOOD_DATE = 0
               END
         END

      INSERT INTO IMAPS.DELTEK.AR_NOTES_HS
         (INVC_ID, NOTES_DT, NOTES_DESC, MODIFIED_BY, TIME_STAMP, COMPANY_ID)
         SELECT @INVC_ID, @NOTES_DT, @NOTES_DESC, @MODIFIED_BY, @TIME_STAMP, @COMPANY_ID
	
      IF @@ERROR <> 0 
         BEGIN	
            CLOSE REMARKS_CURSOR
            DEALLOCATE REMARKS_CURSOR
            GOTO BL_ERROR_HANDLER
         END

      FETCH NEXT FROM REMARKS_CURSOR INTO @INVC_ID, @NOTES_DT, @NOTES_DESC, @COMPANY_ID
   END

CLOSE REMARKS_CURSOR
DEALLOCATE REMARKS_CURSOR

IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER

RETURN(0)

BL_ERROR_HANDLER:

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_number,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)


END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

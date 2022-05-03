IF OBJECT_ID('dbo.XX_R22_ET_VALIDATE_SOURCE_DATA_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_ET_VALIDATE_SOURCE_DATA_SP
    IF OBJECT_ID('dbo.XX_R22_ET_VALIDATE_SOURCE_DATA_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_ET_VALIDATE_SOURCE_DATA_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_ET_VALIDATE_SOURCE_DATA_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go
CREATE PROCEDURE dbo.XX_R22_ET_VALIDATE_SOURCE_DATA_SP
(
@out_STATUS_DESCRIPTION varchar(255) = NULL OUTPUT
)
AS

/******************************************************************************************************
Name:       XX_R22_ET_VALIDATE_SOURCE_DATA_SP
Author:     HVT
Created:    09/19/2005
Purpose:    After data from the source input file have been loaded into staging tables, inspect
            this data by performing data type validation before processing.
            Also verify that the total number of detail records matches that of the footer record,
            and the total regular time from the detail records matches that of the footer record.
            Upon the very first error encountered, halt all interface processing.

            Called by XX_R22_LOAD_ET_STAGING_DATA_SP.
Parameters: 
Result Set: None
Notes:

Feature 415 01/26/2006 - Add code to process new column XX_IMAPS_ET_IN_TMP.AMENDMENT_NUM.

Defect 741  06/14/2006 - The total number of detail records in the footer record in the source input
            file supplied by eT&E system is changed from the total number of text lines (representing
            detail records) to the total number of text lines multiplied by 7.
            
CR-1333     ILC_ACTIVITY_CD added 12/07/07
CR-1539     PAY_TYPE added 04/29/08

DR4037      03/13/2012 CP600001476
            Enable eTime interface and eTime miscode interfaces for divisions 16 and 22 to run
            simultaneously.
*******************************************************************************************************/

DECLARE @SP_NAME                sysname,
        @SPACE_CHAR             char(1),
        @in_TS_YEAR             char(4),
        @in_TS_MONTH            char(2),
        @in_TS_DAY              char(2),
        @in_SAT_REG_TIME        varchar(6),
        @in_SAT_OVERTIME        varchar(6),
        @in_SUN_REG_TIME        varchar(6),
        @in_SUN_OVERTIME        varchar(6),
        @in_MON_REG_TIME        varchar(6),
        @in_MON_OVERTIME        varchar(6),
        @in_TUE_REG_TIME        varchar(6),
        @in_TUE_OVERTIME        varchar(6),
        @in_WED_REG_TIME        varchar(6),
        @in_WED_OVERTIME        varchar(6),
        @in_THU_REG_TIME        varchar(6),
        @in_THU_OVERTIME        varchar(6),
        @in_FRI_REG_TIME        varchar(6),
        @in_FRI_OVERTIME        varchar(6),
        @in_RECORD_TYPE         varchar(1),
        @in_AMENDMENT_NUM       varchar(2),
        @in_ILC_ACTIVITY_CD     varchar(6), -- Added CR-1333
        @in_PAY_TYPE            varchar(3), -- Added CR-1539 
        @str_TS_DT              char(10),
        @c_tot_ftr_rec_count    char(66),
        @c_tot_ftr_reg_time     char(11),
        @tot_dtl_rec_count      integer,
	@tot_dtl_reg_time       decimal(14, 2),
        @bad_data_flag          tinyint,
        @rowcount               integer,
        @error_msg              varchar(255),
        @error_desc             varchar(100)

-- set local constants
SET @SP_NAME = 'XX_R22_ET_VALIDATE_SOURCE_DATA_SP'
SET @SPACE_CHAR = ' '

-- set local variable
SET @bad_data_flag = 0 -- 0 = no error recorded; 1 = error has been recorded
SET @tot_dtl_rec_count = 0  
SET @tot_dtl_reg_time = 0.0

-- First, make sure that staging tables XX_IMAPS_ET_IN_TMP and XX_IMAPS_ET_FTR_IN_TMP have data
SELECT @rowcount = COUNT(1) FROM dbo.XX_R22_IMAPS_ET_IN_TMP

IF @rowcount = 0
   BEGIN
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 305,
         @in_placeholder_value1  = 'ETIME_R22 interface', -- DR4037
         @in_display_requested   = 0,
         @in_calling_object_name = @SP_NAME,
         @out_msg_text           = @error_msg OUTPUT

      SET @error_desc = 'No data in the staging table XX_R22_IMAPS_ET_IN_TMP.'
      SET @out_STATUS_DESCRIPTION = @error_msg + @SPACE_CHAR + @error_desc
      SET @error_msg = @error_msg + CHAR(13) + @error_desc + ' [' + @SP_NAME + ']'
      PRINT @error_msg
      RETURN(1)
   END

SELECT @rowcount = COUNT(1) FROM dbo.XX_R22_IMAPS_ET_FTR_IN_TMP

IF @rowcount = 0
   BEGIN
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 305,
         @in_placeholder_value1  = 'ETIME_R22 interface', -- DR4037
         @in_display_requested   = 0,
         @out_msg_text           = @error_msg OUTPUT

      SET @error_desc = 'No data in the staging table XX_R22_IMAPS_ET_FTR_IN_TMP.'
      SET @out_STATUS_DESCRIPTION = @error_msg + @SPACE_CHAR + @error_desc
      SET @error_msg = @error_msg + CHAR(13) + @error_desc + ' [' + @SP_NAME + ']'
      PRINT @error_msg
      RETURN(1)
   END

DECLARE cursor_chk CURSOR FOR
   SELECT TS_YEAR, TS_MONTH, TS_DAY, SAT_REG_TIME, SAT_OVERTIME, SUN_REG_TIME, SUN_OVERTIME,
          MON_REG_TIME, MON_OVERTIME, TUE_REG_TIME, TUE_OVERTIME, WED_REG_TIME, WED_OVERTIME,
          THU_REG_TIME, THU_OVERTIME, FRI_REG_TIME, FRI_OVERTIME, RECORD_TYPE, AMENDMENT_NUM,
          ILC_ACTIVITY_CD, -- Added CR-1333 
          PAY_TYPE -- Added CR-1539
     FROM dbo.XX_R22_IMAPS_ET_IN_TMP

OPEN cursor_chk
FETCH cursor_chk
   INTO @in_TS_YEAR, @in_TS_MONTH, @in_TS_DAY, @in_SAT_REG_TIME, @in_SAT_OVERTIME,
        @in_SUN_REG_TIME, @in_SUN_OVERTIME, @in_MON_REG_TIME, @in_MON_OVERTIME,
        @in_TUE_REG_TIME, @in_TUE_OVERTIME, @in_WED_REG_TIME, @in_WED_OVERTIME,
        @in_THU_REG_TIME, @in_THU_OVERTIME, @in_FRI_REG_TIME, @in_FRI_OVERTIME,
        @in_RECORD_TYPE, @in_AMENDMENT_NUM, @in_ILC_ACTIVITY_CD, -- Added CR-1333
        @in_PAY_TYPE

WHILE (@@FETCH_STATUS = 0)
   BEGIN
      -- the characters used to form a date value must be numeric and positive
      IF (ISNUMERIC(@in_TS_YEAR) = 1 AND ISNUMERIC(@in_TS_MONTH) = 1 AND ISNUMERIC(@in_TS_DAY) = 1) AND
         (CAST(@in_TS_YEAR AS NUMERIC) > 0 AND CAST(@in_TS_MONTH AS NUMERIC) > 0 AND CAST(@in_TS_DAY AS NUMERIC) > 0)
         BEGIN
            -- first, some very basic tests
            IF CAST(@in_TS_MONTH AS NUMERIC) > 12
               BEGIN
                  SET @bad_data_flag = 1
                  SET @error_desc = 'Month part value (XX_R22_IMAPS_ET_IN_TMP.TS_MONTH) is greater than 12.'
                  GOTO bl_BAD_DATA_EXIT -- jump to the branch label
               END
            IF CAST(@in_TS_DAY AS NUMERIC) > 31
               BEGIN
                  SET @bad_data_flag = 1
                  SET @error_desc = 'Day part value (XX_R22_IMAPS_ET_IN_TMP.TS_DAY) is greater than 31.'
                  GOTO bl_BAD_DATA_EXIT
               END

            SET @str_TS_DT = @in_TS_YEAR + '-' + @in_TS_MONTH + '-' +  @in_TS_DAY
            IF ISDATE(@str_TS_DT) = 0 
               BEGIN
                  SET @bad_data_flag = 1
                  SET @error_desc = 'The assembled timesheet date expression is not a valid date.'
                  GOTO bl_BAD_DATA_EXIT
               END
         END
      ELSE
         BEGIN
            SET @bad_data_flag = 1
            SET @error_desc = 'One or more timesheet date parts are not numeric.'
            GOTO bl_BAD_DATA_EXIT
         END

      -- check the characters that form the hour amount values; they must be numeric
      IF ISNUMERIC(@in_SAT_REG_TIME) = 0 OR ISNUMERIC(@in_SAT_OVERTIME) = 0 OR ISNUMERIC(@in_SUN_REG_TIME) = 0 OR
         ISNUMERIC(@in_SUN_OVERTIME) = 0 OR ISNUMERIC(@in_MON_REG_TIME) = 0 OR ISNUMERIC(@in_MON_OVERTIME) = 0 OR
         ISNUMERIC(@in_TUE_REG_TIME) = 0 OR ISNUMERIC(@in_TUE_OVERTIME) = 0 OR ISNUMERIC(@in_WED_REG_TIME) = 0 OR
         ISNUMERIC(@in_WED_OVERTIME) = 0 OR ISNUMERIC(@in_THU_REG_TIME) = 0 OR ISNUMERIC(@in_THU_OVERTIME) = 0 OR
         ISNUMERIC(@in_FRI_REG_TIME) = 0 OR ISNUMERIC(@in_FRI_OVERTIME) = 0
         BEGIN
            SET @bad_data_flag = 1
            SET @error_desc = 'One or more hour amount expressions are not numeric.'
            GOTO bl_BAD_DATA_EXIT
         END

      IF NOT @in_RECORD_TYPE IN ('R', 'C','N','D') -- R=Regular, C=Correcting
         BEGIN
            SET @bad_data_flag = 1
            SET @error_desc = 'Invalid record type value.'
            GOTO bl_BAD_DATA_EXIT
         END

      IF ISNUMERIC(@in_AMENDMENT_NUM) = 0
         BEGIN
            SET @bad_data_flag = 1
            SET @error_desc = 'Amendment number value is not numeric.'
          GOTO bl_BAD_DATA_EXIT
        END

      SET @tot_dtl_rec_count = @tot_dtl_rec_count + 1

      SET @tot_dtl_reg_time = @tot_dtl_reg_time + CAST(@in_SAT_REG_TIME AS decimal(14, 2)) +
                              CAST(@in_SUN_REG_TIME AS decimal(14, 2)) + CAST(@in_MON_REG_TIME AS decimal(14, 2)) +
                              CAST(@in_TUE_REG_TIME AS decimal(14, 2)) + CAST(@in_WED_REG_TIME AS decimal(14, 2)) +
                              CAST(@in_THU_REG_TIME AS decimal(14, 2)) + CAST(@in_FRI_REG_TIME AS decimal(14, 2))

      FETCH cursor_chk
         INTO @in_TS_YEAR, @in_TS_MONTH, @in_TS_DAY, @in_SAT_REG_TIME, @in_SAT_OVERTIME,
              @in_SUN_REG_TIME, @in_SUN_OVERTIME, @in_MON_REG_TIME, @in_MON_OVERTIME,
              @in_TUE_REG_TIME, @in_TUE_OVERTIME, @in_WED_REG_TIME, @in_WED_OVERTIME,
              @in_THU_REG_TIME, @in_THU_OVERTIME, @in_FRI_REG_TIME, @in_FRI_OVERTIME,
              @in_RECORD_TYPE, @in_AMENDMENT_NUM, @in_ILC_ACTIVITY_CD, --Added CR-1333
              @in_PAY_TYPE -- Added CR-1539  
   END /* WHILE (@@FETCH_STATUS = 0) */


-- Validate the footer record
SELECT @c_tot_ftr_reg_time = TOTAL_REG_TIME, @c_tot_ftr_rec_count = TOTAL_RECORDS
  FROM dbo.XX_R22_IMAPS_ET_FTR_IN_TMP

-- check the characters that form the hour amount values; they must be numeric
IF ISNUMERIC(@c_tot_ftr_reg_time) = 0 OR ISNUMERIC(@c_tot_ftr_rec_count) = 0
   BEGIN
      SET @bad_data_flag = 1
      SET @error_desc = 'One or more footer record amount expressions are not numeric.'
      GOTO bl_BAD_DATA_EXIT
   END

-- Defect 741 Begin
/*
 * Multiply the total number of records in staging table XX_IMAPS_ET_IN_TMP (i.e., the total number of text lines in the
 * source input file representing detail records) by 7 (days of the week). This results in a value comparable to the total
 * number of timesheet records fed to the Costpoint timesheet preprocessor.
 */
SET @tot_dtl_rec_count = @tot_dtl_rec_count * 7
-- Defect 741 End

IF @tot_dtl_rec_count <> CAST(@c_tot_ftr_rec_count AS integer)
   BEGIN
      SET @bad_data_flag = 1
      SET @error_desc = 'The total number of detail records does not match that of the footer record.'
      GOTO bl_BAD_DATA_EXIT
   END

IF @tot_dtl_reg_time <> CAST(@c_tot_ftr_reg_time AS decimal(14, 2))
   BEGIN
      SET @bad_data_flag = 1
      SET @error_desc = 'The total regular time from the detail records does not match that of the footer record.'
      GOTO bl_BAD_DATA_EXIT
   END

bl_BAD_DATA_EXIT:

CLOSE cursor_chk
DEALLOCATE cursor_chk

IF @bad_data_flag = 1
   BEGIN
      -- Bad or nonexistent source input eTime interface data.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 305,
         @in_display_requested   = 0,
         @in_placeholder_value1  = 'ETIME_R22 interface', -- DR4037
         @out_msg_text           = @error_msg OUTPUT

      SET @out_STATUS_DESCRIPTION = @error_msg + @SPACE_CHAR + @error_desc
      SET @error_msg = @error_msg + CHAR(13) + @error_desc + ' [' + @SP_NAME + ']'
      PRINT @error_msg
      RETURN(1)
   END

RETURN(0)
go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_R22_ET_VALIDATE_SOURCE_DATA_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_ET_VALIDATE_SOURCE_DATA_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_ET_VALIDATE_SOURCE_DATA_SP >>>'
go

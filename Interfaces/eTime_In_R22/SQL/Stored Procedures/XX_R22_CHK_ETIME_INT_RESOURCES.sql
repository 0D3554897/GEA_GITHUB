IF OBJECT_ID('dbo.XX_R22_CHK_ETIME_INT_RESOURCES') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_R22_CHK_ETIME_INT_RESOURCES
    IF OBJECT_ID('dbo.XX_R22_CHK_ETIME_INT_RESOURCES') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_R22_CHK_ETIME_INT_RESOURCES >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_R22_CHK_ETIME_INT_RESOURCES >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go

CREATE PROCEDURE dbo.XX_R22_CHK_ETIME_INT_RESOURCES AS
BEGIN

/************************************************************************************************
Name:       XX_CHK_ETIME_INT_RESOURCES
Author:     HVT
Created:    07/15/2005
Purpose:    Retrieve the IMAPS DB name, schema or table owner name and verify that all tables
            commissioned by the eTime interface exist before proceeding with core processing.
Parameters: 
Result Set: None
Notes:      
*************************************************************************************************/

DECLARE @SP_NAME                 sysname,
        @IMAPS_SCHEMA_OWNER      sysname,
        @lv_eTime_DB_name        sysname,
        @lv_IMAPS_table_name     sysname,
        @lv_missing_table_list   varchar(1000),
        @lv_status_desc          varchar(255)

-- set local constants
SET @SP_NAME = 'XX_R22_CHK_ETIME_INT_RESOURCES'
SET @IMAPS_SCHEMA_OWNER = 'dbo'

-- set local variables
SET @lv_missing_table_list = ''
SET @lv_eTime_DB_name = db_name()

-- local temporary table holds the controlled master list of tables used by the eTime interface
CREATE TABLE #eTimeTempTable_1 (IMAPS_TABLE_NAME sysname PRIMARY KEY)

-- load local temporary table with names of all tables used by the eTime interface
INSERT INTO #eTimeTempTable_1 VALUES('XX_R22_CP_PLC_CODE')
INSERT INTO #eTimeTempTable_1 VALUES('XX_R22_CP_PLC_CODE_COUNT')
INSERT INTO #eTimeTempTable_1 VALUES('XX_R22_ET_DAILY_IN')
INSERT INTO #eTimeTempTable_1 VALUES('XX_R22_ET_DAILY_IN_ARC')
INSERT INTO #eTimeTempTable_1 VALUES('XX_R22_IMAPS_ET_FTR_IN_TMP')
INSERT INTO #eTimeTempTable_1 VALUES('XX_R22_IMAPS_ET_IN_TMP')
INSERT INTO #eTimeTempTable_1 VALUES('XX_IMAPS_INT_CONTROL')
INSERT INTO #eTimeTempTable_1 VALUES('XX_IMAPS_INT_STATUS')
INSERT INTO #eTimeTempTable_1 VALUES('XX_IMAPS_MAIL_OUT')
INSERT INTO #eTimeTempTable_1 VALUES('XX_R22_IMAPS_TS_PREP_TEMP')
INSERT INTO #eTimeTempTable_1 VALUES('XX_INT_ERROR_MESSAGE')
INSERT INTO #eTimeTempTable_1 VALUES('XX_LOOKUP_DETAIL')
INSERT INTO #eTimeTempTable_1 VALUES('XX_LOOKUP_DOMAIN')
INSERT INTO #eTimeTempTable_1 VALUES('XX_PROCESSING_PARAMETERS')
INSERT INTO #eTimeTempTable_1 VALUES('XX_R22_TS_PREP_ERRORS_TMP')
INSERT INTO #eTimeTempTable_1 VALUES('XX_PARAM_TEMP')

DECLARE cursor_one CURSOR FOR
   SELECT IMAPS_TABLE_NAME FROM #eTimeTempTable_1

OPEN cursor_one
FETCH cursor_one INTO @lv_IMAPS_table_name

WHILE (@@fetch_status = 0)
   BEGIN
      SELECT 1
        FROM sysobjects
       WHERE db_name() = @lv_eTime_DB_name
         AND user_name(uid) = @IMAPS_SCHEMA_OWNER
         AND xtype = 'U'
         AND name = @lv_IMAPS_table_name

      IF @@ROWCOUNT = 0
          IF DATALENGTH(@lv_missing_table_list) = 0
             SET @lv_missing_table_list = @lv_missing_table_list + @lv_IMAPS_table_name
          ELSE
             SET @lv_missing_table_list = @lv_missing_table_list + ', ' + @lv_IMAPS_table_name

      FETCH cursor_one INTO @lv_IMAPS_table_name
   END

CLOSE cursor_one
DEALLOCATE cursor_one

DROP TABLE #eTimeTempTable_1

IF DATALENGTH(@lv_missing_table_list) > 0
   BEGIN
      -- Missing required eTime interface table(s).
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 300,
         @in_display_requested   = 0,
         @in_calling_object_name = @SP_NAME,
         @out_msg_text           = @lv_status_desc OUTPUT

      PRINT @lv_status_desc + '(' +  @lv_missing_table_list + ')'
      RETURN(1)
   END

RETURN(0) -- 0 means success

END

go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_R22_CHK_ETIME_INT_RESOURCES') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_R22_CHK_ETIME_INT_RESOURCES >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_R22_CHK_ETIME_INT_RESOURCES >>>'
go

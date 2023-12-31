SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_7KEYS_CHK_RESOURCES_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_7KEYS_CHK_RESOURCES_SP]
GO



CREATE PROCEDURE dbo.XX_7KEYS_CHK_RESOURCES_SP AS

/************************************************************************************************
Name:       XX_7KEYS_CHK_RESOURCES_SP
Author:     HVT
Created:    11/04/2005
Purpose:    Verify that all tables used by the 7KEYS/PSP interface exist before proceeding with
            core processing.
            Called by XX_7KEYS_RUN_INTERFACE_SP.
Parameters: 
Result Set: None
Notes:      
*************************************************************************************************/

DECLARE @SP_NAME              sysname,
        @IMAPS_SCHEMA_OWNER   sysname,
        @IMAPS_DB_name        sysname,
        @IMAPS_table_name     sysname,
        @missing_table_list   varchar(1000),
        @status_desc          varchar(255)

PRINT 'Check for existence of required 7KEYS/PSP interface DB resources ...'

-- set local constants
SET @SP_NAME = 'XX_7KEYS_CHK_RESOURCES_SP'
SET @IMAPS_SCHEMA_OWNER = 'dbo'

-- set local variables
SET @missing_table_list = ''
SET @IMAPS_DB_name = db_name()

-- local temporary table holds the controlled master list of tables used by CERIS interface
CREATE TABLE #7KEYSTempTable_1 (IMAPS_TABLE_NAME sysname PRIMARY KEY)

-- Load local temporary table with names of all tables used by the CERIS/BluePages interface

-- for interface-specific source data retrieval from Deltek Costpoint system
INSERT INTO #7KEYSTempTable_1 VALUES('XX_7KEYS_OUT_DETAIL')
INSERT INTO #7KEYSTempTable_1 VALUES('XX_7KEYS_OUT_DETAIL_TEMP')
INSERT INTO #7KEYSTempTable_1 VALUES('XX_7KEYS_OUT_HDR')
INSERT INTO #7KEYSTempTable_1 VALUES('XX_7KEYS_OUT_HDR_TEMP')

-- for recording user-supplied execution job parameters
INSERT INTO #7KEYSTempTable_1 VALUES('XX_7KEYS_RUN_LOG')

-- for the administration of an interface job
INSERT INTO #7KEYSTempTable_1 VALUES('XX_IMAPS_INT_CONTROL')
INSERT INTO #7KEYSTempTable_1 VALUES('XX_IMAPS_INT_STATUS')
INSERT INTO #7KEYSTempTable_1 VALUES('XX_IMAPS_MAIL_OUT')
INSERT INTO #7KEYSTempTable_1 VALUES('XX_INT_ERROR_MESSAGE')
INSERT INTO #7KEYSTempTable_1 VALUES('XX_LOOKUP_DETAIL')
INSERT INTO #7KEYSTempTable_1 VALUES('XX_LOOKUP_DOMAIN')
INSERT INTO #7KEYSTempTable_1 VALUES('XX_PROCESSING_PARAMETERS')

DECLARE cursor_one CURSOR FOR
   SELECT IMAPS_TABLE_NAME FROM #7KEYSTempTable_1

OPEN cursor_one
FETCH cursor_one INTO @IMAPS_table_name

WHILE (@@fetch_status = 0)
   BEGIN
      SELECT 1
        FROM sysobjects
       WHERE db_name() = @IMAPS_DB_name
         AND user_name(uid) = @IMAPS_SCHEMA_OWNER
         AND xtype = 'U'
         AND name = @IMAPS_table_name

      IF @@ROWCOUNT = 0
          IF DATALENGTH(@missing_table_list) = 0
             SET @missing_table_list = @missing_table_list + @IMAPS_table_name
          ELSE
             SET @missing_table_list = @missing_table_list + ', ' + @IMAPS_table_name

      FETCH cursor_one INTO @IMAPS_table_name
   END

CLOSE cursor_one
DEALLOCATE cursor_one

DROP TABLE #7KEYSTempTable_1

IF DATALENGTH(@missing_table_list) > 0
   BEGIN
      -- Missing required CERIS interface table(s).
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 300,
         @in_display_requested   = 0,
         @in_calling_object_name = @SP_NAME,
         @out_msg_text           = @status_desc OUTPUT

      PRINT @status_desc + '(' +  @missing_table_list + ')'
      RETURN(1)
   END

RETURN(0) -- 0 means success



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.XX_CERIS_CHK_RESOURCES_SP    Script Date: 03/08/2006 10:59:07 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_CHK_RESOURCES_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_CERIS_CHK_RESOURCES_SP]
GO






CREATE PROCEDURE dbo.XX_CERIS_CHK_RESOURCES_SP AS

/************************************************************************************************
Name:       XX_CERIS_CHK_RESOURCES_SP
Author:     HVT
Created:    10/06/2005
Purpose:    Verify that all tables used by the CERIS interface exist before proceeding with core
            processing.
            Called by XX_CERIS_RUN_INTERFACE_SP.
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

PRINT 'Check for existence of required CERIS/BluePages interface DB resources ...'

-- set local constants
SET @SP_NAME = 'XX_CERIS_CHK_RESOURCES_SP'
SET @IMAPS_SCHEMA_OWNER = 'dbo'

-- set local variables
SET @missing_table_list = ''
SET @IMAPS_DB_name = db_name()

-- local temporary table holds the controlled master list of tables used by CERIS interface
CREATE TABLE #CERISTempTable_1 (IMAPS_TABLE_NAME sysname PRIMARY KEY)

-- Load local temporary table with names of all tables used by the CERIS/BluePages interface

-- for job-specific source data retrieval from eT&E system
INSERT INTO #CERISTempTable_1 VALUES('XX_CERIS_HIST')
INSERT INTO #CERISTempTable_1 VALUES('XX_CERIS_FIWLR_DIV16_STATUS')
INSERT INTO #CERISTempTable_1 VALUES('XX_CERIS_BLUEPAGES_HIST')
INSERT INTO #CERISTempTable_1 VALUES('XX_CERIS_PORT_NEW_ORGS')

-- for recording source data validation results
INSERT INTO #CERISTempTable_1 VALUES('XX_CERIS_VALIDAT_ERRORS')

-- for staging data to perform transactions directly against Costpoint tables
INSERT INTO #CERISTempTable_1 VALUES('XX_CERIS_CP_DFLT_TS_STG')
INSERT INTO #CERISTempTable_1 VALUES('XX_CERIS_CP_EMPL_LAB_STG')
INSERT INTO #CERISTempTable_1 VALUES('XX_CERIS_CP_EMPL_STG')
INSERT INTO #CERISTempTable_1 VALUES('XX_CERIS_CP_STG')

-- for retroactive timesheet processing
INSERT INTO #CERISTempTable_1 VALUES('XX_CERIS_RETRO_TS')
INSERT INTO #CERISTempTable_1 VALUES('XX_CERIS_RETRO_TS_PREP')
INSERT INTO #CERISTempTable_1 VALUES('XX_IMAPS_ET_IN_TMP')
INSERT INTO #CERISTempTable_1 VALUES('XX_ET_DAILY_IN')
INSERT INTO #CERISTempTable_1 VALUES('XX_IMAPS_TS_PREP_TEMP')

-- for archiving
INSERT INTO #CERISTempTable_1 VALUES('XX_CERIS_HIST_ARCHIVAL')
INSERT INTO #CERISTempTable_1 VALUES('XX_CERIS_HIST_ERROR_ARCHIVAL')
INSERT INTO #CERISTempTable_1 VALUES('XX_CERIS_RETRO_TS_PREP_ARCHIVAL')

-- for the administration of an interface job
INSERT INTO #CERISTempTable_1 VALUES('XX_IMAPS_INT_CONTROL')
INSERT INTO #CERISTempTable_1 VALUES('XX_IMAPS_INT_STATUS')
INSERT INTO #CERISTempTable_1 VALUES('XX_IMAPS_MAIL_OUT')
INSERT INTO #CERISTempTable_1 VALUES('XX_INT_ERROR_MESSAGE')
INSERT INTO #CERISTempTable_1 VALUES('XX_LOOKUP_DETAIL')
INSERT INTO #CERISTempTable_1 VALUES('XX_LOOKUP_DOMAIN')
INSERT INTO #CERISTempTable_1 VALUES('XX_PROCESSING_PARAMETERS')
INSERT INTO #CERISTempTable_1 VALUES('XX_PARAM_TEMP')

DECLARE cursor_one CURSOR FOR
   SELECT IMAPS_TABLE_NAME FROM #CERISTempTable_1

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

DROP TABLE #CERISTempTable_1

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


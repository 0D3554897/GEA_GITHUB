USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE ID = object_id(N'[dbo].[XX_R22_INSERT_PLC_SP]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[XX_R22_INSERT_PLC_SP]
GO


CREATE PROCEDURE [dbo].[XX_R22_INSERT_PLC_SP]
AS

/************************************************************************************************  
Name:       XX_R22_INSERT_PLC_SP  
Authors:    Veera
Created:    06/12/2008  
Purpose:    Refresh PLC table in Staging and eTime db (using a dblink ETIME).
Parameters: None
Notes:

			Improved SELECT statement using CASE statement to insure that the charge code value
            (PROJ.PROJ_ABBRV_CD) isn't blank, a data entry shortcoming in Costpoint.

			Send only those PLCs whose rates have actually been configured. Also, send more
            specific start and end date values for the PLCs.

			04/21/2008 (BP&S Change Request No. CR1543)
            Costpoint multi-company fix (three instances).
CR-7222		Modified for CR-7222

*************************************************************************************************/  

DECLARE @SP_NAME              sysname,
        @ETIME_INTERFACE      varchar(50),
        @DIV_22_COMPANY_ID    varchar(10),
        @rowcount             integer,
        @SQLServer_error_code integer,
        @IMAPS_error_code     integer

BEGIN

-- set local constants
SELECT @SP_NAME = 'XX_R22_INSERT_PLC_SP'
SET @ETIME_INTERFACE = 'ETIME_R22'

-- initialize local variables
SET @IMAPS_error_code = 204

-- Truncate staging PLC tables in IMAR database
TRUNCATE TABLE dbo.XX_R22_CP_PLC_CODE
TRUNCATE TABLE dbo.XX_R22_CP_PLC_CODE_COUNT

SELECT @DIV_22_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = @ETIME_INTERFACE   
   AND PARAMETER_NAME = 'COMPANY_ID'

/*
 * Populate the PLC staging table in IMAR database.
 * If the value of PROJ.PROJ_ABBRV_CD is a single whitespace character, then use the value of
 * PROJ.Ln_PROJ_SEG_ID where n = 1, 2, 3, ... depending on the value of PROJ.LVL_NO where
 * PROJ_LAB_CAT.BILL_LAB_CAT_CD is assigned.
 * With this provision, a record is always returned with both a PLC and charge code values. 
 */

--PROJ_LAB_CAT ONLY PLCs
insert into dbo.XX_R22_CP_PLC_CODE
   (PROJECT_ID, PLC, PLC_DESC, PLC_STATUS, PLC_DATE_OPN, PLC_DATE_CLSD)
   select distinct
          proj.proj_abbrv_cd,
          plc.bill_lab_cat_cd,
          plc.bill_lab_cat_desc,
          proj.active_fl,
          proj.proj_start_dt,
          proj.proj_end_dt
     from imar.deltek.PROJ proj
          inner join
          imar.deltek.PROJ_LAB_CAT plc
          on
          (proj.proj_id = plc.proj_id)
          AND
          (proj.COMPANY_ID = plc.COMPANY_ID)
          AND
          (proj.COMPANY_ID = @DIV_22_COMPANY_ID)
    where plc.proj_id not in (select proj_id from imar.deltek.TM_RT_ORDER)
      and proj.proj_abbrv_cd <> ' '

--TM_RT_ORDER VALID PLCs
insert into dbo.XX_R22_CP_PLC_CODE
   (PROJECT_ID, PLC, PLC_DESC, PLC_STATUS, PLC_DATE_OPN, PLC_DATE_CLSD)
   select distinct
          proj.proj_abbrv_cd,
          plc.bill_lab_cat_cd,
          plc.bill_lab_cat_desc,
          proj.active_fl,
          proj.proj_start_dt,
          proj.proj_end_dt
     from imar.deltek.PROJ proj
          inner join
          imar.deltek.TM_RT_ORDER tm_rt
          on
          (proj.PROJ_ID = tm_rt.PROJ_ID)
          AND
          (proj.COMPANY_ID = @DIV_22_COMPANY_ID)
          inner join
          imar.deltek.PROJ_LAB_CAT plc
          on
          (tm_rt.SRCE_PROJ_ID = plc.PROJ_ID)
          AND
          (plc.COMPANY_ID = @DIV_22_COMPANY_ID)
    where proj.proj_abbrv_cd <> ' '
--begin costpoint preprocessor plc validation does not work as expected
      and tm_rt.seq_no = 1
--end costpoint preprocessor plc validation does not work as expected

SELECT @rowcount = @@ROWCOUNT, @SQLServer_error_code = @@ERROR

-- Defect #310 begin
IF @rowcount = 0
   BEGIN
      -- No %1 records that %2 exist.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 207,
         @in_display_requested   = 1,
         @in_placeholder_value1  = 'Costpoint PROJ-TM_RT_ORDER-PROJ_LAB_CAT',
         @in_placeholder_value2  = 'meet PLC selection criteria',
         @in_calling_object_name = @SP_NAME
      RETURN(1)
   END


IF @SQLServer_error_code <> 0
   BEGIN
      -- display both IMAR's and SQL Server's error messages
      -- Attempt to insert a XX_R22_CP_PLC_CODE record failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = @IMAPS_error_code,
         @in_SQLServer_error_code = @SQLServer_error_code,
         @in_display_requested    = 1,
         @in_placeholder_value1   = 'insert',
         @in_placeholder_value2   = 'XX_R22_CP_PLC_CODE records',
         @in_calling_object_name  = @SP_NAME
      RETURN(1)
   END

-- Create a control record in IMARS staging table
insert into dbo.XX_R22_CP_PLC_CODE_COUNT(PLC_COUNT)
   select COUNT(1) from dbo.XX_R22_CP_PLC_CODE

SELECT @rowcount = @@ROWCOUNT, @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- display both IMAR's and SQL Server's error messages
      -- Attempt to INSERT a XX_R22_CP_PLC_CODE_COUNT record failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = @IMAPS_error_code,
         @in_SQLServer_error_code = @SQLServer_error_code,
         @in_display_requested    = 1,
         @in_placeholder_value1   = 'insert a',
         @in_placeholder_value2   = 'XX_R22_CP_PLC_CODE_COUNT record',
         @in_calling_object_name  = @SP_NAME
      RETURN(1)
   END

-- delete PLC and control tables in eTIME using dblink ETIME
IF (SELECT COUNT(1) FROM ETIME..INTERIM.CP_R22_PLC_CODE) > 0	
   BEGIN
      DELETE ETIME..INTERIM.CP_R22_PLC_CODE

      SELECT @rowcount = @@ROWCOUNT, @SQLServer_error_code = @@ERROR

      IF @SQLServer_error_code <> 0
         BEGIN
            -- display both IMAR's and SQL Server's error messages
            -- Attempt to delete ETIME..INTERIM.CP_R22_PLC_CODE records failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = @IMAPS_error_code,
               @in_SQLServer_error_code = @SQLServer_error_code,
               @in_display_requested    = 1,
               @in_placeholder_value1   = 'delete',
               @in_placeholder_value2   = 'ETIME..INTERIM.CP_R22_PLC_CODE records',
               @in_calling_object_name  = @SP_NAME
            RETURN(1)
         END
   END

/* DON'T BE MEAN AND DELETE PRASHANT'S COUNT TABLE

IF (SELECT COUNT(1) FROM ETIME..INTERIM.CP_R22_PLC_CODE_COUNT) > 0	
   BEGIN
      DELETE ETIME..INTERIM.CP_R22_PLC_CODE_COUNT

      SELECT @rowcount = @@ROWCOUNT, @SQLServer_error_code = @@ERROR

      IF @SQLServer_error_code <> 0
         BEGIN
            -- display both IMAR's and SQL Server's error messages
            -- Attempt to delete a ETIME..INTERIM.CP_R22_PLC_CODE_COUNT record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = @IMAPS_error_code,
               @in_SQLServer_error_code = @SQLServer_error_code,
               @in_display_requested    = 1,
               @in_placeholder_value1   = 'delete',
               @in_placeholder_value2   = 'ETIME..INTERIM.CP_R22_PLC_CODE_COUNT record',
               @in_calling_object_name  = @SP_NAME
            RETURN(1)
         END
   END
*/

-- Directly populate PLC table in eTime database
INSERT INTO ETIME..INTERIM.CP_R22_PLC_CODE
   (PROJECT_ID, PLC, PLC_DESC, PLC_STATUS, PLC_DATE_OPN, PLC_DATE_CLSD)
   SELECT PROJECT_ID, PLC, PLC_DESC, PLC_STATUS, PLC_DATE_OPN, PLC_DATE_CLSD
     FROM dbo.XX_R22_CP_PLC_CODE

SELECT @rowcount = @@ROWCOUNT, @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- display both IMAR's and SQL Server's error messages
      -- Attempt to insert ETIME..INTERIM.CP_R22_PLC_CODE records failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
	 @in_error_code           = @IMAPS_error_code,
	 @in_SQLServer_error_code = @SQLServer_error_code,
	 @in_display_requested    = 1,
	 @in_placeholder_value1   = 'insert',
	 @in_placeholder_value2   = 'ETIME..INTERIM.CP_R22_PLC_CODE records',
	 @in_calling_object_name  = @SP_NAME
      RETURN(1)
   END

-- Added for CR-7222
SELECT @ROWCOUNT= Count(1) from dbo.XX_R22_CP_PLC_CODE

-- Added count and date for CR-7222
INSERT into ETIME..INTERIM.CP_R22_PLC_CODE_COUNT(PLC_COUNT, create_date)
values (@ROWCOUNT, getdate())

SELECT @rowcount = @@ROWCOUNT, @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- display both IMAR's and SQL Server's error messages
      -- Attempt to insert a ETIME..INTERIM.CP_R22_PLC_CODE_COUNT record failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = @IMAPS_error_code,
         @in_SQLServer_error_code = @SQLServer_error_code,
         @in_display_requested    = 1,
         @in_placeholder_value1   = 'insert a',
         @in_placeholder_value2   = 'ETIME..INTERIM.CP_R22_PLC_CODE_COUNT record',
         @in_calling_object_name  = @SP_NAME
      RETURN(1)
   END

RETURN(0)

END












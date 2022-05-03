use imapsstg
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_INSERT_PLC_SP    Script Date: 01/09/2007 1:35:42 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_INSERT_PLC_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_INSERT_PLC_SP]
GO


CREATE PROCEDURE [dbo].[XX_INSERT_PLC_SP]
AS

/************************************************************************************************  
Name:       XX_INSERT_PLC_SP  
Authors:    JG, HVT, KM
Created:    08/29/2005  
Purpose:    Refresh PLC table in Staging and eTime db (using a dblink ETIME).
Parameters: None
Notes:

Defect 319  Improved SELECT statement using CASE statement to insure that the charge code value
            (PROJ.PROJ_ABBRV_CD) isn't blank, a data entry shortcoming in Costpoint.

Defect 1425 Send only those PLCs whose rates have actually been configured. Also, send more
            specific start and end date values for the PLCs.

CP600000326 04/21/2008 (BP&S Change Request No. CR1543)
            Costpoint multi-company fix (three instances).

CR5619		2012-11-26 Exclude DDOU projects from PLC Outbound interface tables

CR5550		2014-08-11 PLC Outbound Performance for DIV16 IMAPS   - KM
			Remove Linkder Server references
			Perhaps replace by SSIS package
*************************************************************************************************/  

DECLARE @SP_NAME              sysname,
        @ETIME_INTERFACE      varchar(50),
        @DIV_16_COMPANY_ID    varchar(10),
        @rowcount             integer,
        @SQLServer_error_code integer,
        @IMAPS_error_code     integer

BEGIN

-- set local constants
SELECT @SP_NAME = 'XX_INSERT_PLC_SP'
SET @ETIME_INTERFACE = 'ETIME'

-- initialize local variables
SET @IMAPS_error_code = 204

-- Truncate staging PLC tables in IMAPS database
TRUNCATE TABLE dbo.CP_PLC_CODE
TRUNCATE TABLE dbo.CP_PLC_CODE_COUNT

-- CP600000326_Begin
SELECT @DIV_16_COMPANY_ID= PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE INTERFACE_NAME_CD = @ETIME_INTERFACE   
   AND PARAMETER_NAME = 'COMPANY_ID'
-- CP600000326_End

/*
 * Populate the PLC staging table in IMAPS database.
 * If the value of PROJ.PROJ_ABBRV_CD is a single whitespace character, then use the value of
 * PROJ.Ln_PROJ_SEG_ID where n = 1, 2, 3, ... depending on the value of PROJ.LVL_NO where
 * PROJ_LAB_CAT.BILL_LAB_CAT_CD is assigned.
 * With this provision, a record is always returned with both a PLC and charge code values. 
 */

print ''
print 'start PLC load 1'
print convert(char(20), getdate(),120)

--PROJ_LAB_CAT ONLY PLCs
insert into dbo.CP_PLC_CODE
   (PROJECT_ID, PLC, PLC_DESC, PLC_STATUS, PLC_DATE_OPN, PLC_DATE_CLSD)
   select distinct
          proj.proj_abbrv_cd,
          plc.bill_lab_cat_cd,
          plc.bill_lab_cat_desc,
          proj.active_fl,
          proj.proj_start_dt,
          proj.proj_end_dt
     from IMAPS.Deltek.PROJ proj
          inner join
          IMAPS.Deltek.PROJ_LAB_CAT plc
          on
          (proj.proj_id = plc.proj_id)
-- CP600000326_Begin
          AND
          (proj.COMPANY_ID = plc.COMPANY_ID)
          AND
          (proj.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000326_End
    where plc.proj_id not in (select proj_id from IMAPS.Deltek.TM_RT_ORDER)
      and proj.proj_abbrv_cd <> ' '
	  --CR5619
	  and left(proj.proj_id,4)<>'DDOU'

print 'start PLC load 2 - real load'
print convert(char(20), getdate(),120)

--TM_RT_ORDER VALID PLCs
insert into dbo.CP_PLC_CODE
   (PROJECT_ID, PLC, PLC_DESC, PLC_STATUS, PLC_DATE_OPN, PLC_DATE_CLSD)
   select distinct
          proj.proj_abbrv_cd,
          plc.bill_lab_cat_cd,
          plc.bill_lab_cat_desc,
          proj.active_fl,
          proj.proj_start_dt,
          proj.proj_end_dt
     from IMAPS.Deltek.PROJ proj
          inner join
          IMAPS.Deltek.TM_RT_ORDER tm_rt
          on
          (proj.PROJ_ID = tm_rt.PROJ_ID)
-- CP600000326_Begin
          AND
          (proj.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000326_End
          inner join
          IMAPS.Deltek.PROJ_LAB_CAT plc
          on
          (tm_rt.SRCE_PROJ_ID = plc.PROJ_ID)
-- CP600000326_Begin
          AND
          (plc.COMPANY_ID = @DIV_16_COMPANY_ID)
-- CP600000326_End
    where proj.proj_abbrv_cd <> ' '
--begin costpoint preprocessor plc validation does not work as expected
      and tm_rt.seq_no = 1
--end costpoint preprocessor plc validation does not work as expected
	--CR5619
	  and left(proj.proj_id,4)<>'DDOU'

SELECT @rowcount = @@ROWCOUNT, @SQLServer_error_code = @@ERROR

print 'end PLC load to staging'
print convert(char(20), getdate(),120)


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
-- Defect #310 end

IF @SQLServer_error_code <> 0
   BEGIN
      -- display both IMAPS's and SQL Server's error messages
      -- Attempt to insert a CP_PLC_CODE record failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = @IMAPS_error_code,
         @in_SQLServer_error_code = @SQLServer_error_code,
         @in_display_requested    = 1,
         @in_placeholder_value1   = 'insert',
         @in_placeholder_value2   = 'CP_PLC_CODE records',
         @in_calling_object_name  = @SP_NAME
      RETURN(1)
   END


-- Create a control record in IMAPS staging table
insert into dbo.CP_PLC_CODE_COUNT(PLC_COUNT)
   select COUNT(1) from dbo.CP_PLC_CODE

SELECT @rowcount = @@ROWCOUNT, @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- display both IMAPS's and SQL Server's error messages
      -- Attempt to INSERT a CP_PLC_CODE_COUNT record failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = @IMAPS_error_code,
         @in_SQLServer_error_code = @SQLServer_error_code,
         @in_display_requested    = 1,
         @in_placeholder_value1   = 'insert a',
         @in_placeholder_value2   = 'CP_PLC_CODE_COUNT record',
         @in_calling_object_name  = @SP_NAME
      RETURN(1)
   END






--CR5550  begin
/*
CR5550		2014-08-11 PLC Outbound Performance for DIV16 IMAPS   - KM
			Remove Linkder Server references
			Perhaps replace by SSIS package


-- delete PLC and control tables in eTIME using dblink ETIME
IF (SELECT COUNT(1) FROM ETIME..INTERIM.CP_PLC_CODE) > 0	
   BEGIN
	
	  print ''
	  print 'start ETIME delete'
	  print convert(char(20), getdate(),120)

      DELETE ETIME..INTERIM.CP_PLC_CODE

      SELECT @rowcount = @@ROWCOUNT, @SQLServer_error_code = @@ERROR

	  print 'end ETIME delete'
	  print convert(char(20), getdate(),120)

      IF @SQLServer_error_code <> 0
         BEGIN
            -- display both IMAPS's and SQL Server's error messages
            -- Attempt to delete ETIME..INTERIM.CP_PLC_CODE records failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = @IMAPS_error_code,
               @in_SQLServer_error_code = @SQLServer_error_code,
               @in_display_requested    = 1,
               @in_placeholder_value1   = 'delete',
               @in_placeholder_value2   = 'ETIME..INTERIM.CP_PLC_CODE records',
               @in_calling_object_name  = @SP_NAME
            RETURN(1)
         END
   END

/* DON'T BE MEAN AND DELETE PRASHANT'S COUNT TABLE

IF (SELECT COUNT(1) FROM ETIME..INTERIM.CP_PLC_CODE_COUNT) > 0	
   BEGIN
      DELETE ETIME..INTERIM.CP_PLC_CODE_COUNT

      SELECT @rowcount = @@ROWCOUNT, @SQLServer_error_code = @@ERROR

      IF @SQLServer_error_code <> 0
         BEGIN
            -- display both IMAPS's and SQL Server's error messages
            -- Attempt to delete a ETIME..INTERIM.CP_PLC_CODE_COUNT record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = @IMAPS_error_code,
               @in_SQLServer_error_code = @SQLServer_error_code,
               @in_display_requested    = 1,
               @in_placeholder_value1   = 'delete',
               @in_placeholder_value2   = 'ETIME..INTERIM.CP_PLC_CODE_COUNT record',
               @in_calling_object_name  = @SP_NAME
            RETURN(1)
         END
   END
*/

print ''
print 'start ETIME insert'
print convert(char(20), getdate(),120)

-- Directly populate PLC table in eTime database
INSERT INTO ETIME..INTERIM.CP_PLC_CODE
   (PROJECT_ID, PLC, PLC_DESC, PLC_STATUS, PLC_DATE_OPN, PLC_DATE_CLSD)
   SELECT PROJECT_ID, PLC, PLC_DESC, PLC_STATUS, PLC_DATE_OPN, PLC_DATE_CLSD
     FROM dbo.CP_PLC_CODE

SELECT @rowcount = @@ROWCOUNT, @SQLServer_error_code = @@ERROR

print 'end ETIME insert'
print convert(char(20), getdate(),120)

IF @SQLServer_error_code <> 0
   BEGIN
      -- display both IMAPS's and SQL Server's error messages
      -- Attempt to insert ETIME..INTERIM.CP_PLC_CODE records failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
	 @in_error_code           = @IMAPS_error_code,
	 @in_SQLServer_error_code = @SQLServer_error_code,
	 @in_display_requested    = 1,
	 @in_placeholder_value1   = 'insert',
	 @in_placeholder_value2   = 'ETIME..INTERIM.CP_PLC_CODE records',
	 @in_calling_object_name  = @SP_NAME
      RETURN(1)
   END


print ''
print 'start ETIME control insert'
print convert(char(20), getdate(),120)

INSERT into ETIME..INTERIM.CP_PLC_CODE_COUNT(PLC_COUNT)
   select COUNT(1) from dbo.CP_PLC_CODE

SELECT @rowcount = @@ROWCOUNT, @SQLServer_error_code = @@ERROR

print 'end ETIME control insert'
print convert(char(20), getdate(),120)

IF @SQLServer_error_code <> 0
   BEGIN
      -- display both IMAPS's and SQL Server's error messages
      -- Attempt to insert a ETIME..INTERIM.CP_PLC_CODE_COUNT record failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = @IMAPS_error_code,
         @in_SQLServer_error_code = @SQLServer_error_code,
         @in_display_requested    = 1,
         @in_placeholder_value1   = 'insert a',
         @in_placeholder_value2   = 'ETIME..INTERIM.CP_PLC_CODE_COUNT record',
         @in_calling_object_name  = @SP_NAME
      RETURN(1)
   END


--CR5550  end
*/




RETURN(0)

END


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO



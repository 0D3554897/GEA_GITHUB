SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_RETRORATE_VALIDATE_USR_CMD_LINE_SP    Script Date: 09/12/2006 12:38:06 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_RETRORATE_VALIDATE_USR_CMD_LINE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_RETRORATE_VALIDATE_USR_CMD_LINE_SP]
GO




CREATE PROCEDURE dbo.XX_RETRORATE_VALIDATE_USR_CMD_LINE_SP
(
@in_year                char(4),
@in_process_date        char(10),
@out_STATUS_DESCRIPTION varchar(275) = NULL OUTPUT
)
AS
/****************************************************************************************************
Name:       XX_RETRORATE_VALIDATE_USR_CMD_LINE_SP
Author:     
Created:    01/06/2006
Purpose:    Validate the user's command line.
            Called by XX_RETRORATE_RUN_INTERFACE_SP.
Parameters: 
Result Set: None
Notes:      Examples of stored procedure call follow.

            Example 1: Run the interface in scheduled mode. This has the same effects as Example 2.
               EXEC XX_RETRORATE_RUN_INTERFACE_SP

            Example 2: Run the interface in scheduled mode. This has the same effects as Example 1.
               EXEC XX_RETRORATE_RUN_INTERFACE_SP
                  @in_year = null,
                  @in_process_date = null

            Example 3: Run the interface in manual mode.
               EXEC XX_RETRORATE_RUN_INTERFACE_SP
                  @in_year = '2005',
                  @in_process_date = '01-03-2006'
****************************************************************************************************/

DECLARE @SP_NAME   sysname,
        @row_count integer

-- set local constants
SET @SP_NAME = 'XX_RETRORATE_VALIDATE_USR_CMD_LINE_SP'

PRINT 'Validate user''s command line ...'

IF ISNUMERIC(@in_year) = 0
   BEGIN
      SET @out_STATUS_DESCRIPTION = 'USER ERROR: Invalid FY code value.'
      GOTO BL_ERROR_HANDLER
   END

IF ISDATE(@in_process_date) = 0
   BEGIN
      SET @out_STATUS_DESCRIPTION = 'USER ERROR: Invalid process date value.'
      GOTO BL_ERROR_HANDLER
   END

SET @out_STATUS_DESCRIPTION = 'USER ERROR: Invalid process date value. Process date cannot be 1, 15, 16, 31, last day of the month, or a Friday.'

IF DATEPART(d, @in_process_date) IN (1, 15, 16, 31)
   GOTO BL_ERROR_HANDLER

-- Process date cannot be a Friday
IF DATEPART(dw, @in_process_date) = 6
   GOTO BL_ERROR_HANDLER

-- Process date cannot be on the 30th of certain months
IF DATEPART(d, DATEADD(DAY, -1, DATEADD(MONTH, 1, (DATEADD(DAY, -DAY(@in_process_date) + 1, @in_process_date))))) = DATEPART(d, getdate())
   GOTO BL_ERROR_HANDLER

-- Process date may be a future date of not more than 4 days
IF CONVERT(datetime, @in_process_date) > GETDATE() + 4
   BEGIN
      SET @out_STATUS_DESCRIPTION = 'USER ERROR: Invalid process date value. Process date may be a future date of not more than 4 days.'
      GOTO BL_ERROR_HANDLER
   END

-- Check if the user-supplied process date is not in IMAPS.Deltek.SUB_PD
SELECT @row_count = COUNT(1)
  from IMAPS.Deltek.SUB_PD
 where SUB_PD_END_DT = @in_process_date

IF @row_count <> 0
   BEGIN
      SET @out_STATUS_DESCRIPTION = 'WARNING: Process date does not exist in IMAPS.Deltek.SUB_PD.'
      GOTO BL_ERROR_HANDLER
   END

/*
 * Check if there are multiple rows exist in the XX_GENL_LAB_CAT table with RATE_DELTA = 0.
 * Process only if there are single rows per GLC code exists in GLC table with blank rate_delta.
 */
-- 02/23/2006 Change begin
SET @row_count = 0
-- 02/23/2006 Change end

select distinct @row_count = COUNT(GENL_LAB_CAT_CD)
  from dbo.XX_GENL_LAB_CAT
 where RATE_DELTA is null
 group by GENL_LAB_CAT_CD
having COUNT(GENL_LAB_CAT_CD) > 1

IF @row_count <> 0
   BEGIN
      SET @out_STATUS_DESCRIPTION = 'WARNING: There are multiple rows per GLC code exist in GLC table with no rate change.'
      GOTO BL_ERROR_HANDLER
   END

RETURN(0)

BL_ERROR_HANDLER:

SET @out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION + ' [' + @SP_NAME + ']'
PRINT @out_STATUS_DESCRIPTION
RETURN(1)





GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


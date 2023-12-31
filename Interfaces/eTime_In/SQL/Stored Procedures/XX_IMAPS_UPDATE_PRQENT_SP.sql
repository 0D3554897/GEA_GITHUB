SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_IMAPS_UPDATE_PRQENT_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   drop procedure [dbo].[XX_IMAPS_UPDATE_PRQENT_SP]
GO


CREATE PROCEDURE dbo.XX_IMAPS_UPDATE_PRQENT_SP
(
@in_Proc_Que_ID         varchar(12),
@in_Proc_ID             varchar(12),
@in_PROC_SERVER_ID      varchar(12),
@out_STATUS_DESCRIPTION varchar(255) = NULL OUTPUT
)
AS

/************************************************************************************************  
Name:       XX_IMAPS_UPDATE_PRQENT_SP  
Author:     JG, HVT
Created:    06/24/2005
Purpose:    Provide information to the Costpoint application to invoke the timesheet preprocessor.

Parameters: @in_Proc_Que_ID is deltek.PROCESS_QUEUE.PROC_QUEUE_ID set up specifically for eTime interface
            @in_Proc_ID is deltek.PROCESS_HDR.PROCESS_ID set up specifically for eTime interface
Result Set: None  
Version:    1.0
Notes:      For version control, see interface eTime_In in ClearCase.

Called by:  XX_CERIS_READY_CP_RUN_SP
            XX_FIWLR_INITIATE_PREPROCESSORS_SP
            XX_PCLAIM_START_AP_PREPROCESSOR_SP
            XX_RETRORATE_READY_CP_RUN_SP
            XX_RUN_ETIME_INTERFACE

03/13/2006  Force-assign a value to IMAPS.Deltek.PROCESS_QUE_ENTRY.PROC_SERVER_ID to facilitate
            other programs to function based on the existence of this value.

CP600000284 04/15/2008 (BP&S Change Request No. CR1543)
            Multi-company fix (one instance).
            
            
2014-02-18  Costpoint 7 changes
			Process Server replaced by Job Server
*************************************************************************************************/  

DECLARE @SP_NAME                  sysname,
        @DIV_16_COMPANY_ID        varchar(10),
        @PROC_STATUS_PENDING      varchar(10),
        @row_count                integer,
        @SQLServer_error_code     integer,
        @error_msg_placeholder1   sysname,
        @error_msg_placeholder2   sysname

-- set local constants
SELECT @SP_NAME = 'XX_IMAPS_UPDATE_PRQENT_SP'
SELECT @PROC_STATUS_PENDING = 'PENDING'

-- CP600000284_Begin

select @DIV_16_COMPANY_ID = PARAMETER_VALUE
  from dbo.XX_PROCESSING_PARAMETERS
 where INTERFACE_NAME_CD = @in_Proc_ID
   and PARAMETER_NAME = 'COMPANY_ID'

SET @row_count = @@ROWCOUNT

IF @row_count = 0 OR LEN(RTRIM(LTRIM(@DIV_16_COMPANY_ID))) = 0
   BEGIN
      SET @SQLServer_error_code = NULL
      SET @error_msg_placeholder1 = 'retrieve COMPANY_ID processing parameter'
      SET @error_msg_placeholder2 = 'for ' + @in_Proc_ID + ' interface'

      -- Attempt to %1 %2 failed.
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = 204,
         @in_SQLServer_error_code = @SQLServer_error_code,
         @in_display_requested    = 1,
         @in_placeholder_value1   = @error_msg_placeholder1,
         @in_placeholder_value2   = @error_msg_placeholder2,
         @in_calling_object_name  = @SP_NAME,
         @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

      RETURN(1) -- return error status and exit
   END

-- CP600000284_End

-- 03/13/2006 HVT_Change_Begin

-- force-assign a value to IMAPS.Deltek.PROCESS_QUE_ENTRY.PROC_SERVER_ID
IF @in_PROC_SERVER_ID IS NULL or LEN(RTRIM(LTRIM(@in_PROC_SERVER_ID))) = 0
   SET @in_PROC_SERVER_ID = @in_Proc_ID

-- 03/13/2006 HVT_Change_End


--2014-02-18  Costpoint 7 changes   BEGIN
UPDATE imaps.deltek.job_schedule
   SET SCH_START_DTT    = GETDATE(),
       MODIFIED_BY      = SUSER_SNAME(),
       TIME_STAMP       = GETDATE()
 WHERE JOB_QUEUE_ID = @in_Proc_Que_ID
   AND JOB_ID    = @in_Proc_ID
   AND COMPANY_ID    = @DIV_16_COMPANY_ID
--2014-02-18  Costpoint 7 changes   END


SELECT @row_count = @@ROWCOUNT, @SQLServer_error_code = @@ERROR

-- Added by JG on 09/16/05 
-- Found an error when trying to test Tatiana's PCLAIM change for correction records
-- to be posted in current period

IF (@SQLServer_error_code <> 0 or @row_count = 0)
   BEGIN
      IF @SQLServer_error_code = 0
         SET @SQLServer_error_code = NULL

      -- Attempt to update Costpoint process queue failed (see DELTEK.PROCESS_QUE_ENTRY).
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code           = 603,
         @in_SQLServer_error_code = @SQLServer_error_code,
         @in_display_requested    = 1,
         @in_calling_object_name  = @SP_NAME,
         @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

      RETURN(1) -- return error status and exit
   END

RETURN(0)

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


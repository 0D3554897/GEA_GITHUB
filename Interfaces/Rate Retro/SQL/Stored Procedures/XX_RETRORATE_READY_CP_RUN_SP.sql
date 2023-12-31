use imapsstg

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_RETRORATE_READY_CP_RUN_SP    Script Date: 01/25/2006 3:23:45 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_RETRORATE_READY_CP_RUN_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   drop procedure [dbo].[XX_RETRORATE_READY_CP_RUN_SP]
GO


CREATE PROCEDURE dbo.XX_RETRORATE_READY_CP_RUN_SP
(
-- Defect_592_Begin
@in_STATUS_RECORD_NUM      integer,
-- Defect_592_End
@out_SQLServer_error_code  integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION    varchar(255) = NULL OUTPUT
)
AS
BEGIN
/****************************************************************************************************
Name:       XX_RETRORATE_READY_CP_RUN_SP
Author:     HVT
Created:    12/20/2005
Purpose:    For the Costpoint timesheet preprocessor use, this sp creates the input file and directly
            update the process or job status and scheduled start date and time. Once these steps are
            done, the Costpoint Process Server application can be run to invoke the Costpoint timesheet
            preprocessor.
            On the Costpoint side, specific setup data -- Deltek.PROCESS_HDR.PROCESS_ID and 
            Deltek.PROCESS_QUEUE.PROC_QUEUE_ID -- must exist in order for the process to complete.
            Called by XX_RETRORATE_RUN_INTERFACE_SP.
Parameters: 
Result Set: None
Notes:

Defect 592  Update the XX_IMAPS_INT_STATUS record with processing statistics.
            Update the IMAPS.Deltek.PROCESS_QUE_ENTRY record to prepare for execution of the
            preprocessor in a manner consistent with other interfaces ETIME, FIWLR and PCLAIM.
****************************************************************************************************/

DECLARE @SP_NAME                        sysname,
        @ETIME_INTERFACE_NAME           varchar(50),
        @INTERFACE_STATUS_COMPLETED     varchar(20),
        @PROC_STATUS_PENDING            varchar(10),
        @IMAPS_DB_NAME                  sysname,
        @IMAPS_SCHEMA_OWNER             sysname,
        @IN_PREP_TABLE_NAME             sysname,
        @IN_PREP_FORMAT_FILENAME        sysname,
        @OUT_TS_PREP_FILENAME           sysname,
        @OUT_CP_ERROR_FILENAME          sysname,
        --@IN_USER_PASSWORD               sysname, --CR3728
        @IN_RETRORATE_CP_PROC_ID        sysname,
        @IN_RETRORATE_CP_PROC_QUEUE_ID  sysname,
        @ret_code                       integer,
        @row_count                      integer

-- set local constants
SET @SP_NAME = 'XX_RETRORATE_READY_CP_RUN_SP'
SET @ETIME_INTERFACE_NAME = 'RETRORATE'
SET @INTERFACE_STATUS_COMPLETED = 'COMPLETED'
SET @PROC_STATUS_PENDING = 'PENDING'
SET @IMAPS_DB_NAME = db_name()

-- Do not go further if the preprocessor staging XX_RATE_RETRO_TS_PREP_TEMP is empty.
select @row_count = COUNT(1) from dbo.XX_RATE_RETRO_TS_PREP_TEMP

IF @row_count = 0
   BEGIN
      SET @out_STATUS_DESCRIPTION = 'WARNING: The preprocessor staging table XX_RATE_RETRO_TS_PREP_TEMP is empty. No bcp run required.'
      PRINT @out_STATUS_DESCRIPTION
      RETURN(1)
   END

-- retrieve necessary parameter data to run this stored procedure
EXEC @ret_code = dbo.XX_RETRORATE_GET_PROCESSING_PARAMS_SP
   @out_IMAPS_SCHEMA_OWNER            = @IMAPS_SCHEMA_OWNER            OUTPUT,
   --@out_IN_USER_PASSWORD              = @IN_USER_PASSWORD              OUTPUT, --CR3728
   @out_IN_TS_PREP_FORMAT_FILENAME    = @IN_PREP_FORMAT_FILENAME       OUTPUT,
   @out_IN_TS_PREP_TABLENAME          = @IN_PREP_TABLE_NAME            OUTPUT,
   @out_OUT_TS_PREP_FILENAME          = @OUT_TS_PREP_FILENAME          OUTPUT,
   @out_OUT_CP_TS_PREP_ERROR_FILENAME = @OUT_CP_ERROR_FILENAME         OUTPUT,
   @out_IN_RETRORATE_CP_PROC_ID       = @IN_RETRORATE_CP_PROC_ID       OUTPUT,
   @out_IN_RETRORATE_CP_PROC_QUEUE_ID = @IN_RETRORATE_CP_PROC_QUEUE_ID OUTPUT

IF @ret_code <> 0 -- the called sp returned an error status
   RETURN(1)

PRINT 'Create Costpoint timesheet preprocessor flat file via bcp ...'

-- produce a flat file to be used as input by the Costpoint timesheet preprocessor
EXEC @ret_code = dbo.XX_EXEC_SHELL_CMD_OSUSER  --CR3728
   @in_IMAPS_db_name       = @IMAPS_DB_NAME,
   @in_IMAPS_table_owner   = @IMAPS_SCHEMA_OWNER,
   @in_source_table        = @IN_PREP_TABLE_NAME,
   @in_format_file         = @IN_PREP_FORMAT_FILENAME,
   @in_output_file         = @OUT_TS_PREP_FILENAME,
   --@in_usr_password        = @IN_USER_PASSWORD, --CR3728
   @out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION OUTPUT

IF @ret_code <> 0 -- the called sp returned an error status
   RETURN(1)

/*
 * Reset the Costpoint timesheet preprocessor job to be run at current date and time
 * pending invocation of the Costpoint Process Server application. This step is an attempt
 * to move the Retro Cost Rate Change interface job to the front of the job queue.
 */
PRINT 'Update Costpoint preprocessor process queue entry data ...'

-- Defect_592_Begin

-- supply Costpoint the necessary info to run its timesheet preprocessor
EXEC @ret_code = dbo.XX_IMAPS_UPDATE_PRQENT_SP
   @in_Proc_Que_ID         = @IN_RETRORATE_CP_PROC_QUEUE_ID,
   @in_Proc_ID             = @IN_RETRORATE_CP_PROC_ID,
   @in_PROC_SERVER_ID      = null,
   @out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION OUTPUT

IF @ret_code <> 0 -- the called sp returned an error status
   RETURN(1)

-- Defect_592_End

RETURN(0)


END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


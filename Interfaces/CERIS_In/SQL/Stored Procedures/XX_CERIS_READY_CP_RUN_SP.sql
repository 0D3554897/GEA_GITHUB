
/****** Object:  StoredProcedure [dbo].[XX_CERIS_READY_CP_RUN_SP]    Script Date: 02/25/2008 08:39:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE ID = object_id(N'[dbo].[XX_CERIS_READY_CP_RUN_SP]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[XX_CERIS_READY_CP_RUN_SP]
GO


CREATE PROCEDURE [dbo].[XX_CERIS_READY_CP_RUN_SP]
(
@in_STATUS_RECORD_NUM     integer,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS

/************************************************************************************************  
Name:       XX_CERIS_READY_CP_RUN_SP
Author:     KM
Created:    03/2006
Purpose:    Process the retroactive timesheet data.
            Called by XX_CERIS_RUN_INTERFACE_SP.

CP600000201 02-14-2008 (Reference Service Request No. DR1435) - Veera Veeramachanane
            CERIS interface has been modified to kickoff preprocessor if run for an empty timesheet file.

CP600001216 05/13/2011 (FSST Service Request No. CR3735)
            Eliminate use of shared ID (e.g., in bcp call)
*************************************************************************************************/

BEGIN

PRINT 'Process Stage CERIS6 - BCP retroactive timesheet data to file (conditional) ...'


DECLARE @SP_NAME                 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
	@ret_code		 integer,
	@output			 varchar(255)

-- set local constants
SET @SP_NAME = 'XX_CERIS_READY_CP_RUN_SP'



-- initialize local variables
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'validate that'
SET @error_msg_placeholder2 = 'CERIS retro timesheets have net of 0 hours'




-- initialize local variables
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'obtain'
SET @error_msg_placeholder2 = 'CERIS parameters'


--1. DECLARE/OBTAIN BCP parameters
DECLARE @IMAPS_DB_NAME sysname,
	@IMAPS_SCHEMA_OWNER sysname,
	@IN_USER_PASSWORD sysname,
	@RETRO_TS_FORMAT_FILE sysname,
	@RETRO_TS_PREP_FILE sysname,
	@IN_PROC_QUE_ID sysname,
	@IN_PROC_ID sysname,
	@IN_PROC_SERVER_ID sysname

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 79 : XX_CERIS_READY_CP_RUN_SP.sql '
 
SELECT 	@IMAPS_DB_NAME = PARAMETER_VALUE
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'IMAPS_DB_NAME'
AND	INTERFACE_NAME_CD = 'CERIS'

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 87 : XX_CERIS_READY_CP_RUN_SP.sql '
 
SELECT 	@IMAPS_SCHEMA_OWNER = PARAMETER_VALUE
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'IMAPS_SCHEMA_OWNER'
AND	INTERFACE_NAME_CD = 'CERIS'

-- CR3735_Begin
/*
SELECT 	@IN_USER_PASSWORD = PARAMETER_VALUE
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'IN_USER_PASSWORD'
AND	INTERFACE_NAME_CD = 'CERIS'
*/
-- CR3735_End

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 104 : XX_CERIS_READY_CP_RUN_SP.sql '
 
SELECT 	@RETRO_TS_FORMAT_FILE = PARAMETER_VALUE
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'RETRO_TS_FORMAT_FILE'
AND	INTERFACE_NAME_CD = 'CERIS'

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 112 : XX_CERIS_READY_CP_RUN_SP.sql '
 
SELECT 	@RETRO_TS_PREP_FILE = PARAMETER_VALUE
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'RETRO_TS_PREP_FILE'
AND	INTERFACE_NAME_CD = 'CERIS'

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 120 : XX_CERIS_READY_CP_RUN_SP.sql '
 
SELECT 	@IN_PROC_QUE_ID = PARAMETER_VALUE
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'IN_PROC_QUE_ID'
AND	INTERFACE_NAME_CD = 'CERIS'

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 128 : XX_CERIS_READY_CP_RUN_SP.sql '
 
SELECT 	@IN_PROC_ID = PARAMETER_VALUE
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'IN_PROC_ID'
AND	INTERFACE_NAME_CD = 'CERIS'

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 136 : XX_CERIS_READY_CP_RUN_SP.sql '
 
SELECT 	@IN_PROC_SERVER_ID = PARAMETER_VALUE
FROM 	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'IN_PROC_SERVER_ID'
AND	INTERFACE_NAME_CD = 'CERIS'

IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER



-- initialize local variables
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'BCP'
SET @error_msg_placeholder2 = 'XX_CERIS_RETRO_TS_PREP'

--2. BCP timesheet file
-- CR3735_Begin
EXEC @ret_code = dbo.XX_EXEC_SHELL_CMD_OSUSER
   @in_IMAPS_db_name       = @IMAPS_DB_NAME,
   @in_IMAPS_table_owner   = @IMAPS_SCHEMA_OWNER,
   @in_source_table        = 'XX_CERIS_RETRO_TS_PREP',
   @in_format_file         = @RETRO_TS_FORMAT_FILE,
   @in_output_file         = @RETRO_TS_PREP_FILE,
-- @in_usr_password        = @IN_USER_PASSWORD,
   @out_STATUS_DESCRIPTION = @output OUTPUT
-- CR3735_End

IF @@ERROR <> 0 GOTO BL_ERROR_HANDLER
IF @ret_code <> 0 GOTO BL_ERROR_HANDLER


-- initialize local variables
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'Kickoff CERIS Retro Timesheet'
SET @error_msg_placeholder2 = 'Costpoint Process'


--3.  Kickoff Process Server
IF 0 <> (SELECT COUNT(1) FROM dbo.XX_CERIS_RETRO_TS_PREP)
BEGIN
	exec @ret_code = dbo.xx_imaps_update_prqent_sp

		@in_Proc_Que_ID = @IN_PROC_QUE_ID,
		@in_Proc_ID = @IN_PROC_ID,
		@in_PROC_SERVER_ID = @IN_PROC_SERVER_ID, --find out what this is
		@out_STATUS_DESCRIPTION = @output OUTPUT
	
	print @output
	
	IF @ret_code <> 0 GOTO BL_ERROR_HANDLER
END
--	Start modified by Veera on 02/14/2008 to run the CERIS timesheet file for empty file Defect: CP600000201
ELSE
BEGIN
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'Rename empty CERIS Timesheet File'
	SET @error_msg_placeholder2 = 'From .TXT to .ZZZ'

	DECLARE @CMD varchar(500)
	SET @CMD = 'COPY ' + @RETRO_TS_PREP_FILE + ' ' + REPLACE(@RETRO_TS_PREP_FILE, '.TXT', '.ZZZ')
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD

	IF @ret_code <> 0 GOTO BL_ERROR_HANDLER	

	SET @CMD = 'DEL ' + @RETRO_TS_PREP_FILE
	EXEC @ret_code = master.dbo.xp_cmdshell @CMD

	IF @ret_code <> 0 GOTO BL_ERROR_HANDLER

END
--	End Defect: CP600000201

RETURN(0)

BL_ERROR_HANDLER:

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 214 : XX_CERIS_READY_CP_RUN_SP.sql '
 
EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_number,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @@ERROR,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)

END













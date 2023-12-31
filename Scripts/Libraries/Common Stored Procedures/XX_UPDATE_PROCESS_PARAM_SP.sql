IF OBJECT_ID('dbo.XX_UPDATE_PROCESS_PARAM_SP') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.XX_UPDATE_PROCESS_PARAM_SP
    IF OBJECT_ID('dbo.XX_UPDATE_PROCESS_PARAM_SP') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.XX_UPDATE_PROCESS_PARAM_SP >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.XX_UPDATE_PROCESS_PARAM_SP >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER ON
go

CREATE PROCEDURE [dbo].[XX_UPDATE_PROCESS_PARAM_SP]
( 
@in_CMD_PATH		sysname,
@in_SEARCH_PATH 	sysname,
@in_RESULT_PATH		sysname,
@in_FORMAT_PATH		sysname,
@in_SOURCE_PARM		sysname,
@in_INTERFACE_NAME	sysname,
@out_ERROR_MESSAGE	varchar(250) OUTPUT
)
AS
/************************************************************************************************  
Name:       	XX_UPDATE_PROCESS_PARAM_SP
Author:     	KM
Created:    	08/2005  
Purpose:    	TO UPDATE XX_PROCESSING_PARAMETER WHERE PARAMETER_NAME = IN_TS_SOURCE_FILENAME
Prerequisites: 	none 

Parameters: 
	Input: 	@in_CMD_PATH, @in_SEARCH_PATH, @in_RESULT_PATH
	Output: none   

Version: 	1.0
Notes:      	

CR3617          03/25/2011 - Implement new shared ID business rule
************************************************************************************************/  
BEGIN

DECLARE
	@FILE_NAME 		sysname,
	@PARAMETER_VALUE 	sysname,
	@CMD 			varchar(300),
	@ret_code 		integer,
	@STATUS_DESCRIPTION	varchar(250)

-- Store PARAMETER_VALUE IN FILE
SET @CMD = @in_CMD_PATH + ' ' + @in_SEARCH_PATH + ' ' + @in_RESULT_PATH
PRINT 'CMD: ' + @CMD
EXEC @ret_code = master.dbo.xp_cmdshell @CMD

IF @ret_code <> 0
BEGIN
	set @OUT_Error_Message = @CMD +' execution Failed!'
	RETURN(1)
END


-- WRITE PARAMETER NAME FROM FILE TO TABLE
-- USING BCP
TRUNCATE TABLE dbo.XX_PARAM_TEMP

-- CR3617_Begin
/*
-- initialize local variables
--CHANGE KM 12/14/05
DECLARE @lv_usr_password sysname

SELECT @lv_usr_password = PARAMETER_VALUE 
FROM dbo.XX_PROCESSING_PARAMETERS
WHERE INTERFACE_NAME_CD = @in_INTERFACE_NAME  -- Parameter Added 08/18/08 Tejas (Old value= ETIME)
AND PARAMETER_NAME = 'IN_USER_PASSWORD'
--CHANGE KM 12/14/05
*/
-- CR3617_End

EXEC @ret_code = dbo.XX_EXEC_SHELL_CMD_INSERT_OSUSER -- Modified for CR-3617 03/25/2011
   @in_IMAPS_db_name       = 'IMAPSStg',
   @in_IMAPS_table_owner   = 'dbo',
   @in_dest_table          = 'XX_PARAM_TEMP',
   @in_format_file         = @in_FORMAT_PATH,
   @in_input_file          = @in_RESULT_PATH,
-- @in_usr_password        = @lv_usr_password ,   -- Modified for CR-3617 03/25/2011
   @out_STATUS_DESCRIPTION = @STATUS_DESCRIPTION OUTPUT

IF @ret_code <> 0
BEGIN
	set @OUT_Error_Message = @STATUS_DESCRIPTION
	RETURN(1)
END

SELECT @FILE_NAME = THE_FILE_NAME FROM dbo.XX_PARAM_TEMP
SET @FILE_NAME = @in_SEARCH_PATH + @FILE_NAME

PRINT 'File_Name: ' + @FILE_NAME +';'

-- Update XX_PROCESSING_PARAMETERS entry
UPDATE dbo.XX_PROCESSING_PARAMETERS
   SET PARAMETER_VALUE = @FILE_NAME,
-- CR3617_Begin
       MODIFIED_BY = SUSER_SNAME(),
       MODIFIED_DATE = GETDATE()
-- CR3617_End
 WHERE PARAMETER_NAME = @IN_SOURCE_PARM
   AND INTERFACE_NAME_CD = @in_INTERFACE_NAME

IF @@ERROR <> 0 -- failure
   BEGIN
      set @OUT_Error_Message = @STATUS_DESCRIPTION
      RETURN(1)
   END

RETURN(0)
END
go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_UPDATE_PROCESS_PARAM_SP') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.XX_UPDATE_PROCESS_PARAM_SP >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.XX_UPDATE_PROCESS_PARAM_SP >>>'
go

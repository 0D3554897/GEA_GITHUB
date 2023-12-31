use imapsstg

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PCLAIM_FILE_BULK_INSERT_SP ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_PCLAIM_FILE_BULK_INSERT_SP ]
GO

CREATE PROCEDURE [dbo].[XX_PCLAIM_FILE_BULK_INSERT_SP ]  (@in_status_record_num int, @out_SystemError int = NULL OUTPUT,
 @out_STATUS_DESCRIPTION varchar(275) =NULL OUTPUT) AS

DECLARE
@IMAPS_DB_NAME        sysname,
@IMAPS_SCHEMA_OWNER    sysname,
@Data_File_Name           varchar(100),
@Frmt_File_Name        varchar(100),
@Frmt_Ftr_File_Name	varchar(100),
@ret_code int,
@lv_usr_password     sysname

SELECT @Data_File_Name   = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS
	 WHERE INTERFACE_NAME_CD = 'PCLAIM' AND PARAMETER_NAME = 'IN_SOURCE_FILENAME'
SELECT @Frmt_File_Name   = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'PCLAIM' AND PARAMETER_NAME = 'IN_DETAIL_FORMAT_FILENAME'
SELECT @Frmt_Ftr_File_Name   = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'PCLAIM' AND PARAMETER_NAME = 'IN_FOOTER_FORMAT_FILENAME'
/*--CR3548
SELECT @lv_usr_password   = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'PCLAIM' AND PARAMETER_NAME = 'IN_USER_PASSWORD'
*/
SELECT @IMAPS_DB_NAME   = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'PCLAIM' AND PARAMETER_NAME = 'IMAPS_DATABASE_NAME'
SELECT @IMAPS_SCHEMA_OWNER = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS 
	WHERE INTERFACE_NAME_CD = 'PCLAIM' AND PARAMETER_NAME = 'IMAPS_SCHEMA_OWNER'


/************************************************************************************************  
Name:       	XX_PCLAIM_FILE_BULK_INSERT_SP  
Author:     	Tatiana Perova
Created:    	08/29/2005  
Purpose:  Part of  Step 1 of PCLAIM interface   created as separate procedure out of step transaction, because of call to command
		prompt that could not be rolled back. It will not affect restart after failed processing since all previous database data
		in tables that got updated will be truncated on each run
	File  @Data_File_Name imported to 
	    	i) XX_PCLAIM_IN_TMP -- Detail Data -- with format file  @Frmt_File_Name
	    	ii) XX_PCLAIM_FTR_IN_TMP -- Footer Data.  -- with format file @Frmt_Ftr_File_Name

                Called by XX_PCLAIM_RUN_INTERFACE_SP

Parameters: 
	Input: @in_STATUS_RECORD_NUM -- identifier of current interface run
	Output:  @out_STATUS_DESCRIPTION --  generated error message
		@out_SystemError  -- system error code
Result Set: 	None  
Version: 	1.0
Notes:
**************************************************************************************************/  

-- clear all staging data from previous runs
TRUNCATE TABLE dbo.XX_PCLAIM_IN
TRUNCATE TABLE dbo.XX_PCLAIM_IN_TMP
TRUNCATE TABLE dbo.XX_PCLAIM_FTR_IN_TMP

-- Insert records into table XX_PCLAIM_IN_TMP
--CR3548
EXEC @ret_code = dbo.XX_EXEC_SHELL_CMD_INSERT_OSUSER
   @in_IMAPS_db_name       = @IMAPS_DB_NAME,
   @in_IMAPS_table_owner   = @IMAPS_SCHEMA_OWNER,
   @in_dest_table          = 'XX_PCLAIM_IN_TMP',
   @in_format_file         = @Frmt_File_Name,
   @in_input_file          = @Data_File_Name ,
   @out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION OUTPUT


IF @ret_code <> 0 -- failure: previous execution step fails
      RETURN(1)

-- Insert records into table XX_PCLAIM_FTR_IN_TMP
--CR3548
EXEC @ret_code = dbo.XX_EXEC_SHELL_CMD_INSERT_OSUSER
   @in_IMAPS_db_name       = @IMAPS_DB_NAME,
   @in_IMAPS_table_owner   = @IMAPS_SCHEMA_OWNER,
   @in_dest_table          = 'XX_PCLAIM_FTR_IN_TMP',
   @in_format_file         = @Frmt_Ftr_File_Name,
   @in_input_file          = @Data_File_Name ,
   @in_usr_password        = @lv_usr_password,
   @out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION OUTPUT

IF @ret_code <> 0 -- failure: previous execution step fails
      RETURN(1)
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


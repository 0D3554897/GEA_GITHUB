SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_7KEYS_ARCHIVE_MOVE_OUTPUT_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   DROP PROCEDURE [dbo].[XX_7KEYS_ARCHIVE_MOVE_OUTPUT_SP]
GO

CREATE PROCEDURE dbo.XX_7KEYS_ARCHIVE_MOVE_OUTPUT_SP
(
@in_STATUS_RECORD_NUM      integer,
@out_SQLServer_error_code  integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION    varchar(255) = NULL OUTPUT
)
AS
/****************************************************************************************************
Name:       XX_7KEYS_ARCHIVE_MOVE_OUTPUT_SP
Author:     HVT
Created:    11/08/2005
Purpose:    Rename and archive the output file. Put a copy of the output file in the receiving FTP
            directory or "Out Box." Clean up. Record job statistics.
            Called by XX_7KEYS_RUN_INTERFACE_SP, XX_7KEYS_CHK_OUTPUT_FILES_SP.
Parameters: 
Result Set: None
Notes:

02/09/2006: Add code to support FTP function.

03/14/2006: Get rid of the previous output file in the Out Box file directory. This ensures that there
            is only one file, the latest/most recent output file is in the Out Box file directory.
            Save the file name of the output file in XX_IMAPS_INT_STATUS.INTERFACE_FILE_NAME
            to facilitate its deletion in the next interface run.
            IMPORTANT: Deletion of two or more files using DOS command incurs the confirmation
            question Are you sure (Y/N)?, an undesirable event, whereas deletion of singular file
            does not.

Defect 647  03/29/2006 - In deleting the previous final output file from the Out Box file directory,
            provide for the special case in which no XX_IMAPS_INT_STATUS records exist for this
            interface (i.e., the interface's inaugural run).
****************************************************************************************************/

DECLARE @SP_NAME                    sysname,
        @7KEYS_INTERFACE_NAME       varchar(50),
        @INTERFACE_STATUS_COMPLETED varchar(20),
        @hdr_output_filename        sysname,     -- including full directory path
        @dtl_output_filename        sysname,     -- including full directory path
        @final_output_filename      sysname,
        @FTP_server                 sysname,
        @receiving_ftp_dir          sysname,     -- so-called "Outbox" for a specific outbound interface
        @output_archival_dir        sysname,     -- full directory path
        @start_pos                  integer,
        @filename_tmp               sysname,
        @updated_filepath           sysname,
        @total_input_records        integer,
        @SQLServer_error_code       integer,
        @IMAPS_error_code           integer,
        @error_msg_placeholder1     sysname,
        @error_msg_placeholder2     sysname,
        @row_count                  integer,
        @ret_code                   integer,
        @tmp_dir_path               sysname,
        @INTERFACE_FILE_NAME        varchar(100)

-- set local constants
SET @SP_NAME = 'XX_7KEYS_ARCHIVE_MOVE_OUTPUT_SP'
SET @7KEYS_INTERFACE_NAME = '7KEYS/PSP'
SET @INTERFACE_STATUS_COMPLETED = 'COMPLETED'

-- initialize local variables
SET @IMAPS_error_code = 204 -- Attempt to %1 %2 failed.

PRINT 'Process Stage 7KEYS3 - Move output file to FTP directory and archive output data ...'

PRINT 'Rename the output file to include the current datetime stamp ...'

-- retrieve necessary parameter data to rename the output file to its final name
EXEC @ret_code = dbo.XX_7KEYS_GET_PROCESSING_PARAMS_SP
   @out_OUT_HEADER_FILENAME         = @hdr_output_filename   OUTPUT,
   @out_OUT_DETAIL_FILENAME         = @dtl_output_filename   OUTPUT,
   @out_OUT_FINAL_FILENAME_PREFIX   = @final_output_filename OUTPUT,
   @out_OUT_ARCHIVAL_DIRECTORY      = @output_archival_dir   OUTPUT,
   @out_OUT_FTP_SERVER              = @FTP_server            OUTPUT,
   @out_OUT_FTP_RECEIVING_DIRECTORY = @receiving_FTP_dir     OUTPUT

/*
 * Rename the latest output file using the current datetime stamp.
 * The resulting file name format is 7keysoutyyyymmddhhmmss.txt.
 */
EXEC @ret_code = dbo.XX_MANAGE_FILE_SP
   @in_shell_cmd      = 'RENAME',   @in_arg_1          = @hdr_output_filename,
   @in_arg_2          = @final_output_filename OUTPUT,
   @in_RENAME_special = 'Y'

IF @ret_code <> 0
   BEGIN
      SET @error_msg_placeholder1 = 'rename output file'
      SET @error_msg_placeholder2 = 'to include datetime stamp'
      GOTO BL_ERROR_HANDLER
   END

-- get the starting position of the output header file's filename in the full directory path
SET @start_pos = CHARINDEX('7keysout', @hdr_output_filename, 1)

-- extract only the output header file's filename without the full directory path
SET @filename_tmp = SUBSTRING(@hdr_output_filename, @start_pos, (DATALENGTH(@hdr_output_filename) - @start_pos) + 1)

-- replace the output header file's filename with its new counterpart
SET @updated_filepath = REPLACE(@hdr_output_filename, @filename_tmp, @final_output_filename)

-- 03/14/2006 HVT_Change_Begin

-- construct the receiving location string (complete with server name and directory path)
SET @receiving_FTP_dir = '\\' + @FTP_server + '\' + @receiving_FTP_dir + '\'

PRINT 'Delete the previous output file in the Out Box file directory ...'

-- Defect 647 Begin

/*
 * Retrieve the name of the previous final output file in the Out Box file directory.
 * Special cases: The previous final output file may not be found or applicable here if (1) this
 * interface is run for the very first time, (2) column XX_IMAPS_INT_STATUS.INTERFACE_FILE_NAME
 * is indeed missing a valid value due to some unknown event.
 */

SELECT @row_count = COUNT(1)
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE INTERFACE_NAME = @7KEYS_INTERFACE_NAME

IF @row_count > 1
   BEGIN
      SELECT @INTERFACE_FILE_NAME = INTERFACE_FILE_NAME
        FROM dbo.XX_IMAPS_INT_STATUS
       WHERE INTERFACE_NAME = @7KEYS_INTERFACE_NAME
         AND CREATED_DATE   = (SELECT MAX(s.CREATED_DATE) 
                                 FROM dbo.XX_IMAPS_INT_STATUS s
                                WHERE s.INTERFACE_NAME = @7KEYS_INTERFACE_NAME
                                  AND s.STATUS_CODE = @INTERFACE_STATUS_COMPLETED)

      -- This condition should not occur (XX_IMAPS_INT_STATUS.INTERFACE_FILE_NAME is not nullable)
      IF @INTERFACE_FILE_NAME IS NULL -- no row affected
         BEGIN
            SET @IMAPS_error_code = 213 -- Missing %1 from %2.
            SET @error_msg_placeholder1 = 'name of output file from the previous completed interface run (INTERFACE_FILE_NAME)'
            SET @error_msg_placeholder2 = 'the XX_IMAPS_INT_STATUS record'
            GOTO BL_ERROR_HANDLER
         END
      ELSE
         BEGIN
            SET @tmp_dir_path = @receiving_FTP_dir + @INTERFACE_FILE_NAME
            EXEC @ret_code = dbo.XX_MANAGE_FILE_SP
               @in_shell_cmd = 'DEL',
               @in_arg_1     = @tmp_dir_path,
               @in_arg_2     = null

            IF @ret_code <> 0
               BEGIN
                  SET @error_msg_placeholder1 = 'delete'
                  SET @error_msg_placeholder2 = 'the previous output file in the Out Box file directory'
                  GOTO BL_ERROR_HANDLER
                END
         END
   END

-- Defect 647 End

PRINT 'Put a copy of the latest output file in the 7Keys/PSP Out Box ...'

EXEC @ret_code = dbo.XX_MANAGE_FILE_SP
   @in_shell_cmd = 'COPY',
   @in_arg_1     = @updated_filepath,
   @in_arg_2     = @receiving_ftp_dir

IF @ret_code <> 0
   BEGIN
      -- USER_ERROR: Attempt to copy output file to 7KEYS/PSP Out Box directory failed. [XX_7KEYS_ARCHIVE_MOVE_OUTPUT_SP]
      SET @error_msg_placeholder1 = 'copy output file'
      SET @error_msg_placeholder2 = 'to 7KEYS/PSP Out Box directory'
      GOTO BL_ERROR_HANDLER
   END

-- 03/14/2006 HVT_Change_End

PRINT 'Put a copy of the latest output file in the Archive directory ...'

-- archive output file 
EXEC @ret_code = dbo.XX_MANAGE_FILE_SP
   @in_shell_cmd = 'COPY',
   @in_arg_1     = @updated_filepath,
   @in_arg_2     = @output_archival_dir

IF @ret_code <> 0
   BEGIN
      SET @error_msg_placeholder1 = 'copy output file'
      SET @error_msg_placeholder2 = 'to 7KEYS/PSP archival directory'
      GOTO BL_ERROR_HANDLER
   END

PRINT 'Clean up temporary output files generated in control point 7KEYS2 ...'

-- Defect 647 Begin
-- get the staging file directory path
SET @start_pos = (CHARINDEX('7keysout', @hdr_output_filename, 1)) - 1
SET @filename_tmp = SUBSTRING(@hdr_output_filename, 1, @start_pos) + '7keysout*.txt'

EXEC @ret_code = dbo.XX_MANAGE_FILE_SP
   @in_shell_cmd = 'DEL',
   @in_arg_1     = @filename_tmp,
   @in_arg_2     = null

IF @ret_code <> 0
   BEGIN
      SET @error_msg_placeholder1 = 'delete'
      SET @error_msg_placeholder2 = 'temporary output files'
      GOTO BL_ERROR_HANDLER
   END
-- Defect 647 End

PRINT 'Record job statistics ...'

SELECT @total_input_records = COUNT(1)
  FROM dbo.XX_7KEYS_OUT_DETAIL_TEMP

-- 03/14/2006 HVT_Change_Begin

UPDATE dbo.XX_IMAPS_INT_STATUS
   SET INTERFACE_FILE_NAME = @final_output_filename,
       RECORD_COUNT_INITIAL = @total_input_records,
       RECORD_COUNT_SUCCESS = @total_input_records,
       RECORD_COUNT_ERROR = 0,
       MODIFIED_BY = SUSER_SNAME(),
       MODIFIED_DATE = GETDATE()
 WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

-- 03/14/2006 HVT_Change_End

SELECT @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to update a XX_IMAPS_INT_STATUS record failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'a XX_IMAPS_INT_STATUS record'
      GOTO BL_ERROR_HANDLER
   END

RETURN(0)

BL_ERROR_HANDLER:

EXEC dbo.XX_ERROR_MSG_DETAIL -- database name must be explicitly provided
   @in_error_code           = @IMAPS_error_code,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @out_SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


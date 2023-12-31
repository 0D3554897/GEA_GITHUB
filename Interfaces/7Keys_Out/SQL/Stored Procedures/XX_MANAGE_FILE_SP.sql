SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_MANAGE_FILE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_MANAGE_FILE_SP]
GO


CREATE PROCEDURE dbo.XX_MANAGE_FILE_SP
(
@in_shell_cmd      varchar(8),
@in_arg_1          sysname,
@in_arg_2          sysname = NULL OUTPUT,
@in_RENAME_special char(1) = NULL OUTPUT
)
AS

/****************************************************************************************************
Name:       XX_MANAGE_FILE_SP
Author:     HVT
Created:    11/09/2005
Purpose:    Execute user-specified shell command via the SQL Server extended stored procedure xp_cmdshell.
            Shell commands are limited to six basic DOS file handling commands.
            The RENAME "special" adds to a source file name (complete with directory path, file name
            and extension) the datetime stamp of the format yyyymmddhhmiss. User must supply the
            "prefix" of the new file name.
            The TYPE command is not used to display the contents of a file.
            The calling stored procedure shall provide the error handling upon receiving a bad
            return status.
Parameters: @in_arg_2 serves as both input and output parameters
Result Set: None
Notes:      

03/29/2006  Add DIR feature.

            Examples of calls follow.

            -- Append the (entire contents) of the detail file to the header file
            EXEC @ret_code = dbo.XX_MANAGE_FILE_SP
               @in_shell_cmd = 'TYPE',
               @in_arg_1 = @dtl_output_filename,
               @in_arg_2 = @hdr_output_filename

            -- produce final result '\\9.48.228.52\development\HVT\7keysout20051111152859.txt'
            EXEC @ret_code = dbo.XX_MANAGE_FILE_SP
               @in_shell_cmd = 'RENAME',
               @in_arg_1 = '\\9.48.228.52\development\HVT\7keysout*.txt',
               @in_arg_2 = '7keysout.txt',
               @in_RENAME_special = 'Y'

            declare @test_var sysname
            set @test_var = 'REN_result.txt'

            exec dbo.XX_MANAGE_FILE_SP
               @in_shell_cmd = 'RENAME',
               @in_arg_1 = '\\9.48.228.52\development\HVT\test.txt',
               @in_arg_2 = @test_var OUTPUT,
               @in_RENAME_special = 'Y'

            EXEC @ret_code = dbo.XX_MANAGE_FILE_SP
               @in_shell_cmd = 'MOVE',
               @in_arg_1 = @src_dir,
               @in_arg_2 = @dst_dir

            EXEC @ret_code = dbo.XX_MANAGE_FILE_SP
               @in_shell_cmd = 'DEL',
               @in_arg_1 = @OUT_CP_ERROR_FILENAME

            -- verify existence of a singular file
            EXEC @ret_code = dbo.XX_MANAGE_FILE_SP
               @in_shell_cmd = 'DIR',
               @in_arg_1 = @src_dir

****************************************************************************************************/

DECLARE @SP_NAME                sysname,
        @error_type             tinyint,
        @cmd                    varchar(255),
        @new_filename	        sysname,
        @today                  datetime,
        @month                  integer,
        @day                    integer,
        @year                   integer,
        @hour                   integer,
        @minute                 integer,
        @second	                integer,
        @dot_pos                integer,  -- the relative position of the search char
        @ret_code               integer,
        @IMAPS_error_code       integer,
        @error_msg_placeholder1 sysname,
        @error_msg_placeholder2 sysname

-- set local constants
SET @SP_NAME = 'XX_MANAGE_FILE_SP'

-- initialize local variables
SET @error_msg_placeholder1 = null
SET @error_msg_placeholder2 = null
SET @IMAPS_error_code = 100 -- Missing required input parameter(s)

-- Validate the stored procedure call

IF @in_shell_cmd IS NULL OR @in_arg_1 IS NULL
   GOTO BL_ERROR_HANDLER

SET @cmd = upper(ltrim(rtrim(@in_shell_cmd)))
   
IF upper(ltrim(rtrim(@cmd))) NOT IN ('DIR', 'COPY', 'DEL', 'ERASE', 'MOVE', 'RENAME', 'TYPE')
   BEGIN
      SET @IMAPS_error_code = 211 -- %1 is not supported.
      SET @error_msg_placeholder1 = 'Shell command ' + ltrim(rtrim(@in_shell_cmd))
      GOTO BL_ERROR_HANDLER
   END

IF @cmd in ('COPY', 'MOVE', 'RENAME', 'TYPE')
   IF @in_arg_1 IS NULL OR @in_arg_2 IS NULL
      GOTO BL_ERROR_HANDLER

IF @cmd in ('DIR', 'DEL', 'ERASE')
   IF @in_arg_1 IS NULL
      GOTO BL_ERROR_HANDLER

-- Construct the command string

IF @in_shell_cmd in ('DIR', 'DEL', 'ERASE')
   SET @cmd = @cmd + ' ' + rtrim(@in_arg_1)

IF @in_shell_cmd in ('COPY', 'MOVE')
   SET @cmd = @cmd + ' ' + rtrim(@in_arg_1) + ' ' + rtrim(@in_arg_2)

-- special RENAME treatment: the new file name shall include the datetime stamp
IF @in_shell_cmd = 'RENAME' 
   IF (@in_RENAME_special IS NOT NULL AND @in_RENAME_special = 'Y')
      BEGIN
         SET @today = GETDATE()
         SET @month = DATEPART(mm, @today)
         SET @day = DATEPART(dd, @today)
         SET @year = DATEPART(yyyy, @today)
         SET @hour = DATEPART(hh, @today)
         SET @minute = DATEPART(mi, @today)
         SET @second = DATEPART(ss, @today)
         SET @dot_pos = PATINDEX('%.%', @in_arg_2)

         -- format of new file name: usr-supplied substr + yyyymmddhhmiss.ext
         SET @new_filename = substring(@in_arg_2, 1, @dot_pos - 1)
                             + CONVERT(varchar, @year)
                             + CONVERT(varchar, @month)
                             + CONVERT(varchar, @day)
                             + CONVERT(varchar, @hour)
                             + CONVERT(varchar, @minute)
                             + CONVERT(varchar, @second)
                             + '.'
                             + substring(@in_arg_2, @dot_pos + 1, datalength(@in_arg_2))

         SET @cmd = @cmd + ' ' + rtrim(@in_arg_1) + ' ' + @new_filename

         -- return the renamed file's name as output parameter value
         SET @in_arg_2 = @new_filename
      END
   ELSE
      SET @cmd = @cmd + ' ' + rtrim(@in_arg_1) + ' ' + rtrim(@in_arg_2)

/*
 * The following appends one file to another.
 * The file to be appended must be specified with full directory path.
 */
IF @in_shell_cmd = 'TYPE'
   SET @cmd = @cmd + ' ' + rtrim(@in_arg_1) + ' >> ' + rtrim(@in_arg_2)

PRINT '@cmd = ' + @cmd

EXEC @ret_code = master.dbo.xp_cmdshell @cmd

IF @ret_code <> 0
   RETURN(1)

RETURN(0)

BL_ERROR_HANDLER:

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_code,
   @in_display_requested    = 1,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME

RETURN(1)

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


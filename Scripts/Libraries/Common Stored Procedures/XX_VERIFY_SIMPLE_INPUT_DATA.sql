SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_VERIFY_SIMPLE_INPUT_DATA]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_VERIFY_SIMPLE_INPUT_DATA]
GO


CREATE PROCEDURE dbo.XX_VERIFY_SIMPLE_INPUT_DATA
(
@in_chk_dataset     varchar(30),
@in_chk_data_type   varchar(30),
@in_chk_value       varchar(12),
@out_chk_result     integer OUTPUT
)
AS

/**************************************************************************************************
Name:       XX_VERIFY_SIMPLE_INPUT_DATA
Author:     HVT
Created:    08/17/2005
Purpose:    Retrieve the EMPL_ID, if any.
Parameters: 
Return:     1=Valid, 0=Invalid
Notes:      
***************************************************************************************************/

DECLARE @table_name         sysname,
        @SQLString          NVARCHAR(500),
        @lv_param_str       varchar(50),
        @lv_retval          integer,
        @lv_rowcount        integer,
        @lv_error_code      integer,
        @SP_NAME            sysname

SET @SP_NAME = 'XX_VERIFY_SIMPLE_INPUT_DATA'

IF @in_chk_dataset IS NULL OR @in_chk_data_type IS NULL OR @in_chk_value IS NULL
   BEGIN
      SET @lv_error_code = 100 -- Missing required input parameter(s)
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = @lv_error_code,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
      SET @out_chk_result = 0
      RETURN(1) -- terminate execution and exit
   END

SET @table_name =
   CASE @in_chk_data_type
      WHEN 'EMPL_ID' THEN 'EMPL'
END

IF UPPER(@in_chk_dataset) = 'DELTEK'
   BEGIN
      SET @table_name = 'IMAPS.deltek.' + @table_name

      -- build column list
      SET @SQLString = N'SELECT DISTINCT ' + @in_chk_data_type + CHAR(13)

      -- build FROM clause
      SET @SQLString = @SQLString + N'FROM ' + @table_name + CHAR(13)

      -- build WHERE clause
      SET @SQLString = @SQLString + N'WHERE ' + @in_chk_data_type + ' = ' + '''' + @in_chk_value + ''''

      EXECUTE sp_executesql @SQLString

      SELECT @lv_error_code = @@ERROR, @lv_rowcount = @@ROWCOUNT

      -- examine the result of the execution of dynamic SQL statement
      IF @lv_error_code <> 0
         BEGIN
            SET @lv_param_str = 'a ' + @table_name + ' record'
            -- Attempt to select a IMAPS.deltek.EMPL record failed.
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code           = 204,
               @in_display_requested    = 1,
               @in_SQLServer_error_code = @lv_error_code,
               @in_placeholder_value1   = 'SELECT',
               @in_placeholder_value2   = @lv_param_str,
               @in_calling_object_name  = @SP_NAME
           SET @out_chk_result = 0
           RETURN(1)
         END

      IF @lv_rowcount = 0
         SET @out_chk_result = 0 -- submitted value is not valid
      ELSE
         SET @out_chk_result = 1 -- submitted value is valid
   END

ELSE IF UPPER(@in_chk_dataset) = 'IMAPS'

   BEGIN
      EXEC @lv_retval = dbo.XX_GET_LOOKUP_DATA
         @usr_domain_const = @in_chk_data_type,
         @usr_app_code     = @in_chk_value

      IF @lv_retval = 1
         SET @out_chk_result = 0 -- submitted value is not valid
      ELSE
         SET @out_chk_result = 1 -- submitted value is valid
   END

RETURN (0)

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


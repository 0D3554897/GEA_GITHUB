SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_RENAME_FILE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_RENAME_FILE_SP]
GO




-- this function calls the xp command RENAME
-- renames a file to a new name that has the date appended to the begining
-- of the new name
-- DROP PROCEDURE dbo.XX_RENAME_FILE_SP
-- 


CREATE PROCEDURE dbo.XX_RENAME_FILE_SP
(@in_SRC_PATH_FILE sysname, @in_NEW_FILE_NAME sysname)  
AS  
BEGIN 

DECLARE  
@CMD		varchar(400),
@ret_code 	integer,
@today		datetime,
@month		integer,
@day		integer,
@year		integer

IF @in_SRC_PATH_FILE IS NULL 
BEGIN
	RETURN(1)
END

IF @in_NEW_FILE_NAME IS NULL
BEGIN
	RETURN(1)
END


SELECT @today = GETDATE()
SELECt @month = DATEPART(mm, @today)
SELECT @day =  DATEPART(dd, @today)
SELECT @year =  DATEPART(yyyy, @today)

SET @CMD = 'RENAME "' + @in_SRC_PATH_FILE + '" "' 
		+ CONVERT(varchar, @month) + '_'
		+ CONVERT(varchar, @day) + '_'
		+ CONVERT(varchar, @year) + '_'		
 		+  @in_NEW_FILE_NAME + '"'
SELECT @CMD
EXEC @ret_code = master.dbo.xp_cmdshell @CMD

RETURN @ret_code

END



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


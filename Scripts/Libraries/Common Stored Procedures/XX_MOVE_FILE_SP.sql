SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_MOVE_FILE_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_MOVE_FILE_SP]
GO



-- this function calls the xp command MOVE
-- DROP FUNCTION dbo.XX_MOVE_FILE_FN
CREATE PROCEDURE dbo.XX_MOVE_FILE_SP
(@in_SRC sysname, @in_DST sysname)  
AS  
BEGIN 

DECLARE  
@CMD		varchar(300),
@ret_code 	integer

IF @in_SRC IS NULL 
BEGIN
	RETURN(1)
END

IF @in_DST IS NULL
BEGIN
	RETURN(1)
END

SET @CMD = 'MOVE "' + @in_SRC + '" "' + @in_DST + '"'

EXEC @ret_code = master.dbo.xp_cmdshell @CMD

RETURN @ret_code

END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


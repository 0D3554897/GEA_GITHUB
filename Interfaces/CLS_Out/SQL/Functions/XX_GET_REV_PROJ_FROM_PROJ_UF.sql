USE [IMAPSStg]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_GET_OEM_REV_VALUES_BY_DIV_UF]    Script Date: 9/16/2022 10:00:42 AM ******/
DROP FUNCTION [dbo].[XX_GET_OEM_REV_VALUES_BY_DIV_UF]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_GET_OEM_REV_VALUES_BY_DIV_UF]    Script Date: 9/16/2022 10:00:42 AM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE FUNCTION [dbo].[XX_GET_OEM_REV_VALUES_BY_DIV_UF](@in_proj_id varchar(50))  
RETURNS varchar(50) AS  
BEGIN
/************************************************************************************************  
Name:       	[XX_GET_OEM_REV_VALUES_BY_DIV_UF]
Author:     	GA
Created:    	09/2022 

FSSTIMAPS-73 - Get Revenue Project from any Project

Usage: SELECT XX_GET_OEM_REV_VALUES_BY_DIV_UF('ABCD.1234.ABCD.1234.ABCD') or
SELECT XX_GET_OEM_REV_VALUES_BY_DIV_UF(IMAPS_PROJ_ID) FROM TABLE

Returns: Revenue Level project. If none, returns project.

************************************************************************************************/

DECLARE @REV_PROJ varchar(50)

SELECT @REV_PROJ=PROJ_ID from IMAPS.Deltek.PROJ_REV_SETUP WHERE CHARINDEX(PROJ_ID, @in_proj_id)>0

RETURN isnull(@REV_PROJ,@in_proj_id)

END


GO



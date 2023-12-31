SET QUOTED_IDENTIFIER ON
go
SET ANSI_NULLS ON
go


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_GET_UTIL_TYP_CD_UF]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[XX_GET_UTIL_TYP_CD_UF]
GO


CREATE FUNCTION [dbo].[XX_GET_UTIL_TYP_CD_UF] 
(@in_HR_TYPE varchar(2))
RETURNS Char(3) AS  
BEGIN 
DECLARE  
@returnvalue char(3)

/************************************************************************************************  
Name:       XX_GET_UTIL_TYP_CD_UF
Author:     	KM
Created:    	10/15/2007  
Purpose:  Conversion function called by Utilization Interface

Parameters: 
	Input: @in_HR_TYPE -- identifier of current interface run

	Returnt:  UTIL_TYP_CD for XX_BMS_IW
Version: 	1.0
Notes:
**************************************************************************************************/ 

if @in_HR_TYPE is NULL 
	BEGIN RETURN NULL END

else if (@in_HR_TYPE = 'AD' OR
		 @in_HR_TYPE = 'HD' OR
		 @in_HR_TYPE = 'OD' OR
		 @in_HR_TYPE = 'OU' OR
		 @in_HR_TYPE = 'SD' OR
		 @in_HR_TYPE = 'VD' 
		)
  BEGIN
	SET @returnvalue = 'TAW'
  END

else if ( @in_HR_TYPE='CE') 
BEGIN
	SET @returnvalue = 'EDU'
END

else if ( @in_HR_TYPE='IP') 
BEGIN
	SET @returnvalue = 'MIN'
END

else if (@in_HR_TYPE = 'B')
BEGIN
	SET @returnvalue = 'BIL'
END

else if (@in_HR_TYPE = 'BP')
BEGIN
	SET @returnvalue = 'PIL'
END

else if( @in_HR_TYPE = 'BE' OR
	@in_HR_TYPE = 'OA' )
BEGIN
	SET @returnvalue = 'NPR'
END

else if( @in_HR_TYPE = 'CR' )
BEGIN
	SET @returnvalue = 'RIG'
END
else
BEGIN
	SET @returnvalue = NULL
END


RETURN  @returnvalue
END
go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_GET_UTIL_TYP_CD_UF') IS NOT NULL
    PRINT '<<< CREATED FUNCTION dbo.XX_GET_UTIL_TYP_CD_UF >>>'
ELSE
    PRINT '<<< FAILED CREATING FUNCTION dbo.XX_GET_UTIL_TYP_CD_UF >>>'
go

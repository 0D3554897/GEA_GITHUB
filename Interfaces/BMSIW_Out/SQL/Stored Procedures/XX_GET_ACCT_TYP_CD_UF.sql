SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_GET_ACCT_TYP_CD_UF]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[XX_GET_ACCT_TYP_CD_UF]
GO



CREATE FUNCTION [dbo].[XX_GET_ACCT_TYP_CD_UF] 
(@in_HR_TYPE varchar(2))
RETURNS Char(1) AS  
BEGIN 
DECLARE  
@returnvalue char(1)

/************************************************************************************************  
Name:       XX_GET_ACCT_TYP_CD_UF
Author:     	KM
Created:    	11/01/2005  
Modified: 10/08/2007 - Modified IP hour types.
Purpose:  Conversion function called by BMS_IW Interface


Parameters: 
	Input: @in_HR_TYPE -- identifier of current interface run

	Returnt:  ACCT_TYP_CD for XX_BMS_IW
Version: 	1.0
Notes:
**************************************************************************************************/ 

if @in_HR_TYPE is NULL 
	BEGIN RETURN NULL END

else if (@in_HR_TYPE = 'AD' OR
	 @in_HR_TYPE = 'HD' OR
	 --@in_HR_TYPE = 'IP' OR -- Removed as IP should get MIN utiliz. if A then its TAW. CR-996
	 @in_HR_TYPE = 'SD' OR
	 @in_HR_TYPE = 'OD' OR -- Added as OD should get TAW Utiliz.
	 @in_HR_TYPE = 'OU' OR -- Added as OU should get TAW Utiliz.	 
	 @in_HR_TYPE = 'VD')
BEGIN
	SET @returnvalue = 'A'
END

else if( --@in_HR_TYPE = 'OD' OR -- Added as OD should get TAW Utiliz.
	 --@in_HR_TYPE = 'OA' OR -- Removed as OA will get NPR
	 --@in_HR_TYPE = 'OU' OR -- Added as OU should get TAW Utiliz.	 
	 @in_HR_TYPE='IP') -- Removed as IP should get MIN utiliz. if A then its TAW. CR-996
BEGIN
	SET @returnvalue = 'I'
END

else if (@in_HR_TYPE = 'B')
BEGIN
	SET @returnvalue = 'C'
END

else if (@in_HR_TYPE = 'BP')
BEGIN
	SET @returnvalue = 'O'
END

else if( @in_HR_TYPE = 'BE' OR
	@in_HR_TYPE = 'OA' )
BEGIN
	SET @returnvalue = 'N'
END

else if( @in_HR_TYPE = 'CE' )
BEGIN
	SET @returnvalue = 'E'
END

else if( @in_HR_TYPE = 'CR' )
BEGIN
	SET @returnvalue = 'I'
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
IF OBJECT_ID('dbo.XX_GET_ACCT_TYP_CD_UF') IS NOT NULL
    PRINT '<<< CREATED FUNCTION dbo.XX_GET_ACCT_TYP_CD_UF >>>'
ELSE
    PRINT '<<< FAILED CREATING FUNCTION dbo.XX_GET_ACCT_TYP_CD_UF >>>'
go

USE [IMAPSStg]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_GET_OEM_EXP_VALUES_BY_DIV_UF]    Script Date: 9/16/2022 11:14:10 AM ******/
DROP FUNCTION [dbo].[XX_GET_OEM_EXP_VALUES_BY_DIV_UF]
GO

/****** Object:  UserDefinedFunction [dbo].[XX_GET_OEM_EXP_VALUES_BY_DIV_UF]    Script Date: 9/16/2022 11:14:10 AM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[XX_GET_OEM_EXP_VALUES_BY_DIV_UF](@in_imaps_acct varchar(8), @in_div varchar(2), @in_which varchar(3))  
RETURNS varchar(50) AS  
BEGIN
/************************************************************************************************  
Name:       	[XX_GET_OEM_EXP_VALUES_BY_DIV_UF]
Author:     	GA
Created:    	09/2022 

FSSTIMAPS-73 - Get Major, Minor or Product_ID

Usage: SELECT IMAPSSTG.DBO.XX_GET_OEM_EXP_VALUES_BY_DIV_UF(IMAPS_ACCT, DIV, WHICH VALUE YOU WANT)
SUPPLY ACCT, DIV AND PARAM 3. VALID 3rd PARAM VALUES ARE MAJ, MIN or PID

Returns: OEM Major, Minor or Product ID, as requested

************************************************************************************************/

-- make sure everything comes in

DECLARE @PARAM_CHECK varchar(50), @RET_VAL varchar(50), @MAJ varchar(3),  @MIN varchar(4), @PID varchar(10)

SET @PARAM_CHECK = @in_imaps_acct + @in_div + @in_which

IF @PARAM_CHECK IS NULL
	RETURN CAST('MISSING PARAMETER ERROR IN XX_GET_OEM_EXP_VALUES_BY_DIV_UF - CHECK JOB LOG' AS INT)


-- populate the values
SELECT @MAJ=M.CLS_MAJOR, @MIN=M.CLS_MINOR, @PID=M.PRODUCT_ID
FROM IMAPSSTG.DBO.XX_CLS_DOWN_HW_SW_MAP M
JOIN IMAPSSTG.DBO.XX_CLS_DOWN_THIS_MONTH_YTD Y
	ON M.IMAPS_ACCT = Y.IMAPS_ACCT
	AND M.DIVISION = @in_div
WHERE Y.IMAPS_ACCT IN (SELECT IMAPS_ACCT FROM IMAPSSTG.DBO.XX_CLS_DOWN_HW_SW_MAP WHERE CLASS = 'EXP')
	AND Y.IMAPS_ACCT = @in_imaps_acct
	AND CLASS = 'EXP'

IF @@ERROR <> 0
	RETURN CAST('PARAMETERS SUPPLIED: ' +@in_imaps_acct + ', ' +@in_div + ', ' + @in_which + ' CAUSE QUERY ERROR - CHECK JOB LOG' AS INT);

-- check results for null
SET @PARAM_CHECK = @MAJ + @MIN + @PID
IF @PARAM_CHECK IS NULL
	RETURN CAST('PARAMETERS SUPPLIED: ' +@in_imaps_acct + ', ' +@in_div + ', ' + @in_which + ' NOT FOUND IN TABLE IMAPSSTG.DBO.XX_CLS_DOWN_HW_SW_MAP - CHECK JOB LOG' AS INT);


IF @in_which = 'MAJ'
  SET @RET_VAL = @MAJ

IF @in_which = 'MIN'
  SET @RET_VAL = @MIN

IF @in_which = 'PID'
  SET @RET_VAL = @PID

RETURN @RET_VAL

END


GO



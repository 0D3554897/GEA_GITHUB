USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_CLS_DOWN_CREATE_LOG_RECORD_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 

 




CREATE PROCEDURE dbo.[XX_CLS_DOWN_CREATE_LOG_RECORD_SP](
@in_FY char(4),
@in_MO char(2),
@in_STATUS_RECORD_NUM    integer, 
@out_SystemError int = NULL OUTPUT, 
@out_STATUS_DESCRIPTION varchar(275) =NULL OUTPUT) AS

BEGIN
/************************************************************************************************  
Name:       	XX_CLS_DOWN_CREATE_LOG_RECORD_SP
Author:     	Tatiana Perova
Created:    	11/2005  
Purpose:    	Validates request parameters, creates log record for CLS Down interface.
		Interface will use FY/Month validated/created in this procedure as a period for
		which data should be collected.

Prerequisites: 	none 
 

Version: 	1.0

************************************************************************************************/  
DECLARE
@FY char(4),
@MO char(2),
@on_demand_fl smallint,
@return_code int,
@current_month int,
@SP_NAME char(30),
@LastFileNum int,
@LastVoucherNum int,
@NumberOfRecords int

SET @return_code = 0
SET @SP_NAME = 'XX_CLS_DOWN_CREATE_LOG_RECORD_SP'

	IF (@in_FY is NULL and @in_MO is NOT NULL) OR
	   (@in_FY is NOT NULL and @in_MO is NULL) OR
	   (@in_FY is NOT NULL and @in_MO is NOT NULL AND
	   (CAST(@in_MO AS int) <0 OR CAST(@in_MO AS int)>12)) 
		BEGIN 
		-- Accounting FY and Month should be correctly entered for CLS run on demand

		SET @return_code = 550
		GOTO ErrorProcessing
		END

	IF @in_FY is NOT NULL and @in_MO is NOT NULL 
			BEGIN
			SET @on_demand_fl = 1
			SET @FY = @in_FY
			SET @MO = @in_MO
			END
	ELSE  -- this branch is for  NULL @in_FY and @in_MO
		BEGIN
		SET @FY = YEAR(GETDATE())
		SET @current_month = MONTH(GETDATE())
		SET @MO = @current_month - 1
		IF @MO = '0' 
			BEGIN
			SET @FY = CAST(@FY AS INT) -1 
			SET @MO = '12'
			END
		IF LEN(@MO) = 1
			BEGIN
			SET @MO = '0' + @MO
			END
	
 	END
-- get New File seq and Voucher seq
SELECT @LastFileNum = MAX(FILE_SEQ_NUM),@LastVoucherNum =  MAX(CAST(VOUCHER_NUM AS int))
FROM dbo.XX_CLS_DOWN_LOG

IF @LastFileNum is NULL  BEGIN SET @LastFileNum = 1 END
ELSE BEGIN SET @LastFileNum = @LastFileNum + 1 END

IF @LastVoucherNum is NULL  BEGIN SET @LastVoucherNum = 1 END
ELSE BEGIN SET @LastVoucherNum =@LastVoucherNum + 1 END

		
INSERT INTO dbo.XX_CLS_DOWN_LOG (STATUS_RECORD_NUM , FILE_SEQ_NUM, VOUCHER_NUM,
	 FY_SENT, MONTH_SENT, LEDGER_ENTRY_DATE, ON_DEMAND)
VALUES 
	(  @in_STATUS_RECORD_NUM, @LastFileNum, @LastVoucherNum, @FY, @MO, CURRENT_TIMESTAMP, @on_demand_fl )

SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT
IF @out_SystemError > 0 
	BEGIN 
	SET @return_code = 1
	GOTO ErrorProcessing 
	END

RETURN 0
ErrorProcessing:
RETURN @return_code
END



 

 

GO
 


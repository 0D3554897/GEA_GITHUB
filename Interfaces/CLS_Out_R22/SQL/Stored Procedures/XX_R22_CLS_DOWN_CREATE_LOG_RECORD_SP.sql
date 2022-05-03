USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CLS_DOWN_CREATE_LOG_RECORD_SP]    Script Date: 5/6/2020 5:10:11 PM ******/
DROP PROCEDURE [dbo].[XX_R22_CLS_DOWN_CREATE_LOG_RECORD_SP]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CLS_DOWN_CREATE_LOG_RECORD_SP]    Script Date: 5/6/2020 5:10:11 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[XX_R22_CLS_DOWN_CREATE_LOG_RECORD_SP]
(
@in_FY                  char(4),
@in_MO                  char(2),
@in_STATUS_RECORD_NUM   integer,
@out_SystemError        integer      = NULL OUTPUT, 
@out_STATUS_DESCRIPTION varchar(275) = NULL OUTPUT
)
AS

/***************************************************************************************************  
Name:       XX_R22_CLS_DOWN_CREATE_LOG_RECORD_SP
Created by: HVT
Created:    10/27/2008  
Purpose:    Validate user-supplied input parameter values. Create log record for the interface run.
            Interface will use the FY and accounting month validated/created in this procedure as
            a period for which data should be collected. The XX_R22_CLS_DOWN_LOG record is created
            right before the commencing of the first control point.

            Called by XX_R22_CLS_DOWN_RUN_INTERFACE_SP.
            Adapted from XX_CLS_DOWN_CREATE_LOG_RECORD_SP.

Notes:

CP600000465 10/27/2008 Reference BP&S Service Request CR1656
            Leverage the existing CLS Down interface for Division 16 to develop an interface
            between Costpoint and CLS to meet Division 22 (aka Research) requirements.

****************************************************************************************************/  

BEGIN

DECLARE @SP_NAME                 sysname,
        @FY_CD                   char(4),
        @PD_NO                   char(2),
        @on_demand_fl            smallint,
        @current_month           integer,
        @LastFileNum             integer,
        @LastVoucherNum          integer,
        @SQLServer_error_code    integer,
        @IMAPS_error_code        integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
        @ret_code                integer

-- set local constants
SET @SP_NAME = 'XX_R22_CLS_DOWN_CREATE_LOG_RECORD_SP'

PRINT '***********************************************************************************************************************'
PRINT '     START OF ' + @SP_NAME
PRINT '***********************************************************************************************************************'



PRINT 'Attempt to validate user input and log interface run ...'

IF (@in_FY is NULL and @in_MO is NOT NULL) OR
   (@in_FY is NOT NULL and @in_MO is NULL) OR
   (@in_FY is NOT NULL and @in_MO is NOT NULL AND (CAST(@in_MO as integer) < 0 OR CAST(@in_MO as integer) > 12)) 
   BEGIN
      SET @IMAPS_error_code = 550 -- Accounting FY and Month should be correctly entered for CLS run on demand
      GOTO ERROR_HANDLER
   END

IF @in_FY is NOT NULL and @in_MO is NOT NULL 
   BEGIN
      SET @on_demand_fl = 1
      SET @FY_CD = @in_FY
      SET @PD_NO = @in_MO
   END
ELSE  -- @in_FY is NULL and @in_MO is NULL
   BEGIN
      SET @FY_CD = YEAR(GETDATE())
      SET @current_month = MONTH(GETDATE())
      SET @PD_NO = @current_month - 1

      IF @PD_NO = '0' 
         BEGIN
            SET @FY_CD = CAST(@FY_CD as integer) - 1 
            SET @PD_NO = '12'
         END

      IF LEN(@PD_NO) = 1
         SET @PD_NO = '0' + @PD_NO
   END

-- get New File seq and Voucher seq
SELECT @LastFileNum    = MAX(FILE_SEQ_NUM),
       @LastVoucherNum = MAX(CAST(VOUCHER_NUM as integer))
  FROM dbo.XX_R22_CLS_DOWN_LOG

IF @LastFileNum is NULL
   SET @LastFileNum = 1
ELSE
   SET @LastFileNum = @LastFileNum + 1

IF @LastVoucherNum is NULL
   SET @LastVoucherNum = 1
ELSE
   SET @LastVoucherNum = @LastVoucherNum + 1

INSERT INTO dbo.XX_R22_CLS_DOWN_LOG
   (STATUS_RECORD_NUM, FILE_SEQ_NUM, VOUCHER_NUM, FY_SENT, MONTH_SENT, LEDGER_ENTRY_DATE, MODIFIED_BY, ON_DEMAND)
   VALUES(@in_STATUS_RECORD_NUM, @LastFileNum, @LastVoucherNum, @FY_CD, @PD_NO, CURRENT_TIMESTAMP, SUSER_SNAME(), @on_demand_fl)

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0  
   BEGIN
      SET @IMAPS_error_code = 204 -- Attempt to insert a record into table XX_R22_CLS_DOWN_LOG failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'a record into table XX_R22_CLS_DOWN_LOG'
      GOTO ERROR_HANDLER
   END

PRINT '***********************************************************************************************************************'
PRINT '     END OF ' + @SP_NAME
PRINT '***********************************************************************************************************************'


RETURN(0)

ERROR_HANDLER:

SET @out_SystemError = @SQLServer_error_code

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_code,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)

END

GO



USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CLS_DOWN_GET_TOTALS_SP]    Script Date: 5/6/2020 5:08:08 PM ******/
DROP PROCEDURE [dbo].[XX_R22_CLS_DOWN_GET_TOTALS_SP]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CLS_DOWN_GET_TOTALS_SP]    Script Date: 5/6/2020 5:08:08 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO




CREATE PROCEDURE [dbo].[XX_R22_CLS_DOWN_GET_TOTALS_SP]
( 
@in_STATUS_RECORD_NUM   integer, 
@out_SystemError        integer      = NULL OUTPUT, 
@out_STATUS_DESCRIPTION varchar(275) = NULL OUTPUT
)
AS

/***********************************************************************************************
Name:       XX_R22_CLS_DOWN_GET_TOTALS_SP
Created by: HVT
Created:    10/27/2008
Purpose:    Create records in the staging table that will be put into control file for the main
            999-format data file.

            Called by XX_R22_CLS_DOWN_RUN_INTERFACE_SP.
            Adapted from XX_CLS_DOWN_GET_TOTALS_SP.

Notes:

CP600000465 10/27/2008 Reference BP&S Service Request CR1656
            Leverage the existing CLS Down interface for Division 16 to develop an interface
            between Costpoint and CLS to meet Division 22 (aka Research) requirements.

************************************************************************************************/

BEGIN

DECLARE @SP_NAME                 varchar(50),
        @default_customer_num    varchar(30),
        @SQLServer_error_code    integer,
        @IMAPS_error_code        integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
        @ret_code                integer

-- set local constants
SET @SP_NAME = 'XX_R22_CLS_DOWN_GET_TOTALS_SP'
SET @IMAPS_error_code = 204 -- Attempt to %1 %2 failed.

PRINT '***********************************************************************************************************************'
PRINT '     START OF ' + @SP_NAME
PRINT '***********************************************************************************************************************'



PRINT 'Attempt to update interface status and populate summary table ...'

-- Update status record (amounts are not updated since it should be always 0)
UPDATE dbo.XX_IMAPS_INT_STATUS
   SET RECORD_COUNT_SUCCESS = (SELECT COUNT(1) FROM dbo.XX_R22_CLS_DOWN)
 WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to update a record in table XX_IMAPS_INT_STATUS failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'a record in table XX_IMAPS_INT_STATUS'
      GOTO ERROR_HANDLER
   END

TRUNCATE TABLE dbo.XX_R22_CLS_DOWN_SUMMARY

INSERT INTO dbo.XX_R22_CLS_DOWN_SUMMARY
   (CLS_MAJOR, CLS_MINOR, CLS_SUB_MINOR, DOLLAR_AMT, RECORD_CNT)
   SELECT CLS_MAJOR, CLS_MINOR, CLS_SUB_MINOR, SUM(ISNULL(DOLLAR_AMT, 0.0)), COUNT(1)
     FROM dbo.XX_R22_CLS_DOWN
    GROUP BY CLS_MAJOR, CLS_MINOR, CLS_SUB_MINOR

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0
   BEGIN
      -- Attempt to insert records into table XX_R22_CLS_DOWN_SUMMARY failed.
      SET @error_msg_placeholder1 = 'insert'
      SET @error_msg_placeholder2 = 'records into table XX_R22_CLS_DOWN_SUMMARY'
      GOTO ERROR_HANDLER
   END

-- Update default customer number here

SELECT @default_customer_num = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS 
 WHERE INTERFACE_NAME_CD = 'CLS_R22'
   AND PARAMETER_NAME = 'DFLT_CUSTOMER_NUM'

UPDATE dbo.XX_R22_CLS_DOWN
   SET CUSTOMER_NUM = @default_customer_num
 WHERE CUSTOMER_NUM IS NULL

SET @SQLServer_error_code = @@ERROR

IF @SQLServer_error_code <> 0  
   BEGIN
      -- Attempt to update records in table XX_R22_CLS_DOWN failed.
      SET @error_msg_placeholder1 = 'update'
      SET @error_msg_placeholder2 = 'records in table XX_R22_CLS_DOWN'
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



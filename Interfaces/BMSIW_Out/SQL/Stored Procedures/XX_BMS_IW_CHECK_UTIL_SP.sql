SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_BMS_IW_CHECK_UTIL_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_BMS_IW_CHECK_UTIL_SP]
GO




CREATE PROCEDURE dbo.XX_BMS_IW_CHECK_UTIL_SP
(
@in_STATUS_RECORD_NUM     integer,
@out_SQLServer_error_code integer      = NULL OUTPUT,
@out_STATUS_DESCRIPTION   varchar(275) = NULL OUTPUT
)
AS
/****************************************************************************************************
Name:       XX_BMS_IW_CHECK_UTIL_SP
Author:     KM
Created:    11/01/2005
Purpose:    This stored procedure checks to see if the 
	    IMAPS TO UTILIZATION Interface has completed
	    Successfully and that it has populated the 
	    XX_UTIL_LAB_OUT table.

Parameters: 
Result Set: None
Notes:
****************************************************************************************************/
BEGIN

DECLARE	@SP_NAME                 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @row_count               integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
	@UTIL_INTERFACE_NAME	 varchar(5),
	@UTIL_STATUS		 varchar(20)

-- set local constants
SET @SP_NAME = 'XX_BMS_IW_CHECK_UTIL_SP'
SET @UTIL_INTERFACE_NAME = 'UTIL'

-- initialize local variables
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'verify Successful Completion'
SET @error_msg_placeholder2 = 'of Util Interface'

-- retrieve the execution result data of the last UTILIZATION interface run or job
SELECT @UTIL_STATUS = STATUS_CODE
  FROM dbo.XX_IMAPS_INT_STATUS
 WHERE INTERFACE_NAME = @UTIL_INTERFACE_NAME
   AND CREATED_DATE   = (SELECT MAX(s.CREATED_DATE) 
                           FROM dbo.XX_IMAPS_INT_STATUS s
                          WHERE s.INTERFACE_NAME = @UTIL_INTERFACE_NAME)

SELECT @SQLServer_error_code = @@ERROR, @row_count = @@ROWCOUNT


IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER

IF @row_count = 0 GOTO BL_ERROR_HANDLER

IF @UTIL_STATUS <> 'COMPLETED' GOTO BL_ERROR_HANDLER


-- TO DO
-- There is some requirement that says the interface
-- must be able to get UTIL_LAB_OUT data from
-- certain timeperiods if needed
-- This requires that we build parameters
-- for type of Interface run - Standard or Custom
-- and dates boundaries for Custom run
DECLARE	@RUN_TYPE	varchar(20),
	@START_DT	datetime,
	@END_DT		datetime

SELECT 	@RUN_TYPE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME = 'RUN_TYPE'


-- If non-standard run
IF(@RUN_TYPE <> 'STANDARD')
BEGIN
	-- get Custom Interface Parameters
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'Convert Custom Interface Run'
	SET @error_msg_placeholder2 = 'Date Parameters Failed'

	SELECT 	@START_DT = CAST(PARAMETER_VALUE as datetime)
	FROM	dbo.XX_PROCESSING_PARAMETERS
	WHERE	PARAMETER_NAME = 'START_DT'
	
	SELECT 	@END_DT = CAST(PARAMETER_VALUE as datetime)
	FROM	dbo.XX_PROCESSING_PARAMETERS
	WHERE	PARAMETER_NAME = 'END_DT'

	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER
	
	--insert desired values into UTIL_LAB_OUT
	SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
	SET @error_msg_placeholder1 = 'Insert Custom Interface'
	SET @error_msg_placeholder2 = 'Data Failed'

	INSERT INTO dbo.XX_UTIL_LAB_OUT
	(	UTIL_LAB_RECORD_NUM,STATUS_RECORD_NUM,TS_LN_KEY,
		EMPL_ID,LAST_FIRST_NAME,EMPL_HOME_ORG_ID,
		EMPL_HOME_ORG_NAME,CONTRACT_ID,CONTRACT_NAME,
		PROJ_ABBRV_CD,PROJ_NAME,INDUSTRY,
		KEY_ACCOUNT,HR_TYPE,TS_DT,
		POSTING_DT,ENTERED_HRS,PERIOD_END_DT)
	SELECT 
		UTIL_LAB_RECORD_NUM, STATUS_RECORD_NUM, TS_LN_KEY,
		EMPL_ID, LAST_FIRST_NAME, EMPL_HOME_ORG_ID,
		EMPL_HOME_ORG_NAME, CONTRACT_ID, CONTRACT_NAME,
		PROJ_ABBRV_CD, PROJ_NAME, INDUSTRY,
		KEY_ACCOUNT, HR_TYPE, TS_DT,
		POSTING_DT, ENTERED_HRS, PERIOD_END_DT
	FROM dbo.XX_UTIL_LAB_OUT_ARCH
	WHERE
	PERIOD_END_DT <= @END_DT AND
	PERIOD_END_DT >= @START_DT

	SELECT @SQLServer_error_code = @@ERROR
	IF @SQLServer_error_code <> 0 GOTO BL_ERROR_HANDLER
	
END


-- If no data in exists in the UTIL_LAB_OUT tables
SET @IMAPS_error_number = 204 -- Attempt to %1 %2 failed.
SET @error_msg_placeholder1 = 'verify that data exists in'
SET @error_msg_placeholder2 = 'table XX_UTIL_LAB_OUT'

SELECT 	@row_count = COUNT(*)
FROM	dbo.XX_UTIL_LAB_OUT

IF @row_count = 0 GOTO BL_ERROR_HANDLER

RETURN(0)

BL_ERROR_HANDLER:

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_number,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

RETURN(1)

END




GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


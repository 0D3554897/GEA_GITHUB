SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_PCLAIM_START_AP_PREPROCESSOR_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_PCLAIM_START_AP_PREPROCESSOR_SP]
GO


CREATE PROCEDURE [dbo].[XX_PCLAIM_START_AP_PREPROCESSOR_SP] (@in_status_record_num int, @SystemError int = NULL OUTPUT,
 @out_STATUS_DESCRIPTION varchar(275) = NULL OUTPUT) AS

DECLARE 
@PCLAIM_Proc_Que_ID  varchar(12) ,
@PCLAIM_Proc_ID  varchar(12) ,
@PCLAIM_PROC_SERVER_ID  varchar(12),
@ret_code int


SELECT @PCLAIM_Proc_Que_ID   = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS WHERE INTERFACE_NAME_CD = 'PCLAIM' AND PARAMETER_NAME = 'PCLAIM_PROC_QUE_ID'
SELECT @PCLAIM_Proc_ID   = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS WHERE INTERFACE_NAME_CD = 'PCLAIM' AND PARAMETER_NAME = 'PCLAIM_PROC_ID'
SELECT @PCLAIM_PROC_SERVER_ID   = PARAMETER_VALUE FROM XX_PROCESSING_PARAMETERS WHERE INTERFACE_NAME_CD = 'PCLAIM' AND PARAMETER_NAME = 'PCLAIM_PROC_SERVER_ID'


/************************************************************************************************  
Name:       XX_PCLAIM_FILL_PREPROCESSOR_STAGE_SP 
Author:     	Tatiana Perova
Created:    	08/24/2005  
Purpose:  Step 3 of PCLAIM interface.
		Calls procedure that updates AP preprocessor task in execution que.
                Called by XX_PCLAIM_RUN_INTERFACE_SP

Parameters: 
	Input: @in_STATUS_RECORD_NUM -- identifier of current interface run
	Output:  @out_STATUS_DESCRIPTION --  generated error message
		@out_out_SystemError  -- system error code
Result Set: 	None  
Version: 	1.0
Notes:
**************************************************************************************************/  

EXEC @ret_code = dbo.XX_IMAPS_UPDATE_PRQENT_SP
	@in_Proc_Que_ID   = @PCLAIM_Proc_Que_ID,
	@in_Proc_ID          =   @PCLAIM_Proc_ID,
	@in_PROC_SERVER_ID     = @PCLAIM_PROC_SERVER_ID,
	@out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION
	
RETURN @ret_code

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


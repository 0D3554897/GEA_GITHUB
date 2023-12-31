use imapsstg

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_PREPROCESSOR_AP_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_PREPROCESSOR_AP_SP]
GO

CREATE PROCEDURE [dbo].[XX_FIWLR_PREPROCESSOR_AP_SP] (
	@in_status_record_num INT, 
	@out_systemerror INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) =NULL OUTPUT)
AS

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_PREPROCESSOR_AP_SP						*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR Preprocessor Accounts Payable Procedure			*/
/* Date			: October 22, 2005						        */
/* Notes		: IMAPS FIW-LR Preprocessor Accounts Payable program will be executed 	*/
/*			  through FIW-LR Run interface program to group all the AP related	*/
/*			  transactions information and validate as per the AP Preprocessor	*/
/*			  data element requirements.						*/
/* Prerequisites	: XX_FIWLR_USDET_V3, XX_AOPUTLAP_INP_HDRV & XX_AOPUTLAP_INP_DETLV	*/
/*			  Table(s) should be created. Access priveleges to AOPUTLAP_INP_HDR 	*/
/*			  AOPUTLAP_INP_DETL table(s) in DELTEK should be provided.		*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: XX_FIWLR_USDET_V3 							*/
/* Version		: 1.1									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 10-22-2005   Veera Veeramachanane   	Created Initial Version					*/
/* 11-07-2005   Veera Veeramachanane   	Modified code to call balancing transaction procedure	*/
/*					Defect : DEV00000243					*/
/*

*/
/************************************************************************************************/


DECLARE 

	@retcode	 INT,
	@aop_stg_sp	 VARCHAR(50),
	@aop_stg_bal_sp	 VARCHAR(50),
	@aop_imaps_sp	 VARCHAR(50),
	@sp_name	 SYSNAME,
	@numberofrecords INT

	SELECT 	@aop_stg_sp	= 'dbo.XX_FIWLR_STG_SP',
		@aop_stg_bal_sp = 'dbo.XX_FIWLR_STG_BAL_SP', -- Added by Veera on 11/07/2005 - Defect : DEV00000243
		@aop_imaps_sp	= 'dbo.XX_FIWLR_IMAPS_STG_SP',
		@sp_name	= 'XX_FIWLR_PREPROCESSOR_AP_SP'


/*
/* Insert the AP transaction related information into AP Preprocessor staging tables */
	EXEC  @retcode = @aop_stg_sp 
			 @in_status_record_num = @in_status_record_num,
			 @out_systemerror = @out_systemerror  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing

-- Start Added by Veera on 11/07/2005 - Defect : DEV00000243
/* Insert the balancing transaction into AP Preprocessor staging tables */
	EXEC  @retcode = @aop_stg_bal_sp
			 @in_status_record_num = @in_status_record_num,
			 @out_systemerror = @out_systemerror  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing
-- End Added by Veera on 11/07/2005 - Defect : DEV00000243

/* Insert the AP vouchers transaction information into AP Preprocessor tables from AP Preprocessor staging tables */
	EXEC  @retCode = @aop_imaps_sp 
			 @in_status_record_num = @in_status_record_num,
			 @out_systemerror = @out_systemerror  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing

*/


/*
1M changes

Sorry.

The old code above was extremely sloppy and difficult to maintain for the 1M changes.

The new code below mimics the code used to load the preprocessors for miscode reprocessing.
One difference is the need to add new vendors for AP vouchers.

*/
set @retcode = 1

	EXEC  @retCode = XX_FIWLR_PROCESS_AP_SP 
			 @out_STATUS_DESCRIPTION = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing



RETURN 0
	ErrorProcessing:
RETURN 1
GO

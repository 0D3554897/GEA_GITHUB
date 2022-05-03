use imapsstg

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE ID = object_id(N'[dbo].[XX_FIWLR_PREP_JE_SP]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[XX_FIWLR_PREP_JE_SP]
GO

CREATE PROCEDURE [dbo].[XX_FIWLR_PREP_JE_SP] (
	@in_status_record_num INT, 
	@out_systemerror INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) =NULL OUTPUT)
AS

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_PREP_JE_SP							*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR Preprocessor Journal Entry Procedure			*/
/* Date			: October 22, 2005						        */
/* Notes		: IMAPS FIW-LR Preprocessor Journal Entry program will be executed 	*/
/*			  through FIW-LR Run interface program to group all the JE related	*/
/*			  transactions information and validate as per the JE Preprocessor	*/
/*			  data element requirements and also insert the JE Balancing transaction*/
/* Prerequisites	: XX_FIWLR_USDET_V3, DELTEK.AOPUTLJE_INP_TR Table(s) should be created. */
/*			  Access priveleges to AOPUTLJE_INP_TR table(s) should be provided.	*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: DELTEK.AOPUTLJE_INP_TR						*/
/* Version		: 1.1									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 11-05-2005   Veera Veeramachanane   	Created Initial Version	Defect : DEV00000243		*/
/* 11-05-2005   Veera Veeramachanane   	Modified procedure name from dbo.XX_FIWLR_STG_JE_SP to	*/
/*					XX_FIWLR_PREPROCESSOR_JE_SP. Defect: DEV000269		*/
/************************************************************************************************/


DECLARE 

	@retcode	 INT,
	@je_stg_sp	 VARCHAR(50),
	@je_stg_bal_sp	 VARCHAR(50),
	@aop_imaps_sp	 VARCHAR(50),
	@sp_name	 SYSNAME,
	@numberofrecords INT

	SELECT 	--@je_stg_sp	= 'dbo.XX_FIWLR_STG_JE_SP',
		@je_stg_sp	= 'dbo.XX_FIWLR_PREPROCESSOR_JE_SP', -- Added by Veera on 11/20/2005 to be in sync with earlier version Defect: DEV0000269
		@je_stg_bal_sp	= 'dbo.XX_FIWLR_STG_JE_BAL_SP',
		@sp_name	= 'XX_FIWLR_PREP_JE_SP'

/*
/* Insert the JE transaction related information into JE Preprocessor tables */
	EXEC  @retcode = @je_stg_sp 
			 @in_status_record_num = @in_status_record_num,
			 @out_systemerror = @out_systemerror  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing

/* Insert the balancing transaction into JE Preprocessor table */
	EXEC  @retcode = @je_stg_bal_sp
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
*/
set @retcode = 1

	EXEC  @retCode = XX_FIWLR_PROCESS_JE_SP 
			 @out_STATUS_DESCRIPTION = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing


RETURN 0
	ErrorProcessing:
RETURN 1

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


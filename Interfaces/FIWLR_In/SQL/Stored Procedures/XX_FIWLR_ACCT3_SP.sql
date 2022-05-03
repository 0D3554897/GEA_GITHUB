SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE ID = object_id(N'[dbo].[XX_FIWLR_ACCT3_SP]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[XX_FIWLR_ACCT3_SP]
GO

CREATE PROCEDURE [dbo].[XX_FIWLR_ACCT3_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

DECLARE 
	@sp_name		VARCHAR(30),
	@sourcewwern16	VARCHAR(3),
	@int_name		VARCHAR(20),
	@param_name		VARCHAR(50)

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_ACCT3_SP							*/
/* Created By		: Clare Robbins	*/
/* Description    	: IMAPS FIW-LR Account3 Procedure					*/
/* Date			: February 13, 2006						        */
/* Notes		: IMAPS FIW-LR Account3 program will apply the appropriate account ID   */
/*			  to N16 transactions per defect DEV00000479 				*/
/* Prerequisites	: XX_FIWLR_USDET_V3 							*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: XX_FIWLR_USDET_V3 							*/
/* Version		: 1.3									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 2-13-2006   Clare Robbins   	Created Initial Version					*/
/************************************************************************************************/

BEGIN

	SELECT  @sp_name = 'XX_FIWLR_ACCT3_SP',
		  @sourcewwern16 = 'N16',
		  @int_name = 'FIWLR',
		  @param_name =  'N16_DR_ACCT_ID'

	UPDATE v
	SET 	v.acct_id = p.parameter_value
	FROM 	dbo.xx_fiwlr_usdet_v3 v,
		dbo.xx_processing_parameters p
	WHERE v.source = @sourcewwern16
	AND p.interface_name_cd = @int_name
	AND p.parameter_name = @param_name
	
	SELECT @out_systemerror = @@ERROR
	IF @out_systemerror <> 0  
		GOTO ErrorProcessing	

RETURN 0
ErrorProcessing:
	
		EXEC dbo.XX_ERROR_MSG_DETAIL
	         		@in_error_code           = 204,
	         		@in_SQLServer_error_code = @out_systemerror,
	         		@in_display_requested    = 1,
				@in_placeholder_value1   = 'update',
	   			@in_placeholder_value2   = 'XX_FIWLR_USDET_V3',
	         		@in_calling_object_name  = @sp_name,
	         		@out_msg_text            = @out_status_description OUTPUT

RETURN 1
END
GO

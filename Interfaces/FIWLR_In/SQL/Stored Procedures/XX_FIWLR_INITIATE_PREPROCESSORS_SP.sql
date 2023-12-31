SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.XX_FIWLR_INITIATE_PREPROCESSORS_SP    Script Date: 09/19/2006 10:08:14 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_INITIATE_PREPROCESSORS_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_INITIATE_PREPROCESSORS_SP]
GO



CREATE PROCEDURE [dbo].[XX_FIWLR_INITIATE_PREPROCESSORS_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

DECLARE 
	@fiwlr_proc_que_id  	VARCHAR(12) ,
	@fiwlr_proc_id  	VARCHAR(12) ,
	@fiwlr_proc_server_id  	VARCHAR(12),
	@sp_name		SYSNAME,
	@ret_code 		INT

BEGIN

	SELECT 	@fiwlr_proc_que_id = parameter_value 
	FROM 	dbo.xx_processing_parameters 
	WHERE 	interface_name_cd = 'FIWLR' 
	AND 	parameter_name = 'FIWLR_PROC_QUE_ID'
	SELECT 	@fiwlr_proc_id = parameter_value 
	FROM 	dbo.xx_processing_parameters 
	WHERE 	interface_name_cd = 'FIWLR' 
	AND 	parameter_name = 'FIWLR_PROC_ID'
	SELECT 	@fiwlr_proc_server_id = parameter_value 
	FROM 	dbo.xx_processing_parameters 
	WHERE 	interface_name_cd = 'FIWLR' 
	AND 	parameter_name = 'FIWLR_PROC_SERVER_ID'
	SELECT 	@sp_name = 'XX_FIWLR_INITIATE_PREPROCESSORS_SP'

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_INITIATE_PREPROCESSORS_SP					*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIWLR Initiate AP and JE Preprocessors				*/
/* Date			: October 23, 2005						        */
/* Notes		: Updates the Process Queue Entry to initiate AP and JE Preprocessor 	*/
/* Prerequisites	: XX_FIWLR_USDET_V3 Table(s) should be created.				*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: DELTEK.PROCESS_QUE_ENTRY						*/
/* Version		: 1.0									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 10-20-2005   Veera Veeramachanane   	Created Initial Version					*/
/************************************************************************************************/

	EXEC @ret_code = dbo.xx_imaps_update_prqent_sp
			@in_proc_que_id = @fiwlr_proc_que_id,
			@in_proc_id =   @fiwlr_proc_id,
			@in_proc_server_id = @fiwlr_proc_server_id,
			@out_status_description = @out_status_description
	
		IF @ret_code <> 0
			GOTO ErrorProcessing

RETURN @ret_code

ErrorProcessing:

	exec dbo.xx_error_msg_detail
         		@in_error_code           = 204,
         		@in_sqlserver_error_code = @out_systemerror,
         		@in_display_requested    = 1,
			@in_placeholder_value1   = 'update',
   			@in_placeholder_value2   = 'XX_FIWLR_USDET_V3',
         		@in_calling_object_name  = @sp_name,
         		@out_msg_text            = @out_status_description output

RETURN 1
END


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


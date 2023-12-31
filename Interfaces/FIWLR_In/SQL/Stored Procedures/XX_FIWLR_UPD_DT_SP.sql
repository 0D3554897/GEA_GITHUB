SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_UPD_DT_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_UPD_DT_SP]
GO


CREATE PROCEDURE [dbo].[XX_FIWLR_UPD_DT_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

DECLARE 

	@numberofrecords 	INT,
	@source_wwer		VARCHAR(3),			
	@source_wwern16		VARCHAR(3),
	@error_type		INT,
	@error_code		INT,
	@error_msg_placeholder1	SYSNAME,
	@error_msg_placeholder2 SYSNAME,
	@sp_name		SYSNAME,
	@fiwlr_in_record_num 	INT

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_UPD_DT_SP							*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR Update Date Format Procedure				*/
/* Date			: October 22, 2005						        */
/* Notes		: IMAPS FIW-LR Update Date Format program will update the date format 	*/
/*			  into a single compatible date format for all the transactions 	*/
/*			  extracted from FIW-LR and WWERN16 transactions.			*/
/* Prerequisites	: XX_FIWLR_USDET_V3 table(s) should be created.				*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: XX_FIWLR_USDET_V3			 				*/
/* Version		: 1.0									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 10-22-2005   Veera Veeramachanane   	Created Initial Version					*/
/************************************************************************************************/

BEGIN

-- set local constants

	SELECT	@sp_name = 'XX_FIWLR_UPD_DT_SP',
		@error_msg_placeholder1	= NULL,
		@error_msg_placeholder2 = NULL,
		@source_wwer = '005',
		@source_wwern16 = 'N16'

-- Update Date format in xx_fiwlr_usdet_v3 table to be in sync with all the date formats extracted

	UPDATE 	dbo.xx_fiwlr_usdet_v3
	SET 	fiwlr_inv_date = CONVERT( VARCHAR(10),CAST((SUBSTRING(fiwlr_inv_date, 1, 2) + '-' + SUBSTRING(fiwlr_inv_date, 3, 2) + '-' + SUBSTRING(fiwlr_inv_date, 5, 2)) as DATETIME),120)
	WHERE 	source <> @source_wwer
	AND 	source <> @source_wwern16
	AND 	fiwlr_inv_date <> ' '
	AND 	status_rec_no = @in_status_record_num

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 1 
				GOTO ErrorProcessing
   			END
--			Print 'Number of date records updated ' + CAST(@numberofrecords AS char)

RETURN 0

ErrorProcessing:

	IF @error_type = 1
   		BEGIN
      			SET @error_code = 204 -- Attempt to update records in table XX_FIWLR_USDET_V3 failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'a record into table XX_FIWLR_USDET_V3'
   		END

		EXEC dbo.xx_error_msg_detail
	         		@in_error_code           = @error_code,
	         		@in_sqlserver_error_code = @out_systemerror,
	         		@in_display_requested    = 1,
				@in_placeholder_value1   = @error_msg_placeholder1,
		   		@in_placeholder_value2   = @error_msg_placeholder2,
	         		@in_calling_object_name  = @sp_name,
	         		@out_msg_text            = @out_status_description OUTPUT

RETURN 1
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


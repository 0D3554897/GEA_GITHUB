USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_PREPROCESSOR_AP_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_R22_FIWLR_PREPROCESSOR_AP_SP]
GO

CREATE PROCEDURE [dbo].[XX_R22_FIWLR_PREPROCESSOR_AP_SP] (
	@in_status_record_num INT, 
	@out_systemerror INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) =NULL OUTPUT)
AS

/************************************************************************************************/
/* Procedure Name	: XX_R22_FIWLR_PREPROCESSOR_AP_SP											*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   							*/
/* Description    	: IMAPS FIW-LR Preprocessor Accounts Payable Procedure						*/
/* Date				: August 10, 2008															*/
/* Notes			: IMAPS FIW-LR Preprocessor Accounts Payable program will be executed 		*/
/*					  through FIW-LR Run interface program to group all the AP related			*/
/*					  transactions information and validate as per the AP Preprocessor			*/
/*					  data element requirements.												*/
/* Prerequisites	: XX_R22_FIWLR_USDET_V3, XX_R22_AOPUTLAP_INP_HDRV,XX_R22_AOPUTLAP_INP_DETLV	*/
/*					  Table(s) should be created. Access priveleges to AOPUTLAP_INP_HDR 		*/
/*					  AOPUTLAP_INP_DETL table(s) in DELTEK should be provided.					*/
/* Parameter(s)		: 																			*/
/*	Input			: Status Record Number														*/
/*	Output			: Error Code and Error Description											*/
/* Tables Updated	: XX_R22_FIWLR_USDET_V3 													*/
/* Version			: 1.0																		*/
/************************************************************************************************/
/* Date			Modified By				Description of change			  						*/
/* ----------   -------------  	   		------------------------    			  				*/
/* 08-10-2008   Veera Veeramachanane   	Created Initial Version									*/
/************************************************************************************************/


--load Vendors
	/*insert vendors into Costpoint*/
	DECLARE		@vend_id			VARCHAR(12),
				@vend_name			VARCHAR(40),
				@vend_longname		VARCHAR(40), 
				@fiwlr_intername 	VARCHAR(20), 
				@fiwlr_rowversion	INT	   

	SELECT 
		@fiwlr_intername  = 'FIWLR_R22',
		@fiwlr_rowversion = 5001 


	DECLARE vendor_id_cursor CURSOR FAST_FORWARD FOR
	SELECT	vendor_id, vend_name, vend_name
	FROM	xx_r22_fiwlr_usdet_v3
	WHERE	source_group = 'AP'
	AND		LEN(LTRIM(RTRIM(vendor_id))) > 0
	GROUP BY vendor_id, vend_name, vend_name

	OPEN vendor_id_cursor
	FETCH NEXT FROM vendor_id_cursor INTO @vend_id,@vend_name,@vend_longname

	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		EXEC @out_systemerror 	=  xx_r22_add_vendor_sp
			 @in_vendorid 		= @vend_id,
			 @in_vendorname 	= @vend_name,
			 @in_vendorlongname = @vend_longname,
			 @in_modified_by 	= @fiwlr_intername,
			 @in_rowversion 	= @fiwlr_rowversion		

		IF @out_systemerror <> 0 GOTO ErrorProcessing

	FETCH NEXT FROM vendor_id_cursor INTO @vend_id,@vend_name,@vend_longname
	END

	CLOSE vendor_id_cursor
	DEALLOCATE vendor_id_cursor

RETURN 0
	ErrorProcessing:
				CLOSE VENDOR_ID_CURSOR
				DEALLOCATE VENDOR_ID_CURSOR

				EXEC dbo.xx_error_msg_detail
	       			@in_error_code           = 204,
	       			@in_sqlserver_error_code = null,
	       			@in_display_requested    = 1,
					@in_placeholder_value1   =  'insert',
					@in_placeholder_value2   = 'vendors into Costpoint',
	        		@in_calling_object_name  = 'XX_R22_FIWLR_PREPROCESSOR_AP_SP',
	        		@out_msg_text            = @out_status_description OUTPUT
RETURN 1

GO

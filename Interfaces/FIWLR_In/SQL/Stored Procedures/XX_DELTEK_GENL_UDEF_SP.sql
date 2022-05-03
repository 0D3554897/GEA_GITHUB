SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.XX_DELTEK_GENL_UDEF_SP    Script Date: 10/04/2006 11:51:03 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_DELTEK_GENL_UDEF_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_DELTEK_GENL_UDEF_SP]
GO


CREATE PROCEDURE [dbo].[XX_DELTEK_GENL_UDEF_SP] (
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

-- genl_udef
DECLARE 
	@error_type		INT,
	@error_code		INT,
	@error_msg_placeholder1	SYSNAME,
	@error_msg_placeholder2 SYSNAME,
	@sp_name		SYSNAME


	SELECT	@sp_name = 'XX_DELTEK_GENL_UDEF_SP',
		@error_msg_placeholder1	= NULL,
		@error_msg_placeholder2 = NULL

/************************************************************************************************/
/* Procedure Name	: XX_DELTEK_GENL_UDEF_SP						*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS GENL UDEF ORG Procedure						*/
/* Date			: October 25, 2005						        */
/* Notes		: IMAPS FIW-LR Genl Udef Org program will insert all default projects	*/
/*			  for all indirect organizatrions 					*/
/* Prerequisites	: XX_TEST_GENL_UDEF, DELETEK.GENL_UDEF Table(s) should exist.		*/
/* Parameter(s)		: 									*/
/*	Input		: 									*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: DELTEK.GENL_UDEF							*/
/* Version		: 1.0									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 11-02-2005   Veera Veeramachanane   	Created Initial Version					*/
/************************************************************************************************/

--copy all records from test genl udef table to genl udef table in imaps 

	INSERT INTO IMAPS.deltek.genl_udef(
		GENL_ID,
		GENL1_ID,
		S_TABLE_ID,
		UDEF_LBL_KEY,
		UDEF_TXT,
		UDEF_ID,
		UDEF_DT,
		UDEF_AMT,
		MODIFIED_BY,
		TIME_STAMP,
		COMPANY_ID,
		ROWVERSION )
	SELECT 	GENL_ID,
		GENL1_ID,
		S_TABLE_ID,
		UDEF_LBL_KEY,
		UDEF_TXT,
		UDEF_ID,
		UDEF_DT,
		UDEF_AMT,
		MODIFIED_BY,
		TIME_STAMP,
		COMPANY_ID,
		ROWVERSION 
	FROM 	dbo.XX_TEST_GENL_UDEF

	SELECT @out_systemerror = @@ERROR
	IF @out_systemerror <> 0 
   		BEGIN
			SET @error_type = 1 
			GOTO ErrorProcessing
   		END

RETURN 0

ErrorProcessing:

	IF @error_type = 1
   		BEGIN
      			SET @error_code = 204 -- Attempt to insert a record into table GENL_UDEF failed.
      			SET @error_msg_placeholder1 = 'insert'
      			SET @error_msg_placeholder2 = 'a record into table GENL_UDEF'
   		END


		EXEC dbo.xx_error_msg_detail
		   @in_error_code           = @error_code,
		   @in_display_requested    = 1,
		   @in_sqlserver_error_code = @out_systemerror,
		   @in_placeholder_value1   = @error_msg_placeholder1,
		   @in_placeholder_value2   = @error_msg_placeholder2,
		   @in_calling_object_name  = @sp_name,
		   @out_msg_text            = @out_status_description OUTPUT

RETURN 1

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


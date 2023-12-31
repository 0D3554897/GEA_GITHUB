SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_ASSIGN_SRC_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_ASSIGN_SRC_SP]
GO


CREATE PROCEDURE [dbo].[XX_FIWLR_ASSIGN_SRC_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

DECLARE 

	@batch_id		INT,
	@numberofrecords 	INT,
	@error_type		INT,	
	@error_code		INT,
	@error_msg_placeholder1	SYSNAME,
	@error_msg_placeholder2 SYSNAME,
	@sp_name		SYSNAME,
	@source_group_ap	VARCHAR(2),
	@source_group_je	VARCHAR(2),
	@fiwlr_in_record_num 	INT

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_ASSIGN_SRC_SP						*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR Assign Source Group Procedure				*/
/* Date			: October 22, 2005						        */
/* Notes		: IMAPS FIW-LR Assign Source program will assign the source group to 	*/
/*			  the transactions extracted from FIW-LR based on the source group 	*/
/*			  mapping logic.							*/
/* Prerequisites	: XX_FIWLR_USDET_V3 and XX_FIWLR_APSRC_GRP table(s) should be created.	*/
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

	SELECT	@sp_name = 'XX_FIWLR_ASSIGN_SRC_SP',
		@error_msg_placeholder1	= NULL,
		@error_msg_placeholder2 = NULL,
		@source_group_ap = 'AP',
		@source_group_je = 'JE'

-- Assign Source Group AP to the AP Sourced transactions

	UPDATE 	a
	SET 	a.source_group = @source_group_ap
	FROM 	dbo.xx_fiwlr_usdet_v3 as a, 
		dbo.xx_fiwlr_apsrc_grp as b
	WHERE 	a.source = b.source
	AND 	status_rec_no = @in_status_record_num;

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 1 
				GOTO ErrorProcessing
   			END

--			Print 'Number of AP Records updated ' + CAST(@NumberOfRecords AS char)

-- Assign Source Group JE to the JE Sourced transactions

		UPDATE 	a
		SET 	a.source_group = @source_group_je
		FROM 	dbo.xx_fiwlr_usdet_v3 as a
		WHERE 	a.source not in (SELECT b.source
			  		 FROM 	dbo.xx_fiwlr_apsrc_grp AS b)
		AND 	status_rec_no = @in_status_record_num

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 2 
				GOTO ErrorProcessing
   			END
				
--			Print 'Number of JE Records updated ' + CAST(@NumberOfRecords AS char)

RETURN 0

ErrorProcessing:

	IF @error_type = 1
   		BEGIN
      			SET @error_code = 204 -- Attempt to update records in table XX_FIWLR_USDET_V3 failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'a record into table XX_FIWLR_USDET_V3'
   		END
	ELSE IF @error_type = 2
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


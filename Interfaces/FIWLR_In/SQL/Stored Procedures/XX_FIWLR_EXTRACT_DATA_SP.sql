use imapsstg
go
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[XX_FIWLR_EXTRACT_DATA_SP]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[XX_FIWLR_EXTRACT_DATA_SP]
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE PROCEDURE [dbo].[XX_FIWLR_EXTRACT_DATA_SP] (
	@in_status_record_num 	INT, 
	@out_SystemError 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

DECLARE 

	@retcode	  	INT,
	@fiwlr_ceris_emp_sp  	VARCHAR(30),
	@fiwlr_vend_sp	  	VARCHAR(30),
	@fiwlr_emp_sp	  	VARCHAR(30),
	@fiwlr_wwern16_sp	VARCHAR(30),
	@fiwlr_assign_src_sp 	VARCHAR(30),
	@fiwlr_upd_dt_sp	VARCHAR(30),
	@wwer_empv_sp		VARCHAR(30),
-- Start Added by Veera on 07/27/06 Defect : DEV00001076
	@sourcegrp		VARCHAR(2), 	
	@sourcewwer		VARCHAR(3), 
	@sourcewwern16		VARCHAR(3) 
	

	SELECT 	@fiwlr_vend_sp 	     = 'dbo.XX_FIWLR_VENDOR_SP',
		@fiwlr_emp_sp 	     = 'dbo.XX_FIWLR_EMP_SP',
		@fiwlr_wwern16_sp    = 'dbo.XX_FIWLR_WWERN16_SP',
		@fiwlr_assign_src_sp = 'dbo.XX_FIWLR_ASSIGN_SRC_SP',
		@fiwlr_ceris_emp_sp  = 'dbo.XX_FIWLR_CERIS_EMP_SP',
		@fiwlr_upd_dt_sp     = 'dbo.XX_FIWLR_UPD_DT_SP',
		@wwer_empv_sp 	     = 'XX_FIWLR_WWER_EMP_VERFL_SP',
-- Start Added by Veera on 07/27/06 Defect : DEV00001076
		@sourcegrp 	     =	'AP',	
		@sourcewwer 	     = '005',
		@sourcewwern16 	     = 'N16' 

	
/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_EXTRACT_DATA_SP						*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR Extract Data Procedure					*/
/* Date			: October 22, 2005						        */
/* Notes		: IMAPS FIW-LR Extract Data program will be executed through FIW-LR Run	*/
/*			  interface to group the data from different sources received. This 	*/
/*			  will categorize the sources to AP and JE based on the source group 	*/
/*			  logic. Also, the program will update the date format to be in sync.	*/
/* Prerequisites	: XX_FIWLR_CERIS_EMP_SP, XX_FIWLR_VENDOR_SP, XX_FIWLR_EMP_SP,  		*/
/*			  XX_FIWLR_WWERN16_SP, XX_FIWLR_ASSIGN_SRC_SP and XX_FIWLR_UPD_DT_SP	*/
/*			  XX_AOPUTLAP_INP_DETLV, XX_FIWLR_INC_EXC_TEST, XX_FIWLR_APSRC_GRP, 	*/
/*			  XX_FIWLR_USDET_ARCHIVE, XX_AOPUTLAP_INP_HDR_ERR, 			*/
/*			  XX_AOPUTLAP_INP_DETL_ERR, XX_AOPUTLJE_INP_TR_ERR, XX_SEQUENCES_HDR,	*/
/*			  XX_SEQUENCES_DETL, XX_SEQUENCES_JE Table(s) should be created.	*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: XX_FIWLR_USDET_V2 and XX_FIWLR_USDET_V3 				*/
/* Version		: 1.3									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 10-22-2005   Veera Veeramachanane   	Created Initial Version					*/
/* 11-14-2005   Veera Veeramachanane   	Commented out calling XX_FIWLR_CERIS_EMP procedure 	*/
/*					to fix distributed link server error. Defect:DEV00000269*/
/* 07-27-2006   Veera Veeramachanane   	Added update statement to populate vend_name for 	*/
/*					Source(s) 005 and N16. Defect:DEV00001076		*/
/*
	Date		Modified By		Description of change	
   ----------   -------------	------------------------ 
   2010-09-13	KM				1M changes

*/
/************************************************************************************************/

/* Extracting employee history information from eT&E (CERIS) */
--	START Commented out by Veera on 11/14/2005 - Defect : DEV00000269
/*	EXEC  @retcode = @fiwlr_ceris_emp_sp 
			 @in_status_record_num 	= @in_status_record_num,
			 @out_SystemError 	= @out_SystemError  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing
*/
--	END Commented out by Veera on 11/14/2005 - Defect : DEV00000269

/* Group the extracted FIW-LR expense and ledger transactions with Vendor details into XX_FIWLR_USDET_V2 table */
	EXEC  @retcode = @fiwlr_vend_sp 
			 @in_status_record_num 	= @in_status_record_num,
			 @out_SystemError 	= @out_SystemError  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT
	
	IF @retcode <> 0
		GOTO ErrorProcessing

/* Group the extracted FIW-LR expense and ledger transactions with Employee details into XX_FIWLR_USDET_V3 table */
	EXEC  @retCode = @fiwlr_emp_sp 
			 @in_status_record_num 	= @in_status_record_num,
			 @out_SystemError 	= @out_SystemError  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing
	
/* Group the extracted WWER N16 expense transactions with FIW-LR ledger and expense transactions into XX_FIWLR_USDET_V3 table */
	EXEC  @retCode = @fiwlr_wwern16_sp 
			 @in_status_record_num 	= @in_status_record_num,
			 @out_SystemError 	= @out_SystemError  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing

/* Assign the source group to the extracted FIW-LR transactions based on the source group mapping logic */
	EXEC  @retCode = @fiwlr_assign_src_sp 
			 @in_status_record_num 	= @in_status_record_num,
			 @out_SystemError 	= @out_SystemError  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing

/* Update the FIW-LR invoice date format to be in sync*/
	EXEC  @retCode = @fiwlr_upd_dt_sp 
			 @in_status_record_num 	= @in_status_record_num,
			 @out_SystemError 	= @out_SystemError  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing

/* Update the Value-Non-Value Added Flag in XX_FIWLR_USDET_V3 table with employee division verification */
	EXEC  @retCode = @wwer_empv_sp 
			 @in_status_record_num 	= @in_status_record_num,
			 @out_SystemError 	= @out_SystemError  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing

/* Update XX_FIWLR_USDET_V3 table for source 005 and N16 with employee lastname/firstname for vend_name */
-- Start Added by Veera on 07/27/06 Defect : DEV00001076
	UPDATE	imapsstg.dbo.xx_fiwlr_usdet_v3
	SET	vendor_id = employee_no,
		vend_name = SUBSTRING((LTRIM(RTRIM(emp_lastname)) + ',' + LTRIM(RTRIM(emp_firstname))),1,25),
		reference1 = SUBSTRING((LTRIM(RTRIM(emp_lastname)) + ',' + LTRIM(RTRIM(emp_firstname))),1,40)
	WHERE	vendor_id = ' '
	AND	source_group = @sourcegrp
	AND	source	IN (@sourcewwer, @sourcewwern16)


	IF @@ERROR <> 0
		GOTO ErrorProcessing

--KM 1M changes
/*
-change to overwrite INTERCO projects on 1M WWER transactions with project from custom BMSIW pull
(project does not flow to FIWLR for these)
*/
	update xx_fiwlr_usdet_v3
	set proj_abbr_cd = (select top 1 account_id from xx_fiwlr_bmsiw_wwer1m_extract_archive where rpt_key=fiwlr.voucher_no and exp_key=cast(fiwlr.wwer_exp_key as int))
	from xx_fiwlr_usdet_v3 fiwlr
	where source='005'
	and division='1M'
	and project_no='INTRACO'

	IF @@ERROR <> 0
		GOTO ErrorProcessing

RETURN 0
ErrorProcessing:
RETURN 1


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


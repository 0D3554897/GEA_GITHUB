USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_FIWLR_WWER_EMP_VERFL_SP]    Script Date: 11/15/2016 11:20:53 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_FIWLR_WWER_EMP_VERFL_SP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[XX_FIWLR_WWER_EMP_VERFL_SP]
GO

USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_FIWLR_WWER_EMP_VERFL_SP]    Script Date: 11/15/2016 11:20:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[XX_FIWLR_WWER_EMP_VERFL_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_WWER_EMP_VERFL_SP						*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR WWER Employee Verification Flag Procedure		*/
/* Date			: October 28, 2005						        */
/* Notes		: IMAPS FIW-LR WWER Employee Verification Flag program will verify the 	*/
/*			  whether employee existed in Division 16 when expense incurred and 	*/
/*			  the value added or non-value added flag in XX_FIWLR_USDET_V3 table.	*/
/* Prerequisites	: XX_FIWLR_USDET_V3 and XX_FIWLR_CERIS_EMP Table(s) should exist.	*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: DELTEK.AOPUTLAP_INP_HDR and DELTEK.AOPUTLAP_INP_DETL 			*/
/* Version		: 1.1									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 10-28-2005   Veera Veeramachanane   	Created Initial Version					*/
/* 11-15-2005   Veera Veeramachanane   	Modified code to improve the performance and added where*/
/*					Defect : DEV0000269					*/
/* 06-21-2006 	Keith McGuire		Defect : DEV0000879					*/
/* 09-15-2006	Keith McGuire		Changed to base flag on WWER_EXP_DT instead of FIWLR_INVC_DT*/
/* 03-07-2007   Keith McGuire		Changed to use common DIV16 status function		*/

/*
	Date		Modified By		Description of change	
   ----------   -------------	------------------------ 
   2010-09-13	KM				1M changes


CR6295 - Div1P - KM - 2013-04-29
For the purposes of this function (used by FIWLR and N16 interfaces), evaluate 1P as if it is the same as 16)
CR8762 Div 2G  TP 2016-11-14
For the purposes of XX_GET_DIV16_STATUS_UF function (used by FIWLR and N16 interfaces), evaluate 2G as if it is the same as 16)
*/

/************************************************************************************************/

DECLARE 
	@emp_id		VARCHAR(12), -- Added by Veera on 11/15/05 Defect : DEV0000269
	@empl_id      	VARCHAR(12),
        @invoice_dt1  	VARCHAR(10),
        @invoice_dt2  	DATETIME,
        @ibm_start_dt 	DATETIME,
--        @invoice_dt2  	VARCHAR(10),
 --       @ibm_start_dt 	VARCHAR(10),
  --      @div_start_dt 	VARCHAR(10),
        @div          	VARCHAR(2),
        @div_from     	VARCHAR(2),
        @div_start_dt 	DATETIME,
        @yes_no_flag  	CHAR(1),
	@sp_name	SYSNAME,
	@div_value	VARCHAR(4),
        @source_group	VARCHAR(2),
	@sourcewwer	VARCHAR(3),
	@sourcewwern16	VARCHAR(3)

BEGIN

	SELECT  @sp_name = 'XX_FIWLR_WWER_EMP_VERFL_SP',
		@source_group = 'AP',
		@div_value = '16',
		@sourcewwer = '005',
		@sourcewwern16 = 'N16'


--begin KM 1M changes
--change to use 1M division status for value-add logic
	UPDATE 	dbo.XX_FIWLR_USDET_V3
	SET	val_nval_cd = dbo.XX_GET_DIV16_STATUS_UF(employee_no,  CAST(wwer_exp_dt as datetime))
	WHERE
		DIVISION in ('16','1P','2G')
	AND	source IN (@sourcewwer, @sourcewwern16)
	AND	source_group = @source_group
	AND	status_rec_no = @in_status_record_num
	AND	DATALENGTH(LTRIM(RTRIM(employee_no))) > 0
	AND	wwer_exp_dt is not null
	
	IF @@ERROR <> 0 GOTO ErrorProcessing

	UPDATE 	dbo.XX_FIWLR_USDET_V3
	SET	val_nval_cd = dbo.XX_GET_DIV1M_STATUS_UF(employee_no,  CAST(wwer_exp_dt as datetime))
	WHERE
		DIVISION='1M'
	AND	source IN (@sourcewwer, @sourcewwern16)
	AND	source_group = @source_group
	AND	status_rec_no = @in_status_record_num
	AND	DATALENGTH(LTRIM(RTRIM(employee_no))) > 0
	AND	wwer_exp_dt is not null
	
	IF @@ERROR <> 0 GOTO ErrorProcessing
--end KM 1M changes
--change to use 1M division status for value-add logic

	UPDATE 	dbo.XX_FIWLR_USDET_V3
	SET	val_nval_cd = 'N'
	WHERE	source_group = @source_group
	AND	source IN (@sourcewwer, @sourcewwern16)
	AND	status_rec_no = @in_status_record_num
	AND 	(val_nval_cd <> 'Y' or val_nval_cd is null)

	IF @@ERROR <> 0 GOTO ErrorProcessing


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


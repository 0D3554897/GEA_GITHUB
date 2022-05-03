USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_FIWLR_VALID_DATA_SP]    Script Date: 11/15/2016 11:12:31 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_FIWLR_VALID_DATA_SP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[XX_FIWLR_VALID_DATA_SP]
GO

USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_FIWLR_VALID_DATA_SP]    Script Date: 11/15/2016 11:12:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO



CREATE  PROCEDURE [dbo].[XX_FIWLR_VALID_DATA_SP] (
	@in_status_record_num INT, 
	@out_systemerror INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) =NULL OUTPUT)
AS

DECLARE 

	@retcode	INT,
	@proj_sp	VARCHAR(30),
	--@org_sp		VARCHAR(30),  Commented by Clare 2/13/06, replaced by blank proj sp
	@acct1_sp	VARCHAR(30),
	@acct2_sp	VARCHAR(30),
	@acct3_sp	VARCHAR(30), --Added by Clare 2/13/06
	--@int_org_sp	VARCHAR(30)  -- Added by Clare 1/25/06, removed by Clare 2/13/06
	@blank_proj_sp VARCHAR(30)	--Added by Clare 2/13/06

	
	SELECT 	@proj_sp  = 'dbo.XX_FIWLR_PROJ_SP',
		--@org_sp   = 'dbo.XX_FIWLR_ORG_SP',	  Commented by Clare 2/13/06	
		@acct1_sp = 'dbo.XX_FIWLR_ACCT1_SP',
		@acct2_sp = 'dbo.XX_FIWLR_ACCT2_SP',
		@acct3_sp = 'dbo.XX_FIWLR_ACCT3_SP', --Added by Clare 2/13/06
		--@int_org_sp = 'dbo.XX_FIWLR_INTL_PROJ_SP'      --Added by Clare 1/25/06 removed by Clare 2/13/06
		@blank_proj_sp = 'dbo.XX_FIWLR_BLANK_PROJ_SP'  --Added by Clare 2/13/06


/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_VALID_DATA_SP						*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR Validate Data Procedure					*/
/* Date			: October 22, 2005						        */
/* Notes		: IMAPS FIW-LR Validate Data program will be executed through FIW-LR 	*/
/*			  Run interface program to retrieve the project abbreviation code and	*/
/*			  based on the project number received from FIW-LR. Account mapping is 	*/
/*			  performed to get the account id based on major, minor, subminor and 	*/
/*			  analysis code mapping to the account created in the table		*/
/*			  XX_CLS_IMPAS_ACCT_MAP.						*/
/* Prerequisites	: XX_FIWLR_USDET_V3 & XX_CLS_IMPAS_ACCT_MAP Table(s) should be created	*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: XX_FIWLR_USDET_V3 							*/
/* Version		: 1.1									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 10-22-2005   Veera Veeramachanane   	Created Initial Version	*/
/* 01-25-2006   Clare Robbins		Add update of org for internal projects/transactions per Feature: DEV00000493*/
/* 02-13-2006   Clare Robbins		Add procedure for new N16 acct id logic per defect DEV00000479*/
/* 02-13-2006   Clare Robbins		Change org update for blank proj per defect DEV00000390			*/
/*
	Date		Modified By		Description of change	
   ----------   -------------	------------------------ 
   2010-09-13	KM				1M changes

CR6295 - Div1P - KM - 2013-04-29
For the purposes of FIWLR account mappings, evaluate 1P as if it is the same as 16


CR8762 - Div2G - TP - 2016-11-03
For the purposes of FIWLR account mappings, evaluate 2G as if it is the same as 16

*/
/************************************************************************************************/

/* Retrieve Project Abbreviation Code based on the Project Number recieved from FIW-LR */
	EXEC  @retcode = @proj_sp 
			 @in_status_record_num = @in_status_record_num,
			 @out_systemerror = @out_systemerror  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT
	
	IF @retcode <> 0
		GOTO ErrorProcessing
		
/* Retrieve Project Abbreviation Code, PAG, Org, and acct ID based on the Department Number recieved from FIW-LR */
	--EXEC  @retCode = @org_sp Commented by Clare 2/13/06
	EXEC @retCode = @blank_proj_sp --Added by Clare 2/13/06
			 @in_status_record_num = @in_status_record_num,
			 @out_systemerror = @out_systemerror  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing
		
/* Retrieve Account ID based on the major, minor and sub-minor mapping */	
	EXEC  @retCode = @acct1_sp 
			 @in_status_record_num = @in_status_record_num,
			 @out_systemerror = @out_systemerror  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing

/* Retrieve Account ID based on the major, minor, sub-minor and analysis code mapping */	
	EXEC  @retCode = @acct2_sp 
			 @in_status_record_num = @in_status_record_num,
			 @out_systemerror = @out_systemerror  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing

/*Begin added by Clare 2/13/06 */
/*Apply single acct to all N16 transactions. */
	EXEC  @retCode = @acct3_sp 
			 @in_status_record_num = @in_status_record_num,
			 @out_systemerror = @out_systemerror  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing
/*End added by Clare 2/13/06*/


/* Commented by Clare 2/13/06  */
/* Begin added by Clare 1/25/06   */
/* Update ORG for internal projects/transactions  */	
/*	EXEC  @retCode = @int_org_sp 
			 @in_status_record_num = @in_status_record_num,
			 @out_systemerror = @out_systemerror  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing */
/* End added by Clare 1/25/06*/



--KM 1M changes
--check on proj and org where not null or blank

--CR6295 begin
	UPDATE 	XX_FIWLR_USDET_V3
	SET PROJ_ABBR_CD = '?'+DIVISION+'?',
		PROJ_ID = NULL
	FROM	XX_FIWLR_USDET_V3 FIWLR
	WHERE	LEN(ISNULL(PROJ_ABBR_CD,'')) > 0
	AND		CASE WHEN DIVISION IN ('2G','1P') THEN '16' ELSE DIVISION END <> isnull((select CASE WHEN left(org_id,2) IN ('2G','1P') THEN '16' ELSE left(org_id,2) END from imaps.deltek.proj where proj_abbrv_cd=FIWLR.PROJ_ABBR_CD), '')
	--AND		DIVISION <> dbo.XX_GET_DIV_FOR_PROJ_ABBRV_CD_UF(proj_abbr_cd) - this is too slow


	IF @@ERROR <> 0 GOTO ErrorProcessing

	UPDATE 	XX_FIWLR_USDET_V3
	SET ORG_ABBR_CD = '?'+DIVISION+'?',
		ORG_ID = NULL
	FROM	XX_FIWLR_USDET_V3 FIWLR
	WHERE	LEN(ISNULL(ORG_ABBR_CD,'')) > 0
	AND		CASE WHEN DIVISION IN ('2G','1P') THEN '16' ELSE DIVISION END <> isnull((select CASE WHEN left(org_id,2) IN ('2G','1P') THEN '16' ELSE left(org_id,2) END from imaps.deltek.org where org_abbrv_cd=FIWLR.ORG_ABBR_CD), '')
	--AND DIVISION <> dbo.XX_GET_DIV_FOR_ORG_ABBRV_CD_UF(org_abbr_cd) - this is too slow

	IF @@ERROR <> 0 GOTO ErrorProcessing


	UPDATE 	XX_FIWLR_USDET_V3
	SET ORG_ABBR_CD = '?'+DIVISION+'?',
		ORG_ID = NULL
	FROM	XX_FIWLR_USDET_V3 FIWLR
	WHERE	LEN(ISNULL(ORG_ID,'')) > 0
	AND		CASE WHEN DIVISION IN ('2G','1P') THEN '16' ELSE DIVISION END <> CASE WHEN LEFT(ORG_ID,2) IN ('2G','1P') THEN '16' ELSE LEFT(ORG_ID,2) END
	--AND DIVISION <> dbo.XX_GET_DIV_FOR_ORG_ABBRV_CD_UF(org_abbr_cd) - this is too slow

	IF @@ERROR <> 0 GOTO ErrorProcessing
--CR6295 end

--end 1M changes


RETURN 0
	ErrorProcessing:

RETURN 1

GO


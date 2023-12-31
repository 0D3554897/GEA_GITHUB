USE [IMAPSStg]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_VALID_DATA_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_R22_FIWLR_VALID_DATA_SP]
GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE  PROCEDURE [dbo].[XX_R22_FIWLR_VALID_DATA_SP] (
	@in_status_record_num INT, 
	@out_systemerror INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) =NULL OUTPUT)
AS

DECLARE 

	@retcode		INT,
	@proj_org_sp	VARCHAR(30),
	@acct_sp		VARCHAR(30)
	
/************************************************************************************************/
/* Procedure Name	: XX_R22_FIWLR_VALID_DATA_SP												*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   							*/
/* Description    	: IMAPS FIW-LR Validate Data Procedure										*/
/* Date				: August 10, 2008															*/
/* Notes			: IMAPS FIW-LR Validate Data program will be executed through FIW-LR 		*/
/*					  Run interface program to retrieve the project abbreviation code and		*/
/*					  based on the project number received from FIW-LR. Account mapping is 		*/
/*					  performed to get the account id based on major, minor, subminor and 		*/
/*					  analysis code mapping to the account created in the table					*/
/*					  XX_R22_CLS_IMPAS_ACCT_MAP.												*/
/* Prerequisites	: XX_R22_FIWLR_USDET_V3 & XX_R22_CLS_IMPAS_ACCT_MAP Table(s) should be created	*/
/* Parameter(s)		: 																			*/
/*	Input			: Status Record Number														*/
/*	Output			: Error Code and Error Description											*/
/* Tables Updated	: XX_R22_FIWLR_USDET_V3 													*/
/* Version			: 1.0																		*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  									*/
/* ----------   -------------  	   	------------------------    			  					*/
/* 08-10-2008   Veera Veeramachanane   	Created Initial Version									*/
/************************************************************************************************/

	SELECT	@proj_org_sp  = 'dbo.XX_R22_FIWLR_PROJ_ORG_SP',
			@acct_sp	  =	'dbo.XX_R22_FIWLR_ACCT_SP'

/* Retrieve Project Abbreviation Code based on the Project Number recieved from FIW-LR */
/* Retrieve Project Abbreviation Code, PAG, Org, and acct ID based on the Department Number recieved from FIW-LR */
	EXEC  @retcode = @proj_org_sp 
			 @in_status_record_num = @in_status_record_num,
			 @out_systemerror = @out_systemerror  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT
	
	IF @retcode <> 0
		GOTO ErrorProcessing
		
/* Retrieve Account ID based on the major, minor and sub-minor mapping */	
/* Retrieve Account ID based on the major, minor, sub-minor and analysis code mapping */	
	EXEC  @retCode = @acct_sp 
			 @in_status_record_num = @in_status_record_num,
			 @out_systemerror = @out_systemerror  OUTPUT, 
			 @out_status_description = @out_status_description OUTPUT

	IF @retcode <> 0
		GOTO ErrorProcessing

/*CR2593 
Add code to the FIWLR interface (after the initial pull from FIWLR) to exclude from further processing Research 
source 060, Dept = ZZZ, and Minor = 0195 if the sum of the records with this criteria is 0.  */
delete xx_r22_fiwlr_usdet_v3
from xx_r22_fiwlr_usdet_v3 fiwlr
where 
	source='060'
and source_group='JE'
and minor = '0195'
and department='ZZZ'
and 0 = 
(select sum(amount)
 from xx_r22_fiwlr_usdet_v3
 where status_rec_no=fiwlr.status_rec_no
	and source=fiwlr.source
	and source_group=fiwlr.source_group
	and minor=fiwlr.minor
	and department=fiwlr.department
    and voucher_no=fiwlr.voucher_no
	and division=fiwlr.division
	and major=fiwlr.major)

IF @@ERROR <> 0 GOTO ErrorProcessing


RETURN 0
	ErrorProcessing:

RETURN 1

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


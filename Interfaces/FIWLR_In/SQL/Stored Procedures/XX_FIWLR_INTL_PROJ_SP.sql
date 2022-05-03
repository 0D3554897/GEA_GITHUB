SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_INTL_PROJ_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
   drop procedure [dbo].[XX_FIWLR_INTL_PROJ_SP]
GO


CREATE PROCEDURE [dbo].[XX_FIWLR_INTL_PROJ_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

DECLARE 
	@home_org_id 	VARCHAR(40),
	@proj_abbr_cd 	VARCHAR(10),
	--@wwer_source	VARCHAR(3),  commented by Clare Robbins on 1/31/06
	--@wwer_n16	VARCHAR(3),  commented by Clare Robbins on 1/31/06
	@payroll_source	VARCHAR(3),
	@sp_name 	SYSNAME

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_INTL_PROJ_SP							*/
/* Created By		: Clare Robbins		   		*/
/* Description    	: IMAPS FIW-LR Update for internal projects Procedure					*/
/* Date			: January 25, 2006					        */
/* Notes		: Feature: DEV00000468
			  For WWER transactions for internal projects, set org to home org of employee if div 16 EE.*/
/*			  Leave org null for non div 16 EE. */
/*			  For non WWER transactions with null project, set org using FIWLR department. */
/*			  If account is project required, use project from org UDEF. Otherwise leave the project null. */
/* Prerequisites	: XX_FIWLR_USDET_V3 Table(s) should be created				*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: XX_FIWLR_USDET_V3 							*/
/* Version		: 1.0								*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 1-25-2006   Clare Robbins   		Created Initial Version					*/
/* 1-26-2006   Veera Veeramachanane   	Modified code to derive home org id for the Div 16 EE   */
/*					working on a non-div 16 project.			*/	
/* 1/31/06      Clare Robbins		New logic requirements provided by Naina.  Comment out WWER logic.  */
/*					Always use project owning org, except for payroll transactions.*/
/* 10/4/06      HVT                     Implement CR037                                         */
/* 05/15/2008   HVT                     Ref CP600000322. Multi-company fix (4 instances).       */
/************************************************************************************************/

BEGIN

	SELECT  @sp_name    = 'XX_FIWLR_INTL_PROJ_SP',
		--@wwer_source	= '005',  Commented by Clare Robbins on 1/31/06
		--@wwer_n16	= 'N16', --Added by Veera on 1/26/06 to derive home org_id for N16 expenses, Commented by Clare Robbins on 1/31/06
		@payroll_source = '060'

-- CP600000322_Begin
DECLARE @DIV_16_COMPANY_ID varchar(10)

SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'FIWLR'
-- CP600000322_End

/*Update division 16 employee WWER transactions for internal projects with home org */	
/*	Commented out by Clare Robbins on 1/31/06
	UPDATE f
	SET f.org_id = e.org_id
	FROM dbo.xx_fiwlr_usdet_v3 f left join imaps.deltek.empl_lab_info e
			on f.employee_no=e.empl_id,
		dbo.xx_fiwlr_int_proj_v i
	WHERE f.proj_abbr_cd = i.proj_abbrv_cd
	AND f.employee_no <> ' '
	AND f.source IN (@wwer_source,@wwer_n16)
--	AND f.source = @wwer_source -- Commented out by Veera on 1/26/06
	AND f.wwer_exp_dt between e.effect_dt and e.end_dt
	AND f.status_rec_no = @in_status_record_num

	SELECT @out_systemerror = @@ERROR
			IF @out_systemerror <> 0  
				GOTO ErrorProcessing  */

	--for payroll, set org using fiwlr dept
	UPDATE v
	SET 	v.org_id = o.org_id,
		v.proj_abbr_cd = null,
		v.proj_id = null
	FROM dbo.xx_fiwlr_usdet_v3 v, imaps.deltek.org o
	WHERE v.source = @payroll_source
	AND v.status_rec_no = @in_status_record_num
	AND o.lvl_no = 4
-- CP600000322_Begin
	AND o.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000322_End
	AND SUBSTRING(o.L4_ORG_SEG_ID, 3, 3) = v.department -- CR037

	SELECT @out_systemerror = @@ERROR
			IF @out_systemerror <> 0  
				GOTO ErrorProcessing

	--for transactions with no project, set org using fiwlr dept (may need to exclude if employee no exists)
/* Commented by Clare Robbins on 1/31/06.  Org should be null.  Transaction should go to suspense.

	UPDATE v
	SET 	v.org_id = o.org_id
	FROM dbo.xx_fiwlr_usdet_v3 v, IMAPS.Deltek.ORG o
	WHERE v.status_rec_no = @in_status_record_num
	AND o.lvl_no = 4
	AND SUBSTRING(o.org_id, 11, 3) = v.department
	AND v.project_no is null
	--AND v.proj_abbr_cd is null
	--AND v.proj_id is null

	SELECT @out_systemerror = @@ERROR
			IF @out_systemerror <> 0  
				GOTO ErrorProcessing  */

	/* For transactions with blank project and project required account, update with proj from org udef */
	/* Exclude payroll transactions, which are specifically handled above - CR 1/31/06*/
	UPDATE v
	SET v.proj_abbr_cd = u.udef_txt
	FROM dbo.xx_fiwlr_usdet_v3 v, 
		imaps.deltek.acct a, 
		imaps.deltek.genl_udef u,
		imaps.deltek.udef_lbl l,
		imaps.deltek.org o
	WHERE a.acct_id = v.acct_id
	AND a.proj_reqd_fl = 'Y'
	AND v.source <> @payroll_source  -- Added by Clare Robbins on 1/31/06
	AND v.proj_abbr_cd is null
	AND v.org_id = o.org_id
	AND o.lvl_no = 4
	AND o.org_id = u.genl_id
	AND u.s_table_id = l.s_table_id 
	AND u.udef_lbl_key = l.udef_lbl_key
	AND u.udef_lbl_key = 6
	AND u.s_table_id = 'ORG'
-- CP600000322_Begin
	AND u.COMPANY_ID = @DIV_16_COMPANY_ID
	AND l.COMPANY_ID = @DIV_16_COMPANY_ID
	AND o.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000322_End

	SELECT @out_systemerror = @@ERROR
			IF @out_systemerror <> 0  
				GOTO ErrorProcessing

RETURN 0

ErrorProcessing:
	
		EXEC dbo.XX_ERROR_MSG_DETAIL
	         		@in_error_code           = 204,
	         		@in_sqlserver_error_code = @out_systemerror,
	         		@in_display_requested    = 1,
				@in_placeholder_value1   = 'update',
		   		@in_placeholder_value2   = 'XX_FIWLR_USDET_V3',
	         		@in_calling_object_name  = @sp_name,
	         		@out_msg_text            = @out_status_description OUTPUT

RETURN 1

END

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

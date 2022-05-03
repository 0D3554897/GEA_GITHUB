USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_FIWLR_BLANK_PROJ_SP]    Script Date: 11/15/2016 11:40:33 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_FIWLR_BLANK_PROJ_SP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[XX_FIWLR_BLANK_PROJ_SP]
GO

USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_FIWLR_BLANK_PROJ_SP]    Script Date: 11/15/2016 11:40:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO



CREATE PROCEDURE [dbo].[XX_FIWLR_BLANK_PROJ_SP]  (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

DECLARE 
	@wwer_source	VARCHAR(3),
	@wwer_n16	VARCHAR(3),
	@sp_name 	SYSNAME

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_BLANK_PROJ_SP							*/
/* Created By		: Clare Robbins		   		*/
/* Description    	: IMAPS FIW-LR Update for transactiosn with blank projects Procedure					*/
/* Date			: February 13, 2006					        */
/* Notes		: Defect DEV00000390.  Also related to Feature DEV00000493.  Changes for Defect 390 superceed changes for 493.				*/
/*			  For non WWER transactions with null project, determine if major and minor map to project required acct.   */
/*			  (If there is a PAG, the account is project required)			*/
/*			  If account is project required, use project from org UDEF and leave the org null.  Preprocessor will pick up owning  */
/*			  org of the project.  */
/*			  If account is not project required, pass org ID mapped from department and set proj abbrev to null.  */
/*			  WWER transactions with blank project should go to suspense.  Don't try to default in data.*/
/* Prerequisites	: XX_FIWLR_USDET_V3 Table(s) should be created				*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: XX_FIWLR_USDET_V3 							*/
/* Version		: 1.0									*/
/************************************************************************************************/
/* Date		Modified By	Description of change			  			*/
/* ----------   -------------  	------------------------    			  		*/
/* 2-13-2006    Clare Robbins   Created Initial Version						*/
/* 10/4/06      HVT             Implement CR037                                         	*/
/* 05/15/2008   HVT             Ref CP600000322 (CR1543) - Multi-company fix (5 instances).     */
/* 03/05/2009   KM				Implement DR1958                                        */
/*
	Date		Modified By		Description of change	
   ----------   -------------	------------------------ 
   2010-09-13	KM				1M changes  Division added to account mapping

CR6295 - Div1P - KM - 2013-04-29
For the purposes of FIWLR account mappings, evaluate 1P as if it is the same as 16

CR6640 - FIWLR transactions containing ETV code needs correct CP account - KM - 2013-09-26
source 060 payroll ETV code account mapping logic
CR6640 - FIWLR transactions containing ETV code needs correct CP account - KM - 2014-02-14
change to make project required take precedence
CR8762 - Div2G - TP - 2016-11-03
For the purposes of FIWLR account mappings, evaluate 2G as if it is the same as 16
*/
/************************************************************************************************/

BEGIN

	SELECT  @sp_name    = 'XX_FIWLR_BLANK_PROJ_SP',
		@wwer_source	= '005',  
		@wwer_n16	= 'N16'

-- CP600000322_Begin
	DECLARE @DIV_16_COMPANY_ID varchar(10)

	SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
	  FROM dbo.XX_PROCESSING_PARAMETERS
	 WHERE PARAMETER_NAME = 'COMPANY_ID'
	   AND INTERFACE_NAME_CD = 'FIWLR'
-- CP600000322_End

--For project required
	UPDATE xx_fiwlr_usdet_v3
	set reference2=a.udef_txt,
		reference3=(select acct_grp_cd from imaps.deltek.proj where proj_abbrv_cd<>'' and proj_abbrv_cd = a.udef_txt)
	FROM
			dbo.xx_fiwlr_usdet_v3 b	
	inner join
		imaps.deltek.org c
	on
	(
		b.status_rec_no = @in_status_record_num 
		AND	b.source NOT IN (@wwer_source,@wwer_n16) 
		AND	len(rtrim(ltrim(b.project_no))) = 0
		AND	len(rtrim(ltrim(b.department))) > 0
		AND		LEFT(c.ORG_ABBRV_CD,3) = isnull(b.department,'')
		AND 	c.lvl_no = 4		
		AND 	c.COMPANY_ID = @DIV_16_COMPANY_ID
	)
	inner join		
		imaps.deltek.genl_udef a
	on
	(
		a.s_table_id = 'ORG'
		and		a.udef_lbl_key = 6
		AND 	a.genl_id = c.org_id
		AND 	a.COMPANY_ID = @DIV_16_COMPANY_ID
	)


	SELECT @out_systemerror = @@ERROR
			IF @out_systemerror <> 0  
				GOTO ErrorProcessing




--For non-project required

UPDATE b
	SET b.org_id = c.org_id,
		b.org_abbr_cd = c.org_abbrv_cd, 
		b.acct_id = m.acct_id
	FROM 	
		dbo.xx_fiwlr_usdet_v3 b
	inner join
		imaps.deltek.org c
	on
	(
		b.status_rec_no = @in_status_record_num 
		AND	len(rtrim(ltrim(b.project_no))) = 0
		AND	len(rtrim(ltrim(b.department))) > 0
		AND	b.source NOT IN (@wwer_source,@wwer_n16) 
		AND 	c.lvl_no = 4
		AND	LEFT(c.ORG_ABBRV_CD,3) = b.department
	)
	inner join
		dbo.xx_cls_imaps_acct_map m
	on
	(	
		--CR6295,CR8762
		CASE WHEN  b.division IN ('2G','1P') THEN '16' ELSE  b.division END = m.division
		AND	b.major	>= m.major_1 
		AND b.major	<= m.major_2 
		AND	b.minor	>= m.minor_1 
		AND	b.minor 	<= m.minor_2 
		AND	b.subminor 	>= (CASE  	WHEN m.sub_minor_1 = '****' 	THEN b.subminor
						  	WHEN m.sub_minor_1 = ' ' 	THEN b.subminor
						  	ELSE m.sub_minor_1 
					   END )
		AND	b.subminor 	<= (CASE  	WHEN m.sub_minor_2 = '****' 	THEN b.subminor
						  	WHEN m.sub_minor_2 = ' ' 	THEN b.subminor
						  	ELSE m.sub_minor_2 
					   END)
		AND len(rtrim(ltrim(isnull(m.pag,'')))) = 0		
		--CR6640
		and len(rtrim(ltrim(isnull(m.analysis_cd,''))))=0
	)

		
	SELECT @out_systemerror = @@ERROR
			IF @out_systemerror <> 0  
				GOTO ErrorProcessing





	--2014-02-14
	--moved this to be after the org update and to make org_id and org_abbr_cd null (to default to owning org of project)
	UPDATE b
	SET 	b.proj_abbr_cd = b.reference2,
    		b.pag_cd = b.reference3,
    		b.acct_id = m.acct_id,
			b.org_id=null,
			b.org_abbr_cd=null
	FROM 
		dbo.xx_fiwlr_usdet_v3 b	,
		dbo.xx_cls_imaps_acct_map m
	where
	(	
		--CR6295,CR8762
		CASE WHEN  b.division IN ('2G','1P') THEN '16' ELSE  b.division END = m.division
		AND	b.major	>= m.major_1 
		AND b.major	<= m.major_2 
		AND	b.minor	>= m.minor_1 
		AND	b.minor <= m.minor_2 
		AND	b.subminor 	>= (CASE  	WHEN m.sub_minor_1 = '****' 	THEN b.subminor
						  	WHEN m.sub_minor_1 = ' ' 	THEN b.subminor 
						  	ELSE m.sub_minor_1 
					   END )
		AND	b.subminor 	<= (CASE  	WHEN m.sub_minor_2 = '****' 	THEN b.subminor
						  	WHEN m.sub_minor_2 = ' ' 	THEN b.subminor
						  	ELSE m.sub_minor_2 
					   END)
		AND len(rtrim(ltrim(isnull(m.pag,'')))) <> 0
		AND	m.pag = isnull(b.reference3,'')
		--CR6640
		and 
		( len(rtrim(ltrim(isnull(m.analysis_cd,''))))=0
			or
		 (b.source='060' and m.analysis_cd=b.etv_code)
		)
	)


	SELECT @out_systemerror = @@ERROR
			IF @out_systemerror <> 0  
				GOTO ErrorProcessing


	update xx_fiwlr_usdet_v3
	set reference2=null,reference3=null

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


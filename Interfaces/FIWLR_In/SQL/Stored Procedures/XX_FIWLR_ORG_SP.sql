
use imapsstg


SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_ORG_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_ORG_SP]
GO

CREATE PROCEDURE [dbo].[XX_FIWLR_ORG_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

DECLARE 
	@org_dept_cd 	VARCHAR(10),
	@proj_pag_cd 	VARCHAR(10),
	@fiwlr_dept_cd 	VARCHAR(10),
	@org_org_id 	VARCHAR(40),
	@proj_proj_id 	VARCHAR(40),
	@proj_abbr_cd 	VARCHAR(10),
	@source		VARCHAR(3),
	@sourcewwern16	VARCHAR(3), -- Added by Veera on 12/22/2005 Defect: DEV00000390 
	@stable_id	SYSNAME,
	@sp_name 	SYSNAME

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_ORG_SP							*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR Organization Procedure					*/
/* Date			: October 22, 2005						        */
/* Notes		: IMAPS FIW-LR Organization program will retrieve the assigned default	*/
/*			  project abbreviation code based on the department.			*/
/* Prerequisites	: XX_FIWLR_USDET_V3 Table(s) should be created				*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: XX_FIWLR_USDET_V3 							*/
/* Version		: 1.1									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 10-22-2005   Veera Veeramachanane   	Created Initial Version					*/
/* 12-22-2005   Veera Veeramachanane   	Modified code to derive project abbreviation code for 	*/
/*					individual particular run. Defect: DEV00000390		*/
/* 10/4/06      HVT                     Implement CR037                                         */
/* 05/15/2008   HVT                     Ref CP600000322. Multi-company fix (5 instances).       */
/* 03/05/2009   KM						Implement DR1958                                        */
/************************************************************************************************/

BEGIN

	SELECT  @sp_name    = 'XX_FIWLR_ORG_SP',
		@stable_id  = 'ORG',
		@source	    = '005',
		@sourcewwern16 = 'N16'

-- CP600000322_Begin
DECLARE @DIV_16_COMPANY_ID varchar(10)

SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'FIWLR'
-- CP600000322_End

/* Cursor to group by each department Number */		
	DECLARE xx_fiwlr_orgv CURSOR FOR

		SELECT	DISTINCT 
			SUBSTRING(c.L4_ORG_SEG_ID, 3, 3) org_dept_cd, -- CR037
			d.acct_grp_cd, b.department, c.org_id, d.proj_id,
			d.proj_abbrv_cd 
		FROM 	imaps.deltek.genl_udef a, 
			dbo.xx_fiwlr_usdet_v3 b, 
			imaps.deltek.org c,
			imaps.deltek.udef_lbl u, 
			imaps.deltek.proj d
		WHERE	a.s_table_id = @stable_id
		AND 	d.proj_abbrv_cd = a.udef_txt
		AND	b.status_rec_no = @in_status_record_num -- Added by Veera on 12/22/2005 Defect: DEV00000390
		--AND   d.org_id = c.org_id
		AND 	a.s_table_id = u.s_table_id 
		AND 	a.udef_lbl_key = u.udef_lbl_key
		AND 	a.udef_lbl_key = 6
		AND 	c.lvl_no = 4
		AND	b.project_no = ' '
		AND	b.department <> ' '
--		AND	b.source <> @source
		AND	b.source NOT IN (@source,@sourcewwern16) -- Added by Veera on 12/22/2005 Defect: DEV00000390
		AND 	SUBSTRING(genl_id, 12, 3) = b.department -- CR037
		AND 	a.genl_id = c.org_id
		--AND 	SUBSTRING(c.L4_ORG_SEG_ID, 3, 3)= b.department -- CR037
		--DR1958 
		AND		LEFT(c.ORG_ABBRV_CD,3)=b.department
-- CP600000322_Begin
		AND 	a.COMPANY_ID = @DIV_16_COMPANY_ID
		AND 	c.COMPANY_ID = @DIV_16_COMPANY_ID
		AND 	u.COMPANY_ID = @DIV_16_COMPANY_ID
		AND 	d.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000322_End

/* Retrieve and Update Project Abbreviation Code based on the Department Number recieved from FIW-LR */
	OPEN xx_fiwlr_orgv
	FETCH NEXT FROM  xx_fiwlr_orgv INTO @org_dept_cd, @proj_pag_cd, @fiwlr_dept_cd, @org_org_id, @proj_proj_id, @proj_abbr_cd

	WHILE (@@fetch_status = 0)
		BEGIN
			-- for each department derive org id and project abbreviation code 
			UPDATE 	v
			SET 	proj_abbr_cd = @proj_abbr_cd,
		--		org_abbr_cd =  @org_org_id,
				pag_cd =  @proj_pag_cd
			FROM 	dbo.xx_fiwlr_usdet_v3 v, 
				imaps.deltek.org a
			WHERE 	--DR1958 
				LEFT(a.ORG_ABBRV_CD,3)=v.department
--SUBSTRING(a.L4_ORG_SEG_ID, 3, 3) = v.department -- CR037

-- CP600000322_Begin
			AND 	a.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000322_End
			AND	v.project_no = ' '
			AND	v.status_rec_no = @in_status_record_num -- Added by Veera on 12/22/2005 Defect: DEV00000390
			AND	v.department <> ' '
--		AND	v.source <> @source
		AND	v.source NOT IN (@source, @sourcewwern16) -- Added by Veera on 12/22/2005 Defect: DEV00000390
		AND	v.department = @org_dept_cd

			SELECT @out_systemerror = @@ERROR
			IF @out_systemerror <> 0  
				GOTO ErrorProcessing	
	
	FETCH NEXT FROM  xx_fiwlr_orgv INTO @org_dept_cd, @proj_pag_cd, @fiwlr_dept_cd, @org_org_id, @proj_proj_id, @proj_abbr_cd

	END

	CLOSE xx_fiwlr_orgv
	DEALLOCATE xx_fiwlr_orgv


RETURN 0
ErrorProcessing:
	CLOSE xx_fiwlr_orgv
	DEALLOCATE xx_fiwlr_orgv

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


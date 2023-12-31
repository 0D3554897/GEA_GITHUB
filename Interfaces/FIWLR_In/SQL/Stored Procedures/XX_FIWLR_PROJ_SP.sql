SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_PROJ_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_PROJ_SP]
GO

CREATE PROCEDURE [dbo].[XX_FIWLR_PROJ_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

DECLARE 
	@fiwlr_proj_no 	VARCHAR(10),
	@proj_proj_cd 	VARCHAR(10),
	@proj_pag_cd 	VARCHAR(40),
	@proj_proj_id 	VARCHAR(10),
	@proj_org_id 	VARCHAR(40),
	@sp_name	SYSNAME

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_PROJ_SP							*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR Project Procedure					*/
/* Date			: October 22, 2005						        */
/* Notes		: IMAPS FIW-LR Project program will retrieve the project abbreviation	*/
/*			  code based on the project number received along with the transactions */
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
/* 05/15/2008   HVT                     Ref CP600000322. Multi-company fix (2 instances).       */
/************************************************************************************************/

BEGIN

	SELECT	@sp_name = 'XX_FIWLR_PROJ_SP'

-- CP600000322_Begin
DECLARE @DIV_16_COMPANY_ID varchar(10)

SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'FIWLR'
-- CP600000322_End

/* Cursor to group by each Project Number */		
	DECLARE xx_fiwlr_projv CURSOR FOR
	
		SELECT DISTINCT v.project_no, a.proj_abbrv_cd, a.proj_id, a.org_id, a.acct_grp_cd
		FROM 	dbo.xx_fiwlr_usdet_v3 v,
			IMAPS.Deltek.PROJ a
		WHERE 	v.project_no = a.proj_abbrv_cd
		AND	v.project_no <> ' '
		AND	v.status_rec_no = @in_status_record_num -- Added by Veera on 12/22/2005 Defect: DEV00000390
-- CP600000322_Begin
		AND	a.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000322_End

	OPEN xx_fiwlr_projv
	FETCH NEXT FROM  xx_fiwlr_projv INTO @fiwlr_proj_no, @proj_proj_cd, @proj_proj_id, @proj_org_id, @proj_pag_cd

	WHILE (@@fetch_status = 0)
		BEGIN
		-- for each project number 
/* Retrieve and Update Project Abbreviation Code based on the Project Number recieved from FIW-LR */
			UPDATE 	v
			SET 	proj_abbr_cd = @proj_proj_cd,
				pag_cd = @proj_pag_cd
			FROM 	dbo.xx_fiwlr_usdet_v3 v,
				IMAPS.Deltek.PROJ a
			WHERE 	v.project_no = a.proj_abbrv_cd
			AND	v.project_no <> ' '
			AND	v.project_no = @proj_proj_cd
			AND	v.status_rec_no = @in_status_record_num -- Added by Veera on 12/22/2005 Defect: DEV00000390
-- CP600000322_Begin
			AND	a.COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000322_End

		SELECT @out_systemerror = @@ERROR 
			IF @out_systemerror <> 0 
					GOTO ErrorProcessing
	
	FETCH NEXT FROM  xx_fiwlr_projv INTO @fiwlr_proj_no, @proj_proj_cd, @proj_proj_id, @proj_org_id, @proj_pag_cd
	END

	CLOSE xx_fiwlr_projv
	DEALLOCATE xx_fiwlr_projv

RETURN 0

ErrorProcessing:

	CLOSE xx_fiwlr_projv
	DEALLOCATE xx_fiwlr_projv

		EXEC dbo.xx_error_msg_detail
	         		@in_error_code           = 204,
	         		@in_sqlserver_error_code = @out_systemerror,
	         		@in_display_requested    = 1,
				@in_placeholder_value1   = 'update',
		   		@in_placeholder_value2   = 'XX_FIWLR_USDET_v3',
	         		@in_calling_object_name  = @sp_name,
	         		@out_msg_text            = @out_status_description OUTPUT

RETURN(1)

END

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


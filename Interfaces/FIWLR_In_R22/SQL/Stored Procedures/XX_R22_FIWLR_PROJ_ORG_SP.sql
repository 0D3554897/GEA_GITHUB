use imapsstg

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_PROJ_ORG_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_R22_FIWLR_PROJ_ORG_SP]
GO

USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[XX_R22_FIWLR_PROJ_ORG_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

DECLARE 
	@fiwlr_proj_no 		VARCHAR(10),
	@proj_proj_cd 		VARCHAR(10),
	@proj_pag_cd 		VARCHAR(40),
	@proj_proj_id 		VARCHAR(10),
	@proj_org_id 		VARCHAR(40),
	@wwer_source		VARCHAR(3),
	@bond_source		VARCHAR(3),
	@numberofrecords 	INT,
	@error_type			INT,
	@error_code			INT,
	@error_msg_placeholder1	SYSNAME,
	@error_msg_placeholder2 SYSNAME,
	@sp_name			SYSNAME,
	@div_22_company_id 	varchar(10)

/************************************************************************************************/
/* Procedure Name	: XX_R22_FIWLR_PROJ_ORG_SP							*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR Project Procedure					*/
/* Date			: August 10, 2008						        */
/* Notes		: IMAPS FIW-LR Project program will retrieve the project abbreviation	*/
/*			  code based on the project number received along with the transactions */
/* Prerequisites	: XX_R22_FIWLR_USDET_V3 Table(s) should be created			*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: XX_R22_FIWLR_USDET_V3 						*/
/* Version		: 1.0									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 08-10-2008   Veera Veeramachanane   	Created Initial Version					*/
/* 04-03-2012   KM					   	CR4663													*/
/* 04-17-2015  TP    CR7905 Adding new top level division                                               */
/************************************************************************************************/

BEGIN

	SELECT	@sp_name 	= 'XX_R22_FIWLR_PROJ_ORG_SP',
			@error_msg_placeholder1	= NULL,
			@error_msg_placeholder2 = NULL,
			@wwer_source 	= '005',
			@bond_source	= '072'


	SELECT	@div_22_company_id = parameter_value
  	FROM	dbo.xx_processing_parameters
 	WHERE	parameter_name= 'COMPANY_ID'
   	AND	interface_name_cd = 'FIWLR_R22'


/*
FIWLR Research requirements
*/


/*
11.	To determine the appropriate project for any type of transaction (including WWER), use the following logic:
If IGS Project is valid, use the IGS Project provided. 
If the IGS Project is not valid, and Leru exists in mapping table, then use project in the Leru mapping table.
Otherwise, use the department/org provided on the transaction to find Org Project UDEF.  The department can be mapped to the last 3 characters of level 5 of the org.
*/

--if IGS project works
	UPDATE	XX_R22_FIWLR_USDET_V3
	SET	PROJ_ABBR_CD = LTRIM(RTRIM(PROJECT_NO))
	FROM	XX_R22_FIWLR_USDET_V3 fiwlr
	WHERE	
	0 <> (SELECT COUNT(1)
		  FROM IMAR.DELTEK.PROJ
		  WHERE 
		  COMPANY_ID = @div_22_company_id
		  AND PROJ_ABBRV_CD <> ''
		  AND PROJ_ABBRV_CD = RTRIM(LTRIM(isnull(PROJECT_NO,'')))
		 )
	AND 	status_rec_no = @in_status_record_num

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
			BEGIN
				SET @error_type = 6
				GOTO ErrorProcessing
			END

--if LERU works
	UPDATE	XX_R22_FIWLR_USDET_V3
	SET	PROJ_ABBR_CD = leru.PROJ_ABBRV_CD
	FROM	XX_R22_FIWLR_USDET_V3 fiwlr 
	INNER JOIN
		XX_R22_FIWLR_LERU_MAP leru
	ON
	(
		fiwlr.DEPARTMENT + fiwlr.PROJ = leru.LERU
	)
	WHERE	PROJ_ABBR_CD IS NULL
	AND 	status_rec_no = @in_status_record_num

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
			BEGIN
				SET @error_type = 7
				GOTO ErrorProcessing
			END

--Otherwise, use the department/org provided on the transaction to find Org Project UDEF.
	UPDATE	XX_R22_FIWLR_USDET_V3
	SET		PROJ_ABBR_CD = (SELECT	g.UDEF_TXT
				FROM	IMAR.DELTEK.GENL_UDEF g
				INNER JOIN
						IMAR.DELTEK.ORG org
				ON
					(	g.COMPANY_ID=@DIV_22_COMPANY_ID   
						and
						g.S_TABLE_ID='ORG'
						and
						g.UDEF_LBL_KEY=50
						and
						g.GENL_ID = org.ORG_ID
						and
						org.ORG_ABBRV_CD=fiwlr.DEPARTMENT
						and ((fiwlr.DIVISION = '24' and org.L1_ORG_SEG_ID = '24')  --CR7905
				                    OR fiwlr.DIVISION <> '24' and org.L1_ORG_SEG_ID = '22')
						)
					)
	FROM	XX_R22_FIWLR_USDET_V3 fiwlr
	WHERE	PROJ_ABBR_CD IS NULL
	AND		DEPARTMENT<>'' --added during CR4663 testing
	AND 	status_rec_no = @in_status_record_num
	--CR 817 requires a project
	AND		MAJOR <> '817'

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
			BEGIN
				SET @error_type = 8
				GOTO ErrorProcessing
			END

--update PAG
	UPDATE	XX_R22_FIWLR_USDET_V3
	SET	PAG_CD = (	SELECT	ACCT_GRP_CD 
					FROM	IMAR.DELTEK.PROJ 
					WHERE	COMPANY_ID=@DIV_22_COMPANY_ID 
					AND		PROJ_ABBRV_CD <> '' 
					AND		PROJ_ABBRV_CD = fiwlr.PROJ_ABBR_CD)
	FROM	XX_R22_FIWLR_USDET_V3 fiwlr
	--AND 	fiwlr.status_rec_no = @in_status_record_num

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
			BEGIN
				SET @error_type = 9
				GOTO ErrorProcessing
			END



/*
1.	Use the following logic to determine the Org to be used on a transaction within Costpoint.

For WWER (Source 005):
	If IGS project is null populate the Org field with the org for the department in the record. (This will take care of regular default accounting and special account coding the expense account to another Research department. It should also handle expenses charged to a Research department by someone in another division when the serial number would miscode.)
	If IGS project is not null, populate the Org field of the transaction with the employee's home org. (This will take care of the travel charged to a government project where the charges should be recorded in the performing org.)

For BOND (Source 072), use the Project owning Org of the project provided on the transaction.  
For all other sources, use the department provided on the transaction to map to the appropriate Org related to the department.
Always post to level 5 of the org.  The 3 character (or 1st 3 characters) department should equate to the last 3 characters of level 5 of the Org.
*/

--005 org  --assuming that we got the Costpoint EMPL_ID into REFERENCE5,and then do the following
	UPDATE	XX_R22_FIWLR_USDET_V3
	SET	ORG_ID = (	SELECT	ORG_ID FROM IMAR.DELTEK.EMPL_LAB_INFO 
				WHERE	EMPL_ID = REFERENCE5
				AND	WWER_EXP_DT BETWEEN EFFECT_DT AND END_DT
				AND ((fiwlr.DIVISION = '24' and LEFT(ORG_ID,2) = '24')  --CR7905
				     OR fiwlr.DIVISION <> '24' and LEFT(ORG_ID,2) = '22')
				  )
	FROM	XX_R22_FIWLR_USDET_V3 fiwlr
	WHERE	SOURCE = @wwer_source
	AND 	status_rec_no = @in_status_record_num
	AND		len(isnull(project_no, ''))>0 


	UPDATE	XX_R22_FIWLR_USDET_V3
	SET	ORG_ABBR_CD = (	SELECT	ORG_ABBRV_CD 
				FROM	IMAR.DELTEK.ORG 
				WHERE	COMPANY_ID=@DIV_22_COMPANY_ID 
				AND	ORG_ID = fiwlr.ORG_ID)
	FROM	XX_R22_FIWLR_USDET_V3 fiwlr
	WHERE	SOURCE = @wwer_source
	AND 	status_rec_no = @in_status_record_num
	AND		len(isnull(project_no, ''))>0 

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
			BEGIN
				SET @error_type = 1
				GOTO ErrorProcessing
			END

	UPDATE	XX_R22_FIWLR_USDET_V3
	SET		REFERENCE5=NULL

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
			BEGIN
				SET @error_type = 1
				GOTO ErrorProcessing
			END


	UPDATE	XX_R22_FIWLR_USDET_V3
	SET	ORG_ABBR_CD = DEPARTMENT,
	ORG_ID	=	(	SELECT	ORG_ID 
				FROM	IMAR.DELTEK.ORG 
				WHERE	COMPANY_ID=@DIV_22_COMPANY_ID 
				AND ORG_ABBRV_CD <> ''
				AND	ORG_ABBRV_CD = fiwlr.DEPARTMENT
				AND ((fiwlr.DIVISION = '24' and ORG.L1_ORG_SEG_ID = '24')    --CR7905
				OR fiwlr.DIVISION <> '24'and ORG.L1_ORG_SEG_ID = '22')
				)
	FROM	XX_R22_FIWLR_USDET_V3 fiwlr
	WHERE	SOURCE = @wwer_source
	AND 	status_rec_no = @in_status_record_num
	AND		len(isnull(project_no, ''))=0

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
			BEGIN
				SET @error_type = 2
				GOTO ErrorProcessing
			END




--072 org   CR1912 - stop treating BOND 072 as special
/*
	UPDATE XX_R22_FIWLR_USDET_V3
	SET	ORG_ID = (	SELECT	ORG_ID FROM IMAR.DELTEK.PROJ 
				WHERE	COMPANY_ID=@DIV_22_COMPANY_ID 
				AND	PROJ_ABBRV_CD <> '' 
				AND	PROJ_ABBRV_CD = fiwlr.PROJ_ABBR_CD)
	FROM XX_R22_FIWLR_USDET_V3 fiwlr
	WHERE SOURCE = @bond_source
	AND 	status_rec_no = @in_status_record_num

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
			BEGIN
				SET @error_type = 3
				GOTO ErrorProcessing
			END

	UPDATE	XX_R22_FIWLR_USDET_V3
	SET	ORG_ABBR_CD = (	SELECT	ORG_ABBRV_CD 
				FROM	IMAR.DELTEK.ORG 
				WHERE	COMPANY_ID=@DIV_22_COMPANY_ID 
				AND	ORG_ID = fiwlr.ORG_ID	)
	FROM	XX_R22_FIWLR_USDET_V3 fiwlr
	WHERE	SOURCE = @bond_source
	AND 	status_rec_no = @in_status_record_num

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
			BEGIN
				SET @error_type = 4
				GOTO ErrorProcessing
			END
*/

	--all other org
	UPDATE	XX_R22_FIWLR_USDET_V3
	SET	ORG_ABBR_CD = DEPARTMENT,
	ORG_ID	=	(	SELECT	ORG_ID 
				FROM	IMAR.DELTEK.ORG 
				WHERE	COMPANY_ID=@DIV_22_COMPANY_ID 
				AND ORG_ABBRV_CD <> ''
				AND	ORG_ABBRV_CD = fiwlr.DEPARTMENT
				AND ((fiwlr.DIVISION = '24' and ORG.L1_ORG_SEG_ID = '24')  --CR7905
				OR fiwlr.DIVISION <> '24'and ORG.L1_ORG_SEG_ID = '22')
				)
	FROM	XX_R22_FIWLR_USDET_V3 fiwlr
	WHERE	SOURCE NOT IN (@wwer_source /*, @bond_source*/)
	AND 	status_rec_no = @in_status_record_num

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
			BEGIN
				SET @error_type = 5
				GOTO ErrorProcessing
			END


	--CR use high level org for certain majors

	--CR4663
	/*
	UPDATE	XX_R22_FIWLR_USDET_V3
	SET	ORG_ABBR_CD = '22.W',
		ORG_ID	=	'22.W'
	FROM	XX_R22_FIWLR_USDET_V3 fiwlr
	WHERE	SOURCE NOT IN (@wwer_source, @bond_source)
	AND 	status_rec_no = @in_status_record_num
	AND		LEFT(MAJOR,1)='5'
	*/
	--CR4663 ORG_ID update
	UPDATE XX_R22_FIWLR_USDET_V3
	SET ORG_ID=(select parameter_value from xx_processing_parameters where interface_name_cd='FIWLR_R22' and parameter_name=fiw.DIVISION+'_ORG_ID_default'),
		ORG_ABBR_CD=(select parameter_value from xx_processing_parameters where interface_name_cd='FIWLR_R22' and parameter_name=fiw.DIVISION+'_ORG_ABBRV_CD_default')
	FROM XX_R22_FIWLR_USDET_V3 fiw
	WHERE	SOURCE NOT IN (@wwer_source, @bond_source)
	AND 	status_rec_no = @in_status_record_num
	AND		LEFT(MAJOR,1)='5' and DIVISION <> '24'  --CR7905

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
			BEGIN
				SET @error_type = 10
				GOTO ErrorProcessing
			END

	
	
	--Everything from Zurich goes to top-level org
	UPDATE	XX_R22_FIWLR_USDET_V3
	SET	ORG_ABBR_CD = '22.Z',
		ORG_ID	=	'22.Z'
	FROM	XX_R22_FIWLR_USDET_V3 fiwlr
	WHERE	DIVISION='YB'

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
			BEGIN
				SET @error_type = 10
				GOTO ErrorProcessing
			END


RETURN 0

ErrorProcessing:

	IF @error_type = 1
   		BEGIN
      			SET @error_code = 204 -- Attempt to retrieve ORG_ID for WWER Source and update XX_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'a record into table XX_FIWLR_USDET_V3 (1)'
   		END  

	ELSE IF @error_type = 2
   		BEGIN
      			SET @error_code = 204 -- Attempt to retrieve ORG_ABBRV_CD for WWER Source and update XX_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'a record into table XX_R22_FIWLR_USDET_V3 (2)'
   		END
	ELSE IF @error_type = 3
   		BEGIN
      			SET @error_code = 204 -- Attempt to retrieve ORG_ID for BOND Source and update XX_FIWLR_USDET_V3 table failed.
			SET @error_msg_placeholder1 = 'update'
			SET @error_msg_placeholder2 = 'a record into table XX_R22_FIWLR_USDET_V3 (3)'
   		END
	ELSE IF @error_type = 4
   		BEGIN
      			SET @error_code = 204 -- Attempt to retrieve ORG_ABBRV_CD for BOND Source and update XX_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'a record into table XX_R22_FIWLR_USDET_V3 (4)'
   		END
	ELSE IF @error_type = 5
   		BEGIN
      			SET @error_code = 204 -- Attempt to retrieve ORG_BBRV_CD for all Source(s) and update XX_FIWLR_USDET_V3 table failed.
			SET @error_msg_placeholder1 = 'update'
			SET @error_msg_placeholder2 = 'a record into table XX_R22_FIWLR_USDET_V3 (5)'
   		END
	ELSE IF @error_type = 6
   		BEGIN
      			SET @error_code = 204 -- Attempt to retrieve PROJ_BBRV_CD if IGS Project is available and update XX_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'a record into table XX_R22_FIWLR_USDET_V3 (6)'
   		END
	ELSE IF @error_type = 7
   		BEGIN
      			SET @error_code = 204 -- Attempt to retrieve PROJ_BBRV_CD based on LERU if IGS Project is not available and update XX_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'a record into table XX_R22_FIWLR_USDET_V3 (7)'
   		END
	ELSE IF @error_type = 8
   		BEGIN
      			SET @error_code = 204 -- Attempt to retrieve PROJ_BBRV_CD based on Department/ORG if IGS Project and LERU not available and update XX_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'a record into table XX_R22_FIWLR_USDET_V3 (8)'
   		END
	ELSE IF @error_type = 9
   		BEGIN
      			SET @error_code = 204 -- Attempt to retrieve PAG based on PROJ_BBRV_CD and update XX_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'a record into table XX_R22_FIWLR_USDET_V3 (9)'
   		END
	--CR4663
	ELSE IF @error_type = 10
   		BEGIN
      			SET @error_code = 204 -- Attempt to retrieve PAG based on PROJ_BBRV_CD and update XX_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'a record into table XX_R22_FIWLR_USDET_V3 for CR4663 (10)'
   		END

		EXEC dbo.xx_error_msg_detail
	         		@in_error_code           = 204,
	         		@in_sqlserver_error_code = @out_systemerror,
	         		@in_display_requested    = 1,
				@in_placeholder_value1   = @error_msg_placeholder1, --'update',
		   		@in_placeholder_value2   = @error_msg_placeholder2, --'XX_R22_FIWLR_USDET_v3',
	         		@in_calling_object_name  = @sp_name,
	         		@out_msg_text            = @out_status_description OUTPUT

RETURN(1)

END





GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


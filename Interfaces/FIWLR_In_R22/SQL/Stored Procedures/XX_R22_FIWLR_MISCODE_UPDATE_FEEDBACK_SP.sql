USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_MISCODE_UPDATE_FEEDBACK_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_R22_FIWLR_MISCODE_UPDATE_FEEDBACK_SP]
GO


/****** Object:  StoredProcedure [dbo].[XX_R22_FIWLR_MISCODE_UPDATE_FEEDBACK_SP]    Script Date: 10/20/2008 16:42:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[XX_R22_FIWLR_MISCODE_UPDATE_FEEDBACK_SP] (
@out_STATUS_DESCRIPTION sysname = NULL
)

AS

/************************************************************************************************/
/* Procedure Name	: XX_R22_FIWLR_MISCODE_UPDATE_FEEDBACK_SP  									*/
/* Created By		: Keith Mcguire													   			*/
/* Description    	: IMAPS FIW-LR Micode Update Feedback										*/
/* Date				: August 10, 2008					        								*/
/* Notes			: UPDATE MISCODE TABLE FOR NULL VALUES AND FEEDBACK							*/
/* Prerequisites	: XX_R22_FIWLR_USDET_MISCODES Table(s) should be created					*/
/* Parameter(s)		: 																			*/
/*	Input			: Status Record Number														*/	
/*	Output			: Error Code and Error Description											*/
/* Tables Updated	: XX_R22_FIWLR_USDET_MISCODES												*/
/* Version			: 1.0																		*/
/************************************************************************************************/
/* Date			Modified By				Description of change			  						*/
/* ----------   -------------  			------------------------    			  				*/
/* 08-10-2008   Veera Veeramachanane   	Created Initial Version									*/
/* 04-03-2012   KM					   	CR4663													*/
/* 04-17-2015 TP        CR7905 Adding new top level division 24                                 */
/* 04-26-2017 TP        CR9365 Vendor error                                                     */
/************************************************************************************************/

BEGIN

 
DECLARE	@sp_name         		SYSNAME,
		@div22_company_id 		VARCHAR (10),
        @imaps_error_number     INTEGER,
        @SQLServer_error_code   INTEGER,
        @error_msg_placeholder1 SYSNAME,
        @error_msg_placeholder2 SYSNAME,
		@interface_name			SYSNAME,
		@ret_code				INT,
		@count					INT

	SELECT	@div22_company_id = parameter_value
	FROM	dbo.xx_processing_parameters
	WHERE	parameter_name = 'COMPANY_ID'
	AND		interface_name_cd = 'FIWLR_R22'



/*
CR2659 - superseded by CR4663
Major 418 miscodes should get corrected to 22.W
Source 405 major 801 should go to 22.W acct 90-02-90

	update xx_r22_fiwlr_usdet_miscodes
	set 
		org_id='22.W',
		org_abbr_cd='22.W',
		proj_abbr_cd=null
	where 
		major='418'

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	update xx_r22_fiwlr_usdet_miscodes
	set 
		org_id='22.W',
		org_abbr_cd='22.W',
		proj_abbr_cd=null,
		acct_id='90-02-90'
	where 
		source='405' 
	and major='801'

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
*/


--begin CR4663
/*
3) CR 2659 applied special logic to major 418 miscodes to auto correct them to 22.W
	Send these to 22.W.G.GD.KHSF   

4) 920 major miscode corrections to 22.W

 SR                34.00  
 22             5,094.18 
 YA             7,034.99  
  
Send ALL these to 22.W.G.GD.KHSF   
*/
	update xx_r22_fiwlr_usdet_miscodes
	SET ORG_ID=(select parameter_value from xx_processing_parameters where interface_name_cd='FIWLR_R22' and parameter_name='YA_ORG_ID_default'),
		ORG_ABBR_CD=(select parameter_value from xx_processing_parameters where interface_name_cd='FIWLR_R22' and parameter_name='YA_ORG_ABBRV_CD_default')
	where 
	major in ('418','920')
	and
	division not in ('YB','24')

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
--end CR4663





	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE NULLS'
	SET @ERROR_MSG_PLACEHOLDER2 = 'PROJ, ORG, ACCT'

	UPDATE	xx_r22_fiwlr_usdet_miscodes
	SET		proj_abbr_cd=null, pag_cd=null
	WHERE	LEN(ISNULL(rtrim(ltrim(proj_abbr_cd)),''))=0

	update xx_r22_fiwlr_usdet_miscodes
	set org_abbr_cd=null
	where len(isnull(rtrim(ltrim(org_abbr_cd)),''))=0

	update xx_r22_fiwlr_usdet_miscodes
	set acct_id=null
	where len(isnull(rtrim(ltrim(acct_id)),''))=0
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE NULL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'INVNO'

	update xx_r22_fiwlr_usdet_miscodes
	set inv_no = 'null'
	where inv_no is null or len(ltrim(rtrim(inv_no)))=0
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE NULL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FIWLR_INV_DATE'
	
	update xx_r22_fiwlr_usdet_miscodes
	set FIWLR_INV_DATE = 'null'
	where FIWLR_INV_DATE is null or len(ltrim(rtrim(FIWLR_INV_DATE)))=0
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE NULL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'PO_NO'

	update xx_r22_fiwlr_usdet_miscodes
	set PO_NO = 'null'
	where PO_NO is null or len(ltrim(rtrim(PO_NO)))=0

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE NULL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'vendor_id'

	update xx_r22_fiwlr_usdet_miscodes
	set vendor_id = 'null'
	where vendor_id is null or len(ltrim(rtrim(vendor_id)))=0
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE NULL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'ORG_ABBR_CD'

	UPDATE	XX_R22_FIWLR_USDET_MISCODES
	SET	ORG_ABBR_CD = (SELECT ORG_ABBRV_CD FROM IMAR.DELTEK.ORG WHERE ORG_ID = FIWLR.ORG_ID AND COMPANY_ID = @div22_company_id) 
	FROM  	XX_R22_FIWLR_USDET_MISCODES FIWLR	
	WHERE 	ORG_ID IS NOT NULL AND RTRIM(ORG_ID) <> ''

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR





	

--1. map for blank PAG, ANALYSIS_CD, and ETV_CODE
	UPDATE	XX_R22_FIWLR_USDET_MISCODES
	SET		ACCT_ID = cls_mapping.ACCT_ID
	FROM	XX_R22_FIWLR_USDET_MISCODES AS fiwlr
	INNER JOIN
			XX_R22_CLS_IMAPS_ACCT_MAP as cls_mapping
	ON (				
		LEN(RTRIM(LTRIM(isnull(cls_mapping.PAG,''))))=0
		AND
		LEN(RTRIM(LTRIM(isnull(cls_mapping.ANALYSIS_CD,''))))=0
		AND
		LEN(RTRIM(LTRIM(isnull(cls_mapping.ETV_CODE,''))))=0

	AND		fiwlr.major		>= (CASE 	WHEN cls_mapping.major_1 = '***' 	THEN fiwlr.major 
										WHEN cls_mapping.major_1 = ' '   	THEN fiwlr.major 
								ELSE	cls_mapping.major_1 
								END )
	AND		fiwlr.major		<= (CASE	WHEN cls_mapping.major_2 = '***' 	THEN fiwlr.major 
										WHEN	cls_mapping.major_2 = ' '   	THEN fiwlr.major
								ELSE	cls_mapping.major_2 
								END )
	AND	fiwlr.minor		>=	   (CASE 	WHEN	cls_mapping.minor_1 = '****' 	THEN fiwlr.minor
						  				WHEN	cls_mapping.minor_1 = ' ' 		THEN fiwlr.minor
						  		ELSE	cls_mapping.minor_1 
								END )
	AND	fiwlr.minor 		<= (CASE  	WHEN cls_mapping.minor_2 = '****' 	THEN fiwlr.minor
						  				WHEN cls_mapping.minor_2 = ' ' 		THEN fiwlr.minor
						  		ELSE cls_mapping.minor_2 
								END)
	AND	fiwlr.subminor 	>=	   (CASE  	WHEN cls_mapping.sub_minor_1 = '****' 	THEN fiwlr.subminor
						  				WHEN cls_mapping.sub_minor_1 = ' ' 	THEN fiwlr.subminor
						  		ELSE cls_mapping.sub_minor_1 
								END )
	AND	fiwlr.subminor 	<=	  (CASE  	WHEN cls_mapping.sub_minor_2 = '****' 	THEN fiwlr.subminor
						  				WHEN cls_mapping.sub_minor_2 = ' ' 	THEN fiwlr.subminor
						  	   ELSE cls_mapping.sub_minor_2 
							   END)
	)



--2. map for PAG, with blank ANALYSIS_CD, and ETV_CODE
	UPDATE	XX_R22_FIWLR_USDET_MISCODES
	SET		ACCT_ID = cls_mapping.ACCT_ID
	FROM	XX_R22_FIWLR_USDET_MISCODES AS fiwlr
	INNER JOIN
			XX_R22_CLS_IMAPS_ACCT_MAP as cls_mapping
	ON (				
		fiwlr.pag_cd = RTRIM(LTRIM(isnull(cls_mapping.PAG,'??????')))
		AND
		LEN(RTRIM(LTRIM(isnull(cls_mapping.ANALYSIS_CD,''))))=0
		AND
		LEN(RTRIM(LTRIM(isnull(cls_mapping.ETV_CODE,''))))=0

		AND	fiwlr.major		>= (CASE 	WHEN cls_mapping.major_1 = '***' 	THEN fiwlr.major 
							WHEN cls_mapping.major_1 = ' '   	THEN fiwlr.major 
							ELSE cls_mapping.major_1 
					   END )
		AND fiwlr.major		<= (CASE	WHEN cls_mapping.major_2 = '***' 	THEN fiwlr.major 
							WHEN cls_mapping.major_2 = ' '   	THEN fiwlr.major
							ELSE cls_mapping.major_2 
					   END )
		AND	fiwlr.minor		>= (CASE  	WHEN cls_mapping.minor_1 = '****' 	THEN fiwlr.minor
						  	WHEN cls_mapping.minor_1 = ' ' 		THEN fiwlr.minor
						  	ELSE cls_mapping.minor_1 
					   END )
		AND	fiwlr.minor 		<= (CASE  	WHEN cls_mapping.minor_2 = '****' 	THEN fiwlr.minor
						  	WHEN cls_mapping.minor_2 = ' ' 		THEN fiwlr.minor
						  	ELSE cls_mapping.minor_2 
					   END)
		AND	fiwlr.subminor 	>= (CASE  	WHEN cls_mapping.sub_minor_1 = '****' 	THEN fiwlr.subminor
						  	WHEN cls_mapping.sub_minor_1 = ' ' 	THEN fiwlr.subminor 
						  	ELSE cls_mapping.sub_minor_1 
					   END )
		AND	fiwlr.subminor 	<= (CASE  	WHEN cls_mapping.sub_minor_2 = '****' 	THEN fiwlr.subminor
						  	WHEN cls_mapping.sub_minor_2 = ' ' 	THEN fiwlr.subminor
						  	ELSE cls_mapping.sub_minor_2 
					   END)
		)




--3. map for PAG and ANALYSIS_CD, with blank ETV_CODE
		UPDATE	XX_R22_FIWLR_USDET_MISCODES
		SET		ACCT_ID = cls_mapping.ACCT_ID
		FROM	XX_R22_FIWLR_USDET_MISCODES AS fiwlr
		INNER JOIN
				XX_R22_CLS_IMAPS_ACCT_MAP as cls_mapping
		ON (				
				fiwlr.pag_cd = RTRIM(LTRIM(isnull(cls_mapping.PAG,'??????')))
		AND
				fiwlr.ANALYSIS_CODE = RTRIM(LTRIM(isnull(cls_mapping.ANALYSIS_CD,'???????')))
		AND
				LEN(RTRIM(LTRIM(isnull(cls_mapping.ETV_CODE,''))))=0

		AND		fiwlr.major		>= (CASE 	WHEN cls_mapping.major_1 = '***' 	THEN fiwlr.major 
							WHEN cls_mapping.major_1 = ' '   	THEN fiwlr.major 
							ELSE cls_mapping.major_1 
					   END )
		AND		fiwlr.major		<= (CASE	WHEN cls_mapping.major_2 = '***' 	THEN fiwlr.major 
							WHEN cls_mapping.major_2 = ' '   	THEN fiwlr.major
							ELSE cls_mapping.major_2 
					   END )
		AND		fiwlr.minor		>= (CASE  	WHEN cls_mapping.minor_1 = '****' 	THEN fiwlr.minor
						  	WHEN cls_mapping.minor_1 = ' ' 		THEN fiwlr.minor
						  	ELSE cls_mapping.minor_1 
					   END )
		AND		fiwlr.minor 		<= (CASE  	WHEN cls_mapping.minor_2 = '****' 	THEN fiwlr.minor
						  	WHEN cls_mapping.minor_2 = ' ' 		THEN fiwlr.minor
						  	ELSE cls_mapping.minor_2 
					   END)
		AND		fiwlr.subminor 	>= (CASE  	WHEN cls_mapping.sub_minor_1 = '****' 	THEN fiwlr.subminor
						  	WHEN cls_mapping.sub_minor_1 = ' ' 	THEN fiwlr.subminor 
						  	ELSE cls_mapping.sub_minor_1 
					   END )
		AND		fiwlr.subminor 	<= (CASE  	WHEN cls_mapping.sub_minor_2 = '****' 	THEN fiwlr.subminor
						  	WHEN cls_mapping.sub_minor_2 = ' ' 	THEN fiwlr.subminor
						  	ELSE cls_mapping.sub_minor_2 
					   END)
		)



--4. map for PAG and ETV_CODE, with blank ANALYSIS_CD
		UPDATE	XX_R22_FIWLR_USDET_MISCODES
		SET		ACCT_ID = cls_mapping.ACCT_ID
		FROM	XX_R22_FIWLR_USDET_MISCODES AS fiwlr
		INNER JOIN
				XX_R22_CLS_IMAPS_ACCT_MAP as cls_mapping
		ON (				
				fiwlr.pag_cd = RTRIM(LTRIM(isnull(cls_mapping.PAG,'??????')))
		AND
				fiwlr.ETV_CODE = RTRIM(LTRIM(isnull(cls_mapping.ETV_CODE,'???????')))
		AND
				LEN(RTRIM(LTRIM(isnull(cls_mapping.ANALYSIS_CD,''))))=0
		AND		fiwlr.major		>= (CASE 	WHEN cls_mapping.major_1 = '***' 	THEN fiwlr.major 
							WHEN cls_mapping.major_1 = ' '   	THEN fiwlr.major 
							ELSE cls_mapping.major_1 
					   END )
		AND		fiwlr.major		<= (CASE	WHEN cls_mapping.major_2 = '***' 	THEN fiwlr.major 
							WHEN cls_mapping.major_2 = ' '   	THEN fiwlr.major
							ELSE cls_mapping.major_2 
					   END )
		AND		fiwlr.minor		>= (CASE  	WHEN cls_mapping.minor_1 = '****' 	THEN fiwlr.minor
						  	WHEN cls_mapping.minor_1 = ' ' 		THEN fiwlr.minor
						  	ELSE cls_mapping.minor_1 
					   END )
		AND		fiwlr.minor 		<= (CASE  	WHEN cls_mapping.minor_2 = '****' 	THEN fiwlr.minor
						  	WHEN cls_mapping.minor_2 = ' ' 		THEN fiwlr.minor
						  	ELSE cls_mapping.minor_2 
					   END)
		AND		fiwlr.subminor 	>= (CASE  	WHEN cls_mapping.sub_minor_1 = '****' 	THEN fiwlr.subminor
						  	WHEN cls_mapping.sub_minor_1 = ' ' 	THEN fiwlr.subminor 
						  	ELSE cls_mapping.sub_minor_1 
					   END )
		AND		fiwlr.subminor 	<= (CASE  	WHEN cls_mapping.sub_minor_2 = '****' 	THEN fiwlr.subminor
						  	WHEN cls_mapping.sub_minor_2 = ' ' 	THEN fiwlr.subminor
						  	ELSE cls_mapping.sub_minor_2 
					   END)
		)



--5. map for PAG and ANALYSIS_CD and ETV_CODE
		UPDATE	XX_R22_FIWLR_USDET_MISCODES
		SET		ACCT_ID = cls_mapping.ACCT_ID
		FROM	XX_R22_FIWLR_USDET_MISCODES AS fiwlr
		INNER JOIN
				XX_R22_CLS_IMAPS_ACCT_MAP as cls_mapping
		ON (				
				fiwlr.pag_cd = RTRIM(LTRIM(isnull(cls_mapping.PAG,'??????')))
		AND
				fiwlr.ANALYSIS_CODE = RTRIM(LTRIM(isnull(cls_mapping.ANALYSIS_CD,'???????')))
		AND
				fiwlr.ETV_CODE = RTRIM(LTRIM(isnull(cls_mapping.ETV_CODE,'??????')))

		AND		fiwlr.major		>= (CASE 	WHEN cls_mapping.major_1 = '***' 	THEN fiwlr.major 
							WHEN cls_mapping.major_1 = ' '   	THEN fiwlr.major 
							ELSE cls_mapping.major_1 
					   END )
		AND		fiwlr.major		<= (CASE	WHEN cls_mapping.major_2 = '***' 	THEN fiwlr.major 
							WHEN cls_mapping.major_2 = ' '   	THEN fiwlr.major
							ELSE cls_mapping.major_2 
					   END )
		AND		fiwlr.minor		>= (CASE  	WHEN cls_mapping.minor_1 = '****' 	THEN fiwlr.minor
						  	WHEN cls_mapping.minor_1 = ' ' 		THEN fiwlr.minor
						  	ELSE cls_mapping.minor_1 
					   END )
		AND		fiwlr.minor 		<= (CASE  	WHEN cls_mapping.minor_2 = '****' 	THEN fiwlr.minor
						  	WHEN cls_mapping.minor_2 = ' ' 		THEN fiwlr.minor
						  	ELSE cls_mapping.minor_2 
					   END)
		AND		fiwlr.subminor 	>= (CASE  	WHEN cls_mapping.sub_minor_1 = '****' 	THEN fiwlr.subminor
						  	WHEN cls_mapping.sub_minor_1 = ' ' 	THEN fiwlr.subminor 
						  	ELSE cls_mapping.sub_minor_1 
					   END )
		AND		fiwlr.subminor 	<= (CASE  	WHEN cls_mapping.sub_minor_2 = '****' 	THEN fiwlr.subminor
						  	WHEN cls_mapping.sub_minor_2 = ' ' 	THEN fiwlr.subminor
						  	ELSE cls_mapping.sub_minor_2 
					   END)
		)



--6. voucher specific mappings go last to override everything
		UPDATE	XX_R22_FIWLR_USDET_MISCODES
		SET		ACCT_ID = cls_mapping.ACCT_ID
		FROM	XX_R22_FIWLR_USDET_MISCODES AS fiwlr
		INNER JOIN
				XX_R22_FIWLR_VCHR_ACCT_MAP as cls_mapping
		ON (
				fiwlr.voucher_no like cls_mapping.VCHR_START+'%'
		AND		fiwlr.major		>= (CASE 	WHEN cls_mapping.major_1 = '***' 	THEN fiwlr.major 
							WHEN cls_mapping.major_1 = ' '   	THEN fiwlr.major 
							ELSE cls_mapping.major_1 
					   END )
		AND		fiwlr.major		<= (CASE	WHEN cls_mapping.major_2 = '***' 	THEN fiwlr.major 
							WHEN cls_mapping.major_2 = ' '   	THEN fiwlr.major
							ELSE cls_mapping.major_2 
					   END )
		AND		fiwlr.minor		>= (CASE  	WHEN cls_mapping.minor_1 = '****' 	THEN fiwlr.minor
						  	WHEN cls_mapping.minor_1 = ' ' 		THEN fiwlr.minor
						  	ELSE cls_mapping.minor_1 
					   END )
		AND		fiwlr.minor 		<= (CASE  	WHEN cls_mapping.minor_2 = '****' 	THEN fiwlr.minor
						  	WHEN cls_mapping.minor_2 = ' ' 		THEN fiwlr.minor
						  	ELSE cls_mapping.minor_2 
					   END)
		AND		fiwlr.subminor 	>= (CASE  	WHEN cls_mapping.sub_minor_1 = '****' 	THEN fiwlr.subminor
						  	WHEN cls_mapping.sub_minor_1 = ' ' 	THEN fiwlr.subminor
						  	ELSE cls_mapping.sub_minor_1 
					   END )
		AND		fiwlr.subminor 	<= (CASE  	WHEN cls_mapping.sub_minor_2 = '****' 	THEN fiwlr.subminor
						  	WHEN cls_mapping.sub_minor_2 = ' ' 	THEN fiwlr.subminor
						  	ELSE cls_mapping.sub_minor_2 
					   END)
		)



	--Zurich special account logic
		UPDATE XX_R22_FIWLR_USDET_MISCODES
		SET 
			PROJ_ABBR_CD = NULL,
			PROJ_ID = NULL,
			ORG_ID = '22.Z'
		WHERE 
			DIVISION='YB'

	    UPDATE XX_R22_FIWLR_USDET_MISCODES
		SET 
			ACCT_ID = '30-01-02'
		WHERE 
			DIVISION='YB'
		AND
			LEFT(MAJOR,1)='3'

		UPDATE XX_R22_FIWLR_USDET_MISCODES
		SET 
			ACCT_ID = '40-01-02'
		WHERE 
			DIVISION='YB'
		AND
			LEFT(MAJOR,1)='4'


	    UPDATE XX_R22_FIWLR_USDET_MISCODES
		SET 
			ACCT_ID = '82-18-02'
		WHERE 
			DIVISION='YB'
		AND
			LEFT(MAJOR,1) in ('6','7','8')

		UPDATE XX_R22_FIWLR_USDET_MISCODES
		SET 
			ACCT_ID = '90-01-02'
		WHERE 
			DIVISION='YB'
		AND
			LEFT(MAJOR,1) in ('5','9')



		--CR for non project required accounts
		update xx_r22_fiwlr_usdet_miscodes
		set proj_abbr_cd = null, proj_id=null, pag_cd=null
		where acct_id is not null
		and
		acct_id in
		(select acct_id
		 from imar.deltek.acct
		 where len(acct_id)=8
		 and PROJ_REQD_FL='N')
			

	





	/* UPDATE FOR MAX LINE ITEMS PER COSTPOINT DOCUMENT */

	--GROUPING AP WWER
	UPDATE XX_R22_FIWLR_USDET_MISCODES
	SET REFERENCE3 = 
	(SELECT MAX(IDENT_REC_NO) FROM XX_R22_FIWLR_USDET_MISCODES  
	WHERE		STATUS_REC_NO = FIWLR.STATUS_REC_NO  
	AND	    	SOURCE_GROUP = FIWLR.SOURCE_GROUP  
	AND		VOUCHER_NO = FIWLR.VOUCHER_NO  
	AND		SOURCE = FIWLR.SOURCE  
	AND		MAJOR = FIWLR.MAJOR  
	AND		ISNULL(INV_NO, '') = ISNULL(FIWLR.INV_NO, '')
	--AND		EXTRACT_DATE = FIWLR.EXTRACT_DATE  
	AND		ISNULL(FIWLR_INV_DATE, '') = ISNULL(FIWLR.FIWLR_INV_DATE, '')  
	AND 		ISNULL(PO_NO, '') = ISNULL(FIWLR.PO_NO, '')
	AND 		ISNULL(VENDOR_ID, '')= ISNULL(FIWLR.VENDOR_ID, '')
	AND		ISNULL(EMPLOYEE_NO, '') = ISNULL(FIWLR.EMPLOYEE_NO, ''))	
	FROM 	XX_R22_FIWLR_USDET_MISCODES FIWLR
	WHERE 	SOURCE_GROUP = 'AP'
	AND	SOURCE IN ('005', 'N16')

	--GROUPING AP NONWWER
	UPDATE XX_R22_FIWLR_USDET_MISCODES
	SET REFERENCE3 = 
	(SELECT MAX(IDENT_REC_NO) FROM XX_R22_FIWLR_USDET_MISCODES  
	WHERE		STATUS_REC_NO = FIWLR.STATUS_REC_NO  
	AND	    	SOURCE_GROUP = FIWLR.SOURCE_GROUP  
	AND		VOUCHER_NO = FIWLR.VOUCHER_NO  
	AND		SOURCE = FIWLR.SOURCE  
	AND		MAJOR = FIWLR.MAJOR  
	AND		ISNULL(INV_NO, '') = ISNULL(FIWLR.INV_NO, '')
	AND		EXTRACT_DATE = FIWLR.EXTRACT_DATE  
	AND		ISNULL(FIWLR_INV_DATE, '') = ISNULL(FIWLR.FIWLR_INV_DATE, '')  
	AND 		ISNULL(PO_NO, '') = ISNULL(FIWLR.PO_NO, '')
	AND 		ISNULL(VENDOR_ID, '')= ISNULL(FIWLR.VENDOR_ID, ''))
	--AND		ISNULL(EMPLOYEE_NO, '') = ISNULL(FIWLR.EMPLOYEE_NO, ''))	
	FROM 	XX_R22_FIWLR_USDET_MISCODES FIWLR
	WHERE 	SOURCE_GROUP = 'AP'
	AND	SOURCE NOT IN ('005', 'N16')
	
	--GROUPING je
	UPDATE XX_R22_FIWLR_USDET_MISCODES
	SET REFERENCE3 = 
	(SELECT MAX(IDENT_REC_NO) FROM XX_R22_FIWLR_USDET_MISCODES  
	WHERE		STATUS_REC_NO = FIWLR.STATUS_REC_NO  
	AND	    	SOURCE_GROUP = FIWLR.SOURCE_GROUP  
	AND		VOUCHER_NO = FIWLR.VOUCHER_NO  
	AND		SOURCE = FIWLR.SOURCE  
	AND		MAJOR = FIWLR.MAJOR)
	--AND		INV_NO = FIWLR.INV_NO  
	--AND		EXTRACT_DATE = FIWLR.EXTRACT_DATE  
	--AND		FIWLR_INV_DATE = FIWLR.FIWLR_INV_DATE  
	--AND 		PO_NO = FIWLR.PO_NO  
	--AND 		VENDOR_ID = FIWLR.VENDOR_ID
	--AND		EMPLOYEE_NO = FIWLR.EMPLOYEE_NO)	
	FROM 	XX_R22_FIWLR_USDET_MISCODES FIWLR
	WHERE 	SOURCE_GROUP = 'JE'


	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	
	DECLARE @STATUS_REC_NO int,
		@REFERENCE3 varchar(125),		@LINE_COUNT int
	
	START_MAX_LINES_CURSOR:
	
	DECLARE MAX_LINES_CURSOR CURSOR FAST_FORWARD FOR
		select status_rec_no, reference3, count(1)
		from XX_R22_FIWLR_USDET_MISCODES
		group by status_rec_no, reference3
		having count(1) > 1497
	
	OPEN MAX_LINES_CURSOR
	FETCH MAX_LINES_CURSOR
	INTO @STATUS_REC_NO, @REFERENCE3, @LINE_COUNT
	
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		DECLARE @CUTOFF_IDENT_REC_NO int
		
		SELECT top 1497 @CUTOFF_IDENT_REC_NO = IDENT_REC_NO
		FROM 	XX_R22_FIWLR_USDET_MISCODES
		WHERE 	STATUS_REC_NO = @STATUS_REC_NO
		AND	REFERENCE3 = @REFERENCE3
		ORDER BY IDENT_REC_NO
	
		UPDATE 	XX_R22_FIWLR_USDET_MISCODES
		SET	REFERENCE3 = REFERENCE3 + 'M'
		WHERE 	STATUS_REC_NO = @STATUS_REC_NO
		AnD	REFERENCE3 = @REFERENCE3
		AND	IDENT_REC_NO > @CUTOFF_IDENT_REC_NO
			
		FETCH MAX_LINES_CURSOR
		INTO @STATUS_REC_NO, @REFERENCE3, @LINE_COUNT
	END
	
	CLOSE MAX_LINES_CURSOR
	DEALLOCATE MAX_LINES_CURSOR
	
		select status_rec_no, reference3, count(1)
		from XX_R22_FIWLR_USDET_MISCODES
		group by status_rec_no, reference3
		having count(1) > 1497
	
	IF @@ROWCOUNT <> 0 GOTO START_MAX_LINES_CURSOR

	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE FEEDBACK'
	SET @ERROR_MSG_PLACEHOLDER2 = ''
	
	/*FEEDBACK UPDATE */	
	UPDATE XX_R22_FIWLR_USDET_MISCODES
	SET REFERENCE1='M',
	REFERENCE2=''

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE FIWLR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH MISCODE FEEDBACK - ACCT_ID'

	UPDATE 	XX_R22_FIWLR_USDET_MISCODES
	SET	REFERENCE2 = CAST(REFERENCE2 + 'acct,' AS VARCHAR(125))
	FROM	XX_R22_FIWLR_USDET_MISCODES FIWLR
	WHERE	
	0 =
	(	SELECT COUNT(1)
		FROM IMAR.DELTEK.ACCT
		WHERE ACCT_ID = FIWLR.ACCT_ID
	)
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE FIWLR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH MISCODE FEEDBACK - ORG_ID & PROJ_ABBRV_CD'
	
	UPDATE 	XX_R22_FIWLR_USDET_MISCODES
	SET	REFERENCE2 = CAST(REFERENCE2 + 'org,' AS VARCHAR(125))
	FROM	XX_R22_FIWLR_USDET_MISCODES FIWLR
	WHERE	0 =
	(	SELECT COUNT(1)
		FROM 	IMAR.DELTEK.ORG
		WHERE	COMPANY_ID = @div22_company_id AND ORG_ABBRV_CD = ISNULL(FIWLR.ORG_ABBR_CD, '?') AND ORG_ABBRV_CD<>''
		AND ((DIVISION = '24' AND L1_ORG_SEG_ID = '24') or (DIVISION <> '24' AND L1_ORG_SEG_ID = '22'))    --CR7905
	)
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	
	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE FIWLR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH MISCODE FEEDBACK - PROJ_ABBRV_CD'
	
	UPDATE 	XX_R22_FIWLR_USDET_MISCODES
	SET	REFERENCE2 = CAST(REFERENCE2 + 'proj,' AS VARCHAR(125))
	FROM	XX_R22_FIWLR_USDET_MISCODES FIWLR
	WHERE	0 =
	(	SELECT	COUNT(1)
		FROM 	IMAR.DELTEK.PROJ p inner join IMAR.DELTEK.ORG o  --CR7905
			on p.ORG_ID = o.ORG_ID
		WHERE   ((FIWLR.DIVISION = '24' and o.L1_ORG_SEG_ID = '24') or
			FIWLR.DIVISION <> '24' and o.L1_ORG_SEG_ID = '22')
    		 AND p.COMPANY_ID = @div22_company_id AND p.PROJ_ABBRV_CD = ISNULL(FIWLR.PROJ_ABBR_CD, '?') AND p.PROJ_ABBRV_CD<>''
         )
	/*--CR for 9X-XX-XX accounts
	AND left(isnull(acct_id, '?'),1) not in ('9')
	*/
	--and not a blank project with non project required account
	AND NOT (
			LEN(ISNULL(fiwlr.PROJ_ABBR_CD, ''))=0 
			AND fiwlr.ACCT_ID IN (SELECT ACCT_ID 
								  FROM IMAR.DELTEK.ACCT 
								  WHERE ACCT_ID=fiwlr.ACCT_ID 
								  AND PROJ_REQD_FL='N')
			)
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE FIWLR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH MISCODE FEEDBACK - ACCT_ID & PROJ_ABBRV_CD'

	UPDATE 	XX_R22_FIWLR_USDET_MISCODES
	SET	REFERENCE2 = CAST(REFERENCE2 + 'acct_pag,' AS VARCHAR(125))
	FROM	XX_R22_FIWLR_USDET_MISCODES FIWLR
	WHERE	LEN(ISNULL(ACCT_ID, ''))<>0
	AND		LEN(ISNULL(PAG_CD, ''))<>0
	AND	0 =
	(	SELECT COUNT(1)
		FROM 	IMAR.DELTEK.ACCT_GRP_SETUP
		WHERE	COMPANY_ID = @div22_company_id 
		AND ACCT_ID = FIWLR.ACCT_ID
		AND	ACCT_GRP_CD = FIWLR.PAG_CD
	)
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE FIWLR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH MISCODE FEEDBACK - ACCT_ID & ORG_ID'

	UPDATE 	XX_R22_FIWLR_USDET_MISCODES
	SET	REFERENCE2 = CAST(REFERENCE2 + 'acct_org,' AS VARCHAR(125))
	FROM	XX_R22_FIWLR_USDET_MISCODES FIWLR
	WHERE	LEN(ISNULL(ACCT_ID, ''))<>0
	AND	LEN(ISNULL(ORG_ID, ''))<>0
	AND	0 =
	(	SELECT COUNT(1)
		FROM 	IMAR.DELTEK.ORG_ACCT
		WHERE	ACCT_ID = FIWLR.ACCT_ID
		AND	ORG_ID = FIWLR.ORG_ID
	)


	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE FIWLR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH MISCODE FEEDBACK - PROJ ALLOW_CHARGES_FL'	

	UPDATE 	XX_R22_FIWLR_USDET_MISCODES
	SET	REFERENCE2 = CAST(REFERENCE2 + 'proj_chg_fl,' AS VARCHAR(125))
	FROM	XX_R22_FIWLR_USDET_MISCODES FIWLR
	WHERE	LEN(ISNULL(PROJ_ABBR_CD, ''))<>0
	AND	1 =
	(	SELECT COUNT(1) 
		FROM 	IMAR.DELTEK.PROJ
		WHERE	COMPANY_ID = @div22_company_id AND PROJ_ABBRV_CD = FIWLR.PROJ_ABBR_CD
		AND	ALLOW_CHARGES_FL = 'N'
	)
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE FIWLR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH MISCODE FEEDBACK - PROJ ACTIVE_FL'	

	UPDATE 	XX_R22_FIWLR_USDET_MISCODES
	SET	REFERENCE2 = CAST(REFERENCE2 + 'proj_inactive,' AS VARCHAR(125))
	FROM	XX_R22_FIWLR_USDET_MISCODES FIWLR
	WHERE	LEN(ISNULL(PROJ_ABBR_CD, ''))<>0
	AND	1 =
	(	SELECT COUNT(1)
		FROM 	IMAR.DELTEK.PROJ
		WHERE	COMPANY_ID = @div22_company_id AND PROJ_ABBRV_CD = FIWLR.PROJ_ABBR_CD
		AND	ACTIVE_FL = 'N'
	)
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE FIWLR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH MISCODE FEEDBACK - ORG ACTIVE_FL'	

	UPDATE 	XX_R22_FIWLR_USDET_MISCODES
	SET	REFERENCE2 = CAST(REFERENCE2 + 'org_inactive,' AS VARCHAR(125))
	FROM	XX_R22_FIWLR_USDET_MISCODES FIWLR
	WHERE	LEN(ISNULL(ORG_ABBR_CD, ''))<>0
	AND	1 =
	(	SELECT COUNT(1)
		FROM 	IMAR.DELTEK.ORG
		WHERE	COMPANY_ID = @div22_company_id AND ORG_ABBRV_CD = FIWLR.ORG_ABBR_CD
	    AND ((FIWLR.DIVISION = '24' AND L1_ORG_SEG_ID = '24') or (FIWLR.DIVISION <> '24' AND L1_ORG_SEG_ID = '22'))    --CR7905
		AND	ACTIVE_FL = 'N'
	)

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE FIWLR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH MISCODE FEEDBACK - ACCT ACTIVE_FL'	

	UPDATE 	XX_R22_FIWLR_USDET_MISCODES
	SET	REFERENCE2 = CAST(REFERENCE2 + 'acct_inactive,' AS VARCHAR(125))
	FROM	XX_R22_FIWLR_USDET_MISCODES FIWLR
	WHERE	LEN(ISNULL(ACCT_ID, ''))<>0
	AND	1 =
	(	SELECT COUNT(1)
		FROM 	IMAR.DELTEK.ACCT
		WHERE	ACCT_ID = FIWLR.ACCT_ID
		AND	ACTIVE_FL = 'N'
	)

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	
	
		-- CR9365 begin

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE FIWLR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH MISCODE FEEDBACK - Vendor'	
	
	
		
	
	
	UPDATE 	XX_R22_FIWLR_USDET_MISCODES
	SET	REFERENCE2 = CAST(REFERENCE2 + 'vendor,' AS VARCHAR(125))
	FROM	XX_R22_FIWLR_USDET_MISCODES FIWLR
	WHERE	 SOURCE = '005'
	AND RTRIM(ISNULL(VENDOR_ID,'null'))= 'null'
	
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	-- CR9365 end


	UPDATE 	XX_R22_FIWLR_USDET_MISCODES
	SET 	REFERENCE2 = 'valid'
	WHERE	LEN(REFERENCE2) = 0
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR




	

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE TO NULL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'INVNO'

	update xx_r22_fiwlr_usdet_miscodes
	set inv_no = null
	where inv_no = 'null' 

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE TO NULL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FIWLR_INV_DATE'
	
	update xx_r22_fiwlr_usdet_miscodes
	set FIWLR_INV_DATE = null
	where FIWLR_INV_DATE = 'null'

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE TO NULL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'PO_NO'

	update xx_r22_fiwlr_usdet_miscodes
	set PO_NO = null
	where PO_NO = 'null'

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE TO NULL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'vendor_id'

	update xx_r22_fiwlr_usdet_miscodes
	set vendor_id = null
	where vendor_id = 'null'

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR





--DR3177
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE TO GROUPING'
	SET @ERROR_MSG_PLACEHOLDER2 = 'TO INCLUDE DIVISION'

	--include division in the grouping
	update xx_r22_fiwlr_usdet_miscodes
	set reference3=reference3+division

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

		


RETURN 0

ERROR:

PRINT @out_STATUS_DESCRIPTION

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_number,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

PRINT @out_STATUS_DESCRIPTION

RETURN 1

END















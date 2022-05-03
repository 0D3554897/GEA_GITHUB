USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_FIWLR_MISCODE_UPDATE_SP]    Script Date: 09/27/2017 11:56:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO





ALTER PROCEDURE [dbo].[XX_R22_FIWLR_MISCODE_UPDATE_SP] (
@in_STATUS_RECORD_NUM integer,
@in_UNIQUE_RECORD_NUM integer,
@in_PROJ_ABBRV_CD varchar(4) = NULL,
@in_ORG_ABBRV_CD varchar(4) = NULL,
@in_ACCT_ID varchar(10) = NULL,
@out_STATUS_DESCRIPTION sysname = NULL
)
AS
BEGIN
/************************************************************************************************  
Name:       	XX_R22_FIWLR_MISCODE_UPDATE_SP  
Author:     	KM  

on change:

1.  UPDATE MISCODE TABLE & REDO-MAPPING
2.  READ UPDATES FROM ARCHIVE TABLE                                                                        */
/* 04-17-2015  TP    CR7905 Adding new top level division                                                  */
/* 02-19-2015  TP    (DR8632 fixed restriction accidently done in CR7905 on org as project owning org )    */
/* 04-26-2015  TP    CR9365 Vendor error                                                                   */
/* 09-25-2015  TP    CR9681 Common record validation was moved to XX_R22_FIWLR_MISCODE_VALIDATE_RECORDS_SP  */
/*                    to be used  for single transaction  as well as for a voucher validation               */
/************************************************************************************************/  

	DECLARE	@SP_NAME         sysname,
		@DIV_22_COMPANY_ID 	 varchar(10),
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@INTERFACE_NAME		 sysname,
		@ret_code		 int,
		@count			 int,
		@PROJ_ABBRV_CD 		varchar(10),
		@ORG_ABBRV_CD 		varchar(10),
		@ACCT_ID 		varchar(12),
		@inc_exc_fl 		char(1),
		@source			char(3),
		@FIWLR_OFFSET_ACCT_ID	varchar(12),
		@major			char(3),
		@change			varchar(10),
		@division       varchar(2)                    -- CR7905

	SELECT @DIV_22_COMPANY_ID = PARAMETER_VALUE
	  FROM dbo.XX_PROCESSING_PARAMETERS
	 WHERE PARAMETER_NAME = 'COMPANY_ID'
	   AND INTERFACE_NAME_CD = 'FIWLR_R22'

	SET @inc_exc_fl = 'I'
	SET @INTERFACE_NAME = 'FIWLR_R22'
	SET @SP_NAME = 'XX_R22_FIWLR_MISCODE_UPDATE_SP'

	UPDATE 	XX_R22_FIWLR_USDET_MISCODES
	SET 	REFERENCE1 = 'U',
		REFERENCE2 = ''
	WHERE	STATUS_REC_NO = @in_STATUS_RECORD_NUM
	AND	IDENT_REC_NO = @in_UNIQUE_RECORD_NUM

	SELECT 	@PROJ_ABBRV_CD = PROJ_ABBR_CD,
		@ORG_ABBRV_CD = ORG_ABBR_CD,
		@ACCT_ID = ACCT_ID,
		@source = SOURCE,
		@major = MAJOR,
		@division = DIVISION
	FROM	XX_R22_FIWLR_USDET_MISCODES
	WHERE	STATUS_REC_NO = @in_STATUS_RECORD_NUM
	AND	IDENT_REC_NO = @in_UNIQUE_RECORD_NUM

	IF @in_PROJ_ABBRV_CD = '' SET @in_PROJ_ABBRV_CD = NULL
	IF @in_ORG_ABBRV_CD = '' SET @in_ORG_ABBRV_CD = NULL
	IF @in_ACCT_ID = '' SET @in_ACCT_ID = NULL

	IF ISNULL(@PROJ_ABBRV_CD, '') <> ISNULL(@in_PROJ_ABBRV_CD, '')
		SET @change = 'proj'
	ELSE IF ISNULL(@ORG_ABBRV_CD, '') <> ISNULL(@in_ORG_ABBRV_CD, '') 
		SET @change = 'org'
	ELSE IF ISNULL(@ACCT_ID, '') <> ISNULL(@in_ACCT_ID, '')
		SET @change = 'acct'

	/* FIWLR DATA MAPPINGS	*/	
	IF @change = 'org'
	BEGIN
		SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
		SET @ERROR_MSG_PLACEHOLDER1 = 'PERFORM FIWLR'
		SET @ERROR_MSG_PLACEHOLDER2 = 'ORGANIZATION MAPPING'
	
		UPDATE	XX_R22_FIWLR_USDET_MISCODES
		SET	ORG_ABBR_CD = @in_ORG_ABBRV_CD
		WHERE 	STATUS_REC_NO = @in_STATUS_RECORD_NUM
		AND	IDENT_REC_NO = @in_UNIQUE_RECORD_NUM	
	
		SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
		IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	
		UPDATE	XX_R22_FIWLR_USDET_MISCODES
		SET	ORG_ID = (SELECT ORG_ID 
		               FROM IMAR.DELTEK.ORG 
		               WHERE COMPANY_ID = @DIV_22_COMPANY_ID AND ORG_ABBRV_CD = FIWLR.ORG_ABBR_CD
		               AND ((@division = '24' AND L1_ORG_SEG_ID = '24') or (@division <> '24' AND L1_ORG_SEG_ID = '22')))  --CR7905
		FROM  	XX_R22_FIWLR_USDET_MISCODES FIWLR	
		WHERE 	STATUS_REC_NO = @in_STATUS_RECORD_NUM
		AND	IDENT_REC_NO = @in_UNIQUE_RECORD_NUM
		
		SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
		IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

		IF LEN(RTRIM(LTRIM(ISNULL(@PROJ_ABBRV_CD, '') )))=0 AND @major<>'817'
		BEGIN
			SET @change='proj'
			SET @in_PROJ_ABBRV_CD = NULL
			SELECT @in_PROJ_ABBRV_CD = 
						g.UDEF_TXT
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
								org.ORG_ABBRV_CD=@in_ORG_ABBRV_CD
								and    --CR7905
								((@division = '24' AND org.L1_ORG_SEG_ID = '24') or (@division <> '24' AND org.L1_ORG_SEG_ID = '22'))
								)
							
		END
	END

	IF @change = 'proj'
	BEGIN		
		SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
		SET @ERROR_MSG_PLACEHOLDER1 = 'PERFORM FIWLR'
		SET @ERROR_MSG_PLACEHOLDER2 = 'PROJECT MAPPING'
	
		
		UPDATE	XX_R22_FIWLR_USDET_MISCODES
		SET	PROJ_ABBR_CD = ( SELECT PROJ_ABBRV_CD  FROM   --CR7905
						IMAR.DELTEK.PROJ p inner join IMAR.DELTEK.ORG o 
						on p.ORG_ID = o.ORG_ID
						where p.PROJ_ABBRV_CD = @in_PROJ_ABBRV_CD 
						and ((@division = '24' and o.L1_ORG_SEG_ID = '24') or
						@division <> '24' and o.L1_ORG_SEG_ID = '22'))
		WHERE 	STATUS_REC_NO = @in_STATUS_RECORD_NUM
		AND	IDENT_REC_NO = @in_UNIQUE_RECORD_NUM

		
		SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
		IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	
		UPDATE	XX_R22_FIWLR_USDET_MISCODES
		SET	PROJ_ID = (SELECT PROJ_ID FROM IMAR.DELTEK.PROJ WHERE COMPANY_ID = @DIV_22_COMPANY_ID AND PROJ_ABBRV_CD = FIWLR.PROJ_ABBR_CD AND PROJ_ABBRV_CD <> ''),
			PAG_CD = (SELECT ACCT_GRP_CD FROM IMAR.DELTEK.PROJ WHERE COMPANY_ID = @DIV_22_COMPANY_ID AND PROJ_ABBRV_CD = FIWLR.PROJ_ABBR_CD AND PROJ_ABBRV_CD <> '')
		FROM  	XX_R22_FIWLR_USDET_MISCODES FIWLR
		WHERE 	STATUS_REC_NO = @in_STATUS_RECORD_NUM
		AND	IDENT_REC_NO = @in_UNIQUE_RECORD_NUM	
		
		SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
		IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

		--for BOND, always use project owning org
		/* CR1912 - stop treating BOND 072 as special
		IF @source='072'
		BEGIN
			UPDATE	XX_R22_FIWLR_USDET_MISCODES
			SET		ORG_ID = (SELECT ORG_ID FROM IMAR.DELTEK.PROJ WHERE COMPANY_ID = @DIV_22_COMPANY_ID AND PROJ_ABBRV_CD = FIWLR.PROJ_ABBR_CD AND PROJ_ABBRV_CD <> '')
			FROM  	XX_R22_FIWLR_USDET_MISCODES FIWLR
			WHERE 	STATUS_REC_NO = @in_STATUS_RECORD_NUM
			AND		IDENT_REC_NO = @in_UNIQUE_RECORD_NUM

			UPDATE	XX_R22_FIWLR_USDET_MISCODES
			SET		ORG_ABBR_CD = (SELECT ORG_ABBRV_CD FROM IMAR.DELTEK.ORG WHERE COMPANY_ID = @DIV_22_COMPANY_ID AND ORG_ID = FIWLR.ORG_ID)
			FROM  	XX_R22_FIWLR_USDET_MISCODES FIWLR
			WHERE 	STATUS_REC_NO = @in_STATUS_RECORD_NUM
			AND		IDENT_REC_NO = @in_UNIQUE_RECORD_NUM
		END
		*/

		SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
		IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	END
	


	SELECT 	@source = SOURCE, @major = MAJOR
		FROM 	XX_R22_FIWLR_USDET_MISCODES
		WHERE	STATUS_REC_NO = @in_STATUS_RECORD_NUM
		AND	IDENT_REC_NO = @in_UNIQUE_RECORD_NUM

	IF @change = 'acct'
	BEGIN
		SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
		SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE FIWLR'
		SET @ERROR_MSG_PLACEHOLDER2 = 'ACCT_ID'
	
		UPDATE	XX_R22_FIWLR_USDET_MISCODES
		SET	ACCT_ID = @in_ACCT_ID
		WHERE 	STATUS_REC_NO = @in_STATUS_RECORD_NUM
		AND	IDENT_REC_NO = @in_UNIQUE_RECORD_NUM
	
		SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
		IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	END
	ELSE
	BEGIN
		/* FIWLR ACCOUNT MAPPING */
		--1. map for blank PAG, ANALYSIS_CD, and ETV_CODE
		UPDATE XX_R22_FIWLR_USDET_V3
		SET 
		ACCT_ID = cls_mapping.ACCT_ID
		FROM 
		XX_R22_FIWLR_USDET_V3 AS fiwlr
		INNER JOIN
		XX_R22_CLS_IMAPS_ACCT_MAP as cls_mapping
			ON (			
				fiwlr.STATUS_REC_NO = @in_STATUS_RECORD_NUM
				and
				fiwlr.IDENT_REC_NO = @in_UNIQUE_RECORD_NUM	
				and
				LEN(RTRIM(LTRIM(isnull(cls_mapping.PAG,''))))=0
				and
				LEN(RTRIM(LTRIM(isnull(cls_mapping.ANALYSIS_CD,''))))=0
				and
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


		--2. map for PAG, with blank ANALYSIS_CD, and ETV_CODE
		UPDATE XX_R22_FIWLR_USDET_V3
		SET 
		ACCT_ID = cls_mapping.ACCT_ID
		FROM 
		XX_R22_FIWLR_USDET_V3 AS fiwlr
		INNER JOIN
		XX_R22_CLS_IMAPS_ACCT_MAP as cls_mapping
			ON (
				fiwlr.STATUS_REC_NO = @in_STATUS_RECORD_NUM
				and
				fiwlr.IDENT_REC_NO = @in_UNIQUE_RECORD_NUM	
				and				
				fiwlr.pag_cd = RTRIM(LTRIM(isnull(cls_mapping.PAG,'??????')))
				and
				LEN(RTRIM(LTRIM(isnull(cls_mapping.ANALYSIS_CD,''))))=0
				and
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
		UPDATE XX_R22_FIWLR_USDET_V3
		SET 
		ACCT_ID = cls_mapping.ACCT_ID
		FROM 
		XX_R22_FIWLR_USDET_V3 AS fiwlr
		INNER JOIN
		XX_R22_CLS_IMAPS_ACCT_MAP as cls_mapping
			ON (	
				fiwlr.STATUS_REC_NO = @in_STATUS_RECORD_NUM
				and
				fiwlr.IDENT_REC_NO = @in_UNIQUE_RECORD_NUM	
				and			
				fiwlr.pag_cd = RTRIM(LTRIM(isnull(cls_mapping.PAG,'??????')))
				and
				fiwlr.ANALYSIS_CODE = RTRIM(LTRIM(isnull(cls_mapping.ANALYSIS_CD,'???????')))
				and
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


		--4. map for PAG and ETV_CODE, with blank ANALYSIS_CD
		UPDATE XX_R22_FIWLR_USDET_V3
		SET 
		ACCT_ID = cls_mapping.ACCT_ID
		FROM 
		XX_R22_FIWLR_USDET_V3 AS fiwlr
		INNER JOIN
		XX_R22_CLS_IMAPS_ACCT_MAP as cls_mapping
			ON (
				fiwlr.STATUS_REC_NO = @in_STATUS_RECORD_NUM
				and
				fiwlr.IDENT_REC_NO = @in_UNIQUE_RECORD_NUM	
				and				
				fiwlr.pag_cd = RTRIM(LTRIM(isnull(cls_mapping.PAG,'??????')))
				and
				fiwlr.ETV_CODE = RTRIM(LTRIM(isnull(cls_mapping.ETV_CODE,'???????')))
				and
				LEN(RTRIM(LTRIM(isnull(cls_mapping.ANALYSIS_CD,''))))=0

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


		--5. map for PAG and ANALYSIS_CD and ETV_CODE
		UPDATE XX_R22_FIWLR_USDET_V3
		SET 
		ACCT_ID = cls_mapping.ACCT_ID
		FROM 
		XX_R22_FIWLR_USDET_V3 AS fiwlr
		INNER JOIN
		XX_R22_CLS_IMAPS_ACCT_MAP as cls_mapping
			ON (	
				fiwlr.STATUS_REC_NO = @in_STATUS_RECORD_NUM
				and
				fiwlr.IDENT_REC_NO = @in_UNIQUE_RECORD_NUM	
				and				
				fiwlr.pag_cd = RTRIM(LTRIM(isnull(cls_mapping.PAG,'??????')))
				and
				fiwlr.ANALYSIS_CODE = RTRIM(LTRIM(isnull(cls_mapping.ANALYSIS_CD,'???????')))
				and
				fiwlr.ETV_CODE = RTRIM(LTRIM(isnull(cls_mapping.ETV_CODE,'??????')))

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

		--6. voucher specific mappings go last to override everything
		UPDATE XX_R22_FIWLR_USDET_V3
		SET 
		ACCT_ID = cls_mapping.ACCT_ID
		FROM 
		XX_R22_FIWLR_USDET_V3 AS fiwlr
		INNER JOIN
		XX_R22_FIWLR_VCHR_ACCT_MAP as cls_mapping
			ON (
				fiwlr.STATUS_REC_NO = @in_STATUS_RECORD_NUM
				and
				fiwlr.IDENT_REC_NO = @in_UNIQUE_RECORD_NUM	
				and	
				fiwlr.voucher_no like cls_mapping.VCHR_START+'%'
			
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


			SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
			IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR		
	
	END


		--CR for non project required accounts
		update xx_r22_fiwlr_usdet_miscodes
		set proj_abbr_cd = null, proj_id=null, pag_cd=null
		where STATUS_REC_NO = @in_STATUS_RECORD_NUM
		AND	IDENT_REC_NO = @in_UNIQUE_RECORD_NUM
		and	acct_id is not null
		and
		acct_id in
		(select acct_id
		 from imar.deltek.acct
		 where len(acct_id)=8
		 and PROJ_REQD_FL='N')


	   			execute dbo.XX_R22_FIWLR_MISCODE_VALIDATE_RECORDS_SP
			        @in_STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM,
			        @in_VOUCHER_NO = null,
			        @in_UNIQUE_RECORD_NUM = @in_UNIQUE_RECORD_NUM ,
			        @out_STATUS_DESCRIPTION = @out_STATUS_DESCRIPTION 





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











GO


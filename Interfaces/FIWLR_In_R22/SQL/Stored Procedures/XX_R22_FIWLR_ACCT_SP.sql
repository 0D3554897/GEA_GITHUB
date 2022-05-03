USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_FIWLR_ACCT_SP]    Script Date: 1/19/2022 4:56:30 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO



CREATE OR ALTER PROCEDURE [dbo].[XX_R22_FIWLR_ACCT_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 		INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

DECLARE 
	@fiwlr_acct_id 			VARCHAR(10),
	@proj_proj_cd 			VARCHAR(10),
	@proj_pag_cd 			VARCHAR (40),
	@vflag					VARCHAR(1),
	@sp_name 				SYSNAME,
	@source_group			VARCHAR(2),
	@sourcewwer				VARCHAR(3),
	@vvoucher_no			VARCHAR(25),
	@vmajor					VARCHAR(3),
	@vminor					VARCHAR(4),
	@vsubminor				VARCHAR(4),
	@numberofrecords 		INT,
	@error_type				INT,
	@error_code				INT,
	@error_msg_placeholder1	SYSNAME,
	@error_msg_placeholder2 SYSNAME


/************************************************************************************************/
/* Procedure Name	: XX_R22_FIWLR_ACCT_SP														*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   							*/
/* Description    	: IMAPS FIW-LR Account1 Procedure											*/
/* Date				: August 10, 2008															*/
/* Notes			: IMAPS FIW-LR Account1 program will map the receieved major, minor and		*/
/*					  sub-minor to the account assigned in the account mapping table.			*/
/* Prerequisites	: XX_R22_FIWLR_USDET_V3 and XX_R22_CLS_IMPAS_ACCT_MAP Table(s) should be	*/
/*					  created.																	*/
/* Parameter(s)		: 																			*/
/*	Input			: Status Record Number														*/
/*	Output			: Error Code and Error Description											*/
/* Tables Updated	: XX_R22_FIWLR_USDET_V3 													*/
/* Version			: 1.0																		*/
/************************************************************************************************/
/* Date			Modified By				Description of change			  						*/
/* ----------   -------------  	   		------------------------    			  				*/
/* 08-10-2008   Veera Veeramachanane   	Created Initial Version                                */
/* 05-18-2015   Tatiana Perova          CR7905 Div24                                           */
/************************************************************************************************/

BEGIN
	SELECT  @sp_name	= 'XX_R22_FIWLR_ACCT_SP',
			@sourcewwer = '005'
			

-------------------/* Map major, minor and sub-minor to the account assigned in the XX_R22_CLS_IMPAS_ACCT_MAP table */

--account mapping logic

/* Regular account mapping logic with pag, value_add, analysis_cd, and etv code
	15. If Voucher number begins with ‘YJT’, use the following table for mapping transactions.  This mapping should override any mapping that may have resulted 
	using the FIWLR Mapping table.
*/

--1. map for blank PAG, ANALYSIS_CD, and ETV_CODE
	UPDATE	xx_r22_fiwlr_usdet_v3
	SET		acct_id = cls_mapping.acct_id
	FROM	xx_r22_fiwlr_usdet_v3 AS fiwlr
	INNER JOIN
			xx_r22_cls_imaps_acct_map as cls_mapping
	ON (				
		LEN(RTRIM(LTRIM(isnull(cls_mapping.pag,''))))=0
		AND
		LEN(RTRIM(LTRIM(isnull(cls_mapping.analysis_cd,''))))=0
		AND
		LEN(RTRIM(LTRIM(isnull(cls_mapping.etv_code,''))))=0

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

		SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
			IF @out_systemerror <> 0 
   				BEGIN
					SET @error_type = 1
					GOTO ErrorProcessing
   				END

--2. map for PAG, with blank ANALYSIS_CD, and ETV_CODE
	UPDATE	xx_r22_fiwlr_usdet_v3
	SET		acct_id = cls_mapping.acct_id
	FROM	xx_r22_fiwlr_usdet_v3 AS fiwlr
	INNER JOIN
			xx_r22_cls_imaps_acct_map as cls_mapping
	ON (				
		fiwlr.pag_cd = RTRIM(LTRIM(isnull(cls_mapping.pag,'??????')))
		AND
		LEN(RTRIM(LTRIM(isnull(cls_mapping.analysis_cd,''))))=0
		AND
		LEN(RTRIM(LTRIM(isnull(cls_mapping.etv_code,''))))=0

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

		SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
			IF @out_systemerror <> 0 
   				BEGIN
					SET @error_type = 2
					GOTO ErrorProcessing
   				END


--3. map for PAG and ANALYSIS_CD, with blank ETV_CODE
		UPDATE	xx_r22_fiwlr_usdet_v3
		SET		acct_id = cls_mapping.acct_id
		FROM	xx_r22_fiwlr_usdet_v3 AS fiwlr
		INNER JOIN
				xx_r22_cls_imaps_acct_map as cls_mapping
		ON (				
				fiwlr.pag_cd = RTRIM(LTRIM(isnull(cls_mapping.pag,'??????')))
		AND
				fiwlr.analysis_code = RTRIM(LTRIM(isnull(cls_mapping.analysis_cd,'???????')))
		AND
				LEN(RTRIM(LTRIM(isnull(cls_mapping.etv_code,''))))=0

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

		SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
			IF @out_systemerror <> 0 
   				BEGIN
					SET @error_type = 3
					GOTO ErrorProcessing
   				END

--4. map for PAG and ETV_CODE, with blank ANALYSIS_CD
		UPDATE	xx_r22_fiwlr_usdet_v3
		SET		acct_id = cls_mapping.acct_id
		FROM	xx_r22_fiwlr_usdet_v3 AS fiwlr
		INNER JOIN
				xx_r22_cls_imaps_acct_map as cls_mapping
		ON (				
				fiwlr.pag_cd = RTRIM(LTRIM(isnull(cls_mapping.pag,'??????')))
		AND
				fiwlr.etv_code = RTRIM(LTRIM(isnull(cls_mapping.etv_code,'???????')))
		AND
				LEN(RTRIM(LTRIM(isnull(cls_mapping.analysis_cd,''))))=0
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

		SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
			IF @out_systemerror <> 0 
   				BEGIN
					SET @error_type = 4
					GOTO ErrorProcessing
   				END

--5. map for PAG and ANALYSIS_CD and ETV_CODE
		UPDATE	xx_r22_fiwlr_usdet_v3
		SET		acct_id = cls_mapping.acct_id
		FROM	xx_r22_fiwlr_usdet_v3 AS fiwlr
		INNER JOIN
				xx_r22_cls_imaps_acct_map as cls_mapping
		ON (				
				fiwlr.pag_cd = RTRIM(LTRIM(isnull(cls_mapping.pag,'??????')))
		AND
				fiwlr.analysis_code = RTRIM(LTRIM(isnull(cls_mapping.analysis_cd,'???????')))
		AND
				fiwlr.etv_code = RTRIM(LTRIM(isnull(cls_mapping.etv_code,'??????')))

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

		SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
			IF @out_systemerror <> 0 
   				BEGIN
					SET @error_type = 5
					GOTO ErrorProcessing
   				END

--6. voucher specific mappings go last to override everything
		UPDATE	xx_r22_fiwlr_usdet_v3
		SET		acct_id = cls_mapping.acct_id
		FROM	xx_r22_fiwlr_usdet_v3 AS fiwlr
		INNER JOIN
				xx_r22_fiwlr_vchr_acct_map as cls_mapping
		ON (
				fiwlr.voucher_no like cls_mapping.vchr_start+'%'
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

		SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
			IF @out_systemerror <> 0 
   				BEGIN
					SET @error_type = 6
					GOTO ErrorProcessing
   				END



	
		--Zurich special account logic
		UPDATE XX_R22_FIWLR_USDET_V3
		SET 
			PROJ_ABBR_CD = NULL,
			PROJ_ID = NULL,
			ORG_ID = '22.Z'
		WHERE 
			DIVISION='YB'

	    UPDATE XX_R22_FIWLR_USDET_V3
		SET 
			ACCT_ID = '30-01-02'
		WHERE 
			DIVISION='YB'
		AND
			LEFT(MAJOR,1)='3'

		UPDATE XX_R22_FIWLR_USDET_V3
		SET 
			ACCT_ID = '40-01-02'
		WHERE 
			DIVISION='YB'
		AND
			LEFT(MAJOR,1)='4'


	    UPDATE XX_R22_FIWLR_USDET_V3
		SET 
			ACCT_ID = '82-18-02'
		WHERE 
			DIVISION='YB'
		AND
			LEFT(MAJOR,1) in ('6','7','8')

		UPDATE XX_R22_FIWLR_USDET_V3
		SET 
			ACCT_ID = '90-01-02'
		WHERE 
			DIVISION='YB'
		AND
			LEFT(MAJOR,1) in ('5','9')




		--CR for non project required accounts
		update xx_r22_fiwlr_usdet_v3
		set proj_abbr_cd = null, proj_id=null, pag_cd=null
		where acct_id is not null
		and
		acct_id in
		(select acct_id
		 from imar.deltek.acct
		 where len(acct_id)=8
		 and PROJ_REQD_FL='N')






		--CR6292 begin
		update xx_r22_fiwlr_usdet_v3
		set proj_abbr_cd=map.PROJ_ABBR_CD,
			proj_id= (select proj_id
					  from imar.deltek.proj
					  where proj_abbrv_cd=map.proj_abbr_cd),
			pag_cd=  (select acct_grp_cd
					  from imar.deltek.proj
					  where proj_abbrv_cd=map.proj_abbr_cd),
			org_abbr_cd=map.org_abbr_cd,
			org_id= (select org_id
					  from imar.deltek.org
					  where org_abbrv_cd=map.org_abbr_cd),
			acct_id=map.acct_id
		from 
		xx_r22_fiwlr_usdet_v3 fiw
		inner join
		XX_R22_FIWLR_MAPPING_OVERRIDE map
		on
		(	fiw.source=map.source
		and fiw.department=map.department
		and fiw.proj=map.proj
		and  fiw.DIVISION = map.DIVISION  --CR13342
		)
		--CR6292 end
			


RETURN 0
ErrorProcessing:

	IF @error_type = 1
   		BEGIN
      			SET @error_code = 204 -- Attempt to map for blank PAG, ANALYSIS_CD, and ETV_CODE to update XX_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'a record into table XX_FIWLR_USDET_V3'
   		END  

	ELSE IF @error_type = 2
   		BEGIN
      			SET @error_code = 204 -- Attempt to map for PAG, with blank ANALYSIS_CD, and ETV_CODE to update XX_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'a record into table XX_R22_FIWLR_USDET_V3'
   		END
	ELSE IF @error_type = 3
   		BEGIN
      			SET @error_code = 204 -- Attempt to map for PAG and ANALYSIS_CD, with blank ETV_CODE to update XX_FIWLR_USDET_V3 table failed.
			SET @error_msg_placeholder1 = 'update'
			SET @error_msg_placeholder2 = 'a record into table XX_R22_FIWLR_USDET_V3'
   		END
	ELSE IF @error_type = 4
   		BEGIN
      			SET @error_code = 204 -- Attempt to map for PAG and ETV_CODE, with blank ANALYSIS_CD to update XX_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'a record into table XX_R22_FIWLR_USDET_V3'
   		END
	ELSE IF @error_type = 5
   		BEGIN
      			SET @error_code = 204 -- Attempt to map for PAG and ANALYSIS_CD and ETV_CODE to update XX_FIWLR_USDET_V3 table failed.
			SET @error_msg_placeholder1 = 'update'
			SET @error_msg_placeholder2 = 'a record into table XX_R22_FIWLR_USDET_V3'
   		END
	ELSE IF @error_type = 6
   		BEGIN
      			SET @error_code = 204 -- Attempt to voucher specific mappings go last to override everything to update XX_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'a record into table XX_R22_FIWLR_USDET_V3'
   		END	

		EXEC dbo.xx_error_msg_detail
	         		@in_error_code           = 204,
	         		@in_sqlserver_error_code = @out_systemerror,
	         		@in_display_requested    = 1,
				@in_placeholder_value1		 = 'update',
		   		@in_placeholder_value2		 = 'XX_R22_FIWLR_USDET_V3',
	         		@in_calling_object_name  = @sp_name,
	         		@out_msg_text            = @out_status_description OUTPUT
	
RETURN 1
END
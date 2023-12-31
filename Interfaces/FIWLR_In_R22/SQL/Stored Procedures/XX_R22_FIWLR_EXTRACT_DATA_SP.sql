USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_FIWLR_EXTRACT_DATA_SP]    Script Date: 10/15/2017 20:11:50 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_R22_FIWLR_EXTRACT_DATA_SP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[XX_R22_FIWLR_EXTRACT_DATA_SP]
GO

CREATE PROCEDURE [dbo].[XX_R22_FIWLR_EXTRACT_DATA_SP] (
	@in_status_record_num 	INT, 
	@out_SystemError 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

DECLARE 
	@sourcegrp					VARCHAR(2), 	
	@source_wwer				VARCHAR(3), 
	@source_group_ap			VARCHAR(2),
	@source_group_je			VARCHAR(2),
	@numberofrecords 			INT,
	@error_type					INT,
	@error_code					INT,
	@error_msg_placeholder1		SYSNAME,
	@error_msg_placeholder2		SYSNAME,
	@sp_name					SYSNAME,
	@fiwlr_in_record_num 		INT,
    @ceris_passkey_value		VARCHAR(128),
    @ceris_keyname				VARCHAR(50),
    @ceris_passkey_value_param  VARCHAR(30),
    @ceris_keyname_param		VARCHAR(30),
    @ceris_interface_name		VARCHAR(50),
    @open_key					VARCHAR(400),
	@close_key					VARCHAR(400)
 
/************************************************************************************************/
/* Procedure Name	: XX_R22_FIWLR_EXTRACT_DATA_SP												*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   							*/
/* Description    	: IMAPS FIW-LR Extract Data Procedure										*/
/* Date				: August 10, 2008															*/
/* Notes			: IMAPS FIW-LR Extract Data program will be executed through FIW-LR Run		*/
/*					  interface to group the data from different sources received. This will	*/
/*			          categorize the sources to AP and JE based on the source group logic.		*/
/*					  Also, the program will update the date format to be in sync.				*/
/* Prerequisites	: XX_AOPUTLAP_INP_DETLV, XX_R22_FIWLR_INC_EXC_TEST, XX_R22_FIWLR_APSRC_GRP, */
/*					  XX_R22_FIWLR_USDET_ARCHIVE, XX_AOPUTLAP_INP_HDR_ERR,						*/
/*					  XX_AOPUTLAP_INP_DETL_ERR, XX_AOPUTLJE_INP_TR_ERR, XX_SEQUENCES_HDR,		*/
/*					  XX_SEQUENCES_DETL, XX_SEQUENCES_JE Table(s) should be created.			*/
/* Parameter(s)		: 																			*/
/*	Input			: Status Record Number														*/
/*	Output			: Error Code and Error Description											*/
/* Tables Updated	: XX_R22_FIWLR_USDET_V2 and XX_R22_FIWLR_USDET_V3 							*/
/* Version			: 1.0																		*/
/************************************************************************************************/
/* Date			Modified By				Description of change		  							*/
/* ----------   -------------  	   		------------------------    		  					*/
/* 08-10-2008   Veera Veeramachanane   	Created Initial Version									*/
/* 04-03-2012   KM					   	DR4626													*/
/* 06-28-2017   TP					   	CR9365  				 WWER vendor     				*/
/* 10-12-2017   Tatiana Perova          CR9841  Employee Last First name are not from IBM ledger*/
/************************************************************************************************/


BEGIN

-- set local constants

	SELECT	@sp_name = 'XX_R22_EXTRACT_DATA_SP',
			@error_msg_placeholder1	= NULL,
			@error_msg_placeholder2 = NULL,
			@source_group_ap = 'AP',
			@source_group_je = 'JE',
			@source_wwer 	 = '005',
			@ceris_interface_name = 'CERIS_R22',
			@ceris_passkey_value_param = 'PASSKEY_VALUE',
			@ceris_keyname_param = 'CERIS_KEYNAME'

	SELECT	@ceris_passkey_value = parameter_value
	FROM	dbo.xx_processing_parameters
	WHERE	parameter_name    = @ceris_passkey_value_param
	AND		interface_name_cd = @ceris_interface_name

	SELECT	@ceris_keyname = parameter_value
	FROM	dbo.xx_processing_parameters
	WHERE	parameter_name    = @ceris_keyname_param
	AND		interface_name_cd = @ceris_interface_name

-- Retrieve data from XX_FIWLR_USDET_V1 table recieved from FIW-LR 
	INSERT INTO dbo.xx_r22_fiwlr_usdet_v3 
       	        (
		status_rec_no,stream_id,ledger_type,major,minor,subminor,
		analysis_code,division,extract_date,fiwlr_inv_date,
		voucher_no,voucher_grp_no,wwer_exp_key,wwer_exp_dt,
		source,acct_month,acct_year,ap_idx,project_no,
		description1,description2,department,accountant_id,
		po_no,inv_no,etv_code,country_code,vendor_id,
		employee_no,amount,input_type,ap_doc_type,
		ref_creation_date,ref_creation_time,creation_date,
		source_group,vend_name,emp_lastname,emp_firstname,
		proj_id,proj_abbr_cd,org_id,org_abbr_cd,pag_cd,
		val_nval_cd,acct_id,
		order_ref,proj,hours,
		reference1,reference2,
		reference3,reference4,reference5 )
	SELECT
		@in_status_record_num,a.stream_id,a.ledger_type,a.major,a.minor,a.subminor,
		a.analysis_code,a.division,a.extract_date,a.fiwlr_inv_date,
		a.voucher_no,a.voucher_grp_no,a.wwer_exp_key,a.wwer_exp_dt,
		a.source,a.acct_month,a.acct_year,a.ap_idx,a.project_no,
		a.description1,a.description2,a.department,a.accountant_id,
		a.po_no,a.inv_no,a.etv_code,a.country_code,a.vendor_id,
		a.employee_no,a.amount,a.input_type,a.ap_doc_type,
		a.ref_creation_date,a.ref_creation_time,getdate(),
		a.source_group,a.vend_name,a.emp_lastname,a.emp_firstname,
		a.proj_id,a.proj_abbr_cd,a.org_id,a.org_abbr_cd,a.pag_cd,
		a.val_nval_cd,a.acct_id,
		a.order_ref, a.proj, a.hours,
		a.reference1,a.reference2,
		a.reference3,a.reference4,a.reference5
	FROM 	dbo.xx_r22_fiwlr_usdet_v1 a
 
		SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
			IF @out_systemerror <> 0 
   				BEGIN
					SET @error_type = 1
					GOTO ErrorProcessing
   				END
				
				
/* CR9365  GET WWER vendor data from XX_R22_FIWLR_WWER_EMPL table */
	UPDATE	dbo.xx_r22_fiwlr_usdet_v3
	SET VENDOR_ID = da.EMPLOYEE_NO, 
		VEND_NAME = LEFT(da.EMPLOYEE_NAME,30), 
		EMPLOYEE_NO = da.EMPLOYEE_NO, 
		EMP_LASTNAME = LEFT(CASE WHEN CHARINDEX(',',da.EMPLOYEE_NAME,1) > 0  Then LEFT(da.EMPLOYEE_NAME,CHARINDEX(',',da.EMPLOYEE_NAME,1)-1) else '' end , 30),
		EMP_FIRSTNAME = LEFT(CASE WHEN CHARINDEX(',',da.EMPLOYEE_NAME,1) > 0 Then  LTRIM(SUBSTRING(da.EMPLOYEE_NAME,CHARINDEX(',',da.EMPLOYEE_NAME,1)+1,LEN(da.EMPLOYEE_NAME)))
	    else '' end ,30)
	FROM  dbo.xx_r22_fiwlr_usdet_v3  ar
		INNER JOIN ( select EMPLOYEE_NO, VOUCHER_NO, ISNULL(EMPLOYEE_NAME,',') EMPLOYEE_NAME 
					 from dbo.XX_R22_FIWLR_WWER_EMPL ) da
			on ar.VOUCHER_NO = da.VOUCHER_NO

		SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
			IF @out_systemerror <> 0 
   				BEGIN
					SET @error_type = 12
					GOTO ErrorProcessing
   				END		
			

/* Group the extracted FIW-LR expense and ledger transactions with Vendor details into XX_R22_FIWLR_USDET_V3 table */
-- Retrieve Vendor details

		UPDATE	dbo.xx_r22_fiwlr_usdet_v3
		SET		vend_name = v.vend_name
		FROM	dbo.xx_r22_fiwlr_usdet_v3 as a
		INNER JOIN dbo.xx_r22_fiwlr_vend_v as v
		ON		a.vendor_id = v.vendor_id
		AND		a.vendor_id is not null
		and		LEN(LTRIM(RTRIM(a.vendor_id))) <> 0	


		SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
			IF @out_systemerror <> 0 
   				BEGIN
					SET @error_type = 2
					GOTO ErrorProcessing
   				END


				
-- Retrieve Employee details from Vendor  CR9841

		UPDATE	dbo.xx_r22_fiwlr_usdet_v3
		SET		emp_lastname = case when  rtrim(isnull(a.emp_lastname,'')) = ''  and rtrim(isnull(v.VEND_NAME,'')) <> '' then  
					SUBSTRING(v.VEND_NAME, 1, case when CHARINDEX(',',v.VEND_NAME,1) > 1  then CHARINDEX(',',v.VEND_NAME,1) -1 else 0 end) 
					else a.emp_lastname end,
				emp_firstname = case when  rtrim(isnull(a.emp_firstname,'')) = ''  and rtrim(isnull(v.VEND_NAME,'')) <> '' then  
					SUBSTRING(v.VEND_NAME,  CHARINDEX(',',v.VEND_NAME,1)+1, case when CHARINDEX(',',v.VEND_NAME,1) > 1 then  LEN(v.VEND_NAME) - CHARINDEX(',',v.VEND_NAME,1)  else 0 end)
					else a.emp_firstname end
		FROM	dbo.xx_r22_fiwlr_usdet_v3 as a
		INNER JOIN	IMAR.deltek.VEND v 
		ON		'R' + a.employee_no = v.VEND_ID
		AND		a.employee_no IS NOT NULL
		AND		LEN(LTRIM(RTRIM(a.employee_no))) <> 0		

		SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
			IF @out_systemerror <> 0 
   				BEGIN
					SET @error_type = 3 
					GOTO ErrorProcessing
   				END


-- Assign Source Group AP to the AP Sourced transactions

	UPDATE 	a
	SET 	a.source_group = @source_group_ap
	FROM 	dbo.xx_r22_fiwlr_usdet_v3 as a, 
			dbo.xx_r22_fiwlr_apsrc_grp as b
	WHERE 	a.source = b.source
	AND 	status_rec_no = @in_status_record_num;

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 4
				GOTO ErrorProcessing
   			END

--			Print 'Number of AP Records updated ' + CAST(@NumberOfRecords AS char)

-- Assign Source Group JE to the JE Sourced transactions

		UPDATE 	a
		SET 	a.source_group = @source_group_je
		FROM 	dbo.xx_r22_fiwlr_usdet_v3 as a
		WHERE 	a.source not in (	SELECT	b.source
			  						FROM 	dbo.xx_r22_fiwlr_apsrc_grp AS b)
		AND 	status_rec_no = @in_status_record_num

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 5 
				GOTO ErrorProcessing
   			END
				
--			Print 'Number of JE Records updated ' + CAST(@NumberOfRecords AS char)

-- Update Date format in XX_R22_FIWLR_USDET_V3 table to be in sync with all the date formats extracted

	UPDATE 	dbo.xx_r22_fiwlr_usdet_v3
	SET 	fiwlr_inv_date = CONVERT( VARCHAR(10),CAST((SUBSTRING(fiwlr_inv_date, 1, 2) + '-' + SUBSTRING(fiwlr_inv_date, 3, 2) + '-' + SUBSTRING(fiwlr_inv_date, 5, 2)) as DATETIME),120)
	WHERE 	source <> @source_wwer
	AND 	fiwlr_inv_date <> ' '
	AND 	status_rec_no = @in_status_record_num

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 6 
				GOTO ErrorProcessing
   			END
--			Print 'Number of date records updated ' + CAST(@numberofrecords AS char)

/* Update XX_R22_FIWLR_USDET_V3 table for source 005 employee lastname/firstname for vend_name */
	UPDATE	imapsstg.dbo.xx_r22_fiwlr_usdet_v3
	SET		vendor_id = employee_no,
			vend_name = SUBSTRING((LTRIM(RTRIM(emp_lastname)) + ',' + LTRIM(RTRIM(emp_firstname))),1,25),
			reference1 = SUBSTRING((LTRIM(RTRIM(emp_lastname)) + ',' + LTRIM(RTRIM(emp_firstname))),1,40)
	WHERE	len(ltrim(rtrim(vendor_id))) = 0
	AND		source	= @source_wwer

	
	UPDATE	xx_r22_fiwlr_usdet_v3
	SET		vend_name=vendor_id
	WHERE	vend_name is null
	/*AND		source=@source_wwer    defect*/

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 7 
				GOTO ErrorProcessing
   			END

	/*UPDATE XX_R22_FIWLR_USDET_V3 with employee_no in REFERENCE5 COLUMN FOR WWER LATER USE*/

	SET @OPEN_KEY = 'OPEN SYMMETRIC KEY' + '  ' + @CERIS_KEYNAME + '  ' + 'DECRYPTION BY PASSWORD = ''' +  @CERIS_PASSKEY_VALUE + '''' + '  '
	SET @CLOSE_KEY = 'CLOSE SYMMETRIC KEY' + '  ' + @CERIS_KEYNAME

	EXEC (@OPEN_KEY)

	UPDATE	dbo.xx_r22_fiwlr_usdet_v3
	SET		reference5 = b.empl_id
	FROM	dbo.xx_r22_fiwlr_usdet_v3 a
	INNER JOIN
			dbo.xx_r22_ceris_empl_id_map b
	on		-- source= @source_wwer  AND  for all employee by  CR9841
			a.employee_no = LTRIM(RTRIM(CONVERT(VARCHAR(50),DECRYPTBYKEY(b.r_empl_id))))

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 8 
				GOTO ErrorProcessing
   			END
--			Print 'Number of date records updated ' + CAST(@numberofrecords AS char)

--PRINT	'EMPLID is ' + @empl_id
 
	EXEC(@close_key)
	
	-- Retrieve Employee details  CR9841

		UPDATE	dbo.xx_r22_fiwlr_usdet_v3
		SET		emp_lastname = case when  rtrim(isnull(a.emp_lastname,'')) = ''  and rtrim(isnull(e.LAST_NAME,'')) <> '' then  e.LAST_NAME else a.emp_lastname end,
				emp_firstname = case when  rtrim(isnull(a.emp_firstname,'')) = ''  and rtrim(isnull(e.FIRST_NAME,'')) <> '' then  e.FIRST_NAME else a.emp_firstname end
		FROM	dbo.xx_r22_fiwlr_usdet_v3 as a
		INNER JOIN	IMAR.deltek.EMPL e 
		ON		a.REFERENCE5 = e.EMPL_ID
		AND		a.employee_no IS NOT NULL
		AND		LEN(LTRIM(RTRIM(a.employee_no))) <> 0		

		SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
			IF @out_systemerror <> 0 
   				BEGIN
					SET @error_type = 3 
					GOTO ErrorProcessing
   				END


	/*UPDATE XX_R22_FIWLR_USDET_V3 with vendor_id to have an R in front of it*/
	UPDATE	imapsstg.dbo.xx_r22_fiwlr_usdet_v3
	SET		vendor_id = 'R'+LTRIM(RTRIM(vendor_id))
	WHERE	LEN(LTRIM(RTRIM(vendor_id))) > 0
	AND	source_group = 'AP'

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 9 
				GOTO ErrorProcessing
   			END
--			Print 'Number of date records updated ' + CAST(@numberofrecords AS char)


	--CR for excluding CLS accounts
	delete xx_r22_fiwlr_usdet_v3
	from 
	xx_r22_fiwlr_usdet_v3 v3
	inner join
	xx_r22_fiwlr_exclude_major_minor exclude
	on
	(
	 v3.major=exclude.major
	and
	 v3.minor=exclude.minor
	)

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 10
				GOTO ErrorProcessing
   			END


	--DR4626
	update xx_r22_fiwlr_usdet_v3
	set	vendor_id=replace(replace(replace(replace(vendor_id, '"', ''), 'Ÿ0', ''), 'Ÿ', ''),char(0),''),
		vend_name=replace(replace(replace(replace(vend_name, '"', ''), 'Ÿ0', ''), 'Ÿ', ''),char(0),''),
		order_ref=replace(replace(replace(replace(order_ref, '"', ''), 'Ÿ0', ''), 'Ÿ', ''),char(0),'')
	where 
	vendor_id like '%Ÿ%'
	or order_ref like '%Ÿ%'
	or vend_name like '%Ÿ%'
	or vendor_id like '%'+char(0)+'%'
	or order_ref like '%'+char(0)+'%'
	or vend_name like '%'+char(0)+'%'

	SELECT @out_systemerror = @@ERROR,  @numberofrecords = @@ROWCOUNT
		IF @out_systemerror <> 0 
   			BEGIN
				SET @error_type = 11
				GOTO ErrorProcessing
   			END




RETURN 0

ErrorProcessing:

	IF @error_type = 1
   		BEGIN
      			SET @error_code = 204 -- Attempt to insert a record into table XX_FIWLR_USDET_V3 failed.
      			SET @error_msg_placeholder1 = 'insert'
      			SET @error_msg_placeholder2 = 'a record into table XX_FIWLR_USDET_V3'
   		END  

	ELSE IF @error_type = 2
   		BEGIN
      			SET @error_code = 204 -- Attempt to update records with Vendor details in XX_R22_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'records with Vendor details in XX_R22_FIWLR_USDET_V3'
   		END
	ELSE IF @error_type = 3
   		BEGIN
      			SET @error_code = 204 -- Attempt to update records with employee details in XX_R22_FIWLR_USDET_V3 table failed.
			SET @error_msg_placeholder1 = 'update'
			SET @error_msg_placeholder2 = 'records with employee details in XX_R22_FIWLR_USDET_V3'
   		END
	ELSE IF @error_type = 4
   		BEGIN
      			SET @error_code = 204 -- Attempt to update records with AP source group in XX_R22_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'records with AP source group in XX_R22_FIWLR_USDET_V3'
   		END
	ELSE IF @error_type = 5
   		BEGIN
      			SET @error_code = 204 -- Attempt to update records with JE source group in XX_R22_FIWLR_USDET_V3 table failed.
			SET @error_msg_placeholder1 = 'update'
			SET @error_msg_placeholder2 = 'records with JE source group in XX_R22_FIWLR_USDET_V3'
   		END
	ELSE IF @error_type = 6
   		BEGIN
      			SET @error_code = 204 -- Attempt to update records with date format in XX_R22_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'records with date format into table XX_R22_FIWLR_USDET_V3'
   		END
	ELSE IF @error_type = 7
   		BEGIN
      			SET @error_code = 204 -- Attempt to update records with employee lastname/firstname for vend_name in XX_R22_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'records with employee lastname/firstname into table XX_R22_FIWLR_USDET_V3'
   		END
	ELSE IF @error_type = 8
   		BEGIN
      			SET @error_code = 204 -- Attempt to update records for source 005 with IMAPS serial number in reference 5 in XX_R22_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'records for source 005 with IMAPS serial number in reference 5XX_R22_FIWLR_USDET_V3'
   		END
	ELSE IF @error_type = 9
   		BEGIN
      			SET @error_code = 204 -- Attempt to update records with vendor_id to have an R as prefix in XX_R22_FIWLR_USDET_V3 table failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'records with vendor_id to have an R as prefix in XX_R22_FIWLR_USDET_V3'
   		END
	ELSE IF @error_type = 10
   		BEGIN
      			SET @error_code = 204 -- 
      			SET @error_msg_placeholder1 = 'exclude'
      			SET @error_msg_placeholder2 = 'CLS accounts'
   		END
	--DR4626
	ELSE IF @error_type = 11
   		BEGIN
      			SET @error_code = 204 -- 
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'records for DR4626 special characters'
   		END


	EXEC dbo.xx_error_msg_detail
	       		@in_error_code           = @error_code,
	       		@in_sqlserver_error_code = @out_systemerror,
	       		@in_display_requested    = 1,
				@in_placeholder_value1   = @error_msg_placeholder1,
				@in_placeholder_value2   = @error_msg_placeholder2,
	        	@in_calling_object_name  = @sp_name,
	        	@out_msg_text            = @out_status_description OUTPUT


RETURN 1
END






GO



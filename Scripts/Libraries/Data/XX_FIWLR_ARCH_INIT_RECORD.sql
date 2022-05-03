DELETE FROM dbo.xx_fiwlr_usdet_archive 

	INSERT INTO dbo.xx_fiwlr_usdet_archive 
	      (	status_rec_no,stream_id,ledger_type,
		major,minor,subminor,analysis_code,
		division,extract_date,fiwlr_inv_date,voucher_no,
		voucher_grp_no,wwer_exp_key,wwer_exp_dt,
		source,acct_month,acct_year,ap_idx,project_no,
		description1,description2,department,accountant_id,
		po_no,inv_no,etv_code,country_code,
		vendor_id,employee_no,amount,input_type,
		ap_doc_type,ref_creation_date,ref_creation_time,creation_date,
		source_group,vend_name,emp_lastname,emp_firstname,
		proj_id,proj_abbr_cd,org_id,org_abbr_cd,
		pag_cd,val_nval_cd,acct_id )
	VALUES( 1,'US','L','816','0100','0000',NULL,'16','20050929',
		NULL,'INITVCH',NULL,NULL,NULL,'060','09','2005',NULL,
		'Q57Y','LABOR DISTRIBUTION',NULL,'D6S','E001',NULL,NULL,
		NULL,'897',NULL,NULL,1136.54,'F',NULL,'20050929','191021174',
		getdate(),'JE',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)

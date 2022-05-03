USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_FIWLR_ACCT1_SP]    Script Date: 11/15/2016 10:55:00 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_FIWLR_ACCT1_SP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[XX_FIWLR_ACCT1_SP]
GO

USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_FIWLR_ACCT1_SP]    Script Date: 11/15/2016 10:55:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO





CREATE PROCEDURE [dbo].[XX_FIWLR_ACCT1_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

DECLARE 
	@fiwlr_acct_id 	VARCHAR(10),
	@proj_proj_cd 	VARCHAR(10),
	@proj_pag_cd 	VARCHAR (40),
	--@proj_proj_id VARCHAR(10),
	--@proj_org_id 	VARCHAR(40),
	@inc_exc_fl	VARCHAR(1),
	@vflag		VARCHAR(1),
	@sp_name 	SYSNAME,
	@source_group	VARCHAR(2),
	@sourcewwer	VARCHAR(3),
	@sourcewwern16	VARCHAR(3),
--	Start Added by Veera on 12/22/2005 Defect: DEV00000390
	@vvoucher_no	VARCHAR(25),
	@vmajor		VARCHAR(3),
	@vminor		VARCHAR(4),
	@vsubminor	VARCHAR(4)
--	End Added by Veera on 12/22/2005 Defect: DEV00000390

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_ACCT1_SP							*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR Account1 Procedure					*/
/* Date			: October 22, 2005						        */
/* Notes		: IMAPS FIW-LR Account1 program will map the receieved major, minor and */
/*			  sub-minor to the account assigned in the account mapping table.	*/
/* Prerequisites	: XX_FIWLR_USDET_V3 and XX_CLS_IMPAS_ACCT_MAP Table(s) should be created*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: XX_FIWLR_USDET_V3 							*/
/* Version		: 1.4									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 10-22-2005   Veera Veeramachanane   	Created Initial Version					*/
/* 11-22-2005   Veera Veeramachanane   	Modified Code to fix the value from minor to subminor	*/					
/*					Defect : DEV0000269					*/
/* 12-22-2005   Veera Veeramachanane   	Incorporated latest enhancement to derive account for	*/
/*					AP and JE transactions which are populated with project */
/*					to lookup CLS -IMAPS account mapping tables where 	*/
/*					analysis code is null. 					*/					
/*					Defect : DEV00000390					*/
/* 02-02-2006   Veera Veeramachanane   	Improved performance of the program by added DISTINCT	*/
/*					in Cursor definition.					*/					
/* 05-02-2006	Keith McGuire		The order of the updates is important 			*/
/*					Cursors are slow					*/
/*					This code is messy, but that's how they asked for it	*/

/*
	Date		Modified By		Description of change	
   ----------   -------------	------------------------ 
   2010-09-13	KM				1M changes  Division added to account mapping

CR6295 - Div1P - KM - 2013-04-29
For the purposes of FIWLR account mappings, evaluate 1P as if it is the same as 16

CR8762  Div2G TP 2016-11-03
For the purposes of FIWLR account mappings, evaluate @G as if it is the same as 16
*/

/************************************************************************************************/

BEGIN
	SELECT  @sp_name = 'XX_FIWLR_ACCT1_SP',
		@inc_exc_fl = 'I',
		@sourcewwer = '005',
		@sourcewwern16 = 'N16'
--		@vflag	= 'N', -- Commented by Veera on 12/22/2005 Defect : DEV00000390
--		@source_group = 'AP', -- Commented by Veera on 12/22/2005 Defect : DEV00000390
		

/* Map major, minor and sub-minor to the account assigned in the XX_CLS_IMPAS_ACCT_MAP table */
/* KEITH TEST
	DECLARE xx_fiwlr_acctv CURSOR FOR
	
		SELECT 	DISTINCT a.proj_abbrv_cd,c.acct_id, c.pag,
			v.voucher_no,v.major, v.minor, v.subminor  -- Added by Veera on 12/22/2005 Defect: DEV00000390
		FROM	dbo.xx_cls_imaps_acct_map c,
			dbo.xx_fiwlr_usdet_v3 v,
			imaps.deltek.proj a
		WHERE	v.source 	NOT IN (@sourcewwer, @sourcewwern16)
		AND	v.project_no 	= a.proj_abbrv_cd
		AND	v.proj_abbr_cd 	= a.proj_abbrv_cd
		AND	c.pag 		= a.acct_grp_cd
		AND	c.analysis_cd 	IS NULL  -- Added by Veera on 12/22/2005 Defect : DEV00000390
--		AND	c.val_non_val_fl= @vflag -- Commented by Veera on 12/22/2005 Defect : DEV00000390
		AND	v.project_no 	<> ' '
		AND	v.status_rec_no = @in_status_record_num
		AND	c.inc_exc_fl 	= @inc_exc_fl 
		AND	v.major		>= (CASE 	WHEN c.major_1 = '***' 		THEN  v.major 
							WHEN c.major_1 = ' '   		THEN v.major 
							ELSE c.major_1 
					   END )
		AND 	v.major		<= (CASE	WHEN c.major_2 = '***' 		THEN v.major 

							WHEN c.major_2 = ' '   		THEN v.major
							ELSE c.major_2 
					   END )
		AND	v.minor		>= (CASE  	WHEN c.minor_1 = '****' 	THEN v.minor
						  	WHEN c.minor_1 = ' ' 		THEN v.minor
						  	ELSE c.minor_1 
					   END )
		AND	v.minor 	<= (CASE  	WHEN minor_2 = '****' 		THEN v.minor
						  	WHEN minor_2 = ' ' 		THEN v.minor
						  	ELSE minor_2 
					   END)
		AND	v.subminor 	>= (CASE  	WHEN c.sub_minor_1 = '****' 	THEN v.subminor
						  	WHEN c.sub_minor_1 = ' ' 	THEN v.subminor -- Added by Veera on 11/22/2005 Defect : DEV0000269
						  	ELSE c.sub_minor_1 
					   END )
		AND	v.subminor 	<= (CASE  	WHEN c.sub_minor_2 = '****' 	THEN v.subminor
						  	WHEN c.sub_minor_2 = ' ' 	THEN v.subminor
						  	ELSE c.sub_minor_2 
					   END)

	OPEN xx_fiwlr_acctv
--	FETCH NEXT FROM  xx_fiwlr_acctv INTO @proj_proj_cd, @fiwlr_acct_id, @proj_pag_cd
	FETCH NEXT FROM  xx_fiwlr_acctv INTO @proj_proj_cd, @fiwlr_acct_id, @proj_pag_cd, @vvoucher_no, @vmajor, @vminor, @vsubminor --	12/22/2005 Defect: DEV00000390
	WHILE (@@fetch_status = 0)
		BEGIN
			-- for each major, minor and sub-minor combination retrieve the assigned account
			UPDATE 	v
			SET 	acct_id = @fiwlr_acct_id
			FROM 	dbo.xx_fiwlr_usdet_v3 v,
				imaps.deltek.proj a,
				dbo.xx_cls_imaps_acct_map c
			WHERE 	v.source 	NOT IN (@sourcewwer, @sourcewwern16)
			AND	v.proj_abbr_cd	<> ' '
			AND	v.proj_abbr_cd 	= a.proj_abbrv_cd
			AND	v.project_no 	= @proj_proj_cd
			AND	c.pag		= @proj_pag_cd
			AND	v.status_rec_no = @in_status_record_num
			AND	c.pag 		= a.acct_grp_cd
			AND	c.inc_exc_fl 	= @inc_exc_fl
			AND	c.analysis_cd 	IS NULL
--			AND	v.source_group 	= @source_group -- Commented by Veera on 12/22/2005 Defect : DEV00000390
			AND	v.voucher_no	= @vvoucher_no
			AND	v.major		= @vmajor
			AND	v.minor		= @vminor
			AND	v.subminor	= @vsubminor

			SELECT @out_systemerror = @@ERROR
			IF @out_systemerror <> 0  
				GOTO ErrorProcessing	
		
--	FETCH NEXT FROM  xx_fiwlr_acctv INTO @proj_proj_cd, @fiwlr_acct_id, @proj_pag_cd
	FETCH NEXT FROM  xx_fiwlr_acctv INTO @proj_proj_cd, @fiwlr_acct_id, @proj_pag_cd, @vvoucher_no, @vmajor, @vminor, @vsubminor
	END

	SELECT @out_systemerror = @@ERROR
	IF @out_systemerror <> 0  
		GOTO ErrorProcessing	

	CLOSE xx_fiwlr_acctv
	DEALLOCATE xx_fiwlr_acctv */




UPDATE 	usdetv3
SET	usdetv3.ACCT_ID = cls_mapping.ACCT_ID
FROM 
dbo.XX_FIWLR_USDET_V3 AS usdetv3
INNER JOIN
dbo.XX_CLS_IMAPS_ACCT_MAP as cls_mapping
	ON (

	--CR6295,CR8762 
		CASE WHEN usdetv3.DIVISION IN ('2G','1P') THEN '16' ELSE usdetv3.DIVISION END = cls_mapping.division
	AND
		usdetv3.pag_cd	=  cls_mapping.PAG
	
	AND	usdetv3.major		>= (CASE 	WHEN cls_mapping.major_1 = '***' 	THEN usdetv3.major 
							WHEN cls_mapping.major_1 = ' '   	THEN usdetv3.major 
							ELSE cls_mapping.major_1 
					   END )
	AND 	usdetv3.major		<= (CASE	WHEN cls_mapping.major_2 = '***' 	THEN usdetv3.major 
							WHEN cls_mapping.major_2 = ' '   	THEN usdetv3.major
							ELSE cls_mapping.major_2 
					   END )
	AND	usdetv3.minor		>= (CASE  	WHEN cls_mapping.minor_1 = '****' 	THEN usdetv3.minor
						  	WHEN cls_mapping.minor_1 = ' ' 		THEN usdetv3.minor
						  	ELSE cls_mapping.minor_1 
					   END )
	AND	usdetv3.minor 		<= (CASE  	WHEN cls_mapping.minor_2 = '****' 	THEN usdetv3.minor
						  	WHEN cls_mapping.minor_2 = ' ' 		THEN usdetv3.minor
						  	ELSE cls_mapping.minor_2 
					   END)
	AND	usdetv3.subminor 	>= (CASE  	WHEN cls_mapping.sub_minor_1 = '****' 	THEN usdetv3.subminor
						  	WHEN cls_mapping.sub_minor_1 = ' ' 	THEN usdetv3.subminor -- Added by Veera on 11/22/2005 Defect : DEV0000269
						  	ELSE cls_mapping.sub_minor_1 
					   END )
	AND	usdetv3.subminor 	<= (CASE  	WHEN cls_mapping.sub_minor_2 = '****' 	THEN usdetv3.subminor
						  	WHEN cls_mapping.sub_minor_2 = ' ' 	THEN usdetv3.subminor
						  	ELSE cls_mapping.sub_minor_2 
					   END)
	AND	cls_mapping.analysis_cd is null
	)
WHERE	usdetv3.SOURCE NOT IN  (@sourcewwer, @sourcewwern16)
and	usdetv3.STATUS_REC_NO = @in_STATUS_RECORD_NUM
and	usdetv3.PROJ_ABBR_CD <> ' '
and	usdetv3.PROJECT_NO <> ' '
and	cls_mapping.inc_exc_fl = @inc_exc_fl


	SELECT @out_systemerror = @@ERROR
	IF @out_systemerror <> 0  
		GOTO ErrorProcessing	



RETURN 0
ErrorProcessing:
	

		EXEC dbo.xx_error_msg_detail
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


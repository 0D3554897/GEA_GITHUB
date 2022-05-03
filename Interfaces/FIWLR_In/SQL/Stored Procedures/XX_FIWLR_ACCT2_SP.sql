USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_FIWLR_ACCT2_SP]    Script Date: 11/15/2016 11:00:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_FIWLR_ACCT2_SP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[XX_FIWLR_ACCT2_SP]
GO

USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_FIWLR_ACCT2_SP]    Script Date: 11/15/2016 11:00:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO






CREATE PROCEDURE [dbo].[XX_FIWLR_ACCT2_SP] (
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
	@vflagy		VARCHAR(1),
	@vflagn		VARCHAR(1),
	@sp_name 	SYSNAME,
	@source_group	VARCHAR(2),
	@sourcewwer	VARCHAR(3),
	--@sourcewwern16	VARCHAR(3),  Commented by Clare 2/13/06
	@vvoucher_no	VARCHAR(25),
	@vmajor		VARCHAR(3),
	@vminor		VARCHAR(4),
	@vsubminor	VARCHAR(4),
	@vanal_cd	VARCHAR(4)  -- Added by Veera on 02/01/06

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_ACCT2_SP							*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR Account2 Procedure					*/
/* Date			: October 22, 2005						        */
/* Notes		: IMAPS FIW-LR Account1 program will map the receieved major, minor,	*/
/*			  sub-minor and analysis code to the account assigned in the account 	*/
/*			  mapping table.							*/
/* Prerequisites	: XX_FIWLR_USDET_V3 and XX_CLS_IMPAS_ACCT_MAP Table(s) should be created*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number							*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: XX_FIWLR_USDET_V3 							*/
/* Version		: 1.3									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 10-22-2005   Veera Veeramachanane   	Created Initial Version					*/
/* 11-22-2005   Veera Veeramachanane   	Modified Code to lookup the employee verification flag 	*/
/*					to determine the employee exists in division 16		*/
/*					Defect : DEV0000269					*/
/* 12-22-2005   Veera Veeramachanane   	Incorporated latest enhancement to derive account for	*/
/*					AP and JE transactions which are populated with project */
/*					to lookup CLS -IMAPS account mapping tables where 	*/
/*					analysis code is null. 					*/
/*					Defect : DEV00000390					*/
/* 02-02-2006   Veera Veeramachanane   	Improved performance Reference: DEV00000497		*/
/* 02-13-2006   Clare Robbins		N16 requires special logic to charge all to specific acct.  Ref CR? and DEV00000479	*/
/* 03-22-2006   Clare Robbins		Only join to analysis code and value add flag when necessary.  DEV00000624 */
/* 05-02-2006	Keith McGuire		The order of the updates is important 			*/
/*					Cursors are slow					*/
/*					This code is messy, but that's how they asked for it	*/

/*
	Date		Modified By		Description of change	
   ----------   -------------	------------------------ 
   2010-09-13	KM				1M changes  Division added to account mapping

CR6295 - Div1P - KM - 2013-04-29
For the purposes of FIWLR account mappings, evaluate 1P as if it is the same as 16

CR6640 - FIWLR transactions containing ETV code needs correct CP account - KM - 2013-09-26
source 060 payroll ETV code account mapping logic


CR8762 - Div2G - TP - 2016-11-03
For the purposes of FIWLR account mappings, evaluate 2G as if it is the same as 16

*/
/************************************************************************************************/

BEGIN

	SELECT  @sp_name = 'XX_FIWLR_ACCT2_SP',
		@inc_exc_fl = 'I',
		@source_group = 'AP',
		@sourcewwer = '005'
--		@vflagy	= 'Y', -- Commented by Veera on 12/22/2005 Defect: DEV00000390
--		@vflagn	= 'N', -- Commented by Veera on 12/22/2005 Defect: DEV00000390
--		@sourcewwern16 = 'N16'  Commented by Clare 2/13/06




/* Map major, minor, sub-minor and  analysis code to the account assigned in the XX_CLS_IMPAS_ACCT_MAP table */

/*KEITH TEST
DECLARE xx_fiwlr_acctv CURSOR FOR
	
		SELECT 	DISTINCT a.proj_abbrv_cd,c.acct_id, c.pag,
			v.voucher_no,v.major, v.minor, v.subminor,
			v.analysis_code   -- Added by Veera on 02/01/06	to improve performance 			
		FROM	dbo.xx_cls_imaps_acct_map c,
			dbo.xx_fiwlr_usdet_v3 v,
			imaps.deltek.proj a
--		WHERE	v.source 	IN (@sourcewwer, @sourcewwern16) Commented by Clare 2/13/06
		WHERE	v.source 	= @sourcewwer --Added by Clare 2/13/06
		AND	v.source_group 	= @source_group
		AND	v.proj_abbr_cd 	= a.proj_abbrv_cd
		AND	c.pag 		= a.acct_grp_cd
		--AND	v.analysis_code = c.analysis_cd   --commented and moved below by Clare DEV00000624
		--AND	c.val_non_val_fl= v.val_nval_cd -- Added by Veera on 11/15/2005 Defect : DEV0000269   --commented and moved below by Clare DEV00000624
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
		--Below added by Clare Robbins on 3/22/06 for defect DEV00000624
		AND	v.analysis_code = (CASE		WHEN c.analysis_cd is null	THEN v.analysis_code
							ELSE c.analysis_cd
						END)
		AND	v.val_nval_cd = (CASE		WHEN c.val_non_val_fl is null	THEN v.val_nval_cd
							ELSE c.val_non_val_fl
					END)

	OPEN xx_fiwlr_acctv
--	FETCH NEXT FROM  xx_fiwlr_acctv INTO @proj_proj_cd, @fiwlr_acct_id, @proj_pag_cd
-- 	Modified by Veera on 02/01/06 to improve performance
--	FETCH NEXT FROM  xx_fiwlr_acctv INTO @proj_proj_cd, @fiwlr_acct_id, @proj_pag_cd, @vvoucher_no, @vmajor, @vminor, @vsubminor
	FETCH NEXT FROM  xx_fiwlr_acctv INTO @proj_proj_cd, @fiwlr_acct_id, @proj_pag_cd, @vvoucher_no, @vmajor, @vminor, @vsubminor, @vanal_cd

	WHILE (@@fetch_status = 0)
		BEGIN
			-- for each major, minor, sub-minor and  analysis code combination retrieve the assigned account
			UPDATE 	v
			SET 	acct_id = @fiwlr_acct_id
			FROM 	dbo.xx_fiwlr_usdet_v3 v,
				imaps.deltek.proj a,
				dbo.xx_cls_imaps_acct_map c
			WHERE 	v.proj_abbr_cd 	= a.proj_abbrv_cd
			AND	v.analysis_code = c.analysis_cd 
			AND	v.analysis_code = @vanal_cd   -- Added by Veera on 02/01/06 to improve performance 			
			AND	v.project_no	<> ' '
			AND	v.proj_abbr_cd 	= @proj_proj_cd
			AND	v.proj_abbr_cd	<> ' '
			AND	v.project_no 	= @proj_proj_cd
			AND	c.pag		= @proj_pag_cd
			AND	v.status_rec_no = @in_status_record_num
			AND	v.source_group 	= @source_group
--			AND	v.source 	IN (@sourcewwer, @sourcewwern16) -- Added by Veera on 11/15/05 DEV00000269, commented by Clare 2/13/06
			AND	v.source 	= @sourcewwer -- Added by Clare 2/13/06
			AND	c.pag 		= a.acct_grp_cd
			AND	c.val_non_val_fl= v.val_nval_cd -- Added by Veera on 12/22/2005 Defect : DEV00000390
		--	AND	c.val_non_val_fl= @vflagy
			AND	c.inc_exc_fl 	= @inc_exc_fl
			AND	v.voucher_no	= @vvoucher_no
			AND	v.major		= @vmajor
			AND	v.minor		= @vminor
			AND	v.subminor	= @vsubminor
	
			SELECT @out_systemerror = @@ERROR
			IF @out_systemerror <> 0  
				GOTO ErrorProcessing	
		
--	FETCH NEXT FROM  xx_fiwlr_acctv INTO @proj_proj_cd, @fiwlr_acct_id, @proj_pag_cd
-- 	Modified by Veera on 02/01/06	to improve performance
--	FETCH NEXT FROM  xx_fiwlr_acctv INTO @proj_proj_cd, @fiwlr_acct_id, @proj_pag_cd, @vvoucher_no, @vmajor, @vminor, @vsubminor
	FETCH NEXT FROM  xx_fiwlr_acctv INTO @proj_proj_cd, @fiwlr_acct_id, @proj_pag_cd, @vvoucher_no, @vmajor, @vminor, @vsubminor, @vanal_cd
	
	END

	SELECT @out_systemerror = @@ERROR
	IF @out_systemerror <> 0  
		GOTO ErrorProcessing	

	CLOSE xx_fiwlr_acctv
	DEALLOCATE xx_fiwlr_acctv */



--BEGIN CHANGE KM 06-19-06
-- update from generic to specific
-- order is important


--analysis_code and val_nval_fl are both null
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
	
	AND	usdetv3.major		>= (CASE 	WHEN cls_mapping.major_1 = '***' 	THEN  usdetv3.major 
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
	AND	cls_mapping.val_non_val_fl is null
)
WHERE	usdetv3.SOURCE = @sourcewwer
and	usdetv3.SOURCE_GROUP = @source_group
and	usdetv3.PROJECT_NO <> ' '
and	usdetv3.STATUS_REC_NO = @in_STATUS_RECORD_NUM
and	usdetv3.PROJ_ABBR_CD <> ' '
and	usdetv3.PROJECT_NO <> ' '
and	cls_mapping.inc_exc_fl = @inc_exc_fl



--analysis_code is null and val_nval_fl is not null
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
	
	AND	usdetv3.major		>= (CASE 	WHEN cls_mapping.major_1 = '***' 	THEN  usdetv3.major 
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
	AND	usdetv3.val_nval_cd = cls_mapping.val_non_val_fl
)
WHERE	usdetv3.SOURCE = @sourcewwer
and	usdetv3.SOURCE_GROUP = @source_group
and	usdetv3.PROJECT_NO <> ' '
and	usdetv3.STATUS_REC_NO = @in_STATUS_RECORD_NUM
and	usdetv3.PROJ_ABBR_CD <> ' '
and	usdetv3.PROJECT_NO <> ' '
and	cls_mapping.inc_exc_fl = @inc_exc_fl




--analysis_code is not null and val_nval_fl is null
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
	
	AND	usdetv3.major		>= (CASE 	WHEN cls_mapping.major_1 = '***' 	THEN  usdetv3.major 
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
	AND	usdetv3.analysis_code = cls_mapping.analysis_cd
	AND	cls_mapping.val_non_val_fl is null
)
WHERE	usdetv3.SOURCE = @sourcewwer
and	usdetv3.SOURCE_GROUP = @source_group
and	usdetv3.PROJECT_NO <> ' '
and	usdetv3.STATUS_REC_NO = @in_STATUS_RECORD_NUM
and	usdetv3.PROJ_ABBR_CD <> ' '
and	usdetv3.PROJECT_NO <> ' '
and	cls_mapping.inc_exc_fl = @inc_exc_fl


--analysis_code is not null and val_nval_fl is not null
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
	
	AND	usdetv3.major		>= (CASE 	WHEN cls_mapping.major_1 = '***' 	THEN  usdetv3.major 
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
	AND	usdetv3.analysis_code = cls_mapping.analysis_cd
	AND	usdetv3.val_nval_cd = cls_mapping.val_non_val_fl
)
WHERE	usdetv3.SOURCE = @sourcewwer
and	usdetv3.SOURCE_GROUP = @source_group
and	usdetv3.PROJECT_NO <> ' '
and	usdetv3.STATUS_REC_NO = @in_STATUS_RECORD_NUM
and	usdetv3.PROJ_ABBR_CD <> ' '
and	usdetv3.PROJECT_NO <> ' '
and	cls_mapping.inc_exc_fl = @inc_exc_fl
--end change KM


	SELECT @out_systemerror = @@ERROR
	IF @out_systemerror <> 0  
		GOTO ErrorProcessing	






--begin CR6640
			declare @sourcePayroll	VARCHAR(3)
			set @sourcePayroll='060'


			--first do mapping for null/blank analysis code in mapping
			UPDATE 	FIWLR
			SET	FIWLR.ACCT_ID = MAP.ACCT_ID
			FROM 
			XX_FIWLR_USDET_V3 AS FIWLR
			INNER JOIN
			XX_CLS_IMAPS_ACCT_MAP as MAP

			ON (
				FIWLR.SOURCE=@sourcePayroll  --<-- key to this CR6640 is Payroll only
			
				--CR6295,CR8762
		        AND CASE WHEN FIWLR.DIVISION IN ('2G','1P') THEN '16' ELSE FIWLR.DIVISION END = MAP.division 
				
				AND	ISNULL(FIWLR.pag_cd, '') =  ISNULL(MAP.PAG, '')
				
				AND	FIWLR.major		>= (CASE 	WHEN MAP.major_1 = '***' 	THEN FIWLR.major 
										WHEN MAP.major_1 = ' '   	THEN FIWLR.major 
										ELSE MAP.major_1 
								   END )
				AND 	FIWLR.major		<= (CASE	WHEN MAP.major_2 = '***' 	THEN FIWLR.major 
										WHEN MAP.major_2 = ' '   	THEN FIWLR.major
										ELSE MAP.major_2 
								   END )
				AND	FIWLR.minor		>= (CASE  	WHEN MAP.minor_1 = '****' 	THEN FIWLR.minor
									  	WHEN MAP.minor_1 = ' ' 		THEN FIWLR.minor
									  	ELSE MAP.minor_1 
								   END )
				AND	FIWLR.minor 		<= (CASE  	WHEN MAP.minor_2 = '****' 	THEN FIWLR.minor
									  	WHEN MAP.minor_2 = ' ' 		THEN FIWLR.minor
									  	ELSE MAP.minor_2 
								   END)
				AND	FIWLR.subminor 	>= (CASE  	WHEN MAP.sub_minor_1 = '****' 	THEN FIWLR.subminor
									  	WHEN MAP.sub_minor_1 = ' ' 	THEN FIWLR.subminor 
									  	ELSE MAP.sub_minor_1 
								   END )
				AND	FIWLR.subminor 	<= (CASE  	WHEN MAP.sub_minor_2 = '****' 	THEN FIWLR.subminor
									  	WHEN MAP.sub_minor_2 = ' ' 	THEN FIWLR.subminor
									  	ELSE MAP.sub_minor_2 
								   END)
				AND	MAP.analysis_cd is null
			)
					
		SELECT @out_systemerror = @@ERROR
		IF @out_systemerror <> 0  
			GOTO ErrorProcessing	


		--then do mapping for where analysis code in mapping matches ETV code on transaction
			UPDATE 	FIWLR
			SET	FIWLR.ACCT_ID = MAP.ACCT_ID
			FROM 
			XX_FIWLR_USDET_V3 AS FIWLR
			INNER JOIN
			XX_CLS_IMAPS_ACCT_MAP as MAP

			ON (
				FIWLR.SOURCE=@sourcePayroll  --<-- key to this CR6640 is Payroll only

				--CR6295,CR8762
		        AND CASE WHEN FIWLR.DIVISION IN ('2G','1P') THEN '16' ELSE FIWLR.DIVISION END = MAP.division 	

				AND	ISNULL(FIWLR.pag_cd, '') =  ISNULL(MAP.PAG, '')
				
				AND	FIWLR.major		>= (CASE 	WHEN MAP.major_1 = '***' 	THEN FIWLR.major 
										WHEN MAP.major_1 = ' '   	THEN FIWLR.major 
										ELSE MAP.major_1 
								   END )
				AND 	FIWLR.major		<= (CASE	WHEN MAP.major_2 = '***' 	THEN FIWLR.major 
										WHEN MAP.major_2 = ' '   	THEN FIWLR.major
										ELSE MAP.major_2 
								   END )
				AND	FIWLR.minor		>= (CASE  	WHEN MAP.minor_1 = '****' 	THEN FIWLR.minor
									  	WHEN MAP.minor_1 = ' ' 		THEN FIWLR.minor
									  	ELSE MAP.minor_1 
								   END )
				AND	FIWLR.minor 		<= (CASE  	WHEN MAP.minor_2 = '****' 	THEN FIWLR.minor
									  	WHEN MAP.minor_2 = ' ' 		THEN FIWLR.minor
									  	ELSE MAP.minor_2 
								   END)
				AND	FIWLR.subminor 	>= (CASE  	WHEN MAP.sub_minor_1 = '****' 	THEN FIWLR.subminor
									  	WHEN MAP.sub_minor_1 = ' ' 	THEN FIWLR.subminor 
									  	ELSE MAP.sub_minor_1 
								   END )
				AND	FIWLR.subminor 	<= (CASE  	WHEN MAP.sub_minor_2 = '****' 	THEN FIWLR.subminor
									  	WHEN MAP.sub_minor_2 = ' ' 	THEN FIWLR.subminor
									  	ELSE MAP.sub_minor_2 
								   END)
				AND	MAP.analysis_cd = FIWLR.ETV_CODE --<-- key to this CR6640 is ETV code mapping for Payroll only
			)
					
		SELECT @out_systemerror = @@ERROR
		IF @out_systemerror <> 0  
			GOTO ErrorProcessing	
--end CR6640





RETURN 0
ErrorProcessing:
	--CLOSE xx_fiwlr_acctv
	--DEALLOCATE xx_fiwlr_acctv	

		EXEC dbo.XX_ERROR_MSG_DETAIL
	         		@in_error_code           = 204,
	         		@in_SQLServer_error_code = @out_systemerror,
	         		@in_display_requested    = 1,
				@in_placeholder_value1   = 'update',
	   			@in_placeholder_value2   = 'XX_FIWLR_USDET_V3',
	         		@in_calling_object_name  = @sp_name,
	         		@out_msg_text            = @out_status_description OUTPUT



--END CHANGE KM 05-02-06

RETURN 1
END














GO


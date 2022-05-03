USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_FIWLR_MISCODE_UPDATE_VOUCHER_SP]    Script Date: 09/27/2017 13:28:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_R22_FIWLR_MISCODE_UPDATE_VOUCHER_SP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[XX_R22_FIWLR_MISCODE_UPDATE_VOUCHER_SP]
GO

USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_FIWLR_MISCODE_UPDATE_VOUCHER_SP]    Script Date: 09/27/2017 13:28:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Tatiana Perova
-- Create date: 09/08/2017
-- Description:	CR9681  - vendor added to transaction , because it is added after initial account selection was done it needs
-- to be re-done for the part what depends on employee/vendor  division. After the update revalidation XX_R22_FIWLR_MISCODE_VALIDATE_RECORDS_SP
-- is called. Vendor error will be removed at this re-validation.
-- The same validation is called after one record update from XX_R22_FIWLR_MISCODE_UPDATE_SP.
-- =============================================
CREATE PROCEDURE [dbo].[XX_R22_FIWLR_MISCODE_UPDATE_VOUCHER_SP] (
@in_STATUS_REC_NO varchar(12),
@in_VOUCHER_NO varchar(12),
@in_VENDOR_ID varchar(7),
@in_VENDOR_NAME varchar(30),
@out_STATUS_DESCRIPTION sysname = NULL
)
AS
BEGIN

/************************************************************************************************  
Name:       	XX_R22_FIWLR_MISCODE_UPDATE_VOUCHER_SP 
Author:     	Placeholder for Miscode application on adding vendor to voucher

************************************************************************************************/  

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
DECLARE	@SP_NAME         sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@INTERFACE_NAME		 sysname,
		@ret_code		 int,
		@count			 int,
		@STATUS_REC_NO   int,
		@out_systemerror int
	
	SET @STATUS_REC_NO  = CAST(@in_STATUS_REC_NO AS INTEGER)
	

    SET @INTERFACE_NAME = 'FIWLR_MISCODE'
	SET @SP_NAME = 'XX_R22_FIWLR_MISCODE_UPDATE_VOUCHER_SP'
	
	
	/* if vendor is new (from blue pages) update VEND table  */
	
	SELECT @count = COUNT(*)  from IMAR.deltek.VEND
	WHERE rtrim(VEND_ID) = rtrim(@in_VENDOR_ID)
	
	
	if (@count = 0) 
		BEGIN
			EXEC @out_systemerror 	=  dbo.xx_R22_add_vendor_sp
				     @in_vendorid 	= @in_VENDOR_ID,
				     @in_vendorname 	= @in_VENDOR_NAME,
				     @in_vendorlongname = '',
				     @in_modified_by 	= @INTERFACE_NAME,
				     @in_rowversion 	= 5000	

			IF   @out_systemerror <>0 
					GOTO ERROR
		END

	UPDATE 	XX_R22_FIWLR_USDET_MISCODES
	SET 	REFERENCE1 = 'U',
		REFERENCE2 = ''
	WHERE	STATUS_REC_NO = @STATUS_REC_NO
	AND	VOUCHER_NO = @in_VOUCHER_NO
	
	if  ( CHARINDEX(',',@in_VENDOR_NAME) = 0 )  SET @in_VENDOR_NAME = @in_VENDOR_NAME + ', ' 
	
	Update  IMAPSstg.dbo.XX_R22_FIWLR_USDET_MISCODES 
	SET VENDOR_ID = @in_VENDOR_ID, 
		VEND_NAME = @in_VENDOR_NAME, 
		EMPLOYEE_NO = case when LEN(@in_VENDOR_ID)> 6 then SUBSTRING(@in_VENDOR_ID,2,6)else  @in_VENDOR_ID end,
		EMP_LASTNAME = LEFT(@in_VENDOR_NAME,CHARINDEX(',',@in_VENDOR_NAME,1)-1),
		EMP_FIRSTNAME =  LTRIM(SUBSTRING(@in_VENDOR_NAME,CHARINDEX(',',@in_VENDOR_NAME,1)+1,LEN(@in_VENDOR_NAME)))
	from  IMAPSstg.dbo.XX_R22_FIWLR_USDET_MISCODES  ar
	WHERE STATUS_REC_NO = @STATUS_REC_NO and
		VOUCHER_NO = @in_VOUCHER_NO
		
	
	-- finding if we have vouchers where PROJECT_NO is present for special update 
	select @count = COUNT(*)
    from dbo.xx_r22_fiwlr_usdet_miscodes
	WHERE    len(isnull(project_no, ''))>0
	AND  source='005'
	AND 	STATUS_REC_NO =@STATUS_REC_NO
	AND     VOUCHER_NO = @in_VOUCHER_NO
	
	
if @count > 0  BEGIN
	/* ----------- department update for records where PROJECT_NO is present
     */
     

	DECLARE 
    @ceris_passkey_value		VARCHAR(128),
    @ceris_keyname		VARCHAR(50)
	
	SELECT @ceris_passkey_value  = PARAMETER_VALUE FROM DBO.XX_PROCESSING_PARAMETERS WHERE PARAMETER_NAME='PASSKEY_VALUE'
	SELECT @ceris_keyname = PARAMETER_VALUE FROM DBO.XX_PROCESSING_PARAMETERS WHERE PARAMETER_NAME= 'CERIS_KEYNAME'

	EXEC ('OPEN SYMMETRIC KEY' + '  ' + @CERIS_KEYNAME + '  ' + 'DECRYPTION BY PASSWORD = ''' +  @CERIS_PASSKEY_VALUE + '''' + '  ')

	UPDATE	dbo.xx_r22_fiwlr_usdet_miscodes
	SET		reference5 = b.empl_id
	FROM	dbo.xx_r22_fiwlr_usdet_miscodes a
	INNER JOIN
			dbo.xx_r22_ceris_empl_id_map b
	on		source='005'
		AND 	STATUS_REC_NO =@STATUS_REC_NO
		AND     VOUCHER_NO = @in_VOUCHER_NO
		AND		ltrim(a.employee_no) = LTRIM(RTRIM(CONVERT(VARCHAR(50),DECRYPTBYKEY(b.r_empl_id))))

	EXEC('CLOSE SYMMETRIC KEY' + '  ' + @CERIS_KEYNAME)
/*   end of run as one block 
-- reset all ORG_ID and ORG_ABBR_CD , in case employee org is not found they should be automatically updated by preprocessor */

	UPDATE	dbo.xx_r22_fiwlr_usdet_miscodes
	SET ORG_ID  = NULL ,
		ORG_ABBR_CD = NULL
	WHERE    len(isnull(project_no, ''))>0
	AND  source='005'
	AND 	STATUS_REC_NO =@STATUS_REC_NO
	AND     VOUCHER_NO = @in_VOUCHER_NO
	

	

	UPDATE	XX_R22_FIWLR_USDET_MISCODES
	SET	ORG_ID = (	SELECT	ORG_ID FROM IMAR.DELTEK.EMPL_LAB_INFO  -- ORG_ID 
				WHERE	EMPL_ID = REFERENCE5
				AND	WWER_EXP_DT BETWEEN EFFECT_DT AND END_DT
				AND ((fiwlr.DIVISION = '24' and LEFT(ORG_ID,2) = '24')  --CR7905
				     OR fiwlr.DIVISION <> '24' and LEFT(ORG_ID,2) = '22')
				  )
	FROM	XX_R22_FIWLR_USDET_MISCODES fiwlr
	WHERE	 SOURCE ='005' 
	AND 	STATUS_REC_NO =@STATUS_REC_NO
	AND     VOUCHER_NO = @in_VOUCHER_NO
	AND		len(isnull(project_no, ''))>0 


	UPDATE	XX_R22_FIWLR_USDET_MISCODES
	SET	 ORG_ABBR_CD = (	SELECT	ORG_ABBRV_CD  -- ORG_ABBR_CD
				FROM	IMAR.DELTEK.ORG 
				WHERE	COMPANY_ID=2
				AND	ORG_ID = fiwlr.ORG_ID)
	FROM	XX_R22_FIWLR_USDET_MISCODES fiwlr
	WHERE	 SOURCE ='005' 
		AND 	STATUS_REC_NO =@STATUS_REC_NO
		AND     VOUCHER_NO = @in_VOUCHER_NO
		AND		len(isnull(project_no, ''))>0 
	
	UPDATE	dbo.xx_r22_fiwlr_usdet_miscodes
	SET REFERENCE5 = NULL

 /*      end department update for records where PROJECT_NO is present------------------------------------------------------------*/
end
   
   
   			execute dbo.XX_R22_FIWLR_MISCODE_VALIDATE_RECORDS_SP
			        @in_STATUS_RECORD_NUM = @STATUS_REC_NO,
			        @in_VOUCHER_NO = @in_VOUCHER_NO,
			        @in_UNIQUE_RECORD_NUM = null ,
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


RETURN 1
END










GO



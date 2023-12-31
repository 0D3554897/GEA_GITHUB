USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE ID = object_id(N'[dbo].[XX_R22_PROJEMPL_INSERT_SP]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[XX_R22_PROJEMPL_INSERT_SP]
GO
CREATE PROCEDURE [dbo].[XX_R22_PROJEMPL_INSERT_SP] 
(	@in_status_record_num 	INT, 
	@out_SQLServer_error_code INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS


/****************************************************************************************************
Name:       XX_R22_PROJEMPL_INSERT_SP
Author:     V Veera
Created:    06/15/2008 
			This stored procedure serves as a script to run and drive all necessary tasks to
            to perform the CERIS_R22 Employee ID mapping to generated Costpoint IMAPS Employee Serial 
			Number.
Modified :	10/18/2014 CR-7222 to resolve Oracle ODBC Default Date issue			
Parameters: 
Result Set: None
Notes:
****************************************************************************************************/

DECLARE 	@error_type		INT,
			@error_code		INT,
			@error_msg_placeholder1	SYSNAME,
			@error_msg_placeholder2 SYSNAME,
			@sp_name		SYSNAME,

		@PROJEMPL_INTERFACE_NAME	varchar(50),
        @CERIS_INTERFACE_NAME       varchar(50),
        @DIV_22_COMPANY_ID          varchar(10),
        @PROJEMPL_COMPANY_PARAM        varchar(50),
        @CERIS_PASSKEY_VALUE        varchar(128),
        @CERIS_PASSKEY_VALUE_PARAM  varchar(30),
        @CERIS_KEYNAME				varchar(50),
		@CERIS_KEYNAME1				varchar(50),
        @CERIS_KEYNAME_PARAM		varchar(30),
		@OPEN_KEY					varchar(400),
		@CLOSE_KEY					varchar(400),
        @SQL_Server_Error_CD        integer

-- set local constants
SET @SP_NAME = 'XX_R22_PROJEMPL_INSERT_SP'
SET @CERIS_INTERFACE_NAME = 'CERIS_R22'
SET @PROJEMPL_INTERFACE_NAME = 'PROJEMPL'
SET @CERIS_PASSKEY_VALUE_PARAM = 'PASSKEY_VALUE'
SET @CERIS_KEYNAME_PARAM = 'CERIS_KEYNAME'
SET @PROJEMPL_COMPANY_PARAM  = 'COMPANY_ID'

SELECT 	@error_msg_placeholder1	= NULL,
		@error_msg_placeholder2 = NULL

SELECT @DIV_22_COMPANY_ID = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME    = @PROJEMPL_COMPANY_PARAM
AND		INTERFACE_NAME_CD = @PROJEMPL_INTERFACE_NAME

SELECT	@CERIS_PASSKEY_VALUE = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME    = @CERIS_PASSKEY_VALUE_PARAM
AND		INTERFACE_NAME_CD = @CERIS_INTERFACE_NAME

SELECT @CERIS_KEYNAME = PARAMETER_VALUE
FROM	dbo.XX_PROCESSING_PARAMETERS
WHERE	PARAMETER_NAME    = @CERIS_KEYNAME_PARAM
AND	INTERFACE_NAME_CD = @CERIS_INTERFACE_NAME

SET @OPEN_KEY = 'OPEN SYMMETRIC KEY' + '  ' + @CERIS_KEYNAME + '  ' + 'DECRYPTION BY PASSWORD = ''' +  @CERIS_PASSKEY_VALUE + '''' + '  '
SET @CLOSE_KEY = 'CLOSE SYMMETRIC KEY' + '  ' + @CERIS_KEYNAME

exec (@OPEN_KEY)

	SELECT @out_SQLServer_error_code = @@ERROR 
	IF @out_SQLServer_error_code <> 0
   		BEGIN
			SET @error_type = 1 
			GOTO ErrorProcessing
   		END

	DELETE FROM ETIME..INTERIM.CP_R22_PROJ_EMPL;

   -- Modified Insert for CR-7222 
   INSERT INTO ETIME..INTERIM.CP_R22_PROJ_EMPL
	(EMPL_NO, JOBM_ID, IN_NEW_TC, ESTH_HRS, CTLC_CODE, CREATE_DATE, STATUS_RECORD_NUM)
   SELECT 
	CONVERT(VARCHAR(50), DECRYPTBYKEY(empm.r_empl_id)), proj.proj_abbrv_cd, 'Y', 0, NULL, CURRENT_TIMESTAMP, @in_status_record_num
	-- Commented CR-7222
	--	INSERT INTO ETIME..INTERIM.CP_R22_PROJ_EMPL(empl_no, jobm_id, status_record_num)
	--	SELECT		CONVERT(VARCHAR(50),DECRYPTBYKEY(empm.r_empl_id)), proj.proj_abbrv_cd, @in_status_record_num
	FROM	imar.deltek.proj_empl pemp
	INNER JOIN imar.deltek.empl emp
	ON		pemp.empl_id = emp.empl_id 
	INNER JOIN imar.deltek.proj proj
	ON		pemp.proj_id = proj.proj_id
	INNER JOIN dbo.xx_r22_ceris_empl_id_map empm
	ON		pemp.empl_id = empm.empl_id
	WHERE	emp.company_id = @div_22_company_id
	AND		proj.company_id = @div_22_company_id
	ORDER BY pemp.proj_id DESC

	SELECT @out_SQLServer_error_code = @@ERROR 
	IF @out_SQLServer_error_code <> 0
   		BEGIN
			SET @error_type = 2 
			GOTO ErrorProcessing
   		END
exec (@CLOSE_KEY)

RETURN(0)

ErrorProcessing:

	IF @error_type = 1
   		BEGIN
      			SET @error_code = 204 -- Attempt to retrieve and open the symmetric key using passkey.
      			SET @error_msg_placeholder1 = 'encryption error'
      			SET @error_msg_placeholder2 = 'unable to open symmetric or invalid passkey'
   		END
	ELSE IF @error_type = 2
   		BEGIN
      			SET @error_code = 204 -- Attempt to insert a record into table ETIME..INTERIM.CP_R22_PROJ_EMPL failed.
      			SET @error_msg_placeholder1 = 'insert'
      			SET @error_msg_placeholder2 = 'a record into table ETIME..INTERIM.CP_R22_PROJ_EMPL'
   		END

		EXEC dbo.xx_error_msg_detail
		   @in_error_code           = @error_code,
		   @in_display_requested    = 1,
		   @in_sqlserver_error_code = @out_SQLServer_error_code,
		   @in_placeholder_value1   = @error_msg_placeholder1,
		   @in_placeholder_value2   = @error_msg_placeholder2,
		   @in_calling_object_name  = @sp_name,
		   @out_msg_text            = @out_status_description OUTPUT
RETURN(1)



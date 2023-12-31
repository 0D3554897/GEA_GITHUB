USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE ID = object_id(N'[dbo].[XX_R22_PROJEMPL_ARCHIVE_SP]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[XX_R22_PROJEMPL_ARCHIVE_SP]
GO

CREATE PROCEDURE [dbo].[XX_R22_PROJEMPL_ARCHIVE_SP] 
(
	@in_status_record_num 	INT, 
	@out_SQLServer_error_code INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

/****************************************************************************************************
Name:       XX_R22_PROJEMPL_ARCHIVE_SP
Author:     V Veera
Created:    06/15/2008 
			This stored procedure serves as a script to run and drive all necessary tasks to
            to perform the CERIS_R22 Employee ID mapping to generated Costpoint IMAPS Employee Serial 
			Number.
Parameters: 
Result Set: None
Notes:
****************************************************************************************************/
-- archive errors
DECLARE 
	@error_type					INT,
	@error_code					INT,
	@total_record_count 		INTEGER,
	@error_msg_placeholder1		SYSNAME,
	@error_msg_placeholder2 	SYSNAME,
	@sp_name					SYSNAME,
    @PROJEMPL_INTERFACE_NAME	VARCHAR(50),
    @DIV_22_COMPANY_ID          VARCHAR(10),
    @PROJEMPL_COMPANY_PARAM     VARCHAR(50),
    @SQL_Server_Error_CD        INTEGER

-- set local constants
	SET @SP_NAME 				 = 'XX_R22_PROJEMPL_ARCHIVE_SP'
	SET @PROJEMPL_INTERFACE_NAME = 'PROJEMPL'
	SET @PROJEMPL_COMPANY_PARAM  = 'COMPANY_ID'

	SELECT 	@error_msg_placeholder1	= NULL,
			@error_msg_placeholder2 = NULL

	SELECT  @DIV_22_COMPANY_ID = parameter_value
	FROM	dbo.XX_PROCESSING_PARAMETERS
	WHERE	parameter_name    = @PROJEMPL_COMPANY_PARAM
	AND		interface_name_cd = @PROJEMPL_INTERFACE_NAME

	INSERT INTO dbo.xx_r22_projempl_archive(status_rec_no, r_empl_id, proj_abbrv_cd, created_by )
	SELECT	@in_status_record_num, empm.empl_id, proj.proj_abbrv_cd, suser_name()	
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
			SET @error_type = 1 
			GOTO ErrorProcessing
   		END

	SELECT  @total_record_count = COUNT(*) 
	FROM	dbo.xx_r22_projempl_archive 
	WHERE	status_rec_no = @in_status_record_num

	UPDATE	dbo.XX_IMAPS_INT_STATUS
	SET		record_count_success = @total_record_count,
       		modified_by = SUSER_SNAME(),
       		modified_date = GETDATE()
 	WHERE	status_record_num = @in_status_record_num

	SELECT @out_SQLServer_error_code = @@ERROR 
	IF @out_SQLServer_error_code <> 0
   		BEGIN
			SET @error_type = 2
			GOTO ErrorProcessing
   		END


RETURN(0)

ErrorProcessing:

	IF @error_type = 1
   		BEGIN
      			SET @error_code = 204 -- Attempt to insert a record into table XX_R22_PROJEMPL_ARCHIVE failed.
      			SET @error_msg_placeholder1 = 'insert'
      			SET @error_msg_placeholder2 = 'a record into table XX_R22_PROJEMPL_ARCHIVE'
   		END

	IF @error_type = 2
   		BEGIN
      			SET @error_code = 204 -- Attempt to update a record in table XX_IMAPS_INT_STATUS failed.
      			SET @error_msg_placeholder1 = 'update'
      			SET @error_msg_placeholder2 = 'a record into table XX_IMAPS_INT_STATUS'
   		END



		EXEC dbo.xx_error_msg_detail
		   @in_error_code           = @error_code,
		   @in_display_requested    = 1,
		   @in_sqlserver_error_code = @out_SQLServer_error_code, --@out_systemerror,
		   @in_placeholder_value1   = @error_msg_placeholder1,
		   @in_placeholder_value2   = @error_msg_placeholder2,
		   @in_calling_object_name  = @sp_name,
		   @out_msg_text            = @out_status_description OUTPUT

RETURN(1)


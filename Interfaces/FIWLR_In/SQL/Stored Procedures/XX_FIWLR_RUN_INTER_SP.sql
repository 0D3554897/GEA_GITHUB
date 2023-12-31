SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[XX_FIWLR_RUN_INTER_SP]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[XX_FIWLR_RUN_INTER_SP]
GO

CREATE PROCEDURE [dbo].[XX_FIWLR_RUN_INTER_SP] 

AS
 
 DECLARE
	 @lastexecutedinterfacestatusnum 	INT,
	 @lastexecutedinterfacestatus 		VARCHAR(10),
	 @lastexecutedcontrolpoint 		VARCHAR(10),
	 @currentexecutionstep 			INT, 
	 @currentinterfacestatusnum		INT,
	 @currentexecutedcontrolpoint		VARCHAR(6),
	 @executionstepprocedure		VARCHAR(50),
	 @executionstepsystemerror		INT,
	 @procedurereturncode			INT,
	 @interfacesuccessfulexecutionstatus	VARCHAR(20),
	 @interfacestartedpreprocessorstatus	VARCHAR(20),
	 @interfacefailedexecutionstatus	VARCHAR(20),
	 @systemerrorcode			INT,
	 @totalnumberofsteps			INT,
	 @numberofrecords			INT,
	 @sp_name				SYSNAME,
	 @out_status_description		VARCHAR(240),
	 @syserror_msg_text			VARCHAR(240),

--Error Parameters

	@error_msg_placeholder1 	SYSNAME,
	@error_msg_placeholder2 	SYSNAME,
	
-- parameters for status record
	@fiwlr_interface_name 		VARCHAR(20),
--	@fiwlr_interface_name1 		VARCHAR(20),
	@imaps_db_name  		SYSNAME,
	@imaps_schema_owner  		SYSNAME,
	@fiwlr_interface 		VARCHAR(50),
	@inbound_int_type 		VARCHAR(1),
	@fiwlr_source_system 		VARCHAR(50),
	@fiwlr_dest_system 		VARCHAR(50),
	@fiwlr_data_fname 		SYSNAME,
	@fiwlr_source_owner  		VARCHAR(50),
	@fiwlr_dest_owner   		VARCHAR(300),
	@fiwlr_control_point_domain 	VARCHAR(50)
	
 
	SELECT 	@fiwlr_interface_name = 'FIWLR', 
--		@fiwlr_interface_name1 = 'FIW_LR',
		@interfacesuccessfulexecutionstatus = 'COMPLETED',
		@interfacestartedpreprocessorstatus = 'CPIN_PROGRESS',
		@interfacefailedexecutionstatus	= 'FAILED',
		@totalnumberofsteps = 7,
		@procedurereturncode = 301,
		@systemerrorcode = NULL,
		@out_status_description = NULL,
		@error_msg_placeholder1 = NULL,
		@error_msg_placeholder2 = NULL,
		@fiwlr_data_fname	= 'N/A',
		@sp_name = 'XX_FIWLR_RUN_INTER_SP',
		@fiwlr_source_system  = 'FIWLR',
		@fiwlr_dest_system = 'IMAPS',
		@inbound_int_type  = 'I',
		@fiwlr_control_point_domain = 'LD_FIWLR_INTER_CTRL_PT '
		

	SELECT	@fiwlr_source_owner = PARAMETER_VALUE 
	FROM	dbo.xx_processing_parameters 
	WHERE	interface_name_cd = 'FIWLR' 
	AND	parameter_name = 'IN_SOURCE_SYSOWNER'
	SELECT 	@fiwlr_dest_owner = PARAMETER_VALUE 
	FROM 	dbo.xx_processing_parameters 
	WHERE 	interface_name_cd = 'FIWLR' 
	AND 	parameter_name = 'IN_DESTINATION_SYSOWNER'
	SELECT 	@imaps_db_name   = PARAMETER_VALUE 
	FROM 	dbo.xx_processing_parameters 
	WHERE 	interface_name_cd = 'FIWLR' 
	AND 	parameter_name = 'IMAPS_DATABASE_NAME'
	SELECT 	@imaps_schema_owner = PARAMETER_VALUE 
	FROM 	dbo.xx_processing_parameters 
	WHERE 	interface_name_cd = 'FIWLR' 
	AND 	parameter_name = 'IMAPS_SCHEMA_OWNER'

/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_RUN_INTER_SP							*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR Run Interface Procedure					*/
/* Date			: October 15, 2005						        */
/* Notes		: IMAPS FIW-LR Run Interface program will extract the data from FIW-LR 	*/
/*			  datawarehouse. Validate the expense and journal transactions extracted*/
/*			  and load into IMAPS AP and JE Preprocessor tables. The program will   */
/*			  initiate AP and JE Preprocessor. After the process is successfully	*/
/*			  completed. The extracted data for this batch and the data that failed */
/*			  the validation will be archived.					*/
/* Prerequisites	: XX_FIWLR_USDET_V1, XX_FIWLR_USDET_V2, XX_FIWLR_USDET_V3,  		*/
/*			  XX_FIWLR_EMP_V, XX_FIWLR_VEND_V, XX_AOPUTLAP_INP_HDRV, 		*/
/*			  XX_AOPUTLAP_INP_DETLV, XX_FIWLR_INC_EXC_TEST, XX_FIWLR_APSRC_GRP, 	*/
/*			  XX_FIWLR_USDET_ARCHIVE, XX_AOPUTLAP_INP_HDR_ERR, 			*/
/*			  XX_AOPUTLAP_INP_DETL_ERR, XX_AOPUTLJE_INP_TR_ERR, XX_SEQUENCES_HDR,	*/
/*			  XX_SEQUENCES_DETL, XX_SEQUENCES_JE Table(s) should be created.	*/
/*			  - For instructions please follow the IMAPS_INT_ERR_MSGS.Sql		*/
/* Parameter(s)		: 									*/
/*	Input		: 									*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: DELTEK.AOPUTLAP_INP_HDR, DELTEK.AOPUTLAP_INP_DETL and 		*/
/*			  DELTEK.AOPUTLJe_INP_TR						*/
/* Version		: 1.2									*/
/************************************************************************************************/
/* Date		Modified By	      Description of change			  		*/
/* ----------   -------------  	      ------------------------    			  	*/
/* 10-15-2005   Veera Veeramachanane  Created Initial Version					*/
/* 11-07-2005   Veera Veeramachanane  Modified code to change XX_FIWLR_PREPROCESSOR_JE_SP to	*/
/*				      XX_FIWLR_PREP_JE_SP for execution step 4. DEV00000243	*/
/* 11-14-2005   Veera Veeramachanane  Modified code to execute XX_FIWLR_CERIS_EMP procedure 	*/
/*				      separately as part of execution step 1 to fix 		*/
/*				      distributed link server error. Defect:DEV00000269	        */
/* 02-08-2008   HVT                   CP600000199 - Reference BP&S Service Request DR1427       */
/*                                    Enable more users to be notified by e-mail upon specific  */
/*                                    interface run events. Change the size of @fiwlr_dest_owner*/
/*                                    from VARCHAR(50) to VARCHAR(300).                         */
/************************************************************************************************/
 

	SELECT  @lastexecutedinterfacestatusnum = status_record_num,
	 	@lastexecutedinterfacestatus = status_code
	FROM	dbo.xx_imaps_int_status
	WHERE 
		created_date = (
			SELECT	MAX(a1.created_date) 
			FROM	dbo.xx_imaps_int_status a1
			WHERE	a1.interface_name = @fiwlr_interface_name
				) 	
			AND	interface_name = @fiwlr_interface_name

	SELECT @systemerrorcode = @@ERROR,  @numberofrecords = @@ROWCOUNT
	IF @systemerrorcode > 0  
		GOTO ErrorProcessing
	
	IF @lastexecutedinterfacestatusnum IS NULL 
		BEGIN
			SELECT  @lastexecutedinterfacestatusnum = COUNT(*)
			FROM 	dbo.xx_imaps_int_status
			WHERE 	interface_name = @fiwlr_interface_name
		
			IF @lastexecutedinterfacestatusnum = 0 
			-- the firts run of the interface
				BEGIN 
					SET  @lastexecutedinterfacestatus =  @interfacesuccessfulexecutionstatus 
				END
			ELSE
				GOTO ErrorProcessing
		END

	IF @lastexecutedinterfacestatus <> @interfacesuccessfulexecutionstatus
		BEGIN
	-- look for last succesful control point	

			SELECT 	@lastexecutedcontrolpoint = control_pt_id 
			FROM 	dbo.xx_imaps_int_control
			WHERE	status_record_num = @lastexecutedinterfacestatusnum 
			AND	interface_name = @fiwlr_interface_name 
			AND	control_pt_status = 'SUCCESS' 
			AND	control_record_num = 
					(
					SELECT	MAX(control_record_num) 
					FROM 	dbo.xx_imaps_int_control a1
					WHERE	a1.STATUS_RECORD_NUM  = @LastExecutedInterfaceStatusNum 
					AND	a1.interface_name = @fiwlr_interface_name 
					AND	a1.control_pt_status = 'SUCCESS'
					) 
			SELECT  @systemerrorcode = @@ERROR,  @numberofrecords = @@ROWCOUNT
			IF @systemerrorcode > 0  
				GOTO ErrorProcessing
			
			IF @lastexecutedcontrolpoint IS NULL 
				BEGIN 
					SET @currentexecutionstep = 1 
				END
			ELSE
				BEGIN
			--select next control point to execute
					SELECT	@currentexecutionstep = presentation_order + 1 
					FROM	dbo.xx_lookup_detail 		
					WHERE	application_code = @lastexecutedcontrolpoint 
				END
				SET @currentinterfacestatusnum = @lastexecutedinterfacestatusnum
		END
	ELSE
		BEGIN 
			SET @currentexecutionstep = 1 
		END

	IF @currentinterfacestatusnum IS NULL 
		BEGIN
		-- create new record in status table
			EXEC  	@procedurereturncode 	= dbo.xx_insert_int_status_record
			   	@in_imaps_db_name      	= @imaps_db_name,
		                @in_imaps_table_owner  	= @imaps_schema_owner,
		                @in_int_name           	= @fiwlr_interface_name,
		                @in_int_type           	= @inbound_int_type,
		                @in_int_source_sys     	= @fiwlr_source_system,
		                @in_int_dest_sys       	= @fiwlr_dest_system,
		                @in_data_fname         	= @fiwlr_data_fname,
		                @in_int_source_owner   	= @fiwlr_source_owner,
		                @in_int_dest_owner     	= @fiwlr_dest_owner,
		                @out_status_record_num 	= @currentinterfacestatusnum OUTPUT
			IF  @procedurereturncode <> 0 
				BEGIN
					GOTO ErrorProcessing 
				END
		END
	
	WHILE @currentexecutionstep <= @totalnumberofsteps
		BEGIN
		/*step four control point should be created  by common code for  the successful preprocesor run 
		   therefor if interface received step 6 for execution it means that AP preprocessor fails and interface will do nothing*/
			IF  @currentexecutionstep = 6
				BEGIN 
					SET @procedurereturncode = 524
					SET @interfacefailedexecutionstatus = @interfacestartedpreprocessorstatus
					GOTO ErrorProcessing
				END

--	START Added by Veera on 11/14/2005 - Defect : DEV00000269
				IF @currentexecutionstep = 1 --THEN 
					BEGIN 
						EXEC @procedurereturncode = [dbo].[XX_FIWLR_CERIS_EMP_SP] 
									     @currentinterfacestatusnum,
                     							     @executionstepsystemerror OUTPUT,
                     							     @out_status_description OUTPUT

						IF @procedurereturncode <> 0
							BEGIN
								SELECT  @sp_name = 'XX_FIWLR_CERIS_EMP_SP', 
									@systemerrorcode = @executionstepsystemerror
								GOTO ErrorProcessing
							END
					END
--	END Commented out by Veera on 11/14/2005 - Defect : DEV00000269

			SELECT @executionstepprocedure =
				CASE 	@currentexecutionstep
					WHEN 1 THEN 'dbo.XX_FIWLR_EXTRACT_DATA_SP'
					WHEN 2 THEN 'dbo.XX_FIWLR_VALID_DATA_SP'
					WHEN 3 THEN 'dbo.XX_FIWLR_PREPROCESSOR_AP_SP'
--					WHEN 4 THEN 'dbo.XX_FIWLR_PREPROCESSOR_JE_SP' -- Commented Out by Veera on 11/07/2005 - Defect : DEV00000243
					WHEN 4 THEN 'dbo.XX_FIWLR_PREP_JE_SP'-- Added by Veera on 11/07/2005 - Defect : DEV00000243
					WHEN 5 THEN 'dbo.XX_FIWLR_INITIATE_PREPROCESSORS_SP'
					WHEN 7 THEN 'dbo.XX_FIWLR_ARCHIVE_SP'
				END

			BEGIN transaction controlstep
				EXEC	@procedurereturncode = @executionstepprocedure
                			@currentinterfacestatusnum,
                      			@executionstepsystemerror OUTPUT,
                      			@out_status_description OUTPUT
		
			IF @procedurereturncode <> 0 -- failure
				BEGIN
				-- for this procedure we assume that errors are logged by steps
					ROLLBACK TRANSACTION controlstep

					SELECT  @sp_name = @executionstepprocedure, 
						@systemerrorcode = @executionstepsystemerror
						GOTO ErrorProcessing
				END
			ELSE	-- success	
				BEGIN	
					COMMIT TRANSACTION controlstep
			-- insert another XX_IMAPS_INT_CONTROL record for the step
					EXEC	dbo.xx_insert_int_control_record
						@in_int_ctrl_pt_num  =@currentexecutionstep,
						@in_lookup_domain_const =@fiwlr_control_point_domain,
						@in_status_record_num  = @currentinterfacestatusnum

					SET @currentexecutionstep = @currentexecutionstep+1

			-- need to stop execution after starting preprocessor step 5
					IF @currentexecutionstep = 6 
						BEGIN
							EXEC	dbo.xx_update_int_status_record	
								@in_status_record_num = @currentinterfacestatusnum,
								@in_status_code =  @interfacestartedpreprocessorstatus
				RETURN 0
				END
			END
		END


-- update status record with "COMPLETED"
	EXEC 	dbo.xx_update_int_status_record
		@in_status_record_num  = @currentinterfacestatusnum,
		@in_status_code        = @interfacesuccessfulexecutionstatus

	EXEC  	dbo.xx_send_status_mail_sp 
		@in_statusrecordnum = @currentinterfacestatusnum

RETURN 0

	ErrorProcessing:

		IF @procedurereturncode = 524
		   BEGIN
		      SET @error_msg_placeholder1 = 'FIWLR'
		      SET @error_msg_placeholder2 = '6.'
		   END

/*
Error processing depends on three values @ProcedureReturnCode,  @out_STATUS_DESCRIPTION and @SystemErrorCode.
For error @ProcedureReturnCode >=1. If  @ProcedureReturnCode <> 1 we will look for IMAPS error message, combine it with system error message.
If @ProcedureReturnCode = 1, we expect  @out_STATUS_DESCRIPTION to be already populated by previous steps.
@ProcedureReturnCode  = 1 AND @out_STATUS_DESCRIPTION is NULL standard unknown message will be displayed (extended
by system message, if available)
*/
	IF @procedurereturncode  = 1 AND @out_status_description IS NULL 
		BEGIN  
			SET @procedurereturncode = 301 
		END

	IF  @systemerrorcode = 0 
		BEGIN 
			SET @systemerrorcode = NULL 
		END 
	IF @procedurereturncode <> 1  
		BEGIN
			EXEC 	dbo.xx_error_msg_detail
	         		@in_error_code          = @procedurereturncode,
	         		@in_sqlserver_error_code = @systemerrorcode,
	         		@in_display_requested   = 1,
				@in_placeholder_value1   = @error_msg_placeholder1,
	   			@in_placeholder_value2   = @error_msg_placeholder2,
	         		@in_calling_object_name = @sp_name,
	         		@out_msg_text           = @out_status_description OUTPUT,
				@out_syserror_msg_text = @syserror_msg_text OUTPUT
			IF @syserror_msg_text IS NOT NULL 
				BEGIN 
					SET @out_status_description = RTRIM(@out_status_description) + @syserror_msg_text
				END
		END

	EXEC	dbo.xx_update_int_status_record
		@in_status_record_num  	=  @currentinterfacestatusnum,
		@in_status_code     	=  @interfacefailedexecutionstatus,
		@in_status_description 	=  @out_status_description

	EXEC  	dbo.xx_send_status_mail_sp 
		@in_statusrecordnum = @currentinterfacestatusnum
RETURN 1


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


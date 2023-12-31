SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.XX_FIWLR_CERIS_EMP_SP    Script Date: 06/23/2006 11:52:46 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_CERIS_EMP_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_CERIS_EMP_SP]
GO





CREATE PROCEDURE [dbo].[XX_FIWLR_CERIS_EMP_SP] (
	@in_status_record_num 	INT, 
	@out_systemerror 	INT = NULL OUTPUT,
	@out_status_description VARCHAR(240) = NULL OUTPUT) 
AS

DECLARE 

	@SpReturnCode	 	INT,
	@NumberOfRecords 	INT,
	@error_type		INT,
	@error_code		INT,
	@error_msg_placeholder1	SYSNAME,
	@error_msg_placeholder2 SYSNAME,
	@sp_name		SYSNAME


/************************************************************************************************/
/* Procedure Name	: XX_FIWLR_CERIS_EMP_SP							*/
/* Created By		: Veerabhadra Chowdary Veeramachanane			   		*/
/* Description    	: IMAPS FIW-LR CERIS Employee Details procedure				*/
/* Date			: October 23, 2005						        */
/* Notes		: IMAPS FIW-LR CERIS Employee program will retrieve the employee 	*/
/*			  history information from eT&E for employee divsion change information	*/
/* Prerequisites	: XX_FIWLR_CERIS_EMP_SP Table is required. A  database link to CERIS	*/
/*			  table IBM_CERIS has to be established (ETIME_RPT..CFRPTADM.IBM_CERIS)	*/
/* Parameter(s)		: 									*/
/*	Input		: Status Record Number (Input)						*/
/*	Output		: Error Code and Error Description					*/
/* Tables Updated	: XX_FIWLR_CERIS_EMP			 				*/
/* Version		: 1.0									*/
/************************************************************************************************/
/* Date		Modified By		Description of change			  		*/
/* ----------   -------------  	   	------------------------    			  	*/
/* 10-23-2005   Veera Veeramachanane   	Created Initial Version					*/
/* 06-21-2006 	Keith McGuire		Defect : DEV0000879					*/

/* CP7 upgrade 
	removing this entire procedure
	no need to get data from ETIME anymore
	we get CERIS data from IMAPS (not ETIME)
	this data is not used
*/
/************************************************************************************************/


BEGIN

	SELECT	@sp_name = 'XX_FIWLR_CERIS_EMP_SP',
		@error_msg_placeholder1	= NULL,
		@error_msg_placeholder2 = NULL

-- Delete the previously extracted employee history information
	TRUNCATE TABLE dbo.xx_fiwlr_ceris_emp
/*
-- CHANGE KM 06/19/06
	SELECT @NumberOfRecords = count(1) 
	FROM    ETIME_RPT..CFRPTADM.IBM_CERIS_HIST
	
	SET @error_type = 2
	IF @@ERROR <> 0 GOTO ErrorProcessing
	IF @NumberOfRecords <= 0 GOTO ErrorProcessing
-- END CHANGE

-- Extract the employee history information from eT&E (CERIS)
	INSERT 	INTO dbo.xx_fiwlr_ceris_emp
       		(status_rec_no,
		emp_no,
		emp_lname,
		emp_fname,
		status,
		dept,
		division,
		div_from,
		div_strt_date,
		ibm_strt_date,
		term_date,
		create_date,
		time_stamp)
	SELECT 	@in_status_record_num,
		SUBSTRING(LTRIM(RTRIM(emplid)),1,10),
		SUBSTRING(LTRIM(RTRIM(lname)),1,25),
		SUBSTRING(LTRIM(RTRIM(fname)),1,25),
		ISNULL(SUBSTRING(LTRIM(RTRIM(status)),1,5), ''),
		SUBSTRING(LTRIM(RTRIM(dept)),1,10),
		SUBSTRING(LTRIM(RTRIM(division)),1,10),
		SUBSTRING(LTRIM(RTRIM(division_from)),1,10),
		division_strt_date,
		ibm_start_dt,
		term_dt,
		min(create_date),
		getdate()
		FROM    ETIME_RPT..CFRPTADM.IBM_CERIS_HIST
		group by 
		SUBSTRING(LTRIM(RTRIM(emplid)),1,10),
		SUBSTRING(LTRIM(RTRIM(lname)),1,25),
		SUBSTRING(LTRIM(RTRIM(fname)),1,25),
		ISNULL(SUBSTRING(LTRIM(RTRIM(status)),1,5), ''),
		SUBSTRING(LTRIM(RTRIM(dept)),1,10),
		SUBSTRING(LTRIM(RTRIM(division)),1,10),
		SUBSTRING(LTRIM(RTRIM(division_from)),1,10),
		division_strt_date,
		ibm_start_dt,
		term_dt

*/

	SET @error_type = 1
	IF @@ERROR <> 0 GOTO ErrorProcessing

RETURN 0
ErrorProcessing:

	IF @error_type = 1
   		BEGIN
      			SET @error_code = 204 -- Attempt to insert a record into table XX_FIWLR_CERIS_EMP failed.
      			SET @error_msg_placeholder1 = 'insert'
      			SET @error_msg_placeholder2 = 'a record into table XX_FIWLR_CERIS_EMP'
   		END
	
	IF @error_type = 2
   		BEGIN
      			SET @error_code = 204 -- Attempt to %1 %2 failed.
      			SET @error_msg_placeholder1 = 'connect to'
      			SET @error_msg_placeholder2 = 'eT&E CERIS table'
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

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


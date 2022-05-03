USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_R22_FIWLR_MISCODE_CLOSEOUT_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_R22_FIWLR_MISCODE_CLOSEOUT_SP]
GO

CREATE PROCEDURE [dbo].[XX_R22_FIWLR_MISCODE_CLOSEOUT_SP] (
@out_STATUS_DESCRIPTION sysname = NULL
)
AS
BEGIN
/************************************************************************************************  
Name:       	XX_R22_FIWLR_MISCODE_CLOSEOUT_SP  
Author:     	KM  

exec XX_R22_FIWLR_miscode_closeout_sp

2014-02-19  Costpoint 7 changes
			Process Server replaced by Job Server
************************************************************************************************/  

	DECLARE	@SP_NAME     sysname = OBJECT_NAME(@@PROCID), --CR11505
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
	@INTERFACE_NAME		 sysname,
	@ret_code		 int,
	@count			 int

	SET @ret_code=1

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'CHECK FIWLR_R22_MISCODE PROCESS'
	SET @ERROR_MSG_PLACEHOLDER2 = 'COMPLETED'

	declare @time_stamp datetime
	declare @process_time_stamp datetime
	
	select @time_stamp = max(time_stamp)
	from xx_error_status 
	where control_pt = 3
	and	interface = 'FIWLR_R22'

	--2014-02-19  Costpoint 7 changes BEGIN
	select	@process_time_stamp = time_stamp
	from 	IMAR.DELTEK.job_schedule
	where 	job_id = 'FIWLR_R22_M'
	and		SCH_START_DTT>getdate()
	--2014-02-19  Costpoint 7 changes END
	
	if @time_stamp is null goto error
	if @process_time_stamp is null goto error
	if @time_stamp >= @process_time_stamp goto error
	
	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'CALL XX_R22_FIWLR_PREPROCESSOR_CLOSEOUT_SP'
	SET @ERROR_MSG_PLACEHOLDER2 = ''
	
	EXEC @ret_code = XX_R22_FIWLR_PREPROCESSOR_CLOSEOUT_SP

	IF @ret_code<>0 goto error


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'DELETE SUCCESSFULLY PROCESSED MISCODES'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FROM XX_R22_FIWLR_USDET_MISCODE'

	UPDATE XX_R22_FIWLR_USDET_MISCODES
	set cp_hdr_no = temp.cp_hdr_no,
	    cp_ln_no = 	temp.cp_ln_no,
	    fy_cd = 	temp.fy_cd,
	    pd_no = 	temp.pd_no,
	    sub_pd_no = temp.sub_pd_no,
	    proj_abbr_cd= temp.proj_abbr_cd,
	    org_abbr_cd = temp.org_abbr_cd,
	    acct_id 	= temp.acct_id
	from
	XX_R22_FIWLR_USDET_TEMP temp
	INNER JOIN
	XX_R22_FIWLR_USDET_MISCODES miscode
	on
	(
	temp.cp_hdr_no is not null
	and
	temp.status_rec_no = miscode.status_rec_no
	and
	temp.ident_rec_no = miscode.ident_rec_no
	)


	UPDATE XX_R22_FIWLR_USDET_ARCHIVE
	set cp_hdr_no = miscode.cp_hdr_no,
	    cp_ln_no = 	miscode.cp_ln_no,
	    fy_cd = 	miscode.fy_cd,
	    pd_no = 	miscode.pd_no,
	    sub_pd_no = miscode.sub_pd_no,
	    proj_abbr_cd= miscode.proj_abbr_cd,
	    org_abbr_cd = miscode.org_abbr_cd,
	    acct_id 	= miscode.acct_id,
		reference5 = 'M'  --change to track which transactions were corrected through miscode application
	from
	XX_R22_FIWLR_USDET_ARCHIVE arch
	INNER JOIN
	XX_R22_FIWLR_USDET_MISCODES miscode
	on
	(
	miscode.cp_hdr_no is not null
	and
	arch.status_rec_no = miscode.status_rec_no
	and
	arch.ident_rec_no = miscode.ident_rec_no
	)

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_ERROR_STATUS'

	UPDATE XX_ERROR_STATUS
	SET 
	STATUS = 'REPROCESSED',
	CONTROL_PT = 7,
	TIME_STAMP = current_timestamp,
	SUCCESS_COUNT = 
	(select isnull(count(1),0) from XX_R22_FIWLR_usdet_miscodes 
	 where 	status_rec_no = err_status.status_record_num
	 and	source_group = err_status.preprocessor
	 and	cp_hdr_no is not null),
	SUCCESS_AMOUNT = 
	(select isnull(sum(amount), .00) from XX_R22_FIWLR_usdet_miscodes 
	 where 	status_rec_no = err_status.status_record_num
	 and	source_group = err_status.preprocessor
	 and	cp_hdr_no is not null),
	ERROR_COUNT = 
	(select isnull(count(1),0) from XX_R22_FIWLR_usdet_miscodes 
	 where 	status_rec_no = err_status.status_record_num
	 and	source_group = err_status.preprocessor
	 and	cp_hdr_no is null),
	ERROR_AMOUNT = 
	(select isnull(sum(amount), .00) from XX_R22_FIWLR_usdet_miscodes 
	 where 	status_rec_no = err_status.status_record_num
	 and	source_group = err_status.preprocessor
	 and	cp_hdr_no is null)
	FROM 	XX_ERROR_STATUS err_status
	WHERE	CONTROL_PT = 3
	AND		INTERFACE='FIWLR_R22'

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'DELETE SUCCESSFULLY PROCESSED MISCODES'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FROM XX_R22_FIWLR_USDET_MISCODE'

	DELETE FROM XX_R22_FIWLR_USDET_MISCODES
	WHERE 	CP_HDR_NO IS NOT NULL

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	UPDATE	XX_R22_FIWLR_USDET_MISCODES
	SET	REFERENCE1 = 'M'
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	

RETURN 0

ERROR:

PRINT @ERROR_MSG_PLACEHOLDER1 + ' ' + @ERROR_MSG_PLACEHOLDER2

EXEC dbo.XX_ERROR_MSG_DETAIL
   @in_error_code           = @IMAPS_error_number,
   @in_display_requested    = 1,
   @in_SQLServer_error_code = @SQLServer_error_code,
   @in_placeholder_value1   = @error_msg_placeholder1,
   @in_placeholder_value2   = @error_msg_placeholder2,
   @in_calling_object_name  = @SP_NAME,
   @out_msg_text            = @out_STATUS_DESCRIPTION OUTPUT

PRINT @out_STATUS_DESCRIPTION

RETURN 1


END

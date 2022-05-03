USE [IMAPSStg]
GO
/****** Object:  StoredProcedure [dbo].[XX_FIWLR_MISCODE_CLOSEOUT_SP]    Script Date: 10/22/2007 10:50:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_FIWLR_MISCODE_CLOSEOUT_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_FIWLR_MISCODE_CLOSEOUT_SP]
GO


CREATE PROCEDURE [dbo].[XX_FIWLR_MISCODE_CLOSEOUT_SP] (
@out_STATUS_DESCRIPTION sysname = NULL
)
AS

BEGIN

/************************************************************************************************  
Name:       XX_FIWLR_MISCODE_CLOSEOUT_SP  
Author:     KM  

Notes:

CP600000200 Reference BP&S Service Request DR1437
            05/05/2008 - Costpoint multi-company fix (seven instances).
            
2014-02-19  Costpoint 7 changes
			Process Server replaced by Job Server
************************************************************************************************/  

DECLARE	@SP_NAME         	 sysname,
        @DIV_16_COMPANY_ID       varchar(10),
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
	@INTERFACE_NAME		 sysname,
	@ret_code		 int,
	@count			 int

	
	declare @FIWLR_USER_ID char(5)
	declare @FIWLR_N16_USER_ID char(6)
	declare @time_stamp datetime
	declare @process_time_stamp datetime

	SET @INTERFACE_NAME = 'FIWLR'
	SET @SP_NAME = 'XX_FIWLR_MISCODE_CLOSEOUT_SP'
	SET @ret_code = 1

	set @FIWLR_USER_ID = 'FIWLR'
	set @FIWLR_N16_USER_ID = 'FIWN16'

-- CP600000200 Begin

	SET @IMAPS_ERROR_NUMBER = 204 -- Attempt to %1 %2 failed.
	SET @ERROR_MSG_PLACEHOLDER1 = 'access required processing parameter COMPANY_ID'
	SET @ERROR_MSG_PLACEHOLDER2 = 'for FIWLR Interface'

	SELECT	@DIV_16_COMPANY_ID = PARAMETER_VALUE
	FROM	dbo.XX_PROCESSING_PARAMETERS
	WHERE	PARAMETER_NAME = 'COMPANY_ID'
	AND	INTERFACE_NAME_CD = 'FIWLR'

	SET @count = @@ROWCOUNT

	IF @count = 0 OR LEN(RTRIM(LTRIM(@DIV_16_COMPANY_ID))) = 0 GOTO ERROR

-- CP600000200 End

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'CHECK AP PREPROCESSOR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'COMPLETED'
	
	select @time_stamp = time_stamp
	from xx_error_status 
	where control_pt = 3
	and  preprocessor = 'AP'
	and  interface = 'FIWLR'

	--2014-02-19  Costpoint 7 changes BEGIN
	select	@process_time_stamp = time_stamp
	from 	imaps.deltek.job_schedule
	where 	job_id = 'AP_REPROCESS'
	and		SCH_START_DTT>getdate()
-- CP600000200 Begin
	and	COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000200 End
	--2014-02-19  Costpoint 7 changes END

	if @time_stamp is not null
	begin
		if @process_time_stamp is null goto error
		if @time_stamp >= @process_time_stamp goto error
	end

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'CHECK JE PREPROCESSOR'
	SET @ERROR_MSG_PLACEHOLDER2 = 'COMPLETED'
	
	select @time_stamp = time_stamp
	from xx_error_status 
	where control_pt = 3
	and  preprocessor = 'JE'
	and  interface = 'FIWLR'

	--2014-02-19  Costpoint 7 changes BEGIN
	select	@process_time_stamp = time_stamp
	from 	imaps.deltek.job_schedule
	where 	job_id = 'JE_REPROCESS'
	and		SCH_START_DTT>getdate()
-- CP600000200 Begin
	and	COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000200 End
	--2014-02-19  Costpoint 7 changes END
	
	if @time_stamp is not null
	begin
		if @process_time_stamp is null goto error
		if @time_stamp >= @process_time_stamp goto error
	end
	
	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE DELTEK.JE_HDR USER ID'
	SET @ERROR_MSG_PLACEHOLDER2 = 'TO FIWLR'

	update imaps.deltek.je_hdr
	set ENTR_USER_ID = @FIWLR_USER_ID
	where left(rtrim(je_desc), 30) in 
		(
		select left(rtrim(je_desc), 30)
		from imaps.deltek.aoputlje_inp_tr
		)
-- CP600000200 Begin
	and	COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000200 End

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE DELTEK.VCHR_HDR USER ID'
	SET @ERROR_MSG_PLACEHOLDER2 = 'TO FIWLR'

	update imaps.deltek.vchr_hdr
	set ENTR_USER_ID = @FIWLR_USER_ID
	where left(rtrim(notes), 30) in 
		(
		select left(rtrim(notes), 30)
		from imaps.deltek.aoputlap_inp_hdr		
		where --right(rtrim(notes), 3) <> 'N16'
		left(right(rtrim(notes),6), 3) <> 'N16' --DR3449
		)
-- CP600000200 Begin
	and	COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000200 End

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE DELTEK.VCHR_HDR USER ID'
	SET @ERROR_MSG_PLACEHOLDER2 = 'TO FIWN16'

	update imaps.deltek.vchr_hdr
	set ENTR_USER_ID = @FIWLR_N16_USER_ID
	where left(rtrim(notes),30) in 
		(
		select left(rtrim(notes), 30)
		from imaps.deltek.aoputlap_inp_hdr
		where --right(rtrim(notes), 3) ='N16'
		left(right(rtrim(notes),6), 3) = 'N16' --DR3449
		)
-- CP600000200 Begin
	and	COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000200 End

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	

	--begin grab the JE and AP Cosptoint Numbers for Reporting Purposes
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE XX_FIWLR_USDET_MISCODES'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH COSTPOINT RPT DATA'
	
	truncate table xx_fiwlr_usdet_rpt_temp

	insert into xx_fiwlr_usdet_rpt_temp
	(SOURCE_GROUP, CP_LN_DESC, CP_LN_NOTES, CP_HDR_KEY, CP_LN_NO)
	SELECT 'AP', VCHR_LN_DESC, NOTES, VCHR_KEY, VCHR_LN_NO
	FROM	IMAPS.DELTEK.VCHR_LN
	WHERE	LEFT(NOTES, 3) <> 'Bal'
	
	insert into xx_fiwlr_usdet_rpt_temp
	(SOURCE_GROUP, CP_LN_DESC, CP_LN_NOTES, CP_HDR_KEY, CP_LN_NO)
	SELECT 'JE', JE_TRN_DESC, NOTES, JE_HDR_KEY, JE_LN_NO
	FROM	IMAPS.DELTEK.JE_TRN
	WHERE	LEFT(NOTES, 3) <> 'Bal'

	--DR1285
	UPDATE xx_fiwlr_usdet_rpt_temp
	set status_Rec_no = left(dbo.xx_parse_csv(cp_ln_desc, 0), 10),
	ident_rec_no = left(dbo.xx_parse_csv_backwards(cp_ln_notes, 1), 10)
	
	UPDATE xx_fiwlr_usdet_rpt_temp
	set cp_hdr_no = hdr.vchr_no,
	    fy_cd = hdr.fy_cd,
	    pd_no = hdr.pd_no,
	    sub_pd_no = hdr.sub_pd_no
	from xx_fiwlr_usdet_rpt_temp tmp
	inner join
	imaps.deltek.vchr_hdr hdr
	on
-- CP600000200 Begin
	(
	tmp.source_group = 'AP'
	and tmp.cp_hdr_key = hdr.vchr_key
	and hdr.COMPANY_ID = @DIV_16_COMPANY_ID
	)
-- CP600000200 End

	UPDATE xx_fiwlr_usdet_rpt_temp
	set cp_hdr_no = hdr.je_no,
	    fy_cd = hdr.fy_cd,
	    pd_no = hdr.pd_no,
	    sub_pd_no = hdr.sub_pd_no
	from xx_fiwlr_usdet_rpt_temp tmp
	inner join
	imaps.deltek.je_hdr hdr
	on
-- CP600000200 Begin
	(
	 tmp.source_group = 'JE'
	 and tmp.cp_hdr_key = hdr.je_hdr_key
	 and hdr.COMPANY_ID = @DIV_16_COMPANY_ID
	)
-- CP600000200 End
	
	UPDATE xx_fiwlr_usdet_miscodes
	set cp_hdr_no = tmp.cp_hdr_no,
	    cp_ln_no = tmp.cp_ln_no,
	    fy_cd = tmp.fy_cd,
	    pd_no = tmp.pd_no,
	    sub_pd_no = tmp.sub_pd_no	  
	from xx_fiwlr_usdet_miscodes usdet
	inner join
	xx_fiwlr_usdet_rpt_temp tmp
	on
	(
	 cast(usdet.status_rec_no as varchar) = tmp.status_rec_no
	and
	 cast(usdet.ident_rec_no as varchar) = tmp.ident_rec_no
	)
		
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	--end grab the JE and AP Cosptoint Numbers for Reporting Purposes


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY MISCODE TOTALS MATCH'
	SET @ERROR_MSG_PLACEHOLDER2 = 'COSTPOINT TOTALS - AP'

	DECLARE @record_count_costpoint int,
		@record_count_imaps int,
		@dollar_amount_costpoint decimal(14,2),
		@dollar_amount_imaps decimal(14,2)

	SELECT 	@record_count_costpoint = isnull(COUNT(1), 0),
		@dollar_amount_costpoint = isnull(SUM(CST_AMT), 0)
	FROM	imaps.deltek.aoputlap_inp_detl
	WHERE	s_status_cd = 'I'
	AND	left(notes, 3) <> 'Bal'

	SELECT  @record_count_imaps = isnull(COUNT(1), 0),
		@dollar_amount_imaps = isnull(SUM(AMOUNT), 0)
	FROM	XX_FIWLR_USDET_MISCODES
	WHERE	CP_HDR_NO IS NOT NULL
	AND	SOURCE_GROUP = 'AP'

	IF	@record_count_costpoint <> @record_count_imaps GOTO ERROR
	IF	@dollar_amount_costpoint <> @dollar_amount_imaps GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY MISCODE TOTALS MATCH'
	SET @ERROR_MSG_PLACEHOLDER2 = 'COSTPOINT TOTALS - JE'

	--DR1285
	set @record_count_costpoint = null
	set @record_count_imaps = null
	set	@dollar_amount_costpoint = null
	set @dollar_amount_imaps = null

	SELECT 	@record_count_costpoint = isnull(COUNT(1), 0),
		@dollar_amount_costpoint = isnull(SUM(TRN_AMT),0)
	FROM	imaps.deltek.aoputlje_inp_tr
	WHERE	s_status_cd = 'I'
	AND	left(notes, 3) <> 'Bal'

	SELECT  @record_count_imaps = isnull(COUNT(1),0),
		@dollar_amount_imaps = isnull(SUM(AMOUNT),0)
	FROM	XX_FIWLR_USDET_MISCODES
	WHERE	CP_HDR_NO IS NOT NULL
	AND	SOURCE_GROUP = 'JE'

	IF	@record_count_costpoint <> @record_count_imaps GOTO ERROR
	IF	@dollar_amount_costpoint <> @dollar_amount_imaps GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_ERROR_STATUS'

	UPDATE XX_ERROR_STATUS
	SET 
	STATUS = 'REPROCESSED',
	CONTROL_PT = 7,
	TIME_STAMP = current_timestamp,
	SUCCESS_COUNT = 
	(select isnull(count(1),0) from xx_fiwlr_usdet_miscodes 
	 where 	status_rec_no = err_status.status_record_num
	 and	source_group = err_status.preprocessor
	 and	cp_hdr_no is not null),
	SUCCESS_AMOUNT = 
	(select isnull(sum(amount), .00) from xx_fiwlr_usdet_miscodes 
	 where 	status_rec_no = err_status.status_record_num
	 and	source_group = err_status.preprocessor
	 and	cp_hdr_no is not null),
	ERROR_COUNT = 
	(select isnull(count(1),0) from xx_fiwlr_usdet_miscodes 
	 where 	status_rec_no = err_status.status_record_num
	 and	source_group = err_status.preprocessor
	 and	cp_hdr_no is null),
	ERROR_AMOUNT = 
	(select isnull(sum(amount), .00) from xx_fiwlr_usdet_miscodes 
	 where 	status_rec_no = err_status.status_record_num
	 and	source_group = err_status.preprocessor
	 and	cp_hdr_no is null)
	FROM 	XX_ERROR_STATUS err_status
	WHERE	CONTROL_PT = 3
	AND		INTERFACE='FIWLR'

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE TABLE'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_FIWLR_USDET_ARCHIVE'

	UPDATE XX_FIWLR_USDET_ARCHIVE
	set cp_hdr_no = miscode.cp_hdr_no,
	    cp_ln_no = 	miscode.cp_ln_no,
	    fy_cd = 	miscode.fy_cd,
	    pd_no = 	miscode.pd_no,
	    sub_pd_no = miscode.sub_pd_no,
	    proj_abbr_cd= miscode.proj_abbr_cd,
	    org_abbr_cd = miscode.org_abbr_cd,
	    acct_id 	= miscode.acct_id
	from
	XX_FIWLR_USDET_ARCHIVE arch
	INNER JOIN
	XX_FIWLR_USDET_MISCODES miscode
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
	SET @ERROR_MSG_PLACEHOLDER1 = 'DELETE SUCCESSFULLY PROCESSED MISCODES'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FROM XX_FIWLR_USDET_MISCODE'

	DELETE FROM XX_FIWLR_USDET_MISCODES
	WHERE 	CP_HDR_NO IS NOT NULL

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	UPDATE	XX_FIWLR_USDET_MISCODES
	SET	REFERENCE1 = 'M'
	
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'TRUNCATE PREPROCESSOR TABLES'
	SET @ERROR_MSG_PLACEHOLDER2 = ''

	TRUNCATE TABLE IMAPS.DELTEK.AOPUTLAP_INP_HDR

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	
	TRUNCATE TABLE IMAPS.DELTEK.AOPUTLAP_INP_DETL

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	TRUNCATE TABLE IMAPS.DELTEK.AOPUTLJE_INP_TR

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


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

PRINT @out_STATUS_DESCRIPTION

RETURN 1


END

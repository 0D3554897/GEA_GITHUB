USE [IMAPSStg]
GO
/****** Object:  StoredProcedure [dbo].[XX_CERIS_BACKUP_EMPL_LAB_INFO_SP]  ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_BACKUP_EMPL_LAB_INFO_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_CERIS_BACKUP_EMPL_LAB_INFO_SP]
GO

CREATE PROCEDURE [dbo].[XX_CERIS_BACKUP_EMPL_LAB_INFO_SP] (
@in_STATUS_RECORD_NUM      integer,
@out_STATUS_DESCRIPTION    varchar(255) = NULL OUTPUT
)

AS

/************************************************************************************************
 Procedure Name	: XX_CERIS_BACKUP_EMPL_LAB_INFO_SP  									 
 Created By		: KM									   								 
 Description    : Backup EMPL_LAB_INFO										 
 Date			: 2012-06-26				        									 
 Notes			:																		 
 Prerequisites	: 																		 
 Parameter(s)	: 																		 
	Input		:																		 
	Output		: Error Code and Error Description										 
 Tables Updated	: XX_CERIS_EMPL_LAB_INFO_PREVIOUS_VALUES					 
 Version		: 1.0																	 
 ************************************************************************************************
 Date		  Modified By			Description of change	  								 
 ----------   -------------  	   	------------------------    			  				 
 2012-06-26   KM   					Created Initial Version									 
 ***********************************************************************************************/

BEGIN

 
DECLARE	@SP_NAME         	 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@ret_code		 int,
		@count			 int,
		@last_STATUS_RECORD_NUM int,
		@days_to_maintain int

	SET @SP_NAME = 'XX_CERIS_BACKUP_EMPL_LAB_INFO_SP'


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'SET days_to_maintain'
	SET @ERROR_MSG_PLACEHOLDER2 = 'VARIABLE'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 61 : XX_CERIS_BACKUP_EMPL_LAB_INFO_SP.sql '
 
	select @days_to_maintain= cast(parameter_value as int)
	from xx_processing_parameters
	where interface_name_cd='CERIS'
	and parameter_name='ELI_BACKUP_days'

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 69 : XX_CERIS_BACKUP_EMPL_LAB_INFO_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	if @days_to_maintain is null set @days_to_maintain=33

	print cast(@days_to_maintain as varchar)

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 79 : XX_CERIS_BACKUP_EMPL_LAB_INFO_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'DELETE XX_CERIS_EMPL_LAB_INFO_PREVIOUS_VALUES'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR RECORDS OLDER THAN '+cast(@days_to_maintain as varchar)+' DAYS'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	delete XX_CERIS_EMPL_LAB_INFO_PREVIOUS_VALUES
	from XX_CERIS_EMPL_LAB_INFO_PREVIOUS_VALUES eli
	where 
	0 = (select count(1) from xx_imaps_int_status where interface_name='CERIS' and status_record_num=eli.status_record_num and created_date>=getdate()-@days_to_maintain)
	
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 97 : XX_CERIS_BACKUP_EMPL_LAB_INFO_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'LOAD XX_CERIS_EMPL_LAB_INFO_PREVIOUS_VALUES'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR THIS RUN'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 109 : XX_CERIS_BACKUP_EMPL_LAB_INFO_SP.sql '
 
	insert into XX_CERIS_EMPL_LAB_INFO_PREVIOUS_VALUES
	(STATUS_RECORD_NUM,
	EMPL_ID,
	EFFECT_DT,
	S_HRLY_SAL_CD,
	HRLY_AMT,
	SAL_AMT,
	ANNL_AMT,
	EXMPT_FL,
	S_EMPL_TYPE_CD,
	ORG_ID,
	TITLE_DESC,
	WORK_STATE_CD,
	STD_EST_HRS,
	STD_EFFECT_AMT,
	LAB_GRP_TYPE,
	GENL_LAB_CAT_CD,
	MODIFIED_BY,
	TIME_STAMP,
	PCT_INCR_RT,
	HOME_REF1_ID,
	HOME_REF2_ID,
	REASON_DESC,
	DETL_JOB_CD,
	PERS_ACT_RSN_CD,
	LAB_LOC_CD,
	MERIT_PCT_RT,
	PROMO_PCT_RT,
	COMP_PLAN_CD,
	SAL_GRADE_CD,
	S_STEP_NO,
	REVIEW_FORM_ID,
	OVERALL_RT,
	MGR_EMPL_ID,
	END_DT,
	SEC_ORG_ID,
	COMMENTS,
	EMPL_CLASS_CD,
	WORK_YR_HRS_NO,
	BILL_LAB_CAT_CD,
	PERS_ACT_RSN_CD_2,
	PERS_ACT_RSN_CD_3,
	REASON_DESC_2,
	REASON_DESC_3,
	CORP_OFCR_FL,
	SEASON_EMPL_FL,
	HIRE_DT_FL,
	TERM_DT_FL,
	AFF_PLAN_CD,
	JOB_GROUP_CD,
	AA_COMMENTS,
	TC_TS_SCHED_CD,
	TC_WORK_SCHED_CD,
	ROWVERSION,
	HR_ORG_ID)
	select 
	@in_STATUS_RECORD_NUM as STATUS_RECORD_NUM,
	EMPL_ID,
	EFFECT_DT,
	S_HRLY_SAL_CD,
	HRLY_AMT,
	SAL_AMT,
	ANNL_AMT,
	EXMPT_FL,
	S_EMPL_TYPE_CD,
	ORG_ID,
	TITLE_DESC,
	WORK_STATE_CD,
	STD_EST_HRS,
	STD_EFFECT_AMT,
	LAB_GRP_TYPE,
	GENL_LAB_CAT_CD,
	MODIFIED_BY,
	TIME_STAMP,
	PCT_INCR_RT,
	HOME_REF1_ID,
	HOME_REF2_ID,
	REASON_DESC,
	DETL_JOB_CD,
	PERS_ACT_RSN_CD,
	LAB_LOC_CD,
	MERIT_PCT_RT,
	PROMO_PCT_RT,
	COMP_PLAN_CD,
	SAL_GRADE_CD,
	S_STEP_NO,
	REVIEW_FORM_ID,
	OVERALL_RT,
	MGR_EMPL_ID,
	END_DT,
	SEC_ORG_ID,
	COMMENTS,
	EMPL_CLASS_CD,
	WORK_YR_HRS_NO,
	BILL_LAB_CAT_CD,
	PERS_ACT_RSN_CD_2,
	PERS_ACT_RSN_CD_3,
	REASON_DESC_2,
	REASON_DESC_3,
	CORP_OFCR_FL,
	SEASON_EMPL_FL,
	HIRE_DT_FL,
	TERM_DT_FL,
	AFF_PLAN_CD,
	JOB_GROUP_CD,
	AA_COMMENTS,
	TC_TS_SCHED_CD,
	TC_WORK_SCHED_CD,
	ROWVERSION,
	HR_ORG_ID
	from imaps.deltek.empl_lab_info eli
	where
	0 <> (select count(1) from xx_ceris_hist where empl_id=eli.empl_id and division in ('16','1M') and term_dt is null)

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 226 : XX_CERIS_BACKUP_EMPL_LAB_INFO_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR	


RETURN 0

ERROR:

PRINT @out_STATUS_DESCRIPTION

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 239 : XX_CERIS_BACKUP_EMPL_LAB_INFO_SP.sql '
 
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

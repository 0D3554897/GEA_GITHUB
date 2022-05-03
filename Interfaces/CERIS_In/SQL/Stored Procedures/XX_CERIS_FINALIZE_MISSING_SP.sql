USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_FINALIZE_MISSING_SP]    Script Date: 02/28/2018 14:19:41 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_CERIS_FINALIZE_MISSING_SP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[XX_CERIS_FINALIZE_MISSING_SP]
GO

USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_FINALIZE_MISSING_SP]    Script Date: 02/28/2018 14:19:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[XX_CERIS_FINALIZE_MISSING_SP] (
@out_STATUS_DESCRIPTION sysname = NULL output
)

AS

/************************************************************************************************
Procedure Name	: XX_CERIS_FINALIZE_MISSING_SP  									 
Created By		: GEA									   								 
Description    	: Update Missing Records with latest Status Record Number and email notification recipients											 
Date			: 2017-03-10				        									 
Notes			:																		 
Prerequisites	: WORKDAY must be successfully run before this			 
Parameter(s)	: 																		 
	Input		:																		 
	Output		: Error Code and Error Description						 
 Tables Updated	: XX_CERIS_DATA_STG_MISSING,									 
Version			: 1.0																	 
************************************************************************************************
Date		Modified By			Description of change	  								 
----------   -------------  	------------------------    			  				 
2017-03-10	 george             Created Initial Version - CR9295					 

CR9295 - gea - 4/13/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
CR9831 - gea - 2/1/2018  - Added query to reactivate employees in missing table
************************************************************************************************/


BEGIN

 
 
PRINT '' -- *~^ CR9295
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        BEGIN XX_CERIS_FINALIZE_MISSING_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' -- *~^ CR9295
 
DECLARE	@SP_NAME         			sysname,

        @IMAPS_error_number      	integer,
        @SQLServer_error_code    	integer,
        @error_msg_placeholder1  	sysname,
        @error_msg_placeholder2  	sysname,
		@ret_code				 	int,
		@count					 	int,
		@current_STATUS_RECORD_NUM 	int



	set @count = 0


	--1
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'FIND STATUS_RECORD_NUM'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR EXTRACT'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 79 : XX_CERIS_FINALIZE_MISSING_SP.sql '  --CR9295
 
	select @count = count(1)
	from XX_CERIS_DATA_STG_MISSING
	where
	created_by = 'MISSING'

 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	
	IF @count > 0
		BEGIN	
			select @current_STATUS_RECORD_NUM = STATUS_RECORD_NUM
			from XX_IMAPS_INT_STATUS
			where
			interface_name='CERIS_LOAD'
			and 
			STATUS_CODE in ('COMPLETED')

-- notify people who need to know by email

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 101 : XX_CERIS_FINALIZE_MISSING_SP.sql '  --CR9295

 			EXEC dbo.XX_CERIS_SEND_MISSING_NOTICE_SP

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 106 : XX_CERIS_FINALIZE_MISSING_SP.sql '  --CR9295

--this update statement must update via coalesce the same columns as those identified in the properties file as REQUIRED
 
			UPDATE imapsstg.DBO.XX_CERIS_DATA_STG_missing 
			SET CREATED_BY = @current_STATUS_RECORD_NUM
			,REC_TYPE = COALESCE(NULLIF(REC_TYPE,''),'MISSING')
			,SERIAL = COALESCE(NULLIF(SERIAL,''),'MISSING')
			,HIRE_DATE_EFF = COALESCE(NULLIF(HIRE_DATE_EFF,''),'MISSING')
			,HIRE_DATE_SRD = COALESCE(NULLIF(HIRE_DATE_SRD,''),'MISSING')
			,DEPT_MGR_SER_1 = COALESCE(NULLIF(DEPT_MGR_SER_1,''),'MISSING')
			,DEPT_MGR_NAME_LAST = COALESCE(NULLIF(DEPT_MGR_NAME_LAST,''),'MISSING')
			,DEPT_MGR_NAME_INIT = COALESCE(NULLIF(DEPT_MGR_NAME_INIT,''),'MISSING')
			,JOB_FAMILY_1 = COALESCE(NULLIF(JOB_FAMILY_1,''),'MISSING')
			,JOB_FAMILY_DATE_1 = COALESCE(NULLIF(JOB_FAMILY_DATE_1,''),'MISSING')
			,LEVEL_PREFIX_1 = COALESCE(NULLIF(LEVEL_PREFIX_1,''),'MISSING')
			,LVL_DATE_1 = COALESCE(NULLIF(LVL_DATE_1,''),'MISSING')
			,DIVISION_1 = COALESCE(NULLIF(DIVISION_1,''),'MISSING')
			,DIV_DATE = COALESCE(NULLIF(DIV_DATE,''),'MISSING')
			,DEPT_PLUS_SFX = COALESCE(NULLIF(DEPT_PLUS_SFX,''),'MISSING')
			,DEPT_DATE = COALESCE(NULLIF(DEPT_DATE,''),'MISSING')
			,EX_NE_OUT = COALESCE(NULLIF(EX_NE_OUT,''),'MISSING')
			,POS_CODE_1 = COALESCE(NULLIF(POS_CODE_1,''),'MISSING')
			,JOB_TITLE = COALESCE(NULLIF(JOB_TITLE,''),'MISSING')
			,POS_DATE_1 = COALESCE(NULLIF(POS_DATE_1,''),'MISSING')
			,EMPL_STAT_1ST = COALESCE(NULLIF(EMPL_STAT_1ST,''),'MISSING')
			,EMPL_STAT_2ND = COALESCE(NULLIF(EMPL_STAT_2ND,''),'MISSING')
			,EMPL_STAT_DATE = COALESCE(NULLIF(EMPL_STAT_DATE,''),'MISSING')
			,WORK_SCHD = COALESCE(NULLIF(WORK_SCHD,''),'MISSING')
			,WORK_SCHD_DATE = COALESCE(NULLIF(WORK_SCHD_DATE,''),'MISSING')
			-- CR9831 ,SET_ID = COALESCE(NULLIF(SET_ID,''),'MISSING')
			-- CR9831 ,LOC_WORK_1 = COALESCE(NULLIF(LOC_WORK_1,''),'MISSING')
			-- CR9831 ,LOC_WORK_ST = COALESCE(NULLIF(LOC_WORK_ST,''),'MISSING')
			,LOC_WORK_DTE_1 = COALESCE(NULLIF(LOC_WORK_DTE_1,''),'MISSING')
			-- CR9831 ,TBWKL_CITY = COALESCE(NULLIF(TBWKL_CITY,''),'MISSING')
			,SALARY = COALESCE(NULLIF(SALARY,''),'MISSING')
			,SAL_CHG_DTE_1 = COALESCE(NULLIF(SAL_CHG_DTE_1,''),'MISSING')
			-- CR9831 ,SAL_RTE_CDE = COALESCE(NULLIF(SAL_RTE_CDE,''),'MISSING')
			,SAL_BASE = COALESCE(NULLIF(SAL_BASE,''),'MISSING')
			,SAL_MO_OUT = COALESCE(NULLIF(SAL_MO_OUT,''),'MISSING')
			,NAME_LAST_MIXED = COALESCE(NULLIF(NAME_LAST_MIXED,''),'MISSING')
			,NAME_FIRST_MIXED = COALESCE(NULLIF(NAME_FIRST_MIXED,''),'MISSING')
			,NAME_INIT = COALESCE(NULLIF(NAME_INIT,''),'MISSING')
			WHERE CREATED_BY = 'MISSING'   --CR9295

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 156 : XX_CERIS_FINALIZE_MISSING_SP.sql '  --CR9295

			-- CR 9831 - re-activate employees just added to missing table
			update IMAPS.DELTEK.EMPL
			set s_empl_status_cd='ACT',term_dt=NULL
			where empl_id in (select serial from IMAPSStg.dbo.XX_CERIS_DATA_STG_MISSING 
								where CREATED_BY=@current_STATUS_RECORD_NUM and COALESCE(SEP_DATE,'')=''
								AND DIVISION_1 IN ('16','1P','1M','2G') )
			and S_EMPL_STATUS_CD='IN'

PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 165 : XX_CERIS_FINALIZE_MISSING_SP.sql '  --CR9295


		END
		else
		begin
			print 'some kind of status record number problem....'
		END



 
PRINT '' -- *~^ CR9295
PRINT '*~^*************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF  XX_CERIS_FINALIZE_MISSING_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' -- *~^ CR9295
 
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



GO



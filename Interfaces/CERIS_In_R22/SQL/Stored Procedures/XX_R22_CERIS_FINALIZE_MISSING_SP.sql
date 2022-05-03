USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CERIS_FINALIZE_MISSING_SP]    Script Date: 06/30/2017 14:34:40 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_R22_CERIS_FINALIZE_MISSING_SP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[XX_R22_CERIS_FINALIZE_MISSING_SP]
GO

USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CERIS_FINALIZE_MISSING_SP]    Script Date: 06/30/2017 14:34:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[XX_R22_CERIS_FINALIZE_MISSING_SP] (
@out_STATUS_DESCRIPTION sysname = NULL output
)

AS

/************************************************************************************************
Procedure Name	: XX_R22_CERIS_FINALIZE_MISSING_SP  									 
Created By		: GEA									   								 
Description    	: Update Missing Records with latest Status Record Number and email notification recipients									

		 
Date			: 2017-04-07				        									 
Notes			:																		 
Prerequisites	: WORKDAY must be successfully run before this			 
Parameter(s)	: 																		 
	Input		:																		 
	Output		: Error Code and Error Description						 
 Tables Updated	: XX_R22_CERIS_DATA_STG_MISSING,									 
Version			: 1.0																	 
************************************************************************************************
Date		Modified By			Description of change	  								 
----------   -------------  	------------------------    			  				 
2017-04-07	 george             Created Initial Version - CR9296					 
CR9296 - gea - 4/7/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
************************************************************************************************/


BEGIN

 
DECLARE	@SP_NAME         		sysname,
        @IMAPS_error_number      	integer,
        @SQLServer_error_code    	integer,
        @error_msg_placeholder1  	sysname,
        @error_msg_placeholder2  	sysname,
		@ret_code				 	int,
		@count					 	int,
		@current_STATUS_RECORD_NUM 	int,
		@missing					varbinary

SET @missing = 0x		

PRINT '' --CR9296
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_R22_CERIS_FINALIZE_MISSING_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9296

SET @SP_NAME = 'XX_R22_CERIS_FINALIZE_MISSING_SP'

	set @count = 0

	--1
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'FIND STATUS_RECORD_NUM'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR EXTRACT'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2


 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 76 : XX_R22_CERIS_FINALIZE_MISSING_SP.sql '  --CR9296
 
	select @count = count(1)
	from XX_R22_CERIS_DATA_STG_MISSING
	where
	created_by = 'MISSING'

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	
	IF @count > 0
		BEGIN	
			select @current_STATUS_RECORD_NUM = STATUS_RECORD_NUM
			from XX_IMAPS_INT_STATUS
			where
			interface_name='CERIS_R22'
			and 
			STATUS_CODE in ('COMPLETED')

--this update statement must update via coalesce the same columns as those identified in the properties file as REQUIRED
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 99 : XX_R22_CERIS_FINALIZE_MISSING_SP.sql '  --CR9296

			UPDATE imapsstg.DBO.XX_R22_CERIS_DATA_STG_missing 
			SET CREATED_BY = @current_STATUS_RECORD_NUM
			,R_EMPL_ID= COALESCE(R_EMPL_ID,@missing)
			,DEPT = COALESCE(NULLIF(DEPT,''),'MISSING')
			,DEPT_SHIFT_1 = COALESCE(NULLIF(DEPT_SHIFT_1,''),'MISSING')
			,DEPT_SHIFT_DT = COALESCE(NULLIF(DEPT_SHIFT_DT,''),'MISSING')
			,DEPT_START_DT = COALESCE(NULLIF(DEPT_START_DT,''),'MISSING')
			,DIVISION = COALESCE(NULLIF(DIVISION,''),'MISSING')
			,DIVISION_START_DT = COALESCE(NULLIF(DIVISION_START_DT,''),'MISSING')
			,EMPL_STAT_DT = COALESCE(NULLIF(EMPL_STAT_DT,''),'MISSING')
			,FLSA_STAT = COALESCE(NULLIF(FLSA_STAT,''),'MISSING')
			,FNAME = COALESCE(NULLIF(FNAME,''),'MISSING')
			,HIRE_EFF_DT = COALESCE(NULLIF(HIRE_EFF_DT,''),'MISSING')
			,IBM_START_DT = COALESCE(NULLIF(IBM_START_DT,''),'MISSING')
			,JOB_FAM = COALESCE(NULLIF(JOB_FAM,''),'MISSING')
			,JOB_FAM_DT = COALESCE(NULLIF(JOB_FAM_DT,''),'MISSING')
			,LNAME = COALESCE(NULLIF(LNAME,''),'MISSING')
			,LVL_DT_1 = COALESCE(NULLIF(LVL_DT_1,''),'MISSING')
			,MGR_INITIALS = COALESCE(NULLIF(MGR_INITIALS,''),'MISSING')
			,MGR_LNAME = COALESCE(NULLIF(MGR_LNAME,''),'MISSING')
			,MGR_SERIAL_NUM = COALESCE(NULLIF(MGR_SERIAL_NUM,''),@missing)
			,MGR2_INITIALS = COALESCE(NULLIF(MGR2_INITIALS,''),'MISSING')
			,MGR2_LNAME = COALESCE(NULLIF(MGR2_LNAME,''),'MISSING')
			,MGR3_INITIALS = COALESCE(NULLIF(MGR3_INITIALS,''),'MISSING')
			,MGR3_LNAME = COALESCE(NULLIF(MGR3_LNAME,''),'MISSING')
			,NAME_INITIALS = COALESCE(NULLIF(NAME_INITIALS,''),'MISSING')
			,POS_CODE = COALESCE(NULLIF(POS_CODE,''),'MISSING')
			,POS_DESC = COALESCE(NULLIF(POS_DESC,''),'MISSING')
			,POS_DT = COALESCE(NULLIF(POS_DT,''),'MISSING')
			,REG_TEMP = COALESCE(NULLIF(REG_TEMP,''),'MISSING')
			,SAL_BAND = COALESCE(NULLIF(SAL_BAND,''),'MISSING')
			,SALARY = COALESCE(NULLIF(SALARY,''),@missing)
			,SALARY_DT = COALESCE(NULLIF(SALARY_DT,''),'MISSING')
			,STATUS = COALESCE(NULLIF(STATUS,''),'MISSING')
			,STD_HRS = COALESCE(NULLIF(STD_HRS,''),'MISSING')
			,WORK_SCHD_DT = COALESCE(NULLIF(WORK_SCHD_DT,''),'MISSING')
			WHERE CREATED_BY = 'MISSING'   --CR9296



		END
		else
		begin
			print 'some kind of status record number problem....'
		END



PRINT '' --CR9296
PRINT '*~^*************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF  XX_R22_CERIS_FINALIZE_MISSING_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9296
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



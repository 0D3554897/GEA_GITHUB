USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_LOAD_SIT_UAT_ONLY_SCRAMBLE_SALARY_SP]  ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_LOAD_SIT_UAT_ONLY_SCRAMBLE_SALARY_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_CERIS_LOAD_SIT_UAT_ONLY_SCRAMBLE_SALARY_SP]
GO

CREATE PROCEDURE [dbo].[XX_CERIS_LOAD_SIT_UAT_ONLY_SCRAMBLE_SALARY_SP] (
@out_STATUS_DESCRIPTION sysname = NULL output
)

AS

/************************************************************************************************
Procedure Name	: XX_CERIS_LOAD_SIT_UAT_ONLY_SCRAMBLE_SALARY_SP  									 
Created By		: KM									   								 
Description    	: Extract Checks and Status Update											 
Date			: 2012-08-20			        									 
Notes			:																		 
Prerequisites	: Step 2 is the Java program and it should run before this				 
Parameter(s)	: 																		 
	Input		:																		 
	Output		: Error Code and Error Description						 
 Tables Updated	: XX_IMAPS_INT_STATUS, 	XX_IMAPS_INT_CONTROL									 
Version			: 1.0																	 
************************************************************************************************
Date		Modified By			Description of change	  								 
----------   -------------  	------------------------    			  				 
2012-06-26   KM   				Created Initial Version	

CR6542 - Sal_Base instead of Salary for employees getting commissions - KM - 2013-08-14								 
************************************************************************************************/

BEGIN

 
DECLARE	@SP_NAME         	 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@ret_code		 int,
		@count			 int,
		@current_STATUS_RECORD_NUM int

	SET @SP_NAME = 'XX_CERIS_LOAD_SIT_UAT_ONLY_SCRAMBLE_SALARY_SP'
	set @count = 1


	--1
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'SCRAMBLE SALARY'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR Monthly Flavor'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	--monthly
	update XX_CERIS_DATA_STG
	set --SAL_BASE='1',
		SAL_MO_OUT=SALARY, --'1',
		SALARY=

		isnull(
			(select
			cast(cast((min(GENL_AVG_RT_AMT*40*4)+max(GENL_AVG_RT_AMT*40*4))/2000 as int) as varchar)
			from imaps.deltek.genl_lab_cat
			where len(genl_lab_cat_cd)=6
			and genl_avg_rt_amt<>0
			and right(genl_lab_cat_cd,2)=ceris.LEVEL_PREFIX_1), '4')
			+
			'000.00' --right(SERIAL,3)+'.00'

	from XX_CERIS_DATA_STG ceris
	where 
	not (EMPL_STAT_1ST='3' and EX_NE_OUT='E' and isnull(EMPL_STAT_3RD,'')<>'2') --daily 
	and
	not (EMPL_STAT_1ST='3' and EX_NE_OUT='N' and isnull(EMPL_STAT_3RD,'')<>'2') --hourly


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 86 : XX_CERIS_LOAD_SIT_UAT_ONLY_SCRAMBLE_SALARY_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'SCRAMBLE SALARY'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR Daily Flavor'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	--daily
	update XX_CERIS_DATA_STG
	set --SAL_BASE='1',
		SAL_MO_OUT=SALARY, --'1',
		SALARY=

		isnull(
			(select
			cast(cast((min(GENL_AVG_RT_AMT*8)+max(GENL_AVG_RT_AMT*8))/200 as int) as varchar)
			from imaps.deltek.genl_lab_cat
			where len(genl_lab_cat_cd)=6
			and genl_avg_rt_amt<>0
			and right(genl_lab_cat_cd,2)=ceris.LEVEL_PREFIX_1), '4')
		+
		'00.00' --right(SERIAL,2)+'.00'
	from XX_CERIS_DATA_STG ceris
	where EMPL_STAT_1ST='3' and EX_NE_OUT='E' and isnull(EMPL_STAT_3RD,'')<>'2' --daily 


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 118 : XX_CERIS_LOAD_SIT_UAT_ONLY_SCRAMBLE_SALARY_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR




	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'SCRAMBLE SALARY'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR Hourly Flavor'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	--houly
	update XX_CERIS_DATA_STG
	set --SAL_BASE='1',
		SAL_MO_OUT=SALARY, --'1',
		SALARY=
		isnull(
			(select
			cast(cast((min(GENL_AVG_RT_AMT)+max(GENL_AVG_RT_AMT))/20 as int) as varchar)
			from imaps.deltek.genl_lab_cat
			where len(genl_lab_cat_cd)=6
			and genl_avg_rt_amt<>0
			and right(genl_lab_cat_cd,2)=ceris.LEVEL_PREFIX_1), '4')
		+
		'0.00'
		--right(SERIAL,1)+'.00'
	from XX_CERIS_DATA_STG ceris
	where EMPL_STAT_1ST='3' and EX_NE_OUT='N' and isnull(EMPL_STAT_3RD,'')<>'2' --hourly


 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 151 : XX_CERIS_LOAD_SIT_UAT_ONLY_SCRAMBLE_SALARY_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	


	--update SAL_BASE for normal employees
	update XX_CERIS_DATA_STG
	set SAL_BASE=SALARY,
		SAL_MO_OUT=SALARY
	where cast(sal_base as decimal(14,2))<>0 --sal_base not 0 0
	and cast(sal_base as decimal(14,2)) = cast(SAL_MO_OUT as decimal(14,2)) --sal_base = salary (from orig non-scrubbed file)

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 166 : XX_CERIS_LOAD_SIT_UAT_ONLY_SCRAMBLE_SALARY_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	--update SAL_BASE for employees on commissions
	update XX_CERIS_DATA_STG
	set SAL_BASE= cast( (cast(salary as decimal(14,2)) * 0.82) as decimal(14,2) ),
		SAL_MO_OUT=SALARY
	where cast(sal_base as decimal(14,2))<>0 --sal_base not 0
	and cast(sal_base as decimal(14,2))<>cast(SAL_MO_OUT as decimal(14,2)) --sal_base <> salary (from orig non-scrubbed file)

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 179 : XX_CERIS_LOAD_SIT_UAT_ONLY_SCRAMBLE_SALARY_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	--update SAL_MO_OUT for execs with 0 SAL_BASE
	update XX_CERIS_DATA_STG
	set SAL_MO_OUT=SALARY
	where cast(sal_base as decimal(14,2))=0 --sal_base not 0
	
 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 190 : XX_CERIS_LOAD_SIT_UAT_ONLY_SCRAMBLE_SALARY_SP.sql '
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	


RETURN 0

ERROR:

PRINT @out_STATUS_DESCRIPTION

 
PRINT convert(varchar, current_timestamp, 21) + ' : WORKDAY : Line 204 : XX_CERIS_LOAD_SIT_UAT_ONLY_SCRAMBLE_SALARY_SP.sql '
 
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

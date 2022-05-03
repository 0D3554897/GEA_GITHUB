USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_CERIS_LOAD_STEP3_SP]  ******/


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_LOAD_STEP3_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_CERIS_LOAD_STEP3_SP]
GO

CREATE PROCEDURE [dbo].[XX_CERIS_LOAD_STEP3_SP] (
@out_STATUS_DESCRIPTION sysname = NULL output
)

AS

/************************************************************************************************
Procedure Name	: XX_CERIS_LOAD_STEP3_SP  									 
Created By		: KM									   								 
Description    	: Extract Checks and Status Update											 
Date			: 2012-06-26				        									 
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
2017-03-09	 george             Modify to validate count of records missing required info						 

CR9295 - gea - 4/13/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
************************************************************************************************/


BEGIN

 
 
PRINT '' -- *~^ CR9295
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        BEGIN XX_CERIS_LOAD_STEP3_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' -- *~^ CR9295
 
DECLARE	@SP_NAME         	 sysname,

        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@ret_code		 int,
		@count			 int,
		@current_STATUS_RECORD_NUM int



	set @count = 1


	--1
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'FIND STATUS_RECORD_NUM'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR EXTRACT'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 80 : XX_CERIS_LOAD_STEP3_SP.sql '  --CR9295
 
	select @count = count(1)
	from XX_IMAPS_INT_STATUS
	where
	interface_name='CERIS_LOAD'
	and 
	STATUS_CODE not in ('COMPLETED', 'RESET')


 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @count <> 1 GOTO ERROR

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 98 : XX_CERIS_LOAD_STEP3_SP.sql '  --CR9295
 
	select @current_STATUS_RECORD_NUM = STATUS_RECORD_NUM
	from XX_IMAPS_INT_STATUS
	where
	interface_name='CERIS_LOAD'
	and 
	STATUS_CODE not in ('COMPLETED', 'RESET')


 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @current_STATUS_RECORD_NUM IS NULL GOTO ERROR


	--2
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY JAVA'
	SET @ERROR_MSG_PLACEHOLDER2 = 'EXECUTION'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 123 : XX_CERIS_LOAD_STEP3_SP.sql '  --CR9295
 
	SELECT @count = COUNT(1)
	FROM xx_ceris_data_stg

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @count <= 1 GOTO ERROR

/*
	check header

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 140 : XX_CERIS_LOAD_STEP3_SP.sql '  --CR9295
 
	SELECT @count = COUNT(1)
	FROM xx_ceris_lcdb_empl_assignments_stg
*/



	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @count <= 1 GOTO ERROR



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY'
	SET @ERROR_MSG_PLACEHOLDER2 = 'NO DUPES'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 161 : XX_CERIS_LOAD_STEP3_SP.sql '  --CR9295
 
	select serial, count(1)
	from xx_ceris_data_stg
	group by serial
	having count(1) >1

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 171 : XX_CERIS_LOAD_STEP3_SP.sql '  --CR9295
 
	SELECT @count = @@ROWCOUNT

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @count <> 0 GOTO ERROR



/*
	PERFORM CHECK ON HEADER VALUES
	
	-NO STRICT CHECK ON SEQUENCE NO
	-STRICT CHECKS ON RECORD COUNT AND HASH

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 192 : XX_CERIS_LOAD_STEP3_SP.sql '  --CR9295
 
	select * from xx_ceris_data_hdr_stg

*/


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'OBTAIN CONTROL DATA'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FROM HEADER'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	declare @seq_out int,
			@recs_out int,
			@table_recs_out int,
			@recs_missing int,
			@hash int,
			@expected_seq_out int,
			@expected_recs_out int,
			@expected_recs_missing int -- CR9295
	--		@expected_hash int

  -- hash holds the number of stem records not loaded
 

 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 218 : XX_CERIS_LOAD_STEP3_SP.sql '  --CR9295
 
	select @seq_out	= cast(SEQ_OUT as int),
		@recs_out	= cast(RECS_OUT as int),
	 	@hash		= cast(HASH as int)
	FROM XX_CERIS_DATA_HDR_STG

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'OBTAIN EXPECTED CONTROL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'DATA FROM DATA'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	set @expected_seq_out=0
	select @expected_seq_out = cast(seq_out as int)+1
	from XX_CERIS_DATA_HDR_STG_ARCH
	where status_record_num=(select max(status_record_num) from XX_CERIS_DATA_HDR_STG_ARCH)

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	set @expected_recs_out=0
	set @expected_recs_out = (select cast(count(1) as varchar) from xx_ceris_data_stg)
         -- start CR 9295
        set @table_recs_out= @expected_recs_out


        set @expected_recs_missing=0
        set @expected_recs_missing = (select cast(count(1) as varchar) from xx_ceris_data_stg_missing where CREATED_BY = 'MISSING')

PRINT '********************************************************************************************************'
PRINT '*       VALIDATION CALCULATION                                                                         *'
PRINT '*                                                                                                      *'
PRINT '* EXPECTED RECORDS MISSING (RECS IN MISSING TABLE) = ' + CAST(@expected_recs_missing AS VARCHAR)
PRINT '* EXPECTED RECORDS OUT (RECS IN  DATA STAGE TABLE) = ' + CAST(@table_recs_out AS VARCHAR)
PRINT '* RECORDS OUT (REC CNT IN FILE HDR) = ' + CAST(@recs_out AS VARCHAR)
PRINT '* HASH (STEM RECORDS FOUND IN DATA FILE) = ' + CAST (@HASH AS VARCHAR)
PRINT '* '
PRINT '* CALCULATION :' + CAST(@expected_recs_out AS VARCHAR) + ' + ' + CAST(@expected_recs_missing AS VARCHAR) + ' SHOULD EQUAL ' + CAST((CAST(@recs_out AS INT) + CAST(@HASH AS INT)) AS VARCHAR) + ' - ' + CAST(@hash AS VARCHAR)
PRINT '* ' 
PRINT '********************************************************************************************************'

        set @expected_recs_out = @expected_recs_out + @expected_recs_missing
        set @recs_out = @recs_out - @hash

        -- end CR 9295

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	
/* no longer needed with workday
	set @expected_hash=0
	set @expected_hash = 
	(
	select 
	sum(
	case 
	 when 1=isnumeric(substring(serial,1,1)) then cast(substring(serial,1,1) as int)
	 else 0
	end
	+
	case 
	 when 1=isnumeric(substring(serial,2,1)) then cast(substring(serial,2,1) as int)
	 else 0
	end
	+
	case 
	 when 1=isnumeric(substring(serial,3,1)) then cast(substring(serial,3,1) as int)
	 else 0
	end
	+
	case 
	 when 1=isnumeric(substring(serial,4,1)) then cast(substring(serial,4,1) as int)
	 else 0
	end
	+
	case
	 when 1=isnumeric(substring(serial,5,1)) then cast(substring(serial,5,1) as int)
	 else 0
	end
	+
	case
	 when 1=isnumeric(substring(serial,6,1)) then cast(substring(serial,6,1) as int)
	 else 0
	end
	)
	from xx_Ceris_data_stg
	)


	set @expected_hash = @expected_hash +
		(
	select 
	sum(
	case 
	 when 1=isnumeric(substring(RUN_DATE,1,1)) then cast(substring(RUN_DATE,1,1) as int)
	 else 0
	end
	+
	case 
	 when 1=isnumeric(substring(RUN_DATE,2,1)) then cast(substring(RUN_DATE,2,1) as int)
	 else 0
	end
	+
	case 
	 when 1=isnumeric(substring(RUN_DATE,3,1)) then cast(substring(RUN_DATE,3,1) as int)
	 else 0
	end
	+
	case 
	 when 1=isnumeric(substring(RUN_DATE,4,1)) then cast(substring(RUN_DATE,4,1) as int)
	 else 0
	end
	+
	case
	 when 1=isnumeric(substring(RUN_DATE,5,1)) then cast(substring(RUN_DATE,5,1) as int)
	 else 0
	end
	+
	case
	 when 1=isnumeric(substring(RUN_DATE,6,1)) then cast(substring(RUN_DATE,6,1) as int)
	 else 0
	end
	+
	case
	 when 1=isnumeric(substring(RUN_DATE,7,1)) then cast(substring(RUN_DATE,7,1) as int)
	 else 0
	end
	+
	case
	 when 1=isnumeric(substring(RUN_DATE,8,1)) then cast(substring(RUN_DATE,8,1) as int)
	 else 0
	end
	)
	from xx_ceris_data_hdr_stg
	)
*/


	if @seq_out <> @expected_seq_out
	begin
		--sequence check is soft by default, unless this hard sequence check parameter is created with a value of yes
		declare @hard_seq_check sysname

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 373 : XX_CERIS_LOAD_STEP3_SP.sql '  --CR9295
 
		select @hard_seq_check=parameter_value
		from xx_processing_parameters
		where interface_name_cd='CERIS_LOAD'
		and parameter_name='HARD_SEQ_CHECK'

		if @hard_seq_check is not null and @hard_seq_check = 'yes'
		begin	
			SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
			SET @ERROR_MSG_PLACEHOLDER1 = 'PERFORM HARD CHECK'
			SET @ERROR_MSG_PLACEHOLDER2 = 'ON SEQ_OUT VALUE'
			GOTO ERROR
		end
		else
		begin
			print 'SEQ_OUT out of sequence! soft warning .....'
		end
	end
	else
	begin
		print 'SEQ_OUT valid.'
	end



	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'CHECK RECS_OUT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'CONTROL'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	if isnull(@recs_out,0) <> isnull(@expected_recs_out,0)
	begin
	    DELETE FROM imapsstg.DBO.XX_CERIS_DATA_STG_missing WHERE CREATED_BY = 'MISSING'   --CR9295
		GOTO ERROR
	end

	/* no longer needed for workday	
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'CHECK HASH'
	SET @ERROR_MSG_PLACEHOLDER2 = 'CONTROL'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	if isnull(@hash,0) <> isnull(@expected_hash,0)
	begin
		GOTO ERROR
	end
*/



	--3
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE XX_IMAPS_INT_STATUS'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH CONTROL TOTALS'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	--TODO, do header checks!

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 434 : XX_CERIS_LOAD_STEP3_SP.sql '  --CR9295
 
	UPDATE XX_IMAPS_INT_STATUS
	SET 
	MODIFIED_BY = suser_name(),
	MODIFIED_DATE = current_timestamp,
	RECORD_COUNT_INITIAL = (SELECT count(1) FROM xx_ceris_data_stg),
	RECORD_COUNT_SUCCESS = (SELECT count(1) FROM xx_ceris_data_stg),
	RECORD_COUNT_ERROR=0,
	AMOUNT_INPUT= (SELECT count(1) FROM xx_ceris_data_stg),
	AMOUNT_PROCESSED= (SELECT count(1) FROM xx_ceris_data_stg),
	AMOUNT_FAILED=0
	WHERE 
	STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM


 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_IMAPS_INT_CONTROL'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 463 : XX_CERIS_LOAD_STEP3_SP.sql '  --CR9295
 
      EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
         @in_int_ctrl_pt_num     = 2,
         @in_lookup_domain_const = 'LD_CERIS_LOAD_CTRL_PT',
         @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	IF @ret_code <> 0 GOTO ERROR



PRINT ' '
PRINT '****** UPDATING STATUS RECORD NUMBER ' + CAST(@current_STATUS_RECORD_NUM AS VARCHAR) + ' TO COMPLETED ******'
PRINT ' '
 
 

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 486 : XX_CERIS_LOAD_STEP3_SP.sql '  --CR9295
 
	EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
	   @in_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM,
	   @in_STATUS_CODE       = 'COMPLETED'

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @ret_code <> 0 GOTO ERROR

	-- Create e-mail data to be used by the PORT application to send e-mail to interface stakeholders
 

 
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 503 : XX_CERIS_LOAD_STEP3_SP.sql '  --CR9295
 
	EXEC @ret_code = dbo.XX_SEND_STATUS_MAIL_SP
	   @in_StatusRecordNum = @current_STATUS_RECORD_NUM

 
 
	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @ret_code <> 0 GOTO ERROR
	


 
PRINT '' -- *~^ CR9295
PRINT '*~^*************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF  XX_CERIS_LOAD_STEP3_SP.sql'
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

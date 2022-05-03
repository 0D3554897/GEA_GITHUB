USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CERIS_LOAD_STEP3_SP]    Script Date: 04/07/2017 10:48:20 ******/

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[XX_R22_CERIS_LOAD_STEP3_SP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[XX_R22_CERIS_LOAD_STEP3_SP]
GO

USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CERIS_LOAD_STEP3_SP]    Script Date: 04/07/2017 10:48:20 ******/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[XX_R22_CERIS_LOAD_STEP3_SP] (
@out_STATUS_DESCRIPTION sysname = NULL output
)

AS

/************************************************************************************************
Procedure Name	: XX_R22_CERIS_LOAD_STEP3_SP  									 
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
2017-03-09	 george             Modify to validate count of records missing required info - CR9296					 
CR9296 - gea - 4/25/2017 - Inserted/Renumbered multiple PRINT statements for logging purposes - marked by: *~^
************************************************************************************************/


BEGIN

 
DECLARE	@SP_NAME         	 sysname,
        @IMAPS_error_number      integer,
        @SQLServer_error_code    integer,
        @error_msg_placeholder1  sysname,
        @error_msg_placeholder2  sysname,
		@ret_code		 int,
		@count			 int,
		@current_STATUS_RECORD_NUM int,
		@in_STATUS_DESCRIPTION   varchar(50)

PRINT '' --CR9296 *~^
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_R22_CERIS_LOAD_STEP3_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9296 *~^
-- *~^
SET @SP_NAME = 'XX_R22_CERIS_LOAD_STEP3_SP'

	set @count = 1


	--1
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'FIND STATUS_RECORD_NUM'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FOR EXTRACT'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

PRINT 'counting STATUS'

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 83 : XX_R22_CERIS_LOAD_STEP3_SP.sql '  --CR9296
 
	select @count = count(1)
	from XX_IMAPS_INT_STATUS
	where
	interface_name='CERIS_R22'
	and 
	STATUS_CODE not in ('COMPLETED', 'RESET')


	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @count <> 1 GOTO ERROR

PRINT 'getting STATUS_RECORD_NUM'

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 100 : XX_R22_CERIS_LOAD_STEP3_SP.sql '  --CR9296
 
	select @current_STATUS_RECORD_NUM = STATUS_RECORD_NUM
	from XX_IMAPS_INT_STATUS
	where
	interface_name='CERIS_R22'
	and 
	STATUS_CODE not in ('COMPLETED', 'RESET')


	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @current_STATUS_RECORD_NUM IS NULL GOTO ERROR


PRINT 'UPDATE THE HEADER'

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 118 : XX_R22_CERIS_LOAD_STEP3_SP.sql '  --CR9296
 
UPDATE XX_R22_CERIS_DATA_HDR_STG SET STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM;

	--2
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY JAVA'
	SET @ERROR_MSG_PLACEHOLDER2 = 'EXECUTION'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2


PRINT 'COUNT R22_CERIS_FILE_STG1'

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 132 : XX_R22_CERIS_LOAD_STEP3_SP.sql '  --CR9296
 
	SELECT @count = COUNT(1)
	FROM XX_R22_CERIS_FILE_STG1

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @count <= 1 GOTO ERROR

/*
	check header - DIV16 ONLY

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 145 : XX_R22_CERIS_LOAD_STEP3_SP.sql '  --CR9296
 
	SELECT @count = COUNT(1)
	FROM XX_R22_CERIS_lcdb_empl_assignments_stg


	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @count <= 1 GOTO ERROR

*/


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'VERIFY'
	SET @ERROR_MSG_PLACEHOLDER2 = 'NO DUPES'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

PRINT 'COUNTING DUPLICATES IN XX_R22_CERIS_FILE_STG1'


 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 166 : XX_R22_CERIS_LOAD_STEP3_SP.sql '  --CR9296
 
	select R_EMPL_ID, count(1)
	from XX_R22_CERIS_FILE_STG1
	group by R_EMPL_ID
	having count(1) >1

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 174 : XX_R22_CERIS_LOAD_STEP3_SP.sql '  --CR9296
 
	SELECT @count = @@ROWCOUNT

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @count <> 0 GOTO ERROR



/*
	PERFORM CHECK ON HEADER VALUES
	
	-NO STRICT CHECK ON SEQUENCE NO
	-STRICT CHECKS ON RECORD COUNT ; NO HASH TO CHECK

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 191 : XX_R22_CERIS_LOAD_STEP3_SP.sql '  --CR9296
 
	select * from XX_R22_CERIS_data_hdr_stg

*/

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'OBTAIN CONTROL DATA'
	SET @ERROR_MSG_PLACEHOLDER2 = 'FROM HEADER'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2


PRINT 'CHECKING SEQUENCE AND RECORD COUNT'

	declare @seq_out int,
			@recs_out int,
			@table_recs_out int,
			@recs_missing int,
			@hash int,
			@expected_seq_out int,
			@expected_recs_out int,
			@expected_recs_missing int, -- CR9295
			@expected_hash int

  -- hash holds the number of stem records not loaded
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 216 : XX_R22_CERIS_LOAD_STEP3_SP.sql '  --CR9296
 
	select @seq_out		= cast(SEQ_OUT as int),
		@recs_out	= cast(RECS_OUT as int),
	 	@hash		= cast(HASH as int)
	FROM XX_R22_CERIS_DATA_HDR_STG

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'OBTAIN EXPECTED CONTROL'
	SET @ERROR_MSG_PLACEHOLDER2 = 'DATA FROM DATA'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2


PRINT 'CHECKING SEQUENCE'

	set @expected_seq_out=0
	select @expected_seq_out = cast(seq_out as int)+1
	from XX_R22_CERIS_DATA_HDR_STG_ARCH
	where status_record_num=(select max(status_record_num) from XX_R22_CERIS_DATA_HDR_STG_ARCH)

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


PRINT 'CHECKING RECORD COUNT'

	set @expected_recs_out=0
	set @expected_recs_out = (select cast(count(1) as varchar) from XX_R22_CERIS_FILE_STG1)
         -- start CR 9296
        set @table_recs_out= @expected_recs_out


        set @expected_recs_missing=0
        set @expected_recs_missing = (select cast(count(1) as varchar) from xx_r22_ceris_data_stg_missing where CREATED_BY = 'MISSING')

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
	


PRINT 'SOFT SEQUENCE COUNT'

	if @seq_out <> @expected_seq_out
	begin
		--sequence check is soft by default, unless this hard sequence check parameter is created with a value of yes
		declare @hard_seq_check sysname

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 284 : XX_R22_CERIS_LOAD_STEP3_SP.sql '  --CR9296
 
		select @hard_seq_check=parameter_value
		from xx_processing_parameters
		where interface_name_cd='CERIS_R22'
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
	    DELETE FROM imapsstg.DBO.XX_R22_CERIS_DATA_STG_missing WHERE CREATED_BY = 'MISSING'   --CR9295
		GOTO ERROR
	end
	
	--3
	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'UPDATE XX_IMAPS_INT_STATUS'
	SET @ERROR_MSG_PLACEHOLDER2 = 'WITH CONTROL TOTALS'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

	--TODO, do header checks!


PRINT 'UPDATE THE STATUS'

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 333 : XX_R22_CERIS_LOAD_STEP3_SP.sql '  --CR9296
 
	UPDATE XX_IMAPS_INT_STATUS
	SET 
	MODIFIED_BY = suser_name(),
	MODIFIED_DATE = current_timestamp,
	RECORD_COUNT_INITIAL = (SELECT count(1) FROM XX_R22_CERIS_FILE_STG1),
	RECORD_COUNT_SUCCESS = (SELECT count(1) FROM XX_R22_CERIS_FILE_STG1),
	RECORD_COUNT_ERROR=0,
	AMOUNT_INPUT= (SELECT count(1) FROM XX_R22_CERIS_FILE_STG1),
	AMOUNT_PROCESSED= (SELECT count(1) FROM XX_R22_CERIS_FILE_STG1),
	AMOUNT_FAILED=0
	WHERE 
	STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR


	/* not needed

	SET @IMAPS_ERROR_NUMBER = 204 -- ATTEMPT TO %1 %2 FAILED.
	SET @ERROR_MSG_PLACEHOLDER1 = 'INSERT'
	SET @ERROR_MSG_PLACEHOLDER2 = 'XX_IMAPS_INT_CONTROL'
	PRINT convert(varchar, current_timestamp, 21) + ' ' + @ERROR_MSG_PLACEHOLDER1+' '+@ERROR_MSG_PLACEHOLDER2

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 360 : XX_R22_CERIS_LOAD_STEP3_SP.sql '  --CR9296
 
      EXEC @ret_code = dbo.XX_INSERT_INT_CONTROL_RECORD
         @in_int_ctrl_pt_num     = 2,
         @in_lookup_domain_const = 'LD_CERIS_R_INTERFACE_CTRL_PT',
         @in_STATUS_RECORD_NUM   = @current_STATUS_RECORD_NUM

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR

	IF @ret_code <> 0 GOTO ERROR

 	*/


PRINT ' '
PRINT '****** UPDATING STATUS RECORD NUMBER ' + CAST(@current_STATUS_RECORD_NUM AS VARCHAR) + ' TO COMPLETED ******'
PRINT ' '

 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 379 : XX_R22_CERIS_LOAD_STEP3_SP.sql '  --CR9296
 
	EXEC @ret_code = dbo.XX_UPDATE_INT_STATUS_RECORD
	   @in_STATUS_RECORD_NUM = @current_STATUS_RECORD_NUM,
	   @in_STATUS_CODE       = 'CSV LOAD VALIDATED',
	   @in_STATUS_DESCRIPTION = 'Data and Header Counts match'

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @ret_code <> 0 GOTO ERROR

	
/* no need to send mail yet

	-- Create e-mail data to be used by the PORT application to send e-mail to interface stakeholders
 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ WORKDAY : Line 395 : XX_R22_CERIS_LOAD_STEP3_SP.sql '  --CR9296
 
	EXEC @ret_code = dbo.XX_SEND_STATUS_MAIL_SP
	   @in_StatusRecordNum = @current_STATUS_RECORD_NUM

	SELECT @SQLSERVER_ERROR_CODE = @@ERROR	
	IF @SQLSERVER_ERROR_CODE <> 0 GOTO ERROR
	IF @ret_code <> 0 GOTO ERROR
*/	



PRINT '' --CR9296 *~^
PRINT '*~^*************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF  XX_R22_CERIS_LOAD_STEP3_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '' --CR9296 *~^
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




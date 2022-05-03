USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_GET_LOOKUP_DATA]    Script Date: 2/4/2021 3:20:35 PM ******/
DROP PROCEDURE [dbo].[XX_GET_LOOKUP_DATA]
GO

/****** Object:  StoredProcedure [dbo].[XX_GET_LOOKUP_DATA]    Script Date: 2/4/2021 3:20:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[XX_GET_LOOKUP_DATA]
(
@usr_domain_const	char(30)    = NULL,
@usr_app_code      	varchar(20) = NULL,
@usr_lookup_id	   	integer     = NULL,
@usr_presentation_order	smallint    = NULL,
@sys_lookup_id	   	integer     = NULL OUTPUT,
@sys_app_code      	varchar(20) = NULL OUTPUT,
@sys_lookup_desc   	varchar(60) = NULL OUTPUT
)
AS

/************************************************************************************************
Name:       XX_GET_LOOKUP_DATA
Author:     HVT
Created:    06/03/2005
Purpose:    Given multiple combinations of user input arguments, retrieve system lookup ID and
            its corresponding application code, and description
Parameters: Lookup application code, code ID
Result Set: None
Notes:      Examples of call:
              EXEC dbo.XX_GET_LOOKUP_DATA 'LD_ETIME_INTERFACE_CTRL_PT', NULL, NULL, 2, NULL
                 @usr_domain_const       = 'LD_ETIME_INTERFACE_CTRL_PT',
                 @usr_presentation_order = 2,
                 @sys_app_code           = @lv_app_code OUTPUT

              EXEC dbo.XX_GET_LOOKUP_DATA NULL, 'ETIME002', NULL, NULL
                 @usr_app_code    = 'ETIME002',
                 @sys_lookup_id   = @lv_lookup_id OUTPUT,
                 @sys_lookup_desc = @lv_lookup_desc OUTPUT

              SET @lv_lookup_id = 7
              EXEC dbo.XX_GET_LOOKUP_DATA NULL, NULL, 7, NULL
                 @sys_lookup_id   = @lv_lookup_id,
                 @sys_lookup_desc = @lv_lookup_desc OUTPUT

              EXEC @lv_retval = dbo.XX_GET_LOOKUP_DATA
                 @usr_domain_const = @lv_ref_data_type,
                 @usr_app_code     = @lv_ref_value

              IF @lv_retval = 1
                 PRINT 'Lookup value is not valid.'
              ELSE
                 PRINT 'Lookup value is valid.'
************************************************************************************************/

DECLARE @lv_error_msg     varchar(255),
        @lv_row_count     integer,
        @lookup_domain_id integer,
        @lookup_id        integer,
        @lookup_desc      varchar(60),
        @SP_NAME          sysname,
		@comment_level	  varchar(10)

-- set local constants
SET @SP_NAME = 'XX_GET_LOOKUP_DATA'
PRINT '******************** ' + @SP_NAME +  '******************** '

SELECT @comment_level = PARAMETER_VALUE FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS 
WHERE INTERFACE_NAME_CD = 'UTIL' AND PARAMETER_NAME = 'COMMENT_LEVEL'


IF @comment_level = 'VERBOSE'
   BEGIN
	PRINT 'INPUTS 1 - 4. Missing numbers mean inputs are null:'
	PRINT '1. @usr_domain_const = ' + @usr_domain_const
	PRINT '2. @usr_app_code = ' + @usr_app_code  
	PRINT '3. @usr_lookup_id = ' + cast(@usr_lookup_id as varchar(10))
	PRINT '4. @usr_presentation_order = ' + cast(@usr_presentation_order as varchar(10))
   END

IF (@usr_app_code IS NULL AND @usr_lookup_id IS NULL) AND (@usr_domain_const IS NULL or @usr_presentation_order IS NULL)
   BEGIN
-- Commented by JG on 09/01/05
/*
      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = 104,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
*/
      PRINT 'One of these must exist: @usr_app_code, @usr_lookup_id. Values are: ' + @usr_app_code + ' and ' + @usr_lookup_id + ', respectively.'
	  PRINT 'AND'
	  PRINT 'Both of these must exist: @usr_domain_const, @usr_presentation_order. Values are: ' + @usr_domain_const + ' and ' + @usr_presentation_order + ', respectively.'
      RETURN (1)
   END

-- verify that XX_LOOKUP_DOMAIN.DOMAIN_CONSTANT isn't bogus
IF @usr_domain_const IS NOT NULL
   BEGIN
   
   IF @comment_level = 'VERBOSE'
	BEGIN
	   PRINT 'THIS STATEMENT SHOULD ALWAYS EXECUTE'
    END

      select @lookup_domain_id = LOOKUP_DOMAIN_ID
        from dbo.XX_LOOKUP_DOMAIN NOHOLDLOCK
       where DOMAIN_CONSTANT = @usr_domain_const

      SET @lv_row_count = @@ROWCOUNT

      IF @lv_row_count = 0
         BEGIN
-- Commented by JG on 09/01/05
/*
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code          = 105,
               @in_display_requested   = 1,
               @in_calling_object_name = @SP_NAME
*/
            PRINT 'The supplied input value @lookup_domain_id (value: '
			PRINT CAST(@lookup_domain_id AS VARCHAR(10)) 
			PRINT ') for XX_LOOKUP_DETAIL.DOMAIN_CONSTANT is invalid or does not exist.' 
			PRINT ' [' + @SP_NAME + ']'
            RETURN (1)
         END
   END

IF @usr_domain_const IS NOT NULL AND @usr_presentation_order IS NOT NULL
   BEGIN
      IF @lookup_domain_id IS NOT NULL
         select @sys_lookup_id   = LOOKUP_ID,
                @sys_app_code    = APPLICATION_CODE,
                @sys_lookup_desc = LOOKUP_DESCRIPTION
           from dbo.XX_LOOKUP_DETAIL NOHOLDLOCK
          where LOOKUP_DOMAIN_ID = @lookup_domain_id
            and PRESENTATION_ORDER = @usr_presentation_order

      SET @lv_row_count = @@ROWCOUNT


	IF @lv_row_count = 0
         BEGIN
-- Commented by JG on 09/01/05
/*
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code          = 106,
               @in_display_requested   = 1,
               @in_calling_object_name = @SP_NAME
*/
            PRINT 'The supplied input values @lookup_domain_id (value: '
			PRINT @lookup_domain_id
			PRINT ') AND @usr_presentation_order (value: '
			PRINT @usr_presentation_order 
			PRINT ') for XX_LOOKUP_DETAIL.PRESENTATION_ORDER are invalid or do not exist.' 
			PRINT 'SHOULD SEE THREE RESULTS HERE'
			PRINT '1. @sys_lookup_id = ' + CAST(@sys_lookup_id AS VARCHAR(10))
			PRINT '2. @sys_app_code = ' + @sys_app_code
			PRINT '3. @sys_lookup_desc = ' + @sys_lookup_desc
			PRINT 'and @lv_row_count (value: ' + @lv_row_count + ' ) should be > 0'

			PRINT 'SUPPLIED BY [' + @SP_NAME + ']'
            RETURN (1)
         END
   END

ELSE IF @usr_app_code IS NOT NULL  -- only XX_LOOKUP_DETAIL.APPLICATION_CODE is supplied as input

   BEGIN
      select @sys_lookup_id   = LOOKUP_ID,
             @sys_app_code    = APPLICATION_CODE,
             @sys_lookup_desc = LOOKUP_DESCRIPTION
        from dbo.XX_LOOKUP_DETAIL NOHOLDLOCK
       where APPLICATION_CODE = @usr_app_code

      SET @lv_row_count = @@ROWCOUNT


      IF @lv_row_count = 0
         BEGIN
-- Commented by JG on 09/01/05
/*
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code          = 107,
               @in_display_requested   = 1,
               @in_calling_object_name = @SP_NAME
*/
            PRINT 'The supplied input value @usr_appcode (value: '  
			PRINT @usr_app_code 
			PRINT ') for XX_LOOKUP_DETAIL.APPLICATION_CODE is invalid or does not exist.'
			PRINT 'SHOULD SEE THREE RESULTS HERE'
			PRINT '1. @sys_lookup_id = ' + CAST(@sys_lookup_id AS VARCHAR(10))
			PRINT '2. @sys_app_code = ' + @sys_app_code
			PRINT '3. @sys_lookup_desc = ' + @sys_lookup_desc
			PRINT 'and @lv_row_count (value: ' + @lv_row_count + ' ) should be > 0'

			PRINT 'SUPPLIED BY [' + @SP_NAME + ']'
            RETURN (1)
         END
   END

ELSE IF @usr_lookup_id IS NOT NULL -- hardcore case: user supplies only a value for XX_LOOKUP_DETAIL.LOOKUP_ID as input

   BEGIN
      select @sys_lookup_id   = LOOKUP_ID,
             @sys_app_code    = APPLICATION_CODE,
             @sys_lookup_desc = LOOKUP_DESCRIPTION
        from dbo.XX_LOOKUP_DETAIL NOHOLDLOCK
       where LOOKUP_ID = @usr_lookup_id

      SET @lv_row_count = @@ROWCOUNT

      IF @lv_row_count = 0
         BEGIN
-- Commented by JG on 09/01/05
/*
            EXEC dbo.XX_ERROR_MSG_DETAIL
               @in_error_code          = 108,
               @in_display_requested   = 1,
               @in_calling_object_name = @SP_NAME
*/
            PRINT 'The supplied input value @usr_lookup_id (value: ' 
			PRINT @usr_lookup_id
			PRINT ') for XX_LOOKUP_DETAIL.LOOKUP_ID is invalid or does not exist.' 
			PRINT 'SHOULD SEE THREE RESULTS HERE'
			PRINT '1. @sys_lookup_id = ' + CAST(@sys_lookup_id AS VARCHAR(10))
			PRINT '2. @sys_app_code = ' + @sys_app_code
			PRINT '3. @sys_lookup_desc = ' + @sys_lookup_desc
			PRINT 'and @lv_row_count (value: ' + @lv_row_count + ' ) should be > 0'

			PRINT 'SUPPLIED BY [' + @SP_NAME + ']'
            RETURN (1)
         END
   END

   
IF @comment_level = 'VERBOSE'
   BEGIN
	PRINT 'OUTPUTS 1 - 3. Missing numbers mean outputs are null:'
	PRINT '1. @sys_lookup_id = ' + CAST(@sys_lookup_id AS VARCHAR(10))
	PRINT '2. @sys_app_code = ' + @sys_app_code
	PRINT '3. @sys_lookup_desc = ' + @sys_lookup_desc
END

PRINT '***************** END ' + @SP_NAME +  '******************** '

RETURN (0)

GO



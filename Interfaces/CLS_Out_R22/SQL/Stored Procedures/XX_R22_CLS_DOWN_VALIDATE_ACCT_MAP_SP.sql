USE [IMAPSStg]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CLS_DOWN_VALIDATE_ACCT_MAP_SP]    Script Date: 5/6/2020 5:05:43 PM ******/
DROP PROCEDURE [dbo].[XX_R22_CLS_DOWN_VALIDATE_ACCT_MAP_SP]
GO

/****** Object:  StoredProcedure [dbo].[XX_R22_CLS_DOWN_VALIDATE_ACCT_MAP_SP]    Script Date: 5/6/2020 5:05:43 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[XX_R22_CLS_DOWN_VALIDATE_ACCT_MAP_SP] AS

/**************************************************************************************************** 
Name:       XX_R22_CLS_DOWN_VALIDATE_ACCT_MAP_SP
Created by: HVT
Created:    10/27/2008  
Purpose:    Check the newly created or refreshed mapping table for for account overlap errors such
            that IMAPS account ID ranges should not cross and have the same multiplier; if some 
            settings could lead to double counting dollars from GL table, warnings will be printed
            into the log.

            This stored procedure is called from DTS package XX_R22 CLS_DOWN_MAPPING_UPDATE.
            However, it may be run alone to validate existing mapping.

            Adapted from XX_CLS_DOWN_VALIDATE_ACCT_MAP_SP.

Notes:

CP600000465 10/27/2008 Reference BP&S Service Request CR1656
            Leverage the existing CLS Down interface for Division 16 to develop an interface
            between Costpoint and CLS to meet Division 22 (aka Research) requirements.

*****************************************************************************************************/  

BEGIN

DECLARE @ret_code               integer,
        @message_param_1        varchar(300),
        @message_param_2        varchar(300),
        @SP_NAME                varchar(50),
        @acct_start             varchar(10), 
        @acct_end               varchar(10), 
        @cls_major              varchar(3), 
        @cls_minor              varchar(4), 
        @cls_sub_minor          varchar(4),
        @first_duplicate_row    integer,
        @second_duplicate_row   integer

SET @SP_NAME = 'XX_R22_CLS_DOWN_VALIDATE_ACCT_MAP_SP'
SET @ret_code = 0

PRINT '***********************************************************************************************************************'
PRINT '     START OF ' + @SP_NAME
PRINT '***********************************************************************************************************************'

/* IMAPS ranges should not cross and have the same multiplier */

DECLARE ACCT_OVERLAP CURSOR FOR
   SELECT a.IMAPS_ACCT_START, a.IMAPS_ACCT_END, a.CLS_MAJOR, a.CLS_MINOR, a.CLS_SUB_MINOR, a.ROW_NUM, b.ROW_NUM
     FROM dbo.XX_R22_CLS_DOWN_ACCT_MAPPING a,
          dbo.XX_R22_CLS_DOWN_ACCT_MAPPING b
    WHERE ((a.IMAPS_ACCT_START <= b.IMAPS_ACCT_END AND a.IMAPS_ACCT_START >= b.IMAPS_ACCT_START) OR 
           (a.IMAPS_ACCT_END >= b.IMAPS_ACCT_START AND a.IMAPS_ACCT_END <= b.IMAPS_ACCT_END)
          )
      AND a.ROW_NUM <> b.ROW_NUM
      AND a.MULTIPLIER = b.MULTIPLIER 

OPEN ACCT_OVERLAP
FETCH NEXT FROM ACCT_OVERLAP INTO @acct_start, @acct_end, @cls_major, @cls_minor, @cls_sub_minor, @first_duplicate_row, @second_duplicate_row

IF @acct_start is NOT NULL
   BEGIN 
      SET @ret_code = 552 -- "In %1 table %2. This could result in misrepresentation of IMAPS GL data"
      SET @message_param_1 = 'XX_R22_CLS_DOWN_ACCT_MAPPING'
      SET @message_param_2 = 'IMAPS account ranges are crossing each other'

      EXEC dbo.XX_ERROR_MSG_DETAIL
         @in_error_code          = @ret_code,
         @in_placeholder_value1  = @message_param_1,
         @in_placeholder_value2  = @message_param_2,
         @in_display_requested   = 1,
         @in_calling_object_name = @SP_NAME
   END

WHILE @@FETCH_STATUS = 0
   BEGIN
      PRINT @acct_start + ' ' +  @acct_end + ' ' + @cls_major + ' ' + @cls_minor + ' ' + @cls_sub_minor +
            ' row ' + CAST(@first_duplicate_row AS char(5)) + ' overlap ' + CAST(@second_duplicate_row AS CHAR(5))

      FETCH NEXT FROM ACCT_OVERLAP INTO @acct_start, @acct_end, @cls_major, @cls_minor, @cls_sub_minor, @first_duplicate_row, @second_duplicate_row

      SET @acct_start = NULL
   END

CLOSE ACCT_OVERLAP
DEALLOCATE ACCT_OVERLAP

PRINT '***********************************************************************************************************************'
PRINT '     END OF ' + @SP_NAME
PRINT '***********************************************************************************************************************'

END

GO



USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_CLS_DOWN_VALIDATE_ACCT_MAP_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 

 




CREATE PROCEDURE [dbo].[XX_CLS_DOWN_VALIDATE_ACCT_MAP_SP]  AS
BEGIN
/************************************************************************************************  
Name:       	XX_CLS_DOWN_VALIDATE_ACCT_MAP_SP
Author:     	Tatiana Perova
Created:    	11/2005  
Purpose:    	Service procedure for CLS Down interface, shows places in account mapping that 
		contradict logic of the process.

Prerequisites: 	none 
 

Version: 	1.0

************************************************************************************************/  
Declare 
@ret_code int,
@NumberOfRecords int,
@message_param_1 varchar(300),
@message_param_2 varchar(300),
@SP_NAME  varchar(30),
@out_SystemError int, 
@out_STATUS_DESCRIPTION varchar(275),
@acct_start varchar(10), 
@acct_end varchar(10), 
@cls_major varchar(3), 
@cls_minor varchar(4), 
@cls_sub_minor varchar(4),
@service_offering varchar(3),
@first_duplicate_row int,
@second_duplicate_row int,
@row_num int


SET @ret_code = 0
SET @SP_NAME = 'XX_CLS_DOWN_VALIDATE_ACCT_MAP_SP'

DECLARE ACCT_OVERLAP CURSOR FOR
/* IMAPS ranges should not cross and have the same multiplier and service*/
SELECT a.[IMAPS_ACCT_START], a.[IMAPS_ACCT_END], 
a.[CLS_MAJOR], a.[CLS_MINOR], 
a.[CLS_SUB_MINOR], a.[ROW_NUM],
b.[ROW_NUM]
 FROM [dbo].[XX_CLS_DOWN_ACCT_MAPPING ]a,
[IMAPSStg].[dbo].[XX_CLS_DOWN_ACCT_MAPPING]b
WHERE
(a.IMAPS_ACCT_START <= b.IMAPS_ACCT_END AND
a.IMAPS_ACCT_START >= b.IMAPS_ACCT_START OR 
a.IMAPS_ACCT_END >= b.IMAPS_ACCT_START AND
a.IMAPS_ACCT_END <= b.IMAPS_ACCT_END) AND 
a.ROW_NUM <> b.ROW_NUM AND
a.MULTIPLIER = b.MULTIPLIER 

OPEN ACCT_OVERLAP
FETCH NEXT FROM ACCT_OVERLAP INTO @acct_start , @acct_end, @cls_major, @cls_minor, @cls_sub_minor, @first_duplicate_row,@second_duplicate_row
IF @acct_start is NOT NULL
BEGIN 
	--In %1  table %2. This will result in misrepresentation of IMAPS GL data
             SET @ret_code =552
	SET @message_param_2 = ' IMAPS account  ranges are crossing each other'
	SET @message_param_1 = ' XX_CLS_DOWN_ACCT_MAPPING'
	         EXEC dbo.XX_ERROR_MSG_DETAIL
            @in_error_code          = @ret_code,
            @in_placeholder_value1 = @message_param_1,
            @in_placeholder_value2 = @message_param_2,
            @in_display_requested   = 1,
            @in_calling_object_name = @SP_NAME,
            @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT

END

WHILE @@FETCH_STATUS = 0
BEGIN
  PRINT @acct_start + ' ' +  @acct_end + ' ' + @cls_major + ' ' +  @cls_minor + ' ' + @cls_sub_minor+
	 ' row '+  CAST(@first_duplicate_row AS char(5))+' overlap ' + CAST(@second_duplicate_row AS CHAR(5))
  FETCH NEXT FROM ACCT_OVERLAP INTO @acct_start , @acct_end, @cls_major, @cls_minor, @cls_sub_minor,  @first_duplicate_row,@second_duplicate_row
 SET @acct_start = NULL
END

CLOSE ACCT_OVERLAP
DEALLOCATE ACCT_OVERLAP

DECLARE ACCT_OVERLAP_SERV CURSOR FOR
SELECT a.[IMAPS_ACCT_START], a.[IMAPS_ACCT_END], 
a.[CLS_MAJOR], a.[CLS_MINOR], 
a.[CLS_SUB_MINOR], a.[SERVICE_OFFERING],
 a.[ROW_NUM],b.[ROW_NUM]
 FROM [dbo].[XX_CLS_DOWN_ACCT_SERV_MAPPING ]a,
[IMAPSStg].[dbo].[XX_CLS_DOWN_ACCT_SERV_MAPPING]b
WHERE
(a.IMAPS_ACCT_START <= b.IMAPS_ACCT_END AND
a.IMAPS_ACCT_START >= b.IMAPS_ACCT_START OR 
a.IMAPS_ACCT_END >= b.IMAPS_ACCT_START AND
a.IMAPS_ACCT_END <= b.IMAPS_ACCT_END) AND 
a.ROW_NUM <> b.ROW_NUM AND
a.SERVICE_OFFERING =  b.SERVICE_OFFERING AND
a.MULTIPLIER = b.MULTIPLIER 

OPEN ACCT_OVERLAP_SERV
FETCH NEXT FROM ACCT_OVERLAP_SERV  INTO @acct_start , @acct_end, @service_offering,  @cls_major, @cls_minor, @cls_sub_minor, @first_duplicate_row,@second_duplicate_row
IF @acct_start is NOT NULL
BEGIN 
	--In %1  table %2. This will result in misrepresentation of IMAPS GL data
	SET @ret_code =552
	SET @message_param_2 = ' IMAPS account  ranges are crossing each other'
	SET @message_param_1 = ' XX_CLS_DOWN_ACCT_SERV_MAPPING'
	         EXEC dbo.XX_ERROR_MSG_DETAIL
            @in_error_code          = @ret_code,
            @in_placeholder_value1 = @message_param_1,
            @in_placeholder_value2 = @message_param_2,
            @in_display_requested   = 1,
            @in_calling_object_name = @SP_NAME,
            @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT

END

WHILE @@FETCH_STATUS = 0
BEGIN
  PRINT @acct_start + ' ' +  @acct_end + ' ' + @service_offering + ' '+ @cls_major + ' ' +  @cls_minor + ' ' + @cls_sub_minor + 
	' row '+  CAST(@first_duplicate_row AS char(5))+' overlap ' + CAST(@second_duplicate_row AS CHAR(5))
  FETCH NEXT FROM ACCT_OVERLAP_SERV  INTO @acct_start , @acct_end,  @service_offering, @cls_major, @cls_minor, @cls_sub_minor , @first_duplicate_row,@second_duplicate_row
 SET @acct_start = NULL
END

CLOSE ACCT_OVERLAP_SERV
DEALLOCATE ACCT_OVERLAP_SERV



/*Validation for FDS reverse We will be grouping FDS reverse by MACHINE_TYPE, .PRODUCT_ID, SERVICE_OFFERED
We need to make sure that each group has only one CLS account to be sent to*/
SELECT 1
FROM (SELECT   b.MACHINE_TYPE, b.PRODUCT_ID,  Count(*) as OCCURRENCE 
FROM  [dbo].[XX_CLS_DOWN_ACCT_MAPPING ] b
WHERE b.REVERSE_FDS = 1 
GROUP BY    b.MACHINE_TYPE, b.PRODUCT_ID) y
WHERE OCCURRENCE > 1

SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT
IF @NumberOfRecords > 0  
BEGIN 
	--In %1  table %2. This will result in misrepresentation of IMAPS GL data
	SET @ret_code =552
	SET @message_param_2 = ' there are multiple accounts to submit FDS reversal'
	SET @message_param_1 = ' XX_CLS_DOWN_ACCT_MAPPING'
	         EXEC dbo.XX_ERROR_MSG_DETAIL
            @in_error_code          = @ret_code,
            @in_placeholder_value1 = @message_param_1,
            @in_placeholder_value2 = @message_param_2,
            @in_display_requested   = 1,
            @in_calling_object_name = @SP_NAME,
            @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT

END

SELECT 1
FROM (SELECT   b.MACHINE_TYPE, b.PRODUCT_ID,  b.SERVICE_OFFERING, Count(*) as OCCURRENCE 
FROM  [dbo].[XX_CLS_DOWN_ACCT_SERV_MAPPING ] b
WHERE b.REVERSE_FDS = 1 
GROUP BY    b.MACHINE_TYPE, b.PRODUCT_ID, b.SERVICE_OFFERING) y
WHERE OCCURRENCE > 1

SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT
IF @NumberOfRecords > 0  
BEGIN 
	--In %1 table %2. This will result in misrepresentation of IMAPS GL data
	SET @ret_code =552
	SET @message_param_2 = ' there are multiple accounts to submit FDS reversal'
	SET @message_param_1 = ' XX_CLS_DOWN_ACCT_SERV_MAPPING'
	         EXEC dbo.XX_ERROR_MSG_DETAIL
            @in_error_code          = @ret_code,
            @in_placeholder_value1 = @message_param_1,
            @in_placeholder_value2 = @message_param_2,
            @in_display_requested   = 1,
            @in_calling_object_name = @SP_NAME,
            @out_msg_text           = @out_STATUS_DESCRIPTION OUTPUT

END

DECLARE EMPTY_STUB CURSOR FOR
Select a.ROW_NUM, a.IMAPS_ACCT_START, a.IMAPS_ACCT_END, a.CLS_MAJOR, a.CLS_MINOR,a.CLS_SUB_MINOR
from XX_CLS_DOWN_ACCT_MAPPING a left join XX_CLS_DOWN_ACCT_SERV_MAPPING b
ON a.IMAPS_ACCT_START = b.IMAPS_ACCT_START and a.IMAPS_ACCT_START = b.IMAPS_ACCT_START 
WHERE a.STUB = 'Y' and b.ROW_NUM is NULL

SET @acct_start = NULL

OPEN EMPTY_STUB
FETCH NEXT FROM EMPTY_STUB  INTO @row_num, @acct_start , @acct_end,   @cls_major, @cls_minor, @cls_sub_minor
IF @acct_start is NOT NULL
BEGIN 
	Print 'Mapping rows marked as stub in XX_CLS_DOWN_ACCT_MAPPING but have no service differentiation in XX_CLS_DOWN_ACCT_SERV_MAPPING '
END

WHILE @@FETCH_STATUS = 0
BEGIN
  PRINT  CAST( @row_num  AS VARCHAR) + '  '+@acct_start + ' ' +  @acct_end + ' ' + @service_offering + ' '+ @cls_major + ' ' +  @cls_minor + ' ' + @cls_sub_minor 
  FETCH NEXT FROM  EMPTY_STUB  INTO  @row_num, @acct_start , @acct_end,   @cls_major, @cls_minor, @cls_sub_minor
 SET @acct_start = NULL
END

CLOSE EMPTY_STUB
DEALLOCATE EMPTY_STUB


DECLARE NOT_COVERED_SERVICES CURSOR FOR
Select a.ROW_NUM, a.IMAPS_ACCT_START, a.IMAPS_ACCT_END, a.CLS_MAJOR, a.CLS_MINOR,a.CLS_SUB_MINOR
 from XX_CLS_DOWN_ACCT_SERV_MAPPING a left join XX_CLS_DOWN_ACCT_MAPPING b
ON a.IMAPS_ACCT_START = b.IMAPS_ACCT_START and a.IMAPS_ACCT_START = b.IMAPS_ACCT_START 
WHERE  b.STUB is NULL

 SET @acct_start = NULL

OPEN NOT_COVERED_SERVICES
FETCH NEXT FROM NOT_COVERED_SERVICES  INTO @row_num, @acct_start , @acct_end,   @cls_major, @cls_minor, @cls_sub_minor
IF @acct_start is NOT NULL
BEGIN 
	Print 'Mapping rows in XX_CLS_DOWN_ACCT_SERV_MAPPING do not have corresponding service in different row in  XX_CLS_DOWN_ACCT_MAPPING'
END

WHILE @@FETCH_STATUS = 0
BEGIN
  PRINT CAST( @row_num  AS VARCHAR) + '  '+@acct_start + ' ' +  @acct_end + ' ' + @service_offering + ' '+ @cls_major + ' ' +  @cls_minor + ' ' + @cls_sub_minor 
  FETCH NEXT FROM NOT_COVERED_SERVICES  INTO  @row_num, @acct_start , @acct_end,   @cls_major, @cls_minor, @cls_sub_minor
 SET @acct_start = NULL
END

CLOSE NOT_COVERED_SERVICES
DEALLOCATE NOT_COVERED_SERVICES
END



 

 

GO
 


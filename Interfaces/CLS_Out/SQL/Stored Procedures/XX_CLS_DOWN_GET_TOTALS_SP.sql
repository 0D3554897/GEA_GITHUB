USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_CLS_DOWN_GET_TOTALS_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 

 




CREATE PROCEDURE [dbo].[XX_CLS_DOWN_GET_TOTALS_SP] ( 
@in_STATUS_RECORD_NUM    integer, 
@out_SystemError int = NULL OUTPUT, 
@out_STATUS_DESCRIPTION varchar(275) =NULL OUTPUT) AS
BEGIN

/************************************************************************************************  
Name:       	XX_CLS_DOWN_GET_TOTALS_SP
Author:     	Tatiana Perova
Created:    	11/2005  
Purpose:    	creates records in the staging table that will be put into control file for
		 I999 main data file

Prerequisites: 	none 
 

Version: 	1.0

************************************************************************************************/  
DECLARE
@SP_NAME varchar(50),
@ret_code int,
@NumberOfRecords int

SET @SP_NAME = 'XX_CLS_DOWN_VALIDATE_FIN_SP'

PRINT '***********************************************************************************************************************'
PRINT @SP_NAME
PRINT '***********************************************************************************************************************'



-- validation/updates for XX_CLS_DOWN
EXEC @ret_code =  [dbo].[XX_CLS_DOWN_VALIDATE_FIN_SP] 
@in_STATUS_RECORD_NUM , 
@out_SystemError OUTPUT , @out_STATUS_DESCRIPTION OUTPUT 

PRINT 'EXECUTED XX_CLS_DOWN_VALIDATE_FIN_SP'

IF @ret_code <> 0  
BEGIN 	GOTO ErrorProcessing END 

-- set local constants
SET @SP_NAME = 'XX_CLS_DOWN_GET_TOTALS_SP'
TRUNCATE TABLE [dbo].[XX_CLS_DOWN_SUMMARY]

PRINT 'TRUNCATED XX_CLS_DOWN_SUMMARY'

PRINT '24. INSERT INTO XX_CLS_DOWN_SUMMARY'

INSERT INTO [dbo].[XX_CLS_DOWN_SUMMARY](DIVISION, [CLS_MAJOR], [CLS_MINOR], [CLS_SUB_MINOR], 
[DOLLAR_AMT],[RECORD_CNT])
SELECT DIVISION, [CLS_MAJOR], [CLS_MINOR], [CLS_SUB_MINOR], SUM([DOLLAR_AMT]),COUNT(*)
FROM dbo.XX_CLS_DOWN 
GROUP BY DIVISION, [CLS_MAJOR], [CLS_MINOR], [CLS_SUB_MINOR] 
ORDER BY DIVISION, [CLS_MAJOR], [CLS_MINOR], [CLS_SUB_MINOR] 

SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT
IF @out_SystemError <> 0  
BEGIN 	SET @ret_code = 1 GOTO ErrorProcessing END

PRINT 'INSERT SUCCESSFUL'

--update default customer number here
DECLARE @CustomerDflt varchar(30)

PRINT 'NOW GETTING VARIOUS PARAMETERS. CUSTOMER DEFAULT IS NEXT'

SELECT @CustomerDflt = PARAMETER_VALUE FROM  IMAPSstg.dbo.XX_PROCESSING_PARAMETERS 
WHERE INTERFACE_NAME_CD = 'CLS' AND PARAMETER_NAME = 'DFLT_CUSTOMER_NUM'

PRINT 'UPDATING XX_CLS_DOWN'

UPDATE XX_CLS_DOWN
SET CUSTOMER_NUM = @CustomerDflt
WHERE CUSTOMER_NUM IS NULL


SELECT @out_SystemError = @@ERROR,  @NumberOfRecords = @@ROWCOUNT
IF @out_SystemError <> 0  
BEGIN 	SET @ret_code = 1 GOTO ErrorProcessing END

PRINT 'UPDATE SUCCESSFUL'

RETURN 0

ErrorProcessing:
RETURN @ret_code

END




 

 

GO
 


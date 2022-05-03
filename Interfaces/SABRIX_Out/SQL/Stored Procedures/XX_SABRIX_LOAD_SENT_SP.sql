USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_SABRIX_LOAD_SENT_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 


CREATE PROCEDURE [dbo].[XX_SABRIX_LOAD_SENT_SP]
(
@in_STATUS_RECORD_NUM integer
)
AS
/************************************************************************************************  
Name:       	XX_SABRIX_LOAD_SENT_SP  
Author:     	GEA  
Created:    	08/2018  
Purpose:    	To insert records into the XX_SABRIX_INVOICE_SENT table

Prerequisites: 	none 

Parameters: 
	Input: 	none
	Output: none   

Version: 	1.0
Notes:      	Call example  
              	EXEC IMAPS.dbo.XX_SABRIX_AR_LOAD_SENT_SP  

************************************************************************************************/  



DECLARE @DIV_16_COMPANY_ID varchar(10),
        @SP_NAME sysname

PRINT '  *~^'
PRINT '*~^**************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        HERE IN XX_SABRIX_LOAD_SENT_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '  *~^'

SET @SP_NAME = 'XX_SABRIX_LOAD_SENT_SP'


 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 62 : XX_SABRIX_LOAD_SENT_SP.sql '  
 
SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'FDS/CCS'


 
PRINT convert(varchar, current_timestamp, 21) + ' : *~^ FDSCCS : Line 71 : XX_SABRIX_LOAD_SENT_SP.sql '  
 
INSERT INTO dbo.XX_SABRIX_INVOICE_SENT
   (CUST_ID, PROJ_ID, INVC_ID, INVC_AMT, INVC_DT, STATUS_RECORD_NUM, DIVISION)
   SELECT CUST_ID, PROJ_ID, INVC_ID, INVC_AMT, INVC_DT, STATUS_RECORD_NUM, DIVISION
     FROM dbo.XX_SABRIX_INV_OUT_SUM
    WHERE STATUS_FL = 'P'


IF @@ERROR <> 0 GOTO ERROR


DECLARE @ERROR varchar(250)
SET @ERROR = 'REVERSAL OF PREVIOUSLY SENT INVOICE - COMPARE INVC_AMT in dbo.XX_SABRIX_INVOICE_SENT to DELTEK.BILL_INVC_HDR_HS'

INSERT INTO dbo.XX_IMAPS_INV_ERROR
   (STATUS_RECORD_NUM, CUST_ID, PROJ_ID, INVC_ID, INVC_DT, ERROR_DESC)
   SELECT a.STATUS_RECORD_NUM, a.CUST_ID, a.PROJ_ID, a.INVC_ID, a.INVC_DT, @ERROR 
     FROM dbo.XX_SABRIX_INV_OUT_SUM a
          INNER JOIN
          IMAPS.DELTEK.BILL_INVC_HDR_HS b
          ON
          (a.invc_id = b.invc_id
           and a.invc_dt = b.invc_dt
           and a.invc_amt <> b.invc_amt
           and b.COMPANY_ID = @DIV_16_COMPANY_ID
          )
          AND a.INVC_ID NOT IN (SELECT INVC_ID FROM dbo.XX_IMAPS_INV_ERROR)


IF @@ERROR <> 0 GOTO ERROR

-- NO LOADING INTO FDS REVERSE TABLE FOR CLSDOWN - WE LET FDS/CCS DO THAT


PRINT '  *~^'
PRINT '*~^*************************************************************************************************************'
PRINT '*~^                                                                                                             *'
PRINT '*~^                        END OF  XX_SABRIX_LOAD_SENT_SP.sql'
PRINT '*~^                                                                                                             *'
PRINT '*~^**************************************************************************************************************'
PRINT '  *~^'
RETURN(0)


ERROR:

RETURN(1)

 

 

 

 

 

 

 

GO
 


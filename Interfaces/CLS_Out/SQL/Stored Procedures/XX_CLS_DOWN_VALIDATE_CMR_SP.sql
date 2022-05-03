USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_CLS_DOWN_VALIDATE_CMR_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 

 




CREATE PROCEDURE [dbo].[XX_CLS_DOWN_VALIDATE_CMR_SP] ( 
@in_STATUS_RECORD_NUM    integer, 
@out_SystemError int = NULL OUTPUT, 
@out_STATUS_DESCRIPTION varchar(275) =NULL OUTPUT) AS

BEGIN

/************************************************************************************************  
Name:       	XX_CLS_DOWN_VALIDATE_CMR_SP
Author:     	KM
Created:    	11/2007 
Purpose:    	no longer needed, since ytd logic change
Prerequisites: 	none 
 

Version: 	1.0

************************************************************************************************/  
PRINT 'XX_CLS_DOWN_VALIDATE_CMR_SP IS NO LONGER NEEDED BUT EXECUTES THIS MESSAGE SUCCESSFULLY'
RETURN 0


END



 

 

GO
 


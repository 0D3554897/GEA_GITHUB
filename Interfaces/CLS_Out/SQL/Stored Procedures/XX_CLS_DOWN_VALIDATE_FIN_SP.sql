USE IMAPSSTG
DROP PROCEDURE [dbo].[XX_CLS_DOWN_VALIDATE_FIN_SP]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 

 




CREATE PROCEDURE [dbo].[XX_CLS_DOWN_VALIDATE_FIN_SP] ( 
@in_STATUS_RECORD_NUM    integer, 
@out_SystemError int = NULL OUTPUT, 
@out_STATUS_DESCRIPTION varchar(275) =NULL OUTPUT) AS
BEGIN

/************************************************************************************************  
Name:       	XX_CLS_DOWN_VALIDATE_FIN_SP
Author:     	KM
Created:    	10/2007  
Purpose:    	no longer needed, since YTD logic change
Prerequisites: 	none 
Version: 	1.0

************************************************************************************************/  

	-- update status record (amounts are not updated since it should be always 0)
	UPDATE dbo.XX_IMAPS_INT_STATUS
	SET RECORD_COUNT_SUCCESS = (SELECT count(*) FROM dbo.XX_CLS_DOWN)
	WHERE STATUS_RECORD_NUM = @in_STATUS_RECORD_NUM

	RETURN 0

END




 

 

GO
 


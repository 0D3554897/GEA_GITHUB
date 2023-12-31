SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_GET_CUSTOMER_FOR_PROJECT_UF]') and xtype in (N'FN', N'IF', N'TF'))
   drop function [dbo].[XX_GET_CUSTOMER_FOR_PROJECT_UF]
GO

CREATE FUNCTION [dbo].[XX_GET_CUSTOMER_FOR_PROJECT_UF](@in_proj_id varchar(30))  
RETURNS varchar(15) AS  

BEGIN

/************************************************************************************************  
Name:       	XX_GET_CUSTOMER_FOR_PROJECT
Author:     	Tatiana Perova
Created:    	11/2005  
Purpose:    	Function was created for the use in CLS Down interface in order to find a 
                customer for the project in the contract structure.

Prerequisites: 	none 
 
Version: 	1.0

Notes:

CP600000313     05/05/2008 (BP&S Change Request No. CR1543)
                Costpoint multi-company fix (one instance).
************************************************************************************************/


DECLARE @return_address_code varchar(15),
        @DIV_16_COMPANY_ID   varchar(10)

-- CP600000313_Begin
SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'CLS'
-- CP600000313_End

WHILE LEN(@in_proj_id) >= 5 
   BEGIN	
      SELECT TOP 1 @return_address_code = ADDR_DC
        FROM IMAPS.Deltek.PROJ_CUST_SETUP
       WHERE PROJ_ID = @in_proj_id
-- CP600000313_Begin
         AND COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000313_End
	
      IF @return_address_code is NULL 
         BEGIN 
            SET @in_proj_id = LEFT(@in_proj_id, LEN(@in_proj_id) - 5) 
            CONTINUE
         END
      ELSE
         BREAK 
   END

RETURN @return_address_code

END

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


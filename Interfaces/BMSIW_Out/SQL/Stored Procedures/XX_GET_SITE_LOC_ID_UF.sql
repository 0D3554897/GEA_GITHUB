SET QUOTED_IDENTIFIER ON
go
SET ANSI_NULLS ON
go
CREATE FUNCTION [dbo].[XX_GET_SITE_LOC_ID_UF]
(
@in_EMPL_ID     varchar(30)
)  
RETURNS char(8)
AS  

BEGIN 

/************************************************************************************************  
Name:       XX_GET_SITE_LOC_ID_UF
Author:     Tejas Patel
Created:    08/30/2007 
Purpose:    This function determines the SITE_LOC_ID from BMSIW.EMF Table XX_UTIL_LOAD_STAGING_DATA_SP.
Parameters: EMPL_ID - Input
Return:     SITE_LOC_ID for XX_UTIL_LAB_OUT
Version:    1.1

Notes:      Examples of function call: Prepare column values for the XX_UTIL_LAB_OUT record

            select dbo.XX_GET_SITE_LOC_ID_UF(EMPL_ID) as SITE_LOC_ID

**************************************************************************************************/ 

DECLARE @SITE_LOC_ID           char(8)

SET @SITE_LOC_ID=NULL

SELECT @SITE_LOC_ID=SITE_LOC_ID
from BMSIW..BMSIW.EMP_MASTER_FILE_UV 
where emp_ser_num=@in_empl_id

RETURN @SITE_LOC_ID

END
go
SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go
IF OBJECT_ID('dbo.XX_GET_SITE_LOC_ID_UF') IS NOT NULL
    PRINT '<<< CREATED FUNCTION dbo.XX_GET_SITE_LOC_ID_UF >>>'
ELSE
    PRINT '<<< FAILED CREATING FUNCTION dbo.XX_GET_SITE_LOC_ID_UF >>>'
go

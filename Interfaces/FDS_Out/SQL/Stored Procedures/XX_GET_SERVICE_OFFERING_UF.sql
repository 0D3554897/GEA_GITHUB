SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  User Defined Function dbo.XX_GET_SERVICE_OFFERING_UF    Script Date: 09/19/2006 10:15:56 AM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_GET_SERVICE_OFFERING_UF]') and xtype in (N'FN', N'IF', N'TF'))
   drop function [dbo].[XX_GET_SERVICE_OFFERING_UF]
GO







CREATE FUNCTION [dbo].[XX_GET_SERVICE_OFFERING_UF] 
(@in_PROJ_ID varchar(30))
RETURNS char(3) AS

BEGIN 

/************************************************************************************************  
Name:       XX_GET_SERVICE_OFFEREING_UF
Author:     KM
Created:    11/01/2005  
Purpose:    Conversion function called by FDS Interface

Parameters: 
	
Version:    1.0
Notes:

CP600000325 04/25/2008 (BP&S Change Request No. CR1543)
            Costpoint multi-company fix (six instances).
**************************************************************************************************/ 

DECLARE @returnvalue       char(3),
        @PAG               varchar(3),
        @DIV_16_COMPANY_ID varchar(10)

-- CP600000325_Begin
SELECT @DIV_16_COMPANY_ID = PARAMETER_VALUE
  FROM dbo.XX_PROCESSING_PARAMETERS
 WHERE PARAMETER_NAME = 'COMPANY_ID'
   AND INTERFACE_NAME_CD = 'FDS/CCS'
-- CP600000325_End

SELECT @PAG = ACCT_GRP_CD
FROM	IMAPS.Deltek.PROJ
WHERE 	PROJ_ID = @in_PROJ_ID
-- CP600000325_Begin
AND	COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000325_End

-- Check for OHW & OSW
IF @PAG in ('OHW', 'OSW')
   SET @returnvalue = @PAG
-- else, check UDEF table for BTO, WEB, CSI
ELSE
   BEGIN
      -- check current level
      SELECT @returnvalue = UDEF_ID
        FROM IMAPS.Deltek.GENL_UDEF
       WHERE GENL_ID = @in_PROJ_ID
         AND S_TABLE_ID = 'PJ'
         AND UDEF_LBL_KEY = 19
-- CP600000325_Begin
         AND COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000xxx_End

      -- if needed, check each level
      IF @returnvalue IS NULL
         BEGIN
            DECLARE @PROJ_ID_L1 varchar(30),
                    @PROJ_ID_L2 varchar(30),
                    @PROJ_ID_L3 varchar(30)
		
            SELECT @PROJ_ID_L1 = L1_PROJ_SEG_ID, 
                   @PROJ_ID_L2 = L2_PROJ_SEG_ID,
                   @PROJ_ID_L3 = L3_PROJ_SEG_ID
              FROM IMAPS.Deltek.PROJ
             WHERE PROJ_ID = @in_PROJ_ID
-- CP600000325_Begin
               AND COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000325_End
            -- Service Offering for L3
            SELECT @returnvalue = UDEF_ID
              FROM IMAPS.Deltek.GENL_UDEF
             WHERE GENL_ID = (@PROJ_ID_L1 + '.' + @PROJ_ID_L2 + '.' + @PROJ_ID_L3)
               AND S_TABLE_ID = 'PJ'
               AND UDEF_LBL_KEY = 19
-- CP600000325_Begin
               AND COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000325_End

            -- Service Offering for L2 if needed
            IF @returnvalue IS NULL
               BEGIN
                  SELECT @returnvalue = UDEF_ID
                    FROM IMAPS.Deltek.GENL_UDEF
                   WHERE GENL_ID = (@PROJ_ID_L1 + '.' + @PROJ_ID_L2)
                     AND S_TABLE_ID = 'PJ'
                     AND UDEF_LBL_KEY = 19
-- CP600000325_Begin
                     AND COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000325_End
		END	

            -- Service Offeringfor L1 if needed
            IF @returnvalue IS NULL
               BEGIN
                  SELECT @returnvalue = UDEF_ID
                    FROM IMAPS.Deltek.GENL_UDEF
                   WHERE GENL_ID = @PROJ_ID_L1
                     AND S_TABLE_ID = 'PJ'
                     AND UDEF_LBL_KEY = 19
-- CP600000325_Begin
                     AND COMPANY_ID = @DIV_16_COMPANY_ID
-- CP600000325_End
               END
         END
	
         -- default value is CSI
         IF @returnvalue IS NULL
            SET @returnvalue = 'CSI'
   END

RETURN  @returnvalue

END








GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


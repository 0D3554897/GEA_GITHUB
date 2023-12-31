

use imapsstg

DECLARE @INTERFACE_NAME_ID integer

SELECT @INTERFACE_NAME_ID = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t2.APPLICATION_CODE = 'FIWLR'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@INTERFACE_NAME_ID, 'FIWLR', 'BMSIW_WWER_N16_PULL_TIMESTAMP', '2009-04-27-09.09.09.024000', SUSER_SNAME(), GETDATE())
go



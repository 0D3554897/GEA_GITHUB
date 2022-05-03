/*
 * Defect No. 610: ETE- 7 Keys - USER_ERROR  Missing interface run type ID from system lookup table.
 *
 * 03/20/2006: This script corrects a typographical error in the system lookup detail data for 7Keys/PSP interface.
 * The value of XX_LOOKUP_DOMAIN.DOMAIN_CONSTANT should be 'LD_INTERFACE_RUN_TYPE' (not 'LD_INTERFACE_RUN_TYPES').
 */

DECLARE @LOOKUP_DOMAIN_ID integer

SELECT @LOOKUP_DOMAIN_ID = LOOKUP_DOMAIN_ID
  FROM dbo.XX_LOOKUP_DOMAIN
 WHERE DOMAIN_CONSTANT like 'LD_INTERFACE_RUN_TYPE%'

UPDATE dbo.XX_LOOKUP_DOMAIN
   SET DOMAIN_CONSTANT = 'LD_INTERFACE_RUN_TYPE'
 WHERE LOOKUP_DOMAIN_ID = @LOOKUP_DOMAIN_ID
go

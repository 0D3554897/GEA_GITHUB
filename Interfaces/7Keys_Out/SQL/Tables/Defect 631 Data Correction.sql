/*
 * Defect 631 03/27/2006 - Missing 7KEYS/PSP processing parameter data
 *
 * On server FFX23DAP01, in database IMAPSStg, table XX_PROCESSING_PARAMETERS, the records for 7KEYS/PSP interface
 * have the incorrect value in column INTERFACE_NAME_ID: 24. The correct value is 76.
 *
 * The cause: In CLearCase, look at the data script 7KEYS_PSP Processing Parameters Table Population Scripts.sql:
 * the SELECT statements incorrectly used column PRESENTATION_ORDER instead of LOOKUP_ID.
 *
 * The fix:
 *
 * (1) Correct SELECT and INSERT statements in 7KEYS_PSP Processing Parameters Table Population Scripts.sql.
 * (2) The script corrects the data.
 *
 * !!IMPORTANT!!: Execution Instructions: Run this script only once for relief puposes. This script is not included
 * in 7KEYS_tbl_compilation_order.txt. Subsequently, when a new build takes place, or for all future builds, only
 * the original the data script 7KEYS_PSP Processing Parameters Table Population Scripts.sql needs to be executed.
 */

DECLARE @INTERFACE_NAME_ID integer

SELECT @INTERFACE_NAME_ID = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t2.APPLICATION_CODE = '7KEYS/PSP'

UPDATE dbo.XX_PROCESSING_PARAMETERS
   SET INTERFACE_NAME_ID = @INTERFACE_NAME_ID
 WHERE INTERFACE_NAME_CD = '7KEYS/PSP'
   AND INTERFACE_NAME_ID != @INTERFACE_NAME_ID
GO
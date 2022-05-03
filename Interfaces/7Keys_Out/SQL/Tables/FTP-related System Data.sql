-- 01/31/2006_Begin Add parameters for FTP processing

/*
 * 7KEYS/PSP interface uses 16 processing parameters. There are 2 processing parameters here in this script.
 * The other 14 processing parameters are in 7KEYS_PSP Processing Parameters Table Population Scripts.sql.
 * See IMAPS_V1_Development/IMAPS_V1/Scripts/Libraries/Data.
 *
 * IMPORTANT: (1) Make sure that the value assigned to column INTERFACE_NAME_ID is correct in the database that
 * these statements are to be executed. (2) Before these SQL commands can be executed, verify that a FTP user
 * account for 7KEYS/PSP users has been set up. The details from this FTP user account shall be used in these
 * INSERT commands. (3) The server name value must be the one on which this script is executed.
 *
 * 02/21/2006: Revised to dynamically use the current value of INTERFACE_NAME_ID for 7KEYS/PSP in whichever
 * IMAPS database where these INSERT statements are executed.
 */

DECLARE @INTERFACE_NAME_ID integer

SELECT @INTERFACE_NAME_ID = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t2.APPLICATION_CODE = '7KEYS/PSP'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@INTERFACE_NAME_ID, '7KEYS/PSP', 'OUT_FTP_SERVER', 'FFX23DAP01', SUSER_SNAME(), GETDATE())
go



DECLARE @INTERFACE_NAME_ID integer

SELECT @INTERFACE_NAME_ID = t2.LOOKUP_ID
  FROM dbo.XX_LOOKUP_DOMAIN t1,
       dbo.XX_LOOKUP_DETAIL t2
 WHERE t1.DOMAIN_CONSTANT  = 'LD_INTERFACE_NAME'
   AND t1.LOOKUP_DOMAIN_ID = t2.LOOKUP_DOMAIN_ID
   AND t2.APPLICATION_CODE = '7KEYS/PSP'

INSERT INTO dbo.XX_PROCESSING_PARAMETERS
   (INTERFACE_NAME_ID, INTERFACE_NAME_CD, PARAMETER_NAME, PARAMETER_VALUE, CREATED_BY, CREATED_DATE)
   VALUES(@INTERFACE_NAME_ID, '7KEYS/PSP', 'OUT_FTP_RECEIVING_DIRECTORY', 'Outbox\7Keys', SUSER_SNAME(), GETDATE())
go

-- 01/31/2006_End
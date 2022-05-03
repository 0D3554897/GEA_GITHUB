-- TABLES
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_BMS_IW_ACCOUNT_DATA] TO imapsprd, imapsstg
--GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_BMS_IW_ACCOUNT_DATA_backup] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_BMS_IW_DTL] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_BMS_IW_HDR] TO imapsprd, imapsstg

-- Stored Procedures
GRANT EXECUTE ON [dbo].[XX_BMS_IW_CHECK_UTIL_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_BMS_IW_CREATE_FLAT_FILE_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_BMS_IW_FTP_FLAT_FILE_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_BMS_IW_RUN_INTERFACE_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_GET_ACCT_TYP_CD_UF] TO imapsprd, imapsstg
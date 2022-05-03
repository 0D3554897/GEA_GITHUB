-- TABLES
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[AOPUTLAP_INP_DETL_ERRORS] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[AOPUTLAP_INP_HDR_ERRORS] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[AOPUTLAP_INP_LAB_ERRORS] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[AOPUTLJE_INP_TR_ERRORS] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_ERROR_AP_TEMP] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_ERROR_JE_TEMP] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_ERROR_STATUS] TO imapsprd, imapsstg



-- Stored Procedures
GRANT EXECUTE ON [dbo].[XX_ERROR_AP_EXPORT_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_ERROR_AP_FIWLR_GRAB_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_ERROR_AP_IMPORT_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_ERROR_AP_PCLAIM_GRAB_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_ERROR_FIWLR_CLOSEOUT_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_ERROR_JE_EXPORT_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_ERROR_JE_FIWLR_GRAB_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_ERROR_JE_IMPORT_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_ERROR_PCLAIM_CLOSEOUT_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_ERROR_REPROCESS_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[InString] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_PARSE_CSV] TO imapsprd, imapsstg










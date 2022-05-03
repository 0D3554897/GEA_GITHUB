-- TABLES
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_R22_CP_PLC_CODE] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_R22_CP_PLC_CODE_COUNT] TO imapsprd, imapsstg

-- Stored Procedures
GRANT EXECUTE ON [dbo].[XX_R22_INSERT_PLC_SP] TO imapsprd, imapsstg

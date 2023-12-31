-- TABLES
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_ET_DAILY_IN  TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_ET_DAILY_IN_ARC  TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_IMAPS_ET_FTR_IN_TMP  TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_IMAPS_ET_IN_TMP  TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_IMAPS_TS_PREP_TEMP  TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_IMAPS_ET_IN_UTIL  TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_IMAPS_TS_PREP_ZEROS  TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_IMAPS_TS_PREP_CONFIG_ERRORS  TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_IMAPS_TS_UTIL_DATA  TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_TS_PREP_ERRORS_TMP  TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_PAY_TYPE_ACCT_MAP  TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_ACCT_RECLASS  TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_IMAPS_TS_PREP_TEMP2 TO imapsprd, imapsstg

-- Stored Procedures
GRANT EXECUTE ON dbo.XX_R22_ETIME_MISCODE_CREATE_FILE_SP  TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_ETIME_MISCODE_CLOSEOUT_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_ETIME_SIMULATE_COSTPOINT_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_CHK_COSTPOINT_RESOURCES TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_CHK_ETIME_INT_RESOURCES TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_GET_ET_PROCESSING_PARAMETERS TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_GET_POSTERROR_EXEC_STEP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_ET_CHK_RUN_OPTION_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_INSERT_TS_PREPROC_RECORDS TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_ET_VALIDATE_SOURCE_DATA_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_LOAD_ET_STAGING_DATA_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_RUN_ET_POSTCOSTPOINT_PROC TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_RUN_ETIME_INTERFACE TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_INSERT_PLC_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_INSERT_TS_RESPROC_MISCODE_SP TO imapsprd, imapsstg
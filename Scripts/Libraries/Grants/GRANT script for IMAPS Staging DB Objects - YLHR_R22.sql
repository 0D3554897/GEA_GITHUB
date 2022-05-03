-- Tables

GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_YLHR_ETIME_CP_HRS_STG TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_YLHR_CP_POSTED_HRS TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_YLHR_CP_MISCODE_HRS TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_YLHR_ETIME_CP_HRS_FINAL TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_R22_YLHR_TIMECARD_EXCEPTION TO imapsprd, imapsstg

-- Stored procedures

GRANT EXECUTE ON dbo.XX_CATCH_PRINT_ERROR_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_YLHR_CHK_RESOURCES_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_YLHR_GET_ETIME_DATA_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_YLHR_GET_CP_DATA_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_YLHR_FINALIZE_OUTPUT_DATA_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_YLHR_RUN_INTERFACE_SP TO imapsprd, imapsstg

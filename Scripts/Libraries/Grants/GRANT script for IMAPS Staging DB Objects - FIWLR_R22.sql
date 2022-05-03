-- TABLES

GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_R22_FIWLR_LERU_MAP TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_R22_CLS_IMAPS_ACCT_MAP TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_R22_FIWLR_VCHR_ACCT_MAP TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_R22_FIWLR_RUNDATE_ACCTCAL TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_R22_FIWLR_APSRC_GRP TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_R22_FIWLR_EMP_V TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_R22_FIWLR_VEND_V TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_R22_FIWLR_USDET_V1 TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_R22_FIWLR_USDET_V3 TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_R22_FIWLR_USDET_TEMP TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.X2_R22_AOPUTLAP_INP_HDR_WORKING TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.X2_R22_AOPUTLAP_INP_DETL_WORKING TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.X2_R22_AOPUTLJE_INP_TR_WORKING TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.X2_R22_AOPUTLJE_INP_VEN_WORKING TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_R22_FIWLR_USDET_MISCODES TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_R22_FIWLR_USDET_ARCHIVE TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_R22_FIWLR_USDET_RPT_TEMP TO IMAPSPRD, IMAPSSTG


-- Stored Procedures

GRANT EXECUTE ON dbo.XX_R22_FIWLR_EXTRACT_DATA_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_FIWLR_PROJ_ORG_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_FIWLR_ACCT_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_FIWLR_VALID_DATA_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_FIWLR_PREPROCESSOR_AP_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_ADD_VENDOR_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_FIWLR_LOAD_PREPROCESSORS_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_FIWLR_PREP_JE_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_FIWLR_INITIATE_PREPROCESSORS_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_FIWLR_PREPROCESSOR_CLOSEOUT_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_FIWLR_MISCODE_UPDATE_FEEDBACK_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_FIWLR_ARCHIVE_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_FIWLR_RUN_INTER_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_FIWLR_MISCODE_UPDATE_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_FIWLR_MISCODE_REPROCESS_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_R22_FIWLR_MISCODE_CLOSEOUT_SP TO imapsprd, imapsstg






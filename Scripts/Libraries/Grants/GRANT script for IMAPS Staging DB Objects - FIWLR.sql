-- TABLES

GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_SEQUENCES_HDR TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_SEQUENCES_DETL TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_SEQUENCES_JE TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_FIWLR_WWERN16 TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_FIWLR_WWERN16_CONTROL TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_FIWLR_INC_EXC TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_FIWLR_APSRC_GRP TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_FIWLR_CERIS_EMP TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_CLS_IMAPS_ACCT_MAP TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_FIWLR_USDET_V1 TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_FIWLR_USDET_V2 TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_FIWLR_USDET_V3 TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_FIWLR_USDET_ARCHIVE TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_FIWLR_EMP_V TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_FIWLR_VEND_V TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_AOPUTLAP_INP_HDRV TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_AOPUTLAP_INP_DETLV TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_AOPUTLAP_INP_HDR_ERR TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_AOPUTLAP_INP_DETL_ERR TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.XX_AOPUTLJE_INP_TR_ERR TO IMAPSPRD, IMAPSSTG
GRANT SELECT, UPDATE, DELTEE, INSERT ON dbo.XX_TEST_GENL_UDEF TO IMAPSPRD, IMAPSSTG
--Added by Veera on 11/30/2005 Defect: DEV0000296
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.XX_FIWLR_RUNDATE_ACCTCAL TO IMAPSPRD, IMAPSSTG
--Added by Veera on 12/06/2005 Defect: DEV0000296
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.xx_fiwlr_wwern16 TO IMAPSPRD,IMAPSSTG, PCLMUSER
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.xx_fiwlr_wwern16_control TO IMAPSPRD,IMAPSSTG, PCLMUSER



-- Stored Procedures

GRANT EXECUTE ON [dbo].[xx_hdr_nextval_sp] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[xx_detl_nextval_sp] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[xx_je_nextval_sp] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_VENDOR_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_EMP_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_WWERN16_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_ASSIGN_SRC_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_CERIS_EMP_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_UPD_DT_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_EXTRACT_DATA_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_PROJ_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_ORG_SP] TO imapsprd, imapsstg

GRANT EXECUTE ON [dbo].[XX_FIWLR_ACCT1_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_ACCT2_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_VALID_DATA_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_STG_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_IMAPS_STG_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_PREPROCESSOR_AP_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_PREPROCESSOR_JE_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_INITIATE_PREPROCESSORS_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_ARCHIVE_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_RUN_INTER_SP] TO imapsprd, imapsstg

GRANT EXECUTE ON [dbo].[XX_DELTEK_GENL_UDEF_SP] TO imapsprd, imapsstg

--DEV0000243
GRANT EXECUTE ON dbo.XX_FIWLR_PREP_JE_SP TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_FIWLR_PREPROCESSOR_JE_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_FIWLR_STG_JE_BAL_SP TO imapsprd, imapsstg
GRANT EXECUTE ON dbo.XX_FIWLR_STG_BAL_SP TO imapsprd, imapsstg






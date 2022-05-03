-- TABLES
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_IMAPS_INV_OUT_SUM] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_IMAPS_INV_OUT_DTL] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_IMAPS_INV_ERROR] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_IMAPS_INVOICE_SENT] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_IMAPS_CMR_STG] TO imapsprd, imapsstg

-- Stored Procedures
GRANT EXECUTE ON [dbo].[XX_AR_LOAD_SUM_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_AR_VALIDATE_CMR_NUM_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_AR_LOAD_DTL_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_AR_CREATE_FLAT_FILES_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_AR_LOAD_SENT_SP] TO imapsprd, imapsstg
--GRANT EXECUTE ON [dbo].[XX_AR_FTP_FILES_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_AR_RUN_OUTBOUND_SP] TO imapsprd, imapsstg

-- Added by KM on 10/14/05
GRANT EXECUTE ON [dbo].[XX_AR_FTP_CCS_FILE_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_AR_FTP_FDS_FILE_SP] TO imapsprd, imapsstg

-- Added by KM on 11/30/05
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_CLS_DOWN_FDS_REVERSE] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_GET_SERVICE_OFFERING_UF] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_GET_MACHINE_TYPE_UF] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_GET_PRODUCT_ID_UF] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_GET_CONTRACT_UF] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_GET_PROJ_ABBRV_CD_UF] TO imapsprd, imapsstg
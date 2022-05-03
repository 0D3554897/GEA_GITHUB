-- TABLES

GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_7KEYS_OUT_DETAIL] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_7KEYS_OUT_DETAIL_TEMP] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_7KEYS_OUT_HDR] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_7KEYS_OUT_HDR_TEMP] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_7KEYS_RUN_LOG] TO imapsprd, imapsstg

-- Defect CP600000074 10/2007 Begin
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_PSR_PTD_FINAL_DATA] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_REVENUE_UNBILLED_SUMMARY] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_REVENUE_ON_OPEN_BILLING_DETL] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_REVENUE_LVL_UNBILLED_BALANCE] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_PSR_PTD_FINAL_DATA] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_REVENUE_ON_OPEN_BILLING_DETL] TO imapsprd, imapsstg
-- Defect CP600000074 10/2007 End


-- Stored Procedures

GRANT EXECUTE ON [dbo].[XX_7KEYS_CHK_RESOURCES_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_7KEYS_GET_PROCESSING_PARAMS_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_7KEYS_PROCESS_RUN_INPUT_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_MANAGE_FILE_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_7KEYS_BUILD_OUTPUT_FILE_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_7KEYS_ARCHIVE_MOVE_OUTPUT_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_7KEYS_LOG_RUN_DATA_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_7KEYS_RUN_INTERFACE_SP] TO imapsprd, imapsstg

-- Defect CP600000074 10/2007 Begin
GRANT EXECUTE ON [dbo].[XX_LOAD_PTD_FINAL_DATA_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_CALCULATE_UNBILLED_REVENUE_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_CALCULATE_UNBILLED_BALANCES_SP] TO imapsprd, imapsstg
-- Defect CP600000074 10/2007 End

/*
 * This script contains all the GRANT statements for IMAPS Staging DB objects necessary to run
 * eTime and PCLAIM interface applications.
 *
 * NOTE: You can only grant or revoke permissions on objects in the current database.
 */



-- use IMAPSStg

-- Part I: IMAPS Tables

-- Common to all IMAPS interfaces
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_INT_ERROR_MESSAGE] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_LOOKUP_DETAIL] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_LOOKUP_DOMAIN] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_IMAPS_INT_CONTROL] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_IMAPS_INT_STATUS] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_IMAPS_MAIL_OUT] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_PROCESSING_PARAMETERS] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_PARAM_TEMP] TO imapsprd, imapsstg

-- eTime interface
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_ET_DAILY_IN] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_ET_DAILY_IN_ARC] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_IMAPS_ET_FTR_IN_TMP] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_IMAPS_ET_IN_TMP] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_IMAPS_TS_PREP_TEMP] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_TS_PREP_ERRORS_TMP] TO imapsprd, imapsstg

-- PCLAIM interface
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_PCLAIM_FTR_IN_TMP] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_PCLAIM_IN] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_PCLAIM_IN_ARCH] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_PCLAIM_IN_TMP] TO imapsprd, imapsstg
-- TP 10/28/2005 begin
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_PCLAIM_IN_LOG] TO imapsprd, imapsstg
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_PCLAIM_IN_LOG] TO pclmuser
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[XX_PCLAIM_IN_TMP] TO pclmuser
-- TP 10/28/2005 end

-- PART III: Stored Procedure

-- Common to all IMAPS interfaces
GRANT EXECUTE ON [dbo].[XX_ERROR_MSG_DETAIL] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_EXEC_SHELL_CMD] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_EXEC_SHELL_CMD_INSERT] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_GET_ERROR_MSG_TEXT] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_GET_LOOKUP_DATA] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_GET_PERIOD_N_SUBPERIOD_DATA] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_GET_SQLSERVER_SYSMSG] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_INSERT_INT_CONTROL_RECORD] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_INSERT_INT_STATUS_RECORD] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_MOVE_FILE_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_RENAME_FILE_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_SEND_STATUS_MAIL_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_ADD_VENDOR_EMPL_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_ADD_VENDOR_SP] TO imapsprd, imapsstg

-- eTime interface
GRANT EXECUTE ON [dbo].[XX_CHK_COSTPOINT_RESOURCES] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_CHK_ETIME_INT_RESOURCES] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_GET_ET_PROCESSING_PARAMETERS] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_GET_POSTERROR_EXEC_STEP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_IMAPS_UPDATE_PRQENT_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_INSERT_PLC_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_INSERT_TS_PREPROC_RECORDS] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_LOAD_ET_STAGING_DATA_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_RUN_ET_POSTCOSTPOINT_PROC] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_RUN_ETIME_INTERFACE] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_UPDATE_INT_STATUS_RECORD] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_UPDATE_PROCESS_PARAM_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_UPDATE_PROCESS_STATUS_SP] TO imapsprd, imapsstg


-- PCLAIM interface
GRANT EXECUTE ON [dbo].[XX_PCLAIM_ARCHIVE_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_PCLAIM_FILE_BULK_INSERT_SP ] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_PCLAIM_FILL_PREPROCESSOR_STAGE_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_PCLAIM_LOAD_STAGING_DATA_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_PCLAIM_RUN_INTERFACE_SP] TO imapsprd, imapsstg
GRANT EXECUTE ON [dbo].[XX_PCLAIM_START_AP_PREPROCESSOR_SP] TO imapsprd, imapsstg


-- TABLES

dbo.xx_mpm_resorce_code_mapping

GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.xx_mpm_resorce_code_mapping TO IMAPSPRD, IMAPSSTG

--Added by Veera on 1/5/07 to exclude EVMS Account
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.xx_mic_eocmap_inc_exc TO IMAPSPRD, IMAPSSTG


-- Stored Procedures

GRANT EXECUTE ON dbo.xx_mpm_interface_setup_sp TO imapsprd, imapsstg





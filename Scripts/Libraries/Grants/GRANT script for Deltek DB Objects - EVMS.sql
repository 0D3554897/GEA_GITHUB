
--DELTEK TABLES
GRANT SELECT, UPDATE, INSERT ON DELTEK.X_MIC_OBSMAP TO imapsstg, imapsprd
GRANT SELECT, UPDATE, INSERT ON DELTEK.X_MIC_WBSMAP TO imapsstg, imapsprd
GRANT SELECT, UPDATE, INSERT ON DELTEK.X_MIC_RESMAP TO imapsstg, imapsprd
GRANT SELECT, UPDATE, INSERT ON DELTEK.X_MIC_EOCMAP TO imapsstg, imapsprd

GRANT SELECT, UPDATE, INSERT,DELETE ON DELTEK.X_MIC_MAP TO imapsstg, imapsprd

--Added by Veera on 1/5/07 to exclude EVMS Account ref: Defect: 1672

GRANT SELECT, UPDATE, DELETE, INSERT ON imaps.deltek.acct TO imapsstg, imapsprd
GRANT SELECT, UPDATE, DELETE, INSERT ON imaps.deltek.empl TO imapsstg, imapsprd
GRANT SELECT, UPDATE, DELETE, INSERT ON imaps.deltek.vend TO imapsstg, imapsprd
GRANT SELECT, UPDATE, DELETE, INSERT ON imaps.deltek.proj TO imapsstg, imapsprd
GRANT SELECT, UPDATE, DELETE, INSERT ON imaps.deltek.org TO IMAPSSTG

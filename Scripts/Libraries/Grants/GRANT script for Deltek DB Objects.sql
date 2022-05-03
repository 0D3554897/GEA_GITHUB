/*
 * This script contains all the GRANT statements for Deltek and IMAPS DB objects necessary to run
 * eTime and PCLAIM interface applications.
 *
 * NOTE: You can only grant or revoke permissions on objects in the current database.
 */

use IMAPS

/* for application use */

GRANT SELECT ON [deltek].[EMPL] to imapsstg, imapsprd
GRANT SELECT ON [deltek].[PROJ] to imapsstg, imapsprd
GRANT SELECT ON [deltek].[UDEF_LBL] to imapsstg, imapsprd
GRANT SELECT ON [deltek].[GENL_UDEF] to imapsstg, imapsprd
GRANT SELECT ON [deltek].[TM_RT_ORDER] to imapsstg, imapsprd
GRANT SELECT ON [deltek].[PROJ_LAB_CAT] to imapsstg, imapsprd
GRANT SELECT ON [deltek].[PROCESS_HDR] to imapsstg, imapsprd
GRANT SELECT ON [deltek].[PROCESS_SERVER] to imapsstg, imapsprd
GRANT SELECT ON [deltek].[PROCESS_QUE_ENTRY] TO imapsprd, imapsstg
GRANT SELECT ON [deltek].[AOPUTLAP_INP_HDR] TO imapsprd, imapsstg
GRANT SELECT ON [deltek].[AOPUTLAP_INP_LAB] TO imapsprd, imapsstg
GRANT SELECT ON [deltek].[AOPUTLAP_INP_DETL] TO imapsprd, imapsstg
GRANT SELECT ON [deltek].[SUB_PD] to imapsstg, imapsprd

-- begin 02/13/2006 TP DV0000527
GRANT SELECT, INSERT, DELETE, UPDATE ON [deltek].[VEND] to imapsstg, imapsprd          
GRANT SELECT, INSERT, DELETE, UPDATE ON [deltek].[VEND_ADDR] to imapsstg, imapsprd     
GRANT SELECT, INSERT, DELETE, UPDATE ON [deltek].[VEND_EMPL] to imapsstg, imapsprd     
--end 02/13/2006 TP DV0000527

GRANT SELECT ON [deltek].[ACCT_GRP_SETUP] to imapsstg, imapsprd -- 02/03/2006 TP DV0000412

/* for developer use only */

GRANT SELECT ON [deltek].[FUNC_PARM_CATLG] to imapsstg, imapsprd
GRANT SELECT ON [deltek].[PROCESS_FUNC_PARM] to imapsstg, imapsprd
GRANT SELECT ON [deltek].[JOB_FUNC_PARM] to imapsstg, imapsprd

-- Defect 1018 06/29/2006 - For other IBM users in order to use the view IMAPSStg.dbo.XX_PCLAIM_DATA_IN_IMAPS_VW
GRANT SELECT ON Deltek.VCHR_HDR_HS TO pclmuser
GRANT SELECT ON Deltek.VCHR_LAB_VEND_HS TO pclmuser
GRANT SELECT ON Deltek.VCHR_LN_ACCT_HS TO pclmuser
GRANT SELECT ON Deltek.VCHR_LN_HS TO pclmuser


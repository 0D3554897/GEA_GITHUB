USE IMAPSSTG
DROP VIEW [dbo].[XX_CLS_DOWN_VW]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 

 





/* 
Used by Control report : CLS Down main.imr
              Catalog : Control Points.cat 
	 Folder: Control Point Views\Xx Cls Down Vw
*/

CREATE VIEW [dbo].[XX_CLS_DOWN_VW]
AS
SELECT     cls_file.CLS_MAJOR, cls_file.CLS_MINOR, cls_file.CLS_SUB_MINOR, cls_file.DOLLAR_AMT, cls_file.MACHINE_TYPE_CD, cls_file.DESCRIPTION2, 
                      cls_file.BUSINESS_AREA, cls_file.PRODUCT_ID, cls_file.CUSTOMER_NUM, cls_file.MARKETING_AREA, cls_file.CONTRACT_NUM, cls_file.GA_AMT, 
                      cls_file.OVERHEAD_AMT, cls_file.MARKETING_OFFICE, cls_file.CONSOLIDATED_REV_BRANCH_OFFICE, cls_file.INDUSTRY, 
                      cls_file.ENTERPRISE_NUM_CD, cls_file.IGS_PROJ, cls_file.SERVICE_OFFERING, cls_file.IMAPS_ACCT, cls_log.STATUS_RECORD_NUM, 
                      cls_log.FILE_SEQ_NUM, cls_log.VOUCHER_NUM, cls_log.FY_SENT, cls_log.MONTH_SENT, cls_log.LEDGER_ENTRY_DATE, cls_log.MODIFIED_BY, 
                      cls_log.ON_DEMAND, cls_file.L1_PROJ_SEG_ID
FROM       IMAPSStg.dbo.XX_CLS_DOWN cls_file,
                          (SELECT     *
                            FROM         [IMAPSStg].[dbo].[XX_CLS_DOWN_LOG]
                            WHERE      [STATUS_RECORD_NUM] =
                                                       (SELECT     MAX(STATUS_RECORD_NUM)
                                                         FROM        [IMAPSStg].[dbo].[XX_CLS_DOWN_LOG])) cls_log









 

 

GO
 


USE IMAPSSTG
DROP VIEW [dbo].[XX_CLS_DOWN_FDS_RECONCILE_VW]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 

 





/* 
Used by Control report : CLS Down FDS reconciliation.imr
              Catalog : Control Points.cat 
	 Folder: Control Point Views\Xx Cls Down Fds Reconcile Vw
*/


CREATE VIEW [dbo].[XX_CLS_DOWN_FDS_RECONCILE_VW]
AS
SELECT     gl.GL_Contract, gl.GL_Contract_Total, cls.CONTRACT_NUM AS CLS_Contract_Num, cls.CLS_Contract_Total
FROM         (SELECT     LEFT(ISNULL(PROJ_ID, 'XXXX'), 4) AS GL_Contract, SUM(AMT) AS GL_Contract_Total
                       FROM         IMAPS.DELTEK.GL_POST_SUM
                       WHERE      (ACCT_ID = '10-01-10' or ACCT_ID = '10-01-11') AND FY_CD =
                                                  (SELECT     TOP 1 FY_SENT
                                                    FROM         [IMAPSstg].[dbo].[XX_CLS_DOWN_VW]) AND PD_NO =
                                                  (SELECT     TOP 1 CAST(MONTH_SENT AS INTEGER)
                                                    FROM         [IMAPSstg].[dbo].[XX_CLS_DOWN_VW])
                       GROUP BY LEFT(ISNULL(PROJ_ID, 'XXXX'), 4)) gl FULL OUTER JOIN
                          (SELECT     CONTRACT_NUM, SUM(DOLLAR_AMT) AS CLS_Contract_Total
                            FROM        IMAPSstg.dbo.XX_CLS_DOWN
                            WHERE      DESCRIPTION2 LIKE 'FDS%'
                            GROUP BY CONTRACT_NUM) cls ON 'D' + RIGHT(cls.CONTRACT_NUM, 3) = gl.GL_Contract





 

 

GO
 


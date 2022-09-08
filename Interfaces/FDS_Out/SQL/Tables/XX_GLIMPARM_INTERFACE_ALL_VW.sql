USE [IMAPSStg]
GO

/****** Object:  View [dbo].[XX_GLIMPARM_INTERFACE_ALL_VW]    Script Date: 6/14/2022 5:33:57 PM ******/
DROP VIEW [dbo].[XX_GLIMPARM_INTERFACE_ALL_VW]
GO

/****** Object:  View [dbo].[XX_GLIMPARM_INTERFACE_ALL_VW]    Script Date: 6/14/2022 5:33:57 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO





/* 
Used by CFF for GLIM Interface

the following diagnosis query will reveal the invoices that are causing the imbalance if zero <> 0:

SELECT * FROM (
SELECT INVOICENUMBER, '121' AS A, SPACE(2) AS B, convert(varchar(6),getdate(),112) AS C,SPACE(2) AS D, 
--case when CAST(AMOUNTLOCALCURRENCY AS bigINT) < 0 then 0 else CAST(AMOUNTLOCALCURRENCY AS bigINT) end AS DEBITS, 
      SPACE(2) AS F, 1 AS G, SPACE(1) AS H, VCODE.PADDED AS I,SPACE(1) AS J, 'N' AS K, SPACE(13) AS L, 
      SUM(CAST(CAST(AMOUNTLOCALCURRENCY AS DECIMAL(16,2))/100 AS DECIMAL(15,2)))AS TOT, 
	  '         897' AS N 
	  from (
		select * from imapsstg.dbo.XX_GLIM_INTERFACE_TXT_VW) PARM  	  
	  JOIN (SELECT '897' AS VA, LEFT(PARAMETER_value + '        ', 8) AS PADDED 
			FROM dbo.XX_PROCESSING_PARAMETERS WITH (NOLOCK) 
			WHERE INTERFACE_NAME_CD = 'FDS/CCS' AND PARAMETER_NAME = 'CONFRMCD') VCODE 
		ON PARM.COUNTRY = VCODE.VA 
	  group by INVOICENUMBER, VCODE.PADDED
)UNBALANCED
WHERE TOT<>0


*/

CREATE VIEW [dbo].[XX_GLIMPARM_INTERFACE_ALL_VW]
AS

SELECT 
  'CC' AS CONSTANT, 
  A AS FILE_ID, 
  B AS FILLER_01, 
  C AS DATE, 
  D AS FILLER_02, 
  right(
    '                         ' + left(
      cast(
        sum(debits) as varchar(25)
      ), 
      LEN(
        cast(
          sum(debits) as varchar(25)
        )
      )-2
    ) + '.' + right(
      cast(
        sum(debits) as varchar(25)
      ), 
      2
    ), 
    16
  ) AS DEBITS, 
  F AS FILLER_03, 
  RIGHT(
    '         ' + CAST(
      COUNT(G) AS VARCHAR(7)
    ), 
    7
  ) AS CNT, 
  H AS FILLER_04, 
  I AS CONFCODE, 
  J AS FILLER_05, 
  K AS REVERSE, 
  L AS FILLER_06, 
  SUM(TOT) AS ZERO, 
  N AS COUNTRY 
FROM 
  (
    SELECT 
      '121' AS A, 
      SPACE(2) AS B, 
      convert(
        varchar(6), 
        getdate(), 
        112
      ) AS C, 
      SPACE(2) AS D, 
      case when CAST(AMOUNTLOCALCURRENCY AS bigINT) < 0 then 0 else CAST(AMOUNTLOCALCURRENCY AS bigint) end AS DEBITS, 
      SPACE(2) AS F, 
      1 AS G, 
      SPACE(1) AS H, 
      VCODE.PADDED AS I, 
      SPACE(1) AS J, 
      'N' AS K, 
      SPACE(13) AS L, 
      SUM(
        CAST(
          CAST(
            AMOUNTLOCALCURRENCY AS decimal(16,2))/ 100 AS DECIMAL(15, 2)
        )
      ) AS TOT, 
      '         897' AS N 
      /*THEN EXTRA FOR MAKING THE COUNT RIGHT */
      , 
      INVOICENUMBER
    from 
      (
        SELECT ROW_NUMBER() OVER(ORDER BY major) AS ID,* from imapsstg.dbo.XX_GLIM_INTERFACE_TXT_VW
           ) PARM 
      JOIN (
        SELECT 
          '897' AS VA, 
          LEFT(PARAMETER_value + '        ', 8) AS PADDED 
        FROM 
          IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS WITH (NOLOCK) 
        WHERE 
          INTERFACE_NAME_CD = 'FDS' 
          AND PARAMETER_NAME = 'CONFRMCD'
      ) VCODE ON PARM.COUNTRY = VCODE.VA 
    group by 
      AMOUNTLOCALCURRENCY, 
      VCODE.PADDED, 
      INVOICENUMBER, 
      ID
  ) P 
GROUP BY 
  A, 
  B, 
  C, 
  D, 
  F, 
  H, 
  I, 
  J, 
  K, 
  L, 
  N



GO



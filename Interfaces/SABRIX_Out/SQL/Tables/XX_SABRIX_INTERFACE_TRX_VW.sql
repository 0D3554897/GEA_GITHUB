USE IMAPSSTG
DROP VIEW [dbo].[XX_SABRIX_INTERFACE_TRX_VW]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
 

 

 

 

 

 

 

 





/* 
Used by CFF for Sabrix Interface
SELECT * FROM IMAPSSTG.DBO.XX_SABRIX_INTERFACE_TRX_VW

DR 10853 - don't exclude $0 invoices
*/

CREATE VIEW [dbo].[XX_SABRIX_INTERFACE_TRX_VW]
AS

SELECT A,B,C,D 
FROM (
-- LINE 1
SELECT '0' ORD,' ' A,' ' B,' ' C,' ' D 
UNION 
--LINE 2
SELECT '1' ORD,' ' A,' ' B,' ' C,' ' D  
UNION 
--LINE 3
SELECT '2' ORD,'FEED NAME' A ,'  RECORDS SENT TO TAX DEPT' B,'  REVENUE AMOUNT SENT TO TAX DEPT' C, '  TAX AMOUNT SENT TO TAX DEPT' D 
UNION
--LINE 4
select '3','---------','  ------------------------','  --------------------------------', '  ---------------------------' 
UNION 
-- LINE 5
SELECT '4','IMAPS', 
right(SPACE(24) + cast(COUNT(*) as varchar (24)),22) as records, 
right(SPACE(32) + cast(CONVERT(DECIMAL(15,2),sum( case when POWER(0,CHARINDEX('-',REV))-1 = 0 then 1 else -1 end * cast(right(REV,LEN(REV)-CHARINDEX('-',REV)) as decimal(13,2))/100)) as varchar(32)),32) as rev, 
RIGHT(SPACE(32) + 
-- cast(SUM(statetax + countytax + citytax) as varchar(32))
CAST(CONVERT(DECIMAL(15,2),sum( case when POWER(0,CHARINDEX('-',statetax))-1 = 0 then 1 else -1 end * cast(right(statetax,LEN(statetax)-CHARINDEX('-',statetax)) as decimal(11,2))/100))  +
CONVERT(DECIMAL(15,2),sum( case when POWER(0,CHARINDEX('-',countytax))-1 = 0 then 1 else -1 end * cast(right(countytax,LEN(countytax)-CHARINDEX('-',countytax)) as decimal(11,2))/100))  +
CONVERT(DECIMAL(15,2),sum( case when POWER(0,CHARINDEX('-',citytax))-1 = 0 then 1 else -1 end * cast(right(citytax,LEN(citytax)-CHARINDEX('-',citytax)) as decimal(11,2))/100)) 
as varchar(32))
,30) as tax
from imapsstg.dbo.xx_sabrix_interface_DTL_vw)x




 

 

 

 

 

 

 

 

GO
 


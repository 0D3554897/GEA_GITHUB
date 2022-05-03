USE IMAPSSTG
DROP VIEW [dbo].[XX_R22_CLS_PARM_FILE_VW]
GO
SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON
GO
/* 
Used by CFF for CLS Interface

usage: select * from imapsstg.dbo.XX_R22_CLS_PARM_FILE_VW where STATUS_RECORD_NUM = 10710

*/

CREATE VIEW [dbo].[XX_R22_CLS_PARM_FILE_VW]
AS

Select top 1 * from

( select 

 'CC' + left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where INTERFACE_NAME_CD = 'CLS_R22' AND  parameter_name ='FILE_ID')+ Filler_3,3) as File_ID --TSPC(PARAM_rs.getString

, Filler_2 + RIGHT('0000'+CAST(SX.FY_SENT AS VARCHAR(4)),4) as Accounting_Year --  LZ(CLS_LOG_rs.getInt('FY_SENT'), 4)

, RIGHT('00'+CAST(SX.MONTH_SENT AS VARCHAR(2)),2) as Accounting_Month_Local -- LZ(CLS_LOG_rs.getInt('MONTH_SENT'), 2)

, Filler_2 +  RIGHT( --'0000000000000000'
'               ' +
CAST((select sum(DOLLAR_AMT) from IMAPSSTG.dbo.XX_R22_CLS_DOWN where DOLLAR_AMT > 0) AS VARCHAR(16)),16) as Local_Debits -- LSPC(LOCAL_DEBITS.toString(), 16) 

, Filler_2 +  RIGHT( --'0000000'
SPACE(7) +(select cast(count(1) as varchar) from IMAPSSTG.dbo.XX_R22_CLS_DOWN ),7) as REC_CNT --LZ(REC_CNT, 7) 

, Filler_1 + LEFT((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where INTERFACE_NAME_CD = 'CLS_R22' AND  parameter_name ='CONFRMCD') + SPACE(8),8) as Confirmed_cd

/******************************************* RIGHT JUSTIFIED ******************************************************
, Filler_1 + RIGHT(--'00000000'
SPACE(8) +(select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where INTERFACE_NAME_CD = 'CLS_R22' AND  parameter_name ='CONFRMCD'),8) as Confirmed_cd -- LZ(CONFRMCD, 8) 
*******************************************************************************************************************/


, Filler_2 as REVERSE 

, Filler_1  + RIGHT(  -- '0000000000000000' 
space(15) + CAST((select sum(isnull(DOLLAR_AMT,0.0)) from IMAPSSTG.dbo.XX_R22_CLS_DOWN ) AS VARCHAR(16)),16) as Net_Amount --LSPC(US_NET_AMT.toString(), 16) 
 
, Filler_9 + left((select parameter_value from IMAPSSTG.dbo.XX_PROCESSING_PARAMETERS where INTERFACE_NAME_CD = 'CLS_R22' AND  parameter_name ='COUNTRY_NUM')+ Filler_3,3)  as Country_Number

from IMAPSSTG.dbo.XX_R22_CLS_DOWN, 

(
 select convert(varchar(4), LEDGER_ENTRY_DATE, 112) AS FY_SENT, MONTH_SENT from IMAPSSTG.dbo.XX_R22_CLS_DOWN_LOG 
         where STATUS_RECORD_NUM IN 
       (SELECT MAX(STATUS_RECORD_NUM) FROM IMAPSSTG.dbo.XX_R22_CLS_DOWN_LOG))    SX,

-- SELECT convert(varchar(4), LEDGER_ENTRY_DATE, 112) FROM IMAPSSTG.dbo.XX_R22_CLS_DOWN_LOG,

(
Select Space(1) as Filler_1
, Space(2) as Filler_2
, Space(3) as Filler_3
, Space(4) as Filler_4
, Space(5) as Filler_5
, Space(6) as Filler_6
, Space(7) as Filler_7
, Space(8) as Filler_8
, Space(9) as Filler_9
, Space(10) as Filler_10
, Space(11) as Filler_11
, Space(12) as Filler_12
, Space(13) as Filler_13
, Space(14) as Filler_14
, Space(15) as Filler_15
, Space(30) as Filler_30

) as Fillers) skills





 

 

GO
 


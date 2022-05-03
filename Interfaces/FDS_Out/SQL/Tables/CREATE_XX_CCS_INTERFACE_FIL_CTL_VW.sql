USE [IMAPSStg]
GO

/****** Object:  View [dbo].[XX_CCS_INTERFACE_FIL_CTL_VW]    Script Date: 09/13/2018 11:14:59 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[XX_CCS_INTERFACE_FIL_CTL_VW]'))
DROP VIEW [dbo].[XX_CCS_INTERFACE_FIL_CTL_VW]
GO

USE [IMAPSStg]
GO

/****** Object:  View [dbo].[XX_CCS_INTERFACE_FIL_CTL_VW]    Script Date: 09/13/2018 11:15:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


/* 
Used by CFF for CCS Interface  - THIS IS A FIL CONTROL RECORD

SELECT * FROM IMAPSSTG.DBO.XX_CCS_INTERFACE_FIL_CTL_VW

Len of field to be sent to packed decimal should be equal to first digit.  
For example, '00000000000' (LEN=11) would be sent to a DEC(11,2) packed decimal field
The number 12345.67 should be converted to 00001234567 for a total length of 11
To convert a column, use the general form:

packed decimal specification: DEC(X,Y)  (LENGTH, PRECISION)

RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(X,0),((COLUMN_NAME) * 100)) as varchar),X)

DECIMAL(X,0) TO REMOVE DECIMAL POINT, WHERE X = LENGTH OF THE PACKED DECIMAL SPECIFICATION
MULTIPLY THE AMOUNT (COLUMN_NAME) BY 100
ZEROES ARE APPENDED TO LEFT OF NUMBER
RIGHT FUNCTION LENGTH IS ALSO EQUAL TO X
*/

CREATE VIEW [dbo].[XX_CCS_INTERFACE_FIL_CTL_VW]
AS

SELECT
/**** requested by CCS *****/
--SPACE(23) AS FILLER_01,
--MAX(INV_DATE) AS INVC_DATE,
2 as ARDIV,
0 as YR_OF_SALE,
99 as FAKE_DIV,
SPACE(3) AS FILLER_00,
SPACE(7) AS WHERE_CUSTOMER_WOULD_GO,
SPACE(1) AS FILLER_01,
'0' AS ZERO,
SPACE(7) AS WHERE_INVOICE_NUM_WOULD_GO,
(select top 1 inv_date from IMAPSSTG.DBO.XX_CCS_INTERFACE_DTL_VW order by invc_id) AS INVC_DATE,
/**** requested by CCS *****/
-- note: bigint required because int maxes out at $21.4 million
CASE CHARINDEX('-',
RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(13,0),((SUM(CASE CHARINDEX('-',INV_AMT) WHEN 0 THEN CAST(INV_AMT AS BIGINT) ELSE CAST(REPLACE(INV_AMT,'-','0') AS BIGINT) * -1 END) ))) as varchar),13)
)WHEN 0 THEN 
RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(13,0),((SUM(CASE CHARINDEX('-',INV_AMT) WHEN 0 THEN CAST(INV_AMT AS BIGINT) ELSE CAST(REPLACE(INV_AMT,'-','0') AS BIGINT) * -1 END) ))) as varchar),13)
ELSE '-' + REPLACE(
RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(13,0),((SUM(CASE CHARINDEX('-',INV_AMT) WHEN 0 THEN CAST(INV_AMT AS BIGINT) ELSE CAST(REPLACE(INV_AMT,'-','0') AS BIGINT) * -1 END) ))) as varchar),13)
,'-','') END as TOT_AMT,

/**** requested by CCS *****/

--sum(cast(inv_amt as bigint)) as tot_amt_DIAGNOSIS,

--SPACE(13) AS FILLER_02,
SPACE(9) as FILLER_02A,
'A' AS SOME_CODE,
SPACE(3) AS FILLER_02B,
/**** requested by CCS *****/
-- SPACE(1) AS I_BILL_LOC, -- THAT'S THE 1
-- SPACE(1) AS FILLER_03,
-- SPACE(3) AS I_TRANS_SEQ_NO,-- THAT'S THE DIGIT
-- how many files sent this month, a sequence number
'3' AS I_BILL_LOC, 
SPACE(1) AS FILLER_03,
right ('000' + cast(
(select 1 + COUNT(distinct status_record_num) from imapsstg.dbo.XX_IMAPS_INVOICE_SENT where convert(varchar(6), getdate(), 112) = convert(varchar(6), time_stamp, 112)) 
as varchar(3)),3) as I_TRANS_SEQ_NO,
/**** requested by CCS *****/
RIGHT('00000000000000000'+ CAST(COUNT(*) + 2 AS VARCHAR(6)),6) AS Q_REC_COUNT,
SPACE(83) AS FILLER_04,
'7' AS C_INITIAL_ACT,
SPACE(35) AS FILLER_05,
SPACE(1) AS C_RECORD_MARK,
SPACE(720) AS FILLER_06


FROM IMAPSSTG.DBO.XX_CCS_INTERFACE_DTL_VW
-- where INV_AMT <> 0


GO



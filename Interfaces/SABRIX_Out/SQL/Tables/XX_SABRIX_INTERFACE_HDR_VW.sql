USE [IMAPSStg]
GO

/****** Object:  View [dbo].[XX_SABRIX_INTERFACE_HDR_VW]    Script Date: 12/7/2022 2:23:20 PM ******/
DROP VIEW [dbo].[XX_SABRIX_INTERFACE_HDR_VW]
GO

/****** Object:  View [dbo].[XX_SABRIX_INTERFACE_HDR_VW]    Script Date: 12/7/2022 2:23:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* 

Used by CFF for Sabrix Interface

usage: select * from imapsstg.dbo.XX_SABRIX_INTERFACE_HDR_VW
PADDED SPACES:

-- PREFERRED FILLER CHARACTER IS VALUE 32 (ASCII SPACE DECIMAL CHARACTER).  SQL SERVER HAS QUIRKS WHEN PADDING WITH SPACES. GENERALLY UNSUPPORTED 

-- IF FILE FAILS WHEN USING 32, FALLBACK VALUE IS 158. MUST ALSO MODIFY SABRIX16_HDR.PROPERTIES
     FILE TO INCLUDE PARAMETER: file.swapchars=158,32 
	 PUT IT IN THE #FILE SECTION

-- FOR FILLER CHARACTER, NO CHANGE NECESSARY TO THE VIEW.  JUST CHANGE PROC PARAMETERS TABLE:

-- TO SEE WHICH FILLER CHARACTER IS CURRENTLY USED: SELECT PARAMETER_VALUE AS INT FROM IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS WHERE INTERFACE_NAME_CD = 'UTIL' AND PARAMETER_NAME = 'PAD_CHAR'

-- TO UPDATE FILLER CHARACTER TO BE USED:  UPDATE IMAPSSTG.DBO.XX_PROCESSING_PARAMETERS SET PARAMETER_VALUE = '158' WHERE PARAMETER_NAME = 'PAD_CHAR'


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

DOING THIS PUTS A DASH (NEGATIVE CHAR) IN THE MIDDLE OF THE NUMBER... SO WE HAVE TO ADJUST:
WE USE A CASE STATEMENT, AND PUT THE GENERAL FORM INTO IT THREE TIMES

CASE CHARINDEX('-',
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(X,0),((COLUMN_NAME) * 100)) as varchar),X)
)WHEN 0 THEN 
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(X,0),((COLUMN_NAME) * 100)) as varchar),X)
ELSE '-' + REPLACE(
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(X,0),((COLUMN_NAME) * 100)) as varchar),X)
,'-','') END as TOT_AMT
*/

CREATE VIEW [dbo].[XX_SABRIX_INTERFACE_HDR_VW]
AS

select 
'          REVENUE SPREAD HEADER IMAPS' as filled_identification_i_loc,
SUBSTRING(convert(varchar,getDate(),120),3,2)+SUBSTRING(convert(varchar,getDate(),120),6,2)+SUBSTRING(convert(varchar,getDate(),120),9,2) as YYMMDD,
SUBSTRING(convert(varchar,getDate(),120),12,2)+SUBSTRING(convert(varchar,getDate(),120),15,2) as time,
--  NEGATIVE NUMBER FORMATTING NOT NECESSARY FOR A COUNT
RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(9,0),COUNT(*)) as varchar),9)as record_count,
'   ' as filler_02,

CASE CHARINDEX('-',
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(15,0),sum( case when POWER(0,CHARINDEX('-',REV))-1 = 0 then 1 else -1 end * cast(right(REV,LEN(REV)-CHARINDEX('-',REV)) as decimal(13,2)))) as varchar),15)
)WHEN 0 THEN 
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(15,0),sum( case when POWER(0,CHARINDEX('-',REV))-1 = 0 then 1 else -1 end * cast(right(REV,LEN(REV)-CHARINDEX('-',REV)) as decimal(13,2)))) as varchar),15)
ELSE '-' + REPLACE(
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(15,0),sum( case when POWER(0,CHARINDEX('-',REV))-1 = 0 then 1 else -1 end * cast(right(REV,LEN(REV)-CHARINDEX('-',REV)) as decimal(13,2)))) as varchar),15)
,'-','') END as REV,

--RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(15,0),sum( case when POWER(0,CHARINDEX('-',REV))-1 = 0 then 1 else -1 end * cast(right(REV,LEN(REV)-CHARINDEX('-',REV)) as decimal(11,2)))) as varchar),15) AS REV,
'000000000000000' AS COST,
'000000000000000' AS OPT_CR,
'000000000000000' AS VOL_DISC,
'000000000000000' AS ZONE_CHG,
'000000000000000' AS TIME_PRC_DIFF,

CASE CHARINDEX('-',
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(15,0),sum(case when POWER(0,CHARINDEX('-',statetax))-1 = 0 then 1 else -1 end * cast(right(statetax,LEN(statetax)-CHARINDEX('-',statetax)) as decimal(11,2)))) as varchar),15)
)WHEN 0 THEN 
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(15,0),sum(case when POWER(0,CHARINDEX('-',statetax))-1 = 0 then 1 else -1 end * cast(right(statetax,LEN(statetax)-CHARINDEX('-',statetax)) as decimal(11,2)))) as varchar),15)
ELSE '-' + REPLACE(
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(15,0),sum(case when POWER(0,CHARINDEX('-',statetax))-1 = 0 then 1 else -1 end * cast(right(statetax,LEN(statetax)-CHARINDEX('-',statetax)) as decimal(11,2)))) as varchar),15)
,'-','') END as STATE_TAX,

-- RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(15,0),sum(case when POWER(0,CHARINDEX('-',statetax))-1 = 0 then 1 else -1 end * cast(right(statetax,LEN(statetax)-CHARINDEX('-',statetax)) as decimal(11,2)))) as varchar),15) AS STATE_TAX,

CASE CHARINDEX('-',
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(15,0),sum(case when POWER(0,CHARINDEX('-',countytax))-1 = 0 then 1 else -1 end * cast(right(countytax,LEN(countytax)-CHARINDEX('-',countytax)) as decimal(11,2)))) as varchar),15)
)WHEN 0 THEN 
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(15,0),sum(case when POWER(0,CHARINDEX('-',countytax))-1 = 0 then 1 else -1 end * cast(right(countytax,LEN(countytax)-CHARINDEX('-',countytax)) as decimal(11,2)))) as varchar),15)
ELSE '-' + REPLACE(
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(15,0),sum(case when POWER(0,CHARINDEX('-',countytax))-1 = 0 then 1 else -1 end * cast(right(countytax,LEN(countytax)-CHARINDEX('-',countytax)) as decimal(11,2)))) as varchar),15)
,'-','') END as COUNTY_TAX,

-- RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(15,0),sum(case when POWER(0,CHARINDEX('-',countytax))-1 = 0 then 1 else -1 end * cast(right(countytax,LEN(countytax)-CHARINDEX('-',countytax)) as decimal(11,2)))) as varchar),15) AS COUNTY_TAX,

CASE CHARINDEX('-',
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(15,0),sum(case when POWER(0,CHARINDEX('-',citytax))-1 = 0 then 1 else -1 end * cast(right(citytax,LEN(citytax)-CHARINDEX('-',citytax)) as decimal(11,2)))) as varchar),15)
)WHEN 0 THEN 
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(15,0),sum(case when POWER(0,CHARINDEX('-',citytax))-1 = 0 then 1 else -1 end * cast(right(citytax,LEN(citytax)-CHARINDEX('-',citytax)) as decimal(11,2)))) as varchar),15)
ELSE '-' + REPLACE(
  RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(15,0),sum(case when POWER(0,CHARINDEX('-',citytax))-1 = 0 then 1 else -1 end * cast(right(citytax,LEN(citytax)-CHARINDEX('-',citytax)) as decimal(11,2)))) as varchar),15)
,'-','') END as CITY_TAX,

--RIGHT('00000000000000000'+ cast(CONVERT(DECIMAL(15,0),sum(case when POWER(0,CHARINDEX('-',citytax))-1 = 0 then 1 else -1 end * cast(right(citytax,LEN(citytax)-CHARINDEX('-',citytax)) as decimal(11,2)))) as varchar),15) AS CITY_TAX,
REPLICATE(CHAR(IMAPSSTG.DBO.XX_GET_PAD_UF()),104) AS SPACES
from imapsstg.dbo.xx_sabrix_interface_DTL_vw
-- filter removed per DR 10853
--where REV<>0




 

 

 

 

 

 

 

 

GO



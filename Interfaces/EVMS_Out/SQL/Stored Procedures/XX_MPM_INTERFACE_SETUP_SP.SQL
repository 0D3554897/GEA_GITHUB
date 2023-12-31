SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_MPM_INTERFACE_SETUP_SP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[XX_MPM_INTERFACE_SETUP_SP]
GO



CREATE PROCEDURE [dbo].[XX_MPM_INTERFACE_SETUP_SP] AS
BEGIN


/************************************************************************************************  
Name:       XX_MPM_INTERFACE_SETUP_SP 
Author:     	Tatiana Perova
Created:    	12/14/2005  
Purpose:    Create/update standard EOC and Resource mapping,  OBS and WBS  for MPM interface
Result Set: 	None  
Version: 	1.1
Notes:
Modified by:	Veera Veeramachanane 07/31/2006. Added new EOC mapping accounts provided by Sean
						 and approved by Emay based on CR30 COA changes 
						 Reference: Feature DEV00001080
		Veera Veeramachanane 12/07/2006. Commented out EOC Mapping Account SQL Script and added new DTS package 						 	 to create accounts and exclude any accounts through excel spreadsheet 
						 Reference: Feature DEV00001555, , Release V1.01 DEV00001672

**************************************************************************************************/  
BEGIN TRANSACTION EVMS_MAPPING

Delete FROM [IMAPS].[DELTEK].[X_MIC_MAP]
WHERE  [X_MAP_CD] = 'STDE'

 INSERT INTO [IMAPS].[DELTEK].[X_MIC_MAP]
([X_MAP_CD], [X_MAP_TYPE_CD], [X_MAP_DESC], 
[MODIFIED_BY], [TIME_STAMP], [X_RES_LABOR_CD], 
[X_RES_ODC_CD], [ROWVERSION], [COMPANY_ID])
VALUES('STDE', 'E', 'Standard EOC map','imapsstg',GETDATE(),
NULL, NULL, 0, 1)


-- Start commented out by Veera on 12/07/06 Feature: DEV00001555, Release V1.01 DEV00001672
/*
-- EOC mapping
/*
Delete FROM [IMAPS].[DELTEK].[X_MIC_EOCMAP]
WHERE  [X_EOCMAP_CD] = 'STDE'
*/
-- begin 03/23/2006 TP update of accounts
INSERT INTO [IMAPS].[DELTEK].[X_MIC_EOCMAP]
SELECT 'STDE' AS X_EOCMAP_CD,
a.ACCT_ID AS ACCT_ID, 
CASE LEFT(a.ACCT_ID,2)
	WHEN '41' THEN 'L'
	WHEN '42' THEN 'T'
	ELSE CASE LEFT(a.ACCT_ID,5)
		WHEN 'PA-60' THEN 'B'
		WHEN 'PA-61' THEN 'B'
		WHEN 'PA-62' THEN 'B'
		WHEN 'PA-63' THEN 'B'
		WHEN 'PA-64' THEN 'B'
		WHEN '43-03' THEN 'V'
		WHEN '43-04' THEN 'V'
		WHEN '43-06' THEN 'V'
		WHEN '43-07' THEN 'V'
		WHEN '43-13' THEN 'O'
		WHEN '43-14' THEN 'S'
		WHEN '43-15' THEN 'M'
		WHEN '43-16' THEN 'O'
		WHEN '43-17' THEN 'O'
		WHEN '43-18' THEN 'I'
		WHEN '43-19' THEN 'O'
		WHEN 'PA-70' THEN 'G'
		WHEN 'PA-71' THEN 'G'
		WHEN 'PA-72' THEN 'G'
		WHEN 'PA-73' THEN 'G'
		WHEN '43-83' THEN 'V'
		WHEN '43-84' THEN 'M'
		WHEN '43-85' THEN 'V'
		WHEN '43-86' THEN 'V'
		WHEN '43-87' THEN 'V'
		WHEN '43-88' THEN 'I'
		WHEN '43-93' THEN 'O'
		WHEN '43-94' THEN 'S'
		WHEN '43-95' THEN 'M'
		WHEN '43-96' THEN 'O'
		WHEN '43-97' THEN 'O'
		WHEN '43-98' THEN 'I'
-- Start Added by Veera on 07/31/06 Feature: DEV00001080
		WHEN '43-05' THEN 'V'
		WHEN '43-08' THEN 'I'
		WHEN '43-09' THEN 'V'
		WHEN '43-89' THEN 'V'
		WHEN '43-99' THEN 'O'
		WHEN 'PA-65' THEN 'B'
		WHEN 'PA-74' THEN 'G'
		WHEN 'PA-75' THEN 'G'
-- End Added by Veera on 07/31/06 Feature: DEV00001080
		END
	END AS X_EOC_CD  ,
'imapsstg' AS MODIFIED_BY,
GETDATE() AS TIME_STAMP,
0 AS ROWVERSION,
1 AS COMPANY_ID
FROM IMAPS.DELTEK.ACCT a  left join [IMAPS].[DELTEK].[X_MIC_EOCMAP] b ON a.ACCT_ID = b.ACCT_ID
WHERE (LEFT(a.ACCT_ID,2) IN ( '41', '42','43','PA') ) AND
a.ACTIVE_FL = 'Y'  AND
b.ACCT_ID is NULL
ORDER BY ACCT_ID
-- end 03/23/2006 TP 
*/
-- End commented out by Veera on 12/07/06 Feature: DEV00001555, Release V1.01 DEV00001672


--Resource mapping (by last name - STDR, by labor category/group -STDB)
Delete FROM [IMAPS].[DELTEK].[X_MIC_MAP]
WHERE  [X_MAP_CD] = 'STDR' or [X_MAP_CD] = 'STDB'

INSERT INTO [IMAPS].[DELTEK].[X_MIC_MAP]
([X_MAP_CD], [X_MAP_TYPE_CD], [X_MAP_DESC], 
[MODIFIED_BY], [TIME_STAMP], [X_RES_LABOR_CD], 
[X_RES_ODC_CD], [ROWVERSION], [COMPANY_ID])
VALUES('STDR', 'R', 'Std res map by name','imapsstg',GETDATE(),
'E', 'V', 0, 1)

INSERT INTO [IMAPS].[DELTEK].[X_MIC_MAP]
([X_MAP_CD], [X_MAP_TYPE_CD], [X_MAP_DESC], 
[MODIFIED_BY], [TIME_STAMP], [X_RES_LABOR_CD], 
[X_RES_ODC_CD], [ROWVERSION], [COMPANY_ID])
VALUES('STDB', 'R', 'Std res map by GLC','imapsstg',GETDATE(),
'E', 'V', 0, 1)

-- For STDB mapping data recreated each run
DELETE FROM [IMAPS].[DELTEK].[X_MIC_RESMAP]
WHERE  [X_RESMAP_CD] = 'STDB' and X_LINE_TYPE_CD = 'E'

-- mapping employees for  STDR
INSERT INTO [IMAPS].[DELTEK].[X_MIC_RESMAP]
([X_RESMAP_CD], [X_RES_CD], [MODIFIED_BY], [TIME_STAMP], 
[X_CP_VALUE_S], [X_LINE_TYPE_CD], [ROWVERSION], [COMPANY_ID])
SELECT 'STDR', LEFT(LAST_NAME,9) + LEFT(FIRST_NAME,1), 'imapsstg', GETDATE(), EMPL_ID, 'E',0,1
FROM IMAPS.DELTEK.EMPL a  left join [IMAPS].[DELTEK].[X_MIC_RESMAP] b
	 ON a.EMPL_ID =  b.X_CP_VALUE_S and b.X_LINE_TYPE_CD = 'E'
WHERE b.X_CP_VALUE_S is NULL 
ORDER BY LEFT(LAST_NAME,9) + LEFT(FIRST_NAME,1)

-- mapping employees for  STDB
INSERT INTO [IMAPS].[DELTEK].[X_MIC_RESMAP]
([X_RESMAP_CD], [X_RES_CD], [MODIFIED_BY], [TIME_STAMP], 
[X_CP_VALUE_S], [X_LINE_TYPE_CD], [ROWVERSION], [COMPANY_ID])
SELECT 'STDB',
ISNULL((select MPM_RESOURCE_CD from XX_MPM_RESORCE_CODE_MAPPING
where IMAPS_LABOR_GROUP =d.LAB_GRP_TYPE and IMAPS_GLC = d.GENL_LAB_CAT_CD),a.EMPL_ID + 'ERR'),
'imapsstg', GETDATE(), a.EMPL_ID, 'E',0,1
FROM IMAPS.DELTEK.EMPL a  left join 
	(SELECT c.EMPL_ID,b.LAB_GRP_TYPE,b.GENL_LAB_CAT_CD from IMAPS.Deltek.EMPL_LAB_INFO b
	inner join 
	(select EMPL_ID, MAX(EFFECT_DT) latest_DT
	from IMAPS.Deltek.EMPL_LAB_INFO
	GROUP BY EMPL_ID) c ON c.EMPL_ID = b.EMPL_ID and c.LATEST_DT = b.EFFECT_DT) d
	ON a.EMPL_ID = d.EMPL_ID
ORDER BY LEFT(LAST_NAME,9) + LEFT(FIRST_NAME,1)

-- mapping vendors  for  STDR
INSERT INTO [IMAPS].[DELTEK].[X_MIC_RESMAP]
([X_RESMAP_CD], [X_RES_CD], [MODIFIED_BY], [TIME_STAMP], 
[X_CP_VALUE_S], [X_LINE_TYPE_CD], [ROWVERSION], [COMPANY_ID])
SELECT 'STDR', LEFT(REPLACE(VEND_NAME,' ',''),10), 'imapsstg', GETDATE(), VEND_ID, 'V',0,1
FROM IMAPS.DELTEK.VEND a  left join
(select * from  [IMAPS].[DELTEK].[X_MIC_RESMAP]  WHERE   X_LINE_TYPE_CD = 'V' and  X_RESMAP_CD =  'STDR') b
	 ON a.VEND_ID =  b.X_CP_VALUE_S
WHERE b.X_CP_VALUE_S is NULL

-- mapping vendors  for  STDB
INSERT INTO [IMAPS].[DELTEK].[X_MIC_RESMAP]
([X_RESMAP_CD], [X_RES_CD], [MODIFIED_BY], [TIME_STAMP], 
[X_CP_VALUE_S], [X_LINE_TYPE_CD], [ROWVERSION], [COMPANY_ID])
SELECT 'STDB', LEFT(REPLACE(VEND_NAME,' ',''),10), 'imapsstg', GETDATE(), VEND_ID, 'V',0,1
FROM IMAPS.DELTEK.VEND a  left join 
(select * from  [IMAPS].[DELTEK].[X_MIC_RESMAP]  WHERE   X_LINE_TYPE_CD = 'V' and  X_RESMAP_CD =  'STDB') b
	 ON a.VEND_ID =  b.X_CP_VALUE_S 
WHERE b.X_CP_VALUE_S is NULL

-- Removal of last name (STDR)  resource mapping  duplicates
DECLARE @IMAPS_RES varchar(30),
@MPM_RES varchar(20), 
@LiNE_TYPE varchar(1),
@Counter int,
@PreviousValue varchar(30),
@CounterLen int

Set @Counter = 0

DECLARE  duplicates CURSOR FOR
SELECT b.X_RES_CD , b.X_CP_VALUE_S, b.X_LINE_TYPE_CD
FROM (SELECT [X_RES_CD], X_LINE_TYPE_CD
	FROM [IMAPS].[DELTEK].[X_MIC_RESMAP]
	WHERE X_RESMAP_CD = 'STDR'
	GROUP BY [X_RES_CD],X_LINE_TYPE_CD
	HAVING count(*) > 1 ) a 
	INNER JOIN  [IMAPS].[DELTEK].[X_MIC_RESMAP] b ON a.X_RES_CD = b.X_RES_CD 
ORDER BY b.X_RES_CD

OPEN duplicates
FETCH NEXT FROM duplicates INTO  @MPM_RES, @IMAPS_RES, @LiNE_TYPE
IF LEN(@MPM_RES) > 0 Set @PreviousValue = LEFT(@MPM_RES, LEN(@MPM_RES) - 1)
ELSE SET @PreviousValue = @MPM_RES
WHILE @@FETCH_STATUS = 0
BEGIN
	IF (LEN(@MPM_RES) > 0 and @PreviousValue =   LEFT(@MPM_RES, LEN(@MPM_RES) - 1)) or
	@PreviousValue = @MPM_RES
	BEGIN
		SET @Counter = @Counter + 1
	END
	ELSE
	BEGIN
		SET @Counter = 1
		IF LEN(@MPM_RES) > 0 Set @PreviousValue = LEFT(@MPM_RES, LEN(@MPM_RES) - 1)
		ELSE SET  @PreviousValue = @MPM_RES
	END
 
   IF @Counter < 10 Set @CounterLen = 1
   ELSE Set @CounterLen = 2
   
   IF LEN(ISNULL(@MPM_RES,'')) > 0
	UPDATE [IMAPS].[DELTEK].[X_MIC_RESMAP]
	SET X_RES_CD = LEFT(ISNULL(X_RES_CD,''), LEN(ISNULL(X_RES_CD,''))-@CounterLen) + LTRIM( CAST( @Counter AS varchar(2)))
	WHERE X_CP_VALUE_S =  @IMAPS_RES  and X_LINE_TYPE_CD = @LiNE_TYPE and ROWVERSION = 0
   ELSE
	UPDATE [IMAPS].[DELTEK].[X_MIC_RESMAP]
	SET X_RES_CD = LTRIM( CAST( @Counter AS varchar(2)))
	WHERE X_CP_VALUE_S =@IMAPS_RES  and X_LINE_TYPE_CD = @LiNE_TYPE  and ROWVERSION = 0

	FETCH NEXT FROM duplicates INTO  @MPM_RES, @IMAPS_RES, @LiNE_TYPE
END

CLOSE duplicates
DEALLOCATE duplicates

-- Validation for last name  resource mapping (STDR code)  duplicates
Print 'DUPLICATES FOUND in Resource mapping STDR:'

DECLARE  duplicates CURSOR FOR
SELECT b.X_RES_CD , b.X_CP_VALUE_S, b.X_LINE_TYPE_CD
FROM (SELECT [X_RES_CD], X_LINE_TYPE_CD
	FROM [IMAPS].[DELTEK].[X_MIC_RESMAP]
	WHERE X_RESMAP_CD = 'STDR'
	GROUP BY [X_RES_CD],X_LINE_TYPE_CD
	HAVING count(*) > 1 ) a 
	INNER JOIN  [IMAPS].[DELTEK].[X_MIC_RESMAP] b ON a.X_RES_CD = b.X_RES_CD 
ORDER BY b.X_RES_CD

OPEN duplicates
FETCH NEXT FROM duplicates INTO  @MPM_RES, @IMAPS_RES,@LiNE_TYPE
IF  @@FETCH_STATUS <> 0  BEGIN Print 'NONE' END
WHILE @@FETCH_STATUS = 0
BEGIN
    Print 'IMAPS: ' + @IMAPS_RES + ' MPM: ' +  @MPM_RES + ' Line Type: ' +  @LiNE_TYPE + ' Mapping code: STDR'
   FETCH NEXT FROM duplicates INTO  @MPM_RES, @IMAPS_RES,@LiNE_TYPE
END

CLOSE duplicates
DEALLOCATE duplicates

-- Work Breakdown  Structure Mapping
INSERT INTO [IMAPS].[DELTEK].[X_MIC_WBSMAP]
([X_CP_PROJ_ID], [X_MIC_WBS_ID], [X_NAME], 
[MODIFIED_BY], [TIME_STAMP], [ROWVERSION])
SELECT
PROJ_ID,  L1_PROJ_SEG_ID + 
CASE L2_PROJ_SEG_ID 
	WHEN NULL THEN ''
	WHEN '' THEN ''
	WHEN ' ' THEN ''
	ELSE '.' + L2_PROJ_SEG_ID 
END +
CASE L3_PROJ_SEG_ID
	WHEN NULL THEN ''
	WHEN '' THEN ''
	WHEN ' ' THEN ''	ELSE  '.' + L3_PROJ_SEG_ID 
END + 
CASE LVL_NO 
	WHEN 4 THEN (CASE L4_PROJ_SEG_ID 
		WHEN NULL THEN ''
		WHEN '' THEN ''
		WHEN ' ' THEN ''
		ELSE  '.' + L4_PROJ_SEG_ID 
		END)
	WHEN 5 THEN (CASE L5_PROJ_SEG_ID 
		WHEN NULL THEN ''
		WHEN '' THEN ''
		WHEN ' ' THEN ''
		ELSE  '.' + L5_PROJ_SEG_ID 
		END)
	WHEN 6 THEN (CASE L6_PROJ_SEG_ID 
		WHEN NULL THEN ''
		WHEN '' THEN ''
		WHEN ' ' THEN ''
		ELSE  '.' + L6_PROJ_SEG_ID 
		END)
	ELSE ''
END, /*
 L1_PROJ_SEG_ID +  L4_PROJ_SEG_ID , */
CASE
 	WHEN  LVL_NO > 4 THEN 'XX ' + LEFT(PROJ_NAME,22)
	ELSE LEFT(PROJ_NAME,25)
END, 
'imapsstg',GETDATE(),0
FROM [IMAPS].[DELTEK].[PROJ] left join [IMAPS].[DELTEK].[X_MIC_WBSMAP] ON PROJ_ID = X_CP_PROJ_ID
WHERE X_CP_PROJ_ID is NULL and LVL_NO > = 4 and LEFT(PROJ_ID,1) = 'D'

-- update for rows that were not manualy entered
UPDATE  [IMAPS].[DELTEK].[X_MIC_WBSMAP]
SET X_MIC_WBS_ID = (SELECT
 L1_PROJ_SEG_ID + 
CASE L2_PROJ_SEG_ID 
	WHEN NULL THEN ''	WHEN '' THEN ''	WHEN ' ' THEN ''
	ELSE '.' + L2_PROJ_SEG_ID 
END +
CASE L3_PROJ_SEG_ID
	WHEN NULL THEN ''
	WHEN '' THEN ''
	WHEN ' ' THEN ''	ELSE  '.' + L3_PROJ_SEG_ID 
END + 
CASE LVL_NO 
	WHEN 4 THEN (CASE L4_PROJ_SEG_ID 
		WHEN NULL THEN ''
		WHEN '' THEN ''
		WHEN ' ' THEN ''
		ELSE  '.' + L4_PROJ_SEG_ID 
		END)
	WHEN 5 THEN (CASE L5_PROJ_SEG_ID 
		WHEN NULL THEN ''
		WHEN '' THEN ''
		WHEN ' ' THEN ''
		ELSE  '.' + L5_PROJ_SEG_ID 
		END)
	WHEN 6 THEN (CASE L6_PROJ_SEG_ID 
		WHEN NULL THEN ''
		WHEN '' THEN ''
		WHEN ' ' THEN ''
		ELSE  '.' + L6_PROJ_SEG_ID 
		END)
	ELSE ''
END
FROM [IMAPS].[DELTEK].[PROJ] WHERE PROJ_ID = X_CP_PROJ_ID AND
LVL_NO > = 4 and LEFT(PROJ_ID,1) = 'D')
WHERE( X_MIC_WBS_ID is NULL or X_MIC_WBS_ID = '') and ROWVERSION = 0

--Validation for duplicates in WBS mapping
Print 'DUPLICATES FOUND in WBS mapping:'

DECLARE @IMAPS_WBS varchar(30),
 @MPM_WBS varchar(20)
DECLARE  duplicates CURSOR FOR
SELECT b.X_CP_PROJ_ID , b.X_MIC_WBS_ID
FROM (SELECT [X_MIC_WBS_ID]
	FROM [IMAPS].[DELTEK].[X_MIC_WBSMAP]
	GROUP BY [X_MIC_WBS_ID]
	HAVING count(*) > 1 ) a 
	INNER JOIN  [IMAPS].[DELTEK].[X_MIC_WBSMAP] b ON a.X_MIC_WBS_ID = b. X_MIC_WBS_ID 
ORDER BY b.X_CP_PROJ_ID

OPEN duplicates
FETCH NEXT FROM duplicates INTO @IMAPS_WBS, @MPM_WBS
IF  @@FETCH_STATUS <> 0  BEGIN Print 'NONE' END
WHILE @@FETCH_STATUS = 0
BEGIN
    Print 'IMAPS: ' + @IMAPS_WBS + ' MPM: ' +  @MPM_WBS
   FETCH NEXT FROM duplicates INTO @IMAPS_WBS, @MPM_WBS
END

CLOSE duplicates
DEALLOCATE duplicates

-- Organization Breakdown Structure Mapping
-- begin 03/23/2006 TP org structure is not used

INSERT INTO [IMAPS].[DELTEK].[X_MIC_OBSMAP]
([X_CP_ORG_ID], [X_MIC_OBS_ID], [X_NAME], 
[MODIFIED_BY], [TIME_STAMP], [ROWVERSION])
SELECT
[ORG_ID],'',LEFT([ORG_NAME],20), 
'IMAPSstg', GETDATE(), 0
FROM IMAPS.DELTEK.ORG left join [IMAPS].[DELTEK].[X_MIC_OBSMAP] ON ORG_ID = X_CP_ORG_ID
WHERE X_CP_ORG_ID is NULL 

/* old code to use org structure 
INSERT INTO [IMAPS].[DELTEK].[X_MIC_OBSMAP]
([X_CP_ORG_ID], [X_MIC_OBS_ID], [X_NAME], 
[MODIFIED_BY], [TIME_STAMP], [ROWVERSION])
SELECT
[ORG_ID], L2_ORG_SEG_ID + L3_ORG_SEG_ID + 
CASE L4_ORG_SEG_ID 
	WHEN NULL THEN ''
	WHEN '' THEN ''
	WHEN ' ' THEN ''
	ELSE '.' + L4_ORG_SEG_ID 
	END +
CASE L5_ORG_SEG_ID
	WHEN NULL THEN ''
	WHEN '' THEN ''
	WHEN ' ' THEN ''
	ELSE  '.' + L5_ORG_SEG_ID
	END, 
LEFT([ORG_NAME],20), 
'IMAPSstg', GETDATE(), 0
FROM IMAPS.DELTEK.ORG left join [IMAPS].[DELTEK].[X_MIC_OBSMAP] ON ORG_ID = X_CP_ORG_ID
WHERE X_CP_ORG_ID is NULL and ORG_ID <> L1_ORG_SEG_ID

UPDATE [IMAPS].[DELTEK].[X_MIC_OBSMAP]
SET X_MIC_OBS_ID =  (SELECT L2_ORG_SEG_ID + L3_ORG_SEG_ID + 
CASE L4_ORG_SEG_ID 
	WHEN NULL THEN ''
	WHEN '' THEN ''
	WHEN ' ' THEN ''	ELSE '.' + L4_ORG_SEG_ID 
	END +
CASE L5_ORG_SEG_ID
	WHEN NULL THEN ''
	WHEN '' THEN ''
	WHEN ' ' THEN ''
	ELSE  '.' + L5_ORG_SEG_ID
	END
FROM IMAPS.DELTEK.ORG WHERE ORG_ID = X_CP_ORG_ID)
WHERE (X_MIC_OBS_ID is NULL or X_MIC_OBS_ID = '') and ROWVERSION = 0

Print 'DUPLICATES FOUND in OBS mapping:'

DECLARE @IMAPS_OBS varchar(30),
 @MPM_OBS varchar(20)

DECLARE  duplicates CURSOR FOR
SELECT b.X_CP_ORG_ID , b.X_MIC_OBS_ID
FROM (SELECT [X_MIC_OBS_ID]
	FROM [IMAPS].[DELTEK].[X_MIC_OBSMAP]
	GROUP BY [X_MIC_OBS_ID]
	HAVING count(*) > 1 ) a 
	INNER JOIN  [IMAPS].[DELTEK].[X_MIC_OBSMAP] b ON a.X_MIC_OBS_ID = b. X_MIC_OBS_ID 
ORDER BY b.X_CP_ORG_ID

OPEN duplicates
FETCH NEXT FROM duplicates INTO @IMAPS_OBS, @MPM_OBS
IF  @@FETCH_STATUS <> 0  BEGIN Print 'NONE' END
WHILE @@FETCH_STATUS = 0
BEGIN
    Print 'IMAPS: ' + @IMAPS_OBS + ' MPM: ' +  @MPM_OBS
   FETCH NEXT FROM duplicates INTO @IMAPS_OBS, @MPM_OBS
END

CLOSE duplicates
DEALLOCATE duplicates
*/
-- end 03/23/2006 TP 
COMMIT TRANSACTION EVMS_MAPPING


END
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


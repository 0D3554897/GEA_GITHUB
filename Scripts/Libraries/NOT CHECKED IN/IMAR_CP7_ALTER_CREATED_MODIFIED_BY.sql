USE IMAPSSTG

/********************************************************************************************
*
* SCRIPT TO GENERATE ALTER COLUMN FOR TABLES THAT CONTAIN CREATED_BY AND MODIFIED_BY 
*
* GENERATE SCRIPT MUST BE USED INSTEAD OF STATIC SCRIPT BECAUSE CONSTRAINT NAMES VARY BY ENVIRONMENT
*
* STATEMENTS MUST BE PERFORMED IN THE CORRECT ORDER
*
* 1. DROP INDEXES
* 2. DROP DEFAULTS
* 3. ALTER TABLE COLUMNS
* 4. ADD DEFAULTS
* 5. ADD INDEXES
* 
*
* AUTHOR: GEORGE ALVAREZ
* DATE : 10/7/2019
*
**********************************************************************************************/

--USE THIS SELECT TO DOCUMENT BEFORE AND AFTER:
 SELECT LEN, TBL, COL
-- BE SURE TO CHANGE GROUP BY AND ORDER BY 

-- USE THIS SELECT TO GENERATE THE STATEMENTS
  --SELECT USE_ORDER, STMT
-- BE SURE TO CHANGE GROUP BY AND ORDER BY 

FROM (

-- USE IMAPSSTG
SELECT     0 AS USE_ORDER, NULL AS COL, NULL AS LEN, NULL AS TBL, NULL AS IDX, NULL AS DFLT, 'USE IMAPSSTG' AS STMT
UNION
SELECT     1 AS USE_ORDER, NULL AS COL, NULL AS LEN, NULL AS TBL, NULL AS IDX, NULL AS DFLT, 'GO' AS STMT
UNION
SELECT     2 AS USE_ORDER, NULL AS COL, NULL AS LEN, NULL AS TBL, NULL AS IDX, NULL AS DFLT, ' ' AS STMT

UNION

-- DROP INDEXES
SELECT      3 AS USE_ORDER,C.NAME AS COL, C.MAX_LENGTH AS LEN, T.NAME AS TBL, i.name as IDX, 
			object_definition(default_object_id) AS dflt,
			'DROP INDEX ' +
            I.name +
			' ON ' + T.NAME +';' AS STMT
FROM        sys.columns c
JOIN        sys.tables  t   ON c.object_id = t.object_id
JOIN		sys.index_columns ic  ON c.column_id = ic.column_id and c.object_id = ic.object_id
JOIN		sys.indexes i   ON ic.index_id = i.index_id and ic.object_id = i.object_id
WHERE       C.NAME IN ('CREATED_BY', 'MODIFIED_BY')
            AND (CHARINDEX('R22',T.NAME)>0
			OR CHARINDEX('IMAR',T.NAME)>0)

UNION

-- DROP DEFAULTS
SELECT      4 AS USE_ORDER,C.NAME AS THE_COLUMN, C.MAX_LENGTH AS LEN, T.NAME AS NOMBRE, I.NAME AS IDX,
			object_definition(default_object_id) AS dflt,
			'ALTER TABLE ' +
            t.name +
			' DROP CONSTRAINT ' + I.NAME + ';' AS STMT
FROM        sys.columns c
JOIN        sys.tables  t   ON c.object_id = t.object_id
JOIN        sys.default_constraints i  ON OBJECT_ID(T.NAME) = I.PARENT_OBJECT_ID
WHERE       C.NAME IN ('CREATED_BY', 'MODIFIED_BY') --c.name LIKE '%CREATED_BY%'
			AND C.COLUMN_ID = I. PARENT_COLUMN_ID
            AND (CHARINDEX('R22',T.NAME)>0
			OR CHARINDEX('IMAR',T.NAME)>0)
			AND C.OBJECT_ID = OBJECT_ID(T.NAME)

UNION

-- ALTER TABLES
SELECT      5 AS USE_ORDER,C.NAME AS THE_COLUMN, C.MAX_LENGTH AS LEN, T.NAME AS NOMBRE, 'PLACEHOLDER FOR IDX',
			object_definition(default_object_id) AS dflt,
			'ALTER TABLE ' +
            t.name +
			' ALTER COLUMN ' + C.NAME + ' SYSNAME NULL;' AS STMT
FROM        sys.columns c
JOIN        sys.tables  t   ON c.object_id = t.object_id
WHERE        C.NAME IN ('CREATED_BY', 'MODIFIED_BY')
            AND (CHARINDEX('R22',T.NAME)>0
			OR CHARINDEX('IMAR',T.NAME)>0)

UNION

-- ADD DEFAULTS
SELECT      6 AS USE_ORDER,C.NAME AS THE_COLUMN, C.MAX_LENGTH AS LEN, T.NAME AS NOMBRE, I.NAME AS IDX,
			object_definition(default_object_id) AS dflt,
			'ALTER TABLE ' +
            t.name +
			' ADD CONSTRAINT ' + I.NAME + ' DEFAULT(' +
			object_definition(default_object_id) + ') FOR ' + C.NAME + ';' AS STMT
FROM        sys.columns c
JOIN        sys.tables  t   ON c.object_id = t.object_id
JOIN        sys.default_constraints i  ON OBJECT_ID(T.NAME) = I.PARENT_OBJECT_ID
WHERE       C.NAME IN ('CREATED_BY', 'MODIFIED_BY') --c.name LIKE '%CREATED_BY%'
			AND C.COLUMN_ID = I. PARENT_COLUMN_ID
            AND (CHARINDEX('R22',T.NAME)>0
			OR CHARINDEX('IMAR',T.NAME)>0)
			AND C.OBJECT_ID = OBJECT_ID(T.NAME)

/*******************************
UNION

-- CREATE INDEXES
SELECT      7 AS USE_ORDER,C.NAME AS THE_COLUMN, C.MAX_LENGTH AS LEN, T.NAME AS NOMBRE, i.name as IDX_NAME, 
			object_definition(default_object_id) AS dflt,
			'CREATE NONCLUSTERED INDEX ' +
            I.name + ' ON ' + T.NAME +' ( ' +
			C.NAME + ' ASC )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF,' +
			'ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY];'	AS STMT
FROM        sys.columns c
JOIN        sys.tables  t   ON c.object_id = t.object_id
JOIN		sys.index_columns ic  ON c.column_id = ic.column_id and c.object_id = ic.object_id
JOIN		sys.indexes i   ON ic.index_id = i.index_id and ic.object_id = i.object_id
WHERE       C.NAME IN ('CREATED_BY', 'MODIFIED_BY')
            AND (CHARINDEX('R22',T.NAME)>0
			OR CHARINDEX('IMAR',T.NAME)>0)
***********************************/

UNION
SELECT     8 AS USE_ORDER, NULL AS COL, NULL AS LEN, NULL AS TBL, NULL AS IDX, NULL AS DFLT, ' ' AS STMT
UNION
SELECT     9 AS USE_ORDER, NULL AS COL, NULL AS LEN, NULL AS TBL, NULL AS IDX, NULL AS DFLT, 'GO' AS STMT

) X
-- FOR BEFORE AND AFTER
 WHERE USE_ORDER = 5
 ORDER BY TBL

-- FOR SCRIPT GENERATION
--GROUP BY STMT, USE_ORDER
--ORDER BY USE_ORDER, STMT
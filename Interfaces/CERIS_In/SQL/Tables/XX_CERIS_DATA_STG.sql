USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_DATA_STG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_CERIS_DATA_STG]
GO

CREATE TABLE [dbo].[XX_CERIS_DATA_STG](

		REC_TYPE           CHAR(01) NOT NULL,      -- /*RECORD TYPE          1-   1 */| 'D'                                                     
		SERIAL             CHAR(06) NOT NULL,      -- /*EMPLOYEE SERIAL      2-   7 */| BY NAME                                                 
		HIRE_DATE_EFF      CHAR(08) NOT NULL,      -- /*HIRE EFF DATE        8-  15 */| BY NAME                                                 
		HIRE_DATE_SRD      CHAR(08) NOT NULL,      -- /*HIRE/SERV REF DTE   16-  23 */| BY NAME                                                 
		SEP_DATE           CHAR(08) NOT NULL,      -- /*SEPARATION DATE     24-  31 */| BY NAME                                                 
		DEPT_MGR_SER_1     CHAR(06) NOT NULL,      -- /*MANAGER 1  SERIAL   32-  37 */| BY NAME                                                 
		DEPT_MGR_NAME_LAST CHAR(30) NOT NULL,      -- /*MANAGER 1  NAME     38-  67 */| SUBSTR(EMP.DEPT_MGR_NAME_1,3,30)                        
		DEPT_MGR_NAME_INIT CHAR(02) NOT NULL,      -- /*MANAGER 1  NAME     68-  69 */| SUBSTR(EMP.DEPT_MGR_NAME_1,1,2)                         
		JOB_FAMILY_1       CHAR(03) NOT NULL,      -- /*JOB FAMILY 1ST      70-  72 */| BY NAME                                                 
		JOB_FAMILY_DATE_1  CHAR(08) NOT NULL,      -- /*JOB FAMILY DTE 1    73-  80 */| BY NAME                                                 
		LEVEL_PREFIX_1     CHAR(02) NOT NULL,      -- /*LEVEL PREFIX 1      81-  82 */| BY NAME                                                 
		LEVEL_SUFFIX_1     CHAR(01) NOT NULL,      -- /*LEVEL SUFFIX 1      83-  83 */| BY NAME                                                 
		LVL_DATE_1         CHAR(08) NOT NULL,      -- /*DATE ENTERED LVL1   84-  91 */| BY NAME                                                 
		DIVISION_1         CHAR(02) NOT NULL,      -- /*DIVISION  1         92-  93 */| BY NAME                                                 
		DIVISION_2         CHAR(02) NOT NULL,      -- /*DIVISION  2         94-  95 */| BY NAME                                                 
		DIV_DATE           CHAR(08) NOT NULL,      -- /*DATE ENTERED DIV    96- 103 */| BY NAME                                                 
		DEPT_PLUS_SFX      CHAR(04) NOT NULL,      -- /*DEPT||SXF          104- 107 */| EMP.DEPT_OFF_NUM_1 || EMP.DEPT_SUF_1                   
		DEPT_DATE          CHAR(08) NOT NULL,      -- /*DEPT NUMBER DATE   108- 115 */| BY NAME                                                
		DEPT_SUF_DATE      CHAR(08) NOT NULL,      -- /*DTE ENT DEPT SUFF  116- 123 */| BY NAME                                                
		EX_NE_OUT          CHAR(01) NOT NULL,      -- /*EXMPT/NONEX INDIC  124- 124 */| BY NAME 

--char(06) or char(08) ??                                               
		EXEMPT_DATE        CHAR(08) NOT NULL,      -- /*EXEMPT-DTE ENT     125- 130 */| BY NAME   
                                             
		POS_CODE_1         CHAR(04) NOT NULL,      -- /*POSITION  CODE 1   131- 134 */| BY NAME                                                
		JOB_TITLE          CHAR(30) NOT NULL,      -- /*POSITION TITLE     135- 164 */| BY NAME                                                
		POS_DATE_1         CHAR(08) NOT NULL,      -- /*POS CODE ENTR 1    165- 172 */| BY NAME                                                
		EMPL_STAT_1ST      CHAR(01) NOT NULL,      -- /*EMPL STAT CODE 1   173- 173 */| BY NAME                                                
		EMPL_STAT_3RD      CHAR(01) NOT NULL,      -- /*EMPL STAT CODE 3   174- 174 */| BY NAME                                                
		EMPL_STAT3_DATE    CHAR(08) NOT NULL,      -- /*EMPL STAT DATE 3   175- 182 */| BY NAME                                                
		EMPL_STAT_2ND      CHAR(01) NOT NULL,      -- /*EMPL STAT CODE 2   183- 183 */| BY NAME                                                
		EMPL_STAT_DATE     CHAR(08) NOT NULL,      -- /*EMP STATUS DATE    184- 191 */| BY NAME                                                
		WORK_SCHD          CHAR(05) NOT NULL,	--PIC '99V.99'    -- /*SCHED WORK HOURS   192- 196 */| BY NAME                                                
		WORK_SCHD_DATE     CHAR(08) NOT NULL,      -- /*WORK SCHD DATE     197- 204 */| BY NAME                                                
		SET_ID             CHAR(02) NOT NULL,      -- /*SET ID             205- 206 */| BY NAME                                                
		LOC_WORK_1         CHAR(03) NOT NULL,      -- /*WORK LOC CODE 1    207- 209 */| BY NAME                                                
		LOC_WORK_ST        CHAR(02) NOT NULL,      -- /*WORK LOCN STATE    210- 211 */| BY NAME                                                
		LOC_WORK_DTE_1     CHAR(08) NOT NULL,      -- /*WORK LOC CD 1 DTE  212- 219 */| BY NAME                                                
		TBWKL_CITY         CHAR(24) NOT NULL,      -- /*Work Location City 220- 243 */| "WHERE TB15.LOC_WORK = EMP.LOC_WORK_1"                 
		SALARY             CHAR(10) NOT NULL,	--PIC '(7)9V.99', -- /*SALARY AMOUNT      244- 253 */| exec logic used 
		SAL_CHG_DTE_1      CHAR(08) NOT NULL,      -- /*SAL CHG DATE 1     254- 261 */| BY NAME  
		SAL_RTE_CDE        CHAR(01) NOT NULL,      -- /*SALARY RATE CODE   262- 262 */| BY NAME                                                
		SAL_BASE           CHAR(10) NOT NULL,	--PIC '(7)9V.99', -- /*BASE SALARY AMT    263- 272 */| 0 if exec            
		SAL_MO_OUT         CHAR(10) NOT NULL,	--PIC '(07)9V.99',-- /*MONTHLY SALARY     273- 282 */| 0 if exec             
		NAME_LAST_MIXED    CHAR(50) NOT NULL,      -- /*EMFG LAST NME MIX  283- 332 */| BY NAME                                                
		NAME_FIRST_MIXED   CHAR(50) NOT NULL,      -- /*EMFG 1ST NAME MIX  333- 382 */| BY NAME                                                
		NAME_INIT          CHAR(03) NOT NULL,      -- /*EMPLOY INITS       383- 385 */| BY NAME                                                
		--ENDPAD             CHAR(65) NOT NULL,      -- /*END FILLER         386- 450 */| blanks              

	[CREATION_DATE] [datetime] NOT NULL DEFAULT getdate(),
	[CREATED_BY] [varchar](35) NOT NULL DEFAULT suser_sname()

) ON [PRIMARY]

GO
SET ANSI_PADDING OFF


/*

--test setup


insert into xx_ceris_data_stg
(
REC_TYPE,
SERIAL,
HIRE_DATE_EFF,
HIRE_DATE_SRD,
SEP_DATE,
DEPT_MGR_SER_1,
DEPT_MGR_NAME_LAST,
DEPT_MGR_NAME_INIT,
JOB_FAMILY_1,
JOB_FAMILY_DATE_1,
LEVEL_PREFIX_1,
LEVEL_SUFFIX_1,
LVL_DATE_1,
DIVISION_1,
DIVISION_2,
DIV_DATE,
DEPT_PLUS_SFX,
DEPT_DATE,
DEPT_SUF_DATE,
EX_NE_OUT,
EXEMPT_DATE,
POS_CODE_1,
JOB_TITLE,
POS_DATE_1,
EMPL_STAT_1ST,
EMPL_STAT_3RD,
EMPL_STAT3_DATE,
EMPL_STAT_2ND,
EMPL_STAT_DATE,
WORK_SCHD,
WORK_SCHD_DATE,
SET_ID,
LOC_WORK_1,
LOC_WORK_ST,
LOC_WORK_DTE_1,
TBWKL_CITY,
SALARY,
SAL_CHG_DTE_1,
SAL_RTE_CDE,
SAL_BASE,
SAL_MO_OUT,
NAME_LAST_MIXED,
NAME_FIRST_MIXED,
NAME_INIT,
CREATION_DATE,
CREATED_BY)
select 
'D' as REC_TYPE,
empl_id as SERIAL, 
isnull(HIRE_EFF_DT,'') as HIRE_DATE_EFF, 
isnull(IBM_START_DT,'') as HIRE_DATE_SRD, 
isnull(term_dt,'') as SEP_DATE, 
left(MGR_SERIAL_NUM,6) as DEPT_MGR_SER_1, 
MGR_LNAME as DEPT_MGR_NAME_LAST, 
left(MGR_INITIALS,2) as DEPT_MGR_NAME_INIT, 
JOB_FAM as JOB_FAMILY_1, 
JOB_FAM_DT as JOB_FAMILY_DATE_1, 
SAL_BAND as LEVEL_PREFIX_1, 
LVL_SUFFIX as LEVEL_SUFFIX_1, 
isnull(LVL_DT_1,'') as LVL_DATE_1, 
DIVISION as DIVISION_1, 
DIVISION_FROM as DIVISION_2, 
DIVISION_START_DT as DIV_DATE, 
left(DEPT,4) as DEPT_PLUS_SFX, 
isnull(DEPT_START_DT,'') as DEPT_DATE, 
isnull(DEPT_SUF_DT,'') as DEPT_SUF_DATE, 
left(FLSA_STAT,1) as EX_NE_OUT, 
isnull(EXEMPT_DT,'') as EXEMPT_DATE,
POS_CODE as POS_CODE_1, 
POS_DESC as JOB_TITLE, 
isnull(POS_DT,'') as POS_DATE_1,
REG_TEMP as EMPL_STAT_1ST, 
STAT3 as EMPL_STAT_3RD, 
isnull(EMPL_STAT3_DT,'') as EMPL_STAT3_DATE, 
left(STATUS,1) as EMPL_STAT_2ND, 
EMPL_STAT_DT as EMPL_STAT_DATE,
cast(STD_HRS as varchar) as WORK_SCHD, 
WORK_SCHD_DT as WORK_SCHD_DATE, 
SALSETID as SET_ID, 
WKLNEW as LOC_WORK_1, 
WKLST as LOC_WORK_ST, 
isnull(WKL_DT,'') as LOC_WORK_DTE_1, 
WKLCITY as TBWKL_CITY, 
cast(SALARY as varchar) as SALARY, 
isnull(salary_dt,'') as SAL_CHG_DTE_1, 
salary_rte_cd as SAL_RTE_CDE, 
cast(salbase as varchar) as SAL_BASE, 
cast(salmo as varchar) as SAL_MO_OUT, 
lname as NAME_LAST_MIXED, 
fname as NAME_FIRST_MIXED, 
name_initials as NAME_INIT, 
getdate() as CREATION_DATE,
suser_sname() as CREATED_BY
from km_ceris_data_stg_20120801


truncate table XX_CERIS_DATA_STG

insert into XX_CERIS_DATA_STG
(
REC_TYPE,
SERIAL,
HIRE_DATE_EFF,
HIRE_DATE_SRD,
SEP_DATE,
DEPT_MGR_SER_1,
DEPT_MGR_NAME_LAST,
DEPT_MGR_NAME_INIT,
JOB_FAMILY_1,
JOB_FAMILY_DATE_1,
LEVEL_PREFIX_1,
LEVEL_SUFFIX_1,
LVL_DATE_1,
DIVISION_1,
DIVISION_2,
DIV_DATE,
DEPT_PLUS_SFX,
DEPT_DATE,
DEPT_SUF_DATE,
EX_NE_OUT,
EXEMPT_DATE,
POS_CODE_1,
JOB_TITLE,
POS_DATE_1,
EMPL_STAT_1ST,
EMPL_STAT_3RD,
EMPL_STAT3_DATE,
EMPL_STAT_2ND,
EMPL_STAT_DATE,
WORK_SCHD,
WORK_SCHD_DATE,
SET_ID,
LOC_WORK_1,
LOC_WORK_ST,
LOC_WORK_DTE_1,
TBWKL_CITY,
SALARY,
SAL_CHG_DTE_1,
SAL_RTE_CDE,
SAL_BASE,
SAL_MO_OUT,
NAME_LAST_MIXED,
NAME_FIRST_MIXED,
NAME_INIT,
CREATION_DATE,
CREATED_BY)
select 
'D' as REC_TYPE,
EMPLID as SERIAL, 
isnull(replace(convert(char(10),HIRE_DATE_EFF,120),'-',''),'') as HIRE_DATE_EFF, 
isnull(replace(convert(char(10),IBM_START_DT,120),'-',''),'') as HIRE_DATE_SRD, 
isnull(replace(convert(char(10),TERM_DT,120),'-',''),'') as SEP_DATE,
left(MGR_SERIAL_NUM,6) as DEPT_MGR_SER_1, 
MGR_LNAME as DEPT_MGR_NAME_LAST, 
MGR_INITIAL as DEPT_MGR_NAME_INIT, 
JOB_FAMILY as JOB_FAMILY_1,
isnull(replace(convert(char(10),JF_DT,120),'-',''),'') as JOB_FAMILY_DATE_1,
SAL_BAND as LEVEL_PREFIX_1, 
LEVEL_SUFFIX as LEVEL_SUFFIX_1,
isnull(replace(convert(char(10),LVL_DATE_1,120),'-',''),'') as LVL_DATE_1,
DIVISION as DIVISION_1, isnull(DIVISION_FROM,'') as DIVISION_2,
isnull(replace(convert(char(10),DIVISION_STRT_DATE,120),'-',''),'') as DIV_DATE,
DEPT as DEPT_PLUS_SFX,
isnull(replace(convert(char(10),DEPT_ST_DATE,120),'-',''),'') as DEPT_DATE,
isnull(replace(convert(char(10),DEPT_SUF_DATE,120),'-',''),'') as DEPT_SUF_DATE,
left(FLSA_STAT,1) as EX_NE_OUT, 
isnull(replace(convert(char(10),EXEMPT_DATE,120),'-',''),'') as EXEMPT_DATE,
POS_CODE as POS_CODE_1, POS_DESC as JOB_TITLE, 
isnull(replace(convert(char(10),POS_DT,120),'-',''),'') as POS_DATE_1,
REG_TEMP as EMPL_STAT_1ST, isnull(STAT3,'') as EMPL_STAT_3RD, 
isnull(replace(convert(char(10),EMPL_STAT3_DATE,120),'-',''),'') as EMPL_STAT3_DATE,
STATUS as EMPL_STAT_2ND,
isnull(replace(convert(char(10),EMPL_STAT_DATE,120),'-',''),'') as EMPL_STAT_DATE,
cast(STD_HRS as varchar) as WORK_SCHD, 
isnull(replace(convert(char(10),WORK_SCHD_DATE,120),'-',''),'') as WORK_SCHD_DATE,
isnull(SALESTID,'') as SET_ID, WKLNEW as LOC_WORK_1, WKLST as LOC_WORK_ST, 
isnull(replace(convert(char(10),HIRE_DATE_EFF,120),'-',''),'') as LOC_WORK_DTE_1, 
 WKLYCITY as TBWKL_CITY,
'4000.00' as SALARY,
isnull(replace(convert(char(10),EMPL_STAT3_DATE,120),'-',''),'') as SAL_CHG_DTE_1,
'?' as SALARY_RTE_CD,
'4000.00' as SALBASE,
'4000.00' as SALMO,

LNAME, FNAME, isnull(NAME_INIT,''), 
current_timestamp as CREATION_DATE,
suser_sname() as CREATED_BY

from ETIME_RPT..CFRPTADM.IBM_CERIS


--daily
update XX_CERIS_DATA_STG
set SALARY='400'
where EMPL_STAT_1ST='3' and EX_NE_OUT='E' and isnull(EMPL_STAT_3RD,'')<>'2' --daily 

--houly
update XX_CERIS_DATA_STG
set SALARY='40'
where EMPL_STAT_1ST='3' and EX_NE_OUT='N' and isnull(EMPL_STAT_3RD,'')<>'2' --hourly


select top 10 *
from XX_CERIS_DATA_STG

*/



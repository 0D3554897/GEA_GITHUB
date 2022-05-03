USE [IMAPSStg]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_CERIS_DATA_STG_ARCH]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_CERIS_DATA_STG_ARCH]
GO

CREATE TABLE [dbo].[XX_CERIS_DATA_STG_ARCH](

	[STATUS_RECORD_NUM] int NOT NULL,

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


	[CREATION_DATE] [datetime] NOT NULL,
	[CREATED_BY] [varchar](35) NOT NULL,


	[ARCHIVE_DATE] [datetime] NOT NULL DEFAULT getdate(),
	[ARCHIVED_BY] [varchar](35) NOT NULL DEFAULT suser_sname()
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF





use imapsstg

/*
XX_CERIS_HIST changes
*/

--LVL_SUFFIX
alter table dbo.xx_ceris_hist
add LVL_SUFFIX varchar(2) NULL
GO
alter table dbo.xx_ceris_hist_archival
add LVL_SUFFIX varchar(2) NULL
GO
--DIVISION_FROM
alter table dbo.xx_ceris_hist
add DIVISION_FROM varchar (2) NULL
GO
alter table dbo.xx_ceris_hist_archival
add DIVISION_FROM varchar (2) NULL
GO
--SALARY
alter table dbo.xx_ceris_hist
add SALARY decimal(15, 2) NULL
GO
alter table dbo.xx_ceris_hist_archival
add SALARY decimal(15, 2) NULL
GO
--SALARY_RTE_CD
alter table dbo.xx_ceris_hist
add SALARY_RTE_CD varchar (3) NULL
GO
alter table dbo.xx_ceris_hist_archival
add SALARY_RTE_CD varchar (3) NULL
GO
--SALARY_DT
alter table dbo.xx_ceris_hist
add SALARY_DT smalldatetime NULL
GO
alter table dbo.xx_ceris_hist_archival
add SALARY_DT smalldatetime NULL
GO
--WKL_DT
alter table dbo.xx_ceris_hist
add WKL_DT smalldatetime NULL
GO
alter table dbo.xx_ceris_hist_archival
add WKL_DT smalldatetime NULL
GO


/*
XX_CERIS_CP_STG changes
*/
alter table dbo.xx_ceris_cp_stg
add WKL_DT smalldatetime NULL
GO
alter table dbo.xx_ceris_cp_stg
add SALARY_DT smalldatetime NULL
GO
alter table dbo.xx_ceris_cp_stg
add LCDB_GLC_EFFECTIVE_DT smalldatetime NULL
GO
/* already exists
alter table dbo.xx_ceris_cp_stg
add S_EMPL_TYPE_CD char(1) NULL
GO
*/
alter table dbo.xx_ceris_cp_stg
add S_HRLY_SAL_CD char(1) NULL
GO
alter table dbo.xx_ceris_cp_stg
add WORK_STATE_CD varchar(2) NULL
GO
alter table dbo.xx_ceris_cp_stg
add REASON_DESC_3 varchar(30) NULL
GO


/*
XX_CERIS_EMPL_LAB_STG changes
*/
/* already exists
alter table dbo.xx_ceris_empl_lab_stg
add S_EMPL_TYPE_CD char(1) NULL
GO
*/
alter table dbo.xx_ceris_cp_empl_lab_stg
add S_HRLY_SAL_CD char(1) NULL
GO
alter table dbo.xx_ceris_cp_empl_lab_stg
add WORK_STATE_CD varchar(2) NULL
GO
alter table dbo.xx_ceris_cp_empl_lab_stg
add REASON_DESC_3 varchar(30) NULL
GO


/*
XX_CERIS_RETRO_TS changes
*/
alter table dbo.xx_ceris_retro_ts
add NEW_HRLY_AMT decimal(10, 4) NULL
GO
alter table dbo.xx_ceris_retro_ts
add NEW_EXMPT_FL char(1) NULL
GO
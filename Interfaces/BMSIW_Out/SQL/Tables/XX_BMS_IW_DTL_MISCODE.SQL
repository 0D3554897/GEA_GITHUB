

if exists (select * from dbo.sysobjects where id = object_id(N'[XX_BMS_IW_DTL_MISCODE]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_BMS_IW_DTL_MISCODE]
GO

CREATE TABLE dbo.XX_BMS_IW_DTL_MISCODE
(
    RECORD_TYPE      char(1)  NOT NULL,
    EMP_SER_NUM      char(6)  NOT NULL,
    CTRY_CD          char(3)  NOT NULL,
    CMPNY_CD         char(8)  NOT NULL,
    TOT_CLMED_HRS    char(7)  NOT NULL,
    ACCT_TYP_CD      char(1)  NOT NULL,
    TRVL_INDICATOR   char(1)  NOT NULL,
    CLM_WK_ENDING_DT char(10) NOT NULL,
    OVRTM_HRS_IND    char(1)  NOT NULL,
    OWNG_LOB_CD      char(3)  NOT NULL,
    OWNG_CNTRY_CD    char(3)  NOT NULL,
    OWNG_CMPNY_CD    char(8)  NOT NULL,
    LBR_SYS_CD       char(8)  NOT NULL,
    CHRG_ACCT_ID     char(8)  NOT NULL,
    CHRG_ACTV_CD     char(6)  NOT NULL,
    FILLER           char(6)  NOT NULL
)
go
IF OBJECT_ID('dbo.XX_BMS_IW_DTL_MISCODE') IS NOT NULL
    PRINT '<<< CREATED TABLE dbo.XX_BMS_IW_DTL_MISCODE >>>'
ELSE
    PRINT '<<< FAILED CREATING TABLE dbo.XX_BMS_IW_DTL_MISCODE >>>'
go

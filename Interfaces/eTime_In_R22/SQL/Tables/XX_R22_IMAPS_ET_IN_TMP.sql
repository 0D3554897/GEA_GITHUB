CREATE TABLE dbo.XX_R22_IMAPS_ET_IN_TMP
(
    EMP_SERIAL_NUM  char(6) NOT NULL,
    TS_YEAR         char(4) NOT NULL,
    TS_MONTH        char(2) NOT NULL,
    TS_DAY          char(2) NOT NULL,
    PROJ_ABBR       char(6) NOT NULL,
    SAT_REG_TIME    char(6) NULL,
    SAT_OVERTIME    char(6) NULL,
    SUN_REG_TIME    char(6) NULL,
    SUN_OVERTIME    char(6) NULL,
    MON_REG_TIME    char(6) NULL,
    MON_OVERTIME    char(6) NULL,
    TUE_REG_TIME    char(6) NULL,
    TUE_OVERTIME    char(6) NULL,
    WED_REG_TIME    char(6) NULL,
    WED_OVERTIME    char(6) NULL,
    THU_REG_TIME    char(6) NULL,
    THU_OVERTIME    char(6) NULL,
    FRI_REG_TIME    char(6) NULL,
    FRI_OVERTIME    char(6) NULL,
    PLC             char(6) NULL,
    RECORD_TYPE     char(1) NULL,
    AMENDMENT_NUM   char(2) NOT NULL,
    ILC_ACTIVITY_CD char(6) NULL,
    PAY_TYPE        char(3) NULL
)
go
IF OBJECT_ID('dbo.XX_R22_IMAPS_ET_IN_TMP') IS NOT NULL
    PRINT '<<< CREATED TABLE dbo.XX_R22_IMAPS_ET_IN_TMP >>>'
ELSE
    PRINT '<<< FAILED CREATING TABLE dbo.XX_R22_IMAPS_ET_IN_TMP >>>'
go

CREATE TABLE dbo.XX_DDC_PREPTBL
(
    TS_DT             smalldatetime NULL,
    EMPL_ID           varchar(12)   NULL,
    S_TS_TYPE_CD      varchar(2)    NULL,
    TS_HDR_SEQ_NO     smallint      NULL,
    CORRECTING_REF_DT smalldatetime NULL,
    AUTOADJ_RT        decimal(10,8) NULL,
    COL_ID_NO         smallint      NULL
)
go
IF OBJECT_ID('dbo.XX_DDC_PREPTBL') IS NOT NULL
    PRINT '<<< CREATED TABLE dbo.XX_DDC_PREPTBL >>>'
ELSE
    PRINT '<<< FAILED CREATING TABLE dbo.XX_DDC_PREPTBL >>>'
go

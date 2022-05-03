CREATE TABLE dbo.XX_DDC_TS_AUTO_ADJUST_ERRORS
(
    EMPL_ID            varchar(12)   NULL,
    TS_DT              smalldatetime NULL,
    S_TS_TYPE_CD       varchar(2)    NULL,
    TS_HDR_SEQ_NO      smallint      NULL,
    CORRRECTING_REF_DT smalldatetime NULL,
    ERROR_MSG          varchar(254)  NULL
)
go
IF OBJECT_ID('dbo.XX_DDC_TS_AUTO_ADJUST_ERRORS') IS NOT NULL
    PRINT '<<< CREATED TABLE dbo.XX_DDC_TS_AUTO_ADJUST_ERRORS >>>'
ELSE
    PRINT '<<< FAILED CREATING TABLE dbo.XX_DDC_TS_AUTO_ADJUST_ERRORS >>>'
go

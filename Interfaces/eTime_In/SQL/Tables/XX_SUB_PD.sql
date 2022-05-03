--Added CR-4886
--Actuals implementation
CREATE TABLE dbo.XX_SUB_PD
(
    FY_CD           varchar(6)    NOT NULL,
    PD_NO           smallint      NOT NULL,
    SUB_PD_NO       smallint      NULL,
    TS_DT           smalldatetime NULL,
    SUB_PD_BEGIN_DT smalldatetime NULL,
    SUB_PD_END_DT   smalldatetime NOT NULL,
    S_STATUS_CD     varchar(1)    NOT NULL,
    MODIFIED_BY     varchar(20)   NOT NULL,
    TIME_STAMP      datetime      NOT NULL,
    ROWVERSION      int           NULL,
    ROWID           int           IDENTITY,
    SPLIT_VAL       int           NULL,
    SPLIT_PER       int           NULL
)

go
IF OBJECT_ID('dbo.XX_SUB_PD') IS NOT NULL
    PRINT '<<< CREATED TABLE dbo.XX_SUB_PD >>>'
ELSE
    PRINT '<<< FAILED CREATING TABLE dbo.XX_SUB_PD >>>'
go

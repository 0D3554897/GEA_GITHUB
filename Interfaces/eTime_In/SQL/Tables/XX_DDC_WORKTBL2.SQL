CREATE TABLE dbo.XX_DDC_WORKTBL2
(
    EMPL_ID         varchar(12)   NULL,
    TS_DT           smalldatetime NULL,
    S_TS_TYPE_CD    varchar(2)    NULL,
    TS_HDR_SEQ_NO   smallint      NULL,
    TOT_HRS_AMT     decimal(14,2) NULL,
    TS_LN_KEY       int           NULL,
    RESID_AMT       decimal(8,2)  NULL,
    COL_ID_NO       smallint      NULL,
    TOT_LAB_CST_AMT decimal(14,2) NULL
)
go
IF OBJECT_ID('dbo.XX_DDC_WORKTBL2') IS NOT NULL
    PRINT '<<< CREATED TABLE dbo.XX_DDC_WORKTBL2 >>>'
ELSE
    PRINT '<<< FAILED CREATING TABLE dbo.XX_DDC_WORKTBL2 >>>'
go

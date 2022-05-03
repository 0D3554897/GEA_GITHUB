CREATE TABLE dbo.XX_R22_ET_DAILY_IN_ARC
(
    ET_DAILY_IN_ARC_NUM int         IDENTITY,
    STATUS_RECORD_NUM   int         NOT NULL,
    EMP_SERIAL_NUM      char(6)     NOT NULL,
    TS_YEAR             char(4)     NOT NULL,
    TS_MONTH            char(2)     NOT NULL,
    TS_DAY              char(2)     NOT NULL,
    TS_DATE             datetime    NOT NULL,
    TS_WEEK_END_DATE    datetime    NOT NULL,
    PROJ_ABBR           char(6)     NOT NULL,
    REG_TIME            char(6)     NULL,
    OVERTIME            char(6)     NULL,
    PLC                 char(6)     NULL,
    RECORD_TYPE         char(1)     NULL,
    AMENDMENT_NUM       char(2)     NOT NULL,
    CREATED_BY          varchar(20) NOT NULL,
    CREATED_DATE        datetime    NOT NULL,
    MODIFIED_BY         varchar(20) NULL,
    MODIFIED_DATE       datetime    NULL,
    ILC_ACTIVITY_CD     varchar(6)  NULL,
    PAY_TYPE            varchar(3)  NULL,
    CONSTRAINT PK_XX_R22_ET_DAILY_IN_ARC
    PRIMARY KEY CLUSTERED (ET_DAILY_IN_ARC_NUM) WITH FILLFACTOR=80,
    CONSTRAINT FK_XX_R22_ET_DAILY_IN_ARC
    FOREIGN KEY (STATUS_RECORD_NUM)
    REFERENCES dbo.XX_IMAPS_INT_STATUS (STATUS_RECORD_NUM)
)
go
IF OBJECT_ID('dbo.XX_R22_ET_DAILY_IN_ARC') IS NOT NULL
    PRINT '<<< CREATED TABLE dbo.XX_R22_ET_DAILY_IN_ARC >>>'
ELSE
    PRINT '<<< FAILED CREATING TABLE dbo.XX_R22_ET_DAILY_IN_ARC >>>'
go

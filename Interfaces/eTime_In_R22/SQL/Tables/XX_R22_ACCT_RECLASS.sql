-- Script Modified 11/05/2008
IF OBJECT_ID('dbo.XX_R22_ACCT_RECLASS') IS NOT NULL
    DROP TABLE dbo.XX_R22_ACCT_RECLASS
ELSE
    PRINT '<<< TABLE dbo.XX_R22_ACCT_RECLASS Does Not Exist, Creating One... >>>'
go

CREATE TABLE dbo.XX_R22_ACCT_RECLASS
(
    LAB_GRP_TYPE varchar(3)  NULL,
    PROJ_ID      varchar(4)  NULL,
    ACCT_GRP_CD  varchar(3)  NULL,
    ACCT_ID      varchar(15) NULL,
    CREATE_DATE  datetime    NULL,
    LINE_TYPE    varchar(10) NULL
)
go
IF OBJECT_ID('dbo.XX_R22_ACCT_RECLASS') IS NOT NULL
    PRINT '<<< CREATED TABLE dbo.XX_R22_ACCT_RECLASS >>>'
ELSE
    PRINT '<<< FAILED CREATING TABLE dbo.XX_R22_ACCT_RECLASS >>>'
go

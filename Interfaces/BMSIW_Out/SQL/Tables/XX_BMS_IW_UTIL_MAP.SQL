

if exists (select * from dbo.sysobjects where id = object_id(N'[XX_BMSIW_UTIL_MAP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [XX_BMSIW_UTIL_MAP]
GO

CREATE TABLE XX_BMSIW_UTIL_MAP
(
  CHARGE_TYPE     VARCHAR(2)              NOT NULL,
  PROJ_CLASS_DEF  VARCHAR(30),
  WORK_ITEM       VARCHAR(8),
  ACCT_ID         VARCHAR(8 ),
  ACTIVITY_CD     VARCHAR(6 ),
  ACCT_TYP_CD     CHAR(1 ),
  UTIL_DMN_CD     CHAR(1 ),
  UTIL_TYP_CD     VARCHAR(3 )
)

go


IF OBJECT_ID('dbo.XX_BMSIW_UTIL_MAP') IS NOT NULL
    PRINT '<<< CREATED TABLE dbo.XX_BMSIW_UTIL_MAP >>>'
ELSE
    PRINT '<<< FAILED CREATING TABLE dbo.XX_BMSIW_UTIL_MAP >>>'
go

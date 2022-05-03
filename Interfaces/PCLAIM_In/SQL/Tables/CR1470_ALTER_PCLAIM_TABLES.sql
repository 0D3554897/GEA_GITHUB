-- Reference BP&S Service Request No. CR1470

USE IMAPSStg
GO

ALTER TABLE dbo.XX_PCLAIM_IN_TMP ADD UNID char(32) NULL 
GO
ALTER TABLE dbo.XX_PCLAIM_IN_TMP ADD REVISION_NUM char(5) NULL 
GO


ALTER TABLE dbo.XX_PCLAIM_IN ADD UNID char(32) NULL 
GO
ALTER TABLE dbo.XX_PCLAIM_IN ADD REVISION_NUM char(5) NULL 
GO


ALTER TABLE dbo.XX_PCLAIM_IN_ARCH ADD UNID char(32) NULL 
GO
ALTER TABLE dbo.XX_PCLAIM_IN_ARCH ADD REVISION_NUM char(5) NULL 
GO

use imapsstg
select top 1 unid, revision_num
from xx_pclaim_in
select top 1 unid, revision_num
from xx_pclaim_in_tmp
select top 1 unid, revision_num
from xx_pclaim_in_arch


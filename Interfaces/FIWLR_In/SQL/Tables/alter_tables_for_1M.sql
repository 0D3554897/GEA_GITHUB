use imapsstg

update xx_cls_imaps_acct_map
set division='16'
where division is null

insert into xx_cls_imaps_acct_map
(
ACCT_ID,
MAJOR_1,
MAJOR_2,
MINOR_1,
MINOR_2,
SUB_MINOR_1,
SUB_MINOR_2,
ANALYSIS_CD,
PAG,
VAL_NON_VAL_FL,
INC_EXC_FL,
ACCT_DESC,
ANALYSIS_CD_DESC,
REFERENCE_1,
REFERENCE_2,
DIVISION,
creation_date,
created_by,
MODIFIED_BY,
MODIFIED_DATE
)
select
ACCT_ID,
MAJOR_1,
MAJOR_2,
MINOR_1,
MINOR_2,
SUB_MINOR_1,
SUB_MINOR_2,
ANALYSIS_CD,
PAG,
VAL_NON_VAL_FL,
INC_EXC_FL,
ACCT_DESC,
ANALYSIS_CD_DESC,
REFERENCE_1,
REFERENCE_2,
'1M' as DIVISION,
current_timestamp as creation_date,
suser_name() as created_by,
suser_name() MODIFIED_BY,
current_timestamp as MODIFIED_DATE
from xx_cls_imaps_acct_map



use imapsstg
/****** Object:  Index IX_FIWLR_USDET_V3_Mapping on Table [dbo].[XX_FIWLR_USDET_V3]    Script Date: 02/22/2007 12:12:43 PM ******/
if exists (select * from dbo.sysindexes where name = N'IX_FIWLR_USDET_V3_Mapping' and id = object_id(N'[dbo].[XX_FIWLR_USDET_V3]'))
drop index [dbo].[XX_FIWLR_USDET_V3].[IX_FIWLR_USDET_V3_Mapping]
GO

 CREATE  CLUSTERED  INDEX [IX_FIWLR_USDET_V3_Mapping] ON [dbo].[XX_FIWLR_USDET_V3]([DIVISION], [MAJOR], [MINOR], [SUBMINOR], [PAG_CD]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO



--test this (after reprocess is done)
if exists (select * from dbo.sysindexes where name = N'miscode_Status_record_line_number' and id = object_id(N'[dbo].[XX_FIWLR_USDET_MISCODES]'))
drop index [dbo].[XX_FIWLR_USDET_MISCODES].[miscode_Status_record_line_number]
GO
/****** Object:  Index [miscode_Status_record_line_number]    Script Date: 09/22/2010 14:49:58 ******/
CREATE UNIQUE CLUSTERED INDEX [miscode_Status_record_line_number] ON [dbo].[XX_FIWLR_USDET_MISCODES] 
(
	[STATUS_REC_NO] ASC,
	[DIVISION] ASC,
	[IDENT_REC_NO] ASC,
	[SOURCE_GROUP] ASC
)WITH (PAD_INDEX  = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, FILLFACTOR = 80, ONLINE = OFF) ON [PRIMARY]

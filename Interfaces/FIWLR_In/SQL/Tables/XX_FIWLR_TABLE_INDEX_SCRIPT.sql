/****** Object:  Index IX_CLS_IMAPS_ACCT_MAP_Mapping on Table [dbo].[XX_CLS_IMAPS_ACCT_MAP]    Script Date: 02/22/2007 12:12:04 PM ******/
if exists (select * from dbo.sysindexes where name = N'IX_CLS_IMAPS_ACCT_MAP_Mapping' and id = object_id(N'[dbo].[XX_CLS_IMAPS_ACCT_MAP]'))
drop index [dbo].[XX_CLS_IMAPS_ACCT_MAP].[IX_CLS_IMAPS_ACCT_MAP_Mapping]
GO

 CREATE  CLUSTERED  INDEX [IX_CLS_IMAPS_ACCT_MAP_Mapping] ON [dbo].[XX_CLS_IMAPS_ACCT_MAP]([MAJOR_1], [MINOR_1], [SUB_MINOR_1], [PAG]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

/****** Object:  Index IX_FIWLR_USDET_V3_Mapping on Table [dbo].[XX_FIWLR_USDET_V3]    Script Date: 02/22/2007 12:12:43 PM ******/
if exists (select * from dbo.sysindexes where name = N'IX_FIWLR_USDET_V3_Mapping' and id = object_id(N'[dbo].[XX_FIWLR_USDET_V3]'))
drop index [dbo].[XX_FIWLR_USDET_V3].[IX_FIWLR_USDET_V3_Mapping]
GO

 CREATE  CLUSTERED  INDEX [IX_FIWLR_USDET_V3_Mapping] ON [dbo].[XX_FIWLR_USDET_V3]([MAJOR], [MINOR], [SUBMINOR], [PAG_CD]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO


/****** Object:  Index IX_FIWLR_USDET_V3_Status on Table [dbo].[XX_FIWLR_USDET_V3]    Script Date: 02/22/2007 12:12:53 PM ******/
if exists (select * from dbo.sysindexes where name = N'IX_FIWLR_USDET_V3_Status' and id = object_id(N'[dbo].[XX_FIWLR_USDET_V3]'))
drop index [dbo].[XX_FIWLR_USDET_V3].[IX_FIWLR_USDET_V3_Status]
GO

 CREATE  INDEX [IX_FIWLR_USDET_V3_Status] ON [dbo].[XX_FIWLR_USDET_V3]([STATUS_REC_NO], [SOURCE_GROUP]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO



/****** Object:  Index Status_record_line_number on Table [dbo].[XX_FIWLR_USDET_ARCHIVE]    Script Date: 6/22/2007 12:27:44 PM ******/
if exists (select * from dbo.sysindexes where name = N'Status_record_line_number' and id = object_id(N'[dbo].[XX_FIWLR_USDET_ARCHIVE]'))
drop index [dbo].[XX_FIWLR_USDET_ARCHIVE].[Status_record_line_number]
GO

 CREATE  UNIQUE  CLUSTERED  INDEX [Status_record_line_number] ON [dbo].[XX_FIWLR_USDET_ARCHIVE]([STATUS_REC_NO], [IDENT_REC_NO], [SOURCE_GROUP]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO



/****** Object:  Index miscode_Status_record_line_number on Table [dbo].[XX_FIWLR_USDET_MISCODES]    Script Date: 6/26/2007 2:33:47 PM ******/
if exists (select * from dbo.sysindexes where name = N'miscode_Status_record_line_number' and id = object_id(N'[dbo].[XX_FIWLR_USDET_MISCODES]'))
drop index [dbo].[XX_FIWLR_USDET_MISCODES].[miscode_Status_record_line_number]
GO

 CREATE  UNIQUE  CLUSTERED  INDEX [miscode_Status_record_line_number] ON [dbo].[XX_FIWLR_USDET_MISCODES]([STATUS_REC_NO], [IDENT_REC_NO], [SOURCE_GROUP]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO



use imapsstg

alter table dbo.xx_ceris_cp_stg
add SALSETID varchar(2) NULL
GO
alter table dbo.xx_ceris_hist
add SALSETID varchar(2) NULL
GO
alter table dbo.xx_ceris_hist_archival
add SALSETID varchar(2) NULL
GO


alter table dbo.xx_ceris_cp_stg
add WKLNEW varchar(3) NULL
GO
alter table dbo.xx_ceris_hist
add WKLNEW varchar(3) NULL
GO
alter table dbo.xx_ceris_hist_archival
add WKLNEW varchar(3) NULL
GO


alter table dbo.xx_ceris_cp_stg
add WKLCITY varchar(24) NULL
GO
alter table dbo.xx_ceris_hist
add WKLCITY varchar(24) NULL
GO
alter table dbo.xx_ceris_hist_archival
add WKLCITY varchar(24) NULL
GO


alter table dbo.xx_ceris_cp_stg
add WKLST varchar(2) NULL
GO
alter table dbo.xx_ceris_hist
add WKLST varchar(2) NULL
GO
alter table dbo.xx_ceris_hist_archival
add WKLST varchar(2) NULL
GO


alter table dbo.xx_ceris_cp_stg
add PAY_DIFFERENTIAL char(1) NULL
GO
alter table dbo.xx_ceris_hist
add PAY_DIFFERENTIAL char(1) NULL
GO
alter table dbo.xx_ceris_hist_archival
add PAY_DIFFERENTIAL char(1) NULL
GO


alter table dbo.xx_ceris_cp_stg
add PAY_DIFFERENTIAL_DT smalldatetime NULL
GO
alter table dbo.xx_ceris_hist
add PAY_DIFFERENTIAL_DT smalldatetime NULL
GO
alter table dbo.xx_ceris_hist_archival
add PAY_DIFFERENTIAL_DT smalldatetime NULL
GO



/****** Object:  Table [dbo].[XX_IMAPS_CMR_STG]    Script Date: 1/11/2006 5:32:20 PM ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_IMAPS_CMR_STG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[XX_IMAPS_CMR_STG]
GO

if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XX_IMAPS_CMR_STG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
 BEGIN
CREATE TABLE [dbo].[XX_IMAPS_CMR_STG] (
	[I_CUST_ENTITY] [int] NOT NULL ,
	[I_CO] [int] NULL ,
	[I_ENT] [int] NULL ,
	[N_ABBREV] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[I_CUST_ADDR_TYPE] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[T_ADDR_LINE_1] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[T_ADDR_LINE_2] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[T_ADDR_LINE_3] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[T_ADDR_LINE_4] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[N_CITY] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[N_ST] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[C_ZIP] [int] NULL ,
	[C_SCC_ST] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[C_SCC_CNTY] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[C_SCC_CITY] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[I_MKTG_OFF] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[A_LEVEL_1_VALUE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[I_PRIMRY_SVC_OFF] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[C_ICC_TE] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[C_ICC_TAX_CLASS] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[C_ESTAB_SIC] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[I_INDUS_DEPT] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[I_INDUS_CLASS] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[C_NAP] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[I_TYPE_CUST_1] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[F_GENRL_SVC_ADMIN] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[F_OCL] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
END

GO



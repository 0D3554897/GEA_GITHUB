USE [IMAPSStg]
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[XX_PLC_RATE_UPDATE_STG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [XX_PLC_RATE_UPDATE_STG]
GO

CREATE TABLE [dbo].[XX_PLC_RATE_UPDATE_STG](
   [PROJ_ID]         [varchar](30) NULL,
   [GENL_LAB_CAT_CD] [varchar](6)  NULL,
   [BILL_LAB_CAT_CD] [varchar](6)  NULL,
   [BILL_RT_AMT]     [varchar](22) NULL,
   [START_DT]        [datetime]    NULL,
   [END_DT]          [datetime]    NULL,
   [CREATE_DT]       [datetime]    NULL,
   [CREATE_USER]     [varchar](20) NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[XX_PLC_RATE_UPDATE_STG] ADD DEFAULT (getdate()) FOR [CREATE_DT]
GO

ALTER TABLE [dbo].[XX_PLC_RATE_UPDATE_STG] ADD DEFAULT (suser_sname()) FOR [CREATE_USER]
GO

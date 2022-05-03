-- DR7751 (CP600002387)

USE [IMAPSStg]
GO

IF EXISTS (select * from dbo.sysobjects where ID = OBJECT_ID(N'[dbo].[XX_IMAPS_INV_OUT_SUM_DTLS_STG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
   DROP TABLE [dbo].[XX_IMAPS_INV_OUT_SUM_DTLS_STG]
GO

CREATE TABLE [dbo].[XX_IMAPS_INV_OUT_SUM_DTLS_STG] (
   [STATUS_RECORD_NUM] [integer] NOT NULL,
   [CTRL_PT4_RUN_FLAG] [varchar](1),
   [TOTAL_INVCS]       [integer],
   [TOTAL_CCS]         [decimal](14, 2),
   [TOTAL_FDS]         [decimal](14, 2),
   [TOTAL_CSP]         [decimal](14, 2),
   [CREATED_DT]        [datetime] NOT NULL DEFAULT (getdate()),
   [CREATED_BY]        [varchar](20) NOT NULL DEFAULT (suser_sname())
) ON [PRIMARY]
GO

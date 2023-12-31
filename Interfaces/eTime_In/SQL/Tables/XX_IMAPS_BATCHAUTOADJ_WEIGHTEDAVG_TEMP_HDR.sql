USE [IMAPSStg]
GO
/****** Object:  Table [dbo].[XX_IMAPS_BATCHAUTOADJ_WEIGHTEDAVG_TEMP_HDR]    Script Date: 02/09/2013 11:52:07 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[XX_IMAPS_BATCHAUTOADJ_WEIGHTEDAVG_TEMP_HDR](
	[TS_DT] [smalldatetime] NULL,
	[EMPL_ID] [varchar](12) NULL,
	[S_TS_TYPE_CD] [varchar](2) NULL,
	[TS_HDR_SEQ_NO] [smallint] NULL,
	[CORRECTING_REF_DT] [smalldatetime] NULL,
	[FRIDAY] [datetime] NULL,
	[MON_SUB_PD_END_DT] [smalldatetime] NULL,
	[OLD_AUTOADJ_RT] [decimal](10, 8) NULL,
	[OLD_AUTOADJ_RT_FOR_FULL_WEEK] [decimal](10, 8) NULL,
	[WEEKLY_SAL] [decimal](10, 2) NULL,
	[UNWEIGHTED_CST] [decimal](21, 10) NULL,
	[HRS_IN_WEEK] [decimal](14, 2) NULL,
	[SPLIT_HRS] [decimal](14, 2) NULL,
	[NEW_AUTOADJ_RT] [decimal](10, 8) NULL,
	[WEIGHTED_CST] [decimal](21, 10) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF